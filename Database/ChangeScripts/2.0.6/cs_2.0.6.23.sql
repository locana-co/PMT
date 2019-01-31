/******************************************************************
Change Script 2.0.6.23 - Consolidated.
1. pmt_stat_orgs_by_activity - changed organization role to Accountable,
from Implementing.
******************************************************************/
INSERT INTO config(version, iteration, changeset) VALUES (2.0, 6, 23);
-- select * from config;
-- SELECT * FROM pmt_stat_orgs_by_activity(1, '768', '', '', null, null); 

/******************************************************************
  pmt_stat_orgs_by_activity
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_stat_orgs_by_activity(tax_id integer, classification_ids character varying, organization_ids character varying, unassigned_tax_ids character varying, 
start_date date, end_date date)
RETURNS SETOF pmt_stat_orgs_by_activity_result AS 
$$
DECLARE
  rec record;
  valid_taxonomy_id boolean;
  filter_classids integer array;
  filter_orgids integer array;
  include_taxids integer array;
  dynamic_where1 text array;
  dynamic_where2 text;
  built_where text array;
  where_statement text;
  execute_statement text;
  i integer;
BEGIN
-- validate and process taxonomy_id parameter
SELECT INTO valid_taxonomy_id * FROM pmt_validate_taxonomy($1); 

-- Must have taxonomy_id parameter to continue
IF NOT valid_taxonomy_id THEN
   RAISE NOTICE '   + A taxonomy is required.';
ELSE
   -- filter by classification ids
   IF ($2 is not null AND $2 <> '') THEN

      -- Create an int array from classification ids list
	filter_classids := string_to_array($2, ',')::int[];

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
	END LOOP;			
   END IF;
   
   -- filter by organization ids
   IF ($3 is not null AND $3 <> '') THEN

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
   -- include unassigned taxonomy ids
   IF ($4 is not null AND $4 <> '') THEN
   
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
	dynamic_where1 := array_append(dynamic_where1, '(start_date > ''' || $5 || ''' AND end_date < ''' || $6 || ''')');
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

   execute_statement :=  'SELECT row_to_json(j) FROM ( SELECT top.o_id, o.name, top.a_ct, top.a_by_tax FROM( SELECT lu.organization_id as o_id,  count(DISTINCT lu.activity_id) as a_ct ' ||
			',(SELECT array_to_json(array_agg(row_to_json(b))) FROM (SELECT classification_id as c_id, count(distinct activity_id) AS a_ct ' ||
			'FROM taxonomy_lookup WHERE taxonomy_id = ' || $1 || ' AND organization_id = lu.organization_id GROUP BY classification_id ) b ) as a_by_tax ' ||
			'FROM organization_lookup lu ' ||
			'WHERE (classification_ids @> ARRAY[(select classification_id from classification where taxonomy_id = (select taxonomy_id from taxonomy where name = ''Organisation Role'') AND iati_name = ''Accountable'')]) ';
   IF where_statement IS NOT NULL THEN 	execute_statement := execute_statement || ' AND ' || where_statement;  END IF;			
   execute_statement :=  execute_statement || 'GROUP BY lu.organization_id ORDER BY a_ct desc LIMIT 10 ) as top JOIN organization o ON top.o_id = o.organization_id ) as j';

   RAISE NOTICE 'Execute statement: %', execute_statement;
   FOR rec IN EXECUTE execute_statement LOOP
     RETURN NEXT rec; 
   END LOOP;
   
END IF; -- must have valid taxonomy   	
END;$$ LANGUAGE plpgsql;