/******************************************************************
Change Script 2.0.8.2 - consolidated.
1. pmt_auto_complete - split out tags (comma dilemited) if requested.
******************************************************************/
INSERT INTO config(version, iteration, changeset) VALUES (2.0, 8, 2);
-- select * from config order by changeset desc;

--select * from pmt_auto_complete('tags','tags');

/******************************************************************
  pmt_auto_complete
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_auto_complete(project_fields character varying, activity_fields character varying)
RETURNS SETOF pmt_auto_complete_result_type AS 
$$
DECLARE
  execute_statement text;
  requested_project_cols text[];
  valid_project_cols text[];
  requested_activity_cols text[];
  valid_activity_cols text[];
  col text;
  rec record;
BEGIN
  IF ( $1 IS NULL OR $1 = '') AND ( $2 IS NULL OR $2 = '')  THEN
   --  no parameters, return nothing
  ELSE
    -- validate parameters	
    IF ($1 IS NOT NULL AND $1 <> '') THEN
      -- parse input to array
      requested_project_cols := string_to_array(replace($1, ' ', ''), ',');      
      RAISE NOTICE 'Requested columns: %', requested_project_cols;
      -- validate column names
      SELECT INTO valid_project_cols array_agg(column_name::text) FROM information_schema.columns WHERE table_name='project' and column_name = ANY(requested_project_cols);
      RAISE NOTICE 'Valid columns: %', valid_project_cols;    
    END IF;
    IF ($2 IS NOT NULL AND $2 <> '') THEN
      -- parse input to array
      requested_activity_cols := string_to_array(replace($2, ' ', ''), ',');      
      RAISE NOTICE 'Requested columns: %', requested_activity_cols;
      -- validate column names
      SELECT INTO valid_activity_cols array_agg(column_name::text) FROM information_schema.columns WHERE table_name='activity' and column_name = ANY(requested_activity_cols);
      RAISE NOTICE 'Valid columns: %', valid_activity_cols;    
    END IF;

    IF valid_project_cols IS NOT NULL THEN
    FOREACH col IN ARRAY valid_project_cols LOOP
      IF execute_statement IS NULL THEN
        IF col = 'tags'::text THEN
          execute_statement := 'SELECT array_agg(DISTINCT trim(both substring(val, 0, 100))) as autocomplete FROM (SELECT DISTINCT regexp_split_to_table(' || col || ', E''\\,'')::text as val FROM project WHERE active = true ';
        ELSE
          execute_statement := 'SELECT array_agg(DISTINCT trim(both substring(val, 0, 100))) as autocomplete FROM (SELECT DISTINCT regexp_split_to_table(' || col || ', E''\\,'')::text as val FROM project WHERE active = true ';
        END IF;        
      ELSE
        IF col = 'tags'::text THEN
          execute_statement := execute_statement || ' UNION ALL SELECT DISTINCT regexp_split_to_table(' || col || ', E''\\,'')::text as val  FROM project WHERE active = true  ';
        ELSE
          execute_statement := execute_statement || ' UNION ALL SELECT DISTINCT regexp_split_to_table(' || col || ', E''\\,'')::text as val  FROM project WHERE active = true  ';
        END IF;        
      END IF;      
    END LOOP;
    END IF;
    IF valid_activity_cols IS NOT NULL THEN
    FOREACH col IN ARRAY valid_activity_cols LOOP
      IF execute_statement IS NULL THEN
        IF col = 'tags'::text THEN
          execute_statement := 'SELECT array_agg(DISTINCT trim(val)) as autocomplete FROM (SELECT  DISTINCT regexp_split_to_table(' || col || ', E''\\,'')::text as val  FROM activity WHERE active = true ';
        ELSE
          execute_statement := 'SELECT array_agg(DISTINCT trim(val)) as autocomplete FROM (SELECT  DISTINCT regexp_split_to_table(' || col || ', E''\\,'')::text as val  FROM activity WHERE active = true ';
        END IF;        
      ELSE
        IF col = 'tags'::text THEN
          execute_statement := execute_statement || ' UNION ALL SELECT DISTINCT regexp_split_to_table(' || col || ', E''\\,'')::text as val  FROM activity WHERE active = true ';
        ELSE
          execute_statement := execute_statement || ' UNION ALL SELECT DISTINCT regexp_split_to_table(' || col || ', E''\\,'')::text as val  FROM activity WHERE active = true ';
        END IF;        
      END IF;       
    END LOOP;
    END IF;
    RAISE NOTICE 'Execute statement: %', execute_statement;
    IF execute_statement IS NOT NULL THEN
      FOR rec IN EXECUTE 'SELECT row_to_json(j) FROM (' || execute_statement || ')ac WHERE val IS NOT NULL AND val <> '''')j' LOOP     
	RETURN NEXT rec;
      END LOOP;
    END IF;
             
  END IF; -- empty parameters		
END;$$ LANGUAGE plpgsql;

-- update permissions
GRANT USAGE ON SCHEMA public TO pmt_read;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO pmt_read;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO pmt_read;
GRANT USAGE ON SCHEMA public TO pmt_write;
GRANT SELECT,INSERT ON ALL TABLES IN SCHEMA public TO pmt_write;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO pmt_write;