/******************************************************************
Change Script 3.0.10.26
1. update pmt_upd_boundary_features to correct feature taxonomy 
selection error when assigning locaitons country
******************************************************************/
INSERT INTO version(_version, _iteration, _changeset) VALUES (3.0, 10, 26);
-- select * from version order by _iteration desc, _changeset desc;

/******************************************************************
1. update pmt_upd_boundary_features to correct feature taxonomy 
selection error when assigning locaitons country  
******************************************************************/
-- upd_boundary_features
CREATE OR REPLACE FUNCTION pmt_upd_boundary_features()
RETURNS trigger AS $pmt_upd_boundary_features$
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
  -- Remove all existing location boundary information for this location (to be recreated by this trigger)
  EXECUTE 'DELETE FROM location_boundary WHERE location_id = ' || NEW.id;
  RAISE NOTICE 'Refreshing boundary features for id % ...', NEW.id;

  -- if a boundary_id and feature_id are provided then get a centroid of the requested feature to serve as the point
  -- locations can be polygons by making an association to an existing boundary feature
  IF (SELECT * FROM pmt_validate_boundary_feature(NEW.boundary_id, NEW.feature_id)) THEN
    SELECT INTO spatialtable _spatial_table FROM boundary b WHERE _active = true AND b.id = NEW.boundary_id;
    -- get centroid and assign as NEW._point
    execute_statement := 'SELECT ST_Transform(ST_Centroid((SELECT _polygon FROM ' || quote_ident(spatialtable) || ' WHERE id = ' || NEW.feature_id || ' LIMIT 1)),4326)' ;
    EXECUTE execute_statement INTO centroid;
    IF (centroid IS NOT NULL) THEN	      
      NEW._point := centroid;
      -- RAISE NOTICE 'Centroid of boundary assigned';
    END IF;
  END IF; 

  -- if a point is provided or assigned above then find all the boundary features 
  -- that are intersected by the point
  IF (NEW._point IS NOT NULL) THEN
    -- loop through each available boundary
    FOR boundary IN SELECT * FROM boundary LOOP
      -- find the feature in the boundary, interescted by our point
      FOR feature IN EXECUTE 'SELECT * FROM ' || quote_ident(boundary._spatial_table)  || ' WHERE ST_Intersects(ST_PointFromText(''' || 
		ST_AsText(NEW._point) || ''', 4326), _polygon)' LOOP
	-- RAISE NOTICE 'Found intersecting boundary for %', boundary._spatial_table;
	-- for each intersected feature, record its values in the location_boundary table
	EXECUTE 'INSERT INTO location_boundary VALUES (' || NEW.id || ', ' || feature.boundary_id || ', ' || feature.id || ', ' || 
		ST_Area(feature._polygon) || ', ' || quote_literal(feature._name) || ')';
	-- assign all associated taxonomy classification from intersected features to new location
	FOR ft IN (SELECT * FROM feature_taxonomy WHERE feature_taxonomy.feature_id = feature.id AND feature_taxonomy.boundary_id = feature.boundary_id) LOOP	  
	  IF ft IS NOT NULL THEN
	  -- RAISE NOTICE 'Found feature taxonomy for feature id %', ft.feature_id;
	  -- RAISE NOTICE 'Found feature taxonomy as classification id %', ft.classification_id;
	    -- replace all previous taxonomy classification associations with new for the given taxonomy
  	    DELETE FROM location_taxonomy WHERE location_id = NEW.id AND classification_id IN 
		(SELECT classification_id FROM _taxonomy_classifications WHERE taxonomy_id = (SELECT taxonomy_id FROM classification WHERE classification.id = ft.classification_id));    
	    INSERT INTO location_taxonomy VALUES (NEW.id, ft.classification_id, 'id');
	  END IF;
	END LOOP;
      END LOOP;	
    END LOOP;
  END IF;

RETURN NEW;

END;
$pmt_upd_boundary_features$ LANGUAGE plpgsql; 
DROP TRIGGER IF EXISTS pmt_upd_boundary_features ON location;
CREATE TRIGGER pmt_upd_boundary_features AFTER INSERT OR UPDATE ON location
    FOR EACH ROW EXECUTE PROCEDURE pmt_upd_boundary_features();

-- update all location_boundary entries
UPDATE location SET _title = _title WHERE _active = true;

-- update permissions
GRANT USAGE ON SCHEMA public TO pmt_read;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO pmt_read;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO pmt_read;
GRANT USAGE ON SCHEMA public TO pmt_write;
GRANT SELECT,INSERT ON ALL TABLES IN SCHEMA public TO pmt_write;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO pmt_write;