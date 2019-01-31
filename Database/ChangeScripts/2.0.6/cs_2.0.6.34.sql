/******************************************************************
Change Script 2.0.6.34 - Consolidated.
1. pmt_filter_projects - performance enhancement.
******************************************************************/
INSERT INTO config(version, iteration, changeset) VALUES (2.0, 6, 34);
-- select * from config order by version, iteration, changeset, updated_date;

CREATE OR REPLACE FUNCTION pmt_filter_projects(classification_ids character varying, organization_ids character varying, unassigned_tax_ids character varying, 
start_date date, end_date date)
RETURNS SETOF pmt_filter_projects_result AS 
$$
DECLARE
  rec record;
  filter_classids integer array;
  filter_orgids integer array;
  include_taxids integer array;
  dynamic_where1 text array;
  dynamic_where2 text array;
  dynamic_where3 text;
  dynamic_where4 text;
  built_where text array;
  execute_statement text;
  i integer;
BEGIN
	--RAISE NOTICE 'Beginning execution of the pmt_filter_project function...';

	-- Both classification & organization filters are null so get everything
	IF ($1 is null OR $1 = '') AND ($2 is null OR $2 = '') AND ($3 is null OR $3 = '') AND ($4 is null OR $5 is null) THEN
		--RAISE NOTICE '   + No classification or organization or date filter.';
		FOR rec IN SELECT project_id as p_id, array_to_string(array_agg(DISTINCT activity_id), ',') as a_ids
		   FROM taxonomy_lookup			
		   GROUP BY project_id	
		   ORDER BY project_id 
		LOOP
			RETURN NEXT rec;
		END LOOP;
	-- filtering	
	ELSE
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
		  dynamic_where2 := array_append(dynamic_where2, '(' || array_to_string(built_where, ' OR ') || ')');
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
		END LOOP;
		-- Add the complied org statements to the where
		dynamic_where2 := array_append(dynamic_where2, '(' || array_to_string(built_where, ' OR ') || ')');
		
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
	      dynamic_where4 := '(' || array_to_string(built_where, ' OR ') || ')';
		
	   END IF;
	   
	   -- filter by date range
	   IF ($4 is not null AND $5 is not null) THEN
		dynamic_where2 := array_append(dynamic_where2, '(start_date > ''' || $4 || ''' AND end_date < ''' || $5 || ''')');
	   END IF;		
	   										
	  -- prepare statement					
	  -- RAISE NOTICE '   + First where statement: %', array_to_string(dynamic_where1, ' AND ');
	  -- RAISE NOTICE '   + Second where statement: %', array_to_string(dynamic_where2, ' AND ');
	  -- RAISE NOTICE '   + Third where statement: %', dynamic_where3;
	  -- RAISE NOTICE '   + Forth where statement: %', dynamic_where4;

	  execute_statement := 'SELECT t2.project_id as p_id, array_to_string(array_agg(DISTINCT t2.activity_id), '','') as a_ids ' ||
			'FROM( ' ||
			'SELECT DISTINCT project_id, activity_id, location_id, georef, classification_ids ' ||
			'FROM location_lookup ';
			
	  IF dynamic_where2 IS NOT NULL THEN          
            IF dynamic_where4 IS NOT NULL THEN
              execute_statement := execute_statement || ' WHERE ' ||  array_to_string(dynamic_where2, ' AND ')  || ' OR ' || dynamic_where4;
            ELSE
              execute_statement := execute_statement || ' WHERE ' ||  array_to_string(dynamic_where2, ' AND ') || ' ';
            END IF;
          ELSE 
            IF dynamic_where4 IS NOT NULL THEN
              execute_statement := execute_statement || ' WHERE ' || dynamic_where4 || ' ';                       
            END IF;
          END IF;
          
	  execute_statement := execute_statement || ') as t2 ' ||			
			'GROUP BY t2.project_id ' ||	
			'ORDER BY t2.project_id ';

	  -- execute statement		
          RAISE NOTICE 'execute: %', execute_statement;			  
	  FOR rec IN EXECUTE execute_statement
	  LOOP
	    RETURN NEXT rec;
	  END LOOP;	
	END IF;	
END;$$ LANGUAGE plpgsql;