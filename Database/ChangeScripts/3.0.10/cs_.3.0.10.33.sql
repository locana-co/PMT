/******************************************************************
Change Script 3.0.10.33
1. create new view _activity_financials
2. create function pmt_overview_stats
3. update pmt_stat_activity_by_tax to use new financial view for 
calculations
4. update pmt_partner_pivot to allow region filter
******************************************************************/
INSERT INTO version(_version, _iteration, _changeset) VALUES (3.0, 10, 33);
-- select * from version order by _iteration desc, _changeset desc;

/******************************************************************
1. create new view _activity_financials
******************************************************************/
CREATE OR REPLACE VIEW _activity_financials AS
 SELECT DISTINCT a.id,
    a.data_group_id,
    dg.classification as data_group,
    f.id AS financial_id,
    f._amount,
    c.classification as currency,
    tt.classification as transaction_type,
    fic.classification as finance_type_category,
    fi.classification as finance_type
   FROM activity a
   LEFT JOIN financial f ON a.id = f.activity_id
   LEFT JOIN
     (SELECT classification_id, classification FROM _taxonomy_classifications WHERE taxonomy = 'Data Group') dg
   ON a.data_group_id = dg.classification_id
   LEFT JOIN
     (SELECT ft.financial_id, c.classification
     FROM financial_taxonomy ft    
     JOIN (SELECT classification_id, classification FROM _taxonomy_classifications WHERE taxonomy = 'Currency') c 
     ON ft.classification_id = c.classification_id) c
   ON f.id = c.financial_id
   LEFT JOIN
     (SELECT ft.financial_id, tt.classification
     FROM financial_taxonomy ft    
     JOIN (SELECT classification_id, classification FROM _taxonomy_classifications WHERE taxonomy = 'Transaction Type') tt 
     ON ft.classification_id = tt.classification_id) tt
   ON f.id = tt.financial_id
    LEFT JOIN
     (SELECT ft.financial_id, fic.classification
     FROM financial_taxonomy ft    
     JOIN (SELECT classification_id, classification FROM _taxonomy_classifications WHERE taxonomy = 'Finance Type (category)') fic
     ON ft.classification_id = fic.classification_id) fic
   ON f.id = fic.financial_id
   LEFT JOIN
     (SELECT ft.financial_id, fi.classification
     FROM financial_taxonomy ft    
     JOIN (SELECT classification_id, classification FROM _taxonomy_classifications WHERE taxonomy = 'Finance Type') fi 
     ON ft.classification_id = fi.classification_id) fi
   ON f.id = fi.financial_id
  WHERE a._active = true AND f._active = true
  ORDER BY a.id,f.id;
   
/******************************************************************
2. create function pmt_overview_stats
  SELECT * FROM pmt_overview_stats('768',null,null,null)
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_overview_stats(data_group_ids character varying, classification_ids character varying, start_date date, end_date date) RETURNS SETOF pmt_json_result_type AS 
$$
DECLARE
  filtered_activity_ids int[];
  activity_count int;
  implmenting_count int;
  total_investment numeric(100,2);
  rec record;
  execute_statement text;
  error_msg text;
BEGIN

   -- get the filtered activity ids
  SELECT INTO filtered_activity_ids * FROM pmt_filter($1,$2,null,null,null,$3,$4,null);
  -- get the total number of activities	
  SELECT INTO activity_count count(id) FROM activity WHERE _active = true AND id = ANY(filtered_activity_ids);
  -- get the total number of implementing organizations
  SELECT INTO implmenting_count count(DISTINCT organization_id) FROM _activity_participants WHERE classification = 'Implementing' AND id = ANY(filtered_activity_ids);
  -- get total amount of investment 
  SELECT INTO total_investment sum(_amount) FROM _activity_financials WHERE id = ANY(filtered_activity_ids) AND (transaction_type IS NULL OR transaction_type = '' OR 
	transaction_type IN ('Incoming Funds','Commitment'));
 	  
  FOR rec IN (SELECT row_to_json(j) FROM(SELECT activity_count as activity_count, implmenting_count as implmenting_count, total_investment as total_investment) j) LOOP  RETURN NEXT rec; END LOOP; 
    RETURN;
    
EXCEPTION WHEN others THEN 
  GET STACKED DIAGNOSTICS error_msg = MESSAGE_TEXT;  
    RAISE NOTICE 'Internal Error - Contact your DBA with the following error message: %', error_msg;

END;$$ LANGUAGE plpgsql;

/******************************************************************
3. update pmt_stat_activity_by_tax to use new financial view for 
calculations
   select * from pmt_stat_activity_by_tax(14,'2209,2210','107',null,null); 
   select * from pmt_stat_activity_by_tax(14,'2209,2210',null,null,null);   
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_stat_activity_by_tax(taxonomy_id integer, data_group_ids character varying, classification_ids character varying, start_date date, end_date date) RETURNS SETOF pmt_json_result_type AS
$$
DECLARE
  dg_ids int[];
  valid_dg_ids int[];
  valid_taxonomy_id integer; 
  filtered_activity_ids int[];
  execute_statement text;    
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

  -- get the filtered activity ids
  SELECT INTO filtered_activity_ids * FROM pmt_filter($2,$3,null,null,null,$4,$5,null);

  -- if data groups are the only filter, then use a execution statement that is more performant
  IF ($3 IS NULL OR $3 = '') AND ($4 IS NULL) AND ($5 IS NULL) THEN
    -- validate and process data_group_ids parameter
    IF $2 IS NOT NULL OR $2 <> '' THEN
      dg_ids:= string_to_array($2, ',')::int[];
      -- validate the data groups id
      SELECT INTO valid_dg_ids array_agg(id)::int[] FROM classification c WHERE c.taxonomy_id = 1 AND _active=true AND id = ANY(dg_ids);
      -- if there are no valid data group ids then get all ids
      IF array_length(valid_dg_ids, 1) <= 0 THEN
        SELECT INTO valid_dg_ids array_agg(id)::int[] FROM classification c WHERE c.taxonomy_id = 1 AND _active=true;
      END IF;      
    END IF;
    -- prepare the execution statement
    execute_statement:= 'SELECT CASE WHEN t.classification_id IS NULL THEN NULL ELSE t.classification_id END,  ' ||
				'CASE WHEN t.classification IS NULL THEN ''Unspecified'' ELSE t.classification END, ' ||
				'count(id) as count, sum(_amount) as sum FROM ' ||
				'(SELECT a.id, f._amount, at.classification_id FROM ' ||
				'(SELECT id ' ||
				'FROM activity ' ||
				'WHERE data_group_id = ANY(ARRAY[' || array_to_string(valid_dg_ids, ',') || ']) and _active = true ) a ' ||
				'LEFT JOIN ' ||
				'(SELECT id, _amount ' ||
				'FROM _activity_financials ' ||
				'WHERE id IN (SELECT id FROM activity WHERE data_group_id = ANY(ARRAY[' || array_to_string(valid_dg_ids, ',') || ']) and _active = true) ' ||
				'AND (transaction_type IS NULL OR transaction_type = '''' OR transaction_type IN (''Incoming Funds'',''Commitment''))) f ' ||
				'ON a.id = f.id ' ||
				'LEFT JOIN ' ||
				'(SELECT activity_id, classification_id ' ||
				'FROM activity_taxonomy ' ||
				'WHERE activity_id IN (SELECT id FROM activity WHERE data_group_id = ANY(ARRAY[' || array_to_string(valid_dg_ids, ',') || ']) and _active = true) ' ||
				'AND classification_id IN (SELECT id FROM classification WHERE _active = true AND taxonomy_id = ' || valid_taxonomy_id || ')) at ' ||
				'ON a.id = at.activity_id ' ||
			') as a ' ||
			'LEFT JOIN ( ' ||
				'SELECT taxonomy_id, taxonomy, classification_id, classification  ' ||
				'FROM _taxonomy_classifications ' ||
				'WHERE taxonomy_id = ' || valid_taxonomy_id || ') as t ' ||
			'ON t.classification_id = a.classification_id ' ||
			'GROUP BY 1,2 ' ||
			'ORDER BY 4'; 
  ELSE    
    -- prepare the execution statement
    execute_statement:= 'SELECT CASE WHEN t.classification_id IS NULL THEN NULL ELSE t.classification_id END,  ' ||
				'CASE WHEN t.classification IS NULL THEN ''Unspecified'' ELSE t.classification END, ' ||
				'count(id) as count, sum(_amount) as sum FROM ' ||
				'(SELECT a.id, f._amount, at.classification_id FROM ' ||
				'(SELECT id ' ||
				'FROM activity ' ||
				'WHERE id = ANY(ARRAY[' || array_to_string(filtered_activity_ids, ',') || '])) a ' ||
				'LEFT JOIN ' ||
				'(SELECT id, _amount ' ||
				'FROM _activity_financials ' ||
				'WHERE id = ANY(ARRAY[' || array_to_string(filtered_activity_ids, ',') || ']) ' ||
				'AND (transaction_type IS NULL OR transaction_type = '''' OR transaction_type IN (''Incoming Funds'',''Commitment''))) f ' ||
				'ON a.id = f.id ' ||
				'LEFT JOIN ' ||
				'(SELECT activity_id, classification_id ' ||
				'FROM activity_taxonomy ' ||
				'WHERE activity_id = ANY(ARRAY[' || array_to_string(filtered_activity_ids, ',') || ']) ' ||
				'AND classification_id IN (SELECT id FROM classification WHERE _active = true AND taxonomy_id = ' || valid_taxonomy_id || ')) at ' ||
				'ON a.id = at.activity_id ' ||
			') as a ' ||
			'LEFT JOIN ( ' ||
				'SELECT taxonomy_id, taxonomy, classification_id, classification  ' ||
				'FROM _taxonomy_classifications ' ||
				'WHERE taxonomy_id = ' || valid_taxonomy_id || ') as t ' ||
			'ON t.classification_id = a.classification_id ' ||
			'GROUP BY 1,2 ' ||
			'ORDER BY 4'; 
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
4. update pmt_partner_pivot to allow region filter
   select * from pmt_partner_pivot(15,18,496,'2209,2210',null,null,null,null,null);
   select * from pmt_partner_pivot(23,22,496,'768','244',null,null,null,null);
   select * from pmt_partner_pivot(23,22,497,null,null,null,null,null,null);
   select * from pmt_partner_pivot(22,23,497,'768',null,null,null,15,74);
   select * from pmt_partner_pivot(22,23,497,'768',null,null,null,16,896);
   select * from pmt_partner_pivot(68,69,496,'2237',null,null,null,16,896);
******************************************************************/
DROP FUNCTION IF EXISTS pmt_partner_pivot(integer, integer, integer, character varying, character varying, date, date);
CREATE OR REPLACE FUNCTION pmt_partner_pivot(row_taxonomy_id integer, column_taxonomy_id integer, org_role_id integer, data_group_ids character varying, classification_ids character varying, 
start_date date, end_date date, boundary_id integer, feature_id integer) RETURNS SETOF pmt_json_result_type AS
$$
DECLARE
  valid_row_taxonomy_id integer; 
  valid_column_taxonomy_id integer; 
  valid_role_id integer;
  valid_boundary_id integer;
  valid_feature_id integer; 
  spatial_table text;
  filtered_activity_ids int[];
  feature_activity_ids int[];
  column_headers text[];
  col text;
  col_count int;
  execute_statement text;    
  rec record;
  error_msg text;
BEGIN

  -- validate and process row_taxonomy_id parameter
  IF $1 IS NOT NULL THEN
    -- validate the taxonomy id
    SELECT INTO valid_row_taxonomy_id id FROM taxonomy WHERE id = $1 AND _active = true;
    IF valid_row_taxonomy_id IS NULL THEN
      FOR rec IN SELECT row_to_json(j) FROM( SELECT 'missing valid required parameter' AS error ) as j LOOP RETURN NEXT rec; END LOOP;
    END IF;
  ELSE
    FOR rec IN SELECT row_to_json(j) FROM( SELECT 'missing required parameter' AS error ) as j LOOP RETURN NEXT rec; END LOOP;
  END IF;
  -- validate and process column_taxonomy_id parameter
  IF $2 IS NOT NULL THEN
    -- validate the taxonomy id
    SELECT INTO valid_column_taxonomy_id id FROM taxonomy WHERE id = $2 AND _active = true;
    IF valid_column_taxonomy_id IS NULL THEN
      FOR rec IN SELECT row_to_json(j) FROM( SELECT 'missing valid required parameter' AS error ) as j LOOP RETURN NEXT rec; END LOOP;
    END IF;
  ELSE
    FOR rec IN SELECT row_to_json(j) FROM( SELECT 'missing required parameter' AS error ) as j LOOP RETURN NEXT rec; END LOOP;
  END IF;
  -- validate and process org_role_id parameter
  IF $3 IS NOT NULL THEN
    -- validate the organization role id
    SELECT INTO valid_role_id classification_id FROM _taxonomy_classifications WHERE taxonomy = 'Organisation Role' AND classification_id = $3;    
    IF valid_role_id IS NULL THEN
      FOR rec IN SELECT row_to_json(j) FROM( SELECT 'missing valid required parameter' AS error ) as j LOOP RETURN NEXT rec; END LOOP;
    END IF;
  ELSE
    FOR rec IN SELECT row_to_json(j) FROM( SELECT 'missing required parameter' AS error ) as j LOOP RETURN NEXT rec; END LOOP;
  END IF;
  -- validate and process boundary_id parameter
  IF $8 IS NOT NULL THEN
    -- validate the boundary id
    SELECT INTO valid_boundary_id id FROM boundary WHERE _active = true AND id = $8;    
    IF valid_boundary_id IS NULL THEN
      FOR rec IN SELECT row_to_json(j) FROM( SELECT 'provided boundary id is invalid' AS error ) as j LOOP RETURN NEXT rec; END LOOP;
    END IF;
  END IF;
  -- validate and process feature_id parameter
  IF $9 IS NOT NULL THEN
    SELECT INTO spatial_table _spatial_table FROM boundary WHERE id = valid_boundary_id; 
    -- validate the feature id
    EXECUTE 'SELECT id FROM '|| spatial_table ||' WHERE _active = true AND id = ' || $9 INTO valid_feature_id;  
    IF valid_feature_id IS NULL THEN
      FOR rec IN SELECT row_to_json(j) FROM( SELECT 'provided feature id is invalid' AS error ) as j LOOP RETURN NEXT rec; END LOOP;
    END IF;
  END IF;
  
  -- get the filtered activity ids
  SELECT INTO filtered_activity_ids * FROM pmt_filter($4,$5,null,null,null,$6,$7,null);

  IF valid_boundary_id IS NOT NULL AND valid_feature_id IS NOT NULL THEN
    -- get the activity ids for the feature
    SELECT INTO feature_activity_ids array_agg(activity_id) FROM _location_lookup ll WHERE ll.boundary_id = valid_boundary_id AND ll.feature_id = valid_feature_id;
  END IF;
  
  -- get the column headers
  SELECT INTO column_headers array_agg(quote_literal(classification))::text[] FROM _taxonomy_classifications WHERE taxonomy_id = valid_column_taxonomy_id;
  
  -- prepare the execution statement
  execute_statement:= 'SELECT ''''::text as c1,';
  col_count :=2;
  
  FOREACH col IN ARRAY column_headers LOOP
    execute_statement:= execute_statement || 'to_json(' || col || '::text) as c' || col_count || ','; 
    col_count := col_count + 1;
  END LOOP;

  execute_statement:= execute_statement || ' to_json(''Unspecified''::text) as c' || col_count || ' UNION ALL SELECT * FROM ( SELECT rows.classification::text, ';
  
  FOREACH col IN ARRAY column_headers LOOP
    execute_statement:= execute_statement || 'json_agg(distinct case when cols.classification = ' || col || 
			' then row(org._label, org.organization_id, org._name) end) as ' || quote_ident(col) || ',';
  END LOOP;

  execute_statement:= execute_statement || 'json_agg(distinct case when cols.classification is null then row(org._label, org.organization_id, org._name) end) as "Unspecified" ';

  IF array_length(feature_activity_ids, 1) > 0 THEN
    execute_statement:= execute_statement || 'FROM ( SELECT id FROM activity WHERE id = ANY(ARRAY[' || array_to_string(filtered_activity_ids, ',') || ']) ' || 
				'AND id = ANY(ARRAY[' || array_to_string(feature_activity_ids, ',') || '])) a ';
  ELSE
    execute_statement:= execute_statement || 'FROM ( SELECT id FROM activity WHERE id = ANY(ARRAY[' || array_to_string(filtered_activity_ids, ',') || '])) a ';
  END IF;
			
  execute_statement:= execute_statement	|| 'LEFT JOIN ' ||
			'(SELECT id, _label, _name, organization_id ' ||
			'FROM _activity_participants ' ||
			'WHERE id = ANY(ARRAY[' || array_to_string(filtered_activity_ids, ',') || ']) AND classification_id = ' || valid_role_id || ') as org ' ||
			'ON a.id = org.id ' ||
			'LEFT JOIN ' ||
			'(SELECT id, classification ' ||
			'FROM _activity_taxonomies ' ||
			'WHERE id = ANY(ARRAY[' || array_to_string(filtered_activity_ids, ',') || ']) AND taxonomy_id = ' || valid_column_taxonomy_id || ') as cols ' ||
			'ON a.id = cols.id ' ||
			'LEFT JOIN ' ||
			'(SELECT id, classification ' ||
			'FROM _activity_taxonomies ' ||
			'WHERE id = ANY(ARRAY[' || array_to_string(filtered_activity_ids, ',') || ']) AND taxonomy_id = ' || valid_row_taxonomy_id || ') as rows ' ||
			'ON a.id = rows.id ' ||
			'GROUP BY 1 ' ||
			') as selection';
  
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