/******************************************************************
Change Script 2.0.7.4 - Consolidated.
1. pmt_infobox_project_info
2. pmt_infobox_project_stats
3. pmt_infobox_project_desc
4. pmt_infobox_project_contact
5. pmt_infobox_activity_stats
6. pmt_infobox_activity_contact
7. pmt_infobox_activity_desc
******************************************************************/
INSERT INTO config(version, iteration, changeset) VALUES (2.0, 7, 4);
-- select * from config order by version, iteration, changeset, updated_date;

-- testing
-- select * from pmt_infobox_project_info(2, 15);
-- select * from pmt_infobox_project_stats(1);
-- select * from pmt_infobox_project_desc(1);
-- select * from pmt_infobox_project_contact(1);
-- select * from pmt_infobox_activity_stats(1);
-- select * from pmt_infobox_activity_desc(1);
-- select * from pmt_infobox_activity_contact(1);

-- new drop statements

DROP FUNCTION IF EXISTS pmt_infobox_activity_contact(integer)  CASCADE;
DROP FUNCTION IF EXISTS pmt_infobox_activity_desc(integer)  CASCADE;
DROP FUNCTION IF EXISTS pmt_infobox_activity_stats(integer)  CASCADE;
DROP FUNCTION IF EXISTS pmt_infobox_project_contact(integer)  CASCADE;
DROP FUNCTION IF EXISTS pmt_infobox_project_desc(integer)  CASCADE;
DROP FUNCTION IF EXISTS pmt_infobox_project_info(integer, integer)  CASCADE;
DROP FUNCTION IF EXISTS pmt_infobox_project_nutrition(integer)  CASCADE;
DROP FUNCTION IF EXISTS pmt_infobox_project_stats(integer)  CASCADE;

-- info box project general information
CREATE OR REPLACE FUNCTION pmt_infobox_project_info(project_id integer, tax_id integer)
RETURNS SETOF pmt_infobox_result_type AS 
$$
DECLARE
  valid_taxonomy_id boolean;
  t_id integer;
  rec record;
  data_message text;
BEGIN	
   IF $1 IS NOT NULL THEN	
	-- set no data message
	data_message := 'No Data Entered';

	-- validate and process taxonomy_id parameter
	SELECT INTO valid_taxonomy_id * FROM pmt_validate_taxonomy($2);

	IF valid_taxonomy_id THEN
	  t_id := $2;
	ELSE
	  t_id := 1;
	END IF;
	
	FOR rec IN (
	select row_to_json(j)
	from
	(	
		-- project general information
		select p.project_id
		      ,coalesce(p.label, p.title, data_message) as title				
		      ,coalesce(pp.name, data_message) as org_name
		      ,coalesce(pp.url, data_message) as org_url
		      ,coalesce(sector.name, data_message) as sector
		      ,coalesce(p.tags, data_message) as keywords
		      ,coalesce(p.url, data_message) as project_url
		      ,(select array_to_json(array_agg(row_to_json(c))) from (
			select l.lat_dd as lat, l.long_dd as long, array_to_string(array_agg(DISTINCT lt.classification_id), ',') as c_id
			from location l
			left join taxonomy_lookup lt
			on l.location_id = lt.location_id
			where l.project_id = $1  and l.active = true and lt.taxonomy_id = t_id
			group by  l.lat_dd, l.long_dd
		      ) c ) as l_ids
		from
		-- project
		(select p.project_id, p.title, p.label, p.tags, p.url
		from project p
		where p.project_id = $1 and p.active = true) p
		left join		
		-- participants
		(select pp.project_id, array_to_string(array_agg(distinct o.name), ',') as name, array_to_string(array_agg(distinct o.url), ',') as url
		from participation pp
		join organization o
		on pp.organization_id = o.organization_id
		left join participation_taxonomy ppt
		on pp.participation_id = ppt.participation_id
		join classification c
		on ppt.classification_id = c.classification_id 
		where c.taxonomy_id = (select taxonomy_id from taxonomy where name = 'Organisation Role') 
		AND pp.project_id = $1 and pp.active = true and o.active = true and c.active = true
		group by pp.project_id) pp
		on p.project_id = pp.project_id
		left join
		-- Sector
		(select p.project_id, array_to_string(array_agg(c.name), ',') as name
		from project p 
		join project_taxonomy pt
		on p.project_id = pt.project_id
		join classification c
		on pt.classification_id = c.classification_id
		where c.taxonomy_id = (select taxonomy_id from taxonomy where name = 'Sector')
		and p.project_id = $1 and p.active = true and c.active = true
		group by p.project_id) as sector
		on p.project_id = sector.project_id
	) j
	) LOOP		
		RETURN NEXT rec;
	END LOOP;
   END IF;
END;$$ LANGUAGE plpgsql;

-- info box project stats
CREATE OR REPLACE FUNCTION pmt_infobox_project_stats(project_id integer)
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
		select p.project_id
		       ,p.start_date
		       ,p.end_date
		       ,coalesce(s.name, data_message) as sector
		       ,f.amount as grant
		from
		-- project
		(select p.project_id, p.start_date, p.end_date
		from project p
		where p.active = true and p.project_id = $1) p
		left join
		-- sector
		(select pt.project_id, array_to_string(array_agg(distinct c.name), ',') as  name
		from project_taxonomy pt
		join classification c
		on pt.classification_id = c.classification_id
		where c.active = true and c.taxonomy_id = (select taxonomy_id from taxonomy where name = 'Sector')
		AND pt.project_id = $1
		group by pt.project_id) as s
		on p.project_id = s.project_id
		left join
		-- financials
		(select f.project_id, sum(f.amount) as amount
		from financial f
		where f.activity_id is null and f.active = true and f.project_id = $1
		group by f.project_id) as f
		on p.project_id = f.project_id
	) j
	) LOOP		
		RETURN NEXT rec;
	END LOOP;
   END IF;
END;$$ LANGUAGE plpgsql;

-- info box project description
CREATE OR REPLACE FUNCTION pmt_infobox_project_desc(project_id integer)
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
		select p.project_id
			,coalesce(p.title, data_message) as title
		       ,coalesce(p.description, data_message) as description
		from project p
		where p.active = true and p.project_id = $1	
	) j
	) LOOP		
		RETURN NEXT rec;
	END LOOP;
   END IF;
END;$$ LANGUAGE plpgsql;

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
		where p.active = true and p.project_id = $1) p
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
		where  pp.active = true and o.active = true and c.active = true
		and c.taxonomy_id = (select taxonomy_id from taxonomy where name = 'Organisation Role') AND (c.name = 'Implementing')
		and pp.activity_id is null and pp.project_id = $1
		group by pp.project_id) pt
		on p.project_id = pt.project_id
		left join
		-- contacts
		(select pc.project_id, array_to_string(array_agg(distinct c.first_name || ' ' || c.last_name), ',') as contacts
		from project_contact pc
		join contact c
		on pc.contact_id = c.contact_id
		where c.active = true and pc.project_id = $1
		group by pc.project_id) c
		on p.project_id = c.project_id
		
	) j
	) LOOP		
		RETURN NEXT rec;
	END LOOP;
   END IF;
END;$$ LANGUAGE plpgsql;

-- info box activity stats
CREATE OR REPLACE FUNCTION pmt_infobox_activity_stats(activity_id integer)
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
		select a.activity_id
		       ,a.start_date
		       ,a.end_date
		       ,coalesce(si.name, data_message) as sector
		       ,coalesce(s.name, data_message) as status
		       ,coalesce(l.name, data_message) as location
		       ,coalesce(a.tags, data_message) as keywords 				
		from
		-- activity
		(select a.activity_id, a.start_date, a.end_date, a.tags
		from activity a
		where a.active = true and a.activity_id = $1) a
		left join
		-- Location
		(select l.activity_id, array_to_string(array_agg(distinct l.gaul2_name || ', ' || l.gaul1_name || ', ' || l.gaul0_name ), ',') as name
		from location_lookup l		
		where l.activity_id = $1
		group by l.activity_id) as l
		on a.activity_id =  l.activity_id
		left join 
		-- Sector
		(select at.activity_id, array_to_string(array_agg(distinct c.name), ',') as name
		from activity_taxonomy at
		join classification c
		on at.classification_id = c.classification_id
		where c.active = true and c.taxonomy_id = (select taxonomy_id from taxonomy where name = 'Sector')
		and at.activity_id = $1
		group by at.activity_id) as si
		on a.activity_id = si.activity_id
		left join
		-- Activity Status
		(select at.activity_id, array_to_string(array_agg(distinct c.name), ',') as name
		from activity_taxonomy at
		join classification c
		on at.classification_id = c.classification_id
		where  c.active = true
		and c.taxonomy_id =(select taxonomy_id from taxonomy where name = 'Activity Status')
		AND at.activity_id = $1
		group by at.activity_id) s
		on a.activity_id = s.activity_id
	) j
	) LOOP		
		RETURN NEXT rec;
	END LOOP;
   END IF;
END;$$ LANGUAGE plpgsql;

-- info box activity description
CREATE OR REPLACE FUNCTION pmt_infobox_activity_desc(activity_id integer)
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
		select a.activity_id
		       ,coalesce(a.description, data_message) as description
		from activity a
		where a.active = true and a.activity_id = $1	
	) j
	) LOOP		
		RETURN NEXT rec;
	END LOOP;
   END IF;
END;$$ LANGUAGE plpgsql;

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
		(select a.activity_id, a.start_date, a.end_date
		from activity a
		where a.active = true and a.activity_id = $1) a
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
		where pp.active = true and o.active = true and c.active = true 
		and c.taxonomy_id = (select taxonomy_id from taxonomy where name = 'Organisation Role') AND (c.name = 'Implementing' OR c.name = 'Funding')
		and pp.activity_id = $1
		group by pp.activity_id) pt
		on a.activity_id = pt.activity_id
		left join
		-- contacts
		(select ac.activity_id, array_to_string(array_agg(distinct c.first_name || ' ' || c.last_name), ',') as contacts
		from activity_contact ac
		join contact c
		on ac.contact_id = c.contact_id
		where c.active = true and ac.activity_id = $1
		group by ac.activity_id) c
		on a.activity_id = c.activity_id	
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