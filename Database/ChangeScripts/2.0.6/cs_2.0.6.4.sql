/******************************************************************
Change Script 2.0.6.4 - Consolidated
1. pmt_tax_inuse - fixed error, classification was returning with 
taxonomy category_id instead of its own.
******************************************************************/
UPDATE config SET changeset = 4, updated_date = current_date WHERE "version" = 2.0 AND iteration = 6;
-- SELECT pmt_version();

/******************************************************************
  pmt_tax_inuse
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_tax_inuse(data_group_id integer, taxonomy_ids character varying, country_ids character varying)
RETURNS SETOF pmt_tax_inuse_result_type AS 
$$
DECLARE
  valid_classification_id boolean;
  valid_classification_ids int[];
  valid_country_ids int[];
  dynamic_where1 text;
  dynamic_where2 text;
  exectute_statement text;
  data_group_id integer;
  filter_taxids int[];
  rec record;
BEGIN
  -- confirm the passed id is a valid data group
  SELECT INTO data_group_id classification_id FROM taxonomy_classifications WHERE taxonomy = 'Data Group' AND classification_id = $1;

  -- if data group exists validate and filter	
  IF data_group_id IS NOT NULL THEN
    dynamic_where1 := ' where project_id in (select distinct project_id from taxonomy_lookup where classification_id =' || data_group_id || ')';
    dynamic_where2 := ' where project_id in (select distinct project_id from taxonomy_lookup where classification_id =' || data_group_id || ')';
  END IF;
  
  -- if taxonomy_ids exists validate and filter
  IF $2 IS NOT NULL OR $2 <> '' THEN
    SELECT INTO filter_taxids * FROM pmt_validate_taxonomies($2);
    IF filter_taxids IS NOT NULL THEN
      IF dynamic_where2 IS NULL THEN
        dynamic_where2 := ' where taxonomy_id = ANY(ARRAY[' || array_to_string(filter_taxids, ',') || '])';
      ELSE
        dynamic_where2 := dynamic_where2 || ' and taxonomy_id = ANY(ARRAY[' || array_to_string(filter_taxids, ',')  || '])';
      END IF;    
    END IF;
  END IF;

   --  if country_ids exists validate and filter
  IF $3 IS NOT NULL OR $3 <> '' THEN
    SELECT INTO valid_classification_ids * FROM pmt_validate_classifications($3);
    RAISE NOTICE 'valid classification ids: %', valid_classification_ids;
    IF valid_classification_ids IS NOT NULL THEN
      SELECT INTO valid_country_ids array_agg(DISTINCT c.classification_id)::INT[] 
      FROM (
        SELECT classification.classification_id 
        FROM classification 
        WHERE active = true 
        AND classification.classification_id = ANY(valid_classification_ids)
        AND classification.taxonomy_id = (SELECT taxonomy.taxonomy_id FROM taxonomy WHERE iati_codelist = 'Country')
         ORDER BY classification.classification_id
      ) as c;
    END IF;
    
    IF valid_country_ids IS NOT NULL THEN
      IF dynamic_where1 IS NOT NULL THEN
        dynamic_where1 := dynamic_where1 || ' and location_id in (select location_id from taxonomy_lookup where classification_id = ANY(ARRAY[' || array_to_string(valid_country_ids, ',')  || ']))';
      ELSE
        dynamic_where1 := ' where location_id in (select location_id from taxonomy_lookup where classification_id = ANY(ARRAY[' || array_to_string(valid_country_ids, ',')  || ']))';
      END IF;
      IF dynamic_where2 IS NOT NULL THEN
        dynamic_where2 := dynamic_where2 || ' and location_id in (select location_id from taxonomy_lookup where classification_id = ANY(ARRAY[' || array_to_string(valid_country_ids, ',')  || ']))';
      ELSE
        dynamic_where2 := ' where location_id in (select location_id from taxonomy_lookup where classification_id = ANY(ARRAY[' || array_to_string(valid_country_ids, ',')  || ']))';
      END IF;           
    END IF; 
  END IF;
  
  -- prepare statement
  exectute_statement := 'select row_to_json(t) from ( ' ||
	 'select taxonomy.taxonomy_id as t_id, taxonomy.name, taxonomy.is_category as is_cat, taxonomy.category_id as cat_id,( ' ||
	  'select array_to_json(array_agg(row_to_json(c))) ' ||
	   'from ( ' ||
	    'select class_order.classification_id as c_id, c.category_id as cat_id, c.name ' ||
	    'from (select taxonomy_id, classification_id, category_id, count(distinct location_id) as location_count ' ||
	    'from taxonomy_lookup ';
  
  IF dynamic_where1 IS NOT NULL THEN
    exectute_statement := exectute_statement || ' ' || dynamic_where1 || ' ';
  END IF;

  exectute_statement := exectute_statement || ' group by taxonomy_id, classification_id, category_id ' ||
	     ') as class_order ' ||
	    'join classification c ' ||
	    'on class_order.classification_id = c.classification_id ' ||
	    'where class_order.taxonomy_id = taxonomy.taxonomy_id ' ||
	    'order by class_order.location_count desc ' ||
	    ') c ) as classifications ' ||
	'from (select tl.taxonomy_id, t.name, t.is_category, t.category_id ' ||
	'from (select distinct taxonomy_id ' ||   
	'from taxonomy_lookup ';

  IF dynamic_where2 IS NOT NULL THEN
     exectute_statement := exectute_statement || ' ' || dynamic_where2 || ' ';
  END IF;

  exectute_statement := exectute_statement || ') tl join taxonomy t ' ||
	'on tl.taxonomy_id = t.taxonomy_id ' ||
	'order by t.name) as taxonomy ' ||
	') t ';
	
  RAISE NOTICE 'Execute: %', exectute_statement;
  		    
  -- execute statement
  FOR rec IN EXECUTE exectute_statement	    
  LOOP
    RETURN NEXT rec;    
  END LOOP;
END;$$ LANGUAGE plpgsql;