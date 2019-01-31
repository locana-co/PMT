/******************************************************************
Change Script 2.0.8.35 - consolidated.
1. Rename enumerator types to follow pmt naming convention.
******************************************************************/
INSERT INTO version(version, iteration, changeset) VALUES (2.0, 8, 35);
-- select * from version order by changeset desc;

-- old drop statements
DROP FUNCTION IF EXISTS pmt_edit_activity_contact(integer, integer, integer, edit_action)  CASCADE;
DROP FUNCTION IF EXISTS pmt_edit_activity_taxonomy(character varying, integer, edit_action)  CASCADE;
DROP FUNCTION IF EXISTS pmt_edit_participation(integer, integer, integer, integer, integer, integer, edit_action)  CASCADE;
DROP FUNCTION IF EXISTS pmt_validate_user_authority(integer, integer, auth_crud)  CASCADE;

-- rename types
ALTER TYPE auth_crud RENAME TO pmt_auth_crud;
ALTER TYPE auth_source RENAME TO pmt_auth_source;
ALTER TYPE edit_action RENAME TO pmt_edit_action;

-- new drop statements
DROP FUNCTION IF EXISTS pmt_edit_activity_contact(integer, integer, integer, pmt_edit_action)  CASCADE;
DROP FUNCTION IF EXISTS pmt_edit_activity_taxonomy(character varying, integer, pmt_edit_action)  CASCADE;
DROP FUNCTION IF EXISTS pmt_edit_participation(integer, integer, integer, integer, integer, integer, pmt_edit_action)  CASCADE;
DROP FUNCTION IF EXISTS pmt_validate_user_authority(integer, integer, pmt_auth_crud)  CASCADE;

/******************************************************************
  pmt_user_auth
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_user_auth(username character varying(255), password character varying(255)) RETURNS 
SETOF pmt_json_result_type AS $$
DECLARE 
  valid_user_id integer;
  authorization_source pmt_auth_source;
  valid_data_group_id integer;
  user_organization_id integer;
  user_data_group_id integer;  
  authorized_project_ids integer[];
  role_super boolean;	
  rec record;
BEGIN 
  SELECT INTO valid_user_id "user".user_id FROM "user" WHERE "user".username = $1 AND "user".password = $2;
  IF valid_user_id IS NOT NULL THEN
    -- determine editing authorization source
    SELECT INTO authorization_source edit_auth_source from config LIMIT 1;	
    CASE authorization_source
       -- authorization determined by organization affiliation
        WHEN 'organization' THEN
         -- get users organization_id
         SELECT INTO user_organization_id organization_id FROM "user" WHERE "user".user_id = valid_user_id;   
	 -- validate users organization_id	
         IF (SELECT * FROM pmt_validate_organization(user_organization_id)) THEN
           -- get list of project_ids user has authority to edit
           SELECT INTO authorized_project_ids array_agg(DISTINCT p.project_id)::int[] FROM participation_taxonomy pt JOIN participation p ON pt.participation_id = p.participation_id
           WHERE p.organization_id = user_organization_id AND pt.classification_id IN (SELECT classification_id FROM taxonomy_classifications WHERE taxonomy = 'Organisation Role' and classification = 'Accountable');
         END IF;
       -- authorization determined by data group affiliation
       WHEN 'data_group' THEN
         -- get users data_group_id
         SELECT INTO user_data_group_id data_group_id FROM "user" WHERE "user".user_id = valid_user_id;  
         -- validate users data_group_id
	 SELECT INTO valid_data_group_id classification_id::integer FROM taxonomy_classifications WHERE classification_id = user_data_group_id AND taxonomy = 'Data Group';
	 IF (valid_data_group_id IS NOT NULL) THEN
           -- get list of project_ids user has authority to edit
           SELECT INTO authorized_project_ids array_agg(DISTINCT pt.project_id)::int[] FROM project_taxonomy pt 
           WHERE pt.classification_id IN (SELECT classification_id FROM taxonomy_classifications WHERE taxonomy = 'Data Group' and classification_id = user_data_group_id);          
         END IF;
       ELSE
    END CASE;

    -- check to see if user has a role with "SUPER" rights (if so they have full adminsitrative editing rights to the database)
    SELECT INTO role_super super FROM role WHERE role_id = (SELECT role_id FROM user_role WHERE user_role.user_id = valid_user_id);
    IF role_super THEN
      -- if super user than all project ids are authorized
      SELECT INTO authorized_project_ids array_agg(DISTINCT p.project_id)::int[] FROM project p;
    END IF;
    
    FOR rec IN (SELECT row_to_json(j) FROM( 
	SELECT user_id, first_name, last_name, "user".username, email, "user".organization_id
	,(SELECT name FROM organization WHERE organization_id = "user".organization_id) as organization, "user".data_group_id
	,(SELECT classification FROM taxonomy_classifications WHERE classification_id = "user".data_group_id) as data_group
	,array_to_string(authorized_project_ids, ',') as authorized_project_ids
	,(SELECT array_to_json(array_agg(row_to_json(r))) FROM ( SELECT r.role_id, r.name FROM role r 
	JOIN user_role ur ON r.role_id = ur.role_id WHERE ur.user_id = "user".user_id) r ) as roles 
	FROM "user" WHERE "user".user_id = valid_user_id
      ) j ) LOOP		
        RETURN NEXT rec;
    END LOOP;
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
  pmt_validate_user_authority
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_validate_user_authority(user_id integer, project_id integer, auth_type pmt_auth_crud) RETURNS boolean AS $$
DECLARE 
	user_organization_id integer;
	user_data_group_id integer;
	valid_data_group_id integer;
	authorized_project_ids integer[];
	authorized_project_id boolean;
	authorization_source pmt_auth_source;	
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
/******************************************************************
   pmt_edit_activity_taxonomy
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_edit_activity_taxonomy(activity_ids character varying, classification_id integer, edit_action pmt_edit_action) RETURNS BOOLEAN AS 
$$
DECLARE
  valid_classification_id boolean;
  valid_activity_ids integer[];
  msg text;
  record_id integer;
  t_id integer;
  i integer;
  rec record;
BEGIN	

  -- first and second parameters are required
  IF ($1 is not null AND $1 <> '') AND ($2 IS NOT NULL) THEN
  
    -- validate classification_id
    SELECT INTO valid_classification_id * FROM pmt_validate_classification($2);
    -- must provide a valid classification_id to continue
    IF NOT valid_classification_id THEN
      RAISE NOTICE 'Error: Must provide a valid classification_id.';
      RETURN false;
    END IF;
    -- validate activity_ids
    SELECT INTO valid_activity_ids array_agg(DISTINCT activity_id) FROM activity WHERE activity_id = ANY(string_to_array($1, ',')::int[]);
    -- must provide a min of one valid activity_id to continue
    IF valid_activity_ids IS NOT NULL THEN
      -- get the taxonomy_id of the classification_id
      SELECT INTO t_id taxonomy_id FROM taxonomy_classifications tc WHERE tc.classification_id = $2;
      IF t_id IS NOT NULL THEN
        -- operations based on edit_action
        CASE $3
          WHEN 'add' THEN
            FOREACH i IN ARRAY valid_activity_ids LOOP 
             SELECT INTO record_id activity_id FROM activity_taxonomy as at WHERE at.activity_id = i AND at.classification_id = $2 LIMIT 1;
             IF record_id IS NULL THEN
               EXECUTE 'INSERT INTO activity_taxonomy(activity_id, classification_id, field) VALUES ('|| i ||', '|| $2 ||', ''activity_id'')';
               RAISE NOTICE 'Add Record: %', 'Activity_id ('|| i ||') is now associated to classification_id ('|| $2 ||').'; 
             ELSE
               RAISE NOTICE'Add Record: %', 'This activity_id ('|| i ||') already has an association to this classification_id ('|| $2 ||').';                
             END IF;
            END LOOP;
          WHEN 'delete' THEN
            FOREACH i IN ARRAY valid_activity_ids LOOP 
              EXECUTE 'DELETE FROM activity_taxonomy WHERE activity_id ='|| i ||' AND classification_id = '|| $2 ||' AND field = ''activity_id'''; 
              RAISE NOTICE 'Delete Record: %', 'Remove association to classification_id ('|| $2 ||') for actvity_id ('|| i ||')';
            END LOOP;
          WHEN 'replace' THEN
            FOREACH i IN ARRAY valid_activity_ids LOOP 
              EXECUTE 'DELETE FROM activity_taxonomy WHERE activity_id ='|| i ||' AND classification_id in (SELECT classification_id FROM taxonomy_classifications WHERE taxonomy_id = '|| t_id||') AND field = ''activity_id''';
              RAISE NOTICE 'Delete Record: %', 'Remove association to taxonomy_id ('|| t_id ||') for actvity_id ('|| i ||')';
	      EXECUTE 'INSERT INTO activity_taxonomy(activity_id, classification_id, field) VALUES ('|| i ||', '|| $2 ||', ''activity_id'')'; 
              RAISE NOTICE 'Add Record: %', 'Activity_id ('|| i ||') is now associated to classification_id ('|| $2 ||').';
            END LOOP;
          ELSE
            FOREACH i IN ARRAY valid_activity_ids LOOP 
             SELECT INTO record_id activity_id FROM activity_taxonomy as at WHERE at.activity_id = i AND at.classification_id = $2 LIMIT 1;
             IF record_id IS NULL THEN
               EXECUTE 'INSERT INTO activity_taxonomy(activity_id, classification_id, field) VALUES ('|| i ||', '|| $2 ||', ''activity_id'')';
               RAISE NOTICE 'Add Record: %', 'Activity_id ('|| i ||') is now associated to classification_id ('|| $2 ||').'; 
             ELSE
               RAISE NOTICE'Add Record: %', 'This activity_id ('|| i ||') already has an association to this classification_id ('|| $2 ||').';                
             END IF;
            END LOOP;
        END CASE;
        RETURN true;
      ELSE
        RAISE NOTICE 'Error: There is no taxonomy_id for given classification_id.';
	RETURN false;
      END IF;
    ELSE
      RAISE NOTICE 'Error: Must provide at least one valid activity_id.';
      RETURN false;
    END IF;
  ELSE
    RAISE NOTICE 'Error: Must provide all parameters.';
    RETURN false;
  END IF; 	  
END;$$ LANGUAGE plpgsql;
/******************************************************************
   pmt_edit_activity_contact
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_edit_activity_contact(user_id integer, activity_id integer, contact_id integer, edit_action pmt_edit_action) RETURNS BOOLEAN AS 
$$
DECLARE
  p_id integer;
  record_id integer;
BEGIN	
  -- first three parameters are required 
  IF ($1 IS NOT NULL) AND ($2 IS NOT NULL) AND ($3 IS NOT NULL) THEN
    -- validate activity_id & contact_id
    IF (SELECT * FROM pmt_validate_activity($2)) AND (SELECT * FROM pmt_validate_contact($3)) THEN
      -- get project_id for activity
      SELECT INTO p_id project_id FROM activity WHERE activity.activity_id = $2;
      
      -- operations based on the requested edit action
      CASE $4
        WHEN 'delete' THEN
          -- validate users authority to perform an update action on this project
          IF (SELECT * FROM pmt_validate_user_authority($1, p_id, 'update')) THEN          
            EXECUTE 'DELETE FROM activity_contact WHERE activity_id ='|| $2 ||' AND contact_id = '|| $3; 
            RAISE NOTICE 'Delete Record: %', 'Remove association to contact_id ('|| $3 ||') for actvity_id ('|| $2 ||')';
          ELSE
            RAISE NOTICE 'Error: The requested edit action requires the user to have UPDATE rights to this project: %', p_id;
	    RETURN FALSE;
          END IF;           
        WHEN 'replace' THEN            
           -- validate users authority to perform an update and create action on this project
          IF (SELECT * FROM pmt_validate_user_authority($1, p_id, 'update')) AND (SELECT * FROM pmt_validate_user_authority($1, p_id, 'create')) THEN          
            EXECUTE 'DELETE FROM activity_contact WHERE activity_id ='|| $2;
            RAISE NOTICE 'Delete Record: %', 'Removed all contacts for actvity_id ('|| $2 ||')';
	    EXECUTE 'INSERT INTO activity_contact(activity_id, contact_id) VALUES ('|| $2 ||', '|| $3 ||')';
            RAISE NOTICE 'Add Record: %', 'Activity_id ('|| $2 ||') is now associated to contact_id ('|| $3 ||').'; 
          ELSE
            RAISE NOTICE 'Error: The requested edit action requires the user to have UPDATE and CREATE rights to this project: %', p_id;
	    RETURN FALSE;
          END IF;        
        ELSE
          -- validate users authority to perform a create action on this project
          IF (SELECT * FROM pmt_validate_user_authority($1, p_id, 'create')) THEN          
            SELECT INTO record_id ac.activity_id FROM activity_contact as ac WHERE ac.activity_id = $2 AND ac.contact_id = $3 LIMIT 1;
            IF record_id IS NULL THEN
              EXECUTE 'INSERT INTO activity_contact(activity_id, contact_id) VALUES ('|| $2 ||', '|| $3 ||')';
              RAISE NOTICE 'Add Record: %', 'Activity_id ('|| $2 ||') is now associated to contact_id ('|| $3 ||').'; 
            ELSE
              RAISE NOTICE'Add Record: %', 'This activity_id ('|| $2 ||') already has an association to this contact_id ('|| $3 ||').';                
            END IF;
          ELSE
            RAISE NOTICE 'Error: The requested edit action requires the user to have CREATE rights to this project: %', p_id;
	    RETURN FALSE;
          END IF;                  
      END CASE;
      -- edits are complete return successful
      RETURN TRUE;         
    ELSE
      RAISE NOTICE 'Error: Invalid activity_id or contact_id.';
      RETURN FALSE;
    END IF;
  ELSE
    RAISE NOTICE 'Error: Must provide all parameters.';
    RETURN false;
  END IF; 
  
EXCEPTION WHEN others THEN
    RETURN FALSE;  	  
END;$$ LANGUAGE plpgsql;
/******************************************************************
   pmt_edit_participation
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_edit_participation(user_id integer, participation_id integer, project_id integer, activity_id integer, 
organization_id integer, classification_id integer, edit_action pmt_edit_action) RETURNS BOOLEAN AS 
$$
DECLARE
  p_id integer;
  o_id integer;  
  a_id integer;  
  c_id integer;  
  record_id integer;
  participation_records integer[];
  user_name text;
BEGIN	

  -- user parameter is required
  IF ($1 IS NULL) THEN
    RAISE NOTICE 'Error: Must have user_id parameter.';
    RETURN FALSE;  
  END IF;
  -- get users name
  SELECT INTO user_name username FROM "user" WHERE "user".user_id = $1;
  -- validate participation_id if provided
  IF ($2 IS NOT NULL) THEN
    SELECT INTO record_id p.participation_id FROM participation p WHERE p.participation_id = $2 AND active = true;
    IF record_id IS NULL THEN
      RAISE NOTICE 'Error: Provided participation_id is invalid or inactive.';
      RETURN FALSE;
    END IF;    
  END IF;  
  -- validate project_id if provided
  IF ($3 IS NOT NULL) THEN
    SELECT INTO p_id p.project_id FROM project p WHERE p.project_id = $3 AND active = true;
    IF p_id IS NULL THEN
      RAISE NOTICE 'Error: Provided project_id is invalid or inactive.';
      RETURN FALSE;
    END IF;    
  END IF;
  -- validate activity_id if provided
  IF ($4 IS NOT NULL) THEN
    SELECT INTO a_id a.activity_id FROM activity a WHERE a.activity_id = $4 AND active = true;
    IF a_id IS NULL THEN
      RAISE NOTICE 'Error: Provided activity_id is invalid or inactive.';
      RETURN FALSE;
    END IF;    
  END IF;
  -- validate organization_id if provided
  IF ($5 IS NOT NULL) THEN
    SELECT INTO o_id o.organization_id FROM organization o WHERE o.organization_id = $5 AND active = true;
    IF o_id IS NULL THEN
      RAISE NOTICE 'Error: Provided organization_id is invalid or inactive.';
      RETURN FALSE;
    END IF;    
  END IF;
  -- validate classification_id if provided
  IF ($6 IS NOT NULL) THEN
    SELECT INTO c_id c.classification_id FROM classification c WHERE c.classification_id = $5 AND active = true AND c.classification_id IN (select classification_id from taxonomy_classifications where taxonomy = 'Organisation Role');
    IF c_id IS NULL THEN
      RAISE NOTICE 'Error: Provided classification_id is not in the Organisation Role taxonomy or is inactive.';
      RETURN FALSE;
    END IF;    
  END IF;
  
  -- operations based on the requested edit action
  CASE $7
    WHEN 'delete' THEN
      -- check for required parameters
      IF (record_id IS NULL) THEN 
        RAISE NOTICE 'Error: Must have participation_id parameter when edit action is: %', $7;
	RETURN FALSE;  
      END IF;  
      -- validate users authority to perform an update action on this project
      IF (SELECT * FROM pmt_validate_user_authority($1, p_id, 'update')) THEN
        EXECUTE 'DELETE FROM participation WHERE participation_id ='|| record_id; 
        EXECUTE 'DELETE FROM participation_taxonomy WHERE participation_id ='|| record_id; 
        RAISE NOTICE 'Delete Record: %', 'Removed participation and taxonomy associated to this participation_id ('|| record_id ||')';
      ELSE
        RAISE NOTICE 'Error: The requested edit action requires the user to have UPDATE rights to this project: %', p_id;
        RETURN FALSE;
      END IF;   
    WHEN 'replace' THEN            
      -- check for required parameters
      IF (p_id IS NULL) OR (o_id IS NULL) OR (c_id IS NULL) THEN
        RAISE NOTICE 'Error: Must have project_id, organization_id and classification_id parameters when edit action is: %', $7;
	RETURN FALSE;  
      END IF;
      -- validate users authority to perform an update and create action on this project
      IF (SELECT * FROM pmt_validate_user_authority($1, p_id, 'update')) AND (SELECT * FROM pmt_validate_user_authority($1, p_id, 'create')) THEN        
        IF a_id IS NOT NULL THEN
          -- activity participation
          SELECT INTO participation_records array_agg(p.participation_id)::int[] FROM participation p WHERE p.project_id = p_id AND p.activity_id = a_id;
          RAISE NOTICE 'Participation records to be deleted and replaced: %', participation_records;
          EXECUTE 'DELETE FROM participation WHERE participation_id = ANY(ARRAY['|| array_to_string(participation_records, ',')  || '])'; 
          EXECUTE 'DELETE FROM participation_taxonomy WHERE participation_id= ANY(ARRAY['|| array_to_string(participation_records, ',')  || '])'; 
          EXECUTE 'INSERT INTO participation(project_id, activity_id, organization_id, created_by, updated_by) VALUES (' || p_id || ',' || a_id || ',' || o_id || 
		',' || quote_literal(user_name) || ',' || quote_literal(user_name) || ') RETURNING participation_id;' INTO record_id;
          EXECUTE 'INSERT INTO participation_taxonomy(participation_id, classification_id, field) VALUES (' || record_id || ',' || c_id || ', ''participation_id'');';
          RAISE NOTICE 'Add Record: %', 'participation_id ('|| record_id ||') has organiztaion_id  ('|| o_id ||'), project_id ('|| p_id ||'), activity_id ('|| a_id ||
		') is now associated to classification_id ('|| c_id ||').'; 
        ELSE
          -- project participation
          SELECT INTO participation_records array_agg(p.participation_id)::int[]  FROM participation p WHERE p.project_id = p_id AND p.activity_id IS NULL;
          RAISE NOTICE 'Participation records to be deleted and replaced: %', participation_records;
          EXECUTE 'DELETE FROM participation WHERE participation_id = ANY(ARRAY['|| array_to_string(participation_records, ',') || '])'; 
          EXECUTE 'DELETE FROM participation_taxonomy WHERE participation_id = ANY(ARRAY['|| array_to_string(participation_records, ',') || '])'; 
          EXECUTE 'INSERT INTO participation(project_id, organization_id, created_by, updated_by) VALUES (' || p_id || ',' || o_id || 
		',' || quote_literal(user_name) || ',' || quote_literal(user_name) || ') RETURNING participation_id;' INTO record_id;
          EXECUTE 'INSERT INTO participation_taxonomy(participation_id, classification_id, field) VALUES (' || record_id || ',' || c_id || ', ''participation_id'');';
          RAISE NOTICE 'Add Record: %', 'participation_id ('|| record_id ||') has organiztaion_id  ('|| o_id ||'), project_id ('|| p_id ||') is now associated to classification_id ('|| c_id ||').'; 
        END IF;
      ELSE
        RAISE NOTICE 'Error: The requested edit action requires the user to have UPDATE and CREATE rights to this project: %', p_id;
        RETURN FALSE;
      END IF;
    ELSE
      -- check for required parameters
      IF (p_id IS NULL) OR (o_id IS NULL) OR (c_id IS NULL) THEN
        RAISE NOTICE 'Error: Must have project_id, organization_id and classification_id parameters when edit action is: %', $7;
	RETURN FALSE;  
      END IF;
      -- validate users authority to perform a create action on this project
      IF (SELECT * FROM pmt_validate_user_authority($1, p_id, 'create')) THEN
        IF a_id IS NOT NULL THEN
          -- activity participation          
          EXECUTE 'INSERT INTO participation(project_id, activity_id, organization_id, created_by, updated_by) VALUES (' || p_id || ',' || a_id || ',' || o_id || 
		',' || quote_literal(user_name) || ',' || quote_literal(user_name) || ') RETURNING participation_id;' INTO record_id;
          EXECUTE 'INSERT INTO participation_taxonomy(participation_id, classification_id, field) VALUES (' || record_id || ',' || c_id || ', ''participation_id'');';
          RAISE NOTICE 'Add Record: %', 'participation_id ('|| record_id ||') has organiztaion_id  ('|| o_id ||'), project_id ('|| p_id ||'), activity_id ('|| a_id ||
		') is now associated to classification_id ('|| c_id ||').'; 
        ELSE
          -- project participation          
          EXECUTE 'INSERT INTO participation(project_id, organization_id, created_by, updated_by) VALUES (' || p_id || ',' || o_id || 
		',' || quote_literal(user_name) || ',' || quote_literal(user_name) || ') RETURNING participation_id;' INTO record_id;
          EXECUTE 'INSERT INTO participation_taxonomy(participation_id, classification_id, field) VALUES (' || record_id || ',' || c_id || ', ''participation_id'');';
          RAISE NOTICE 'Add Record: %', 'participation_id ('|| record_id ||') has organiztaion_id  ('|| o_id ||'), project_id ('|| p_id ||') is now associated to classification_id ('|| c_id ||').'; 
        END IF;
      ELSE
        RAISE NOTICE 'Error: The requested edit action requires the user to have CREATE rights to this project: %', p_id;
        RETURN FALSE;
      END IF;        
  END CASE;

  -- edits are complete return successful
  RETURN TRUE;         
            
EXCEPTION WHEN others THEN
     RETURN FALSE;  	  
END;$$ LANGUAGE plpgsql;

-- update permissions
GRANT USAGE ON SCHEMA public TO pmt_read;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO pmt_read;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO pmt_read;
GRANT USAGE ON SCHEMA public TO pmt_write;
GRANT SELECT,INSERT ON ALL TABLES IN SCHEMA public TO pmt_write;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO pmt_write;