/******************************************************************
Change Script 3.0.10.56
1. update pmt_activity_ids_by_boundary to address errors in update to
return parent activities
******************************************************************/
INSERT INTO version(_version, _iteration, _changeset) VALUES (3.0, 10, 56);
-- select * from version order by _iteration desc, _changeset desc;

/******************************************************************
1. update pmt_activity_ids_by_boundary to address errors in update to
return parent activities
  SELECT * FROM pmt_activity_ids_by_boundary(12, 9,'2237',null,null,null,null,'1/1/2002','12/31/2020',null,'26288,26290,26303','[{"b":14,"ids":[2]}]');
  SELECT * FROM pmt_activity_ids_by_boundary(8, 1,'768',null,null,null,null,null,null,null,null,null);
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_activity_ids_by_boundary(boundary_id integer, feature_id integer, data_group_ids character varying, 
classification_ids character varying, org_ids character varying, imp_org_ids character varying, fund_org_ids character varying, start_date date, end_date date,
unassigned_taxonomy_ids character varying, activity_ids character varying, boundary_filter json)
RETURNS SETOF pmt_json_result_type AS 
$$
DECLARE
  valid_boundary_id integer;
  execute_statement text;
  where_child_statement text;
  where_parent_statement text;
  filtered_activity_ids int[];
  boundary_json json;
  boundary_filters text[];
  boundary_statement text;
  boundary_activity_ids int[];
  a_ids int[];
  valid_activity_ids int[];
  json record; 
  rec record;
  error_msg text;
BEGIN  
  -- validate and process boundary_id parameter
  IF $1 IS NOT NULL AND $2 IS NOT NULL THEN
    SELECT INTO valid_boundary_id id FROM boundary WHERE id = $1;    
    -- exit if boundary id is not valid
    IF valid_boundary_id IS NULL THEN 
       FOR rec IN SELECT row_to_json(j) FROM( SELECT 'invalid parameter' AS error ) as j
	LOOP
        RETURN NEXT rec;    
       END LOOP;
    END IF;
  ELSE
    FOR rec IN SELECT row_to_json(j) FROM( SELECT 'missing required parameter' AS error ) as j
    LOOP
      RETURN NEXT rec;    
    END LOOP;    
  END IF;

  -- get the filtered activity ids
  SELECT INTO filtered_activity_ids * FROM pmt_filter($3,$4,$5,$6,$7,$8,$9,$10);

  -- get the list of activity ids
  IF ($11 IS NOT NULL OR $11 <> '' ) THEN
    a_ids:= string_to_array($11, ',')::int[];
    SELECT INTO valid_activity_ids array_agg(id) FROM activity WHERE _active = true AND id = ANY(a_ids);
  END IF;
  
  -- get the filtered activity ids by boundary
  IF ($12 IS NOT NULL) THEN 
    FOR boundary_json IN (SELECT * FROM json_array_elements($12)) LOOP
      FOR json IN (SELECT * FROM json_each_text(boundary_json)) LOOP
        -- RAISE NOTICE 'JSON key/value: %', lower(json.key) || ':' || json.value;          
        CASE json.key::text 
          WHEN 'b' THEN
            boundary_statement := ' (ll.boundary_id = ' || json.value::int;
          WHEN 'ids' THEN
            boundary_statement := boundary_statement || ' AND ll.feature_id = ANY(ARRAY' || json.value || ')) ';
            boundary_filters := array_append(boundary_filters, boundary_statement);
          ELSE
        END CASE;
      END LOOP;
    END LOOP;
    IF array_length(filtered_activity_ids, 1) > 0 THEN
      EXECUTE 'SELECT array_agg(activity_id)::int[] FROM _location_lookup ll WHERE' ||  array_to_string(boundary_filters, 'OR') INTO boundary_activity_ids;
    END IF;
  END IF;
  
  -- prepare the execution statement
  execute_statement:= 'SELECT id, _title FROM activity WHERE parent_id IS NULL AND ';

  where_child_statement:= '( ARRAY[id] <@ ( SELECT array_agg(DISTINCT activity_id) FROM _filter_boundaries WHERE activity_id = ANY(ARRAY[' || array_to_string(filtered_activity_ids, ',') || ']) ';
  where_parent_statement:= 'OR ARRAY[id] <@ ( SELECT array_agg(DISTINCT parent_id) FROM _filter_boundaries WHERE activity_id = ANY(ARRAY[' || array_to_string(filtered_activity_ids, ',') || ']) ';
  
  -- add filter for boundary		
  IF array_length(boundary_activity_ids, 1) > 0 THEN
    where_child_statement:= where_child_statement || 'AND activity_id = ANY(ARRAY[' || array_to_string(boundary_activity_ids, ',') || ']) ';
    where_parent_statement:= where_parent_statement || 'AND parent_id = ANY(ARRAY[' || array_to_string(boundary_activity_ids, ',') || ']) ';
  END IF;
  
  -- add filter for activities in list
  IF array_length(valid_activity_ids, 1) > 0 THEN
    where_child_statement:= where_child_statement || 'AND activity_id = ANY(ARRAY[' || array_to_string(valid_activity_ids, ',') || ']) ';
    where_parent_statement:= where_parent_statement || 'AND parent_id = ANY(ARRAY[' || array_to_string(valid_activity_ids, ',') || ']) ';
  END IF;
  
  where_child_statement:= where_child_statement || 'AND boundary_id = ' || valid_boundary_id || ' AND feature_id = ' || $2 || ')';
  where_parent_statement:= where_parent_statement || 'AND boundary_id = ' || valid_boundary_id || ' AND feature_id = ' || $2 || ')';  

  execute_statement:= execute_statement || where_child_statement || where_parent_statement;

  RAISE NOTICE 'Execute statement: %', execute_statement;			

  FOR rec IN EXECUTE 'SELECT row_to_json(j) FROM (' || execute_statement || '))j' LOOP  		
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

