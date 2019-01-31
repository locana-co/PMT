/******************************************************************
Change Script 2.0.6.12 - Consolidated

1. pmt_stat_locations - statistics function for returning lat/long
for locations.
******************************************************************/
UPDATE config SET changeset = 12, updated_date = current_date WHERE "version" = 2.0 AND iteration = 6;
-- SELECT pmt_version();
-- 
-- SELECT * FROM pmt_stat_locations('', '', '', null, null); -- 80(p) 6112 (a)
-- SELECT * FROM pmt_stat_locations((select array_to_string(array_agg(classification_id), ',') from taxonomy_classifications 
--     where taxonomy = 'Country' and upper(classification) = 
--     ANY(ARRAY['BURKINA FASO', 'ETHIOPIA', 'GHANA','INDIA','MALI','NIGERIA','UGANDA','TANZANIA, UNITED REPUBLIC OF'])), '', '', null, null);
/******************************************************************
  pmt_stat_locations
******************************************************************/
DROP FUNCTION IF EXISTS pmt_stat_locations(character varying, character varying, character varying, date, date) CASCADE;
DROP TYPE IF EXISTS pmt_stat_locations_result;
CREATE TYPE pmt_stat_locations_result AS (response json);

CREATE OR REPLACE FUNCTION pmt_stat_locations(classification_ids character varying, organization_ids character varying, unassigned_tax_ids character varying, 
start_date date, end_date date)
RETURNS SETOF pmt_stat_locations_result AS 
$$
DECLARE
  rec record;
  filter_classids integer array;
  filter_orgids integer array;
  include_taxids integer array;
  dynamic_where1 text array;
  dynamic_where2 text;
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
	dynamic_where1 := array_append(dynamic_where1, '(' || array_to_string(built_where, ' OR ') || ')');
	
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

   -- locations
   execute_statement := 'select row_to_json(t) from (SELECT filter.location_id as l_id, l.lat_dd, l.long_dd FROM ' ||
			'(SELECT location_id FROM location_lookup ';
			
   IF where_statement IS NOT NULL THEN 	execute_statement := execute_statement || ' WHERE ' || where_statement;  END IF;
   
   execute_statement := execute_statement || ') as filter JOIN location l ON filter.location_id = l.location_id) as t';
   
   
   FOR rec IN EXECUTE execute_statement LOOP
     RETURN NEXT rec; 
   END LOOP;
   	
END;$$ LANGUAGE plpgsql;