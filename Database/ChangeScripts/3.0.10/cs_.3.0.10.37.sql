/******************************************************************
Change Script 3.0.10.37
1. create pmt_update_crosswalks function to update crosswalked
taxonomies for a data group
2. update _taxonomy_xwalks view to correct duplication  
3. update pmt_stat_activity_by_tax address errors in calculations
******************************************************************/
INSERT INTO version(_version, _iteration, _changeset) VALUES (3.0, 10, 37);
-- select * from version order by _iteration desc, _changeset desc;

/******************************************************************
1. create pmt_update_crosswalks function to update crosswalked
taxonomies for a data group
   select * from pmt_update_crosswalks(768);   
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_update_crosswalks(data_group_id integer) RETURNS BOOLEAN AS
$$
DECLARE
  valid_data_group_id integer;
  activity_ids integer[];
  existing integer;
  classification text;
  rec record;
  xwalk record;
  error_msg text;
BEGIN
  -- validate data group id
  IF $1 IS NOT NULL THEN
    SELECT INTO valid_data_group_id id FROM classification WHERE taxonomy_id = 1 AND id = $1;
    IF valid_data_group_id IS NULL THEN
      RAISE NOTICE 'Data group id not valid.', error_msg;
      RETURN FALSE;
    END IF;
  ELSE
    RAISE NOTICE 'Data group id is a required parameter.', error_msg;
    RETURN FALSE;
  END IF;

  -- get a list of activity ids for the data group
  SELECT INTO activity_ids array_agg(a.id)::int[] FROM activity a WHERE a._active = true AND a.data_group_id = valid_data_group_id;
  
  -- remove all the crosswalk data (currently only crosswalk activity taxonomies)
  DELETE FROM activity_taxonomy WHERE _field = 'xwalk' AND activity_id = ANY(activity_ids);

  -- loop through all the activity taxonomies and determine if a crosswalk is needed
  FOR rec IN SELECT * FROM activity_taxonomy WHERE activity_id = ANY(activity_ids) AND classification_id IN 
	(SELECT DISTINCT origin_classification_id FROM taxonomy_xwalk WHERE _active = true) LOOP  	
    SELECT INTO classification _name from classification WHERE id = rec.classification_id;	
    RAISE NOTICE 'Activity id %', '(' || rec.activity_id || ') with classification (' || rec.classification_id || '): ' || classification;
    -- loop through all the crosswalk records and apply relationships
    FOR xwalk IN SELECT * FROM _taxonomy_xwalks WHERE origin_classification_id = rec.classification_id LOOP
      -- check to see if the relationships currently exists
      SELECT INTO existing activity_id FROM activity_taxonomy WHERE activity_id = rec.activity_id AND classification_id = xwalk.linked_classification_id AND _field = 'xwalk';
      IF existing > 0 THEN
        RAISE NOTICE '-----> Crosswalk exists to taxonomy %',  xwalk.linked_taxonomy || '(' || xwalk.linked_taxonomy_id || ') & classification ' || xwalk.linked_classification || ' (' || xwalk.linked_classification_id || ')';
      ELSE 
        -- add the relationship
        RAISE NOTICE '-----> Crosswalking to taxonomy %',  xwalk.linked_taxonomy || '(' || xwalk.linked_taxonomy_id || ') & classification ' || xwalk.linked_classification || ' (' || xwalk.linked_classification_id || ')';
        INSERT INTO activity_taxonomy (activity_id, classification_id, _field) VALUES (rec.activity_id, xwalk.linked_classification_id, 'xwalk');
      END IF;      
    END LOOP;
  END LOOP;
  
RETURN TRUE;
 
EXCEPTION WHEN others THEN 
  GET STACKED DIAGNOSTICS error_msg = MESSAGE_TEXT;  
    RAISE NOTICE 'Internal Error - Contact your DBA with the following error message: %', error_msg;
    
END;$$ LANGUAGE plpgsql;

-- SELECT * FROM activity_taxonomy WHERE _field = 'xwalk'

/******************************************************************
2. update _taxonomy_xwalks view to correct duplication  
******************************************************************/
CREATE OR REPLACE VIEW _taxonomy_xwalks AS 
  SELECT origin_taxonomy_id, 
	o.taxonomy as origin_taxonomy,
	origin_classification_id,
	o.classification as origin_classification,
	linked_taxonomy_id,
	l.taxonomy as linked_taxonomy,
	linked_classification_id,
	l.classification as linked_classification,
	_direction
  FROM taxonomy_xwalk t
  LEFT JOIN (SELECT * FROM _taxonomy_classifications) o
  ON t.origin_taxonomy_id = o.taxonomy_id AND t.origin_classification_id = o.classification_id
  LEFT JOIN (SELECT * FROM _taxonomy_classifications) l
  ON t.linked_taxonomy_id = l.taxonomy_id AND t.linked_classification_id = l.classification_id;


/******************************************************************
3. update pmt_stat_activity_by_tax address errors in calculations
   select * from pmt_stat_activity_by_tax(23,null,'794',null,null,15,74);   
   select * from pmt_stat_activity_by_tax(23,'768',null,null,null,16,896); 
   select * from pmt_stat_activity_by_tax(14,null,null,null,null,15,74); 
******************************************************************/
DROP FUNCTION IF EXISTS pmt_stat_activity_by_tax(integer, character varying, character varying, date, date);
CREATE OR REPLACE FUNCTION pmt_stat_activity_by_tax(taxonomy_id integer, data_group_ids character varying, classification_ids character varying, 
start_date date, end_date date, boundary_id integer, feature_id integer) RETURNS SETOF pmt_json_result_type AS
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
    where_statement:= 'WHERE id = ANY(ARRAY[' || array_to_string(filtered_activity_ids, ',') || ']) '|| 
				'AND id = ANY(ARRAY[' || array_to_string(feature_activity_ids, ',') || ']) ';
  ELSE
    where_statement:= 'WHERE id = ANY(ARRAY[' || array_to_string(filtered_activity_ids, ',') || ']) ';
  END IF;

  -- prepare the execution statement
  execute_statement:= 'SELECT CASE WHEN t.classification_id IS NULL THEN NULL ELSE t.classification_id END,  ' ||
			'CASE WHEN t.classification IS NULL THEN ''Unspecified'' ELSE t.classification END, ' ||
			'count(DISTINCT id) as count, sum(_amount) as sum FROM ' ||
			'(SELECT DISTINCT at.id, f._amount, at.classification_id FROM ' ||				
				'(SELECT DISTINCT id, classification_id ' ||
				'FROM _activity_taxonomies ' || where_statement ||
				') at ' ||
				'LEFT JOIN ' ||
				'(SELECT DISTINCT id, _amount ' ||
				'FROM _activity_financials '|| where_statement ||
				') f ' ||
				'ON at.id = f.id ' ||
			') a ' ||
			'LEFT JOIN ( ' ||
				'SELECT taxonomy_id, taxonomy, classification_id, classification  ' ||
				'FROM _taxonomy_classifications ' ||
				'WHERE taxonomy_id = ' || valid_taxonomy_id || ') as t ' ||
			'ON t.classification_id = a.classification_id ' ||
			'GROUP BY 1,2 ' ||
			'ORDER BY 4'; 
	
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

