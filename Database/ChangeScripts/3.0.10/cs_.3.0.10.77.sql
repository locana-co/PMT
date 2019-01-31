/******************************************************************
Change Script 3.0.10.77
1. update overloaded pmt_users method to include authorization information
******************************************************************/
INSERT INTO version(_version, _iteration, _changeset) VALUES (3.0, 10, 77);
-- select * from version order by _iteration desc, _changeset desc;

/******************************************************************
1. update overloaded pmt_users method to include authorization information
  select * from pmt_users(2);
******************************************************************/
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
	SELECT u.id, u._first_name, u._last_name, u._username, u._email, u.organization_id
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
		,(SELECT _access_date from user_log where user_id = u.id order by _access_date desc LIMIT 1)
		,u._active	
	FROM (SELECT * FROM user_instance ui WHERE ui.instance_id = $1) ui
	JOIN users u
	ON ui.user_id = u.id
	JOIN (SELECT * FROM role WHERE _name = 'Editor') r
	ON ui.role_id = r.id
	UNION ALL
	-- get authorizations for Administrator/Super (all activities in data group(s) for instance)
	SELECT u.id, u._first_name, u._last_name, u._username, u._email, u.organization_id
	,(SELECT _name FROM organization WHERE id = u.organization_id) as organization
	, r.id as role_id, r._name as role
	,(SELECT row_to_json(a) FROM ( 
			SELECT (SELECT array_agg(id) as activity_ids
			FROM activity a		
			WHERE ARRAY[a.data_group_id] <@ (SELECT data_group_ids FROM instance WHERE id = $1)) as activity_ids,
			(SELECT null as classification_ids) as classification_ids
			) a ) as authorizations
		,(SELECT _access_date from user_log where user_id = u.id order by _access_date desc LIMIT 1)
		,u._active	
	FROM (SELECT * FROM user_instance ui WHERE ui.instance_id = $1) ui
	JOIN users u
	ON ui.user_id = u.id
	JOIN (SELECT * FROM role WHERE _name IN ('Administrator','Super')) r
	ON ui.role_id = r.id
	UNION ALL
	-- get authorizations for Reader (no authorizations)
	SELECT u.id, u._first_name, u._last_name, u._username, u._email, u.organization_id
	,(SELECT _name FROM organization WHERE id = u.organization_id) as organization
	, r.id as role_id, r._name as role
	,(SELECT row_to_json(a) FROM ( 
			SELECT (SELECT null as activity_ids) as activity_ids,
			(SELECT null as classification_ids) as classification_ids
			) a ) as authorizations
		,(SELECT _access_date from user_log where user_id = u.id order by _access_date desc LIMIT 1)
		,u._active	
	FROM (SELECT * FROM user_instance ui WHERE ui.instance_id = $1) ui
	JOIN users u
	ON ui.user_id = u.id
	JOIN (SELECT * FROM role WHERE _name = 'Reader') r
	ON ui.role_id = r.id
	) j 
  ) LOOP		
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