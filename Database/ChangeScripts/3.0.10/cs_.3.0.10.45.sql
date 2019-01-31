/******************************************************************
Change Script 3.0.10.45
1. add feature_id to _location_boundary_features view
2. update function pmt_boundary_pivot to fix errors 
******************************************************************/
INSERT INTO version(_version, _iteration, _changeset) VALUES (3.0, 10, 45);
-- select * from version order by _iteration desc, _changeset desc;

/******************************************************************
1. add feature_id to _location_boundary_features view
******************************************************************/
-- drop dependent views
DROP VIEW IF EXISTS tanaim_nbs;
DROP VIEW IF EXISTS _location_boundary_features;
CREATE OR REPLACE VIEW _location_boundary_features AS 
 SELECT l.id AS location_id,
    l.activity_id,
    lb.boundary_id,
    b._name AS boundary_name,
    lb.feature_id,
    lb._feature_name AS feature_name,
    lb._feature_area AS feature_area
   FROM location l
     JOIN location_boundary lb ON l.id = lb.location_id
     JOIN boundary b ON lb.boundary_id = b.id
  ORDER BY l.id, lb.boundary_id;

-- recreate dependent view (no changes made)
CREATE OR REPLACE VIEW tanaim_nbs AS 
 SELECT a.id AS activity_id,
    a._title AS title,
    l.id AS location_id,
    l._lat_dd AS lat_dd,
    l._long_dd AS long_dd,
    l._point AS point,
    ( SELECT lbf.feature_name
           FROM _location_boundary_features lbf
          WHERE lbf.boundary_id = (( SELECT boundary.id
                   FROM boundary
                  WHERE boundary._name::text = 'GAUL Level 0'::text)) AND lbf.location_id = l.id
         LIMIT 1) AS "Country (Gaul0)",
    ( SELECT lbf.feature_name
           FROM _location_boundary_features lbf
          WHERE lbf.boundary_id = (( SELECT boundary.id
                   FROM boundary
                  WHERE boundary._name::text = 'GAUL Level 1'::text)) AND lbf.location_id = l.id
         LIMIT 1) AS "Region (Gaul1)",
    ( SELECT lbf.feature_name
           FROM _location_boundary_features lbf
          WHERE lbf.boundary_id = (( SELECT boundary.id
                   FROM boundary
                  WHERE boundary._name::text = 'GAUL Level 2'::text)) AND lbf.location_id = l.id
         LIMIT 1) AS "District (Gaul2)",
    ( SELECT lbf.feature_name
           FROM _location_boundary_features lbf
          WHERE lbf.boundary_id = (( SELECT boundary.id
                   FROM boundary
                  WHERE boundary._name::text = 'NBS Tanzania Regions'::text)) AND lbf.location_id = l.id
         LIMIT 1) AS "Region (NBS2)",
    ( SELECT lbf.feature_name
           FROM _location_boundary_features lbf
          WHERE lbf.boundary_id = (( SELECT boundary.id
                   FROM boundary
                  WHERE boundary._name::text = 'NBS Tanzania Districts'::text)) AND lbf.location_id = l.id
         LIMIT 1) AS "District (NBS1)"
   FROM activity a
     JOIN location l ON a.id = l.activity_id
  WHERE (l.id IN ( SELECT _location_boundary_features.location_id
           FROM _location_boundary_features
          WHERE _location_boundary_features.feature_name::text = 'United Republic of Tanzania'::text))
  ORDER BY a.id, a._title;
    
/******************************************************************
2. update function pmt_boundary_pivot to fix errors 
   select * from pmt_boundary_pivot(16,22,true,497,'768',null,null,null,15,74);
   select * from pmt_boundary_pivot(16,68,false,496,'2237',null,null,null,15,74);
   select * from pmt_boundary_pivot(16,68,true,496,'2237',null,null,null,15,74);
   select * from pmt_boundary_pivot(16,53,true,496,'769',null,null,null,15,74);
   select * from pmt_boundary_pivot(2,53,false,496,'769',null,null,null,1,208);
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_boundary_pivot(pivot_boundary_id integer, pivot_taxonomy_id integer, boundary_as_row boolean,
org_role_id integer, data_group_ids character varying, classification_ids character varying, start_date date, 
end_date date, boundary_id integer, feature_id integer) RETURNS SETOF pmt_json_result_type AS
$$
DECLARE
  valid_pivot_boundary_id integer; 
  valid_pivot_taxonomy_id integer; 
  valid_role_id integer;
  valid_boundary_id integer;
  valid_feature_id integer; 
  spatial_table text;
  pivot_table text;
  feature_name text;
  feature_ids int[];
  filtered_activity_ids int[];
  feature_activity_ids int[];
  column_headers text[];
  col text;
  col_count int;
  execute_statement text;    
  rec record;
  error_msg text;
BEGIN

  -- validate and process pivot_boundary_id parameter
  IF $1 IS NOT NULL THEN
    -- validate the pivot boundary id
    SELECT INTO valid_pivot_boundary_id id FROM boundary WHERE id = $1 AND _active = true;
    IF valid_pivot_boundary_id IS NULL THEN
      FOR rec IN SELECT row_to_json(j) FROM( SELECT 'missing valid required parameter' AS error ) as j LOOP RETURN NEXT rec; END LOOP;
    END IF;
  ELSE
    FOR rec IN SELECT row_to_json(j) FROM( SELECT 'missing required parameter' AS error ) as j LOOP RETURN NEXT rec; END LOOP;
  END IF;
  -- validate and process pivot_taxonomy_id parameter
  IF $2 IS NOT NULL THEN
    -- validate the pivot taxonomy id
    SELECT INTO valid_pivot_taxonomy_id id FROM taxonomy WHERE id = $2 AND _active = true;
    IF valid_pivot_taxonomy_id IS NULL THEN
      FOR rec IN SELECT row_to_json(j) FROM( SELECT 'missing valid required parameter' AS error ) as j LOOP RETURN NEXT rec; END LOOP;
    END IF;
  ELSE
    FOR rec IN SELECT row_to_json(j) FROM( SELECT 'missing required parameter' AS error ) as j LOOP RETURN NEXT rec; END LOOP;
  END IF;
   -- validate and process boundary_as_row parameter
  IF $3 IS NULL THEN
     boundary_as_row := false;
  END IF;
  -- validate and process org_role_id parameter
  IF $4 IS NOT NULL THEN
    -- validate the organization role id
    SELECT INTO valid_role_id classification_id FROM _taxonomy_classifications WHERE taxonomy = 'Organisation Role' AND classification_id = $4;    
    IF valid_role_id IS NULL THEN
      FOR rec IN SELECT row_to_json(j) FROM( SELECT 'missing valid required parameter' AS error ) as j LOOP RETURN NEXT rec; END LOOP;
    END IF;
  ELSE
    FOR rec IN SELECT row_to_json(j) FROM( SELECT 'missing required parameter' AS error ) as j LOOP RETURN NEXT rec; END LOOP;
  END IF;
  -- validate and process boundary_id parameter
  IF $9 IS NOT NULL THEN
    -- validate the boundary id
    SELECT INTO valid_boundary_id id FROM boundary WHERE _active = true AND id = $9;    
    IF valid_boundary_id IS NULL THEN
      FOR rec IN SELECT row_to_json(j) FROM( SELECT 'provided boundary id is invalid' AS error ) as j LOOP RETURN NEXT rec; END LOOP;
    END IF;
  ELSE
    FOR rec IN SELECT row_to_json(j) FROM( SELECT 'missing required parameter' AS error ) as j LOOP RETURN NEXT rec; END LOOP;
  END IF;
  -- validate and process feature_id parameter
  IF $10 IS NOT NULL THEN
    -- get the name of the spatial table for the filtered boundary
    SELECT INTO spatial_table _spatial_table FROM boundary WHERE id = valid_boundary_id; 
    -- validate the feature id
    EXECUTE 'SELECT id FROM '|| spatial_table ||' WHERE _active = true AND id = ' || $10 INTO valid_feature_id;
    -- get valid feature name
    EXECUTE 'SELECT _name FROM '|| spatial_table ||' WHERE _active = true AND id = ' || $10 INTO feature_name;  
    IF valid_feature_id IS NULL THEN
      FOR rec IN SELECT row_to_json(j) FROM( SELECT 'provided feature id is invalid' AS error ) as j LOOP RETURN NEXT rec; END LOOP;
    END IF;
  ELSE
    FOR rec IN SELECT row_to_json(j) FROM( SELECT 'missing required parameter' AS error ) as j LOOP RETURN NEXT rec; END LOOP;
  END IF;
  
  -- get the filtered activity ids
  SELECT INTO filtered_activity_ids * FROM pmt_filter($5,$6,null,null,null,$7,$8,null);

  IF valid_boundary_id IS NOT NULL AND valid_feature_id IS NOT NULL THEN
    -- get the activity ids for the feature
    SELECT INTO feature_activity_ids array_agg(activity_id) FROM _location_lookup ll WHERE ll.boundary_id = valid_boundary_id AND ll.feature_id = valid_feature_id;
  END IF;

  -- the name of the spatial table 
  SELECT INTO pivot_table _spatial_table FROM boundary WHERE id = valid_pivot_boundary_id; 
  
  -- get the column headers
  IF(boundary_as_row)THEN
    SELECT INTO column_headers array_agg(quote_literal(classification))::text[] FROM _taxonomy_classifications WHERE taxonomy_id = valid_pivot_taxonomy_id;
    EXECUTE 'SELECT array_agg(id)::int[] FROM '|| pivot_table ||' WHERE _'|| spatial_table || '_name = ' || quote_literal(feature_name) INTO feature_ids;
  ELSE      
    EXECUTE 'SELECT array_agg(quote_literal(_name))::text[] FROM '|| pivot_table ||' WHERE _'|| spatial_table || '_name = ' || quote_literal(feature_name) INTO column_headers;
  END IF;  
  
  -- prepare the execution statement
  execute_statement:= 'SELECT ''''::text as c1,';
  col_count :=2;

  -- prepare the column headers
  FOREACH col IN ARRAY column_headers LOOP
    execute_statement:= execute_statement || 'to_json(' || col || '::text) as c' || col_count || ','; 
    col_count := col_count + 1;
  END LOOP;
  
  -- trim off the last comma
  execute_statement:= substring(execute_statement, 0, length(execute_statement));

  -- begin the aggregation statement
  execute_statement:= execute_statement || ' UNION ALL SELECT * FROM ( SELECT rows.classification::text, ';

  -- prepare the aggreation select statement
  FOREACH col IN ARRAY column_headers LOOP
    execute_statement:= execute_statement || 'json_agg(distinct case when cols.classification = ' || col || 
			' then row(org._label, org.organization_id, org._name) end) as ' || quote_ident(col) || ',';
  END LOOP;
  
  -- trim off the last comma
  execute_statement:= substring(execute_statement, 0, length(execute_statement));
  
  IF array_length(feature_activity_ids, 1) > 0 THEN
    execute_statement:= execute_statement || ' FROM ( SELECT id FROM activity WHERE id = ANY(ARRAY[' || array_to_string(filtered_activity_ids, ',') || ']) ' || 
				'AND id = ANY(ARRAY[' || array_to_string(feature_activity_ids, ',') || '])) a ';
  ELSE
    execute_statement:= execute_statement || 'FROM ( SELECT id FROM activity WHERE id = ANY(ARRAY[' || array_to_string(filtered_activity_ids, ',') || '])) a ';
  END IF;
			
  execute_statement:= execute_statement	|| 'LEFT JOIN ' ||
			'(SELECT id, _label, _name, organization_id ' ||
			'FROM _activity_participants ' ||
			'WHERE id = ANY(ARRAY[' || array_to_string(filtered_activity_ids, ',') || ']) AND classification_id = ' || valid_role_id || ') as org ' ||
			'ON a.id = org.id ' ||
			'LEFT JOIN ';
  IF (boundary_as_row) THEN
    execute_statement:= execute_statement	|| '(SELECT id, classification ' ||
			'FROM _activity_taxonomies ' ||
			'WHERE id = ANY(ARRAY[' || array_to_string(filtered_activity_ids, ',') || ']) AND taxonomy_id = ' || valid_pivot_taxonomy_id || ') as cols ' ||
			'ON a.id = cols.id ' ||
			'LEFT JOIN ' ||
			'(SELECT DISTINCT activity_id as id, feature_name as classification ' ||
			'FROM _location_boundary_features ' ||
			'WHERE activity_id = ANY(ARRAY[' || array_to_string(filtered_activity_ids, ',') || ']) AND boundary_id = ' || valid_pivot_boundary_id || 
			' AND feature_id = ANY(ARRAY[' || array_to_string(feature_ids, ',') || '])) as rows ' ||
			'ON a.id = rows.id ' ||
			'GROUP BY 1 ' ||
			') as selection';
  ELSE
    execute_statement:= execute_statement	|| '(SELECT DISTINCT activity_id as id, feature_name as classification ' ||
			'FROM _location_boundary_features ' ||
			'WHERE activity_id = ANY(ARRAY[' || array_to_string(filtered_activity_ids, ',') || ']) AND boundary_id = ' || valid_pivot_boundary_id || ') as cols ' ||
			'ON a.id = cols.id ' ||
			'LEFT JOIN ' ||
			'(SELECT id, classification ' ||
			'FROM _activity_taxonomies ' ||
			'WHERE id = ANY(ARRAY[' || array_to_string(filtered_activity_ids, ',') || ']) AND taxonomy_id = ' || valid_pivot_taxonomy_id || ') as rows ' ||
			'ON a.id = rows.id ' ||
			'GROUP BY 1 ' ||
			') as selection';
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