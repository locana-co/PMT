/******************************************************************
Change Script 3.0.10.107
1. update function pmt_activity_detail to add _direct_phone
2. update function pmt_activity to add _direct_phone
******************************************************************/
INSERT INTO version(_version, _iteration, _changeset) VALUES (3.0, 10, 107);
-- select * from version order by _iteration desc, _changeset desc;

/******************************************************************
1. update function pmt_activity_detail to add _direct_phone
   select * from pmt_activity_detail(29571);
   select * from activity where _active = true and id in (select activity_id from activity_contact);
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_activity_detail(activity_id integer) RETURNS SETOF pmt_json_result_type AS $$
DECLARE
  rec record;
  invalid_return_columns text[];
  return_columns text;
  execute_statement text;
  error_msg text;
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
				'select o.participation_id as p_id, o.id, o._name, r.classification as role, r.classification_id as role_id, ' ||
				't.classification as type, t.classification_id as type_id, i.classification as imp_type, i.classification_id as imp_type_id ' ||
				'from ' || 
				'(select * from ' ||
				'(select id as participation_id, organization_id from participation where _active = true and activity_id = ' ||  $1 || ') p ' ||
				'join organization o  ' ||
				'on p.organization_id = o.id) o ' ||
				'left join ' ||
				'(select * from _organization_lookup where taxonomy = ''Organisation Role'') r ' ||
				'on r.activity_id = ' ||  $1 || ' and r.organization_id = o.id ' ||
				'left join ' ||
				'(select * from _organization_lookup where taxonomy = ''Organisation Type'') t ' ||
				'on t.activity_id = ' ||  $1 || ' and t.organization_id = o.id ' ||
				'left join  ' ||
				'(select * from _organization_lookup where taxonomy = ''Implementing Types'') i ' ||
				'on i.activity_id = ' ||  $1 || ' and i.organization_id = o.id ' ||
				') p ) as organizations ';
				
    -- contacts
    execute_statement := execute_statement || ',(SELECT array_to_json(array_agg(row_to_json(c))) FROM ( ' ||
				'select c.id, c._first_name, c._last_name, c._title, c._email, c._direct_phone, c.organization_id, o._name ' ||
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
				'select d.id, d._title, d._description, d._amount, (SELECT array_to_json(array_agg(row_to_json(t))) FROM ( ' ||
				'select distinct tc.taxonomy_id, tc.taxonomy, tc.classification_id, tc.classification, tc._code ' ||
				'from detail_taxonomy dt ' ||
				'join _taxonomy_classifications tc ' ||
				'on dt.classification_id = tc.classification_id ' ||
				'and dt.detail_id = d.id ' ||
				') t ) as taxonomy ' ||
				'from detail d ' ||				
				'where d._active = true and d.activity_id = ' || $1 ||				
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

EXCEPTION WHEN others THEN 
  GET STACKED DIAGNOSTICS error_msg = MESSAGE_TEXT;  
    RAISE NOTICE 'Internal Error - Contact your DBA with the following error message: %', error_msg;
    
END;$$ LANGUAGE plpgsql;

/******************************************************************
2. update function pmt_activity to add _direct_phone
   select * from pmt_activity(29571);
   select * from activity where _active = true and id in (select activity_id from activity_contact)
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_activity(activity_id integer) RETURNS SETOF pmt_json_result_type AS $$
DECLARE
  rec record;
  invalid_return_columns text[];
  return_columns text;
  execute_statement text;
  error_msg text;
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
				'select _name as organization, _url as url, _address1 as address,  ' ||
				'_city as city, _state_providence as state_providence, _postal_code as zip, _country as country, r.classification as role, ' ||
				'array_to_string(array_agg(t.classification),'','') as type, i.classification as prime ' ||
				'from ' || 
				'(select * from ' ||
				'(select id as participation_id, organization_id from participation where _active = true and activity_id = ' ||  $1 || ') p ' ||
				'join organization o  ' ||
				'on p.organization_id = o.id) o ' ||
				'left join ' ||
				'(select * from _organization_lookup where taxonomy = ''Organisation Role'') r ' ||
				'on r.activity_id = ' ||  $1 || ' and r.organization_id = o.id ' ||
				'left join ' ||
				'(select * from _organization_lookup where taxonomy = ''Organisation Type'') t ' ||
				'on t.activity_id = ' ||  $1 || ' and t.organization_id = o.id ' ||
				'left join  ' ||
				'(select * from _organization_lookup where taxonomy = ''Implementing Types'') i ' ||
				'on i.activity_id = ' ||  $1 || ' and i.organization_id = o.id ' ||
				'group by 1,2,3,4,5,6,7,8,10 ' ||
				') p ) as organizations ';
    -- contacts
    execute_statement := execute_statement || ',(SELECT array_to_json(array_agg(row_to_json(c))) FROM ( ' ||
				'select c.id, c._first_name, c._last_name, c._email, c._direct_phone, c.organization_id, o._name, c._title ' ||
				'from activity_contact ac ' ||
				'join contact c ' ||
				'on ac.contact_id = c.id ' ||
				'left join organization o ' ||
				'on c.organization_id = o.id ' ||
				'where c._active = true and ac.activity_id = ' || $1 ||
				') c ) as contacts ';	
    -- details
    execute_statement := execute_statement || ',(SELECT array_to_json(array_agg(row_to_json(d))) FROM ( ' ||
				'select d.id, d._title, d._description, d._amount, (SELECT array_to_json(array_agg(row_to_json(t))) FROM ( ' ||
				'select distinct tc.taxonomy_id, tc.taxonomy, tc.classification_id, tc.classification, tc._code ' ||
				'from detail_taxonomy dt ' ||
				'join _taxonomy_classifications tc ' ||
				'on dt.classification_id = tc.classification_id ' ||
				'and dt.detail_id = d.id ' ||
				') t ) as taxonomy ' ||
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

EXCEPTION WHEN others THEN 
  GET STACKED DIAGNOSTICS error_msg = MESSAGE_TEXT;  
    RAISE NOTICE 'Internal Error - Contact your DBA with the following error message: %', error_msg;
    
END;$$ LANGUAGE plpgsql;
