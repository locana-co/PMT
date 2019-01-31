/******************************************************************
Change Script 2.0.8.60
1. pmt_orgs - restrict returned organizations to active only.
******************************************************************/
INSERT INTO version(version, iteration, changeset) VALUES (2.0, 8, 60);
-- select * from version order by changeset desc;

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