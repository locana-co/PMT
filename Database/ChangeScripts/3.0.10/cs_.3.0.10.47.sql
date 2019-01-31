/******************************************************************
Change Script 3.0.10.47
1. update pmt_activities to add start and end dates
******************************************************************/
INSERT INTO version(_version, _iteration, _changeset) VALUES (3.0, 10, 47);
-- select * from version order by _iteration desc, _changeset desc;

/******************************************************************
1. update pmt_activities 
   select * from pmt_activities('2267',null,null,null,null,null,null,null); 
   select * from pmt_activities('769',null,null,null,null,null,null,null); 
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_activities(data_group_ids character varying, classification_ids character varying, org_ids character varying,
imp_org_ids character varying, fund_org_ids character varying, start_date date, end_date date, unassigned_taxonomy_ids character varying) RETURNS SETOF pmt_json_result_type AS
$$
DECLARE
  filtered_activity_ids int[];
  execute_statement text;    
  rec record;
  error_msg text;
BEGIN
  -- get the filtered activity ids
  SELECT INTO filtered_activity_ids * FROM pmt_filter($1,$2,$3,$4,$5,$6,$7,$8);

   execute_statement:= 'SELECT a.id, parent_id, data_group_id, (SELECT _name FROM classification WHERE id = data_group_id) as data_group, _title, sum(_amount) as amount, classification as currency, _code as currency_code, a._start_date, a._end_date, array_agg( o._name) as providers' ||
		' FROM (SELECT * FROM activity WHERE _active = true AND id = ANY(ARRAY[' || array_to_string(filtered_activity_ids, ',') || '])) a' ||
  		' LEFT JOIN (SELECT * FROM financial WHERE _active = true) f ' ||
  		' ON a.id = f.activity_id ' ||
  		' LEFT JOIN ( select financial_id, classification, _code ' ||
				' FROM financial_taxonomy ft ' ||
				' JOIN _taxonomy_classifications tc ' ||
				' on ft.classification_id = tc.classification_id ' ||
				' where tc.taxonomy = ''Currency'') as currency ' ||
				' ON currency.financial_id = f.id ' ||
        'LEFT JOIN organization o ON (o.id = provider_id)'
  		' GROUP BY 1,2,3,4,5,7,8,9,10 ';


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