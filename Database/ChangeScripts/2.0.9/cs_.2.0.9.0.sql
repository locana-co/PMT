/******************************************************************
Change Script 2.0.9.0
1. User Authentication Model upgrade
******************************************************************/
INSERT INTO version(version, iteration, changeset) VALUES (2.0, 9, 0);
-- select * from version order by iteration desc, changeset desc;

/******************************************************************
   pmt_version
   select * from pmt_version()
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_version() RETURNS SETOF pmt_version_result_type AS 
$$
DECLARE
  rec record;
BEGIN	
  FOR rec IN (  SELECT version::text||'.'||iteration::text||'.'||changeset::text AS pmt_version, updated_date::date as last_update, (SELECT created_date from config where config_id = (select min(config_id) from config))::date as created
		FROM version ORDER BY version DESC, iteration DESC, changeset DESC LIMIT 1 
		) LOOP		
	RETURN NEXT rec;
  END LOOP;	  
END;$$ LANGUAGE plpgsql;

/******************************************************************
  Update pmt_auth_soure enum values and base user authorization on 
  user by user instead of entire instance

  SELECT enum_range(NULL::pmt_edit_action)
******************************************************************/

-- remove depreciated functions
DROP FUNCTION IF EXISTS pmt_auth_user(character varying, character varying) CASCADE;
DROP FUNCTION IF EXISTS pmt_create_user(integer, integer, integer, character varying(255), character varying(255), character varying(255), character varying(150), character varying(150));
DROP FUNCTION IF EXISTS pmt_update_user(integer, integer, integer, integer, character varying(255), character varying(255),  character varying(255), character varying(150), character varying(150));
DROP FUNCTION IF EXISTS pmt_edit_activity_taxonomy(character varying, integer, pmt_edit_action)  CASCADE;
DROP FUNCTION IF EXISTS pmt_edit_activity_taxonomy(integer, character varying, character varying, pmt_edit_action)  CASCADE;
DROP FUNCTION IF EXISTS pmt_edit_project_taxonomy(integer, integer, integer, pmt_edit_action)  CASCADE;
DROP FUNCTION IF EXISTS pmt_edit_project_taxonomy(integer, character varying, character varying, pmt_edit_action)  CASCADE;
DROP FUNCTION IF EXISTS bmgf_infobox_activity_contact(integer)  CASCADE;
DROP FUNCTION IF EXISTS bmgf_infobox_activity_desc (integer)  CASCADE;
DROP FUNCTION IF EXISTS bmgf_infobox_activity_stats (integer)  CASCADE;
DROP FUNCTION IF EXISTS pmt_infobox_activity_contact (integer)  CASCADE;
DROP FUNCTION IF EXISTS pmt_infobox_activity_desc (integer)  CASCADE;
DROP FUNCTION IF EXISTS pmt_infobox_activity_stats (integer)  CASCADE;
DROP FUNCTION IF EXISTS pmt_activity_details (integer)  CASCADE;
DROP FUNCTION IF EXISTS bmgf_infobox_project_contact (integer)  CASCADE;
DROP FUNCTION IF EXISTS bmgf_infobox_project_desc (integer)  CASCADE;
DROP FUNCTION IF EXISTS bmgf_infobox_project_info (integer)  CASCADE;
DROP FUNCTION IF EXISTS bmgf_infobox_project_nutrition (integer)  CASCADE;
DROP FUNCTION IF EXISTS bmgf_infobox_project_stats (integer)  CASCADE;
DROP FUNCTION IF EXISTS pmt_infobox_project_contact (integer)  CASCADE;
DROP FUNCTION IF EXISTS pmt_infobox_project_desc (integer)  CASCADE;
DROP FUNCTION IF EXISTS pmt_infobox_project_info (integer)  CASCADE;
DROP FUNCTION IF EXISTS pmt_infobox_project_stats (integer)  CASCADE;

-- drop the user_role table
DROP VIEW data_loading_report;
DROP TABLE user_role;

-- Add new field to provide secuirty permissions to role table
ALTER TABLE role ADD COLUMN "security" boolean NOT NULL DEFAULT false;

-- Add new role
INSERT INTO role(name, description, read, "create", update, delete, super, security, created_by, updated_by) VALUES ('Administrator', 'Administrator role for read-only of all public data. Create and update rights to user and security data.', TRUE, TRUE, TRUE, TRUE, FALSE, TRUE, 'PMT Core Role', 'PMT Core Role');
UPDATE role SET security = TRUE WHERE name = 'Super';

-- remove the edit authorization source field from the configuration table
ALTER TABLE config DROP COLUMN edit_auth_source;

-- drop enum type
DROP TYPE pmt_auth_source;

--  add new column to user table for authentication source
ALTER TABLE "user" ADD COLUMN role_id integer NOT NULL DEFAULT 1 REFERENCES role(role_id);

-- remove data group column from user table
ALTER TABLE "user" DROP COLUMN data_group_id;

-- add constraint to the username field to be unique
ALTER TABLE "user" ADD UNIQUE(username);

-- remove requirement for organization id
ALTER TABLE "user" ALTER COLUMN organization_id DROP NOT NULL;

-- create new table to store role based authentication by project
--DROP TABLE "user_project_role";
CREATE TABLE "user_project_role" 
(
	"user_project_role_id" 	SERIAL				NOT NULL
	,"user_id"		integer				NOT NULL REFERENCES "user"(user_id)
	,"role_id"		integer				NOT NULL REFERENCES role(role_id)
	,"project_id"		integer				REFERENCES project(project_id)
	,"classification_id"	integer 			REFERENCES classification(classification_id) 
								CHECK(project_id IS NOT NULL OR classification_id IS NOT NULL) 
	,"active"		boolean				NOT NULL DEFAULT TRUE
	,"retired_by"		integer	
	,"created_by" 		character varying(50)
	,"created_date" 	timestamp without time zone 	NOT NULL DEFAULT current_date
	,"updated_by" 		character varying(50)
	,"updated_date" 	timestamp without time zone 	NOT NULL DEFAULT current_date
	,CONSTRAINT user_project_role_id PRIMARY KEY(user_project_role_id)
);
-- Add TRIGGER to allow only one setting: project_id or classification_id


/******************************************************************
   pmt_validate_user
   select * from pmt_validate_user(34);
   select * from pmt_validate_user(999);
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_validate_user(id integer) RETURNS BOOLEAN AS 
$$
DECLARE valid_id integer;
BEGIN 
     IF $1 IS NULL THEN    
       RETURN false;
     END IF;    
     
     SELECT INTO valid_id user_id FROM "user" WHERE active = true AND user_id = $1;	 

     IF valid_id IS NULL THEN
      RETURN false;
     ELSE 
      RETURN true;
     END IF;
     
EXCEPTION WHEN others THEN
    RETURN FALSE;
END;$$ LANGUAGE plpgsql;


/******************************************************************
   pmt_validate_role
   select * from pmt_validate_role(4);
   select * from pmt_validate_role(6);
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_validate_role(id integer) RETURNS BOOLEAN AS 
$$
DECLARE valid_id integer;
BEGIN 
     IF $1 IS NULL THEN    
       RETURN false;
     END IF;    
     
     SELECT INTO valid_id role_id FROM role WHERE active = true AND role_id = $1;	 

     IF valid_id IS NULL THEN
      RETURN false;
     ELSE 
      RETURN true;
     END IF;
     
EXCEPTION WHEN others THEN
    RETURN FALSE;
END;$$ LANGUAGE plpgsql;


/******************************************************************
  pmt_user_auth
  select * from "user"
  select * from pmt_user_auth('bob','$2a$10$Nl29XV2eNXyJ5LobdmiGPuL1ikOSTM.cAEX.ITL4Ri09uisyeg7Qq');
  select * from pmt_user_auth('super','$2a$10$62XU6NIKi1RuFeAMTt1zluVGGALWfmNWgW2jIa8t9R59jLFLaJU.m');
  select * from pmt_user_auth('sparadee','$2a$10$4QcfiM6aIcnGfnCkib7jGe294WyGfwcaPTdzeYaH7el6885S41DFu');
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_user_auth(username character varying(255), password character varying(255)) RETURNS 
SETOF pmt_json_result_type AS $$
DECLARE 
  valid_user_id integer;
  role_super boolean;	
  rec record;
BEGIN 
  -- validate user and get user_id
  SELECT INTO valid_user_id "user".user_id FROM "user" WHERE "user".username = $1 AND "user".password = $2 AND active = true;
  
  IF valid_user_id IS NOT NULL THEN
    -- check to see if user has a role with "SUPER" rights (if so they have full adminsitrative editing rights to the database)
    SELECT INTO role_super super FROM role WHERE role_id = (SELECT role_id FROM "user" WHERE user_id = valid_user_id);
    IF role_super THEN
        FOR rec IN (
	SELECT row_to_json(j) FROM(	 				
	SELECT u.user_id, u.first_name, u.last_name, u.username, u.email
	,u.organization_id
	,(SELECT name FROM organization WHERE organization_id = u.organization_id) as organization
	,u.role_id
	,(SELECT name FROM role WHERE role_id = u.role_id) as role
	,null as authorizations
	FROM "user" u
	WHERE u.user_id = valid_user_id
	) j
      ) LOOP		
        RETURN NEXT rec;
      END LOOP;
    -- get all the authorization information for the user
    ELSE
      FOR rec IN (
	SELECT row_to_json(j) FROM(	 				
	SELECT u.user_id, u.first_name, u.last_name, u.username, u.email
	,u.organization_id
	,(SELECT name FROM organization WHERE organization_id = u.organization_id) as organization
	,u.role_id
	,(SELECT name FROM role WHERE role_id = u.role_id) as role
	,(SELECT array_to_json(array_agg(row_to_json(r))) FROM (
			SELECT p.role_id, r.name as role, array_agg(p.project_id) as project_ids FROM
			(SELECT user_id, project_id, role_id
			FROM user_project_role
			WHERE user_id = u.user_id AND classification_id IS NULL
			UNION ALL
			SELECT ua.user_id, pt.project_id, ua.role_id
			FROM user_project_role ua
			JOIN project_taxonomy pt
			ON ua.classification_id = pt.classification_id
			WHERE ua.user_id = u.user_id AND ua.classification_id IS NOT NULL) p			
			JOIN role r
			ON p.role_id = r.role_id
			GROUP BY p.role_id, r.name) as r
		) as authorizations
	FROM "user" u
	WHERE u.user_id = valid_user_id	
	) j
      ) LOOP		
        RETURN NEXT rec;
      END LOOP;    
    END IF;
    -- log user activity
    INSERT INTO user_activity(user_id, username, status) VALUES (valid_user_id, $1, 'success');		  
  ELSE
    FOR rec IN (SELECT row_to_json(j) FROM( SELECT 'Invalid username or password.' AS message ) j ) LOOP		
        RETURN NEXT rec;
    END LOOP;	
    -- log user activity
    INSERT INTO user_activity(username, status) VALUES ($1, 'fail');		  
  END IF;
END; 
$$ LANGUAGE 'plpgsql';


/******************************************************************
  pmt_users
  select * from pmt_users();
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_users() RETURNS SETOF pmt_json_result_type AS $$
DECLARE 
  rec record;
BEGIN 
  FOR rec IN (
	SELECT row_to_json(j) FROM( 
	SELECT u.user_id, u.first_name, u.last_name, u.username, u.email
	,u.organization_id
	,(SELECT name FROM organization WHERE organization_id = u.organization_id) as organization
	,u.role_id
	,(SELECT name FROM role WHERE role_id = u.role_id) as role
	FROM "user" u
	) j 
    ) LOOP		
    RETURN NEXT rec;
  END LOOP;			  
END; 
$$ LANGUAGE 'plpgsql';

/******************************************************************
  pmt_user
  select * from pmt_user(5);    
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_user(user_id integer) RETURNS SETOF pmt_json_result_type AS $$
DECLARE 
  rec record;
  role_super boolean;
  valid_user_id integer;
  created_by_id integer;
  execute_statement text;
BEGIN 
  -- check to see if user has a role with "SUPER" rights (if so they have full adminsitrative editing rights to the database)
    SELECT INTO role_super super FROM role WHERE role_id = (SELECT "user".role_id FROM "user" WHERE "user".user_id = valid_user_id);
    IF role_super THEN
      execute_statement := 'SELECT u.user_id, u.first_name, u.last_name, u.username, u.email ' ||
			',u.organization_id ' ||
			',(SELECT name FROM organization WHERE organization_id = u.organization_id) as organization ' ||
			',u.role_id ' ||
			',(SELECT name FROM role WHERE role_id = u.role_id) as role ' ||
			',null as projects ' ||
			'FROM "user" u 	 ' ||
			'WHERE u.user_id =  ' || $1;
	
    -- get all the authorization information for the user
    ELSE
      execute_statement := 'SELECT u.user_id, u.first_name, u.last_name, u.username, u.email ' ||
			',u.organization_id ' ||
			',(SELECT name FROM organization WHERE organization_id = u.organization_id) as organization ' ||
			',u.role_id ' ||
			',(SELECT name FROM role WHERE role_id = u.role_id) as role ';
      IF (created_by_id IS NOT NULL) THEN
        execute_statement := execute_statement || ',(SELECT CASE WHEN first_name = '' OR first_name IS NULL THEN u.created_by ELSE TRIM(first_name || '' '' || last_name) END FROM "user" WHERE username = u.created_by) as created_by ';        
      ELSE
        execute_statement := execute_statement || ',u.created_by ';
      END IF;

      execute_statement := execute_statement || ',(SELECT array_to_json(array_agg(row_to_json(s))) FROM ( ' ||
			'SELECT user_authority.project_id, p.title, user_authority.role_id, (SELECT name FROM role WHERE role_id = user_authority.role_id) as role ' ||
			'FROM (SELECT ua.project_id, ua.role_id  ' ||
			'FROM user_project_role ua  ' ||
			'WHERE ua.user_id = ' || $1 || ' AND ua.classification_id IS NULL AND ua.active = true  ' ||
			'UNION ALL ' ||
			'SELECT pt.project_id, ua.role_id  ' ||
			'FROM user_project_role ua  ' ||
			'JOIN project_taxonomy pt ON ua.classification_id = pt.classification_id  ' ||
			'WHERE ua.user_id = ' || $1 || ' AND ua.classification_id IS NOT NULL AND ua.active = true) user_authority ' ||
			'JOIN project p ' ||
			'ON user_authority.project_id = p.project_id) s ' ||
			') as projects ' ||
			'FROM "user" u ' ||
			'WHERE u.user_id =  ' || $1;
			    
    END IF;			  

    RAISE NOTICE 'Execute statement: %', execute_statement;
    FOR rec IN EXECUTE 'SELECT row_to_json(j) FROM (' || execute_statement || ')j' LOOP     
	RETURN NEXT rec;
    END LOOP;       
END; 
$$ LANGUAGE 'plpgsql';

/******************************************************************
  pmt_project_users
  select * from pmt_project_users(15);
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_project_users(project_id integer) RETURNS SETOF pmt_json_result_type AS $$
DECLARE 
  rec record;
BEGIN 
  FOR rec IN (
	SELECT row_to_json(j) FROM( 		
	SELECT u.user_id, u.first_name, u.last_name, u.username, u.email
	, u.organization_id
	,(SELECT name FROM organization WHERE organization_id = u.organization_id) as organization
	, upr.role_id
	,(SELECT name FROM role WHERE role_id = upr.role_id) as role
	FROM (SELECT ua.project_id, ua.user_id, ua.role_id 
	FROM user_project_role ua 
	WHERE ua.classification_id IS NULL AND ua.active = true 
	UNION ALL
	SELECT pt.project_id, ua.user_id, ua.role_id 
	FROM user_project_role ua 
	JOIN project_taxonomy pt ON ua.classification_id = pt.classification_id 
	WHERE ua.classification_id IS NOT NULL AND ua.active = true) upr
	JOIN "user" u
	ON upr.user_id = u.user_id
	WHERE upr.project_id = $1	
	) j 
    ) LOOP		
    RETURN NEXT rec;
  END LOOP;			  
END; 
$$ LANGUAGE 'plpgsql';


/******************************************************************
  pmt_validate_user_authority

  select * from pmt_validate_user_authority(34, null, 'create');
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_validate_user_authority(user_id integer, project_id integer, auth_type pmt_auth_crud) RETURNS boolean AS $$
DECLARE 
	users_authority record;
	error_msg text;
	role_crud boolean;
BEGIN 
     -- user and authorization type parameters are required
     IF $1 IS NULL  OR $3 IS NULL THEN    
       RAISE NOTICE 'Missing required parameters';
       RETURN FALSE;
     END IF; 
     
     -- check to see if user has a role with "SUPER" rights (if so they have full adminsitrative editing rights to the database)
     SELECT INTO role_crud super FROM role WHERE role_id = (SELECT role_id FROM "user" WHERE "user".user_id = $1);

     IF role_crud THEN
       RAISE NOTICE 'User is a Super User';
       RETURN TRUE;
     END IF;  
     
     -- No project_id, the requesting authorization at the database level
     IF $2 IS NULL THEN
       -- Only authorization type valid at the database level is CREATE
       -- (determine if user is allowed to create new records)
       IF auth_type = 'create' THEN
         SELECT INTO role_crud "create" FROM role WHERE role_id = (SELECT role_id FROM "user" WHERE "user".user_id  = $1);	           
         IF role_crud THEN
	   RETURN TRUE;
         ELSE
	   RETURN FALSE;
         END IF;
       ELSE
         RETURN FALSE;
       END IF;
     END IF;

     -- determine if user has access to the requested project
     FOR users_authority IN (SELECT * FROM (SELECT ua.project_id, ua.role_id FROM user_project_role ua WHERE ua.user_id = $1 AND ua.classification_id IS NULL AND ua.active = true UNION ALL
     SELECT pt.project_id, ua.role_id FROM user_project_role ua JOIN project_taxonomy pt ON ua.classification_id = pt.classification_id WHERE ua.user_id = $1 AND ua.classification_id IS NOT NULL AND ua.active = true) auth 
     WHERE auth.project_id = $2) LOOP
       -- get users authorization type based on their role
       CASE auth_type
	 WHEN 'create' THEN
	   SELECT INTO role_crud "create" FROM role WHERE role_id = users_authority.role_id;	    
	 WHEN 'read' THEN
	   SELECT INTO role_crud "read" FROM role WHERE role_id = users_authority.role_id;	    
	 WHEN 'update' THEN
	   SELECT INTO role_crud "update" FROM role WHERE role_id = users_authority.role_id;	    
  	 WHEN 'delete' THEN
	   SELECT INTO role_crud "delete" FROM role WHERE role_id = users_authority.role_id;	    
	 ELSE
	   RETURN FALSE;
       END CASE; 

       -- determine if the authorization type is allowed by user role
       IF role_crud THEN
	 RETURN TRUE;
       ELSE
         RAISE NOTICE 'User does not have requested authorization type (%) for requested project', $3;
	 RETURN FALSE;
       END IF;             
     END LOOP;

     RAISE NOTICE 'Project id (%) NOT in authorized projects.', $2;
     RETURN FALSE;    
    
EXCEPTION WHEN others THEN
     GET STACKED DIAGNOSTICS error_msg = MESSAGE_TEXT;  
    RAISE NOTICE 'Internal Error - Contact your DBA with the following error message: %', error_msg;
    RETURN FALSE;
END; 
$$ LANGUAGE 'plpgsql';

/******************************************************************
   pmt_edit_project

   select * from pmt_edit_project(34,null,'{"title": "testing", "url":"www.google.com"}', false);
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_edit_project(user_id integer, project_id integer, key_value_data json, delete_record boolean default false) RETURNS SETOF pmt_json_result_type AS 
$$
DECLARE
  new_project_id integer;
  user_role_id integer;
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
      -- add user as owner of new project
      EXECUTE 'INSERT INTO user_project_role (user_id, role_id, project_id, created_by, updated_by) VALUES (' || $1 || ', (SELECT role_id FROM role WHERE name  = ''Super''),' || new_project_id || ', ' 
              || quote_literal(user_name) || ',' || quote_literal(user_name) || ');';
    ELSE
      FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: User does NOT have authority to create a new project.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
    END IF;
  -- validate project_id if provided and validate users authority to update an existing record  
  ELSE
    -- validate project_id			
    IF (SELECT * FROM pmt_validate_project($2)) THEN 
      -- validate users authority to 'delete' this project
      IF ($4) THEN
        IF (SELECT delete FROM role WHERE role.role_id = (SELECT "user".role_id FROM "user" WHERE "user".user_id = $1)) THEN
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

/******************************************************************
   pmt_edit_user
   select * from pmt_edit_user(34,null,'{"email":"jhanhock@mail.com", "username":"jhanhock1", "password":"password"}', false);
   select * from pmt_edit_user(34,null,'{"email":"jhanhock1@mail.com", "password":"password"}', false);
   select * from pmt_edit_user(34,158,null, true);
   select * from pmt_edit_user(4,4,'{"email":"jhanhock@mail.com", "role_id":3}', false);
   select * from "user"
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_edit_user(request_user_id integer, target_user_id integer, key_value_data json, delete_record boolean default false) RETURNS SETOF pmt_json_result_type AS 
$$
DECLARE
  user_role_id integer;  
  user_id integer;
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
  rec record;
  error_msg1 text;
  error_msg2 text;
  error_msg3 text;
  is_self boolean;
BEGIN	
  -- set columns that are not editable via the parameters 
  invalid_editing_columns := ARRAY['user_id', 'active', 'retired_by', 'created_by', 'created_date', 'updated_by', 'updated_date'];
  invalid_self_editing_columns := ARRAY['user_id', 'active', 'retired_by', 'created_by', 'created_date', 'updated_by', 'updated_date', 'role_id'];
  -- required columns for new records
  required_columns := ARRAY['username', 'email', 'password'];
  
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
  SELECT INTO user_name username FROM "user" WHERE "user".user_id = $1;
  -- get users role
  SELECT INTO user_role_id role_id FROM "user" WHERE "user".user_id = $1;

  is_self = false;
  IF ($1 = $2) THEN
    is_self := true;
    invalid_editing_columns := invalid_self_editing_columns;
  END IF;
  -- user has authority for security actions on the database
  IF(SELECT security FROM role WHERE role_id = user_role_id) OR (is_self) THEN  
    -- create a new user record  
    IF ($2 IS NULL) THEN
      -- validate required columns have been provided
      RAISE NOTICE 'Provided columns: %', provided_columns;
      IF ( provided_columns @> required_columns ) THEN
	-- create new user record
	execute_statement := null;
	insert_statement := 'INSERT INTO "user" (';
	values_statement := 'VALUES (';
	-- loop through the columns of the user table        
        FOR json IN (SELECT * FROM json_each_text($3)) LOOP
	  RAISE NOTICE 'JSON key/value: %', lower(json.key) || ':' || json.value;
	  -- get the column information for column that user is requesting to edit	
	  FOR column_record IN (SELECT * FROM information_schema.columns WHERE table_schema='public' AND table_name='user' AND column_name != ALL(invalid_editing_columns) AND lower(column_name) = lower(json.key)) LOOP 
	      RAISE NOTICE 'Editing column: %', column_record.column_name;
	      RAISE NOTICE 'Assigning new value: %', json.value;
	      
	      CASE column_record.data_type 
		WHEN 'integer', 'numeric' THEN              
		  IF (SELECT pmt_isnumeric(json.value)) THEN
		    insert_statement := insert_statement || column_record.column_name || ', '; 
		    values_statement := values_statement || json.value || ', '; 
		  END IF;
		  IF (lower(json.value) = 'null') THEN
		    insert_statement := insert_statement || column_record.column_name || ', '; 
		    values_statement := values_statement || 'null, '; 
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
	      END CASE;	      
	    END LOOP;
	  END LOOP;
	  -- add additional statements and concatenate 
	 insert_statement := insert_statement || 'created_by, updated_by) ';
	 values_statement := values_statement || quote_literal(user_name) || ', ' || quote_literal(user_name) || ') RETURNING "user".user_id;';
          
	 execute_statement := insert_statement || values_statement;
	      
         RAISE NOTICE 'Statements: %', execute_statement;
	 EXECUTE execute_statement INTO user_id;
	 EXECUTE 'UPDATE "user" SET password = crypt(password, gen_salt(''bf'', 10)) where user_id = ' || user_id;
	 
      ELSE
        FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: A required field was not provided.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
      END IF;  
    -- update/delete a user record    
    ELSE
      -- validate target_user_id
      SELECT INTO user_id "user".user_id FROM "user" WHERE "user".user_id = $2;
      IF (user_id IS NOT NULL) THEN
        -- delete user record
        IF ($4) THEN
          EXECUTE 'UPDATE "user" SET active = false, updated_by = ' || quote_literal(user_name) || ', updated_date = ' || quote_literal(current_date) || ' WHERE "user".user_id = ' || user_id ;
        -- update user record
        ELSE
	  -- loop through the columns of the activity table        
          FOR json IN (SELECT * FROM json_each_text($3)) LOOP
	    RAISE NOTICE 'JSON key/value: %', lower(json.key) || ':' || json.value;
	    -- get the column information for column that user is requesting to edit	
	    FOR column_record IN (SELECT * FROM information_schema.columns WHERE table_schema='public' AND table_name='user' AND column_name != ALL(invalid_editing_columns) AND lower(column_name) = lower(json.key)) LOOP 
	      RAISE NOTICE 'Editing column: %', column_record.column_name;
	      RAISE NOTICE 'Assigning new value: %', json.value;
	      execute_statement := null;
	      CASE column_record.data_type 
		WHEN 'integer', 'numeric' THEN              
		  IF (SELECT pmt_isnumeric(json.value)) THEN
		    execute_statement := 'UPDATE "user" SET ' || column_record.column_name || ' = ' || json.value || ' WHERE user_id = ' || user_id; 
		  END IF;
		  IF (lower(json.value) = 'null') THEN
		    execute_statement := 'UPDATE "user" SET ' || column_record.column_name || ' = null WHERE user_id = ' || user_id; 
		  END IF;
		ELSE
		  -- if the value has the text null then assign the column value null
		  IF (lower(json.value) = 'null') THEN
		    execute_statement := 'UPDATE "user" SET ' || column_record.column_name || ' = null WHERE user_id = ' || user_id; 
		  ELSE
		    execute_statement := 'UPDATE "user" SET ' || column_record.column_name || ' = ' || quote_literal(json.value) || ' WHERE user_id = ' || user_id; 
		  END IF;
	      END CASE;
	      IF execute_statement IS NOT NULL THEN
		RAISE NOTICE 'Statement: %', execute_statement;
		EXECUTE execute_statement;
		IF (column_record.column_name = 'password') THEN
		  EXECUTE 'UPDATE "user" SET password = crypt(password, gen_salt(''bf'', 10)) where user_id = ' || user_id;
		END IF;		
		EXECUTE 'UPDATE "user" SET updated_by = ' || quote_literal(user_name) || ', updated_date = ' || quote_literal(current_date) || ' WHERE  user_id = ' || user_id;
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


CREATE OR REPLACE VIEW data_loading_report
AS SELECT 'activity table' as "table", COUNT(*) AS "total record count", (SELECT COUNT(*) FROM activity WHERE active = true) AS "active record count", 0 AS "core PMT count", '' as "comments" FROM activity
UNION ALL
SELECT 'activity_contact' as "table", COUNT(*) AS "total record count", (SELECT COUNT(*) FROM activity_contact) AS "active record count", 0 AS "core PMT count", '' as "comments" FROM activity_contact
UNION ALL
SELECT 'activity_taxonomy' as "table", COUNT(*) AS "total record count", (SELECT COUNT(*) FROM activity_taxonomy) AS "active record count", 0 AS "core PMT count", '' as "comments" FROM activity_taxonomy
UNION ALL
SELECT 'boundary table' as "table", COUNT(*) AS "total record count", (SELECT COUNT(*) FROM boundary WHERE active = true) AS "active record count", 3 AS "core PMT count", 'Correct count reflects minimum count on default PMT install.' as "comments" FROM boundary			
UNION ALL
SELECT 'boundary_taxonomy' as "table", COUNT(*) AS "total record count", (SELECT COUNT(*) FROM boundary_taxonomy) AS "active record count", 0 AS "core PMT count", '' as "comments" FROM boundary_taxonomy			
UNION ALL
SELECT 'contact table' as "table", COUNT(*) AS "total record count", (SELECT COUNT(*) FROM contact WHERE active = true) AS "active record count", 0 AS "core PMT count", '' as "comments" FROM contact			
UNION ALL
SELECT 'contact_taxonomy' as "table", COUNT(*) AS "total record count", (SELECT COUNT(*) FROM contact_taxonomy) AS "active record count", 0 AS "core PMT count", '' as "comments" FROM contact_taxonomy
UNION ALL
SELECT 'detail table' as "table", COUNT(*) AS "total record count", (SELECT COUNT(*) FROM detail WHERE active = true) AS "active record count", 0 AS "core PMT count", '' as "comments" FROM detail
UNION ALL
SELECT 'feature_taxonomy' as "table", COUNT(*) AS "total record count", (SELECT COUNT(*) FROM feature_taxonomy) AS "active record count", 277 AS "core PMT count", 'Correct count reflects minimum count on default PMT install.' as "comments" FROM feature_taxonomy
UNION ALL
SELECT 'financial table' as "table", COUNT(*) AS "total record count", (SELECT COUNT(*) FROM financial WHERE active = true) AS "active record count", 0 AS "core PMT count", '' as "comments" FROM financial
UNION ALL
SELECT 'financial_taxonomy' as "table", COUNT(*) AS "total record count", (SELECT COUNT(*) FROM financial_taxonomy) AS "active record count", 0 AS "core PMT count", '' as "comments" FROM financial_taxonomy
UNION ALL
SELECT 'gaul0 table' as "table", COUNT(*) AS "total record count", (SELECT COUNT(*) FROM gaul0 WHERE active = true) AS "active record count", 277 AS "core PMT count", 'Core count reflects minimum count on default PMT install.' as "comments" FROM gaul0
UNION ALL
SELECT 'gaul1 table' as "table", COUNT (*) AS "total record count", (SELECT COUNT(*) FROM gaul1 WHERE active = true) AS "active record count", 3469 AS "core PMT count", 'Core count reflects minimum count on default PMT install.' as "comments" FROM gaul1
UNION ALL
SELECT 'gaul2 table' as "table", COUNT(*) AS "total record count", (SELECT COUNT(*) FROM gaul2 WHERE active = true) AS "active record count", 37378 AS "core PMT count", 'Core count reflects minimum count on default PMT install.' as "comments" FROM gaul2
UNION ALL
SELECT 'location table' as "table", COUNT(*) AS "total record count", (SELECT COUNT(*) FROM location WHERE active = true) AS "active record count", 0 AS "core PMT count", '' as "comments" FROM location 
UNION ALL
SELECT 'location_boundary' as "table", COUNT(*) AS "total record count", (SELECT COUNT(*) FROM location_boundary) AS "active record count", 0 AS "core PMT count", '' as "comments" FROM location_boundary
UNION ALL
SELECT 'location_taxonomy' as "table", COUNT(*) AS "total record count", (SELECT COUNT(*) FROM location_taxonomy) AS "active record count", 0 AS "core PMT count", '' as "comments" FROM location_taxonomy
UNION ALL
SELECT 'map table' as "table", COUNT(*) AS "total record count", (SELECT COUNT(*) FROM map WHERE active = true) AS "active record count", 0 AS "core PMT count", '' as "comments" FROM map
UNION ALL
SELECT 'organization table' as "table", COUNT(*) AS "total record count", (SELECT COUNT(*) FROM organization WHERE active = true) AS "active record count", 0 AS "core PMT count", '' as "comments" FROM organization
UNION ALL
SELECT 'organization_taxonomy' as "table", COUNT(*) AS "total record count", (SELECT COUNT(*) FROM organization_taxonomy) AS "active record count", 0 AS "core PMT count", '' as "comments" FROM organization_taxonomy	
UNION ALL
SELECT 'participation table' as "table", COUNT(*) AS "total record count", (SELECT COUNT(*) FROM participation WHERE active = true) AS "active record count", 0 AS "core PMT count", '' as "comments" FROM participation
UNION ALL
SELECT 'participation_taxonomy' as "table", COUNT(*) AS "total record count", (SELECT COUNT(*) FROM participation_taxonomy) AS "active record count", 0 AS "core PMT count", '' as "comments" FROM participation_taxonomy
UNION ALL
SELECT 'project table' as "table", COUNT(*) AS "total record count", (SELECT COUNT(*) FROM project WHERE active = true) AS "active record count", 0 AS "core PMT count", '' as "comments" FROM project
UNION ALL
SELECT 'project_contact' as "table", COUNT(*) AS "total record count", (SELECT COUNT(*) FROM project_contact) AS "active record count", 0 AS "core PMT count", '' as "comments" FROM project_contact
UNION ALL
SELECT 'project_taxonomy' as "table", COUNT(*) AS "total record count", (SELECT COUNT(*) FROM project_taxonomy) AS "active record count", 0 AS "core PMT count", '' as "comments" FROM project_taxonomy
UNION ALL
SELECT 'result table' as "table", COUNT(*) AS "total record count", (SELECT COUNT(*) FROM result WHERE active = true) AS "active record count", 0 AS "core PMT count", '' as "comments" FROM result
UNION ALL
SELECT 'result_taxonomy' as "table", COUNT(*) AS "total record count", (SELECT COUNT(*) FROM result_taxonomy) AS "active record count", 0 AS "core PMT count", '' as "comments" FROM result_taxonomy
UNION ALL
SELECT 'role table' as "table", COUNT(*) AS "total record count", (SELECT COUNT(*) FROM role WHERE active = true) AS "active record count", 4 AS "core PMT count", 'Core count reflects minimum count on default PMT install.' as "comments" FROM role
UNION ALL
SELECT 'taxonomy_xwalk table' as "table", COUNT(*) AS "total record count", (SELECT COUNT(*) FROM taxonomy_xwalk WHERE active = true) AS "active record count", 0 AS "core PMT count", 'Core count reflects minimum count on default PMT install.' as "comments" FROM taxonomy_xwalk
UNION ALL
SELECT 'user table' as "table", COUNT(*) AS "total record count", (SELECT COUNT(*) FROM "user" WHERE active = true) AS "active record count", 0 AS "core PMT count", '' as "comments" FROM "user"
UNION ALL
SELECT 'user_project_role table' as "table", COUNT(*) AS "total record count", (SELECT COUNT(*) FROM user_project_role WHERE active = true) AS "active record count", 0 AS "core PMT count", '' as "comments" FROM user_project_role
UNION ALL
SELECT 'classification table' as "table", COUNT(*) AS "total record count", (SELECT COUNT(*) FROM classification WHERE active = true) AS "active record count", 772 AS "core PMT count", 'Core count reflects minimum count on default PMT install.' as "comments" FROM classification
UNION ALL
SELECT 'taxonomy table' as "table", COUNT(*) AS "total record count", (SELECT COUNT(*) FROM taxonomy WHERE active = true) AS "active record count", 16 AS "core PMT count", 'Core count reflects minimum count on default PMT install.' as "comments" FROM taxonomy;


/******************************************************************
   pmt_edit_user_project_role

select * from pmt_edit_user_project_role(6,4,5,25,null,false);
select * from pmt_edit_user_project_role(6,4,5,25,null,true);
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_edit_user_project_role(request_user_id integer, target_user_id integer, role_id integer, project_id integer, classification_id integer, delete_record boolean default false) RETURNS SETOF pmt_json_result_type AS 
$$
DECLARE
  user_role_id integer;
  valid_project_id integer;
  valid_classification_id integer;
  record_id integer;
  execute_statement text;
  user_name text;
  rec record;
  error_msg1 text;
  error_msg2 text;
  error_msg3 text;
BEGIN	
  
  -- the first three parameters AND either the forth or fifth parameters are required for all operations
  IF ($1 IS NOT NULL) AND ($2 IS NOT NULL) AND ($3 IS NOT NULL) AND ($4 IS NOT NULL OR $5 IS NOT NULL) THEN
    -- validate user parameters
    IF (SELECT * FROM pmt_validate_user($1)) AND (SELECT * FROM pmt_validate_user($2)) THEN
      -- get users name
      SELECT INTO user_name username FROM "user" WHERE "user".user_id = $1;
      RAISE NOTICE 'User requesting edit: %', user_name;
      -- get users role
      SELECT INTO user_role_id "user".role_id FROM "user" WHERE "user".user_id = $1;
      -- user has authority for security actions on the database
      IF(SELECT security FROM role WHERE role.role_id = user_role_id) THEN
        RAISE NOTICE 'User requesting edits has authority.';
        -- validate role
        IF (SELECT * FROM pmt_validate_role($3)) THEN
          -- validate project
          IF($4 IS NOT NULL) AND (SELECT * FROM pmt_validate_project($4))THEN
            valid_project_id := $4;
          END IF;
          -- validate classification
          IF ($5 IS NOT NULL) AND (SELECT * FROM pmt_validate_classification($5)) THEN
            valid_classification_id := $5;
          END IF;
          -- authorization by project
          IF (valid_project_id IS NOT NULL) THEN            
            SELECT INTO record_id user_project_role_id FROM user_project_role WHERE user_id = $2 AND user_project_role.project_id = $4;
            -- existing record
            IF (record_id IS NOT NULL) THEN
              -- delete record
              IF ($6) THEN
                EXECUTE 'UPDATE user_project_role SET active = false, updated_by = ' || quote_literal(user_name) || ', updated_date = ' || quote_literal(current_date) || ' WHERE  user_project_role_id = ' || record_id;
              -- update record
              ELSE                
                EXECUTE 'UPDATE user_project_role SET active = true, role_id = ' || $3 || ', updated_by = ' || quote_literal(user_name) || ', updated_date = ' || quote_literal(current_date) || ' WHERE  user_project_role_id = ' || record_id;
              END IF;
            -- no record exists
            ELSE
              IF ($6) THEN
                FOR rec IN (SELECT row_to_json(j) FROM(SELECT 'Error: No records exsist with provided user_id and project_id.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
              -- create record  
              ELSE
                EXECUTE 'INSERT INTO user_project_role (user_id, role_id, project_id, created_by, updated_by) VALUES (' || $2 || ', ' || $3 || ', ' || $4  || ', ' || quote_literal(user_name) || ', '  || quote_literal(user_name) || ')';
              END IF;
            END IF;
          -- authorization by taxonomy
          ELSIF (valid_classification_id IS NOT NULL) THEN
            SELECT INTO record_id user_project_role_id FROM user_project_role WHERE user_id = $2 AND user_project_role.classification_id = $5;
            -- existing record
            IF (record_id IS NOT NULL) THEN
              -- delete record
              IF ($6) THEN
                EXECUTE 'UPDATE user_project_role SET active = false, updated_by = ' || quote_literal(user_name) || ', updated_date = ' || quote_literal(current_date) || ' WHERE  user_project_role_id = ' || record_id;
              -- update record
              ELSE
                EXECUTE 'UPDATE user_project_role SET active = true, role_id = ' || $3 || ', updated_by = ' || quote_literal(user_name) || ', updated_date = ' || quote_literal(current_date) || ' WHERE  user_project_role_id = ' || record_id;
              END IF;
            -- no record exists
            ELSE
              IF ($6) THEN
                FOR rec IN (SELECT row_to_json(j) FROM(SELECT 'Error: No records exsist with provided user_id and classification_id.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
              -- create record  
              ELSE
                EXECUTE 'INSERT INTO user_project_role (user_id, role_id, classification_id, created_by, updated_by) VALUES (' || $2 || ', ' || $3 || ', ' || $5  || ', '  || quote_literal(user_name) || ', '  || quote_literal(user_name) || ')';
              END IF;
            END IF;
          -- invalid parameters
          ELSE
            FOR rec IN (SELECT row_to_json(j) FROM(SELECT 'Error: Invalid project_id or classification_id.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
          END IF;       
        -- invalid user role
        ELSE
          FOR rec IN (SELECT row_to_json(j) FROM(SELECT 'Error: Invalid role_id.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
        END IF;
      -- user does not have authority for security actions on the database      
      ELSE
        FOR rec IN (SELECT row_to_json(j) FROM(SELECT 'Error: User does NOT have security authorization on the database.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
      END IF;
    ELSE
      FOR rec IN (SELECT row_to_json(j) FROM(SELECT 'Error: Invalid user_id.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
    END IF;      
  -- error if a required parameters is missing
  ELSE
    FOR rec IN (SELECT row_to_json(j) FROM(SELECT 'Error: A required parameter was not provided.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
  END IF; 
 
  -- editing completed successfullly
  FOR rec IN (SELECT row_to_json(j) FROM(SELECT 'Success' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;         
  
EXCEPTION WHEN others THEN
     GET STACKED DIAGNOSTICS error_msg1 = MESSAGE_TEXT,
                          error_msg2 = PG_EXCEPTION_DETAIL,
                          error_msg3 = PG_EXCEPTION_HINT;
    FOR rec IN (SELECT row_to_json(j) FROM(SELECT 'Internal Error - Contact your DBA with the following error message: ' || error_msg1 as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;	  
END;$$ LANGUAGE plpgsql;


/******************************************************************
  pmt_activate_project
  SELECT * FROM pmt_activate_project(6, 37, false)
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
  IF (SELECT * FROM pmt_validate_user_authority($1, $2, 'delete')) THEN
    RAISE NOTICE 'User has authority to delete';
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

