/******************************************************************
Change Script 2.0.8.48 - consolidated.
1. pmt_edit_location - - new function for editing location
2. upd_boundary_features - update to check for null point
3. pmt_validiate_location - new function to validate location_id
******************************************************************/
INSERT INTO version(version, iteration, changeset) VALUES (2.0, 8, 48);
-- select * from version order by changeset desc;

-- testing (title, description, point)
-- select * from location where title = 'Test Location'
-- delete from location where title = 'Test Location'
-- select * from pmt_edit_location(3, null, 6, '{"title": "Test Location", "point":"POINT(39.0234375 6.9427857850946015)"}', false); -- create 
-- select * from pmt_edit_location(3, null, 6, '{"TITLE": "Test Location", "point":"POINT(18.984375 10.071628685919361)"}', false); -- create 
-- select * from pmt_edit_location(3, null, 6, '{"title": "Test Location", "description": "a cool place", "point":"POINT(26.3671875 15.215288476840565)"}', false); -- create 
-- select * from pmt_edit_location(3, 81119, null, '{"description": "a very cool place"}', false); -- update 
-- select * from pmt_edit_location(3, 81118, null, '{"point":"POINT(4.921875 27.308333052145453)"}', false); -- update
-- select * from pmt_edit_location(3, 81116, null, null, true); -- delete

-- old drop statement
DROP FUNCTION IF EXISTS pmt_edit_location(integer, integer, integer, json, boolean)  CASCADE;

/******************************************************************
  pmt_edit_location
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_edit_location(user_id integer, location_id integer, activity_id integer, key_value_data json, delete_record boolean default false) RETURNS SETOF pmt_json_result_type AS 
$$
DECLARE
  new_location_id integer;
  p_id integer;
  a_id integer;
  l_id integer;
  json record;
  column_record record;
  execute_statement text;
  invalid_editing_columns text[];
  delete_response json;
  user_name text;
  rec record;
  error_msg1 text;
  error_msg2 text;
  error_msg3 text;
BEGIN	
  -- set columns that are not editable via the parameters 
  invalid_editing_columns := ARRAY['location_id','activity_id','project_id', 'x', 'y', 'lat_dd', 'long_dd', 'latlong', 'georef', 
				   'active', 'retired_by', 'created_by', 'created_date', 'updated_by', 'updated_date'];
  
  -- user_id is required for all operations
  IF ($1 IS NOT NULL) THEN
    -- update/create operation
    IF NOT ($5) THEN
      -- json is required
      IF ($4 IS NULL) THEN
        FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: The json parameter is required for a create/update operation.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
      END IF;
      -- activity_id is required if location_id is null
      IF ($2 IS NULL) AND ($3 IS NULL) THEN
        FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: activity_id is required for a create operation.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
      END IF;
    -- delete operation	
    ELSE
      -- location_id is requried
      IF ($2 IS NULL) THEN
        FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: location_id is required for a delete operation.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
      END IF;
    END IF;
  -- error if user_id    
  ELSE
    FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: user_id is a required parameter for all operations.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
  END IF; 

  -- get users name
  SELECT INTO user_name username FROM "user" WHERE "user".user_id = $1;

  -- if location_id is null then validate users authroity to create a new location record  
  IF ($2 IS NULL) THEN
    -- validate activity_id
    IF (SELECT * FROM pmt_validate_activity($3)) THEN 
      SELECT INTO p_id a.project_id FROM activity a WHERE a.activity_id = $3;
      IF (SELECT * FROM pmt_validate_user_authority($1, p_id, 'create')) THEN
        EXECUTE 'INSERT INTO location(project_id, activity_id, created_by, updated_by) VALUES (' || p_id || ',' || $3 || ',' || quote_literal(user_name) || ',' || quote_literal(user_name) || ') RETURNING location_id;' INTO new_location_id;
        RAISE NOTICE 'Created new location with id: %', new_location_id;
      ELSE
        FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: User does NOT have authority to create a new location for activity_id: ' || $3 as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
      END IF;
    ELSE
      FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: activity_id is not valid.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
    END IF;
  -- validate location_id if provided and validate users authority to update an existing record  
  ELSE    
    -- validate location_id
    IF (SELECT * FROM pmt_validate_location($2)) THEN 
      -- get project_id and activity_id for location
      SELECT INTO p_id l.project_id FROM location l WHERE l.location_id = $2;      
      SELECT INTO a_id l.activity_id FROM location l WHERE l.location_id = $2;      
      -- validate users authority to 'delete' this activity
      IF ($5) THEN
        IF (SELECT * FROM pmt_validate_user_authority($1, p_id, 'delete')) THEN
          -- deactivate this activity          
          EXECUTE 'UPDATE location SET active = false, updated_by = ' || quote_literal(user_name) || ', updated_date = ' || quote_literal(current_date) || ' WHERE location_id = ' || $2;
        ELSE
          FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: User does NOT have authority to delete this location.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
        END IF;
      -- validate users authority to 'update' this activity
      ELSE        
        IF (SELECT * FROM pmt_validate_user_authority($1, p_id, 'update')) THEN   
        ELSE
          FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: User does NOT have authority to update this location.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
        END IF;
      END IF;
    ELSE
      FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: Invalid location_id.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
    END IF;
  END IF;

  -- assign the location_id to use in statements
  IF new_location_id IS NOT NULL THEN
    l_id := new_location_id;
  ELSE
    l_id := $2;
  END IF;
    
  -- loop through the columns of the activity table        
  FOR json IN (SELECT * FROM json_each_text($4)) LOOP
    RAISE NOTICE 'JSON key/value: %', lower(json.key) || ':' || json.value;
    -- get the column information for column that user is requesting to edit	
    FOR column_record IN (SELECT * FROM information_schema.columns WHERE table_schema='public' AND table_name='location' AND column_name != ALL(invalid_editing_columns) AND lower(column_name) = lower(json.key)) LOOP 
      RAISE NOTICE 'Editing column: %', column_record.column_name;
      RAISE NOTICE 'Assigning new value: %', json.value;
      RAISE NOTICE 'Column type: %', column_record.data_type;
      execute_statement := null;
      CASE column_record.data_type 
        WHEN 'integer', 'numeric' THEN              
          IF (SELECT pmt_isnumeric(json.value)) THEN
            execute_statement := 'UPDATE location SET ' || column_record.column_name || ' = ' || json.value || ' WHERE location_id = ' || l_id; 
          END IF;
          IF (lower(json.value) = 'null') THEN
            execute_statement := 'UPDATE location SET ' || column_record.column_name || ' = null WHERE location_id = ' || l_id; 
          END IF;
        WHEN 'USER-DEFINED' THEN
          IF(column_record.udt_name = 'geometry') THEN
	    -- per documenation assumes projection is (WGS84: 4326)
            execute_statement := 'UPDATE location SET ' || column_record.column_name || ' = ST_GeomFromText(' || quote_literal(json.value) || ', 4326) WHERE location_id = ' || l_id; 
          END IF;
        ELSE
          -- if the value has the text null then assign the column value null
          IF (lower(json.value) = 'null') THEN
            execute_statement := 'UPDATE location SET ' || column_record.column_name || ' = null WHERE location_id = ' || l_id; 
          ELSE
            execute_statement := 'UPDATE location SET ' || column_record.column_name || ' = ' || quote_literal(json.value) || ' WHERE location_id = ' || l_id; 
          END IF;
      END CASE;
      IF execute_statement IS NOT NULL THEN
        RAISE NOTICE 'Statement: %', execute_statement;
        EXECUTE execute_statement;
                
        EXECUTE 'UPDATE location SET updated_by = ' || quote_literal(user_name) || ', updated_date = ' || quote_literal(current_date) || ' WHERE  location_id = ' || l_id;
      END IF;
    END LOOP;
  END LOOP;
  -- editing completed successfullly
  FOR rec IN (SELECT row_to_json(j) FROM(select l_id as id, 'Success' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;         
  
EXCEPTION WHEN others THEN
     GET STACKED DIAGNOSTICS error_msg1 = MESSAGE_TEXT,
                          error_msg2 = PG_EXCEPTION_DETAIL,
                          error_msg3 = PG_EXCEPTION_HINT;
    FOR rec IN (SELECT row_to_json(j) FROM(select l_id as id, 'Internal Error - Contact your DBA with the following error message: ' || error_msg1 as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;	  
END;$$ LANGUAGE plpgsql;

-- upd_boundary_features
CREATE OR REPLACE FUNCTION upd_boundary_features()
RETURNS trigger AS $upd_boundary_features$
    DECLARE
	boundary RECORD;
	feature RECORD;
	rec RECORD;
	id integer;
    BEGIN
      --RAISE NOTICE 'Refreshing boundary features for location_id % ...', NEW.location_id;
	EXECUTE 'DELETE FROM location_boundary WHERE location_id = ' || NEW.location_id;
	
      -- Only process if there is a point value
      IF (NEW.point IS NOT NULL) THEN
	
	FOR boundary IN SELECT * FROM boundary LOOP
		--RAISE NOTICE 'Add % boundary features ...', quote_ident(boundary.spatial_table);
		FOR feature IN EXECUTE 'SELECT * FROM ' || quote_ident(boundary.spatial_table)  || ' WHERE ST_Intersects(ST_PointFromText(''' ||
			ST_AsText(NEW.point) || ''', 4326), polygon)' LOOP
			EXECUTE 'INSERT INTO location_boundary VALUES (' || NEW.location_id || ', ' || 
			feature.boundary_id || ', ' || feature.feature_id || ')';
		END LOOP;
				
	END LOOP;

	-- Find Country of location and add as location taxonomy
	FOR rec IN ( SELECT feature_id FROM  gaul0 WHERE ST_Intersects(NEW.point, polygon)) LOOP
	  RAISE NOTICE 'Intersected GUAL0 feature id: %', rec.feature_id; 
	  SELECT INTO id classification_id FROM feature_taxonomy WHERE feature_id = rec.feature_id;
	  IF id IS NOT NULL THEN	
	    DELETE FROM location_taxonomy WHERE location_id = NEW.location_id AND classification_id IN (SELECT classification_id FROM taxonomy_classifications WHERE taxonomy = 'Country');
	    INSERT INTO location_taxonomy VALUES (NEW.location_id, id, 'location_id');
	  END IF;
	END LOOP;
	
      END IF;
      RETURN NEW;
    END;
$upd_boundary_features$ LANGUAGE plpgsql; 
DROP TRIGGER IF EXISTS upd_boundary_features ON location;
CREATE TRIGGER upd_boundary_features BEFORE INSERT OR UPDATE ON location
    FOR EACH ROW EXECUTE PROCEDURE upd_boundary_features();

/******************************************************************
  pmt_validate_location
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_validate_location(id integer) RETURNS boolean AS $$
DECLARE valid_id integer;
BEGIN 
     IF $1 IS NULL THEN    
       RETURN false;
     END IF;    
     
     SELECT INTO valid_id location_id FROM location WHERE active = true AND location_id = $1;	 

     IF valid_id IS NULL THEN
      RETURN false;
     ELSE 
      RETURN true;
     END IF;
     
EXCEPTION WHEN others THEN
    RETURN FALSE;
END; 
$$ LANGUAGE 'plpgsql';    

-- update permissions
GRANT USAGE ON SCHEMA public TO pmt_read;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO pmt_read;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO pmt_read;
GRANT USAGE ON SCHEMA public TO pmt_write;
GRANT SELECT,INSERT ON ALL TABLES IN SCHEMA public TO pmt_write;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO pmt_write;