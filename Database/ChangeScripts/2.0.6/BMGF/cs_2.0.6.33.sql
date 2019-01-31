/******************************************************************
Change Script 2.0.6.33 - Consolidated.
1. pmt_filter_cvs - activities were not being filtered. 
******************************************************************/
INSERT INTO config(version, iteration, changeset) VALUES (2.0, 6,33);
-- select * from config order by version, iteration, changeset, updated_date;

-- select * from pmt_data_groups() --768
-- select * from classification where lower(name) like 'tanzania%' -- 244
-- select * from pmt_filter_cvs('768,244','','',null,null, 'sparadee@spatialdev.com');

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

  IF project_ids IS NOT NULL THEN
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
		AND pp.project_id = pid AND pp.active = true AND o.active = true and c.active = true
		group by pp.project_id) ac
		on p.project_id = ac.project_id
		left join
		-- initiative
		(select pt.project_id, array_to_string(array_agg(c.name), ',') as name
		from project_taxonomy pt
		join classification c
		on pt.classification_id = c.classification_id
		where c.taxonomy_id = (select taxonomy_id from taxonomy where name = 'Initiative')
		AND pt.project_id = pid and c.active = true
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
		and p.project_id = pid and c.active = true
		group by p.project_id) as fc
		on p.project_id = fc.project_id
		left join
		-- financials
		(select f.project_id, sum(f.amount) as amount
		from financial f
		where f.activity_id is null and f.project_id = pid and f.active = true
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
		and pp.activity_id is null and pp.project_id = pid and pp.active = true and o.active = true and c.active = true
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
		AND pp.project_id = pid and pp.active = true and o.active = true and c.active = true
		group by pp.project_id) sg
		on p.project_id = sg.project_id
		left join
		-- country
		(select pt.project_id, array_to_string(array_agg(c.name), ',') as country 
		from project_taxonomy pt
		join classification c
		on pt.classification_id = c.classification_id
		where c.taxonomy_id = (select taxonomy_id from taxonomy where name = 'Country')
		AND pt.project_id = pid and c.active = true
		group by pt.project_id) as c
		on p.project_id = c.project_id;
     counter := counter + 1;
     
     -- get the activitiy ids
     SELECT INTO activity_ids string_to_array(a_ids, ',')::int[] FROM pmt_filter_projects($1,$2,$3,$4,$5) WHERE p_id = pid;
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
		where a.activity_id = aid and a.active = true) a
		left join 
		-- Sub-Initiative
		(select at.activity_id, array_to_string(array_agg(c.name), ',') as name
		from activity_taxonomy at
		join classification c
		on at.classification_id = c.classification_id
		where c.taxonomy_id = (select taxonomy_id from taxonomy where name = 'Sub-Initiative')
		and at.activity_id = aid and c.active = true
		group by at.activity_id) as si
		on a.activity_id = si.activity_id
		left join
		-- Country
		(select l.activity_id, array_to_string(array_agg(c.name), ',') as name
		from location l 
		join location_taxonomy lt
		on l.location_id = lt.location_id
		join classification c
		on lt.classification_id = c.classification_id
		where c.taxonomy_id =(select taxonomy_id from taxonomy where name = 'Country')
		AND l.activity_id = aid and l.active = true and c.active = true
		group by l.activity_id) c
		on a.activity_id = c.activity_id
		left join
		-- Activity Status
		(select at.activity_id, array_to_string(array_agg(c.name), ',') as name
		from activity_taxonomy at
		join classification c
		on at.classification_id = c.classification_id
		where c.taxonomy_id =(select taxonomy_id from taxonomy where name = 'Activity Status')
		AND at.activity_id = aid and c.active = true
		group by at.activity_id) s
		on a.activity_id = s.activity_id
		left join
		-- financials
		(select f.activity_id, sum(f.amount) as amount
		from financial f
		where f.activity_id = aid and f.active = true
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
		and pp.activity_id = aid and pp.active = true and o.active = true and c.active = true
		group by pp.activity_id) pt
		on a.activity_id = pt.activity_id
		left join
		-- locations
		(select l.activity_id, array_to_string(array_agg(DISTINCT l.lat_dd || ' ' || l.long_dd), ',') as location
		from location l
		where l.activity_id = aid and l.active = true
		group by l.activity_id) l
		on a.activity_id = l.activity_id;
        counter := counter + 1;
     END LOOP;     
  END LOOP;
  filename := '''/usr/local/pmt_dir/' || $6 || '_' || current_date || '.csv''';
  EXECUTE 'COPY(SELECT c1,c2,c3,c4,c5,c6,c7,c8,c9,c10,c11,c12,c13,c14,c15,c16,c17,c18 FROM csv_data ORDER BY id) To ' || filename || ' With CSV;'; 
  RETURN TRUE;
  ELSE
    RETURN FALSE;
  END IF;
END;$$ LANGUAGE plpgsql;