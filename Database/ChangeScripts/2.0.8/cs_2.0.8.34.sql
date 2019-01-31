/******************************************************************
Change Script 2.0.8.34 - consolidated.
1. pmt_edit_activity - update to allow deletion and to return id 
and message values.
2. pmt_activate_activity -  new function for activating/deactivating
an activity and its related records.
3. pmt_activate_project -  new function for activating/deactivating
a project and its related records.
******************************************************************/
INSERT INTO version(version, iteration, changeset) VALUES (2.0, 8, 34);
-- select * from version order by changeset desc;

-- testing
-- select * from activity where activity_id in (11850, 15820, 15821);
-- select * from pmt_edit_activity(34, 11850, 749, '{"Label": "test"}', false); -- update
-- select * from pmt_edit_activity(34, 11850, 749, '{"Label": "null"}', false); -- update
-- select * from pmt_edit_activity(34, null, 749, '{"title": "test"}', false); -- create
-- select * from pmt_edit_activity(34, 15820, null, null, true); -- delete (ID FROM CREATE)
-- select * from pmt_edit_activity(34, 11850, 749, null, false); -- "Error: the json parameter is required for a create/update operation."
-- select * from pmt_edit_activity(null, 11850, 749, null, false); -- "Error: user_id is a required parameter for all operations."
-- select * from pmt_edit_activity(34, null, 749, null, true); -- "Error: activity_id is required for a delete operation."
-- select * from pmt_edit_activity(34, null, null, '{"title": "test"}', false); -- "Error: project_id is required for a create operation."

-- select 'p', project_id, 0, 0, active, updated_by, updated_date from project where project_id = 402 
-- UNION ALL 
-- select 'a', project_id, activity_id, 0, active, updated_by, updated_date from activity where project_id = 402 
-- UNION ALL 
-- select 'l', project_id, activity_id, location_id, active, updated_by, updated_date from location where project_id = 402 
-- UNION ALL
-- select 'pp', project_id, activity_id, participation_id, active, updated_by, updated_date from participation where project_id = 402
-- UNION ALL
-- select 'f', project_id, activity_id, financial_id, active, updated_by, updated_date from financial where project_id = 402
-- UNION ALL
-- select 'd', project_id, activity_id, detail_id, active, updated_by, updated_date from detail where project_id = 402
-- UNION ALL
-- select 'r', 0, activity_id, result_id, active, updated_by, updated_date from result where project_id = 402;

-- select * from pmt_activate_activity(34, 15820, true);
-- select * from pmt_activate_project(34, 402, false);


-- old drop statement
DROP FUNCTION IF EXISTS pmt_edit_activity(integer, integer, json)  CASCADE;
-- new drop statement
DROP FUNCTION IF EXISTS pmt_activate_activity(integer, integer, boolean)  CASCADE;
DROP FUNCTION IF EXISTS pmt_activate_project(integer, integer, boolean)  CASCADE;
DROP FUNCTION IF EXISTS pmt_edit_activity(integer, integer, json, boolean)  CASCADE;

-- update to function
CREATE OR REPLACE FUNCTION pmt_edit_activity(user_id integer, activity_id integer, project_id integer, key_value_data json, delete_record boolean default false) RETURNS SETOF pmt_json_result_type AS 
$$
DECLARE
  new_activity_id integer;
  p_id integer;
  a_id integer;
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
  invalid_editing_columns := ARRAY['activity_id','project_id', 'active', 'retired_by', 'created_by', 'created_date', 'updated_by', 'updated_date'];
  
  -- user_id is required for all operations
  IF ($1 IS NOT NULL) THEN
    -- update/create operation
    IF NOT ($5) THEN
      -- json is required
      IF ($4 IS NULL) THEN
        FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: The json parameter is required for a create/update operation.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
      END IF;
      -- project_id is required if activity_id is null
      IF ($2 IS NULL) AND ($3 IS NULL) THEN
        FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: project_id is required for a create operation.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
      END IF;
    -- delete operation	
    ELSE
      -- activity_id is requried
      IF ($2 IS NULL) THEN
        FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: activity_id is required for a delete operation.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
      END IF;
    END IF;
  -- error if user_id    
  ELSE
    FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: user_id is a required parameter for all operations.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
  END IF; 

  -- get users name
  SELECT INTO user_name username FROM "user" WHERE "user".user_id = $1;

  -- if activity_id is null then validate users authroity to create a new activity record  
  IF ($2 IS NULL) THEN
    -- validate project_id
    IF (SELECT * FROM pmt_validate_project($3)) THEN       
      IF (SELECT * FROM pmt_validate_user_authority($1, $3, 'create')) THEN
        EXECUTE 'INSERT INTO activity(project_id, created_by, updated_by) VALUES (' || $3 || ',' || quote_literal(user_name) || ',' || quote_literal(user_name) || ') RETURNING activity_id;' INTO new_activity_id;
        RAISE NOTICE 'Created new activity with id: %', new_activity_id;
      ELSE
        FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: User does NOT have authority to create a new activity for project_id: ' || $3 as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
      END IF;
    ELSE
      FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: project_id is not valid.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
    END IF;
  -- validate activity_id if provided and validate users authority to update an existing record  
  ELSE
    -- get project_id for activity
    SELECT INTO p_id activity.project_id FROM activity WHERE activity.activity_id = $2;      
    -- validate activity_id
    IF (SELECT * FROM pmt_validate_activity($2)) THEN 
      -- validate users authority to 'delete' this activity
      IF ($5) THEN
        IF (SELECT * FROM pmt_validate_user_authority($1, p_id, 'delete')) THEN
        -- deactivate this activity          
          FOR rec IN (SELECT * FROM pmt_activate_activity($1, $2, false)) LOOP  RETURN NEXT rec; END LOOP; RETURN;
        ELSE
          FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: User does NOT have authority to delete this activity.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
        END IF;
      -- validate users authority to 'update' this activity
      ELSE        
        IF (SELECT * FROM pmt_validate_user_authority($1, p_id, 'update')) THEN   
        ELSE
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
    a_id := $2;
  END IF;
    
  -- loop through the columns of the activity table        
  FOR json IN (SELECT * FROM json_each_text($4)) LOOP
    RAISE NOTICE 'JSON key/value: %', lower(json.key) || ':' || json.value;
    -- get the column information for column that user is requesting to edit	
    FOR column_record IN (SELECT * FROM information_schema.columns WHERE table_schema='public' AND table_name='activity' AND column_name != ALL(invalid_editing_columns) AND lower(column_name) = lower(json.key)) LOOP 
      RAISE NOTICE 'Editing column: %', column_record.column_name;
      RAISE NOTICE 'Assigning new value: %', json.value;
      execute_statement := null;
      CASE column_record.data_type 
        WHEN 'integer', 'numeric' THEN              
          IF (SELECT pmt_isnumeric(json.value)) THEN
            execute_statement := 'UPDATE activity SET ' || column_record.column_name || ' = ' || json.value || ' WHERE activity_id = ' || a_id; 
          END IF;
          IF (lower(json.value) = 'null') THEN
            execute_statement := 'UPDATE activity SET ' || column_record.column_name || ' = null WHERE activity_id = ' || a_id; 
          END IF;
        ELSE
          -- if the value has the text null then assign the column value null
          IF (lower(json.value) = 'null') THEN
            execute_statement := 'UPDATE activity SET ' || column_record.column_name || ' = null WHERE activity_id = ' || a_id; 
          ELSE
            execute_statement := 'UPDATE activity SET ' || column_record.column_name || ' = ' || quote_literal(json.value) || ' WHERE activity_id = ' || a_id; 
          END IF;
      END CASE;
      IF execute_statement IS NOT NULL THEN
        RAISE NOTICE 'Statement: %', execute_statement;
        EXECUTE execute_statement;
                
        EXECUTE 'UPDATE activity SET updated_by = ' || quote_literal(user_name) || ', updated_date = ' || quote_literal(current_date) || ' WHERE  activity_id = ' || a_id;
      END IF;
    END LOOP;
  END LOOP;
  -- editing completed successfullly
  FOR rec IN (SELECT row_to_json(j) FROM(select a_id as id, 'Success' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;         
  
EXCEPTION WHEN others THEN
     GET STACKED DIAGNOSTICS error_msg1 = MESSAGE_TEXT,
                          error_msg2 = PG_EXCEPTION_DETAIL,
                          error_msg3 = PG_EXCEPTION_HINT;
    FOR rec IN (SELECT row_to_json(j) FROM(select a_id as id, 'Internal Error - Contact your DBA with the following error message: ' || error_msg1 as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;	  
END;$$ LANGUAGE plpgsql;

/******************************************************************
  pmt_activate_activity
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_activate_activity(user_id integer, activity_id integer, activate boolean default true) RETURNS SETOF pmt_json_result_type AS  $$
DECLARE
  p_id integer;
  user_name text;
  rec record;
  error_msg1 text;
  error_msg2 text;
  error_msg3 text; 
BEGIN 
  -- user and activity_id parameters are required
  IF ($1 IS NOT NULL) AND ($2 IS NOT NULL) THEN
    -- get users name
    SELECT INTO user_name username FROM "user" WHERE "user".user_id = $1;
  ELSE
    FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: Must included user_id and activity_id data parameters.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
  END IF; 

  -- get project_id for activity
  SELECT INTO p_id project_id FROM activity WHERE activity.activity_id = $2;   

  -- validate activity_id
  IF p_id IS NOT NULL THEN  
    -- user must have 'delete' privilages to change active values
    IF (SELECT * FROM pmt_validate_user_authority($1, p_id, 'delete')) THEN
      -- set active values as requested       
      EXECUTE 'UPDATE activity SET active = ' || $3 || ', updated_by =' || quote_literal(user_name) || ', updated_date = ' || quote_literal(current_date) || ' WHERE activity.activity_id = ' || $2 || ';';
      EXECUTE 'UPDATE location SET active = ' || $3 || ', updated_by =' || quote_literal(user_name) || ', updated_date = ' || quote_literal(current_date) || ' WHERE location.activity_id = ' || $2 || ';';
      EXECUTE 'UPDATE financial SET active = ' || $3 || ', updated_by =' || quote_literal(user_name) || ', updated_date = ' || quote_literal(current_date) || ' WHERE financial.activity_id = ' || $2 || ';';
      EXECUTE 'UPDATE participation SET active = ' || $3 || ', updated_by =' || quote_literal(user_name) || ', updated_date = ' || quote_literal(current_date) || ' WHERE participation.activity_id = ' || $2 || ';';
      EXECUTE 'UPDATE detail SET active = ' || $3 || ', updated_by =' || quote_literal(user_name) || ', updated_date = ' || quote_literal(current_date) || ' WHERE detail.activity_id = ' || $2 || ';';
      EXECUTE 'UPDATE result SET active = ' || $3 || ', updated_by =' || quote_literal(user_name) || ', updated_date = ' || quote_literal(current_date) || ' WHERE result.activity_id = ' || $2 || ';';
    ELSE
      FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: User does NOT have authority to change the active status of this activity and its assoicated records.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
    END IF;
  ELSE
    FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: Invalid activity_id.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
  END IF;

   -- editing completed successfullly
  FOR rec IN (SELECT row_to_json(j) FROM(select $2 as id, 'Success' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;        
    	  
EXCEPTION WHEN others THEN
      GET STACKED DIAGNOSTICS error_msg1 = MESSAGE_TEXT,
                          error_msg2 = PG_EXCEPTION_DETAIL,
                          error_msg3 = PG_EXCEPTION_HINT;
    FOR rec IN (SELECT row_to_json(j) FROM(select $2 as id, 'Internal Error - Contact your DBA with the following error message: ' || error_msg1 as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;	 
END; 
$$ LANGUAGE 'plpgsql';

/******************************************************************
  pmt_activate_project
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_activate_project(user_id integer, project_id integer, activate boolean default true) RETURNS SETOF pmt_json_result_type AS  $$
DECLARE
  p_id integer;
  user_name text;
  rec record;
  error_msg1 text;
  error_msg2 text;
  error_msg3 text; 
BEGIN 
  -- user and activity_id parameters are required
  IF ($1 IS NOT NULL) AND ($2 IS NOT NULL) THEN
    -- get users name
    SELECT INTO user_name username FROM "user" WHERE "user".user_id = $1;
  ELSE
    FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: Must included user_id and project_id data parameters.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
  END IF; 

  -- user must have 'delete' privilages to change active values
  IF (SELECT * FROM pmt_validate_user_authority($1, p_id, 'delete')) THEN
    -- set active values as requested       
    EXECUTE 'UPDATE project SET active = ' || $3 || ', updated_by =' || quote_literal(user_name) || ', updated_date = ' || quote_literal(current_date) || ' WHERE project.project_id = ' || $2 || ';';
    EXECUTE 'UPDATE activity SET active = ' || $3 || ', updated_by =' || quote_literal(user_name) || ', updated_date = ' || quote_literal(current_date) || ' WHERE activity.project_id = ' || $2 || ';';
    EXECUTE 'UPDATE location SET active = ' || $3 || ', updated_by =' || quote_literal(user_name) || ', updated_date = ' || quote_literal(current_date) || ' WHERE location.project_id = ' || $2 || ';';
    EXECUTE 'UPDATE financial SET active = ' || $3 || ', updated_by =' || quote_literal(user_name) || ', updated_date = ' || quote_literal(current_date) || ' WHERE financial.project_id = ' || $2 || ';';
    EXECUTE 'UPDATE participation SET active = ' || $3 || ', updated_by =' || quote_literal(user_name) || ', updated_date = ' || quote_literal(current_date) || ' WHERE participation.project_id = ' || $2 || ';';
    EXECUTE 'UPDATE detail SET active = ' || $3 || ', updated_by =' || quote_literal(user_name) || ', updated_date = ' || quote_literal(current_date) || ' WHERE detail.project_id = ' || $2 || ';';    
  ELSE
    FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: User does NOT have authority to change the active status of this project and its assoicated records.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
  END IF;

   -- editing completed successfullly
  FOR rec IN (SELECT row_to_json(j) FROM(select $2 as id, 'Success' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;        
    	  
EXCEPTION WHEN others THEN
      GET STACKED DIAGNOSTICS error_msg1 = MESSAGE_TEXT,
                          error_msg2 = PG_EXCEPTION_DETAIL,
                          error_msg3 = PG_EXCEPTION_HINT;
    FOR rec IN (SELECT row_to_json(j) FROM(select $2 as id, 'Internal Error - Contact your DBA with the following error message: ' || error_msg1 as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;	 
END;
$$ LANGUAGE 'plpgsql';

-- update permissions
GRANT USAGE ON SCHEMA public TO pmt_read;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO pmt_read;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO pmt_read;
GRANT USAGE ON SCHEMA public TO pmt_write;
GRANT SELECT,INSERT ON ALL TABLES IN SCHEMA public TO pmt_write;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO pmt_write;