/******************************************************************
Change Script 2.0.8.38
1. pmt_edit_project_taxonomy
******************************************************************/
INSERT INTO version(version, iteration, changeset) VALUES (2.0, 8, 38);
-- select * from version order by changeset desc;

-- select pt.*, tc.classification from project_taxonomy pt join taxonomy_classifications tc on pt.classification_id = tc.classification_id where project_id = 15
-- select taxonomy, classification_id, classification from taxonomy_classifications where taxonomy = 'Data Group'

-- select * from pmt_edit_project_taxonomy(3, 15, 5, 'add');
-- select * from pmt_edit_project_taxonomy(3, 15, 6, 'replace');
-- select * from pmt_edit_project_taxonomy(3, 15, 6, 'delete');
-- select * from pmt_edit_project_taxonomy(1, 15, 6, 'delete');
-- select * from pmt_edit_project_taxonomy(34, 732, 9999, 'delete');

DROP FUNCTION IF EXISTS pmt_edit_project_taxonomy(integer, integer, integer, pmt_edit_action)  CASCADE;

/******************************************************************
   pmt_edit_project_taxonomy
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_edit_project_taxonomy(user_id integer, project_id integer, classification_id integer, edit_action pmt_edit_action) RETURNS BOOLEAN AS 
$$
DECLARE
  valid_classification_id boolean;
  valid_project_id integer;
  record_id integer;
  t_id integer;
  i integer;
  rec record;
  error_msg1 text;
  error_msg2 text;
  error_msg3 text; 
BEGIN	

  -- first three parameters are required 
  IF ($1 IS NOT NULL) AND ($2 IS NOT NULL) AND ($3 IS NOT NULL) THEN
  
    IF (SELECT * FROM pmt_validate_project($2)) AND (SELECT * FROM pmt_validate_classification($3)) THEN
  
      -- get the taxonomy_id of the classification_id
      SELECT INTO t_id taxonomy_id FROM taxonomy_classifications tc WHERE tc.classification_id = $3;
      
      IF t_id IS NOT NULL THEN
        -- operations based on the requested edit action
        CASE $4          
          WHEN 'delete' THEN
            -- validate users authority to perform an update action on this project
            IF (SELECT * FROM pmt_validate_user_authority($1, $2, 'update')) THEN 
              EXECUTE 'DELETE FROM project_taxonomy WHERE project_id ='|| $2 ||' AND classification_id = '|| $3 ||' AND field = ''project_id'''; 
              RAISE NOTICE 'Delete Record: %', 'Remove association to classification_id ('|| $3 ||') for project_id ('|| $2 ||')';
            ELSE
              RAISE NOTICE 'Error: The requested edit action requires the user to have UPDATE rights to this project: %', $2;
	      RETURN FALSE;
            END IF;     
          WHEN 'replace' THEN
             -- validate users authority to perform an update and create action on this project
            IF (SELECT * FROM pmt_validate_user_authority($1, $2, 'update')) AND (SELECT * FROM pmt_validate_user_authority($1, $2, 'create')) THEN
            
              EXECUTE 'DELETE FROM project_taxonomy WHERE project_id ='|| $2 ||' AND classification_id in (SELECT classification_id FROM taxonomy_classifications WHERE taxonomy_id = '|| t_id||') AND field = ''project_id''';
              RAISE NOTICE 'Delete Record: %', 'Remove association to taxonomy_id ('|| t_id ||') for project_id ('|| $2 ||')';
	      EXECUTE 'INSERT INTO project_taxonomy(project_id, classification_id, field) VALUES ('|| $2 ||', '|| $3 ||', ''project_id'')'; 
              RAISE NOTICE 'Add Record: %', 'project_id ('|| $2 ||') is now associated to classification_id ('|| $3 ||').';
            ELSE
              RAISE NOTICE 'Error: The requested edit action requires the user to have UPDATE and CREATE rights to this project: %', $2;
	      RETURN FALSE;
            END IF;  
          ELSE
            -- validate users authority to perform a create action on this project
            IF (SELECT * FROM pmt_validate_user_authority($1, $2, 'create')) THEN 
              
              SELECT INTO record_id pt.project_id FROM project_taxonomy as pt WHERE pt.project_id = $2 AND pt.classification_id = $3 LIMIT 1;
              IF record_id IS NULL THEN
               EXECUTE 'INSERT INTO project_taxonomy(project_id, classification_id, field) VALUES ('|| $2 ||', '|| $3 ||', ''project_id'')';
               RAISE NOTICE 'Add Record: %', 'project_id ('|| $2 ||') is now associated to classification_id ('|| $3 ||').'; 
             ELSE
               RAISE NOTICE'Add Record: %', 'This project_id ('|| $2 ||') already has an association to this classification_id ('|| $3 ||').';                
             END IF;
             
            ELSE
              RAISE NOTICE 'Error: The requested edit action requires the user to have CREATE rights to this project: %', $2;
	      RETURN FALSE;
            END IF;        
        END CASE;
        RETURN true;
      ELSE
        RAISE NOTICE 'Error: There is no taxonomy_id for given classification_id.';
	RETURN false;
      END IF;
      
    ELSE
      RAISE NOTICE 'Error: Invalid project_id or classification_id.';
      RETURN false;
    END IF;
  ELSE
    RAISE NOTICE 'Error: Must provide user_id, project_id and classification_id parameters.';
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