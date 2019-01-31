/******************************************************************
Change Script 3.0.10.7
1. update pmt_locations_for_boundaries function: add date filter
2. update pmt_activity_ids_by_boundary function: add title & date filter
******************************************************************/
INSERT INTO version(_version, _iteration, _changeset) VALUES (3.0, 10, 7);
-- select * from version order by _iteration desc, _changeset desc;
/******************************************************************
1. update pmt_locations_for_boundaries function: add date filter
  SELECT * FROM pmt_locations_for_boundaries(8, '768', '797','','','1/1/2012','12/31/2018'); --bmgf
******************************************************************/
DROP FUNCTION IF EXISTS pmt_locations_for_boundaries(integer, character varying, character varying, character varying, character varying);
CREATE OR REPLACE FUNCTION pmt_locations_for_boundaries(boundary_id integer, data_group_ids character varying,
  classification_ids character varying, imp_org_ids character varying, fund_org_ids character varying, start_date date, end_date date)
RETURNS SETOF pmt_json_result_type AS 
$$
DECLARE
  valid_boundary_id integer;
  dg_ids int[];
  c_ids int[];
  imp_ids int[];
  fund_ids int[];
  valid_dg_ids int[];  
  valid_c_ids int[];  
  valid_imp_ids int[];  
  valid_fund_ids int[]; 
  org_statement text;
  tax_statement text;
  execute_statement text;
  dg_where text;
  org_where text[];
  tax_where text[];
  tax_joins text[];
  date_where text[];
  w text;
  idx int;
  cls record;
  rec record;
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

  -- validate and process data_group_ids parameter
  IF $2 IS NOT NULL THEN
    dg_ids:= string_to_array($2, ',')::int[];
    -- validate the data groups id
    SELECT INTO valid_dg_ids array_agg(id)::int[] FROM classification WHERE taxonomy_id = 1 AND _active=true AND id = ANY(dg_ids);
  END IF;
  -- validate and process classification_ids parameter
  IF $3 IS NOT NULL THEN
    c_ids:= string_to_array($3, ',')::int[];
    -- validate the classification ids
    SELECT INTO valid_c_ids array_agg(id)::int[] FROM classification WHERE _active=true AND id = ANY(c_ids);
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

  execute_statement:= 'SELECT feature_id as id, count(distinct o.activity_id) as a, count(distinct location_id) as l, boundary_id as b FROM ';
  org_statement := '(SELECT distinct activity_id FROM _filter_organizations ';
  tax_statement := 'JOIN (SELECT distinct t1.activity_id FROM  ';
  
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
  IF array_length(valid_imp_ids, 1) > 0 THEN
    org_where := array_append(org_where, '(organization_ids && ARRAY[' || array_to_string(valid_imp_ids, ',') || '] AND role = ''Implementing'')');
  END IF;
  -- restrict returned results by start date
  IF $6 IS NOT NULL THEN
    date_where := array_append(date_where, '_start_date >= ' || quote_literal($6));
  END IF;
  -- restrict returned results by end date
  IF $7 IS NOT NULL THEN
    date_where := array_append(date_where, '_end_date <= ' || quote_literal($7));
  END IF;

  -- build statements
  IF dg_where IS NOT NULL THEN
    org_statement := org_statement || 'WHERE ' || dg_where;
  END IF;

  -- build _filter_taxonomies statement
  IF array_length(tax_where, 1) > 0 THEN
    idx := 1;
    FOREACH w IN ARRAY tax_where LOOP
      IF dg_where IS NOT NULL THEN
        IF idx = 1 THEN
          tax_joins := array_append(tax_joins, '(SELECT activity_id FROM _filter_taxonomies WHERE ' || dg_where ||
  	    ' AND ' || w || ') t' || idx);
        ELSE
          tax_joins := array_append(tax_joins, '(SELECT activity_id FROM _filter_taxonomies WHERE ' || dg_where ||
  	    ' AND ' || w || ') t' || idx || ' ON t' || idx - 1 || '.activity_id = t' || idx || '.activity_id ');
        END IF;
      ELSE 
        IF idx = 1 THEN
          tax_joins := array_append(tax_joins, '(SELECT activity_id FROM _filter_taxonomies WHERE ' ||  w || ') t' || idx);
        ELSE
          tax_joins := array_append(tax_joins, '(SELECT activity_id FROM _filter_taxonomies WHERE ' ||  w || ') t' || idx 
            || ' ON t' || idx - 1 || '.activity_id = t' || idx || '.activity_id ');
        END IF;        
      END IF;
      idx := idx + 1;
    END LOOP; 
    tax_statement := tax_statement || array_to_string(tax_joins, ' JOIN ');
  ELSE
    IF dg_where IS NOT NULL THEN
      tax_statement := tax_statement || '(SELECT activity_id FROM _filter_taxonomies WHERE ' || dg_where || ') t1';  
    ELSE
      tax_statement := tax_statement || '(SELECT activity_id FROM _filter_taxonomies ) t1';  
    END IF;    
  END IF;

  -- build _filter_organizations statement
  IF array_length(org_where, 1) > 0 THEN
    IF dg_where IS NOT NULL THEN
      org_statement := org_statement || ' AND (' || array_to_string(org_where, ' AND ') || ') ';
    ELSE 
      org_statement := org_statement || 'WHERE (' || array_to_string(org_where, ' AND ') || ') ';
    END IF;
  END IF;

  org_statement := org_statement || ') as o ';
  tax_statement := tax_statement || ') as c ';
  
  execute_statement:= execute_statement || org_statement || tax_statement ||
		'ON o.activity_id = c.activity_id ' ||
		'LEFT JOIN _filter_boundaries ab ON o.activity_id = ab.activity_id WHERE ab.boundary_id = ' || valid_boundary_id; 

  -- add date filter if applicable		
  IF array_length(date_where, 1) > 0 THEN
    execute_statement:= execute_statement || ' AND ab.activity_id IN (SELECT id FROM activity WHERE ' || array_to_string(date_where, ' AND ') || ') ';
  END IF;

  execute_statement:= execute_statement || ' GROUP BY 1,4';
  
  RAISE NOTICE 'Execute statement: %', execute_statement;			

  FOR rec IN EXECUTE 'SELECT row_to_json(j) FROM (' || execute_statement || ')j' LOOP  		
	RETURN NEXT rec;
  END LOOP;

END;$$ LANGUAGE plpgsql;

/******************************************************************
2. update pmt_activity_ids_by_boundary function: add title & date filter
  SELECT * FROM pmt_activity_ids_by_boundary(8, 4, '768', '','','', '1/1/2012', null); --bmgf
******************************************************************/
DROP FUNCTION IF EXISTS pmt_activity_ids_by_boundary(integer, integer, character varying, character varying, character varying, character varying);
CREATE OR REPLACE FUNCTION pmt_activity_ids_by_boundary(boundary_id integer, feature_id integer, data_group_ids character varying, 
classification_ids character varying, imp_org_ids character varying, fund_org_ids character varying, start_date date, end_date date)
RETURNS SETOF pmt_json_result_type AS 
$$
DECLARE
  valid_boundary_id integer;
  dg_ids int[];
  c_ids int[];
  imp_ids int[];
  fund_ids int[];
  valid_dg_ids int[];  
  valid_c_ids int[];  
  valid_imp_ids int[];  
  valid_fund_ids int[];  
  org_statement text;
  tax_statement text;
  execute_statement text;
  dg_where text;
  org_where text[];
  tax_where text[];
  tax_joins text[];
  date_where text[];
  w text;
  idx int;
  cls record;
  rec record;
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

  -- validate and process data_group_ids parameter
  IF $3 IS NOT NULL THEN
    dg_ids:= string_to_array($3, ',')::int[];
    -- validate the data groups id
    SELECT INTO valid_dg_ids array_agg(id)::int[] FROM classification WHERE taxonomy_id = 1 AND _active=true AND id = ANY(dg_ids);
  END IF;
   -- validate and process classification_ids parameter
  IF $4 IS NOT NULL THEN
    c_ids:= string_to_array($4, ',')::int[];
    -- validate the classification ids
    SELECT INTO valid_c_ids array_agg(id)::int[] FROM classification WHERE _active=true AND id = ANY(c_ids);
  END IF;
   -- validate and process imp_org_ids parameter
  IF $5 IS NOT NULL THEN
    imp_ids:= string_to_array($5, ',')::int[];
    -- validate the org ids
    SELECT INTO valid_imp_ids array_agg(id)::int[] FROM organization WHERE _active=true AND id = ANY(imp_ids);
  END IF;
   -- validate and process fund_org_ids parameter
  IF $6 IS NOT NULL THEN
    fund_ids:= string_to_array($6, ',')::int[];
    -- validate the org ids
    SELECT INTO valid_fund_ids array_agg(id)::int[] FROM organization WHERE _active=true AND id = ANY(fund_ids);
  END IF;

  -- begin statements
  execute_statement:= 'SELECT id, _title FROM activity WHERE ARRAY[id] <@ (SELECT array_agg(DISTINCT o.activity_id) as a FROM ';
  org_statement := '(SELECT distinct activity_id FROM _filter_organizations ';
  tax_statement := 'JOIN (SELECT distinct t1.activity_id FROM  ';

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
  IF array_length(valid_imp_ids, 1) > 0 THEN
    org_where := array_append(org_where, '(organization_ids && ARRAY[' || array_to_string(valid_imp_ids, ',') || '] AND role = ''Implementing'')');
  END IF;
   -- restrict returned results by org id(s)
  IF array_length(valid_fund_ids, 1) > 0 THEN
    org_where := array_append(org_where, '(organization_ids && ARRAY[' || array_to_string(valid_imp_ids, ',') || '] AND role = ''Funding'')');
  END IF;
  -- restrict returned results by start date
  IF $7 IS NOT NULL THEN
    date_where := array_append(date_where, '_start_date >= ' || quote_literal($7));
  END IF;
  -- restrict returned results by end date
  IF $8 IS NOT NULL THEN
    date_where := array_append(date_where, '_end_date <= ' || quote_literal($8));
  END IF;

   -- build statements
  IF dg_where IS NOT NULL THEN
    org_statement := org_statement || 'WHERE ' || dg_where;
  END IF;

  -- build _filter_taxonomies statement
  IF array_length(tax_where, 1) > 0 THEN
    idx := 1;
    FOREACH w IN ARRAY tax_where LOOP
      IF dg_where IS NOT NULL THEN
        IF idx = 1 THEN
          tax_joins := array_append(tax_joins, '(SELECT activity_id FROM _filter_taxonomies WHERE ' || dg_where ||
  	    ' AND ' || w || ') t' || idx);
        ELSE
          tax_joins := array_append(tax_joins, '(SELECT activity_id FROM _filter_taxonomies WHERE ' || dg_where ||
  	    ' AND ' || w || ') t' || idx || ' ON t' || idx - 1 || '.activity_id = t' || idx || '.activity_id ');
        END IF;
      ELSE 
        IF idx = 1 THEN
          tax_joins := array_append(tax_joins, '(SELECT activity_id FROM _filter_taxonomies WHERE ' ||  w || ') t' || idx);
        ELSE
          tax_joins := array_append(tax_joins, '(SELECT activity_id FROM _filter_taxonomies WHERE ' ||  w || ') t' || idx 
            || ' ON t' || idx - 1 || '.activity_id = t' || idx || '.activity_id ');
        END IF;        
      END IF;
      idx := idx + 1;
    END LOOP; 
    tax_statement := tax_statement || array_to_string(tax_joins, ' JOIN ');
  ELSE
    IF dg_where IS NOT NULL THEN
      tax_statement := tax_statement || '(SELECT activity_id FROM _filter_taxonomies WHERE ' || dg_where || ') t1';  
    ELSE
      tax_statement := tax_statement || '(SELECT activity_id FROM _filter_taxonomies ) t1';  
    END IF;    
  END IF;

  -- build _filter_organizations statement
  IF array_length(org_where, 1) > 0 THEN
    IF dg_where IS NOT NULL THEN
      org_statement := org_statement || ' AND (' || array_to_string(org_where, ' AND ') || ') ';
    ELSE 
      org_statement := org_statement || 'WHERE (' || array_to_string(org_where, ' AND ') || ') ';
    END IF;
  END IF;

  org_statement := org_statement || ') as o ';
  tax_statement := tax_statement || ') as c ';
  
  execute_statement:= execute_statement || org_statement || tax_statement ||
		'ON o.activity_id = c.activity_id ' ||
		'LEFT JOIN _filter_boundaries ab ON o.activity_id = ab.activity_id ' ||
		'WHERE ab.boundary_id = ' || valid_boundary_id || ' AND ab.feature_id = ' || $2;

   -- add date filter if applicable		
  IF array_length(date_where, 1) > 0 THEN
    execute_statement:= execute_statement || ' AND ab.activity_id IN (SELECT id FROM activity WHERE ' || array_to_string(date_where, ' AND ') || ') ';
  END IF;
  
  RAISE NOTICE 'Execute statement: %', execute_statement;			

  FOR rec IN EXECUTE 'SELECT row_to_json(j) FROM (' || execute_statement || '))j' LOOP  		
	RETURN NEXT rec;
  END LOOP;
  
END;$$ LANGUAGE plpgsql;