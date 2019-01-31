/******************************************************************
Change Script 3.0.10.52
1. update pmt_activities to add activity ids filter
******************************************************************/
INSERT INTO version(_version, _iteration, _changeset) VALUES (3.0, 10, 52);
-- select * from version order by _iteration desc, _changeset desc;

/******************************************************************
1. update pmt_activities 
   select * from pmt_activities('2267',null,null,null,null,null,null,null,null); 
   select * from pmt_activities('769',null,null,null,null,null,null,null,'22970,22971,22972'); 
******************************************************************/
DROP FUNCTION IF EXISTS pmt_activities(character varying,character varying, character varying, character varying, character varying, date, date, character varying);
CREATE OR REPLACE FUNCTION pmt_activities(data_group_ids character varying, classification_ids character varying, org_ids character varying,
imp_org_ids character varying, fund_org_ids character varying, start_date date, end_date date, unassigned_taxonomy_ids character varying, activity_ids character varying) RETURNS SETOF pmt_json_result_type AS
$$
DECLARE
  filtered_activity_ids int[];
  a_ids int[];
  valid_activity_ids int[];
  execute_statement text;    
  rec record;
  error_msg text;
BEGIN
  -- get the filtered activity ids
  SELECT INTO filtered_activity_ids * FROM pmt_filter($1,$2,$3,$4,$5,$6,$7,$8);

  -- get the list of activity ids
  IF ($9 IS NOT NULL OR $9 <> '' ) THEN
    a_ids:= string_to_array($9, ',')::int[];
    SELECT INTO valid_activity_ids array_agg(id) FROM activity WHERE _active = true AND id = ANY(a_ids);
  END IF;
  
  execute_statement:= 'SELECT a.id, parent_id, data_group_id, (SELECT _name FROM classification WHERE id = data_group_id) as data_group, _title, sum(_amount) as amount, classification as currency, _code as currency_code, a._start_date, a._end_date, array_agg( o._name) as providers' ||
		' FROM (SELECT * FROM activity WHERE _active = true AND id = ANY(ARRAY[' || array_to_string(filtered_activity_ids, ',') || ']) ';
  -- add filter for activities in list
  IF array_length(valid_activity_ids, 1) > 0 THEN
    execute_statement:= execute_statement || 'AND id = ANY(ARRAY[' || array_to_string(valid_activity_ids, ',') || ']) ';
  END IF;
  		
  execute_statement:= execute_statement || ') a' ||
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