/******************************************************************
Change Script 3.0.10.86
1. update pmt_contacts to adhere to db version 3.0.10
******************************************************************/
INSERT INTO version(_version, _iteration, _changeset) VALUES (3.0, 10, 86);
-- select * from version order by _iteration desc, _changeset desc;

/******************************************************************
1. update pmt_contacts to include contact id
select * from pmt_contacts();
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_contacts() RETURNS SETOF pmt_json_result_type AS $$
DECLARE
  rec record;
BEGIN	
  
  FOR rec IN ( SELECT row_to_json(j) FROM ( 
    SELECT c.id, _first_name, _last_name, _title, _email, organization_id as o_id,
	(SELECT _name FROM organization where id = c.organization_id and _active = true) as org,
	(SELECT array_agg(activity_id) FROM activity_contact WHERE contact_id = c.id) as activities
    FROM contact c
    WHERE _active = true
    ORDER BY _last_name, _first_name) j
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