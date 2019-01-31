/******************************************************************
Change Script 3.0.10.67
1. update pmt_stat_activity_by_tax to sort null values last.
******************************************************************/
INSERT INTO version(_version, _iteration, _changeset) VALUES (3.0, 10, 67);
-- select * from version order by _iteration desc, _changeset desc;

/******************************************************************
1. create funciton to support batch updates for location boundary
recalculations
  select * from pmt_recalculate_location_boundaries(ARRAY[2345]);
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_recalculate_location_boundaries(l_ids integer[]) RETURNS boolean AS $$
DECLARE
  l_id int;
  ct int;
  location_record record;
  boundary record;
  feature record;
  ft record;
  feature_spatial_table text;
  feature_group text;
  simple_polygon_boundary text;
  simple_polygon_feature text;
  feature_statement text;
  error_msg text;
BEGIN

-- no parameter is provided, exit
IF $1 IS NULL THEN    
  RETURN FALSE;
END IF;
 
IF array_length(l_ids,1)>0 THEN
  ct:=1;
  -- loop through all the activity_ids and purge each activity
  FOREACH l_id IN ARRAY l_ids LOOP
    EXECUTE 'SELECT * FROM location WHERE id = ' || l_id INTO location_record;
    --RAISE NOTICE 'Updating location id: %', location_record.id;
    IF (location_record.id IS NOT NULL) THEN
      RAISE NOTICE 'Updating location id: %', location_record.id;
      RAISE NOTICE 'Updating location #: %', ct;
      -- Remove all existing location boundary information for this location (to be recreated by this trigger)
      EXECUTE 'DELETE FROM location_boundary WHERE location_id = ' || location_record.id;
      RAISE NOTICE 'Refreshing boundary features for id % ...', location_record.id; 

      -- if the location is an exact location (point), then intersect all boundaries
      IF (location_record.boundary_id IS NULL AND location_record.feature_id IS NULL) THEN
        -- loop through each available boundary
        FOR boundary IN SELECT * FROM boundary LOOP
          -- find the feature in the boundary, interescted by our point
          FOR feature IN EXECUTE 'SELECT * FROM ' || quote_ident(boundary._spatial_table)  || ' WHERE ST_Intersects(ST_PointFromText(''' || 
		ST_AsText(location_record._point) || ''', 4326), _polygon)' LOOP
	    -- RAISE NOTICE 'Found intersecting boundary for %', boundary._spatial_table;
	    -- for each intersected feature, record its values in the location_boundary table
	    EXECUTE 'INSERT INTO location_boundary VALUES (' || location_record.id || ', ' || feature.boundary_id || ', ' || feature.id || ', ' || quote_literal(feature._name) || ')';
	    -- assign all associated taxonomy classification from intersected features to location_record location
	    FOR ft IN (SELECT * FROM feature_taxonomy WHERE feature_taxonomy.feature_id = feature.id AND feature_taxonomy.boundary_id = feature.boundary_id) LOOP	  
	      IF ft IS NOT NULL THEN
	      -- RAISE NOTICE 'Found feature taxonomy for feature id %', ft.feature_id;
	      -- RAISE NOTICE 'Found feature taxonomy as classification id %', ft.classification_id;
	        -- replace all previous taxonomy classification associations with location_record for the given taxonomy
  	        DELETE FROM location_taxonomy WHERE location_id = location_record.id AND classification_id IN 
	  	  (SELECT classification_id FROM _taxonomy_classifications WHERE taxonomy_id = (SELECT taxonomy_id FROM classification WHERE classification.id = ft.classification_id));    
	        INSERT INTO location_taxonomy VALUES (location_record.id, ft.classification_id, 'id');
	      END IF;
	    END LOOP;
          END LOOP;	
        END LOOP;
      -- if the location is polygon feature, then only intersect boundaries that are less than or equal administrative levels
      ELSE
        -- get the spatial table of the location feature
        SELECT INTO feature_spatial_table _spatial_table FROM boundary WHERE id = location_record.boundary_id; 
        -- get the boundary group of the location feature
        SELECT INTO feature_group _group FROM boundary WHERE id = location_record.boundary_id; 
        -- loop through each available boundary that has an administrative level equal to or less than the location feature
        FOR boundary IN SELECT * FROM boundary WHERE (_admin_level IS NULL OR _admin_level <= location_record._admin_level) AND (_group = 'global' OR _group = feature_group)  LOOP
          -- get the simple polygon column for the boundary
          EXECUTE 'SELECT column_name FROM information_schema.columns WHERE table_name = ''' || quote_ident(boundary._spatial_table)  || ''' AND column_name = ''_polygon_simple_med''' INTO simple_polygon_boundary;
          -- get the simple polygon column for the feature
          EXECUTE 'SELECT column_name FROM information_schema.columns WHERE table_name = ''' || quote_ident(feature_spatial_table)  || ''' AND column_name = ''_polygon_simple_med''' INTO simple_polygon_feature;
          -- boundary and feature are the same
          IF boundary._spatial_table = feature_spatial_table THEN 
            feature_statement := 'SELECT id, boundary_id, _name FROM ' || quote_ident(feature_spatial_table)  || ' WHERE id = ' || location_record.feature_id;
            -- find the feature in the boundary, interescted by our point
            FOR feature IN EXECUTE feature_statement LOOP
	      EXECUTE 'INSERT INTO location_boundary VALUES (' || location_record.id || ', ' || feature.boundary_id || ', ' || feature.id || ', ' || quote_literal(feature._name) || ')';	  
            END LOOP;
          -- boundary and feature are different do an intersection
          ELSE    
            -- boundary has a simple polygon
            IF simple_polygon_boundary IS NOT NULL THEN
              RAISE NOTICE 'Boundary % has a simplified polgon', boundary._spatial_table;
              IF simple_polygon_feature IS NOT NULL THEN
                RAISE NOTICE 'Feature % has a simplified polgon', feature_spatial_table;
                feature_statement := 'SELECT b.id, b.boundary_id, b._name FROM ' || quote_ident(boundary._spatial_table)  || ' b, ' ||
	          '(SELECT _polygon_simple_med FROM ' || quote_ident(feature_spatial_table)  || ' WHERE id = ' || location_record.feature_id || ') l ' ||
	          'WHERE ST_Intersects(b._polygon_simple_med, l._polygon_simple_med) AND (ST_Area(ST_Intersection(b._polygon_simple_med, l._polygon_simple_med))/ST_Area(l._polygon_simple_med)) > .85';
              ELSE
	        RAISE NOTICE 'Feature % does not have a simplified polgon', feature_spatial_table;
                feature_statement := 'SELECT b.id, b.boundary_id, b._name FROM ' || quote_ident(boundary._spatial_table)  || ' b, ' ||
	          '(SELECT _polygon FROM ' || quote_ident(feature_spatial_table)  || ' WHERE id = ' || location_record.feature_id || ') l ' ||
	          'WHERE ST_Intersects(b._polygon_simple_med, l._polygon) AND (ST_Area(ST_Intersection(b._polygon_simple_med, l._polygon))/ST_Area(l._polygon)) > .85';
              END IF;	
            -- boundary does not have a simple polygon
            ELSE
	    RAISE NOTICE 'Boundary % does NOT have a simplified polgon',boundary._spatial_table;
              IF simple_polygon_feature IS NOT NULL THEN
                RAISE NOTICE 'Feature % has a simplified polgon', feature_spatial_table;
	        feature_statement := 'SELECT b.id, b.boundary_id, b._name FROM ' || quote_ident(boundary._spatial_table)  || ' b, ' ||
	          '(SELECT _polygon_simple_med FROM ' || quote_ident(feature_spatial_table)  || ' WHERE id = ' || location_record.feature_id || ') l ' ||
	          'WHERE ST_Intersects(b._polygon, l._polygon_simple_med) AND (ST_Area(ST_Intersection(b._polygon, l._polygon_simple_med))/ST_Area(l._polygon_simple_med)) > .85';
	      ELSE	
	        RAISE NOTICE 'Feature % does not have a simplified polgon', feature_spatial_table;
	        feature_statement := 'SELECT b.id, b.boundary_id, b._name FROM ' || quote_ident(boundary._spatial_table)  || ' b, ' ||
	          '(SELECT _polygon FROM ' || quote_ident(feature_spatial_table)  || ' WHERE id = ' || location_record.feature_id || ') l ' ||
	          'WHERE ST_Intersects(b._polygon, l._polygon) AND (ST_Area(ST_Intersection(b._polygon, l._polygon))/ST_Area(l._polygon)) > .85';
	      END IF;
            END IF;
            -- find the feature in the boundary, interescted by our point
            FOR feature IN EXECUTE feature_statement LOOP
	     -- RAISE NOTICE 'Found intersecting boundary for %', boundary._spatial_table;
	      -- for each intersected feature, record its values in the location_boundary table
	      EXECUTE 'INSERT INTO location_boundary VALUES (' || location_record.id || ', ' || feature.boundary_id || ', ' || feature.id || ', ' || quote_literal(feature._name) || ')';
	      -- assign all associated taxonomy classification from intersected features to location_record location
	      FOR ft IN (SELECT * FROM feature_taxonomy WHERE feature_taxonomy.feature_id = feature.id AND feature_taxonomy.boundary_id = feature.boundary_id) LOOP	  
	        IF ft IS NOT NULL THEN
	          -- RAISE NOTICE 'Found feature taxonomy for feature id %', ft.feature_id;
	          -- RAISE NOTICE 'Found feature taxonomy as classification id %', ft.classification_id;
  	          -- replace all previous taxonomy classification associations with location_record for the given taxonomy
  	          DELETE FROM location_taxonomy WHERE location_id = location_record.id AND classification_id IN 
	    	    (SELECT classification_id FROM _taxonomy_classifications WHERE taxonomy_id = (SELECT taxonomy_id FROM classification WHERE classification.id = ft.classification_id));    
	          INSERT INTO location_taxonomy VALUES (location_record.id, ft.classification_id, 'id');
	        END IF;
	      END LOOP;
            END LOOP;
          END IF;	
        END LOOP;
      END IF;
    END IF;
    ct:=ct+1;
  END LOOP;    
ELSE
  -- exit if array is empty
  RETURN FALSE;
END IF;

-- success
RETURN TRUE;

EXCEPTION
  -- some type of error occurred, return unsuccessful
     WHEN others THEN 
       GET STACKED DIAGNOSTICS error_msg = MESSAGE_TEXT;
       RAISE NOTICE 'Error: %', error_msg;
       RETURN FALSE;
       
END;$$ LANGUAGE plpgsql;

-- update permissions
GRANT USAGE ON SCHEMA public TO pmt_read;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO pmt_read;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO pmt_read;
GRANT USAGE ON SCHEMA public TO pmt_write;
GRANT SELECT,INSERT ON ALL TABLES IN SCHEMA public TO pmt_write;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO pmt_write;