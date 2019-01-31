/******************************************************************
Change Script 3.0.10.102
1. update pmt_validate_user_authority to correct logic for role
authorization
2. update pmt_edit_organization to authenticate properly
3. update pmt_users to return new "Curator" role
******************************************************************/
INSERT INTO version(_version, _iteration, _changeset) VALUES (3.0, 10, 102);
-- select * from version order by _iteration desc, _changeset desc;

/******************************************************************
1. update pmt_validate_user_authority to correct logic for role
authorization
  select * from pmt_validate_user_authority(2, 278, 13231, null, 'update'); -- admin, tanaim, activity outside of dgs
  select * from pmt_validate_user_authority(2, 278, null, 2237, 'create'); -- admin, tanaim, create on unauthorize dg
  select * from pmt_validate_user_authority(1, 277, null, 2237, 'create'); -- admin, ethaim, acitivity in dgs
  select * from pmt_validate_user_authority(1, 275, 26287, null, 'delete'); -- editor, ethaim, acitivity in dgs
  select * from _user_instances
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_validate_user_authority(instance_id integer, user_id integer, activity_id integer, data_group_id integer, auth_type pmt_auth_crud) RETURNS boolean AS $$
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
  -- validate auth_type (required)
  IF $5 IS NULL THEN
    RAISE NOTICE 'Missing required parameter (auth_type).';
    RETURN FALSE;
  ELSE
    -- validate activity_id (required) if NOT a create operation
    IF $5 <> 'create' THEN
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
    ELSE
      -- validate data_group_id (required) when action is create
      IF $4 IS NULL THEN
        RAISE NOTICE 'Missing required parameter (data_group_id) when action is create.';
        RETURN FALSE;
      ELSE
        IF NOT (SELECT * FROM pmt_is_data_group($4)) THEN
          RAISE NOTICE 'Missing valid, required parameter (data_group_id) when action is create.';
          RETURN FALSE;
        END IF;
        RAISE NOTICE 'Data group is valid for create: %', $4;
      END IF;
    END IF;
  END IF; 

  IF users_role IS NULL THEN
    RAISE NOTICE 'User role is null: %', users_role._name;
    RETURN FALSE;
  ELSE
    -- Super has full rights
    IF users_role._super THEN
      RAISE NOTICE 'User has "Super" rights on instance: %', valid_user_instance.instance;
      RETURN TRUE;
    -- Administrator has full rights to instance data groups
    ELSIF users_role._create AND users_role._update AND users_role._delete AND users_role._security THEN
      IF $5 = 'create' THEN
        -- validate user has access to requested data group
        IF ARRAY[$4] <@ (valid_user_instance.data_group_ids) THEN
          RAISE NOTICE 'User has "Administrative" rights on instance: %', valid_user_instance.instance;
          RETURN TRUE;
        ELSE
          RAISE NOTICE 'User has "Administrative" rights on instance %, but requsted data group is not owned.', valid_user_instance.instance;
          RETURN FALSE;
        END IF;
      ELSE
        -- determine if user has access to activity
        IF ARRAY[valid_activity.id] <@ (SELECT array_agg(id) FROM activity WHERE activity.data_group_id = ANY(valid_instance.data_group_ids)) THEN
          RAISE NOTICE 'User has "Administrative" rights on instance: %', valid_user_instance.instance;
          RETURN TRUE;
        ELSE
          RAISE NOTICE 'User has "Administrative" rights on instance %, but requsted activity is not owned.', valid_user_instance.instance;
          RETURN FALSE;
        END IF;
      END IF;
    -- Editor has rights only authorized activities on instance data groups
    ELSIF users_role._create AND users_role._update THEN
      IF $5 = 'create' THEN
        -- validate user has access to requested data group
        IF ARRAY[$4] <@ (valid_user_instance.data_group_ids) THEN
          RAISE NOTICE 'User has "Editor" rights on instance, create authorization: %', users_role._create;
          RETURN users_role._create;
        ELSE
          RAISE NOTICE 'User has "Editor" rights on instance %, but requsted data group is not owned.', valid_user_instance.instance;
          RETURN FALSE;
        END IF;
      ELSE
        -- determine if user has access to activity
        IF (SELECT ARRAY [valid_activity.id] <@ array_agg(p.activity_id) as activity_ids FROM (
		  -- authorized by activity by instance
		  SELECT ua.user_id, ua.activity_id
		  FROM user_activity ua
		  WHERE _active = true AND ua.user_id = valid_user_instance.user_id AND classification_id IS NULL
		    AND ua.activity_id IN (SELECT id FROM activity WHERE activity.data_group_id = ANY(ARRAY[(SELECT data_group_ids FROM instance WHERE id = valid_user_instance.instance_id)]))
		  UNION ALL
		  -- authorized by classification by instance
		  SELECT ua.user_id, at.activity_id
		  FROM (SELECT * FROM user_activity WHERE _active = true AND user_activity.user_id = valid_user_instance.user_id AND classification_id IS NOT NULL) ua
		  JOIN (SELECT * FROM activity_taxonomy WHERE _field = 'id' AND activity_taxonomy.activity_id IN (SELECT id FROM activity WHERE activity.data_group_id = ANY(ARRAY[(SELECT data_group_ids FROM instance WHERE id = valid_user_instance.instance_id)]))) at
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
      END IF;
    -- Reader no CRUD authorization
    ELSE
      RAISE NOTICE 'User has "Reader" rights on instance.', valid_user_instance.instance;
      RETURN FALSE;
    END IF;
  END IF;
  
  RETURN FALSE;
    
EXCEPTION WHEN others THEN
     GET STACKED DIAGNOSTICS error_msg = MESSAGE_TEXT;  
    RAISE NOTICE 'Internal Error - Contact your DBA with the following error message: %', error_msg;
    RETURN FALSE;
END; 
$$ LANGUAGE 'plpgsql';


/******************************************************************
  2. update pmt_edit_organization to authenticate properly
  select * from pmt_edit_organization(1,275,null,'{"_name":"AAA Org","_label":"AAA"}',false); -- ethaimeditor
*******************************************************************/
CREATE OR REPLACE FUNCTION pmt_edit_organization(instance_id integer, user_id integer, organization_id integer, key_value_data json, delete_record boolean DEFAULT false)
  RETURNS SETOF pmt_json_result_type AS $$
DECLARE
  new_organization_id integer;
  o_id integer;
  json record;
  column_record record;
  execute_statement text;
  rec record;  
  invalid_editing_columns text[];
  users_role record;
  valid_user_instance record;
  instance_record record;
  user_record record;
  error_msg text;
BEGIN	

  -- set columns that are not editable via the parameters 
  invalid_editing_columns := ARRAY['id', '_active', '_retired_by', '_created_by', '_created_date', '_updated_by', '_updated_date'];

    -- instance_id is required
  IF ($1 IS NULL) THEN
    FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: instance_id is a required parameter.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
  -- must be valid
  ELSE
    SELECT INTO instance_record * FROM instance WHERE _active = true AND id = $1;
    IF instance_record IS NULL THEN
      FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: Invalid instance_id.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
    END IF;
  END IF;
  
  -- user_id is required
  IF ($2 IS NULL) THEN
    FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: user_id is a required parameter.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
  -- must be valid
  ELSE
    SELECT INTO user_record * FROM users WHERE _active = true AND id = $2;
    IF user_record IS NULL THEN
      FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: Invalid user_id.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
    END IF;
    SELECT INTO valid_user_instance * FROM _user_instances WHERE _user_instances.user_id = $2 AND _user_instances.instance_id = $1;
    IF valid_user_instance.user_id IS NULL THEN
      FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: Provided user_id is not valid or does not have access to instance.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
    ELSE
      SELECT INTO users_role * FROM role WHERE id = valid_user_instance.role_id;
      RAISE NOTICE 'User: %', valid_user_instance.username;
      RAISE NOTICE 'Role: %', valid_user_instance.role;
    END IF;
  END IF;
  
  -- data parameters are required
  IF NOT ($5) AND ($4 IS NULL) THEN
	FOR rec IN (SELECT row_to_json(j) FROM (select null as id, 'Error: Must included json parameter when delete_record is false.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
  END IF;

  -- org id is valid if present
  IF ($3 IS NOT NULL) AND (SELECT * FROM pmt_validate_organization($3))='f' THEN
	FOR rec IN (SELECT row_to_json(j) FROM (select null as id, 'Error: Invalid organization id.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
  END IF;

  -- validate user authority to edit organizations (MUST HAVE "Delete" permissions on instance - i.e. Administrative Role)
  IF NOT users_role._delete THEN
    FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: Provided user_id does not have proper permissions on instance. User must have role that permits deletes.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
  END IF;

	-- Handle Add
	IF ($3 IS NULL) THEN
		EXECUTE 'INSERT INTO organization(_name, _created_by, _updated_by) VALUES ( ''NEW ORGANIZATION'', ' || quote_literal(user_record._username) || ',' || quote_literal(user_record._username) || ') RETURNING id;' INTO new_organization_id;
		--RAISE NOTICE 'Created new organization with id: %', new_organization_id;
	END IF;
	-- Handle Delete/Deactivate
	IF ($5) AND ($3 IS NOT NULL) THEN
		EXECUTE 'UPDATE organization SET _active = false, _retired_by =  ' || quote_literal(user_record.id) || ' WHERE organization.id = ' || $3;
		--RAISE NOTICE 'Maked organization with id: % as INACTIVE', $3;
	END IF;

	IF new_organization_id IS NOT NULL THEN
		o_id := new_organization_id;
	ELSE
		o_id := $3;
	END IF;

	--RAISE NOTICE 'o_id = %', o_id;

	-- loop through the columns of the organization table and build up Update SQL
	FOR json IN (SELECT * FROM json_each_text($4)) LOOP
		--RAISE NOTICE 'JSON key/value: %', lower(json.key) || ':' || json.value;

		FOR column_record IN (SELECT * FROM information_schema.columns WHERE table_schema='public' AND table_name='organization' AND column_name != ALL(invalid_editing_columns) AND lower(column_name) = lower(json.key)) LOOP 
			--RAISE NOTICE 'Editing column: %', column_record.column_name;
			--RAISE NOTICE 'Assigning new value: %', json.value;

			execute_statement := null;
			CASE column_record.data_type 
				WHEN 'integer', 'numeric' THEN              
					IF (SELECT pmt_isnumeric(json.value)) THEN
						execute_statement := 'UPDATE organization SET ' || column_record.column_name || ' = ' || json.value || ' WHERE id = ' || o_id; 
					END IF;
					
					IF (lower(json.value) = 'null') THEN
						execute_statement := 'UPDATE organization SET ' || column_record.column_name || ' = null WHERE id = ' || o_id; 
					END IF;
				ELSE
				-- if the value has the text null then assign the column value null
					IF json.value IS NULL THEN
						execute_statement := 'UPDATE organization SET ' || column_record.column_name || ' = null WHERE id = ' || o_id; 
					ELSE
						execute_statement := 'UPDATE organization SET ' || column_record.column_name || ' = ' || quote_literal(json.value) || ' WHERE id = ' || o_id; 
					END IF;
			END CASE;

			IF execute_statement IS NOT NULL THEN
				--RAISE NOTICE 'execute_statement: %', execute_statement;
				EXECUTE execute_statement;
				EXECUTE 'UPDATE organization SET _updated_by = ' || quote_literal(user_record._username) || ', _updated_date = ' || quote_literal(current_date) || ' WHERE  id = ' || o_id;
			END IF;
		END LOOP;  -- END COLUMNS LOOP
	END LOOP; -- END JSON LOOP


-- Send Success response
FOR rec IN (SELECT row_to_json(j) FROM(select o_id as id, 'Success' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
   
EXCEPTION WHEN others THEN
    GET STACKED DIAGNOSTICS error_msg = MESSAGE_TEXT;
    FOR rec IN (SELECT row_to_json(j) FROM(select o_id as id, 'Internal Error - organization your DBA with the following error message: ' || error_msg as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;	  
END;$$ LANGUAGE plpgsql; 


/******************************************************************
  3. update pmt_users to return new "Curator" role
  SELECT pmt_users(1);
*******************************************************************/
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
	-- get authorizations for Editors (only valid role for authorizations)
	SELECT u.id, u._first_name, u._last_name, u._username, u._email, u._phone, u.organization_id
	,(SELECT _name FROM organization WHERE id = u.organization_id) as organization
	, r.id as role_id, r._name as role
	,(SELECT row_to_json(a) FROM ( 
		SELECT (SELECT array_agg(activity_id) as activity_ids
		FROM (SELECT * FROM user_activity WHERE _active = true AND activity_id IS NOT NULL) ua
		JOIN activity a
		ON ua.activity_id = a.id			
		WHERE ua.user_id = u.id AND ARRAY[a.data_group_id] <@ (SELECT data_group_ids FROM instance WHERE id = $1)) as activity_ids,
		(SELECT array_agg(classification_id) as classification_ids
		FROM user_activity 
		WHERE _active = true AND classification_id IS NOT NULL AND user_id = u.id) as classification_ids
	) a ) as authorizations
	,(SELECT array_to_json(array_agg(row_to_json(tax))) FROM (	
		SELECT taxonomy_id as t_id, taxonomy as t, (SELECT array_to_json(array_agg(row_to_json(tc))) FROM (
			SELECT classification_id as c_id, classification as c
			FROM _taxonomy_classifications
			WHERE taxonomy_id = tc.taxonomy_id
			AND classification_id IN (SELECT classification_id FROM user_activity 
						WHERE _active = true AND classification_id IS NOT NULL AND user_id = u.id)
			) tc ) as c
		FROM  _taxonomy_classifications tc
		WHERE classification_id IN (SELECT classification_id FROM user_activity 
						WHERE _active = true AND classification_id IS NOT NULL AND user_id = u.id)
		GROUP BY 1,2
		ORDER BY 1
	 ) tax ) as classifications  
	,(SELECT _access_date from user_log where user_id = u.id order by _access_date desc LIMIT 1)
	,u._active	
	FROM (SELECT * FROM user_instance ui WHERE ui.instance_id = $1) ui
	JOIN (SELECT * FROM users WHERE _username <> 'public')  u
	ON ui.user_id = u.id
	JOIN (SELECT * FROM role WHERE _name IN ('Editor','Curator')) r
	ON ui.role_id = r.id
	UNION ALL
	-- get authorizations for Administrator/Super (all activities in data group(s) for instance)
	SELECT u.id, u._first_name, u._last_name, u._username, u._email, u._phone, u.organization_id
	,(SELECT _name FROM organization WHERE id = u.organization_id) as organization
	, r.id as role_id, r._name as role
	,(SELECT row_to_json(a) FROM ( 
			SELECT (SELECT array_agg(id) as activity_ids
			FROM activity a		
			WHERE ARRAY[a.data_group_id] <@ (SELECT data_group_ids FROM instance WHERE id = $1)) as activity_ids,
			(SELECT null as classification_ids) as classification_ids
			) a ) as authorizations
	,null as classifications
	,(SELECT _access_date from user_log where user_id = u.id order by _access_date desc LIMIT 1)
	,u._active	
	FROM (SELECT * FROM user_instance ui WHERE ui.instance_id = $1) ui
	JOIN (SELECT * FROM users WHERE _username <> 'public')  u
	ON ui.user_id = u.id
	JOIN (SELECT * FROM role WHERE _name IN ('Administrator','Super')) r
	ON ui.role_id = r.id
	UNION ALL
	-- get authorizations for Reader (no authorizations)
	SELECT u.id, u._first_name, u._last_name, u._username, u._email, u._phone, u.organization_id
	,(SELECT _name FROM organization WHERE id = u.organization_id) as organization
	, r.id as role_id, r._name as role
	,(SELECT row_to_json(a) FROM ( 
			SELECT (SELECT null as activity_ids) as activity_ids,
			(SELECT null as classification_ids) as classification_ids
			) a ) as authorizations
	,null as classifications
	,(SELECT _access_date from user_log where user_id = u.id order by _access_date desc LIMIT 1)
	,u._active	
	FROM (SELECT * FROM user_instance ui WHERE ui.instance_id = $1) ui
	JOIN (SELECT * FROM users WHERE _username <> 'public')  u
	ON ui.user_id = u.id
	JOIN (SELECT * FROM role WHERE _name = 'Reader') r
	ON ui.role_id = r.id
	) j 
  ) LOOP		
    RETURN NEXT rec;
  END LOOP;	
END;$$ LANGUAGE plpgsql;


-- update permissions
GRANT USAGE ON SCHEMA public TO pmt_read;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO pmt_read;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO pmt_read;
GRANT USAGE ON SCHEMA public TO pmt_write;
GRANT SELECT,INSERT ON ALL TABLES IN SCHEMA public TO pmt_write;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO pmt_write;