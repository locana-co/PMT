/******************************************************************
Change Script 3.0.10.94
1. update pmt_activities to address errors in financial counts
******************************************************************/
INSERT INTO version(_version, _iteration, _changeset) VALUES (3.0, 10, 94);
-- select * from version order by _iteration desc, _changeset desc;

/******************************************************************
1. update pmt_activities to address errors in financial counts
   select * from pmt_activities('2237','1122',null,null,null,null,null,null,null,'[{"b":12,"ids":[9]},{"b":13,"ids":[52,8,3,9,22,34,24,21,36,50,25,69,31,49,53,12,68,56]},{"b":14,"ids":[659,543,568,595,570,643,648,644,645,646,647,590,548,592,600,632,633,630,597,631,598,666,554,674,624,664,639,640,606,559,555,556,553,557,594,652,552,596,593,584,627,585,628,587,651,677,678,605,599,660,571,671,546,670,672,545,663,673,668,669,560,561,564,566,638,626,661,567,625,637,665,667,662,563,562,655,572,565,656,657,658,550,569,547,602,676,601,603,617,618,621,622,623,582,634,580,615,620,589,588,613,612,616,614,586,575,583,579,653,654,551,577,574,573,619,578,635,636,581,607,608,609,610,611,576,629,641,642,650,604,558,591]}]'); 
   select * from pmt_activities('2237',null,null,null,null,null,null,null,'29566',null);
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_activities(data_group_ids character varying, classification_ids character varying, org_ids character varying,
imp_org_ids character varying, fund_org_ids character varying, start_date date, end_date date, unassigned_taxonomy_ids character varying, 
activity_ids character varying, boundary_filter json) RETURNS SETOF pmt_json_result_type AS
$$
DECLARE
  filtered_activity_ids int[];
  a_ids int[];
  valid_activity_ids int[];
  boundary_json json;
  boundary_filters text[];
  boundary_statement text;
  boundary_activity_ids int[];
  execute_statement text; 
  json record;   
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
 
  -- get the filtered activity ids by boundary
  IF ($10 IS NOT NULL) THEN
    RAISE NOTICE 'json was not null';      
    FOR boundary_json IN (SELECT * FROM json_array_elements($10)) LOOP
      FOR json IN (SELECT * FROM json_each_text(boundary_json)) LOOP
        -- RAISE NOTICE 'JSON key/value: %', lower(json.key) || ':' || json.value;          
        CASE json.key::text 
          WHEN 'b' THEN
            boundary_statement := ' (ll.boundary_id = ' || json.value::int;
          WHEN 'ids' THEN
            boundary_statement := boundary_statement || ' AND ll.feature_id = ANY(ARRAY' || json.value || ')) ';
            boundary_filters := array_append(boundary_filters, boundary_statement);
          ELSE
        END CASE;
      END LOOP;
    END LOOP;
    IF array_length(boundary_filters, 1) > 0 THEN
      EXECUTE 'SELECT array_agg(activity_id)::int[] FROM _location_lookup ll WHERE' ||  array_to_string(boundary_filters, 'OR') INTO boundary_activity_ids;
    END IF;
  END IF;
  
  execute_statement:= 'SELECT DISTINCT a.id, parent_id as pid, data_group_id as dgid, (SELECT _name FROM classification WHERE id = data_group_id) as dg, ' ||
		'_title as t, _amount as a, a._start_date as sd, a._end_date as ed, array_agg( o._name) as f ' ||
		'FROM ( SELECT DISTINCT af.parent_id as id, null as parent_id, af.data_group_id, af._title, a._start_date, a._end_date ' ||
			'FROM ( ' ||
				'SELECT * FROM _activity_family ' ||
				'WHERE (child_id = ANY(ARRAY[' || array_to_string(filtered_activity_ids, ',') || ']) OR parent_id = ANY(ARRAY[' || array_to_string(filtered_activity_ids, ',') || ']))';

  -- add filter for activities in list
  IF array_length(valid_activity_ids, 1) > 0 THEN
    execute_statement:= execute_statement || 'AND (child_id = ANY(ARRAY[' || array_to_string(valid_activity_ids, ',') || ']) OR parent_id = ANY(ARRAY[' || array_to_string(valid_activity_ids, ',') || '])) ';
  END IF;

  -- add filter for boundary		
  IF array_length(boundary_activity_ids, 1) > 0 THEN
    execute_statement:= execute_statement || 'AND (child_id = ANY(ARRAY[' || array_to_string(boundary_activity_ids, ',') || ']) OR parent_id = ANY(ARRAY[' || array_to_string(boundary_activity_ids, ',') || '])) ';
  END IF;
  	RAISE NOTICE 'Execute statement: %', execute_statement;	
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
		'GROUP BY 1,2,3,4,5,6,7,8 ';


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