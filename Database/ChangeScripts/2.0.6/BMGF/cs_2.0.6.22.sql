/******************************************************************
Change Script 2.0.6.22 - Consolidated.
1. pmt_infobox_project_contact - change in partner logic. BMGF instance ONLY.
******************************************************************/
INSERT INTO config(version, iteration, changeset) VALUES (2.0, 6, 22);

-- SELECT * FROM config;

-- info box project contact/partner
CREATE OR REPLACE FUNCTION pmt_infobox_project_contact(project_id integer)
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
		select 
			 p.project_id
			,coalesce(pt.partners, data_message) as partners 
			,coalesce(c.contacts, data_message) as contacts
		from
		-- project
		(select p.project_id
		from project p
		where p.project_id = $1) p
		left join
		-- all partners
		(select pp.project_id, array_to_string(array_agg(distinct o.name), ',') as partners
		from participation pp
		join organization o
		on pp.organization_id = o.organization_id
		left join participation_taxonomy ppt
		on pp.participation_id = ppt.participation_id
		join classification c
		on ppt.classification_id = c.classification_id
		where c.taxonomy_id = (select taxonomy_id from taxonomy where name = 'Organisation Role') AND (c.name = 'Implementing')
		and pp.activity_id is null and pp.project_id = $1
		group by pp.project_id) pt
		on p.project_id = pt.project_id
		left join
		-- contacts
		(select pc.project_id, array_to_string(array_agg(distinct c.first_name || ' ' || c.last_name), ',') as contacts
		from project_contact pc
		join contact c
		on pc.contact_id = c.contact_id
		where pc.project_id = $1
		group by pc.project_id) c
		on p.project_id = c.project_id
		
	) j
	) LOOP		
		RETURN NEXT rec;
	END LOOP;
   END IF;
END;$$ LANGUAGE plpgsql;
