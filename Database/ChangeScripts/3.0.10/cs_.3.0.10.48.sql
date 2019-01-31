/******************************************************************
Change Script 3.0.10.48
1. new function pmt_boundary_feature to provide feature information
for a specific boundary feature
******************************************************************/
INSERT INTO version(_version, _iteration, _changeset) VALUES (3.0, 10, 48);
-- select * from version order by _iteration desc, _changeset desc;

/******************************************************************
1. update pmt_boundary_feature 
   select * from pmt_boundary_feature(14, 1); 
   select * from pmt_boundary_feature(13, 1); 
   select * from pmt_boundary_feature(12, 1);
   select * from pmt_boundary_feature(17, 15174); 
   select * from pmt_boundary_feature(15, 74);   
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_boundary_feature(boundary_id integer, feature_id integer) RETURNS SETOF pmt_json_result_type AS
$$
DECLARE
  valid_feature boolean;
  spatial_table text;  
  fields text[];
  field text;
  execute_statement text;    
  rec record;
  error_msg text;
BEGIN
  -- validate and process boundary_id parameter
  IF $1 IS NOT NULL AND $2 IS NOT NULL THEN
    SELECT INTO valid_feature * FROM pmt_validate_boundary_feature($1, $2);
    IF valid_feature THEN
      -- get the spatial table name for boundary 
      SELECT INTO spatial_table _spatial_table FROM boundary WHERE id = $1;
      -- get all name levels for the boundary
      SELECT INTO fields array_agg(column_name::text)::text[] FROM information_schema.columns WHERE table_schema = 'public' AND table_name = spatial_table AND column_name similar to '%_name' ORDER BY 1 ASC;
      -- prepare execution statement
      execute_statement:= 'SELECT ';
      FOREACH field IN ARRAY fields LOOP
       IF field <> '_name' THEN
         execute_statement:= execute_statement || field || ' as ' || quote_ident(substring(field from 0 + length(spatial_table)+1 for length(field))) || ',';
       ELSE
         execute_statement:= execute_statement || field || ' as ' || quote_ident(substring(spatial_table from length(spatial_table) for length(spatial_table)-1) || '_name') || ',';
       END IF;
      END LOOP;     
      -- determine admin level
      execute_statement:= execute_statement || quote_literal(substring(spatial_table from length(spatial_table) for length(spatial_table)-1)) || ' as admin_level';
      -- finish statement
      execute_statement:= execute_statement || ' FROM ' || spatial_table || ' WHERE id = ' || $2;
    ELSE
      FOR rec IN SELECT row_to_json(j) FROM( SELECT 'Must provide valid boundary id and feature id parameter.' AS error ) as j LOOP RETURN NEXT rec; END LOOP;
    END IF;
  ELSE
    FOR rec IN SELECT row_to_json(j) FROM( SELECT 'Must provide valid boundary id and feature id parameter.' AS error ) as j LOOP RETURN NEXT rec; END LOOP;
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