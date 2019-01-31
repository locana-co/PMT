/******************************************************************
Change Script 3.0.10.27
1. update pmt_partner_pivot to handle apostrophy in fields
******************************************************************/
INSERT INTO version(_version, _iteration, _changeset) VALUES (3.0, 10, 27);
-- select * from version order by _iteration desc, _changeset desc;

/******************************************************************
1. update pmt_partner_pivot to handle apostrophy in fields
   select * from pmt_partner_pivot(15,18,496,'2209,2210',null,null,null);
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
  
  -- get the filtered activity ids
  SELECT INTO filtered_activity_ids * FROM pmt_filter($4,$5,null,null,null,$6,$7,null);

  -- get the column headers
  SELECT INTO column_headers array_agg(quote_literal(classification))::text[] FROM _taxonomy_classifications WHERE taxonomy_id = valid_column_taxonomy_id;
  
  -- prepare the execution statement
  execute_statement:= 'SELECT '''' as c1,';
  col_count :=2;
  
  FOREACH col IN ARRAY column_headers LOOP
    execute_statement:= execute_statement || col || ' as c' || col_count || ','; 
    col_count := col_count + 1;
  END LOOP;

  execute_statement:= execute_statement || '''Unspecified'' as c' || col_count || ' UNION ALL SELECT distinct * FROM ( SELECT rows.classification::text, ';
  
  FOREACH col IN ARRAY column_headers LOOP
    execute_statement:= execute_statement || 'array_to_string(array_remove(array_agg(distinct case when cols.classification = ' || col || 
			' then org._label end), NULL), '', '')::text as ' || quote_ident(col) || ',';			
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

-- update permissions
GRANT USAGE ON SCHEMA public TO pmt_read;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO pmt_read;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO pmt_read;
GRANT USAGE ON SCHEMA public TO pmt_write;
GRANT SELECT,INSERT ON ALL TABLES IN SCHEMA public TO pmt_write;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO pmt_write;