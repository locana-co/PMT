/******************************************************************
Change Script 3.0.10.99
1. update function pmt_activity_family_titles to return requested
classification assignments 
******************************************************************/
INSERT INTO version(_version, _iteration, _changeset) VALUES (3.0, 10, 99);
-- select * from version order by _iteration desc, _changeset desc;

/******************************************************************
1. update function pmt_activity_family_titles to return requested
classification assignments
   select * from pmt_activity_family_titles('2237', '2567,2568');
   select * from pmt_activity_family_titles('2237', '');
   select * from pmt_activity_family_titles('', '');
   select * from _activity_taxonomies
   SELECT * FROM pmt_activity_family_titles('2237','2268');
    SELECT id, _title, array_agg(pt.classification_id)::int[] as c, (SELECT array_to_json(array_agg(row_to_json(children))) FROM ( SELECT id, _title, array_agg(at.classification_id)::int[] as c  FROM activity a LEFT JOIN (SELECT * FROM activity_taxonomy WHERE classification_id = ANY(ARRAY[2268])) at ON a.id = at.activity_id  WHERE _active = true AND parent_id = p.id  GROUP BY 1,2 ) as children ) as children FROM activity p LEFT JOIN (SELECT * FROM activity_taxonomy WHERE classification_id = ANY(ARRAY[2268])) pt ON p.id = pt.activity_id WHERE _active = true AND parent_id IS NULL AND data_group_id = ANY(ARRAY[2237]) GROUP BY 1,2

******************************************************************/
DROP FUNCTION IF EXISTS pmt_activity_family_titles(character varying);
CREATE OR REPLACE FUNCTION pmt_activity_family_titles(data_group_ids character varying, classification_ids character varying) RETURNS SETOF pmt_json_result_type AS
$$
DECLARE 
  dg_ids int[];
  c_ids int[];
  valid_dg_ids int[]; 
  valid_c_ids int[]; 
  execute_statement text; 
  rec record;
  error_msg text;
BEGIN

  -- validate data group ids
  IF $1 IS NOT NULL OR $1 <> '' THEN
    dg_ids:= string_to_array($1, ',')::int[];
    -- validate the filter classification ids
    SELECT INTO valid_dg_ids array_agg(id)::int[] FROM classification WHERE _active = true AND taxonomy_id = 1 AND id = ANY(dg_ids);
  END IF; 

  -- validate classification ids
  IF $2 IS NOT NULL OR $2 <> '' THEN
    c_ids:= string_to_array($2, ',')::int[];
    -- validate the filter classification ids
    SELECT INTO valid_c_ids array_agg(id)::int[] FROM classification WHERE _active = true AND id = ANY(c_ids);
  END IF; 

  IF array_length(valid_c_ids, 1) > 0 THEN
    -- prepare statement
    execute_statement:= 'SELECT id, _title, ' ||
			    'array_agg(pt.classification_id)::int[] as c, ' ||
			    '(SELECT array_to_json(array_agg(row_to_json(children))) FROM ( ' ||
				'SELECT id, _title, array_agg(at.classification_id)::int[] as c  ' ||
				'FROM activity a ' ||
				'LEFT JOIN (SELECT * FROM activity_taxonomy WHERE classification_id = ANY(ARRAY[' || array_to_string(valid_c_ids, ',') || '])) at ' ||
				'ON a.id = at.activity_id  ' ||
				'WHERE _active = true AND parent_id = p.id  ' ||
				 'GROUP BY 1,2 ' ||
			    ') as children ) as children ' ||
			    'FROM activity p ' ||
			    'LEFT JOIN (SELECT * FROM activity_taxonomy WHERE classification_id = ANY(ARRAY[' || array_to_string(valid_c_ids, ',') || '])) pt ' ||
			    'ON p.id = pt.activity_id ';
  ELSE
    -- prepare statement
    execute_statement:= 'SELECT id, _title, ' ||
			    'null::int[] as c, ' ||
			    '(SELECT array_to_json(array_agg(row_to_json(children))) FROM ( ' ||
				'SELECT id, _title, null::int[] as c  ' ||
				'FROM activity a ' ||
				'WHERE _active = true AND parent_id = p.id  ' ||
			    ') as children ) as children ' ||
			    'FROM activity p ';
  END IF;
     
  -- add where statement based on provided valid data groups			    
  IF array_length(valid_dg_ids, 1) > 0 THEN    
    execute_statement:= execute_statement || 'WHERE _active = true AND parent_id IS NULL AND data_group_id = ANY(ARRAY[' || array_to_string(valid_dg_ids, ',') || ']) GROUP BY 1,2';
    
  ELSE
    execute_statement:= execute_statement || 'WHERE _active = true AND parent_id IS NULL GROUP BY 1,2';    
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