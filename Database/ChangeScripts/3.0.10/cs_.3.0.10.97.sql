/******************************************************************
Change Script 3.0.10.97
1. create new function to pmt_is_data_groups support consistantcy checks
2. add new fields to the taxonomy table to support ownership
3. update pmt_taxonomies function for current model
4. create new pmt_edit_taxonomy function
5. create new pmt_edit_classification function
6. create pmt_taxonomy_search to filter all active taxonomies 
  by search criteria, and exclude returns by taxonomy_id
7. create pmt_taxonomy_count to return count of filtered taxonomies
8. create pmt_classification_search to filter all active classifications 
  by search criteria
9. create pmt_classification_count to count filtered active classifications 
  by search criteria
******************************************************************/
INSERT INTO version(_version, _iteration, _changeset) VALUES (3.0, 10, 97);
-- select * from version order by _iteration desc, _changeset desc;

/*************************************************************************
  1. create new function to pmt_is_data_groups support consistantcy checks
  select id from classification where taxonomy_id = 1
  select * from pmt_is_data_groups(ARRAY[2237]);
*************************************************************************/
-- pmt_is_data_groups
CREATE OR REPLACE FUNCTION pmt_is_data_groups(classification_ids integer[]) RETURNS boolean AS $$
DECLARE 
	rec_count integer;
BEGIN 
     IF $1 IS NULL OR array_length($1, 1) = 0 THEN  
       -- allowing nulls to be truthy 
       RETURN true;
     END IF;    

     SELECT INTO rec_count count(DISTINCT id)::int FROM classification WHERE classification.id = ANY($1) AND taxonomy_id = 1;	
     -- SELECT count(DISTINCT id)::int,array_length(ARRAY[1068,769,768], 1)  FROM classification WHERE classification.id = ANY(ARRAY[1068,769,768]) AND taxonomy_id = 1;	
	
     IF rec_count = array_length($1, 1) THEN
       RETURN TRUE; 
     ELSE
       RETURN FALSE;
     END IF;
     
EXCEPTION WHEN OTHERS THEN
    RETURN FALSE;
END; 
$$ LANGUAGE 'plpgsql'; 

/******************************************************************
 2. add new taxonomy table to support ownership
******************************************************************/
-- add new fields
ALTER TABLE taxonomy
	ADD COLUMN _core boolean default false,
	ADD COLUMN data_group_ids integer[];
-- add new constraint
ALTER TABLE taxonomy DROP CONSTRAINT IF EXISTS chk_taxonomy_dg_chk;
ALTER TABLE taxonomy 
	ADD CONSTRAINT chk_taxonomy_dg_chk CHECK (pmt_is_data_groups(data_group_ids)) NOT VALID;

/******************************************************************
 3. update pmt_taxonomies function for current model
   select * from pmt_taxonomies(1,false);
******************************************************************/
-- drop old 8.0 function
DROP FUNCTION IF EXISTS pmt_taxonomies(character varying);
-- new function to replace old
CREATE OR REPLACE FUNCTION pmt_taxonomies(instance_id integer, return_core boolean) RETURNS SETOF pmt_json_result_type AS $$
DECLARE 
	valid_instance record;
	execute_statement text;
	rec record;
	error_msg text;
BEGIN 

   -- validate instance id
   IF $1 IS NOT NULL THEN
     SELECT INTO valid_instance * FROM instance WHERE id = $1;
     IF valid_instance IS NULL THEN
       FOR rec IN SELECT row_to_json(j) FROM( SELECT 'Error: provided instance_id is invalid.' AS error ) as j LOOP RETURN NEXT rec; END LOOP;
     END IF;
   END IF;

   -- return instance specific taxonomies
   IF valid_instance IS NOT NULL THEN
     -- return core
     IF return_core THEN
       execute_statement:= 'SELECT * FROM taxonomy WHERE data_group_ids <@ valid_instance.data_group_ids AND _active = true';
     -- do not return core
     ELSE
       execute_statement:= 'SELECT * FROM taxonomy WHERE data_group_ids <@ valid_instance.data_group_ids AND _active = true AND _core = false';
     END IF;
   -- return all instance taxonomies
   ELSE
     -- return core
     IF return_core THEN
       execute_statement:= 'SELECT * FROM taxonomy WHERE _active = true'; 
     -- do not return core
     ELSE
       execute_statement:= 'SELECT * FROM taxonomy WHERE _active = true AND _core = false';
     END IF;
   END IF;

  RAISE NOTICE 'Execute statement: %', execute_statement;			

  FOR rec IN EXECUTE 'SELECT row_to_json(j) FROM (' || execute_statement || ')j' LOOP  		
	RETURN NEXT rec;
  END LOOP;

EXCEPTION WHEN others THEN
  GET STACKED DIAGNOSTICS error_msg = MESSAGE_TEXT;
    RAISE NOTICE 'Internal Error - Contact your DBA with the following error message: %', error_msg; 
END; 
$$ LANGUAGE 'plpgsql';

/******************************************************************
 4. create new pmt_edit_taxonomy function
   select * from pmt_edit_taxonomy(1,34,null,'{"_name": "Test Taxonomy","_description": "testing"}',false); -- create
   select * from pmt_edit_taxonomy(1,34,85,'{"_description": "testing update"}',false); -- update
   select * from pmt_edit_taxonomy(1,34,85,null,true); -- delete
   select * from taxonomy where _name = 'Test Taxonomy'
   delete from taxonomy where _name = 'Test Taxonomy'
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_edit_taxonomy(instance_id integer, user_id integer, taxonomy_id integer, key_value_data json, delete_record boolean DEFAULT false)
  RETURNS SETOF pmt_json_result_type AS $$
DECLARE
	valid_taxonomy_id integer;
	new_taxonomy_id integer;
	username text;
	valid_user_instance record;
	t_id integer;
	json record;
	column_record record;
	execute_statement text;
	invalid_editing_columns text[];
	users_role record;
	rec record;
	error_msg1 text;
	error_msg2 text;
	error_msg3 text;
BEGIN	

  -- set columns that are not editable via the parameters 
  invalid_editing_columns := ARRAY['id', '_active', '_retired_by', '_created_by', '_created_date', '_updated_by', '_updated_date', 'data_group_ids', '_core' ];
  

  -- instance_id is required for all operations
  IF ($1 IS NULL) THEN
	FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: instance_id is a required parameter for all operations.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
  END IF;
  -- user_id is required for all operations
  IF ($2 IS NULL) THEN
	FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: user_id is a required parameter for all operations.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
  END IF;

  -- update/create operation
  IF NOT ($5) THEN
    -- json is required
    IF ($4 IS NULL) THEN
      FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: The json parameter is required for a create/update operation.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
    END IF;    
  -- delete operation	
  ELSE
    -- taxonomy id is requried
    IF ($3 IS NULL) THEN
      FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: taxonomy_id is required for a delete operation.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
    ELSE
      SELECT INTO valid_taxonomy_id id FROM taxonomy WHERE id = $3;
      IF valid_taxonomy_id IS NULL THEN
        FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: The provided taxonomy_id is invalid.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
      END IF;
    END IF;
  END IF;
  
  -- get users name
  SELECT INTO username _username FROM users WHERE users.id = $2;
  -- get user role
  SELECT INTO valid_user_instance * FROM _user_instances WHERE _user_instances.user_id = $2 AND _user_instances.instance_id = $1;
  -- valiate user access on instance
  IF valid_user_instance.user_id IS NOT NULL THEN
    SELECT INTO users_role * FROM role WHERE id = valid_user_instance.role_id;
    RAISE NOTICE 'Role: %', valid_user_instance.role;
  ELSE
    FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: User does not have authorization on the provided instance.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
  END IF;

  -- validate user's authorization to edit at the entity level (required role with: _security = true)
  IF (SELECT _security FROM role WHERE id = valid_user_instance.role_id) THEN
    -- create operation
    IF ($3 IS NULL) THEN
      EXECUTE 'INSERT INTO taxonomy(data_group_ids, _created_by, _updated_by) VALUES (ARRAY[' || array_to_string(valid_user_instance.data_group_ids, ',') || '], ' || quote_literal(valid_user_instance.username) || 
      ',' || quote_literal(valid_user_instance.username) || ') RETURNING id;' INTO new_taxonomy_id;
      -- RAISE NOTICE 'Created new taxonomy with id: %', new_taxonomy_id;
    -- update/delete operations
    ELSE
      -- validate users authorization to edit requested taxonomy
      IF (SELECT valid_user_instance.data_group_ids @> data_group_ids FROM taxonomy WHERE id = $3) THEN
        -- delete operation
        IF ($5) THEN
          UPDATE taxonomy SET _active = false, _updated_by = quote_literal(valid_user_instance.username) WHERE id = $3;
          UPDATE classification SET _active = false, _updated_by = quote_literal(valid_user_instance.username) WHERE classification.taxonomy_id = $3;
        END IF;
      ELSE
        FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: User does not have authorization to edit this taxonomy.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
      END IF;      
    END IF;
  ELSE
    FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: The user does not have authorization to edit taxonomies for the provided instance.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
  END IF;
  
  -- assign the activity_id to use in statements
  IF new_taxonomy_id IS NOT NULL THEN
    t_id := new_taxonomy_id;
  ELSE
    t_id := $3;
  END IF;
  
 -- loop through the columns of the activity table        
  FOR json IN (SELECT * FROM json_each_text($4)) LOOP
    RAISE NOTICE 'JSON key/value: %', lower(json.key) || ':' || json.value;
    -- get the column information for column that user is requesting to edit	
    FOR column_record IN (SELECT * FROM information_schema.columns WHERE table_schema='public' AND table_name='taxonomy' AND column_name != ALL(invalid_editing_columns) AND lower(column_name) = lower(json.key)) LOOP 
      RAISE NOTICE 'Editing column: %', column_record.column_name;
      RAISE NOTICE 'Assigning new value: %', json.value;
      execute_statement := null;
      CASE column_record.data_type 
        WHEN 'integer', 'numeric' THEN              
          IF (SELECT pmt_isnumeric(json.value)) THEN
            execute_statement := 'UPDATE taxonomy SET ' || column_record.column_name || ' = ' || json.value || ' WHERE id = ' || t_id; 
          END IF;
          IF (lower(json.value) = 'null') THEN
            execute_statement := 'UPDATE taxonomy SET ' || column_record.column_name || ' = null WHERE id = ' || t_id; 
          END IF;
        ELSE
          -- if the value has the text null then assign the column value null
          IF (lower(json.value) = 'null') THEN
            execute_statement := 'UPDATE taxonomy SET ' || column_record.column_name || ' = null WHERE id = ' || t_id; 
          ELSE
            execute_statement := 'UPDATE taxonomy SET ' || column_record.column_name || ' = ' || quote_literal(json.value) || ' WHERE id = ' || t_id; 
          END IF;
      END CASE;
      IF execute_statement IS NOT NULL THEN
        RAISE NOTICE 'Statement: %', execute_statement;
        EXECUTE execute_statement;
                
        EXECUTE 'UPDATE taxonomy SET _updated_by = ' || quote_literal(username) || ', _updated_date = ' || quote_literal(current_date) || ' WHERE  id = ' || t_id;
      END IF;
    END LOOP;
  END LOOP;
  
  -- editing completed successfullly
  FOR rec IN (SELECT row_to_json(j) FROM(select t_id as id, 'Success' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;         
   
EXCEPTION WHEN others THEN
    GET STACKED DIAGNOSTICS error_msg1 = MESSAGE_TEXT,
                          error_msg2 = PG_EXCEPTION_DETAIL,
                          error_msg3 = PG_EXCEPTION_HINT;
    FOR rec IN (SELECT row_to_json(j) FROM(select t_id as id, 'Internal Error - Taxonomy table edit. Please contact your DBA with the following error message: ' || error_msg1 as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;	  
END;
$$ LANGUAGE 'plpgsql';


/******************************************************************
 5. create new pmt_edit_classification function
   select * from pmt_edit_classification(1,34,null,80,'{"_name": "Test Classification","_description": "testing"}',false); -- create
   select * from pmt_edit_classification(1,34,2571,null,'{"_description": "testing update"}',false); -- update
   select * from pmt_edit_classification(1,34,2571,null,null,true); -- delete
   select * from classification where _name = 'Test Classification'
   delete from classification where _name = 'Test Classification'
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_edit_classification(instance_id integer, user_id integer, classification_id integer, taxonomy_id integer, key_value_data json, delete_record boolean DEFAULT false)
  RETURNS SETOF pmt_json_result_type AS $$
DECLARE
	valid_classification record;
	valid_taxonomy_id integer;
	new_classification_id integer;
	username text;
	valid_user_instance record;
	c_id integer;
	json record;
	column_record record;
	execute_statement text;
	invalid_editing_columns text[];
	users_role record;
	rec record;
	error_msg1 text;
	error_msg2 text;
	error_msg3 text;
BEGIN	

  -- set columns that are not editable via the parameters 
  invalid_editing_columns := ARRAY['id', '_active', '_retired_by', '_created_by', '_created_date', '_updated_by', '_updated_date' ];
  

  -- instance_id is required for all operations
  IF ($1 IS NULL) THEN
	FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: instance_id is a required parameter for all operations.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
  END IF;
  -- user_id is required for all operations
  IF ($2 IS NULL) THEN
	FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: user_id is a required parameter for all operations.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
  END IF;

  -- update/create operation
  IF NOT ($6) THEN
    -- json is required
    IF ($5 IS NULL) THEN
      FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: The json parameter is required for a create/update operation.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
    END IF; 
    -- taxonomy id required on create operations
    IF ($3 IS NULL) AND ($4 IS NULL) THEN
      FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: The taxonomy_id parameter is required for a create operation.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
    END IF;   
  -- delete operation	
  ELSE
    -- classification id is requried
    IF ($3 IS NULL) THEN
      FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: classification_id is required for a delete operation.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
    END IF;
  END IF;
  -- validate classification id if provided
  IF ($3 IS NOT NULL) THEN
    SELECT INTO valid_classification * FROM classification WHERE id = $3;
    IF valid_classification IS NULL THEN
         FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: The provided classification_id is invalid.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
    END IF;
  END IF;
  
  -- get users name
  SELECT INTO username _username FROM users WHERE users.id = $2;
  -- get user role
  SELECT INTO valid_user_instance * FROM _user_instances WHERE _user_instances.user_id = $2 AND _user_instances.instance_id = $1;
  -- valiate user access on instance
  IF valid_user_instance.user_id IS NOT NULL THEN
    SELECT INTO users_role * FROM role WHERE id = valid_user_instance.role_id;
    RAISE NOTICE 'Role: %', valid_user_instance.role;
  ELSE
    FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: User does not have authorization on the provided instance.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
  END IF;

  -- validate user's authorization to edit at the entity level (required role with: _security = true)
  IF (SELECT _security FROM role WHERE id = valid_user_instance.role_id) THEN
    -- create operation
    IF ($3 IS NULL) THEN
      SELECT INTO valid_taxonomy_id id FROM taxonomy WHERE id = $4;
      IF valid_taxonomy_id IS NULL THEN
        FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: A valid taxonomy_id parameter is required for a create operation.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
      END IF;
      EXECUTE 'INSERT INTO classification(taxonomy_id, _created_by, _updated_by) VALUES (' || valid_taxonomy_id || ',' || quote_literal(valid_user_instance.username) || 
      ',' || quote_literal(valid_user_instance.username) || ') RETURNING id;' INTO new_classification_id;
      -- RAISE NOTICE 'Created new classification with id: %', new_classification_id;
    -- update/delete operations
    ELSE
      -- validate users authorization to edit requested taxonomy
      IF (SELECT valid_user_instance.data_group_ids @> data_group_ids FROM taxonomy WHERE id = valid_classification.taxonomy_id) THEN
        -- delete operation
        IF ($6) THEN
          UPDATE classification SET _active = false, _updated_by = quote_literal(valid_user_instance.username) WHERE id = $3;
        END IF;
      ELSE
        FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: User does not have authorization to edit this taxonomy.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
      END IF;      
    END IF;
  ELSE
    FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: The user does not have authorization to edit taxonomies for the provided instance.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
  END IF;
  
  -- assign the id to use in statements
  IF new_classification_id IS NOT NULL THEN
    c_id := new_classification_id;
  ELSE
    c_id := $3;
  END IF;
  
 -- loop through the columns of the activity table        
  FOR json IN (SELECT * FROM json_each_text($5)) LOOP
    RAISE NOTICE 'JSON key/value: %', lower(json.key) || ':' || json.value;
    -- get the column information for column that user is requesting to edit	
    FOR column_record IN (SELECT * FROM information_schema.columns WHERE table_schema='public' AND table_name='classification' AND column_name != ALL(invalid_editing_columns) AND lower(column_name) = lower(json.key)) LOOP 
      RAISE NOTICE 'Editing column: %', column_record.column_name;
      RAISE NOTICE 'Assigning new value: %', json.value;
      execute_statement := null;
      CASE column_record.data_type 
        WHEN 'integer', 'numeric' THEN              
          IF (SELECT pmt_isnumeric(json.value)) THEN
            execute_statement := 'UPDATE classification SET ' || column_record.column_name || ' = ' || json.value || ' WHERE id = ' || c_id; 
          END IF;
          IF (lower(json.value) = 'null') THEN
            execute_statement := 'UPDATE classification SET ' || column_record.column_name || ' = null WHERE id = ' || c_id; 
          END IF;
        ELSE
          -- if the value has the text null then assign the column value null
          IF (lower(json.value) = 'null') THEN
            execute_statement := 'UPDATE classification SET ' || column_record.column_name || ' = null WHERE id = ' || c_id; 
          ELSE
            execute_statement := 'UPDATE classification SET ' || column_record.column_name || ' = ' || quote_literal(json.value) || ' WHERE id = ' || c_id; 
          END IF;
      END CASE;
      IF execute_statement IS NOT NULL THEN
        RAISE NOTICE 'Statement: %', execute_statement;
        EXECUTE execute_statement;
                
        EXECUTE 'UPDATE classification SET _updated_by = ' || quote_literal(username) || ', _updated_date = ' || quote_literal(current_date) || ' WHERE  id = ' || c_id;
      END IF;
    END LOOP;
  END LOOP;
  
  -- editing completed successfullly
  FOR rec IN (SELECT row_to_json(j) FROM(select c_id as id, 'Success' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;         
   
EXCEPTION WHEN others THEN
    GET STACKED DIAGNOSTICS error_msg1 = MESSAGE_TEXT,
                          error_msg2 = PG_EXCEPTION_DETAIL,
                          error_msg3 = PG_EXCEPTION_HINT;
    FOR rec IN (SELECT row_to_json(j) FROM(select c_id as id, 'Internal Error - classification table edit. Please contact your DBA with the following error message: ' || error_msg1 as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;	  
END;
$$ LANGUAGE 'plpgsql';

 /******************************************************************
6. create pmt_taxonomy_search to filter all active taxonomies 
  by search criteria, and exclude returns by taxonomy_id
  select * from pmt_taxonomy_search(1,'org',null,0,10,true);
  select * from pmt_taxonomy_search(1,'org','5,8',0,10,false);
  select * from pmt_taxonomy_search(1,null,null,0,30,false);
  select * from pmt_taxonomy_search(1,'org',null,0,10,false);
  select * from pmt_taxonomy_search(1,null,'5',5,5,true); 
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_taxonomy_search(instance_id integer, search_text text, exclude_ids character varying, offsetter integer, limiter integer, return_core boolean)
  RETURNS SETOF pmt_json_result_type AS $$
DECLARE 
  t_ids integer[];
  valid_taxonomy_ids integer[];
  valid_instance record;
  rec record;
  execute_statement text;
BEGIN 

  -- validate instance id
  IF $1 IS NOT NULL THEN
    SELECT INTO valid_instance * FROM instance WHERE id = $1;
    IF valid_instance IS NULL THEN
      FOR rec IN SELECT row_to_json(j) FROM( SELECT 'Error: provided instance_id is invalid.' AS error ) as j LOOP RETURN NEXT rec; END LOOP;
    END IF;
  END IF;
  
  -- validate excluded taxonomy ids
  IF $3 IS NOT NULL AND $3 <> '' THEN
    t_ids:= string_to_array($3, ',')::int[];
    SELECT INTO valid_taxonomy_ids array_agg(id)::int[] FROM taxonomy t WHERE _active=true AND id = ANY(t_ids);
  END IF;

  -- return instance specific taxonomies
  IF valid_instance IS NOT NULL THEN
    -- return core
     IF return_core THEN
      execute_statement:= 'SELECT * FROM taxonomy WHERE data_group_ids <@ valid_instance.data_group_ids AND _active = true ';
    -- do not return core
    ELSE
      execute_statement:= 'SELECT * FROM taxonomy WHERE data_group_ids <@ valid_instance.data_group_ids AND _active = true AND _core = false ';
    END IF;
  -- return all instance taxonomies
  ELSE
    -- return core
    IF return_core THEN
      execute_statement:= 'SELECT * FROM taxonomy WHERE _active = true '; 
    -- do not return core
    ELSE
      execute_statement:= 'SELECT * FROM taxonomy WHERE _active = true AND _core = false ';
    END IF;
  END IF;

  -- filter by search critieria
  IF $2 IS NOT NULL AND $2 <> '' THEN
    execute_statement:= execute_statement || 'AND id IN (SELECT taxonomy_id FROM _taxonomy_classifications WHERE (lower(taxonomy) LIKE ''%' || lower($2) || '%'' ' ||
						' OR lower(classification) LIKE ''%' || lower($2) || '%'')) ';
  END IF;

  -- exculusons
  IF $3 IS NOT NULL AND $3 <> '' THEN
    execute_statement:= execute_statement || ' AND NOT (id = ANY(ARRAY[' || array_to_string(valid_taxonomy_ids, ',') || '])) ';
  END IF;

  execute_statement:= execute_statement || ' ORDER BY id, _name ';

  -- offset
  IF $4 IS NOT NULL THEN
    execute_statement:= execute_statement || ' OFFSET ' || $4;
  END IF;

  -- limit
  IF $5 IS NOT NULL THEN
    execute_statement:= execute_statement || ' LIMIT ' || $5;
  END IF;
  
  RAISE NOTICE 'execute_statement: %', execute_statement;	
  
  FOR rec IN EXECUTE 'SELECT row_to_json(j) FROM (' || execute_statement || ')j' LOOP  		
	RETURN NEXT rec;
  END LOOP;

END;
$$ LANGUAGE 'plpgsql'; 

 /******************************************************************
7. create pmt_taxonomy_count to return count of filtered taxonomies
  select * from pmt_taxonomy_count(1,'org',null,false);
  select * from pmt_taxonomy_count(1,'org','5,8',false);
  select * from pmt_taxonomy_count(1,null,null,false);
  select * from pmt_taxonomy_count(1,'org',null,false);
  select * from pmt_taxonomy_count(1,null,'5',true); 
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_taxonomy_count(instance_id integer, search_text text, exclude_ids character varying, return_core boolean)
  RETURNS SETOF pmt_json_result_type AS $$
DECLARE 
  t_ids integer[];
  valid_taxonomy_ids integer[];
  valid_instance record;
  rec record;
  execute_statement text;
BEGIN 

  -- validate instance id
  IF $1 IS NOT NULL THEN
    SELECT INTO valid_instance * FROM instance WHERE id = $1;
    IF valid_instance IS NULL THEN
      FOR rec IN SELECT row_to_json(j) FROM( SELECT 'Error: provided instance_id is invalid.' AS error ) as j LOOP RETURN NEXT rec; END LOOP;
    END IF;
  END IF;
  
  -- validate excluded taxonomy ids
  IF $3 IS NOT NULL AND $3 <> '' THEN
    t_ids:= string_to_array($3, ',')::int[];
    SELECT INTO valid_taxonomy_ids array_agg(id)::int[] FROM taxonomy t WHERE _active=true AND id = ANY(t_ids);
  END IF;

  execute_statement := 'SELECT   Count(DISTINCT taxonomy_id) FROM _taxonomy_classifications ';
 
  -- return instance specific taxonomies
  IF valid_instance IS NOT NULL THEN
    -- return core
     IF return_core THEN
      execute_statement:= 'SELECT count(DISTINCT id) as count FROM taxonomy WHERE data_group_ids <@ valid_instance.data_group_ids AND _active = true ';
    -- do not return core
    ELSE
      execute_statement:= 'SELECT count(DISTINCT id) as count FROM taxonomy WHERE data_group_ids <@ valid_instance.data_group_ids AND _active = true AND _core = false ';
    END IF;
  -- return all instance taxonomies
  ELSE
    -- return core
    IF return_core THEN
      execute_statement:= 'SELECT count(DISTINCT id) as count FROM taxonomy WHERE _active = true '; 
    -- do not return core
    ELSE
      execute_statement:= 'SELECT count(DISTINCT id) as count FROM taxonomy WHERE _active = true AND _core = false ';
    END IF;
  END IF;

  -- filter by search critieria
  IF $2 IS NOT NULL AND $2 <> '' THEN
    execute_statement:= execute_statement || 'AND id IN (SELECT taxonomy_id FROM _taxonomy_classifications WHERE (lower(taxonomy) LIKE ''%' || lower($2) || '%'' ' ||
						' OR lower(classification) LIKE ''%' || lower($2) || '%'')) ';
  END IF;

  -- exculusons
  IF $3 IS NOT NULL AND $3 <> '' THEN
    execute_statement:= execute_statement || ' AND NOT (id = ANY(ARRAY[' || array_to_string(valid_taxonomy_ids, ',') || '])) ';
  END IF;

  RAISE NOTICE 'execute_statement: %', execute_statement;	
  
  FOR rec IN EXECUTE 'SELECT row_to_json(j) FROM (' || execute_statement || ')j' LOOP  		
	RETURN NEXT rec;
  END LOOP;
  
END;
$$ LANGUAGE 'plpgsql'; 

  /******************************************************************
8. create pmt_classification_search to filter all active classifications 
  by search criteria
  select * from  pmt_classification_search(77,'agr',null,null);
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_classification_search(taxonomy_id integer, search_text text, offsetter integer, limiter integer)
  RETURNS SETOF pmt_json_result_type AS $$
DECLARE 
  filtered_parent_classification_ids integer[];
  filtered_child_classification_ids integer[];
  valid_taxonomy record;
  rec record;
  execute_statement text;
  error_msg text;
BEGIN
  -- validate taxonomy id
  IF $1 IS NULL THEN
    FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: taxonomy_id is a required parameter.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
  ELSE
    SELECT INTO valid_taxonomy * FROM taxonomy WHERE _active = true AND id = $1;
    IF valid_taxonomy IS NULL THEN
      FOR rec IN SELECT row_to_json(j) FROM( SELECT 'Error: provided taxonomy_id is invalid.' AS error ) as j LOOP RETURN NEXT rec; END LOOP;
    END IF;
  END IF;

  -- filter by search critieria
  IF $2 IS NOT NULL AND $2 <> '' THEN
    -- get a filtered listing of ids for parent taxonomies matching criteria
    execute_statement := 'SELECT array_agg(DISTINCT cid) FROM ( ' ||
			'SELECT tc1.classification_id as cid, tc1.classification as cc, null as id, null as c ' ||
			'FROM (SELECT * FROM _taxonomy_classifications tc  WHERE taxonomy_id = ' || $1 || ' AND lower(classification) LIKE ''%' || lower($2) || '%'' ) tc1 ' ||
			'UNION ALL ' ||
			'SELECT tc3.classification_id as id, tc3.classification as c, tc2.classification_id as id, tc2.classification as c FROM ' ||
			'(SELECT * FROM _taxonomy_classifications tc  WHERE taxonomy_id = (SELECT id FROM taxonomy WHERE parent_id = ' || $1 || ') ' ||
			'AND lower(classification) LIKE ''%' || lower($2) || '%'' ) tc2 ' ||
			'LEFT JOIN _taxonomy_classifications tc3 ' ||
			'ON tc3.classification_id = tc2.classification_parent_id) as foo';
    EXECUTE execute_statement INTO filtered_parent_classification_ids;
    
    -- get a filtered listing of ids for child taxonomies matching criteria (if requested taxonomy is a parent)
    IF (valid_taxonomy._is_category) THEN      
      execute_statement := 'SELECT array_agg(DISTINCT id) FROM ( ' ||
			'SELECT tc1.classification_id as cid, tc1.classification as cc, null as id, null as c ' ||
			'FROM (SELECT * FROM _taxonomy_classifications tc  WHERE taxonomy_id = ' || $1 || ' AND lower(classification) LIKE ''%' || lower($2) || '%'' ) tc1 ' ||
			'UNION ALL ' ||
			'SELECT tc3.classification_id as id, tc3.classification as c, tc2.classification_id as id, tc2.classification as c FROM ' ||
			'(SELECT * FROM _taxonomy_classifications tc  WHERE taxonomy_id = (SELECT id FROM taxonomy WHERE parent_id = ' || $1 || ') ' ||
			'AND lower(classification) LIKE ''%' || lower($2) || '%'' ) tc2 ' ||
			'LEFT JOIN _taxonomy_classifications tc3 ' ||
			'ON tc3.classification_id = tc2.classification_parent_id) as foo';
      EXECUTE execute_statement INTO filtered_child_classification_ids;
    END IF;
  END IF;
  		
  -- begin building nested query for parent -> child taxonomies
  IF (valid_taxonomy._is_category) THEN      
      execute_statement := 'SELECT classification_id as id, classification as c, (SELECT array_to_json(array_agg(row_to_json(a))) FROM ( ' || 
				'SELECT DISTINCT parent_id as id, _title FROM _activity_family_taxonomies WHERE classification_id = tc.classification_id ' || 
				') a ) as activities ' || 
			',(SELECT array_to_json(array_agg(row_to_json(t))) FROM ( ' || 
				'SELECT classification_id as id, classification as c, (SELECT array_to_json(array_agg(row_to_json(a))) FROM ( ' || 
					'SELECT DISTINCT parent_id as id, _title FROM _activity_family_taxonomies WHERE classification_id = cc.classification_id ' ||
					') a ) as activities ' ||  
				'FROM _taxonomy_classifications cc ';
      -- add child filter if requested
      IF $2 IS NOT NULL AND $2 <> '' THEN
        -- child filter has results
        IF array_length(filtered_child_classification_ids, 1) > 0 THEN
          execute_statement := execute_statement || 'WHERE classification_parent_id = tc.classification_id AND classification_id = ANY(ARRAY[' || array_to_string(filtered_child_classification_ids, ',') || ']) )t ) as children ';
        -- child filter has no results
        ELSE
          execute_statement := execute_statement || 'WHERE classification_parent_id = tc.classification_id AND classification_id IS NULL )t ) as children ';
        END IF;

        -- parent filter has results
        IF array_length(filtered_parent_classification_ids, 1) > 0 THEN
          execute_statement := execute_statement || 'FROM _taxonomy_classifications tc  WHERE classification_id = ANY(ARRAY[' || array_to_string(filtered_parent_classification_ids, ',') || ']) ';
        -- parent filter has no results
        ELSE
          execute_statement := execute_statement || 'FROM _taxonomy_classifications tc  WHERE classification_id = null ';
        END IF;
        
      -- no filter was applied
      ELSE
        execute_statement := execute_statement || 'WHERE classification_parent_id = tc.classification_id ' || 
			')t ) as children ' || 
			'FROM _taxonomy_classifications tc  WHERE taxonomy_id = ' || $1;
      END IF;
    -- begin building flat query for single taxonomies  
    ELSE      
      execute_statement := 'SELECT classification_id as id, classification as c, (SELECT array_to_json(array_agg(row_to_json(a))) FROM ( ' ||
				'SELECT DISTINCT parent_id as id, _title FROM _activity_family_taxonomies WHERE classification_id = tc.classification_id ' || 
				') a ) as activities, null as children ' || 
			'FROM _taxonomy_classifications tc  WHERE taxonomy_id = ' || $1;
      -- add filter if requested
      IF $2 IS NOT NULL AND $2 <> '' THEN
        execute_statement := execute_statement || 'AND lower(classification) LIKE ''%' || lower($2) || '%'''; 
      END IF;
    END IF;

  -- offset
  IF $3 IS NOT NULL THEN
    execute_statement:= execute_statement || ' OFFSET ' || $3;
  END IF;

  -- limit
  IF $4 IS NOT NULL THEN
    execute_statement:= execute_statement || ' LIMIT ' || $4;
  END IF;
  
  RAISE NOTICE 'execute_statement: %', execute_statement;	
  
  FOR rec IN EXECUTE 'SELECT row_to_json(j) FROM (' || execute_statement || ')j' LOOP  		
	RETURN NEXT rec;
  END LOOP;

EXCEPTION WHEN others THEN
    GET STACKED DIAGNOSTICS error_msg = MESSAGE_TEXT;
    FOR rec IN (SELECT row_to_json(j) FROM(select 'Internal Error: Please contact your DBA with the following error message: ' || error_msg as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;	  

END;
$$ LANGUAGE 'plpgsql'; 
  
 /******************************************************************
9. create pmt_classification_count to count filtered active classifications 
  by search criteria
  select * from pmt_classification_count(81,null);
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_classification_count(taxonomy_id integer, search_text text)
  RETURNS SETOF pmt_json_result_type AS $$
DECLARE
  valid_taxonomy_id int;
  rec record;
  execute_statement text;
  error_msg text;
BEGIN
  -- validate taxonomy id
  IF $1 IS NULL THEN
    FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: taxonomy_id is a required parameter.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
  ELSE
    SELECT INTO valid_taxonomy_id id FROM taxonomy WHERE _active = true AND id = $1;
    IF valid_taxonomy_id IS NULL THEN
      FOR rec IN SELECT row_to_json(j) FROM( SELECT 'Error: provided taxonomy_id is invalid.' AS error ) as j LOOP RETURN NEXT rec; END LOOP;
    END IF;
  END IF;

  execute_statement:= 'SELECT count(DISTINCT id) as count FROM classification WHERE taxonomy_id = ' || $1;

  -- filter by search critieria
  IF $2 IS NOT NULL AND $2 <> '' THEN
    execute_statement:= execute_statement || ' AND lower(_name) LIKE ''%' || lower($2) || '%'' ';
  END IF;
  
  RAISE NOTICE 'execute_statement: %', execute_statement;	
  
  FOR rec IN EXECUTE 'SELECT row_to_json(j) FROM (' || execute_statement || ')j' LOOP  		
	RETURN NEXT rec;
  END LOOP;

EXCEPTION WHEN others THEN
    GET STACKED DIAGNOSTICS error_msg = MESSAGE_TEXT;
    FOR rec IN (SELECT row_to_json(j) FROM(select 'Internal Error: Please contact your DBA with the following error message: ' || error_msg as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;	  

END;
$$ LANGUAGE 'plpgsql'; 
  
-- update permissions
GRANT USAGE ON SCHEMA public TO pmt_read;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO pmt_read;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO pmt_read;
GRANT USAGE ON SCHEMA public TO pmt_write;
GRANT SELECT,INSERT ON ALL TABLES IN SCHEMA public TO pmt_write;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO pmt_write;