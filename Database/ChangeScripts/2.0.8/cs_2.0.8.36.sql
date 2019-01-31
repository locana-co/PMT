/******************************************************************
Change Script 2.0.8.36 - consolidated.
1. pmt_edit_project_contact - new function for editing a project's
contacts.
2. pmt_validate_project - new function to validate a active project_id 
3. pmt_validate_projects - new function to validate active project_ids
******************************************************************/
INSERT INTO version(version, iteration, changeset) VALUES (2.0, 8, 36);
-- select * from version order by changeset desc;

DROP FUNCTION IF EXISTS pmt_edit_project_contact(integer, integer, integer, pmt_edit_action)  CASCADE;
DROP FUNCTION IF EXISTS pmt_validate_project(integer)  CASCADE;
DROP FUNCTION IF EXISTS pmt_validate_projects(character varying)  CASCADE;

-- SELECT * FROM pmt_validate_user_authority(34, 733, 'update') -- bmgf
-- SELECT * FROM pmt_validate_user_authority(1, 3, 'update') -- oam
-- select * from project_contact where project_id = 771 
-- select * from contact limit 10 -- 113,145

-- select * from pmt_edit_project_contact(3,15, 14, 'add');
-- select * from pmt_edit_project_contact(3,15, 15, 'add');
-- select * from pmt_edit_project_contact(3,15, 16, 'replace');
-- select * from pmt_edit_project_contact(3,15, 16, 'delete');

-- select * from pmt_validate_project(15);
-- select * from pmt_validate_projects('12,1,4,6,15,89');
/******************************************************************
  pmt_validate_project
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_validate_project(id integer) RETURNS boolean AS $$
DECLARE valid_id integer;
BEGIN 
     IF $1 IS NULL THEN    
       RETURN false;
     END IF;    
     
     SELECT INTO valid_id project_id FROM project WHERE active = true AND project_id = $1;	 

     IF valid_id IS NULL THEN
      RETURN false;
     ELSE 
      RETURN true;
     END IF;
     
EXCEPTION WHEN others THEN
    RETURN FALSE;
END; 
$$ LANGUAGE 'plpgsql';
/******************************************************************
  pmt_validate_projects
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_validate_projects(project_ids character varying) RETURNS INT[] AS $$
DECLARE 
  valid_project_ids INT[];
  filter_project_ids INT[];
BEGIN 
     IF $1 IS NULL THEN    
       RETURN valid_project_ids;
     END IF;

     filter_project_ids := string_to_array($1, ',')::int[];
     
     SELECT INTO valid_project_ids array_agg(DISTINCT project_id)::INT[] FROM (SELECT project_id FROM project WHERE active = true AND project_id = ANY(filter_project_ids) ORDER BY project_id) AS t;
     
     RETURN valid_project_ids;

EXCEPTION
     WHEN others THEN RETURN NULL;
END; 
$$ LANGUAGE 'plpgsql';
/******************************************************************
   pmt_edit_project_contact
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_edit_project_contact(user_id integer, project_id integer, contact_id integer, edit_action pmt_edit_action) RETURNS BOOLEAN AS 
$$
DECLARE
  p_id integer;
  record_id integer;
  error_msg1 text;
  error_msg2 text;
  error_msg3 text;
BEGIN	
  -- first three parameters are required 
  IF ($1 IS NOT NULL) AND ($2 IS NOT NULL) AND ($3 IS NOT NULL) THEN
    -- validate project_id & contact_id
    IF (SELECT * FROM pmt_validate_project($2)) AND (SELECT * FROM pmt_validate_contact($3)) THEN
      p_id := $2;
      
      -- operations based on the requested edit action
      CASE $4
        WHEN 'delete' THEN
          -- validate users authority to perform an update action on this project
          IF (SELECT * FROM pmt_validate_user_authority($1, p_id, 'update')) THEN          
            EXECUTE 'DELETE FROM project_contact WHERE project_id ='|| $2 ||' AND contact_id = '|| $3; 
            RAISE NOTICE 'Delete Record: %', 'Remove association to contact_id ('|| $3 ||') for project_id ('|| $2 ||')';
          ELSE
            RAISE NOTICE 'Error: The requested edit action requires the user to have UPDATE rights to this project: %', p_id;
	    RETURN FALSE;
          END IF;           
        WHEN 'replace' THEN            
           -- validate users authority to perform an update and create action on this project
          IF (SELECT * FROM pmt_validate_user_authority($1, p_id, 'update')) AND (SELECT * FROM pmt_validate_user_authority($1, p_id, 'create')) THEN          
            EXECUTE 'DELETE FROM project_contact WHERE project_id ='|| $2;
            RAISE NOTICE 'Delete Record: %', 'Removed all contacts for project_id ('|| $2 ||')';
	    EXECUTE 'INSERT INTO project_contact(project_id, contact_id) VALUES ('|| $2 ||', '|| $3 ||')';
            RAISE NOTICE 'Add Record: %', 'project_id ('|| $2 ||') is now associated to contact_id ('|| $3 ||').'; 
          ELSE
            RAISE NOTICE 'Error: The requested edit action requires the user to have UPDATE and CREATE rights to this project: %', p_id;
	    RETURN FALSE;
          END IF;        
        ELSE
          -- validate users authority to perform a create action on this project
          IF (SELECT * FROM pmt_validate_user_authority($1, p_id, 'create')) THEN          
            SELECT INTO record_id pc.project_id FROM project_contact as pc WHERE pc.project_id = $2 AND pc.contact_id = $3 LIMIT 1;
            IF record_id IS NULL THEN
              EXECUTE 'INSERT INTO project_contact(project_id, contact_id) VALUES ('|| $2 ||', '|| $3 ||')';
              RAISE NOTICE 'Add Record: %', 'project_id ('|| $2 ||') is now associated to contact_id ('|| $3 ||').'; 
            ELSE
              RAISE NOTICE'Add Record: %', 'This project_id ('|| $2 ||') already has an association to this contact_id ('|| $3 ||').';                
            END IF;
          ELSE
            RAISE NOTICE 'Error: The requested edit action requires the user to have CREATE rights to this project: %', p_id;
	    RETURN FALSE;
          END IF;                  
      END CASE;
      -- edits are complete return successful
      RETURN TRUE;         
    ELSE
      RAISE NOTICE 'Error: Invalid project_id or contact_id.';
      RETURN FALSE;
    END IF;
  ELSE
    RAISE NOTICE 'Error: Must provide all parameters.';
    RETURN false;
  END IF; 
  
EXCEPTION WHEN others THEN
   GET STACKED DIAGNOSTICS error_msg1 = MESSAGE_TEXT,
		  error_msg2 = PG_EXCEPTION_DETAIL,
		  error_msg3 = PG_EXCEPTION_HINT;
    RAISE NOTICE 'Error: %', error_msg1;
    RETURN FALSE;  	  
END;$$ LANGUAGE plpgsql;

-- update permissions
GRANT USAGE ON SCHEMA public TO pmt_read;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO pmt_read;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO pmt_read;
GRANT USAGE ON SCHEMA public TO pmt_write;
GRANT SELECT,INSERT ON ALL TABLES IN SCHEMA public TO pmt_write;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO pmt_write;