/******************************************************************
Change Script 2.0.8.20 - consolidated.
1. pmt_user_auth - adding logic to write to audit table for the purpose
of tracking users.
******************************************************************/
INSERT INTO version(version, iteration, changeset) VALUES (2.0, 8, 20);
-- select * from version order by changeset desc;

DROP TABLE IF EXISTS  user_activity CASCADE;

-- select * from pmt_user_auth('sparadee', '$2a$10$4QcfiM6aIcnGfnCkib7jGe294WyGfwcaPTdzeYaH7el6885S41DFu');
-- select * from pmt_user_auth('sparadee', '$2a$10$DPnA68frTNMBCUD/Z0JnZONUte.CYVtu7LYz28auiokzFgXXj');
-- select * from pmt_user_auth('user test', '$2a$10$DPnA68frTNMBCUD/Z0JnZONUte.CYVtu7LYz28auiokzFgXXjJs92');
-- select * from pmt_user_auth('kenya_user', '$2a$10$exaSGq.CMsAMCQy1NWZaL.dJhTaBP3iwoKUTX/GEdeFmNq8/axefe');

--User Activity
CREATE TABLE "user_activity"
(
	"user_activity_id"	SERIAL				NOT NULL
	,"user_id"		integer 			NULL			
	,"username"		character varying(255)		NOT NULL
	,"access_date" 		timestamp		 	NOT NULL DEFAULT current_timestamp
	,"status"		character varying(50)		NOT NULL 
	,CONSTRAINT user_activity_id PRIMARY KEY(user_activity_id)
);

CREATE OR REPLACE FUNCTION pmt_user_auth(username character varying(255), password character varying(255)) RETURNS 
SETOF pmt_user_auth_result_type AS $$
DECLARE 
  valid_user_id integer;
  authorization_source auth_source;
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

-- new permissions
GRANT SELECT, INSERT ON user_activity TO pmt_read;
GRANT USAGE ON user_activity_user_activity_id_seq TO pmt_read;
-- update permissions
GRANT USAGE ON SCHEMA public TO pmt_read;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO pmt_read;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO pmt_read;
GRANT USAGE ON SCHEMA public TO pmt_write;
GRANT SELECT,INSERT ON ALL TABLES IN SCHEMA public TO pmt_write;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO pmt_write;
