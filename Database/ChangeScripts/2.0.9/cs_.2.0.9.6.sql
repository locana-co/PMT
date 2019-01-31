/******************************************************************
Change Script 2.0.9.6
1. pmt_purge_project - remove logic for removing unused contacts
and organizations
2. pmt_purge_activity - remove logic for removing unused contacts
and organizations
******************************************************************/
INSERT INTO version(version, iteration, changeset) VALUES (2.0, 9, 6);
-- select * from version order by iteration desc, changeset desc;

/******************************************************************
  pmt_purge_activity  
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_purge_activity(a_id integer) RETURNS BOOLEAN AS $$
DECLARE 
BEGIN 
     IF $1 IS NULL THEN    
       RETURN FALSE;
     END IF;
	-- Purge data
	DELETE FROM activity_contact WHERE activity_id = $1;
	DELETE FROM activity_taxonomy WHERE activity_id = $1;
	DELETE FROM financial_taxonomy WHERE financial_id IN (SELECT financial_id FROM financial WHERE activity_id = $1);
	DELETE FROM financial WHERE activity_id = $1;
	DELETE FROM participation_taxonomy WHERE participation_id IN (SELECT participation_id FROM participation WHERE activity_id = $1);
	DELETE FROM detail WHERE activity_id = $1;
	DELETE FROM result_taxonomy WHERE result_id IN (SELECT result_id FROM result WHERE activity_id = $1);
	DELETE FROM result WHERE activity_id = $1;
	DELETE FROM location_taxonomy WHERE location_id IN (SELECT location_id FROM location WHERE activity_id = $1);
	DELETE FROM location_boundary WHERE location_id IN (SELECT location_id FROM location WHERE activity_id = $1);
	DELETE FROM activity WHERE activity_id = $1;
	DELETE FROM location WHERE activity_id = $1;
	DELETE FROM participation WHERE activity_id = $1;	
	PERFORM refresh_taxonomy_lookup();
     RETURN TRUE;

EXCEPTION
     WHEN others THEN RETURN FALSE;
END; 
$$ LANGUAGE 'plpgsql';

/******************************************************************
  pmt_purge_project  
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_purge_project(p_id integer) RETURNS BOOLEAN AS $$
DECLARE 
BEGIN 
     IF $1 IS NULL THEN    
       RETURN FALSE;
     END IF;
	-- Purge data
	DELETE FROM activity_contact WHERE activity_id IN (SELECT activity_id FROM activity WHERE project_id = $1);
	DELETE FROM activity_taxonomy WHERE activity_id IN (SELECT activity_id FROM activity WHERE project_id = $1);
	DELETE FROM financial_taxonomy WHERE financial_id IN (SELECT financial_id FROM financial WHERE project_id = $1);
	DELETE FROM financial WHERE project_id = $1;
	DELETE FROM participation_taxonomy WHERE participation_id IN (SELECT participation_id FROM participation WHERE project_id = $1);
	DELETE FROM project_contact WHERE project_id = $1;
	DELETE FROM project_taxonomy WHERE project_id = $1;
	DELETE FROM detail WHERE project_id = $1;
	DELETE FROM result_taxonomy WHERE result_id IN (SELECT result_id FROM result WHERE activity_id IN (SELECT activity_id FROM activity WHERE project_id = $1));
	DELETE FROM result WHERE activity_id IN (SELECT activity_id FROM activity WHERE project_id = $1);
	DELETE FROM location_taxonomy WHERE location_id IN (SELECT location_id FROM location WHERE project_id = $1);
	DELETE FROM location_boundary WHERE location_id IN (SELECT location_id FROM location WHERE project_id = $1);
	DELETE FROM user_project_role WHERE project_id = $1;
	DELETE FROM activity WHERE project_id = $1;
	DELETE FROM location WHERE project_id = $1;
	DELETE FROM participation WHERE project_id = $1;
	DELETE FROM project WHERE project_id = $1;	
        PERFORM refresh_taxonomy_lookup();
     RETURN TRUE;

EXCEPTION
     WHEN others THEN RETURN FALSE;
END; 
$$ LANGUAGE 'plpgsql';

-- update permissions
GRANT USAGE ON SCHEMA public TO pmt_read;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO pmt_read;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO pmt_read;
GRANT USAGE ON SCHEMA public TO pmt_write;
GRANT SELECT,INSERT ON ALL TABLES IN SCHEMA public TO pmt_write;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO pmt_write;