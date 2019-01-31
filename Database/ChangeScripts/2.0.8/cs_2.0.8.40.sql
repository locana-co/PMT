/******************************************************************
Change Script 2.0.8.40 - consolidated.
1. pmt_edit_detail - new function for editing a detail
2. pmt_validate_detail - new function for validating a detail id.
******************************************************************/
INSERT INTO version(version, iteration, changeset) VALUES (2.0, 8, 40);
-- select * from version order by changeset desc;

DROP FUNCTION IF EXISTS pmt_edit_detail(integer, integer, integer, integer, json, boolean)  CASCADE;
DROP FUNCTION IF EXISTS pmt_validate_detail(integer)  CASCADE;

-- select * from detail where project_id = 3;

-- select * from pmt_edit_detail(3,1,null,null,'{"title": "Description of Activities Related to Nutrition"}', false);
-- select * from pmt_edit_detail(3,null,3,null,'{"title": "Test Title", "description":"a description", "amount":3}', false);
-- select * from pmt_edit_detail(34,null,493,2245,'{"title": "Test Title", "description":"a description", "amount":3}', false);
-- select * from pmt_edit_detail(3,1,null,null,null, true);

/******************************************************************
  pmt_validate_detail
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_validate_detail(id integer) RETURNS boolean AS $$
DECLARE valid_id integer;
BEGIN 
     IF $1 IS NULL THEN    
       RETURN false;
     END IF;    
     
     SELECT INTO valid_id detail_id FROM detail WHERE active = true AND detail_id = $1;	 

     IF valid_id IS NULL THEN
      RETURN false;
     ELSE 
      RETURN true;
     END IF;
     
EXCEPTION WHEN others THEN
    RETURN FALSE;
END; 
$$ LANGUAGE 'plpgsql';
/******************************************************************
   pmt_edit_detail
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_edit_detail(user_id integer, detail_id integer, project_id integer, activity_id integer, key_value_data json, delete_record boolean default false) 
RETURNS SETOF pmt_json_result_type AS 
$$
DECLARE
  new_detail_id integer;
  p_id integer;
  a_id integer;
  d_id integer;
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
  invalid_editing_columns := ARRAY['detail_id', 'project_id', 'activity_id', 'active', 'retired_by', 'created_by', 'created_date', 'updated_by', 'updated_date'];
  
  -- validate required parameters
  -- user_id always required
  IF ($1 IS NOT NULL) THEN
    -- if delete_record = false then json is required
    IF NOT ($6) AND ($5 IS NULL) THEN
      FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: Must included json parameter when delete_record is false.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
    ELSE
      IF ($2 IS NULL) AND ($6) THEN
        FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: Must included detail_id when delete_record is true.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
      END IF;
    END IF;
    -- must supply a detail_id, a project_id or activity_id
    IF ($2 IS NULL) AND ($3 IS NULL) AND ($4 IS NULL) THEN
      FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: Must included project_id or activity_id parameter when detail_id parameter is null.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
    END IF;
  ELSE
    FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: Must included user_id parameter.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
  END IF; 

  -- get users name
  SELECT INTO user_name username FROM "user" WHERE "user".user_id = $1;

  -- if detail_id is null then validate users authroity to create a new detail record  
  IF ($2 IS NULL) THEN
  
    -- validate the associated project/activity records
    IF ($3 IS NOT NULL) THEN
      IF (SELECT * FROM pmt_validate_project($3)) THEN  
        p_id := $3;
      ELSE
        FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: Invalid project_id.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
      END IF;      
    END IF;
    
    IF ($4 IS NOT NULL) THEN
        IF (SELECT * FROM pmt_validate_activity($4)) THEN  
          a_id := $4;
          SELECT INTO p_id a.project_id FROM activity a WHERE a.activity_id = $4;
        ELSE
          FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: Invalid activity_id.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
        END IF;
    END IF; 

    IF p_id IS NOT NULL THEN
      IF (SELECT * FROM pmt_validate_user_authority($1, p_id, 'create')) THEN
        IF a_id IS NOT NULL THEN
          EXECUTE 'INSERT INTO detail(project_id, activity_id, created_by, updated_by) VALUES (' || p_id  || ',' || a_id || ',' || quote_literal(user_name) || ',' 
		|| quote_literal(user_name) || ') RETURNING detail_id;' INTO new_detail_id;
        ELSE
          EXECUTE 'INSERT INTO detail(project_id, created_by, updated_by) VALUES (' || p_id  || ',' || quote_literal(user_name) || ',' 
		|| quote_literal(user_name) || ') RETURNING detail_id;' INTO new_detail_id;
        END IF;
        
        RAISE NOTICE 'Created new detail with id: %', new_detail_id;
      ELSE
        FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: User does NOT have authority to create a new detail record for project id ' || p_id as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
      END IF;
    ELSE
      FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: Must provide a valid project_id.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
    END IF;
    
  -- validate detail_id if provided and validate users authority to update an existing record  
  ELSE  
    -- validate detail_id
    IF (SELECT * FROM pmt_validate_detail($2)) THEN 
      -- get project_id from detail record
      SELECT INTO p_id d.project_id FROM detail d WHERE d.detail_id = $2;      
      -- validate users authority to 'delete' this detail
      IF ($6) THEN
        IF (SELECT * FROM pmt_validate_user_authority($1, p_id, 'delete')) THEN
          -- deactivate this detail 
          EXECUTE 'UPDATE detail SET active = false WHERE detail_id = ' || $2;
        ELSE
          FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: User does NOT have authority to delete this detail for project id ' || p_id  as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
        END IF;
      -- validate users authority to 'update' this activity
      ELSE        
        IF (SELECT * FROM pmt_validate_user_authority($1, p_id, 'update')) THEN   
        ELSE
          FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: User does NOT have authority to update this project.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
        END IF;
      END IF;
    ELSE
      FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: Invalid detail_id.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
    END IF;
  END IF;

  -- assign the project_id to use in statements
  IF new_detail_id IS NOT NULL THEN
    d_id := new_detail_id;
  ELSE
    d_id := $2;
  END IF;
    
  -- loop through the columns of the detail table        
  FOR json IN (SELECT * FROM json_each_text($5)) LOOP
    RAISE NOTICE 'JSON key/value: %', lower(json.key) || ':' || json.value;
    -- get the column information for column that user is requesting to edit	
    FOR column_record IN (SELECT * FROM information_schema.columns WHERE table_schema='public' AND table_name='detail' AND column_name != ALL(invalid_editing_columns) AND lower(column_name) = lower(json.key)) LOOP 
      RAISE NOTICE 'Editing column: %', column_record.column_name;
      RAISE NOTICE 'Assigning new value: %', json.value;
      execute_statement := null;
      CASE column_record.data_type 
        WHEN 'integer', 'numeric' THEN              
          IF (SELECT pmt_isnumeric(json.value)) THEN
            execute_statement := 'UPDATE detail SET ' || column_record.column_name || ' = ' || json.value || ' WHERE detail_id = ' || d_id; 
          END IF;
          IF (lower(json.value) = 'null') THEN
            execute_statement := 'UPDATE detail SET ' || column_record.column_name || ' = null WHERE detail_id = ' || d_id; 
          END IF;
        ELSE
          -- if the value has the text null then assign the column value null
          IF (lower(json.value) = 'null') THEN
            execute_statement := 'UPDATE detail SET ' || column_record.column_name || ' = null WHERE detail_id = ' || d_id; 
          ELSE
            execute_statement := 'UPDATE detail SET ' || column_record.column_name || ' = ' || quote_literal(json.value) || ' WHERE detail_id = ' || d_id; 
          END IF;
      END CASE;
      IF execute_statement IS NOT NULL THEN
        RAISE NOTICE 'Statement: %', execute_statement;
        EXECUTE execute_statement;
                
        EXECUTE 'UPDATE detail SET updated_by = ' || quote_literal(user_name) || ', updated_date = ' || quote_literal(current_date) || ' WHERE  detail_id = ' || d_id;
      END IF;
    END LOOP;
  END LOOP;
  -- editing completed successfullly
  FOR rec IN (SELECT row_to_json(j) FROM(select d_id as id, 'Success' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;         
  
EXCEPTION WHEN others THEN
     GET STACKED DIAGNOSTICS error_msg1 = MESSAGE_TEXT,
                          error_msg2 = PG_EXCEPTION_DETAIL,
                          error_msg3 = PG_EXCEPTION_HINT;
    FOR rec IN (SELECT row_to_json(j) FROM(select d_id as id, 'Internal Error - Contact your DBA with the following error message: ' || error_msg1 as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;	  
END;$$ LANGUAGE plpgsql;

-- update permissions
GRANT USAGE ON SCHEMA public TO pmt_read;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO pmt_read;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO pmt_read;
GRANT USAGE ON SCHEMA public TO pmt_write;
GRANT SELECT,INSERT ON ALL TABLES IN SCHEMA public TO pmt_write;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO pmt_write;