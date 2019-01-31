/******************************************************************
Change Script 3.0.10.10

1. update pmt_users to include login timestamp
******************************************************************/
INSERT INTO version(_version, _iteration, _changeset) VALUES (3.0, 10, 10);
-- select * from version order by _iteration desc, _changeset desc;

/******************************************************************
1. update pmt_users to include login timestamp
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
	,u.role_id
	,(SELECT _name FROM role WHERE id = u.role_id) as role
	,(SELECT _access_date from user_log where user_id = u.id order by _access_date desc LIMIT 1)
	,u._active
	FROM users u
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
