/******************************************************************
Change Script 3.0.10.60
1. update function pmt_stat_by_org to return activity ids
******************************************************************/
INSERT INTO version(_version, _iteration, _changeset) VALUES (3.0, 10, 60);
-- select * from version order by _iteration desc, _changeset desc;

/******************************************************************
1. update function pmt_stat_by_org to return activity ids
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
  execute_statement:= 'SELECT organization_id as id, _name as name, _label as label, classification as role, count(DISTINCT id) as activity_count, array_agg(DISTINCT id) as a_ids ' ||
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