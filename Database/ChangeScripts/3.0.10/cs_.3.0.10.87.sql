/******************************************************************
Change Script 3.0.10.87
1. create pmt_boundary_search to allow text search of pmt boundaries
2. update pmt_edit_organization to new data model
3. update pmt_orgs to include _url
4. update table users to add column _phone
5. update pmt_users() to return _phone
6. update pmt_users (overloaded method) to return _phone
7. update pmt_find_users to return _phone
******************************************************************/
INSERT INTO version(_version, _iteration, _changeset) VALUES (3.0, 10, 87);
-- select * from version order by _iteration desc, _changeset desc;

/******************************************************************
1. create pmt_boundary_search to allow text search of pmt boundaries
   select * from pmt_boundary_search( 'gadm','libolo' );
   select * from pmt_boundary_search( 'gaul','eta' );
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_boundary_search(boundary_type character varying, search_string character varying) RETURNS SETOF pmt_json_result_type AS 
$$
DECLARE
valid_boundary_type character varying;
boundary_tables text[];          -- Array of tables use in search
boundary_table text;             -- Used in looping through Array of tables
boundary_table_columns text[];   -- Used to hold array of all '%_name%' columns
boundary_table_column text;      -- Used in looping through array of column names
boundary_table_idx integer;      -- Index of current table in the tables array
column_names text Array[4];      -- Array of column names to use for the boundary levels 
column_name text;                -- Used in looping through the column_name array
column_count integer;            -- Index of current column loop
column_str text;                 -- String buffer used to build up the column names for the Select
column_name_idx integer;         -- Index of current column name loop
execute_statement text;          -- String buffer used to build up the Select statements
rec record;                      -- Used to build up the JSON return recs
error_msg text;                  -- Error text
BEGIN
-- init array of virtual column names to use
SELECT INTO column_names string_to_array('b0,b1,b2,b3', ',') as cn;

-- validate and process boundary_type parameter
IF $1 IS NOT NULL THEN
	-- validate the boundary type
	SELECT INTO valid_boundary_type DISTINCT _type FROM boundary WHERE _type = $1 AND _active = true;
	IF valid_boundary_type IS NULL THEN
		FOR rec IN SELECT row_to_json(j) FROM( SELECT 'missing valid required parameter' AS error ) as j LOOP RETURN NEXT rec; END LOOP;
	END IF;
ELSE
	FOR rec IN SELECT row_to_json(j) FROM( SELECT 'missing required parameter: boundary_type' AS error ) as j LOOP RETURN NEXT rec; END LOOP;
END IF;

-- validate Search Text parameter
IF $2 IS NULL THEN
	FOR rec IN SELECT row_to_json(j) FROM( SELECT 'missing required parameter: search_text' AS error ) as j LOOP RETURN NEXT rec; END LOOP;
END IF;

-- get table names for this boundary type
SELECT INTO boundary_tables array_agg(_spatial_table::text) FROM (SELECT _spatial_table FROM boundary WHERE _type = valid_boundary_type ORDER BY _admin_level ) as b;

-- begin execution statement
-- init loop
execute_statement := '';  -- final SQL to execute
boundary_table_idx := 1;  -- idx of current boundary table, used in loop
column_count := 1;        -- current column idx, used in loop
column_str := '';         -- work string used for building up columns for the SQL
FOREACH boundary_table IN ARRAY boundary_tables LOOP
	--RAISE NOTICE 'Boundary_Table: %', boundary_table;

	-- Get Column Names for this table
	SELECT INTO boundary_table_columns array_agg(attname::text) FROM(
		SELECT c.relname, a.attname
		FROM pg_class as c
		INNER JOIN pg_attribute AS a ON a.attrelid = c.oid
		WHERE c.relname = boundary_table
		AND a.attname <> '_name'
		AND a.attname like '%name%'
		AND c.relkind = 'r'
		ORDER BY c.relname, a.attname
	) as bc;

	column_name_idx := 1; 
	column_count:=1; -- init column cntr
	IF boundary_table_columns IS NOT NULL THEN  
		-- Loop through all tables building up each SQL used in the UNION
		BEGIN

		-- build up the column names for parent nodes
		FOREACH boundary_table_column IN ARRAY boundary_table_columns LOOP
			SELECT INTO column_name column_names[column_name_idx];
			column_str := column_str || boundary_table_column || ' AS ' || column_name || ', ';
			--RAISE NOTICE '1 column_str: %', column_str;

			column_name_idx := column_name_idx + 1;
			column_count := column_count + 1;
		END LOOP;

		-- build current node
		IF column_name_idx <= array_upper(column_names,1) THEN
			SELECT INTO column_name column_names[column_name_idx];
			column_str := column_str || '_name AS ' || column_name || ', ';
			--RAISE NOTICE '2 column_str: %', column_str;
		END IF;

		END;

	ELSE -- if there are no parent columns add _name
		-- build column for this node. This node has no parent
		column_str := column_str || '_name AS ' || column_names[column_name_idx] || ', ';
		--RAISE NOTICE '3 column_str: %', column_str;
	END IF;

	-- add in additional columns to fill out the SQL such that the UNION works correctly.
	column_name_idx:= column_name_idx +1;
	WHILE column_name_idx < 5 LOOP
		SELECT INTO column_name column_names[column_name_idx];
		column_str := column_str || ' ''''::text AS ' || column_name || ', ';
		--RAISE NOTICE '4 column_str: %', column_str;

		column_name_idx:= column_name_idx +1;
	END LOOP; 

	-- add UNION if necessary (every one execpt the 1st)
	IF boundary_table_idx <> 1 THEN
		execute_statement := execute_statement || ' UNION ';
	END IF;

	-- build up the SQL for this table
	execute_statement := execute_statement || 'SELECT * FROM ' || 
		'(SELECT ' || column_str || ' ''' || boundary_table || ''' as table_name, id, _polygon FROM ' || boundary_table || ' ) as boundry_tbl ' ||
		'WHERE ' ||
		'    lower(b0) like ''%' || lower($2) || '%''' || 
		' OR lower(b1) like ''%' || lower($2) || '%''' || 
		' OR lower(b2) like ''%' || lower($2) || '%''' || 
		' OR lower(b3) like ''%' || lower($2) || '%''  ';

	column_str := '';
	--RAISE NOTICE '5 execute_statement: %', execute_statement;
	boundary_table_idx := boundary_table_idx + 1;
END LOOP; -- boundary_table IN ARRAY boundary_tables

-- concat searches, add in the call to get Geometry Envelope and preform SQL
execute_statement := 'SELECT b0,b1,b2,b3, table_name, id, Box2D(_polygon) as bounds FROM 
		( ' ||  execute_statement || ') AS all_names ' ||
	' ORDER BY b0, b1, b2, b3';

--RAISE NOTICE 'Execute Statement: %1', execute_statement;

FOR rec IN EXECUTE 'SELECT row_to_json(j) FROM (' || execute_statement || ')j' LOOP
	RETURN NEXT rec;
END LOOP;

EXCEPTION WHEN others THEN
	GET STACKED DIAGNOSTICS error_msg = MESSAGE_TEXT;
RAISE NOTICE 'Internal Error - Contact your DBA with the following error message: %', error_msg;

END;$$ LANGUAGE plpgsql; 

/******************************************************************
2. update pmt_edit_organization to new data model

  -- test (role:super crud:update) PASS
  SELECT * FROM pmt_edit_organization(1,34,13,'{"_address1":"testing address edit"}',false);
  -- test (role:editor crud:update) PASS
  SELECT * FROM pmt_edit_organization(1,288,13,'{"_address1":"testing address edit"}',false);
  -- test (role:reader crud:update) PASS
  SELECT * FROM pmt_edit_organization(1,275,13,'{"_address1":"testing address edit"}',false);
  -- test (role:admin crud:create) PASS
  SELECT * FROM pmt_edit_organization(1,287,null,'{"_name":"Test Organization", "_label":"TestOrg"}',false);
  -- test (role:admin crud:delete) PASS
  SELECT * FROM pmt_edit_organization(1,287,3471,null,true);
  -- test (role:super crud:update bad field names) PASS
  SELECT * FROM pmt_edit_organization(1,34,13,'{"address1":"testing edit to invalid field"}',false);

select * from _user_instances
select * from organization where id = 13
******************************************************************/
DROP FUNCTION IF EXISTS pmt_edit_organization(integer, integer, json, boolean);
CREATE OR REPLACE FUNCTION pmt_edit_organization(instance_id integer, user_id integer, organization_id integer, key_value_data json, delete_record boolean DEFAULT false)
  RETURNS SETOF pmt_json_result_type AS $$
DECLARE
	new_organization_id integer;
	o_id integer;
	json record;
	column_record record;
	execute_statement text;
	invalid_editing_columns text[];
	user_name text;
	rec record;
	requesting_users_instance record;
	users_role text;
	error_msg1 text;
	error_msg2 text;
	error_msg3 text;
BEGIN	

--RAISE NOTICE 'pmt_edit_organization(instance_id %, user_id %, organization_id %, key_value_data %, delete_record %', instance_id, user_id, organization_id, key_value_data, delete_record;

-- set columns that are not editable via the parameters 
invalid_editing_columns := ARRAY['id', '_active', '_retired_by', 'iati_import_id','_created_by', '_created_date', '_updated_by', '_updated_date'];
  
-- instance_id is required for all operations
IF ($1 IS NULL) THEN
  FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: instance_id is a required parameter for all operations.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
END IF;
-- user_id is required for all operations
IF ($2 IS NULL) THEN
  FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: user_id is a required parameter for all operations.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
END IF;
-- data parameters are required
IF NOT ($5) AND ($4 IS NULL) THEN
  FOR rec IN (SELECT row_to_json(j) FROM (select null as id, 'Error: Must included json parameter when delete_record is false.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
END IF;
-- Org id is valid if present
IF ($3 IS NOT NULL) AND (SELECT * FROM pmt_validate_organization($3))='f' THEN
	FOR rec IN (SELECT row_to_json(j) FROM (select null as id, 'Error: Invalid organization id.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
END IF;


-- Get requesting users info
SELECT INTO requesting_users_instance * FROM _user_instances WHERE _user_instances.user_id = $2 AND _user_instances.instance_id = $1;
IF requesting_users_instance.user_id IS NULL THEN
	--RAISE NOTICE 'Provided user_id is not valid or does not have access to instance.';
	FOR rec IN (SELECT row_to_json(j) FROM (select null as id, 'Error: Provided user_id is not valid or does not have access to instance.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
END IF;

-- If Authorized
IF (SELECT _security FROM role WHERE id = requesting_users_instance.role_id) THEN
	-- User authorized
	--RAISE NOTICE 'User % is Authorized', requesting_users_instance.username;

	-- Handle Add
	IF ($3 IS NULL) THEN
		EXECUTE 'INSERT INTO organization(_name, _created_by, _updated_by) VALUES ( ''NEW ORGANIZATION'', ' || quote_literal(requesting_users_instance.username) || ',' || quote_literal(requesting_users_instance.username) || ') RETURNING id;' INTO new_organization_id;
		--RAISE NOTICE 'Created new organization with id: %', new_organization_id;
	END IF;
	-- Handle Delete/Deactivate
	IF ($5) AND ($3 IS NOT NULL) THEN
		EXECUTE 'UPDATE organization SET _active = false, _retired_by =  ' || quote_literal(requesting_users_instance.user_id) || ' WHERE organization.id = ' || $3;
		--RAISE NOTICE 'Maked organization with id: % as INACTIVE', $3;
	END IF;

	IF new_organization_id IS NOT NULL THEN
		o_id := new_organization_id;
	ELSE
		o_id := $3;
	END IF;

	--RAISE NOTICE 'o_id = %', o_id;

	-- loop through the columns of the organization table and build up Update SQL
	FOR json IN (SELECT * FROM json_each_text($4)) LOOP
		--RAISE NOTICE 'JSON key/value: %', lower(json.key) || ':' || json.value;

		FOR column_record IN (SELECT * FROM information_schema.columns WHERE table_schema='public' AND table_name='organization' AND column_name != ALL(invalid_editing_columns) AND lower(column_name) = lower(json.key)) LOOP 
			--RAISE NOTICE 'Editing column: %', column_record.column_name;
			--RAISE NOTICE 'Assigning new value: %', json.value;

			execute_statement := null;
			CASE column_record.data_type 
				WHEN 'integer', 'numeric' THEN              
					IF (SELECT pmt_isnumeric(json.value)) THEN
						execute_statement := 'UPDATE organization SET ' || column_record.column_name || ' = ' || json.value || ' WHERE id = ' || o_id; 
					END IF;
					
					IF (lower(json.value) = 'null') THEN
						execute_statement := 'UPDATE organization SET ' || column_record.column_name || ' = null WHERE id = ' || o_id; 
					END IF;
				ELSE
				-- if the value has the text null then assign the column value null
					IF (lower(json.value) = 'null') THEN
						execute_statement := 'UPDATE organization SET ' || column_record.column_name || ' = null WHERE id = ' || o_id; 
					ELSE
						execute_statement := 'UPDATE organization SET ' || column_record.column_name || ' = ' || quote_literal(json.value) || ' WHERE id = ' || o_id; 
					END IF;
			END CASE;

			IF execute_statement IS NOT NULL THEN
				--RAISE NOTICE 'execute_statement: %', execute_statement;
				EXECUTE execute_statement;
				EXECUTE 'UPDATE organization SET _updated_by = ' || quote_literal(requesting_users_instance.username) || ', _updated_date = ' || quote_literal(current_date) || ' WHERE  id = ' || o_id;
			END IF;
		END LOOP;  -- END COLUMNS LOOP
	END LOOP; -- END JSON LOOP
ELSE
	-- User NOT Authorized
	FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: User does NOT have authority to edit an organization.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
END IF;

-- Send Success response
FOR rec IN (SELECT row_to_json(j) FROM(select o_id as id, 'Success' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
   
EXCEPTION WHEN others THEN
    GET STACKED DIAGNOSTICS error_msg1 = MESSAGE_TEXT,
                          error_msg2 = PG_EXCEPTION_DETAIL,
                          error_msg3 = PG_EXCEPTION_HINT;
    FOR rec IN (SELECT row_to_json(j) FROM(select o_id as id, 'Internal Error - organization your DBA with the following error message: ' || error_msg1 as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;	  
END;$$ LANGUAGE plpgsql; 

/******************************************************************
3. update pmt_orgs to include _url
   SELECT * FROM pmt_orgs();
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_orgs() RETURNS SETOF pmt_json_result_type AS $$
DECLARE 
  rec record;
BEGIN 
  FOR rec IN (
	SELECT row_to_json(j) FROM( 
	SELECT id, _name, _label, _url
	FROM organization
	WHERE _active = true
	) j 
    ) LOOP		
    RETURN NEXT rec;
  END LOOP;			  
END;$$ LANGUAGE plpgsql; 


/******************************************************************
4. update users to add column _phone
   SELECT * FROM users;
******************************************************************/
ALTER TABLE users ADD COLUMN _phone CHARACTER VARYING;

/******************************************************************
5. update pmt_users() to return _phone
  SELECT * FROM pmt_users();
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_users() RETURNS SETOF pmt_json_result_type AS $$
DECLARE 
  rec record;
BEGIN 
  FOR rec IN (
    SELECT row_to_json(j) FROM( 
	SELECT u.id, u._first_name, u._last_name, u._username, u._email, u._phone
	,u.organization_id
	,(SELECT _name FROM organization WHERE id = u.organization_id) as organization
	,(SELECT array_to_json(array_agg(row_to_json(ui))) FROM (SELECT instance_id, instance, role_id, role FROM _user_instances WHERE user_id = u.id) as ui) as instances
	,(SELECT _access_date from user_log where user_id = u.id order by _access_date desc LIMIT 1)
	,u._active
	FROM (SELECT * FROM users WHERE _username <> 'public') u
	) j 
  ) LOOP		
    RETURN NEXT rec;
  END LOOP;			  
END;$$ LANGUAGE plpgsql; 

/******************************************************************
6. update pmt_users (overloaded method) to return _phone
  SELECT * FROM pmt_users(1);
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_users(instance_id integer) RETURNS SETOF pmt_json_result_type AS $$
DECLARE 
  rec record;
  error_msg text;
BEGIN
  -- validate required parameter
  IF $1 IS NULL THEN
    FOR rec IN (SELECT row_to_json(j) FROM( SELECT 'Instance id is a required parameter.' AS message ) j ) LOOP		
        RETURN NEXT rec;
    END LOOP;
  END IF;
   
  FOR rec IN (
    SELECT row_to_json(j) FROM( 
	-- get authorizations for Editors (only valid role for authorizations)
	SELECT u.id, u._first_name, u._last_name, u._username, u._email, u._phone, u.organization_id
	,(SELECT _name FROM organization WHERE id = u.organization_id) as organization
	, r.id as role_id, r._name as role
	,(SELECT row_to_json(a) FROM ( 
		SELECT (SELECT array_agg(activity_id) as activity_ids
		FROM (SELECT * FROM user_activity WHERE _active = true AND activity_id IS NOT NULL) ua
		JOIN activity a
		ON ua.activity_id = a.id			
		WHERE ua.user_id = u.id AND ARRAY[a.data_group_id] <@ (SELECT data_group_ids FROM instance WHERE id = $1)) as activity_ids,
		(SELECT array_agg(classification_id) as classification_ids
		FROM user_activity 
		WHERE _active = true AND classification_id IS NOT NULL AND user_id = u.id) as classification_ids
	) a ) as authorizations
	,(SELECT array_to_json(array_agg(row_to_json(tax))) FROM (	
		SELECT taxonomy_id as t_id, taxonomy as t, (SELECT array_to_json(array_agg(row_to_json(tc))) FROM (
			SELECT classification_id as c_id, classification as c
			FROM _taxonomy_classifications
			WHERE taxonomy_id = tc.taxonomy_id
			AND classification_id IN (SELECT classification_id FROM user_activity 
						WHERE _active = true AND classification_id IS NOT NULL AND user_id = u.id)
			) tc ) as c
		FROM  _taxonomy_classifications tc
		WHERE classification_id IN (SELECT classification_id FROM user_activity 
						WHERE _active = true AND classification_id IS NOT NULL AND user_id = u.id)
		GROUP BY 1,2
		ORDER BY 1
	 ) tax ) as classifications  
	,(SELECT _access_date from user_log where user_id = u.id order by _access_date desc LIMIT 1)
	,u._active	
	FROM (SELECT * FROM user_instance ui WHERE ui.instance_id = $1) ui
	JOIN (SELECT * FROM users WHERE _username <> 'public')  u
	ON ui.user_id = u.id
	JOIN (SELECT * FROM role WHERE _name = 'Editor') r
	ON ui.role_id = r.id
	UNION ALL
	-- get authorizations for Administrator/Super (all activities in data group(s) for instance)
	SELECT u.id, u._first_name, u._last_name, u._username, u._email, u._phone, u.organization_id
	,(SELECT _name FROM organization WHERE id = u.organization_id) as organization
	, r.id as role_id, r._name as role
	,(SELECT row_to_json(a) FROM ( 
			SELECT (SELECT array_agg(id) as activity_ids
			FROM activity a		
			WHERE ARRAY[a.data_group_id] <@ (SELECT data_group_ids FROM instance WHERE id = $1)) as activity_ids,
			(SELECT null as classification_ids) as classification_ids
			) a ) as authorizations
	,null as classifications
	,(SELECT _access_date from user_log where user_id = u.id order by _access_date desc LIMIT 1)
	,u._active	
	FROM (SELECT * FROM user_instance ui WHERE ui.instance_id = $1) ui
	JOIN (SELECT * FROM users WHERE _username <> 'public')  u
	ON ui.user_id = u.id
	JOIN (SELECT * FROM role WHERE _name IN ('Administrator','Super')) r
	ON ui.role_id = r.id
	UNION ALL
	-- get authorizations for Reader (no authorizations)
	SELECT u.id, u._first_name, u._last_name, u._username, u._phone, u._email, u.organization_id
	,(SELECT _name FROM organization WHERE id = u.organization_id) as organization
	, r.id as role_id, r._name as role
	,(SELECT row_to_json(a) FROM ( 
			SELECT (SELECT null as activity_ids) as activity_ids,
			(SELECT null as classification_ids) as classification_ids
			) a ) as authorizations
	,null as classifications
	,(SELECT _access_date from user_log where user_id = u.id order by _access_date desc LIMIT 1)
	,u._active	
	FROM (SELECT * FROM user_instance ui WHERE ui.instance_id = $1) ui
	JOIN (SELECT * FROM users WHERE _username <> 'public')  u
	ON ui.user_id = u.id
	JOIN (SELECT * FROM role WHERE _name = 'Reader') r
	ON ui.role_id = r.id
	) j 
  ) LOOP		
    RETURN NEXT rec;
  END LOOP;	
END;$$ LANGUAGE plpgsql; 


/******************************************************************
7. update pmt_find_users to return _phone
  SELECT * FROM pmt_find_users('shawna','paradee','sparadee@spatialdev.com');
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_find_users(first_name character varying, last_name character varying, email character varying)
  RETURNS SETOF pmt_json_result_type AS $$
DECLARE 
  execute_statement text;
  rec record;
  error_msg text;
BEGIN 
	
  IF ($1 IS NULL) OR ($2 IS NULL) OR ($3 IS NULL) THEN
    FOR rec IN (SELECT row_to_json(j) FROM(SELECT 'Error: All parameters are required.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
  END IF;
  
  execute_statement := 'SELECT u.id, u._first_name, u._last_name, u._username, u._email, u._phone, u.organization_id ' ||
	',(SELECT _name FROM organization WHERE id = u.organization_id) as organization ' ||
	',(SELECT array_to_json(array_agg(row_to_json(ui))) FROM (SELECT instance_id, instance, role_id, role FROM _user_instances WHERE user_id = u.id) as ui) as instances ' ||
	',(SELECT _access_date from user_log where user_id = u.id order by _access_date desc LIMIT 1) ' ||
	',u._active ' ||
	'FROM users u '
	'WHERE lower(_first_name) LIKE ' || quote_literal(lower($1)) || ' OR lower(_last_name) LIKE ' || quote_literal(lower($2)) || ' OR lower(_email) LIKE ' || quote_literal(lower($3));
	
  RAISE NOTICE 'Execute statement: %', execute_statement;			

  FOR rec IN EXECUTE 'SELECT row_to_json(j) FROM (' || execute_statement || ')j' LOOP  		
    RETURN NEXT rec;
  END LOOP;

  EXCEPTION WHEN others THEN 
  GET STACKED DIAGNOSTICS error_msg = MESSAGE_TEXT;  
    RAISE NOTICE 'Internal Error - Contact your DBA with the following error message: %', error_msg;
 END;$$ LANGUAGE plpgsql; 

  
