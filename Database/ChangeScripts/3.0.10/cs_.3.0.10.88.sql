/******************************************************************
Change Script 3.0.10.88
1. update pmt_activity_detail to return all required contact information
2. update pmt_contacts rename output fields
3. update pmt_validate_contact to adhear to new data model
4. update pmt_validate_contacts to adhere to new model
5. create pmt_exists_activity_contact to output if a contact is 
   already assigned to an activity returns true or false
6. update pmt_edit_contact to adhere to new data model
******************************************************************/
INSERT INTO version(_version, _iteration, _changeset) VALUES (3.0, 10, 88);
-- select * from version order by _iteration desc, _changeset desc;

/******************************************************************
1. update pmt_activity_detail to return all required contact information. 
   The added or changed fields are activities, organization_id, organization_name, and _title.
  SELECT * FROM pmt_activity_detail(26326);
  ****************************************************************/
CREATE OR REPLACE FUNCTION pmt_activity_detail(activity_id integer) RETURNS SETOF pmt_json_result_type AS 
$$
DECLARE
  rec record;
  invalid_return_columns text[];
  return_columns text;
  execute_statement text;
  data_message text;
BEGIN
  IF $1 IS NOT NULL THEN	
    -- get list of columns to return
    SELECT INTO return_columns array_to_string(array_agg('a.' || column_name::text), ', ') FROM information_schema.columns 
    WHERE table_schema='public' AND table_name='activity';

    -- dynamically build the execute statment	
    execute_statement := 'SELECT ' || return_columns || ', (SELECT _name FROM classification WHERE id = data_group_id) as data_group' || 
				', (SELECT _title FROM activity WHERE id = a.parent_id) as parent_title, l.ct ';

    -- taxonomy	
    execute_statement := execute_statement || ',(SELECT array_to_json(array_agg(row_to_json(t))) FROM ( ' ||
				'select tc.taxonomy_id, tc.taxonomy, tc.classification_id, tc.classification, tc._code ' ||
				'from activity_taxonomy at ' ||
				'join _taxonomy_classifications  tc ' ||
				'on at.classification_id = tc.classification_id ' ||
				'and at.activity_id = ' || $1 ||
				') t ) as taxonomy ';
    -- organizations			
    execute_statement := execute_statement || ',(SELECT array_to_json(array_agg(row_to_json(p))) FROM ( ' ||
				'select p.id as p_id, o.id, o._name, tc.classification_id, tc.classification ' ||
				'from (select * from participation where _active = true and activity_id = ' || $1 || ') p  ' ||
  				'left join organization o ON p.organization_id = o.id '  ||
  				'left join participation_taxonomy pt ON p.id = pt.participation_id '  ||
  				'left join _taxonomy_classifications tc ON pt.classification_id = tc.classification_id '  ||
				') p ) as organizations ';
				
    -- contacts
    execute_statement := execute_statement || ',(SELECT array_to_json(array_agg(row_to_json(c))) FROM ( ' ||
				'select c.id, c._first_name, c._last_name, c._email, c._title, c.organization_id, o._name as organization_name, ' ||
				'(SELECT array_agg(activity_id) FROM activity_contact WHERE contact_id = c.id) as activities ' || 
				'from activity_contact ac ' ||
				'join contact c ' ||
				'on ac.contact_id = c.id ' ||
				'left join organization o ' ||
				'on c.organization_id = o.id ' ||
				'where c._active = true and ac.activity_id = ' || $1 ||
				') c ) as contacts ';	

    -- financials
    execute_statement := execute_statement || ',(SELECT array_to_json(array_agg(row_to_json(f))) FROM ( ' ||
				'select f.id, f._amount, f._start_date, f._end_date'  ||
						',provider_id' ||
						',(SELECT _name FROM organization WHERE id = provider_id) as provider' ||
						',recipient_id' ||
						',(SELECT _name FROM organization WHERE id = recipient_id) as recipient' ||
						', (SELECT array_to_json(array_agg(row_to_json(t))) FROM ( ' ||
						'select tc.taxonomy_id, tc.taxonomy, tc.classification_id, tc.classification, tc._code ' ||
						'from financial_taxonomy ft ' ||
						'join _taxonomy_classifications tc ' ||
						'on ft.classification_id = tc.classification_id ' ||
						'and ft.financial_id = f.id ' ||
						') t ) as taxonomy ' ||
				'from financial f ' ||		
				'where f._active = true and f.activity_id = ' || $1 ||
				') f ) as financials ';

    -- locations
    execute_statement := execute_statement || ',(SELECT array_to_json(array_agg(row_to_json(l))) FROM (  ' ||
				'select l.id, l._admin0, l._admin1, l._admin2, l._admin3, l._admin_level, l.boundary_id, l.feature_id ' ||
				'from location l ' ||		
				'where l._active = true and l.activity_id = ' || $1 ||
				') l ) as locations ';		

    -- children
    execute_statement := execute_statement || ',(SELECT array_to_json(array_agg(row_to_json(a))) FROM (  ' ||
				'select a.id, a._title ' ||					
				'from activity a ' ||		
				'where a._active = true and a.parent_id = ' || $1 ||
				') a ) as children ';	
													
								
    -- activity
    execute_statement := execute_statement || 'from (select * from activity a where a._active = true and a.id = ' || $1 || ') a ';
    -- locations
    execute_statement := execute_statement || 'left join ' ||
				'(select ll.activity_id, count(distinct ll.location_id) as ct ' ||
				'from _location_lookup ll ' ||
				'where ll.activity_id = ' || $1 ||
				'group by ll.activity_id) l ' ||
				'on a.id = l.activity_id ';


RAISE NOTICE 'Execute statement: %', execute_statement;			

FOR rec IN EXECUTE 'SELECT row_to_json(j) FROM (' || execute_statement || ')j' LOOP  		
	RETURN NEXT rec;
END LOOP;
   END IF;
END;$$ LANGUAGE plpgsql;

/******************************************************************
2. update pmt_contacts rename output fields
  select * from pmt_contacts();
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_contacts() RETURNS SETOF pmt_json_result_type AS $$
DECLARE
  rec record;
BEGIN	
  
  FOR rec IN ( SELECT row_to_json(j) FROM ( 
    SELECT c.id, _first_name, _last_name, _title, _email, organization_id,
	(SELECT _name FROM organization where id = c.organization_id and _active = true) as organization_name,
	(SELECT array_agg(activity_id) FROM activity_contact WHERE contact_id = c.id) as activities
    FROM contact c
    WHERE _active = true
    ORDER BY _last_name, _first_name) j
  ) LOOP		
	RETURN NEXT rec;
  END LOOP;	  
END;$$ LANGUAGE plpgsql;

/******************************************************************
3. update pmt_validate_contact to adhear to new data model
   select * from pmt_validate_contact(2143);
   select * from pmt_validate_contact(99);
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_validate_contact(id integer) RETURNS boolean AS $$
DECLARE valid_id record;
BEGIN 

     IF $1 IS NULL THEN    
       RETURN false;
     END IF;    
     
     SELECT INTO valid_id contact.id FROM contact WHERE _active = true AND contact.id = $1;	 

     IF valid_id IS NULL THEN
      RETURN false;
     ELSE 
      RETURN true;
     END IF;
     
EXCEPTION WHEN others THEN
    RETURN FALSE;
END;$$ LANGUAGE plpgsql;

/******************************************************************
4. update pmt_validate_contacts to adhere to new model
   select * from pmt_validate_contacts('2154,2156,1750,99');
   select * from contact
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_validate_contacts(contact_ids character varying)
  RETURNS integer[] AS $$
DECLARE 
  valid_contact_ids INT[];
  filter_contact_ids INT[];
BEGIN 
     IF $1 IS NULL THEN    
       RETURN valid_contact_ids;
     END IF;

     filter_contact_ids := string_to_array($1, ',')::int[];
     
     SELECT INTO valid_contact_ids array_agg(DISTINCT t.id)::INT[] FROM (SELECT contact.id FROM contact WHERE _active = true AND contact.id = ANY(filter_contact_ids) ORDER BY contact.id) AS t;
     
     RETURN valid_contact_ids;

EXCEPTION
     WHEN others THEN RETURN NULL;
END;$$ LANGUAGE plpgsql;

/******************************************************************
5. create pmt_exists_activity_contact to output if a contact is already assigned to an activity
   returns true or false
   select * from pmt_exists_activity_contact(173,134);
   select * from pmt_exists_activity_contact(173,137);
   select * from activity_contact order by 1;
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_exists_activity_contact(activity_id integer, contact_id integer)
  RETURNS boolean AS
$$
DECLARE found_record record;
BEGIN 
     IF $1 IS NULL THEN    
       RETURN false;
     END IF;    
     
     SELECT * INTO found_record FROM activity_contact WHERE activity_contact.activity_id = $1 AND activity_contact.contact_id = $2;	 

     IF found_record IS NULL THEN
      RETURN false;
     ELSE 
      RETURN true;
     END IF;
     
EXCEPTION WHEN others THEN
    RETURN FALSE;
END; 
$$
  LANGUAGE plpgsql;


/******************************************************************
6. update pmt_edit_contact to adhere to new data model

  -- test (role:super crud:update) PASS
  SELECT * FROM pmt_edit_contact(1,34,741,768,113,'{"_title":"testing address edit"}',false);
  -- test (role:editor crud:update) PASS
  SELECT * FROM pmt_edit_contact(1,275,26197,2237,2139,'{"_address1":"testing address edit"}',false);
  -- test (role:reader crud:update) PASS
  SELECT * FROM pmt_edit_contact(1,274,26197,2237,2139,'{"_address1":"testing address edit"}',false);
  -- test (role:admin crud:create) PASS
  SELECT * FROM pmt_edit_contact(1,287,26197,2237,null,'{"_first_name":"Test", "_last_name":"Test"}',false);
  -- test (role:admin crud:delete) PASS
  SELECT * FROM pmt_edit_contact(1,287,26197,2237,2257,null,true);
  -- test (role:editor crud:delete) PASS
  SELECT * FROM pmt_edit_contact(1,275,26197,2237,2258,null,true);
  -- test (role:super crud:update bad field names) PASS
  SELECT * FROM pmt_edit_contact(1,34,26197,2237,2258,'{"bad_field":"stuff","_first_name":"Updated Test"}',false);

select * from _user_instances ui left join user_activity ua on ui.user_id = ua.user_id order by 1,4;
select * from (select a.id as a_id, a.data_group_id, c.* from contact c join activity_contact ac on c.id = ac.contact_id join activity a on ac.activity_id = a.id) c 
where data_group_id = 2237 and id = 2258 order by 1;
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_edit_contact(instance_id integer, user_id integer, activity_id integer, data_group_id integer, contact_id integer, key_value_data json, delete_record boolean default false) RETURNS SETOF pmt_json_result_type AS 
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
  valid_user_instance record; 
  users_role record;
  error_msg1 text;
  error_msg2 text;
  error_msg3 text;
BEGIN	
  -- set columns that are not editable via the parameters 
  invalid_editing_columns := ARRAY['id', '_active', '_retired_by', '_created_by', '_created_date', '_updated_by', '_updated_date'];
  
   -- instance_id is required for all operations
  IF ($1 IS NULL) THEN
    FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: instance_id is a required parameter for all operations.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
  END IF;
  -- user_id is required for all operations
  IF ($2 IS NULL) THEN
    FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: user_id is a required parameter for all operations.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
  END IF;
  
  -- update/create operation
  IF NOT ($7) THEN
    -- json is required
    IF ($6 IS NULL) THEN
      FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: The json parameter is required for a create/update operation.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
    END IF;
    -- if contact_id is null (create) data_group_id is required
    IF ($5 IS NULL) AND ($4 IS NULL) THEN
      FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: The data_group_id parameter is required for a create operation.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
    END IF;      
  ELSE
    -- delete operation	
    -- contact_id is requried
    IF ($5 IS NULL) THEN
      FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: contact_id is required for a delete operation.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
    END IF;
  END IF;
 
  -- get users name
  SELECT INTO user_name _username FROM users WHERE users.id = $2;
  -- get user role
  SELECT INTO valid_user_instance * FROM _user_instances WHERE _user_instances.user_id = $2 AND _user_instances.instance_id = $1;
  IF valid_user_instance.user_id IS NOT NULL THEN
    SELECT INTO users_role * FROM role WHERE id = valid_user_instance.role_id;
    RAISE NOTICE 'Role: %', valid_user_instance.role;
  END IF;
  
  -- if contact_id is null then validate users authroity to create a new contact record  
  IF ($5 IS NULL) THEN
    IF (SELECT * FROM pmt_validate_user_authority($1, $2, null, $4, 'create')) THEN
      --create new contact and retrieve new id
      EXECUTE 'INSERT INTO contact(_created_by, _updated_by) VALUES (' || quote_literal(user_name) || ',' || quote_literal(user_name) || ') RETURNING contact.id;' INTO new_contact_id;
      RAISE NOTICE 'Created new contact with id: %', new_contact_id;
      --add connection to activity so that user shows up on an activity's contact page 
      EXECUTE 'INSERT INTO activity_contact(activity_id, contact_id) VALUES (' || $3 || ',' || new_contact_id || ')';
      RAISE NOTICE 'Created new reltationship between contact and activity';
    ELSE
      FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: User does NOT have authority to create a new contact.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
    END IF;
  -- validate contact_id if provided and validate users authority to update an existing record  
  ELSE      
    IF (SELECT * FROM pmt_validate_contact($5)) THEN 
      -- validate users authority to 'delete' this contact
      IF ($7) THEN
        IF (SELECT * FROM pmt_validate_user_authority($1, $2, $3, null, 'delete')) THEN
          -- deactivate this contact      
          EXECUTE 'UPDATE contact SET _active = false WHERE contact.id = ' || $5;
          --remove connection to activity
		  --EXECUTE 'DELETE FROM activity_contact WHERE activity_contact.activity_id = ' || $3 || ' AND activity_contact.contact_id = ' || $5;
        ELSE
          FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: User does NOT have authority to delete this contact.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
        END IF;
      -- validate users authority to 'update' this contact
      ELSE          
        IF NOT (SELECT * FROM pmt_validate_user_authority($1, $2, $3, null, 'update')) THEN   
          FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: User does NOT have authority to update this contact.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
	ELSE  
           -- if this is an update of a contact that's already assigned to a project then skip
	   IF  NOT (select * from pmt_exists_activity_contact($3, $5)) THEN
	      --add connection to activity so that user shows up on an activity's contact page 
	     EXECUTE 'INSERT INTO activity_contact(activity_id, contact_id) VALUES (' || $3 || ',' || $5 || ')';
	   END IF;
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
    c_id := $5;
  END IF;
  
  -- loop through the columns of the contact table        
  FOR json IN (SELECT * FROM json_each_text($6)) LOOP
    RAISE NOTICE 'JSON key/value: %', lower(json.key) || ':' || json.value;
    -- get the column information for column that user is requesting to edit	
    FOR column_record IN (SELECT * FROM information_schema.columns WHERE table_schema='public' AND table_name='contact' AND column_name != ALL(invalid_editing_columns) AND lower(column_name) = lower(json.key)) LOOP 
      RAISE NOTICE 'Editing column: %', column_record.column_name;
      RAISE NOTICE 'Assigning new value: %', json.value;
      execute_statement := null;
      CASE column_record.data_type 
        WHEN 'integer', 'numeric' THEN              
          IF (SELECT pmt_isnumeric(json.value)) THEN
            execute_statement := 'UPDATE contact SET ' || column_record.column_name || ' = ' || json.value || ' WHERE contact.id = ' || c_id; 
          END IF;
          IF (lower(json.value) = 'null') THEN
            execute_statement := 'UPDATE contact SET ' || column_record.column_name || ' = null WHERE contact.id = ' || c_id; 
          END IF;
        ELSE
          -- if the value has the text null then assign the column value null
          IF (lower(json.value) = 'null') THEN
            execute_statement := 'UPDATE contact SET ' || column_record.column_name || ' = null WHERE contact.id = ' || c_id; 
          ELSE
            execute_statement := 'UPDATE contact SET ' || column_record.column_name || ' = ' || quote_literal(json.value) || ' WHERE contact.id = ' || c_id; 
          END IF;
      END CASE;
      IF execute_statement IS NOT NULL THEN
        RAISE NOTICE 'Statement: %', execute_statement;
        EXECUTE execute_statement;
                
        EXECUTE 'UPDATE contact SET _updated_by = ' || quote_literal(user_name) || ', _updated_date = ' || quote_literal(current_date) || ' WHERE  contact.id = ' || c_id;
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