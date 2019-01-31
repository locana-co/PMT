/******************************************************************
Change Script 3.0.10.59
1. update pmt_stat_activity_by_tax to add activity_ids.
******************************************************************/
INSERT INTO version(_version, _iteration, _changeset) VALUES (3.0, 10, 59);
-- select * from version order by _iteration desc, _changeset desc;

/******************************************************************
1. update pmt_stat_activity_by_tax to add activity_ids.
   select * from pmt_stat_activity_by_tax(14,'2208',null,null,null,15,74,9);
   select * from pmt_stat_activity_by_tax(69,'2237',null,null,null,15,74,5); 
   select * from pmt_stat_activity_by_tax(68,'2237',null,null,null,15,74,3);
   select * from pmt_stat_activity_by_tax(68,'2237',null,null,null,15,74,null); 
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_stat_activity_by_tax(taxonomy_id integer, data_group_ids character varying, classification_ids character varying, 
start_date date, end_date date, boundary_id integer, feature_id integer, record_limit integer) RETURNS SETOF pmt_json_result_type AS
$$
DECLARE
  dg_ids int[];
  valid_dg_ids int[];
  valid_taxonomy_id integer; 
  valid_boundary_id integer;
  valid_feature_id integer; 
  spatial_table text;
  filtered_activity_ids int[];
  feature_activity_ids int[];
  execute_statement text; 
  where_statement text;
  rec record;
  error_msg text;
BEGIN

  -- validate and process taxonomy_id parameter
  IF $1 IS NOT NULL THEN
    -- validate the taxonomy id
    SELECT INTO valid_taxonomy_id id FROM taxonomy WHERE id = $1 AND _active = true;
    IF valid_taxonomy_id IS NULL THEN
      FOR rec IN SELECT row_to_json(j) FROM( SELECT 'missing valid required parameter' AS error ) as j LOOP RETURN NEXT rec; END LOOP;
    END IF;
  ELSE
    FOR rec IN SELECT row_to_json(j) FROM( SELECT 'missing required parameter' AS error ) as j LOOP RETURN NEXT rec; END LOOP;
  END IF;
  -- validate and process boundary_id parameter
  IF $6 IS NOT NULL THEN
    -- validate the boundary id
    SELECT INTO valid_boundary_id id FROM boundary WHERE _active = true AND id = $6;    
    IF valid_boundary_id IS NULL THEN
      FOR rec IN SELECT row_to_json(j) FROM( SELECT 'provided boundary id is invalid' AS error ) as j LOOP RETURN NEXT rec; END LOOP;
    END IF;
  END IF;
  -- validate and process feature_id parameter
  IF $7 IS NOT NULL THEN
     SELECT INTO spatial_table _spatial_table FROM boundary WHERE id = valid_boundary_id; 
    -- validate the feature id
    EXECUTE 'SELECT id FROM '|| spatial_table ||' WHERE _active = true AND id = ' || $7 INTO valid_feature_id;  
    IF valid_feature_id IS NULL THEN
      FOR rec IN SELECT row_to_json(j) FROM( SELECT 'provided feature id is invalid' AS error ) as j LOOP RETURN NEXT rec; END LOOP;
    END IF;
  END IF;  
  
  -- get the filtered activity ids
  SELECT INTO filtered_activity_ids * FROM pmt_filter($2,$3,null,null,null,$4,$5,null);

  IF valid_boundary_id IS NOT NULL AND valid_feature_id IS NOT NULL THEN
    -- get the activity ids for the feature
    SELECT INTO feature_activity_ids array_agg(activity_id) FROM _location_lookup ll WHERE ll.boundary_id = valid_boundary_id AND ll.feature_id = valid_feature_id;
  END IF;

    -- determine which where statement to use
  IF array_length(feature_activity_ids, 1) > 0 THEN
    where_statement:= 'WHERE (parent_id = ANY(ARRAY[' || array_to_string(filtered_activity_ids, ',') || ']) '|| 
				'AND parent_id = ANY(ARRAY[' || array_to_string(feature_activity_ids, ',') || '])) ' || 
				'OR (child_id = ANY(ARRAY[' || array_to_string(filtered_activity_ids, ',') || ']) '|| 
				'AND child_id = ANY(ARRAY[' || array_to_string(feature_activity_ids, ',') || '])) ';
  ELSE
    where_statement:= 'WHERE parent_id = ANY(ARRAY[' || array_to_string(filtered_activity_ids, ',') || ']) ' ||
			'OR child_id = ANY(ARRAY[' || array_to_string(filtered_activity_ids, ',') || ']) ';
  END IF;

  -- prepare the execution statement
  execute_statement:= 'SELECT CASE WHEN classification_id IS NULL THEN NULL ELSE classification_id END as classification_id, ' ||
			'CASE WHEN classification IS NULL THEN ''Unspecified'' ELSE classification END as classification, ' ||   
			'count(DISTINCT parent_id), sum(amount), array_agg(DISTINCT parent_id) as a_ids, ROW_NUMBER () OVER (ORDER BY sum(amount) DESC) as rec_count FROM ' || 
			'(SELECT DISTINCT classification_id, classification, parent_id, amount '
			'FROM _activity_family_taxonomies WHERE taxonomy_id = ' || valid_taxonomy_id || ' AND parent_id IN ' ||
			'(SELECT DISTINCT parent_id FROM _activity_family ' || where_statement || ') ORDER BY 3,1 ) a GROUP BY 1,2';

  IF record_limit > 0 THEN
    execute_statement := 'SELECT classification_id, classification, count, a_ids, sum FROM (' || execute_statement || 
	') as foo WHERE rec_count <= ' || record_limit || ' UNION ALL '
	'SELECT null, ''Other'', count(DISTINCT parent_id) as count,  array_agg(DISTINCT parent_id) as a_ids, sum(amount) as sum FROM ' ||
	'(SELECT DISTINCT classification_id, classification, parent_id, amount ' ||
	'FROM _activity_family_taxonomies WHERE taxonomy_id = ' || valid_taxonomy_id || ' AND parent_id IN ' ||
	'(SELECT DISTINCT parent_id FROM _activity_family ' || where_statement || ') ' ||
	'AND classification_id IN ( ' ||
		'SELECT classification_id FROM ( ' ||
		    'SELECT CASE WHEN classification_id IS NULL THEN NULL ELSE classification_id END as classification_id, ' ||
			'CASE WHEN classification IS NULL THEN ''Unspecified'' ELSE classification END as classification, ' ||   
			'count(DISTINCT parent_id), sum(amount), ROW_NUMBER () OVER (ORDER BY sum(amount) DESC) as rec_count FROM ' || 
			'(SELECT DISTINCT classification_id, classification, parent_id, amount '
			'FROM _activity_family_taxonomies WHERE taxonomy_id = ' || valid_taxonomy_id || ' AND parent_id IN ' ||
			'(SELECT DISTINCT parent_id FROM _activity_family ' || where_statement || ') ORDER BY 3,1 ) a GROUP BY 1,2' ||
			') as foo WHERE rec_count > ' || record_limit || ' ) ORDER BY 3,1 ) a'; 		
  ELSE
    execute_statement := execute_statement || ' ORDER BY 4 DESC';
  END IF;
  	
  RAISE NOTICE 'Execute statement: %', execute_statement;			

  FOR rec IN EXECUTE 'SELECT row_to_json(j) FROM (' || execute_statement || ')j' LOOP  		
	RETURN NEXT rec;
  END LOOP;
 
EXCEPTION WHEN others THEN 
  GET STACKED DIAGNOSTICS error_msg = MESSAGE_TEXT;  
    RAISE NOTICE 'Internal Error - Contact your DBA with the following error message: %', error_msg;
    
END;$$ LANGUAGE plpgsql;


-- update permissions
GRANT USAGE ON SCHEMA public TO pmt_read;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO pmt_read;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO pmt_read;
GRANT USAGE ON SCHEMA public TO pmt_write;
GRANT SELECT,INSERT ON ALL TABLES IN SCHEMA public TO pmt_write;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO pmt_write;

