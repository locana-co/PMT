/******************************************************************
Change Script 2.0.8.6 - consolidated.
1. pmt_contacts - new function to get all contacts in the database
1. pmt_orgs - new function to get all organizations in the database
******************************************************************/
INSERT INTO config(version, iteration, changeset) VALUES (2.0, 8, 6);
-- select * from config order by changeset desc;

DROP FUNCTION IF EXISTS pmt_contacts()  CASCADE;
DROP FUNCTION IF EXISTS pmt_orgs()  CASCADE;

DROP TYPE IF EXISTS pmt_contacts_result_type CASCADE;
DROP TYPE IF EXISTS pmt_orgs_result_type CASCADE;

CREATE TYPE pmt_contacts_result_type AS (response json);
CREATE TYPE pmt_orgs_result_type AS (response json);

-- select * from pmt_contacts();
-- select * from pmt_orgs();

/******************************************************************
   pmt_contacts
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_contacts() RETURNS SETOF pmt_contacts_result_type AS 
$$
DECLARE
  rec record;
BEGIN	
  
  FOR rec IN ( SELECT row_to_json(j) FROM ( 
    SELECT c.contact_id as c_id, first_name, last_name, email, organization_id as o_id,
	(SELECT name FROM organization where organization_id = c.organization_id) as org
    FROM contact c
    ORDER BY last_name, first_name) j
  ) LOOP		
	RETURN NEXT rec;
  END LOOP;	  
END;$$ LANGUAGE plpgsql;
/******************************************************************
   pmt_orgs
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_orgs() RETURNS SETOF pmt_orgs_result_type AS 
$$
DECLARE
  rec record;
BEGIN	
  
  FOR rec IN ( SELECT row_to_json(j) FROM ( 
    SELECT organization_id as o_id, name
    FROM organization
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