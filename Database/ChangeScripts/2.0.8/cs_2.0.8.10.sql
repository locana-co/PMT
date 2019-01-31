/******************************************************************
Change Script 2.0.8.10 - consolidated.
1. pmt_validate_contact - new function to validate a contact_id
2. pmt_validate_contacts - new function to validate contact_ids
3. pmt_edit_activity_contact - new function for editing an activity's
contacts.
******************************************************************/
INSERT INTO version(version, iteration, changeset) VALUES (2.0, 8, 10);
-- select * from version order by changeset desc;

DROP FUNCTION IF EXISTS pmt_validate_contact(integer)  CASCADE;
DROP FUNCTION IF EXISTS pmt_validate_contacts(character varying)  CASCADE;
DROP FUNCTION IF EXISTS pmt_edit_activity_contact(integer, integer, integer, edit_action)  CASCADE;

-- SELECT * FROM pmt_validate_user_authority(34, 733) -- bmgf
-- SELECT * FROM pmt_validate_user_authority(1, 3) -- oam
-- select * from activity_contact where activity_id in (SELECT activity_id FROM activity where project_id = 733)
-- select * from activity_contact where activity_id in (SELECT activity_id FROM activity where project_id = 3)
-- select * from contact

-- select * from pmt_edit_activity_contact(34,14863, 169, 'add');
-- select * from pmt_edit_activity_contact(1,14863, 145, 'add');
-- select * from pmt_edit_activity_contact(1,14863, 160, 'replace');
-- select * from pmt_edit_activity_contact(34,14863, 160, 'delete');
/******************************************************************
  pmt_validate_contact
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_validate_contact(id integer) RETURNS boolean AS $$
DECLARE valid_id integer;
BEGIN 
     IF $1 IS NULL THEN    
       RETURN false;
     END IF;    
     
     SELECT INTO valid_id contact_id FROM contact WHERE active = true AND contact_id = $1;	 

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
  pmt_validate_contacts
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_validate_contacts(contact_ids character varying) RETURNS INT[] AS $$
DECLARE 
  valid_contact_ids INT[];
  filter_contact_ids INT[];
BEGIN 
     IF $1 IS NULL THEN    
       RETURN valid_contact_ids;
     END IF;

     filter_contact_ids := string_to_array($1, ',')::int[];
     
     SELECT INTO valid_contact_ids array_agg(DISTINCT contact_id)::INT[] FROM (SELECT contact_id FROM contact WHERE active = true AND contact_id = ANY(filter_contact_ids) ORDER BY contact_id) AS t;
     
     RETURN valid_contact_ids;

EXCEPTION
     WHEN others THEN RETURN NULL;
END; 
$$ LANGUAGE 'plpgsql';
/******************************************************************
   pmt_edit_activity_contact
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_edit_activity_contact(user_id integer, activity_id integer, contact_id integer, edit_action edit_action) RETURNS BOOLEAN AS 
$$
DECLARE
  p_id integer;
  record_id integer;
BEGIN	
  -- first three parameters are required 
  IF ($1 IS NOT NULL) AND ($2 IS NOT NULL) AND ($3 IS NOT NULL) THEN
    -- validate activity_id & contact_id
    IF (SELECT * FROM pmt_validate_activity($2)) AND (SELECT * FROM pmt_validate_contact($3)) THEN
      -- get project_id for activity
      SELECT INTO p_id project_id FROM activity WHERE activity.activity_id = $2;
      
      -- operations based on the requested edit action
      CASE $4
        WHEN 'delete' THEN
          -- validate users authority to perform an update action on this project
          IF (SELECT * FROM pmt_validate_user_authority($1, p_id, 'update')) THEN          
            EXECUTE 'DELETE FROM activity_contact WHERE activity_id ='|| $2 ||' AND contact_id = '|| $3; 
            RAISE NOTICE 'Delete Record: %', 'Remove association to contact_id ('|| $3 ||') for actvity_id ('|| $2 ||')';
          ELSE
            RAISE NOTICE 'Error: The requested edit action requires the user to have UPDATE rights to this project: %', p_id;
	    RETURN FALSE;
          END IF;           
        WHEN 'replace' THEN            
           -- validate users authority to perform an update and create action on this project
          IF (SELECT * FROM pmt_validate_user_authority($1, p_id, 'update')) AND (SELECT * FROM pmt_validate_user_authority($1, p_id, 'create')) THEN          
            EXECUTE 'DELETE FROM activity_contact WHERE activity_id ='|| $2;
            RAISE NOTICE 'Delete Record: %', 'Removed all contacts for actvity_id ('|| $2 ||')';
	    EXECUTE 'INSERT INTO activity_contact(activity_id, contact_id) VALUES ('|| $2 ||', '|| $3 ||')';
            RAISE NOTICE 'Add Record: %', 'Activity_id ('|| $2 ||') is now associated to contact_id ('|| $3 ||').'; 
          ELSE
            RAISE NOTICE 'Error: The requested edit action requires the user to have UPDATE and CREATE rights to this project: %', p_id;
	    RETURN FALSE;
          END IF;        
        ELSE
          -- validate users authority to perform a create action on this project
          IF (SELECT * FROM pmt_validate_user_authority($1, p_id, 'create')) THEN          
            SELECT INTO record_id ac.activity_id FROM activity_contact as ac WHERE ac.activity_id = $2 AND ac.contact_id = $3 LIMIT 1;
            IF record_id IS NULL THEN
              EXECUTE 'INSERT INTO activity_contact(activity_id, contact_id) VALUES ('|| $2 ||', '|| $3 ||')';
              RAISE NOTICE 'Add Record: %', 'Activity_id ('|| $2 ||') is now associated to contact_id ('|| $3 ||').'; 
            ELSE
              RAISE NOTICE'Add Record: %', 'This activity_id ('|| $2 ||') already has an association to this contact_id ('|| $3 ||').';                
            END IF;
          ELSE
            RAISE NOTICE 'Error: The requested edit action requires the user to have CREATE rights to this project: %', p_id;
	    RETURN FALSE;
          END IF;                  
      END CASE;
      -- edits are complete return successful
      RETURN TRUE;         
    ELSE
      RAISE NOTICE 'Error: Invalid activity_id or contact_id.';
      RETURN FALSE;
    END IF;
  ELSE
    RAISE NOTICE 'Error: Must provide all parameters.';
    RETURN false;
  END IF; 
  
EXCEPTION WHEN others THEN
    RETURN FALSE;  	  
END;$$ LANGUAGE plpgsql;

-- update permissions
GRANT USAGE ON SCHEMA public TO pmt_read;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO pmt_read;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO pmt_read;
GRANT USAGE ON SCHEMA public TO pmt_write;
GRANT SELECT,INSERT ON ALL TABLES IN SCHEMA public TO pmt_write;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO pmt_write;