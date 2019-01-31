/******************************************************************
Change Script 3.0.10.84
1. update pmt_edit_activity for new data model
******************************************************************/
INSERT INTO version(_version, _iteration, _changeset) VALUES (3.0, 10, 84);
-- select * from version order by _iteration desc, _changeset desc;

/******************************************************************
1. update pmt_edit_activity for new data model
select * from pmt_edit_activity(1,34,26326,null,'{"_title": "MERET PLUS Managing Environmental Resources to Ena…able Livelihoods Through Partnership and Land Use", "_start_date": "12/30/2006", "_end_date": "12/30/2011", "_description": "MERET is implemented through the Natural Resource …ality of the work before households receive food."}', false);
select * from pmt_edit_activity(1,275,null,2237,'{"_title": "AAA", "_start_date": "5/2/2017", "_end_date": "5/31/2017", "_description": null}', false);
select * from activity where id = 26326
select * from users
******************************************************************/
DROP FUNCTION IF EXISTS pmt_edit_activity(integer, integer, integer, json, boolean);
CREATE OR REPLACE FUNCTION pmt_edit_activity(instance_id integer, user_id integer, activity_id integer, data_group_id integer, key_value_data json, delete_record boolean default false) RETURNS SETOF pmt_json_result_type AS 
$$
DECLARE
  new_activity_id integer;
  a_id integer;
  json record;
  column_record record;
  execute_statement text;
  invalid_editing_columns text[];
  delete_response json;
  username text;
  rec record;
  valid_user_instance record; 
  users_role record;
  error_msg1 text;
  error_msg2 text;
  error_msg3 text;
BEGIN
  -- simulate database error 
  -- FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: simulating a database error.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
  	
  -- set columns that are not editable via the parameters 
  invalid_editing_columns := ARRAY['id', '_active', '_retired_by', '_created_by', '_created_date', '_updated_by', '_updated_date'];
  
  -- instance_id is required for all operations
  IF ($1 IS NULL) THEN
    FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: instance_id is a required parameter for all operations.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
  END IF;
  -- user_id is required for all operations
  IF ($2 IS NULL) THEN
    FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: user_id is a required parameter for all operations.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
  END IF;
  
  -- update/create operation
  IF NOT ($6) THEN
    -- json is required
    IF ($5 IS NULL) THEN
      FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: The json parameter is required for a create/update operation.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
    END IF;
    -- if activity is null (create) data_group_id is required
    IF ($3 IS NULL) AND ($4 IS NULL) THEN
      FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: The data_group_id parameter is required for a create operation.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
    END IF;      
  -- delete operation	
  ELSE
    -- activity_id is requried
    IF ($3 IS NULL) THEN
      FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: activity_id is required for a delete operation.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
    END IF;
  END IF;
 
  -- get users name
  SELECT INTO username _username FROM users WHERE users.id = $2;
  -- get user role
  SELECT INTO valid_user_instance * FROM _user_instances WHERE _user_instances.user_id = $2 AND _user_instances.instance_id = $1;
  IF valid_user_instance.user_id IS NOT NULL THEN
    SELECT INTO users_role * FROM role WHERE id = valid_user_instance.role_id;
    RAISE NOTICE 'Role: %', valid_user_instance.role;
  END IF;

  -- if activity_id is null then validate users authroity to create a new activity record  
  IF ($3 IS NULL) THEN       
      IF (SELECT * FROM pmt_validate_user_authority($1, $2, null, $4, 'create')) THEN
        EXECUTE 'INSERT INTO activity(data_group_id, _created_by, _updated_by) VALUES (' || $4 || ',' || quote_literal(username) || ',' || quote_literal(username) || ') RETURNING id;' INTO new_activity_id;
        RAISE NOTICE 'Created new activity with id: %', new_activity_id;
        IF valid_user_instance.role = 'Editor' THEN
          EXECUTE 'INSERT INTO user_activity(user_id, activity_id, _created_by, _updated_by) VALUES (' || $2 || ',' || new_activity_id || ',' || quote_literal(username) || ',' || quote_literal(username) || ');';
          RAISE NOTICE 'Authorized activity for Editor role.';
        END IF;
      ELSE
        FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: User does NOT have authority to create a new activity on instance id: ' || $1 as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
      END IF;
  -- validate activity_id and validate users authority to update/delete an existing record  
  ELSE    
    -- validate activity_id
    IF (SELECT * FROM pmt_validate_activity($3)) THEN 
      -- validate users authority to 'delete' this activity
      IF ($6) THEN
        IF (SELECT * FROM pmt_validate_user_authority($1, $2, $3, null, 'delete')) THEN
	  -- delete this activity          
          IF (SELECT * FROM pmt_purge_activity($3)) THEN
            -- delete completed successfullly
	    FOR rec IN (SELECT row_to_json(j) FROM(select $3 as id, 'Success' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
	  ELSE
	    -- delete failed
	    FOR rec IN (SELECT row_to_json(j) FROM(select $3 as id, 'Error: Activity was not successfully deleted.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
	  END IF;
        ELSE
          FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: User does NOT have authority to delete this activity.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
        END IF;
      -- validate users authority to 'update' this activity
      ELSE        
        IF NOT (SELECT * FROM pmt_validate_user_authority($1, $2, $3, null, 'update')) THEN   
          FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: User does NOT have authority to update this activity.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
        END IF;
      END IF;
    ELSE
      FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: Invalid activity_id.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
    END IF;
  END IF;

  -- assign the activity_id to use in statements
  IF new_activity_id IS NOT NULL THEN
    a_id := new_activity_id;
  ELSE
    a_id := $3;
  END IF;
    
  -- loop through the columns of the activity table        
  FOR json IN (SELECT * FROM json_each_text($5)) LOOP
    RAISE NOTICE 'JSON key/value: %', lower(json.key) || ':' || json.value;
    -- get the column information for column that user is requesting to edit	
    FOR column_record IN (SELECT * FROM information_schema.columns WHERE table_schema='public' AND table_name='activity' AND column_name != ALL(invalid_editing_columns) AND lower(column_name) = lower(json.key)) LOOP 
      RAISE NOTICE 'Editing column: %', column_record.column_name;
      RAISE NOTICE 'Assigning new value: %', json.value;
      execute_statement := null;
      CASE column_record.data_type 
        WHEN 'integer', 'numeric' THEN              
          IF (SELECT pmt_isnumeric(json.value)) THEN
            execute_statement := 'UPDATE activity SET ' || column_record.column_name || ' = ' || json.value || ' WHERE id = ' || a_id; 
          END IF;
          IF (lower(json.value) = 'null') THEN
            execute_statement := 'UPDATE activity SET ' || column_record.column_name || ' = null WHERE id = ' || a_id; 
          END IF;
        ELSE
          -- if the value has the text null then assign the column value null
          IF (lower(json.value) = 'null') THEN
            execute_statement := 'UPDATE activity SET ' || column_record.column_name || ' = null WHERE id = ' || a_id; 
          ELSE
            execute_statement := 'UPDATE activity SET ' || column_record.column_name || ' = ' || quote_literal(json.value) || ' WHERE id = ' || a_id; 
          END IF;
      END CASE;
      IF execute_statement IS NOT NULL THEN
        RAISE NOTICE 'Statement: %', execute_statement;
        EXECUTE execute_statement;
                
        EXECUTE 'UPDATE activity SET _updated_by = ' || quote_literal(username) || ', _updated_date = ' || quote_literal(current_date) || ' WHERE  id = ' || a_id;
      END IF;
    END LOOP;
  END LOOP;
  -- editing completed successfullly
  FOR rec IN (SELECT row_to_json(j) FROM(select a_id as id, 'Success' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;         
  
EXCEPTION WHEN others THEN
  GET STACKED DIAGNOSTICS error_msg1 = MESSAGE_TEXT;
  FOR rec IN (SELECT row_to_json(j) FROM(select a_id as id, 'Internal Error - Contact your DBA with the following error message: ' || error_msg1 as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;	  

END;$$ LANGUAGE plpgsql;


-- update permissions
GRANT USAGE ON SCHEMA public TO pmt_read;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO pmt_read;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO pmt_read;
GRANT USAGE ON SCHEMA public TO pmt_write;
GRANT SELECT,INSERT ON ALL TABLES IN SCHEMA public TO pmt_write;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO pmt_write;