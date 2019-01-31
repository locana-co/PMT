/******************************************************************
Change Script 3.0.10.74
1. update function pmt_classifications to accept instance_id.
******************************************************************/
INSERT INTO version(_version, _iteration, _changeset) VALUES (3.0, 10, 74);
-- select * from version order by _iteration desc, _changeset desc;

/******************************************************************
1. Update function pmt_classifications accept instance_id
  select * from pmt_classifications(15, '2237', null, true);
  select * from pmt_classifications(15, null, 1, true);
  select * from pmt_classifications(18, '1068', false);
  select id, _name from classification where taxonomy_id = 1
  select id, _name from taxonomy order by 2
******************************************************************/
DROP FUNCTION IF EXISTS pmt_classifications(integer, character varying, boolean);
CREATE OR REPLACE FUNCTION pmt_classifications(taxonomy_id integer, data_group_ids character varying, instance_id integer, locations_only boolean) RETURNS SETOF pmt_json_result_type AS
$$
DECLARE
  valid_taxonomy_id integer; 
  dg_ids int[];
  valid_dg_ids int[]; 
  rec record;
  execute_statement text;
  error_msg text;
BEGIN

  -- validate and process taxonomy_id parameter (required)
  IF $1 IS NOT NULL THEN
    -- validate the taxonomy id
    SELECT INTO valid_taxonomy_id id FROM taxonomy WHERE id = $1 AND _active = true;
    IF valid_taxonomy_id IS NULL THEN
      FOR rec IN SELECT row_to_json(j) FROM( SELECT 'missing valid required parameter' AS error ) as j LOOP RETURN NEXT rec; END LOOP;
    END IF;
  ELSE
    FOR rec IN SELECT row_to_json(j) FROM( SELECT 'missing required parameter' AS error ) as j LOOP RETURN NEXT rec; END LOOP;
  END IF;
  -- validate and process data_group_ids parameter
  IF $2 IS NOT NULL THEN
    dg_ids:= string_to_array($2, ',')::int[];
    -- validate the data groups id
    SELECT INTO valid_dg_ids array_agg(id)::int[] FROM classification c WHERE c.taxonomy_id = 1 AND _active=true AND id = ANY(dg_ids);
  ELSE
    IF $3 IS NOT NULL THEN
      SELECT INTO valid_dg_ids instance.data_group_ids FROM instance WHERE id = $3;
    END IF;
  END IF;

  -- if data groups are given return in-use classifications only
  IF array_length(valid_dg_ids, 1) > 0 THEN
    execute_statement := 'SELECT classification_id as id, classification as c, count(DISTINCT id) as ct FROM _activity_taxonomies at WHERE at.taxonomy_id = ' || $1 || 
	' AND data_group_id = ANY(ARRAY[' || array_to_string(valid_dg_ids, ',') || ']) ';
    IF locations_only THEN
      execute_statement := execute_statement || 'AND id IN (SELECT activity_id FROM _location_lookup WHERE data_group_id = ANY(ARRAY[' || array_to_string(valid_dg_ids, ',') || '])) ';
    END IF;
    execute_statement := execute_statement || 'GROUP BY 1,2';
  -- otherwise return all classifications
  ELSE
    execute_statement := 'SELECT classification_id as id, classification as c, null as ct FROM _taxonomy_classifications tc WHERE tc.taxonomy_id = ' || $1;
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