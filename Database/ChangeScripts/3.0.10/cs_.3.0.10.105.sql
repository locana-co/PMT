/******************************************************************
Change Script 3.0.10.105
1. update pmt_edit_contact to all contacts without activity refrences
2. remove character limitations from contact fields
3. create pmt_taxonomies()
******************************************************************/
INSERT INTO version(_version, _iteration, _changeset) VALUES (3.0, 10, 105);
-- select * from version order by _iteration desc, _changeset desc;

/******************************************************************
1. update pmt_edit_contact to adhere to new data model

  SELECT * FROM pmt_edit_contact(4,34,null,769, null,'{"_address1":"Earth Institute, Columbia University Columbia University 615 West 131 St Street, Room 254 Mail Code 8725 New York, NY 10027-7922 New York, NY 8725 or Recta Cali-Palmira, km 17 A.A. 6713 Cali Colombia","_direct_phone":"+1 845 365 8330","_email":"psanchez@ei.columbia.edu","_first_name":"Pedro","_last_name":"Sanchez","_title":"Grantee","organization_id":null}', false);

{"_address1":"Earth Institute, Columbia University Columbia University 615 West 131 St Street, Room 254 Mail Code 8725 New York, NY 10027-7922 New York, NY 8725 or Recta Cali-Palmira, km 17 A.A. 6713 Cali Colombia","_direct_phone":"+1 845 365 8330","_email":"psanchez@ei.columbia.edu","_first_name":"Pedro","_last_name":"Sanchez","_title":"Grantee","organization_id":null}

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
      IF $3 IS NOT NULL THEN
        --add connection to activity so that user shows up on an activity's contact page 
        EXECUTE 'INSERT INTO activity_contact(activity_id, contact_id) VALUES (' || $3 || ',' || new_contact_id || ')';
        RAISE NOTICE 'Created new reltationship between contact and activity';
      END IF;
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


/******************************************************************
2. remove character limitations from contact fields
******************************************************************/
-- drop views dependent (no changes)
DROP VIEW IF EXISTS _activity_contacts;

-- select * from contact
ALTER TABLE contact ALTER COLUMN _salutation TYPE character varying;
ALTER TABLE contact ALTER COLUMN _initial TYPE character varying;
ALTER TABLE contact ALTER COLUMN _last_name TYPE character varying;
ALTER TABLE contact ALTER COLUMN _title TYPE character varying;
ALTER TABLE contact ALTER COLUMN _address1 TYPE character varying;
ALTER TABLE contact ALTER COLUMN _address2 TYPE character varying;
ALTER TABLE contact ALTER COLUMN _city TYPE character varying;
ALTER TABLE contact ALTER COLUMN _state_providence  TYPE character varying;
ALTER TABLE contact ALTER COLUMN _postal_code  TYPE character varying;
ALTER TABLE contact ALTER COLUMN _country TYPE character varying;
ALTER TABLE contact ALTER COLUMN _direct_phone TYPE character varying;
ALTER TABLE contact ALTER COLUMN _mobile_phone TYPE character varying;
ALTER TABLE contact ALTER COLUMN _fax TYPE character varying;
ALTER TABLE contact ALTER COLUMN _email TYPE character varying;
ALTER TABLE contact ALTER COLUMN _url TYPE character varying;

-- recreate dependent views
CREATE OR REPLACE VIEW _activity_contacts AS 
 SELECT a.id AS activity_id,
    c.id AS contact_id,
    a.data_group_id,
    a._title,
    c._salutation,
    c._first_name,
    c._last_name
   FROM activity a
     LEFT JOIN activity_contact ac ON a.id = ac.activity_id
     JOIN contact c ON ac.contact_id = c.id
  ORDER BY a.id;


/******************************************************************
3. remove character limitations from contact fields
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_taxonomy() RETURNS SETOF pmt_json_result_type AS 
$$
DECLARE
  error_msg1 text;
  error_msg2 text;
  error_msg3 text;
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

  -- editing completed successfullly
  FOR rec IN (SELECT row_to_json(j) FROM(select c_id as id, 'Success' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
     
EXCEPTION WHEN others THEN
    GET STACKED DIAGNOSTICS error_msg1 = MESSAGE_TEXT,
                          error_msg2 = PG_EXCEPTION_DETAIL,
                          error_msg3 = PG_EXCEPTION_HINT;
    FOR rec IN (SELECT row_to_json(j) FROM(select c_id as id, 'Internal Error - Contact your DBA with the following error message: ' || error_msg1 as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;	  
END;$$ LANGUAGE plpgsql;


/******************************************************************
 3. new pmt_edit_financial_with_taxonomy for new data model
 select * from pmt_edit_financial_with_taxonomy(4,34,22970,null,'{"_amount":100.00}', ARRAY[1930,2200], false);
 select * from _activity_financials
  select * from _taxonomy_classifications
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_edit_financial_with_taxonomy(instance_id integer, user_id integer, activity_id integer, financial_id integer, key_value_data json, classification_ids int[], delete_record boolean default false) 
RETURNS SETOF pmt_json_result_type AS 
$$
DECLARE
  activity_record record;
  f_id integer;
  json record;
  column_record record;
  execute_statement text;
  invalid_editing_columns text[];
  username text;
  rec record;
  error_msg text;
BEGIN	
  -- simulate database error 
  -- FOR rec IN (SELECT row_to_json(j) FROM(select financial_id as id, 'Error: simulating a database error.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
  
  -- set columns that are not editable via the parameters 
  invalid_editing_columns := ARRAY['id', 'activity_id', '_active', '_retired_by', '_created_by', '_created_date', '_updated_by', '_updated_date'];
  
  -- instance_id is required for all operations
  IF ($1 IS NULL) THEN
    FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: instance_id is a required parameter for all operations.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
  END IF;
  -- user_id is required for all operations
  IF ($2 IS NULL) THEN
    FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: user_id is a required parameter for all operations.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
  END IF;
  -- activity_id is required for all operations
  IF ($3 IS NULL) THEN
    FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: activity_id is a required parameter for all operations.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
  ELSE
     -- validate the associated activity record
    IF (SELECT * FROM pmt_validate_activity($3)) THEN  
      SELECT INTO activity_record * FROM activity WHERE id = $3;
    ELSE
      FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: Invalid activity_id.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
    END IF;
  END IF;

  -- update/create operation
  IF NOT ($7) THEN
    -- json is required
    IF ($5 IS NULL) THEN
      FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: The json parameter is required for a create/update operation.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
    END IF;      
  -- delete operation	
  ELSE
    -- financial_id is requried
    IF ($4 IS NULL) THEN
      FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: financial_id is required for a delete operation.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
    END IF;
  END IF;

  -- get users name
  SELECT INTO username _username FROM users WHERE users.id = $2;

  -- validate users authority to update the activity record
  IF NOT (SELECT * FROM pmt_validate_user_authority($1, $2, activity_record.id, null, 'update')) THEN
    FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: User does NOT have authority to upadate/create a new financial record for activity id ' || activity_record.id as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
  END IF;  
    
  -- if financial_id is null then validate users authroity to create a new financial record  
  IF ($4 IS NULL) THEN   
    -- create new financial record for activity
    EXECUTE 'INSERT INTO financial(activity_id, _created_by, _updated_by) VALUES (' || activity_record.id || ',' || quote_literal(username) || ',' 
		|| quote_literal(username) || ') RETURNING id;' INTO f_id;
    RAISE NOTICE 'Created new financial with id: %', f_id;   
   IF array_length($6,1) > 0 THEN
     EXECUTE 'INSERT INTO financial_taxonomy (financial_id, classification_id, _field) SELECT '||f_id||',id,''id'' FROM classification WHERE id = ANY(ARRAY[' || array_to_string($6, ',') || '])';
   END IF;
  -- validate financial_id if provided and validate users authority to update an existing record  
  ELSE  
    -- validate financial_id
    IF (SELECT * FROM pmt_validate_financial($4)) THEN 
      f_id := $4;     
      -- 'delete' this financial record
      IF ($7) THEN
          EXECUTE 'DELETE FROM financial_taxonomy WHERE financial_id = ' || $4;
          EXECUTE 'DELETE FROM financial WHERE id = ' || $4;
      END IF;
    ELSE
      FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: Invalid financial_id.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
    END IF;
  END IF;
  
  -- loop through the columns of the financial table        
  FOR json IN (SELECT * FROM json_each_text($5)) LOOP
    RAISE NOTICE 'JSON key/value: %', lower(json.key) || ':' || json.value;
    -- get the column information for column that user is requesting to edit	
    FOR column_record IN (SELECT * FROM information_schema.columns WHERE table_schema='public' AND table_name='financial' AND column_name != ALL(invalid_editing_columns) AND lower(column_name) = lower(json.key)) LOOP 
      RAISE NOTICE 'Editing column: %', column_record.column_name;
      RAISE NOTICE 'Assigning new value: %', json.value;
      execute_statement := null;
      CASE column_record.data_type 
        WHEN 'integer', 'numeric' THEN              
          IF (SELECT pmt_isnumeric(json.value)) THEN
            execute_statement := 'UPDATE financial SET ' || column_record.column_name || ' = ' || json.value || ' WHERE id = ' || f_id; 
          END IF;
          IF (lower(json.value) = 'null') THEN
            execute_statement := 'UPDATE financial SET ' || column_record.column_name || ' = null WHERE id = ' || f_id; 
          END IF;
        ELSE
          -- if the value has the text null then assign the column value null
          IF (lower(json.value) = 'null') THEN
            execute_statement := 'UPDATE financial SET ' || column_record.column_name || ' = null WHERE id = ' || f_id; 
          ELSE
            execute_statement := 'UPDATE financial SET ' || column_record.column_name || ' = ' || quote_literal(json.value) || ' WHERE id = ' || f_id; 
          END IF;
      END CASE;
      IF execute_statement IS NOT NULL THEN
        RAISE NOTICE 'Statement: %', execute_statement;
        EXECUTE execute_statement;
                
        EXECUTE 'UPDATE financial SET _updated_by = ' || quote_literal(username) || ', _updated_date = ' || quote_literal(current_date) || ' WHERE  id = ' || f_id;
      END IF;
    END LOOP;
  END LOOP;
  -- editing completed successfullly
  FOR rec IN (SELECT row_to_json(j) FROM(select f_id as id, 'Success' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;         
  
EXCEPTION WHEN others THEN
     GET STACKED DIAGNOSTICS error_msg = MESSAGE_TEXT;
    FOR rec IN (SELECT row_to_json(j) FROM(select f_id as id, 'Internal Error - Contact your DBA with the following error message: ' || error_msg as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;	  
END;$$ LANGUAGE plpgsql;


/******************************************************************
4. update pmt_activities_all function to support api
   select * from pmt_activities_all('769', false); -- all activities active true & false
   select * from pmt_activities_all('769', true); -- active activities only
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_activities_all(data_group_ids character varying, only_active boolean) RETURNS SETOF pmt_json_result_type AS
$$
DECLARE
  dg_ids int[];
  data_group_ids int[];
  execute_statement text; 
  json record;   
  rec record;
  error_msg text;
BEGIN
  -- validate data group ids
  IF $1 IS NOT NULL THEN
    dg_ids:= string_to_array($1, ',')::int[];
    SELECT INTO data_group_ids array_agg(id) FROM classification WHERE taxonomy_id = 1 AND id = ANY(dg_ids);
  END IF;
  
  execute_statement:= 'SELECT a.id, a.data_group_id, a.parent_id, a._title, a._description, a._url, a._start_date, ' ||
			'a._end_date, a._iati_identifier,  ' ||
			'(SELECT array_agg(DISTINCT classification_id) FROM activity_taxonomy WHERE classification_id NOT IN (SELECT id FROM classification WHERE taxonomy_id IN (72,73,52,53)) AND activity_id = a.id) as c,  ' ||
			'(SELECT array_to_json(array_agg(row_to_json(c))) FROM (  ' ||
			'	select c._first_name || '' '' || c._last_name as n, c._email e, c._title as t, c._address1 as a, c._direct_phone as p  ' ||
			'	from activity_contact ac  ' ||
			'	join contact c on ac.contact_id = c.id   ' ||
			'	where c._active = true and ac.activity_id = a.id) c ' ||
			') as contacts, ' ||
			'(SELECT array_to_json(array_agg(row_to_json(f))) FROM (  ' ||
			'	select f.id, f._amount as a, (SELECT array_agg(DISTINCT classification_id) FROM financial_taxonomy WHERE id = f.id) as c  ' ||
			'	from financial f  ' ||
			'	where f._active = true and f.activity_id = a.id) f ' ||
			') as financials, ' ||
			'(SELECT array_to_json(array_agg(row_to_json(l))) FROM (  ' ||
			'	select l.id, l._admin0, l._admin1, l._admin2, l._admin_level  ' ||
			'	from location l  ' ||
			'	where l._active = true and l.activity_id = a.id) l  ' ||
			') as locations, ' ||
			'(SELECT array_to_json(array_agg(row_to_json(fnd))) FROM (  ' ||
			'	SELECT DISTINCT _name, _label  ' ||
			'	FROM _activity_participants  ' ||
			'	WHERE classification = ''Funding'' AND id = a.id) fnd ' ||
			') as funding, ' ||
			'(SELECT array_to_json(array_agg(row_to_json(fnd))) FROM (  ' ||
			'	SELECT DISTINCT _name, _label  ' ||
			'	FROM _activity_participants  ' ||
			'	WHERE classification = ''Implementing'' AND id = a.id) fnd ' ||
			') as implementing, ' ||
			'(SELECT array_to_json(array_agg(row_to_json(fnd))) FROM (  ' ||
			'	SELECT DISTINCT _name, _label  ' ||
			'	FROM _activity_participants  ' ||
			'	WHERE classification = ''Accountable'' AND id = a.id) fnd ' ||
			') as accountable ' ||
			'from activity a  ' ||
			'where parent_id is null ';

	IF data_group_ids IS NOT NULL THEN
		execute_statement:= execute_statement || 'AND data_group_id = ANY(ARRAY[' || array_to_string(data_group_ids, ',')  || ']) ';
	END IF;
	IF only_active THEN
		execute_statement:= execute_statement || 'AND _active = true ';
	END IF;

	
  RAISE NOTICE 'Execute statement: %', execute_statement;

  FOR rec IN EXECUTE 'SELECT row_to_json(j) FROM (' || execute_statement || ')j' LOOP
	RETURN NEXT rec;
  END LOOP;

EXCEPTION WHEN others THEN
  GET STACKED DIAGNOSTICS error_msg = MESSAGE_TEXT;
    RAISE NOTICE 'Internal Error - Contact your DBA with the following error message: %', error_msg;

END;$$ LANGUAGE plpgsql;

-- 
-- SELECT a.id, a.data_group_id, a.parent_id, a._title, a._description, a._url, a._start_date, 
-- a._end_date, a._iati_identifier, 
-- (SELECT array_agg(DISTINCT classification_id) FROM activity_taxonomy WHERE activity_id = a.id) as c, 
-- (SELECT array_to_json(array_agg(row_to_json(c))) FROM ( 
-- 	select c._first_name || ' ' || c._last_name as n, c._email e, c._title as t, c._address1 as a, c._direct_phone as p 
-- 	from activity_contact ac 
-- 	join contact c on ac.contact_id = c.id  
-- 	where c._active = true and ac.activity_id = a.id) c
-- ) as contacts,
-- (SELECT array_to_json(array_agg(row_to_json(f))) FROM ( 
-- 	select f.id, f._amount as a, (SELECT array_agg(DISTINCT classification_id) FROM financial_taxonomy WHERE id = f.id) as c 
-- 	from financial f 
-- 	where f._active = true and f.activity_id = a.id) f
-- ) as financials,
-- (SELECT array_to_json(array_agg(row_to_json(l))) FROM ( 
-- 	select l.id, l._admin0, l._admin1, l._admin2, l._admin_level 
-- 	from location l 
-- 	where l._active = true and l.activity_id = a.id) l 
-- ) as locations,
-- (SELECT array_to_json(array_agg(row_to_json(fnd))) FROM ( 
-- 	SELECT DISTINCT _name, _label 
-- 	FROM _activity_participants 
-- 	WHERE classification = 'Funding' AND id = a.id) fnd
-- ) as funding,
-- (SELECT array_to_json(array_agg(row_to_json(fnd))) FROM ( 
-- 	SELECT DISTINCT _name, _label 
-- 	FROM _activity_participants 
-- 	WHERE classification = 'Implementing' AND id = a.id) fnd
-- ) as implementing,
-- (SELECT array_to_json(array_agg(row_to_json(fnd))) FROM ( 
-- 	SELECT DISTINCT _name, _label 
-- 	FROM _activity_participants 
-- 	WHERE classification = 'Accountable' AND id = a.id) fnd
-- ) as accountable
-- from activity a 
-- where parent_id is null

