/******************************************************************
Change Script 3.0.10.55
1. update _filter_boundaries to add parent_id
2. update pmt_locations_for_boundaries return parent activity counts
3. update pmt_activity_ids_by_boundary only return parent activities
4. update pmt_activity_count to only count parent activities
******************************************************************/
INSERT INTO version(_version, _iteration, _changeset) VALUES (3.0, 10, 55);
-- select * from version order by _iteration desc, _changeset desc;

 /******************************************************************
1. update _filter_boundaries to add parent_id
******************************************************************/
DROP VIEW IF EXISTS _filter_boundaries;
CREATE OR REPLACE VIEW _filter_boundaries AS 
SELECT a.id as activity_id, a.parent_id, a.data_group_id, l.id as location_id, lb.feature_id, lb.boundary_id
  FROM (SELECT id, data_group_id, parent_id FROM activity WHERE _active = true) a
  LEFT JOIN (SELECT id, activity_id FROM location WHERE _active = true) l
  ON a.id = l.activity_id
  LEFT JOIN location_boundary lb 
  ON l.id = lb.location_id;  
  
 /******************************************************************
2. update pmt_locations_for_boundaries return parent activity counts
  SELECT * FROM pmt_locations_for_boundaries(8,'768',null,null,null,null,null,null,null,null,null); 
  SELECT * FROM pmt_locations_for_boundaries(8,'768','797',null,null,null,'1/1/2012','12/31/2018',null,null,null)
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_locations_for_boundaries(boundary_id integer, data_group_ids character varying,
  classification_ids character varying, org_ids character varying, imp_org_ids character varying, fund_org_ids character varying, 
  start_date date, end_date date, unassigned_taxonomy_ids character varying, activity_ids character varying, boundary_filter json)
RETURNS SETOF pmt_json_result_type AS 
$$
DECLARE
  valid_boundary_id integer; 
  execute_statement text;
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
  IF $1 IS NOT NULL THEN
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
  SELECT INTO filtered_activity_ids * FROM pmt_filter($2,$3,$4,$5,$6,$7,$8,$9);
   
  -- get the list of activity ids
  IF ($10 IS NOT NULL OR $10 <> '' ) THEN
    a_ids:= string_to_array($10, ',')::int[];
    SELECT INTO valid_activity_ids array_agg(id) FROM activity WHERE _active = true AND id = ANY(a_ids);
  END IF;
  
  -- get the filtered activity ids by boundary
  IF ($11 IS NOT NULL) THEN
    RAISE NOTICE 'json was not null';      
    FOR boundary_json IN (SELECT * FROM json_array_elements($11)) LOOP
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
  execute_statement:= 'SELECT feature_id as id, count(distinct CASE WHEN parent_id IS NULL THEN activity_id WHEN parent_id IS NOT NULL THEN parent_id ELSE NULL END) as p, ' ||
		'count(distinct activity_id) as a, count(distinct location_id) as l, boundary_id as b FROM _filter_boundaries ' ||
		'WHERE activity_id = ANY(ARRAY[' || array_to_string(filtered_activity_ids, ',') || ']) ';

  -- add filter for boundary		
  IF array_length(boundary_activity_ids, 1) > 0 THEN
    execute_statement:= execute_statement || 'AND activity_id = ANY(ARRAY[' || array_to_string(boundary_activity_ids, ',') || ']) ';
  END IF;

  -- add filter for activities in list
  IF array_length(valid_activity_ids, 1) > 0 THEN
    execute_statement:= execute_statement || 'AND activity_id = ANY(ARRAY[' || array_to_string(valid_activity_ids, ',') || ']) ';
  END IF;
  
  execute_statement:= execute_statement || 'AND boundary_id = ' || valid_boundary_id || ' GROUP BY 1,5';

  RAISE NOTICE 'Execute statement: %', execute_statement;			

  FOR rec IN EXECUTE 'SELECT row_to_json(j) FROM (' || execute_statement || ')j' LOOP  		
	RETURN NEXT rec;
  END LOOP;

EXCEPTION WHEN others THEN 
  GET STACKED DIAGNOSTICS error_msg = MESSAGE_TEXT;  
    RAISE NOTICE 'Internal Error - Contact your DBA with the following error message: %', error_msg;

END;$$ LANGUAGE plpgsql;


/******************************************************************
3. update pmt_activity_ids_by_boundary only return parent activities
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
  execute_statement:= 'SELECT id, _title FROM activity WHERE parent_id IS NULL AND ARRAY[id] <@ ( SELECT array_agg(DISTINCT activity_id) FROM _filter_boundaries ' ||
		'WHERE activity_id = ANY(ARRAY[' || array_to_string(filtered_activity_ids, ',') || ']) ';

  -- add filter for boundary		
  IF array_length(boundary_activity_ids, 1) > 0 THEN
    execute_statement:= execute_statement || 'AND activity_id = ANY(ARRAY[' || array_to_string(boundary_activity_ids, ',') || ']) ';
  END IF;
  
  -- add filter for activities in list
  IF array_length(valid_activity_ids, 1) > 0 THEN
    execute_statement:= execute_statement || 'AND activity_id = ANY(ARRAY[' || array_to_string(valid_activity_ids, ',') || ']) ';
  END IF;
  
  execute_statement:= execute_statement || 'AND boundary_id = ' || valid_boundary_id || ' AND feature_id = ' || $2;

  RAISE NOTICE 'Execute statement: %', execute_statement;			

  FOR rec IN EXECUTE 'SELECT row_to_json(j) FROM (' || execute_statement || '))j' LOOP  		
	RETURN NEXT rec;
  END LOOP;
  
EXCEPTION WHEN others THEN 
  GET STACKED DIAGNOSTICS error_msg = MESSAGE_TEXT;  
    RAISE NOTICE 'Internal Error - Contact your DBA with the following error message: %', error_msg;
     
END;$$ LANGUAGE plpgsql;


 /******************************************************************
4. update pmt_activity_count to only count parent activities
  SELECT * FROM pmt_activity_count('768',null,null,null,null,null,null,null,null,null);
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
		'WHERE parent_id IS NULL AND activity_id = ANY(ARRAY[' || array_to_string(filtered_activity_ids, ',') || ']) AND location_id IS NOT NULL';
  select_statement_2 := ' SELECT CASE WHEN count(distinct location_id) > 0 THEN count(distinct parent_id) ELSE 0 END as ct FROM _filter_boundaries ' ||
		'WHERE parent_id IS NOT NULL AND activity_id = ANY(ARRAY[' || array_to_string(filtered_activity_ids, ',') || ']) AND location_id IS NOT NULL';		

  -- add filter for boundary			
  IF array_length(boundary_activity_ids, 1) > 0 THEN
    select_statement_1:= select_statement_1 || ' AND activity_id = ANY(ARRAY[' || array_to_string(boundary_activity_ids, ',') || ']) ';
    select_statement_2:= select_statement_2 || ' AND activity_id = ANY(ARRAY[' || array_to_string(boundary_activity_ids, ',') || ']) ';
  END IF;

  -- add filter for activities in list
  IF array_length(valid_activity_ids, 1) > 0 THEN
    select_statement_1:= select_statement_1 || 'AND activity_id = ANY(ARRAY[' || array_to_string(valid_activity_ids, ',') || ']) ';
    select_statement_2:= select_statement_2 || 'AND activity_id = ANY(ARRAY[' || array_to_string(valid_activity_ids, ',') || ']) ';
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

