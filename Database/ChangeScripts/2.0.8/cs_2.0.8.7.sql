/******************************************************************
Change Script 2.0.8.7 - consolidated.
1. version - rename config table to version and remove app_dir.
2. pmt_version - update to use version table.
3. config - create new table to hold configuration information for a
pmt instance (i.e. editing authorization source).
4. pmt_validate_user_authority - new function to validate a user and
project to determine if user has authorization to edit the given
project.
******************************************************************/
INSERT INTO version(version, iteration, changeset) VALUES (2.0, 8, 7);
-- select * from version order by changeset desc;

-- drop statements
DROP TABLE IF EXISTS "version" CASCADE;


-- version table
CREATE TABLE "version"
(
	"version_id"		SERIAL				NOT NULL
	,"version"		numeric(2,1)
	,"iteration" 		integer
	,"changeset" 		integer
	,"created_date" 	timestamp without time zone 	NOT NULL DEFAULT current_date
	,"updated_date" 	timestamp without time zone 	NOT NULL DEFAULT current_date
	,CONSTRAINT version_id PRIMARY KEY(version_id)
);

-- add the current version information
-- INSERT INTO version(version, iteration, changeset, download_dir) VALUES (2.0, 8, 0);

-- copy all the rows from config into version
INSERT INTO version(version, iteration, changeset, created_date, updated_date)
	SELECT version, iteration, changeset, created_date, updated_date  FROM config;

-- pmt_version
CREATE OR REPLACE FUNCTION pmt_version() RETURNS SETOF pmt_version_result_type AS 
$$
DECLARE
  rec record;
BEGIN	
  FOR rec IN (  SELECT version::text||'.'||iteration::text||'.'||changeset::text AS pmt_version, updated_date::date as last_update, (SELECT created_date from config where config_id = (select min(config_id) from config))::date as created
		FROM version ORDER BY version, iteration, changeset DESC LIMIT 1 
		) LOOP		
	RETURN NEXT rec;
  END LOOP;	  
END;$$ LANGUAGE plpgsql;

DROP TABLE IF EXISTS  config CASCADE;
DROP TYPE IF EXISTS edit_auth CASCADE;
CREATE TYPE auth_source AS ENUM ('organization','data_group');
-- Configuration
CREATE TABLE "config" 
(
	"config_id" 		SERIAL				NOT NULL
	,"version"		numeric(2,1)
	,"download_dir"		text
	,"edit_auth_source"	auth_source			DEFAULT 'data_group'
	,"created_date" 	timestamp without time zone 	NOT NULL DEFAULT current_date
	,"updated_date" 	timestamp without time zone 	NOT NULL DEFAULT current_date
	,CONSTRAINT config_id PRIMARY KEY(config_id)
);
-- add the current configuration information
INSERT INTO config(version, download_dir) VALUES (2.0, '/var/lib/postgresql/9.3/main/');
-- UPDATE config SET edit_auth_source = 'organization'; --(bmgf)

-- SELECT * FROM config;

-- select * from pmt_validate_user_authority(34 , 1, 'create')  -- sparadee (super)  always true
-- select * from pmt_validate_user_authority(1, 704, 'delete') -- krao (editor 521)  false
-- select * from pmt_validate_user_authority(1, 704, 'update') -- krao (editor 521)  true

-- select * from pmt_validate_user_authority(4, 15, 'update') -- kenya_user (editor 3)  true
-- select * from pmt_validate_user_authority(4, 15, 'delete') -- kenya_user (editor 3)  false

DROP FUNCTION IF EXISTS pmt_validate_user_authority(integer, integer)  CASCADE;

CREATE TYPE auth_crud AS ENUM ('create','read','update','delete');

DROP FUNCTION IF EXISTS pmt_validate_user_authority(integer, integer, auth_crud)  CASCADE;

/******************************************************************
  pmt_validate_user_authority
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_validate_user_authority(user_id integer, project_id integer, auth_type auth_crud) RETURNS boolean AS $$
DECLARE 
	user_organization_id integer;
	user_data_group_id integer;
	valid_data_group_id integer;
	authorized_project_ids integer[];
	authorized_project_id boolean;
	authorization_source auth_source;	
	role_crud boolean;
BEGIN 
     -- user and authorization type parameters are required
     IF $1 IS NULL  OR $3 IS NULL THEN    
       RAISE NOTICE 'Missing required parameters';
       RETURN FALSE;
     END IF;    

     -- check to see if user has a role with "SUPER" rights (if so they have full adminsitrative editing rights to the database)
     SELECT INTO role_crud super FROM role WHERE role_id = (SELECT role_id FROM user_role WHERE user_role.user_id = $1);

     IF role_crud THEN
       RAISE NOTICE 'User is a Super User';
       RETURN TRUE;
     END IF;

     -- get users authorization type based on their role
     CASE auth_type
	WHEN 'create' THEN
	  SELECT INTO role_crud "create" FROM role WHERE role_id = (SELECT role_id FROM user_role WHERE user_role.user_id = $1);	    
	WHEN 'read' THEN
	  SELECT INTO role_crud "read" FROM role WHERE role_id = (SELECT role_id FROM user_role WHERE user_role.user_id = $1);
	WHEN 'update' THEN
	  SELECT INTO role_crud "update" FROM role WHERE role_id = (SELECT role_id FROM user_role WHERE user_role.user_id = $1);
  	WHEN 'delete' THEN
	  SELECT INTO role_crud "delete" FROM role WHERE role_id = (SELECT role_id FROM user_role WHERE user_role.user_id = $1);
	ELSE
	  RETURN FALSE;
     END CASE;       

     -- If there is no project_id provided then validate based on users authorization type (CRUD)
     IF $2 IS NULL THEN       
       IF role_crud THEN
	 RETURN TRUE;
       ELSE
	 RETURN FALSE;
       END IF;
     END IF;
     
     -- determine editing authorization source
     SELECT INTO authorization_source edit_auth_source from config LIMIT 1;

     CASE authorization_source
       -- authorization determined by organization affiliation
       WHEN 'organization' THEN
         -- get users organization_id
         SELECT INTO user_organization_id organization_id FROM "user" WHERE "user".user_id = $1;   
	 -- validate users organization_id	
         IF (SELECT * FROM pmt_validate_organization(user_organization_id)) THEN
           RAISE NOTICE 'Organization id is valid: %', user_organization_id;
           -- get list of project_ids user has authority to edit
           SELECT INTO authorized_project_ids array_agg(DISTINCT p.project_id)::int[] FROM participation_taxonomy pt JOIN participation p ON pt.participation_id = p.participation_id
           WHERE p.organization_id = user_organization_id AND pt.classification_id IN (SELECT classification_id FROM taxonomy_classifications WHERE taxonomy = 'Organisation Role' and classification = 'Accountable');
           RAISE NOTICE 'Authorized project_ids: %', authorized_project_ids;
	 ELSE
	   RAISE NOTICE 'Organization id for user is NOT valid.';
	   RETURN FALSE;
         END IF;
       -- authorization determined by data group affiliation
       WHEN 'data_group' THEN
         -- get users data_group_id
         SELECT INTO user_data_group_id data_group_id FROM "user" WHERE "user".user_id = $1;  
         -- validate users data_group_id
	 SELECT INTO valid_data_group_id classification_id::integer FROM taxonomy_classifications WHERE classification_id = user_data_group_id AND taxonomy = 'Data Group';
	 IF (valid_data_group_id IS NOT NULL) THEN
           RAISE NOTICE 'Data Group id is valid: %', user_data_group_id;
           -- get list of project_ids user has authority to edit
           SELECT INTO authorized_project_ids array_agg(DISTINCT pt.project_id)::int[] FROM project_taxonomy pt 
           WHERE pt.classification_id IN (SELECT classification_id FROM taxonomy_classifications WHERE taxonomy = 'Data Group' and classification_id = user_data_group_id);          
           RAISE NOTICE 'Authorized project_ids: %', authorized_project_ids;
	 ELSE
	   RAISE NOTICE 'Data Group id for user is NOT valid.';
	   RETURN FALSE;
         END IF;
       ELSE
     END CASE;             

     IF authorized_project_ids IS NOT NULL THEN
       -- the requested project is in the list of authorized projects
       IF ($2 = ANY(authorized_project_ids)) THEN        
         RAISE NOTICE 'Project id (%) in authorized projects.', $2;
         -- determine if the authorization type is allowed by user role
         IF role_crud THEN
	   RETURN TRUE;
         ELSE
           RAISE NOTICE 'User does not have request authorization type: %', $3;
	   RETURN FALSE;
         END IF;
       ELSE
         RAISE NOTICE 'Project id (%) NOT in authorized projects.', $2;
	 RETURN FALSE;
       END IF;
     ELSE
        RAISE NOTICE 'There are NO authorized projects';
	RETURN FALSE;
     END IF;
    
EXCEPTION WHEN others THEN
    RETURN FALSE;
END; 
$$ LANGUAGE 'plpgsql';

-- update permissions
GRANT USAGE ON SCHEMA public TO pmt_read;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO pmt_read;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO pmt_read;
GRANT USAGE ON SCHEMA public TO pmt_write;
GRANT SELECT,INSERT ON ALL TABLES IN SCHEMA public TO pmt_write;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO pmt_write;