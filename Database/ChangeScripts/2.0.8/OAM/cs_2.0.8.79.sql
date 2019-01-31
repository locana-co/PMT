/******************************************************************
Change Script 2.0.8.79
1. pmt_locations_by_tax - remove automatic category lookup
******************************************************************/
INSERT INTO version(version, iteration, changeset) VALUES (2.0, 8, 79);
-- select * from version order by changeset desc;

-- select * from pmt_locations_by_tax(14, '800', '223');
-- select * from pmt_locations_by_tax(23, '768,769', '55');

DROP FUNCTION IF EXISTS pmt_locations_by_tax(Integer, character varying, character varying) CASCADE;
DROP TYPE IF EXISTS pmt_locations_by_tax_dd_result_type CASCADE;

CREATE TYPE pmt_locations_by_tax_dd_result_type AS  (l_id integer, x integer, y integer, lat numeric, lng numeric, r_ids text);

CREATE OR REPLACE FUNCTION pmt_locations_by_tax(tax_id Integer, data_group character varying, country_ids character varying) RETURNS SETOF pmt_locations_by_tax_dd_result_type AS 
$$
DECLARE
  valid_data_group_ids int[];
  dg_id integer;
  valid_country_ids int[];
  valid_classification_ids int[];
  valid_taxonomy_id boolean;
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
     --  -- yes, this is a category taxonomy
--       IF report_by_category THEN
--         -- what are the root taxonomy(ies) of the category taxonomy
--         SELECT INTO report_taxonomy_id * FROM pmt_category_root(report_taxonomy_id, data_group);
--         -- there are root taxonomy(ies)
--         IF report_taxonomy_id IS NOT NULL THEN
--            -- RAISE NOTICE 'report_taxonomy_id: %', report_taxonomy_id;
--         ELSE
--           report_taxonomy_id := $1;
--           report_by_category := false;
--         END IF;
--       END IF;      
    END IF;	
  END IF;

    -- validate and process country_ids parameter
  IF $3 IS NOT NULL OR $3 <> '' THEN
    SELECT INTO valid_classification_ids * FROM pmt_validate_classifications($3);
    RAISE NOTICE 'valid classification ids: %', valid_classification_ids;
  END IF;
    
  -- validate and process data_group parameter
  IF $2 IS NOT NULL OR $2 <> '' THEN
    -- validate the classification id
    SELECT INTO valid_data_group_ids * FROM pmt_validate_classifications($2);

    IF valid_data_group_ids IS NOT NULL THEN
      IF valid_classification_ids IS NOT NULL THEN
        FOREACH dg_id IN ARRAY valid_data_group_ids LOOP
          valid_classification_ids := array_append(valid_classification_ids, dg_id);
        END LOOP;
      ELSE
        valid_classification_ids := valid_data_group_ids;
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
  execute_statement := 'SELECT t2.location_id as l_id, t2.x, t2.y, t2.lat_dd, t2.long_dd, array_to_string(array_agg(DISTINCT report_by.classification_id), '','') as c_ids ' ||
				'FROM( ' ||
				'SELECT DISTINCT ll.location_id, ll.x, ll.y, l.lat_dd, l.long_dd, ll.georef, ll.classification_ids FROM location_lookup ll ' ||
				'JOIN location l ON ll.location_id = l.location_id ';
				
  IF dynamic_where2 IS NOT NULL THEN          
    execute_statement := execute_statement || ' WHERE ' ||  array_to_string(dynamic_where2, ' AND ');
  END IF;

  IF report_taxonomy_id IS NULL THEN report_taxonomy_id := 1; END IF;
  
  execute_statement := execute_statement || ') as t2 ' ||
				'LEFT JOIN ' ||
				'(SELECT distinct location_id, classification_id FROM taxonomy_lookup  ' ||
				'WHERE taxonomy_lookup.taxonomy_id = ' || report_taxonomy_id || ') AS report_by  ' ||
				'ON t2.location_id = report_by.location_id ' ||
				'GROUP BY t2.location_id, t2.x, t2.y, t2.lat_dd, t2.long_dd, t2.georef ' ||	
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


CREATE OR REPLACE FUNCTION pmt_locations_by_tax(tax_id integer, data_group integer, country_ids character varying)
  RETURNS SETOF pmt_locations_by_tax_result_type AS
$BODY$
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
      -- SELECT INTO report_by_category is_category FROM taxonomy WHERE taxonomy_id = (report_taxonomy_id);      
--       -- yes, this is a category taxonomy
--       IF report_by_category THEN
--         -- what are the root taxonomy(ies) of the category taxonomy
--         SELECT INTO report_taxonomy_id * FROM pmt_category_root(report_taxonomy_id, data_group);
--         -- there are root taxonomy(ies)
--         IF report_taxonomy_id IS NOT NULL THEN
--            -- RAISE NOTICE 'report_taxonomy_id: %', report_taxonomy_id;
--         ELSE
--           report_taxonomy_id := $1;
--           report_by_category := false;
--         END IF;
--       END IF;      
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
  
END;$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100
  ROWS 1000;
ALTER FUNCTION pmt_locations_by_tax(integer, integer, character varying)
  OWNER TO postgres;
GRANT EXECUTE ON FUNCTION pmt_locations_by_tax(integer, integer, character varying) TO postgres;
GRANT EXECUTE ON FUNCTION pmt_locations_by_tax(integer, integer, character varying) TO public;
GRANT EXECUTE ON FUNCTION pmt_locations_by_tax(integer, integer, character varying) TO pmt_read;
GRANT EXECUTE ON FUNCTION pmt_locations_by_tax(integer, integer, character varying) TO pmt_write;


-- update permissions
GRANT USAGE ON SCHEMA public TO pmt_read;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO pmt_read;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO pmt_read;
GRANT USAGE ON SCHEMA public TO pmt_write;
GRANT SELECT,INSERT ON ALL TABLES IN SCHEMA public TO pmt_write;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO pmt_write;