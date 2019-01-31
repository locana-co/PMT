/******************************************************************
Change Script 2.0.7.21 - Consolidated.
1. pmt_org_inuse - bug fix.
******************************************************************/
INSERT INTO config(version, iteration, changeset) VALUES (2.0, 7, 21);
-- select * from config order by changeset desc;

-- select * from pmt_data_groups();
-- select * from pmt_org_inuse('768,496');

CREATE OR REPLACE FUNCTION pmt_org_inuse(classification_ids character varying)
RETURNS SETOF pmt_org_inuse_result_type AS $$
DECLARE
  valid_classification_ids int[];
  dynamic_where1 text array;
  built_where text array;
  execute_statement text;
  i integer;
  rec record;
BEGIN
  -- validate classification_ids parameter
  IF $1 IS NOT NULL OR $1 <> '' THEN
    SELECT INTO valid_classification_ids * FROM pmt_validate_classifications($1);    
    RAISE NOTICE 'Valid classifications: %', valid_classification_ids;
  END IF;

  -- create dynamic where from valid classification_ids
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
	dynamic_where1 := array_append(dynamic_where1, '(' || array_to_string(built_where, ' OR ') || ')');
    END LOOP;			
  END IF;
  
  -- prepare statement
  execute_statement := 'select row_to_json(j) from ( select org_order.organization_id as o_id, o.name ' ||
			'from ( select organization_id, count(distinct activity_id) as a_ct ' ||
			'from organization_lookup '; 
  IF dynamic_where1 IS NOT NULL THEN          
    execute_statement := execute_statement || 'where ' ||  array_to_string(dynamic_where1, ' AND ') ;
  END IF;

  execute_statement := execute_statement ||'group by organization_id ' ||
			') as org_order ' ||				 
			'join organization o on org_order.organization_id = o.organization_id ' || 
			'order by org_order.a_ct desc ) j';
  
  RAISE NOTICE 'Where: %', dynamic_where1;	
  RAISE NOTICE 'Execute: %', execute_statement;
  		    
  -- execute statement
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