/******************************************************************
Change Script 2.0.6.16 - Consolidated

1. pmt_infobox_activity_contact - bug fix.
******************************************************************/
UPDATE config SET changeset = 16, updated_date = current_date WHERE "version" = 2.0 AND iteration = 6;
-- SELECT * FROM pmt_version();

-- SELECT * FROM pmt_infobox_activity_contact(14946)

-- info box activity contact/partner
CREATE OR REPLACE FUNCTION pmt_infobox_activity_contact(activity_id integer)
RETURNS SETOF pmt_infobox_result_type AS 
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
		select  a.activity_id
		       ,coalesce(pt.partners, data_message) as partners 
		       ,coalesce(c.contacts, data_message) as contacts
		from
		-- activity
		(select a.activity_id, a.start_date, a.end_date, a.content
		from activity a
		where a.activity_id = $1) a
		left join
		-- all partners
		(select pp.activity_id, array_to_string(array_agg(distinct o.name), ',') as partners
		from participation pp
		join organization o
		on pp.organization_id = o.organization_id
		left join participation_taxonomy ppt
		on pp.participation_id = ppt.participation_id
		join classification c
		on ppt.classification_id = c.classification_id
		where c.taxonomy_id = (select taxonomy_id from taxonomy where name = 'Organisation Role') AND (c.name = 'Implementing' OR c.name = 'Funding')
		and pp.activity_id = $1
		group by pp.activity_id) pt
		on a.activity_id = pt.activity_id
		left join
		-- contacts
		(select ac.activity_id, array_to_string(array_agg(distinct c.first_name || ' ' || c.last_name), ',') as contacts
		from activity_contact ac
		join contact c
		on ac.contact_id = c.contact_id
		where ac.activity_id = $1
		group by ac.activity_id) c
		on a.activity_id = c.activity_id	
	) j
	) LOOP		
		RETURN NEXT rec;
	END LOOP;
   END IF;
END;$$ LANGUAGE plpgsql;