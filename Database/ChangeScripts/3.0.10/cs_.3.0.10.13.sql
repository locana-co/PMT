/******************************************************************
Change Script 3.0.10.13

1. update pmt_global_search for the new data model and application 
requirements
2. update pmt_auto_complete for the new data model and application 
requirements
******************************************************************/
INSERT INTO version(_version, _iteration, _changeset) VALUES (3.0, 10, 13);
-- select * from version order by _iteration desc, _changeset desc;

/******************************************************************
1. update pmt_global_search for the new data model
   select * from pmt_global_search('fish');
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_global_search(search_text text) RETURNS SETOF pmt_json_result_type AS
$$
DECLARE
  rec record;
  col text;
  error_msg text;
  column_array text[];
  execute_statement text;
  dynamic_where text[];
BEGIN
  -- validate search_text, required
  IF ($1 IS NULL OR $1 = '') THEN
    -- must include all parameters, return error
    FOR rec IN (SELECT row_to_json(j) FROM(SELECT 'Error: Must include search_text data parameter.' as message) j) LOOP  RETURN NEXT rec; END LOOP; 
    RETURN;
  END IF;
  
  -- dynamically get list of columns to use from activity table
  SELECT INTO column_array array_agg(column_name::text) FROM information_schema.columns
                               WHERE data_type IN ('character varying', 'text') AND table_name = 'activity';

  FOREACH col IN ARRAY column_array LOOP
    dynamic_where := array_append(dynamic_where, 'lower('|| col ||') LIKE lower(''%' || $1 || '%'')');
    -- RAISE NOTICE 'dynamic where: %', dynamic_where;
  END LOOP;

  execute_statement := 'SELECT id, _title FROM activity WHERE ' ||  '(' || array_to_string(dynamic_where, ' OR ') || ')';

  -- RAISE NOTICE 'Execute statement: %', execute_statement;
  FOR rec IN EXECUTE 'SELECT row_to_json(j) FROM (' || execute_statement || ')j' LOOP
    RETURN NEXT rec;
  END LOOP;

EXCEPTION WHEN others THEN 
  GET STACKED DIAGNOSTICS error_msg = MESSAGE_TEXT;  
    RAISE NOTICE 'Internal Error - Contact your DBA with the following error message: %', error_msg;
    
END;$$ LANGUAGE plpgsql;


/******************************************************************
2. update pmt_auto_complete for the new data model
   select * from pmt_auto_complete('_tags,opportunity_id');
******************************************************************/
-- remove the old function completely
DROP FUNCTION IF EXISTS pmt_auto_complete(character varying, character varying);
-- create the new function (without project)
CREATE OR REPLACE FUNCTION pmt_auto_complete(filter_fields character varying) RETURNS SETOF pmt_json_result_type AS
$$
DECLARE
  select_statements text[];
  requested_project_cols text[];
  valid_project_cols text[];
  requested_activity_cols text[];
  valid_activity_cols text[];
  col text;
  rec record;
  error_msg text;
BEGIN
  --  validate filter_fields parameter, required
  IF ( $1 IS NULL OR $1 = '') THEN    
    FOR rec IN (SELECT row_to_json(j) FROM(SELECT 'Error: Must include a valid column name (text).' as message) j) LOOP  RETURN NEXT rec; END LOOP; 
    RETURN;
  END IF;

  -- parse filter_fields parameter into an array of column names
  requested_activity_cols := string_to_array(replace($1, ' ', ''), ',');
  RAISE NOTICE 'Requested columns: %', requested_activity_cols;

  -- validate column names (must be of type text or character varying)
  SELECT INTO valid_activity_cols array_agg(column_name::text) FROM information_schema.columns 
	WHERE table_name='activity' AND data_type IN ('character varying', 'text') AND column_name = ANY(requested_activity_cols);
  RAISE NOTICE 'Valid columns: %', valid_activity_cols;

  IF array_length(valid_activity_cols, 1) > 0 THEN
    FOREACH col IN ARRAY valid_activity_cols LOOP
      IF col = '_tags' THEN
        select_statements = array_append(select_statements, 'SELECT DISTINCT substring(trim(lower(val)) for 100)::text as val FROM (' ||
			'SELECT DISTINCT regexp_split_to_table(_tags, E''\\,'')::text as val FROM activity ' ||
			'WHERE _active = true AND ' || col ||  ' IS NOT NULL) t ' ||
			'WHERE val IS NOT NULL AND val <> ''''');        
      ELSE
        select_statements = array_append(select_statements,'SELECT DISTINCT replace(substring(trim(' || col ||  ') for 100), ''"'', '''')::text as val ' ||
			'FROM activity WHERE _active = true AND ' || col ||  ' IS NOT NULL');
      END IF;
    END LOOP;

    -- execute the prepared statement
    RAISE NOTICE 'Select statements: %', select_statements;
    FOR rec IN EXECUTE 'SELECT row_to_json(j) FROM ( SELECT array_agg(val) as autocomplete FROM (' || array_to_string(select_statements, ' UNION ALL ') || ')v ORDER BY 1 )j' LOOP
      RETURN NEXT rec;
    END LOOP;
    
  ELSE
    FOR rec IN (SELECT row_to_json(j) FROM(SELECT 'Error: Must include at least one valid column name of data type text or character varying.' as message) j) LOOP  RETURN NEXT rec; END LOOP; 
    RETURN;
  END IF;
  
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
