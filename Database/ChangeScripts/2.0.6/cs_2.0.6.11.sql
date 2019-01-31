/******************************************************************
Change Script 2.0.6.11 - Consolidated

1. pmt_locations_by_tax - performance upgrade
2. pmt_locations_by_org - performance upgrade
3. pmt_filter_locations - performance upgrade
4. pmt_activity_listview - performance upgrade
******************************************************************/
UPDATE config SET changeset = 11, updated_date = current_date WHERE "version" = 2.0 AND iteration = 6;
-- SELECT pmt_version();

-- select * from pmt_locations_by_tax (null, null, '');
-- select * from pmt_locations_by_tax(1, null, '');
-- select * from pmt_locations_by_tax (10, 725, ''); 
-- select * from pmt_locations_by_tax (10, 772, '50');

-- select * from pmt_locations_by_org(null, 768,'');
-- select * from pmt_locations_by_org (null, 772, '50');
-- select * from pmt_locations_by_org (null, null, null);

-- select * from pmt_filter_locations(1,'', '', '', null, null);
-- select * from pmt_filter_locations(10,'768', '', '', null, null);
-- select * from pmt_filter_locations(10, '768', '13', '', '1-1-2010', '1-1-2012');
-- select * from pmt_filter_locations(22,'816', '', '22', null, null);

-- select * from  pmt_activity_listview(15, '771,496', '', '','a_name', 20, 20);
/******************************************************************
  pmt_locations_by_tax
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_locations_by_tax(tax_id Integer, data_group Integer, country_ids character varying)
RETURNS SETOF pmt_locations_by_tax_result_type AS 
$$
DECLARE
  data_group_id integer;
  valid_country_ids int[];
  valid_classification_ids int[];
  valid_taxonomy_id boolean;
  valid_classification_id boolean;
  report_by_category boolean; 
  report_taxonomy_id integer;
  built_where text array;
  dynamic_where1 text;
  dynamic_where2 text array;  
  execute_statement text;
  i integer;
  rec record;
BEGIN
  report_by_category := false; -- intialize to false  
  
  -- validate and process taxonomy_id parameter
  IF $1 IS NOT NULL THEN
    SELECT INTO valid_taxonomy_id * FROM pmt_validate_taxonomy($1);    
    -- has valid taxonomy id
    IF valid_taxonomy_id THEN 
       report_taxonomy_id := $1;
      -- is this taxonomy a category?
      SELECT INTO report_by_category is_category FROM taxonomy WHERE taxonomy_id = (report_taxonomy_id);      
      -- yes, this is a category taxonomy
      IF report_by_category THEN
        -- what are the root taxonomy(ies) of the category taxonomy
        SELECT INTO report_taxonomy_id * FROM pmt_category_root(report_taxonomy_id, data_group);
        -- there are root taxonomy(ies)
        IF report_taxonomy_id IS NOT NULL THEN
           -- RAISE NOTICE 'report_taxonomy_id: %', report_taxonomy_id;
        ELSE
          report_taxonomy_id := $1;
          report_by_category := false;
        END IF;
      END IF;      
    END IF;	
  END IF;

    -- validate and process country_ids parameter
  IF $3 IS NOT NULL OR $3 <> '' THEN
    SELECT INTO valid_classification_ids * FROM pmt_validate_classifications($3);
    RAISE NOTICE 'valid classification ids: %', valid_classification_ids;
  END IF;
    
  -- validate and process data_group parameter
  IF $2 IS NOT NULL THEN
    -- validate the classification id
    SELECT INTO valid_classification_id * FROM pmt_validate_classification($2);

    IF valid_classification_id THEN
      IF valid_classification_ids IS NOT NULL THEN
        valid_classification_ids := array_append(valid_classification_ids, $2);
      ELSE
        valid_classification_ids := array[$2];
      END IF;
    END IF;
  END IF;

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
	dynamic_where2 := array_append(dynamic_where2, '(' || array_to_string(built_where, ' OR ') || ')');
  END LOOP;			
END IF;
  
  -- prepare statement
  execute_statement := 'SELECT t2.location_id as l_id, t2.x, t2.y, array_to_string(array_agg(DISTINCT report_by.classification_id), '','') as c_ids ' ||
				'FROM( ' ||
				'SELECT DISTINCT location_id, x, y, georef, classification_ids FROM location_lookup ';
				
  IF dynamic_where2 IS NOT NULL THEN          
    execute_statement := execute_statement || ' WHERE ' ||  array_to_string(dynamic_where2, ' AND ');
  END IF;

  IF report_taxonomy_id IS NULL THEN report_taxonomy_id := 1; END IF;
  
  execute_statement := execute_statement || ') as t2 ' ||
				'LEFT JOIN ' ||
				'(SELECT distinct location_id, classification_id FROM taxonomy_lookup  ' ||
				'WHERE taxonomy_lookup.taxonomy_id = ' || report_taxonomy_id || ') AS report_by  ' ||
				'ON t2.location_id = report_by.location_id ' ||
				'GROUP BY t2.location_id,t2.x, t2.y, t2.georef ' ||	
				'ORDER BY t2.georef ';  
  -- execute statement
  RAISE NOTICE 'Where statement: %', dynamic_where2;
  RAISE NOTICE 'Execute statement: %', execute_statement;
  FOR rec IN EXECUTE execute_statement	    
  LOOP
   IF report_by_category THEN 
      SELECT INTO rec.c_ids array_to_string(array_agg(DISTINCT category_id), ',') FROM classification WHERE classification_id = ANY(string_to_array(rec.c_ids, ',')::int[]);
      RETURN NEXT rec;
    ELSE
      RETURN NEXT rec;    
    END IF;
  END LOOP;
  
END;$$ LANGUAGE plpgsql;


/******************************************************************
  pmt_locations_by_org
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_locations_by_org(class_id Integer, data_group Integer, country_ids character varying)
RETURNS SETOF pmt_locations_by_org_result_type AS 
$$
DECLARE
  valid_classification_id boolean;
  valid_classification_ids int[];
  dynamic_where2 text array;
  dynamic_join text;
  built_where text array;
  i integer;
  execute_statement text;
  rec record;
BEGIN
  -- validate country_ids parameter
  IF $3 IS NOT NULL OR $3 <> '' THEN
    SELECT INTO valid_classification_ids * FROM pmt_validate_classifications($3);    
    RAISE NOTICE 'Valid classifications (country_ids): %', valid_classification_ids;
  END IF;
  
  -- validate and process classification_id parameter
  IF $1 IS NOT NULL THEN
    SELECT INTO valid_classification_id * FROM pmt_validate_classification($1);  
    RAISE NOTICE 'Valid classification id: %', valid_classification_id;  
    -- has valid classification id
    IF valid_classification_id THEN
      -- if the list of valid classification ids is not nulll add it
      IF valid_classification_ids IS NOT NULL THEN
        valid_classification_ids := array_append(valid_classification_ids, $1);
      -- if the list of valid classification ids is null, create it
      ELSE
        valid_classification_ids := array[$1];
      END IF;
    END IF;	
  END IF;

  -- validate and process data_group parameter
  IF $2 IS NOT NULL THEN
    SELECT INTO valid_classification_id * FROM pmt_validate_classification($2);    
    RAISE NOTICE 'Valid data group: %', valid_classification_id;  
    -- has valid classification id
    IF valid_classification_id THEN
      -- if the list of valid classification ids is not nulll add it
      IF valid_classification_ids IS NOT NULL THEN
        valid_classification_ids := array_append(valid_classification_ids, $2);
      -- if the list of valid classification ids is null, create it
      ELSE
        valid_classification_ids := array[$2];
      END IF;
    END IF;	   
  END IF;

  -- create dynamic where
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
	dynamic_where2 := array_append(dynamic_where2, '(' || array_to_string(built_where, ' OR ') || ')');
  END LOOP;			
END IF;
  

  -- prepare statement
  execute_statement := 'SELECT location_id, x, y, array_to_string(organization_ids, '','') AS o_ids  FROM location_lookup';
				
  IF dynamic_where2 IS NOT NULL THEN          
    execute_statement := execute_statement || ' WHERE ' ||  array_to_string(dynamic_where2, ' AND ');
  END IF;

  execute_statement := execute_statement || ' ORDER BY georef ';  
				   
  -- execute statement
  RAISE NOTICE 'Where statement: %', dynamic_where2;
  RAISE NOTICE 'Execute statement: %', execute_statement;
  FOR rec IN EXECUTE execute_statement	    
  LOOP
    RETURN NEXT rec;    
  END LOOP;
  
END;$$ LANGUAGE plpgsql;
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

		   execute_statement := 'SELECT t2.location_id as l_id, t2.georef as g_id, array_to_string(array_agg(DISTINCT report_by.classification_id), '','') as cl_id ' ||
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


-- Function statements
CREATE OR REPLACE FUNCTION pmt_activity_listview(tax_id integer, classification_ids character varying, organization_ids character varying, unassigned_tax_ids character varying, 
orderby text, limit_rec integer, offset_rec integer)
RETURNS SETOF pmt_activity_listview_result AS 
$$
DECLARE
  valid_taxonomy_id boolean;
  report_by_category boolean; 
  report_taxonomy_id integer;
  filter_classids integer array;
  filter_orgids integer array;
  include_taxids integer array;  
  rec record;  
  dynamic_where1 text array;
  dynamic_where2 text;
  built_where text array; 
  execute_statement text;
  count_statement text;
  paging_statement text;
  record_count integer;
  i integer;
BEGIN

-- validate and process taxonomy_id parameter
SELECT INTO valid_taxonomy_id * FROM pmt_validate_taxonomy($1); 

-- Must have valid taxonomy_id parameter to continue
IF NOT valid_taxonomy_id THEN
  RAISE NOTICE '   + A taxonomy is required.';
-- Has a valid taxonomy_id parameter 
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
		dynamic_where1 := array_append(dynamic_where1, '(' || array_to_string(built_where, ' OR ') || ')');
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
	dynamic_where1 := array_append(dynamic_where1, '(' || array_to_string(built_where, ' OR ') || ')');
	
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
      dynamic_where2 := '(' || array_to_string(built_where, ' OR ') || ')';
	
    END IF;
   
    -- create dynamic paging statment
    IF $5 IS NOT NULL AND $5 <> '' THEN
      IF paging_statement IS NOT NULL THEN
        paging_statement := paging_statement || 'ORDER BY ' || $5 || ' ';
      ELSE
        paging_statement := ' ORDER BY ' || $5 || ' ';
      END IF;
    END IF;		    
    IF $6 IS NOT NULL AND $6 > 0 THEN
      IF paging_statement IS NOT NULL THEN
        paging_statement := paging_statement || 'LIMIT ' || $6 || ' ';
      ELSE
        paging_statement := ' LIMIT ' || $6 || ' ';
      END IF;
    END IF;		
    IF $7 IS NOT NULL AND $7 > 0 THEN
      IF paging_statement IS NOT NULL THEN
        paging_statement := paging_statement || 'OFFSET ' || $7 || ' ';
      ELSE
        paging_statement := ' OFFSET ' || $7 || ' ';
      END IF;      
    END IF;		

    -- prepare statement				
    RAISE NOTICE '   + The reporting taxonomy is: %', $1;
    RAISE NOTICE '   + The base taxonomy is: % ', report_taxonomy_id;												
    RAISE NOTICE '   + First where statement: %', array_to_string(dynamic_where1, ' AND ');
    RAISE NOTICE '   + Second where statement: %', dynamic_where2;
    RAISE NOTICE '   + The paging statement: %', paging_statement;
		
    -- prepare statement for the selection
    execute_statement := 'SELECT filter.activity_id AS a_id, filter.title AS a_name, filter.description AS a_desc, filter.start_date as a_date1, filter.organization_id as o_id, filter.name as o_name, report_by.name as r_name ' ||
			'FROM (SELECT t1.activity_id, a.title, a.description, a.start_date, t1.organization_id, o.name FROM ' ||
			-- filter 
			'(SELECT * FROM organization_lookup ) as t1 ' ||
			-- activity
			'JOIN (SELECT activity_id, title, description, start_date, end_date from activity) as a ' ||
			'ON t1.activity_id = a.activity_id ' ||
			-- organization
			'JOIN (SELECT organization_id, name from organization) as o ' ||
			'ON t1.organization_id = o.organization_id ';
			
    -- append where statements			
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

    IF report_by_category THEN
      execute_statement := execute_statement || ') as filter ' ||
			-- report by
			'LEFT JOIN (SELECT DISTINCT tl.activity_id, cc.name FROM taxonomy_lookup tl ' ||
			'JOIN classification c ON tl.classification_id = c.classification_id ' ||
			'JOIN classification cc ON c.category_id = cc.classification_id ' ||
			-- dynamic where
			'WHERE tl.taxonomy_id = ' || report_taxonomy_id ||') as report_by ' ||			
			'ON filter.activity_id = report_by.activity_id ' ||
			'GROUP BY filter.activity_id, filter.title, filter.organization_id, filter.name ';
    ELSE
      execute_statement := execute_statement || ') as filter ' ||
			-- report by
			'LEFT JOIN (SELECT DISTINCT tl.activity_id, array_to_string(array_agg(distinct c.name), '','') as name FROM taxonomy_lookup tl ' ||
			'JOIN classification c ON tl.classification_id = c.classification_id ' ||
			-- dynamic where
			'WHERE tl.taxonomy_id = ' || report_taxonomy_id ||' GROUP BY tl.activity_id ) as report_by ' ||			
			'ON filter.activity_id = report_by.activity_id ';
    END IF;			
    
    -- if there is a paging request then add it
    IF paging_statement IS NOT NULL THEN 
      execute_statement := execute_statement || ' ' || paging_statement;
    END IF;
    
    -- execute statement		
    RAISE NOTICE 'execute: %', 'SELECT row_to_json(j) FROM (' || execute_statement || ')j';	   
     
    FOR rec IN EXECUTE 'SELECT row_to_json(j) FROM (' || execute_statement || ')j' LOOP     
	RETURN NEXT rec;
    END LOOP;	

END IF; -- Must have valid taxonomy_id parameter to continue

END;$$ LANGUAGE plpgsql;


