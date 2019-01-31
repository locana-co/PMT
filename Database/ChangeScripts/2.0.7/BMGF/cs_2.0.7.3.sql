/******************************************************************
Change Script 2.0.7.3 - Consolidated.
1. Rename pmt_infobox_project_info to bmgf_infobox_project_info
2. Rename pmt_infobox_project_stats to bmgf_infobox_project_stats
3. Rename pmt_infobox_project_desc to bmgf_infobox_project_desc
4. Rename pmt_infobox_project_contact to bmgf_infobox_project_contact
5. Rename pmt_infobox_project_nutrition to bmgf_infobox_project_nutrition
6. Rename pmt_infobox_activity_stats to bmgf_infobox_activity_stats
7. Rename pmt_infobox_activity_contact to bmgf_infobox_activity_contact
8. Rename pmt_infobox_activity_desc to bmgf_infobox_activity_desc
9. Rename pmt_project_list to bmgf_project_list
******************************************************************/
INSERT INTO config(version, iteration, changeset) VALUES (2.0, 7, 3);
-- select * from config order by version, iteration, changeset, updated_date;

-- drop old functions
DROP FUNCTION IF EXISTS pmt_infobox_project_info(integer)  CASCADE;
DROP FUNCTION IF EXISTS pmt_infobox_project_info(integer, integer)  CASCADE;
DROP FUNCTION IF EXISTS pmt_infobox_project_stats(integer)  CASCADE;
DROP FUNCTION IF EXISTS pmt_infobox_project_desc(integer)  CASCADE;
DROP FUNCTION IF EXISTS pmt_infobox_project_contact(integer)  CASCADE;
DROP FUNCTION IF EXISTS pmt_infobox_project_nutrition(integer)  CASCADE;
DROP FUNCTION IF EXISTS pmt_infobox_activity_stats(integer)  CASCADE;
DROP FUNCTION IF EXISTS pmt_infobox_activity_desc(integer)  CASCADE;
DROP FUNCTION IF EXISTS pmt_infobox_activity_contact(integer)  CASCADE;
DROP FUNCTION IF EXISTS pmt_project_list() CASCADE;

-- new drop statements
DROP FUNCTION IF EXISTS bmgf_infobox_project_info(integer, integer)  CASCADE;
DROP FUNCTION IF EXISTS bmgf_infobox_project_stats(integer)  CASCADE;
DROP FUNCTION IF EXISTS bmgf_infobox_project_desc(integer)  CASCADE;
DROP FUNCTION IF EXISTS bmgf_infobox_project_contact(integer)  CASCADE;
DROP FUNCTION IF EXISTS bmgf_infobox_project_nutrition(integer)  CASCADE;
DROP FUNCTION IF EXISTS bmgf_infobox_activity_stats(integer)  CASCADE;
DROP FUNCTION IF EXISTS bmgf_infobox_activity_desc(integer)  CASCADE;
DROP FUNCTION IF EXISTS bmgf_infobox_activity_contact(integer)  CASCADE;
DROP FUNCTION IF EXISTS bmgf_project_list() CASCADE;

-- create new types for all functions
DROP TYPE IF EXISTS bmgf_infobox_result_type;
CREATE TYPE bmgf_infobox_result_type AS (response json);

-- update function names/types
-- info box project general information
CREATE OR REPLACE FUNCTION bmgf_infobox_project_info(project_id integer, tax_id integer)
RETURNS SETOF bmgf_infobox_result_type AS 
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
		      ,coalesce(p.opportunity_id, data_message) as grant_id
		      ,coalesce(pp.name, data_message) as org_name
		      ,coalesce(pp.url, data_message) as org_url
		      ,coalesce(fc.focus_crop, data_message) as focus_crop
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
		(select p.project_id, p.title, p.label, p.opportunity_id, p.tags, p.url
		from project p
		where p.project_id = $1 and p.active = true) p
		left join		
		-- participants
		(select pp.project_id, array_to_string(array_agg(o.name), ',') as name, array_to_string(array_agg(o.url), ',') as url
		from participation pp
		join organization o
		on pp.organization_id = o.organization_id
		left join participation_taxonomy ppt
		on pp.participation_id = ppt.participation_id
		join classification c
		on ppt.classification_id = c.classification_id 
		where c.taxonomy_id = (select taxonomy_id from taxonomy where name = 'Organisation Role') AND c.name = 'Accountable'
		AND pp.project_id = $1 and pp.active = true and o.active = true and c.active = true
		group by pp.project_id) pp
		on p.project_id = pp.project_id
		left join
		-- focus crop
		(select p.project_id, array_to_string(array_agg(c.name), ',') as focus_crop
		from project p 
		join project_taxonomy pt
		on p.project_id = pt.project_id
		join classification c
		on pt.classification_id = c.classification_id
		where c.taxonomy_id = (select taxonomy_id from taxonomy where name = 'Focus Crop')
		and p.project_id = $1 and p.active = true and c.active = true
		group by p.project_id) as fc
		on p.project_id = fc.project_id
	) j
	) LOOP		
		RETURN NEXT rec;
	END LOOP;
   END IF;
END;$$ LANGUAGE plpgsql;

-- info box project stats
CREATE OR REPLACE FUNCTION bmgf_infobox_project_stats(project_id integer)
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
		select p.project_id
		       ,p.start_date
		       ,p.end_date
		       ,coalesce(i.name, data_message) as initiative
		       ,f.amount as grant
		from
		-- project
		(select p.project_id, p.start_date, p.end_date
		from project p
		where p.active = true and p.project_id = $1) p
		left join
		-- initiative
		(select pt.project_id, array_to_string(array_agg(distinct c.name), ',') as  name
		from project_taxonomy pt
		join classification c
		on pt.classification_id = c.classification_id
		where c.active = true and c.taxonomy_id = (select taxonomy_id from taxonomy where name = 'Initiative')
		AND pt.project_id = $1
		group by pt.project_id) as i
		on p.project_id = i.project_id
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
CREATE OR REPLACE FUNCTION bmgf_infobox_project_desc(project_id integer)
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
		select p.project_id
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
CREATE OR REPLACE FUNCTION bmgf_infobox_project_contact(project_id integer)
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

-- info box project nutrition details
CREATE OR REPLACE FUNCTION bmgf_infobox_project_nutrition(project_id integer)
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
		select s.project_id
		       ,coalesce(s.description, data_message) as summary
		       ,coalesce(d.description, data_message) as description
		       ,coalesce(nf.nutrient_focus, data_message) as nutrient_focus
		from
		-- project
		(select p.project_id
		from project p
		where p.active = true and p.project_id = $1) p
		left join
		-- Summary of Activities Related to Nutrition
		(select d.project_id, array_to_string(array_agg(d.description), ',') as description
		from detail d
		where d.title = 'Summary of Activities Related to Nutrition' and d.active = true
		and d.project_id = $1
		group by d.project_id) as s
		on p.project_id = s.project_id
		left join
		-- Description of Activities Related to Nutrition
		(select d.project_id, array_to_string(array_agg(d.description), ',') as description
		from detail d
		where d.title = 'Description of Activities Related to Nutrition' and d.active = true
		and d.project_id = $1
		group by d.project_id) as d
		on p.project_id = d.project_id
		left join
		-- Nutrient Focus
		(select pt.project_id, array_to_string(array_agg(c.name), ',') as nutrient_focus
		from project_taxonomy pt
		join classification c
		on pt.classification_id = c.classification_id
		where c.active = true and c.taxonomy_id = (select taxonomy_id from taxonomy where name = 'Nutrient Focus')
		and pt.project_id = $1
		group by pt.project_id) as nf
		on p.project_id = nf.project_id	
	) j
	) LOOP		
		RETURN NEXT rec;
	END LOOP;
   END IF;
END;$$ LANGUAGE plpgsql;

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
		       ,coalesce(a.city_village, data_message) as location
		       ,coalesce(a.tags, data_message) as keywords 				
		from
		-- activity
		(select a.activity_id, a.start_date, a.end_date, a.content, a.tags, a.city_village
		from activity a
		where a.active = true and a.activity_id = $1) a
		left join 
		-- Sub-Initiative
		(select at.activity_id, array_to_string(array_agg(distinct c.name), ',') as name
		from activity_taxonomy at
		join classification c
		on at.classification_id = c.classification_id
		where c.active = true and c.taxonomy_id = (select taxonomy_id from taxonomy where name = 'Sub-Initiative')
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
CREATE OR REPLACE FUNCTION bmgf_infobox_activity_desc(activity_id integer)
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
CREATE OR REPLACE FUNCTION bmgf_infobox_activity_contact(activity_id integer)
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
		select  a.activity_id
		       ,coalesce(pt.partners, data_message) as partners 
		       ,coalesce(c.contacts, data_message) as contacts
		from
		-- activity
		(select a.activity_id, a.start_date, a.end_date, a.content
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

-- project list view
CREATE OR REPLACE FUNCTION bmgf_project_list()
RETURNS SETOF bmgf_infobox_result_type AS 
$$
DECLARE
  rec record;
BEGIN
	FOR rec IN (
	select row_to_json(j)
	from
	(
		select  p.project_id AS p_id
			,p.title
			,a.activity_ids AS a_ids
			,pa.orgs AS org
			,pf.funding_orgs AS f_orgs
			,i.initiative AS init
		from
		-- project
		(select p.project_id, p.title, p.opportunity_id
		from project p
		where p.active = true) p
		left join
		-- activity
		(select a.project_id, array_to_string(array_agg(distinct a.activity_id ), ',') as activity_ids
		from activity a
		where a.active = true
		group by a.project_id) a
		on p.project_id = a.project_id
		left join
		-- participants (Accountable)
		(select pp.project_id, array_to_string(array_agg(distinct o.name), ',') as orgs
		from participation pp
		join organization o
		on pp.organization_id = o.organization_id
		left join participation_taxonomy ppt
		on pp.participation_id = ppt.participation_id
		join classification c
		on ppt.classification_id = c.classification_id 
		where c.taxonomy_id = (select taxonomy_id from taxonomy where name = 'Organisation Role') AND c.name = 'Accountable'
		group by pp.project_id) pa
		on p.project_id = pa.project_id
		left join
		-- participants (Funding)
		(select pp.project_id, array_to_string(array_agg(distinct o.name), ',') as funding_orgs 
		from participation pp
		join organization o
		on pp.organization_id = o.organization_id
		left join participation_taxonomy ppt
		on pp.participation_id = ppt.participation_id
		join classification c
		on ppt.classification_id = c.classification_id 
		where c.taxonomy_id = (select taxonomy_id from taxonomy where name = 'Organisation Role') AND (c.name = 'Funding')
		group by pp.project_id) pf
		on p.project_id = pf.project_id
		left join
		-- initiative
		(select pt.project_id, array_to_string(array_agg(distinct c.name), ',') as  initiative
		from project_taxonomy pt
		join classification c
		on pt.classification_id = c.classification_id
		where c.taxonomy_id = (select taxonomy_id from taxonomy where name = 'Initiative')
		group by pt.project_id) as i
		on p.project_id = i.project_id		
	) j
	) LOOP		
		RETURN NEXT rec;
	END LOOP;
END;$$ LANGUAGE plpgsql;

-- update permissions
GRANT USAGE ON SCHEMA public TO pmt_read;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO pmt_read;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO pmt_read;
GRANT USAGE ON SCHEMA public TO pmt_write;
GRANT SELECT,INSERT ON ALL TABLES IN SCHEMA public TO pmt_write;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO pmt_write;