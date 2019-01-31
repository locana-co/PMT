/******************************************************************
Change Script 2.0.6.32 - Consolidated.
1. pmt_stat_counts -  bug fix.
******************************************************************/
INSERT INTO config(version, iteration, changeset) VALUES (2.0, 6, 32);
-- select * from config order by version, iteration, changeset, updated_date;

-- select * from pmt_stat_counts('107,768', '100', '', null, null);
-- select * from pmt_stat_counts('59,94,107,126,160,186,244,256,768', '', '', '1-1-2009', '12-31-2017')

CREATE OR REPLACE FUNCTION pmt_stat_counts(classification_ids character varying, organization_ids character varying, unassigned_tax_ids character varying, 
start_date date, end_date date)
RETURNS SETOF pmt_stat_counts_result AS 
$$
DECLARE
  rec record;
  filter_classids integer array;
  filter_orgids integer array;
  include_taxids integer array;
  dynamic_where1 text array;  
  dynamic_org_where text array;
  dynamic_where2 text;
  org_where text array;
  built_where text array;
  where_statement text;
  execute_statement text;
  i integer;
  num_projects integer;
  num_activities integer;
  num_orgs integer;
  num_districts integer;
BEGIN
  -- filter by classification ids
   IF ($1 is not null AND $1 <> '') THEN

      -- Create an int array from classification ids list
	filter_classids := string_to_array($1, ',')::int[];

      -- Loop through each taxonomy classification group to contruct the where statement 
	FOR rec IN( 
	SELECT tc.taxonomy_id, array_agg(tc.classification_id) AS filter_array 
	FROM taxonomy_classifications tc 
	WHERE classification_id = ANY(filter_classids) GROUP BY tc.taxonomy_id
	) LOOP				
	  built_where := null;
	  -- for each classification add to the where statement
	  FOREACH i IN ARRAY rec.filter_array LOOP				
		built_where :=  array_append(built_where, 'classification_ids @> ARRAY['|| i ||']');
	  END LOOP;
	  -- add each classification within the same taxonomy to the where joined by 'OR'
	  dynamic_where1 := array_append(dynamic_where1, '(' || array_to_string(built_where, ' OR ') || ')');
	  dynamic_org_where := array_append(dynamic_org_where, '(' || array_to_string(built_where, ' OR ') || ')');
	END LOOP;			
   END IF;
   
   -- filter by organization ids
   IF ($2 is not null AND $2 <> '') THEN

      -- Create an int array from organization ids list
	filter_orgids := string_to_array($2, ',')::int[];		

      -- Loop through the organization_ids and construct the where statement
	built_where := null;
	FOREACH i IN ARRAY filter_orgids LOOP
		built_where :=  array_append(built_where, 'organization_ids @> ARRAY['|| i ||']');
		org_where := array_append(org_where, 'organization_id = ' || i ||' ');
	END LOOP;
	-- Add the complied org statements to the where
	dynamic_where1 := array_append(dynamic_where1, '(' || array_to_string(built_where, ' OR ') || ')');
	dynamic_org_where := array_append(dynamic_org_where, '(' || array_to_string(org_where, ' OR ') || ')');
   END IF;
   -- include unassigned taxonomy ids
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
	dynamic_org_where := array_append(dynamic_org_where, '(start_date > ''' || $4 || ''' AND end_date < ''' || $5 || ''')');
   END IF;	
   
   -- prepare where statement
   IF dynamic_where1 IS NOT NULL THEN          
    IF dynamic_where2 IS NOT NULL THEN
      where_statement := array_to_string(dynamic_where1, ' AND ')  || ' OR ' || dynamic_where2;
    ELSE
      where_statement :=  array_to_string(dynamic_where1, ' AND ') || ' ';
    END IF;
   ELSE 
    IF dynamic_where2 IS NOT NULL THEN
      where_statement :=  dynamic_where2 || ' ';                       
    END IF;
   END IF;

   -- number of projects
   execute_statement := 'SELECT count(DISTINCT project_id)::int FROM location_lookup ';
   IF where_statement IS NOT NULL THEN 	execute_statement := execute_statement || ' WHERE ' || where_statement;  END IF;
   RAISE NOTICE 'Number of projects : %', execute_statement;
   EXECUTE execute_statement INTO num_projects;   
   
   -- number of activities
   execute_statement := 'SELECT count(DISTINCT activity_id)::int FROM location_lookup ';
   IF where_statement IS NOT NULL THEN 	execute_statement := execute_statement || ' WHERE ' || where_statement;  END IF;
   RAISE NOTICE 'Number of activities : %', execute_statement;
   EXECUTE execute_statement INTO num_activities;

    -- number of districts
   execute_statement := 'SELECT count(DISTINCT lbf.name)::int FROM (SELECT location_id ' ||
			'FROM location_lookup ';
   IF where_statement IS NOT NULL THEN 	execute_statement := execute_statement || ' WHERE ' || where_statement;  END IF;
   execute_statement := execute_statement || ') as l JOIN location_boundary_features lbf ON l.location_id = lbf.location_id ' ||
			'WHERE lbf.boundary_id = (SELECT boundary_id FROM boundary WHERE spatial_table = ''gaul2'')';
   RAISE NOTICE 'Number of districts : %', execute_statement;			
   EXECUTE execute_statement INTO num_districts;
   
   -- number of orgs
   execute_statement := 'SELECT count(DISTINCT organization_id)::int FROM organization_lookup ' ||
			'WHERE (classification_ids @> ARRAY[(select classification_id from classification where taxonomy_id = (select taxonomy_id from taxonomy where name = ''Organisation Role'') AND iati_name = ''Implementing'')]) ';

    -- prepare where statement
   IF dynamic_org_where IS NOT NULL THEN          
    IF dynamic_where2 IS NOT NULL THEN
      where_statement := array_to_string(dynamic_org_where, ' AND ')  || ' OR ' || dynamic_where2;
    ELSE
      where_statement :=  array_to_string(dynamic_org_where, ' AND ') || ' ';
    END IF;
   ELSE 
    IF dynamic_where2 IS NOT NULL THEN
      where_statement :=  dynamic_where2 || ' ';                       
    END IF;
   END IF;
   			
   IF where_statement IS NOT NULL THEN 	execute_statement := execute_statement || ' AND ' || where_statement;  END IF;
   RAISE NOTICE 'Number of orgs : %', execute_statement;
   EXECUTE execute_statement INTO num_orgs;

  
   
   FOR rec IN EXECUTE 'select row_to_json(t) from (SELECT ' || 
   'coalesce('|| num_projects || ', 0) as p_ct, ' || 
   'coalesce('|| num_activities || ', 0) as a_ct, ' || 
   'coalesce('|| num_orgs || ', 0) as o_ct, ' || 
   'coalesce('|| num_districts || ', 0) as d_ct ' || 
   ') t;' LOOP
     RETURN NEXT rec; 
   END LOOP;
   	
END;$$ LANGUAGE plpgsql;

