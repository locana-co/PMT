/******************************************************************
Change Script 3.0.10.72
1. update users table set first and last name fields as required
2. update user_instance table set role_id as required
3. create pmt_find_users provide validation assistance for duplication
of users
******************************************************************/
INSERT INTO version(_version, _iteration, _changeset) VALUES (3.0, 10, 72);
-- select * from version order by _iteration desc, _changeset desc;

/******************************************************************
1. update users table set first and last name fields as required
******************************************************************/
ALTER TABLE users ALTER COLUMN _first_name SET NOT NULL;
ALTER TABLE users ALTER COLUMN _last_name SET NOT NULL;

/******************************************************************
2. update user_instance table set role_id as required
******************************************************************/
ALTER TABLE user_instance ALTER COLUMN role_id SET NOT NULL;

/******************************************************************
3. create pmt_find_users provide validation assistance for duplication
of users
  select * from pmt_find_users('shawna','paradee','sparadee@spatialdev.com');
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_find_users(first_name character varying, last_name character varying, email character varying) RETURNS SETOF pmt_json_result_type AS
$$
DECLARE 
  execute_statement text;
  rec record;
  error_msg text;
BEGIN 
	
  IF ($1 IS NULL) OR ($2 IS NULL) OR ($3 IS NULL) THEN
    FOR rec IN (SELECT row_to_json(j) FROM(SELECT 'Error: All parameters are required.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
  END IF;
  
  execute_statement := 'SELECT u.id, u._first_name, u._last_name, u._username, u._email, u.organization_id ' ||
	',(SELECT _name FROM organization WHERE id = u.organization_id) as organization ' ||
	',(SELECT array_to_json(array_agg(row_to_json(ui))) FROM (SELECT instance_id, instance, role_id, role FROM _user_instances WHERE user_id = u.id) as ui) as instances ' ||
	',(SELECT _access_date from user_log where user_id = u.id order by _access_date desc LIMIT 1) ' ||
	',u._active ' ||
	'FROM users u '
	'WHERE lower(_first_name) LIKE ' || quote_literal(lower($1)) || ' OR lower(_last_name) LIKE ' || quote_literal(lower($2)) || ' OR lower(_email) LIKE ' || quote_literal(lower($3));
	
  RAISE NOTICE 'Execute statement: %', execute_statement;			

  FOR rec IN EXECUTE 'SELECT row_to_json(j) FROM (' || execute_statement || ')j' LOOP  		
    RETURN NEXT rec;
  END LOOP;

  EXCEPTION WHEN others THEN 
  GET STACKED DIAGNOSTICS error_msg = MESSAGE_TEXT;  
    RAISE NOTICE 'Internal Error - Contact your DBA with the following error message: %', error_msg;
    	    
END;$$ LANGUAGE plpgsql; 


-- update permissions
GRANT USAGE ON SCHEMA public TO pmt_read;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO pmt_read;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO pmt_read;
GRANT USAGE ON SCHEMA public TO pmt_write;
GRANT SELECT,INSERT ON ALL TABLES IN SCHEMA public TO pmt_write;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO pmt_write;