/******************************************************************
Change Script 3.0.10.36
1. update pmt_overview_stats to allow feature/boundary filters 
******************************************************************/
INSERT INTO version(_version, _iteration, _changeset) VALUES (3.0, 10, 36);
-- select * from version order by _iteration desc, _changeset desc;

/******************************************************************
1. update pmt_overview_stats to allow feature/boundary filters
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
    SELECT INTO activity_count count(id) FROM activity WHERE _active = true AND id = ANY(filtered_activity_ids) AND id = ANY(feature_activity_ids);
  ELSE
    SELECT INTO activity_count count(id) FROM activity WHERE _active = true AND id = ANY(filtered_activity_ids);
  END IF;	
  
  -- get the total number of implementing organizations
  IF array_length(feature_activity_ids, 1) > 0 THEN
    SELECT INTO implmenting_count count(DISTINCT organization_id) FROM _activity_participants WHERE classification = 'Implementing' AND id = ANY(filtered_activity_ids) AND id = ANY(feature_activity_ids);
  ELSE
    SELECT INTO implmenting_count count(DISTINCT organization_id) FROM _activity_participants WHERE classification = 'Implementing' AND id = ANY(filtered_activity_ids);
  END IF;
  
  -- get total amount of investment
  IF array_length(feature_activity_ids, 1) > 0 THEN
    SELECT INTO total_investment sum(_amount) FROM _activity_financials WHERE id = ANY(filtered_activity_ids) AND id = ANY(feature_activity_ids) 
	AND (transaction_type IS NULL OR transaction_type = '' OR transaction_type IN ('Incoming Funds','Commitment')); 
  ELSE
    SELECT INTO total_investment sum(_amount) FROM _activity_financials WHERE id = ANY(filtered_activity_ids) AND (transaction_type IS NULL OR transaction_type = '' OR 
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