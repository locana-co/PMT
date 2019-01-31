/******************************************************************
Change Script 2.0.6.6 - Consolidated

1. pmt_stat_counts - statistics function for project, activity, org 
& district counts.
2. pmt_stat_project_by_tax - statistics function for project counts
by taxonomy.
3. pmt_stat_activity_by_tax - statistics function for activity counts
by taxonomy.
4. pmt_stat_orgs_by_activity - statistics function for top ten implementing 
orgs by activity counts reporting by taxonomy.
******************************************************************/
UPDATE config SET changeset = 6, updated_date = current_date WHERE "version" = 2.0 AND iteration = 6;
-- SELECT pmt_version();
-- 
-- SELECT * FROM pmt_stat_counts('', '', '', null, null); -- 80(p) 6112 (a)
-- SELECT * FROM pmt_stat_counts('768', '', '', null, null); -- 72(p) 5656(a)
-- SELECT * FROM pmt_stat_project_by_tax(23, '768', '', '', null, null);-- 80 (this should come up with the same as pmt_stat_counts but there are some duplicate Initiative taxonomy assigments caused by Livestock reassignement from Focus Crop to Initiative
-- SELECT * FROM pmt_stat_activity_by_tax(17, '768', '', '17', null, null); -- 5656
-- SELECT * FROM pmt_stat_orgs_by_activity(23, '768', '', '', null, null); -- compared with pmt1.0.action_partner and got same results

/******************************************************************
  pmt_stat_counts
******************************************************************/
DROP FUNCTION IF EXISTS pmt_stat_counts(character varying, character varying, character varying, date, date) CASCADE;
DROP TYPE IF EXISTS pmt_stat_counts_result;
CREATE TYPE pmt_stat_counts_result AS (response json);
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

   -- number of projects
   execute_statement := 'SELECT count(DISTINCT project_id)::int ' ||
			'FROM( SELECT project_id, activity_id, array_agg(distinct taxonomy_id) as taxonomy_ids, array_agg(distinct classification_id) as classification_ids, ' || 
			'array_agg(distinct organization_id) as organization_ids FROM taxonomy_lookup GROUP BY project_id, activity_id) as filter ';
   IF where_statement IS NOT NULL THEN 	execute_statement := execute_statement || ' WHERE ' || where_statement;  END IF;
   EXECUTE execute_statement INTO num_projects;   
   
   -- number of activities
   execute_statement := 'SELECT count(DISTINCT activity_id)::int ' ||
			'FROM( SELECT project_id, activity_id, array_agg(distinct taxonomy_id) as taxonomy_ids, array_agg(distinct classification_id) as classification_ids, ' || 
			'array_agg(distinct organization_id) as organization_ids FROM taxonomy_lookup GROUP BY project_id, activity_id) as filter ';
   IF where_statement IS NOT NULL THEN 	execute_statement := execute_statement || ' WHERE ' || where_statement;  END IF;
   EXECUTE execute_statement INTO num_activities;
   
   -- number of orgs
   execute_statement := 'SELECT count(DISTINCT p.organization_id)::int ' ||
			'FROM participation p JOIN participation_taxonomy pt ON p.participation_id = pt.participation_id ' ||
			'JOIN (SELECT project_id, activity_id, array_agg(distinct taxonomy_id) as taxonomy_ids, array_agg(distinct classification_id) as classification_ids, ' ||
			'array_agg(distinct organization_id) as organization_ids FROM taxonomy_lookup GROUP BY project_id, activity_id) as filter ' ||
			'ON (p.project_id = filter.project_id and p.activity_id = filter.activity_id) OR (p.project_id = filter.project_id AND p.activity_id IS NULL) ' ||
			'WHERE pt.classification_id = (select classification_id from classification where taxonomy_id = (select taxonomy_id from taxonomy where name = ''Organisation Role'') AND iati_name = ''Implementing'') ';
   IF where_statement IS NOT NULL THEN 	execute_statement := execute_statement || ' AND ' || where_statement;  END IF;
   EXECUTE execute_statement INTO num_orgs;

   -- number of districts
   execute_statement := 'SELECT count(DISTINCT lbf.name)::int FROM (SELECT filter.location_id ' ||
			'FROM( SELECT location_id, array_agg(distinct taxonomy_id) as taxonomy_ids, array_agg(distinct classification_id) as classification_ids, ' || 
			'array_agg(distinct organization_id) as organization_ids FROM taxonomy_lookup GROUP BY location_id) as filter ';
   IF where_statement IS NOT NULL THEN 	execute_statement := execute_statement || ' WHERE ' || where_statement;  END IF;
   execute_statement := execute_statement || ') as l JOIN location_boundary_features lbf ON l.location_id = lbf.location_id ' ||
			'WHERE lbf.boundary_id = (SELECT boundary_id FROM boundary WHERE spatial_table = ''gaul2'')';
   EXECUTE execute_statement INTO num_districts;
   
   FOR rec IN EXECUTE 'select row_to_json(t) from (SELECT ' || 
   'coalesce('|| num_projects || ', 0) as p_ct, ' || 
   'coalesce('|| num_activities || ', 0) as a_ct, ' || 
   'coalesce('|| num_orgs || ', 0) as o_ct, ' || 
   'coalesce('|| num_districts || ', 0) as d_ct ' || 
   ') t;' LOOP
     RETURN NEXT rec; 
   END LOOP;
   	
END;$$ LANGUAGE plpgsql;
/******************************************************************
  pmt_stat_project_by_tax
******************************************************************/
DROP FUNCTION IF EXISTS pmt_stat_project_by_tax(integer, character varying, character varying, character varying, date, date) CASCADE;
DROP TYPE IF EXISTS pmt_stat_project_by_tax_result;
CREATE TYPE pmt_stat_project_by_tax_result AS (response json);
CREATE OR REPLACE FUNCTION pmt_stat_project_by_tax(tax_id integer, classification_ids character varying, organization_ids character varying, unassigned_tax_ids character varying, 
start_date date, end_date date)
RETURNS SETOF pmt_stat_project_by_tax_result AS 
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

   execute_statement :=  'select row_to_json(j) FROM (SELECT report_by.classification_id as c_id, count(DISTINCT a.project_id) as p_ct FROM ' ||
			 '(SELECT DISTINCT project_id FROM (SELECT project_id, activity_id, array_agg(distinct taxonomy_id) as taxonomy_ids, ' ||
			 'array_agg(distinct classification_id) as classification_ids, array_agg(distinct organization_id) as organization_ids ' ||
			 'FROM taxonomy_lookup GROUP BY project_id, activity_id) as filter ';
   IF where_statement IS NOT NULL THEN 	execute_statement := execute_statement || ' WHERE ' || where_statement;  END IF;
   execute_statement :=  execute_statement || ')as a LEFT JOIN (SELECT project_id,classification_id FROM taxonomy_lookup WHERE taxonomy_id = ' || $1 || ') as report_by ' ||
			 'ON a.project_id = report_by.project_id GROUP BY classification_id) as j';
   
 
   FOR rec IN EXECUTE execute_statement LOOP
     RETURN NEXT rec; 
   END LOOP;
   
END IF; -- must have valid taxonomy   	
END;$$ LANGUAGE plpgsql;
/******************************************************************
  pmt_stat_activity_by_tax
******************************************************************/
DROP FUNCTION IF EXISTS pmt_stat_activity_by_tax(integer, character varying, character varying, character varying, date, date) CASCADE;
DROP TYPE IF EXISTS pmt_stat_activity_by_tax_result;
CREATE TYPE pmt_stat_activity_by_tax_result AS (response json);
CREATE OR REPLACE FUNCTION pmt_stat_activity_by_tax(tax_id integer, classification_ids character varying, organization_ids character varying, unassigned_tax_ids character varying, 
start_date date, end_date date)
RETURNS SETOF pmt_stat_activity_by_tax_result AS 
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

   execute_statement :=  'select row_to_json(j) FROM (SELECT report_by.classification_id as c_id, count(DISTINCT a.activity_id) as a_ct FROM ' ||
			 '(SELECT DISTINCT activity_id FROM (SELECT project_id, activity_id, array_agg(distinct taxonomy_id) as taxonomy_ids, ' ||
			 'array_agg(distinct classification_id) as classification_ids, array_agg(distinct organization_id) as organization_ids ' ||
			 'FROM taxonomy_lookup GROUP BY project_id, activity_id) as filter ';
   IF where_statement IS NOT NULL THEN 	execute_statement := execute_statement || ' WHERE ' || where_statement;  END IF;
   execute_statement :=  execute_statement || ')as a LEFT JOIN (SELECT activity_id,classification_id FROM taxonomy_lookup WHERE taxonomy_id = ' || $1 || ') as report_by ' ||
			 'ON a.activity_id = report_by.activity_id GROUP BY classification_id) as j';
   
 
   FOR rec IN EXECUTE execute_statement LOOP
     RETURN NEXT rec; 
   END LOOP;
   
END IF; -- must have valid taxonomy   	
END;$$ LANGUAGE plpgsql;
/******************************************************************
  pmt_stat_orgs_by_activity
******************************************************************/
DROP FUNCTION IF EXISTS pmt_stat_orgs_by_activity(integer, character varying, character varying, character varying, date, date) CASCADE;
DROP TYPE IF EXISTS pmt_stat_orgs_by_activity_result;
CREATE TYPE pmt_stat_orgs_by_activity_result AS (response json);
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

   execute_statement :=  'SELECT row_to_json(j) FROM (SELECT p.organization_id as o_id,  count(DISTINCT filter.activity_id) as a_ct ' ||
			',(SELECT array_to_json(array_agg(row_to_json(b))) FROM (SELECT classification_id as c_id, count(distinct activity_id) AS a_ct ' ||
			'FROM taxonomy_lookup WHERE taxonomy_id = ' || $1 || ' AND organization_id = p.organization_id GROUP BY classification_id ) b ) as a_by_tax ' ||
			'FROM participation p JOIN participation_taxonomy pt ON p.participation_id = pt.participation_id ' ||
			'JOIN (SELECT project_id, activity_id, array_agg(distinct taxonomy_id) as taxonomy_ids, array_agg(distinct classification_id) as classification_ids, ' ||
			'array_agg(distinct organization_id) as organization_ids FROM taxonomy_lookup GROUP BY project_id, activity_id) as filter ' ||
			'ON (p.project_id = filter.project_id and p.activity_id = filter.activity_id) OR (p.project_id = filter.project_id AND p.activity_id IS NULL) ' ||
			'WHERE pt.classification_id = (select classification_id from classification where taxonomy_id = (select taxonomy_id from taxonomy where name = ''Organisation Role'') AND iati_name = ''Implementing'') ';
   IF where_statement IS NOT NULL THEN 	execute_statement := execute_statement || ' AND ' || where_statement;  END IF;			
   execute_statement :=  execute_statement || 'GROUP BY p.organization_id ORDER BY a_ct desc LIMIT 10) as j';
 
   FOR rec IN EXECUTE execute_statement LOOP
     RETURN NEXT rec; 
   END LOOP;
   
END IF; -- must have valid taxonomy   	
END;$$ LANGUAGE plpgsql;