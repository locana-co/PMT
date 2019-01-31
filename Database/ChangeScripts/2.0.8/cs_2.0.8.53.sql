/******************************************************************
Change Script 2.0.8.53 - consolidated.
1. pmt_activity_listview - alter lookup for organization role to 
iati_name field to support custom naming of the iati codelist.
******************************************************************/
INSERT INTO version(version, iteration, changeset) VALUES (2.0, 8, 53);
-- select * from version order by changeset desc;

-- SELECT * FROM pmt_activity_listview('824','',null, null, null, '7','a_name asc', 100, 0)

/******************************************************************
  pmt_activity_listview
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_activity_listview(classification_ids character varying, organization_ids character varying, unassigned_tax_ids character varying, 
start_date date, end_date date, report_taxonomy_ids character varying, orderby text, limit_rec integer, offset_rec integer) RETURNS SETOF pmt_json_result_type AS $$
DECLARE  
  filter_classids integer array;
  filter_orgids integer array;
  include_taxids integer array;  
  reporting_taxids integer array;
  rec record;  
  dynamic_where1 text array;
  dynamic_where2 text;
  dynamic_join text;
  dynamic_select text;
  join_ct integer;
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
		built_where :=  array_append(built_where, 't1.organization_id = '|| i );
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
	dynamic_where1 := array_append(dynamic_where1, '(t1.start_date > ''' || $4 || ''' AND t1.end_date < ''' || $5 || ''')');
    END IF;	

    -- -- report by taxonomy(ies)
    IF $6 IS NOT NULL AND $6 <> '' THEN      
      -- validate taxonomy ids
      SELECT INTO reporting_taxids * FROM pmt_validate_taxonomies($6);

      join_ct := 1;

      IF reporting_taxids IS NOT NULL THEN
        -- Loop through the reporting taxonomy_ids and construct the join statements      
        FOREACH i IN ARRAY reporting_taxids LOOP
          -- prepare join statements
	  IF dynamic_join IS NOT NULL THEN
            dynamic_join := dynamic_join || ' LEFT JOIN (SELECT  ot.activity_id, array_to_string(array_agg(DISTINCT tc.classification), '','') as classes ' ||
					'FROM organization_lookup ot  JOIN taxonomy_classifications tc ON tc.classification_id = ANY(ot.classification_ids) ' ||
					'WHERE taxonomy_id = ' || i || ' GROUP BY ot.activity_id ) tax' || join_ct || ' ON tax' || join_ct || '.activity_id = filter.activity_id';
          ELSE
            dynamic_join := ' LEFT JOIN (SELECT  ot.activity_id, array_to_string(array_agg(DISTINCT tc.classification), '','') as classes ' ||
					'FROM organization_lookup ot  JOIN taxonomy_classifications tc ON tc.classification_id = ANY(ot.classification_ids) ' ||
					'WHERE taxonomy_id = ' || i || ' GROUP BY ot.activity_id ) tax' || join_ct || ' ON tax' || join_ct || '.activity_id = filter.activity_id';
          END IF;
          -- prepare select statements
          IF dynamic_select IS NOT NULL THEN
            dynamic_select := dynamic_select || ', tax' || join_ct || '.classes as tax' || join_ct || ' ';
          ELSE
            dynamic_select := ', tax' || join_ct || '.classes as tax' || join_ct || ' ';
          END IF;
          join_ct := join_ct + 1;
        END LOOP;			
      END IF;
    END IF;
    
    -- create dynamic paging statment
    IF $7 IS NOT NULL AND $7 <> '' THEN      
      IF paging_statement IS NOT NULL THEN
        paging_statement := paging_statement || 'ORDER BY ' || $7 || ' ';
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
    RAISE NOTICE '   + First where statement: %', array_to_string(dynamic_where1, ' AND ');
    RAISE NOTICE '   + Second where statement: %', dynamic_where2;
    RAISE NOTICE '   + The join statement: %', dynamic_join;
    RAISE NOTICE '   + The select statement: %', dynamic_select;
    RAISE NOTICE '   + The paging statement: %', paging_statement;
		
    -- prepare statement for the selection
    execute_statement := 'SELECT filter.activity_id AS a_id, filter.title AS a_name, f_orgs.orgs as f_orgs, i_orgs.orgs as i_orgs ';

    IF dynamic_select IS NOT NULL THEN
      execute_statement := execute_statement || dynamic_select;
    END IF;

    execute_statement := execute_statement ||			
			-- filter
			'FROM ( SELECT DISTINCT t1.activity_id, a.title FROM  ' ||			
			'(SELECT * FROM organization_lookup ) as t1 ' ||
				-- activity
			'JOIN (SELECT activity_id, title from activity) as a ' ||
			'ON t1.activity_id = a.activity_id ';			
			
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

    execute_statement := execute_statement || ') as filter ' ||
			-- organiztions (funding)
			'LEFT JOIN (SELECT ot.activity_id, array_to_string(array_agg(DISTINCT o.name), '','') as orgs ' ||
			'FROM organization_lookup ot JOIN taxonomy_classifications tc ON tc.classification_id = ANY(ot.classification_ids) ' ||
			'JOIN organization o ON ot.organization_id = o.organization_id WHERE iati_codelist = ''Organisation Role'' AND iati_name = ''Funding'' ' ||
			'GROUP BY ot.activity_id ) f_orgs ON f_orgs.activity_id = filter.activity_id ' ||
			-- organiztions (implementing); 	
			'LEFT JOIN (SELECT ot.activity_id, array_to_string(array_agg(DISTINCT o.name), '','') as orgs ' ||
			'FROM organization_lookup ot JOIN taxonomy_classifications tc ON tc.classification_id = ANY(ot.classification_ids) ' ||
			'JOIN organization o ON ot.organization_id = o.organization_id WHERE iati_codelist = ''Organisation Role'' AND iati_name = ''Implementing'' '||
			'GROUP BY ot.activity_id) i_orgs ON i_orgs.activity_id = filter.activity_id ';
    		
     IF dynamic_join IS NOT NULL THEN
      execute_statement := execute_statement || dynamic_join;
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

END;$$ LANGUAGE plpgsql;

-- update permissions
GRANT USAGE ON SCHEMA public TO pmt_read;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO pmt_read;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO pmt_read;
GRANT USAGE ON SCHEMA public TO pmt_write;
GRANT SELECT,INSERT ON ALL TABLES IN SCHEMA public TO pmt_write;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO pmt_write;