/******************************************************************
Change Script 3.0.10.89
1. Update _activity_taxonomies view to add parent_id fields.
2. Update function pmt_classifications to return associated child
classification if parent.
3. Updated pmt_users to fix order of fields in union, causing a 
  mismatch between phone and email.
4. Updated pmt_activity_detail to add organization taxonomy.
5. Create pmt_consolidate_orgs to allow combining/consolidations of 
organizations in to one organization.
6. Update pmt_edit_organization to fix issue with NULL's.
******************************************************************/
INSERT INTO version(_version, _iteration, _changeset) VALUES (3.0, 10, 89);
-- select * from version order by _iteration desc, _changeset desc;

/******************************************************************
1. Update _activity_taxonomies view to add parent_id fields
******************************************************************/
-- drop dependencies
DROP MATERIALIZED VIEW IF EXISTS _activity_family_taxonomies;
DROP VIEW IF EXISTS _activity_taxonomies;
CREATE OR REPLACE VIEW _activity_taxonomies AS 
 SELECT a.id,
    a.parent_id,
    a._title,
    a.data_group_id,
    dg.classification AS data_group,
    at._field,
    tc.taxonomy_id,
    tc.taxonomy,
    tc.taxonomy_parent_id,
    tc.classification_id,
    tc.classification,
    tc.classification_parent_id
   FROM activity a
     JOIN activity_taxonomy at ON a.id = at.activity_id
     JOIN _taxonomy_classifications tc ON at.classification_id = tc.classification_id
     LEFT JOIN _taxonomy_classifications dg ON a.data_group_id = dg.classification_id
  WHERE a._active = true
  ORDER BY a.id;

 -- recreate dependencies unchanged
CREATE MATERIALIZED VIEW _activity_family_taxonomies AS 
  SELECT af.parent_id, af.child_id, af._title, af.data_group_id, m.amount, t.taxonomy_id, t.taxonomy, t.classification_id, t.classification, t._field FROM 
  (SELECT * FROM _activity_family) af
  LEFT JOIN (SELECT id, sum(_amount) as amount FROM _activity_financials  
  WHERE (transaction_type IS NULL OR transaction_type = '' OR transaction_type IN ('Incoming Funds','Commitment'))
  GROUP BY 1) m
  ON af.parent_id = m.id
  LEFT JOIN (SELECT id, taxonomy_id, taxonomy, classification_id, classification, _field FROM _activity_taxonomies) t
  ON af.parent_id = t.id OR af.child_id = t.id;

  CREATE INDEX _activity_family_taxonomies_parent_id ON _activity_family_taxonomies (parent_id);
  CREATE INDEX _activity_family_taxonomies_child_id ON _activity_family_taxonomies (child_id);
  CREATE INDEX _activity_family_taxonomies_amount ON _activity_family_taxonomies (amount);
  CREATE INDEX _activity_family_taxonomies_taxonomy_id ON _activity_family_taxonomies (taxonomy_id);
  CREATE INDEX _activity_family_taxonomies_classification_id ON _activity_family_taxonomies (classification_id);


/******************************************************************
2. Update function pmt_classifications to return associated child
classification if parent
  select * from pmt_classifications(79, '2237', null, true);
  select * from pmt_classifications(79, null, null, true);
  select * from pmt_classifications(79, '2237', null, false);
******************************************************************/
DROP FUNCTION IF EXISTS pmt_classifications(integer, character varying, integer, boolean);
CREATE OR REPLACE FUNCTION pmt_classifications(taxonomy_id integer, data_group_ids character varying, instance_id integer, locations_only boolean) RETURNS SETOF pmt_json_result_type AS
$$
DECLARE
  valid_taxonomy record; 
  dg_ids int[];
  valid_dg_ids int[]; 
  rec record;
  execute_statement text;
  error_msg text;
BEGIN

  -- validate and process taxonomy_id parameter (required)
  IF $1 IS NOT NULL THEN
    -- validate the taxonomy id
    SELECT INTO valid_taxonomy * FROM taxonomy WHERE id = $1 AND _active = true;
    IF valid_taxonomy IS NULL THEN
      FOR rec IN SELECT row_to_json(j) FROM( SELECT 'missing valid required parameter' AS error ) as j LOOP RETURN NEXT rec; END LOOP;
    END IF;
  ELSE
    FOR rec IN SELECT row_to_json(j) FROM( SELECT 'missing required parameter' AS error ) as j LOOP RETURN NEXT rec; END LOOP;
  END IF;
  -- validate and process data_group_ids parameter
  IF $2 IS NOT NULL THEN
    dg_ids:= string_to_array($2, ',')::int[];
    -- validate the data groups id
    SELECT INTO valid_dg_ids array_agg(id)::int[] FROM classification c WHERE c.taxonomy_id = 1 AND _active=true AND id = ANY(dg_ids);
  ELSE
    IF $3 IS NOT NULL THEN
      SELECT INTO valid_dg_ids instance.data_group_ids FROM instance WHERE id = $3;
    END IF;
  END IF;

  -- if data groups are given return in-use classifications only
  IF array_length(valid_dg_ids, 1) > 0 THEN
    IF (valid_taxonomy._is_category) THEN
      execute_statement := 'SELECT at.classification_id as id, at.classification as c, count(DISTINCT at.parent_id) as ct,(SELECT array_to_json(array_agg(row_to_json(t))) FROM ( ' ||
	'	SELECT classification_id as id, classification as c, count(DISTINCT parent_id) as ct FROM _activity_taxonomies ' ||
	'	WHERE classification_parent_id = at.classification_id AND data_group_id = ANY(ARRAY[' || array_to_string(valid_dg_ids, ',') || ']) ';
      IF locations_only THEN
        execute_statement := execute_statement || 'AND id IN (SELECT activity_id FROM _location_lookup WHERE data_group_id = ANY(ARRAY[' || array_to_string(valid_dg_ids, ',') || '])) ';
      END IF;
      execute_statement := execute_statement || 'GROUP BY 1,2 )t ) as children ' ||
	 'FROM _activity_taxonomies at WHERE at.taxonomy_id = ' || $1 || 'AND data_group_id = ANY(ARRAY[' || array_to_string(valid_dg_ids, ',') || ']) ';
      IF locations_only THEN
        execute_statement := execute_statement || 'AND id IN (SELECT activity_id FROM _location_lookup WHERE data_group_id = ANY(ARRAY[' || array_to_string(valid_dg_ids, ',') || '])) ';
      END IF;
    ELSE
      execute_statement := 'SELECT classification_id as id, classification as c, count(DISTINCT id) as ct FROM _activity_taxonomies at WHERE at.taxonomy_id = ' || $1 || 
	' AND data_group_id = ANY(ARRAY[' || array_to_string(valid_dg_ids, ',') || ']) ';
      IF locations_only THEN
        execute_statement := execute_statement || 'AND id IN (SELECT activity_id FROM _location_lookup WHERE data_group_id = ANY(ARRAY[' || array_to_string(valid_dg_ids, ',') || '])) ';
      END IF;
    END IF;
    execute_statement := execute_statement || 'GROUP BY 1,2';
  -- otherwise return all classifications
  ELSE
    IF (valid_taxonomy._is_category) THEN
      execute_statement := 'SELECT classification_id as id, classification as c, null as ct,(SELECT array_to_json(array_agg(row_to_json(t))) FROM ( ' ||
	' SELECT classification_id as id, classification as c, null as ct FROM _taxonomy_classifications WHERE classification_parent_id = tc.classification_id )t ) as children ' ||
	' FROM _taxonomy_classifications tc  WHERE taxonomy_id = ' || $1;
    ELSE
      execute_statement := 'SELECT classification_id as id, classification as c, null as ct FROM _taxonomy_classifications tc WHERE tc.taxonomy_id = ' || $1;
    END IF;
END IF;
		
  RAISE NOTICE 'Execute statement: %', execute_statement;			

  FOR rec IN EXECUTE 'SELECT row_to_json(j) FROM (' || execute_statement || ')j' LOOP  		
	RETURN NEXT rec;
  END LOOP;
 
EXCEPTION WHEN others THEN 
  GET STACKED DIAGNOSTICS error_msg = MESSAGE_TEXT;  
    RAISE NOTICE 'Internal Error - Contact your DBA with the following error message: %', error_msg;
    
END;$$ LANGUAGE plpgsql;

/******************************************************************
  3. Updated pmt_users to fix order of fields in union, causing a 
  mismatch between phone and email.
  SELECT pmt_users(1);
*******************************************************************/
CREATE OR REPLACE FUNCTION pmt_users(instance_id integer) RETURNS SETOF pmt_json_result_type AS
$$
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
	SELECT u.id, u._first_name, u._last_name, u._username, u._email, u._phone, u.organization_id
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
  4. Updated pmt_activity_detail to add organization taxonomy.
  select * from pmt_activity_detail(29549);
  select * from activity;
*******************************************************************/
CREATE OR REPLACE FUNCTION pmt_activity_detail(activity_id integer) RETURNS SETOF pmt_json_result_type AS $$
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
				'select p.id as p_id, o.id, o._name, tc.classification_id, tc.classification, ' ||
					'cl._name as type, cl.id as type_id ' ||
				'from (select * from participation where _active = true and activity_id = ' || $1 || ') p  ' ||
  				'left join organization o ' ||
					'left outer join organization_taxonomy ot ' ||
						'left join classification cl ' ||
						'on ot.classification_id = cl.id ' ||
					'ON o.id = ot.organization_id ' ||
				'ON p.organization_id = o.id '  ||
  				'left join participation_taxonomy pt ON p.id = pt.participation_id '  ||
  				'left join _taxonomy_classifications tc ON pt.classification_id = tc.classification_id '  ||
				') p ) as organizations ';
				
    -- contacts
    execute_statement := execute_statement || ',(SELECT array_to_json(array_agg(row_to_json(c))) FROM ( ' ||
				'select c.id, c._first_name, c._last_name, c._email, c.organization_id, o._name ' ||
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
				'where ll.activity_id = ' || $1 || ' ' ||
				'group by ll.activity_id) l ' ||
				'on a.id = l.activity_id ';


  RAISE NOTICE 'Execute statement: %', execute_statement;			

  FOR rec IN EXECUTE 'SELECT row_to_json(j) FROM (' || execute_statement || ')j' LOOP  		
	RETURN NEXT rec;
  END LOOP;
END IF;

END;$$ LANGUAGE plpgsql;

/******************************************************************
  5. Create pmt_consolidate_orgs to allow combining/consolidations of 
     organizations in to one organization.
*******************************************************************/
CREATE OR REPLACE FUNCTION pmt_consolidate_orgs (user_id integer, organization_id_to_keep integer, organization_ids_to_consolidate integer[])
  RETURNS SETOF pmt_json_result_type AS $$
DECLARE
	requesting_user record;
	rec record;
	error_msg1 text;
	error_msg2 text;
	error_msg3 text;
BEGIN	

--RAISE NOTICE 'pmt_consolidate_orgs( user_id %, organization_id_to_keep %, organization_ids_to_consolidate % ',  user_id, organization_id_to_keep, organization_ids_to_consolidate;

-- user_id is required for all operations
IF (user_id IS NULL) THEN
	FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: user_id is a required parameter for all operations.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
END IF;

-- organization_id_to_keep is required for all operations
IF (organization_id_to_keep IS NULL) THEN
	FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: organization_id_to_keep is a required parameter for all operations.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
END IF;

-- organization_ids_to_consolidate integer[] is required for all operations
IF (organization_ids_to_consolidate IS NULL) THEN
	FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: An array of organization_ids is a required parameter for all operations.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
END IF;

-- orgs to consolidate must have at leat 1 rec
IF (array_length(organization_ids_to_consolidate,1) IS NULL) THEN
	FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: At least one Organization to consolidate must be passed to this function.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
END IF;

-- Check to see that the organization to keep is not listed in the ones to consolidate
IF (ARRAY[organization_id_to_keep] <@ organization_ids_to_consolidate) THEN
	FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: The organization to keep must not be part of the list or organizations to consolidate.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
END IF;


-- Get requesting users info
SELECT INTO requesting_user * FROM users WHERE id = $1;
IF requesting_user._username IS NULL THEN
	--RAISE NOTICE 'Provided user_id is not valid or does not have access to instance.';
	FOR rec IN (SELECT row_to_json(j) FROM (select null as id, 'Error: Provided user_id is not valid or does not have access to instance.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
END IF;


-- reassign all child recs

-- reassign contact
--RAISE NOTICE 'Updating Contacts';
UPDATE contact SET organization_id = organization_id_to_keep, _updated_by = requesting_user._username WHERE organization_id = ANY($3);

--RAISE NOTICE 'Updating Instance';
UPDATE instance 
	SET organization_id = organization_id_to_keep, _updated_by = requesting_user._username --, _active = false, _retired_by = user_id, ? 
	WHERE organization_id = ANY($3);

-- RAISE NOTICE 'Updating participation';
-- Reassign participation
-- Retire duplicate activities
UPDATE participation 
SET _active = false, _updated_by = requesting_user._username, _retired_by = user_id
WHERE 
	organization_id = ANY($3)
	AND _active = true
	AND activity_id IN (
		SELECT activity_id
		FROM participation 
		WHERE 
			organization_id = organization_id_to_keep
			AND _active = true
	)
;
-- Move missing activities aka all non duplicates
UPDATE participation 
SET organization_id = organization_id_to_keep, _updated_by = requesting_user._username 
WHERE 
	organization_id = ANY($3)
	AND _active = true
	AND activity_id NOT IN (
		SELECT activity_id
		FROM participation 
		WHERE 
			organization_id = organization_id_to_keep
			AND _active = true
	)
;

--RAISE NOTICE 'Updating organization_taxonomy';
-- reassign organization_taxonomy
-- remove duplicates fist
FOR rec IN
	-- all would be duplicates if organization_id merged
	SELECT c.organization_id, c.classification_id, c._field
	FROM organization_taxonomy AS c
		LEFT JOIN organization_taxonomy AS k
		ON c.classification_id = k.classification_id AND c._field = k._field
	WHERE 
		c.organization_id = ANY($3) 
		AND k.organization_id = organization_id_to_keep
	-- end dup sql
LOOP
	DELETE FROM organization_taxonomy WHERE _field = rec._field AND organization_id = rec.organization_id AND classification_id = rec.classification_id;
	--RAISE NOTICE 'ORGANIZATION_ID %, classification_id %, _field %', rec.organization_id, rec.classification_id, rec._field;	   
END LOOP;
   
-- update all non-duplicates to consolidated organization
UPDATE organization_taxonomy SET organization_id = organization_id_to_keep WHERE organization_id = ANY($3);



-- reassign users
--RAISE NOTICE 'Updating users';
UPDATE users 
	SET organization_id = organization_id_to_keep, _updated_by = requesting_user._username 
	WHERE organization_id = ANY($3);

-- reassign organization recs
--RAISE NOTICE 'Updating organization';
UPDATE organization 
	SET _active = false, _retired_by = requesting_user.id, _updated_by = requesting_user._username 
	WHERE id = ANY(organization_ids_to_consolidate);

--RAISE NOTICE 'Updating Complete';

-- Send Success response
FOR rec IN (SELECT row_to_json(j) FROM(select 'Success' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;

EXCEPTION WHEN others THEN
  GET STACKED DIAGNOSTICS error_msg1 = MESSAGE_TEXT,
                          error_msg2 = PG_EXCEPTION_DETAIL,                           
                          error_msg3 = PG_EXCEPTION_HINT;
FOR rec IN (SELECT row_to_json(j) FROM(select 'Internal Error - organization your DBA with the following error message: ' || error_msg1 as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;	  

END;$$ LANGUAGE plpgsql; 

/******************************************************************
  6. Update pmt_edit_organization to fix issue with NULL's
*******************************************************************/
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
invalid_editing_columns := ARRAY['id', '_active', '_retired_by', '_created_by', '_created_date', '_updated_by', '_updated_date'];
  

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
					IF json.value IS NULL THEN
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
	FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: User does NOT have authority to create a new organization.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
END IF;

-- Send Success response
FOR rec IN (SELECT row_to_json(j) FROM(select o_id as id, 'Success' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
   
EXCEPTION WHEN others THEN
    GET STACKED DIAGNOSTICS error_msg1 = MESSAGE_TEXT,
                          error_msg2 = PG_EXCEPTION_DETAIL,
                          error_msg3 = PG_EXCEPTION_HINT;
    FOR rec IN (SELECT row_to_json(j) FROM(select o_id as id, 'Internal Error - organization your DBA with the following error message: ' || error_msg1 as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;	  
END;$$ LANGUAGE plpgsql; 


-- update permissions
GRANT USAGE ON SCHEMA public TO pmt_read;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO pmt_read;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO pmt_read;
GRANT USAGE ON SCHEMA public TO pmt_write;
GRANT SELECT,INSERT ON ALL TABLES IN SCHEMA public TO pmt_write;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO pmt_write;