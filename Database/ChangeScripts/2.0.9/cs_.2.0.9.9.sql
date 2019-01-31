/******************************************************************
Change Script 2.0.9.9
1. pmt_users - return active 
2. pmt_user - return active
******************************************************************/
INSERT INTO version(version, iteration, changeset) VALUES (2.0, 9, 9);
-- select * from version order by iteration desc, changeset desc;

-- select * from pmt_users()
-- select * from pmt_user(34)

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
	,u.active
	FROM "user" u
	) j 
    ) LOOP		
    RETURN NEXT rec;
  END LOOP;			  
END; 
$$ LANGUAGE 'plpgsql';

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
			',u.active ' ||
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
			',u.active ' ||
			'FROM "user" u ' ||
			'WHERE u.user_id =  ' || $1;
			    
    END IF;			  

    RAISE NOTICE 'Execute statement: %', execute_statement;
    FOR rec IN EXECUTE 'SELECT row_to_json(j) FROM (' || execute_statement || ')j' LOOP     
	RETURN NEXT rec;
    END LOOP;       
END; 
$$ LANGUAGE 'plpgsql';


-- update permissions
GRANT USAGE ON SCHEMA public TO pmt_read;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO pmt_read;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO pmt_read;
GRANT USAGE ON SCHEMA public TO pmt_write;
GRANT SELECT,INSERT ON ALL TABLES IN SCHEMA public TO pmt_write;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO pmt_write;