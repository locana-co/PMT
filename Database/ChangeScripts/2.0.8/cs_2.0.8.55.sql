/******************************************************************
Change Script 2.0.8.55
1. location_boundary - add feature_area column to store feature 
total area value.
2. upd_boundary_features - calculate feature area of intersected 
gaul features
3. location_boundary_features - added feature area to view
4. location_lookup - altered logic to select smallest gaul2 feature
intersected
******************************************************************/
INSERT INTO version(version, iteration, changeset) VALUES (2.0, 8, 55);
-- select * from version order by changeset desc;

ALTER TABLE location_boundary ADD COLUMN feature_area float;

CREATE OR REPLACE FUNCTION upd_boundary_features()
RETURNS trigger AS $upd_boundary_features$
    DECLARE
	boundary RECORD;
	feature RECORD;
	ft RECORD;
	rec RECORD;
	spatialtable text;
	execute_statement text;
	centroid geometry;
	id integer;
    BEGIN
      --RAISE NOTICE 'Refreshing boundary features for location_id % ...', NEW.location_id;
      EXECUTE 'DELETE FROM location_boundary WHERE location_id = ' || NEW.location_id;

      IF (SELECT * FROM pmt_validate_boundary_feature(NEW.boundary_id, NEW.feature_id)) THEN
        SELECT INTO spatialtable spatial_table FROM boundary b WHERE active = true AND b.boundary_id = NEW.boundary_id;
        -- get centroid and assign as NEW.point
        execute_statement := 'SELECT ST_Transform(ST_Centroid((SELECT polygon FROM ' || quote_ident(spatialtable) || ' WHERE feature_id = ' || NEW.feature_id || ' LIMIT 1)),4326)' ;
        EXECUTE execute_statement INTO centroid;
	IF (centroid IS NOT NULL) THEN	
	  RAISE NOTICE 'Centroid of boundary assigned';
          NEW.point := centroid;
        END IF;
      END IF; 
        
      -- Only process if there is a point value
      IF (NEW.point IS NOT NULL) THEN
	
	FOR boundary IN SELECT * FROM boundary LOOP
		--RAISE NOTICE 'Add % boundary features ...', quote_ident(boundary.spatial_table);
		FOR feature IN EXECUTE 'SELECT * FROM ' || quote_ident(boundary.spatial_table)  || ' WHERE ST_Intersects(ST_PointFromText(''' ||
			ST_AsText(NEW.point) || ''', 4326), polygon)' LOOP
		  -- For each boundary locate intersecting features and record them in the location_boundary table
		  EXECUTE 'INSERT INTO location_boundary VALUES (' || NEW.location_id || ', ' || feature.boundary_id || ', ' || feature.feature_id || ', ' || ST_Area(feature.polygon) || ')';
		  -- Assign all associated taxonomy classification from intersected features to new location
		  FOR ft IN (SELECT * FROM feature_taxonomy WHERE feature_id = feature.feature_id) LOOP
		    -- Replace all previous taxonomy associates with new
		    DELETE FROM location_taxonomy WHERE location_id = NEW.location_id AND classification_id IN (SELECT classification_id FROM taxonomy_classifications WHERE taxonomy_id = (SELECT taxonomy_id FROM classification WHERE classification_id = ft.classification_id));    
		    INSERT INTO location_taxonomy VALUES (NEW.location_id, ft.classification_id, 'location_id');
		  END LOOP;
		END LOOP;
				
	END LOOP;
      END IF;
      
      RETURN NEW;
      
    END;
$upd_boundary_features$ LANGUAGE plpgsql; 
DROP TRIGGER IF EXISTS upd_boundary_features ON location;
CREATE TRIGGER upd_boundary_features BEFORE INSERT OR UPDATE ON location
    FOR EACH ROW EXECUTE PROCEDURE upd_boundary_features();

UPDATE location SET active = true WHERE active = true;
UPDATE location SET active = false WHERE active = false;

DROP MATERIALIZED VIEW location_lookup;
DROP VIEW location_boundary_features;

CREATE OR REPLACE VIEW location_boundary_features
AS SELECT l.location_id, l.activity_id, b.boundary_id, b.name as boundary_name, lb.feature_area, g0.name
FROM location l
JOIN location_boundary lb
ON l.location_id = lb.location_id
JOIN boundary b
ON lb.boundary_id = b.boundary_id
JOIN gaul0 g0
ON lb.feature_id = g0.feature_id AND lb.boundary_id = g0.boundary_id
--WHERE l.location_id = 123
UNION ALL
SELECT l.location_id, l.activity_id, b.boundary_id,  b.name as boundary_name, lb.feature_area, g1.name
FROM location l
JOIN location_boundary lb
ON l.location_id = lb.location_id
JOIN boundary b
ON lb.boundary_id = b.boundary_id
JOIN gaul1 g1
ON lb.feature_id = g1.feature_id AND lb.boundary_id = g1.boundary_id
--WHERE l.location_id = 123
UNION ALL
SELECT l.location_id, l.activity_id, b.boundary_id,  b.name as boundary_name, lb.feature_area, g2.name
FROM location l
JOIN location_boundary lb
ON l.location_id = lb.location_id
JOIN boundary b
ON lb.boundary_id = b.boundary_id
JOIN gaul2 g2
ON lb.feature_id = g2.feature_id AND lb.boundary_id = g2.boundary_id
ORDER BY location_id, boundary_id;

CREATE MATERIALIZED VIEW location_lookup AS
(SELECT project_id, activity_id, location_id, start_date, end_date, x, y, georef, array_agg(distinct taxonomy_id) as taxonomy_ids, array_agg(distinct classification_id) as classification_ids, array_agg(distinct organization_id) as organization_ids,
(SELECT lbf.name FROM location_boundary_features lbf WHERE taxonomy_lookup.location_id = lbf.location_id AND lbf.boundary_id = 1 LIMIT 1) as gaul0_name,
(SELECT lbf.name FROM location_boundary_features lbf WHERE taxonomy_lookup.location_id = lbf.location_id AND lbf.boundary_id = 2 LIMIT 1) as gaul1_name,
(SELECT lbf.name FROM location_boundary_features lbf WHERE taxonomy_lookup.location_id = lbf.location_id AND lbf.boundary_id = 3 ORDER BY lbf.feature_area LIMIT 1) as gaul2_name
FROM taxonomy_lookup
GROUP BY project_id, activity_id, location_id, start_date, end_date, x, y, georef);

-- Create index for location_lookup
CREATE INDEX location_lookup_project_id_idx on location_lookup(project_id);
CREATE INDEX location_lookup_activity_id_idx on location_lookup(activity_id);
CREATE INDEX location_lookup_location_id_idx on location_lookup(location_id);
CREATE INDEX location_lookup_start_date_idx on location_lookup(start_date);
CREATE INDEX location_lookup_end_date_idx on location_lookup(end_date);
CREATE INDEX location_lookup_gaul0_name_idx on location_lookup(gaul0_name);
CREATE INDEX location_lookup_gaul1_name_idx on location_lookup(gaul1_name);
CREATE INDEX location_lookup_gaul2_name_idx on location_lookup(gaul2_name);

-- update permissions
GRANT USAGE ON SCHEMA public TO pmt_read;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO pmt_read;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO pmt_read;
GRANT USAGE ON SCHEMA public TO pmt_write;
GRANT SELECT,INSERT ON ALL TABLES IN SCHEMA public TO pmt_write;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO pmt_write;
