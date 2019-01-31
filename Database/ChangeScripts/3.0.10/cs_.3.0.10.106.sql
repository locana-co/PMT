/******************************************************************
Change Script 3.0.10.106
1. update function pmt_classifications to address bug in SQL
******************************************************************/
INSERT INTO version(_version, _iteration, _changeset) VALUES (3.0, 10, 106);
-- select * from version order by _iteration desc, _changeset desc;

/******************************************************************
1. update function pmt_classifications to address bug in SQL
  select * from pmt_classifications(14, null, null, false);
  select * from pmt_classifications(79, null, null, false);
  select * from pmt_classifications(79, '2237', null, false);
   select * from pmt_classifications(15, '2237', null, false);
   select * from pmt_classifications(18, null, null, false);
   select * from taxonomy
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_classifications(taxonomy_id integer, data_group_ids character varying, instance_id integer, locations_only boolean) RETURNS SETOF pmt_json_result_type AS
$$
DECLARE
  valid_taxonomy record; 
  dg_ids int[];
  valid_dg_ids int[]; 
  rec record;
  execute_statement text;
  error_msg text;
BEGIN

  -- validate and process taxonomy_id parameter (required)
  IF $1 IS NOT NULL THEN
    -- validate the taxonomy id
    SELECT INTO valid_taxonomy * FROM taxonomy WHERE id = $1 AND _active = true;
    IF valid_taxonomy IS NULL THEN
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
    IF (valid_taxonomy._is_category) THEN
      execute_statement := 'SELECT at.classification_id as id, at.classification as c, at._code as code, at._iati_name as iati, count(DISTINCT at.parent_id) as ct,(SELECT array_to_json(array_agg(row_to_json(t))) FROM ( ' ||
	'	SELECT classification_id as id, classification as c, _code as code, _iati_name as iati, count(DISTINCT parent_id) as ct FROM _activity_taxonomies ' ||
	'	WHERE classification_parent_id = at.classification_id AND data_group_id = ANY(ARRAY[' || array_to_string(valid_dg_ids, ',') || ']) ';
      IF locations_only THEN
        execute_statement := execute_statement || 'AND id IN (SELECT activity_id FROM _location_lookup WHERE data_group_id = ANY(ARRAY[' || array_to_string(valid_dg_ids, ',') || '])) ';
      END IF;
      execute_statement := execute_statement || 'GROUP BY 1,2,3,4 )t ) as children ' ||
	 'FROM _activity_taxonomies at WHERE at.taxonomy_id = ' || $1 || 'AND data_group_id = ANY(ARRAY[' || array_to_string(valid_dg_ids, ',') || ']) ';
      IF locations_only THEN
        execute_statement := execute_statement || 'AND id IN (SELECT activity_id FROM _location_lookup WHERE data_group_id = ANY(ARRAY[' || array_to_string(valid_dg_ids, ',') || '])) ';
      END IF;
    ELSE
      execute_statement := 'SELECT classification_id as id, classification as c, _code as code, _iati_name as iati, count(DISTINCT id) as ct FROM _activity_taxonomies at WHERE at.taxonomy_id = ' || $1 || 
	' AND data_group_id = ANY(ARRAY[' || array_to_string(valid_dg_ids, ',') || ']) ';
      IF locations_only THEN
        execute_statement := execute_statement || 'AND id IN (SELECT activity_id FROM _location_lookup WHERE data_group_id = ANY(ARRAY[' || array_to_string(valid_dg_ids, ',') || '])) ';
      END IF;
    END IF;
    execute_statement := execute_statement || 'GROUP BY 1,2,3,4';
  -- otherwise return all classifications
  ELSE
    IF (valid_taxonomy._is_category) THEN
      execute_statement := 'SELECT classification_id as id, classification as c, _code as code, _iati_name as iati, null as ct,(SELECT array_to_json(array_agg(row_to_json(t))) FROM ( ' ||
	' SELECT classification_id as id, classification as c, _code as code, _iati_name as iati, null as ct FROM _taxonomy_classifications WHERE classification_parent_id = tc.classification_id )t ) as children ' ||
	' FROM _taxonomy_classifications tc  WHERE taxonomy_id = ' || $1;
    ELSE
      execute_statement := 'SELECT classification_id as id, classification as c, _code as code, _iati_name as iati, null as ct FROM _taxonomy_classifications tc WHERE tc.taxonomy_id = ' || $1;
    END IF;
END IF;
		
  RAISE NOTICE 'Execute statement: %', execute_statement;			

  FOR rec IN EXECUTE 'SELECT row_to_json(j) FROM (' || execute_statement || ')j' LOOP  		
	RETURN NEXT rec;
  END LOOP;
 
EXCEPTION WHEN others THEN 
  GET STACKED DIAGNOSTICS error_msg = MESSAGE_TEXT;  
    RAISE NOTICE 'Internal Error - Contact your DBA with the following error message: %', error_msg;
    
END;$$ LANGUAGE plpgsql;
