/******************************************************************
Change Script 2.0.8.58
1. pmt_edit_participation - updating function to allow multiple
classifiction_ids to support one to many taxonomy assignments
per a single participation record.
2. pmt_edit_participation_taxonomy - new function to edit 
participation taxonomy.
3. pmt_validate_participation - new function to validate a 
participation_id
4. pmt_validate_participations - new function to validate multiple 
participation_ids
******************************************************************/
INSERT INTO version(version, iteration, changeset) VALUES (2.0, 8, 58);
-- select * from version order by changeset desc;

DROP FUNCTION IF EXISTS pmt_edit_participation(integer,integer,integer,integer,integer,integer,pmt_edit_action);
DROP FUNCTION IF EXISTS pmt_edit_participation(integer,integer,integer,integer,character varying,integer,pmt_edit_action);
DROP FUNCTION IF EXISTS pmt_edit_participation_taxonomy(character varying,integer,pmt_edit_action);
DROP FUNCTION IF EXISTS pmt_edit_participation_taxonomy(integer,integer,pmt_edit_action);
DROP FUNCTION IF EXISTS pmt_validate_participation(integer);
DROP FUNCTION IF EXISTS pmt_validate_participations(character varying);

-- testing
-- select * from pmt_edit_participation(34, null, 2, 18416, 2008, '496', null)
-- select * from pmt_edit_participation_taxonomy(34,57789, 496, 'delete')
-- select * from pmt_edit_participation_taxonomy(34,57789, 496, 'add')
-- select * from pmt_edit_participation_taxonomy(34,57789, 494, 'replace')
-- select * from pmt_edit_participation_taxonomy(34,57789, 497, 'add')
-- select * from pmt_edit_participation(34, null, 463, 1653, 519, '496,497', 'add');
-- select * from pmt_edit_participation(34, 65843, null, null, null, null, 'delete');
-- SELECT * FROM pmt_validate_participations('18416,57789,34331,2');

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
        EXECUTE 'DELETE FROM participation WHERE participation_id ='|| record_id; 
        EXECUTE 'DELETE FROM participation_taxonomy WHERE participation_id ='|| record_id; 
        RAISE NOTICE 'Delete Record: %', 'Removed participation and taxonomy associated to this participation_id ('|| record_id ||')';
      ELSE
        FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: The requested edit action requires the user to have UPDATE rights to this project: ' || p_id as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;     
      END IF;   
    WHEN 'replace' THEN            
      -- check for required parameters
      IF (p_id IS NULL) OR (o_id IS NULL) OR (c_id IS NULL) THEN
        FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: Must have project_id, organization_id and classification_id parameters when edit action is: ' || $7 as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;     
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
	  FOREACH c_id IN ARRAY c_ids LOOP
	    EXECUTE 'INSERT INTO participation_taxonomy(participation_id, classification_id, field) VALUES (' || record_id || ',' || c_id || ', ''participation_id'');';
	  END LOOP;          
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

/******************************************************************
   pmt_edit_participation_taxonomy
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_edit_participation_taxonomy(user_id integer, participation_id integer, classification_id integer, edit_action pmt_edit_action) RETURNS BOOLEAN AS 
$$
DECLARE
  valid_classification_id boolean;
  valid_participation_id integer;
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
  
    IF (SELECT * FROM pmt_validate_participation($2)) AND (SELECT * FROM pmt_validate_classification($3)) THEN
  
      -- get the taxonomy_id of the classification_id
      SELECT INTO t_id taxonomy_id FROM taxonomy_classifications tc WHERE tc.classification_id = $3;
      
      IF t_id IS NOT NULL THEN
        -- operations based on the requested edit action
        CASE $4          
          WHEN 'delete' THEN
            -- validate users authority to perform an update action on this participation
            IF (SELECT * FROM pmt_validate_user_authority($1, $2, 'update')) THEN 
              EXECUTE 'DELETE FROM participation_taxonomy WHERE participation_id ='|| $2 ||' AND classification_id = '|| $3 ||' AND field = ''participation_id'''; 
              RAISE NOTICE 'Delete Record: %', 'Remove association to classification_id ('|| $3 ||') for participation_id ('|| $2 ||')';
            ELSE
              RAISE NOTICE 'Error: The requested edit action requires the user to have UPDATE rights to this participation: %', $2;
	      RETURN FALSE;
            END IF;     
          WHEN 'replace' THEN
             -- validate users authority to perform an update and create action on this participation
            IF (SELECT * FROM pmt_validate_user_authority($1, $2, 'update')) AND (SELECT * FROM pmt_validate_user_authority($1, $2, 'create')) THEN
            
              EXECUTE 'DELETE FROM participation_taxonomy WHERE participation_id ='|| $2 ||' AND classification_id in (SELECT classification_id FROM taxonomy_classifications WHERE taxonomy_id = '|| t_id||') AND field = ''participation_id''';
              RAISE NOTICE 'Delete Record: %', 'Remove association to taxonomy_id ('|| t_id ||') for participation_id ('|| $2 ||')';
	      EXECUTE 'INSERT INTO participation_taxonomy(participation_id, classification_id, field) VALUES ('|| $2 ||', '|| $3 ||', ''participation_id'')'; 
              RAISE NOTICE 'Add Record: %', 'participation_id ('|| $2 ||') is now associated to classification_id ('|| $3 ||').';
            ELSE
              RAISE NOTICE 'Error: The requested edit action requires the user to have UPDATE and CREATE rights to this participation: %', $2;
	      RETURN FALSE;
            END IF;  
          ELSE
            -- validate users authority to perform a create action on this participation
            IF (SELECT * FROM pmt_validate_user_authority($1, $2, 'create')) THEN 
              
              SELECT INTO record_id pt.participation_id FROM participation_taxonomy as pt WHERE pt.participation_id = $2 AND pt.classification_id = $3 LIMIT 1;
              IF record_id IS NULL THEN
               EXECUTE 'INSERT INTO participation_taxonomy(participation_id, classification_id, field) VALUES ('|| $2 ||', '|| $3 ||', ''participation_id'')';
               RAISE NOTICE 'Add Record: %', 'participation_id ('|| $2 ||') is now associated to classification_id ('|| $3 ||').'; 
             ELSE
               RAISE NOTICE'Add Record: %', 'This participation_id ('|| $2 ||') already has an association to this classification_id ('|| $3 ||').';                
             END IF;
             
            ELSE
              RAISE NOTICE 'Error: The requested edit action requires the user to have CREATE rights to this participation: %', $2;
	      RETURN FALSE;
            END IF;        
        END CASE;
        RETURN true;
      ELSE
        RAISE NOTICE 'Error: There is no taxonomy_id for given classification_id.';
	RETURN false;
      END IF;
      
    ELSE
      RAISE NOTICE 'Error: Invalid participation_id or classification_id.';
      RETURN false;
    END IF;
  ELSE
    RAISE NOTICE 'Error: Must provide user_id, participation_id and classification_id parameters.';
    RETURN false;
  END IF;
  
EXCEPTION WHEN others THEN
  GET STACKED DIAGNOSTICS error_msg1 = MESSAGE_TEXT,
		  error_msg2 = PG_EXCEPTION_DETAIL,
		  error_msg3 = PG_EXCEPTION_HINT;
                          
  RAISE NOTICE 'Error: %', error_msg1;                          
  RETURN FALSE;   	  
END;$$ LANGUAGE plpgsql;

/******************************************************************
  pmt_validate_participation
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_validate_participation(id integer) RETURNS boolean AS $$
DECLARE valid_id integer;
BEGIN 
     IF $1 IS NULL THEN    
       RETURN false;
     END IF;    
     
     SELECT INTO valid_id participation_id FROM participation WHERE active = true AND participation_id = $1;	 

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
  pmt_validate_participations
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_validate_participations(participation_ids character varying) RETURNS INT[] AS $$
DECLARE 
  valid_participation_ids INT[];
  filter_participation_ids INT[];
BEGIN 
     IF $1 IS NULL THEN    
       RETURN valid_participation_ids;
     END IF;

     filter_participation_ids := string_to_array($1, ',')::int[];
     
     SELECT INTO valid_participation_ids array_agg(DISTINCT participation_id)::INT[] FROM (SELECT participation_id FROM participation WHERE active = true AND participation_id = ANY(filter_participation_ids) ORDER BY participation_id) AS t;
     
     RETURN valid_participation_ids;

EXCEPTION
     WHEN others THEN RETURN NULL;
END; 
$$ LANGUAGE 'plpgsql';

-- update permissions
GRANT USAGE ON SCHEMA public TO pmt_read;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO pmt_read;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO pmt_read;
GRANT USAGE ON SCHEMA public TO pmt_write;
GRANT SELECT,INSERT ON ALL TABLES IN SCHEMA public TO pmt_write;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO pmt_write;