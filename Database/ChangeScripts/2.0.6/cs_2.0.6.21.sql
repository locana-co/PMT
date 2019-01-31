/******************************************************************
Change Script 2.0.6.21 - Consolidated
1. pmt_auto_complete - function accepting columns for both project
and activity and compiles a list of unique data from those fields
for use in an autocomplete or type ahead function.
******************************************************************/
INSERT INTO config(version, iteration, changeset) VALUES (2.0, 6, 21);
-- SELECT * FROM pmt_version();

CREATE TYPE pmt_auto_complete_result_type AS (response json);

-- SELECT * FROM pmt_auto_complete('title, opportunity_id', 'title');
-- SELECT * FROM pmt_auto_complete('title', 'title');

-- pmt_auto_compete
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
        execute_statement := 'SELECT array_agg(DISTINCT trim(both substring(val, 0, 100))) as autocomplete FROM (SELECT DISTINCT ' || col || '::text as val FROM project WHERE active = true ';
      ELSE
        execute_statement := execute_statement || ' UNION ALL SELECT DISTINCT ' || col || '::text as val  FROM project WHERE active = true  ';
      END IF;      
    END LOOP;
    END IF;
    IF valid_activity_cols IS NOT NULL THEN
    FOREACH col IN ARRAY valid_activity_cols LOOP
      IF execute_statement IS NULL THEN
        execute_statement := 'SELECT array_agg(DISTINCT val) as autocomplete FROM (SELECT  DISTINCT ' || col || '::text as val  FROM activity WHERE active = true ';
      ELSE
        execute_statement := execute_statement || ' UNION ALL SELECT DISTINCT ' || col || '::text as val  FROM activity WHERE active = true ';
      END IF;       
    END LOOP;
    END IF;
    RAISE NOTICE 'Execute statement: %', execute_statement;
    IF execute_statement IS NOT NULL THEN
      FOR rec IN EXECUTE 'SELECT row_to_json(j) FROM (' || execute_statement || ')ac WHERE val IS NOT NULL)j' LOOP     
	RETURN NEXT rec;
      END LOOP;
    END IF;
             
  END IF; -- empty parameters		
END;$$ LANGUAGE plpgsql;


-- SELECT array_agg(DISTINCT trim(both substring(val, 0, 100))) as autocomplete FROM ( 
-- SELECT DISTINCT opportunity_id::text as val FROM project WHERE active = true 
-- UNION ALL 
-- SELECT DISTINCT opportunity_id::text as val FROM activity WHERE active = true ) foo
-- WHERE val IS NOT NULL





