/******************************************************************
Change Script 3.0.10.82
 1. create new function to rebuild materialized views
 2. update pmt_edit_location to manage location taxonomies automatically
******************************************************************/
INSERT INTO version(_version, _iteration, _changeset) VALUES (3.0, 10, 82);
-- select * from version order by _iteration desc, _changeset desc;

/******************************************************************
 1. create new function to rebuild materialized views and analyze/vacuum
    select * from pmt_refresh_views(1,34);
    VACUUM ANALYZE;
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_refresh_views(instance_id integer, user_id integer) RETURNS SETOF pmt_json_result_type AS
$$
DECLARE
  users_instance record;
  rec record;
  error_msg text;
BEGIN
  -- instance_id is required
  IF ($1 IS NULL) THEN
    FOR rec IN (SELECT row_to_json(j) FROM(SELECT false AS success, 'Error: instance_id is a required parameter.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
  END IF;
  -- user_id is required
  IF ($2 IS NULL) THEN
    FOR rec IN (SELECT row_to_json(j) FROM(SELECT false AS success, 'Error: user_id is a required parameter.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
  END IF;
  
  -- get requesting user's information
  SELECT INTO users_instance * FROM _user_instances WHERE _user_instances.user_id = $2 AND _user_instances.instance_id = $1;

  -- user has authority for security actions on the instance
  IF (users_instance.role = 'Administrator' OR users_instance.role = 'Super') THEN
    -- refresh materialze views
    REFRESH MATERIALIZED VIEW _activity_family_finacials;
    REFRESH MATERIALIZED VIEW _activity_family_taxonomies;
    REFRESH MATERIALIZED VIEW _partnerlink_sankey_links;
    REFRESH MATERIALIZED VIEW _partnerlink_sankey_nodes;

   FOR rec IN (SELECT row_to_json(j) FROM(SELECT true AS success, 'Success' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
  ELSE
    FOR rec IN (SELECT row_to_json(j) FROM(SELECT false AS success, 'Error: user does not have Administrative or Super rights on instance.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
  END IF; 
    
EXCEPTION WHEN others THEN
  GET STACKED DIAGNOSTICS error_msg = MESSAGE_TEXT;
    FOR rec IN (SELECT row_to_json(j) FROM(SELECT false AS success, 'Internal Error - Contact your DBA with the following error message: ' || error_msg as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
    
END;$$ LANGUAGE plpgsql;


/******************************************************************
 2. update pmt_edit_location to manage location taxonomies automatically
******************************************************************/
DROP FUNCTION IF EXISTS pmt_edit_location(integer, integer, integer, json, boolean);
CREATE OR REPLACE FUNCTION pmt_edit_location(instance_id integer, user_id integer, activity_id integer, location_id integer, boundary_id integer, 
feature_id integer, admin_level integer, key_value_data json, delete_record boolean default false) RETURNS SETOF pmt_json_result_type AS 
$$
DECLARE
  a_id integer;
  l_id integer;
  boundary record;
  feature text;
  json record;
  column_record record;
  execute_statement text;
  invalid_editing_columns text[];
  delete_response json;
  username text;
  location_record record;
  rec record;
  error_msg text;
BEGIN	
  -- set columns that are not editable via the parameters 
  invalid_editing_columns := ARRAY['id','activity_id', '_x', '_y', '_lat_dd', '_long_dd', '_latlong', '_active', '_retired_by', '_created_by', '_created_date', '_updated_by', '_updated_date'];

  -- instance_id is required for all operations
  IF ($1 IS NULL) THEN
    FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: instance_id is a required parameter for all operations.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
  END IF;
  -- user_id is required for all operations
  IF ($2 IS NULL) THEN
    FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: user_id is a required parameter for all operations.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
  END IF;
  -- activity_id is required for all operations
  IF ($3 IS NULL) THEN
    FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: activity_id is a required parameter for all operations.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
  ELSE
     -- validate the associated activity record
    IF (SELECT * FROM pmt_validate_activity($3)) THEN  
      SELECT INTO a_id id FROM activity WHERE id = $3;
    ELSE
      FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: Invalid activity_id.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
    END IF;
  END IF;
  -- create operation
  IF NOT ($9) THEN
    -- boundary_id, feature_id & admin_level are required for create operations
    IF ($5 IS NULL) OR ($6 IS NULL) OR ($7 IS NULL) THEN
      FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: The boundary_id, feature_id & admin_level parameters are required for a create operation.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
    ELSE
      IF (SELECT * FROM pmt_validate_boundary_feature($5,$6)) THEN
        SELECT INTO boundary * FROM boundary WHERE id = $5;
        EXECUTE 'SELECT ST_AsText(_point) FROM '|| boundary._spatial_table ||' WHERE _active = true AND id = ' || $6 INTO feature; 
      ELSE
        FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: Invalid boundary_id & feature_id.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
      END IF;
      IF NOT (ARRAY[$7] <@ ARRAY[0,1,2,3]) THEN
        FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: Invalid admin_level.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
      END IF;
    END IF;
    -- json is required
    IF ($8 IS NULL) THEN
      FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: The json parameter is required for a create operation.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
    END IF;
  -- delete operation	
  ELSE
    -- location_id is required
    IF ($4 IS NULL) THEN
      FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: location_id is required for a delete operation.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
    END IF;
  END IF;
 
  -- get users name
  SELECT INTO username _username FROM users WHERE users.id = $2;

  -- validate users authority to update the activity record
  IF NOT (SELECT * FROM pmt_validate_user_authority($1, $2, $3, null, 'update')) THEN
    FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: User does NOT have authority to create/delete a location record for activity id ' || a_id as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
  END IF;  
  	
  -- create location record 
  IF NOT ($9) THEN
    EXECUTE 'INSERT INTO location(activity_id, boundary_id, feature_id, _admin_level, _point, _created_by, _updated_by) VALUES (' || $3 || ',' || $5 || ',' || $6 || ',' || $7 || 
		', ST_GeomFromText(' || quote_literal(feature) || ', 4326),' || quote_literal(username) || ',' || quote_literal(username) || ') RETURNING id;' INTO l_id;
    RAISE NOTICE 'Created new location with id: %', l_id;
  -- validate location_id if provided and validate users authority to update an existing record  
  ELSE    
    -- validate location_id
    IF (SELECT * FROM pmt_validate_location($4)) THEN      
      l_id := $4;
      -- delete this location   
      EXECUTE 'DELETE FROM location_taxonomy WHERE location_id = ' || l_id;       
      EXECUTE 'DELETE FROM location WHERE id = ' || l_id;
      FOR rec IN (SELECT row_to_json(j) FROM(select l_id as id, 'Success' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;  
    ELSE
      FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: Invalid location_id.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
    END IF;
  END IF;

  -- loop through the columns of the location table        
  FOR json IN (SELECT * FROM json_each_text($8)) LOOP
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
            execute_statement := 'UPDATE location SET ' || column_record.column_name || ' = ' || json.value || ' WHERE id = ' || l_id; 
          END IF;
          IF (lower(json.value) = 'null') THEN
            execute_statement := 'UPDATE location SET ' || column_record.column_name || ' = null WHERE id = ' || l_id; 
          END IF;
        WHEN 'USER-DEFINED' THEN
          IF(column_record.udt_name = 'geometry') THEN
	    -- per documenation assumes projection is (WGS84: 4326)
            execute_statement := 'UPDATE location SET ' || column_record.column_name || ' = ST_GeomFromText(' || quote_literal(json.value) || ', 4326) WHERE id = ' || l_id; 
          END IF;
        ELSE
          -- if the value has the text null then assign the column value null
          IF (lower(json.value) = 'null') THEN
            execute_statement := 'UPDATE location SET ' || column_record.column_name || ' = null WHERE id = ' || l_id; 
          ELSE
            execute_statement := 'UPDATE location SET ' || column_record.column_name || ' = ' || quote_literal(json.value) || ' WHERE id = ' || l_id; 
          END IF;
      END CASE;
      IF execute_statement IS NOT NULL THEN
        RAISE NOTICE 'Statement: %', execute_statement;
        EXECUTE execute_statement;
                
        EXECUTE 'UPDATE location SET _updated_by = ' || quote_literal(username) || ', _updated_date = ' || quote_literal(current_date) || ' WHERE  id = ' || l_id;
      END IF;
    END LOOP;
  END LOOP;
  -- get the location record
  SELECT INTO location_record * FROM location WHERE id = l_id;
  -- assign the correct "National/Local" taxonomy
  IF (location_record._admin_level = 0) THEN
    EXECUTE 'INSERT INTO location_taxonomy(location_id, classification_id, _field) VALUES (' || l_id || ', (SELECT classification_id FROM _taxonomy_classifications WHERE taxonomy = ''National/Local'' AND classification = ''National''), ''id'');';
  ELSE
    EXECUTE 'INSERT INTO location_taxonomy(location_id, classification_id, _field) VALUES (' || l_id || ', (SELECT classification_id FROM _taxonomy_classifications WHERE taxonomy = ''National/Local'' AND classification = ''Local''), ''id'');';
  END IF;
  -- assign the correct "Geographic Exactness" & "Geographic Location Class" taxonomy
  IF (location_record.boundary_id IS NOT NULL) THEN
    EXECUTE 'INSERT INTO location_taxonomy(location_id, classification_id, _field) VALUES (' || l_id || ', (SELECT classification_id FROM _taxonomy_classifications WHERE taxonomy = ''Geographic Exactness'' AND classification = ''Approximate''), ''id'');';
    EXECUTE 'INSERT INTO location_taxonomy(location_id, classification_id, _field) VALUES (' || l_id || ', (SELECT classification_id FROM _taxonomy_classifications WHERE taxonomy = ''Geographic Location Class'' AND classification = ''Administrative Region''), ''id'');';
  END IF;
  -- assign the correct "Geographical Precision" taxonomy
  IF (location_record._admin_level = 0) THEN
    EXECUTE 'INSERT INTO location_taxonomy(location_id, classification_id, _field) VALUES (' || l_id || ', (SELECT classification_id FROM _taxonomy_classifications WHERE taxonomy = ''Geographical Precision'' AND classification = ''Unclear - country''), ''id'');';
  END IF;
  IF (location_record._admin_level = 1) THEN
    EXECUTE 'INSERT INTO location_taxonomy(location_id, classification_id, _field) VALUES (' || l_id || ', (SELECT classification_id FROM _taxonomy_classifications WHERE taxonomy = ''Geographical Precision'' AND classification = ''First order administrative division''), ''id'');';
  END IF;
  IF (location_record._admin_level = 2) THEN
    EXECUTE 'INSERT INTO location_taxonomy(location_id, classification_id, _field) VALUES (' || l_id || ', (SELECT classification_id FROM _taxonomy_classifications WHERE taxonomy = ''Geographical Precision'' AND classification = ''Second order administrative division''), ''id'');';
  END IF;
  -- editing completed successfullly
  FOR rec IN (SELECT row_to_json(j) FROM(select l_id as id, 'Success' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;         
  
EXCEPTION WHEN others THEN
     GET STACKED DIAGNOSTICS error_msg = MESSAGE_TEXT;
    FOR rec IN (SELECT row_to_json(j) FROM(select l_id as id, 'Internal Error - Contact your DBA with the following error message: ' || error_msg as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;	  
END;$$ LANGUAGE plpgsql;


-- update permissions
GRANT USAGE ON SCHEMA public TO pmt_read;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO pmt_read;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO pmt_read;
GRANT USAGE ON SCHEMA public TO pmt_write;
GRANT SELECT,INSERT ON ALL TABLES IN SCHEMA public TO pmt_write;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO pmt_write;