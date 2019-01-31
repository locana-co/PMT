/******************************************************************
Change Script 2.0.9.5
1. pmt_edit_participation - bug fix. delete request always failing,
because project_id not collected for authentication.
******************************************************************/
INSERT INTO version(version, iteration, changeset) VALUES (2.0, 9, 5);
-- select * from version order by iteration desc, changeset desc;

/******************************************************************
   TESTING
   select * from classification where taxonomy_id in (select taxonomy_id from taxonomy where name =  'Organisation Role')
   select * from organization
   select * from participation pp join participation_taxonomy ppt on pp.participation_id = ppt.participation_id where pp.project_id = 15 and pp.activity_id = 113 
   select enum_range(null::pmt_edit_action)
   project_id: 15
   activity_id: 113

   -- add
   select * from pmt_edit_participation(6, null, 15, 113, 2,'494', 'add');
   -- replace
   select * from pmt_edit_participation(6, null, 15, 113, 2,'494', 'replace');
   -- delete
   select * from pmt_edit_participation(6, 621, null, null, null, null, 'delete');
   
******************************************************************/

/******************************************************************
   pmt_edit_participation
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_edit_participation(user_id integer, participation_id integer, project_id integer, activity_id integer, 
organization_id integer, classification_ids character varying, edit_action pmt_edit_action) RETURNS SETOF pmt_json_result_type AS 
$$
DECLARE
  p_id integer;
  o_id integer;  
  a_id integer;  
  c_ids integer array;  
  c_id integer;
  id integer;
  record_id integer;
  participation_records integer[];
  user_name text;
  rec record;
  error_msg1 text;
  error_msg2 text;
  error_msg3 text;
BEGIN	

  -- user parameter is required
  IF ($1 IS NULL) THEN
    FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: Must have user_id parameter.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
  END IF;
  -- get users name
  SELECT INTO user_name username FROM "user" WHERE "user".user_id = $1;
  -- validate participation_id if provided
  IF ($2 IS NOT NULL) THEN
    SELECT INTO record_id p.participation_id FROM participation p WHERE p.participation_id = $2 AND active = true;
    SELECT INTO p_id p.project_id FROM participation p WHERE p.participation_id = $2 AND active = true;
    IF record_id IS NULL THEN
      FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: Provided participation_id is invalid or inactive.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;     
    END IF;    
  END IF;  
  -- validate project_id if provided
  IF ($3 IS NOT NULL) THEN
    SELECT INTO p_id p.project_id FROM project p WHERE p.project_id = $3 AND active = true;
    IF p_id IS NULL THEN
      FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: Provided project_id is invalid or inactive.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;          
    END IF;    
  END IF;
  -- validate activity_id if provided
  IF ($4 IS NOT NULL) THEN
    SELECT INTO a_id a.activity_id FROM activity a WHERE a.activity_id = $4 AND active = true;
    IF a_id IS NULL THEN
      FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: Provided activity_id is invalid or inactive.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;     
    ELSE
      SELECT INTO p_id a.project_id FROM activity a WHERE a.activity_id = a_id;
    END IF; 
       
  END IF;
  -- validate organization_id if provided
  IF ($5 IS NOT NULL) THEN
    SELECT INTO o_id o.organization_id FROM organization o WHERE o.organization_id = $5 AND active = true;
    IF o_id IS NULL THEN
      FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: Provided organization_id is invalid or inactive.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;     
    END IF;    
  END IF;
  -- validate classification_id if provided
  IF ($6 IS NOT NULL) THEN
    SELECT INTO c_ids * FROM pmt_validate_classifications($6);        
    SELECT INTO c_ids array_agg(tc.classification_id) from taxonomy_classifications tc where tc.taxonomy = 'Organisation Role' AND tc.classification_id = ANY(c_ids);
    IF c_ids IS NULL THEN
      FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: Provided classification_ids are not in the Organisation Role taxonomy or are inactive.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
    END IF;    
  END IF;
  
  -- operations based on the requested edit action
  CASE $7
    WHEN 'delete' THEN
      -- check for required parameters
      IF (record_id IS NULL) THEN 
        FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: Must have participation_id parameter when edit action is: ' || $7 as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;     
      END IF;  
      -- validate users authority to perform an update action on this project
      IF (SELECT * FROM pmt_validate_user_authority($1, p_id, 'update')) THEN
        EXECUTE 'UPDATE participation SET active = false, updated_by = ' || quote_literal(user_name) || ', updated_date = ' || quote_literal(current_date) || ' WHERE participation_id ='|| record_id; 
        RAISE NOTICE 'Delete Record: %', 'Deactivated participation record: ('|| record_id ||')';
      ELSE
        FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: The requested edit action requires the user to have UPDATE rights to this project: ' || p_id as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;     
      END IF;   
    WHEN 'replace' THEN            
      -- check for required parameters
      IF (p_id IS NULL) OR (o_id IS NULL) OR (c_ids IS NULL) THEN
        FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: Must have project_id, organization_id and classification_id parameters when edit action is: ' || $7 as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;     
      END IF;
      -- validate users authority to perform an update and create action on this project
      IF (SELECT * FROM pmt_validate_user_authority($1, p_id, 'update')) AND (SELECT * FROM pmt_validate_user_authority($1, p_id, 'create')) THEN        
        IF a_id IS NOT NULL THEN
          -- activity participation
          SELECT INTO participation_records array_agg(p.participation_id)::int[] FROM participation p WHERE p.project_id = p_id AND p.activity_id = a_id;
          RAISE NOTICE 'Participation records to be deleted and replaced: %', participation_records;
	  EXECUTE 'UPDATE participation SET active = false, updated_by = ' || quote_literal(user_name) || ', updated_date = ' || quote_literal(current_date) || ' WHERE participation_id = ANY(ARRAY['|| array_to_string(participation_records, ',')  || '])'; 
          EXECUTE 'INSERT INTO participation(project_id, activity_id, organization_id, created_by, updated_by) VALUES (' || p_id || ',' || a_id || ',' || o_id || 
		',' || quote_literal(user_name) || ',' || quote_literal(user_name) || ') RETURNING participation_id;' INTO record_id;
	  FOREACH c_id IN ARRAY c_ids LOOP
	    EXECUTE 'INSERT INTO participation_taxonomy(participation_id, classification_id, field) VALUES (' || record_id || ',' || c_id || ', ''participation_id'');';
	  END LOOP;          
          RAISE NOTICE 'Add Record: %', 'participation_id ('|| record_id ||') has organiztaion_id  ('|| o_id ||'), project_id ('|| p_id ||'), activity_id ('|| a_id ||
		') is now associated to classification_id ('|| c_id ||').'; 
        ELSE
          -- project participation
          SELECT INTO participation_records array_agg(p.participation_id)::int[]  FROM participation p WHERE p.project_id = p_id AND p.activity_id IS NULL;
          RAISE NOTICE 'Participation records to be deleted and replaced: %', participation_records;
          EXECUTE 'UPDATE participation SET active = false, updated_by = ' || quote_literal(user_name) || ', updated_date = ' || quote_literal(current_date) || ' WHERE participation_id = ANY(ARRAY['|| array_to_string(participation_records, ',')  || '])'; 
          EXECUTE 'INSERT INTO participation(project_id, organization_id, created_by, updated_by) VALUES (' || p_id || ',' || o_id || 
		',' || quote_literal(user_name) || ',' || quote_literal(user_name) || ') RETURNING participation_id;' INTO record_id;
          FOREACH c_id IN ARRAY c_ids LOOP
	    EXECUTE 'INSERT INTO participation_taxonomy(participation_id, classification_id, field) VALUES (' || record_id || ',' || c_id || ', ''participation_id'');';
	  END LOOP;
          RAISE NOTICE 'Add Record: %', 'participation_id ('|| record_id ||') has organiztaion_id  ('|| o_id ||'), project_id ('|| p_id ||') is now associated to classification_id ('|| c_id ||').'; 
          
        END IF;
      ELSE
        FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: The requested edit action requires the user to have UPDATE and CREATE rights to this project: ' || p_id as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;     
      END IF;
    -- add (action)
    ELSE
      -- check for required parameters
      IF (p_id IS NULL) OR (o_id IS NULL) OR (c_ids IS NULL) THEN
        FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: Must have project_id, organization_id and classification_id parameters when edit action is: ' || $7 as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;     
      END IF;
      -- validate users authority to perform a create action on this project
      IF (SELECT * FROM pmt_validate_user_authority($1, p_id, 'create')) THEN
        IF a_id IS NOT NULL THEN
          -- activity participation          
          SELECT INTO record_id pp.participation_id FROM participation pp WHERE pp.project_id = p_id AND pp.activity_id = a_id AND pp.organization_id = o_id;
          IF record_id IS NULL THEN
            EXECUTE 'INSERT INTO participation(project_id, activity_id, organization_id, created_by, updated_by) VALUES (' || p_id || ',' || a_id || ',' || o_id || 
		',' || quote_literal(user_name) || ',' || quote_literal(user_name) || ') RETURNING participation_id;' INTO record_id;
	  END IF;
          FOREACH c_id IN ARRAY c_ids LOOP
            SELECT INTO id pt.classification_id FROM participation_taxonomy pt WHERE pt.field = 'participation_id' AND pt.participation_id = record_id AND pt.classification_id = c_id;
            IF id IS NULL THEN
	      EXECUTE 'INSERT INTO participation_taxonomy(participation_id, classification_id, field) VALUES (' || record_id || ',' || c_id || ', ''participation_id'');';
	      RAISE NOTICE 'Add Record: %', 'participation_id ('|| record_id ||') has organiztaion_id  ('|| o_id ||'), project_id ('|| p_id ||'), activity_id ('|| a_id ||
		') is now associated to classification_id ('|| c_id ||').'; 
	    END IF;
	  END LOOP;          
        ELSE
          -- project participation          
          SELECT INTO record_id pp.participation_id FROM participation pp WHERE pp.project_id = p_id AND pp.activity_id IS NULL AND pp.organization_id = o_id;
          IF record_id IS NULL THEN
            EXECUTE 'INSERT INTO participation(project_id, organization_id, created_by, updated_by) VALUES (' || p_id || ',' || o_id || 
		',' || quote_literal(user_name) || ',' || quote_literal(user_name) || ') RETURNING participation_id;' INTO record_id;
	  END IF;
          FOREACH c_id IN ARRAY c_ids LOOP
            SELECT INTO id pt.classification_id FROM participation_taxonomy pt WHERE pt.field = 'participation_id' AND pt.participation_id = record_id AND pt.classification_id = c_id;
            IF id IS NULL THEN
	      EXECUTE 'INSERT INTO participation_taxonomy(participation_id, classification_id, field) VALUES (' || record_id || ',' || c_id || ', ''participation_id'');';
	      RAISE NOTICE 'Add Record: %', 'participation_id ('|| record_id ||') has organiztaion_id  ('|| o_id ||'), project_id ('|| p_id ||') is now associated to classification_id ('|| c_id ||').'; 
	    END IF;
	  END LOOP;   
        END IF;
      ELSE
        FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: The requested edit action requires the user to have CREATE rights to this project: ' || p_id as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;     
      END IF;        
  END CASE;

  -- editing completed successfullly
  FOR rec IN (SELECT row_to_json(j) FROM(select record_id as id, 'Success' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;         
  
EXCEPTION WHEN others THEN
     GET STACKED DIAGNOSTICS error_msg1 = MESSAGE_TEXT,
                          error_msg2 = PG_EXCEPTION_DETAIL,
                          error_msg3 = PG_EXCEPTION_HINT;
    FOR rec IN (SELECT row_to_json(j) FROM(select record_id as id, 'Internal Error - Contact your DBA with the following error message: ' || error_msg1 as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
      
END;$$ LANGUAGE plpgsql;

-- update permissions
GRANT USAGE ON SCHEMA public TO pmt_read;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO pmt_read;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO pmt_read;
GRANT USAGE ON SCHEMA public TO pmt_write;
GRANT SELECT,INSERT ON ALL TABLES IN SCHEMA public TO pmt_write;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO pmt_write;