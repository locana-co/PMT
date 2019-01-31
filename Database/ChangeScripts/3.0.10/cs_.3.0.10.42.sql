/******************************************************************
Change Script 3.0.10.42
1. update _activity_financials to include parent id
2. update _activity_taxonomies to include parent id
3. update _activity_participants to include parent id
4. update pmt_overview_stats to remove children from activity and 
financial counts
******************************************************************/
INSERT INTO version(_version, _iteration, _changeset) VALUES (3.0, 10, 42);
-- select * from version order by _iteration desc, _changeset desc;

/******************************************************************
1. update _activity_financials to include parent id
******************************************************************/
DROP VIEW _activity_financials;
CREATE OR REPLACE VIEW _activity_financials AS 
 SELECT DISTINCT a.id,
    a.parent_id,
    a.data_group_id,
    dg.classification AS data_group,
    f.id AS financial_id,
    f._amount,
    c.classification AS currency,
    tt.classification AS transaction_type,
    fic.classification AS finance_type_category,
    fi.classification AS finance_type
   FROM activity a
     LEFT JOIN financial f ON a.id = f.activity_id
     LEFT JOIN ( SELECT _taxonomy_classifications.classification_id,
            _taxonomy_classifications.classification
           FROM _taxonomy_classifications
          WHERE _taxonomy_classifications.taxonomy::text = 'Data Group'::text) dg ON a.data_group_id = dg.classification_id
     LEFT JOIN ( SELECT ft.financial_id,
            c_1.classification
           FROM financial_taxonomy ft
             JOIN ( SELECT _taxonomy_classifications.classification_id,
                    _taxonomy_classifications.classification
                   FROM _taxonomy_classifications
                  WHERE _taxonomy_classifications.taxonomy::text = 'Currency'::text) c_1 ON ft.classification_id = c_1.classification_id) c ON f.id = c.financial_id
     LEFT JOIN ( SELECT ft.financial_id,
            tt_1.classification
           FROM financial_taxonomy ft
             JOIN ( SELECT _taxonomy_classifications.classification_id,
                    _taxonomy_classifications.classification
                   FROM _taxonomy_classifications
                  WHERE _taxonomy_classifications.taxonomy::text = 'Transaction Type'::text) tt_1 ON ft.classification_id = tt_1.classification_id) tt ON f.id = tt.financial_id
     LEFT JOIN ( SELECT ft.financial_id,
            fic_1.classification
           FROM financial_taxonomy ft
             JOIN ( SELECT _taxonomy_classifications.classification_id,
                    _taxonomy_classifications.classification
                   FROM _taxonomy_classifications
                  WHERE _taxonomy_classifications.taxonomy::text = 'Finance Type (category)'::text) fic_1 ON ft.classification_id = fic_1.classification_id) fic ON f.id = fic.financial_id
     LEFT JOIN ( SELECT ft.financial_id,
            fi_1.classification
           FROM financial_taxonomy ft
             JOIN ( SELECT _taxonomy_classifications.classification_id,
                    _taxonomy_classifications.classification
                   FROM _taxonomy_classifications
                  WHERE _taxonomy_classifications.taxonomy::text = 'Finance Type'::text) fi_1 ON ft.classification_id = fi_1.classification_id) fi ON f.id = fi.financial_id
  WHERE a._active = true AND f._active = true
  ORDER BY a.id, f.id;

/******************************************************************
2. update _activity_taxonomies to include parent id
******************************************************************/
DROP VIEW _activity_taxonomies;
CREATE OR REPLACE VIEW _activity_taxonomies AS 
 SELECT a.id,
    a.parent_id,
    a._title,
    a.data_group_id,
    dg.classification AS data_group,
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
3. update _activity_participants to include parent id
******************************************************************/
DROP VIEW _activity_participants;
CREATE OR REPLACE VIEW _activity_participants AS 
 SELECT a.id,
    a.parent_id,
    a._title,
    a.data_group_id,
    dg.classification AS data_group,
    o.id AS organization_id,
    o._name,
    o._label,
    tc.classification_id,
    tc.classification
   FROM activity a
     LEFT JOIN participation pp ON a.id = pp.activity_id
     LEFT JOIN participation_taxonomy ppt ON pp.id = ppt.participation_id
     LEFT JOIN _taxonomy_classifications tc ON ppt.classification_id = tc.classification_id
     LEFT JOIN organization o ON pp.organization_id = o.id
     LEFT JOIN _taxonomy_classifications dg ON a.data_group_id = dg.classification_id
  WHERE a._active = true AND pp._active = true
  ORDER BY a.id;
    
/******************************************************************
4. update pmt_overview_stats to remove children from activity and 
financial counts
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
    SELECT INTO total_investment sum(_amount) FROM _activity_financials WHERE parent_id IS NULL AND id = ANY(filtered_activity_ids) AND id = ANY(feature_activity_ids) 
	AND (transaction_type IS NULL OR transaction_type = '' OR transaction_type IN ('Incoming Funds','Commitment')); 
  ELSE
    SELECT INTO total_investment sum(_amount) FROM _activity_financials WHERE parent_id IS NULL AND id = ANY(filtered_activity_ids) AND (transaction_type IS NULL OR transaction_type = '' OR 
	transaction_type IN ('Incoming Funds','Commitment')); 
  END IF;
  
  FOR rec IN (SELECT row_to_json(j) FROM(SELECT activity_count as activity_count, implmenting_count as implmenting_count, total_investment as total_investment) j) LOOP  RETURN NEXT rec; END LOOP; 
    RETURN;   	  
    
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