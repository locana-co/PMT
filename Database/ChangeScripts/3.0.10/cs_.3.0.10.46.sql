/******************************************************************
Change Script 3.0.10.46
1. Create view _activity_family to support parent -> child queries
2. Create materialized view _activity_family_finacials to support
finanaical queries on parent -> child relationships where financials 
are on the parent only
3. Update pmt_activity_by_invest function properly query top activities
based on fiancial information from the parent, while considering all 
activity locations
4. update pmt_overview_stats to address errors investment aggregations
5. Update _activity_taxonomies view to add _field feild
6. Create materialized view _activity_family_taxonomies to support
taxonomy queries on parent -> child relationships where financials 
are on the parent only and taxonomies are on all levels
7. update pmt_stat_activity_by_tax address errors in calculations
******************************************************************/
INSERT INTO version(_version, _iteration, _changeset) VALUES (3.0, 10, 46);
-- select * from version order by _iteration desc, _changeset desc;

/******************************************************************
1. Create view _activity_family to support parent -> child queries
******************************************************************/
DROP VIEW IF EXISTS _activity_family;
CREATE VIEW _activity_family AS 
  SELECT p.id as parent_id, c.id as child_id, p._title, p.data_group_id FROM
  (SELECT id, _title, data_group_id FROM activity WHERE _active = true AND parent_id IS NULL) p
  LEFT JOIN
  (SELECT id, parent_id FROM activity WHERE _active = true AND parent_id IS NOT NULL) c
  ON p.id = c.parent_id;

/******************************************************************
2. Create materialized view _activity_family_finacials to support
finanaical queries on parent -> child relationships where financials 
are on the parent only
******************************************************************/
DROP MATERIALIZED VIEW IF EXISTS _activity_family_finacials;
CREATE MATERIALIZED VIEW _activity_family_finacials AS 
  SELECT af.parent_id, af.child_id, af._title, af.data_group_id, m.amount, f._name as funder, i._name as implementor, a._name as accountable FROM 
  (SELECT * FROM _activity_family) af
  LEFT JOIN (SELECT id, sum(_amount) as amount FROM _activity_financials  
  WHERE (transaction_type IS NULL OR transaction_type = '' OR transaction_type IN ('Incoming Funds','Commitment'))
  GROUP BY 1) m
  ON af.parent_id = m.id
  LEFT JOIN (SELECT id,_name FROM _activity_participants WHERE classification = 'Funding') f
  ON af.parent_id = f.id OR af.child_id = f.id
  LEFT JOIN (SELECT id,_name FROM _activity_participants WHERE classification = 'Implementing') i
  ON af.parent_id = i.id OR af.child_id = i.id
  LEFT JOIN (SELECT id,_name FROM _activity_participants WHERE classification = 'Accountable') a
  ON af.parent_id = a.id OR af.child_id = a.id;

  CREATE INDEX _activity_family_finacials_parent_id ON _activity_family_finacials (parent_id);
  CREATE INDEX _activity_family_finacials_child_id ON _activity_family_finacials (child_id);
  CREATE INDEX _activity_family_finacials_amount ON _activity_family_finacials (amount);

/******************************************************************
3. Update pmt_activity_by_invest function properly query top activities
based on fiancial information from the parent, while considering all activity locations
   select * from pmt_activity_by_invest('768',null,null,null,15,74,5,'opportunity_id,_description');
   select * from pmt_activity_by_invest('768',null,null,null,15,239,5,'opportunity_id,_description');  
   select * from pmt_activity_by_invest('2237',null,null,null,16,896,5,null);  
   select * from pmt_activity_by_invest('2237',null,null,null,16,891,5,null);  
******************************************************************/
DROP FUNCTION IF EXISTS pmt_activity_by_invest(character varying, character varying, date, date, integer, integer, integer);
CREATE OR REPLACE FUNCTION pmt_activity_by_invest(data_group_ids character varying, classification_ids character varying, 
start_date date, end_date date, boundary_id integer, feature_id integer, limit_records integer, field_list character varying) RETURNS SETOF pmt_json_result_type AS
$$
DECLARE
  valid_boundary_id integer;
  valid_feature_id integer; 
  spatial_table text;
  filtered_activity_ids int[];
  feature_activity_ids int[];
  column_list character varying[];
  valid_column text;
  execute_statement text; 
  where_statement text;    
  rec record;
  error_msg text;
BEGIN
  
  -- validate and process boundary_id parameter
  IF $5 IS NOT NULL THEN
    -- validate the boundary id
    SELECT INTO valid_boundary_id id FROM boundary WHERE _active = true AND id = $5;    
    IF valid_boundary_id IS NULL THEN
      FOR rec IN SELECT row_to_json(j) FROM( SELECT 'provided boundary id is invalid' AS error ) as j LOOP RETURN NEXT rec; END LOOP;
    END IF;
  END IF;
  -- validate and process feature_id parameter
  IF $6 IS NOT NULL THEN
     SELECT INTO spatial_table _spatial_table FROM boundary WHERE id = valid_boundary_id; 
    -- validate the feature id
    EXECUTE 'SELECT id FROM '|| spatial_table ||' WHERE _active = true AND id = ' || $6 INTO valid_feature_id;  
    IF valid_feature_id IS NULL THEN
      FOR rec IN SELECT row_to_json(j) FROM( SELECT 'provided feature id is invalid' AS error ) as j LOOP RETURN NEXT rec; END LOOP;
    END IF;
  END IF;

  -- get the filtered activity ids
  SELECT INTO filtered_activity_ids * FROM pmt_filter($1,$2,null,null,null,$3,$4,null);

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
  execute_statement:= 'SELECT a.parent_id as id, a._title, a.amount, string_agg(DISTINCT a.funder,'','') as fund, ' ||
				'string_agg(DISTINCT a.implementor,'','') as imp, string_agg(DISTINCT a.accountable,'','') as acct ';

  -- validate and process the field_list parameter
  IF $8 IS NOT NULL THEN
    column_list:= string_to_array($8, ',')::character varying[];
    -- get list of valid columns to return
    FOR valid_column IN (SELECT column_name FROM information_schema.columns WHERE table_schema='public' AND table_name='activity' AND column_name = ANY(column_list)) LOOP
      execute_statement:= execute_statement || ', (SELECT ' || valid_column || ' FROM activity WHERE id = a.parent_id) as ' || valid_column;
    END LOOP;
  END IF;

  execute_statement:= execute_statement || ' FROM _activity_family_finacials a WHERE parent_id IN (SELECT DISTINCT parent_id FROM _activity_family ' || 
			where_statement || ') AND a.amount IS NOT NULL GROUP BY 1,2,3 ORDER BY 3 DESC';
			
  -- add limit if requested
  IF limit_records > 0 THEN
    execute_statement:= execute_statement || ' LIMIT ' || limit_records;
  END IF;						
  
  RAISE NOTICE 'Execute statement: %', execute_statement;			

  FOR rec IN EXECUTE 'SELECT row_to_json(j) FROM (' || execute_statement || ')j' LOOP  		
	RETURN NEXT rec;
  END LOOP;
  
EXCEPTION WHEN others THEN 
  GET STACKED DIAGNOSTICS error_msg = MESSAGE_TEXT;  
    RAISE NOTICE 'Internal Error - Contact your DBA with the following error message: %', error_msg;
    
END;$$ LANGUAGE plpgsql;

 
/******************************************************************
4. update pmt_overview_stats to address errors investment aggregations
  SELECT * FROM pmt_overview_stats('768',null,null,null,null,null)
  SELECT * FROM pmt_overview_stats('768',null,null,null,15,74)
  SELECT * FROM pmt_overview_stats('768',null,null,null,15,227)
******************************************************************/
DROP FUNCTION IF EXISTS pmt_overview_stats(character varying, character varying, date, date);
CREATE OR REPLACE FUNCTION pmt_overview_stats(data_group_ids character varying, classification_ids character varying, 
start_date date, end_date date, boundary_id integer, feature_id integer) RETURNS SETOF pmt_json_result_type AS 
$$
DECLARE
  dg_ids int[];
  valid_dg_ids int[];
  valid_boundary_id integer;
  valid_feature_id integer; 
  spatial_table text;
  filtered_activity_ids int[];
  feature_activity_ids int[];
  activity_count int;
  implmenting_count int;
  total_investment numeric(100,2);
  rec record;
  execute_statement text;
  error_msg text;
BEGIN
  -- validate and process data_group_ids parameter
  IF $1 IS NOT NULL THEN
    dg_ids:= string_to_array($1, ',')::int[];
    -- validate the data groups id
    SELECT INTO valid_dg_ids array_agg(id)::int[] FROM classification WHERE taxonomy_id = 1 AND _active=true AND id = ANY(dg_ids);
  END IF;
  -- validate and process boundary_id parameter
  IF $5 IS NOT NULL THEN
    -- validate the boundary id
    SELECT INTO valid_boundary_id id FROM boundary WHERE _active = true AND id = $5;    
    IF valid_boundary_id IS NULL THEN
      FOR rec IN SELECT row_to_json(j) FROM( SELECT 'provided boundary id is invalid' AS error ) as j LOOP RETURN NEXT rec; END LOOP;
    END IF;
  END IF;
  -- validate and process feature_id parameter
  IF $6 IS NOT NULL THEN
    SELECT INTO spatial_table _spatial_table FROM boundary WHERE id = valid_boundary_id; 
    -- validate the feature id
    EXECUTE 'SELECT id FROM '|| spatial_table ||' WHERE _active = true AND id = ' || $6 INTO valid_feature_id;  
    IF valid_feature_id IS NULL THEN
      FOR rec IN SELECT row_to_json(j) FROM( SELECT 'provided feature id is invalid' AS error ) as j LOOP RETURN NEXT rec; END LOOP;
    END IF;
  END IF;
  
  -- get the filtered activity ids
  SELECT INTO filtered_activity_ids * FROM pmt_filter($1,$2,null,null,null,$3,$4,null);
  -- get the activity ids filtered by the boundary/feature
  IF valid_boundary_id IS NOT NULL AND valid_feature_id IS NOT NULL THEN
    -- get the activity ids for the feature
    IF array_length(valid_dg_ids, 1) > 0 THEN
      SELECT INTO feature_activity_ids array_agg(activity_id) FROM _location_lookup ll WHERE ll.boundary_id = valid_boundary_id AND ll.feature_id = valid_feature_id AND data_group_id = ANY(valid_dg_ids);
    ELSE
      SELECT INTO feature_activity_ids array_agg(activity_id) FROM _location_lookup ll WHERE ll.boundary_id = valid_boundary_id AND ll.feature_id = valid_feature_id;
    END IF;    
  END IF;
  
  -- get the total number of activities
  IF array_length(feature_activity_ids, 1) > 0 THEN
    SELECT INTO activity_count count(id) FROM activity WHERE _active = true AND parent_id IS NULL AND id = ANY(filtered_activity_ids) AND id = ANY(feature_activity_ids);
  ELSE
    SELECT INTO activity_count count(id) FROM activity WHERE _active = true AND parent_id IS NULL AND id = ANY(filtered_activity_ids);
  END IF;	
  
  -- get the total number of implementing organizations
  IF array_length(feature_activity_ids, 1) > 0 THEN
    SELECT INTO implmenting_count count(DISTINCT organization_id) FROM _activity_participants WHERE classification = 'Implementing' AND id = ANY(filtered_activity_ids) AND id = ANY(feature_activity_ids);
  ELSE
    SELECT INTO implmenting_count count(DISTINCT organization_id) FROM _activity_participants WHERE classification = 'Implementing' AND id = ANY(filtered_activity_ids);
  END IF;
  
  -- get total amount of investment
  IF array_length(feature_activity_ids, 1) > 0 THEN
    SELECT INTO total_investment sum(amount) FROM (
	SELECT DISTINCT parent_id, amount FROM _activity_family_finacials 
	WHERE parent_id IN (
		SELECT DISTINCT parent_id FROM _activity_family 
		WHERE (parent_id = ANY(filtered_activity_ids) AND parent_id = ANY(feature_activity_ids))
		OR (child_id = ANY(filtered_activity_ids) AND child_id = ANY(feature_activity_ids))
	) AND amount IS NOT NULL
    ) as f;
  ELSE
    SELECT INTO total_investment sum(amount) FROM (
	SELECT DISTINCT parent_id, amount FROM _activity_family_finacials 
	WHERE parent_id IN (
		SELECT DISTINCT parent_id FROM _activity_family 
		WHERE parent_id = ANY(filtered_activity_ids) OR child_id = ANY(filtered_activity_ids)
	) AND amount IS NOT NULL
    ) as f;
  END IF;
  
  FOR rec IN (SELECT row_to_json(j) FROM(SELECT activity_count as activity_count, implmenting_count as implmenting_count, total_investment as total_investment) j) LOOP  RETURN NEXT rec; END LOOP; 
    RETURN;   	  
    
EXCEPTION WHEN others THEN 
  GET STACKED DIAGNOSTICS error_msg = MESSAGE_TEXT;  
    RAISE NOTICE 'Internal Error - Contact your DBA with the following error message: %', error_msg;

END;$$ LANGUAGE plpgsql;

/******************************************************************
5. Update _activity_taxonomies view to add _field feild
******************************************************************/
DROP VIEW IF EXISTS _activity_taxonomies;
CREATE OR REPLACE VIEW _activity_taxonomies AS 
 SELECT a.id,
    a.parent_id,
    a._title,
    a.data_group_id,
    dg.classification AS data_group,
    at._field,
    tc.taxonomy_id,
    tc.taxonomy,
    tc.classification_id,
    tc.classification
   FROM activity a
     JOIN activity_taxonomy at ON a.id = at.activity_id
     JOIN _taxonomy_classifications tc ON at.classification_id = tc.classification_id
     LEFT JOIN _taxonomy_classifications dg ON a.data_group_id = dg.classification_id
  WHERE a._active = true
  ORDER BY a.id;

/******************************************************************
6. Create materialized view _activity_family_taxonomies to support
taxonomy queries on parent -> child relationships where financials 
are on the parent only and taxonomies are on all levels
******************************************************************/  
DROP MATERIALIZED VIEW IF EXISTS _activity_family_taxonomies;
CREATE MATERIALIZED VIEW _activity_family_taxonomies AS 
  SELECT af.parent_id, af.child_id, af._title, af.data_group_id, m.amount, t.taxonomy_id, t.taxonomy, t.classification_id, t.classification, t._field FROM 
  (SELECT * FROM _activity_family) af
  LEFT JOIN (SELECT id, sum(_amount) as amount FROM _activity_financials  
  WHERE (transaction_type IS NULL OR transaction_type = '' OR transaction_type IN ('Incoming Funds','Commitment'))
  GROUP BY 1) m
  ON af.parent_id = m.id
  LEFT JOIN (SELECT id, taxonomy_id, taxonomy, classification_id, classification, _field FROM _activity_taxonomies) t
  ON af.parent_id = t.id OR af.child_id = t.id;

  CREATE INDEX _activity_family_taxonomies_parent_id ON _activity_family_taxonomies (parent_id);
  CREATE INDEX _activity_family_taxonomies_child_id ON _activity_family_taxonomies (child_id);
  CREATE INDEX _activity_family_taxonomies_amount ON _activity_family_taxonomies (amount);
  CREATE INDEX _activity_family_taxonomies_taxonomy_id ON _activity_family_taxonomies (taxonomy_id);
  CREATE INDEX _activity_family_taxonomies_classification_id ON _activity_family_taxonomies (classification_id);
    
/******************************************************************
7. update pmt_stat_activity_by_tax address errors in calculations
   select * from pmt_stat_activity_by_tax(17,'768',null,null,null,null,null);  
   select * from pmt_stat_activity_by_tax(23,'768',null,null,null,null,null); 
   select * from pmt_stat_activity_by_tax(23,'768',null,null,null,15,74);
   select * from pmt_stat_activity_by_tax(14,'2208',null,null,null,15,74); 
******************************************************************/
DROP FUNCTION IF EXISTS pmt_stat_activity_by_tax(integer, character varying, character varying, date, date, integer, integer, integer);
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
    where_statement:= 'WHERE (parent_id = ANY(ARRAY[' || array_to_string(filtered_activity_ids, ',') || ']) '|| 
				'AND parent_id = ANY(ARRAY[' || array_to_string(feature_activity_ids, ',') || '])) ' || 
				'OR (child_id = ANY(ARRAY[' || array_to_string(filtered_activity_ids, ',') || ']) '|| 
				'AND child_id = ANY(ARRAY[' || array_to_string(feature_activity_ids, ',') || '])) ';
  ELSE
    where_statement:= 'WHERE parent_id = ANY(ARRAY[' || array_to_string(filtered_activity_ids, ',') || ']) ' ||
			'OR child_id = ANY(ARRAY[' || array_to_string(filtered_activity_ids, ',') || ']) ';
  END IF;

  -- prepare the execution statement
  execute_statement:= 'SELECT CASE WHEN classification_id IS NULL THEN NULL ELSE classification_id END, ' ||
			'CASE WHEN classification IS NULL THEN ''Unspecified'' ELSE classification END, ' ||   
			'count(DISTINCT parent_id), sum(amount) FROM ' || 
			'(SELECT DISTINCT classification_id, classification, parent_id, amount '
			'FROM _activity_family_taxonomies WHERE taxonomy_id = ' || valid_taxonomy_id || ' AND parent_id IN ' ||
			'(SELECT DISTINCT parent_id FROM _activity_family ' || where_statement || ')) a GROUP BY 1,2 ORDER BY 4';
	
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

