/******************************************************************
Change Script 2.0.8.68
1. pmt_taxonomies - add code to the returned object, repaire category
selection
******************************************************************/
INSERT INTO version(version, iteration, changeset) VALUES (2.0, 8, 68);
-- select * from version order by changeset desc;

-- select * from pmt_taxonomies(null);
-- select * from pmt_taxonomies('20,27');

CREATE OR REPLACE FUNCTION pmt_taxonomies(taxonomy_ids character varying) RETURNS SETOF pmt_json_result_type AS $$
DECLARE
  valid_taxonomy_ids int[];  
  dynamic_where1 text;
  dynamic_where2 text;
  exectute_statement text;
  data_group_id integer;
  filter_taxids int[];
  rec record;
BEGIN	 
  
  -- if taxonomy_ids exists validate and filter
  IF $1 IS NOT NULL OR $1 <> '' THEN
    SELECT INTO valid_taxonomy_ids * FROM pmt_validate_taxonomies($1);
    IF valid_taxonomy_ids IS NOT NULL THEN
       -- get categories/sub-categories of related taxonomies
       SELECT INTO filter_taxids array_agg(taxonomy_id)::INT[] FROM taxonomy WHERE taxonomy_id = ANY(valid_taxonomy_ids) OR taxonomy_id IN ( SELECT category_id FROM taxonomy WHERE taxonomy_id = ANY(valid_taxonomy_ids)) AND active = true;
      dynamic_where1 := ' where taxonomy_id = ANY(ARRAY[' || array_to_string(filter_taxids, ',') || '])';  
      dynamic_where2 := ' where taxonomy_id = ANY(ARRAY[' || array_to_string(filter_taxids, ',') || '])';  
    END IF;
  END IF;
  
  -- prepare statement
  exectute_statement := 'select row_to_json(t) from ( ' ||
	 'select taxonomy.taxonomy_id as t_id, taxonomy.taxonomy as name, taxonomy.is_category as is_cat, taxonomy.taxonomy_category_id as cat_id, ( ' ||
	  'select array_to_json(array_agg(row_to_json(c))) ' ||
	   'from ( ' ||
	    'select class_order.classification_id as c_id, class_order.cat_id, class_order.classification as name, class_order.code as code ' ||
	    'from (select taxonomy_id, classification_id, classification, code, classification_category_id as cat_id ' ||
	    'from taxonomy_classifications ';
  
  IF dynamic_where1 IS NOT NULL THEN
    exectute_statement := exectute_statement || ' ' || dynamic_where1 || ' ';
  END IF;

  exectute_statement := exectute_statement || ' group by taxonomy_id, classification_id, classification, code, classification_category_id  ' ||
	     ') as class_order ' ||
	    'where class_order.taxonomy_id = taxonomy.taxonomy_id ' ||
	    ') c ) as classifications ' ||
	'from (select DISTINCT taxonomy_id, taxonomy, is_category, taxonomy_category_id ' ||  
	'from taxonomy_classifications ';

  IF dynamic_where2 IS NOT NULL THEN
     exectute_statement := exectute_statement || ' ' || dynamic_where2 || ' ';
  END IF;

  exectute_statement := exectute_statement || 'order by taxonomy) as taxonomy ' ||
	') t ';
	
  --RAISE NOTICE 'Execute: %', exectute_statement;
  		    
  -- execute statement
  FOR rec IN EXECUTE exectute_statement	    
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