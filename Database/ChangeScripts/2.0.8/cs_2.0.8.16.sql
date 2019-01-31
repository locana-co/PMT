/******************************************************************
Change Script 2.0.8.16 - consolidated.
1. pmt_infobox_activity - new function to provide all infobox info
for an activity, including necessary id values to support editing.
This function will be replacing all activity infobox functions for
bmgf and pmt.
******************************************************************/
INSERT INTO version(version, iteration, changeset) VALUES (2.0, 8, 16);
-- select * from version order by changeset desc;

-- select * from pmt_infobox_activity(11243);

DROP FUNCTION IF EXISTS pmt_infobox_activity(integer)  CASCADE;

CREATE OR REPLACE FUNCTION pmt_infobox_activity(activity_id integer)
RETURNS SETOF pmt_infobox_result_type AS 
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
    -- -- taxonomy	
    execute_statement := execute_statement || ',(SELECT array_to_json(array_agg(row_to_json(t))) FROM ( ' ||
				'select tc.taxonomy_id, tc.taxonomy, tc.classification_id, tc.classification ' ||
				'from activity_taxonomy at ' ||
				'join taxonomy_classifications  tc ' ||
				'on at.classification_id = tc.classification_id ' ||
				'and at.activity_id = ' || $1 ||
				') t ) as taxonomy ';
    -- partners			
    execute_statement := execute_statement || ',(SELECT array_to_json(array_agg(row_to_json(p))) FROM ( ' ||
				'select o.organization_id, o.name, tc.taxonomy_id, tc.taxonomy, tc.classification_id, tc.classification ' ||
				'from participation pp ' ||
				'join organization o ' ||
				'on pp.organization_id = o.organization_id ' ||
				'left join participation_taxonomy ppt ' ||
				'on pp.participation_id = ppt.participation_id ' ||
				'join taxonomy_classifications tc ' ||
				'on ppt.classification_id = tc.classification_id ' ||
				'where pp.active = true and o.active = true ' ||
				'and tc.taxonomy = ''Organisation Role'' and (tc.classification = ''Implementing'' OR tc.classification= ''Funding'') ' ||
				'and pp.activity_id = ' || $1 ||
				') p ) as partners ';
    -- contacts
    execute_statement := execute_statement || ',(SELECT array_to_json(array_agg(row_to_json(c))) FROM ( ' ||
				'select c.contact_id, c.first_name, c.last_name, c.organization_id, o.name ' ||
				'from activity_contact ac ' ||
				'join contact c ' ||
				'on ac.contact_id = c.contact_id ' ||
				'left join organization o ' ||
				'on c.organization_id = o.organization_id ' ||
				'where c.active = true and ac.activity_id = ' || $1 ||
				') c ) as contacts ';				
    -- activity
    execute_statement := execute_statement || 'from (select * from activity a where a.active = true and a.activity_id = ' || $1 || ') a ';
    -- locations
    execute_statement := execute_statement || 'left join ' ||
				'(select ll.activity_id, count(ll.location_id) as location_ct, array_to_string(array_agg(distinct ll.gaul0_name || '','' || ll.gaul1_name || '','' || ll.gaul2_name), '';'') as admin_bnds ' ||
				'from location_lookup ll ' ||
				'where ll.activity_id = ' || $1 ||
				'group by ll.activity_id) l ' ||
				'on a.activity_id = l.activity_id ';

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