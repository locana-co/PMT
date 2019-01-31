/******************************************************************
Change Script 3.0.10.69
1. update pmt_user_auth to use the new permissioning model
2. create new core view _user_instances for user instances
3. update pmt_users to use the new permissioning model
4. create new overloaded pmt_users
5. update pmt_edit_user to use new permissioning model
******************************************************************/
INSERT INTO version(_version, _iteration, _changeset) VALUES (3.0, 10, 69);
-- select * from version order by _iteration desc, _changeset desc;

/******************************************************************
1. update pmt_user_auth to use the new permissioning model
  select * from pmt_user_auth('sparadee','Butt3rflies',1); -- ethaim
  select * from pmt_user_auth('tanaimeditor','test',2); -- tanaim
  select * from pmt_user_auth('ethaimeditor','test',1); -- ethaim
  select * from pmt_user_auth('spatialdeveditor','test',3); -- spatialdev
  select * from pmt_user_auth('spatialdeveditor','test',1); -- spatialdev
  select * from pmt_user_auth('tanaimadmin','test',2); -- tanaim
  select * from user_log
******************************************************************/
DROP FUNCTION IF EXISTS pmt_user_auth(character varying, character varying);
CREATE OR REPLACE FUNCTION pmt_user_auth(username character varying(255), password character varying(255), instance_id integer) RETURNS 
SETOF pmt_json_result_type AS $$
DECLARE 
  valid_user_id integer;
  auth_instance_id integer;
  auth_success boolean;
  users_role record;
  users_instance record;	
  rec record;
  error_msg text;
BEGIN
  -- validate required parameter
  IF $3 IS NULL THEN
    FOR rec IN (SELECT row_to_json(j) FROM( SELECT 'Instance id is a required parameter.' AS message ) j ) LOOP		
        RETURN NEXT rec;
    END LOOP;
  ELSE
    SELECT INTO users_instance * FROM instance WHERE id = $3;	
    IF users_instance IS NULL THEN
      FOR rec IN (SELECT row_to_json(j) FROM( SELECT 'A valid instance id is a required parameter.' AS message ) j ) LOOP		
        RETURN NEXT rec;
      END LOOP;
    END IF;
  END IF;
   
  -- determine if the password is valid for this user
  SELECT INTO auth_success (_password = crypt($2, _password)) AS pswmatch FROM users WHERE _username = $1 AND _active = true;

  IF (auth_success) THEN
    -- validate user and get user_id
    SELECT INTO valid_user_id users.id FROM users WHERE users._username = $1;
  END IF;
  
  IF valid_user_id IS NOT NULL THEN
    -- validate the user has access to the instance
    SELECT INTO auth_instance_id user_instance.instance_id FROM user_instance WHERE user_instance.user_id = valid_user_id AND user_instance.instance_id = users_instance.id;    
    IF auth_instance_id IS NOT NULL THEN 
      -- get the users role on the instance
      SELECT INTO users_role * FROM role WHERE id = (SELECT role_id FROM user_instance WHERE user_instance.user_id = valid_user_id AND user_instance.instance_id = auth_instance_id);
      CASE users_role._name
        WHEN 'Super' THEN
          FOR rec IN (
	    SELECT row_to_json(j) FROM(	 				
	      SELECT u.id, u._first_name, u._last_name, u._username, u._email ,u.organization_id
	        ,(SELECT _name FROM organization WHERE id = u.organization_id) as organization
	        ,users_role.id as role_id
	        ,users_role._name as role
	        ,(SELECT row_to_json(ra) FROM (SELECT users_role._read,users_role._create,users_role._update,users_role._delete,users_role._super,users_role._security) ra) as role_auth
	        ,null as authorizations
	      FROM users u
	      WHERE u.id = valid_user_id
	    ) j
          ) LOOP		
            RETURN NEXT rec;
          END LOOP;
        WHEN 'Administrator' THEN
          FOR rec IN (
	    SELECT row_to_json(j) FROM(	 				
	      SELECT u.id, u._first_name, u._last_name, u._username, u._email ,u.organization_id
	        ,(SELECT _name FROM organization WHERE id = u.organization_id) as organization
	        ,users_role.id as role_id
	        ,users_role._name as role
	        ,(SELECT row_to_json(ra) FROM (SELECT users_role._read,users_role._create,users_role._update,users_role._delete,users_role._super,users_role._security) ra) as role_auth
	        ,(SELECT array_agg(id) as activity_ids FROM activity WHERE data_group_id = ANY(ARRAY[(SELECT data_group_ids FROM instance WHERE id = auth_instance_id)])) as authorizations
	      FROM users u
	      WHERE u.id = valid_user_id
	    ) j
          ) LOOP		
            RETURN NEXT rec;
          END LOOP;
        WHEN 'Reader' THEN
          FOR rec IN (
	    SELECT row_to_json(j) FROM(	 				
	      SELECT u.id, u._first_name, u._last_name, u._username, u._email ,u.organization_id
	        ,(SELECT _name FROM organization WHERE id = u.organization_id) as organization
	        ,users_role.id as role_id
	        ,users_role._name as role
	        ,(SELECT row_to_json(ra) FROM (SELECT users_role._read,users_role._create,users_role._update,users_role._delete,users_role._super,users_role._security) ra) as role_auth
	        ,null as authorizations
	      FROM users u
	      WHERE u.id = valid_user_id
	    ) j
          ) LOOP		
            RETURN NEXT rec;
          END LOOP;
        ELSE
          FOR rec IN (
	    SELECT row_to_json(j) FROM(	 				
	      SELECT u.id, u._first_name, u._last_name, u._username, u._email ,u.organization_id
	        ,(SELECT _name FROM organization WHERE id = u.organization_id) as organization
	        ,users_role.id as role_id
	        ,users_role._name as role
	        ,(SELECT row_to_json(ra) FROM (SELECT users_role._read,users_role._create,users_role._update,users_role._delete,users_role._super,users_role._security) ra) as role_auth
	        ,(SELECT array_agg(p.activity_id) as activity_ids FROM (
		  -- authorized by activity by instance
		  SELECT user_id, activity_id
		  FROM user_activity
		  WHERE user_id = u.id AND classification_id IS NULL
		    AND activity_id IN (SELECT id FROM activity WHERE data_group_id = ANY(ARRAY[(SELECT data_group_ids FROM instance WHERE id = auth_instance_id)]))
		  UNION ALL
		  -- authorized by classification by instance
		  SELECT ua.user_id, at.activity_id
		  FROM (SELECT * FROM user_activity WHERE user_id = u.id AND classification_id IS NOT NULL) ua
		  JOIN (SELECT * FROM activity_taxonomy WHERE _field = 'id') at
		  ON ua.classification_id = at.classification_id
		  ) p			
	      ) as authorizations
	      FROM users u
	      WHERE u.id = valid_user_id
	    ) j
          ) LOOP		
            RETURN NEXT rec;
          END LOOP;
      END CASE;
      -- log user 
      INSERT INTO user_log (user_id, _username, _access_date, _status, instance_id) VALUES (valid_user_id, $1 ,current_timestamp, 'success', $3);
    -- user does not have access to instance
    ELSE
      -- log user (invalid instance access)
      INSERT INTO user_log (user_id, _username, _access_date, _status, instance_id) VALUES (valid_user_id, $1,current_timestamp, 'failed - user does not have instance access', $3);
      FOR rec IN (SELECT row_to_json(j) FROM( SELECT 'User does not have access to application instance.' AS message ) j ) LOOP		
          RETURN NEXT rec;
      END LOOP;	      
    END IF;
  -- invalid user or password
  ELSE
    -- log user (bad user/password)
    INSERT INTO user_log (user_id, _username, _access_date, _status, instance_id) VALUES (null, $1 ,current_timestamp, 'failed - invalid username or password', $3);      
    FOR rec IN (SELECT row_to_json(j) FROM( SELECT 'Invalid username or password.' AS message ) j ) LOOP		
        RETURN NEXT rec;
    END LOOP;		  
  END IF;

EXCEPTION WHEN others THEN 
  GET STACKED DIAGNOSTICS error_msg = MESSAGE_TEXT;  
    RAISE NOTICE 'Internal Error - Contact your DBA with the following error message: %', error_msg;
    FOR rec IN (SELECT row_to_json(j) FROM( SELECT 'An error occured, please contact the administrator.' AS message ) j ) LOOP		
        RETURN NEXT rec;
    END LOOP;
END; 
$$ LANGUAGE 'plpgsql';

/******************************************************************
2. create new core view for user instances
  select * from _user_instances;
******************************************************************/
CREATE OR REPLACE VIEW _user_instances AS 
  SELECT i.id as instance_id, i._theme as instance, u.id as user_id, 
	u._username as username, r.id as role_id, r._name as role
  FROM (SELECT * FROM instance WHERE _active = true) i
  JOIN user_instance ui
  ON i.id = ui.instance_id
  JOIN (SELECT * FROM users WHERE _active = true) u
  ON ui.user_id = u.id
  JOIN role r
  ON ui.role_id = r.id
  ORDER BY 1,3,2;

/******************************************************************
3. update pmt_users to use the new permissioning model
  select * from pmt_users();
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_users() RETURNS SETOF pmt_json_result_type AS
$$
DECLARE 
  rec record;
BEGIN 
  FOR rec IN (
    SELECT row_to_json(j) FROM( 
	SELECT u.id, u._first_name, u._last_name, u._username, u._email
	,u.organization_id
	,(SELECT _name FROM organization WHERE id = u.organization_id) as organization
	,(SELECT array_to_json(array_agg(row_to_json(ui))) FROM (SELECT instance_id, instance, role_id, role FROM _user_instances WHERE user_id = u.id) as ui) as instances
	,(SELECT _access_date from user_log where user_id = u.id order by _access_date desc LIMIT 1)
	,u._active
	FROM users u
	) j 
  ) LOOP		
    RETURN NEXT rec;
  END LOOP;			  

END;$$ LANGUAGE plpgsql; 

/******************************************************************
4. create new overloaded pmt_users
  select * from pmt_users(2);
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_users(instance_id integer) RETURNS SETOF pmt_json_result_type AS
$$
DECLARE 
  rec record;
  error_msg text;
BEGIN
  -- validate required parameter
  IF $1 IS NULL THEN
    FOR rec IN (SELECT row_to_json(j) FROM( SELECT 'Instance id is a required parameter.' AS message ) j ) LOOP		
        RETURN NEXT rec;
    END LOOP;
  END IF;
   
  FOR rec IN (
    SELECT row_to_json(j) FROM( 
	SELECT u.id, u._first_name, u._last_name, u._username, u._email
	,u.organization_id
	,(SELECT _name FROM organization WHERE id = u.organization_id) as organization
	,(SELECT role_id FROM _user_instances WHERE user_id = u.id AND _user_instances.instance_id = $1) as role_id
	,(SELECT role FROM _user_instances WHERE user_id = u.id AND _user_instances.instance_id = $1) as role
	,(SELECT _access_date from user_log where user_id = u.id order by _access_date desc LIMIT 1)
	,u._active
	FROM users u
	WHERE u.id IN (SELECT user_id FROM _user_instances WHERE _user_instances.instance_id = $1)
	) j 
  ) LOOP		
    RETURN NEXT rec;
  END LOOP;			  

EXCEPTION WHEN others THEN 
  GET STACKED DIAGNOSTICS error_msg = MESSAGE_TEXT;  
    RAISE NOTICE 'Internal Error - Contact your DBA with the following error message: %', error_msg;
    FOR rec IN (SELECT row_to_json(j) FROM( SELECT 'An error occured, please contact the administrator.' AS message ) j ) LOOP		
        RETURN NEXT rec;
    END LOOP;
    
END;$$ LANGUAGE plpgsql; 

/******************************************************************
5. update pmt_edit_user to use new permissioning model
  select * from pmt_edit_user(1, 34, 270, '{"organization_id": 2672}', 1, false) -- ethaim, sparadee, update
  select * from pmt_edit_user(1, 34, 271, null, null, true) -- ethaim, tanaimeditor, delete
  select * from pmt_edit_user(null, 270, 34, null, null, true) -- missing instance
  select * from pmt_edit_user(1, null, 270, null, null, false) -- missing requesting user
  select * from pmt_edit_user(1, 34, null, null, null, false) -- missing json on create
  select * from pmt_edit_user(1, 34, null, '{"organization_id": 2672}', null, false) -- missing role id on create
  select * from pmt_edit_user(1, 34, null, '{"organization_id": 2672}', 10, false) -- invalid role id on create
  select * from pmt_edit_user(1, 34, null, '{"organization_id": 2672, "_username":"testuser", "_password":"testpassword","_email":"test@mail.com"}', 1, false) -- missing first & last name on create
  select * from pmt_edit_user(1, 34, null, '{"organization_id": 999999, "_username":"testuser", "_password":"testpassword","_email":"test@mail.com","_first_name":"Test","_last_name":"User"}', 1, false) --  bad org create
  select * from pmt_edit_user(1, 34, null, '{"organization_id": 2672, "_username":"sparadee", "_password":"testpassword","_email":"test@mail.com","_first_name":"Test","_last_name":"User"}', 1, false) --  duplicate user create
  select * from pmt_edit_user(1, 34, null, '{"organization_id": 2672, "_username":"testuser", "_password":"testpassword","_email":"test@mail.com","_first_name":"Test","_last_name":"User"}', 1, false) --  good create
  select * from pmt_edit_user(1, 34, 275, '{"_password":"testpasswording"}', 3, false) --  good update
  select * from pmt_edit_user(1, 34, 275, null, 2, false) --  good update
  select * from pmt_edit_user(1, 34, 275, null, null, true) --  good delete
******************************************************************/
DROP FUNCTION IF EXISTS pmt_edit_user(integer, integer, json, boolean);
CREATE OR REPLACE FUNCTION pmt_edit_user(instance_id integer, request_user_id integer, target_user_id integer, key_value_data json, role_id integer, delete_record boolean DEFAULT false)
  RETURNS SETOF pmt_json_result_type AS $$
DECLARE
  org_id integer;
  user_id integer;
  json record;
  valid_role_id integer;
  valid_instance_id integer;
  user_instance_id integer;
  user_role_id integer;
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
  requesting_users_instance record;
  rec record;
  error_msg1 text;
  error_msg2 text;
  error_msg3 text;
  is_self boolean;
BEGIN
  -- set columns that are not editable via the parameters
  invalid_editing_columns := ARRAY['id', '_retired_by', '_created_by', '_created_date', '_updated_by', '_updated_date'];
  invalid_self_editing_columns := ARRAY['id', '_retired_by', '_created_by', '_created_date', '_updated_by', '_updated_date'];
  -- required columns for new records
  required_columns := ARRAY['_first_name','_last_name','_username', '_email', '_password', 'organization_id'];

  -- instance_id is required for all operations
  IF ($1 IS NULL) THEN
    FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: instance_id is a required parameter.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
  ELSE
    -- instance_id must be valid
    SELECT INTO valid_instance_id id FROM instance WHERE id = $1;
    IF valid_instance_id IS NULL THEN
      FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: A valid instance_id is a required.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
    END IF;
  END IF;
  -- request_user_id is required for all operations
  IF ($2 IS NULL) THEN
    FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: request_user_id is a required parameter.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
  END IF;

  -- delete operation (delete_record = true)
  IF ($6) THEN
    -- target_user_id is requried
    IF ($3 IS NULL) THEN
      FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: target_user_id is required for a delete operation.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
    END IF;      
  -- update/create operation (delete_record = false)    
  ELSE
    -- role_id is required
    IF ($5 IS NULL) THEN
      FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: The role_id is required for a create/update operation.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
    ELSE
      -- role_id must be valid
      SELECT INTO valid_role_id id FROM role WHERE _active = true AND id = $5;
      IF valid_role_id IS NULL THEN
        FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: A valid role_id is required for a create/update operation.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
      END IF;
    END IF;
    -- collect provided columns from the json
    FOR json IN (SELECT * FROM json_each_text($4)) LOOP
      RAISE NOTICE 'Provided JSON key/value: %', lower(json.key) || ':' || json.value;
      provided_columns := array_append(provided_columns, lower(json.key));
    END LOOP;      
  END IF;        

  -- get requesting user's information
  SELECT INTO requesting_users_instance * FROM _user_instances WHERE _user_instances.user_id = $2 AND _user_instances.instance_id = $1;

  -- determine if requesting user is editing self
  is_self = false;
  IF ($2 = $3) THEN
    is_self := true;
    invalid_editing_columns := invalid_self_editing_columns;
  END IF;
  
  -- user has authority for security actions on the instance
  IF (SELECT _security FROM role WHERE id = requesting_users_instance.role_id) OR (is_self) THEN
    RAISE NOTICE '%', 'User ' || requesting_users_instance.username || ' has security rights on instance: ' || requesting_users_instance.instance;
    -- create a new user record
    IF ($3 IS NULL) THEN
      -- json is required
      IF ($4 IS NULL) THEN
        FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: The json parameter is required for a create operation.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
      END IF;
      -- validate required columns have been provided
      RAISE NOTICE 'Provided columns: %', provided_columns;
      IF ( provided_columns @> required_columns ) THEN
	-- create new user record
	execute_statement := null;
	insert_statement := 'INSERT INTO "users" (';
	values_statement := 'VALUES (';
	-- loop through the columns of the user table
        FOR json IN (SELECT * FROM json_each_text($4)) LOOP
	  RAISE NOTICE 'JSON key/value: %', lower(json.key) || ':' || json.value;	  
	  -- get the column information for column that user is requesting to edit
	  FOR column_record IN (SELECT * FROM information_schema.columns WHERE table_schema='public' AND table_name='users' AND column_name != ALL(invalid_editing_columns) AND lower(column_name) = lower(json.key)) LOOP
	    RAISE NOTICE 'Editing column: %', column_record.column_name;
	    RAISE NOTICE 'Assigning new value: %', json.value;
	    CASE column_record.data_type
	    -- number data types
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
	      -- null value
	      IF (lower(json.value) = 'null') THEN
	        insert_statement := insert_statement || column_record.column_name || ', ';
	        values_statement := values_statement || 'null, ';
	      END IF;
	    -- other data types (not ingeter or numeric)
	    ELSE
	      -- process the username
	      IF column_record.column_name = '_username' THEN
	        SELECT INTO unq_user_name _username::text FROM users WHERE _username = json.value;
		RAISE NOTICE 'Name was not unique if not null: %', unq_user_name;
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
	values_statement := values_statement || quote_literal(requesting_users_instance.username) || ', ' || quote_literal(requesting_users_instance.username) || ') RETURNING "users".id;';
	-- concatenate insert and values statment 
	execute_statement := insert_statement || values_statement;
        RAISE NOTICE 'Statements: %', execute_statement;
	-- create user and return user id
	EXECUTE execute_statement INTO user_id;
	-- encrypt user password
	EXECUTE 'UPDATE "users" SET _password = crypt(_password, gen_salt(''bf'', 10)) where id = ' || user_id;
        -- assign user role on instance
        EXECUTE 'INSERT INTO user_instance (instance_id, user_id, role_id) VALUES (' || valid_instance_id || ',' || user_id || ',' || valid_role_id || ')';
      ELSE
        RAISE NOTICE 'Required columns: %', required_columns;
        FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: A required field was not provided.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
      END IF;
    -- update/delete a user record
    ELSE
      -- validate target_user_id
      SELECT INTO user_id users.id FROM users WHERE users.id = $3;
      IF (user_id IS NOT NULL) THEN
        -- delete user record
        IF ($6) THEN
          RAISE NOTICE 'Deleting user % from instance', $3;
          -- delete user from instance
          EXECUTE 'DELETE FROM user_instance WHERE user_instance.user_id = ' || user_id || ' AND user_instance.instance_id = ' || valid_instance_id;
          -- determine if user has access to other instances
          SELECT INTO user_instance_id user_instance.instance_id FROM user_instance WHERE user_instance.user_id = $3 LIMIT 1;
          -- delete user if user is not assigned to any other instances
          IF user_instance_id IS NULL THEN
            RAISE NOTICE 'Deleting user % from database.', $3;
            EXECUTE 'DELETE FROM users WHERE users.id = ' || $3 ;
          END IF;
        -- update user record
        ELSE
          RAISE NOTICE 'Updating user % record', $3;
	  -- loop through the columns of the activity table
          FOR json IN (SELECT * FROM json_each_text($4)) LOOP
	    RAISE NOTICE 'JSON key/value: %', lower(json.key) || ':' || json.value;
	    -- get the column information for column that user is requesting to edit
	    FOR column_record IN (SELECT * FROM information_schema.columns WHERE table_schema='public' AND table_name='users' AND column_name != ALL(invalid_editing_columns) AND lower(column_name) = lower(json.key)) LOOP
	      RAISE NOTICE 'Editing column: %', column_record.column_name;
	      RAISE NOTICE 'Assigning new value: %', json.value;
	      execute_statement := null;
              CASE column_record.data_type
               -- number data types
		WHEN 'integer', 'numeric' THEN
		  IF (SELECT pmt_isnumeric(json.value)) THEN
		    execute_statement := 'UPDATE "users" SET ' || column_record.column_name || ' = ' || json.value || ' WHERE id = ' || user_id;
		  END IF;
		  IF (lower(json.value) = 'null') THEN
		    execute_statement := 'UPDATE "users" SET ' || column_record.column_name || ' = null WHERE id = ' || user_id;
		  END IF;
		-- other data types (not ingeter or numeric)
		ELSE
		  -- if the value has the text null then assign the column value null
		  IF (lower(json.value) = 'null') THEN
		    execute_statement := 'UPDATE "users" SET ' || column_record.column_name || ' = null WHERE id = ' || user_id;
		  ELSE
		    execute_statement := 'UPDATE "users" SET ' || column_record.column_name || ' = ' || quote_literal(json.value) || ' WHERE id = ' || user_id;
		  END IF;
	      END CASE;
	      -- update user record
	      IF execute_statement IS NOT NULL THEN
		RAISE NOTICE 'Statement: %', execute_statement;
		EXECUTE execute_statement;
		IF (column_record.column_name = '_password') THEN
		  EXECUTE 'UPDATE "users" SET _password = crypt(_password, gen_salt(''bf'', 10)) where id = ' || user_id;
		END IF;
		EXECUTE 'UPDATE "users" SET _updated_by = ' || quote_literal(requesting_users_instance.username) || ', _updated_date = ' || quote_literal(current_date) || ' WHERE  id = ' || user_id;
	      END IF;
	    END LOOP;
	  END LOOP;
	  -- determine if user is assigned to instance
          SELECT INTO user_role_id user_instance.role_id FROM user_instance WHERE user_instance.user_id = $3 AND user_instance.instance_id = $1;
          IF user_role_id IS NULL THEN
            RAISE NOTICE 'Assigning user % to instance', $3;
            -- assign user role on instance
	    EXECUTE 'INSERT INTO user_instance (instance_id, user_id, role_id) VALUES (' || valid_instance_id || ',' || user_id || ',' || valid_role_id || ')';
          ELSE
            RAISE NOTICE 'Updating user % role on instance', $3;
            -- update the user role
	    EXECUTE 'UPDATE user_instance SET role_id = ' || valid_role_id || ' WHERE user_instance.user_id = ' || $3 || ' AND user_instance.instance_id = ' || $1;
          END IF;	 
        END IF;
      -- target user id must be valid  
      ELSE
        FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: target_user_id is not a valid user_id.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
      END IF;
    -- creating new record
    END IF;
  -- user is not authorized for security actions on this instance
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