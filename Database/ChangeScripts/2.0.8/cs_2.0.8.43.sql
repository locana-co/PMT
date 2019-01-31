/******************************************************************
Change Script 2.0.8.43 - consolidated.
1. pmt_edit_participation - bug fix, incorrect parameter in classification_id
check.
******************************************************************/
INSERT INTO version(version, iteration, changeset) VALUES (2.0, 8, 43);
-- select * from version order by changeset desc;

-- select * from pmt_edit_participation(3, null, 15, 66, 3, 494, 'add');
-- select * from taxonomy_classifications where classification_id = 494

/******************************************************************
   pmt_edit_participation
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_edit_participation(user_id integer, participation_id integer, project_id integer, activity_id integer, 
organization_id integer, classification_id integer, edit_action pmt_edit_action) RETURNS BOOLEAN AS 
$$
DECLARE
  p_id integer;
  o_id integer;  
  a_id integer;  
  c_id integer;  
  record_id integer;
  participation_records integer[];
  user_name text;
BEGIN	

  -- user parameter is required
  IF ($1 IS NULL) THEN
    RAISE NOTICE 'Error: Must have user_id parameter.';
    RETURN FALSE;  
  END IF;
  -- get users name
  SELECT INTO user_name username FROM "user" WHERE "user".user_id = $1;
  -- validate participation_id if provided
  IF ($2 IS NOT NULL) THEN
    SELECT INTO record_id p.participation_id FROM participation p WHERE p.participation_id = $2 AND active = true;
    IF record_id IS NULL THEN
      RAISE NOTICE 'Error: Provided participation_id is invalid or inactive.';
      RETURN FALSE;
    END IF;    
  END IF;  
  -- validate project_id if provided
  IF ($3 IS NOT NULL) THEN
    SELECT INTO p_id p.project_id FROM project p WHERE p.project_id = $3 AND active = true;
    IF p_id IS NULL THEN
      RAISE NOTICE 'Error: Provided project_id is invalid or inactive.';
      RETURN FALSE;
    END IF;    
  END IF;
  -- validate activity_id if provided
  IF ($4 IS NOT NULL) THEN
    SELECT INTO a_id a.activity_id FROM activity a WHERE a.activity_id = $4 AND active = true;
    IF a_id IS NULL THEN
      RAISE NOTICE 'Error: Provided activity_id is invalid or inactive.';
      RETURN FALSE;
    END IF;    
  END IF;
  -- validate organization_id if provided
  IF ($5 IS NOT NULL) THEN
    SELECT INTO o_id o.organization_id FROM organization o WHERE o.organization_id = $5 AND active = true;
    IF o_id IS NULL THEN
      RAISE NOTICE 'Error: Provided organization_id is invalid or inactive.';
      RETURN FALSE;
    END IF;    
  END IF;
  -- validate classification_id if provided
  IF ($6 IS NOT NULL) THEN
    SELECT INTO c_id tc.classification_id from taxonomy_classifications tc where tc.taxonomy = 'Organisation Role' AND tc.classification_id = $6;
    IF c_id IS NULL THEN
      RAISE NOTICE 'Error: Provided classification_id is not in the Organisation Role taxonomy or is inactive.';
      RETURN FALSE;
    END IF;    
  END IF;
  
  -- operations based on the requested edit action
  CASE $7
    WHEN 'delete' THEN
      -- check for required parameters
      IF (record_id IS NULL) THEN 
        RAISE NOTICE 'Error: Must have participation_id parameter when edit action is: %', $7;
	RETURN FALSE;  
      END IF;  
      -- validate users authority to perform an update action on this project
      IF (SELECT * FROM pmt_validate_user_authority($1, p_id, 'update')) THEN
        EXECUTE 'DELETE FROM participation WHERE participation_id ='|| record_id; 
        EXECUTE 'DELETE FROM participation_taxonomy WHERE participation_id ='|| record_id; 
        RAISE NOTICE 'Delete Record: %', 'Removed participation and taxonomy associated to this participation_id ('|| record_id ||')';
      ELSE
        RAISE NOTICE 'Error: The requested edit action requires the user to have UPDATE rights to this project: %', p_id;
        RETURN FALSE;
      END IF;   
    WHEN 'replace' THEN            
      -- check for required parameters
      IF (p_id IS NULL) OR (o_id IS NULL) OR (c_id IS NULL) THEN
        RAISE NOTICE 'Error: Must have project_id, organization_id and classification_id parameters when edit action is: %', $7;
	RETURN FALSE;  
      END IF;
      -- validate users authority to perform an update and create action on this project
      IF (SELECT * FROM pmt_validate_user_authority($1, p_id, 'update')) AND (SELECT * FROM pmt_validate_user_authority($1, p_id, 'create')) THEN        
        IF a_id IS NOT NULL THEN
          -- activity participation
          SELECT INTO participation_records array_agg(p.participation_id)::int[] FROM participation p WHERE p.project_id = p_id AND p.activity_id = a_id;
          RAISE NOTICE 'Participation records to be deleted and replaced: %', participation_records;
          EXECUTE 'DELETE FROM participation WHERE participation_id = ANY(ARRAY['|| array_to_string(participation_records, ',')  || '])'; 
          EXECUTE 'DELETE FROM participation_taxonomy WHERE participation_id= ANY(ARRAY['|| array_to_string(participation_records, ',')  || '])'; 
          EXECUTE 'INSERT INTO participation(project_id, activity_id, organization_id, created_by, updated_by) VALUES (' || p_id || ',' || a_id || ',' || o_id || 
		',' || quote_literal(user_name) || ',' || quote_literal(user_name) || ') RETURNING participation_id;' INTO record_id;
          EXECUTE 'INSERT INTO participation_taxonomy(participation_id, classification_id, field) VALUES (' || record_id || ',' || c_id || ', ''participation_id'');';
          RAISE NOTICE 'Add Record: %', 'participation_id ('|| record_id ||') has organiztaion_id  ('|| o_id ||'), project_id ('|| p_id ||'), activity_id ('|| a_id ||
		') is now associated to classification_id ('|| c_id ||').'; 
        ELSE
          -- project participation
          SELECT INTO participation_records array_agg(p.participation_id)::int[]  FROM participation p WHERE p.project_id = p_id AND p.activity_id IS NULL;
          RAISE NOTICE 'Participation records to be deleted and replaced: %', participation_records;
          EXECUTE 'DELETE FROM participation WHERE participation_id = ANY(ARRAY['|| array_to_string(participation_records, ',') || '])'; 
          EXECUTE 'DELETE FROM participation_taxonomy WHERE participation_id = ANY(ARRAY['|| array_to_string(participation_records, ',') || '])'; 
          EXECUTE 'INSERT INTO participation(project_id, organization_id, created_by, updated_by) VALUES (' || p_id || ',' || o_id || 
		',' || quote_literal(user_name) || ',' || quote_literal(user_name) || ') RETURNING participation_id;' INTO record_id;
          EXECUTE 'INSERT INTO participation_taxonomy(participation_id, classification_id, field) VALUES (' || record_id || ',' || c_id || ', ''participation_id'');';
          RAISE NOTICE 'Add Record: %', 'participation_id ('|| record_id ||') has organiztaion_id  ('|| o_id ||'), project_id ('|| p_id ||') is now associated to classification_id ('|| c_id ||').'; 
        END IF;
      ELSE
        RAISE NOTICE 'Error: The requested edit action requires the user to have UPDATE and CREATE rights to this project: %', p_id;
        RETURN FALSE;
      END IF;
    ELSE
      -- check for required parameters
      IF (p_id IS NULL) OR (o_id IS NULL) OR (c_id IS NULL) THEN
        RAISE NOTICE 'Error: Must have project_id, organization_id and classification_id parameters when edit action is: %', $7;
	RETURN FALSE;  
      END IF;
      -- validate users authority to perform a create action on this project
      IF (SELECT * FROM pmt_validate_user_authority($1, p_id, 'create')) THEN
        IF a_id IS NOT NULL THEN
          -- activity participation          
          EXECUTE 'INSERT INTO participation(project_id, activity_id, organization_id, created_by, updated_by) VALUES (' || p_id || ',' || a_id || ',' || o_id || 
		',' || quote_literal(user_name) || ',' || quote_literal(user_name) || ') RETURNING participation_id;' INTO record_id;
          EXECUTE 'INSERT INTO participation_taxonomy(participation_id, classification_id, field) VALUES (' || record_id || ',' || c_id || ', ''participation_id'');';
          RAISE NOTICE 'Add Record: %', 'participation_id ('|| record_id ||') has organiztaion_id  ('|| o_id ||'), project_id ('|| p_id ||'), activity_id ('|| a_id ||
		') is now associated to classification_id ('|| c_id ||').'; 
        ELSE
          -- project participation          
          EXECUTE 'INSERT INTO participation(project_id, organization_id, created_by, updated_by) VALUES (' || p_id || ',' || o_id || 
		',' || quote_literal(user_name) || ',' || quote_literal(user_name) || ') RETURNING participation_id;' INTO record_id;
          EXECUTE 'INSERT INTO participation_taxonomy(participation_id, classification_id, field) VALUES (' || record_id || ',' || c_id || ', ''participation_id'');';
          RAISE NOTICE 'Add Record: %', 'participation_id ('|| record_id ||') has organiztaion_id  ('|| o_id ||'), project_id ('|| p_id ||') is now associated to classification_id ('|| c_id ||').'; 
        END IF;
      ELSE
        RAISE NOTICE 'Error: The requested edit action requires the user to have CREATE rights to this project: %', p_id;
        RETURN FALSE;
      END IF;        
  END CASE;

  -- edits are complete return successful
  RETURN TRUE;         
            
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