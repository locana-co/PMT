/******************************************************************
Change Script 3.0.10.35
1. update pmt_stat_activity_by_tax to allow region filter
2. update function pmt_stat_invest_by_funder to use boundary
over classifications, add limit parameter
3. create new function pmt_stat_by_org 
******************************************************************/
INSERT INTO version(_version, _iteration, _changeset) VALUES (3.0, 10, 35);
-- select * from version order by _iteration desc, _changeset desc;

/******************************************************************
1. update pmt_stat_activity_by_tax to allow region filter
   select * from pmt_stat_activity_by_tax(23,'768',null,null,null,15,74);   
   select * from pmt_stat_activity_by_tax(23,'768',null,null,null,16,896); 
   select * from pmt_stat_activity_by_tax(14,null,null,null,null,15,74); 
******************************************************************/
DROP FUNCTION IF EXISTS pmt_stat_activity_by_tax(integer, character varying, character varying, date, date);
CREATE OR REPLACE FUNCTION pmt_stat_activity_by_tax(taxonomy_id integer, data_group_ids character varying, classification_ids character varying, 
start_date date, end_date date, boundary_id integer, feature_id integer) RETURNS SETOF pmt_json_result_type AS
$$
DECLARE
  dg_ids int[];
  valid_dg_ids int[];
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
    where_statement:= 'WHERE id = ANY(ARRAY[' || array_to_string(filtered_activity_ids, ',') || ']) '|| 
				'AND id = ANY(ARRAY[' || array_to_string(feature_activity_ids, ',') || ']) ';
  ELSE
    where_statement:= 'WHERE id = ANY(ARRAY[' || array_to_string(filtered_activity_ids, ',') || ']) ';
  END IF;

  -- prepare the execution statement
  execute_statement:= 'SELECT CASE WHEN t.classification_id IS NULL THEN NULL ELSE t.classification_id END,  ' ||
			'CASE WHEN t.classification IS NULL THEN ''Unspecified'' ELSE t.classification END, ' ||
			'count(id) as count, sum(_amount) as sum FROM ' ||
			'(SELECT at.id, f._amount, at.classification_id FROM ' ||				
				'(SELECT id, classification_id ' ||
				'FROM _activity_taxonomies ' || where_statement ||
				') at ' ||
				'LEFT JOIN ' ||
				'(SELECT id, _amount ' ||
				'FROM _activity_financials '|| where_statement ||
				') f ' ||
				'ON at.id = f.id ' ||
			') a ' ||
			'LEFT JOIN ( ' ||
				'SELECT taxonomy_id, taxonomy, classification_id, classification  ' ||
				'FROM _taxonomy_classifications ' ||
				'WHERE taxonomy_id = ' || valid_taxonomy_id || ') as t ' ||
			'ON t.classification_id = a.classification_id ' ||
			'GROUP BY 1,2 ' ||
			'ORDER BY 4'; 
	
  RAISE NOTICE 'Execute statement: %', execute_statement;			

  FOR rec IN EXECUTE 'SELECT row_to_json(j) FROM (' || execute_statement || ')j' LOOP  		
	RETURN NEXT rec;
  END LOOP;
 
EXCEPTION WHEN others THEN 
  GET STACKED DIAGNOSTICS error_msg = MESSAGE_TEXT;  
    RAISE NOTICE 'Internal Error - Contact your DBA with the following error message: %', error_msg;
    
END;$$ LANGUAGE plpgsql;

/******************************************************************
2. update function pmt_stat_invest_by_funder to use boundary
over classifications
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
			'count(f.activity_id) as count, sum(f._amount) as sum ' ||
			'FROM ' ||
			'(SELECT activity_id, provider_id, _amount ' ||
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
3. create new function pmt_stat_by_org 
   select * from pmt_stat_by_org(null,null,null,null,497,null,null,5);
   select * from pmt_stat_by_org('769,768',null,null,null,497,15,74,5);
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_stat_by_org(data_group_ids character varying, classification_ids character varying, 
start_date date, end_date date, org_role_id integer, boundary_id integer, feature_id integer, limit_records integer) RETURNS SETOF pmt_json_result_type AS
$$
DECLARE
  valid_role_id integer; 
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

  -- validate and process org_role_id parameter (required)
  IF $5 IS NOT NULL THEN
    -- validate the organization role id
    SELECT INTO valid_role_id classification_id FROM _taxonomy_classifications WHERE taxonomy = 'Organisation Role' AND classification_id = $5;    
    IF valid_role_id IS NULL THEN
      FOR rec IN SELECT row_to_json(j) FROM( SELECT 'provided organization role id is invalid' AS error ) as j LOOP RETURN NEXT rec; END LOOP;
    END IF;
  ELSE
    FOR rec IN SELECT row_to_json(j) FROM( SELECT 'organization role id is required' AS error ) as j LOOP RETURN NEXT rec; END LOOP;
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
  SELECT INTO filtered_activity_ids * FROM pmt_filter($1,$2,null,null,null,$3,$4,null);

  IF valid_boundary_id IS NOT NULL AND valid_feature_id IS NOT NULL THEN
    -- get the activity ids for the feature
    SELECT INTO feature_activity_ids array_agg(activity_id) FROM _location_lookup ll WHERE ll.boundary_id = valid_boundary_id AND ll.feature_id = valid_feature_id;
  END IF;

  
  -- determine which where statement to use
  IF array_length(feature_activity_ids, 1) > 0 THEN
    where_statement:= 'AND id = ANY(ARRAY[' || array_to_string(filtered_activity_ids, ',') || ']) '|| 
				'AND id = ANY(ARRAY[' || array_to_string(feature_activity_ids, ',') || ']) ';
  ELSE
    where_statement:= 'AND id = ANY(ARRAY[' || array_to_string(filtered_activity_ids, ',') || ']) ';
  END IF;

  -- prepare the execution statement
  execute_statement:= 'SELECT organization_id as id, _name as name, _label as label, classification as role, count(DISTINCT id) as activity_count ' ||
			'FROM _activity_participants ' ||
			'WHERE classification_id = ' || valid_role_id || ' ' ||
			where_statement ||
			'GROUP BY 1,2,3,4 ' ||
			'ORDER BY 4 DESC ';
  
			
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