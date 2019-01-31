/******************************************************************
Change Script 3.0.10.90
1. update pmt_activity_count to address counting issues (parent -> child)
2. update pmt_locations_for_boundaries to address counting issues (parent -> child)
3. update pmt_activity_ids_by_boundary to address errors in update to
return parent activities
4. update pmt_activities to address errors in returning parent activities
5. Updated pmt_activity_detail to add details.
******************************************************************/
INSERT INTO version(_version, _iteration, _changeset) VALUES (3.0, 10, 90);
-- select * from version order by _iteration desc, _changeset desc;

 /******************************************************************
1. update pmt_activity_count to address counting issues (parent -> child)
  SELECT * FROM pmt_activity_count('2237',null,null,null,null,null,null,null,'29608,29647',null);
  SELECT * FROM pmt_activity_count('2237','1122',null,null,null,null,null,null,null,null);
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_activity_count(data_group_ids character varying, classification_ids character varying, org_ids character varying, imp_org_ids character varying, 
fund_org_ids character varying, start_date date, end_date date, unassigned_taxonomy_ids character varying, activity_ids character varying, boundary_filter json)
RETURNS SETOF pmt_json_result_type AS 
$$
DECLARE
  execute_statement text;
  select_statement_1 text;
  select_statement_2 text;
  filtered_activity_ids int[]; 
  boundary_json json;
  boundary_filters text[];
  boundary_statement text;
  boundary_activity_ids int[];
  a_ids int[];
  valid_activity_ids int[];
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
    IF array_length(filtered_activity_ids, 1) > 0 THEN
      EXECUTE 'SELECT array_agg(activity_id)::int[] FROM _location_lookup ll WHERE' ||  array_to_string(boundary_filters, 'OR') INTO boundary_activity_ids;
    END IF;
  END IF;
  
  -- prepare the execution statement
  execute_statement:= 'SELECT count(DISTINCT activity_id) as ct FROM ( ';

  select_statement_1 := ' SELECT DISTINCT activity_id, location_id FROM _filter_boundaries ' ||
		'WHERE parent_id IS NULL AND activity_id = ANY(ARRAY[' || array_to_string(filtered_activity_ids, ',') || ']) AND location_id IS NOT NULL ';
  select_statement_2 := ' SELECT DISTINCT parent_id, location_id FROM _filter_boundaries ' ||
		'WHERE parent_id IS NOT NULL AND (activity_id = ANY(ARRAY[' || array_to_string(filtered_activity_ids, ',') || ']) AND location_id IS NOT NULL ' ||
		'OR parent_id = ANY(ARRAY[' || array_to_string(filtered_activity_ids, ',') || ']) AND location_id IS NOT NULL) ';		

  -- add filter for boundary			
  IF array_length(boundary_activity_ids, 1) > 0 THEN
    select_statement_1:= select_statement_1 || ' AND activity_id = ANY(ARRAY[' || array_to_string(boundary_activity_ids, ',') || ']) ';
    select_statement_2:= select_statement_2 || ' AND activity_id = ANY(ARRAY[' || array_to_string(boundary_activity_ids, ',') || ']) ';
  END IF;

  -- add filter for activities in list
  IF array_length(valid_activity_ids, 1) > 0 THEN
    select_statement_1:= select_statement_1 || ' AND (activity_id = ANY(ARRAY[' || array_to_string(valid_activity_ids, ',') || ']) OR parent_id = ANY(ARRAY[' || array_to_string(valid_activity_ids, ',') || '])) ';
    select_statement_2:= select_statement_2 || ' AND (activity_id = ANY(ARRAY[' || array_to_string(valid_activity_ids, ',') || ']) OR parent_id = ANY(ARRAY[' || array_to_string(valid_activity_ids, ',') || '])) ';
  END IF;

  -- union the select statements
  execute_statement:= execute_statement || select_statement_1 || ' UNION ALL ' || select_statement_2 || ') as c';
  
  RAISE NOTICE 'Execute statement: %', execute_statement;			

  FOR rec IN EXECUTE 'SELECT row_to_json(j) FROM (' || execute_statement || ')j' LOOP  		
	RETURN NEXT rec;
  END LOOP;

EXCEPTION WHEN others THEN 
  GET STACKED DIAGNOSTICS error_msg = MESSAGE_TEXT;  
    RAISE NOTICE 'Internal Error - Contact your DBA with the following error message: %', error_msg;

END;$$ LANGUAGE plpgsql;

 /******************************************************************
2. update pmt_locations_for_boundaries to address counting issues (parent -> child)
  SELECT * FROM pmt_locations_for_boundaries(12,'2237',null,null,null,null,null,null,null,'29608,29647',null);
  SELECT * FROM pmt_locations_for_boundaries(12,'2237','1122',null,null,null,null,null,null,'',null); 
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_locations_for_boundaries(boundary_id integer, data_group_ids character varying,
  classification_ids character varying, org_ids character varying, imp_org_ids character varying, fund_org_ids character varying, 
  start_date date, end_date date, unassigned_taxonomy_ids character varying, activity_ids character varying, boundary_filter json)
RETURNS SETOF pmt_json_result_type AS 
$$
DECLARE
  valid_boundary_id integer; 
  execute_statement text;
  filtered_activity_ids int[];
  boundary_json json;
  boundary_filters text[];
  boundary_statement text;
  boundary_activity_ids int[];
  a_ids int[];
  valid_activity_ids int[];
  json record; 
  rec record;
  error_msg text;
BEGIN  
  -- validate and process boundary_id parameter
  IF $1 IS NOT NULL THEN
    SELECT INTO valid_boundary_id id FROM boundary WHERE id = $1;    
    -- exit if boundary id is not valid
    IF valid_boundary_id IS NULL THEN 
       FOR rec IN SELECT row_to_json(j) FROM( SELECT 'invalid parameter' AS error ) as j
	LOOP
        RETURN NEXT rec;    
       END LOOP;
    END IF;
  ELSE
    FOR rec IN SELECT row_to_json(j) FROM( SELECT 'missing required parameter' AS error ) as j
    LOOP
      RETURN NEXT rec;    
    END LOOP;    
  END IF;

  -- get the filtered activity ids
  SELECT INTO filtered_activity_ids * FROM pmt_filter($2,$3,$4,$5,$6,$7,$8,$9);
   
  -- get the list of activity ids
  IF ($10 IS NOT NULL OR $10 <> '' ) THEN
    a_ids:= string_to_array($10, ',')::int[];
    SELECT INTO valid_activity_ids array_agg(id) FROM activity WHERE _active = true AND id = ANY(a_ids);
  END IF;
  
  -- get the filtered activity ids by boundary
  IF ($11 IS NOT NULL) THEN
    RAISE NOTICE 'json was not null';      
    FOR boundary_json IN (SELECT * FROM json_array_elements($11)) LOOP
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
  
  -- prepare the execution statement
  execute_statement:= 'SELECT feature_id as id, count(distinct CASE WHEN parent_id IS NULL THEN activity_id WHEN parent_id IS NOT NULL THEN parent_id ELSE NULL END) as p, ' ||
		'count(distinct activity_id) as a, count(distinct location_id) as l, boundary_id as b FROM _filter_boundaries ' ||
		'WHERE (activity_id = ANY(ARRAY[' || array_to_string(filtered_activity_ids, ',') || ']) OR parent_id = ANY(ARRAY[' || array_to_string(filtered_activity_ids, ',') || '])) ';

  -- add filter for boundary		
  IF array_length(boundary_activity_ids, 1) > 0 THEN
    execute_statement:= execute_statement || 'AND activity_id = ANY(ARRAY[' || array_to_string(boundary_activity_ids, ',') || ']) ';
  END IF;

  -- add filter for activities in list
  IF array_length(valid_activity_ids, 1) > 0 THEN
    execute_statement:= execute_statement || 'AND (activity_id = ANY(ARRAY[' || array_to_string(valid_activity_ids, ',') || ']) OR parent_id = ANY(ARRAY[' || array_to_string(valid_activity_ids, ',') || '])) ';
  END IF;
  
  execute_statement:= execute_statement || 'AND boundary_id = ' || valid_boundary_id || ' GROUP BY 1,5';

  RAISE NOTICE 'Execute statement: %', execute_statement;			

  FOR rec IN EXECUTE 'SELECT row_to_json(j) FROM (' || execute_statement || ')j' LOOP  		
	RETURN NEXT rec;
  END LOOP;

EXCEPTION WHEN others THEN 
  GET STACKED DIAGNOSTICS error_msg = MESSAGE_TEXT;  
    RAISE NOTICE 'Internal Error - Contact your DBA with the following error message: %', error_msg;

END;$$ LANGUAGE plpgsql;

/******************************************************************
3. update pmt_activity_ids_by_boundary to address errors in update to
return parent activities
  SELECT * FROM pmt_activity_ids_by_boundary(12, 9,'2237','1122',null,null,null,null,null,null,null,null);
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_activity_ids_by_boundary(boundary_id integer, feature_id integer, data_group_ids character varying, 
classification_ids character varying, org_ids character varying, imp_org_ids character varying, fund_org_ids character varying, start_date date, end_date date,
unassigned_taxonomy_ids character varying, activity_ids character varying, boundary_filter json)
RETURNS SETOF pmt_json_result_type AS 
$$
DECLARE
  valid_boundary_id integer;
  execute_statement text;
  where_child_statement text;
  where_parent_statement text;
  filtered_activity_ids int[];
  boundary_json json;
  boundary_filters text[];
  boundary_statement text;
  boundary_activity_ids int[];
  a_ids int[];
  valid_activity_ids int[];
  json record; 
  rec record;
  error_msg text;
BEGIN  
  -- validate and process boundary_id parameter
  IF $1 IS NOT NULL AND $2 IS NOT NULL THEN
    SELECT INTO valid_boundary_id id FROM boundary WHERE id = $1;    
    -- exit if boundary id is not valid
    IF valid_boundary_id IS NULL THEN 
       FOR rec IN SELECT row_to_json(j) FROM( SELECT 'invalid parameter' AS error ) as j
	LOOP
        RETURN NEXT rec;    
       END LOOP;
    END IF;
  ELSE
    FOR rec IN SELECT row_to_json(j) FROM( SELECT 'missing required parameter' AS error ) as j
    LOOP
      RETURN NEXT rec;    
    END LOOP;    
  END IF;

  -- get the filtered activity ids
  SELECT INTO filtered_activity_ids * FROM pmt_filter($3,$4,$5,$6,$7,$8,$9,$10);

  -- get the list of activity ids
  IF ($11 IS NOT NULL OR $11 <> '' ) THEN
    a_ids:= string_to_array($11, ',')::int[];
    SELECT INTO valid_activity_ids array_agg(id) FROM activity WHERE _active = true AND id = ANY(a_ids);
  END IF;
  
  -- get the filtered activity ids by boundary
  IF ($12 IS NOT NULL) THEN 
    FOR boundary_json IN (SELECT * FROM json_array_elements($12)) LOOP
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
    IF array_length(filtered_activity_ids, 1) > 0 THEN
      EXECUTE 'SELECT array_agg(activity_id)::int[] FROM _location_lookup ll WHERE' ||  array_to_string(boundary_filters, 'OR') INTO boundary_activity_ids;
    END IF;
  END IF;
  
  -- prepare the execution statement
  execute_statement:= 'SELECT id, _title FROM activity WHERE parent_id IS NULL AND ';

  where_child_statement:= '( ARRAY[id] <@ ( SELECT array_agg(DISTINCT activity_id) FROM _filter_boundaries WHERE activity_id = ANY(ARRAY[' || array_to_string(filtered_activity_ids, ',') || ']) ';
  where_parent_statement:= 'OR ARRAY[id] <@ ( SELECT array_agg(DISTINCT parent_id) FROM _filter_boundaries WHERE parent_id = ANY(ARRAY[' || array_to_string(filtered_activity_ids, ',') || ']) ';
  
  -- add filter for boundary		
  IF array_length(boundary_activity_ids, 1) > 0 THEN
    where_child_statement:= where_child_statement || 'AND activity_id = ANY(ARRAY[' || array_to_string(boundary_activity_ids, ',') || ']) ';
    where_parent_statement:= where_parent_statement || 'AND parent_id = ANY(ARRAY[' || array_to_string(boundary_activity_ids, ',') || ']) ';
  END IF;
  
  -- add filter for activities in list
  IF array_length(valid_activity_ids, 1) > 0 THEN
    where_child_statement:= where_child_statement || 'AND activity_id = ANY(ARRAY[' || array_to_string(valid_activity_ids, ',') || ']) ';
    where_parent_statement:= where_parent_statement || 'AND parent_id = ANY(ARRAY[' || array_to_string(valid_activity_ids, ',') || ']) ';
  END IF;
  
  where_child_statement:= where_child_statement || 'AND boundary_id = ' || valid_boundary_id || ' AND feature_id = ' || $2 || ')';
  where_parent_statement:= where_parent_statement || 'AND boundary_id = ' || valid_boundary_id || ' AND feature_id = ' || $2 || ')';  

  execute_statement:= execute_statement || where_child_statement || where_parent_statement;

  RAISE NOTICE 'Execute statement: %', execute_statement;			

  FOR rec IN EXECUTE 'SELECT row_to_json(j) FROM (' || execute_statement || '))j' LOOP  		
	RETURN NEXT rec;
  END LOOP;
  
EXCEPTION WHEN others THEN 
  GET STACKED DIAGNOSTICS error_msg = MESSAGE_TEXT;  
    RAISE NOTICE 'Internal Error - Contact your DBA with the following error message: %', error_msg;
     
END;$$ LANGUAGE plpgsql;

/******************************************************************
4. update pmt_activities to address errors in returning parent activities
   select * from pmt_activities('2237','1122',null,null,null,null,null,null,null,'[{"b":12,"ids":[9]},{"b":13,"ids":[52,8,3,9,22,34,24,21,36,50,25,69,31,49,53,12,68,56]},{"b":14,"ids":[659,543,568,595,570,643,648,644,645,646,647,590,548,592,600,632,633,630,597,631,598,666,554,674,624,664,639,640,606,559,555,556,553,557,594,652,552,596,593,584,627,585,628,587,651,677,678,605,599,660,571,671,546,670,672,545,663,673,668,669,560,561,564,566,638,626,661,567,625,637,665,667,662,563,562,655,572,565,656,657,658,550,569,547,602,676,601,603,617,618,621,622,623,582,634,580,615,620,589,588,613,612,616,614,586,575,583,579,653,654,551,577,574,573,619,578,635,636,581,607,608,609,610,611,576,629,641,642,650,604,558,591]}]'); 
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
		'_title as t, sum(_amount) as a, a._start_date as sd, a._end_date as ed, array_agg( o._name) as f ' ||
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
  		' LEFT JOIN (SELECT id, activity_id, _amount, provider_id FROM financial WHERE _active = true) f ' ||
  		' ON a.id = f.activity_id ' ||
  		' LEFT JOIN ( select financial_id, classification, _code ' ||
				' FROM financial_taxonomy ft ' ||
				' JOIN _taxonomy_classifications tc ' ||
				' on ft.classification_id = tc.classification_id ' ||
				' where tc.taxonomy = ''Transaction Type''' || 
				'OR classification IS NULL OR classification = ''Incoming Funds'' OR classification = ''Commitment'' ) as ft ' ||
		'ON ft.financial_id = f.id ' ||
		'LEFT JOIN (SELECT id, _name FROM _activity_participants WHERE classification = ''Funding'') o ON a.id = o.id ' ||
		'GROUP BY 1,2,3,4,5,7,8 ';


  RAISE NOTICE 'Execute statement: %', execute_statement;

  FOR rec IN EXECUTE 'SELECT row_to_json(j) FROM (' || execute_statement || ')j' LOOP
	RETURN NEXT rec;
  END LOOP;

EXCEPTION WHEN others THEN
  GET STACKED DIAGNOSTICS error_msg = MESSAGE_TEXT;
    RAISE NOTICE 'Internal Error - Contact your DBA with the following error message: %', error_msg;

END;$$ LANGUAGE plpgsql;

/******************************************************************
  5. Updated pmt_activity_detail to add details.
  select * from pmt_activity_detail(29549);
  select * from activity;
*******************************************************************/
CREATE OR REPLACE FUNCTION pmt_activity_detail(activity_id integer) RETURNS SETOF pmt_json_result_type AS $$
DECLARE
  rec record;
  invalid_return_columns text[];
  return_columns text;
  execute_statement text;
  data_message text;
BEGIN
  IF $1 IS NOT NULL THEN	
    -- get list of columns to return
    SELECT INTO return_columns array_to_string(array_agg('a.' || column_name::text), ', ') FROM information_schema.columns 
    WHERE table_schema='public' AND table_name='activity';

    -- dynamically build the execute statment	
    execute_statement := 'SELECT ' || return_columns || ', (SELECT _name FROM classification WHERE id = data_group_id) as data_group' || 
				', (SELECT _title FROM activity WHERE id = a.parent_id) as parent_title, l.ct ';

    -- taxonomy	
    execute_statement := execute_statement || ',(SELECT array_to_json(array_agg(row_to_json(t))) FROM ( ' ||
				'select tc.taxonomy_id, tc.taxonomy, tc.classification_id, tc.classification, tc._code ' ||
				'from activity_taxonomy at ' ||
				'join _taxonomy_classifications  tc ' ||
				'on at.classification_id = tc.classification_id ' ||
				'and at.activity_id = ' || $1 ||
				') t ) as taxonomy ';
    -- organizations			
    execute_statement := execute_statement || ',(SELECT array_to_json(array_agg(row_to_json(p))) FROM ( ' ||
				'select p.id as p_id, o.id, o._name, tc.classification_id, tc.classification, ' ||
					'cl._name as type, cl.id as type_id ' ||
				'from (select * from participation where _active = true and activity_id = ' || $1 || ') p  ' ||
  				'left join organization o ' ||
					'left join organization_taxonomy ot ' ||
						'left join classification cl ' ||
						'on ot.classification_id = cl.id ' ||
					'ON o.id = ot.organization_id ' ||
				'ON p.organization_id = o.id '  ||
  				'left join participation_taxonomy pt ON p.id = pt.participation_id '  ||
  				'left join _taxonomy_classifications tc ON pt.classification_id = tc.classification_id '  ||
				') p ) as organizations ';
				
    -- contacts
    execute_statement := execute_statement || ',(SELECT array_to_json(array_agg(row_to_json(c))) FROM ( ' ||
				'select c.id, c._first_name, c._last_name, c._title, c._email, c.organization_id, o._name ' ||
				'from activity_contact ac ' ||
				'join contact c ' ||
				'on ac.contact_id = c.id ' ||
				'left join organization o ' ||
				'on c.organization_id = o.id ' ||
				'where c._active = true and ac.activity_id = ' || $1 ||
				') c ) as contacts ';	

    -- financials
    execute_statement := execute_statement || ',(SELECT array_to_json(array_agg(row_to_json(f))) FROM ( ' ||
				'select f.id, f._amount, f._start_date, f._end_date'  ||
						',provider_id' ||
						',(SELECT _name FROM organization WHERE id = provider_id) as provider' ||
						',recipient_id' ||
						',(SELECT _name FROM organization WHERE id = recipient_id) as recipient' ||
						', (SELECT array_to_json(array_agg(row_to_json(t))) FROM ( ' ||
						'select tc.taxonomy_id, tc.taxonomy, tc.classification_id, tc.classification, tc._code ' ||
						'from financial_taxonomy ft ' ||
						'join _taxonomy_classifications tc ' ||
						'on ft.classification_id = tc.classification_id ' ||
						'and ft.financial_id = f.id ' ||
						') t ) as taxonomy ' ||
				'from financial f ' ||		
				'where f._active = true and f.activity_id = ' || $1 ||
				') f ) as financials ';

    -- locations
    execute_statement := execute_statement || ',(SELECT array_to_json(array_agg(row_to_json(l))) FROM (  ' ||
				'select l.id, l._admin0, l._admin1, l._admin2, l._admin3, l._admin_level, l.boundary_id, l.feature_id ' ||
				'from location l ' ||		
				'where l._active = true and l.activity_id = ' || $1 ||
				') l ) as locations ';		
    -- details
    execute_statement := execute_statement || ',(SELECT array_to_json(array_agg(row_to_json(d))) FROM (  ' ||
				'select id, _title ' ||
				'from detail ' ||		
				'where _active = true and activity_id = ' || $1 ||
				') d ) as details ';		
    -- children
    execute_statement := execute_statement || ',(SELECT array_to_json(array_agg(row_to_json(a))) FROM (  ' ||
				'select a.id, a._title ' ||					
				'from activity a ' ||		
				'where a._active = true and a.parent_id = ' || $1 ||
				') a ) as children ';	
													
								
    -- activity
    execute_statement := execute_statement || 'from (select * from activity a where a._active = true and a.id = ' || $1 || ') a ';
    -- locations
    execute_statement := execute_statement || 'left join ' ||
				'(select ll.activity_id, count(distinct ll.location_id) as ct ' ||
				'from _location_lookup ll ' ||
				'where ll.activity_id = ' || $1 || ' ' ||
				'group by ll.activity_id) l ' ||
				'on a.id = l.activity_id ';


  RAISE NOTICE 'Execute statement: %', execute_statement;			

  FOR rec IN EXECUTE 'SELECT row_to_json(j) FROM (' || execute_statement || ')j' LOOP  		
	RETURN NEXT rec;
  END LOOP;
END IF;

END;$$ LANGUAGE plpgsql;


/******************************************************************
3. update pmt_activity function to add _admin_level
  SELECT * FROM pmt_activity(29549);
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_activity(activity_id integer) RETURNS SETOF pmt_json_result_type AS 
$$
DECLARE
  rec record;
  invalid_return_columns text[];
  return_columns text;
  execute_statement text;
  data_message text;
BEGIN
  IF $1 IS NOT NULL THEN	
    -- set columns that are not to be returned 
    invalid_return_columns := ARRAY['_active', '_retired_by', '_created_by', '_created_date'];
    -- get list of columns to return
    SELECT INTO return_columns array_to_string(array_agg('a.' || column_name::text), ', ') FROM information_schema.columns 
    WHERE table_schema='public' AND table_name='activity' AND column_name != ALL(invalid_return_columns);

    -- dynamically build the execute statment	
    execute_statement := 'SELECT ' || return_columns || ', (SELECT _name FROM classification WHERE id = data_group_id) as data_group' || 
				', (SELECT _title FROM activity WHERE id = a.parent_id) as parent_title, l.ct ';

    -- taxonomy	
    execute_statement := execute_statement || ',(SELECT array_to_json(array_agg(row_to_json(t))) FROM ( ' ||
				'select tc.taxonomy_id, tc.taxonomy, tc.classification_id, tc.classification, tc._code ' ||
				'from activity_taxonomy at ' ||
				'join _taxonomy_classifications  tc ' ||
				'on at.classification_id = tc.classification_id ' ||
				'and at.activity_id = ' || $1 ||
				') t ) as taxonomy ';
    -- organizations			
    execute_statement := execute_statement || ',(SELECT array_to_json(array_agg(row_to_json(p))) FROM ( ' ||
				'select _name as organization, classification as role, _url as url, _address1 as address, '  ||
				'_city as city, _state_providence as state_providence, _postal_code as zip, _country as country ' ||
				'from _organization_lookup ol join organization o on ol.organization_id = o.id ' ||
				'where activity_id = ' || $1 ||
				') p ) as organizations ';
				
    -- contacts
    execute_statement := execute_statement || ',(SELECT array_to_json(array_agg(row_to_json(c))) FROM ( ' ||
				'select c.id, c._first_name, c._last_name, c._email, c._title, c.organization_id, o._name ' ||
				'from activity_contact ac ' ||
				'join contact c ' ||
				'on ac.contact_id = c.id ' ||
				'left join organization o ' ||
				'on c.organization_id = o.id ' ||
				'where c._active = true and ac.activity_id = ' || $1 ||
				') c ) as contacts ';	
    -- details
    execute_statement := execute_statement || ',(SELECT array_to_json(array_agg(row_to_json(d))) FROM ( ' ||
				'select d.id, d._title, d._description, d._amount ' ||
				'from detail d ' ||				
				'where d._active = true and d.activity_id = ' || $1 ||
				') d ) as details ';					

    -- financials
    execute_statement := execute_statement || ',(SELECT array_to_json(array_agg(row_to_json(f))) FROM ( ' ||
				'select f.id, f._amount, f._start_date, f._end_date '  ||
						',(SELECT _name FROM organization WHERE id = provider_id) as provider' ||
						',(SELECT _name FROM organization WHERE id = recipient_id) as recipient' ||
						', (SELECT array_to_json(array_agg(row_to_json(t))) FROM ( ' ||
						'select tc.taxonomy_id, tc.taxonomy, tc.classification_id, tc.classification, tc._code ' ||
						'from financial_taxonomy ft ' ||
						'join _taxonomy_classifications tc ' ||
						'on ft.classification_id = tc.classification_id ' ||
						'and ft.financial_id = f.id ' ||
						') t ) as taxonomy ' ||
				'from financial f ' ||		
				'where f._active = true and f.activity_id = ' || $1 ||
				') f ) as financials ';

    -- details
    execute_statement := execute_statement || ',(SELECT array_to_json(array_agg(row_to_json(d))) FROM (  ' ||
				'select id, _title ' ||
				'from detail ' ||		
				'where _active = true and activity_id = ' || $1 ||
				') d ) as details ';			
											
     -- locations
    execute_statement := execute_statement || ',(SELECT array_agg(l.id)::int[]  ' ||
				'from location l ' ||		
				'where l._active = true and l.activity_id = ' || $1 ||
				') as location_ids ';	

    -- locations
    execute_statement := execute_statement || ',(SELECT array_to_json(array_agg(row_to_json(l))) FROM (  ' ||
				'select l.id, l._admin0, l._admin1, l._admin2, l._admin3, l._admin_level ' ||
					', (SELECT array_to_json(array_agg(row_to_json(t))) FROM ( ' ||
					'select tc.taxonomy_id, tc.taxonomy, tc.classification_id, tc.classification, tc._code ' ||
					'from location_taxonomy lt ' ||
					'join _taxonomy_classifications tc ' ||
					'on lt.classification_id = tc.classification_id ' ||
					'and lt.location_id = l.id ' ||
					') t ) as taxonomy ' ||
					', (SELECT array_to_json(array_agg(row_to_json(b))) FROM ( ' ||
					'select lb.boundary_id, lb.feature_id, lb._feature_name ' ||
					'from location_boundary lb ' ||					
					'where lb.location_id = l.id ' ||
					') b ) as boundaries ' ||
				'from location l ' ||		
				'where l._active = true and l.activity_id = ' || $1 ||
				') l ) as locations ';		

    -- children
    execute_statement := execute_statement || ',(SELECT array_to_json(array_agg(row_to_json(a))) FROM (  ' ||
				'select a.id, a._title ' ||					
				'from activity a ' ||		
				'where a._active = true and a.parent_id = ' || $1 ||
				') a ) as children ';	
													
								
    -- activity
    execute_statement := execute_statement || 'from (select * from activity a where a._active = true and a.id = ' || $1 || ') a ';
    -- locations
    execute_statement := execute_statement || 'left join ' ||
				'(select ll.activity_id, count(distinct ll.location_id) as ct ' ||
				'from _location_lookup ll ' ||
				'where ll.activity_id = ' || $1 ||
				'group by ll.activity_id) l ' ||
				'on a.id = l.activity_id ';


RAISE NOTICE 'Execute statement: %', execute_statement;			

FOR rec IN EXECUTE 'SELECT row_to_json(j) FROM (' || execute_statement || ')j' LOOP  		
	RETURN NEXT rec;
END LOOP;
   END IF;
END;$$ LANGUAGE plpgsql;



-- update permissions
GRANT USAGE ON SCHEMA public TO pmt_read;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO pmt_read;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO pmt_read;
GRANT USAGE ON SCHEMA public TO pmt_write;
GRANT SELECT,INSERT ON ALL TABLES IN SCHEMA public TO pmt_write;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO pmt_write;