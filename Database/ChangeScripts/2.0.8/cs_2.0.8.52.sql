/******************************************************************
Change Script 2.0.8.52 - consolidated.
1. pmt_category_root - new overloaded function to allow requests
for multiple data groups as well
******************************************************************/
INSERT INTO version(version, iteration, changeset) VALUES (2.0, 8, 52);
-- select * from version order by changeset desc;

DROP FUNCTION IF EXISTS pmt_category_root(integer, character varying) CASCADE;

-- select * from pmt_category_root(17,'978');
-- select * from pmt_locations_by_tax(17, '978', '');
-- select * from pmt_data_groups();

/******************************************************************
  pmt_category_root (overloaded method)
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_category_root(id integer, data_group character varying) RETURNS INT AS $$
DECLARE 
  valid_taxonomy_id boolean;
  base_taxonomy_ids integer[];
  base_taxonomy_id integer;
  data_group_ids integer[];
  classification_ids integer[];
  is_current_category boolean;
  dynamic_where1 text;
  dynamic_where2 text;
  execute_statement text;
  sub_category record;
  subsub_category record;
  rec record;
BEGIN 

     IF $1 IS NULL THEN    
       RETURN base_taxonomy_ids;
     END IF;
     -- validation test
     SELECT INTO valid_taxonomy_id * FROM pmt_validate_taxonomy($1);
     -- is a valid taxonomy
     IF valid_taxonomy_id THEN
       -- is the current taxonomy a category?
       SELECT INTO is_current_category is_category FROM taxonomy WHERE taxonomy_id = $1;
         -- Yes, loop through the sub-category(ies)
         IF is_current_category THEN
           FOR sub_category IN (SELECT taxonomy_id, is_category FROM taxonomy WHERE category_id = $1) LOOP
           RAISE NOTICE 'sub category: %', sub_category.taxonomy_id || ' ' || sub_category.is_category;
             -- is the sub-category a category?
             IF sub_category.is_category THEN
               -- Yes, loop through the sub-sub-category(ies) 
               FOR subsub_category IN (SELECT taxonomy.taxonomy_id, taxonomy.is_category FROM taxonomy WHERE category_id = sub_category.taxonomy_id) LOOP
                 IF subsub_category.is_category THEN
                   -- this is currently the limit in category depth for PMT (this could be expanded)
                 ELSE
                   -- No, this is a base taxonomy for the given category, collect it
                   base_taxonomy_ids := array_append(base_taxonomy_ids, subsub_category.taxonomy_id);
                 END IF;
               END LOOP;               
             ELSE
               -- No, this is a base taxonomy for the given category, collect it
               base_taxonomy_ids := array_append(base_taxonomy_ids, sub_category.taxonomy_id);
             END IF;
           END LOOP;
         ELSE
           -- No, this is a base taxonomy
	   base_taxonomy_ids := array_append(base_taxonomy_ids, $1);
         END IF;
     ELSE
     END IF;

     
     -- validate and process data_group parameter
     IF $2 IS NOT NULL THEN
       classification_ids := string_to_array($2, ',')::int[];
       -- check that the data group exists
       SELECT INTO data_group_ids array_agg(classification.classification_id) FROM classification WHERE classification.classification_id = ANY(classification_ids) AND classification.taxonomy_id = (SELECT taxonomy.taxonomy_id FROM taxonomy WHERE name = 'Data Group');
       RAISE NOTICE 'data groups: %', array_to_string(data_group_ids, ',');
       -- add where statement if data group is valid
       IF data_group_ids IS NOT NULL THEN	
          dynamic_where1 := ' and project_id in (select distinct project_id from taxonomy_lookup where classification_id = ANY(ARRAY[' || array_to_string(data_group_ids, ',') || ']))';
          dynamic_where2 := ' and project_id in (select distinct project_id from taxonomy_lookup where classification_id = ANY(ARRAY[' || array_to_string(data_group_ids, ',') || ']))';
       END IF;    
     END IF;
     
     -- prepare statement
     execute_statement := 'SELECT taxonomy_id ' 
	|| ' FROM (SELECT taxonomy_id, count(location_id) as rec_count ' 
        || ' FROM taxonomy_lookup '
        || ' WHERE taxonomy_id = ANY(ARRAY[' || array_to_string(base_taxonomy_ids, ',') || ']) ';
        
     IF dynamic_where1 IS NOT NULL THEN
	execute_statement := execute_statement || ' ' || dynamic_where1 || ' ';
     END IF;

     execute_statement := execute_statement || ' GROUP BY taxonomy_id) t2 JOIN '
        || '(SELECT MAX(t1.rec_count) as rec_max FROM '
	|| '(SELECT count(location_id) as rec_count '
	|| 'FROM taxonomy_lookup ' 
     	|| 'WHERE taxonomy_id = ANY(ARRAY[' || array_to_string(base_taxonomy_ids, ',') || ']) ';

     IF dynamic_where2 IS NOT NULL THEN
	execute_statement := execute_statement || ' ' || dynamic_where2 || ' ';
     END IF;
      	
     execute_statement := execute_statement || 'GROUP BY taxonomy_id) t1 ) t3 '
     	|| 'ON t2.rec_count = t3.rec_max LIMIT 1;';

     RAISE NOTICE 'Execute statement: %', execute_statement;
     
     -- determine root taxonomy to return by popularity
       FOR rec IN EXECUTE execute_statement	    
	  LOOP
	    base_taxonomy_id := rec.taxonomy_id;
	  END LOOP;
      
     RETURN base_taxonomy_id;

 EXCEPTION
      WHEN others THEN RETURN NULL;
END; 
$$ LANGUAGE 'plpgsql';

-- update permissions
GRANT USAGE ON SCHEMA public TO pmt_read;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO pmt_read;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO pmt_read;
GRANT USAGE ON SCHEMA public TO pmt_write;
GRANT SELECT,INSERT ON ALL TABLES IN SCHEMA public TO pmt_write;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO pmt_write;