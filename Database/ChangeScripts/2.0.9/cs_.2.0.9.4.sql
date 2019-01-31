/******************************************************************
Change Script 2.0.9.4
1. pmt_contacts - update to return only active contacts.
2. pmt_orgs - update to return only active organizations.
******************************************************************/
INSERT INTO version(version, iteration, changeset) VALUES (2.0, 9, 4);
-- select * from version order by iteration desc, changeset desc;

-- TESTING:
-- select * from pmt_contacts()
-- select * from pmt_orgs()

/******************************************************************
   pmt_contacts
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_contacts() RETURNS SETOF pmt_json_result_type AS $$
DECLARE
  rec record;
BEGIN	
  
  FOR rec IN ( SELECT row_to_json(j) FROM ( 
    SELECT c.contact_id as c_id, first_name, last_name, email, organization_id as o_id,
	(SELECT name FROM organization where organization_id = c.organization_id and active = true) as org
    FROM contact c
    WHERE active = true
    ORDER BY last_name, first_name) j
  ) LOOP		
	RETURN NEXT rec;
  END LOOP;	  
END;$$ LANGUAGE plpgsql;

/******************************************************************
   pmt_orgs
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_orgs() RETURNS SETOF pmt_json_result_type AS $$
DECLARE
  rec record;
BEGIN	
  
  FOR rec IN ( SELECT row_to_json(j) FROM ( 
    SELECT organization_id as o_id, name
    FROM organization
    WHERE active = true
    ORDER BY name) j
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

