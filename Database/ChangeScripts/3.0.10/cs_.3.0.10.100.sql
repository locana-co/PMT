/******************************************************************
Change Script 3.0.10.100
1. update pmt_taxonomy_search to remove exclusions
******************************************************************/
INSERT INTO version(_version, _iteration, _changeset) VALUES (3.0, 10, 100);
-- select * from version order by _iteration desc, _changeset desc;

 /******************************************************************
1. update pmt_taxonomy_search to remove exclusions
  select * from pmt_taxonomy_search(1,'org',0,10,true);
  select * from pmt_taxonomy_search(1,'org',0,10,false);
  select * from pmt_taxonomy_search(1,null,0,30,false);
  select * from pmt_taxonomy_search(1,'org',0,10,false);
  select * from pmt_taxonomy_search(1,null,5,5,true); 
******************************************************************/
DROP FUNCTION IF EXISTS pmt_taxonomy_search(instance_id integer, search_text text, exclude_ids character varying, offsetter integer, limiter integer, return_core boolean);
CREATE OR REPLACE FUNCTION pmt_taxonomy_search(instance_id integer, search_text text, offsetter integer, limiter integer, return_core boolean)
  RETURNS SETOF pmt_json_result_type AS $$
DECLARE 
  t_ids integer[];
  valid_taxonomy_ids integer[];
  valid_instance record;
  rec record;
  execute_statement text;
BEGIN 

  -- validate instance id
  IF $1 IS NOT NULL THEN
    SELECT INTO valid_instance * FROM instance WHERE id = $1;
    IF valid_instance IS NULL THEN
      FOR rec IN SELECT row_to_json(j) FROM( SELECT 'Error: provided instance_id is invalid.' AS error ) as j LOOP RETURN NEXT rec; END LOOP;
    END IF;
  END IF;

  -- begin selection statement	
  execute_statement:= 'SELECT t.*, tc.id as child_id, tc._name as child_name FROM taxonomy t LEFT JOIN taxonomy tc ON t.id = tc.parent_id ';
  
  -- return instance specific taxonomies
  IF valid_instance IS NOT NULL THEN
    -- return core
     IF return_core THEN
      execute_statement:= execute_statement || 'WHERE t.data_group_ids <@ valid_instance.data_group_ids AND t._active = true AND t.parent_id is null ';
    -- do not return core
    ELSE
      execute_statement:= execute_statement || 'WHERE t.data_group_ids <@ valid_instance.data_group_ids AND t._active = true AND t._core = false AND t.parent_id is null ';
    END IF;
  -- return all instance taxonomies
  ELSE
    -- return core
    IF return_core THEN
      execute_statement:= execute_statement || 'WHERE t._active = true AND t.parent_id is null '; 
    -- do not return core
    ELSE
      execute_statement:= execute_statement || 'WHERE t._active = true AND t._core = false AND t.parent_id is null ';
    END IF;
  END IF;

  -- filter by search critieria
  IF $2 IS NOT NULL AND $2 <> '' THEN
    execute_statement:= execute_statement || 'AND t.id IN (SELECT taxonomy_id FROM _taxonomy_classifications WHERE (lower(taxonomy) LIKE ''%' || lower($2) || '%'' ' ||
						' OR lower(classification) LIKE ''%' || lower($2) || '%'')) ';
  END IF;

  execute_statement:= execute_statement || ' ORDER BY t.id, t._name ';

  -- offset
  IF $3 IS NOT NULL THEN
    execute_statement:= execute_statement || ' OFFSET ' || $3;
  END IF;

  -- limit
  IF $4 IS NOT NULL THEN
    execute_statement:= execute_statement || ' LIMIT ' || $4;
  END IF;
  
  RAISE NOTICE 'execute_statement: %', execute_statement;	
  
  FOR rec IN EXECUTE 'SELECT row_to_json(j) FROM (' || execute_statement || ')j' LOOP  		
	RETURN NEXT rec;
  END LOOP;

END;
$$ LANGUAGE 'plpgsql'; 

-- update permissions
GRANT USAGE ON SCHEMA public TO pmt_read;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO pmt_read;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO pmt_read;
GRANT USAGE ON SCHEMA public TO pmt_write;
GRANT SELECT,INSERT ON ALL TABLES IN SCHEMA public TO pmt_write;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO pmt_write;