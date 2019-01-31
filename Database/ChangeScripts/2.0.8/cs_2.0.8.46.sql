/******************************************************************
Change Script 2.0.8.46 - consolidated.
1. pmt_activity - adding participation_id to organization object for 
editing 
2. pmt_project - adding participation_id to organization object for 
editing 
******************************************************************/
INSERT INTO version(version, iteration, changeset) VALUES (2.0, 8, 46);
-- select * from version order by changeset desc;

-- select * from pmt_activity(3);
-- select * from pmt_activity(1700);
-- select * from pmt_activity(15794);
-- select * from pmt_project(16);

DROP FUNCTION IF EXISTS pmt_activity(integer)  CASCADE;

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
    invalid_return_columns := ARRAY['active', 'retired_by', 'created_by', 'created_date'];
    -- get list of columns to return
    SELECT INTO return_columns array_to_string(array_agg('a.' || column_name::text), ', ') FROM information_schema.columns 
    WHERE table_schema='public' AND table_name='activity' AND column_name != ALL(invalid_return_columns);

    -- dynamically build the execute statment	
    execute_statement := 'SELECT ' || return_columns || ', l.location_ct, l.admin_bnds ';

    -- taxonomy	
    execute_statement := execute_statement || ',(SELECT array_to_json(array_agg(row_to_json(t))) FROM ( ' ||
				'select tc.taxonomy_id, tc.taxonomy, tc.classification_id, tc.classification ' ||
				'from activity_taxonomy at ' ||
				'join taxonomy_classifications  tc ' ||
				'on at.classification_id = tc.classification_id ' ||
				'and at.activity_id = ' || $1 ||
				') t ) as taxonomy ';
    -- organizations			
    execute_statement := execute_statement || ',(SELECT array_to_json(array_agg(row_to_json(p))) FROM ( ' ||
				'select pp.participation_id, o.organization_id, o.name, o.url'  ||
						', (SELECT array_to_json(array_agg(row_to_json(t))) FROM ( ' ||
						'select tc.taxonomy_id, tc.taxonomy, tc.classification_id, tc.classification ' ||
						'from participation_taxonomy pt ' ||
						'join taxonomy_classifications tc ' ||
						'on pt.classification_id = tc.classification_id ' ||
						'and pt.participation_id = pp.participation_id ' ||
						') t ) as taxonomy ' ||
				'from participation pp ' ||
				'join organization o ' ||
				'on pp.organization_id = o.organization_id ' ||				
				'where pp.active = true and o.active = true ' ||
				'and pp.activity_id = ' || $1 ||
				') p ) as organizations ';
    -- contacts
    execute_statement := execute_statement || ',(SELECT array_to_json(array_agg(row_to_json(c))) FROM ( ' ||
				'select c.contact_id, c.first_name, c.last_name, c.email, c.organization_id, o.name ' ||
				'from activity_contact ac ' ||
				'join contact c ' ||
				'on ac.contact_id = c.contact_id ' ||
				'left join organization o ' ||
				'on c.organization_id = o.organization_id ' ||
				'where c.active = true and ac.activity_id = ' || $1 ||
				') c ) as contacts ';	
    -- details
    execute_statement := execute_statement || ',(SELECT array_to_json(array_agg(row_to_json(d))) FROM ( ' ||
				'select d.detail_id, d.title, d.description, d.amount ' ||
				'from detail d ' ||				
				'where d.active = true and d.activity_id = ' || $1 ||
				') d ) as details ';					

    -- financials
    execute_statement := execute_statement || ',(SELECT array_to_json(array_agg(row_to_json(f))) FROM ( ' ||
				'select f.financial_id, f.amount'  ||
						', (SELECT array_to_json(array_agg(row_to_json(t))) FROM ( ' ||
						'select tc.taxonomy_id, tc.taxonomy, tc.classification_id, tc.classification ' ||
						'from financial_taxonomy ft ' ||
						'join taxonomy_classifications tc ' ||
						'on ft.classification_id = tc.classification_id ' ||
						'and ft.financial_id = f.financial_id ' ||
						') t ) as taxonomy ' ||
				'from financial f ' ||		
				'where f.active = true and f.activity_id = ' || $1 ||
				') f ) as financials ';
											
     -- locations
    execute_statement := execute_statement || ',(SELECT array_to_json(array_agg(row_to_json(l))) FROM ( ' ||
				'select l.location_id, l.lat_dd, l.long_dd, l.x, l.y, l.georef'  ||
						', (SELECT array_to_json(array_agg(row_to_json(t))) FROM ( ' ||
						'select tc.taxonomy_id, tc.taxonomy, tc.classification_id, tc.classification ' ||
						'from location_taxonomy lt ' ||
						'join taxonomy_classifications tc ' ||
						'on lt.classification_id = tc.classification_id ' ||
						'and lt.location_id = l.location_id ' ||
						') t ) as taxonomy ' ||
				'from location l ' ||								
				'where l.active = true and l.activity_id = ' || $1 ||
				') l ) as locations ';		
								
    -- activity
    execute_statement := execute_statement || 'from (select * from activity a where a.active = true and a.activity_id = ' || $1 || ') a ';
    -- locations
    execute_statement := execute_statement || 'left join ' ||
				'(select ll.activity_id, count(distinct ll.location_id) as location_ct, array_to_string(array_agg(distinct ll.gaul0_name || '','' || ll.gaul1_name || '','' || ll.gaul2_name), '';'') as admin_bnds ' ||
				'from location_lookup ll ' ||
				'where ll.activity_id = ' || $1 ||
				'group by ll.activity_id) l ' ||
				'on a.activity_id = l.activity_id ';


	RAISE NOTICE 'Execute statement: %', execute_statement;			

	FOR rec IN EXECUTE 'SELECT row_to_json(j) FROM (' || execute_statement || ')j' LOOP  		
		RETURN NEXT rec;
	END LOOP;
   END IF;
END;$$ LANGUAGE plpgsql;
/******************************************************************
   pmt_project
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_project(project_id integer) RETURNS SETOF pmt_json_result_type AS $$
DECLARE
  rec record;
  invalid_return_columns text[];
  return_columns text;
  execute_statement text;
  data_message text;
BEGIN
  IF $1 IS NOT NULL THEN	
    -- set columns that are not to be returned 
    invalid_return_columns := ARRAY['active', 'retired_by', 'created_by', 'created_date'];
    -- get list of columns to return
    SELECT INTO return_columns array_to_string(array_agg('p.' || column_name::text), ', ') FROM information_schema.columns 
    WHERE table_schema='public' AND table_name='project' AND column_name != ALL(invalid_return_columns);

    -- dynamically build the execute statment	
    execute_statement := 'SELECT ' || return_columns;

    -- taxonomy	
    execute_statement := execute_statement || ',(SELECT array_to_json(array_agg(row_to_json(t))) FROM ( ' ||
				'select tc.taxonomy_id, tc.taxonomy, tc.classification_id, tc.classification ' ||
				'from project_taxonomy pt ' ||
				'join taxonomy_classifications  tc ' ||
				'on pt.classification_id = tc.classification_id ' ||
				'and pt.project_id = ' || $1 ||
				') t ) as taxonomy ';
    -- organizations			
    execute_statement := execute_statement || ',(SELECT array_to_json(array_agg(row_to_json(p))) FROM ( ' ||
				'select pp.participation_id, o.organization_id, o.name, o.url'  ||
						', (SELECT array_to_json(array_agg(row_to_json(t))) FROM ( ' ||
						'select tc.taxonomy_id, tc.taxonomy, tc.classification_id, tc.classification ' ||
						'from participation_taxonomy pt ' ||
						'join taxonomy_classifications tc ' ||
						'on pt.classification_id = tc.classification_id ' ||
						'and pt.participation_id = pp.participation_id ' ||
						') t ) as taxonomy ' ||
				'from participation pp ' ||
				'join organization o ' ||
				'on pp.organization_id = o.organization_id ' ||				
				'where pp.active = true and o.active = true ' ||
				'and pp.activity_id is null and pp.project_id = ' || $1 ||
				') p ) as organizations ';
    -- contacts
    execute_statement := execute_statement || ',(SELECT array_to_json(array_agg(row_to_json(c))) FROM ( ' ||
				'select c.contact_id, c.first_name, c.last_name, c.email, c.organization_id, o.name ' ||
				'from project_contact pc ' ||
				'join contact c ' ||
				'on pc.contact_id = c.contact_id ' ||
				'left join organization o ' ||
				'on c.organization_id = o.organization_id ' ||
				'where c.active = true and pc.project_id = ' || $1 ||
				') c ) as contacts ';					
    -- details
    execute_statement := execute_statement || ',(SELECT array_to_json(array_agg(row_to_json(d))) FROM ( ' ||
				'select d.detail_id, d.title, d.description, d.amount ' ||
				'from detail d ' ||				
				'where d.active = true and d.activity_id is null and d.project_id = ' || $1 ||
				') d ) as details ';

    -- financials
    execute_statement := execute_statement || ',(SELECT array_to_json(array_agg(row_to_json(f))) FROM ( ' ||
				'select f.financial_id, f.amount'  ||
						', (SELECT array_to_json(array_agg(row_to_json(t))) FROM ( ' ||
						'select tc.taxonomy_id, tc.taxonomy, tc.classification_id, tc.classification ' ||
						'from financial_taxonomy ft ' ||
						'join taxonomy_classifications tc ' ||
						'on ft.classification_id = tc.classification_id ' ||
						'and ft.financial_id = f.financial_id ' ||
						') t ) as taxonomy ' ||
				'from financial f ' ||				
				'where f.active = true and f.activity_id is null and f.project_id = ' || $1 ||
				') f ) as financials ';
												
    -- activities
    execute_statement := execute_statement || ',(SELECT array_agg(a.activity_id)::int[]  ' ||
				'from activity a ' ||		
				'where a.active = true and a.project_id = ' || $1 ||
				') as activity_ids ';		
				
    -- locations
    execute_statement := execute_statement || ',(SELECT array_agg(l.location_id)::int[]  ' ||
				'from location l ' ||		
				'where l.active = true and l.project_id = ' || $1 ||
				') as location_ids ';		
								
    -- project
    execute_statement := execute_statement || 'from (select * from project p where p.active = true and p.project_id = ' || $1 || ') p ';
   

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