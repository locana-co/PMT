/******************************************************************
Change Script 2.0.8.12 - consolidated.
1. pmt_edit_contact - new function to create/edit a contact.
******************************************************************/
INSERT INTO version(version, iteration, changeset) VALUES (2.0, 8, 12);
-- select * from version order by changeset desc;

DROP FUNCTION IF EXISTS pmt_edit_contact(integer, integer, json)  CASCADE;

-- SELECT * FROM pmt_validate_user_authority(34, null, 'create') -- bmgf
-- SELECT * FROM pmt_validate_user_authority(1, 1) -- oam
-- select * from contact order by contact_id desc

-- select * from pmt_edit_contact(34,null,'{"organization_id": 13, "first_name":"Shawna", "last_name":"Paradee", "title":"DBA"}');
-- select * from pmt_edit_contact(34,668,'{"organization_id": 152, "email":"sparadee@spatialdev.com"}');
-- delete from contact where contact_id = 668
/******************************************************************
   pmt_edit_contact
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_edit_contact(user_id integer, contact_id integer, key_value_data json) RETURNS BOOLEAN AS 
$$
DECLARE
  new_contact_id integer;
  c_id integer;
  json record;
  column_record record;
  execute_statement text;
  invalid_editing_columns text[];
  user_name text;
BEGIN	
  -- set columns that are not editable via the parameters 
  invalid_editing_columns := ARRAY['contact_id', 'active', 'retired_by', 'created_by', 'created_date', 'updated_by', 'updated_date'];
  
  -- user and data parameters are required (next versions will have a flag for deletion)
  IF ($1 IS NULL) OR ($3 IS NULL) THEN
    RAISE NOTICE 'Error: Must user and json data parameters.';
    RETURN FALSE;
  END IF; 

  -- get users name
  SELECT INTO user_name username FROM "user" WHERE "user".user_id = $1;

  -- if contact_id is null then validate users authroity to create a new contact record  
  IF ($2 IS NULL) THEN
    IF (SELECT * FROM pmt_validate_user_authority($1, null, 'create')) THEN
      EXECUTE 'INSERT INTO contact(created_by, updated_by) VALUES (' || quote_literal(user_name) || ',' || quote_literal(user_name) || ') RETURNING contact_id;' INTO new_contact_id;
      RAISE NOTICE 'Created new contact with id: %', new_contact_id;
    ELSE
      RAISE NOTICE 'Error: User does NOT have authority to create a new contact.';
      RETURN FALSE;
    END IF;
  -- validate contact_id if provided and validate users authority to update an existing record  
  ELSE      
    IF (SELECT * FROM pmt_validate_contact($2)) THEN 
      -- validate users authority to 'update' this contact
      IF (SELECT * FROM pmt_validate_user_authority($1, null, 'update')) THEN   
      ELSE
        RAISE NOTICE 'Error: User does NOT have authority to update an existing contact.';
        RETURN FALSE;
      END IF;
    ELSE
      RAISE NOTICE 'Error: Invalid contact_id.';
      RETURN FALSE;
    END IF;
  END IF;
             
  -- assign the contact_id to use in statements
  IF new_contact_id IS NOT NULL THEN
    c_id := new_contact_id;
  ELSE
    c_id := $2;
  END IF;
  
  -- loop through the columns of the contact table        
  FOR json IN (SELECT * FROM json_each_text($3)) LOOP
    RAISE NOTICE 'JSON key/value: %', json.key || ':' || json.value;
    -- get the column information for column that user is requesting to edit	
    FOR column_record IN (SELECT * FROM information_schema.columns WHERE table_schema='public' AND table_name='contact' AND column_name != ALL(invalid_editing_columns) AND column_name = json.key) LOOP 
      RAISE NOTICE 'Editing column: %', column_record.column_name;
      RAISE NOTICE 'Assigning new value: %', json.value;
      execute_statement := null;
      CASE column_record.data_type 
        WHEN 'integer', 'numeric' THEN              
          IF (SELECT pmt_isnumeric(json.value)) THEN
            execute_statement := 'UPDATE contact SET ' || column_record.column_name || ' = ' || json.value || ' WHERE contact_id = ' || c_id; 
          END IF;
        ELSE
          -- if the value has the text null then assign the column value null
          IF (lower(json.value) = 'null') THEN
            execute_statement := 'UPDATE contact SET ' || column_record.column_name || ' = null WHERE contact_id = ' || c_id; 
          ELSE
            execute_statement := 'UPDATE contact SET ' || column_record.column_name || ' = ' || quote_literal(json.value) || ' WHERE contact_id = ' || c_id; 
          END IF;
      END CASE;
      IF execute_statement IS NOT NULL THEN
        RAISE NOTICE 'Statement: %', execute_statement;
        EXECUTE execute_statement;
                
        EXECUTE 'UPDATE contact SET updated_by = ' || quote_literal(user_name) || ', updated_date = ' || quote_literal(current_date) || ' WHERE  contact_id = ' || c_id;
      END IF;
    END LOOP;
  END LOOP;
  -- editing completed successfullly
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