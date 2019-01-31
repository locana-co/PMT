/******************************************************************
Change Script 2.0.8.42 - consolidated.
1. pmt_edit_organization - new function for editing organizations.
2. pmt_edit_contact - update function to allow deletion of contacts.
******************************************************************/
INSERT INTO version(version, iteration, changeset) VALUES (2.0, 8, 42);
-- select * from version order by changeset desc;

-- old drop statement
DROP FUNCTION IF EXISTS pmt_edit_contact(integer, integer, json)  CASCADE;
-- new drop statements
DROP FUNCTION IF EXISTS pmt_edit_contact(integer, integer, json, boolean)  CASCADE;
DROP FUNCTION IF EXISTS pmt_edit_organization(integer, integer, json, boolean)  CASCADE;

-- select * from contact where contact_id in (14241)
-- select * from organization where organization_id in (22,406)

-- select * from pmt_edit_organization(3,null,'{"name":"test", "address1":"testing testing", "city":"test"}'); -- add
-- select * from pmt_edit_organization(3,406,'{"address2":"testing testing", "country":"test"}'); -- update
-- select * from pmt_edit_organization(3,406,null,true); -- delete

-- select * from pmt_edit_contact(3,null,'{"organization_id":13, "first_name":"Shawna", "Last_Name":"test"}'); -- add
-- select * from pmt_edit_contact(3,14241,'{"organization_id":13, "first_name":"Shawna", "Last_Name":"testing"}');  -- update
-- select * from pmt_edit_contact(3,14241,null,true); -- delete

-- delete from organization where organization_id = 406
-- delete from contact where contact_id in (14241)
/******************************************************************
   pmt_edit_organization
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_edit_organization(user_id integer, organization_id integer, key_value_data json, delete_record boolean default false) RETURNS SETOF pmt_json_result_type AS 
$$
DECLARE
  new_organization_id integer;
  o_id integer;
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
  invalid_editing_columns := ARRAY['organization_id', 'active', 'retired_by', 'created_by', 'created_date', 'updated_by', 'updated_date'];
  
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

  -- if organization_id is null then validate users authroity to create a new organization record  
  IF ($2 IS NULL) THEN
    IF (SELECT * FROM pmt_validate_user_authority($1, null, 'create')) THEN
      EXECUTE 'INSERT INTO organization(created_by, updated_by) VALUES (' || quote_literal(user_name) || ',' || quote_literal(user_name) || ') RETURNING organization_id;' INTO new_organization_id;
      RAISE NOTICE 'Created new organization with id: %', new_organization_id;
    ELSE
      FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: User does NOT have authority to create a new organization.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
    END IF;
  -- validate organization_id if provided and validate users authority to update an existing record  
  ELSE      
    IF (SELECT * FROM pmt_validate_organization($2)) THEN 
       -- validate users authority to 'delete' this organization
      IF ($4) THEN
        IF (SELECT * FROM pmt_validate_user_authority($1, null, 'delete')) THEN
          -- deactivate this organization          
          EXECUTE 'UPDATE organization SET active = false WHERE organization.organization_id = ' || $2;
        ELSE
          FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: User does NOT have authority to delete this organization.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
        END IF;
      -- validate users authority to 'update' this activity
      ELSE             
        IF (SELECT * FROM pmt_validate_user_authority($1, null, 'update')) THEN   
        ELSE
          FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: User does NOT have authority to update an existing organization.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
        END IF;
      END IF;
    ELSE
      FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: Invalid organization_id.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
    END IF;
  END IF;
             
  -- assign the organization_id to use in statements
  IF new_organization_id IS NOT NULL THEN
    o_id := new_organization_id;
  ELSE
    o_id := $2;
  END IF;
  
  -- loop through the columns of the organization table        
  FOR json IN (SELECT * FROM json_each_text($3)) LOOP
    RAISE NOTICE 'JSON key/value: %', lower(json.key) || ':' || json.value;
    -- get the column information for column that user is requesting to edit	
    FOR column_record IN (SELECT * FROM information_schema.columns WHERE table_schema='public' AND table_name='organization' AND column_name != ALL(invalid_editing_columns) AND lower(column_name) = lower(json.key)) LOOP 
      RAISE NOTICE 'Editing column: %', column_record.column_name;
      RAISE NOTICE 'Assigning new value: %', json.value;
      execute_statement := null;
      CASE column_record.data_type 
        WHEN 'integer', 'numeric' THEN              
          IF (SELECT pmt_isnumeric(json.value)) THEN
            execute_statement := 'UPDATE organization SET ' || column_record.column_name || ' = ' || json.value || ' WHERE organization_id = ' || o_id; 
          END IF;
           IF (lower(json.value) = 'null') THEN
            execute_statement := 'UPDATE organization SET ' || column_record.column_name || ' = null WHERE organization_id = ' || o_id; 
          END IF;
        ELSE
          -- if the value has the text null then assign the column value null
          IF (lower(json.value) = 'null') THEN
            execute_statement := 'UPDATE organization SET ' || column_record.column_name || ' = null WHERE organization_id = ' || o_id; 
          ELSE
            execute_statement := 'UPDATE organization SET ' || column_record.column_name || ' = ' || quote_literal(json.value) || ' WHERE organization_id = ' || o_id; 
          END IF;
      END CASE;
      IF execute_statement IS NOT NULL THEN
        RAISE NOTICE 'Statement: %', execute_statement;
        EXECUTE execute_statement;
                
        EXECUTE 'UPDATE organization SET updated_by = ' || quote_literal(user_name) || ', updated_date = ' || quote_literal(current_date) || ' WHERE  organization_id = ' || o_id;
      END IF;
    END LOOP;
  END LOOP;
  -- editing completed successfullly
  FOR rec IN (SELECT row_to_json(j) FROM(select o_id as id, 'Success' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
   
EXCEPTION WHEN others THEN
    GET STACKED DIAGNOSTICS error_msg1 = MESSAGE_TEXT,
                          error_msg2 = PG_EXCEPTION_DETAIL,
                          error_msg3 = PG_EXCEPTION_HINT;
    FOR rec IN (SELECT row_to_json(j) FROM(select o_id as id, 'Internal Error - organization your DBA with the following error message: ' || error_msg1 as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;	  
END;$$ LANGUAGE plpgsql;


/******************************************************************
   pmt_edit_contact
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_edit_contact(user_id integer, contact_id integer, key_value_data json, delete_record boolean default false) RETURNS SETOF pmt_json_result_type AS 
$$
DECLARE
  new_contact_id integer;
  c_id integer;
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
  invalid_editing_columns := ARRAY['contact_id', 'active', 'retired_by', 'created_by', 'created_date', 'updated_by', 'updated_date'];
  
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

  -- if contact_id is null then validate users authroity to create a new contact record  
  IF ($2 IS NULL) THEN
    IF (SELECT * FROM pmt_validate_user_authority($1, null, 'create')) THEN
      EXECUTE 'INSERT INTO contact(created_by, updated_by) VALUES (' || quote_literal(user_name) || ',' || quote_literal(user_name) || ') RETURNING contact_id;' INTO new_contact_id;
      RAISE NOTICE 'Created new contact with id: %', new_contact_id;
    ELSE
      FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: User does NOT have authority to create a new contact.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
    END IF;
  -- validate contact_id if provided and validate users authority to update an existing record  
  ELSE      
    IF (SELECT * FROM pmt_validate_contact($2)) THEN 
      -- validate users authority to 'delete' this contact
      IF ($4) THEN
        IF (SELECT * FROM pmt_validate_user_authority($1, null, 'delete')) THEN
          -- deactivate this contact          
          EXECUTE 'UPDATE contact SET active = false WHERE contact.contact_id = ' || $2;
        ELSE
          FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: User does NOT have authority to delete this contact.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
        END IF;
      -- validate users authority to 'update' this contact
      ELSE          
        IF (SELECT * FROM pmt_validate_user_authority($1, null, 'update')) THEN   
        ELSE
          FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: User does NOT have authority to update an existing contact.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
        END IF;
      END IF;
    ELSE
      FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: Invalid contact_id.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
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
    RAISE NOTICE 'JSON key/value: %', lower(json.key) || ':' || json.value;
    -- get the column information for column that user is requesting to edit	
    FOR column_record IN (SELECT * FROM information_schema.columns WHERE table_schema='public' AND table_name='contact' AND column_name != ALL(invalid_editing_columns) AND lower(column_name) = lower(json.key)) LOOP 
      RAISE NOTICE 'Editing column: %', column_record.column_name;
      RAISE NOTICE 'Assigning new value: %', json.value;
      execute_statement := null;
      CASE column_record.data_type 
        WHEN 'integer', 'numeric' THEN              
          IF (SELECT pmt_isnumeric(json.value)) THEN
            execute_statement := 'UPDATE contact SET ' || column_record.column_name || ' = ' || json.value || ' WHERE contact_id = ' || c_id; 
          END IF;
          IF (lower(json.value) = 'null') THEN
            execute_statement := 'UPDATE contact SET ' || column_record.column_name || ' = null WHERE contact_id = ' || c_id; 
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
  FOR rec IN (SELECT row_to_json(j) FROM(select c_id as id, 'Success' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
   
EXCEPTION WHEN others THEN
    GET STACKED DIAGNOSTICS error_msg1 = MESSAGE_TEXT,
                          error_msg2 = PG_EXCEPTION_DETAIL,
                          error_msg3 = PG_EXCEPTION_HINT;
    FOR rec IN (SELECT row_to_json(j) FROM(select c_id as id, 'Internal Error - Contact your DBA with the following error message: ' || error_msg1 as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;	  
END;$$ LANGUAGE plpgsql;

-- update permissions
GRANT USAGE ON SCHEMA public TO pmt_read;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO pmt_read;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO pmt_read;
GRANT USAGE ON SCHEMA public TO pmt_write;
GRANT SELECT,INSERT ON ALL TABLES IN SCHEMA public TO pmt_write;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO pmt_write;