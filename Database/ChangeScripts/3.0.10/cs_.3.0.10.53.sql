/******************************************************************
Change Script 3.0.10.53
1. update pmt_locations_for_boundaries to add organization id filter (without role)
2. update pmt_activity_ids_by_boundary to add organization id filter (without role)
3. update pmt_activity_count to add organization id filter (without role)
4. update pmt_activities_by_polygon to add activity_ids and boundary filters
5. update pmt_filter function to address bug in multiple organization parameters for different roles
6. update pmt_overview_stats to allow multiple features ids
7. update pmt_activities to remove duplicate providers
******************************************************************/
INSERT INTO version(_version, _iteration, _changeset) VALUES (3.0, 10, 53);
-- select * from version order by _iteration desc, _changeset desc;

 /******************************************************************
1. update pmt_locations_for_boundaries to add organization id filter (without role)
  SELECT * FROM pmt_locations_for_boundaries(12,'2237',null,null,null,null,null,null,null,null,null); 
  SELECT * FROM pmt_locations_for_boundaries(12,'2209,2210',null,null,'2520',null,'1/1/1970','12/31/2024',null,null,null);
******************************************************************/
DROP FUNCTION IF EXISTS pmt_org_inuse(character varying);
DROP FUNCTION IF EXISTS pmt_locations_for_boundaries(integer, character varying, character varying, character varying, character varying, date, date, character varying, character varying, json);
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
RAISE NOTICE 'filtered_activity_ids: %', filtered_activity_ids;    
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
2. update pmt_activity_ids_by_boundary to add organization id filter (without role)
  SELECT * FROM pmt_activity_ids_by_boundary(12, 9,'2237',null,null,null,null,'1/1/2002','12/31/2020',null,'26288,26290,26303','[{"b":14,"ids":[2]}]');
******************************************************************/
DROP FUNCTION IF EXISTS pmt_activity_ids_by_boundary(integer, integer, character varying, character varying, character varying, character varying, date, date, character varying, character varying, json);
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
3. update pmt_activity_count to add organization id filter (without role)
  SELECT * FROM pmt_activity_count('2209,2210',null,null,'2520',null,'1/1/1970','12/31/2024',null,null,null);
******************************************************************/
DROP FUNCTION IF EXISTS pmt_activity_count(character varying, character varying, character varying, character varying, date, date, character varying, character varying, json);
CREATE OR REPLACE FUNCTION pmt_activity_count(data_group_ids character varying, classification_ids character varying, org_ids character varying, imp_org_ids character varying, 
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
  execute_statement:= 'SELECT CASE WHEN count(distinct location_id) > 0 THEN count(distinct activity_id) ELSE 0 END as ct FROM _filter_boundaries ' ||
		'WHERE activity_id = ANY(ARRAY[' || array_to_string(filtered_activity_ids, ',') || ']) AND location_id IS NOT NULL';

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
4. update pmt_activities_by_polygon to add activity_ids and boundary filters
  select * from pmt_activities_by_polygon('POLYGON ((38.25223105686701 8.14760225670679, 38.25084770772398 8.133556877151992, 38.24675082162665 8.120051253656747, 38.24009783961018 8.107604399757935, 38.23114443204243 8.09669464107061, 38.22023467335511 8.087741233502863, 38.20778781945629 8.081088251486396, 38.194282195961044 8.076991365389063, 38.18023681640625 8.075608016246028, 38.166191436851456 8.076991365389063, 38.15268581335621 8.081088251486396, 38.14023895945739 8.087741233502863, 38.12932920077007 8.09669464107061, 38.12037579320232 8.107604399757935, 38.11372281118585 8.120051253656747, 38.10962592508852 8.133556877151992, 38.10824257594549 8.14760225670679, 38.10962592508852 8.161647636261588, 38.11372281118585 8.175153259756833, 38.12037579320232 8.187600113655646, 38.12932920077007 8.19850987234297, 38.14023895945739 8.207463279910717, 38.15268581335621 8.214116261927185, 38.166191436851456 8.218213148024518, 38.18023681640625 8.219596497167553, 38.194282195961044 8.218213148024518, 38.20778781945629 8.214116261927185, 38.22023467335511 8.207463279910717, 38.23114443204243 8.19850987234297, 38.24009783961018 8.187600113655645, 38.24675082162665 8.175153259756833, 38.25084770772398 8.161647636261586, 38.25223105686701 8.14760225670679))','768,769','2212',null,null,null,'01-01-2001','12-31-2021',null, null,null);
******************************************************************/
DROP FUNCTION IF EXISTS pmt_activities_by_polygon(character varying, character varying, character varying, character varying, character varying, character varying, date, date, character varying);
DROP FUNCTION IF EXISTS pmt_activities_by_polygon(character varying);
CREATE OR REPLACE FUNCTION pmt_activities_by_polygon(wktpolygon character varying, data_group_ids character varying, classification_ids character varying, org_ids character varying,
imp_org_ids character varying, fund_org_ids character varying, start_date date, end_date date, unassigned_taxonomy_ids character varying, activity_ids character varying, boundary_filter json) 
RETURNS SETOF pmt_json_result_type AS $$
DECLARE
  filtered_activity_ids int[];
  wkt text;
  boundary_json json;
  boundary_filters text[];
  boundary_statement text;
  boundary_activity_ids int[];
  a_ids int[];
  valid_activity_ids int[];
  json record; 
  rec record;
  error_msg text;
  execute_statement text;
BEGIN

  -- validate and process wktpolygon parameter
  IF $1 IS NOT NULL THEN
    -- validate that incoming WKT is a polygon and that it is all uppercase
    IF (upper(substring(trim($1) from 1 for 7)) = 'POLYGON') THEN
      wkt := replace(lower(trim($1)), 'polygon', 'POLYGON');
      -- RAISE NOTICE 'WKT: %', wkt;
    ELSE
      FOR rec IN (SELECT row_to_json(j) FROM (SELECT 'WKT must be of type POLYGON' as error) j ) LOOP		
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
  execute_statement:= 'SELECT array_to_json(array_agg(DISTINCT activity_id)) AS activity_ids FROM location l WHERE _active = true AND ST_Contains(ST_GeomFromText(' || 
		quote_literal(wkt) || 
		', 4326), l._point) AND activity_id = ANY(ARRAY[' || array_to_string(filtered_activity_ids, ',') || '])';


  -- add filter for boundary		
  IF array_length(boundary_activity_ids, 1) > 0 THEN
    execute_statement:= execute_statement || 'AND activity_id = ANY(ARRAY[' || array_to_string(boundary_activity_ids, ',') || ']) ';
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


/*************************************************************************
  5. update pmt_filter function to address bug in multiple organization
  parameters for different roles
     select * from pmt_filter('768','816,819','13','','','1/1/2012','12/31/2018','22');
     select * from pmt_filter(null,null,null,null,null,null,null,null);
*************************************************************************/
-- drop old function 
DROP FUNCTION IF EXISTS pmt_filter(character varying, character varying, character varying, character varying, character varying, date, date);
-- create new function with new parameter
CREATE OR REPLACE FUNCTION pmt_filter(data_group_ids character varying, classification_ids character varying, org_ids character varying,
imp_org_ids character varying, fund_org_ids character varying, start_date date, end_date date, unassigned_taxonomy_ids character varying) RETURNS integer[] AS 
$$
DECLARE 
  execute_statement text;
  org_statement text;
  tax_statement text;
  activity_statement text;
  dg_ids int[];
  c_ids int[];
  imp_ids int[];
  fund_ids int[];
  o_ids int[];
  t_ids int[];
  valid_dg_ids int[];  
  valid_c_ids int[];  
  valid_imp_ids int[];  
  valid_fund_ids int[]; 
  valid_o_ids int[];
  valid_t_ids int[];
  dg_where text;
  org_where text[];
  tax_where text[];
  date_where text[];
  unassigned_where text;
  cls record;
  activities_id int[];
  error_msg text;
BEGIN 

  -- validate and process data_group_ids parameter
  IF $1 IS NOT NULL THEN
    dg_ids:= string_to_array($1, ',')::int[];
    -- validate the data groups id
    SELECT INTO valid_dg_ids array_agg(id)::int[] FROM classification WHERE taxonomy_id = 1 AND _active=true AND id = ANY(dg_ids);
  END IF;
  -- validate and process classification_ids parameter
  IF $2 IS NOT NULL THEN
    c_ids:= string_to_array($2, ',')::int[];
    -- validate the classification ids
    SELECT INTO valid_c_ids array_agg(id)::int[] FROM classification WHERE _active=true AND id = ANY(c_ids);
  END IF;
  -- validate and process org_ids parameter
  IF $3 IS NOT NULL THEN
    o_ids:= string_to_array($3, ',')::int[];
    -- validate the org ids
    SELECT INTO valid_o_ids array_agg(id)::int[] FROM organization WHERE _active=true AND id = ANY(o_ids);
  END IF;
  -- validate and process imp_org_ids parameter
  IF $4 IS NOT NULL THEN
    imp_ids:= string_to_array($4, ',')::int[];
    -- validate the org ids
    SELECT INTO valid_imp_ids array_agg(id)::int[] FROM organization WHERE _active=true AND id = ANY(imp_ids);
  END IF;
  -- validate and process fund_org_ids parameter
  IF $5 IS NOT NULL THEN
    fund_ids:= string_to_array($5, ',')::int[];
    -- validate the org ids
    SELECT INTO valid_fund_ids array_agg(id)::int[] FROM organization WHERE _active=true AND id = ANY(fund_ids);
  END IF;
  -- validate and process unassigned_taxonomy_ids parameter
  IF $8 IS NOT NULL THEN
    t_ids:= string_to_array($8, ',')::int[];
    -- validate the taxonomy ids
    SELECT INTO valid_t_ids array_agg(id)::int[] FROM taxonomy WHERE _active=true AND id = ANY(t_ids);
  END IF;
  
  -- restrict returned results by data group id(s)
  IF array_length(valid_dg_ids, 1) > 0 THEN
    dg_where := 'data_group_id = ANY(ARRAY[' || array_to_string(valid_dg_ids, ',') || ']) ';
  END IF;
  -- restrict returned results by classification id(s)
  IF array_length(valid_c_ids, 1) > 0 THEN
    FOR cls IN EXECUTE 'SELECT taxonomy_id, array_agg(id) as c FROM classification WHERE _active = true AND id = ANY(ARRAY[' || array_to_string(valid_c_ids, ',') || ']) GROUP BY 1 ORDER BY 1' LOOP
      tax_where := array_append(tax_where, '(taxonomy_id = ' || cls.taxonomy_id || ' AND classification_id = ANY(ARRAY[' || array_to_string(cls.c, ',') || ']))');
    END LOOP;
  END IF;
  -- restrict returned results by org id(s)
  IF array_length(valid_o_ids, 1) > 0 THEN
    org_where := array_append(org_where, '(organization_ids && ARRAY[' || array_to_string(valid_o_ids, ',') || '])');
  END IF;
  -- restrict returned results by implmenting org id(s)
  IF array_length(valid_imp_ids, 1) > 0 THEN
    org_where := array_append(org_where, '(organization_ids && ARRAY[' || array_to_string(valid_imp_ids, ',') || '] AND role = ''Implementing'')');
  END IF;
  -- restrict returned results by funding org id(s)
  IF array_length(valid_fund_ids, 1) > 0 THEN
    org_where := array_append(org_where, '(organization_ids && ARRAY[' || array_to_string(valid_fund_ids, ',') || '] AND role = ''Funding'')');
  END IF;
  -- restrict returned results by start date
  IF $6 IS NOT NULL THEN
    date_where := array_append(date_where, '_start_date >= ' || quote_literal($6));
  END IF;
  -- restrict returned results by end date
  IF $7 IS NOT NULL THEN
    date_where := array_append(date_where, '_end_date <= ' || quote_literal($7));
  END IF;
  -- restrict returned results by unassigned taxonomy id(s)
  IF array_length(valid_t_ids, 1) > 0 THEN
    unassigned_where := 'unassigned @> ARRAY[' || array_to_string(valid_t_ids, ',') || '] ';
  END IF;

  -- RAISE NOTICE 'Data group where statement: %', dg_where;
  -- RAISE NOTICE 'Classification where statement: %', tax_where;
  -- RAISE NOTICE 'Organization where statement: %', org_where;
  -- RAISE NOTICE 'Date where statement: %', date_where;

  -- prepare _filter_taxonomies statement
  IF array_length(tax_where, 1) > 0 THEN
    tax_statement := 'SELECT DISTINCT activity_id FROM _filter_taxonomies WHERE (' || array_to_string(tax_where, ' AND ') || ') ';
  END IF;
  -- prepare _filter_organizations statement
  IF array_length(org_where, 1) > 0 THEN
    org_statement := 'SELECT activity_id FROM _filter_organizations WHERE (' || array_to_string(org_where, ' OR ') || ') GROUP BY activity_id HAVING count(activity_id) >= ' || array_length(org_where, 1);
  END IF;
  -- prepare activity statement
  activity_statement:= 'SELECT DISTINCT id as activity_id FROM activity WHERE _active = true ';
  IF array_length(date_where, 1) > 0 THEN
    activity_statement := activity_statement || 'AND (' || array_to_string(date_where, ' AND ') || ') ';
  END IF;
  IF dg_where IS NOT NULL THEN
    activity_statement := activity_statement || 'AND (' || dg_where || ') ';
  END IF;   

  -- build execution statement
  execute_statement := 'SELECT array_agg(DISTINCT activity_id)::int[] as activities FROM ( ';
  -- RAISE NOTICE 'Execute statement begins: %', execute_statement;
  -- two filters, requires a join
  IF tax_statement IS NOT NULL AND org_statement IS NOT NULL THEN
    execute_statement := execute_statement || 'SELECT activity_id, count(*) ct FROM ( ' || tax_statement || ' UNION ALL ' || org_statement ||
	') a GROUP BY 1 ';
    -- add the unassigned taxonomy filter if needed
    IF unassigned_where IS NOT NULL THEN
      execute_statement := execute_statement || 'UNION ALL SELECT activity_id, 2 FROM _filter_unassigned WHERE ' || unassigned_where || ' ';
    END IF;  
    execute_statement := execute_statement || ') a WHERE ct > 1 AND activity_id IN ( ' || activity_statement || ' )';     	
    RAISE NOTICE 'Execute statement (two filters): %', execute_statement;
  ELSE
    -- one filter
    IF tax_statement IS NOT NULL OR org_statement IS NOT NULL THEN
      IF tax_statement IS NOT NULL THEN
        execute_statement := execute_statement || tax_statement;
      END IF;
      IF org_statement IS NOT NULL THEN
        execute_statement := execute_statement || org_statement;
      END IF;
      -- add the unassigned taxonomy filter if needed
      IF unassigned_where IS NOT NULL THEN
        execute_statement := execute_statement || 'UNION ALL SELECT activity_id FROM _filter_unassigned WHERE ' || unassigned_where;
      END IF; 
      execute_statement := execute_statement ||  ') a WHERE activity_id IN ( ' || activity_statement || ' )';
      RAISE NOTICE 'Execute statement (one filter): %', execute_statement;
    END IF;
  END IF;
  
  -- no filters
  IF tax_statement IS NULL AND org_statement IS NULL THEN
    -- add the unassigned taxonomy filter if needed
    IF unassigned_where IS NOT NULL THEN
      execute_statement := execute_statement || 'SELECT activity_id FROM _filter_unassigned WHERE ' || unassigned_where || 
      ') a WHERE activity_id IN ( ' || activity_statement || ' )';
    ELSE
      execute_statement := execute_statement || activity_statement || ' ) as a'; 
    END IF;     
    RAISE NOTICE 'Execute statement (no filters): %', execute_statement;   
  END IF;
  
  RAISE NOTICE 'Execute statement: %', execute_statement;
  EXECUTE execute_statement INTO activities_id;
  RETURN activities_id;

EXCEPTION WHEN others THEN 
  GET STACKED DIAGNOSTICS error_msg = MESSAGE_TEXT;  
    RAISE NOTICE 'Internal Error - Contact your DBA with the following error message: %', error_msg;
    	
END;$$ LANGUAGE plpgsql;


/******************************************************************
6. update pmt_overview_stats to allow multiple features ids
  SELECT * FROM pmt_overview_stats('768',null,null,null,15,'227,74,38,87')
  SELECT * FROM pmt_overview_stats('768',null,null,null,15,'74')
  SELECT * FROM pmt_overview_stats('768',null,null,null,null,null)
  SELECT * FROM pmt_overview_stats('768',null,null,null,15,'74,227');
******************************************************************/
DROP FUNCTION IF EXISTS pmt_overview_stats(character varying, character varying, date, date, integer, integer);
CREATE OR REPLACE FUNCTION pmt_overview_stats(data_group_ids character varying, classification_ids character varying, 
start_date date, end_date date, boundary_id integer, feature_ids character varying) RETURNS SETOF pmt_json_result_type AS 
$$
DECLARE
  dg_ids int[];
  f_ids int[];
  valid_dg_ids int[];
  valid_boundary_id integer;
  valid_feature_ids int[];
  spatial_table text;
  filtered_activity_ids int[];
  feature_activity_ids int[];
  activity_count int;
  implmenting_count int;
  total_investment numeric(100,2);
  country_count int;
  rec record;
  execute_statement text;
  error_msg text;
BEGIN
  -- validate and process data_group_ids parameter
  IF $1 IS NOT NULL THEN
    dg_ids:= string_to_array($1, ',')::int[];
    -- validate the data groups id
    SELECT INTO valid_dg_ids array_agg(id)::int[] FROM classification WHERE taxonomy_id = 1 AND _active=true AND id = ANY(dg_ids);
  END IF;
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
    f_ids:= string_to_array($6, ',')::int[];
    SELECT INTO spatial_table _spatial_table FROM boundary WHERE id = valid_boundary_id; 
    -- validate the feature id
    EXECUTE 'SELECT array_agg(id)::int[] FROM '|| spatial_table ||' WHERE _active = true AND id = ANY(ARRAY[' || array_to_string(f_ids, ',') || '])' INTO valid_feature_ids;  
    IF array_length(valid_feature_ids, 1) < 1 THEN
      FOR rec IN SELECT row_to_json(j) FROM( SELECT 'provided feature id(s) are invalid' AS error ) as j LOOP RETURN NEXT rec; END LOOP;
    END IF;
  END IF;
  
  -- get the filtered activity ids
  SELECT INTO filtered_activity_ids * FROM pmt_filter($1,$2,null,null,null,$3,$4,null);
  -- get the activity ids filtered by the boundary/feature
  IF valid_boundary_id IS NOT NULL AND array_length(valid_feature_ids, 1) > 0 THEN
    -- get the activity ids for the feature
    IF array_length(valid_dg_ids, 1) > 0 THEN
      SELECT INTO feature_activity_ids array_agg(activity_id) FROM _location_lookup ll WHERE ll.boundary_id = valid_boundary_id AND ll.feature_id = ANY(valid_feature_ids) AND data_group_id = ANY(valid_dg_ids);
    ELSE
      SELECT INTO feature_activity_ids array_agg(activity_id) FROM _location_lookup ll WHERE ll.boundary_id = valid_boundary_id AND ll.feature_id = ANY(valid_feature_ids);
    END IF;    
  END IF;
  
  -- get the total number of activities
  IF array_length(feature_activity_ids, 1) > 0 THEN
    SELECT INTO activity_count count(id) FROM activity WHERE _active = true AND parent_id IS NULL AND id = ANY(filtered_activity_ids) AND id = ANY(feature_activity_ids);
  ELSE
    SELECT INTO activity_count count(id) FROM activity WHERE _active = true AND parent_id IS NULL AND id = ANY(filtered_activity_ids);
  END IF;	
  
  -- get the total number of implementing organizations
  IF array_length(feature_activity_ids, 1) > 0 THEN
    SELECT INTO implmenting_count count(DISTINCT organization_id) FROM _activity_participants WHERE classification = 'Implementing' AND id = ANY(filtered_activity_ids) AND id = ANY(feature_activity_ids);
  ELSE
    SELECT INTO implmenting_count count(DISTINCT organization_id) FROM _activity_participants WHERE classification = 'Implementing' AND id = ANY(filtered_activity_ids);
  END IF;
  
  -- get total amount of investment
  IF array_length(feature_activity_ids, 1) > 0 THEN
    SELECT INTO total_investment sum(amount) FROM (
	SELECT DISTINCT parent_id, amount FROM _activity_family_finacials 
	WHERE parent_id IN (
		SELECT DISTINCT parent_id FROM _activity_family 
		WHERE (parent_id = ANY(filtered_activity_ids) AND parent_id = ANY(feature_activity_ids))
		OR (child_id = ANY(filtered_activity_ids) AND child_id = ANY(feature_activity_ids))
	) AND amount IS NOT NULL
    ) as f;
  ELSE
    SELECT INTO total_investment sum(amount) FROM (
	SELECT DISTINCT parent_id, amount FROM _activity_family_finacials 
	WHERE parent_id IN (
		SELECT DISTINCT parent_id FROM _activity_family 
		WHERE parent_id = ANY(filtered_activity_ids) OR child_id = ANY(filtered_activity_ids)
	) AND amount IS NOT NULL
    ) as f;
  END IF;

  -- get the total number of countries
  IF array_length(feature_activity_ids, 1) > 0 THEN
    SELECT INTO country_count count(distinct feature_id) FROM _location_lookup ll WHERE ll.boundary_id = 15 AND activity_id = ANY(filtered_activity_ids) AND activity_id = ANY(feature_activity_ids) AND ll.feature_id = ANY(valid_feature_ids);
  ELSE
    SELECT INTO country_count count(distinct feature_id) FROM _location_lookup ll WHERE ll.boundary_id = 15 AND activity_id = ANY(filtered_activity_ids);
  END IF;	
  
  FOR rec IN (SELECT row_to_json(j) FROM(SELECT activity_count as activity_count, implmenting_count as implmenting_count, 
		total_investment as total_investment, country_count as country_count) j) LOOP  RETURN NEXT rec; END LOOP; 
    RETURN;   	  
    
EXCEPTION WHEN others THEN 
  GET STACKED DIAGNOSTICS error_msg = MESSAGE_TEXT;  
    RAISE NOTICE 'Internal Error - Contact your DBA with the following error message: %', error_msg;

END;$$ LANGUAGE plpgsql;


/******************************************************************
7. update pmt_activities to remove duplicate providers and update return object to reduce size
   select * from pmt_activities('768','794',null,null,null,null,null,null,null); 
   select * from pmt_activities('769',null,null,null,'13',null,null,null,null); 
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_activities(data_group_ids character varying, classification_ids character varying, org_ids character varying,
imp_org_ids character varying, fund_org_ids character varying, start_date date, end_date date, unassigned_taxonomy_ids character varying, activity_ids character varying) RETURNS SETOF pmt_json_result_type AS
$$
DECLARE
  filtered_activity_ids int[];
  a_ids int[];
  valid_activity_ids int[];
  execute_statement text;    
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
  
  execute_statement:= 'SELECT a.id, parent_id as pid, data_group_id as dgid, (SELECT _name FROM classification WHERE id = data_group_id) as dg, ' ||
		'_title as t, sum(_amount) as a, a._start_date as sd, a._end_date as ed, array_agg( o._name) as f' ||
		' FROM (SELECT id, parent_id, data_group_id, _title, _start_date, _end_date FROM activity WHERE _active = true AND id = ANY(ARRAY[' || array_to_string(filtered_activity_ids, ',') || ']) ';
  -- add filter for activities in list
  IF array_length(valid_activity_ids, 1) > 0 THEN
    execute_statement:= execute_statement || 'AND id = ANY(ARRAY[' || array_to_string(valid_activity_ids, ',') || ']) ';
  END IF;
  		
  execute_statement:= execute_statement || ') a' ||
  		' LEFT JOIN (SELECT id, activity_id, _amount, provider_id FROM financial WHERE _active = true) f ' ||
  		' ON a.id = f.activity_id ' ||
  		' LEFT JOIN ( select financial_id, classification, _code ' ||
				' FROM financial_taxonomy ft ' ||
				' JOIN _taxonomy_classifications tc ' ||
				' on ft.classification_id = tc.classification_id ' ||
				' where tc.taxonomy = ''Transaction Type'') as ft ' ||
		'ON ft.financial_id = f.id ' ||
		'LEFT JOIN (SELECT id, _name FROM _activity_participants WHERE classification = ''Funding'') o ON a.id = o.id '
		'WHERE classification IS NULL OR classification = ''Incoming Funds'' OR classification = ''Commitment'' ' ||
		'GROUP BY 1,2,3,4,5,7,8 ';


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