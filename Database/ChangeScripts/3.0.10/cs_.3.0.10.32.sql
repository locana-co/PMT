/******************************************************************
Change Script 3.0.10.32
1. update pmt_activities to add currency code & classification
2. update pmt_activities_by_polygon to allow for filtering
******************************************************************/
INSERT INTO version(_version, _iteration, _changeset) VALUES (3.0, 10, 32);
-- select * from version order by _iteration desc, _changeset desc;

/******************************************************************
1. update pmt_activities 
   select * from pmt_activities('2267',null,null,null,null,null,null,null); 
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

   execute_statement:= 'SELECT a.id, parent_id, data_group_id, (SELECT _name FROM classification WHERE id = data_group_id) as data_group, _title, sum(_amount) as amount, classification as currency, _code as currency_code' ||
		' FROM (SELECT * FROM activity WHERE _active = true AND id = ANY(ARRAY[' || array_to_string(filtered_activity_ids, ',') || '])) a' ||
  		' LEFT JOIN (SELECT * FROM financial WHERE _active = true) f ' ||
  		' ON a.id = f.activity_id ' ||
  		' LEFT JOIN ( select financial_id, classification, _code ' ||
				' FROM financial_taxonomy ft ' ||
				' JOIN _taxonomy_classifications tc ' ||
				' on ft.classification_id = tc.classification_id ' ||
				' where tc.taxonomy = ''Currency'') as currency ' ||
				' ON currency.financial_id = f.id ' ||
  		' GROUP BY 1,2,3,4,5,7,8 ';

  RAISE NOTICE 'Execute statement: %', execute_statement;

  FOR rec IN EXECUTE 'SELECT row_to_json(j) FROM (' || execute_statement || ')j' LOOP
	RETURN NEXT rec;
  END LOOP;

EXCEPTION WHEN others THEN
  GET STACKED DIAGNOSTICS error_msg = MESSAGE_TEXT;
    RAISE NOTICE 'Internal Error - Contact your DBA with the following error message: %', error_msg;

END;$$ LANGUAGE plpgsql;


/******************************************************************
2. update pmt_activities_by_polygon
  select * from pmt_activities_by_polygon('POLYGON ((38.25223105686701 8.14760225670679, 38.25084770772398 8.133556877151992, 38.24675082162665 8.120051253656747, 38.24009783961018 8.107604399757935, 38.23114443204243 8.09669464107061, 38.22023467335511 8.087741233502863, 38.20778781945629 8.081088251486396, 38.194282195961044 8.076991365389063, 38.18023681640625 8.075608016246028, 38.166191436851456 8.076991365389063, 38.15268581335621 8.081088251486396, 38.14023895945739 8.087741233502863, 38.12932920077007 8.09669464107061, 38.12037579320232 8.107604399757935, 38.11372281118585 8.120051253656747, 38.10962592508852 8.133556877151992, 38.10824257594549 8.14760225670679, 38.10962592508852 8.161647636261588, 38.11372281118585 8.175153259756833, 38.12037579320232 8.187600113655646, 38.12932920077007 8.19850987234297, 38.14023895945739 8.207463279910717, 38.15268581335621 8.214116261927185, 38.166191436851456 8.218213148024518, 38.18023681640625 8.219596497167553, 38.194282195961044 8.218213148024518, 38.20778781945629 8.214116261927185, 38.22023467335511 8.207463279910717, 38.23114443204243 8.19850987234297, 38.24009783961018 8.187600113655645, 38.24675082162665 8.175153259756833, 38.25084770772398 8.161647636261586, 38.25223105686701 8.14760225670679))','768,769','2212',null,null,null,'01-01-2001','12-31-2021',null);
  select * from pmt_filter('768,769','2212',null,null,null,'01-01-2001','12-31-2021',null);
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_activities_by_polygon(wktpolygon character varying, data_group_ids character varying, classification_ids character varying, org_ids character varying,
imp_org_ids character varying, fund_org_ids character varying, start_date date, end_date date, unassigned_taxonomy_ids character varying) RETURNS SETOF pmt_json_result_type AS $$
DECLARE
  filtered_activity_ids int[];
  wkt text;
  rec record;
  error_msg text;
  i integer;

BEGIN
  -- get the filtered activity ids
  SELECT INTO filtered_activity_ids * FROM pmt_filter($2,$3,$4,$5,$6,$7,$8,$9);

  -- validate that incoming WKT is a polygon and that it is all uppercase
  IF (upper(substring(trim($1) from 1 for 7)) = 'POLYGON') THEN
    -- RAISE NOTICE 'WKT: %', $1;
    wkt := replace(lower(trim($1)), 'polygon', 'POLYGON');    
    -- RAISE NOTICE 'WKT Fixed: %', wkt; 

    -- list activities within wkt polygon
    FOR rec IN (
    SELECT row_to_json(j)
    FROM(
      SELECT array_to_json(array_agg(DISTINCT l.activity_id)) As activity_ids
      FROM location l
      WHERE _active = true
      AND ST_Contains(ST_GeomFromText(wkt, 4326), l._point)
      AND activity_id = ANY(filtered_activity_ids)
      )j
    ) LOOP		
      RETURN NEXT rec;
    END LOOP;
    
  ELSE
    FOR rec IN (SELECT row_to_json(j) FROM (SELECT 'WKT must be of type POLYGON' as error) j ) LOOP		
      RETURN NEXT rec;
    END LOOP;	
  END IF;

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