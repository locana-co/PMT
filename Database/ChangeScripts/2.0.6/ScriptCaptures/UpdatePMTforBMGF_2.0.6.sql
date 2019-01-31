/*********************************************************************
	BMGF Database Creation Script	
This script will add the BMGF specific features.
**********************************************************************/
--Drop Views  (if they exist)
DROP VIEW IF EXISTS data_loading_report;

--Drop Functions
DROP FUNCTION IF EXISTS pmt_infobox_project_info(integer)  CASCADE;
DROP FUNCTION IF EXISTS pmt_infobox_project_stats(integer)  CASCADE;
DROP FUNCTION IF EXISTS pmt_infobox_project_desc(integer)  CASCADE;
DROP FUNCTION IF EXISTS pmt_infobox_project_contact(integer)  CASCADE;
DROP FUNCTION IF EXISTS pmt_infobox_project_nutrition(integer)  CASCADE;
DROP FUNCTION IF EXISTS pmt_infobox_activity_stats(integer)  CASCADE;
DROP FUNCTION IF EXISTS pmt_infobox_activity_desc(integer)  CASCADE;
DROP FUNCTION IF EXISTS pmt_infobox_activity_contact(integer)  CASCADE;
DROP FUNCTION IF EXISTS pmt_filter_cvs(character varying, character varying, character varying, date, date) CASCADE;
DROP FUNCTION IF EXISTS pmt_project_list() CASCADE;

--Drop Types  (if it exists)
DROP TYPE IF EXISTS pmt_infobox_result_type;

/*****************************************************************
ENTITY -- update entities.
******************************************************************/
--Activity
ALTER TABLE "activity" ADD COLUMN "opportunity_id" character varying;
ALTER TABLE "activity" ADD COLUMN "city_village"   character varying;	

--Project
ALTER TABLE "project" ADD COLUMN "impact" 		character varying;
ALTER TABLE "project" ADD COLUMN "people_affected"	integer;
ALTER TABLE "project" ADD COLUMN "fte"			integer;
ALTER TABLE "project" ADD COLUMN "opportunity_id"	character varying;	
           
/*****************************************************************
Functions -- is procedural code that is executed when called.
Create FUNCTIONS:
	1.  pmt_infobox_menu - given a list of locations, returns
	json of associated project & activities for the purpose of 
	building the info box menu.
	2.  pmt_infobox_project_info - returns json of project information 
	for a given project id for the info box.
	3. pmt_infobox_project_stats - returns json of project stats 
	for a given project id for the info box.
	4.  pmt_infobox_project_desc - returns json of project description 
	for a given project id for the info box.
	5.  pmt_infobox_project_contact - returns json of project contacts  
	and partners for a given project id for the info box.
	6.  pmt_infobox_project_nutrition - returns json of project nutrition 
	data for a given project id for the info box.
	7.  pmt_infobox_activity_stats - returns json of activity information 
	for a given activity id for the info box.
	8.  pmt_infobox_activity_desc - returns json of activity description 
	for a given activity id for the info box.
	9.  pmt_infobox_activity_contact - returns json of activity contacts 
	and partners for a given activity id for the info box.
	10. pmt_filter_cvs - exports data to cvs based using the 
	pmt_filter_projects function.
	11. pmt_project_list - returns json of all project ids, titles, 
	organizations, intitatives and activity ids

******************************************************************/

-- create types for all functions
CREATE TYPE pmt_infobox_result_type AS (response json);

-- info box project general information
CREATE OR REPLACE FUNCTION pmt_infobox_project_info(project_id integer)
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
		-- project general information
		select p.project_id
		      ,coalesce(p.label, p.title, data_message) as title				
		      ,coalesce(p.opportunity_id, data_message) as grant_id
		      ,coalesce(pp.name, data_message) as org_name
		      ,coalesce(pp.url, data_message) as org_url
		      ,coalesce(fc.focus_crop, data_message) as focus_crop
		      ,coalesce(p.tags, data_message) as keywords
		      ,coalesce(p.url, data_message) as project_url
		from
		-- project
		(select p.project_id, p.title, p.label, p.opportunity_id, p.tags, p.url
		from project p
		where p.project_id = $1) p
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
		AND pp.project_id = $1
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
		and p.project_id = $1
		group by p.project_id) as fc
		on p.project_id = fc.project_id
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
		       ,coalesce(i.name, data_message) as initiative
		       ,f.amount as grant
		from
		-- project
		(select p.project_id, p.start_date, p.end_date
		from project p
		where p.project_id = $1) p
		left join
		-- initiative
		(select pt.project_id, array_to_string(array_agg(distinct c.name), ',') as  name
		from project_taxonomy pt
		join classification c
		on pt.classification_id = c.classification_id
		where c.taxonomy_id = (select taxonomy_id from taxonomy where name = 'Initiative')
		AND pt.project_id = $1
		group by pt.project_id) as i
		on p.project_id = i.project_id
		left join
		-- financials
		(select f.project_id, sum(f.amount) as amount
		from financial f
		where f.activity_id is null and f.project_id = $1
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
		       ,coalesce(p.description, data_message) as description
		from project p
		where p.project_id = $1	
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
		where c.taxonomy_id = (select taxonomy_id from taxonomy where name = 'Organisation Role') AND (c.name = 'Implementing' OR c.name = 'Funding')
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

-- info box project nutrition details
CREATE OR REPLACE FUNCTION pmt_infobox_project_nutrition(project_id integer)
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
		select s.project_id
		       ,coalesce(s.description, data_message) as summary
		       ,coalesce(d.description, data_message) as description
		       ,coalesce(nf.nutrient_focus, data_message) as nutrient_focus
		from
		-- project
		(select p.project_id
		from project p
		where p.project_id = $1) p
		left join
		-- Summary of Activities Related to Nutrition
		(select d.project_id, array_to_string(array_agg(d.description), ',') as description
		from detail d
		where d.title = 'Summary of Activities Related to Nutrition'
		and d.project_id = $1
		group by d.project_id) as s
		on p.project_id = s.project_id
		left join
		-- Description of Activities Related to Nutrition
		(select d.project_id, array_to_string(array_agg(d.description), ',') as description
		from detail d
		where d.title = 'Description of Activities Related to Nutrition'
		and d.project_id = $1
		group by d.project_id) as d
		on p.project_id = d.project_id
		left join
		-- Nutrient Focus
		(select pt.project_id, array_to_string(array_agg(c.name), ',') as nutrient_focus
		from project_taxonomy pt
		join classification c
		on pt.classification_id = c.classification_id
		where c.taxonomy_id = (select taxonomy_id from taxonomy where name = 'Nutrient Focus')
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
		       ,coalesce(a.content, data_message) as content
		       ,coalesce(si.name, data_message) as sub_initiative
		       ,coalesce(s.name, data_message) as status
		       ,coalesce(a.city_village, data_message) as location
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
		where a.activity_id = $1	
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
		(select a.activity_id, a.start_date, a.end_date, a.content
		from activity a
		where a.activity_id = $1) a
		left join
		-- all partners
		(select pp.activity_id, array_to_string(distinct array_agg(o.name), ',') as partners
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

-- export to cvs 
CREATE OR REPLACE FUNCTION pmt_filter_cvs(classification_ids character varying, organization_ids character varying, unassigned_tax_ids character varying, start_date date, end_date date, email text) 
    RETURNS BOOLEAN AS $$
DECLARE
  project_ids int[];	
  activity_ids int[];
  pid int;
  aid int;
  counter int;
  filter_classids integer array;
  filter_orgids integer array;
  filter text;
  disclaimer text;
  filename text;
  rec record;
BEGIN
  -- create temporary table to hold our data for the csv
  CREATE TEMPORARY TABLE csv_data (
      id int,c1 text,c2 text,c3 text,c4 text,c5 text,c6 text,c7 text,c8 text,c9 text,c10 text
     ,c11 text,c12 text,c13 text,c14 text,c15 text,c16 text,c17 text,c18 text
     ) ON COMMIT DROP;

  -- build version/date/filter line
  filter := 'PMT 2.0, Database Version 2.04, Retrieval Date:' || CURRENT_DATE;

  IF ($1 is null OR $1 = '') AND ($2 is null OR $2 = '')  AND ($3 is null OR $4 is null) THEN
    filter := filter || ',Filters: none';	    
  ELSE
    filter_classids := string_to_array($1, ',')::int[]; 
    filter_orgids := string_to_array($2, ',')::int[]; 
    filter := filter || ',Filters: ';
    IF array_length(filter_classids, 1) > 0 THEN
      FOR rec IN (SELECT tc.taxonomy, array_to_string(array_agg(tc.classification), ',') AS classification FROM taxonomy_classifications tc 
	  WHERE classification_id = ANY(filter_classids) GROUP BY tc.taxonomy) LOOP
	  filter := filter || rec.taxonomy || '=' || rec.classification || ' | ';
      END LOOP;
    END IF;
    IF array_length(filter_orgids, 1) > 0 THEN
      FOR rec IN (SELECT array_to_string(array_agg(o.name), ',') as names FROM organization o WHERE organization_id = ANY(filter_orgids)) LOOP
         filter := filter || 'Organization=' || rec.names || ' | ';
      END LOOP;
    END IF;
    IF $3 is not null AND $4 is not null THEN
      filter := filter || 'DateRange=' || $3 || ' to ' || $4 || ' | ';
    END IF;
  END IF;

  disclaimer := 'Disclaimer: TEXT';
  
  -- get the project ids
  SELECT INTO project_ids array_agg(p_id)::int[] FROM pmt_filter_projects($1,$2,$3,$4,$5);
  RAISE NOTICE 'Project ids to export: %', project_ids;

  -- start record counter, used to ensure the proper order of rows
  counter := 1;

  -- write the filter
  INSERT INTO csv_data (id,c1) SELECT counter, filter;
  counter := counter + 1;
  -- write the disclaimer
  INSERT INTO csv_data (id,c1) SELECT counter, disclaimer;
  counter := counter + 1;
  	
  -- loop through all projects
  FOREACH pid IN ARRAY project_ids LOOP
     RAISE NOTICE '  + Preparing project id: %', pid;
        -- insert project header
	INSERT INTO csv_data (id,c1,c2,c3,c4,c5,c6,c7,c8,c9,c10,c11,c12,c13,c14,c15,c16,c17,c18)	
		-- Project Query
		SELECT  counter
			,'Project Data' 
			,'PMT ProjectID'
			,'OppID'
			,'Organization'
			,'Organization Website'
			,'Project Name'
			,'Project Description'
			,'Initiative'
			,'Focus Crop'
			,'Start Date'
			,'End Date'
			,'Grant Amount'
			,'Population Affected'
			,'FTEs'
			,'Partners'
			,'Project Website'
			,'Sub Grantees'
			,'Country';	
	counter := counter + 1;
	-- insert project data 
	INSERT INTO csv_data (id,c1,c2,c3,c4,c5,c6,c7,c8,c9,c10,c11,c12,c13,c14,c15,c16,c17,c18)	 
		select  counter
			,''::text			-- Project Data
			,p.project_id::text		-- PMT ProjectID
			,p.opportunity_id::text		-- OppID
			,ac.name::text			-- Organization
			,ac.url::text			-- Organization Website
			,p.title::text			-- Project Name
			,p.description::text		-- Project Description
			,i.name::text			-- Initiative
			,fc.focus_crop::text		-- Focus Crop
			,p.start_date::text		-- Start Date
			,p.end_date::text		-- End Date
			,f.amount::text			-- Grant Amount
			,p.people_affected::text	-- Population Affected
			,p.fte::text			-- FTEs
			,pt.partners::text		-- Partners
			,p.url::text			-- Project Website
			,sg.sub_grantees::text		-- Sub Grantees
			,c.country::text		-- Country
		from
		-- project
		(select p.project_id, p.title, p.description, p.opportunity_id, p.start_date, p.end_date, p.people_affected, p.fte, p.url
		from project p
		where p.project_id = pid) p
		left join
		-- accountable organization
		(select pp.project_id, array_to_string(array_agg(o.name), ',') as name, array_to_string(array_agg(o.url), ',') as url
		from participation pp
		join organization o
		on pp.organization_id = o.organization_id
		left join participation_taxonomy ppt
		on pp.participation_id = ppt.participation_id
		join classification c
		on ppt.classification_id = c.classification_id 
		where c.taxonomy_id = (select taxonomy_id from taxonomy where name = 'Organisation Role') AND c.name = 'Accountable'
		AND pp.project_id = pid
		group by pp.project_id) ac
		on p.project_id = ac.project_id
		left join
		-- initiative
		(select pt.project_id, array_to_string(array_agg(c.name), ',') as name
		from project_taxonomy pt
		join classification c
		on pt.classification_id = c.classification_id
		where c.taxonomy_id = (select taxonomy_id from taxonomy where name = 'Initiative')
		AND pt.project_id = pid
		group by pt.project_id) as i
		on p.project_id = i.project_id
		left join
		-- focus crop
		(select p.project_id, array_to_string(array_agg(c.name), ',') as focus_crop
		from project p 
		join project_taxonomy pt
		on p.project_id = pt.project_id
		join classification c
		on pt.classification_id = c.classification_id
		where c.taxonomy_id = (select taxonomy_id from taxonomy where name = 'Focus Crop')
		and p.project_id = pid
		group by p.project_id) as fc
		on p.project_id = fc.project_id
		left join
		-- financials
		(select f.project_id, sum(f.amount) as amount
		from financial f
		where f.activity_id is null and f.project_id = pid
		group by f.project_id) as f
		on p.project_id = f.project_id
		left join
		-- all partners
		(select pp.project_id, array_to_string(array_agg(o.name), ',') as partners
		from participation pp
		join organization o
		on pp.organization_id = o.organization_id
		left join participation_taxonomy ppt
		on pp.participation_id = ppt.participation_id
		join classification c
		on ppt.classification_id = c.classification_id
		where c.taxonomy_id = (select taxonomy_id from taxonomy where name = 'Organisation Role') AND (c.name = 'Implementing' OR c.name = 'Funding')
		and pp.activity_id is null and pp.project_id = pid
		group by pp.project_id) pt
		on p.project_id = pt.project_id
		left join
		-- implementing organizations (sub-grantees)
		(select pp.project_id, array_to_string(array_agg(o.name), ',') as sub_grantees
		from participation pp
		join organization o
		on pp.organization_id = o.organization_id
		left join participation_taxonomy ppt
		on pp.participation_id = ppt.participation_id
		join classification c
		on ppt.classification_id = c.classification_id 
		where c.taxonomy_id = (select taxonomy_id from taxonomy where name = 'Organisation Role') AND c.name = 'Implementing'
		AND pp.project_id = pid
		group by pp.project_id) sg
		on p.project_id = sg.project_id
		left join
		-- country
		(select pt.project_id, array_to_string(array_agg(c.name), ',') as country 
		from project_taxonomy pt
		join classification c
		on pt.classification_id = c.classification_id
		where c.taxonomy_id = (select taxonomy_id from taxonomy where name = 'Country')
		AND pt.project_id = pid
		group by pt.project_id) as c
		on p.project_id = c.project_id;
     counter := counter + 1;
     
     -- get the activitiy ids
     SELECT INTO activity_ids string_to_array(a_ids, ',')::int[] FROM pmt_filter_projects('','','',null,null) WHERE p_id = pid;
     RAISE NOTICE '  + Activity ids to export: %', activity_ids;
     -- insert activity header
     INSERT INTO csv_data (id,c1,c2,c3,c4,c5,c6,c7,c8,c9,c10,c11,c12,c13,c14,c15,c16)        	
     		SELECT  counter
			,'Activity Data' 
			,'PMT ActivityID'
			,'OppID'
			,'Activity Title'
			,'Activity Description'
			,'BMGF Sub-Initiative'
			,'Latitude Longitude'
			,'Country'
			,'City Village'
			,'Partners'
			,'Partner Role'
			,'Start Date'
			,'End Date'
			,'Award Amount Allocated'
			,'Activity Status'	
			,'Keywords';
     counter := counter + 1;
     -- loop through all activities
     FOREACH aid IN ARRAY activity_ids LOOP
        RAISE NOTICE '    + Preparing activity id: %', aid;	
        -- insert activity data
	INSERT INTO csv_data (id,c1,c2,c3,c4,c5,c6,c7,c8,c9,c10,c11,c12,c13,c14,c15,c16)         	
		select  counter
			,''::text			-- Activity Data
			,a.activity_id::text		-- PMT ActivityID
			,a.opportunity_id::text		-- OppID
			,a.title::text			-- Activity Title
			,a.description::text		-- Activity Description
			,si.name::text			-- BMGF Sub-Initiative
			,l.location::text		-- Latitude Longitude
			,c.name::text			-- Country
			,a.city_village::text		-- City Village			
			,pt.partners::text		-- Partners
			,pt.role::text			-- Partner Role
			,a.start_date::text		-- Start Date
			,a.end_date::text		-- End Date
			,f.amount::text			-- Award Amount Allocated
			,s.name::text			-- Activity Status	
			,a.tags::text			-- Keywords
		from
		-- activity
		(select a.activity_id, a.opportunity_id, a.title, a.description, a.start_date, a.end_date, a.tags, a.city_village
		from activity a
		where a.activity_id = aid) a
		left join 
		-- Sub-Initiative
		(select at.activity_id, array_to_string(array_agg(c.name), ',') as name
		from activity_taxonomy at
		join classification c
		on at.classification_id = c.classification_id
		where c.taxonomy_id = (select taxonomy_id from taxonomy where name = 'Sub-Initiative')
		and at.activity_id = aid
		group by at.activity_id) as si
		on a.activity_id = si.activity_id
		left join
		-- Country
		(select at.activity_id, array_to_string(array_agg(c.name), ',') as name
		from activity_taxonomy at
		join classification c
		on at.classification_id = c.classification_id
		where c.taxonomy_id =(select taxonomy_id from taxonomy where name = 'Country')
		AND at.activity_id = aid
		group by at.activity_id) c
		on a.activity_id = c.activity_id
		left join
		-- Activity Status
		(select at.activity_id, array_to_string(array_agg(c.name), ',') as name
		from activity_taxonomy at
		join classification c
		on at.classification_id = c.classification_id
		where c.taxonomy_id =(select taxonomy_id from taxonomy where name = 'Activity Status')
		AND at.activity_id = aid
		group by at.activity_id) s
		on a.activity_id = s.activity_id
		left join
		-- financials
		(select f.activity_id, sum(f.amount) as amount
		from financial f
		where f.activity_id = aid
		group by f.activity_id) as f
		on a.activity_id = f.activity_id
		left join
		-- all partners
		(select pp.activity_id, array_to_string(array_agg(o.name), ',') as partners, array_to_string(array_agg(DISTINCT c.name), ',') as role
		from participation pp
		join organization o
		on pp.organization_id = o.organization_id
		left join participation_taxonomy ppt
		on pp.participation_id = ppt.participation_id
		join classification c
		on ppt.classification_id = c.classification_id
		where c.taxonomy_id = (select taxonomy_id from taxonomy where name = 'Organisation Role') AND (c.name = 'Implementing' OR c.name = 'Funding')
		and pp.activity_id = aid
		group by pp.activity_id) pt
		on a.activity_id = pt.activity_id
		left join
		-- locations
		(select l.activity_id, array_to_string(array_agg(DISTINCT l.lat_dd || ' ' || l.long_dd), ',') as location
		from location l
		where l.activity_id = aid
		group by l.activity_id) l
		on a.activity_id = l.activity_id;
        counter := counter + 1;
     END LOOP;     
  END LOOP;
  filename := '''/usr/local/pmt_dir/' || $6 || '_' || current_date || '.csv''';
  EXECUTE 'COPY(SELECT c1,c2,c3,c4,c5,c6,c7,c8,c9,c10,c11,c12,c13,c14,c15,c16,c17,c18 FROM csv_data ORDER BY id) To ' || filename || ' With CSV;'; 
  RETURN TRUE;
END;$$ LANGUAGE plpgsql;

-- project list view
CREATE OR REPLACE FUNCTION pmt_project_list()
RETURNS SETOF pmt_infobox_result_type AS 
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

/*****************************************************************
VIEWS -- under development and not final. Currently for the 
purpose checking validitiy of data migration.
******************************************************************/
-------------------------------------------------------------------
-- Data Loading Report for record counts
-------------------------------------------------------------------
CREATE OR REPLACE VIEW data_loading_report
AS SELECT 'activity table' as "table", COUNT(*)::integer AS "current record count", 6970 AS "correct record count", 'Populated by LoadBMGFData.sql & ScrubBMGFData.sql' as "comments" FROM activity
UNION ALL
SELECT 'activity_contact junction table' as "table", COUNT(*)::integer AS "current record count", 78 AS "correct record count", 'Populated by LoadBMGFData.sql & ScrubBMGFData.sql' as "comments" FROM activity_contact
UNION ALL
SELECT 'activity_taxonomy junction table' as "table", COUNT(*)::integer AS "current record count", 10060 AS "correct record count", 'Populated by LoadBMGFData.sql & ScrubBMGFData.sql' as "comments" FROM activity_taxonomy
UNION ALL
SELECT 'boundary table' as "table", COUNT(*) AS "current record count", 3 AS "correct record count", 'Populated by CreatePMTSpatialData(n).sql' as "comments" FROM boundary			
UNION ALL
SELECT 'boundary_taxonomy junction table' as "table", COUNT(*) AS "current record count", 0 AS "correct record count", 'Currently does not contain data.' as "comments" FROM boundary_taxonomy			
UNION ALL
SELECT 'contact table' as "table", COUNT(*) AS "current record count", 340 AS "correct record count", 'Populated by LoadBMGFData.sql & ScrubBMGFData.sql' as "comments" FROM contact			
UNION ALL
SELECT 'contact_taxonomy junction table' as "table", COUNT(*) AS "current record count", 0 AS "correct record count", 'Currently does not contain data.' as "comments" FROM contact_taxonomy
UNION ALL
SELECT 'detail table' as "table", COUNT(*) AS "current record count", 155 AS "correct record count", 'Populated by LoadBMGFNutritionData.sql.' as "comments" FROM detail
UNION ALL
SELECT 'feature_taxonomy junction table' as "table", COUNT(*) AS "current record count", 277 AS "correct record count", 'Populated by AddTaxonomyGAUL0.sql.' as "comments" FROM feature_taxonomy
UNION ALL
SELECT 'financial table' as "table", COUNT(*) AS "current record count", 1274 AS "correct record count", 'Populated by LoadBMGFData.sql & ScrubBMGFData.sql' as "comments" FROM financial			
UNION ALL
SELECT 'financial_taxonomy junction table' as "table", COUNT(*) AS "current record count", 0 AS "correct record count", 'Currently does not contain data.' as "comments" FROM financial_taxonomy		
UNION ALL
SELECT 'gaul0 table' as "table", COUNT(*) AS "current record count", 277 AS "correct record count", 'Populated by CreatePMTSpatialData(n).sql' as "comments" FROM gaul0
UNION ALL
SELECT 'gaul1 table' as "table", COUNT (*) AS "current record count", 3469 AS "correct record count", 'Populated by CreatePMTSpatialData(n).sql' as "comments" FROM gaul1
UNION ALL
SELECT 'gaul2 table' as "table", COUNT(*) AS "current record count", 37378 AS "correct record count", 'Populated by CreatePMTSpatialData(n).sql' as "comments" FROM gaul2
UNION ALL
SELECT 'location table' as "table", COUNT(*) AS "current record count", 8045 AS "correct record count", 'Populated by LoadBMGFData.sql & ScrubBMGFData.sql' as "comments" FROM location 
UNION ALL
SELECT 'location_boundary junction table' as "table", COUNT(*) AS "current record count", 18118 AS "correct record count", 'Populated by CreatePMTSpatialData(n).sql' as "comments" FROM location_boundary
UNION ALL
SELECT 'location_taxonomy junction table' as "table", COUNT(*) AS "current record count", 8007 AS "correct record count", 'Populated by LoadBMGFData.sql.' as "comments" FROM location_taxonomy
UNION ALL
SELECT 'organization table' as "table", COUNT(*) AS "current record count", 1182 AS "correct record count", 'Populated by LoadBMGFData.sql & ScrubBMGFData.sql' as "comments" FROM organization		
UNION ALL
SELECT 'organization_taxonomy junction table' as "table", COUNT(*) AS "current record count", 0 AS "correct record count", 'Currently does not contain data.' as "comments" FROM organization_taxonomy	
UNION ALL
SELECT 'participation table' as "table", COUNT(*) AS "current record count", 6543 AS "correct record count", 'Populated by LoadBMGFData.sql & ScrubBMGFData.sql' as "comments" FROM participation
UNION ALL
SELECT 'participation_taxonomy junction table' as "table", COUNT(*) AS "current record count", 6594 AS "correct record count", 'Populated by LoadBMGFData.sql & ScrubBMGFData.sql' as "comments" FROM participation_taxonomy
UNION ALL
SELECT 'project table' as "table", COUNT(*) AS "current record count", 373 AS "correct record count", 'Populated by LoadBMGFData.sql & ScrubBMGFData.sql' as "comments" FROM project			
UNION ALL
SELECT 'project_contact junction table' as "table", COUNT(*) AS "current record count", 131 AS "correct record count", 'Populated by LoadBMGFData.sql & ScrubBMGFData.sql' as "comments" FROM project_contact
UNION ALL
SELECT 'project_taxonomy junction table' as "table", COUNT(*) AS "current record count", 1076 AS "correct record count", 'Populated by LoadBMGFData.sql, ScrubBMGFData.sql & LoadBMGFNutritionData.sql.' as "comments" FROM project_taxonomy
UNION ALL
SELECT 'result table' as "table", COUNT(*) AS "current record count", 0 AS "correct record count", 'Currently does not contain data.' as "comments" FROM result			
UNION ALL
SELECT 'result_taxonomy junction table' as "table", COUNT(*) AS "current record count", 0 AS "correct record count", 'Currently does not contain data.' as "comments" FROM result_taxonomy
UNION ALL
SELECT 'classification table' as "table", COUNT(*) AS "current record count", 854 AS "correct record count", 'Populated by LoadBMGFData.sql, ScrubBMGFData.sql, LoadBMGFNutritionData.sql & LoadIATIStandards.sql.' as "comments" FROM classification
UNION ALL
SELECT 'taxonomy table' as "table", COUNT(*) AS "current record count", 27 AS "correct record count", 'Populated by LoadBMGFData.sql, ScrubBMGFData.sql, LoadBMGFNutritionData.sql & LoadIATIStandards.sql.' as "comments" FROM taxonomy;

