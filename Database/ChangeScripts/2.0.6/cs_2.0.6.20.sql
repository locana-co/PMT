/******************************************************************
Change Script 2.0.6.20 - consolidated.
1. Remove unsued congif columns
2. Update pmt_version to return latest version data.
******************************************************************/
INSERT INTO config(version, iteration, changeset) VALUES (2.0, 6, 20);

-- SELECT * FROM pmt_version();

-- remove unused columns
ALTER TABLE config DROP app_db;
ALTER TABLE config DROP app_db_server;

-- update function logic
CREATE OR REPLACE FUNCTION pmt_version() RETURNS SETOF pmt_version_result_type AS 
$$
DECLARE
  rec record;
BEGIN	
  -- collect locations 
  FOR rec IN (  SELECT version::text||'.'||iteration::text||'.'||changeset::text AS pmt_version, updated_date::date as last_update, (SELECT created_date from config where config_id = (select min(config_id) from config))::date as created
		FROM config ORDER BY version, iteration, changeset DESC LIMIT 1 
		) LOOP		
	RETURN NEXT rec;
  END LOOP;	  
END;$$ LANGUAGE plpgsql;

