/******************************************************************
Change Script 2.0.8.56 - consolidated.
1. tanaim_activity - new location format specifically for tanaim
******************************************************************/
INSERT INTO version(version, iteration, changeset) VALUES (2.0, 8, 56);
-- select * from version order by changeset desc;

-- test
-- select * from tanaim_activity(19485);

DROP FUNCTION IF EXISTS tanaim_activity(integer) CASCADE;

CREATE OR REPLACE FUNCTION tanaim_activity(activity_id integer) RETURNS SETOF pmt_json_result_type AS 
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
				'select tc.taxonomy_id, tc.taxonomy, tc.classification_id, tc.classification, tc.code ' ||
				'from activity_taxonomy at ' ||
				'join taxonomy_classifications  tc ' ||
				'on at.classification_id = tc.classification_id ' ||
				'and at.activity_id = ' || $1 ||
				') t ) as taxonomy ';
    -- organizations			
    execute_statement := execute_statement || ',(SELECT array_to_json(array_agg(row_to_json(p))) FROM ( ' ||
				'select pp.participation_id, o.organization_id, o.name, o.url'  ||
						', (SELECT array_to_json(array_agg(row_to_json(t))) FROM ( ' ||
						'select tc.taxonomy_id, tc.taxonomy, tc.classification_id, tc.classification, tc.code ' ||
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
						'select tc.taxonomy_id, tc.taxonomy, tc.classification_id, tc.classification, tc.code ' ||
						'from financial_taxonomy ft ' ||
						'join taxonomy_classifications tc ' ||
						'on ft.classification_id = tc.classification_id ' ||
						'and ft.financial_id = f.financial_id ' ||
						') t ) as taxonomy ' ||
				'from financial f ' ||		
				'where f.active = true and f.activity_id = ' || $1 ||
				') f ) as financials ';
											
     -- locations
    execute_statement := execute_statement || ',(SELECT array_agg(l.location_id)::int[]  ' ||
				'from location l ' ||		
				'where l.active = true and l.activity_id = ' || $1 ||
				') as location_ids ';			
								
    -- activity
    execute_statement := execute_statement || 'from (select * from activity a where a.active = true and a.activity_id = ' || $1 || ') a ';
    -- locations
    execute_statement := execute_statement || 'left join ' ||
				'(select g1.activity_id, sum(g1.location_ct) as location_ct, array_to_string(array_agg(distinct g1.gaul1), ''; '')  as admin_bnds from ' ||
				'(select ll.activity_id, count(distinct ll.location_id) as location_ct, ll.gaul1_name || '' ('' || array_to_string(array_agg(distinct ll.gaul2_name), '','') || '')'' as gaul1 ' ||
				'from location_lookup ll ' ||
				'where ll.activity_id = ' || $1 ||
				'group by ll.activity_id, ll.gaul1_name) g1 ' ||
				'group by g1.activity_id) l ' ||
				'on a.activity_id = l.activity_id ';


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