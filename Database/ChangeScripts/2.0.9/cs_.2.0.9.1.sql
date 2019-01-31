/******************************************************************
Change Script 2.0.9.1
1. pmt_clone_activity - new function for cloning an activity.
******************************************************************/
INSERT INTO version(version, iteration, changeset) VALUES (2.0, 9, 1);
-- select * from version order by iteration desc, changeset desc;

DROP FUNCTION IF EXISTS pmt_clone_activity(integer, integer, integer, json);

-- SELECT * FROM pmt_clone_activity(34, 15795, NULL, '{"title": "testing title update", "description":"testing description update"}');

-- select * from financial where activity_id in (15795,23524)
-- select * from activity_taxonomy where activity_id in (15795,23524) order by 2
-- select * from activity_contact where activity_id in (15795,23524)
-- select * from participation  where activity_id in (15795,23524)
-- select * from participation_taxonomy where participation_id in (select participation_id from participation  where activity_id in (15795,23524))

-- SELECT * FROM pmt_clone_activity(4, 44, null, null);
-- select * from activity order by activity_id desc
-- select * from pmt_purge_activity(23524)

CREATE OR REPLACE FUNCTION pmt_clone_activity(user_id integer, activity_id integer, project_id integer, key_value_data json) RETURNS SETOF pmt_json_result_type AS 
$$
DECLARE
  new_activity_id integer;  
  new_record_id integer;
  p_id integer;
  column_names text;
  user_name text;
  column_record record;
  original_record record;
  taxonomy_record record;
  invalid_editing_columns text[];  
  json record;  
  execute_statement text; 
  rec record;
  error_msg1 text;
  error_msg2 text;
  error_msg3 text;
BEGIN	
  -- set columns that are not editable via the parameters 
  invalid_editing_columns := ARRAY['activity_id','project_id', 'active', 'retired_by', 'created_by', 'created_date', 'updated_by', 'updated_date'];
  
  -- user_id and activity_id are required for all operations
  IF ($1 IS NULL) OR ($2 IS NULL) THEN    
    FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: user_id and activity_id are required parameters for all operations.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
  END IF; 

  -- get users name
  SELECT INTO user_name username FROM "user" WHERE "user".user_id = $1;

  -- validate user
  IF ((SELECT * FROM pmt_validate_user($1)) = false) THEN
    FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: Invalid user_id.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
  END IF;

  -- validate activity
  IF ((SELECT * FROM pmt_validate_activity($2)) = false) THEN
    FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: Invalid activity_id.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
  END IF;

  -- validate project 
  IF ($3 IS NOT NULL) THEN
    IF ((SELECT * FROM pmt_validate_project($3)) = false) THEN
      FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: Invalid project_id.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
    ELSE
      p_id := $3;
    END IF;
  ELSE
    SELECT INTO p_id a.project_id FROM activity a WHERE a.activity_id = $2;
  END IF;

  -- validate users authority to create new activity on project
  IF (SELECT * FROM pmt_validate_user_authority($1, p_id, 'create')) THEN    
    -- get the column names to clone
    column_names := ', ';
    FOR column_record IN (SELECT * FROM information_schema.columns WHERE table_schema='public' AND table_name='activity' AND column_name != ALL(invalid_editing_columns)) LOOP 
      column_names := column_names || column_record.column_name || ', ';
    END LOOP;

    -- clone activity
    execute_statement := 'INSERT INTO activity (project_id' || column_names || 'created_by, updated_by) (SELECT ' || p_id ||  column_names ||  quote_literal(user_name) || ',' || 
	quote_literal(user_name) || ' FROM activity WHERE activity.activity_id = ' || $2 || ')  RETURNING activity_id;';
    -- RAISE NOTICE 'Statement: %', execute_statement;
    EXECUTE execute_statement INTO new_activity_id;
    
    -- update new activity based on provided json
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
              execute_statement := 'UPDATE activity SET ' || column_record.column_name || ' = ' || json.value || ' WHERE activity_id = ' || new_activity_id; 
            END IF;
            IF (lower(json.value) = 'null') THEN
              execute_statement := 'UPDATE activity SET ' || column_record.column_name || ' = null WHERE activity_id = ' || new_activity_id; 
            END IF;
          ELSE
            -- if the value has the text null then assign the column value null
            IF (lower(json.value) = 'null') THEN
              execute_statement := 'UPDATE activity SET ' || column_record.column_name || ' = null WHERE activity_id = ' || new_activity_id; 
            ELSE
              execute_statement := 'UPDATE activity SET ' || column_record.column_name || ' = ' || quote_literal(json.value) || ' WHERE activity_id = ' || new_activity_id; 
            END IF;
        END CASE;
        IF execute_statement IS NOT NULL THEN
          RAISE NOTICE 'Statement: %', execute_statement;
          EXECUTE execute_statement;                
        END IF;
      END LOOP;
    END LOOP;   

    -- loop through activity contacts and clone relationships
    FOR original_record IN (SELECT * FROM activity_contact ac WHERE ac.activity_id = $2) LOOP
      EXECUTE 'INSERT INTO activity_contact (activity_id, contact_id) VALUES ( ' || new_activity_id || ', ' || original_record.contact_id || ')';
    END LOOP;
    
    -- loop through activity taxonomy and clone relationships
    FOR original_record IN (SELECT * FROM activity_taxonomy at WHERE at.activity_id = $2) LOOP
      EXECUTE 'INSERT INTO activity_taxonomy (activity_id, classification_id, field) VALUES ( ' || new_activity_id || ', ' || original_record.classification_id || ', ''activity_id'')';
    END LOOP;
    
    -- loop through activity participation & its taxonomy records and clone
    FOR original_record IN (SELECT * FROM participation pp WHERE pp.activity_id = $2 AND pp.active = true) LOOP
      EXECUTE 'INSERT INTO participation (project_id, activity_id, organization_id, created_by, updated_by) VALUES ( ' || p_id || ', ' || new_activity_id || ', ' || 
		original_record.organization_id || ', ' ||  quote_literal(user_name) || ', ' ||  quote_literal(user_name) || ')  RETURNING participation_id;' INTO new_record_id;
      FOR taxonomy_record IN (SELECT * FROM participation_taxonomy ppt WHERE ppt.participation_id = original_record.participation_id) LOOP
        EXECUTE 'INSERT INTO participation_taxonomy (participation_id, classification_id, field) VALUES ( ' || new_record_id || ', ' || taxonomy_record.classification_id || ', ''participation_id'')';  
      END LOOP;	
    END LOOP;
    
    -- loop through financial & its taxonomy records and clone
    FOR original_record IN (SELECT * FROM financial f WHERE f.activity_id = $2 AND f.active = true) LOOP
      -- prepare to clone
      invalid_editing_columns := ARRAY['financial_id','project_id', 'activity_id', 'active', 'retired_by', 'created_by', 'created_date', 'updated_by', 'updated_date'];
      column_names := ', ';
      FOR column_record IN (SELECT * FROM information_schema.columns WHERE table_schema='public' AND table_name='financial' AND column_name != ALL(invalid_editing_columns)) LOOP 
        column_names := column_names || column_record.column_name || ', ';
      END LOOP;

      -- clone activity's financial record
      execute_statement := 'INSERT INTO financial (project_id, activity_id' || column_names || 'created_by, updated_by) (SELECT ' || p_id || ', ' || new_activity_id ||  
	column_names ||  quote_literal(user_name) || ',' || quote_literal(user_name) || ' FROM financial WHERE financial.financial_id = ' || original_record.financial_id || ')  RETURNING financial_id;';
      -- RAISE NOTICE 'Statement: %', execute_statement;
      EXECUTE execute_statement INTO new_record_id;
	-- clone activity's financial taxonomy record
      FOR taxonomy_record IN (SELECT * FROM financial_taxonomy ft WHERE ft.financial_id = original_record.financial_id) LOOP
        EXECUTE 'INSERT INTO financial_taxonomy (financial_id, classification_id, field) VALUES ( ' || new_record_id || ', ' || taxonomy_record.classification_id || ', ''financial_id'')';  
      END LOOP;	
    END LOOP;
      
    -- loop through result & its taxonomy records and clone
    FOR original_record IN (SELECT * FROM result r WHERE r.activity_id = $2 AND r.active = true) LOOP
      -- prepare to clone
      invalid_editing_columns := ARRAY['result_id','project_id', 'activity_id', 'active', 'retired_by', 'created_by', 'created_date', 'updated_by', 'updated_date'];
      column_names := ', ';
      FOR column_record IN (SELECT * FROM information_schema.columns WHERE table_schema='public' AND table_name='result' AND column_name != ALL(invalid_editing_columns)) LOOP 
        column_names := column_names || column_record.column_name || ', ';
      END LOOP;

      -- clone activity's result record
      execute_statement := 'INSERT INTO result (project_id, activity_id' || column_names || 'created_by, updated_by) (SELECT ' || p_id || ', ' || new_activity_id ||  
	column_names ||  quote_literal(user_name) || ',' || quote_literal(user_name) || ' FROM result WHERE result.result_id = ' || original_record.result_id || ')  RETURNING result_id;';
      -- RAISE NOTICE 'Statement: %', execute_statement;
      EXECUTE execute_statement INTO new_record_id;
	-- clone activity's result taxonomy record
      FOR taxonomy_record IN (SELECT * FROM result_taxonomy rt WHERE rt.result_id = original_record.result_id) LOOP
        EXECUTE 'INSERT INTO result_taxonomy (result_id, classification_id, field) VALUES ( ' || new_record_id || ', ' || taxonomy_record.classification_id || ', ''result_id'')';  
      END LOOP;	
    END LOOP;

    -- loop through detail & its taxonomy records and clone
    FOR original_record IN (SELECT * FROM detail d WHERE d.activity_id = $2 AND d.active = true) LOOP
      -- prepare to clone
      invalid_editing_columns := ARRAY['detail_id','project_id', 'activity_id', 'active', 'retired_by', 'created_by', 'created_date', 'updated_by', 'updated_date'];
      column_names := ', ';
      FOR column_record IN (SELECT * FROM information_schema.columns WHERE table_schema='public' AND table_name='detail' AND column_name != ALL(invalid_editing_columns)) LOOP 
        column_names := column_names || column_record.column_name || ', ';
      END LOOP;

      -- clone activity's detail record
      execute_statement := 'INSERT INTO detail (project_id, activity_id' || column_names || 'created_by, updated_by) (SELECT ' || p_id || ', ' || new_activity_id ||  
	column_names ||  quote_literal(user_name) || ',' || quote_literal(user_name) || ' FROM detail WHERE detail.detail_id = ' || original_record.detail_id || ')  RETURNING detail_id;';
      -- RAISE NOTICE 'Statement: %', execute_statement;
      EXECUTE execute_statement INTO new_record_id;
	-- clone activity's detail taxonomy record
      FOR taxonomy_record IN (SELECT * FROM detail_taxonomy dt WHERE dt.detail_id = original_record.detail_id) LOOP
        EXECUTE 'INSERT INTO detail_taxonomy (detail_id, classification_id, field) VALUES ( ' || new_record_id || ', ' || taxonomy_record.classification_id || ', ''detail_id'')';  
      END LOOP;	
    END LOOP;
        
  ELSE  
    FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: User does NOT have authority to create new records on this project.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
  END IF;
  
  -- editing completed successfullly
  FOR rec IN (SELECT row_to_json(j) FROM(select new_activity_id as id, 'Success' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;         
  
EXCEPTION WHEN others THEN
     GET STACKED DIAGNOSTICS error_msg1 = MESSAGE_TEXT,
                          error_msg2 = PG_EXCEPTION_DETAIL,
                          error_msg3 = PG_EXCEPTION_HINT;
    FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Internal Error - Contact your DBA with the following error message: ' || error_msg1 as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;	  
END;$$ LANGUAGE plpgsql;

-- update permissions
GRANT USAGE ON SCHEMA public TO pmt_read;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO pmt_read;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO pmt_read;
GRANT USAGE ON SCHEMA public TO pmt_write;
GRANT SELECT,INSERT ON ALL TABLES IN SCHEMA public TO pmt_write;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO pmt_write;

