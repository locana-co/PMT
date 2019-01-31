/******************************************************************
Change Script 3.0.10.17

1. update pmt_activity_count to include boundary id so counts 
properly reflect map
******************************************************************/
INSERT INTO version(_version, _iteration, _changeset) VALUES (3.0, 10, 17);
-- select * from version order by _iteration desc, _changeset desc;

 /******************************************************************
1. update pmt_activity_count to include boundary id so counts properly 
reflect map
  SELECT * FROM pmt_activity_count('768','2212,831','1681','','1/1/2012','12/31/2018',null); --bmgf
  SELECT * FROM pmt_activity_count('768',null,null,null,null,null,null); --bmgf
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_activity_count(data_group_ids character varying, classification_ids character varying, 
imp_org_ids character varying, fund_org_ids character varying, start_date date, end_date date, unassigned_taxonomy_ids character varying)
RETURNS SETOF pmt_json_result_type AS 
$$
DECLARE
  execute_statement text;
  filtered_activity_ids int[]; 
  rec record;
  error_msg text;
BEGIN  

  -- get the filtered activity ids
  SELECT INTO filtered_activity_ids * FROM pmt_filter($1,$2,null,$3,$4,$5,$6,$7);

  -- prepare the execution statement
  execute_statement:= 'SELECT CASE WHEN count(distinct location_id) > 0 THEN count(distinct activity_id) ELSE 0 END as ct FROM _filter_boundaries ' ||
		'WHERE activity_id = ANY(ARRAY[' || array_to_string(filtered_activity_ids, ',') || ']) AND boundary_id = (SELECT id FROM boundary WHERE _name = ''Continent'')';

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