/******************************************************************
Change Script 3.0.10.24
1. create function pmt_boundary_filter
******************************************************************/
INSERT INTO version(_version, _iteration, _changeset) VALUES (3.0, 10, 24);
-- select * from version order by _iteration desc, _changeset desc;

/******************************************************************
1. create function pmt_boundary_filter
   select * from pmt_boundary_filter('gadm1','_gadm0_name','Ethiopia,Mali');   
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_boundary_filter(boundary_table character varying, query_field character varying, query character varying) RETURNS SETOF pmt_json_result_type AS
$$
DECLARE
  params text[];
  execute_statement text;    
  rec record;
  error_msg text;
BEGIN
  params:= string_to_array($3, ',')::text[];
  -- ensure all parameters are provided
  IF $1 IS NULL OR $2 IS NULL OR $3 IS NULL THEN
    FOR rec IN SELECT row_to_json(j) FROM( SELECT 'missing valid required parameter' AS error ) as j LOOP RETURN NEXT rec; END LOOP;
  END IF;

  -- prepare the execution statement
  execute_statement:= 'SELECT id, _name FROM ' || $1 || ' WHERE ' || $2 || ' = ANY(ARRAY[''' || array_to_string(params, ''',''') || '''])'; 
  
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