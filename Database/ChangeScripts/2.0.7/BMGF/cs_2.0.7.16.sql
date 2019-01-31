/******************************************************************
Change Script 2.0.7.16 - Consolidated.
1. bmgf_infobox_activity_stats - updating to include total number of 
associated locations and a list of admin boundaries.
******************************************************************/
INSERT INTO config(version, iteration, changeset) VALUES (2.0, 7, 16);
-- select * from config order by version, iteration, changeset, updated_date;

-- select * from bmgf_infobox_activity_stats(6624);

-- select activity_id, count(location_id) as ct
-- from location_lookup		
-- group by activity_id
-- order by ct

-- info box activity stats
CREATE OR REPLACE FUNCTION bmgf_infobox_activity_stats(activity_id integer)
RETURNS SETOF bmgf_infobox_result_type AS 
$$
DECLARE
  rec record;
  data_message text;
BEGIN
   IF $1 IS NOT NULL THEN		
	-- set no data message
	data_message := 'No Data Entered';
	
	FOR rec IN (
	select row_to_json(j)
	from
	(	
		select a.activity_id
		       ,a.start_date
		       ,a.end_date
		       ,coalesce(a.content, data_message) as content
		       ,coalesce(si.name, data_message) as sub_initiative
		       ,coalesce(s.name, data_message) as status
		       ,coalesce(l.admin_bnds, data_message) as location
		       ,l.location_ct as location_ct
		       ,coalesce(a.tags, data_message) as keywords 				
		from
		-- activity
		(select a.activity_id, a.start_date, a.end_date, a.content, a.tags, a.city_village
		from activity a
		where a.activity_id = $1) a
		left join 
		-- Sub-Initiative
		(select at.activity_id, array_to_string(array_agg(distinct c.name), ',') as name
		from activity_taxonomy at
		join classification c
		on at.classification_id = c.classification_id
		where c.taxonomy_id = (select taxonomy_id from taxonomy where name = 'Sub-Initiative')
		and at.activity_id = $1
		group by at.activity_id) as si
		on a.activity_id = si.activity_id
		left join
		-- Activity Status
		(select at.activity_id, array_to_string(array_agg(distinct c.name), ',') as name
		from activity_taxonomy at
		join classification c
		on at.classification_id = c.classification_id
		where c.taxonomy_id =(select taxonomy_id from taxonomy where name = 'Activity Status')
		AND at.activity_id = $1
		group by at.activity_id) s
		on a.activity_id = s.activity_id
		left join
		-- Location
		(select ll.activity_id, count(ll.location_id) as location_ct, array_to_string(array_agg(distinct ll.gaul0_name || ',' || ll.gaul1_name || ',' || ll.gaul2_name), ';') as admin_bnds
		from location_lookup ll
		where ll.activity_id = $1
		group by ll.activity_id) l
		on a.activity_id = l.activity_id
	) j
	) LOOP		
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