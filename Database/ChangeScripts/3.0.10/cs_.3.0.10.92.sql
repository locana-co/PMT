/******************************************************************
Change Script 3.0.10.92
1. update pmt_org_inuse function to remove location requirement
2. update function pmt_stat_invest_by_funder properly filter locations
with child activities
******************************************************************/
INSERT INTO version(_version, _iteration, _changeset) VALUES (3.0, 10, 92);
-- select * from version order by _iteration desc, _changeset desc;

/******************************************************************
1. update pmt_org_inuse function to remove location requirement
  SELECT * FROM pmt_org_inuse('2237','497');  
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_org_inuse(data_group_ids character varying, org_role_ids character varying)
RETURNS SETOF pmt_json_result_type AS $$
DECLARE
  dg_ids int[];
  valid_dg_ids int[];
  role_ids int[];
  valid_role_ids int[];
  built_where text[];
  execute_statement text;
  i integer;
  rec record;
BEGIN
  -- validate and process data_group_ids parameter
  IF $1 IS NOT NULL OR $1 <> '' THEN
    dg_ids:= string_to_array($1, ',')::int[];
    -- validate the data groups ids
    SELECT INTO valid_dg_ids array_agg(id)::int[] FROM classification WHERE taxonomy_id = 1 AND _active=true AND id = ANY(dg_ids);
  END IF;
  
  -- validate org role ids parameter
  IF $2 IS NOT NULL OR $2 <> '' THEN
    role_ids:= string_to_array($2, ',')::int[];
    -- validate the org role ids
    SELECT INTO valid_role_ids array_agg(id)::int[] FROM classification WHERE taxonomy_id = (SELECT id FROM taxonomy WHERE _name = 'Organisation Role') 
	AND _active=true AND id = ANY(role_ids);
  END IF;
  
  execute_statement :=
    'SELECT organization_id as id, organization as n, count(DISTINCT activity_id) as ct, lower(substring(organization, 1, 1)) as o ' ||
    'FROM (SELECT * FROM _organization_lookup) as foo ';
  
  built_where := null;

  IF array_length(valid_dg_ids, 1) > 0 THEN			
    built_where := array_append(built_where, 'data_group_id = ANY(ARRAY[' || array_to_string(valid_dg_ids, ',') || ']) ');
  END IF;
  
  IF array_length(valid_role_ids, 1) > 0 THEN
    built_where := array_append(built_where, 'classification_id = ANY(ARRAY[' || array_to_string(valid_role_ids, ',') || ']) ');
  END IF;

  IF array_length(built_where, 1) > 0 THEN
    execute_statement := execute_statement || 'WHERE ' || array_to_string(built_where, ' AND ');
  END IF;

    execute_statement := execute_statement || 'GROUP BY 1,2 ORDER BY 2 ';
   
  RAISE NOTICE 'Execute statement: %', execute_statement;			

  FOR rec IN EXECUTE 'SELECT row_to_json(j) FROM (' || execute_statement || ')j' LOOP  		
    RETURN NEXT rec;
  END LOOP;
	
END;$$ LANGUAGE plpgsql;


/******************************************************************
2. update function pmt_stat_invest_by_funder properly filter locations
with child activities
   select * from pmt_stat_invest_by_funder(null,null,null,null,null,null,5);
   select * from pmt_stat_invest_by_funder('2237',null,null,null,15,74,10);			
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
    SELECT INTO feature_activity_ids array_agg(id) FROM (SELECT CASE WHEN a.parent_id IS NOT NULL THEN a.parent_id ELSE a.id END as id FROM _location_lookup ll JOIN activity a ON ll.activity_id = a.id WHERE ll.boundary_id = valid_boundary_id AND ll.feature_id = valid_feature_id) as foo;
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



-- update permissions
GRANT USAGE ON SCHEMA public TO pmt_read;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO pmt_read;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO pmt_read;
GRANT USAGE ON SCHEMA public TO pmt_write;
GRANT SELECT,INSERT ON ALL TABLES IN SCHEMA public TO pmt_write;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO pmt_write;