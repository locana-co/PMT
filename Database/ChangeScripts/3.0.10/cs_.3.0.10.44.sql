/******************************************************************
Change Script 3.0.10.44
1. update pmt_stat_activity_by_tax to add toggle for aggregating
children
******************************************************************/
INSERT INTO version(_version, _iteration, _changeset) VALUES (3.0, 10, 44);
-- select * from version order by _iteration desc, _changeset desc;

/******************************************************************
1. update pmt_stat_activity_by_tax address errors in calculations
   select * from pmt_stat_activity_by_tax(17,'768',null,null,null,null,null,true);  
   select * from pmt_stat_activity_by_tax(23,'768',null,null,null,null,null,false); 
   select * from pmt_stat_activity_by_tax(23,'768',null,null,null,15,74,false);
   select * from pmt_stat_activity_by_tax(14,'2208',null,null,null,15,74,false); 
******************************************************************/
DROP FUNCTION IF EXISTS pmt_stat_activity_by_tax(integer, character varying, character varying, date, date, integer, integer);
CREATE OR REPLACE FUNCTION pmt_stat_activity_by_tax(taxonomy_id integer, data_group_ids character varying, classification_ids character varying, 
start_date date, end_date date, boundary_id integer, feature_id integer, agg_children boolean) RETURNS SETOF pmt_json_result_type AS
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
  -- validate and process agg_children parameter
  IF $8 IS NULL THEN
    -- default is false
    agg_children:= false;
  END IF; 
  
  -- get the filtered activity ids
  SELECT INTO filtered_activity_ids * FROM pmt_filter($2,$3,null,null,null,$4,$5,null);

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
  execute_statement:= 'SELECT CASE WHEN t.classification_id IS NULL THEN NULL ELSE t.classification_id END,  ' ||   
			'CASE WHEN t.classification IS NULL THEN ''Unspecified'' ELSE t.classification END,  ' ||   
			'count(distinct a.id), sum(a.amount) FROM  ' || 
			'(SELECT a.id, sum(f._amount) as amount FROM  ' || 
			'(SELECT id FROM activity WHERE _active = true AND parent_id IS NULL ' || where_statement ||
			') a  ' || 
			'LEFT JOIN  ' || 
			'(SELECT id, _amount FROM _activity_financials WHERE parent_id IS NULL AND ' ||
			'(transaction_type IS NULL OR transaction_type = '''' OR transaction_type IN (''Incoming Funds'',''Commitment'')) ' || where_statement ||
			') f  ' || 
			'ON a.id = f.id  ' || 
			'GROUP BY 1) a  ' || 
			'LEFT JOIN  ' || 
			'(SELECT id, parent_id, classification_id, classification FROM _activity_taxonomies WHERE taxonomy_id = ' || valid_taxonomy_id || ' ' || where_statement ||
			') t  ';
			
  IF agg_children THEN
    execute_statement:= execute_statement || 'ON a.id = t.id OR a.id = t.parent_id  ';
  ELSE
    execute_statement:= execute_statement || 'ON a.id = t.id  ';
  END IF;			

  execute_statement:= execute_statement || 'GROUP BY 1,2 ORDER BY 4'; 
	
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

