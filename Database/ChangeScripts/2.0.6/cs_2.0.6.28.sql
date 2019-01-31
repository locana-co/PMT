/******************************************************************
Change Script 2.0.6.28 - Consolidated
1. pmt_purge_project - new function for purging all data associated
to a single project.
******************************************************************/
INSERT INTO config(version, iteration, changeset) VALUES (2.0, 6, 28);
-- select * from config order by version, iteration, changeset, updated_date;

--  SELECT xml_id, project_id, action, type, taxonomy, data_group, error  FROM xml;
--  SELECT * FROM pmt_purge_activity(38520);
--  SELECT * FROM pmt_purge_project(157);

-- select * from taxonomy_lookup where project_id = 157

DROP FUNCTION IF EXISTS pmt_purge_project(integer) CASCADE;
DROP FUNCTION IF EXISTS pmt_purge_activity(integer) CASCADE;

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
        DELETE FROM activity WHERE project_id = $1;
        DELETE FROM location WHERE project_id = $1;
        DELETE FROM participation WHERE project_id = $1;
        DELETE FROM project WHERE project_id = $1;
        DELETE FROM contact_taxonomy WHERE contact_id IN (SELECT contact_id FROM contact WHERE contact_id NOT IN (SELECT DISTINCT contact_id FROM activity_contact) AND contact_id NOT IN (SELECT DISTINCT contact_id FROM project_contact));
        DELETE FROM contact WHERE contact_id NOT IN (SELECT DISTINCT contact_id FROM activity_contact) AND contact_id NOT IN (SELECT DISTINCT contact_id FROM project_contact);
        DELETE FROM organization_taxonomy WHERE organization_id IN (SELECT organization_id FROM organization WHERE organization_id NOT IN (SELECT DISTINCT organization_id FROM participation) AND organization_id NOT IN (SELECT DISTINCT organization_id FROM contact));
        DELETE FROM organization WHERE organization_id NOT IN (SELECT DISTINCT organization_id FROM participation) AND organization_id NOT IN (SELECT DISTINCT organization_id FROM contact);        
        PERFORM refresh_taxonomy_lookup();
     RETURN TRUE;

EXCEPTION
     WHEN others THEN RETURN FALSE;
END; 
$$ LANGUAGE 'plpgsql';


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
        DELETE FROM contact_taxonomy WHERE contact_id IN (SELECT contact_id FROM contact WHERE contact_id NOT IN (SELECT DISTINCT contact_id FROM activity_contact) AND contact_id NOT IN (SELECT DISTINCT contact_id FROM project_contact));
        DELETE FROM contact WHERE contact_id NOT IN (SELECT DISTINCT contact_id FROM activity_contact) AND contact_id NOT IN (SELECT DISTINCT contact_id FROM project_contact);
        DELETE FROM organization_taxonomy WHERE organization_id IN (SELECT organization_id FROM organization WHERE organization_id NOT IN (SELECT DISTINCT organization_id FROM participation) AND organization_id NOT IN (SELECT DISTINCT organization_id FROM contact));
        DELETE FROM organization WHERE organization_id NOT IN (SELECT DISTINCT organization_id FROM participation) AND organization_id NOT IN (SELECT DISTINCT organization_id FROM contact);        
        PERFORM refresh_taxonomy_lookup();
     RETURN TRUE;

EXCEPTION
     WHEN others THEN RETURN FALSE;
END; 
$$ LANGUAGE 'plpgsql';