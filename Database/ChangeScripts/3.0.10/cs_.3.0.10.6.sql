/******************************************************************
Change Script 3.0.10.6
1. update pmt_validate_organization for v3.0 data model
2. add unique constraint to users._username
3. update pmt_edit_user function for new naming conventions
******************************************************************/
INSERT INTO version(_version, _iteration, _changeset) VALUES (3.0, 10, 6);
-- select * from version order by _iteration desc, _changeset desc;

/******************************************************************
 1. update pmt_validate_organization
    select * from pmt_validate_organization(13);
******************************************************************/
DROP FUNCTION IF EXISTS pmt_validate_organization(integer);
CREATE OR REPLACE FUNCTION pmt_validate_organization(organization_id integer) RETURNS boolean AS $$
DECLARE valid_id integer;
BEGIN
     IF $1 IS NULL THEN
       RETURN FALSE;
     END IF;

     SELECT INTO valid_id id FROM organization WHERE _active = true AND id = $1;

     IF valid_id IS NULL THEN
      RETURN FALSE;
     ELSE
      RETURN TRUE;
     END IF;

EXCEPTION WHEN others THEN
    RETURN FALSE;
END;$$ LANGUAGE plpgsql;

/******************************************************************
 2. add unique constraint to users._username
******************************************************************/
ALTER TABLE users ADD CONSTRAINT chk_users_username UNIQUE (_username);

/******************************************************************
 3. update pmt_edit_user
    select * from users;
    -- create new user with valid org
    select * from pmt_edit_user(34,null, '{"organization_id":13, "_first_name":"John", "_last_name":"Doe", "_username":"johndoe", "_email": "jdoe@mail.com", "_password":"password"}', false);
    -- create new user with invalid org
    select * from pmt_edit_user(34,null, '{"organization_id":9999999, "_first_name":"John", "_last_name":"Doe", "_username":"johndoe", "_email": "jdoe@mail.com", "_password":"password"}', false);
    -- create new user with a username that already exists
    select * from pmt_edit_user(34,null, '{"organization_id":13, "_first_name":"John", "_last_name":"Doe", "_username":"johndoe", "_email": "jdoe@mail.com", "_password":"password"}', false);
    -- update first name and last name
    select * from pmt_edit_user(34,(select id from users where _username = 'johndoe'), '{"_first_name": "Jane", "_last_name":"Doe-Doe"}', false);
    -- update email and password
    select * from pmt_edit_user(34,(select id from users where _username = 'johndoe'), '{"_email": "jdoe-doe@mail.com", "_password":"password123"}', false);
    -- de-activate test user
    select * from pmt_edit_user(34, (select id from users where _username = 'johndoe'), null, true);
    -- delete test user
    delete from users where _username = 'johndoe';
******************************************************************/
DROP FUNCTION IF EXISTS pmt_edit_user(integer, integer, json, boolean);
CREATE OR REPLACE FUNCTION pmt_edit_user(request_user_id integer, target_user_id integer, key_value_data json, delete_record boolean DEFAULT false)
  RETURNS SETOF pmt_json_result_type AS $$
DECLARE
  user_role_id integer;
  user_id integer;
  org_id integer;
  json record;
  column_record record;
  execute_statement text;
  insert_statement text;
  values_statement text;
  invalid_editing_columns text[];
  invalid_self_editing_columns text[];
  required_columns text [];
  provided_columns text [];
  delete_response json;
  user_name text;
  unq_user_name text;
  rec record;
  error_msg1 text;
  error_msg2 text;
  error_msg3 text;
  is_self boolean;
BEGIN
  -- set columns that are not editable via the parameters
  invalid_editing_columns := ARRAY['id', '_retired_by', '_created_by', '_created_date', '_updated_by', '_updated_date'];
  invalid_self_editing_columns := ARRAY['id', '_retired_by', '_created_by', '_created_date', '_updated_by', '_updated_date', 'role_id'];
  -- required columns for new records
  required_columns := ARRAY['_username', '_email', '_password', 'organization_id'];

  -- request_user_id is required for all operations
  IF ($1 IS NOT NULL) THEN
    -- update/create operation
    IF NOT ($4) THEN
      -- json is required
      IF ($3 IS NULL) THEN
        FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: The json parameter is required for a create/update operation.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
      END IF;
    -- delete operation
    ELSE
      -- target_user_id is requried
      IF ($2 IS NULL) THEN
        FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: target_user_id is required for a delete operation.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
      END IF;
    END IF;

    -- collect provided columns from the json
    FOR json IN (SELECT * FROM json_each_text($3)) LOOP
      RAISE NOTICE 'JSON key/value: %', lower(json.key) || ':' || json.value;
      provided_columns := array_append(provided_columns, lower(json.key));
    END LOOP;

  -- error if request_user_id not provided
  ELSE
    FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: request_user_id is a required parameter for all operations.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
  END IF;

  -- get users name
  SELECT INTO user_name _username FROM "users" WHERE "users".id = $1;
  -- get users role
  SELECT INTO user_role_id role_id FROM "users" WHERE "users".id = $1;

  is_self = false;
  IF ($1 = $2) THEN
    is_self := true;
    invalid_editing_columns := invalid_self_editing_columns;
  END IF;
  
  -- user has authority for security actions on the database
  IF(SELECT _security FROM role WHERE id = user_role_id) OR (is_self) THEN
    -- create a new user record
    IF ($2 IS NULL) THEN
      -- validate required columns have been provided
      RAISE NOTICE 'Provided columns: %', provided_columns;
      IF ( provided_columns @> required_columns ) THEN
	-- create new user record
	execute_statement := null;
	insert_statement := 'INSERT INTO "users" (';
	values_statement := 'VALUES (';
	-- loop through the columns of the user table
        FOR json IN (SELECT * FROM json_each_text($3)) LOOP
	  RAISE NOTICE 'JSON key/value: %', lower(json.key) || ':' || json.value;
	  -- get the column information for column that user is requesting to edit
	  FOR column_record IN (SELECT * FROM information_schema.columns WHERE table_schema='public' AND table_name='users' AND column_name != ALL(invalid_editing_columns) AND lower(column_name) = lower(json.key)) LOOP
	      RAISE NOTICE 'Editing column: %', column_record.column_name;
	      RAISE NOTICE 'Assigning new value: %', json.value;
	      CASE column_record.data_type
		WHEN 'integer', 'numeric' THEN
		  IF (SELECT pmt_isnumeric(json.value)) THEN
		    -- process organization id
		    IF column_record.column_name = 'organization_id' THEN
		      SELECT INTO org_id id FROM organization where id = json.value::integer;
		      -- validate organization id
		      IF(SELECT * FROM pmt_validate_organization(org_id)) THEN
		        insert_statement := insert_statement || column_record.column_name || ', ';
		        values_statement := values_statement || json.value || ', ';
		      ELSE
		        -- valid organization is required
		        FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: invalid organization_id.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
		      END IF;
		    ELSE
		      insert_statement := insert_statement || column_record.column_name || ', ';
		      values_statement := values_statement || json.value || ', ';
		    END IF;
		  END IF;
		  
		  IF (lower(json.value) = 'null') THEN
		    insert_statement := insert_statement || column_record.column_name || ', ';
		    values_statement := values_statement || 'null, ';
		  END IF;
		-- other data types (not ingeter or numeric)
		ELSE
		  -- process organization id
		  IF column_record.column_name = '_username' THEN
		    SELECT INTO unq_user_name _username::text FROM users WHERE _username = json.value;
		    RAISE NOTICE 'unq_user_name: %', unq_user_name;
		    IF (unq_user_name IS NOT NULL) THEN
		      -- the requested username already exists, usernames must be unique
		      FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: username already exists.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
		    ELSE
		      insert_statement := insert_statement || column_record.column_name || ', ';
		      values_statement := values_statement || quote_literal(json.value) || ', ';
		    END IF;
		  ELSE 
		    -- if the value has the text null then assign the column value null
		    IF (lower(json.value) = 'null') THEN
		      insert_statement := insert_statement || column_record.column_name || ', ';
		      values_statement := values_statement || 'null, ';
		    ELSE
		      insert_statement := insert_statement || column_record.column_name || ', ';
		      values_statement := values_statement || quote_literal(json.value) || ', ';
		    END IF;
		  END IF;		  
	      END CASE;
	    END LOOP;
	  END LOOP;

	  -- add additional statements and concatenate
	 insert_statement := insert_statement || '_created_by, _updated_by) ';
	 values_statement := values_statement || quote_literal(user_name) || ', ' || quote_literal(user_name) || ') RETURNING "users".id;';

	 execute_statement := insert_statement || values_statement;

         RAISE NOTICE 'Statements: %', execute_statement;
	 EXECUTE execute_statement INTO user_id;
	 EXECUTE 'UPDATE "users" SET _password = crypt(_password, gen_salt(''bf'', 10)) where id = ' || user_id;

      ELSE
        FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: A required field was not provided.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
      END IF;
    -- update/delete a user record
    ELSE
      -- validate target_user_id
      SELECT INTO user_id "users".id FROM "users" WHERE "users".id = $2;
      IF (user_id IS NOT NULL) THEN
        -- delete user record
        IF ($4) THEN
          EXECUTE 'UPDATE "users" SET _active = false, _updated_by = ' || quote_literal(user_name) || ', _updated_date = ' || quote_literal(current_date) || ' WHERE "users".id = ' || user_id ;
        -- update user record
        ELSE
	  -- loop through the columns of the activity table
          FOR json IN (SELECT * FROM json_each_text($3)) LOOP
	    RAISE NOTICE 'JSON key/value: %', lower(json.key) || ':' || json.value;
	    -- get the column information for column that user is requesting to edit
	    FOR column_record IN (SELECT * FROM information_schema.columns WHERE table_schema='public' AND table_name='users' AND column_name != ALL(invalid_editing_columns) AND lower(column_name) = lower(json.key)) LOOP
	      RAISE NOTICE 'Editing column: %', column_record.column_name;
	      RAISE NOTICE 'Assigning new value: %', json.value;
	      execute_statement := null;
              CASE column_record.data_type
		WHEN 'integer', 'numeric' THEN
		  IF (SELECT pmt_isnumeric(json.value)) THEN
		    execute_statement := 'UPDATE "users" SET ' || column_record.column_name || ' = ' || json.value || ' WHERE id = ' || user_id;
		  END IF;
		  IF (lower(json.value) = 'null') THEN
		    execute_statement := 'UPDATE "users" SET ' || column_record.column_name || ' = null WHERE id = ' || user_id;
		  END IF;
		ELSE
		  -- if the value has the text null then assign the column value null
		  IF (lower(json.value) = 'null') THEN
		    execute_statement := 'UPDATE "users" SET ' || column_record.column_name || ' = null WHERE id = ' || user_id;
		  ELSE
		    execute_statement := 'UPDATE "users" SET ' || column_record.column_name || ' = ' || quote_literal(json.value) || ' WHERE id = ' || user_id;
		  END IF;
	      END CASE;
	      IF execute_statement IS NOT NULL THEN
		RAISE NOTICE 'Statement: %', execute_statement;
		EXECUTE execute_statement;
		IF (column_record.column_name = '_password') THEN
		  EXECUTE 'UPDATE "users" SET _password = crypt(_password, gen_salt(''bf'', 10)) where id = ' || user_id;
		END IF;
		EXECUTE 'UPDATE "users" SET _updated_by = ' || quote_literal(user_name) || ', _updated_date = ' || quote_literal(current_date) || ' WHERE  id = ' || user_id;
	      END IF;
	    END LOOP;
	  END LOOP;
        END IF;
      ELSE
        FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: target_user_id is not a valid user_id.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
      END IF;
    END IF;
  -- user is not authorized for security actions on the database
  ELSE
    FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: User does NOT have security authorization on the database.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
  END IF;

  -- editing completed successfullly
  FOR rec IN (SELECT row_to_json(j) FROM(select user_id as id, 'Success' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;

EXCEPTION WHEN others THEN
     GET STACKED DIAGNOSTICS error_msg1 = MESSAGE_TEXT,
                          error_msg2 = PG_EXCEPTION_DETAIL,
                          error_msg3 = PG_EXCEPTION_HINT;
    FOR rec IN (SELECT row_to_json(j) FROM(select user_id as id, 'Internal Error - Contact your DBA with the following error message: ' || error_msg1 as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
END;$$ LANGUAGE plpgsql;

-- update permissions
GRANT USAGE ON SCHEMA public TO pmt_read;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO pmt_read;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO pmt_read;
GRANT USAGE ON SCHEMA public TO pmt_write;
GRANT SELECT,INSERT ON ALL TABLES IN SCHEMA public TO pmt_write;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO pmt_write;