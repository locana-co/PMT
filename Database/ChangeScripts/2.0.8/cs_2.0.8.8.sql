/******************************************************************
Change Script 2.0.8.8 - consolidated.
1. pmt_locations_by_org -  bug fix when sending a class_id parameter,
was not filtering organizations correctly.
******************************************************************/
INSERT INTO version(version, iteration, changeset) VALUES (2.0, 8, 8);
-- select * from version order by changeset desc;

-- select * from pmt_locations_by_org(496, 773, '179')
-- select * from pmt_locations_by_org(496, 769, '')
-- select * from pmt_locations_by_org(496, 810, '179') -- funding, world bank, nepal
-- select * from pmt_locations_by_org(496, 773, '179')
-- select * from pmt_locations_by_org(null,null, '') -- bolivia, bolivia

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
  execute_statement := 'SELECT ll.location_id, x, y, array_to_string(array_agg(ol.organization_id), '','') AS o_ids FROM location_lookup ll ' ||
		'JOIN (select distinct unnest(location_ids) as location_id, organization_id FROM organization_lookup';
				
  IF dynamic_where2 IS NOT NULL THEN          
    execute_statement := execute_statement || ' WHERE ' ||  array_to_string(dynamic_where2, ' AND ');
  END IF;

  execute_statement := execute_statement || ') as ol ON ll.location_id = ol.location_id GROUP BY ll.location_id, x, y, georef ORDER BY georef ';  
				   
  -- execute statement
  RAISE NOTICE 'Where statement: %', dynamic_where2;
  RAISE NOTICE 'Execute statement: %', execute_statement;
  FOR rec IN EXECUTE execute_statement	    
  LOOP
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