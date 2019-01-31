/******************************************************************
Change Script 3.0.10.54
1. update pmt_filter function to address mutliple classification filter bug
2. update function pmt_stat_invest_by_funder to return activity ids
3. create function pmt_activity_titles to return title list for activities
******************************************************************/
INSERT INTO version(_version, _iteration, _changeset) VALUES (3.0, 10, 54);
-- select * from version order by _iteration desc, _changeset desc;

/*************************************************************************
  1. update pmt_filter function to address mutliple classification filter bug
     select * from pmt_filter('768','816,819','13','','','1/1/2012','12/31/2018','22');
     select * from pmt_filter(null,null,null,null,null,null,null,null);
*************************************************************************/
CREATE OR REPLACE FUNCTION pmt_filter(data_group_ids character varying, classification_ids character varying, org_ids character varying,
imp_org_ids character varying, fund_org_ids character varying, start_date date, end_date date, unassigned_taxonomy_ids character varying) RETURNS integer[] AS 
$$
DECLARE 
  execute_statement text;
  org_statement text;
  tax_statement text;
  activity_statement text;
  dg_ids int[];
  c_ids int[];
  imp_ids int[];
  fund_ids int[];
  o_ids int[];
  t_ids int[];
  valid_dg_ids int[];  
  valid_c_ids int[];  
  valid_imp_ids int[];  
  valid_fund_ids int[]; 
  valid_o_ids int[];
  valid_t_ids int[];
  dg_where text;
  org_where text[];
  tax_where text[];
  date_where text[];
  unassigned_where text;
  cls record;
  activities_id int[];
  error_msg text;
BEGIN 

  -- validate and process data_group_ids parameter
  IF $1 IS NOT NULL THEN
    dg_ids:= string_to_array($1, ',')::int[];
    -- validate the data groups id
    SELECT INTO valid_dg_ids array_agg(id)::int[] FROM classification WHERE taxonomy_id = 1 AND _active=true AND id = ANY(dg_ids);
  END IF;
  -- validate and process classification_ids parameter
  IF $2 IS NOT NULL THEN
    c_ids:= string_to_array($2, ',')::int[];
    -- validate the classification ids
    SELECT INTO valid_c_ids array_agg(id)::int[] FROM classification WHERE _active=true AND id = ANY(c_ids);
  END IF;
  -- validate and process org_ids parameter
  IF $3 IS NOT NULL THEN
    o_ids:= string_to_array($3, ',')::int[];
    -- validate the org ids
    SELECT INTO valid_o_ids array_agg(id)::int[] FROM organization WHERE _active=true AND id = ANY(o_ids);
  END IF;
  -- validate and process imp_org_ids parameter
  IF $4 IS NOT NULL THEN
    imp_ids:= string_to_array($4, ',')::int[];
    -- validate the org ids
    SELECT INTO valid_imp_ids array_agg(id)::int[] FROM organization WHERE _active=true AND id = ANY(imp_ids);
  END IF;
  -- validate and process fund_org_ids parameter
  IF $5 IS NOT NULL THEN
    fund_ids:= string_to_array($5, ',')::int[];
    -- validate the org ids
    SELECT INTO valid_fund_ids array_agg(id)::int[] FROM organization WHERE _active=true AND id = ANY(fund_ids);
  END IF;
  -- validate and process unassigned_taxonomy_ids parameter
  IF $8 IS NOT NULL THEN
    t_ids:= string_to_array($8, ',')::int[];
    -- validate the taxonomy ids
    SELECT INTO valid_t_ids array_agg(id)::int[] FROM taxonomy WHERE _active=true AND id = ANY(t_ids);
  END IF;
  
  -- restrict returned results by data group id(s)
  IF array_length(valid_dg_ids, 1) > 0 THEN
    dg_where := 'data_group_id = ANY(ARRAY[' || array_to_string(valid_dg_ids, ',') || ']) ';
  END IF;
  -- restrict returned results by classification id(s)
  IF array_length(valid_c_ids, 1) > 0 THEN
    FOR cls IN EXECUTE 'SELECT taxonomy_id, array_agg(id) as c FROM classification WHERE _active = true AND id = ANY(ARRAY[' || array_to_string(valid_c_ids, ',') || ']) GROUP BY 1 ORDER BY 1' LOOP
      tax_where := array_append(tax_where, '(taxonomy_id = ' || cls.taxonomy_id || ' AND c_ids @> ARRAY[' || array_to_string(cls.c, ',') || '])');
    END LOOP;
  END IF;
  -- restrict returned results by org id(s)
  IF array_length(valid_o_ids, 1) > 0 THEN
    org_where := array_append(org_where, '(organization_ids && ARRAY[' || array_to_string(valid_o_ids, ',') || '])');
  END IF;
  -- restrict returned results by implmenting org id(s)
  IF array_length(valid_imp_ids, 1) > 0 THEN
    org_where := array_append(org_where, '(organization_ids && ARRAY[' || array_to_string(valid_imp_ids, ',') || '] AND role = ''Implementing'')');
  END IF;
  -- restrict returned results by funding org id(s)
  IF array_length(valid_fund_ids, 1) > 0 THEN
    org_where := array_append(org_where, '(organization_ids && ARRAY[' || array_to_string(valid_fund_ids, ',') || '] AND role = ''Funding'')');
  END IF;
  -- restrict returned results by start date
  IF $6 IS NOT NULL THEN
    date_where := array_append(date_where, '_start_date >= ' || quote_literal($6));
  END IF;
  -- restrict returned results by end date
  IF $7 IS NOT NULL THEN
    date_where := array_append(date_where, '_end_date <= ' || quote_literal($7));
  END IF;
  -- restrict returned results by unassigned taxonomy id(s)
  IF array_length(valid_t_ids, 1) > 0 THEN
    unassigned_where := 'unassigned @> ARRAY[' || array_to_string(valid_t_ids, ',') || '] ';
  END IF;

  -- RAISE NOTICE 'Data group where statement: %', dg_where;
  -- RAISE NOTICE 'Classification where statement: %', tax_where;
  -- RAISE NOTICE 'Organization where statement: %', org_where;
  -- RAISE NOTICE 'Date where statement: %', date_where;

  -- prepare _filter_taxonomies statement
  IF array_length(tax_where, 1) > 0 THEN
    tax_statement := 'SELECT activity_id FROM (SELECT activity_id, taxonomy_id, array_agg(DISTINCT classification_id) as c_ids FROM _filter_taxonomies GROUP BY 1,2) as t ' 
		|| 'WHERE (' || array_to_string(tax_where, ' OR ') || ') GROUP BY 1 HAVING count(activity_id) > ' || array_length(tax_where, 1) - 1;
  END IF;
  -- prepare _filter_organizations statement
  IF array_length(org_where, 1) > 0 THEN
    org_statement := 'SELECT activity_id FROM _filter_organizations WHERE (' || array_to_string(org_where, ' OR ') || ') GROUP BY activity_id HAVING count(activity_id) >= ' || array_length(org_where, 1);
  END IF;
  -- prepare activity statement
  activity_statement:= 'SELECT DISTINCT id as activity_id FROM activity WHERE _active = true ';
  IF array_length(date_where, 1) > 0 THEN
    activity_statement := activity_statement || 'AND (' || array_to_string(date_where, ' AND ') || ') ';
  END IF;
  IF dg_where IS NOT NULL THEN
    activity_statement := activity_statement || 'AND (' || dg_where || ') ';
  END IF;   

  -- build execution statement
  execute_statement := 'SELECT array_agg(DISTINCT activity_id)::int[] as activities FROM ( ';
  -- RAISE NOTICE 'Execute statement begins: %', execute_statement;
  -- two filters, requires a join
  IF tax_statement IS NOT NULL AND org_statement IS NOT NULL THEN
    execute_statement := execute_statement || 'SELECT activity_id, count(*) ct FROM ( ' || tax_statement || ' UNION ALL ' || org_statement ||
	') a GROUP BY 1 ';
    -- add the unassigned taxonomy filter if needed
    IF unassigned_where IS NOT NULL THEN
      execute_statement := execute_statement || 'UNION ALL SELECT activity_id, 2 FROM _filter_unassigned WHERE ' || unassigned_where || ' ';
    END IF;  
    execute_statement := execute_statement || ') a WHERE ct > 1 AND activity_id IN ( ' || activity_statement || ' )';     	
    RAISE NOTICE 'Execute statement (two filters): %', execute_statement;
  ELSE
    -- one filter
    IF tax_statement IS NOT NULL OR org_statement IS NOT NULL THEN
      IF tax_statement IS NOT NULL THEN
        execute_statement := execute_statement || tax_statement;
      END IF;
      IF org_statement IS NOT NULL THEN
        execute_statement := execute_statement || org_statement;
      END IF;
      -- add the unassigned taxonomy filter if needed
      IF unassigned_where IS NOT NULL THEN
        execute_statement := execute_statement || 'UNION ALL SELECT activity_id FROM _filter_unassigned WHERE ' || unassigned_where;
      END IF; 
      execute_statement := execute_statement ||  ') a WHERE activity_id IN ( ' || activity_statement || ' )';
      RAISE NOTICE 'Execute statement (one filter): %', execute_statement;
    END IF;
  END IF;
  
  -- no filters
  IF tax_statement IS NULL AND org_statement IS NULL THEN
    -- add the unassigned taxonomy filter if needed
    IF unassigned_where IS NOT NULL THEN
      execute_statement := execute_statement || 'SELECT activity_id FROM _filter_unassigned WHERE ' || unassigned_where || 
      ') a WHERE activity_id IN ( ' || activity_statement || ' )';
    ELSE
      execute_statement := execute_statement || activity_statement || ' ) as a'; 
    END IF;     
    RAISE NOTICE 'Execute statement (no filters): %', execute_statement;   
  END IF;
  
  RAISE NOTICE 'Execute statement: %', execute_statement;
  EXECUTE execute_statement INTO activities_id;
  RETURN activities_id;

EXCEPTION WHEN others THEN 
  GET STACKED DIAGNOSTICS error_msg = MESSAGE_TEXT;  
    RAISE NOTICE 'Internal Error - Contact your DBA with the following error message: %', error_msg;
    	
END;$$ LANGUAGE plpgsql;


/******************************************************************
2. update function pmt_stat_invest_by_funder to return activity ids
   select * from pmt_stat_invest_by_funder(null,null,null,null,null,null,5);
   select * from pmt_stat_invest_by_funder('2237',null,null,null,15,74,5);			
******************************************************************/
DROP FUNCTION IF EXISTS pmt_stat_invest_by_funder(character varying, character varying, date, date);
CREATE OR REPLACE FUNCTION pmt_stat_invest_by_funder(data_group_ids character varying, classification_ids character varying, 
start_date date, end_date date, boundary_id integer, feature_id integer, limit_records integer) RETURNS SETOF pmt_json_result_type AS
$$
DECLARE
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

  -- validate and process boundary_id parameter
  IF $5 IS NOT NULL THEN
    -- validate the boundary id
    SELECT INTO valid_boundary_id id FROM boundary WHERE _active = true AND id = $5;    
    IF valid_boundary_id IS NULL THEN
      FOR rec IN SELECT row_to_json(j) FROM( SELECT 'provided boundary id is invalid' AS error ) as j LOOP RETURN NEXT rec; END LOOP;
    END IF;
  END IF;
  -- validate and process feature_id parameter
  IF $6 IS NOT NULL THEN
     SELECT INTO spatial_table _spatial_table FROM boundary WHERE id = valid_boundary_id; 
    -- validate the feature id
    EXECUTE 'SELECT id FROM '|| spatial_table ||' WHERE _active = true AND id = ' || $6 INTO valid_feature_id;  
    IF valid_feature_id IS NULL THEN
      FOR rec IN SELECT row_to_json(j) FROM( SELECT 'provided feature id is invalid' AS error ) as j LOOP RETURN NEXT rec; END LOOP;
    END IF;
  END IF;  

  -- get the filtered activity ids
  SELECT INTO filtered_activity_ids * FROM pmt_filter($1,$2,null,null,null,$3,$4,null);

  IF valid_boundary_id IS NOT NULL AND valid_feature_id IS NOT NULL THEN
    -- get the activity ids for the feature
    SELECT INTO feature_activity_ids array_agg(activity_id) FROM _location_lookup ll WHERE ll.boundary_id = valid_boundary_id AND ll.feature_id = valid_feature_id;
  END IF;

  
  -- determine which where statement to use
  IF array_length(feature_activity_ids, 1) > 0 THEN
    where_statement:= 'WHERE _active = true AND activity_id = ANY(ARRAY[' || array_to_string(filtered_activity_ids, ',') || ']) '|| 
				'AND activity_id = ANY(ARRAY[' || array_to_string(feature_activity_ids, ',') || ']) ';
  ELSE
    where_statement:= 'WHERE _active = true AND activity_id = ANY(ARRAY[' || array_to_string(filtered_activity_ids, ',') || ']) ';
  END IF;

  -- prepare the execution statement
  execute_statement:= 'SELECT o.id, ' ||
			'CASE WHEN o._name IS NULL OR o._name = '''' THEN ''Unknown/Multiple Funders'' ELSE o._name END as name, ' ||
			'CASE WHEN o._name IS NULL OR o._name = '''' THEN ''Unknown/Multiple Funders'' ELSE o._label END as label,  ' ||
			'count(DISTINCT f.activity_id) as count, sum(f._amount) as sum, array_agg(DISTINCT f.activity_id) as a_ids ' ||
			'FROM ' ||
			'(SELECT distinct activity_id, provider_id, _amount ' ||
			'FROM financial ' ||
			 where_statement || ') f ' ||
			'LEFT JOIN ' ||
			'(SELECT id, _name, _label ' ||
			'FROM organization ' ||
			'WHERE _active = true) o ' ||
			'ON f.provider_id = o.id ' ||
			'GROUP BY 1,2,3 ' ||
			'ORDER BY 5 DESC';

			
  IF limit_records > 0 THEN
    execute_statement:= execute_statement || ' LIMIT ' || limit_records;
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
3. create function pmt_activity_titles to return title list for activities
   select * from pmt_activity_titles(ARRAY[26271,26283,26284,26286,26287,26288,26322,26323,26324,26325]);			
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_activity_titles(activity_ids integer[]) RETURNS SETOF pmt_json_result_type AS
$$
DECLARE   
  rec record;
  error_msg text;
BEGIN

  IF $1 IS NULL THEN    
    FOR rec IN SELECT row_to_json(j) FROM( SELECT 'Must provide valid array of activity ids as parameter.' AS error ) as j LOOP RETURN NEXT rec; END LOOP;
  ELSE
    IF array_length($1, 1) < 1 THEN
      FOR rec IN SELECT row_to_json(j) FROM( SELECT 'Must provide valid array of activity ids as parameter.' AS error ) as j LOOP RETURN NEXT rec; END LOOP;
    END IF;    
  END IF;
  
  FOR rec IN SELECT row_to_json(j) FROM ( SELECT id, _title FROM activity WHERE id = ANY($1))j LOOP  		
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