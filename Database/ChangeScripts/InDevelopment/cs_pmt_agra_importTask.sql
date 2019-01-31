/******************************************************************
Change Script 3.0.10._
1. update pmt_activities_all function to return _active value


******************************************************************/

 /******************************************************************
1. update pmt_activities_all function to return _active value
   select * from pmt_activities_all('769', false); -- all activities active true & false
   select * from pmt_activities_all('769', true); -- active activities only
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_activities_all(data_group_ids character varying, only_active boolean) RETURNS SETOF pmt_json_result_type AS
$$
DECLARE
  dg_ids int[];
  data_group_ids int[];
  execute_statement text; 
  json record;   
  rec record;
  error_msg text;
BEGIN
  -- validate data group ids
  IF $1 IS NOT NULL THEN
    dg_ids:= string_to_array($1, ',')::int[];
    SELECT INTO data_group_ids array_agg(id) FROM classification WHERE taxonomy_id = 1 AND id = ANY(dg_ids);
  END IF;
  
  execute_statement:= 'SELECT DISTINCT a.id, parent_id as pid, data_group_id as dgid, _iati_identifier as iati, a._active as active, (SELECT _name FROM classification WHERE id = data_group_id) as dg, ' ||
		'_title as t, _amount as a, a._start_date as sd, a._end_date as ed, array_agg( o._name) as f ' ||
		'FROM ( SELECT DISTINCT af.parent_id as id, null as parent_id, _iati_identifier, _active, af.data_group_id, af._title, a._start_date, a._end_date ' ||
			'FROM ( ' || 
				'SELECT p.id AS parent_id, c.id AS child_id, p._title, p.data_group_id ' ||
				'FROM ( SELECT activity.id, activity._title, activity.data_group_id FROM activity ' ||
				'WHERE activity.parent_id IS NULL ';
				IF data_group_ids IS NOT NULL THEN
					execute_statement:= execute_statement || 'AND activity.data_group_id = ANY(ARRAY[' || array_to_string(data_group_ids, ',')  || ']) ';
				END IF;
				IF only_active THEN
					execute_statement:= execute_statement || 'AND activity._active = true ';
				END IF;

				
				
  execute_statement:= execute_statement || ') p LEFT JOIN ( SELECT activity.id, activity.parent_id FROM activity WHERE activity.parent_id IS NOT NULL ';
			        IF data_group_ids IS NOT NULL THEN
					execute_statement:= execute_statement || 'AND activity.data_group_id = ANY(ARRAY[' || array_to_string(data_group_ids, ',')  || ']) ';
				END IF;
				IF only_active THEN
					execute_statement:= execute_statement || 'AND activity._active = true ';
				END IF;

  execute_statement:= execute_statement || ') c ON p.id = c.parent_id ';

					
  execute_statement:= execute_statement || ') af JOIN activity a ON af.parent_id = a.id ) a' ||
  		' LEFT JOIN ( ' ||
			'SELECT DISTINCT f.activity_id, sum(_amount) as _amount FROM ( ' ||
			'SELECT id, activity_id, _amount, provider_id FROM financial WHERE _active = true) f ' ||
			' LEFT JOIN ( select financial_id, classification, _code ' ||
				' FROM financial_taxonomy ft ' ||
				' JOIN _taxonomy_classifications tc ' ||
				' on ft.classification_id = tc.classification_id ' ||
				' where tc.taxonomy = ''Transaction Type''' || 
				'OR classification IS NULL OR classification = ''Incoming Funds'' OR classification = ''Commitment'' ) as ft ' ||
		'ON ft.financial_id = f.id GROUP BY 1 ) f ON a.id = f.activity_id ' ||
		'LEFT JOIN (SELECT id, _name FROM _activity_participants WHERE classification = ''Funding'') o ON a.id = o.id ' ||
		'GROUP BY 1,2,3,4,5,6,7,8,9,10 ';


  RAISE NOTICE 'Execute statement: %', execute_statement;

  FOR rec IN EXECUTE 'SELECT row_to_json(j) FROM (' || execute_statement || ')j' LOOP
	RETURN NEXT rec;
  END LOOP;

EXCEPTION WHEN others THEN
  GET STACKED DIAGNOSTICS error_msg = MESSAGE_TEXT;
    RAISE NOTICE 'Internal Error - Contact your DBA with the following error message: %', error_msg;

END;$$ LANGUAGE plpgsql;
 