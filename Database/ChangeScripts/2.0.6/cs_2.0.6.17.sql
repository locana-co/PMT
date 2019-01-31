/******************************************************************
Change Script 2.0.6.17 - Consolidated

1. pmt_activity_listview - adding gual0 & 1 names and financials. 
******************************************************************/
UPDATE config SET changeset = 17, updated_date = current_date WHERE "version" = 2.0 AND iteration = 6;
-- SELECT pmt_version();

-- select * from  pmt_activity_listview(15, '771,496', '', '','a_name', 50, 0);

-- location_lookup
ALTER TABLE "location_lookup" ADD COLUMN "gaul0_name" character varying;
ALTER TABLE "location_lookup" ADD COLUMN "gaul1_name" character varying;
ALTER TABLE "location_lookup" ADD COLUMN "gaul2_name" character varying;

-- update lookup
UPDATE location_lookup SET gaul0_name = lbf.name FROM location_boundary_features lbf WHERE location_lookup.location_id = lbf.location_id AND lbf.boundary_id = 1;
UPDATE location_lookup SET gaul1_name = lbf.name FROM location_boundary_features lbf WHERE location_lookup.location_id = lbf.location_id AND lbf.boundary_id = 2;
UPDATE location_lookup SET gaul2_name = lbf.name FROM location_boundary_features lbf WHERE location_lookup.location_id = lbf.location_id AND lbf.boundary_id = 3;

-- function to support the taxonomy_lookup table
CREATE OR REPLACE FUNCTION refresh_taxonomy_lookup() RETURNS integer AS $$
BEGIN
    RAISE NOTICE 'Refreshing taxonomy_lookup...';

        EXECUTE 'TRUNCATE TABLE taxonomy_lookup';
        EXECUTE 'INSERT INTO taxonomy_lookup(project_id, activity_id, location_id, organization_id, participation_id, start_date, end_date, x, y, georef, taxonomy_id, classification_id) '
                || 'SELECT project_id, activity_id, location_id, organization_id, participation_id, activity_start, activity_end, x, y, georef, t.taxonomy_id, foo.classification_id ' 
		|| 'FROM(SELECT pa.project_id, pa.activity_id, pa.location_id, pa.organization_id, pa.participation_id, pa.activity_start, pa.activity_end, pa.x, pa.y, pa.georef, et.classification_id '
		|| 'FROM active_project_activities pa '
		|| 'JOIN entity_taxonomy et '
		|| 'ON pa.project_id = et.id AND field = ''project_id'' '
		|| 'UNION '
		|| 'SELECT pa.project_id, pa.activity_id, pa.location_id, pa.organization_id, pa.participation_id, pa.activity_start, pa.activity_end, pa.x, pa.y, pa.georef, et.classification_id '
		|| 'FROM active_project_activities pa '
		|| 'JOIN entity_taxonomy et '
		|| 'ON pa.activity_id = et.id AND field = ''activity_id'' '
		|| 'UNION '
		|| 'SELECT pa.project_id, pa.activity_id, pa.location_id, pa.organization_id, pa.participation_id, pa.activity_start, pa.activity_end, pa.x, pa.y, pa.georef, et.classification_id '
		|| 'FROM active_project_activities pa '
		|| 'JOIN entity_taxonomy et '
		|| 'ON pa.location_id = et.id AND field = ''location_id'' '
		|| 'UNION '
		|| 'SELECT pa.project_id, pa.activity_id, pa.location_id, pa.organization_id, pa.participation_id, pa.activity_start, pa.activity_end, pa.x, pa.y, pa.georef, et.classification_id ' 
		|| 'FROM active_project_activities pa '
		|| 'JOIN entity_taxonomy et '
		|| 'ON pa.organization_id = et.id AND field = ''organization_id'' '
		|| 'UNION '
		|| 'SELECT pa.project_id, pa.activity_id, pa.location_id, pa.organization_id, pa.participation_id, pa.activity_start, pa.activity_end, pa.x, pa.y, pa.georef, et.classification_id '
		|| 'FROM active_project_activities pa '
		|| 'JOIN entity_taxonomy et '
		|| 'ON pa.participation_id = et.id AND field = ''participation_id'' '
		|| ') as foo '
		|| 'JOIN classification c '
		|| 'ON foo.classification_id = c.classification_id '
		|| 'JOIN taxonomy t '
		|| 'ON c.taxonomy_id = t.taxonomy_id ';

    	EXECUTE 'TRUNCATE TABLE location_lookup';	

    	EXECUTE 'INSERT INTO location_lookup(project_id, activity_id, location_id, start_date, end_date, x, y, georef, taxonomy_ids, classification_ids, organization_ids) ' ||
		'SELECT project_id, activity_id, location_id, start_date, end_date, x, y, georef, array_agg(distinct taxonomy_id) as taxonomy_ids, array_agg(distinct classification_id) as classification_ids, array_agg(distinct organization_id) as organization_ids ' ||
		'FROM taxonomy_lookup ' ||
		'GROUP BY project_id, activity_id, location_id, start_date, end_date, x, y, georef';
		
	EXECUTE 'UPDATE location_lookup SET gaul0_name = lbf.name FROM location_boundary_features lbf WHERE location_lookup.location_id = lbf.location_id AND lbf.boundary_id = 1;';
	EXECUTE 'UPDATE location_lookup SET gaul1_name = lbf.name FROM location_boundary_features lbf WHERE location_lookup.location_id = lbf.location_id AND lbf.boundary_id = 2;';
	EXECUTE 'UPDATE location_lookup SET gaul2_name = lbf.name FROM location_boundary_features lbf WHERE location_lookup.location_id = lbf.location_id AND lbf.boundary_id = 3;';

	EXECUTE 'TRUNCATE TABLE organization_lookup';

	EXECUTE 'INSERT INTO organization_lookup(project_id, activity_id, organization_id, taxonomy_ids,classification_ids,location_ids) ' ||
		'SELECT project_id, activity_id, organization_id, array_agg(distinct taxonomy_id) as taxonomy_ids, array_agg(distinct classification_id) as classification_ids, array_agg(distinct location_id) as location_ids ' ||
		'FROM taxonomy_lookup  ' ||
		'GROUP BY project_id, activity_id, organization_id';

	
    RAISE NOTICE 'Done refreshing taxonomy_lookup.';
    RETURN 1;
END;
$$ LANGUAGE plpgsql;

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
    execute_statement := 'SELECT filter.activity_id AS a_id, filter.title AS a_name, filter.description AS a_desc, filter.start_date as a_date1, f.amount, filter.name as o_name, l.gaul, report_by.name as r_name   ' ||
			'FROM ( SELECT t1.activity_id, a.title, a.description, a.start_date, t1.organization_id, o.name FROM  ' ||
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

    execute_statement := execute_statement || 'LEFT JOIN (SELECT activity_id, array_to_string(array_agg(gaul0_name || '', '' || gaul1_name), ''; '') as gaul FROM location_lookup GROUP BY activity_id) as l ' ||
			'ON filter.activity_id = l.activity_id ' ||
			'LEFT JOIN (SELECT activity_id, sum(amount) as amount FROM financial GROUP BY activity_id) as f ' ||
			'ON filter.activity_id = f.activity_id'; 			
    
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
