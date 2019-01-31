/******************************************************************
Change Script 3.0.10._
1. Removing the exlude list from pmt_taxonomy_search in favor of a dynamic query to remove all child taxonomies. Also added child_id into the returned data to correctly connect child data to the parent.
******************************************************************/
INSERT INTO version(_version, _iteration, _changeset) VALUES (3.0, 10, _);
-- select * from version order by _iteration desc, _changeset desc;

-- Function: pmt_taxonomy_search(integer, text, character varying, integer, integer, boolean)

 DROP FUNCTION pmt_taxonomy_search(integer, text, character varying, integer, integer, boolean);

CREATE OR REPLACE FUNCTION pmt_taxonomy_search(instance_id integer, search_text text, offsetter integer, limiter integer, return_core boolean)
  RETURNS SETOF pmt_json_result_type AS
$BODY$
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
  
  execute_statement:= 'SELECT t.*, (Select tt.id from taxonomy tt where tt.parent_id = t.id) as child_id FROM taxonomy t';
  
  -- return instance specific taxonomies
  IF valid_instance IS NOT NULL THEN
    -- return core
     IF return_core THEN
      execute_statement:= execute_statement || ' WHERE data_group_ids <@ valid_instance.data_group_ids AND _active = true AND parent_id is null ';
    -- do not return core
    ELSE
      execute_statement:= execute_statement || ' WHERE data_group_ids <@ valid_instance.data_group_ids AND _active = true AND _core = false AND parent_id is null ';
    END IF;
  -- return all instance taxonomies
  ELSE
    -- return core
    IF return_core THEN
      execute_statement:= execute_statement || ' WHERE _active = true AND parent_id is null '; 
    -- do not return core
    ELSE
      execute_statement:= execute_statement || ' WHERE _active = true AND _core = false AND parent_id is null ';
    END IF;
  END IF;

  -- filter by search critieria
  IF $2 IS NOT NULL AND $2 <> '' THEN
    execute_statement:= execute_statement || 'AND id IN (SELECT taxonomy_id FROM _taxonomy_classifications WHERE (lower(taxonomy) LIKE ''%' || lower($2) || '%'' ' ||
						' OR lower(classification) LIKE ''%' || lower($2) || '%'')) ';
  END IF;

  execute_statement:= execute_statement || ' ORDER BY id, _name ';

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
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100
  ROWS 1000;
ALTER FUNCTION pmt_taxonomy_search(integer, text, integer, integer, boolean)
  OWNER TO postgres;

  
-- update permissions
GRANT USAGE ON SCHEMA public TO pmt_read;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO pmt_read;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO pmt_read;
GRANT USAGE ON SCHEMA public TO pmt_write;
GRANT SELECT,INSERT ON ALL TABLES IN SCHEMA public TO pmt_write;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO pmt_write;