/******************************************************************
Change Script 3.0.10.23
1. update pmt_stat_activity_by_tax for new data model and application
requirements
2. create new function pmt_stat_invest_by_funder
3. create new _label field in the organization table & populate
4. update view _activity_participants with id and label
5. create new function pmt_partner_pivot
6. update pmt_activities
7. remove project related and deprecated functions
******************************************************************/
INSERT INTO version(_version, _iteration, _changeset) VALUES (3.0, 10, 23);
-- select * from version order by _iteration desc, _changeset desc;

/******************************************************************
1. update pmt_stat_activity_by_tax for new data model and application
requirements
   select * from pmt_stat_activity_by_tax(14,'2209,2210','107',null,null);   
******************************************************************/
DROP FUNCTION IF EXISTS pmt_stat_activity_by_tax(integer, character varying, character varying, character varying, date, date);
CREATE OR REPLACE FUNCTION pmt_stat_activity_by_tax(taxonomy_id integer, data_group_ids character varying, classification_ids character varying, start_date date, end_date date) RETURNS SETOF pmt_json_result_type AS
$$
DECLARE
  dg_ids int[];
  valid_dg_ids int[];
  valid_taxonomy_id integer; 
  filtered_activity_ids int[];
  execute_statement text;    
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

  -- get the filtered activity ids
  SELECT INTO filtered_activity_ids * FROM pmt_filter($2,$3,null,null,null,$4,$5,null);

  -- if data groups are the only filter, then use a execution statement that is more performant
  IF ($3 IS NULL OR $3 = '') AND ($4 IS NULL) AND ($5 IS NULL) THEN
    -- validate and process data_group_ids parameter
    IF $2 IS NOT NULL OR $2 <> '' THEN
      dg_ids:= string_to_array($2, ',')::int[];
      -- validate the data groups id
      SELECT INTO valid_dg_ids array_agg(id)::int[] FROM classification c WHERE c.taxonomy_id = 1 AND _active=true AND id = ANY(dg_ids);
      -- if there are no valid data group ids then get all ids
      IF array_length(valid_dg_ids, 1) <= 0 THEN
        SELECT INTO valid_dg_ids array_agg(id)::int[] FROM classification c WHERE c.taxonomy_id = 1 AND _active=true;
      END IF;      
    END IF;
    -- prepare the execution statement
    execute_statement:= 'SELECT CASE WHEN t.classification_id IS NULL THEN NULL ELSE t.classification_id END,  ' ||
				'CASE WHEN t.classification IS NULL THEN ''Unspecified'' ELSE t.classification END, ' ||
				'count(id) as count, sum(_amount) as sum FROM ' ||
				'(SELECT a.id, f._amount, at.classification_id FROM ' ||
				'(SELECT id ' ||
				'FROM activity ' ||
				'WHERE data_group_id = ANY(ARRAY[' || array_to_string(valid_dg_ids, ',') || ']) and _active = true ) a ' ||
				'LEFT JOIN ' ||
				'(SELECT activity_id, _amount ' ||
				'FROM financial ' ||
				'WHERE _active = true AND activity_id IN (SELECT id FROM activity WHERE data_group_id = ANY(ARRAY[' || array_to_string(valid_dg_ids, ',') || ']) and _active = true)) f ' ||
				'ON a.id = f.activity_id ' ||
				'LEFT JOIN ' ||
				'(SELECT activity_id, classification_id ' ||
				'FROM activity_taxonomy ' ||
				'WHERE activity_id IN (SELECT id FROM activity WHERE data_group_id = ANY(ARRAY[' || array_to_string(valid_dg_ids, ',') || ']) and _active = true) ' ||
				'AND classification_id IN (SELECT id FROM classification WHERE _active = true AND taxonomy_id = ' || valid_taxonomy_id || ')) at ' ||
				'ON a.id = at.activity_id ' ||
			') as a ' ||
			'LEFT JOIN ( ' ||
				'SELECT taxonomy_id, taxonomy, classification_id, classification  ' ||
				'FROM _taxonomy_classifications ' ||
				'WHERE taxonomy_id = ' || valid_taxonomy_id || ') as t ' ||
			'ON t.classification_id = a.classification_id ' ||
			'GROUP BY 1,2 ' ||
			'ORDER BY 4'; 
  ELSE    
    -- prepare the execution statement
    execute_statement:= 'SELECT CASE WHEN t.classification_id IS NULL THEN NULL ELSE t.classification_id END,  ' ||
				'CASE WHEN t.classification IS NULL THEN ''Unspecified'' ELSE t.classification END, ' ||
				'count(id) as count, sum(_amount) as sum FROM ' ||
				'(SELECT a.id, f._amount, at.classification_id FROM ' ||
				'(SELECT id ' ||
				'FROM activity ' ||
				'WHERE id = ANY(ARRAY[' || array_to_string(filtered_activity_ids, ',') || '])) a ' ||
				'LEFT JOIN ' ||
				'(SELECT activity_id, _amount ' ||
				'FROM financial ' ||
				'WHERE activity_id = ANY(ARRAY[' || array_to_string(filtered_activity_ids, ',') || '])) f ' ||
				'ON a.id = f.activity_id ' ||
				'LEFT JOIN ' ||
				'(SELECT activity_id, classification_id ' ||
				'FROM activity_taxonomy ' ||
				'WHERE activity_id = ANY(ARRAY[' || array_to_string(filtered_activity_ids, ',') || ']) ' ||
				'AND classification_id IN (SELECT id FROM classification WHERE _active = true AND taxonomy_id = ' || valid_taxonomy_id || ')) at ' ||
				'ON a.id = at.activity_id ' ||
			') as a ' ||
			'LEFT JOIN ( ' ||
				'SELECT taxonomy_id, taxonomy, classification_id, classification  ' ||
				'FROM _taxonomy_classifications ' ||
				'WHERE taxonomy_id = ' || valid_taxonomy_id || ') as t ' ||
			'ON t.classification_id = a.classification_id ' ||
			'GROUP BY 1,2 ' ||
			'ORDER BY 4'; 
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
2. create new function pmt_stat_invest_by_funder
   select * from pmt_stat_invest_by_funder('2237',null,null,null);
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_stat_invest_by_funder(data_group_ids character varying, classification_ids character varying, start_date date, end_date date) RETURNS SETOF pmt_json_result_type AS
$$
DECLARE
  valid_role_id integer; 
  filtered_activity_ids int[];
  execute_statement text;    
  rec record;
  error_msg text;
BEGIN

  -- get the filtered activity ids
  SELECT INTO filtered_activity_ids * FROM pmt_filter($1,$2,null,null,null,$3,$4,null);

  -- prepare the execution statement
  execute_statement:= 'SELECT o.id, o._name as name, o._label as label, count(f.activity_id) as count, sum(f._amount) as sum ' ||
			'FROM ' ||
			'(SELECT activity_id, provider_id, _amount ' ||
			'FROM financial ' ||
			'WHERE _active = true AND activity_id = ANY(ARRAY[' || array_to_string(filtered_activity_ids, ',') || '])) f ' ||
			'LEFT JOIN ' ||
			'(SELECT id, _name, _label ' ||
			'FROM organization ' ||
			'WHERE _active = true) o ' ||
			'ON f.provider_id = o.id ' ||
			'GROUP BY 1,2,3 ' ||
			'ORDER BY 5 DESC';
  
  RAISE NOTICE 'Execute statement: %', execute_statement;			

  FOR rec IN EXECUTE 'SELECT row_to_json(j) FROM (' || execute_statement || ')j' LOOP  		
	RETURN NEXT rec;
  END LOOP;
 
EXCEPTION WHEN others THEN 
  GET STACKED DIAGNOSTICS error_msg = MESSAGE_TEXT;  
    RAISE NOTICE 'Internal Error - Contact your DBA with the following error message: %', error_msg;
    
END;$$ LANGUAGE plpgsql;

/******************************************************************
3. create new _label field in the organization table & populate
******************************************************************/
ALTER TABLE organization ADD COLUMN _label character varying;
UPDATE organization SET _label = _name, _updated_by = 'cs_3.0.10.23' WHERE _active = true;
UPDATE organization SET _label = substring(_label from position('(' in _label)+1 for length(_label)) WHERE position('(' in _label)>0 AND position(')' in _label)>0;
UPDATE organization SET _label = substring(_label from 0 for position(')' in _label)) WHERE position(')' in _label)>0;
UPDATE organization SET _label = trim(_label) WHERE _active = true;

/******************************************************************
4. update view _activity_participants with id and label
******************************************************************/
DROP VIEW _activity_participants;
CREATE OR REPLACE VIEW _activity_participants AS 
 SELECT a.id,
    a._title,
    a.data_group_id,
    dg.classification AS data_group,
    o.id as organization_id,
    o._name,
    o._label,
    tc.classification_id,
    tc.classification
   FROM activity a
     LEFT JOIN participation pp ON a.id = pp.activity_id
     LEFT JOIN participation_taxonomy ppt ON pp.id = ppt.participation_id
     LEFT JOIN _taxonomy_classifications tc ON ppt.classification_id = tc.classification_id
     LEFT JOIN organization o ON pp.organization_id = o.id
     LEFT JOIN _taxonomy_classifications dg ON a.data_group_id = dg.classification_id
  WHERE a._active = true AND pp._active = true
  ORDER BY a.id;
  
/******************************************************************
5. create new function pmt_partner_pivot
   select * from pmt_partner_pivot(68,69,496,'2237',null,null,null);
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_partner_pivot(row_taxonomy_id integer, column_taxonomy_id integer, org_role_id integer, data_group_ids character varying, classification_ids character varying, 
start_date date, end_date date) RETURNS SETOF pmt_json_result_type AS
$$
DECLARE
  valid_row_taxonomy_id integer; 
  valid_column_taxonomy_id integer; 
  valid_role_id integer; 
  filtered_activity_ids int[];
  column_headers text[];
  col text;
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
  
  -- get the filtered activity ids
  SELECT INTO filtered_activity_ids * FROM pmt_filter($4,$5,null,null,null,$6,$7,null);

  -- get the column headers
  SELECT INTO column_headers array_agg(classification)::text[] FROM _taxonomy_classifications WHERE taxonomy_id = valid_column_taxonomy_id;
  
  -- prepare the execution statement
  execute_statement:= 'SELECT '''' as c,''' || array_to_string(column_headers, ''' as c,''') || ''' as c,''Unspecified'' as c UNION ALL SELECT distinct * FROM ( ' || 
			'SELECT rows.classification::text, ';
  FOREACH col IN ARRAY column_headers LOOP
    execute_statement:= execute_statement || 'array_to_string(array_remove(array_agg(distinct case when cols.classification = ' || quote_literal(col) || 
			' then org._label end), NULL), '', '')::text as "' || col || '",';			
  END LOOP;

  execute_statement:= execute_statement || 'array_to_string(array_remove(array_agg(distinct case when cols.classification is null then org._label end), NULL), '', '')::text as "Unspecified" ' ||
			'FROM ( SELECT id FROM activity WHERE id = ANY(ARRAY[' || array_to_string(filtered_activity_ids, ',') || '])) a ' ||
			'LEFT JOIN ' ||
			'(SELECT id, _label ' ||
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
			'GROUP BY 1 ORDER BY 2,1 ' ||
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
6. update pmt_activities for new data model and application
requirements
   select * from pmt_activities('768','797',null,null,null,'1/1/2005','1/1/2020','18');   
******************************************************************/
DROP FUNCTION IF EXISTS pmt_activities();
CREATE OR REPLACE FUNCTION pmt_activities(data_group_ids character varying, classification_ids character varying, org_ids character varying,
imp_org_ids character varying, fund_org_ids character varying, start_date date, end_date date, unassigned_taxonomy_ids character varying) RETURNS SETOF pmt_json_result_type AS
$$
DECLARE
  filtered_activity_ids int[];
  execute_statement text;    
  rec record;
  error_msg text;
BEGIN

  -- get the filtered activity ids
  SELECT INTO filtered_activity_ids * FROM pmt_filter($1,$2,$3,$4,$5,$6,$7,$8);

  -- prepare the execution statement
  execute_statement:= 'SELECT a.id, parent_id, data_group_id, (SELECT _name FROM classification WHERE id = data_group_id) as data_group, _title, sum(_amount) as amount ' ||
		'FROM (SELECT * FROM activity WHERE _active = true AND id = ANY(ARRAY[' || array_to_string(filtered_activity_ids, ',') || '])) a ' ||
  		'LEFT JOIN (SELECT * FROM financial WHERE _active = true) f ' ||
  		'ON a.id = f.activity_id ' ||
  		'GROUP BY 1,2,3,4,5 ';

  RAISE NOTICE 'Execute statement: %', execute_statement;			

  FOR rec IN EXECUTE 'SELECT row_to_json(j) FROM (' || execute_statement || ')j' LOOP  		
	RETURN NEXT rec;
  END LOOP;
 
EXCEPTION WHEN others THEN 
  GET STACKED DIAGNOSTICS error_msg = MESSAGE_TEXT;  
    RAISE NOTICE 'Internal Error - Contact your DBA with the following error message: %', error_msg;
    
END;$$ LANGUAGE plpgsql;

/******************************************************************
7. remove project related functions or depercated functions
******************************************************************/
DROP FUNCTION IF EXISTS bmgf_global_search(text);
DROP FUNCTION IF EXISTS bmgf_infobox_project_info(integer, integer);
DROP FUNCTION IF EXISTS bmgf_locations_by_tax(integer, integer, character varying);
DROP FUNCTION IF EXISTS bmgf_project_list();
DROP FUNCTION IF EXISTS pmt_activate_project(integer, integer, boolean);
DROP FUNCTION IF EXISTS pmt_edit_project(integer, integer, json, boolean);
DROP FUNCTION IF EXISTS pmt_edit_project_contact(integer, integer, integer, pmt_edit_action);
DROP FUNCTION IF EXISTS pmt_edit_project_taxonomy(integer, character varying, character varying, character varying, pmt_edit_action);
DROP FUNCTION IF EXISTS pmt_edit_user_project_role(integer, integer, integer, integer, integer, boolean);
DROP FUNCTION IF EXISTS pmt_filter_locations(integer, character varying, character varying, character varying, date, date);
DROP FUNCTION IF EXISTS pmt_filter_orgs(character varying, character varying, character varying, date, date);
DROP FUNCTION IF EXISTS pmt_filter_projects(character varying, character varying, character varying, date, date);
DROP FUNCTION IF EXISTS pmt_infobox_activity(integer);
DROP FUNCTION IF EXISTS pmt_infobox_menu(text);
DROP FUNCTION IF EXISTS pmt_infobox_project_info(integer, integer);
DROP FUNCTION IF EXISTS pmt_project(integer);
DROP FUNCTION IF EXISTS pmt_project_listview(integer, character varying, character varying, character varying, date, date, text, integer, integer);
DROP FUNCTION IF EXISTS pmt_project_listview_ct(character varying, character varying, character varying, date, date);
DROP FUNCTION IF EXISTS pmt_project_users(integer);
DROP FUNCTION IF EXISTS pmt_projects();
DROP FUNCTION IF EXISTS pmt_stat_project_by_tax(integer, character varying, character varying, character varying, date, date);
DROP FUNCTION IF EXISTS pmt_validate_project(integer);
DROP FUNCTION IF EXISTS pmt_validate_projects(character varying);

-- update permissions
GRANT USAGE ON SCHEMA public TO pmt_read;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO pmt_read;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO pmt_read;
GRANT USAGE ON SCHEMA public TO pmt_write;
GRANT SELECT,INSERT ON ALL TABLES IN SCHEMA public TO pmt_write;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO pmt_write;