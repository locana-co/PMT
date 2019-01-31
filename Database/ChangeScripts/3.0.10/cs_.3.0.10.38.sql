/******************************************************************
Change Script 3.0.10.38
1. create pmt_activity_by_invest
******************************************************************/
INSERT INTO version(_version, _iteration, _changeset) VALUES (3.0, 10, 38);
-- select * from version order by _iteration desc, _changeset desc;

/******************************************************************
1. create pmt_activity_by_invest function to return top x activities
by investment amount
   select * from pmt_activity_by_invest(null,null,null,null,null,null,5);
   select * from pmt_activity_by_invest('2237',null,null,null,15,74,5);  
   select * from pmt_activity_by_invest('2237',null,null,null,16,896,5);  
   select * from pmt_activity_by_invest('2237',null,null,null,16,891,5);  
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_activity_by_invest(data_group_ids character varying, classification_ids character varying, 
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
    where_statement:= 'WHERE _active = true AND id = ANY(ARRAY[' || array_to_string(filtered_activity_ids, ',') || ']) '|| 
				'AND id = ANY(ARRAY[' || array_to_string(feature_activity_ids, ',') || ']) ';
  ELSE
    where_statement:= 'WHERE _active = true AND id = ANY(ARRAY[' || array_to_string(filtered_activity_ids, ',') || ']) ';
  END IF;
  
  -- prepare the execution statement
  execute_statement:= 'SELECT a.id, a._title as title, f.investment  ' ||
			',(SELECT array_to_json(array_agg(row_to_json(t))) FROM (   ' ||
			'SELECT classification as role, array_agg(_name) as name, array_agg(_label) as label  ' ||
			'FROM _activity_participants  ' ||
			'WHERE id = a.id  ' ||
			'GROUP BY 1  ' ||
			') t ) as organizations  ' || 
			'FROM  ' ||
			'(SELECT id, _title  ' ||
			'FROM activity  ' ||
			 where_statement || ') a  ' ||
			'LEFT JOIN  ' ||
			'(SELECT activity_id, sum(_amount) as investment  ' ||
			'FROM financial  ' ||
			'WHERE _active = true  ' ||
			'GROUP BY 1 ) f  ' ||
			'ON a.id = f.activity_id  ' ||
			'ORDER BY 3 DESC';

			
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

