/******************************************************************
Change Script 3.0.10.98
1. update pmt_stat_activity_by_tax to address bug in classification
filter
2. update pmt_partner_pivot to ensure proper filtering of both
parent and child activities
3. create new function pmt_activity_family_titles
4. update pmt_edit_participation to allow Organisation Type taxonomy
5. create pmt_get_valid_id to get a single valid activity id from 
the database
******************************************************************/
INSERT INTO version(_version, _iteration, _changeset) VALUES (3.0, 10, 98);
-- select * from version order by _iteration desc, _changeset desc;

/******************************************************************
1. update pmt_stat_activity_by_tax to addrss bug in classification
filter.

 select * from pmt_stat_activity_by_tax(15,'2237','2570,794,658,659,660,661,662,663,664,665,666,667,668,669,670,671,672,673,674,675',
   null,null,15,74,null,'794,658,659,660,661,662,663,664,665,666,667,668,669,670,671,672,673,674,675');

******************************************************************/
DROP FUNCTION IF EXISTS pmt_stat_activity_by_tax(integer, character varying, character varying, date, date, integer, integer, integer);
CREATE OR REPLACE FUNCTION pmt_stat_activity_by_tax(taxonomy_id integer, data_group_ids character varying, classification_ids character varying, 
start_date date, end_date date, boundary_id integer, feature_id integer, record_limit integer, filter_classification_ids character varying) RETURNS SETOF pmt_json_result_type AS
$$
DECLARE
  dg_ids int[];
  c_ids int[];
  filter_c_ids int[];
  valid_dg_ids int[];
  valid_c_ids int[];
  valid_filter_c_ids int[];
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
  -- validate and process filter_classification_ids parameter
  IF $9 IS NOT NULL THEN
    filter_c_ids:= string_to_array($9, ',')::int[];
    -- validate the filter classification ids
    SELECT INTO valid_filter_c_ids array_agg(id)::int[] FROM classification WHERE _active=true AND id = ANY(filter_c_ids);
  END IF; 

  -- get the filtered activity ids
  SELECT INTO filtered_activity_ids * FROM pmt_filter($2,array_to_string(valid_c_ids, ','),null,null,null,$4,$5,null);
  
  IF valid_boundary_id IS NOT NULL AND valid_feature_id IS NOT NULL THEN
    -- get the activity ids for the feature
    SELECT INTO feature_activity_ids array_agg(activity_id) FROM _location_lookup ll WHERE ll.boundary_id = valid_boundary_id AND ll.feature_id = valid_feature_id;
  END IF;
  
  -- determine which where statement to use
  IF array_length(feature_activity_ids, 1) > 0 THEN
    where_statement:= 'WHERE (parent_id = ANY(ARRAY[' || array_to_string(filtered_activity_ids, ',') || ']) ' || 
				'OR child_id = ANY(ARRAY[' || array_to_string(filtered_activity_ids, ',') || '])) ' || 
				'AND ( parent_id = ANY(ARRAY[' || array_to_string(feature_activity_ids, ',') || '])' || 
				'OR child_id = ANY(ARRAY[' || array_to_string(feature_activity_ids, ',') || '])) ';
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
  IF array_length(valid_filter_c_ids, 1) > 0 THEN
    execute_statement:= execute_statement || 'AND classification_id = ANY(ARRAY[' || array_to_string(valid_filter_c_ids, ',') || ']) ';
  END IF;
  
  -- complete statement
  execute_statement:= execute_statement || 'ORDER BY 3,1 ) a GROUP BY 1,2';
  
  IF record_limit > 0 AND record_limit IS NOT NULL THEN
    execute_statement := 'SELECT classification_id, classification, count, a_ids, sum FROM ( ' || execute_statement || 
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
  	
  RAISE NOTICE 'Execute statement: %', execute_statement;		

  FOR rec IN EXECUTE 'SELECT row_to_json(j) FROM (' || execute_statement || ')j' LOOP  		
	RETURN NEXT rec;
  END LOOP;
 
EXCEPTION WHEN others THEN 
  GET STACKED DIAGNOSTICS error_msg = MESSAGE_TEXT;  
    RAISE NOTICE 'Internal Error - Contact your DBA with the following error message: %', error_msg;
    
END;$$ LANGUAGE plpgsql;

/******************************************************************
2. update pmt_partner_pivot to ensure proper filtering of both
parent and child activities
   select * from pmt_partner_pivot(77,69,497,'2237','2570',null,null,15,74);
******************************************************************/
DROP FUNCTION IF EXISTS pmt_partner_pivot(integer, integer, integer, character varying, character varying, date, date);
CREATE OR REPLACE FUNCTION pmt_partner_pivot(row_taxonomy_id integer, column_taxonomy_id integer, org_role_id integer, data_group_ids character varying, classification_ids character varying, 
start_date date, end_date date, boundary_id integer, feature_id integer) RETURNS SETOF pmt_json_result_type AS
$$
DECLARE
  valid_row_taxonomy_id integer; 
  valid_column_taxonomy_id integer; 
  valid_role_id integer;
  valid_boundary_id integer;
  valid_feature_id integer; 
  spatial_table text;
  filtered_activity_ids int[];
  feature_activity_ids int[];
  column_headers text[];
  col text;
  col_count int;
  execute_statement text;    
  rec record;
  error_msg text;
BEGIN

  -- validate and process row_taxonomy_id parameter
  IF $1 IS NOT NULL THEN
    -- validate the taxonomy id
    SELECT INTO valid_row_taxonomy_id id FROM taxonomy WHERE id = $1 AND _active = true;
    IF valid_row_taxonomy_id IS NULL THEN
      FOR rec IN SELECT row_to_json(j) FROM( SELECT 'missing valid required parameter' AS error ) as j LOOP RETURN NEXT rec; END LOOP;
    END IF;
  ELSE
    FOR rec IN SELECT row_to_json(j) FROM( SELECT 'missing required parameter' AS error ) as j LOOP RETURN NEXT rec; END LOOP;
  END IF;
  -- validate and process column_taxonomy_id parameter
  IF $2 IS NOT NULL THEN
    -- validate the taxonomy id
    SELECT INTO valid_column_taxonomy_id id FROM taxonomy WHERE id = $2 AND _active = true;
    IF valid_column_taxonomy_id IS NULL THEN
      FOR rec IN SELECT row_to_json(j) FROM( SELECT 'missing valid required parameter' AS error ) as j LOOP RETURN NEXT rec; END LOOP;
    END IF;
  ELSE
    FOR rec IN SELECT row_to_json(j) FROM( SELECT 'missing required parameter' AS error ) as j LOOP RETURN NEXT rec; END LOOP;
  END IF;
  -- validate and process org_role_id parameter
  IF $3 IS NOT NULL THEN
    -- validate the organization role id
    SELECT INTO valid_role_id classification_id FROM _taxonomy_classifications WHERE taxonomy = 'Organisation Role' AND classification_id = $3;    
    IF valid_role_id IS NULL THEN
      FOR rec IN SELECT row_to_json(j) FROM( SELECT 'missing valid required parameter' AS error ) as j LOOP RETURN NEXT rec; END LOOP;
    END IF;
  ELSE
    FOR rec IN SELECT row_to_json(j) FROM( SELECT 'missing required parameter' AS error ) as j LOOP RETURN NEXT rec; END LOOP;
  END IF;
  -- validate and process boundary_id parameter
  IF $8 IS NOT NULL THEN
    -- validate the boundary id
    SELECT INTO valid_boundary_id id FROM boundary WHERE _active = true AND id = $8;    
    IF valid_boundary_id IS NULL THEN
      FOR rec IN SELECT row_to_json(j) FROM( SELECT 'provided boundary id is invalid' AS error ) as j LOOP RETURN NEXT rec; END LOOP;
    END IF;
  END IF;
  -- validate and process feature_id parameter
  IF $9 IS NOT NULL THEN
    SELECT INTO spatial_table _spatial_table FROM boundary WHERE id = valid_boundary_id; 
    -- validate the feature id
    EXECUTE 'SELECT id FROM '|| spatial_table ||' WHERE _active = true AND id = ' || $9 INTO valid_feature_id;  
    IF valid_feature_id IS NULL THEN
      FOR rec IN SELECT row_to_json(j) FROM( SELECT 'provided feature id is invalid' AS error ) as j LOOP RETURN NEXT rec; END LOOP;
    END IF;
  END IF;
  
  -- get the filtered activity ids
  SELECT INTO filtered_activity_ids * FROM pmt_filter($4,$5,null,null,null,$6,$7,null);

  IF valid_boundary_id IS NOT NULL AND valid_feature_id IS NOT NULL THEN
    -- get the activity ids for the feature
    SELECT INTO feature_activity_ids array_agg(activity_id) FROM _location_lookup ll WHERE ll.boundary_id = valid_boundary_id AND ll.feature_id = valid_feature_id;
  END IF;
  
  -- get the column headers
  SELECT INTO column_headers array_agg(quote_literal(classification))::text[] FROM _taxonomy_classifications WHERE taxonomy_id = valid_column_taxonomy_id;
  
  -- prepare the execution statement
  execute_statement:= 'SELECT ''''::text as c1,';
  col_count :=2;
  
  FOREACH col IN ARRAY column_headers LOOP
    execute_statement:= execute_statement || 'to_json(' || col || '::text) as c' || col_count || ','; 
    col_count := col_count + 1;
  END LOOP;

  execute_statement:= execute_statement || ' to_json(''Unspecified''::text) as c' || col_count || ' UNION ALL SELECT * FROM ( SELECT rows.classification::text, ';
  
  FOREACH col IN ARRAY column_headers LOOP
    execute_statement:= execute_statement || 'json_agg(distinct case when cols.classification = ' || col || 
			' then row(org._label, org.organization_id, org._name) end) as ' || quote_ident(col) || ',';
  END LOOP;

  execute_statement:= execute_statement || 'json_agg(distinct case when cols.classification is null then row(org._label, org.organization_id, org._name) end) as "Unspecified" ';

  IF array_length(feature_activity_ids, 1) > 0 THEN
    execute_statement:= execute_statement || 'FROM ( SELECT id FROM activity WHERE (id = ANY(ARRAY[' || array_to_string(filtered_activity_ids, ',') || ']) ' || 
								'OR parent_id = ANY(ARRAY[' || array_to_string(filtered_activity_ids, ',') || '])) ' || 
								'AND (id = ANY(ARRAY[' || array_to_string(feature_activity_ids, ',') || ']) ' ||
								'OR parent_id = ANY(ARRAY[' || array_to_string(feature_activity_ids, ',') || ']))' || 
							') a ';
  ELSE
    execute_statement:= execute_statement || 'FROM ( SELECT id FROM activity WHERE (id = ANY(ARRAY[' || array_to_string(filtered_activity_ids, ',') || ']) ' || 
								'OR parent_id = ANY(ARRAY[' || array_to_string(filtered_activity_ids, ',') || '])) ' || 
							') a ';
  END IF;
	
  execute_statement:= execute_statement	|| 'LEFT JOIN ' ||
			'(SELECT id, _label, _name, organization_id ' ||
			'FROM _activity_participants ' ||
			'WHERE id = ANY(ARRAY[' || array_to_string(filtered_activity_ids, ',') || ']) AND classification_id = ' || valid_role_id || ') as org ' ||
			'ON a.id = org.id ' ||
			'LEFT JOIN ' ||
			'(SELECT id, classification ' ||
			'FROM _activity_taxonomies ' ||
			'WHERE id = ANY(ARRAY[' || array_to_string(filtered_activity_ids, ',') || ']) AND taxonomy_id = ' || valid_column_taxonomy_id || ') as cols ' ||
			'ON a.id = cols.id ' ||
			'LEFT JOIN ' ||
			'(SELECT id, classification ' ||
			'FROM _activity_taxonomies ' ||
			'WHERE id = ANY(ARRAY[' || array_to_string(filtered_activity_ids, ',') || ']) AND taxonomy_id = ' || valid_row_taxonomy_id || ') as rows ' ||
			'ON a.id = rows.id ' ||
			'GROUP BY 1 ' ||
			') as selection';
  
  RAISE NOTICE 'Execute statement: %', execute_statement;			

  FOR rec IN EXECUTE 'SELECT row_to_json(j) FROM (' || execute_statement || ')j' LOOP  		
	RETURN NEXT rec;
  END LOOP;
 
EXCEPTION WHEN others THEN 
  GET STACKED DIAGNOSTICS error_msg = MESSAGE_TEXT;  
    RAISE NOTICE 'Internal Error - Contact your DBA with the following error message: %', error_msg;
    
END;$$ LANGUAGE plpgsql;

/******************************************************************
3. create new function pmt_activity_family_titles
   select * from pmt_activity_family_titles('2237');
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_activity_family_titles(data_group_ids character varying) RETURNS SETOF pmt_json_result_type AS
$$
DECLARE 
  dg_ids int[];
  valid_dg_ids int[]; 
  execute_statement text; 
  rec record;
  error_msg text;
BEGIN

  -- validate data group ids
  IF $1 IS NOT NULL OR $1 <> '' THEN
    dg_ids:= string_to_array($1, ',')::int[];
    -- validate the filter classification ids
    SELECT INTO valid_dg_ids array_agg(id)::int[] FROM classification WHERE _active = true AND taxonomy_id = 1 AND id = ANY(dg_ids);
  END IF; 

  -- prepare statement
  execute_statement:= 'SELECT id, _title, (SELECT array_to_json(array_agg(row_to_json(c))) FROM ( ' ||
				'SELECT id, _title ' ||
				'FROM activity ' ||
				'WHERE _active = true AND parent_id = p.id ' ||
			    ') as c ) as children ' ||
			    'FROM activity p ';

  -- add where statement based on provided valid data groups			    
  IF array_length(valid_dg_ids, 1) > 0 THEN    
    execute_statement:= execute_statement || 'WHERE _active = true AND parent_id IS NULL AND data_group_id = ANY(ARRAY[' || array_to_string(valid_dg_ids, ',') || '])';
    
  ELSE
    execute_statement:= execute_statement || 'WHERE _active = true AND parent_id IS NULL';    
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
4. update pmt_edit_participation to allow Organisation Type taxonomy
 select * from pmt_edit_participation(1,34,26197,3163,88929,'496','replace');
 select * from pmt_edit_participation(1,34,26326,3335,null,'494','add');
 select * from pmt_edit_participation(1,34,26269,3461,95742,null,'delete');
 select * from _activity_participants where id = 26197
 select * from participation where activity_id = 26197
 select * from _taxonomy_classifications tc where tc.taxonomy IN ('Organisation Role','Organisation Type','Implementing Types')
******************************************************************/
DROP FUNCTION IF EXISTS pmt_edit_participation(integer, integer, integer, integer, integer, character varying, pmt_edit_action);
CREATE OR REPLACE FUNCTION pmt_edit_participation(instance_id integer, user_id integer, activity_id integer, organization_id integer, participation_id integer, classification_ids character varying, edit_action pmt_edit_action) RETURNS SETOF pmt_json_result_type AS 
$$
DECLARE
  c_ids integer array;  
  c_id integer;
  id integer;
  record_id integer;
  record_is_active boolean;
  tax_ct integer;
  username text;
  rec record;
  error_message text;
  error_msg text;
BEGIN 
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
    IF NOT (SELECT * FROM pmt_validate_activity($3)) THEN  
      FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: Invalid activity_id.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
    END IF;
  END IF;
  -- organization_id is required for all operations
  IF ($4 IS NULL) THEN
    FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: organization_id is a required parameter for all operations.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
  ELSE
     -- validate the associated organization record
    IF NOT (SELECT * FROM pmt_validate_organization($4)) THEN  
      FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: Invalid organization_id.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
    END IF;
  END IF;
  -- validate the participation_id
  IF ($5 IS NOT NULL) THEN
    IF (SELECT * FROM pmt_validate_participation($5)) THEN
      record_id := $5;
    ELSE
      FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: Invalid participation_id.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
    END IF;
  ELSE
    -- participation_id is required for replace & delete
    IF ($7 <> 'add') THEN
      FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: participation_id is a required parameter for replace/delete operations.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
    END IF;
  END IF;
    -- validate classification_id if provided
  IF ($6 IS NOT NULL) THEN
    SELECT INTO c_ids * FROM pmt_validate_classifications($6);        
    SELECT INTO c_ids array_agg(tc.classification_id) from _taxonomy_classifications tc where tc.taxonomy IN ('Organisation Role','Organisation Type','Implementing Types') AND tc.classification_id = ANY(c_ids);
    IF c_ids IS NULL THEN
      FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: Provided classification_ids are not in the Organisation Role taxonomy or are inactive.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
    END IF;    
  END IF;
  -- edit_action is required for all operations
  IF ($7 IS NULL) THEN
    FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: edit_action is a required parameter for all operations.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
  END IF;
  
  -- get users name
  SELECT INTO username _username FROM users WHERE users.id = $2;
  
  -- operations based on the requested edit action
  CASE $7
    WHEN 'delete' THEN 
      -- validate users authority to perform an update action on this project
      IF (SELECT * FROM pmt_validate_user_authority($1, $2, $3, null, 'update')) THEN      
        EXECUTE 'DELETE FROM participation_taxonomy WHERE participation_id ='|| $5;
        EXECUTE 'DELETE FROM participation WHERE id ='|| $5; 
        RAISE NOTICE 'Delete Record: %', 'Deactivated participation record: ('|| $5 ||')';
      ELSE
        FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: The requested edit action requires the user to have UPDATE rights to this activity: ' || $3 as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;     
      END IF; 
    WHEN 'replace' THEN            
      -- check for required parameters
      IF ($3 IS NULL) OR ($4 IS NULL) OR ($5 IS NULL) OR (c_ids IS NULL) THEN
        FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: Must have activity_id, organization_id, participation_id and classification_id parameters when edit action is: ' || $7 as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;     
      END IF;
      -- validate users authority to perform an update on the activity
      IF (SELECT * FROM pmt_validate_user_authority($1, $2, $3, null, 'update')) THEN      
	-- delete all taxonomy records for participation 
	EXECUTE 'DELETE FROM participation_taxonomy WHERE participation_id ='|| $5;
	-- update record
	EXECUTE 'UPDATE participation SET activity_id = ' || $3 || ', organization_id = ' || $4 || ', _updated_by = ' || quote_literal(username) || ', _updated_date = ' || quote_literal(current_date) || ' WHERE id = '|| $5;
	-- add taxonomy records
	EXECUTE 'INSERT INTO participation_taxonomy(participation_id, classification_id, _field) SELECT '|| $5 ||', id, ''id'' FROM ' ||
	       'classification WHERE id IN (' || array_to_string(c_ids, ',') || ')';             
      ELSE
        FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: The requested edit action requires the user to have UPDATE rights to this activity: ' || $3 as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;     
      END IF;
    -- add (action)
    ELSE
      -- check for required parameters
      IF ($3 IS NULL) OR ($4 IS NULL) OR (c_ids IS NULL) THEN
        FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: Must have activity_id, organization_id and classification_id parameters when edit action is: ' || $7 as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;     
      END IF;
      -- validate users authority to perform a create action on this project
      IF (SELECT * FROM pmt_validate_user_authority($1, $2, $3, null, 'update')) THEN
        -- determine if requested particpation record currently exists                   
        SELECT INTO record_id pp.id FROM participation pp WHERE pp.activity_id = $3 AND pp.organization_id = $4;          
        -- the requested participation record exists
        IF (record_id IS NOT NULL) THEN            
	  -- delete all taxonomy records for participation 
	  EXECUTE 'DELETE FROM participation_taxonomy WHERE participation_id ='|| record_id;
	  -- add taxonomy records
	  EXECUTE 'INSERT INTO participation_taxonomy(participation_id, classification_id, _field) SELECT '|| record_id ||', id, ''id'' FROM ' ||
	       'classification WHERE id IN (' || array_to_string(c_ids, ',') || ')';                                     
	-- the requested participation record does NOT exist
	ELSE
	  -- create the participation record
	  EXECUTE 'INSERT INTO participation(activity_id, organization_id, _created_by, _updated_by) VALUES (' || $3 || ',' || $4 ||  ',' || quote_literal(username) || ',' || quote_literal(username) || ') RETURNING id;' INTO record_id;
	  -- add taxonomy records
	  EXECUTE 'INSERT INTO participation_taxonomy(participation_id, classification_id, _field) SELECT '|| record_id ||', id, ''id'' FROM ' ||
	       'classification WHERE id IN (' || array_to_string(c_ids, ',') || ')';
	END IF;
      ELSE
        FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: The requested edit action requires the user to have UPDATE rights to this activity: ' || $3 as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;     
      END IF;        
  END CASE;

  -- editing completed successfullly
  FOR rec IN (SELECT row_to_json(j) FROM(select record_id as id, 'Success' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;         
  
EXCEPTION WHEN others THEN
     GET STACKED DIAGNOSTICS error_msg = MESSAGE_TEXT;
    FOR rec IN (SELECT row_to_json(j) FROM(select record_id as id, 'Internal Error - Contact your DBA with the following error message: ' || error_msg as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
      
END;$$ LANGUAGE plpgsql;

/******************************************************************
5. create pmt_get_valid_id to get a single valid activity id from 
the database
  select * from pmt_get_valid_id('2237');
  select * from activity where id = 26269
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_get_valid_id(data_group_ids character varying) RETURNS SETOF pmt_json_result_type AS $$
DECLARE
  dg_ids int[];
  valid_dg_ids int[];
  execute_statement text; 
  rec record;
  error_msg text;
BEGIN

  -- validate data group ids
  IF $1 IS NOT NULL OR $1 <> '' THEN
    dg_ids:= string_to_array($1, ',')::int[];
    -- validate the filter classification ids
    SELECT INTO valid_dg_ids array_agg(id)::int[] FROM classification WHERE _active = true AND taxonomy_id = 1 AND id = ANY(dg_ids);
  END IF; 

  -- restrict first returned id to data group(s)
  IF array_length(valid_dg_ids, 1) > 0 THEN
    execute_statement:= 'SELECT id FROM activity WHERE _active = true AND parent_id IS NULL AND data_group_id = ANY(ARRAY[' || array_to_string(valid_dg_ids, ',') || ']) LIMIT 1';
  ELSE
    execute_statement:= 'SELECT id FROM activity WHERE _active = true AND parent_id IS NULL LIMIT 1';
  END IF;
  
  RAISE NOTICE 'Execute statement: %', execute_statement;			

  FOR rec IN EXECUTE 'SELECT row_to_json(j) FROM (' || execute_statement || ')j' LOOP  		
	RETURN NEXT rec;
  END LOOP;
  
EXCEPTION WHEN others THEN 
  GET STACKED DIAGNOSTICS error_msg = MESSAGE_TEXT;  
    RAISE NOTICE 'Internal Error - Contact your DBA with the following error message: %', error_msg;
    
END;$$ LANGUAGE plpgsql;

-- update permissions
GRANT USAGE ON SCHEMA public TO pmt_read;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO pmt_read;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO pmt_read;
GRANT USAGE ON SCHEMA public TO pmt_write;
GRANT SELECT,INSERT ON ALL TABLES IN SCHEMA public TO pmt_write;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO pmt_write;