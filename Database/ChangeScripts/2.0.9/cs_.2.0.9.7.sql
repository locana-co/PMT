/******************************************************************
Change Script 2.0.9.7
1. pmt_edit_participation - update to reactivate inactive records,
when replace/add requests existing record. 
******************************************************************/
-- INSERT INTO version(version, iteration, changeset) VALUES (2.0, 9, 7);
-- select * from version order by iteration desc, changeset desc;

/******************************************************************
   TESTING
   
   UPDATE "user" SET role_id = (select role_id from role where name = 'Super') WHERE username = 'sparadee';   
   
   select * from participation pp join participation_taxonomy ppt on pp.participation_id = ppt.participation_id where project_id = 757 AND activity_id IS NULL order by 2,3,4
   select organization_id, name, active from organization order by 2
   project_id: 757
   activity_id: 13718  

   -- ACTIVITY PARTICIPATION TESTS
   -- add (new participation record)
   select * from pmt_edit_participation(34, null, 757, 13718, 2121,'494', 'add');
   -- add (existing active participation record w existing tax)
   select * from pmt_edit_participation(34, null, 757, 13718, 2121,'494', 'add');
   -- add (existing active participation record w new tax)
   select * from pmt_edit_participation(34, null, 757, 13718, 2121,'496', 'add');
   -- delete
   select * from pmt_edit_participation(34, 67452, null, null, null, null, 'delete');
   -- add (existing inactive participation record w tax)
   select * from pmt_edit_participation(34, null, 757, 13718, 2121,'494', 'add');
   -- replace (new participation record)
   select * from pmt_edit_participation(34, null, 757, 13718, 265,'494', 'replace');
   -- replace (existing inactive participation record w existing tax)
   select * from pmt_edit_participation(34, null, 757, 13718, 5,'497', 'replace');
   -- replace (existing inactive participation record w new tax)
   select * from pmt_edit_participation(34, null, 757, 13718, 5,'494', 'replace');
   -- PROJECT PARTICIPATION TESTS
   -- add (new participation record)
   select * from pmt_edit_participation(34, null, 757, null, 2121,'494', 'add');
   -- add (existing active participation record w existing tax)
   select * from pmt_edit_participation(34, null, 757, null, 2121,'494', 'add');
   -- add (existing active participation record w new tax)
   select * from pmt_edit_participation(34, null, 757, null, 2121,'496', 'add');
   -- delete
   select * from pmt_edit_participation(34, 67454, null, null, null, null, 'delete');
   -- add (existing inactive participation record w tax)
   select * from pmt_edit_participation(34, null, 757, null, 2121,'494', 'add');
   -- replace (new participation record)
   select * from pmt_edit_participation(34, null, 757, null, 265,'494', 'replace');
   -- replace (existing inactive participation record w existing tax)
   select * from pmt_edit_participation(34, null, 757, null, 13,'496', 'replace');
   -- replace (existing inactive participation record w new tax)
   select * from pmt_edit_participation(34, null, 757, null, 100,'496', 'replace');
   
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
  record_is_active boolean;
  tax_ct integer;
  participation_records integer[];
  user_name text;
  rec record;
  error_message text;
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
  -- validate participation_id if provided (required for replace and delete operations)
  IF ($2 IS NOT NULL) THEN
    SELECT INTO record_id p.participation_id FROM participation p WHERE p.participation_id = $2 AND active = true;
    SELECT INTO p_id p.project_id FROM participation p WHERE p.participation_id = $2 AND active = true;
    IF record_id IS NULL THEN
      FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: Provided participation_id is invalid or inactive.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;     
    END IF;
    IF p_id IS NULL THEN
      FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: Could not retreive valid project_id for provided participation_id.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;     
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
      -- ensure the project_id is correct for given activity_id (overrides project_id parameter)
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
        -- activity participation
        IF a_id IS NOT NULL THEN
          -- collect all participation records for activity
          SELECT INTO participation_records array_agg(p.participation_id)::int[] FROM participation p WHERE p.project_id = p_id AND p.activity_id = a_id;
	  -- deactivate all participation records for activity
	  EXECUTE 'UPDATE participation SET active = false, updated_by = ' || quote_literal(user_name) || ', updated_date = ' || quote_literal(current_date) || ' WHERE participation_id = ANY(ARRAY['|| array_to_string(participation_records, ',')  || '])'; 
	  -- determine if requested particpation record currently exists
	  SELECT INTO record_id p.participation_id FROM participation p WHERE p.project_id = p_id AND p.activity_id = a_id AND p.organization_id = o_id;

	  -- the requested participation record exists
	  IF (record_id IS NOT NULL) THEN
	    -- reactivate the record
	    EXECUTE 'UPDATE participation SET active = true, updated_by = ' || quote_literal(user_name) || ', updated_date = ' || quote_literal(current_date) || ' WHERE participation_id = '|| record_id; 
	    -- remove any taxonomies associated with the participation record
	    EXECUTE 'DELETE FROM participation_taxonomy WHERE participation_id = ' || record_id;	    
	  -- the requested participation record does NOT exist
	  ELSE
	    -- create the participation record
	    EXECUTE 'INSERT INTO participation(project_id, activity_id, organization_id, created_by, updated_by) VALUES (' || p_id || ',' || a_id || ',' || o_id || ',' || quote_literal(user_name) || ',' || quote_literal(user_name) || ') RETURNING participation_id;' INTO record_id;
	  END IF;

	  -- add requested taxonomies to participation record
	  FOREACH c_id IN ARRAY c_ids LOOP
            EXECUTE 'INSERT INTO participation_taxonomy(participation_id, classification_id, field) VALUES (' || record_id || ',' || c_id || ', ''participation_id'');';
          END LOOP;
            
        -- project particpation
        ELSE
          -- collect all participation records for project
          SELECT INTO participation_records array_agg(p.participation_id)::int[]  FROM participation p WHERE p.project_id = p_id AND p.activity_id IS NULL;
          -- deactivate all participation records for project
	  EXECUTE 'UPDATE participation SET active = false, updated_by = ' || quote_literal(user_name) || ', updated_date = ' || quote_literal(current_date) || ' WHERE participation_id = ANY(ARRAY['|| array_to_string(participation_records, ',')  || '])'; 
	  -- determine if requested particpation record currently exists
	  SELECT INTO record_id p.participation_id FROM participation p WHERE p.project_id = p_id AND p.activity_id IS NULL AND p.organization_id = o_id;

	  -- the requested participation record exists
	  IF (record_id IS NOT NULL) THEN
	    -- reactivate the record
	    EXECUTE 'UPDATE participation SET active = true, updated_by = ' || quote_literal(user_name) || ', updated_date = ' || quote_literal(current_date) || ' WHERE participation_id = '|| record_id; 
	    -- remove any taxonomies associated with the participation record
	    EXECUTE 'DELETE FROM participation_taxonomy WHERE participation_id = ' || record_id;	    
	  -- the requested participation record does NOT exist
	  ELSE
	    -- create the participation record
	    EXECUTE 'INSERT INTO participation(project_id, organization_id, created_by, updated_by) VALUES (' || p_id || ',' || o_id || ',' || quote_literal(user_name) || ',' || quote_literal(user_name) || ') RETURNING participation_id;' INTO record_id;
	  END IF;

	  -- add requested taxonomies to participation record
	  FOREACH c_id IN ARRAY c_ids LOOP
            EXECUTE 'INSERT INTO participation_taxonomy(participation_id, classification_id, field) VALUES (' || record_id || ',' || c_id || ', ''participation_id'');';
          END LOOP;
          
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
        -- activity participation 
        IF a_id IS NOT NULL THEN
          -- determine if requested particpation record currently exists                   
          SELECT INTO record_id pp.participation_id FROM participation pp WHERE pp.project_id = p_id AND pp.activity_id = a_id AND pp.organization_id = o_id;          
          -- the requested participation record exists
          IF (record_id IS NOT NULL) THEN
            -- determine if requested participation record is active
            SELECT INTO record_is_active pp.active FROM participation pp WHERE pp.participation_id = record_id;
            -- requested participation is active
            IF record_is_active THEN
               -- add requested taxonomies to participation record if they do not exist
	      FOREACH c_id IN ARRAY c_ids LOOP
	        -- determine if the classification is already assoicated to the participation record
	        SELECT INTO tax_ct COUNT(*) FROM participation_taxonomy pt WHERE pt.participation_id = record_id AND pt.classification_id = c_id AND field = 'participation_id';
	        IF (tax_ct > 0) THEN
	          FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Info: Classification (' || c_id || ') already exists for this participation record: ' || record_id as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;  
	        ELSE
	          EXECUTE 'INSERT INTO participation_taxonomy(participation_id, classification_id, field) VALUES (' || record_id || ',' || c_id || ', ''participation_id'');';
	        END IF;                
              END LOOP;
            -- requested participation is NOT active
            ELSE
              -- reactivate the record
	      EXECUTE 'UPDATE participation SET active = true, updated_by = ' || quote_literal(user_name) || ', updated_date = ' || quote_literal(current_date) || ' WHERE participation_id = '|| record_id; 
	      -- remove any taxonomies associated with the participation record
	      EXECUTE 'DELETE FROM participation_taxonomy WHERE participation_id = ' || record_id;	    
	      -- add requested taxonomies to participation record
	      FOREACH c_id IN ARRAY c_ids LOOP
                EXECUTE 'INSERT INTO participation_taxonomy(participation_id, classification_id, field) VALUES (' || record_id || ',' || c_id || ', ''participation_id'');';
              END LOOP;
            END IF;                        
	  -- the requested participation record does NOT exist
	  ELSE
	    -- create the participation record
	    EXECUTE 'INSERT INTO participation(project_id, activity_id, organization_id, created_by, updated_by) VALUES (' || p_id || ',' || a_id || ',' || o_id || ',' || quote_literal(user_name) || ',' || quote_literal(user_name) || ') RETURNING participation_id;' INTO record_id;
	    -- add requested taxonomies to participation record
	    FOREACH c_id IN ARRAY c_ids LOOP
              EXECUTE 'INSERT INTO participation_taxonomy(participation_id, classification_id, field) VALUES (' || record_id || ',' || c_id || ', ''participation_id'');';
            END LOOP;
	  END IF;
	                        
        -- project participation
        ELSE                   
          -- determine if requested particpation record currently exists
	  SELECT INTO record_id p.participation_id FROM participation p WHERE p.project_id = p_id AND p.activity_id IS NULL AND p.organization_id = o_id;

	  -- the requested participation record exists
	  IF (record_id IS NOT NULL) THEN
	    -- determine if requested participation record is active
            SELECT INTO record_is_active pp.active FROM participation pp WHERE pp.participation_id = record_id;
            -- requested participation is active
            IF record_is_active THEN
               -- add requested taxonomies to participation record if they do not exist
	      FOREACH c_id IN ARRAY c_ids LOOP
	        -- determine if the classification is already assoicated to the participation record
	        SELECT INTO tax_ct COUNT(*) FROM participation_taxonomy pt WHERE pt.participation_id = record_id AND pt.classification_id = c_id AND field = 'participation_id';
	        IF (tax_ct > 0) THEN
	          FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Info: Classification (' || c_id || ') already exists for this participation record: ' || record_id as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;  
	        ELSE
	          EXECUTE 'INSERT INTO participation_taxonomy(participation_id, classification_id, field) VALUES (' || record_id || ',' || c_id || ', ''participation_id'');';
	        END IF;                
              END LOOP;
            -- requested participation is NOT active
            ELSE
              -- reactivate the record
	      EXECUTE 'UPDATE participation SET active = true, updated_by = ' || quote_literal(user_name) || ', updated_date = ' || quote_literal(current_date) || ' WHERE participation_id = '|| record_id; 
	      -- remove any taxonomies associated with the participation record
	      EXECUTE 'DELETE FROM participation_taxonomy WHERE participation_id = ' || record_id;	    
	      -- add requested taxonomies to participation record
	      FOREACH c_id IN ARRAY c_ids LOOP
                EXECUTE 'INSERT INTO participation_taxonomy(participation_id, classification_id, field) VALUES (' || record_id || ',' || c_id || ', ''participation_id'');';
              END LOOP;
            END IF;	    
	  -- the requested participation record does NOT exist
	  ELSE
	    -- create the participation record
	    EXECUTE 'INSERT INTO participation(project_id, organization_id, created_by, updated_by) VALUES (' || p_id || ',' || o_id || ',' || quote_literal(user_name) || ',' || quote_literal(user_name) || ') RETURNING participation_id;' INTO record_id;
	    -- add requested taxonomies to participation record
	    FOREACH c_id IN ARRAY c_ids LOOP
              EXECUTE 'INSERT INTO participation_taxonomy(participation_id, classification_id, field) VALUES (' || record_id || ',' || c_id || ', ''participation_id'');';
            END LOOP;
	  END IF;	           
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
