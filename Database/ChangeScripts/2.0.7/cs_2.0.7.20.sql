/******************************************************************
Change Script 2.0.7.20 - Consolidated.
1. pmt_activity_listview - bug fix to remove duplications. adding
object for multiple taxonomy and organizations
******************************************************************/
INSERT INTO config(version, iteration, changeset) VALUES (2.0, 7, 20);
-- select * from config order by changeset desc;
-- select * from  pmt_activity_listview('769,662', '', '15', null,null, 'a_id', null, null); 
-- select * from  pmt_activity_listview('769,665,662', '', '', '1-1-1990','12-31-2014', 'a_id', 10, 100);
-- select * from  pmt_activity_listview('769,496,665,662', '68', '15','1-1-2000', '12-31-2014', 'a_id', null, null); 
-- select * from  pmt_activity_listview_ct('769,496,665,662', '68', '15','1-1-2000', '12-31-2014'); 
-- select * from  pmt_activity_listview('769', '', '', null, null, '', null, null); 
-- select * from  pmt_activity_listview_ct('768', '', '',null,null); 

-- drop statements (old)
DROP FUNCTION IF EXISTS pmt_activity_listview(integer, character varying, character varying, character varying, date, date, text, integer, integer) CASCADE;
-- drop statements (new)
DROP FUNCTION IF EXISTS pmt_activity_listview(character varying, character varying, character varying, date, date, text, integer, integer) CASCADE;

-- pmt_activity_listview
CREATE OR REPLACE FUNCTION pmt_activity_listview(classification_ids character varying, organization_ids character varying, unassigned_tax_ids character varying, 
start_date date, end_date date, orderby text, limit_rec integer, offset_rec integer)
RETURNS SETOF pmt_activity_listview_result AS 
$$
DECLARE  
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
    
    -- create dynamic paging statment
    IF $6 IS NOT NULL AND $6 <> '' THEN
      IF paging_statement IS NOT NULL THEN
        paging_statement := paging_statement || 'ORDER BY ' || $6 || ' ';
      ELSE
        paging_statement := ' ORDER BY ' || $6 || ' ';
      END IF;
    END IF;		    
    IF $7 IS NOT NULL AND $7 > 0 THEN
      IF paging_statement IS NOT NULL THEN
        paging_statement := paging_statement || 'LIMIT ' || $7 || ' ';
      ELSE
        paging_statement := ' LIMIT ' || $7 || ' ';
      END IF;
    END IF;		
    IF $8 IS NOT NULL AND $8 > 0 THEN
      IF paging_statement IS NOT NULL THEN
        paging_statement := paging_statement || 'OFFSET ' || $8 || ' ';
      ELSE
        paging_statement := ' OFFSET ' || $8 || ' ';
      END IF;      
    END IF;		

    -- prepare statement																
    RAISE NOTICE '   + First where statement: %', array_to_string(dynamic_where1, ' AND ');
    RAISE NOTICE '   + Second where statement: %', dynamic_where2;
    RAISE NOTICE '   + The paging statement: %', paging_statement;
		
    -- prepare statement for the selection
    execute_statement := 'SELECT filter.activity_id AS a_id, filter.title AS a_name, filter.description AS a_desc, filter.start_date as a_date1, f.amount, l.gaul ' ||
			-- organizations
			',(SELECT array_to_json(array_agg(row_to_json(o))) FROM (SELECT ot.organization_id as o_id, o.name, classification as c ' ||
			'FROM organization_lookup ot JOIN taxonomy_classifications tc ON tc.classification_id = ANY(ot.classification_ids) ' ||
			'JOIN organization o ON ot.organization_id = o.organization_id WHERE taxonomy = ''Organisation Role'' AND ot.activity_id = filter.activity_id ) as o ) orgs ' ||
			-- taxonomy
			',(SELECT array_to_json(array_agg(row_to_json(z))) FROM (SELECT DISTINCT taxonomy as t, classification as c ' ||
			'FROM organization_lookup ot JOIN taxonomy_classifications tc ON tc.classification_id = ANY(ot.classification_ids) ' ||
			'WHERE taxonomy <> ''Organisation Role'' AND ot.activity_id = filter.activity_id ) as z) taxonomy ' ||
			-- filter
			'FROM ( SELECT DISTINCT t1.activity_id, a.title, a.description, a.start_date FROM  ' ||			
			'(SELECT * FROM organization_lookup ) as t1 ' ||
			-- activity
			'JOIN (SELECT activity_id, title, description, start_date, end_date from activity) as a ' ||
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

    execute_statement := execute_statement || ') as filter LEFT JOIN (SELECT activity_id, array_to_string(array_agg(gaul0_name || '', '' || gaul1_name), ''; '') as gaul FROM location_lookup GROUP BY activity_id) as l ' ||
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

END;$$ LANGUAGE plpgsql;

-- update permissions
GRANT USAGE ON SCHEMA public TO pmt_read;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO pmt_read;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO pmt_read;
GRANT USAGE ON SCHEMA public TO pmt_write;
GRANT SELECT,INSERT ON ALL TABLES IN SCHEMA public TO pmt_write;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO pmt_write;