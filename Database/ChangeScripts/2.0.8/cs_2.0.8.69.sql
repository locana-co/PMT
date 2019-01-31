/******************************************************************
Change Script 2.0.8.69
1. pmt_edit_map - new function to support editing of the map table

Instructions:
1. Change authentication logic to allow user to edit only rows belonging
to them
2. Logic Error:   
-- This should create a map record with my user_id and the description field = to testingnow
select * from pmt_edit_map((select user_id from "user" where username = 'sparadee'),5,'{"description":"testingnow"}', false); 
-- No record is found
select * from map where user_id = (select user_id from "user" where username = 'sparadee')

******************************************************************/
INSERT INTO version(version, iteration, changeset) VALUES (2.0, 8, 69);
-- select * from version order by changeset desc;

/******************************************************************
   pmt_validate_map
******************************************************************/
DROP FUNCTION IF EXISTS pmt_validate_map(integer);

CREATE OR REPLACE FUNCTION pmt_validate_map(id integer) RETURNS boolean AS $$
DECLARE valid_id integer;
BEGIN 
      IF $1 IS NULL THEN    
       RETURN false;
     END IF;    
     
     SELECT INTO valid_id map_id FROM map WHERE active = true AND map_id = $1;   

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
   pmt_edit_map

   TESTING
   select * from pmt_edit_map(34,5,'{"description":"testingnow"}', false); -- pass
   select * from pmt_edit_map(54,5,'{"description":"test"}', false); -- pass
   select * from pmt_edit_map(5422,5,'{"description":"test"}', false); -- pass  
   select * from pmt_edit_map(54,33,'{"description":"test"}', false); -- pass

******************************************************************/
CREATE OR REPLACE FUNCTION pmt_edit_map(user_id integer, map_id integer, key_value_data json, delete_record boolean default false) RETURNS SETOF pmt_json_result_type AS 
$$
DECLARE
  new_map_id integer;
  m_id integer;
  json record;
  column_record record;
  execute_statement text;
  invalid_editing_columns text[];
  user_name text;
  rec record;
  error_msg1 text;
  error_msg2 text;
  error_msg3 text;
BEGIN 
  -- set columns that are not editable via the parameters 
  invalid_editing_columns := ARRAY['map_id', 'active', 'retired_by', 'created_by', 'created_date', 'updated_by', 'updated_date'];
  
  -- user and data parameters are required
  IF ($1 IS NOT NULL) THEN
    IF NOT ($4) AND ($3 IS NULL) THEN
      FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: Must included json parameter when delete_record is false.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
    END IF;
  ELSE
    FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: Must included user_id parameter.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
  END IF; 

  -- get users name
  SELECT INTO user_name username FROM "user" WHERE "user".user_id = $1;

  -- if map_id is null then validate users authroity to create a new map record  
  IF ($2 IS NULL) THEN
    IF (SELECT * FROM pmt_validate_user_authority($1, null, 'read')) THEN
      EXECUTE 'INSERT INTO map(user_id, created_by, updated_by) VALUES (' || $1 || ',' || quote_literal(user_name) || ',' || quote_literal(user_name) || ') RETURNING map_id;' INTO new_map_id;
      RAISE NOTICE 'Created new map with id: %', new_map_id;
    ELSE
      FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: User does NOT have authority to create a new map.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
    END IF;
  -- validate map_id if provided 
  ELSE      
    IF (SELECT * FROM pmt_validate_map($2)) THEN 

      -- validate users authority to 'delete' this map
      IF ($4) THEN
        IF ((SELECT * FROM pmt_validate_user_authority($1, null, 'read')) AND ((SELECT map.user_id FROM map WHERE map.map_id = $2) = $1))  THEN
          -- deactivate this map          
          EXECUTE 'UPDATE map SET active = false WHERE map.map_id = ' || $2;
        ELSE
          FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: User does NOT have authority to delete this map.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
        END IF;

      -- validate users authority to 'update' this map
      ELSE          
        IF (SELECT * FROM pmt_validate_user_authority($1, null, 'read')) THEN   
        ELSE
      -- this error should never be thrown  
          FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: User does NOT have authority to update an existing map.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
        END IF;
      END IF;
    ELSE
      FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: Invalid map_id.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
    END IF;
  END IF;
             
  -- assign the map_id to use in statements
  IF new_map_id IS NOT NULL THEN
    m_id := new_map_id;
  ELSE
    m_id := $2;
  END IF;
  
  -- loop through the columns of the map table        
  FOR json IN (SELECT * FROM json_each_text($3)) LOOP
    RAISE NOTICE 'JSON key/value: %', lower(json.key) || ':' || json.value;
    -- get the column information for column that user is requesting to edit  
    FOR column_record IN (SELECT * FROM information_schema.columns WHERE table_schema='public' AND table_name='map' AND column_name != ALL(invalid_editing_columns) AND lower(column_name) = lower(json.key)) LOOP 
      RAISE NOTICE 'Editing column: %', column_record.column_name;
      RAISE NOTICE 'Assigning new value: %', json.value;
      execute_statement := null;
      CASE column_record.data_type 
        WHEN 'integer', 'numeric' THEN              
          IF (SELECT pmt_isnumeric(json.value)) THEN
            execute_statement := 'UPDATE map SET ' || column_record.column_name || ' = ' || json.value || ' WHERE map_id = ' || m_id; 
          END IF;
          IF (lower(json.value) = 'null') THEN
            execute_statement := 'UPDATE map SET ' || column_record.column_name || ' = null WHERE map_id = ' || m_id; 
          END IF;
        ELSE
          -- if the value has the text null then assign the column value null
          IF (lower(json.value) = 'null') THEN
            execute_statement := 'UPDATE map SET ' || column_record.column_name || ' = null WHERE map_id = ' || m_id; 
          ELSE
            execute_statement := 'UPDATE map SET ' || column_record.column_name || ' = ' || quote_literal(json.value) || ' WHERE map_id = ' || m_id; 
          END IF;
      END CASE;
      IF execute_statement IS NOT NULL THEN
        RAISE NOTICE 'Statement: %', execute_statement;
        EXECUTE execute_statement;
                
        EXECUTE 'UPDATE map SET updated_by = ' || quote_literal(user_name) || ', updated_date = ' || quote_literal(current_date) || ' WHERE  map_id = ' || m_id;
      END IF;
    END LOOP;
  END LOOP;
  -- editing completed successfullly
  FOR rec IN (SELECT row_to_json(j) FROM(select m_id as id, 'Success' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
   
EXCEPTION WHEN others THEN
    GET STACKED DIAGNOSTICS error_msg1 = MESSAGE_TEXT,
                          error_msg2 = PG_EXCEPTION_DETAIL,
                          error_msg3 = PG_EXCEPTION_HINT;
    FOR rec IN (SELECT row_to_json(j) FROM(select m_id as id, 'Internal Error - Contact your DBA with the following error message: ' || error_msg1 as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;    
END;$$ LANGUAGE plpgsql;

-- update permissions
GRANT USAGE ON SCHEMA public TO pmt_read;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO pmt_read;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO pmt_read;
GRANT USAGE ON SCHEMA public TO pmt_write;
GRANT SELECT,INSERT ON ALL TABLES IN SCHEMA public TO pmt_write;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO pmt_write;

