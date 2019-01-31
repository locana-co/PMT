/******************************************************************
Change Script 2.0.6.3 - Consolidated
1. pmt_filter_orgs - complete redesign. 
2. pmt_org_inuse - new function.
******************************************************************/
UPDATE config SET changeset = 3, updated_date = current_date WHERE "version" = 2.0 AND iteration = 6;
-- select * from pmt_version()
/******************************************************************
  pmt_filter_orgs
******************************************************************/
DROP FUNCTION IF EXISTS pmt_filter_orgs(character varying, character varying, date, date) CASCADE;
DROP FUNCTION IF EXISTS pmt_filter_orgs(character varying, character varying, character varying, date, date) CASCADE;
DROP TYPE IF EXISTS pmt_filter_orgs_result;
CREATE TYPE pmt_filter_orgs_result AS (l_id integer, g_id character varying(20),  r_ids text);  
CREATE OR REPLACE FUNCTION pmt_filter_orgs(classification_ids character varying, organization_ids character varying, unassigned_tax_ids character varying, 
start_date date, end_date date)
RETURNS SETOF pmt_filter_orgs_result AS 
$$
DECLARE
  rec record;
  filter_classids integer array;
  filter_orgids integer array;
  include_taxids integer array;
  dynamic_where1 text array;
  dynamic_where2 text;
  built_where text array;
  execute_statement text;
  i integer;
BEGIN
  -- filter by classification ids
  IF ($1 is not null AND $1 <> '') THEN
    SELECT INTO filter_classids * FROM pmt_validate_classifications($1);

    IF filter_classids IS NOT NULL THEN
      -- Loop through each taxonomy classification group to contruct the where statement 
      FOR rec IN( SELECT tc.taxonomy_id, array_agg(tc.classification_id) AS filter_array 
      FROM taxonomy_classifications tc WHERE classification_id = ANY(filter_classids) GROUP BY tc.taxonomy_id
      ) LOOP				
	built_where := null;
	-- for each classification add to the where statement
	FOREACH i IN ARRAY rec.filter_array LOOP 
	  built_where :=  array_append(built_where, 'classification_ids @> ARRAY['|| i ||']');
	END LOOP;
	-- add each classification within the same taxonomy to the where joined by 'OR'
	dynamic_where1 := array_append(dynamic_where1, '(' || array_to_string(built_where, ' OR ') || ')');
      END LOOP;			
    END IF;
  END IF;

  -- filter by organization ids
  IF ($2 is not null AND $2 <> '') THEN
    -- Create an int array from organization ids list
    filter_orgids := string_to_array($2, ',')::int[];
    -- Loop through the organization_ids and construct the where statement
    built_where := null;
    FOREACH i IN ARRAY filter_orgids LOOP
	built_where :=  array_append(built_where, 'organization_ids @> ARRAY['|| i ||']');
    END LOOP;
    -- Add the complied org statements to the where
    dynamic_where1 := array_append(dynamic_where1, '(' || array_to_string(built_where, ' OR ') || ')');
  END IF;

  -- include values with unassigned taxonomy(ies)
  IF ($3 is not null AND $3 <> '') THEN
    -- Create an int array from unassigned ids list
    include_taxids := string_to_array($3, ',')::int[];				
    -- Loop through the organization_ids and construct the where statement
    built_where := null;
    FOREACH i IN ARRAY include_taxids LOOP
      built_where :=  array_append(built_where, 'not (taxonomy_ids @> ARRAY['|| i ||'])');
    END LOOP;			
    -- Add the complied org statements to the where
    dynamic_where2 := '(' || array_to_string(built_where, ' OR ') || ')';
  END IF;

  -- filter by date range
  IF ($4 is not null AND $5 is not null) THEN
    dynamic_where1 := array_append(dynamic_where1, '(start_date > ''' || $4 || ''' AND end_date < ''' || $5 || ''')');
  END IF;	

  RAISE NOTICE '   + Where1 statement: %', array_to_string(dynamic_where1, ' AND ');
  RAISE NOTICE '   + Where2 statement: %', dynamic_where2;
  
  -- prepare statement
  execute_statement := 'SELECT t1.location_id as l_id, t1.georef as g_id, array_to_string(t1.organization_ids, '','') as r_id  ' ||
			'FROM ( SELECT DISTINCT location_id, georef, start_date, end_date, array_agg(DISTINCT taxonomy_id) as taxonomy_ids, ' || 
			'array_agg(DISTINCT classification_id) as classification_ids, array_agg(DISTINCT organization_id) as organization_ids ' ||
			'FROM taxonomy_lookup GROUP BY location_id, georef, start_date, end_date ) AS t1  ';
			
  IF dynamic_where1 IS NOT NULL THEN          
    IF dynamic_where2 IS NOT NULL THEN
      execute_statement := execute_statement || ' WHERE ' ||  array_to_string(dynamic_where1, ' AND ')  || ' OR ' || dynamic_where2;
    ELSE
      execute_statement := execute_statement || ' WHERE ' ||  array_to_string(dynamic_where1, ' AND ') || ' ';
    END IF;
  ELSE 
    IF dynamic_where2 IS NOT NULL THEN
      execute_statement := execute_statement || ' WHERE ' || dynamic_where2 || ' ';                       
    END IF;
  END IF;

  execute_statement := execute_statement || 'ORDER BY t1.georef';

  -- execute statement		
  RAISE NOTICE 'Execute: %', execute_statement;		
  FOR rec IN EXECUTE execute_statement	LOOP
    RETURN NEXT rec;    
  END LOOP;	
		
END;$$ LANGUAGE plpgsql;

/******************************************************************
  pmt_org_inuse
******************************************************************/
DROP FUNCTION IF EXISTS pmt_org_inuse(character varying, character varying, date, date) CASCADE;
DROP FUNCTION IF EXISTS pmt_org_inuse(character varying) CASCADE;
DROP TYPE IF EXISTS pmt_org_inuse_result_type;
CREATE TYPE pmt_org_inuse_result_type AS (response json);
CREATE OR REPLACE FUNCTION pmt_org_inuse(classification_ids character varying)
RETURNS SETOF pmt_org_inuse_result_type AS $$
DECLARE
  valid_classification_ids int[];
  dynamic_where1 text array;
  built_where text array;
  execute_statement text;
  i integer;
  rec record;
BEGIN
  -- validate classification_ids parameter
  IF $1 IS NOT NULL OR $1 <> '' THEN
    SELECT INTO valid_classification_ids * FROM pmt_validate_classifications($1);    
    RAISE NOTICE 'Valid classifications: %', valid_classification_ids;
  END IF;

  -- create dynamic where from valid classification_ids
  IF valid_classification_ids IS NOT NULL THEN
    -- Loop through each taxonomy classification group to contruct the where statement 
    FOR rec IN( SELECT tc.taxonomy_id, array_agg(tc.classification_id) AS filter_array 
    FROM taxonomy_classifications tc WHERE classification_id = ANY(valid_classification_ids) GROUP BY tc.taxonomy_id
    ) LOOP				
	built_where := null;
	-- for each classification add to the where statement
	FOREACH i IN ARRAY rec.filter_array LOOP 
	  built_where :=  array_append(built_where, 'classification_ids @> ARRAY['|| i ||']');
	END LOOP;
	-- add each classification within the same taxonomy to the where joined by 'OR'
	dynamic_where1 := array_append(dynamic_where1, '(' || array_to_string(built_where, ' OR ') || ')');
    END LOOP;			
  END IF;
  
  -- prepare statement
  execute_statement := 'select row_to_json(j) from ( select org_order.organization_id as o_id, o.name ' ||
			'from ( select organization_id, count(distinct location_id) as location_count ' ||
			'from taxonomy_lookup '; 
  IF dynamic_where1 IS NOT NULL THEN          
    execute_statement := execute_statement || 'where location_id in (select location_id from (select location_id, array_agg(classification_id) as classification_ids from taxonomy_lookup group by location_id) as lookup ' ||
			'where ' ||  array_to_string(dynamic_where1, ' AND ') || ') ';
  END IF;

  execute_statement := execute_statement ||'group by organization_id ' ||
			') as org_order ' ||				 
			'join organization o on org_order.organization_id = o.organization_id ' || 
			'order by org_order.location_count desc ) j';
  
  RAISE NOTICE 'Where: %', dynamic_where1;	
  RAISE NOTICE 'Execute: %', execute_statement;
  		    
  -- execute statement
  FOR rec IN EXECUTE execute_statement	    
  LOOP
    RETURN NEXT rec;    
  END LOOP;
END;$$ LANGUAGE plpgsql;
