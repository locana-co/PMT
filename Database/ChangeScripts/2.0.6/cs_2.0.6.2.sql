/******************************************************************
Change Script 2.0.6.2 - Consolidated

1. pmt_locations_by_org - performance improvement.
2. pmt_locations_by_tax - performance improvement.
******************************************************************/
UPDATE config SET changeset = 2, updated_date = current_date WHERE "version" = 2.0 AND iteration = 6;
-- SELECT pmt_version();

DROP FUNCTION IF EXISTS pmt_locations_by_org(integer,integer,character varying) CASCADE;
DROP FUNCTION IF EXISTS pmt_locations_by_tax(integer, integer,character varying) CASCADE;

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
  execute_statement := 'SELECT t1.location_id, t1.x, t1.y, array_to_string(organization_ids, '','')::text AS o_ids  FROM ' ||
				'(SELECT DISTINCT location_id, x, y, georef, array_agg(distinct classification_id) as classification_ids, array_agg(distinct organization_id) as organization_ids ' ||
				'FROM taxonomy_lookup GROUP BY location_id, x, y, georef) AS t1 ';
				
  IF dynamic_where2 IS NOT NULL THEN          
    execute_statement := execute_statement || ' WHERE ' ||  array_to_string(dynamic_where2, ' AND ');
  END IF;

  execute_statement := execute_statement || ' ' ||				
				--'GROUP BY t1.location_id,t1.x, t1.y ' ||	
				'ORDER BY t1.georef ';  
				   
  -- execute statement
  RAISE NOTICE 'Where statement: %', dynamic_where2;
  RAISE NOTICE 'Execute statement: %', execute_statement;
  FOR rec IN EXECUTE execute_statement	    
  LOOP
    RETURN NEXT rec;    
  END LOOP;
  
END;$$ LANGUAGE plpgsql;
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
				'SELECT DISTINCT t1.location_id, t1.x, t1.y, t1.georef, t1.classification_ids FROM ' ||
				'(SELECT DISTINCT location_id, x, y, georef, start_date, end_date, array_agg(distinct taxonomy_id) as taxonomy_ids, array_agg(distinct classification_id) as classification_ids, array_agg(distinct organization_id) as organization_ids ' ||
				'FROM taxonomy_lookup GROUP BY location_id, x, y, georef, start_date, end_date ' ||
				') AS t1 ';
				
  IF dynamic_where2 IS NOT NULL THEN          
    execute_statement := execute_statement || ' WHERE ' ||  array_to_string(dynamic_where2, ' AND ');
  END IF;

  execute_statement := execute_statement || ') as t2 ' ||
				'LEFT JOIN ' ||
				'(SELECT * FROM taxonomy_lookup  ' ||
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
