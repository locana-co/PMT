/******************************************************************
Change Script 3.0.10.58
1. update pmt_activity_count address bug returning zero when keyword
filter applied
******************************************************************/
INSERT INTO version(_version, _iteration, _changeset) VALUES (3.0, 10, 58);
-- select * from version order by _iteration desc, _changeset desc;

 /******************************************************************
1. update pmt_activity_count to only count parent activities
  SELECT * FROM pmt_activity_count('2237',null,null,null,null,'1-1-2002','12-31-2020',null,'26255,26257,26259',null);
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_activity_count(data_group_ids character varying, classification_ids character varying, org_ids character varying, imp_org_ids character varying, 
fund_org_ids character varying, start_date date, end_date date, unassigned_taxonomy_ids character varying, activity_ids character varying, boundary_filter json)
RETURNS SETOF pmt_json_result_type AS 
$$
DECLARE
  execute_statement text;
  select_statement_1 text;
  select_statement_2 text;
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

  -- get the filtered activity ids
  SELECT INTO filtered_activity_ids * FROM pmt_filter($1,$2,$3,$4,$5,$6,$7,$8);
  
  -- get the list of activity ids
  IF ($9 IS NOT NULL OR $9 <> '' ) THEN
    a_ids:= string_to_array($9, ',')::int[];
    SELECT INTO valid_activity_ids array_agg(id) FROM activity WHERE _active = true AND id = ANY(a_ids);
  END IF;
  
  -- get the filtered activity ids by boundary
  IF ($10 IS NOT NULL) THEN
    RAISE NOTICE 'json was not null';      
    FOR boundary_json IN (SELECT * FROM json_array_elements($10)) LOOP
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
  execute_statement:= 'SELECT sum(ct) as ct FROM ( ';

  select_statement_1 := ' SELECT CASE WHEN count(distinct location_id) > 0 THEN count(distinct activity_id) ELSE 0 END as ct FROM _filter_boundaries ' ||
		'WHERE parent_id IS NULL AND activity_id = ANY(ARRAY[' || array_to_string(filtered_activity_ids, ',') || ']) AND location_id IS NOT NULL ';
  select_statement_2 := ' SELECT CASE WHEN count(distinct location_id) > 0 THEN count(distinct parent_id) ELSE 0 END as ct FROM _filter_boundaries ' ||
		'WHERE parent_id IS NOT NULL AND activity_id = ANY(ARRAY[' || array_to_string(filtered_activity_ids, ',') || ']) AND location_id IS NOT NULL ';		

  -- add filter for boundary			
  IF array_length(boundary_activity_ids, 1) > 0 THEN
    select_statement_1:= select_statement_1 || ' AND activity_id = ANY(ARRAY[' || array_to_string(boundary_activity_ids, ',') || ']) ';
    select_statement_2:= select_statement_2 || ' AND activity_id = ANY(ARRAY[' || array_to_string(boundary_activity_ids, ',') || ']) ';
  END IF;

  -- add filter for activities in list
  IF array_length(valid_activity_ids, 1) > 0 THEN
    select_statement_1:= select_statement_1 || ' AND activity_id = ANY(ARRAY[' || array_to_string(valid_activity_ids, ',') || ']) ';
    select_statement_2:= select_statement_2 || ' AND activity_id = ANY(ARRAY[' || array_to_string(valid_activity_ids, ',') || ']) ';
  END IF;

  -- union the select statements
  execute_statement:= execute_statement || select_statement_1 || ' UNION ALL ' || select_statement_2 || ') as c';
  
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

