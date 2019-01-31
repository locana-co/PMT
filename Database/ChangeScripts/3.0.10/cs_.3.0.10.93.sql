/******************************************************************
Change Script 3.0.10.93
1. update pmt_validate_detail to adhere to new data model
2. update pmt_edit_detail to adhere to new data model
3. update pmt_stat_activity_by_tax to addrss bug in classification
filter.
4. update pmt_consolidate_orgs to follow PMT requirements and add
missing entity updates.
******************************************************************/
INSERT INTO version(_version, _iteration, _changeset) VALUES (3.0, 10, 93);
-- select * from version order by _iteration desc, _changeset desc;

/******************************************************************
1. update pmt_validate_detail to adhere to new data model
  select * from detail;
  select * from pmt_validate_detail(1);
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_validate_detail(id integer) RETURNS boolean AS $$
DECLARE valid_id integer;
BEGIN 
     IF $1 IS NULL THEN    
       RETURN false;
     END IF;    
     
     SELECT INTO valid_id detail.id FROM detail WHERE _active = true AND detail.id = $1;	 

     IF valid_id IS NULL THEN
      RETURN false;
     ELSE 
      RETURN true;
     END IF;
     
EXCEPTION WHEN others THEN
    RETURN FALSE;
END; 
$$ LANGUAGE plpgsql;

 /******************************************************************
2. update pmt_edit_detail to adhere to new data model
  select * from (select id, _title from activity) a join detail d on a.id = d.activity_id order by 1,3
  select * from pmt_edit_detail(1, 34, 29548, null, '{"_title": "changeling"}', false); -- add
  select * from pmt_edit_detail(1, 34, 29548, 1845, '{"_title": "a whole new world"}', false); -- edit
  select * from pmt_edit_detail(1, 34, 29548, 1845, null, true); -- delete
  select * from pmt_edit_detail(1, 34, null, 1845, null, true); -- required param
  select * from pmt_edit_detail(1, 34, 29548, null, null, true); -- required param
  select * from pmt_edit_detail(1, 34, 29548, null, null, false); -- required param
  select * from pmt_edit_detail(1, 34, 29548, 99999, null, true); -- invalid param
******************************************************************/
DROP FUNCTION IF EXISTS pmt_edit_detail(integer, integer, integer, integer, json, boolean);
CREATE OR REPLACE FUNCTION pmt_edit_detail(instance_id integer, user_id integer, activity_id integer, detail_id integer, key_value_data json, delete_record boolean DEFAULT false)
RETURNS SETOF pmt_json_result_type AS 
$$
DECLARE
  d_id integer;
  json record;
  activity_record record;
  column_record record;
  execute_statement text;
  invalid_editing_columns text[];
  username text;
  rec record;
  error_msg1 text;
  error_msg2 text;
  error_msg3 text;
BEGIN	
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
  IF NOT ($6) THEN
    -- json is required
    IF ($5 IS NULL) THEN
      FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: The json parameter is required for a create/update operation.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
    END IF;      
  -- delete operation	
  ELSE
    -- detail_id is requried
    IF ($4 IS NULL) THEN
      FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: detail_id is required for a delete operation.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
    END IF;
  END IF;

    -- get users name
  SELECT INTO username _username FROM users WHERE users.id = $2;

  -- validate users authority to update the activity record
  IF NOT (SELECT * FROM pmt_validate_user_authority($1, $2, activity_record.id, null, 'update')) THEN
    FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: User does NOT have authority to upadate/create a new financial record for activity id ' || activity_record.id as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
  END IF;

  -- if detail_id is null then create a new detail record  
  IF ($4 IS NULL) THEN
    -- create new detail record for activity
    EXECUTE 'INSERT INTO detail(activity_id, _created_by, _updated_by) VALUES (' || activity_record.id || ',' || quote_literal(username) || ',' 
		|| quote_literal(username) || ') RETURNING id;' INTO d_id;
    RAISE NOTICE 'Created new detail with id: %', d_id; 
  -- validate detail_id if provided and validate users authority to update an existing record  
  ELSE  
    -- validate detail_id
    IF (SELECT * FROM pmt_validate_detail($4)) THEN 
      d_id:= $4;
      -- 'delete' this detail record
      IF ($6) THEN
          EXECUTE 'DELETE FROM detail_taxonomy WHERE detail_id = ' || $4;
          EXECUTE 'DELETE FROM detail WHERE id = ' || $4;
      END IF;
    ELSE
      FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: Invalid detail_id.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
    END IF;
  END IF;
    
  -- loop through the columns of the detail table        
  FOR json IN (SELECT * FROM json_each_text($5)) LOOP
    RAISE NOTICE 'JSON key/value: %', lower(json.key) || ':' || json.value;
    -- get the column information for column that user is requesting to edit	
    FOR column_record IN (SELECT * FROM information_schema.columns WHERE table_schema='public' AND table_name='detail' AND column_name != ALL(invalid_editing_columns) AND lower(column_name) = lower(json.key)) LOOP 
      RAISE NOTICE 'Editing column: %', column_record.column_name;
      RAISE NOTICE 'Assigning new value: %', json.value;
      execute_statement := null;
      CASE column_record.data_type 
        WHEN 'integer', 'numeric' THEN              
          IF (SELECT pmt_isnumeric(json.value)) THEN
            execute_statement := 'UPDATE detail SET ' || column_record.column_name || ' = ' || json.value || ' WHERE id = ' || d_id; 
          END IF;
          IF (lower(json.value) = 'null') THEN
            execute_statement := 'UPDATE detail SET ' || column_record.column_name || ' = null WHERE id = ' || d_id; 
          END IF;
        ELSE
          -- if the value has the text null then assign the column value null
          IF (lower(json.value) = 'null') THEN
            execute_statement := 'UPDATE detail SET ' || column_record.column_name || ' = null WHERE id = ' || d_id; 
          ELSE
            execute_statement := 'UPDATE detail SET ' || column_record.column_name || ' = ' || quote_literal(json.value) || ' WHERE id = ' || d_id; 
          END IF;
      END CASE;
      IF execute_statement IS NOT NULL THEN
        RAISE NOTICE 'Statement: %', execute_statement;
        EXECUTE execute_statement;
                
        EXECUTE 'UPDATE detail SET _updated_by = ' || quote_literal(username) || ', _updated_date = ' || quote_literal(current_date) || ' WHERE  id = ' || d_id;
      END IF;
    END LOOP;
  END LOOP;
  -- editing completed successfullly
  FOR rec IN (SELECT row_to_json(j) FROM(select d_id as id, 'Success' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;         
  
EXCEPTION WHEN others THEN
     GET STACKED DIAGNOSTICS error_msg1 = MESSAGE_TEXT,
                          error_msg2 = PG_EXCEPTION_DETAIL,
                          error_msg3 = PG_EXCEPTION_HINT;
    FOR rec IN (SELECT row_to_json(j) FROM(select d_id as id, 'Internal Error - Contact your DBA with the following error message: ' || error_msg1 as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;	  
END;$$ LANGUAGE plpgsql;


/******************************************************************
3. update pmt_stat_activity_by_tax to addrss bug in classification
filter.
   select * from pmt_stat_activity_by_tax(79,'2237',null,null,null,15,74,null);
   select * from pmt_stat_activity_by_tax(79,'2237',null,null,null,15,74,5); 
   select * from pmt_stat_activity_by_tax(79,'2237','2475,2480',null,null,15,74,null);
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_stat_activity_by_tax(taxonomy_id integer, data_group_ids character varying, classification_ids character varying, 
start_date date, end_date date, boundary_id integer, feature_id integer, record_limit integer) RETURNS SETOF pmt_json_result_type AS
$$
DECLARE
  dg_ids int[];
  c_ids int[];
  valid_dg_ids int[];
  valid_c_ids int[];
  valid_taxonomy_id integer; 
  valid_boundary_id integer;
  valid_feature_id integer; 
  spatial_table text;
  filtered_activity_ids int[];
  feature_activity_ids int[];
  execute_statement text; 
  where_statement text;
  rec record;
  error_msg text;
BEGIN

  -- validate and process taxonomy_id parameter
  IF $1 IS NOT NULL THEN
    -- validate the taxonomy id
    SELECT INTO valid_taxonomy_id id FROM taxonomy WHERE id = $1 AND _active = true;
    IF valid_taxonomy_id IS NULL THEN
      FOR rec IN SELECT row_to_json(j) FROM( SELECT 'missing valid required parameter' AS error ) as j LOOP RETURN NEXT rec; END LOOP;
    END IF;
  ELSE
    FOR rec IN SELECT row_to_json(j) FROM( SELECT 'missing required parameter' AS error ) as j LOOP RETURN NEXT rec; END LOOP;
  END IF;
  -- validate and process classification_ids parameter
  IF $3 IS NOT NULL THEN
    c_ids:= string_to_array($3, ',')::int[];
    -- validate the classification ids
    SELECT INTO valid_c_ids array_agg(id)::int[] FROM classification WHERE _active=true AND id = ANY(c_ids);
  END IF;
  -- validate and process boundary_id parameter
  IF $6 IS NOT NULL THEN
    -- validate the boundary id
    SELECT INTO valid_boundary_id id FROM boundary WHERE _active = true AND id = $6;    
    IF valid_boundary_id IS NULL THEN
      FOR rec IN SELECT row_to_json(j) FROM( SELECT 'provided boundary id is invalid' AS error ) as j LOOP RETURN NEXT rec; END LOOP;
    END IF;
  END IF;
  -- validate and process feature_id parameter
  IF $7 IS NOT NULL THEN
     SELECT INTO spatial_table _spatial_table FROM boundary WHERE id = valid_boundary_id; 
    -- validate the feature id
    EXECUTE 'SELECT id FROM '|| spatial_table ||' WHERE _active = true AND id = ' || $7 INTO valid_feature_id;  
    IF valid_feature_id IS NULL THEN
      FOR rec IN SELECT row_to_json(j) FROM( SELECT 'provided feature id is invalid' AS error ) as j LOOP RETURN NEXT rec; END LOOP;
    END IF;
  END IF;  
  
  -- get the filtered activity ids
  SELECT INTO filtered_activity_ids * FROM pmt_filter($2,$3,null,null,null,$4,$5,null);
  
  IF valid_boundary_id IS NOT NULL AND valid_feature_id IS NOT NULL THEN
    -- get the activity ids for the feature
    SELECT INTO feature_activity_ids array_agg(activity_id) FROM _location_lookup ll WHERE ll.boundary_id = valid_boundary_id AND ll.feature_id = valid_feature_id;
  END IF;

    -- determine which where statement to use
  IF array_length(feature_activity_ids, 1) > 0 THEN
    where_statement:= 'WHERE (parent_id = ANY(ARRAY[' || array_to_string(filtered_activity_ids, ',') || ']) '|| 
				'AND parent_id = ANY(ARRAY[' || array_to_string(feature_activity_ids, ',') || '])) ' || 
				'OR (child_id = ANY(ARRAY[' || array_to_string(filtered_activity_ids, ',') || ']) '|| 
				'AND child_id = ANY(ARRAY[' || array_to_string(feature_activity_ids, ',') || '])) ';
  ELSE
    where_statement:= 'WHERE parent_id = ANY(ARRAY[' || array_to_string(filtered_activity_ids, ',') || ']) ' ||
			'OR child_id = ANY(ARRAY[' || array_to_string(filtered_activity_ids, ',') || ']) ';
  END IF;

  -- prepare the execution statement
  execute_statement:= 'SELECT CASE WHEN classification_id IS NULL THEN NULL ELSE classification_id END as classification_id, ' ||
			'CASE WHEN classification IS NULL THEN ''Unspecified'' ELSE classification END as classification, ' ||   
			'count(DISTINCT parent_id), sum(amount), array_agg(DISTINCT parent_id) as a_ids, ROW_NUMBER () OVER (ORDER BY sum(amount) DESC NULLS LAST) as rec_count FROM ' || 
			'(SELECT DISTINCT classification_id, classification, parent_id, amount '
			'FROM _activity_family_taxonomies WHERE taxonomy_id = ' || valid_taxonomy_id || ' AND parent_id IN ' ||
			'(SELECT DISTINCT parent_id FROM _activity_family ' || where_statement || ') ';
  
  -- add classification filter if requested
  IF array_length(valid_c_ids, 1) > 0 THEN
    execute_statement:= execute_statement || 'AND classification_id = ANY(ARRAY[' || array_to_string(valid_c_ids, ',') || ']) ';
  END IF;
  
  -- complete statement
  execute_statement:= execute_statement || 'ORDER BY 3,1 ) a GROUP BY 1,2';
  
  IF record_limit > 0 AND record_limit IS NOT NULL THEN
    execute_statement := 'SELECT classification_id, classification, count, a_ids, sum FROM (' || execute_statement || 
	') as foo WHERE rec_count <= ' || record_limit || ' UNION ALL '
	'SELECT null, ''Other'', count(DISTINCT parent_id) as count,  array_agg(DISTINCT parent_id) as a_ids, sum(amount) as sum FROM ' ||
	'(SELECT DISTINCT classification_id, classification, parent_id, amount ' ||
	'FROM _activity_family_taxonomies WHERE taxonomy_id = ' || valid_taxonomy_id || ' AND parent_id IN ' ||
	'(SELECT DISTINCT parent_id FROM _activity_family ' || where_statement || ') ' ||
	'AND classification_id IN ( ' ||
		'SELECT classification_id FROM ( ' ||
		    'SELECT CASE WHEN classification_id IS NULL THEN NULL ELSE classification_id END as classification_id, ' ||
			'CASE WHEN classification IS NULL THEN ''Unspecified'' ELSE classification END as classification, ' ||   
			'count(DISTINCT parent_id), sum(amount), ROW_NUMBER () OVER (ORDER BY sum(amount) DESC) as rec_count FROM ' || 
			'(SELECT DISTINCT classification_id, classification, parent_id, amount '
			'FROM _activity_family_taxonomies WHERE taxonomy_id = ' || valid_taxonomy_id || ' AND parent_id IN ' ||
			'(SELECT DISTINCT parent_id FROM _activity_family ' || where_statement || ') ORDER BY 3,1 ) a GROUP BY 1,2' ||
			') as foo WHERE rec_count > ' || record_limit || ' ) ORDER BY 3,1 ) a'; 		
  ELSE
    execute_statement := execute_statement || ' ORDER BY 4 DESC NULLS LAST';
  END IF;
  	
  RAISE INFO 'Execute statement: %', execute_statement;		

  FOR rec IN EXECUTE 'SELECT row_to_json(j) FROM (' || execute_statement || ')j' LOOP  		
	RETURN NEXT rec;
  END LOOP;
 
EXCEPTION WHEN others THEN 
  GET STACKED DIAGNOSTICS error_msg = MESSAGE_TEXT;  
    RAISE NOTICE 'Internal Error - Contact your DBA with the following error message: %', error_msg;
    
END;$$ LANGUAGE plpgsql;

/******************************************************************
4. update pmt_consolidate_orgs to follow PMT requirements and add
missing entity updates.
  select id, _name, _label from organization where _active=true order by _label;
  select * from pmt_consolidate_orgs(1,34,3540,ARRAY[3541,3542]::int[]); -- Cooperative Promotion Agency (CPA)
  select * from pmt_consolidate_orgs(1,34,3527,ARRAY[3109]::int[]); -- African Medical and Research Foundation - Ethiopia (AMREF)
  select * from pmt_consolidate_orgs(1,34,730,ARRAY[1630]::int[]); -- Agricultural Transformation Agency (ATA)
*******************************************************************/
DROP FUNCTION IF EXISTS pmt_consolidate_orgs (integer, integer, integer[]);
CREATE OR REPLACE FUNCTION pmt_consolidate_orgs (instance_id integer, user_id integer, organization_id_to_keep integer, organization_ids_to_consolidate integer[])
  RETURNS SETOF pmt_json_result_type AS $$
DECLARE
  valid_user_instance record;
  instance_record record;
  user_record record;
  participation_summary record;
  users_role record;
  keep_id integer;
  consolidate_ids integer[];
  ct int;
  rec record;
  error_msg1 text;
  error_msg2 text;
  error_msg3 text;
BEGIN	
  
  -- instance_id is required
  IF ($1 IS NULL) THEN
    FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: instance_id is a required parameter.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
  -- must be valid
  ELSE
    SELECT INTO instance_record * FROM instance WHERE _active = true AND id = $1;
    IF instance_record IS NULL THEN
      FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: Invalid instance_id.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
    END IF;
  END IF;
  -- user_id is required
  IF ($2 IS NULL) THEN
    FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: user_id is a required parameter.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
  -- must be valid
  ELSE
    SELECT INTO user_record * FROM users WHERE _active = true AND id = $2;
    IF user_record IS NULL THEN
      FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: Invalid user_id.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
    END IF;
    SELECT INTO valid_user_instance * FROM _user_instances WHERE _user_instances.user_id = $2 AND _user_instances.instance_id = $1;
    IF valid_user_instance.user_id IS NULL THEN
      FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: Provided user_id is not valid or does not have access to instance.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
    ELSE
      SELECT INTO users_role * FROM role WHERE id = valid_user_instance.role_id;
      RAISE NOTICE 'User: %', valid_user_instance.username;
      RAISE NOTICE 'Role: %', valid_user_instance.role;
    END IF;
  END IF;
  -- organization_id_to_keep is required
  IF ($3 IS NULL) THEN
    FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: organization_id_to_keep is a required parameter.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
  -- must be valid
  ELSE
    SELECT INTO keep_id id FROM organization WHERE id = $3;
    IF keep_id IS NULL THEN
      FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: Invalid organization_id_to_keep.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
    END IF;
  END IF;
  -- organization_ids_to_consolidate is required
  IF ($4 IS NULL) OR (array_length($4, 1) <= 0) THEN
    FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: organization_ids_to_consolidate is a required parameter.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
  -- must have at least one valid id
  ELSE
    SELECT INTO consolidate_ids array_agg(id)::int[] FROM organization WHERE id = ANY($4);
    IF (consolidate_ids IS NULL) OR (array_length(consolidate_ids, 1) <= 0) THEN
      FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: Invalid organization_ids_to_consolidate ids.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
    END IF;
  END IF;

  -- validate user authority to edit organizations (MUST HAVE "Delete" permissions on instance - i.e. Administrative Role)
  IF NOT users_role._delete THEN
    FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: Provided user_id does not have proper permissions on instance. User must have role that permits deletes.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
  END IF;
  
  -- reassign contact organizations
  SELECT INTO ct count(*) FROM contact WHERE organization_id = ANY(consolidate_ids);
  RAISE NOTICE 'Number of updated contacts: %', ct;
  UPDATE contact SET organization_id = keep_id, _updated_by = valid_user_instance.username WHERE organization_id = ANY(consolidate_ids);

  -- reassign instance organizations
  SELECT INTO ct count(*) FROM instance WHERE organization_id = ANY(consolidate_ids);
  RAISE NOTICE 'Number of updated instances: %', ct;
  UPDATE instance SET organization_id = keep_id, _updated_by = valid_user_instance.username WHERE organization_id = ANY(consolidate_ids);

  -- loop through participation records and reassign
  FOR participation_summary IN (SELECT activity_id, count(DISTINCT organization_id) as ct FROM participation WHERE organization_id = keep_id OR organization_id = ANY(consolidate_ids) GROUP BY 1) LOOP 
    -- the kept and a consolidated organization(s) are both on a single activity
    -- need to move taxonomies to kept organization (if not assigned) and deactivate participation records for consolidated
    IF participation_summary.ct > 1 THEN
      -- move all taxonomy classifications from consolidated orgs to kept org, if not assigned
      INSERT INTO participation_taxonomy (participation_id, classification_id, _field) 
        SELECT (SELECT id FROM participation WHERE organization_id = keep_id AND activity_id = participation_summary.activity_id LIMIT 1), classification_id, 'id' 
        FROM participation_taxonomy 
        WHERE participation_id IN (SELECT id FROM participation WHERE organization_id = ANY(consolidate_ids) AND activity_id = participation_summary.activity_id) 
        AND classification_id NOT IN (SELECT classification_id FROM participation_taxonomy WHERE participation_id IN (SELECT id FROM participation WHERE organization_id = keep_id AND activity_id = participation_summary.activity_id));
      -- de-activate consolidated organizations
      SELECT INTO ct count(*) FROM participation WHERE organization_id = ANY(consolidate_ids) AND activity_id = participation_summary.activity_id;
      RAISE NOTICE 'Number of updated participations: %',  ct || ' for activity id ' || participation_summary.activity_id || ' with count ' || participation_summary.ct;
      UPDATE participation SET _active = false, _updated_by = valid_user_instance.username WHERE organization_id = ANY(consolidate_ids) AND activity_id = participation_summary.activity_id;
    -- only the consolidate orgs are found on the activity
    -- replace the organization ids with kept id
    ELSE
      SELECT INTO ct count(*) FROM participation WHERE organization_id = ANY(consolidate_ids) AND activity_id = participation_summary.activity_id;
      RAISE NOTICE 'Number of updated participations: %',  ct || ' for activity id ' || participation_summary.activity_id || ' with count ' || participation_summary.ct;
      UPDATE participation SET organization_id = keep_id, _updated_by = valid_user_instance.username WHERE organization_id = ANY(consolidate_ids) AND activity_id = participation_summary.activity_id;
    END IF;
  END LOOP;

  -- reassign user organizations
  SELECT INTO ct count(*) FROM users WHERE organization_id = ANY(consolidate_ids);
  RAISE NOTICE 'Number of updated users: %',  ct;
  UPDATE users SET organization_id = keep_id, _updated_by = valid_user_instance.username WHERE organization_id = ANY(consolidate_ids);
  
  -- reassign organization taxonomies
  SELECT INTO ct count(*) FROM organization_taxonomy 
    WHERE organization_id IN (SELECT id FROM organization WHERE id = ANY(consolidate_ids)) 
    AND classification_id NOT IN (SELECT classification_id FROM organization_taxonomy WHERE organization_id IN (SELECT id FROM organization WHERE id = keep_id));
  RAISE NOTICE 'Number of updated organization taxonomies: %',  ct;
  INSERT INTO organization_taxonomy (organization_id, classification_id, _field) 
    SELECT (SELECT id FROM organization WHERE id = keep_id LIMIT 1), classification_id, 'id' 
    FROM organization_taxonomy 
    WHERE organization_id IN (SELECT id FROM organization WHERE id = ANY(consolidate_ids)) 
    AND classification_id NOT IN (SELECT classification_id FROM organization_taxonomy WHERE organization_id IN (SELECT id FROM organization WHERE id = keep_id));
    
  -- reassign financial provider & recipient
  SELECT INTO ct count(DISTINCT id) FROM financial WHERE provider_id = ANY(consolidate_ids) OR recipient_id = ANY(consolidate_ids);
  RAISE NOTICE 'Number of updated financials: %',  ct; 
  UPDATE financial SET provider_id = keep_id, _updated_by = valid_user_instance.username WHERE provider_id = ANY(consolidate_ids);
  UPDATE financial SET recipient_id = keep_id, _updated_by = valid_user_instance.username WHERE recipient_id = ANY(consolidate_ids);

  -- retire organization records
  SELECT INTO ct count(DISTINCT id) FROM organization WHERE id = ANY(consolidate_ids);
  RAISE NOTICE 'Number of retired organizations: %',  ct; 
  UPDATE organization SET _active = false, _retired_by = keep_id, _updated_by = valid_user_instance.username	WHERE id = ANY(consolidate_ids);
  
  -- successful response
  FOR rec IN (SELECT row_to_json(j) FROM(SELECT keep_id as id, 'Success' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;

EXCEPTION WHEN others THEN
  GET STACKED DIAGNOSTICS error_msg1 = MESSAGE_TEXT,
                          error_msg2 = PG_EXCEPTION_DETAIL,                           
                          error_msg3 = PG_EXCEPTION_HINT;
FOR rec IN (SELECT row_to_json(j) FROM(select 'Internal Error - organization your DBA with the following error message: ' || error_msg1 as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;	  

END;$$ LANGUAGE plpgsql; 

-- update permissions
GRANT USAGE ON SCHEMA public TO pmt_read;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO pmt_read;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO pmt_read;
GRANT USAGE ON SCHEMA public TO pmt_write;
GRANT SELECT,INSERT ON ALL TABLES IN SCHEMA public TO pmt_write;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO pmt_write;