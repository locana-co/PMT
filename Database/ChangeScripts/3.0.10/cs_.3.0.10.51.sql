/******************************************************************
Change Script 3.0.10.51
1. update pmt_global_search to add data group ids filter and return 
array of activity ids instead of a listing of activity ids and titles.
1. update pmt_locations_for_boundaries to add organization id filter (without role)
3. update pmt_activity_ids_by_boundary to add boundary and activity id filter
4. update pmt_activity_count to add boundary and activity id filter
5. new function pmt_boundary_hierarchy for constructing a nested
boundary menu
******************************************************************/
INSERT INTO version(_version, _iteration, _changeset) VALUES (3.0, 10, 51);
-- select * from version order by _iteration desc, _changeset desc;

 /******************************************************************
1. update pmt_locations_for_boundaries to add boundary and activity id filter
  SELECT * FROM pmt_locations_for_boundaries(12,'2237',null,null,null,null,null,null,'26288,26290,26303', '[{"b": 12, "ids": [1]}, {"b": 13, "ids": [48]}, {"b": 14, "ids": [1, 2, 3, 5, 536, 6, 8, 535, 4, 7]}]');  
  SELECT * FROM pmt_locations_for_boundaries(12,'2237',null,null,null,null,null,null,null,null); 
******************************************************************/
DROP FUNCTION IF EXISTS pmt_locations_for_boundaries(integer, character varying, character varying, character varying, character varying, date, date, character varying);
CREATE OR REPLACE FUNCTION pmt_locations_for_boundaries(boundary_id integer, data_group_ids character varying,
  classification_ids character varying, imp_org_ids character varying, fund_org_ids character varying, start_date date, end_date date,
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
  SELECT INTO filtered_activity_ids * FROM pmt_filter($2,$3,null,$4,$5,$6,$7,$8);

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
  execute_statement:= 'SELECT feature_id as id, count(distinct activity_id) as a, count(distinct location_id) as l, boundary_id as b FROM _filter_boundaries ' ||
		'WHERE activity_id = ANY(ARRAY[' || array_to_string(filtered_activity_ids, ',') || ']) ';

  -- add filter for boundary		
  IF array_length(boundary_activity_ids, 1) > 0 THEN
    execute_statement:= execute_statement || 'AND activity_id = ANY(ARRAY[' || array_to_string(boundary_activity_ids, ',') || ']) ';
  END IF;

  -- add filter for activities in list
  IF array_length(valid_activity_ids, 1) > 0 THEN
    execute_statement:= execute_statement || 'AND activity_id = ANY(ARRAY[' || array_to_string(valid_activity_ids, ',') || ']) ';
  END IF;
  
  execute_statement:= execute_statement || 'AND boundary_id = ' || valid_boundary_id || ' GROUP BY 1,4';

  RAISE NOTICE 'Execute statement: %', execute_statement;			

  FOR rec IN EXECUTE 'SELECT row_to_json(j) FROM (' || execute_statement || ')j' LOOP  		
	RETURN NEXT rec;
  END LOOP;

EXCEPTION WHEN others THEN 
  GET STACKED DIAGNOSTICS error_msg = MESSAGE_TEXT;  
    RAISE NOTICE 'Internal Error - Contact your DBA with the following error message: %', error_msg;

END;$$ LANGUAGE plpgsql;

/******************************************************************
3. update pmt_activity_ids_by_boundary to add boundary and activity id filter 
  SELECT * FROM pmt_activity_ids_by_boundary(12, 9,'2237',null,null,null,'1/1/2002','12/31/2020',null,'26288,26290,26303','[{"b":14,"ids":[2]}]');
******************************************************************/
DROP FUNCTION IF EXISTS pmt_activity_ids_by_boundary(integer, integer, character varying, character varying, character varying, character varying,date,date,character varying);
CREATE OR REPLACE FUNCTION pmt_activity_ids_by_boundary(boundary_id integer, feature_id integer, data_group_ids character varying, 
classification_ids character varying, imp_org_ids character varying, fund_org_ids character varying, start_date date, end_date date,
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
  SELECT INTO filtered_activity_ids * FROM pmt_filter($3,$4,null,$5,$6,$7,$8,$9);

  -- get the list of activity ids
  IF ($10 IS NOT NULL OR $10 <> '' ) THEN
    a_ids:= string_to_array($10, ',')::int[];
    SELECT INTO valid_activity_ids array_agg(id) FROM activity WHERE _active = true AND id = ANY(a_ids);
  END IF;
  
  -- get the filtered activity ids by boundary
  IF ($11 IS NOT NULL) THEN 
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
  execute_statement:= 'SELECT id, _title FROM activity WHERE ARRAY[id] <@ ( SELECT array_agg(DISTINCT activity_id) FROM _filter_boundaries ' ||
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
4. update pmt_activity_count to add boundary and activity id filter
  SELECT * FROM pmt_activity_count('768','2212,831','1681','','1/1/2012','12/31/2018',null,null,null);
******************************************************************/
DROP FUNCTION IF EXISTS pmt_activity_count(character varying, character varying, character varying, character varying, date, date, character varying);
CREATE OR REPLACE FUNCTION pmt_activity_count(data_group_ids character varying, classification_ids character varying, imp_org_ids character varying, 
fund_org_ids character varying, start_date date, end_date date, unassigned_taxonomy_ids character varying, activity_ids character varying, boundary_filter json)
RETURNS SETOF pmt_json_result_type AS 
$$
DECLARE
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

  -- get the filtered activity ids
  SELECT INTO filtered_activity_ids * FROM pmt_filter($1,$2,null,$3,$4,$5,$6,$7);
  
  -- get the list of activity ids
  IF ($8 IS NOT NULL OR $8 <> '' ) THEN
    a_ids:= string_to_array($8, ',')::int[];
    SELECT INTO valid_activity_ids array_agg(id) FROM activity WHERE _active = true AND id = ANY(a_ids);
  END IF;
  
  -- get the filtered activity ids by boundary
  IF ($9 IS NOT NULL) THEN
    RAISE NOTICE 'json was not null';      
    FOR boundary_json IN (SELECT * FROM json_array_elements($9)) LOOP
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
  execute_statement:= 'SELECT CASE WHEN count(distinct location_id) > 0 THEN count(distinct activity_id) ELSE 0 END as ct FROM _filter_boundaries ' ||
		'WHERE activity_id = ANY(ARRAY[' || array_to_string(filtered_activity_ids, ',') || '])';

  -- add filter for boundary			
  IF array_length(boundary_activity_ids, 1) > 0 THEN
    execute_statement:= execute_statement || ' AND activity_id = ANY(ARRAY[' || array_to_string(boundary_activity_ids, ',') || ']) ';
  END IF;

  -- add filter for activities in list
  IF array_length(valid_activity_ids, 1) > 0 THEN
    execute_statement:= execute_statement || 'AND activity_id = ANY(ARRAY[' || array_to_string(valid_activity_ids, ',') || ']) ';
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
5. new function pmt_boundary_hierarchy for constructing a nested
boundary menu
  select * from pmt_boundary_hierarchy('gadm','0,1,2','Ethiopia');
  select * from pmt_boundary_hierarchy('unocha','1,2,3',null);
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_boundary_hierarchy(boundary_type character varying, admin_levels character varying, filter_features character varying) RETURNS SETOF pmt_json_result_type AS
$$
DECLARE
  valid_boundary_type character varying;
  boundary_ids integer[];
  boundary_tables text[];
  boundary_id integer;
  boundary_table text;
  parent_admin integer;
  query_string text;
  count integer;
  idx integer;
  execute_statement text;    
  rec record;
  error_msg text;
BEGIN

  -- validate and process boundary_type parameter
  IF $1 IS NOT NULL THEN
    -- validate the boundary type
    SELECT INTO valid_boundary_type DISTINCT _type FROM boundary WHERE _type = $1 AND _active = true;
    IF valid_boundary_type IS NULL THEN
      FOR rec IN SELECT row_to_json(j) FROM( SELECT 'missing valid required parameter' AS error ) as j LOOP RETURN NEXT rec; END LOOP;
    END IF;
  ELSE
    FOR rec IN SELECT row_to_json(j) FROM( SELECT 'missing required parameter' AS error ) as j LOOP RETURN NEXT rec; END LOOP;
  END IF;
  -- process admin_levels parameter and collect boundary ids
  IF $2 IS NOT NULL THEN
    -- collect boundary ids for requested admin levels
    SELECT INTO boundary_ids array_agg(id) FROM (SELECT id FROM boundary WHERE _type = valid_boundary_type AND ARRAY[_admin_level] <@ string_to_array($2, ',')::int[] ORDER BY _admin_level) AS b;
    SELECT INTO boundary_tables array_agg(_spatial_table::text) FROM (SELECT _spatial_table FROM boundary WHERE _type = valid_boundary_type AND ARRAY[_admin_level] <@ string_to_array($2, ',')::int[] ORDER BY _admin_level DESC) AS b;
    -- if admin levels requested results in no boundaries, use all boundaries for the given type
    IF array_length(boundary_ids, 1) <= 0 OR boundary_ids IS NULL THEN
      SELECT INTO boundary_ids array_agg(id) FROM (SELECT id FROM boundary WHERE _type = valid_boundary_type ORDER BY _admin_level) as b;
      SELECT INTO boundary_tables array_agg(_spatial_table::text) FROM (SELECT _spatial_table FROM boundary WHERE _type = valid_boundary_type ORDER BY _admin_level DESC) as b;
    END IF;    
  ELSE
    -- collect all boundary ids for the given type if no admin levels are specified
    SELECT INTO boundary_ids array_agg(id) FROM (SELECT id FROM boundary WHERE _type = valid_boundary_type ORDER BY _admin_level) as b;
    SELECT INTO boundary_tables array_agg(_spatial_table::text) FROM (SELECT _spatial_table FROM boundary WHERE _type = valid_boundary_type ORDER BY _admin_level DESC) as b;
  END IF;

  -- begin execution statement
  execute_statement := 'SELECT ';
  
  count := 0;
  FOREACH boundary_id IN ARRAY boundary_ids LOOP
    execute_statement := execute_statement || boundary_id || ' as b' || count || ', ';
    count := count + 1;
  END LOOP;

  count := 0;
  FOREACH boundary_id IN ARRAY boundary_ids LOOP
    execute_statement := execute_statement || '(SELECT array_to_json(array_agg(row_to_json(b' || count || '))) FROM ( ';
    execute_statement := execute_statement || 'SELECT id, _name as n ';
    -- if not the last element add a comma
    IF (count + 1) < array_length(boundary_ids, 1) THEN
      execute_statement := execute_statement || ',';
    END IF;    
    count := count + 1;
  END LOOP;
  
  count := array_length(boundary_tables, 1);
  idx := 1;
  FOREACH boundary_table IN ARRAY boundary_tables LOOP
    count := count - 1;
    IF count <> 0 THEN
      execute_statement := execute_statement || 'FROM ' || boundary_table || ' '; 
      execute_statement := execute_statement || 'WHERE _' || boundary_tables[idx + 1] || '_name = ' || boundary_tables[idx + 1] || '._name ';
      execute_statement := execute_statement || ') b' || count || ' ) as b ';  
    ELSE
      execute_statement := execute_statement || 'FROM ' || boundary_table || ' ';
      IF $3 IS NOT NULL OR $3 <> '' THEN
        SELECT INTO query_string array_to_string(array_agg(query), ',') FROM ( SELECT quote_literal(trim(unnest(string_to_array(lower($3), ',')))) as query) as foo;
        execute_statement := execute_statement || 'WHERE lower(_name) IN (' || query_string || ')'; 
      END IF;
      execute_statement := execute_statement || ') b' || count || ') as boundaries'; 
    END IF; 
    idx := idx + 1;     
  END LOOP;
	
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