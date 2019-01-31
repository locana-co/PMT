/******************************************************************
Change Script 2.0.7.12 - Consolidated.
1. pmt_filter_locations - remove g_id from return results.
2. pmt_filter_orgs - remove g_id from return results.
******************************************************************/
INSERT INTO config(version, iteration, changeset) VALUES (2.0, 7, 12);
-- select * from config order by version, iteration, changeset, updated_date;

DROP FUNCTION IF EXISTS pmt_filter_locations(integer, character varying, character varying, character varying, date, date) CASCADE;
DROP FUNCTION IF EXISTS pmt_filter_orgs(character varying, character varying, character varying, date, date) CASCADE;
DROP TYPE IF EXISTS pmt_filter_locations_result CASCADE;
DROP TYPE IF EXISTS pmt_filter_orgs_result CASCADE;
CREATE TYPE pmt_filter_locations_result AS (l_id integer, r_ids text);
CREATE TYPE pmt_filter_orgs_result AS (l_id integer, r_ids text); 

/******************************************************************
  pmt_filter_locations
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_filter_locations(tax_id integer, classification_ids character varying, organization_ids character varying, 
 unassigned_tax_ids character varying, start_date date, end_date date)
RETURNS SETOF pmt_filter_locations_result AS 
$$
DECLARE
  rec record;
  valid_taxonomy_id boolean;
  report_by_category boolean; 
  report_taxonomy_id integer;
  filter_classids integer array;
  filter_orgids integer array;
  include_taxids integer array;
  dynamic_where2 text array; 
  dynamic_where4 text;
  built_where text array;
  execute_statement text;
  i integer;
BEGIN
	RAISE NOTICE 'Beginning execution of the pmt_filter_location function...';

	-- validate and process taxonomy_id parameter
	SELECT INTO valid_taxonomy_id * FROM pmt_validate_taxonomy($1); 
	
	-- Must have taxonomy_id parameter to continue
	IF NOT valid_taxonomy_id THEN
	   RAISE NOTICE '   + A taxonomy is required.';
	ELSE	
		   		
		  report_taxonomy_id := $1;
		  -- is this taxonomy a category?
		  SELECT INTO report_by_category is_category FROM taxonomy WHERE taxonomy_id = (report_taxonomy_id);      
		  -- yes, this is a category taxonomy
		  IF report_by_category THEN
		    -- what are the root taxonomy(ies) of the category taxonomy
		    SELECT INTO report_taxonomy_id * FROM pmt_category_root(report_taxonomy_id, null);		    
		    IF report_taxonomy_id IS NULL THEN
		      -- there is no root taxonomy
		      report_taxonomy_id := $1;
		      report_by_category := false;
		    END IF;
		  END IF;		      
		    
		-- The all filters are null so get everything and report by the taxonomy
		IF ($2 is null OR $2 = '') AND ($3 is null OR $3 = '') AND ($4 is null OR $4 = '') AND ($5 is null OR $6 is null) THEN
			RAISE NOTICE '   + No classification or organization or date filter.';
			RAISE NOTICE '   + The reporting taxonomy is: %.', $1;
			
			FOR rec IN SELECT t2.location_id as l_id, t2.georef as g_id, array_to_string(array_agg(DISTINCT report_by.classification_id), ',') as cl_id
			FROM location_lookup AS t2
			LEFT JOIN
			(SELECT DISTINCT location_id, classification_id FROM taxonomy_lookup 
			WHERE taxonomy_id = report_taxonomy_id) AS report_by 
			ON t2.location_id = report_by.location_id
			GROUP BY t2.location_id, t2.georef	
			ORDER BY t2.georef LOOP
		          -- if reporting by a category then swap the classification_ids
			  IF report_by_category THEN 
			    SELECT INTO rec.cl_id array_to_string(array_agg(DISTINCT category_id), ',') FROM classification WHERE classification_id = ANY(string_to_array(rec.cl_id, ',')::int[]);
			    RETURN NEXT rec;
			  ELSE
			    RETURN NEXT rec;    
			  END IF;
			END LOOP;
		-- filtering	
		ELSE
		   -- filter by classification ids
		   IF ($2 is not null AND $2 <> '') THEN
		      RAISE NOTICE '   + The classification filter is: %.', string_to_array($2, ',')::int[];

			SELECT INTO filter_classids * FROM pmt_validate_classifications($2);

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
				dynamic_where2 := array_append(dynamic_where2, '(' || array_to_string(built_where, ' OR ') || ')');
			  END LOOP;			
			END IF;
		   END IF;
		   
		   -- filter by organization ids
		   IF ($3 is not null AND $3 <> '') THEN
		      RAISE NOTICE '   + The organization filter is: %.', string_to_array($3, ',')::int[];

		      -- Create an int array from organization ids list
			filter_orgids := string_to_array($3, ',')::int[];

		      -- Loop through the organization_ids and construct the where statement
			built_where := null;
			FOREACH i IN ARRAY filter_orgids LOOP
				built_where :=  array_append(built_where, 'organization_ids @> ARRAY['|| i ||']');
			END LOOP;
			-- Add the complied org statements to the where
			dynamic_where2 := array_append(dynamic_where2, '(' || array_to_string(built_where, ' OR ') || ')');
			
		   END IF;

		   -- include values with unassigned taxonomy(ies)
		   IF ($4 is not null AND $4 <> '') THEN
		      RAISE NOTICE '   + The include unassigned is: %.', string_to_array($4, ',')::int[];

		      -- Create an int array from unassigned ids list
		      include_taxids := string_to_array($4, ',')::int[];				

		      -- Loop through the organization_ids and construct the where statement
		      built_where := null;
		      FOREACH i IN ARRAY include_taxids LOOP
			built_where :=  array_append(built_where, 'not (taxonomy_ids @> ARRAY['|| i ||'])');
		      END LOOP;			
		      -- Add the complied org statements to the where
		      dynamic_where4 := '(' || array_to_string(built_where, ' OR ') || ')';
			
		   END IF;

		   -- filter by date range
		   IF ($5 is not null AND $6 is not null) THEN
			RAISE NOTICE '   + The date filter is: %.', $5 || ' & ' || $6;
			dynamic_where2 := array_append(dynamic_where2, '(start_date > ''' || $5 || ''' AND end_date < ''' || $6 || ''')');
		   END IF;
		   
		   -- prepare statement				
		   RAISE NOTICE '   + The reporting taxonomy is: %.', $1;												
		   RAISE NOTICE '   + Second where statement: %', array_to_string(dynamic_where2, ' AND ');
		   RAISE NOTICE '   + Forth where statement: %', dynamic_where4;

		   execute_statement := 'SELECT t2.location_id as l_id, array_to_string(array_agg(DISTINCT report_by.classification_id), '','') as cl_id ' ||
				'FROM( ' ||
				'SELECT location_id, georef, classification_ids FROM location_lookup ';
				
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
				'LEFT JOIN ' ||
				'(SELECT * FROM taxonomy_lookup  ' ||
				'WHERE taxonomy_lookup.taxonomy_id = ' || report_taxonomy_id || ') AS report_by  ' ||
				'ON t2.location_id = report_by.location_id ' ||
				'GROUP BY t2.location_id, t2.georef ' ||	
				'ORDER BY t2.georef ';  

		-- execute statement		
		RAISE NOTICE 'execute: %', execute_statement;		
		FOR rec IN EXECUTE execute_statement				
		 LOOP
		  IF report_by_category THEN 
		    SELECT INTO rec.cl_id array_to_string(array_agg(DISTINCT category_id), ',') FROM classification WHERE classification_id = ANY(string_to_array(rec.cl_id, ',')::int[]);
		    RETURN NEXT rec;
		  ELSE
		    RETURN NEXT rec;    
		  END IF;
		END LOOP;	
	END IF;
    END IF;
END;$$ LANGUAGE plpgsql;

/******************************************************************
  pmt_filter_orgs
******************************************************************/
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
  execute_statement := 'SELECT t1.location_id as l_id, array_to_string(t1.organization_ids, '','') as r_id  ' ||
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

-- update permissions
GRANT USAGE ON SCHEMA public TO pmt_read;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO pmt_read;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO pmt_read;
GRANT USAGE ON SCHEMA public TO pmt_write;
GRANT SELECT,INSERT ON ALL TABLES IN SCHEMA public TO pmt_write;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO pmt_write;