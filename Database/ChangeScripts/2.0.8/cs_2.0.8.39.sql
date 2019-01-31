/******************************************************************
Change Script 2.0.8.39 - consolidated.
1. pmt_edit_project - new function for editing a project.
******************************************************************/
INSERT INTO version(version, iteration, changeset) VALUES (2.0, 8, 39);
-- select * from version order by changeset desc;

DROP FUNCTION IF EXISTS pmt_edit_project(integer, integer, json, boolean)  CASCADE;

-- select * from project where project_id = 1;
-- select * from pmt_edit_project(3,1,'{"label": "null", "url":"null"}', false);
-- select * from pmt_edit_project(3,null,'{"title": "testing", "url":"www.google.com"}', false);

/******************************************************************
   pmt_edit_project
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_edit_project(user_id integer, project_id integer, key_value_data json, delete_record boolean default false) RETURNS SETOF pmt_json_result_type AS 
$$
DECLARE
  new_project_id integer;
  p_id integer;
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
  invalid_editing_columns := ARRAY['project_id', 'active', 'retired_by', 'created_by', 'created_date', 'updated_by', 'updated_date'];
  
  -- user and data parameters are required
  IF ($1 IS NOT NULL) THEN
    IF NOT ($4) AND ($3 IS NULL) THEN
      FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: Must included json parameter when delete_record is false.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
    END IF;
  ELSE
    FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: Must included user_id parameter.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
  END IF; 

  -- get users name
  SELECT INTO user_name username FROM "user" WHERE "user".user_id = $1;

  -- if project_id is null then validate users authroity to create a new project record  
  IF ($2 IS NULL) THEN
    IF (SELECT * FROM pmt_validate_user_authority($1, null, 'create')) THEN
      EXECUTE 'INSERT INTO project(created_by, updated_by) VALUES (' || quote_literal(user_name) || ',' || quote_literal(user_name) || ') RETURNING project_id;' INTO new_project_id;
      RAISE NOTICE 'Created new project with id: %', new_project_id;
    ELSE
      FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: User does NOT have authority to create a new project.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
    END IF;
  -- validate project_id if provided and validate users authority to update an existing record  
  ELSE
    -- validate project_id
    IF (SELECT * FROM pmt_validate_project($2)) THEN 
      -- validate users authority to 'delete' this project
      IF ($4) THEN
        IF (SELECT * FROM pmt_validate_user_authority($1, $2, 'delete')) THEN
        -- deactivate this project          
          FOR rec IN (SELECT * FROM pmt_activate_project($1, $2, false)) LOOP  RETURN NEXT rec; END LOOP; RETURN;
        ELSE
          FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: User does NOT have authority to delete this project.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
        END IF;
      -- validate users authority to 'update' this activity
      ELSE        
        IF (SELECT * FROM pmt_validate_user_authority($1, $2, 'update')) THEN   
        ELSE
          FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: User does NOT have authority to update this project.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
        END IF;
      END IF;
    ELSE
      FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: Invalid project_id.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
    END IF;
  END IF;

  -- assign the project_id to use in statements
  IF new_project_id IS NOT NULL THEN
    p_id := new_project_id;
  ELSE
    p_id := $2;
  END IF;
    
  -- loop through the columns of the contact table        
  FOR json IN (SELECT * FROM json_each_text($3)) LOOP
    RAISE NOTICE 'JSON key/value: %', lower(json.key) || ':' || json.value;
    -- get the column information for column that user is requesting to edit	
    FOR column_record IN (SELECT * FROM information_schema.columns WHERE table_schema='public' AND table_name='project' AND column_name != ALL(invalid_editing_columns) AND lower(column_name) = lower(json.key)) LOOP 
      RAISE NOTICE 'Editing column: %', column_record.column_name;
      RAISE NOTICE 'Assigning new value: %', json.value;
      execute_statement := null;
      CASE column_record.data_type 
        WHEN 'integer', 'numeric' THEN              
          IF (SELECT pmt_isnumeric(json.value)) THEN
            execute_statement := 'UPDATE project SET ' || column_record.column_name || ' = ' || json.value || ' WHERE project_id = ' || p_id; 
          END IF;
          IF (lower(json.value) = 'null') THEN
            execute_statement := 'UPDATE project SET ' || column_record.column_name || ' = null WHERE project_id = ' || p_id; 
          END IF;
        ELSE
          -- if the value has the text null then assign the column value null
          IF (lower(json.value) = 'null') THEN
            execute_statement := 'UPDATE project SET ' || column_record.column_name || ' = null WHERE project_id = ' || p_id; 
          ELSE
            execute_statement := 'UPDATE project SET ' || column_record.column_name || ' = ' || quote_literal(json.value) || ' WHERE project_id = ' || p_id; 
          END IF;
      END CASE;
      IF execute_statement IS NOT NULL THEN
        RAISE NOTICE 'Statement: %', execute_statement;
        EXECUTE execute_statement;
                
        EXECUTE 'UPDATE project SET updated_by = ' || quote_literal(user_name) || ', updated_date = ' || quote_literal(current_date) || ' WHERE  project_id = ' || p_id;
      END IF;
    END LOOP;
  END LOOP;
  -- editing completed successfullly
  FOR rec IN (SELECT row_to_json(j) FROM(select p_id as id, 'Success' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;         
  
EXCEPTION WHEN others THEN
     GET STACKED DIAGNOSTICS error_msg1 = MESSAGE_TEXT,
                          error_msg2 = PG_EXCEPTION_DETAIL,
                          error_msg3 = PG_EXCEPTION_HINT;
    FOR rec IN (SELECT row_to_json(j) FROM(select p_id as id, 'Internal Error - Contact your DBA with the following error message: ' || error_msg1 as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;	  
END;$$ LANGUAGE plpgsql;

-- update permissions
GRANT USAGE ON SCHEMA public TO pmt_read;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO pmt_read;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO pmt_read;
GRANT USAGE ON SCHEMA public TO pmt_write;
GRANT SELECT,INSERT ON ALL TABLES IN SCHEMA public TO pmt_write;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO pmt_write;