/******************************************************************
Change Script 2.0.8.32 - consolidated.
1. tanaim_filter_csv - new function for exporting data from tanaim
as csv.
******************************************************************/
INSERT INTO version(version, iteration, changeset) VALUES (2.0, 8, 32);
-- select * from version order by changeset desc;

-- select * from tanaim_filter_csv('1201','','',null,null, 'sparadee@spatialdev.com');

CREATE OR REPLACE FUNCTION tanaim_filter_csv(classification_ids character varying, organization_ids character varying, unassigned_tax_ids character varying, start_date date, end_date date, email text) 
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
  db_instance text;
  db_version text;
  rec record;
BEGIN
  -- create temporary table to hold our data for the csv
  CREATE TEMPORARY TABLE csv_data (
      id int,c1 text,c2 text,c3 text,c4 text,c5 text,c6 text,c7 text,c8 text,c9 text,c10 text
     ,c11 text,c12 text,c13 text,c14 text,c15 text,c16 text,c17 text,c18 text, c19 text, c20 text
     ) ON COMMIT DROP;

  -- get database version	
  SELECT INTO db_version version FROM pmt_version();	
  
  -- build version/date/filter line
  filter := 'PMT 2.0, Database Version ' || db_version || ', Retrieval Date:' || CURRENT_DATE;

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

    -- insert activity header
     INSERT INTO csv_data (id,c1,c2,c3,c4,c5,c6,c7,c8,c9,c10,c11,c12,c13,c14,c15,c16,c17,c18,c19,c20)        	
     		SELECT  counter
			,'Activity Data' 
			,'PMT ActivityID'
			,'S_No'
			,'ProgramName/Sub-Category'
			,'ProgramDescription'
			,'DevelopmentPartners'
			,'ImplementingPartner'
			,'LocalPartners_Collaborators'
			,'InterventionCategory'
			,'InterventionSub-Category'
			,'Activities'
			,'ActivityStatus'
			,'Country'
			,'Region'
			,'District'
			,'TargetBeneficiaries'
			,'Crops_Livestock'
			,'StartDate' 
			,'EndDate'
			,'InvestmentAmount (Tanzanian Shilling)';
     counter := counter + 1;
     	
  -- loop through all projects
  FOREACH pid IN ARRAY project_ids LOOP

     -- get the activitiy ids
     SELECT INTO activity_ids string_to_array(a_ids, ',')::int[] FROM pmt_filter_projects($1,$2,$3,$4,$5) WHERE p_id = pid;
     RAISE NOTICE '  + Activity ids to export: %', activity_ids;
   
     -- loop through all activities
     FOREACH aid IN ARRAY activity_ids LOOP
        RAISE NOTICE '    + Preparing activity id: %', aid;	
        -- insert activity data
	INSERT INTO csv_data (id,c1,c2,c3,c4,c5,c6,c7,c8,c9,c10,c11,c12,c13,c14,c15,c16,c17,c18,c19,c20)        	
		select  counter
			,''::text			-- Activity Data
			,a.activity_id::text		-- PMT ActivityID
			,a.iati_identifier::text	-- S_No
			,a.title::text			-- ProgramName/Sub-Category
			,a.description::text		-- ProgramDescription
			,acc.name::text			-- DevelopmentPartners
			,fund.name::text		-- ImplementingPartner
			,imp.name::text			-- LocalPartners_Collaborators
			,ic.name::text			-- InterventionCategory
			,isc.name::text			-- InterventionSub-Category
			,a.content::text		-- Activities
			,s.name::text			-- Activity Status	
			,c.name::text			-- Country
			,g1.region::text	  	-- Region
			,g2.district::text		-- District
			,a.target_beneficiaries::text	-- TargetBeneficiaries
			,cl.name::text			-- Crops_Livestock
			,a.start_date::text		-- Start Date
			,a.end_date::text		-- End Date
			,f.amount::text			-- InvestmentAmount			
		from
		-- activity
		(select a.activity_id, a.iati_identifier, a.title, a.description, a.start_date, a.end_date, a.target_beneficiaries, a.content
		from activity a
		where a.activity_id = aid and a.active = true) a
		left join 
		-- Category
		(select at.activity_id, array_to_string(array_agg(DISTINCT c.name), ',') as name
		from activity_taxonomy at
		join classification c
		on at.classification_id = c.classification_id
		where c.taxonomy_id = (select taxonomy_id from taxonomy where name = 'Category')
		and at.activity_id = aid and c.active = true
		group by at.activity_id) as ic
		on a.activity_id = ic.activity_id
		left join
		-- Sub-Category
		(select at.activity_id, array_to_string(array_agg(DISTINCT c.name), ',') as name
		from activity_taxonomy at
		join classification c
		on at.classification_id = c.classification_id
		where c.taxonomy_id = (select taxonomy_id from taxonomy where name = 'Sub-Category')
		and at.activity_id = aid and c.active = true
		group by at.activity_id) as isc
		on a.activity_id = isc.activity_id
		left join
		-- Country
		(select l.activity_id, array_to_string(array_agg(DISTINCT c.name), ',') as name
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
		(select at.activity_id, array_to_string(array_agg(DISTINCT c.name), ',') as name
		from activity_taxonomy at
		join classification c
		on at.classification_id = c.classification_id
		where c.taxonomy_id =(select taxonomy_id from taxonomy where name = 'Activity Status')
		AND at.activity_id = aid and c.active = true
		group by at.activity_id) s
		on a.activity_id = s.activity_id
		left join
		-- Crops and Livestock
		(select at.activity_id, array_to_string(array_agg(DISTINCT c.name), ',') as name
		from activity_taxonomy at
		join classification c
		on at.classification_id = c.classification_id
		where c.taxonomy_id =(select taxonomy_id from taxonomy where name = 'Crops and Livestock')
		AND at.activity_id = aid and c.active = true
		group by at.activity_id) cl
		on a.activity_id = cl.activity_id
		left join
		-- financials
		(select f.activity_id, sum(f.amount) as amount
		from financial f
		where f.activity_id = aid and f.active = true
		group by f.activity_id) as f
		on a.activity_id = f.activity_id
		left join
		-- accountable
		(select pp.activity_id, array_to_string(array_agg(DISTINCT o.name), ',') as name, array_to_string(array_agg(DISTINCT c.name), ',') as role
		from participation pp
		join organization o
		on pp.organization_id = o.organization_id
		left join participation_taxonomy ppt
		on pp.participation_id = ppt.participation_id
		join classification c
		on ppt.classification_id = c.classification_id
		where c.taxonomy_id = (select taxonomy_id from taxonomy where name = 'Organisation Role') AND (c.name = 'Accountable')
		and pp.activity_id = aid and pp.active = true and o.active = true and c.active = true
		group by pp.activity_id) acc
		on a.activity_id = acc.activity_id
		left join
		-- funding
		(select pp.activity_id, array_to_string(array_agg(DISTINCT o.name), ',') as name, array_to_string(array_agg(DISTINCT c.name), ',') as role
		from participation pp
		join organization o
		on pp.organization_id = o.organization_id
		left join participation_taxonomy ppt
		on pp.participation_id = ppt.participation_id
		join classification c
		on ppt.classification_id = c.classification_id
		where c.taxonomy_id = (select taxonomy_id from taxonomy where name = 'Organisation Role') AND (c.name = 'Funding')
		and pp.activity_id = aid and pp.active = true and o.active = true and c.active = true
		group by pp.activity_id) fund
		on a.activity_id = fund.activity_id
		left join
		-- implementing
		(select pp.activity_id, array_to_string(array_agg(DISTINCT o.name), ',') as name, array_to_string(array_agg(DISTINCT c.name), ',') as role
		from participation pp
		join organization o
		on pp.organization_id = o.organization_id
		left join participation_taxonomy ppt
		on pp.participation_id = ppt.participation_id
		join classification c
		on ppt.classification_id = c.classification_id
		where c.taxonomy_id = (select taxonomy_id from taxonomy where name = 'Organisation Role') AND (c.name = 'Implementing')
		and pp.activity_id = aid and pp.active = true and o.active = true and c.active = true
		group by pp.activity_id) imp
		on a.activity_id = imp.activity_id
		left join
		-- regions
		(select ll.activity_id, array_to_string(array_agg(DISTINCT gaul1_name), ',') as region
		from location_lookup ll 
		group by ll.activity_id) g1
		on a.activity_id = g1.activity_id
		left join
		-- districts
		(select ll.activity_id, array_to_string(array_agg(DISTINCT gaul2_name), ',') as district
		from location_lookup ll 
		group by ll.activity_id) g2
		on a.activity_id = g2.activity_id;
        counter := counter + 1;
     END LOOP;     
  END LOOP;
    -- get the database instance (information is used by the server process to use instance specific email message when emailing file)
  SELECT INTO db_instance * FROM current_database();
  filename := '''/usr/local/pmt_dir/' || $6 || '_' || lower(db_instance) || '.csv''';
  EXECUTE 'COPY(SELECT c1,c2,c3,c4,c5,c6,c7,c8,c9,c10,c11,c12,c13,c14,c15,c16,c17,c18,c19,c20 FROM csv_data ORDER BY id) To ' || filename || ' With CSV;'; 
  RETURN TRUE;
  ELSE
    RETURN FALSE;
  END IF;
END;$$ LANGUAGE plpgsql;


-- update permissions
GRANT USAGE ON SCHEMA public TO pmt_read;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO pmt_read;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO pmt_read;
GRANT USAGE ON SCHEMA public TO pmt_write;
GRANT SELECT,INSERT ON ALL TABLES IN SCHEMA public TO pmt_write;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO pmt_write;