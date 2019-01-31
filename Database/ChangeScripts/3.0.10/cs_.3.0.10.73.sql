/******************************************************************
Change Script 3.0.10.73
1. update pmt_validate_user_authority for new permissions model
2. update pmt_user_auth to ensure only authorized data groups are included in
autorizations for taxonomies
3. add uniaue constraints to user_activity table for user_id, 
activity_id and classification_id
4. create pmt_edit_user_activity to manage user activity authorizations
******************************************************************/
INSERT INTO version(_version, _iteration, _changeset) VALUES (3.0, 10, 73);
-- select * from version order by _iteration desc, _changeset desc;

/******************************************************************
1. update pmt_validate_user_authority for new permissions model
  select * from pmt_validate_user_authority(2, 278, 13231, 'create'); -- admin, tanaim, activity outside of dgs
  select * from pmt_validate_user_authority(1, 277, 26313, 'create'); -- admin, ethaim, acitivity in dgs
  select * from pmt_validate_user_authority(1, 275, 26287, 'delete'); -- editor, ethaim, acitivity in dgs
  select * from pmt_validate_user_authority(1, 99, 26287, 'delete');
  select * from _user_instances
******************************************************************/
DROP FUNCTION IF EXISTS pmt_validate_user_authority(integer, integer, pmt_auth_crud);
CREATE OR REPLACE FUNCTION pmt_validate_user_authority(instance_id integer, user_id integer, activity_id integer, auth_type pmt_auth_crud) RETURNS boolean AS $$
DECLARE
  valid_instance record;
  valid_user_instance record; 
  valid_activity record;
  users_role record;
  error_msg text;
BEGIN
  -- validate instance_id (required)
  IF $1 IS NULL THEN
    RAISE NOTICE 'Missing required parameter (instance_id).';
    RETURN FALSE;
  ELSE
    SELECT INTO valid_instance * FROM instance WHERE id = $1;
    IF valid_instance.id IS NULL THEN
      RAISE NOTICE 'Missing valid, required parameter (instance_id).';
      RETURN FALSE;
    END IF;
    RAISE NOTICE 'Instance: %', valid_instance._theme;
  END IF;
  -- validate user_id (required)
  IF $2 IS NULL THEN
    RAISE NOTICE 'Missing required parameter (user_id).';
    RETURN FALSE;
  ELSE
    SELECT INTO valid_user_instance * FROM _user_instances WHERE _user_instances.user_id = $2 AND _user_instances.instance_id = $1;
    IF valid_user_instance.user_id IS NULL THEN
      RAISE NOTICE 'Provided user_id is not valid or does not have access to instance.';
      RETURN FALSE;
    ELSE
      SELECT INTO users_role * FROM role WHERE id = valid_user_instance.role_id;
      RAISE NOTICE 'User: %', valid_user_instance.username;
      RAISE NOTICE 'Role: %', valid_user_instance.role;
    END IF;
  END IF;
  -- validate activity_id (required)
  IF $3 IS NULL THEN
    RAISE NOTICE 'Missing required parameter (activity_id).';
    RETURN FALSE;
  ELSE
    SELECT INTO valid_activity * FROM activity WHERE id = $3;
    IF valid_activity IS NULL THEN
      RAISE NOTICE 'Missing valid, required parameter (activity_id).';
      RETURN FALSE;
    END IF;
    RAISE NOTICE 'Activity: %', valid_activity._title;
    RAISE NOTICE 'Data group: %', valid_activity.data_group_id;
  END IF;
  -- validate auth_type (required)
  IF $4 IS NULL THEN
    RAISE NOTICE 'Missing required parameter (auth_type).';
    RETURN FALSE;
  END IF;

  IF users_role IS NULL THEN
    RAISE NOTICE 'User role is null: %', users_role._name;
    RETURN FALSE;
  ELSE
    CASE users_role._name
      -- Super role has full rights
      WHEN 'Super' THEN
        RAISE NOTICE 'User has "Super" rights on instance: %', valid_user_instance.instance;
        RETURN TRUE;
      -- Administrator has full rights to instance data groups
      WHEN 'Administrator' THEN  
        IF ARRAY[valid_activity.id] <@ (SELECT array_agg(id) FROM activity WHERE data_group_id = ANY(valid_instance.data_group_ids)) THEN
          RAISE NOTICE 'User has "Administrative" rights on instance: %', valid_user_instance.instance;
          RETURN TRUE;
        ELSE
          RAISE NOTICE 'User has "Administrative" rights on instance %, but requsted activity is not owned.', valid_user_instance.instance;
          RETURN FALSE;
        END IF;
      WHEN 'Editor' THEN
        -- determine if user has access to activity
         IF (SELECT ARRAY [valid_activity.id] <@ array_agg(p.activity_id) as activity_ids FROM (
		  -- authorized by activity by instance
		  SELECT ua.user_id, ua.activity_id
		  FROM user_activity ua
		  WHERE _active = true AND ua.user_id = valid_user_instance.user_id AND classification_id IS NULL
		    AND ua.activity_id IN (SELECT id FROM activity WHERE data_group_id = ANY(ARRAY[(SELECT data_group_ids FROM instance WHERE id = valid_user_instance.instance_id)]))
		  UNION ALL
		  -- authorized by classification by instance
		  SELECT ua.user_id, at.activity_id
		  FROM (SELECT * FROM user_activity WHERE _active = true AND user_activity.user_id = valid_user_instance.user_id AND classification_id IS NOT NULL) ua
		  JOIN (SELECT * FROM activity_taxonomy WHERE _field = 'id' AND activity_taxonomy.activity_id IN (SELECT id FROM activity WHERE data_group_id = ANY(ARRAY[(SELECT data_group_ids FROM instance WHERE id = valid_user_instance.instance_id)]))) at
		  ON ua.classification_id = at.classification_id
		  ) p)
        THEN
          RAISE NOTICE 'User requesting "%" rights.', auth_type::text;
          CASE auth_type
            WHEN 'create' THEN
              RAISE NOTICE 'User is authorized: %', users_role._create;
              RETURN users_role._create;
            WHEN 'update' THEN
              RAISE NOTICE 'User is authorized: %', users_role._update;
              RETURN users_role._update;
            WHEN 'delete' THEN
              RAISE NOTICE 'User is authorized: %', users_role._delete;
              RETURN users_role._delete;
            ELSE
              RETURN FALSE;
          END CASE;
        ELSE
          RAISE NOTICE 'User has "Editor" rights on instance %, but does not have access to requested activity id.', valid_user_instance.instance;
          RETURN FALSE;
        END IF;		
      WHEN 'Reader' THEN
        RETURN FALSE;
      ELSE
    END CASE;
  END IF;
  
  RETURN FALSE;
    
EXCEPTION WHEN others THEN
     GET STACKED DIAGNOSTICS error_msg = MESSAGE_TEXT;  
    RAISE NOTICE 'Internal Error - Contact your DBA with the following error message: %', error_msg;
    RETURN FALSE;
END; 
$$ LANGUAGE 'plpgsql';

/******************************************************************
2. update pmt_user_auth to ensure only data groups are included in
autorizations for taxonomies
  select * from pmt_user_auth('sparadee','Butt3rflies',1); -- ethaim
  select * from pmt_user_auth('tanaimeditor','test',2); -- tanaim
  select * from pmt_user_auth('ethaimeditor','test',1); -- ethaim
  select * from pmt_user_auth('spatialdeveditor','test',3); -- spatialdev
  select * from pmt_user_auth('spatialdeveditor','test',1); -- spatialdev
  select * from pmt_user_auth('tanaimadmin','test',2); -- tanaim
  select * from user_log
******************************************************************/
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
		  WHERE _active = true AND user_id = u.id AND classification_id IS NULL
		    AND activity_id IN (SELECT id FROM activity WHERE data_group_id = ANY(ARRAY[(SELECT data_group_ids FROM instance WHERE id = auth_instance_id)]))
		  UNION ALL
		  -- authorized by classification by instance
		  SELECT ua.user_id, at.activity_id
		  FROM (SELECT * FROM user_activity WHERE _active = true AND user_id = u.id AND classification_id IS NOT NULL) ua
		  JOIN (SELECT * FROM activity_taxonomy WHERE _field = 'id' AND activity_id IN (SELECT id FROM activity WHERE data_group_id = ANY(ARRAY[(SELECT data_group_ids FROM instance WHERE id = auth_instance_id)]))) at
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
3. add uniaue constraints to user_activity table for user_id, 
activity_id and classification_id
******************************************************************/
ALTER TABLE user_activity ADD CONSTRAINT chk_unq_user_activity_classification UNIQUE (user_id, activity_id, classification_id);

/******************************************************************
4. create pmt_edit_user_activity to manage user activity authorizations
  select * from pmt_edit_user_activity(1, 277, 275, ARRAY[26197,26200], null, true) -- ethaimadmin, ethaimeditor, delete activities
  select * from pmt_edit_user_activity(1, 277, 275, null, ARRAY[2242,2240,999999], true) -- ethaimadmin, ethaimeditor, delete classifications
  select * from pmt_edit_user_activity(1, 277, 275, null, ARRAY[2239,2242], false) -- ethaimadmin, ethaimeditor, add new/existing classifications
  select * from pmt_edit_user_activity(1, 277, 275, ARRAY[26197,26250], null, false) -- ethaimadmin, ethaimeditor, add new/existing activities
  select * from user_activity where user_id = 275
  select * from _user_instances
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_edit_user_activity(instance_id integer, request_user_id integer, target_user_id integer, activity_ids integer[], classification_ids integer[], delete_record boolean DEFAULT false)
  RETURNS SETOF pmt_json_result_type AS $$
DECLARE
  valid_instance record;
  valid_request_user record;
  valid_target_user record;
  request_user_instance record;
  target_user_instance record;
  valid_activity_ids integer[];
  valid_classification_ids integer[];
  a_id integer;
  c_id integer;
  rec record;
  error_msg1 text;
  is_self boolean;
BEGIN
  -- instance_id is required for all operations
  IF ($1 IS NULL) THEN
    FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: instance_id is a required parameter.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
  ELSE
    -- instance_id must be valid
    SELECT INTO valid_instance * FROM instance WHERE id = $1;
    IF valid_instance.id IS NULL THEN
      FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: A valid instance_id is a required.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
    END IF;
    RAISE NOTICE 'Instance: %', valid_instance._theme;
  END IF;
  -- request_user_id is required for all operations
  IF ($2 IS NULL) THEN
    FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: request_user_id is a required parameter.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
  ELSE
    -- request_user_id must be valid
    SELECT INTO valid_request_user * FROM users WHERE id = $2;
    IF valid_request_user.id IS NULL THEN
      FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: A valid request_user_id is a required.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
    ELSE
      -- requesting user must have access to the requested instance with "Super" or "Administrator" role
      SELECT INTO request_user_instance * FROM _user_instances WHERE _user_instances.user_id = $2 AND _user_instances.instance_id = $1;
      IF request_user_instance.user_id IS NULL THEN
        FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: The requesting user must have access to instance.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
      ELSE
        IF request_user_instance.role <> 'Super' AND request_user_instance.role <> 'Administrator' THEN
          FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: The requesting user must have security rights on instance.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
        END IF;
        RAISE NOTICE 'Requesting User: %', request_user_instance.username;
        RAISE NOTICE 'Requesting Role: %', request_user_instance.role;
      END IF;
    END IF;
  END IF;
  -- target_user_id is required for all operations
  IF ($3 IS NULL) THEN
    FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: target_user_id is a required parameter.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
  ELSE
    -- target_user_id must be valid
    SELECT INTO valid_target_user * FROM users WHERE id = $3;
    IF valid_target_user.id IS NULL THEN
      FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: A valid target_user_id is a required.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
    ELSE
      -- target user must have access to the requested instance with a role greater then "Reader"
      SELECT INTO target_user_instance * FROM _user_instances WHERE _user_instances.user_id = $3 AND _user_instances.instance_id = $1;
      IF target_user_instance.user_id IS NULL THEN
        FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: The target user must have access to instance.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
      ELSE
        IF target_user_instance.role = 'Reader' THEN
          FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: The target user must have edit rights on instance.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
        END IF;
        RAISE NOTICE 'Target User: %', target_user_instance.username;
        RAISE NOTICE 'Target Role: %', target_user_instance.role;
      END IF;
    END IF;
  END IF;
  -- validate activity_ids
  IF ($4 IS NOT NULL) THEN
    SELECT INTO valid_activity_ids array_agg(id) FROM activity WHERE data_group_id = ANY(valid_instance.data_group_ids) AND id = ANY($4);
    RAISE NOTICE 'Valid activity ids: %', valid_activity_ids;
  END IF;
  -- validate classification_ids
  IF ($5 IS NOT NULL) THEN
    SELECT INTO valid_classification_ids array_agg(id) FROM classification WHERE id = ANY($5);
    RAISE NOTICE 'Valid classification ids: %', valid_classification_ids;
  END IF;
  
  -- delete operation (delete_record = true)
  IF ($6) THEN
    IF array_length(valid_activity_ids, 1) > 0 THEN
      RAISE NOTICE 'Deleting activities...'; 
      -- set matching record inactive
      UPDATE user_activity SET _active = false, _updated_by = quote_ident(valid_request_user._username)
      FROM (SELECT * FROM user_activity WHERE user_id = valid_target_user.id AND activity_id = ANY(valid_activity_ids) AND _active = true) ua 
      WHERE user_activity.id = ua.id;     
    END IF;
    IF array_length(valid_classification_ids, 1) > 0 THEN 
      RAISE NOTICE 'Deleting classifications...'; 
      -- set matching record inactive
      UPDATE user_activity SET _active = false, _updated_by = quote_ident(valid_request_user._username)
      FROM (SELECT * FROM user_activity WHERE user_id = valid_target_user.id AND classification_id = ANY(valid_classification_ids) AND _active = true) ua 
      WHERE user_activity.id = ua.id; 
    END IF;
  -- create operation 
  ELSE
    IF array_length(valid_activity_ids, 1) > 0 THEN
      RAISE NOTICE 'Adding activities...'; 
      -- set matching record active
      UPDATE user_activity SET _active = true, _updated_by = quote_ident(valid_request_user._username) 
      FROM (SELECT * FROM user_activity WHERE user_id = valid_target_user.id AND activity_id = ANY(valid_activity_ids) AND _active = false) ua 
      WHERE user_activity.id = ua.id; 
      -- create new records
      INSERT INTO user_activity(user_id, activity_id, _created_by, _updated_by) 
      SELECT * FROM (SELECT valid_target_user.id as id, unnest(valid_activity_ids) as a_id, valid_request_user._username, valid_request_user._username) as a 
      WHERE a.a_id NOT IN (SELECT activity_id FROM user_activity WHERE user_id = valid_target_user.id AND activity_id IS NOT NULL);
    END IF;
    IF array_length(valid_classification_ids, 1) > 0 THEN 
      RAISE NOTICE 'Adding classifications...'; 
      -- set matching record active
      UPDATE user_activity SET _active = true, _updated_by = quote_ident(valid_request_user._username) 
      FROM (SELECT * FROM user_activity WHERE user_id = valid_target_user.id AND classification_id = ANY(valid_classification_ids) AND _active = false) ua 
      WHERE user_activity.id = ua.id; 
      -- create new records
      INSERT INTO user_activity(user_id, classification_id, _created_by, _updated_by) 
      SELECT * FROM (SELECT valid_target_user.id as id, unnest(valid_classification_ids) as c_id, valid_request_user._username, valid_request_user._username) as c 
      WHERE c.c_id NOT IN (SELECT classification_id FROM user_activity WHERE user_id = valid_target_user.id AND classification_id IS NOT NULL);
    END IF;
  END IF;
  
  -- editing completed successfullly
  FOR rec IN (SELECT row_to_json(j) FROM(select target_user_id as id, 'Success' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;

EXCEPTION WHEN others THEN
     GET STACKED DIAGNOSTICS error_msg1 = MESSAGE_TEXT;
    FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Internal Error - Contact your DBA with the following error message: ' || error_msg1 as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
END;$$ LANGUAGE plpgsql;

-- update permissions
GRANT USAGE ON SCHEMA public TO pmt_read;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO pmt_read;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO pmt_read;
GRANT USAGE ON SCHEMA public TO pmt_write;
GRANT SELECT,INSERT ON ALL TABLES IN SCHEMA public TO pmt_write;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO pmt_write;