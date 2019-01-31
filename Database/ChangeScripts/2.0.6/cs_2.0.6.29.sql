/******************************************************************
Change Script 2.0.6.29 - Consolidated.
1. pmt_project_listview & pmt_project_listview_ct - adding date 
parameters.
******************************************************************/
INSERT INTO config(version, iteration, changeset) VALUES (2.0, 6, 29);
-- select * from config order by version, iteration, changeset, updated_date;

-- select * from pmt_project_listview(23, '769', '', '', '1-1-2012', '12-31-2014', '', null, null);
-- SELECT * FROM pmt_project_listview(23, '768', '', '', '1-1-1990','12-31-2014', 'title', 10, 20);
-- select * from pmt_project_listview_ct('769', '', '', '1-1-2012', '12-31-2014');
-- SELECT * FROM pmt_project_listview_ct('768', '', '', '1-1-1990','12-31-2014');

-- old
DROP FUNCTION IF EXISTS pmt_project_listview(integer, character varying, character varying, character varying, text, integer, integer) CASCADE;
DROP FUNCTION IF EXISTS pmt_project_listview_ct(character varying, character varying, character varying, text, integer, integer) CASCADE;
-- new
DROP FUNCTION IF EXISTS pmt_project_listview(integer, character varying, character varying, character varying, date, date, text, integer, integer) CASCADE;
DROP FUNCTION IF EXISTS pmt_project_listview_ct(character varying, character varying, character varying, date, date, text, integer, integer) CASCADE;

CREATE OR REPLACE FUNCTION pmt_project_listview(tax_id integer, classification_ids character varying, organization_ids character varying, unassigned_tax_ids character varying, 
start_date date, end_date date, orderby text, limit_rec integer, offset_rec integer)
RETURNS SETOF pmt_project_listview_result AS 
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

    -- filter by date range
    IF ($5 is not null AND $6 is not null) THEN
	dynamic_where1 := array_append(dynamic_where1, '(filter.start_date > ''' || $5 || ''' AND filter.end_date < ''' || $6 || ''')');
    END IF;	
	   
    -- create dynamic paging statment
    IF $7 IS NOT NULL AND $7 <> '' THEN
      IF paging_statement IS NOT NULL THEN
        paging_statement := paging_statement || 'ORDER BY ' || $5 || ' ';
      ELSE
        paging_statement := ' ORDER BY ' || $7 || ' ';
      END IF;
    END IF;		    
    IF $8 IS NOT NULL AND $8 > 0 THEN
      IF paging_statement IS NOT NULL THEN
        paging_statement := paging_statement || 'LIMIT ' || $8 || ' ';
      ELSE
        paging_statement := ' LIMIT ' || $8 || ' ';
      END IF;
    END IF;		
    IF $9 IS NOT NULL AND $9 > 0 THEN
      IF paging_statement IS NOT NULL THEN
        paging_statement := paging_statement || 'OFFSET ' || $9 || ' ';
      ELSE
        paging_statement := ' OFFSET ' || $9 || ' ';
      END IF;      
    END IF;	

    -- prepare statement				
    RAISE NOTICE '   + The reporting taxonomy is: %', $1;
    RAISE NOTICE '   + The base taxonomy is: % ', report_taxonomy_id;												
    RAISE NOTICE '   + First where statement: %', array_to_string(dynamic_where1, ' AND ');
    RAISE NOTICE '   + Second where statement: %', dynamic_where2;
    RAISE NOTICE '   + The paging statement: %', paging_statement;

     -- prepare statement for the selection
    execute_statement := 'select distinct  p.project_id AS p_id ,p.title ,p.activity_ids AS a_ids ,pa.orgs AS org ,pf.funding_orgs AS f_orgs ,i.c_name ' ||
			 'from ' ||
			 -- project/activity
			 '(select p.project_id, p.title, p.opportunity_id, array_agg(filter.activity_id) as activity_ids from project p ' ||
			 -- filter
			 'join (SELECT project_id, start_date, end_date, activity_id, array_agg(distinct taxonomy_id) as taxonomy_ids, array_agg(distinct classification_id) as classification_ids ' ||
			 ',array_agg(distinct organization_id) as organization_ids FROM taxonomy_lookup GROUP BY project_id, start_date, end_date, activity_id) as filter on p.project_id = filter.project_id ';

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

    execute_statement := execute_statement || '  GROUP BY p.project_id, p.title, p.opportunity_id ) p left join ' ||
			-- participants (Accountable)
			'(select pp.project_id, array_to_string(array_agg(distinct o.name), '','') as orgs from participation pp join organization o on pp.organization_id = o.organization_id ' ||
			'left join participation_taxonomy ppt on pp.participation_id = ppt.participation_id join classification c on ppt.classification_id = c.classification_id ' ||
			'where c.taxonomy_id = (select taxonomy_id from taxonomy where name = ''Organisation Role'') AND c.name = ''Accountable'' group by pp.project_id) pa on p.project_id = pa.project_id left join ' ||
			-- participants (Funding)
			'(select pp.project_id, array_to_string(array_agg(distinct o.name), '','') as funding_orgs from participation pp join organization o on pp.organization_id = o.organization_id ' ||
			'left join participation_taxonomy ppt on pp.participation_id = ppt.participation_id join classification c on ppt.classification_id = c.classification_id ' ||
			'where c.taxonomy_id = (select taxonomy_id from taxonomy where name = ''Organisation Role'') AND (c.name = ''Funding'') group by pp.project_id) pf on p.project_id = pf.project_id left join ' ||
			-- project taxonomy
			'(select pt.project_id, array_to_string(array_agg(distinct c.name), '','') as  c_name from project_taxonomy pt join classification c on pt.classification_id = c.classification_id ' ||
			'where c.taxonomy_id = ' || $1 || ' group by pt.project_id) as i on p.project_id = i.project_id	';

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
/******************************************************************
  pmt_project_listview_ct
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_project_listview_ct(classification_ids character varying, organization_ids character varying, unassigned_tax_ids character varying, start_date date, end_date date)
RETURNS INT AS 
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


    -- filter by classification ids
    IF ($1 is not null AND $1 <> '') THEN
      RAISE NOTICE '   + The classification filter is: %.', string_to_array($1, ',')::int[];

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
      RAISE NOTICE '   + The organization filter is: %.', string_to_array($2, ',')::int[];

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
      RAISE NOTICE '   + The include unassigned is: %.', string_to_array($3, ',')::int[];

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
   
    -- prepare statement																
    RAISE NOTICE '   + First where statement: %', array_to_string(dynamic_where1, ' AND ');
    RAISE NOTICE '   + Second where statement: %', dynamic_where2;

    -- prepare the statement for the record count (can be leaner for faster exectution)
    count_statement := 'SELECT COUNT(distinct p_id) FROM(SELECT DISTINCT filter.project_id AS p_id, filter.organization_id as o_id ' ||
			'FROM (SELECT t1.project_id, t1.organization_id FROM ' ||
			'(SELECT project_id, organization_id, start_date, end_date, array_agg(distinct taxonomy_id) as taxonomy_ids, array_agg(distinct classification_id) as classification_ids, array_agg(distinct organization_id) as organization_ids ' ||
			'FROM taxonomy_lookup GROUP BY project_id, organization_id, start_date, end_date ) as t1 ';			
   
    -- append where statements			
    IF dynamic_where1 IS NOT NULL THEN          
      IF dynamic_where2 IS NOT NULL THEN
        count_statement := count_statement || ' WHERE ' ||  array_to_string(dynamic_where1, ' AND ')  || ' OR ' || dynamic_where2;
      ELSE
        count_statement := count_statement || ' WHERE ' ||  array_to_string(dynamic_where1, ' AND ') || ' ';
      END IF;
    ELSE 
      IF dynamic_where2 IS NOT NULL THEN
        count_statement := count_statement || ' WHERE ' || dynamic_where2 || ' ';
      END IF;
    END IF;	

    count_statement := count_statement || ') as filter ) as count';	 
    
    -- get total record count
    EXECUTE count_statement INTO record_count;

    RETURN record_count;

END;$$ LANGUAGE plpgsql;
