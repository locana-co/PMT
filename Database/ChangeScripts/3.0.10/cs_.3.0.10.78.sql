/******************************************************************
Change Script 3.0.10.78
1. update pmt_validate_user_authority to correct logic for create
authorization
2. update pmt_validate_activity for new data model
3. update pmt_purge_activity function for new permissions model
4. update pmt_activate_activity for new data model
5. update _user_instances to add data group information
6. update pmt_validate_taxonomies for new data model
7. update pmt_validate_financial for new data model
8. update pmt_validate_financials for new data model
9. update pmt_validate_participation for new data model
10. update pmt_edit_activity for new data model
11. update pmt_edit_activity_taxonomy for the new data model
12. update pmt_edit_financial for new data model
13. update pmt_edit_financial_taxonomy for the new data model
14. update pmt_edit_participation for new data model
15. update pmt_full_record to return participation id & rename to pmt_activity_detail
16. update pmt_edit_location for new data model
17. address bug in pmt_upd_boundary_features
18. remove unused functions (pmt_countries, pmt_user)
19. consolidate location boundary update functions
******************************************************************/
INSERT INTO version(_version, _iteration, _changeset) VALUES (3.0, 10, 78);
-- select * from version order by _iteration desc, _changeset desc;

/******************************************************************
1. update pmt_validate_user_authority to correct logic for create
authorization
  select * from pmt_validate_user_authority(2, 278, 13231, null, 'update'); -- admin, tanaim, activity outside of dgs
  select * from pmt_validate_user_authority(2, 278, null, 2237, 'create'); -- admin, tanaim, create on unauthorize dg
  select * from pmt_validate_user_authority(1, 277, null, 2237, 'create'); -- admin, ethaim, acitivity in dgs
  select * from pmt_validate_user_authority(1, 275, 26287, null, 'delete'); -- editor, ethaim, acitivity in dgs
  select * from _user_instances
******************************************************************/
DROP FUNCTION IF EXISTS pmt_validate_user_authority(integer, integer, pmt_auth_crud);
DROP FUNCTION IF EXISTS pmt_validate_user_authority(integer, integer, integer, integer, pmt_auth_crud);
DROP FUNCTION IF EXISTS pmt_validate_user_authority(integer, integer, integer, pmt_auth_crud);
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
    CASE users_role._name
      -- Super role has full rights
      WHEN 'Super' THEN
        RAISE NOTICE 'User has "Super" rights on instance: %', valid_user_instance.instance;
        RETURN TRUE;
      -- Administrator has full rights to instance data groups
      WHEN 'Administrator' THEN 
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
      WHEN 'Editor' THEN
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
2. update pmt_validate_activity for new data model
  select * from pmt_validate_activity(19544);
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_validate_activity(id integer)
  RETURNS boolean AS 
$$
DECLARE 
  valid_id integer;
BEGIN 
     IF $1 IS NULL THEN    
       RETURN false;
     END IF;    
     
     SELECT INTO valid_id activity.id FROM activity WHERE activity.id = $1;	 

     IF valid_id IS NULL THEN
      RETURN false;
     ELSE 
      RETURN true;
     END IF;
     
EXCEPTION WHEN others THEN
    RETURN FALSE;
END;$$ LANGUAGE plpgsql;

/******************************************************************
 3. update pmt_purge_activity function for new permissions model
 NOTE: this function is not intended to be used in the API! This is 
 intended to be an internal function used by other functions or a DBA
******************************************************************/
DROP FUNCTION IF EXISTS pmt_purge_activity(integer);
CREATE OR REPLACE FUNCTION pmt_purge_activity(a_id integer) RETURNS boolean AS $$
DECLARE
  children int[];
  child_id int;
  activity_record record;
  error_msg text;
BEGIN 
  -- no parameter is provided, exit
  IF $1 IS NULL THEN    
    RETURN FALSE;
  END IF;
  -- validate activity_id
  SELECT INTO activity_record * FROM activity WHERE id = $1;
  IF activity_record IS NULL THEN
    -- id doesn't exsist, exit
    RETURN FALSE;
  ELSE
    -- collect the children activity ids if there are children
    SELECT INTO children array_agg(id) FROM activity WHERE parent_id = activity_record.id;    
  END IF;
  
  IF array_length(children,1)>0 THEN
    -- loop through all the children and purge each child activity
    FOREACH child_id IN ARRAY children LOOP
      -- Purge taxonomy associated data
      DELETE FROM activity_taxonomy WHERE activity_id = child_id;
      DELETE FROM financial_taxonomy WHERE financial_id IN (SELECT id FROM financial WHERE activity_id = child_id);
      DELETE FROM detail_taxonomy WHERE detail_id IN (SELECT id FROM detail WHERE activity_id = child_id);
      DELETE FROM result_taxonomy WHERE result_id IN (SELECT id FROM result WHERE activity_id = child_id);
      DELETE FROM location_taxonomy WHERE location_id IN (SELECT id FROM location WHERE activity_id = child_id);
      DELETE FROM participation_taxonomy WHERE participation_id IN (SELECT id FROM participation WHERE activity_id = child_id);
      -- purge related data
      DELETE FROM financial WHERE activity_id = child_id;
      DELETE FROM detail WHERE activity_id = child_id;
      DELETE FROM result WHERE activity_id = child_id;
      DELETE FROM activity_contact WHERE activity_id = child_id;
      DELETE FROM location WHERE activity_id = child_id;	
      DELETE FROM participation WHERE activity_id = child_id;
      -- purge user permissions
      DELETE FROM user_activity WHERE activity_id = child_id;
      -- purge the activity
      DELETE FROM activity WHERE id = child_id;
    END LOOP;
  END IF;

  -- purge the requested activity
  -- purge taxonomy associated data
  DELETE FROM activity_taxonomy WHERE activity_id = $1;
  DELETE FROM financial_taxonomy WHERE financial_id IN (SELECT id FROM financial WHERE activity_id = $1);
  DELETE FROM detail_taxonomy WHERE detail_id IN (SELECT id FROM detail WHERE activity_id = $1);
  DELETE FROM result_taxonomy WHERE result_id IN (SELECT id FROM result WHERE activity_id = $1);
  DELETE FROM location_taxonomy WHERE location_id IN (SELECT id FROM location WHERE activity_id = $1);
  DELETE FROM participation_taxonomy WHERE participation_id IN (SELECT id FROM participation WHERE activity_id = $1);
  -- purge related data
  DELETE FROM financial WHERE activity_id = $1;
  DELETE FROM detail WHERE activity_id = $1;
  DELETE FROM result WHERE activity_id = $1;
  DELETE FROM activity_contact WHERE activity_id = $1;
  DELETE FROM location WHERE activity_id = $1;	
  DELETE FROM participation WHERE activity_id = $1;
  -- purge user permissions
  DELETE FROM user_activity WHERE activity_id = $1;
  -- purge the activity
  DELETE FROM activity WHERE id = $1;
  -- return success				
  RETURN TRUE;

EXCEPTION
  -- some type of error occurred, return unsuccessful
     WHEN others THEN 
       GET STACKED DIAGNOSTICS error_msg = MESSAGE_TEXT;
       RAISE NOTICE 'Error: %', error_msg;
       RETURN FALSE;
END;  
$$ LANGUAGE 'plpgsql';

/******************************************************************
 4. update pmt_activate_activity for new data model
******************************************************************/
DROP FUNCTION IF EXISTS pmt_activate_activity(integer, integer, boolean);
CREATE OR REPLACE FUNCTION pmt_activate_activity(instance_id integer, user_id integer, activity_id integer, activate boolean default true) RETURNS SETOF pmt_json_result_type AS  $$
DECLARE
  username text;
  rec record;
  error_msg1 text;
  error_msg2 text;
  error_msg3 text; 
BEGIN 
  -- instance, user and activity id parameters are required
  IF ($1 IS NULL) AND ($2 IS NULL) AND ($3 IS NULL) THEN
    FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: Must included instance_id, user_id and activity_id data parameters.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
  END IF; 

  -- get users name
  SELECT INTO username _username FROM users WHERE users.id = $2;
  
  -- validate activity_id
  IF (SELECT * FROM pmt_validate_activity($3)) THEN  
    -- user must have 'delete' privilages to change active values
    IF (SELECT * FROM pmt_validate_user_authority($1, $2, $3, null, 'delete')) THEN
      -- set active values as requested       
      EXECUTE 'UPDATE activity SET _active = ' || $3 || ', _updated_by =' || quote_literal(username) || ', _updated_date = ' || quote_literal(current_date) || ' WHERE activity.id = ' || $3 || ';';
      EXECUTE 'UPDATE location SET _active = ' || $3 || ', _updated_by =' || quote_literal(username) || ', _updated_date = ' || quote_literal(current_date) || ' WHERE location.activity_id = ' || $3 || ';';
      EXECUTE 'UPDATE financial SET _active = ' || $3 || ', _updated_by =' || quote_literal(username) || ', _updated_date = ' || quote_literal(current_date) || ' WHERE financial.activity_id = ' || $3 || ';';
      EXECUTE 'UPDATE participation SET _active = ' || $3 || ', _updated_by =' || quote_literal(username) || ', _updated_date = ' || quote_literal(current_date) || ' WHERE participation.activity_id = ' || $3 || ';';
      EXECUTE 'UPDATE detail SET _active = ' || $3 || ', _updated_by =' || quote_literal(username) || ', _updated_date = ' || quote_literal(current_date) || ' WHERE detail.activity_id = ' || $3 || ';';
      EXECUTE 'UPDATE result SET _active = ' || $3 || ', _updated_by =' || quote_literal(username) || ', _updated_date = ' || quote_literal(current_date) || ' WHERE result.activity_id = ' || $3 || ';';
    ELSE
      FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: User does NOT have authority to change the active status of this activity and its assoicated records.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
    END IF;
  ELSE
    FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: Invalid activity_id.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
  END IF;

   -- editing completed successfullly
  FOR rec IN (SELECT row_to_json(j) FROM(select $3 as id, 'Success' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;        
    	  
EXCEPTION WHEN others THEN
      GET STACKED DIAGNOSTICS error_msg1 = MESSAGE_TEXT,
                          error_msg2 = PG_EXCEPTION_DETAIL,
                          error_msg3 = PG_EXCEPTION_HINT;
    FOR rec IN (SELECT row_to_json(j) FROM(select $3 as id, 'Internal Error - Contact your DBA with the following error message: ' || error_msg1 as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;	 
END; 
$$ LANGUAGE 'plpgsql';


/******************************************************************
5. update _user_instances to add data group information
  select * from _user_instances;
******************************************************************/
DROP VIEW IF EXISTS _user_instances;
CREATE OR REPLACE VIEW _user_instances AS 
  SELECT i.id as instance_id, i._theme as instance, data_group_ids, u.id as user_id, 
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
6. update pmt_validate_taxonomies for new data model
  select * from pmt_validate_taxonomies('15,14,1,6,99');
******************************************************************/
DROP FUNCTION IF EXISTS pmt_validate_taxonomies(character varying);
CREATE OR REPLACE FUNCTION pmt_validate_taxonomies(ids character varying)
  RETURNS integer[] AS 
$$
DECLARE 
  valid_taxonomy_ids INT[];
  filter_taxonomy_ids INT[];
BEGIN 
     IF $1 IS NULL THEN    
       RETURN valid_taxonomy_ids;
     END IF;

     filter_taxonomy_ids := string_to_array($1, ',')::int[];
     
     SELECT INTO valid_taxonomy_ids array_agg(DISTINCT id)::INT[] FROM (SELECT id FROM taxonomy WHERE _active = true AND id = ANY(filter_taxonomy_ids) ORDER BY id) AS t;
     
     RETURN valid_taxonomy_ids;

EXCEPTION
     WHEN others THEN RETURN NULL;
END;$$ LANGUAGE plpgsql;

/******************************************************************
 7. update pmt_validate_financial for new data model
 select * from pmt_validate_financial(27565);
 select * from financial
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_validate_financial(id integer) RETURNS boolean AS $$
DECLARE 
  valid_id integer;
  error_msg text;
BEGIN 
     IF $1 IS NULL THEN    
       RETURN false;
     END IF;    
     
     SELECT INTO valid_id financial.id FROM financial WHERE _active = true AND financial.id = $1;	 

     IF valid_id IS NULL THEN
      RETURN false;
     ELSE 
      RETURN true;
     END IF;
     
EXCEPTION WHEN others THEN
  GET STACKED DIAGNOSTICS error_msg = MESSAGE_TEXT;
  RAISE NOTICE 'Internal Error - Contact your DBA with the following error message: %', error_msg;
  RETURN FALSE;

END; 
$$ LANGUAGE 'plpgsql';

/******************************************************************
 8. update pmt_validate_financials for new data model
 select * from pmt_validate_financials('9999999,26371,26372,26373,26374');
 select * from financial
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_validate_financials(financial_ids character varying) RETURNS integer[] AS $$
DECLARE 
  valid_financial_ids INT[];
  filter_financial_ids INT[];
  error_msg text;
BEGIN 
     IF $1 IS NULL THEN    
       RETURN valid_financial_ids;
     END IF;

     filter_financial_ids := string_to_array($1, ',')::int[];
     
     SELECT INTO valid_financial_ids array_agg(DISTINCT id)::INT[] FROM (SELECT id FROM financial WHERE _active = true AND id = ANY(filter_financial_ids) ORDER BY id) AS f;
     
     RETURN valid_financial_ids;
     
EXCEPTION WHEN others THEN
  GET STACKED DIAGNOSTICS error_msg = MESSAGE_TEXT;
  RAISE NOTICE 'Internal Error - Contact your DBA with the following error message: %', error_msg;
  RETURN FALSE;

END; 
$$ LANGUAGE 'plpgsql';
/******************************************************************
 9. update pmt_validate_participation for new data model
 select * from pmt_validate_participation(37);
 select * from participation where _active = true
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_validate_participation(id integer) RETURNS boolean AS $$
DECLARE valid_id integer;
BEGIN 
     IF $1 IS NULL THEN    
       RETURN false;
     END IF;    
     
     SELECT INTO valid_id participation.id FROM participation WHERE _active = true AND participation.id = $1;	 

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
10. update pmt_edit_activity for new data model
select * from pmt_edit_activity(1,34,26326,null,'{"_title": "MERET PLUS Managing Environmental Resources to Ena…able Livelihoods Through Partnership and Land Use", "_start_date": "12/30/2006", "_end_date": "12/30/2011", "_description": "MERET is implemented through the Natural Resource …ality of the work before households receive food."}', false);
select * from pmt_edit_activity(1,34,null,2237,'{"_title": "AAA", "_start_date": "5/2/2017", "_end_date": "5/31/2017", "_description": null}', false);
select * from activity where id = 26326
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

  -- if activity_id is null then validate users authroity to create a new activity record  
  IF ($3 IS NULL) THEN       
      IF (SELECT * FROM pmt_validate_user_authority($1, $2, null, $4, 'create')) THEN
        EXECUTE 'INSERT INTO activity(data_group_id, _created_by, _updated_by) VALUES (' || $4 || ',' || quote_literal(username) || ',' || quote_literal(username) || ') RETURNING id;' INTO new_activity_id;
        RAISE NOTICE 'Created new activity with id: %', new_activity_id;
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

/******************************************************************
11. update pmt_edit_activity_taxonomy for the new data model
select * from pmt_edit_activity_taxonomy(1,34,'26326','797,2239,2418,2435,659,660,661,724,726,736,677,680,731',null,'replace');
select * from pmt_edit_activity_taxonomy(1,34,'26326',null,'69,74','delete');
select * from pmt_edit_activity_taxonomy(57,'10814','788','replace') -- pass 
******************************************************************/
DROP FUNCTION IF EXISTS pmt_edit_activity_taxonomy(integer, character varying, character varying, character varying, pmt_edit_action);
CREATE OR REPLACE FUNCTION pmt_edit_activity_taxonomy(instance_id integer, user_id integer, activity_ids character varying, classification_ids character varying, taxonomy_ids character varying, edit_action pmt_edit_action) RETURNS SETOF pmt_json_result_type AS  
$$
DECLARE
  valid_classification_ids integer[];	-- valid classification_ids from parameter
  valid_activity_ids integer[];    	-- valid activity_ids from parameter
  valid_taxonomy_ids integer[];	-- valid taxonomy_ids from parameter
  a_id integer;				-- activity_id
  c_id integer;				-- classification_id
  t_id integer;				-- taxonomy_id
  at_id integer;			-- activity_taxonomy activity_id
  tc record;				-- taxonomy_classifications record
  rec record;				
  error_msg1 text;
BEGIN	
  
  -- instance_id is required for all operations
  IF ($1 IS NULL) THEN
    FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: instance_id is a required parameter for all operations.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
  END IF;
  -- user_id is required for all operations
  IF ($2 IS NULL) THEN
    FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: user_id is a required parameter for all operations.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
  END IF;
  -- activity_ids is required for all operations
  IF ($3 IS NULL OR $3 = '') THEN
    FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: activity_ids is a required parameter for all operations.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
  END IF;
  -- edit_action is required for all operations
  IF ($6 IS NULL) THEN
    FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: edit_action is a required parameter for all operations.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
  END IF;
  -- classification_ids are required for add & replace, and delete only if taxonomy_ids is null
  -- taxonomy_ids is only required for delete, if classification_ids is null
  IF ($6 = 'delete') THEN
    -- classification_ids OR taxonomy_ids are required for delete
    IF ($4 IS NULL OR $4 = '') AND ($5 IS NULL OR $5 = '') THEN
      FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: classification_ids or taxonomy_ids are a required parameter for delete operations.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
    END IF;
  ELSE
    -- classification_ids are required for add & replace
    IF ($4 IS NULL OR $4 = '') THEN
      FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: classification_ids is a required parameter for all operations.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
    END IF;
  END IF;
    
  -- validate activity_ids
  SELECT INTO valid_activity_ids * FROM pmt_validate_activities($3);
  -- validate classification_ids
  SELECT INTO valid_classification_ids * FROM pmt_validate_classifications($4);
  -- validate taxonomy_ids
  SELECT INTO valid_taxonomy_ids * FROM pmt_validate_taxonomies($5);
    
  -- must provide a min of one valid activity_id to continue
  IF valid_activity_ids IS NULL THEN
    FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: Must provide at least one valid activity_id.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
  END IF;

  IF $6 = 'delete' THEN
    -- must provide a min of one valid classification_id or taxonomy_id to continue
    IF valid_classification_ids IS NULL AND valid_taxonomy_ids IS NULL THEN
      FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: Must provide at least one valid classification_id or taxonomy_id.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
    END IF;
  ELSE
    -- must provide a min of one valid classification_id to continue
    IF valid_classification_ids IS NULL THEN
      FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: Must provide at least one valid classification_id.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
    END IF;
  END IF;
  
  -- on delete actions with taxonomy_ids
  IF $6 = 'delete' AND valid_taxonomy_ids IS NOT NULL THEN
    -- loop through the valid taxonomy ids
    FOR t_id IN EXECUTE 'SELECT id FROM taxonomy WHERE id = ANY(ARRAY[' || array_to_string(valid_taxonomy_ids, ',') || '])' LOOP
      FOREACH a_id IN ARRAY valid_activity_ids LOOP 
        -- validate users authority to add/delete/update an activity's classifications (use update for all taxonomy operations)
	IF (SELECT * FROM pmt_validate_user_authority($1, $2, a_id, null, 'update')) THEN 
          EXECUTE 'DELETE FROM activity_taxonomy WHERE activity_id ='|| a_id ||' AND classification_id IN (SELECT id FROM classification WHERE taxonomy_id = '|| t_id || ') AND _field = ''id'''; 
          RAISE NOTICE 'Delete Record: %', 'Remove association to taxonomy id ('|| t_id ||') for actvity id ('|| a_id ||')';	   
        ELSE
          RAISE NOTICE'User does not have update authorization on activity (id: %), which is required to edit activity taxonomies.', a_id;
        END IF;
      END LOOP;
    END LOOP;    
    -- editing completed successfullly
    FOR rec IN (SELECT row_to_json(j) FROM(select $3 as activity_ids, 'Success' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN; 
  END IF;
  
  -- loop through sets of valid classification_ids by taxonomy
  FOR tc IN EXECUTE 'SELECT taxonomy_id::integer, array_agg(classification_id)::integer[] AS classification_id FROM _taxonomy_classifications  tc ' ||
	'WHERE classification_id = ANY(ARRAY['|| array_to_string(valid_classification_ids, ',') || ']) GROUP BY taxonomy_id ORDER BY taxonomy_id ' LOOP       
    -- operations based on edit_action
    CASE $6  
      WHEN 'delete' THEN
        FOREACH a_id IN ARRAY valid_activity_ids LOOP 
          -- validate users authority to add/delete/update an activity's classifications (use update for all taxonomy operations)
	  IF (SELECT * FROM pmt_validate_user_authority($1, $2, a_id, null, 'update')) THEN 
            EXECUTE 'DELETE FROM activity_taxonomy WHERE activity_id ='|| a_id ||' AND classification_id = ANY(ARRAY['|| array_to_string(tc.classification_id, ',') ||']) AND _field = ''id'''; 
            RAISE NOTICE 'Delete Record: %', 'Remove association to classification_id(s) ('|| array_to_string(tc.classification_id, ',') ||') for actvity id ('|| a_id ||')';	   
          ELSE
            RAISE NOTICE'User does not have update authorization on activity (id: %), which is required to edit activity taxonomies.', a_id;
          END IF;
        END LOOP;
      WHEN 'replace' THEN
        FOREACH a_id IN ARRAY valid_activity_ids LOOP 
          -- validate users authority to add/delete/update an activity's classifications (use update for all taxonomy operations)
	  IF (SELECT * FROM pmt_validate_user_authority($1, $2, a_id, null, 'update')) THEN 
            -- remove all classifications for given taxonomy 
            EXECUTE 'DELETE FROM activity_taxonomy WHERE activity_id ='|| a_id ||' AND classification_id in ' ||
                 '(SELECT classification_id FROM _taxonomy_classifications WHERE taxonomy_id = '|| tc.taxonomy_id||') AND _field = ''id''';
            RAISE NOTICE 'Delete Record: %', 'Remove association to taxonomy_id ('|| tc.taxonomy_id ||') for actvity id ('|| a_id ||')';
            -- insert all classification_ids for this taxonomy
	    EXECUTE 'INSERT INTO activity_taxonomy(activity_id, classification_id, _field) SELECT '|| a_id ||', id, ''id'' FROM ' ||
	       'classification WHERE id IN (' || array_to_string(tc.classification_id, ',') || ')'; 
            RAISE NOTICE 'Add Record: %', 'Activity_id ('|| a_id ||') is now associated to classification_ids ('|| array_to_string(tc.classification_id, ',') ||').';  
          ELSE
            RAISE NOTICE'User does not have update authorization on activity (id: %), which is required to edit activity taxonomies.', a_id;
          END IF;
        END LOOP;
      -- add (DEFAULT)
      ELSE
        FOREACH a_id IN ARRAY valid_activity_ids LOOP 
          FOREACH c_id IN ARRAY tc.classification_id LOOP
            -- validate users authority to add/delete/update an activity's classifications (use update for all taxonomy operations)
	    IF (SELECT * FROM pmt_validate_user_authority($1, $2, a_id, null, 'update')) THEN 
              -- check to see if this classification is already assoicated to the activity
              SELECT INTO at_id activity_id FROM activity_taxonomy as at WHERE at.activity_id = a_id AND at.classification_id = c_id LIMIT 1;
              IF at_id IS NULL THEN
                EXECUTE 'INSERT INTO activity_taxonomy(activity_id, classification_id, _field) VALUES ('|| a_id ||', '|| c_id ||', ''id'')';
                RAISE NOTICE 'Add Record: %', 'Activity_id ('|| a_id ||') is now associated to classification_id ('|| c_id ||').'; 
              ELSE
                RAISE NOTICE'Add Record: %', 'This activity_id ('|| a_id ||') already has an association to this classification_id ('|| c_id ||').';                
              END IF;
            ELSE
              RAISE NOTICE'User does not have update authorization on activity (id: %), which is required to edit activity taxonomies.', a_id;
            END IF;
          END LOOP;
        END LOOP;
    END CASE;
  END LOOP;    

  -- editing completed successfullly
  FOR rec IN (SELECT row_to_json(j) FROM(select $3 as activity_ids, 'Success' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN; 
 	
EXCEPTION WHEN others THEN
  GET STACKED DIAGNOSTICS error_msg1 = MESSAGE_TEXT;
  FOR rec IN (SELECT row_to_json(j) FROM(select a_id as id, 'Internal Error - Contact your DBA with the following error message: ' || error_msg1 as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;	  

END;$$ LANGUAGE plpgsql;

/******************************************************************
 12. update pmt_edit_financial for new data model
******************************************************************/
DROP FUNCTION IF EXISTS pmt_edit_financial(integer, integer, integer, integer, json, boolean);
CREATE OR REPLACE FUNCTION pmt_edit_financial(instance_id integer, user_id integer, activity_id integer, financial_id integer, key_value_data json, delete_record boolean default false) 
RETURNS SETOF pmt_json_result_type AS 
$$
DECLARE
  activity_record record;
  f_id integer;
  json record;
  column_record record;
  execute_statement text;
  invalid_editing_columns text[];
  username text;
  rec record;
  error_msg text;
BEGIN	
  -- simulate database error 
  -- FOR rec IN (SELECT row_to_json(j) FROM(select financial_id as id, 'Error: simulating a database error.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
  
  -- set columns that are not editable via the parameters 
  invalid_editing_columns := ARRAY['id', 'activity_id', '_active', '_retired_by', '_created_by', '_created_date', '_updated_by', '_updated_date'];
  
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
      SELECT INTO activity_record * FROM activity WHERE id = $3;
    ELSE
      FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: Invalid activity_id.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
    END IF;
  END IF;

  -- update/create operation
  IF NOT ($6) THEN
    -- json is required
    IF ($5 IS NULL) THEN
      FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: The json parameter is required for a create/update operation.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
    END IF;      
  -- delete operation	
  ELSE
    -- financial_id is requried
    IF ($4 IS NULL) THEN
      FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: financial_id is required for a delete operation.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
    END IF;
  END IF;

  -- get users name
  SELECT INTO username _username FROM users WHERE users.id = $2;

  -- validate users authority to update the activity record
  IF NOT (SELECT * FROM pmt_validate_user_authority($1, $2, activity_record.id, null, 'update')) THEN
    FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: User does NOT have authority to upadate/create a new financial record for activity id ' || activity_record.id as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
  END IF;  
    
  -- if financial_id is null then validate users authroity to create a new financial record  
  IF ($4 IS NULL) THEN   
    -- create new financial record for activity
    EXECUTE 'INSERT INTO financial(activity_id, _created_by, _updated_by) VALUES (' || activity_record.id || ',' || quote_literal(username) || ',' 
		|| quote_literal(username) || ') RETURNING id;' INTO f_id;
    RAISE NOTICE 'Created new financial with id: %', f_id;   
  -- validate financial_id if provided and validate users authority to update an existing record  
  ELSE  
    -- validate financial_id
    IF (SELECT * FROM pmt_validate_financial($4)) THEN 
      f_id := $4;     
      -- 'delete' this financial record
      IF ($6) THEN
          EXECUTE 'DELETE FROM financial_taxonomy WHERE financial_id = ' || $4;
          EXECUTE 'DELETE FROM financial WHERE id = ' || $4;
      END IF;
    ELSE
      FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: Invalid financial_id.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
    END IF;
  END IF;
  
  -- loop through the columns of the financial table        
  FOR json IN (SELECT * FROM json_each_text($5)) LOOP
    RAISE NOTICE 'JSON key/value: %', lower(json.key) || ':' || json.value;
    -- get the column information for column that user is requesting to edit	
    FOR column_record IN (SELECT * FROM information_schema.columns WHERE table_schema='public' AND table_name='financial' AND column_name != ALL(invalid_editing_columns) AND lower(column_name) = lower(json.key)) LOOP 
      RAISE NOTICE 'Editing column: %', column_record.column_name;
      RAISE NOTICE 'Assigning new value: %', json.value;
      execute_statement := null;
      CASE column_record.data_type 
        WHEN 'integer', 'numeric' THEN              
          IF (SELECT pmt_isnumeric(json.value)) THEN
            execute_statement := 'UPDATE financial SET ' || column_record.column_name || ' = ' || json.value || ' WHERE id = ' || f_id; 
          END IF;
          IF (lower(json.value) = 'null') THEN
            execute_statement := 'UPDATE financial SET ' || column_record.column_name || ' = null WHERE id = ' || f_id; 
          END IF;
        ELSE
          -- if the value has the text null then assign the column value null
          IF (lower(json.value) = 'null') THEN
            execute_statement := 'UPDATE financial SET ' || column_record.column_name || ' = null WHERE id = ' || f_id; 
          ELSE
            execute_statement := 'UPDATE financial SET ' || column_record.column_name || ' = ' || quote_literal(json.value) || ' WHERE id = ' || f_id; 
          END IF;
      END CASE;
      IF execute_statement IS NOT NULL THEN
        RAISE NOTICE 'Statement: %', execute_statement;
        EXECUTE execute_statement;
                
        EXECUTE 'UPDATE financial SET _updated_by = ' || quote_literal(username) || ', _updated_date = ' || quote_literal(current_date) || ' WHERE  id = ' || f_id;
      END IF;
    END LOOP;
  END LOOP;
  -- editing completed successfullly
  FOR rec IN (SELECT row_to_json(j) FROM(select f_id as id, 'Success' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;         
  
EXCEPTION WHEN others THEN
     GET STACKED DIAGNOSTICS error_msg = MESSAGE_TEXT;
    FOR rec IN (SELECT row_to_json(j) FROM(select f_id as id, 'Internal Error - Contact your DBA with the following error message: ' || error_msg as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;	  
END;$$ LANGUAGE plpgsql;

/******************************************************************
13. update pmt_edit_financial_taxonomy for the new data model
select * from pmt_edit_financial_taxonomy(27,'8061,8062,8063,8064,8065,8066,8067','419',null,'delete') -- pass
select * from pmt_edit_financial_taxonomy(27,'8061,8062,8063,8064,8065,8066,8067','419',null,'add') -- pass
select * from pmt_edit_financial_taxonomy(1,34,'26945','1930,2200',null,'replace') -- pass
select * from classification where id = 1930
select * from _activity_financials where financial_id = 26945
******************************************************************/
DROP FUNCTION IF EXISTS pmt_edit_financial_taxonomy(integer, character varying, character varying, character varying, pmt_edit_action);
CREATE OR REPLACE FUNCTION pmt_edit_financial_taxonomy(instance_id integer, user_id integer, financial_ids character varying, classification_ids character varying, taxonomy_ids character varying, edit_action pmt_edit_action) RETURNS SETOF pmt_json_result_type AS  
$$
DECLARE
  valid_classification_ids integer[]; 	-- valid classification_ids from parameter
  valid_financial_ids integer[];     	-- valid financial_ids from parameter
  valid_taxonomy_ids integer[];     	-- valid taxonomy_ids from parameter
  a_id integer;				-- activity_id
  f_id integer; 		      	-- financial_id
  c_id integer;       			-- classification_id
  p_id integer;       			-- project_id
  t_id integer;       			-- taxonomy_id
  ft_id integer;      			-- financial_taxonomy financial_id
  tc record;        			-- taxonomy_classifications record
  rec record;
  error_msg text;
BEGIN 

  -- instance_id is required for all operations
  IF ($1 IS NULL) THEN
    FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: instance_id is a required parameter for all operations.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
  END IF;
  -- user_id is required for all operations
  IF ($2 IS NULL) THEN
    FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: user_id is a required parameter for all operations.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
  END IF;
  -- financial_ids is required for all operations
  IF ($3 IS NULL OR $3 = '') THEN
    FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: financial_ids is a required parameter for all operations.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
  END IF;
  -- edit_action is required for all operations
  IF ($6 IS NULL) THEN
    FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: edit_action is a required parameter for all operations.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
  END IF;
  -- classification_ids are required for add & replace, and delete only if taxonomy_ids is null
  -- taxonomy_ids is only required for delete, if classification_ids is null
  IF ($6 = 'delete') THEN
    -- classification_ids OR taxonomy_ids are required for delete
    IF ($4 IS NULL OR $4 = '') AND ($5 IS NULL OR $5 = '') THEN
      FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: classification_ids or taxonomy_ids are a required parameter for delete operations.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
    END IF;
  ELSE
    -- classification_ids are required for add & replace
    IF ($4 IS NULL OR $4 = '') THEN
      FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: classification_ids is a required parameter for all operations.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
    END IF;
  END IF;
    
  -- validate financial_ids
  SELECT INTO valid_financial_ids * FROM pmt_validate_financials($3);
  -- validate classification_ids
  SELECT INTO valid_classification_ids * FROM pmt_validate_classifications($4);
  -- validate taxonomy_ids
  SELECT INTO valid_taxonomy_ids * FROM pmt_validate_taxonomies($5);
    
  -- must provide a min of one valid financial_id to continue
  IF valid_financial_ids IS NULL THEN
    FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: Must provide at least one valid financial_id.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
  END IF;

  IF $6 = 'delete' THEN
    -- must provide a min of one valid classification_id or taxonomy_id to continue
    IF valid_classification_ids IS NULL AND valid_taxonomy_ids IS NULL THEN
      FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: Must provide at least one valid classification_id or taxonomy_id.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
    END IF;
  ELSE
    -- must provide a min of one valid classification_id to continue
    IF valid_classification_ids IS NULL THEN
      FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: Must provide at least one valid classification_id.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
    END IF;
  END IF;
  
  -- on delete actions with taxonomy_ids
  IF $6 = 'delete' AND valid_taxonomy_ids IS NOT NULL THEN
    -- loop through the valid taxonomy ids
    FOR t_id IN EXECUTE 'SELECT id FROM taxonomy WHERE id = ANY(ARRAY[' || array_to_string(valid_taxonomy_ids, ',') || '])' LOOP
      FOREACH f_id IN ARRAY valid_financial_ids LOOP 
        SELECT INTO a_id activity_id FROM financial WHERE id = f_id;
        -- validate users authority to add/delete/update an activity's financial classifications (use update for all taxonomy operations)
	IF (SELECT * FROM pmt_validate_user_authority($1, $2, a_id, null, 'update')) THEN 
          EXECUTE 'DELETE FROM financial_taxonomy WHERE financial_id ='|| f_id ||' AND classification_id IN (SELECT id FROM classification WHERE taxonomy_id = '|| t_id || ') AND _field = ''id'''; 
          RAISE NOTICE 'Delete Record: %', 'Remove association to taxonomy id ('|| t_id ||') for financial id ('|| f_id ||')';	   
        ELSE
          RAISE NOTICE'User does not have update authorization on activity (id: %), which is required to edit activity financials.', a_id;
        END IF;
      END LOOP;
    END LOOP;    
    -- editing completed successfullly
    FOR rec IN (SELECT row_to_json(j) FROM(select $3 as activity_ids, 'Success' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN; 
  END IF;
  
  -- loop through sets of valid classification_ids by taxonomy
  FOR tc IN EXECUTE 'SELECT taxonomy_id::integer, array_agg(classification_id)::integer[] AS classification_id FROM _taxonomy_classifications  tc ' ||
	'WHERE classification_id = ANY(ARRAY['|| array_to_string(valid_classification_ids, ',') || ']) GROUP BY taxonomy_id ORDER BY taxonomy_id ' LOOP       
    -- operations based on edit_action
    CASE $6  
      WHEN 'delete' THEN
        FOREACH f_id IN ARRAY valid_financial_ids LOOP 
          SELECT INTO a_id activity_id FROM financial WHERE id = f_id;
          -- validate users authority to add/delete/update an activity's financial classifications (use update for all taxonomy operations)
	  IF (SELECT * FROM pmt_validate_user_authority($1, $2, a_id, null, 'update')) THEN 
            EXECUTE 'DELETE FROM financial_taxonomy WHERE financial_id ='|| f_id ||' AND classification_id = ANY(ARRAY['|| array_to_string(tc.classification_id, ',') ||']) AND _field = ''id'''; 
            RAISE NOTICE 'Delete Record: %', 'Remove association to classification_id(s) ('|| array_to_string(tc.classification_id, ',') ||') for financial id ('|| f_id ||')';	   
          ELSE
            RAISE NOTICE'User does not have update authorization on activity (id: %), which is required to edit activity financials.', a_id;
          END IF;
        END LOOP;
      WHEN 'replace' THEN
        FOREACH f_id IN ARRAY valid_financial_ids LOOP 
          SELECT INTO a_id activity_id FROM financial WHERE id = f_id;
          -- validate users authority to add/delete/update an activity's financial classifications (use update for all taxonomy operations)
	  IF (SELECT * FROM pmt_validate_user_authority($1, $2, a_id, null, 'update')) THEN 
            -- remove all classifications for given taxonomy 
            EXECUTE 'DELETE FROM financial_taxonomy WHERE financial_id ='|| f_id ||' AND classification_id in ' ||
                 '(SELECT classification_id FROM _taxonomy_classifications WHERE taxonomy_id = '|| tc.taxonomy_id||') AND _field = ''id''';
            RAISE NOTICE 'Delete Record: %', 'Remove association to taxonomy_id ('|| tc.taxonomy_id ||') for financial id ('|| f_id ||')';
            -- insert all classification_ids for this taxonomy
	    EXECUTE 'INSERT INTO financial_taxonomy(financial_id, classification_id, _field) SELECT '|| f_id ||', id, ''id'' FROM ' ||
	       'classification WHERE id IN (' || array_to_string(tc.classification_id, ',') || ')'; 
            RAISE NOTICE 'Add Record: %', 'Financial_id ('|| f_id ||') is now associated to classification_ids ('|| array_to_string(tc.classification_id, ',') ||').';  
          ELSE
            RAISE NOTICE'User does not have update authorization on activity (id: %), which is required to edit activity financial taxonomies.', a_id;
          END IF;
        END LOOP;
      -- add (DEFAULT)
      ELSE
        FOREACH f_id IN ARRAY valid_financial_ids LOOP 
          SELECT INTO a_id activity_id FROM financial WHERE id = f_id;
          FOREACH c_id IN ARRAY tc.classification_id LOOP
            -- validate users authority to add/delete/update an activity's financial classifications (use update for all taxonomy operations)
	    IF (SELECT * FROM pmt_validate_user_authority($1, $2, a_id, null, 'update')) THEN 
              -- check to see if this classification is already assoicated to the activity
              SELECT INTO ft_id financial_id FROM financial_taxonomy as ft WHERE ft.financial_id = f_id AND ft.classification_id = c_id LIMIT 1;
              IF ft_id IS NULL THEN
                EXECUTE 'INSERT INTO financial_taxonomy(financial_id, classification_id, _field) VALUES ('|| f_id ||', '|| c_id ||', ''id'')';
                RAISE NOTICE 'Add Record: %', 'Finicial_id ('|| f_id ||') is now associated to classification_id ('|| c_id ||').'; 
              ELSE
                RAISE NOTICE'Add Record: %', 'This financial_id ('|| f_id ||') already has an association to this classification_id ('|| c_id ||').';                
              END IF;
            ELSE
              RAISE NOTICE'User does not have update authorization on activity (id: %), which is required to edit activity financial taxonomies.', a_id;
            END IF;
          END LOOP;
        END LOOP;
    END CASE;
  END LOOP;    

  -- editing completed successfullly
  FOR rec IN (SELECT row_to_json(j) FROM(select $3 as financial_ids, 'Success' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN; 
 	
EXCEPTION WHEN others THEN
  GET STACKED DIAGNOSTICS error_msg = MESSAGE_TEXT;
  FOR rec IN (SELECT row_to_json(j) FROM(select f_id as id, 'Internal Error - Contact your DBA with the following error message: ' || error_msg as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;	  

END;$$ LANGUAGE plpgsql;

/******************************************************************
14. update pmt_edit_participation for new data model
 select * from pmt_edit_participation(1,34,26326,3124,89115,'494','replace');
 select * from pmt_edit_participation(1,34,26326,3335,null,'494','add');
 select * from pmt_edit_participation(1,34,26269,3461,95742,null,'delete');
******************************************************************/
DROP FUNCTION IF EXISTS pmt_edit_participation(integer, integer, integer, integer, integer, character varying, pmt_edit_action);
CREATE OR REPLACE FUNCTION pmt_edit_participation(instance_id integer, user_id integer, activity_id integer, organization_id integer, participation_id integer, classification_ids character varying, edit_action pmt_edit_action) RETURNS SETOF pmt_json_result_type AS 
$$
DECLARE
  c_ids integer array;  
  c_id integer;
  id integer;
  record_id integer;
  record_is_active boolean;
  tax_ct integer;
  username text;
  rec record;
  error_message text;
  error_msg text;
BEGIN 
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
    IF NOT (SELECT * FROM pmt_validate_activity($3)) THEN  
      FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: Invalid activity_id.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
    END IF;
  END IF;
  -- organization_id is required for all operations
  IF ($4 IS NULL) THEN
    FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: organization_id is a required parameter for all operations.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
  ELSE
     -- validate the associated organization record
    IF NOT (SELECT * FROM pmt_validate_organization($4)) THEN  
      FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: Invalid organization_id.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
    END IF;
  END IF;
  -- validate the participation_id
  IF ($5 IS NOT NULL) THEN
    IF (SELECT * FROM pmt_validate_participation($5)) THEN
      record_id := $5;
    ELSE
      FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: Invalid participation_id.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
    END IF;
  ELSE
    -- participation_id is required for replace & delete
    IF ($7 <> 'add') THEN
      FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: participation_id is a required parameter for replace/delete operations.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
    END IF;
  END IF;
    -- validate classification_id if provided
  IF ($6 IS NOT NULL) THEN
    SELECT INTO c_ids * FROM pmt_validate_classifications($6);        
    SELECT INTO c_ids array_agg(tc.classification_id) from _taxonomy_classifications tc where tc.taxonomy = 'Organisation Role' AND tc.classification_id = ANY(c_ids);
    IF c_ids IS NULL THEN
      FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: Provided classification_ids are not in the Organisation Role taxonomy or are inactive.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
    END IF;    
  END IF;
  -- edit_action is required for all operations
  IF ($7 IS NULL) THEN
    FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: edit_action is a required parameter for all operations.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
  END IF;
  
  -- get users name
  SELECT INTO username _username FROM users WHERE users.id = $2;
  
  -- operations based on the requested edit action
  CASE $7
    WHEN 'delete' THEN 
      -- validate users authority to perform an update action on this project
      IF (SELECT * FROM pmt_validate_user_authority($1, $2, $3, null, 'update')) THEN      
        EXECUTE 'DELETE FROM participation_taxonomy WHERE participation_id ='|| $5;
        EXECUTE 'DELETE FROM participation WHERE id ='|| $5; 
        RAISE NOTICE 'Delete Record: %', 'Deactivated participation record: ('|| $5 ||')';
      ELSE
        FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: The requested edit action requires the user to have UPDATE rights to this activity: ' || $3 as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;     
      END IF; 
    WHEN 'replace' THEN            
      -- check for required parameters
      IF ($3 IS NULL) OR ($4 IS NULL) OR ($5 IS NULL) OR (c_ids IS NULL) THEN
        FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: Must have activity_id, organization_id, participation_id and classification_id parameters when edit action is: ' || $7 as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;     
      END IF;
      -- validate users authority to perform an update on the activity
      IF (SELECT * FROM pmt_validate_user_authority($1, $2, $3, null, 'update')) THEN      
	-- delete all taxonomy records for participation 
	EXECUTE 'DELETE FROM participation_taxonomy WHERE participation_id ='|| $5;
	-- update record
	EXECUTE 'UPDATE participation SET activity_id = ' || $3 || ', organization_id = ' || $4 || ', _updated_by = ' || quote_literal(username) || ', _updated_date = ' || quote_literal(current_date) || ' WHERE id = '|| $5;
	-- add taxonomy records
	EXECUTE 'INSERT INTO participation_taxonomy(participation_id, classification_id, _field) SELECT '|| $5 ||', id, ''id'' FROM ' ||
	       'classification WHERE id IN (' || array_to_string(c_ids, ',') || ')';             
      ELSE
        FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: The requested edit action requires the user to have UPDATE rights to this activity: ' || $3 as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;     
      END IF;
    -- add (action)
    ELSE
      -- check for required parameters
      IF ($3 IS NULL) OR ($4 IS NULL) OR (c_ids IS NULL) THEN
        FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: Must have activity_id, organization_id and classification_id parameters when edit action is: ' || $7 as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;     
      END IF;
      -- validate users authority to perform a create action on this project
      IF (SELECT * FROM pmt_validate_user_authority($1, $2, $3, null, 'update')) THEN
        -- determine if requested particpation record currently exists                   
        SELECT INTO record_id pp.id FROM participation pp WHERE pp.activity_id = $3 AND pp.organization_id = $4;          
        -- the requested participation record exists
        IF (record_id IS NOT NULL) THEN            
	  -- delete all taxonomy records for participation 
	  EXECUTE 'DELETE FROM participation_taxonomy WHERE participation_id ='|| record_id;
	  -- add taxonomy records
	  EXECUTE 'INSERT INTO participation_taxonomy(participation_id, classification_id, _field) SELECT '|| record_id ||', id, ''id'' FROM ' ||
	       'classification WHERE id IN (' || array_to_string(c_ids, ',') || ')';                                     
	-- the requested participation record does NOT exist
	ELSE
	  -- create the participation record
	  EXECUTE 'INSERT INTO participation(activity_id, organization_id, _created_by, _updated_by) VALUES (' || $3 || ',' || $4 ||  ',' || quote_literal(username) || ',' || quote_literal(username) || ') RETURNING id;' INTO record_id;
	  -- add taxonomy records
	  EXECUTE 'INSERT INTO participation_taxonomy(participation_id, classification_id, _field) SELECT '|| record_id ||', id, ''id'' FROM ' ||
	       'classification WHERE id IN (' || array_to_string(c_ids, ',') || ')';
	END IF;
      ELSE
        FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: The requested edit action requires the user to have UPDATE rights to this activity: ' || $3 as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;     
      END IF;        
  END CASE;

  -- editing completed successfullly
  FOR rec IN (SELECT row_to_json(j) FROM(select record_id as id, 'Success' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;         
  
EXCEPTION WHEN others THEN
     GET STACKED DIAGNOSTICS error_msg = MESSAGE_TEXT;
    FOR rec IN (SELECT row_to_json(j) FROM(select record_id as id, 'Internal Error - Contact your DBA with the following error message: ' || error_msg as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
      
END;$$ LANGUAGE plpgsql;


/******************************************************************
15. update pmt_full_record to return participation id and rename
to pmt_activity_detail
  SELECT * FROM pmt_activity_detail(26326);
******************************************************************/
DROP FUNCTION IF EXISTS pmt_full_record(integer);
CREATE OR REPLACE FUNCTION pmt_activity_detail(activity_id integer) RETURNS SETOF pmt_json_result_type AS 
$$
DECLARE
  rec record;
  invalid_return_columns text[];
  return_columns text;
  execute_statement text;
  data_message text;
BEGIN
  IF $1 IS NOT NULL THEN	
    -- get list of columns to return
    SELECT INTO return_columns array_to_string(array_agg('a.' || column_name::text), ', ') FROM information_schema.columns 
    WHERE table_schema='public' AND table_name='activity';

    -- dynamically build the execute statment	
    execute_statement := 'SELECT ' || return_columns || ', (SELECT _name FROM classification WHERE id = data_group_id) as data_group' || 
				', (SELECT _title FROM activity WHERE id = a.parent_id) as parent_title, l.ct ';

    -- taxonomy	
    execute_statement := execute_statement || ',(SELECT array_to_json(array_agg(row_to_json(t))) FROM ( ' ||
				'select tc.taxonomy_id, tc.taxonomy, tc.classification_id, tc.classification, tc._code ' ||
				'from activity_taxonomy at ' ||
				'join _taxonomy_classifications  tc ' ||
				'on at.classification_id = tc.classification_id ' ||
				'and at.activity_id = ' || $1 ||
				') t ) as taxonomy ';
    -- organizations			
    execute_statement := execute_statement || ',(SELECT array_to_json(array_agg(row_to_json(p))) FROM ( ' ||
				'select p.id as p_id, o.id, o._name, tc.classification_id, tc.classification ' ||
				'from (select * from participation where _active = true and activity_id = ' || $1 || ') p  ' ||
  				'left join organization o ON p.organization_id = o.id '  ||
  				'left join participation_taxonomy pt ON p.id = pt.participation_id '  ||
  				'left join _taxonomy_classifications tc ON pt.classification_id = tc.classification_id '  ||
				') p ) as organizations ';
				
    -- contacts
    execute_statement := execute_statement || ',(SELECT array_to_json(array_agg(row_to_json(c))) FROM ( ' ||
				'select c.id, c._first_name, c._last_name, c._email, c.organization_id, o._name ' ||
				'from activity_contact ac ' ||
				'join contact c ' ||
				'on ac.contact_id = c.id ' ||
				'left join organization o ' ||
				'on c.organization_id = o.id ' ||
				'where c._active = true and ac.activity_id = ' || $1 ||
				') c ) as contacts ';	

    -- financials
    execute_statement := execute_statement || ',(SELECT array_to_json(array_agg(row_to_json(f))) FROM ( ' ||
				'select f.id, f._amount, f._start_date, f._end_date'  ||
						',provider_id' ||
						',(SELECT _name FROM organization WHERE id = provider_id) as provider' ||
						',recipient_id' ||
						',(SELECT _name FROM organization WHERE id = recipient_id) as recipient' ||
						', (SELECT array_to_json(array_agg(row_to_json(t))) FROM ( ' ||
						'select tc.taxonomy_id, tc.taxonomy, tc.classification_id, tc.classification, tc._code ' ||
						'from financial_taxonomy ft ' ||
						'join _taxonomy_classifications tc ' ||
						'on ft.classification_id = tc.classification_id ' ||
						'and ft.financial_id = f.id ' ||
						') t ) as taxonomy ' ||
				'from financial f ' ||		
				'where f._active = true and f.activity_id = ' || $1 ||
				') f ) as financials ';

    -- locations
    execute_statement := execute_statement || ',(SELECT array_to_json(array_agg(row_to_json(l))) FROM (  ' ||
				'select l.id, l._admin0, l._admin1, l._admin2, l._admin3, l._admin_level, l.boundary_id, l.feature_id ' ||
				'from location l ' ||		
				'where l._active = true and l.activity_id = ' || $1 ||
				') l ) as locations ';		

    -- children
    execute_statement := execute_statement || ',(SELECT array_to_json(array_agg(row_to_json(a))) FROM (  ' ||
				'select a.id, a._title ' ||					
				'from activity a ' ||		
				'where a._active = true and a.parent_id = ' || $1 ||
				') a ) as children ';	
													
								
    -- activity
    execute_statement := execute_statement || 'from (select * from activity a where a._active = true and a.id = ' || $1 || ') a ';
    -- locations
    execute_statement := execute_statement || 'left join ' ||
				'(select ll.activity_id, count(distinct ll.location_id) as ct ' ||
				'from _location_lookup ll ' ||
				'where ll.activity_id = ' || $1 ||
				'group by ll.activity_id) l ' ||
				'on a.id = l.activity_id ';


RAISE NOTICE 'Execute statement: %', execute_statement;			

FOR rec IN EXECUTE 'SELECT row_to_json(j) FROM (' || execute_statement || ')j' LOOP  		
	RETURN NEXT rec;
END LOOP;
   END IF;
END;$$ LANGUAGE plpgsql;

/******************************************************************
 16. update pmt_edit_location for new data model
 --- can only create or delete locations
 --- required: boundary_id & feature_id OR point pmt_validate_boundary_feature
 --- admin_level
 select * from pmt_edit_location(1,34,26253,null,13,59,2,'{"_admin0": "Ethiopida", "_admin1": "Tigray", "_admin2": "Southern"}', false);
 select * from pmt_edit_location(1,34,26253,50805,null,null,null,null,true);
 select id, _name, _eth_1_name, boundary_id from eth_2 order by 3,2
 select id, activity_id, boundary_id, feature_id, _point from location where _active = true limit 100
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
  -- editing completed successfullly
  FOR rec IN (SELECT row_to_json(j) FROM(select l_id as id, 'Success' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;         
  
EXCEPTION WHEN others THEN
     GET STACKED DIAGNOSTICS error_msg = MESSAGE_TEXT;
    FOR rec IN (SELECT row_to_json(j) FROM(select l_id as id, 'Internal Error - Contact your DBA with the following error message: ' || error_msg as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;	  
END;$$ LANGUAGE plpgsql;

/******************************************************************
 17. address bug in pmt_upd_boundary_features
******************************************************************/
-- upd_boundary_features
CREATE OR REPLACE FUNCTION pmt_upd_boundary_features()
RETURNS trigger AS $pmt_upd_boundary_features$
DECLARE
  boundary record;
  feature record;
  ft record;
  feature_spatial_table text;
  feature_group text;
  simple_polygon_boundary text;
  simple_polygon_feature text;
  feature_statement text;
  error_msg text;
BEGIN
  -- Remove all existing location boundary information for this location (to be recreated by this trigger)
  EXECUTE 'DELETE FROM location_boundary WHERE location_id = ' || NEW.id;
  RAISE NOTICE 'Refreshing boundary features for id % ...', NEW.id; 

  -- if the location is an exact location (point), then intersect all boundaries
  IF (NEW.boundary_id IS NULL AND NEW.feature_id IS NULL) THEN
    -- loop through each available boundary
    FOR boundary IN SELECT * FROM boundary LOOP
      -- find the feature in the boundary, interescted by our point
      FOR feature IN EXECUTE 'SELECT * FROM ' || quote_ident(boundary._spatial_table)  || ' WHERE ST_Intersects(ST_PointFromText(''' || 
		ST_AsText(NEW._point) || ''', 4326), _polygon)' LOOP
	-- RAISE NOTICE 'Found intersecting boundary for %', boundary._spatial_table;
	-- for each intersected feature, record its values in the location_boundary table
	EXECUTE 'INSERT INTO location_boundary VALUES (' || NEW.id || ', ' || feature.boundary_id || ', ' || feature.id || ', ' || quote_literal(feature._name) || ')';
	-- assign all associated taxonomy classification from intersected features to new location
	FOR ft IN (SELECT * FROM feature_taxonomy WHERE feature_taxonomy.feature_id = feature.id AND feature_taxonomy.boundary_id = feature.boundary_id) LOOP	  
	  IF ft IS NOT NULL THEN
	  -- RAISE NOTICE 'Found feature taxonomy for feature id %', ft.feature_id;
	  -- RAISE NOTICE 'Found feature taxonomy as classification id %', ft.classification_id;
	    -- replace all previous taxonomy classification associations with new for the given taxonomy
  	    DELETE FROM location_taxonomy WHERE location_id = NEW.id AND classification_id IN 
		(SELECT classification_id FROM _taxonomy_classifications WHERE taxonomy_id = (SELECT taxonomy_id FROM classification WHERE classification.id = ft.classification_id));    
	    INSERT INTO location_taxonomy VALUES (NEW.id, ft.classification_id, 'id');
	  END IF;
	END LOOP;
      END LOOP;	
    END LOOP;
  -- if the location is polygon feature, then only intersect boundaries that are less than or equal administrative levels
  ELSE
    -- get the spatial table of the location feature
    SELECT INTO feature_spatial_table _spatial_table FROM boundary WHERE id = NEW.boundary_id; 
    -- get the boundary group of the location feature
    SELECT INTO feature_group _group FROM boundary WHERE id = NEW.boundary_id; 
    -- loop through each available boundary that has an administrative level equal to or less than the location feature
    FOR boundary IN SELECT * FROM boundary WHERE (_admin_level IS NULL OR _admin_level <= NEW._admin_level)  LOOP
      IF (feature_group = 'global') OR (boundary._group = 'global') OR (feature_group = boundary._group) THEN     
      -- get the simple polygon column for the boundary
      EXECUTE 'SELECT column_name FROM information_schema.columns WHERE table_name = ''' || quote_ident(boundary._spatial_table)  || ''' AND column_name = ''_polygon_simple_med''' INTO simple_polygon_boundary;
      -- get the simple polygon column for the feature
      EXECUTE 'SELECT column_name FROM information_schema.columns WHERE table_name = ''' || quote_ident(feature_spatial_table)  || ''' AND column_name = ''_polygon_simple_med''' INTO simple_polygon_feature;
      -- boundary and feature are the same
      IF boundary._spatial_table = feature_spatial_table THEN 
        feature_statement := 'SELECT id, boundary_id, _name FROM ' || quote_ident(feature_spatial_table)  || ' WHERE id = ' || NEW.feature_id;
        -- find the feature in the boundary, interescted by our point
        FOR feature IN EXECUTE feature_statement LOOP
	  EXECUTE 'INSERT INTO location_boundary VALUES (' || NEW.id || ', ' || feature.boundary_id || ', ' || feature.id || ', ' || quote_literal(feature._name) || ')';	  
        END LOOP;
      -- boundary and feature are different do an intersection
      ELSE    
        -- boundary has a simple polygon
        IF simple_polygon_boundary IS NOT NULL THEN
          RAISE NOTICE 'Boundary % has a simplified polgon', boundary._spatial_table;
          IF simple_polygon_feature IS NOT NULL THEN
            RAISE NOTICE 'Feature % has a simplified polgon', feature_spatial_table;
            feature_statement := 'SELECT b.id, b.boundary_id, b._name FROM ' || quote_ident(boundary._spatial_table)  || ' b, ' ||
	      '(SELECT _polygon_simple_med FROM ' || quote_ident(feature_spatial_table)  || ' WHERE id = ' || NEW.feature_id || ') l ' ||
	      'WHERE ST_Intersects(b._polygon_simple_med, l._polygon_simple_med) AND (ST_Area(ST_Intersection(b._polygon_simple_med, l._polygon_simple_med))/ST_Area(l._polygon_simple_med)) > .85';
          ELSE
	    RAISE NOTICE 'Feature % does not have a simplified polgon', feature_spatial_table;
            feature_statement := 'SELECT b.id, b.boundary_id, b._name FROM ' || quote_ident(boundary._spatial_table)  || ' b, ' ||
	      '(SELECT _polygon FROM ' || quote_ident(feature_spatial_table)  || ' WHERE id = ' || NEW.feature_id || ') l ' ||
	      'WHERE ST_Intersects(b._polygon_simple_med, l._polygon) AND (ST_Area(ST_Intersection(b._polygon_simple_med, l._polygon))/ST_Area(l._polygon)) > .85';
          END IF;	
        -- boundary does not have a simple polygon
        ELSE
	RAISE NOTICE 'Boundary % does NOT have a simplified polgon',boundary._spatial_table;
          IF simple_polygon_feature IS NOT NULL THEN
            RAISE NOTICE 'Feature % has a simplified polgon', feature_spatial_table;
	    feature_statement := 'SELECT b.id, b.boundary_id, b._name FROM ' || quote_ident(boundary._spatial_table)  || ' b, ' ||
	      '(SELECT _polygon_simple_med FROM ' || quote_ident(feature_spatial_table)  || ' WHERE id = ' || NEW.feature_id || ') l ' ||
	      'WHERE ST_Intersects(b._polygon, l._polygon_simple_med) AND (ST_Area(ST_Intersection(b._polygon, l._polygon_simple_med))/ST_Area(l._polygon_simple_med)) > .85';
	  ELSE	
	    RAISE NOTICE 'Feature % does not have a simplified polgon', feature_spatial_table;
	    feature_statement := 'SELECT b.id, b.boundary_id, b._name FROM ' || quote_ident(boundary._spatial_table)  || ' b, ' ||
	      '(SELECT _polygon FROM ' || quote_ident(feature_spatial_table)  || ' WHERE id = ' || NEW.feature_id || ') l ' ||
	      'WHERE ST_Intersects(b._polygon, l._polygon) AND (ST_Area(ST_Intersection(b._polygon, l._polygon))/ST_Area(l._polygon)) > .85';
	  END IF;
        END IF;
        -- find the feature in the boundary, interescted by our point
        FOR feature IN EXECUTE feature_statement LOOP
	  -- RAISE NOTICE 'Found intersecting boundary for %', boundary._spatial_table;
	  -- for each intersected feature, record its values in the location_boundary table
	  EXECUTE 'INSERT INTO location_boundary VALUES (' || NEW.id || ', ' || feature.boundary_id || ', ' || feature.id || ', ' || quote_literal(feature._name) || ')';
	  -- assign all associated taxonomy classification from intersected features to new location
	  FOR ft IN (SELECT * FROM feature_taxonomy WHERE feature_taxonomy.feature_id = feature.id AND feature_taxonomy.boundary_id = feature.boundary_id) LOOP	  
	    IF ft IS NOT NULL THEN
	      -- RAISE NOTICE 'Found feature taxonomy for feature id %', ft.feature_id;
	      -- RAISE NOTICE 'Found feature taxonomy as classification id %', ft.classification_id;
	      -- replace all previous taxonomy classification associations with new for the given taxonomy
  	      DELETE FROM location_taxonomy WHERE location_id = NEW.id AND classification_id IN 
		(SELECT classification_id FROM _taxonomy_classifications WHERE taxonomy_id = (SELECT taxonomy_id FROM classification WHERE classification.id = ft.classification_id));    
	      INSERT INTO location_taxonomy VALUES (NEW.id, ft.classification_id, 'id');
	    END IF;
	  END LOOP;
        END LOOP;
      END IF;
      END IF;	
    END LOOP;
  END IF;

RETURN NEW;

EXCEPTION WHEN others THEN 
  GET STACKED DIAGNOSTICS error_msg = MESSAGE_TEXT;  
    RAISE NOTICE 'Internal Error - Contact your DBA with the following error message: %', ' Location id (' || NEW.id || ') - ' || error_msg;
END;
$pmt_upd_boundary_features$ LANGUAGE plpgsql; 
DROP TRIGGER IF EXISTS pmt_upd_boundary_features ON location;
CREATE TRIGGER pmt_upd_boundary_features AFTER INSERT OR UPDATE ON location
    FOR EACH ROW EXECUTE PROCEDURE pmt_upd_boundary_features();

/******************************************************************
 18. Remove unused functions
******************************************************************/
DROP FUNCTION IF EXISTS pmt_countries();
DROP FUNCTION IF EXISTS pmt_user();

/******************************************************************
19. rename to pmt_recalculate_location_boundaries to pmt_update_location_boundries
and delete duplicated function pmt_update_location_boundries
  select * from pmt_update_location_boundries(ARRAY[2345]);
******************************************************************/
DROP FUNCTION IF EXISTS pmt_update_location_boundries(integer);
DROP FUNCTION IF EXISTS pmt_recalculate_location_boundaries(integer[]);
CREATE OR REPLACE FUNCTION pmt_update_location_boundries(l_ids integer[]) RETURNS boolean AS $$
DECLARE
  l_id int;
  ct int;
  location_record record;
  boundary record;
  feature record;
  ft record;
  feature_spatial_table text;
  feature_group text;
  simple_polygon_boundary text;
  simple_polygon_feature text;
  feature_statement text;
  error_msg text;
BEGIN

-- no parameter is provided, exit
IF $1 IS NULL THEN    
  RETURN FALSE;
END IF;
 
IF array_length(l_ids,1)>0 THEN
  ct:=1;
  -- loop through all the activity_ids and purge each activity
  FOREACH l_id IN ARRAY l_ids LOOP
    EXECUTE 'SELECT * FROM location WHERE id = ' || l_id INTO location_record;
    --RAISE NOTICE 'Updating location id: %', location_record.id;
    IF (location_record.id IS NOT NULL) THEN
      RAISE NOTICE 'Updating location id: %', location_record.id;
      RAISE NOTICE 'Updating location #: %', ct;
      -- Remove all existing location boundary information for this location (to be recreated by this trigger)
      EXECUTE 'DELETE FROM location_boundary WHERE location_id = ' || location_record.id;
      RAISE NOTICE 'Refreshing boundary features for id % ...', location_record.id; 

      -- if the location is an exact location (point), then intersect all boundaries
      IF (location_record.boundary_id IS NULL AND location_record.feature_id IS NULL) THEN
        -- loop through each available boundary
        FOR boundary IN SELECT * FROM boundary LOOP
          -- find the feature in the boundary, interescted by our point
          FOR feature IN EXECUTE 'SELECT * FROM ' || quote_ident(boundary._spatial_table)  || ' WHERE ST_Intersects(ST_PointFromText(''' || 
		ST_AsText(location_record._point) || ''', 4326), _polygon)' LOOP
	    -- RAISE NOTICE 'Found intersecting boundary for %', boundary._spatial_table;
	    -- for each intersected feature, record its values in the location_boundary table
	    EXECUTE 'INSERT INTO location_boundary VALUES (' || location_record.id || ', ' || feature.boundary_id || ', ' || feature.id || ', ' || quote_literal(feature._name) || ')';
	    -- assign all associated taxonomy classification from intersected features to location_record location
	    FOR ft IN (SELECT * FROM feature_taxonomy WHERE feature_taxonomy.feature_id = feature.id AND feature_taxonomy.boundary_id = feature.boundary_id) LOOP	  
	      IF ft IS NOT NULL THEN
	      -- RAISE NOTICE 'Found feature taxonomy for feature id %', ft.feature_id;
	      -- RAISE NOTICE 'Found feature taxonomy as classification id %', ft.classification_id;
	        -- replace all previous taxonomy classification associations with location_record for the given taxonomy
  	        DELETE FROM location_taxonomy WHERE location_id = location_record.id AND classification_id IN 
	  	  (SELECT classification_id FROM _taxonomy_classifications WHERE taxonomy_id = (SELECT taxonomy_id FROM classification WHERE classification.id = ft.classification_id));    
	        INSERT INTO location_taxonomy VALUES (location_record.id, ft.classification_id, 'id');
	      END IF;
	    END LOOP;
          END LOOP;	
        END LOOP;
      -- if the location is polygon feature, then only intersect boundaries that are less than or equal administrative levels
      ELSE
        -- get the spatial table of the location feature
        SELECT INTO feature_spatial_table _spatial_table FROM boundary WHERE id = location_record.boundary_id; 
        -- get the boundary group of the location feature
        SELECT INTO feature_group _group FROM boundary WHERE id = location_record.boundary_id; 
        -- loop through each available boundary that has an administrative level equal to or less than the location feature
        FOR boundary IN SELECT * FROM boundary WHERE (_admin_level IS NULL OR _admin_level <= location_record._admin_level) AND (_group = 'global' OR _group = feature_group)  LOOP
          -- get the simple polygon column for the boundary
          EXECUTE 'SELECT column_name FROM information_schema.columns WHERE table_name = ''' || quote_ident(boundary._spatial_table)  || ''' AND column_name = ''_polygon_simple_med''' INTO simple_polygon_boundary;
          -- get the simple polygon column for the feature
          EXECUTE 'SELECT column_name FROM information_schema.columns WHERE table_name = ''' || quote_ident(feature_spatial_table)  || ''' AND column_name = ''_polygon_simple_med''' INTO simple_polygon_feature;
          -- boundary and feature are the same
          IF boundary._spatial_table = feature_spatial_table THEN 
            feature_statement := 'SELECT id, boundary_id, _name FROM ' || quote_ident(feature_spatial_table)  || ' WHERE id = ' || location_record.feature_id;
            -- find the feature in the boundary, interescted by our point
            FOR feature IN EXECUTE feature_statement LOOP
	      EXECUTE 'INSERT INTO location_boundary VALUES (' || location_record.id || ', ' || feature.boundary_id || ', ' || feature.id || ', ' || quote_literal(feature._name) || ')';	  
            END LOOP;
          -- boundary and feature are different do an intersection
          ELSE    
            -- boundary has a simple polygon
            IF simple_polygon_boundary IS NOT NULL THEN
              RAISE NOTICE 'Boundary % has a simplified polgon', boundary._spatial_table;
              IF simple_polygon_feature IS NOT NULL THEN
                RAISE NOTICE 'Feature % has a simplified polgon', feature_spatial_table;
                feature_statement := 'SELECT b.id, b.boundary_id, b._name FROM ' || quote_ident(boundary._spatial_table)  || ' b, ' ||
	          '(SELECT _polygon_simple_med FROM ' || quote_ident(feature_spatial_table)  || ' WHERE id = ' || location_record.feature_id || ') l ' ||
	          'WHERE ST_Intersects(b._polygon_simple_med, l._polygon_simple_med) AND (ST_Area(ST_Intersection(b._polygon_simple_med, l._polygon_simple_med))/ST_Area(l._polygon_simple_med)) > .85';
              ELSE
	        RAISE NOTICE 'Feature % does not have a simplified polgon', feature_spatial_table;
                feature_statement := 'SELECT b.id, b.boundary_id, b._name FROM ' || quote_ident(boundary._spatial_table)  || ' b, ' ||
	          '(SELECT _polygon FROM ' || quote_ident(feature_spatial_table)  || ' WHERE id = ' || location_record.feature_id || ') l ' ||
	          'WHERE ST_Intersects(b._polygon_simple_med, l._polygon) AND (ST_Area(ST_Intersection(b._polygon_simple_med, l._polygon))/ST_Area(l._polygon)) > .85';
              END IF;	
            -- boundary does not have a simple polygon
            ELSE
	    RAISE NOTICE 'Boundary % does NOT have a simplified polgon',boundary._spatial_table;
              IF simple_polygon_feature IS NOT NULL THEN
                RAISE NOTICE 'Feature % has a simplified polgon', feature_spatial_table;
	        feature_statement := 'SELECT b.id, b.boundary_id, b._name FROM ' || quote_ident(boundary._spatial_table)  || ' b, ' ||
	          '(SELECT _polygon_simple_med FROM ' || quote_ident(feature_spatial_table)  || ' WHERE id = ' || location_record.feature_id || ') l ' ||
	          'WHERE ST_Intersects(b._polygon, l._polygon_simple_med) AND (ST_Area(ST_Intersection(b._polygon, l._polygon_simple_med))/ST_Area(l._polygon_simple_med)) > .85';
	      ELSE	
	        RAISE NOTICE 'Feature % does not have a simplified polgon', feature_spatial_table;
	        feature_statement := 'SELECT b.id, b.boundary_id, b._name FROM ' || quote_ident(boundary._spatial_table)  || ' b, ' ||
	          '(SELECT _polygon FROM ' || quote_ident(feature_spatial_table)  || ' WHERE id = ' || location_record.feature_id || ') l ' ||
	          'WHERE ST_Intersects(b._polygon, l._polygon) AND (ST_Area(ST_Intersection(b._polygon, l._polygon))/ST_Area(l._polygon)) > .85';
	      END IF;
            END IF;
            -- find the feature in the boundary, interescted by our point
            FOR feature IN EXECUTE feature_statement LOOP
	     -- RAISE NOTICE 'Found intersecting boundary for %', boundary._spatial_table;
	      -- for each intersected feature, record its values in the location_boundary table
	      EXECUTE 'INSERT INTO location_boundary VALUES (' || location_record.id || ', ' || feature.boundary_id || ', ' || feature.id || ', ' || quote_literal(feature._name) || ')';
	      -- assign all associated taxonomy classification from intersected features to location_record location
	      FOR ft IN (SELECT * FROM feature_taxonomy WHERE feature_taxonomy.feature_id = feature.id AND feature_taxonomy.boundary_id = feature.boundary_id) LOOP	  
	        IF ft IS NOT NULL THEN
	          -- RAISE NOTICE 'Found feature taxonomy for feature id %', ft.feature_id;
	          -- RAISE NOTICE 'Found feature taxonomy as classification id %', ft.classification_id;
  	          -- replace all previous taxonomy classification associations with location_record for the given taxonomy
  	          DELETE FROM location_taxonomy WHERE location_id = location_record.id AND classification_id IN 
	    	    (SELECT classification_id FROM _taxonomy_classifications WHERE taxonomy_id = (SELECT taxonomy_id FROM classification WHERE classification.id = ft.classification_id));    
	          INSERT INTO location_taxonomy VALUES (location_record.id, ft.classification_id, 'id');
	        END IF;
	      END LOOP;
            END LOOP;
          END IF;	
        END LOOP;
      END IF;
    END IF;
    ct:=ct+1;
  END LOOP;    
ELSE
  -- exit if array is empty
  RETURN FALSE;
END IF;

-- success
RETURN TRUE;

EXCEPTION
  -- some type of error occurred, return unsuccessful
     WHEN others THEN 
       GET STACKED DIAGNOSTICS error_msg = MESSAGE_TEXT;
       RAISE NOTICE 'Error: %', error_msg;
       RETURN FALSE;
       
END;$$ LANGUAGE plpgsql;

-- update permissions
GRANT USAGE ON SCHEMA public TO pmt_read;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO pmt_read;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO pmt_read;
GRANT USAGE ON SCHEMA public TO pmt_write;
GRANT SELECT,INSERT ON ALL TABLES IN SCHEMA public TO pmt_write;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO pmt_write;