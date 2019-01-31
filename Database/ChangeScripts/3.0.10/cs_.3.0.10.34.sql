/******************************************************************
Change Script 3.0.10.34
1. Create a pmt_filter_string function that has the same signature as pmt_filter and returns a "pretty string" of selected filters for the csv functions. 
2. Update all export functions to use centralized logic.
******************************************************************/
INSERT INTO version(_version, _iteration, _changeset) VALUES (3.0, 10, 34);
-- select * from version order by _iteration desc, _changeset desc;

/******************************************************************
1. Create a pmt_filter_string function

   SELECT * FROM pmt_filter_string('768','831','1681','','','1/1/2012','12/31/2018','23');
   SELECT * FROM pmt_filter_string('768','831','1681','','',null,'12/31/2018','23');
   SELECT * FROM pmt_filter_string('768','831','1681','','','1/1/2010','12/31/2018','23');
   SELECT * FROM pmt_filter_string('768,769','831','1681,1682','','','1/1/2010', null,'23');
   SELECT * FROM pmt_filter_string('768','831,842','1681','','','1/1/2010', null,'23');
   SELECT * FROM pmt_filter_string('768,769','','','275,1681','2737',null,null,'23');
   SELECT * FROM pmt_filter_string('768','','','','',null,null,'23, 24');
   SELECT * FROM pmt_filter_string('768,769','831','1681,1682','','','1/1/2010', null,'23,24');
   SELECT * FROM pmt_export('768,769','','','275,1681','2737',null,null,'23');
   SELECT * FROM pmt_filter_string('768','831','1681','','','1/1/2012','12/31/2018','23');

********************************************************************/

CREATE OR REPLACE FUNCTION pmt_filter_string(data_group_ids character varying, classification_ids character varying, org_ids character varying, imp_org_ids character varying, fund_org_ids character varying, start_date date, end_date date, unassigned_taxonomy_ids character varying)
  RETURNS character varying AS
$BODY$
DECLARE 
  error_msg character varying;
  filter_str character varying;
  filter character varying;
  filter_classids int[];
  filter_orgids int[];
  filter_imporgs int[];
  filter_fundorgs int[];
  filter_unassgntax int[];
  rec record;
  db_version character varying;
  element record;
  startdate text;
  enddate text;
BEGIN 

  -- get database version
  FOR element IN SELECT * FROM json_each( (SELECT * from pmt_version()) ) LOOP
   IF element.key = 'pmt_version' THEN
        -- remove quotes from json string
	db_version = replace(element.value::text, '"', '');
	RAISE NOTICE 'db version: %', db_version;
   END IF;
  END LOOP;

  -- build version/date/filter line
  filter = 'PMT 3.0, Database Version ' || db_version || ', Retrieval Date: ' || CURRENT_DATE;

  IF ($1 is null OR $1 = '') AND ($2 is null OR $2 = '')  AND ($3 is null OR $3 = '') AND ($4 is null OR $4 = '') AND ($5 is null OR $5 = '') AND ($6 is null ) AND ($7 is null) AND ($8 is null OR $8 = '') THEN
    filter := filter || ', Filters: None';     
  ELSE
    -- concat data group ids with classification_ids
    filter_classids :=  array_cat(string_to_array($1, ',')::int[], string_to_array($2, ',')::int[]);
    filter_orgids := string_to_array($3, ',')::int[];
    filter_imporgs = string_to_array($4, ',')::int[]; -- implementing orgs
    filter_fundorgs = string_to_array($5, ',')::int[]; -- funding orgs
    filter_unassgntax = string_to_array($8, ',')::int[]; -- unassigned taxonomies
    filter := filter || ', Filters: ';
    
    -- Classifications
    IF array_length(filter_classids, 1) > 0 THEN
      FOR rec IN (SELECT tc.taxonomy, array_to_string(array_agg(tc.classification), ', ') AS classification FROM _taxonomy_classifications tc 
    WHERE classification_id = ANY(filter_classids) GROUP BY tc.taxonomy) LOOP
    filter := filter || rec.taxonomy || ': ' || rec.classification || ' | ';
      END LOOP;
    END IF;
    -- Unassigned Taxonomies
    --RAISE NOTICE 'unassigned taxonomies: %', filter_unassgntax;
    IF array_length(filter_unassgntax, 1) > 0 THEN
      FOR rec IN(SELECT array_to_string(array_agg(distinct tc.taxonomy), ', ') AS taxonomy FROM _taxonomy_classifications tc 
    WHERE taxonomy_id = ANY(filter_unassgntax)) LOOP
    filter := filter || 'Unassigned taxonomies: ' || rec.taxonomy || ' | ';
      END LOOP;
    END IF;
    -- Orgs
    IF array_length(filter_orgids, 1) > 0 THEN
      FOR rec IN (SELECT array_to_string(array_agg(o._name), ', ') as names FROM organization o WHERE id = ANY(filter_orgids)) LOOP
         filter := filter || 'Organization: ' || rec.names || ' | ';
      END LOOP;
    END IF;
    -- Implementing Organizations
    IF array_length(filter_imporgs, 1) > 0 THEN
      FOR rec IN (SELECT array_to_string(array_agg(o._name), ', ') as names FROM organization o WHERE id = ANY(filter_imporgs)) LOOP
         filter := filter || 'Implementing: ' || rec.names || ' | ';
      END LOOP;
    END IF;
    -- Funding Organizations
    IF array_length(filter_fundorgs, 1) > 0 THEN
      FOR rec IN (SELECT array_to_string(array_agg(o._name), ',') as names FROM organization o WHERE id = ANY(filter_imporgs)) LOOP
         filter := filter || 'Funding: ' || rec.names || ' | ';
      END LOOP;
    END IF;
    -- Date Range
    IF $6 is not null OR $7 is not null THEN
      SELECT INTO startdate * FROM COALESCE($6::text, 'None');
      SELECT INTO enddate * FROM COALESCE($7::text, 'None');      
      filter := filter || 'DateRange: ' || startdate || ' to ' || enddate ;
    END IF;
  END IF;

  RETURN filter;

EXCEPTION WHEN others THEN 
  GET STACKED DIAGNOSTICS error_msg = MESSAGE_TEXT;  
    RAISE NOTICE 'Internal Error - Contact your DBA with the following error message: %', error_msg;
    	
END;$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION pmt_filter(character varying, character varying, character varying, character varying, character varying, date, date, character varying)
  OWNER TO postgres;


/*************************************************************
   2. Update all export functions to use centralized logic
   
**************************************************************/


-- Function: pmt_export(character varying, character varying, character varying, character varying, character varying, date, date, character varying)

-- DROP FUNCTION pmt_export(character varying, character varying, character varying, character varying, character varying, date, date, character varying);

CREATE OR REPLACE FUNCTION pmt_export(data_group_ids character varying, classification_ids character varying, org_ids character varying, imp_org_ids character varying, fund_org_ids character varying, start_date date, end_date date, unassigned_taxonomy_ids character varying)
  RETURNS SETOF pmt_json_result_type AS
$BODY$
DECLARE
  activity_ids int[];
  parent_ids int[];
  no_parent_activities int[];
  children_ids int[];
  pid int;
  aid int;
  counter int;
  filter_classids integer array;
  filter_orgids integer array;
  filter text;
  disclaimer text;
  filename text;
  fileencoding text;
  db_version text;
  db_instance text;
  rec record;
  element record;
  error_msg text;
BEGIN
  -- create temporary table to hold our data for the csv
  CREATE TEMPORARY TABLE csv_data (
      id int,c1 text,c2 text,c3 text,c4 text,c5 text,c6 text,c7 text,c8 text,c9 text,c10 text
     ,c11 text,c12 text,c13 text,c14 text,c15 text,c16 text,c17 text,c18 text
     ) ON COMMIT DROP;

  -- get database version
  FOR element IN SELECT * FROM json_each( (SELECT * from pmt_version()) ) LOOP
   IF element.key = 'pmt_version' THEN
	db_version = element.value;
	RAISE NOTICE 'db version: %', db_version;
   END IF;
  END LOOP;
  
  -- build version/date/filter line
  SELECT INTO filter * FROM pmt_filter_string($1,$2,$3,$4,$5,$6,$7,$8);
  RAISE NOTICE 'filters: %', filter;

  disclaimer := 'Disclaimer: TEXT';
  counter := 1;
 
  -- write the filter
  INSERT INTO csv_data (id,c1) SELECT counter, filter;
  counter := counter + 1;
  -- write the disclaimer
  INSERT INTO csv_data (id,c1) SELECT counter, disclaimer;
  counter := counter + 1;

  SELECT INTO activity_ids * FROM pmt_filter($1,$2,$3,$4,$5,$6,$7,$8);

  -- get activities with no parents
  SELECT INTO no_parent_activities array_agg(id) FROM ((SELECT id FROM activity WHERE id IN (SELECT unnest( (SELECT * FROM pmt_filter($1,$2,$3,$4,$5,$6,$7,$8)) )) AND parent_id IS NULL )
   EXCEPT
  SELECT distinct parent_id from activity where parent_id in ((SELECT id FROM activity WHERE id IN (SELECT unnest( (SELECT * FROM pmt_filter($1,$2,$3,$4,$5,$6,$7,$8)) )) AND parent_id IS NULL ))) j;
   
   -- no activities 
   IF no_parent_activities IS NULL THEN
	no_parent_activities = activity_ids;
	RAISE NOTICE 'activity ids: %', activity_ids; 
   END IF;

  RAISE NOTICE 'non parent activities: %', no_parent_activities;

  -- get all parent activities
  SELECT INTO parent_ids array_agg(distinct parent_id) FROM activity WHERE parent_id IN (SELECT id FROM activity WHERE id IN (SELECT unnest( (SELECT * FROM pmt_filter($1,$2,$3,$4,$5,$6,$7,$8)) )) and parent_id IS NULL);

   -- 1. Add header row and Loop through activities with no children or parents
   -- 2. Loop through parent activities & their children. Add header row for each parent & group of children
 
   -- activity ids with no children or parents

   IF no_parent_activities IS NOT NULL THEN

     -- Add one header row for this group of activities
     INSERT INTO csv_data (id,c1,c2,c3,c4,c5,c6,c7,c8,c9,c10,c11,c12,c13,c14)        	
     		SELECT  counter
			,'Activity Data' 
			,'PMT ActivityID'
			,'Activity Title'
			,'Activity Description'
			,'Sector - Name'
			,'Sector - Code'
			,'Latitude Longitude'
			,'Country'
			,'Funding Organization(s)'
			,'Implementing Organization(s)'
			,'Start Date'
			,'End Date'
			,'Total Budget'
			,'Activity Status';
	counter := counter + 1;
	
	FOREACH pid IN ARRAY no_parent_activities LOOP

	RAISE NOTICE 'Processing activity: %', pid;

	-- Add activity data row to csv
	INSERT INTO csv_data (id,c1,c2,c3,c4,c5,c6,c7,c8,c9,c10,c11,c12,c13,c14)         	
		SELECT  counter
			,''::text			-- Activity Data
			,a.id::text		        -- PMT ActivityID
			,a._title::text			-- Activity Title
			,a._description::text		-- Activity Description
			,s.name::text			-- Sector name
			,s.code::text			-- Sector code
			,l.location::text		-- Latitude Longitude
			,c.name::text			-- Country			
			,fo.funding::text		-- Funding Orgs
			,io.implementing::text		-- Implementing Orgs
			,a._start_date::text		-- Start Date
			,a._end_date::text		-- End Date
			,f.amount::text			-- Total Bugdet
			,acs.name::text			-- Activity Status	
		from
		-- activity
		(SELECT a.id, a._title, a._description, a._start_date, a._end_date
		from activity a
		where a.id = pid and a._active = true) a
		left join 
		-- Sector
		(SELECT at.activity_id, '''' || array_to_string(array_agg(c._code), ',') || '''' as code, array_to_string(array_agg(c._name), ',') as name
  		from activity_taxonomy at
  		join classification c
		on at.classification_id = c.id
		where c.taxonomy_id = (SELECT id from taxonomy where _name = 'Sector')
		and at.activity_id = pid and c._active = true
		group by at.activity_id
		) as s
		on a.id = s.activity_id
		left join
		-- Country
		(SELECT l.activity_id, array_to_string(array_agg(distinct c._name), ',') as name
		from location l 
		join location_taxonomy lt
		on l.id = lt.location_id
		join classification c
		on lt.classification_id = c.id
		where c.taxonomy_id =(SELECT id from taxonomy where _name = 'Country')
		AND l.activity_id = pid and l._active = true and c._active = true
		group by l.activity_id) c
		on a.id = c.activity_id
		left join
		-- Activity Status
		(SELECT at.activity_id, array_to_string(array_agg(c._name), ',') as name
		from activity_taxonomy at
		join classification c
		on at.classification_id = c.id
		where c.taxonomy_id =(SELECT id from taxonomy where _name = 'Activity Status')
		AND at.activity_id = pid and c._active = true
		group by at.activity_id) acs
		on a.id = acs.activity_id
		left join
		-- financials
		(SELECT f.activity_id, sum(f._amount) as amount
		from financial f
		where f.activity_id = pid and f._active = true
		group by f.activity_id) as f
		on a.id = f.activity_id
		left join
		-- implementing orgs
		(SELECT pp.activity_id, array_to_string(array_agg(o._name), ',') as implementing
		from participation pp
		join organization o
		on pp.organization_id = o.id
		left join participation_taxonomy ppt
		on pp.id = ppt.participation_id
		join classification c
		on ppt.classification_id = c.id
		where c.taxonomy_id = (SELECT id from taxonomy where _name = 'Organisation Role') AND (c._iati_name = 'Implementing')
		and pp.activity_id = pid and pp._active = true and o._active = true and c._active = true
		group by pp.activity_id) io
		on a.id = io.activity_id
		left join
		-- funding orgs
		(SELECT pp.activity_id, array_to_string(array_agg(o._name), ',') as funding
		from participation pp
		join organization o
		on pp.organization_id = o.id
		left join participation_taxonomy ppt
		on pp.id = ppt.participation_id
		join classification c
		on ppt.classification_id = c.id
		where c.taxonomy_id = (SELECT id from taxonomy where _name = 'Organisation Role') AND (c._iati_name = 'Funding')
		and pp.activity_id = pid and pp._active = true and o._active = true and c._active = true
		group by pp.activity_id) fo
		on a.id = fo.activity_id
		left join
		-- locations
		(SELECT l.activity_id, array_to_string(array_agg(DISTINCT l._lat_dd || ' ' || l._long_dd), ',') as location
		from location l
		where l.activity_id = pid and l._active = true
		group by l.activity_id) l
		on a.id = l.activity_id;
        counter := counter + 1;
	END LOOP;
	END IF;


     IF parent_ids IS NOT NULL THEN
  	 -- Loop through parent_ids
     FOREACH pid IN ARRAY parent_ids LOOP
     RAISE NOTICE 'Preparing activity id: %', pid;	

     -- Add parent header to csv
     INSERT INTO csv_data (id,c1,c2,c3,c4,c5,c6,c7,c8)        	
		SELECT  counter
			,'Project Data' 
			,'PMT ProjectID'
			,'Project Name'
			,'Project Description'
			,'Data Group'
			,'Start Date'
			,'End Date'
			,'Total Budget';
	counter := counter + 1;	

	-- Add parent data row to csv
	INSERT INTO csv_data (id,c1,c2,c3,c4,c5,c6,c7,c8)         	
		
		SELECT  counter  
			,''::text			-- Project Data
			,a.id::text		-- PMT ProjectID
			,a._title::text			-- Project Name
			,a._description::text		-- Project Description
			,dg.name::text			-- Data Group
			,a._start_date::text		-- Start Date
			,a._end_date::text		-- End Date
			,f.amount::text			-- Total Budget
		from
		-- activity
		(SELECT a.id, a._title, a._description, a._start_date, a._end_date
		from activity a
		where a._active = true and a.id = pid
		) a		
		left join
		-- data group
		(SELECT a.id as activity_id, array_to_string(array_agg(distinct c._name), ',') as name
		from activity_taxonomy at left join activity a on at.activity_id = a.id left join classification c on a.data_group_id = c.id
		where c.taxonomy_id = (SELECT id from taxonomy where _name = 'Data Group')
		and c._active = true 
		and a.id = pid
		group by a.id
		) as dg
		on a.id = dg.activity_id
		left join		
		-- financials
		(SELECT f.activity_id, sum(f._amount) as amount
		from financial f
		where f.activity_id = pid 
		and f._active = true
		group by f.activity_id) as f
		on a.id = f.activity_id;
        counter := counter + 1;

	-- get children
	SELECT INTO children_ids array_agg(id) FROM activity a WHERE parent_id = pid;

	IF children_ids IS NOT NULL THEN
	
	RAISE NOTICE 'Children ids: %', children_ids;

	 -- Add child header to csv
     INSERT INTO csv_data (id,c1,c2,c3,c4,c5,c6,c7,c8,c9,c10,c11,c12,c13,c14,c15)        	
     		SELECT  counter
			,'Activity Data' 
			,'PMT ActivityID'
			,'Activity Title'
			,'Activity Description'
			,'Sector - Name'
			,'Sector - Code'
			,'Latitude Longitude'
			,'Country'
			,'Funding Organization(s)'
			,'Implementing Organization(s)'
			,'Start Date'
			,'End Date'
			,'Total Budget'
			,'Activity Status'
			,'Parent ID';
	counter := counter + 1;		

        -- Loop through children
	FOREACH aid IN ARRAY children_ids LOOP
	
	-- Add children data row
	INSERT INTO csv_data (id,c1,c2,c3,c4,c5,c6,c7,c8,c9,c10,c11,c12,c13,c14,c15)         	
		SELECT  counter
			,''::text			-- Activity Data
			,a.id::text		        -- PMT ActivityID
			,a._title::text			-- Activity Title
			,a._description::text		-- Activity Description
			,s.name::text			-- Sector name
			,s.code::text			-- Sector code
			,l.location::text		-- Latitude Longitude
			,c.name::text			-- Country			
			,fo.funding::text		-- Funding Orgs
			,io.implementing::text		-- Implementing Orgs
			,a._start_date::text		-- Start Date
			,a._end_date::text		-- End Date
			,f.amount::text			-- Total Bugdet
			,acs.name::text			-- Activity Status
			,a.parent_id::text		-- Parent ID	
		from
		-- activity
		(SELECT a.id, a._title, a._description, a._start_date, a._end_date, a.parent_id
		from activity a
		where a.id = aid and a._active = true) a
		left join 
		-- Sector
		(SELECT at.activity_id, '''' || array_to_string(array_agg(c._code), ',') || '''' as code, array_to_string(array_agg(c._name), ',') as name
  		from activity_taxonomy at
  		join classification c
		on at.classification_id = c.id
		where c.taxonomy_id = (SELECT id from taxonomy where _name = 'Sector')
		and at.activity_id = pid and c._active = true
		group by at.activity_id
		) as s
		on a.id = s.activity_id
		left join
		-- Country
		(SELECT l.activity_id, array_to_string(array_agg(c._name), ',') as name
		from location l 
		join location_taxonomy lt
		on l.id = lt.location_id
		join classification c
		on lt.classification_id = c.id
		where c.taxonomy_id =(SELECT id from taxonomy where _name = 'Country')
		AND l.activity_id = aid and l._active = true and c._active = true
		group by l.activity_id) c
		on a.id = c.activity_id
		left join
		-- Activity Status
		(SELECT at.activity_id, array_to_string(array_agg(c._name), ',') as name
		from activity_taxonomy at
		join classification c
		on at.classification_id = c.id
		where c.taxonomy_id =(SELECT id from taxonomy where _name = 'Activity Status')
		AND at.activity_id = aid and c._active = true
		group by at.activity_id) acs
		on a.id = acs.activity_id
		left join
		-- financials
		(SELECT f.activity_id, sum(f._amount) as amount
		from financial f
		where f.activity_id = aid and f._active = true
		group by f.activity_id) as f
		on a.id = f.activity_id
		left join
		-- implementing orgs
		(SELECT pp.activity_id, array_to_string(array_agg(o._name), ',') as implementing
		from participation pp
		join organization o
		on pp.organization_id = o.id
		left join participation_taxonomy ppt
		on pp.id = ppt.participation_id
		join classification c
		on ppt.classification_id = c.id
		where c.taxonomy_id = (SELECT id from taxonomy where _name = 'Organisation Role') AND (c._iati_name = 'Implementing')
		and pp.activity_id = aid and pp._active = true and o._active = true and c._active = true
		group by pp.activity_id) io
		on a.id = io.activity_id
		left join
		-- funding orgs
		(SELECT pp.activity_id, array_to_string(array_agg(o._name), ',') as funding
		from participation pp
		join organization o
		on pp.organization_id = o.id
		left join participation_taxonomy ppt
		on pp.id = ppt.participation_id
		join classification c
		on ppt.classification_id = c.id
		where c.taxonomy_id = (SELECT id from taxonomy where _name = 'Organisation Role') AND (c._iati_name = 'Funding')
		and pp.activity_id = aid and pp._active = true and o._active = true and c._active = true
		group by pp.activity_id) fo
		on a.id = fo.activity_id
		left join
		-- locations
		(SELECT l.activity_id, array_to_string(array_agg(DISTINCT l._lat_dd || ' ' || l._long_dd), ',') as location
		from location l
		where l.activity_id = aid and l._active = true
		group by l.activity_id) l
		on a.id = l.activity_id;
        counter := counter + 1;

	END LOOP; 

	END IF; 

  END LOOP;

  END IF;

  -- uncomment for testing csv result		
  -- filename := '''/Users/admin/Desktop/pmt-v/pmtexportdefault.csv''';
  -- fileencoding = '''UTF8''';
  -- EXECUTE 'COPY(SELECT c1,c2,c3,c4,c5,c6,c7,c8,c9,c10,c11,c12,c13,c14,c15,c16,c17,c18 FROM csv_data ORDER BY id) To ' || filename || ' With CSV ENCODING ' || fileencoding || ';'; 

    FOR rec IN SELECT row_to_json(j) FROM (
    SELECT c1,c2,c3,c4,c5,c6,c7,c8,c9,c10,c11,c12,c13,c14,c15,c16,c17,c18 FROM csv_data ORDER BY id
  ) j LOOP
	RETURN NEXT rec;
  END LOOP;
  
EXCEPTION WHEN others THEN
    GET STACKED DIAGNOSTICS error_msg = MESSAGE_TEXT;
    FOR rec IN (SELECT row_to_json(j) FROM(SELECT 'Internal Error - Contact your DBA with the following error message: ' || error_msg as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;	  	
END;$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100
  ROWS 1000;
ALTER FUNCTION pmt_export(character varying, character varying, character varying, character varying, character varying, date, date, character varying)
  OWNER TO postgres;


-- Function: pmt_export_bmgf(character varying, character varying, character varying, character varying, character varying, date, date, character varying)

-- DROP FUNCTION pmt_export_bmgf(character varying, character varying, character varying, character varying, character varying, date, date, character varying);

CREATE OR REPLACE FUNCTION pmt_export_bmgf(data_group_ids character varying, classification_ids character varying, org_ids character varying, imp_org_ids character varying, fund_org_ids character varying, start_date date, end_date date, unassigned_taxonomy_ids character varying)
  RETURNS SETOF pmt_json_result_type AS
$BODY$
DECLARE
  activity_ids int[];
  parent_ids int[];
  no_parent_activities int[];
  children_ids int[];
  pid int;
  aid int;
  counter int;
  filter_classids integer array;
  filter_orgids integer array;
  filter text;
  disclaimer text;
  filename text;
  fileencoding text;
  db_version text;
  db_instance text;
  rec record;
  element record;
  error_msg text;
BEGIN
  -- create temporary table to hold our data for the csv
  CREATE TEMPORARY TABLE csv_data (
      id int,c1 text,c2 text,c3 text,c4 text,c5 text,c6 text,c7 text,c8 text,c9 text,c10 text
     ,c11 text,c12 text,c13 text,c14 text,c15 text,c16 text,c17 text,c18 text, c19 text, c20 text
     ) ON COMMIT DROP;

  -- get database version
  FOR element IN SELECT * FROM json_each( (SELECT * FROM pmt_version()) ) LOOP
   IF element.key = 'pmt_version' THEN
	db_version = element.value;
	RAISE NOTICE 'db version: %', db_version;
   END IF;
  END LOOP;
  
  -- build version/date/filter line
  SELECT INTO filter * FROM pmt_filter_string($1,$2,$3,$4,$5,$6,$7,$8);
  RAISE NOTICE 'filters: %', filter;

  disclaimer := 'Disclaimer: TEXT';
  counter := 1;
 
  -- write the filter
  INSERT INTO csv_data (id,c1) SELECT counter, filter;
  counter := counter + 1;
  -- write the disclaimer
  INSERT INTO csv_data (id,c1) SELECT counter, disclaimer;
  counter := counter + 1;

  SELECT INTO activity_ids * FROM pmt_filter($1,$2,$3,$4,$5,$6,$7,$8);

  -- get activities with no parents
  SELECT INTO no_parent_activities array_agg(id) FROM ((SELECT id FROM activity WHERE id IN (SELECT unnest( (SELECT * FROM pmt_filter($1,$2,$3,$4,$5,$6,$7,$8)) )) AND parent_id IS NULL )
   EXCEPT
  SELECT distinct parent_id FROM activity where parent_id in ((SELECT id FROM activity WHERE id IN (SELECT unnest( (SELECT * FROM pmt_filter($1,$2,$3,$4,$5,$6,$7,$8)) )) AND parent_id IS NULL ))) j;
   
   -- no activities 
   IF no_parent_activities IS NULL THEN
	no_parent_activities = activity_ids;
	RAISE NOTICE 'activity ids: %', activity_ids; 
   END IF;

  RAISE NOTICE 'non parent activities: %', no_parent_activities;

  -- get all parent activities
  SELECT INTO parent_ids array_agg(distinct parent_id) FROM activity WHERE parent_id IN (SELECT id FROM activity WHERE id IN (SELECT unnest( (SELECT * FROM pmt_filter($1,$2,$3,$4,$5,$6,$7,$8)) )) and parent_id IS NULL);

   -- 1. Add header row and Loop through activities with no children or parents
   -- 2. Loop through parent activities & their children. Add header row for each parent & group of children
 
   -- activity ids with no children or parents

   IF no_parent_activities IS NOT NULL THEN
     
     -- Add one header row for this group of activities
     INSERT INTO csv_data (id,c1,c2,c3,c4,c5,c6,c7,c8,c9,c10,c11,c12,c13,c14,c15,c16,c17,c18)        	
     		SELECT  counter
			,'Activity Data' 
			,'PMT ActivityID'
			,'OppID'
			,'Activity Title'
			,'Activity Description'
			,'BMGF Sub-Initiative'
			,'Latitude Longitude'
			,'Country'
			,'Region'
			,'District'
			,'City Village'
			,'Partners'
			,'Partner Role'
			,'Start Date'
			,'End Date'
			,'Award Amount Allocated'
			,'Activity Status'	
			,'Keywords';
     counter := counter + 1;

     FOREACH pid IN ARRAY no_parent_activities LOOP

		-- Add activity data row to csv
		INSERT INTO csv_data (id,c1,c2,c3,c4,c5,c6,c7,c8,c9,c10,c11,c12,c13,c14,c15,c16,c17,c18)         	
		SELECT  counter
			,''::text			-- Activity Data
			,a.id::text		-- PMT ActivityID
			,a.opportunity_id::text		-- OppID
			,a._title::text			-- Activity Title
			,a._description::text		-- Activity Description
			,si.name::text			-- BMGF Sub-Initiative
			,l.location::text		-- Latitude Longitude
			,c.name::text			-- Country
			,g1.region::text	  	-- Region
			,g2.district::text	  	-- District
			,a.city_village::text		-- City Village			
			,pt.partners::text		-- Partners
			,pt.role::text			-- Partner Role
			,a._start_date::text		-- Start Date
			,a._end_date::text		-- End Date
			,f.amount::text			-- Award Amount Allocated
			,s.name::text			-- Activity Status	
			,a._tags::text			-- Keywords
		FROM
		-- activity
		(SELECT a.id, a.opportunity_id, a._title, a._description, a._start_date, a._end_date, a._tags, a.city_village
		FROM activity a
		where a.id = pid and a._active = true) a
		left join 
		-- Sub-Initiative
		(SELECT at.activity_id, array_to_string(array_agg(DISTINCT c._name), ',') as name
		FROM activity_taxonomy at
		join classification c
		on at.classification_id = c.id
		where c.taxonomy_id = (SELECT id FROM taxonomy where _name = 'Sub-Initiative')
		and at.activity_id = pid and c._active = true
		group by at.activity_id) as si
		on a.id = si.activity_id
		left join
		-- Country
		(SELECT l.activity_id, array_to_string(array_agg(DISTINCT c._name), ',') as name
		FROM location l 
		join location_taxonomy lt
		on l.id = lt.location_id
		join classification c
		on lt.classification_id = c.id
		where c.taxonomy_id =(SELECT id FROM taxonomy where _name = 'Country')
		AND l.activity_id = pid and l._active = true and c._active = true
		group by l.activity_id) c
		on a.id = c.activity_id
		left join
		-- Activity Status
		(SELECT at.activity_id, array_to_string(array_agg(DISTINCT c._name), ',') as name
		FROM activity_taxonomy at
		join classification c
		on at.classification_id = c.id
		where c.taxonomy_id =(SELECT id FROM taxonomy where _name = 'Activity Status')
		AND at.activity_id = pid and c._active = true
		group by at.activity_id) s
		on a.id = s.activity_id
		left join
		-- financials
		(SELECT f.activity_id, sum(f._amount) as amount
		FROM financial f
		where f.activity_id = pid and f._active = true
		group by f.activity_id) as f
		on a.id = f.activity_id
		left join
		-- all partners
		(SELECT pp.activity_id, array_to_string(array_agg(DISTINCT o._name), ',') as partners, array_to_string(array_agg(DISTINCT c._name), ',') as role
		FROM participation pp
		join organization o
		on pp.organization_id = o.id
		left join participation_taxonomy ppt
		on pp.id = ppt.participation_id
		join classification c
		on ppt.classification_id = c.id
		where c.taxonomy_id = (SELECT id FROM taxonomy where _name = 'Organisation Role') AND (c._name = 'Implementing' OR c._name = 'Funding')
		and pp.activity_id = pid and pp._active = true and o._active = true and c._active = true
		group by pp.activity_id) pt
		on a.id = pt.activity_id
		left join
		-- locations
		(SELECT l.activity_id, array_to_string(array_agg(DISTINCT l._lat_dd || ' ' || l._long_dd), ',') as location
		FROM location l
		where l.activity_id = pid and l._active = true
		group by l.activity_id) l
		on a.id = l.activity_id
		left join
		-- regions
		(SELECT lb.activity_id, array_to_string(array_agg(DISTINCT feature_name), ',') as region
		FROM _location_boundary_features lb where boundary_name = 'GAUL Level 1' 
		group by lb.activity_id) g1		
		on a.id = g1.activity_id
		left join
		-- districts
		(SELECT lb.activity_id, array_to_string(array_agg(DISTINCT feature_name), ',') as district
		FROM _location_boundary_features lb where boundary_name = 'GAUL Level 2'
		group by lb.activity_id) g2		
		on a.id = g2.activity_id;
        counter := counter + 1;
  END LOOP;
  END IF;


     IF parent_ids IS NOT NULL THEN
  	 -- Loop through parent_ids
     FOREACH pid IN ARRAY parent_ids LOOP
     RAISE NOTICE 'Preparing activity id: %', pid;	

     -- Add parent header to csv
     INSERT INTO csv_data (id,c1,c2,c3,c4,c5,c6,c7,c8,c9,c10,c11,c12,c13,c14,c15,c16,c17,c18)        	
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

			-- Add parent data row to csv
     		INSERT INTO csv_data (id,c1,c2,c3,c4,c5,c6,c7,c8,c9,c10,c11,c12,c13,c14,c15,c16,c17,c18)         	
					SELECT
			counter  
			,''::text			-- Project Data
			,a.id::text			-- PMT ActivityID
			,a.opportunity_id::text		-- OppID
			,ac.name::text			-- Organization
			,ac.url::text			-- Organization Website
			,a._title::text			-- Project Name
			,a._description::text		-- Project Description
			,i.name::text			-- Initiative
			,fc.focus_crop::text		-- Focus Crop
			,a._start_date::text		-- Start Date
			,a._end_date::text		-- End Date
			,f.amount::text			-- Grant Amount
			,a.people_affected::text	-- Population Affected
			,a.fte::text			-- FTEs
			,pt.partners::text		-- Partners
			,a._url::text			-- Project Website
			,sg.sub_grantees::text		-- Sub Grantees
			,c.country::text		-- Country
		FROM
		-- activity
		(SELECT a.id, a._title, a._description, a._start_date, a._end_date, a.opportunity_id, a.people_affected, a.fte, a._url
		FROM activity a
		where a.id = pid 
		and a._active = true) a
		left join
		-- accountable organization
		(SELECT pp.activity_id, array_to_string(array_agg(o._name), ',') as name, array_to_string(array_agg(o._url), ',') as url
		FROM participation pp
		join organization o
		on pp.organization_id = o.id
		left join participation_taxonomy ppt
		on pp.id = ppt.participation_id
		join classification c
		on ppt.classification_id = c.id
		where c.taxonomy_id = (SELECT id FROM taxonomy where _name = 'Organisation Role') AND (c._iati_name = 'Accounting')
		and pp.activity_id = pid 
		and pp._active = true and o._active = true and c._active = true
		group by pp.activity_id) ac
		on a.id = ac.activity_id
		left join
		-- initiative
		(SELECT at.activity_id, array_to_string(array_agg(DISTINCT c._name), ',') as name
		FROM activity_taxonomy at
		join classification c
		on at.classification_id = c.id
		where c.taxonomy_id = (SELECT id FROM taxonomy where _name = 'Initiative')
		AND at.activity_id = pid 
		and c._active = true
		group by at.activity_id) as i
		on a.id = i.activity_id
		left join
		-- focus crop
		(SELECT at.activity_id, array_to_string(array_agg(DISTINCT c._name), ',') as focus_crop
		FROM activity_taxonomy at
		join classification c
		on at.classification_id = c.id
		where c.taxonomy_id = (SELECT id FROM taxonomy where _name = 'Focus Crop')
		AND at.activity_id = pid 
		and c._active = true
		group by at.activity_id) as fc
		on a.id = fc.activity_id
		left join
		-- financials
		(SELECT f.activity_id, sum(f._amount) as amount
		FROM financial f
		where f.activity_id = pid 
		and f._active = true
		group by f.activity_id) as f
		on a.id = f.activity_id
		left join
		-- all partners
		(SELECT pp.activity_id, array_to_string(array_agg(o._name), ',') as partners 
		FROM participation pp
		join organization o
		on pp.organization_id = o.id
		left join participation_taxonomy ppt
		on pp.id = ppt.participation_id
		join classification c
		on ppt.classification_id = c.id
		where c.taxonomy_id = (SELECT id FROM taxonomy where _name = 'Organisation Role') AND (c._iati_name = 'Accounting' OR c._name = 'Funding')
		and pp.activity_id = pid 
		and pp._active = true and o._active = true and c._active = true
		group by pp.activity_id) pt
		on a.id = pt.activity_id
		left join
		-- implementing organizations (sub-grantees)
		(SELECT pp.activity_id, array_to_string(array_agg(o._name), ',') as sub_grantees
		FROM participation pp
		join organization o
		on pp.organization_id = o.id
		left join participation_taxonomy ppt
		on pp.id = ppt.participation_id
		join classification c
		on ppt.classification_id = c.id
		where c.taxonomy_id = (SELECT id FROM taxonomy where _name = 'Organisation Role') AND (c._iati_name = 'Implementing')
		and pp.activity_id = pid 
		and pp._active = true 
		and o._active = true and c._active = true
		group by pp.activity_id) sg
		on a.id = sg.activity_id
		left join
		-- country
		(SELECT at.activity_id, array_to_string(array_agg(DISTINCT c._name), ',') as country
		FROM activity_taxonomy at
		join classification c
		on at.classification_id = c.id
		where c.taxonomy_id = (SELECT id FROM taxonomy where _name = 'Country')
		AND at.activity_id = pid 
		and c._active = true
		group by at.activity_id) as c
		on a.id = fc.activity_id;
		counter := counter + 1;

        	-- get children
	SELECT INTO children_ids array_agg(id) FROM activity a WHERE parent_id = pid;

	IF children_ids IS NOT NULL THEN
	
	RAISE NOTICE 'Children ids: %', children_ids;	

	 -- insert activity header
     INSERT INTO csv_data (id,c1,c2,c3,c4,c5,c6,c7,c8,c9,c10,c11,c12,c13,c14,c15,c16,c17,c18)        	
     		SELECT  counter
			,'Activity Data' 
			,'PMT ActivityID'
			,'OppID'
			,'Activity Title'
			,'Activity Description'
			,'BMGF Sub-Initiative'
			,'Latitude Longitude'
			,'Country'
			,'Region'
			,'District'
			,'City Village'
			,'Partners'
			,'Partner Role'
			,'Start Date'
			,'End Date'
			,'Award Amount Allocated'
			,'Activity Status'	
			,'Keywords';
     counter := counter + 1;

        -- Loop through children
	FOREACH aid IN ARRAY children_ids LOOP

			INSERT INTO csv_data (id,c1,c2,c3,c4,c5,c6,c7,c8,c9,c10,c11,c12,c13,c14,c15,c16,c17,c18,c19)         	
		SELECT  counter
			,''::text				-- Activity Data
			,a.id::text				-- PMT ActivityID
			,a.opportunity_id::text	-- Opaid
			,a._title::text			-- Activity Title
			,a._description::text	-- Activity Description
			,si.name::text			-- BMGF Sub-Initiative
			,l.location::text		-- Latitude Longitude
			,c.name::text			-- Country
			,g1.region::text	  	-- Region
			,g2.district::text	  	-- District
			,a.city_village::text	-- City Village			
			,pt.partners::text		-- Partners
			,pt.role::text			-- Partner Role
			,a._start_date::text	-- Start Date
			,a._end_date::text		-- End Date
			,f.amount::text			-- Award Amount Allocated
			,s.name::text			-- Activity Status	
			,a._tags::text			-- Keywords
			,a.parent_id::text 		-- Parent Activity ID
		FROM
		-- activity
		(SELECT a.id, a.opportunity_id, a._title, a._description, a._start_date, a._end_date, a._tags, a.city_village, a.parent_id
		FROM activity a
		where a.id = aid and a._active = true) a
		left join 
		-- Sub-Initiative
		(SELECT at.activity_id, array_to_string(array_agg(DISTINCT c._name), ',') as name
		FROM activity_taxonomy at
		join classification c
		on at.classification_id = c.id
		where c.taxonomy_id = (SELECT id FROM taxonomy where _name = 'Sub-Initiative')
		and at.activity_id = aid and c._active = true
		group by at.activity_id) as si
		on a.id = si.activity_id
		left join
		-- Country
		(SELECT l.activity_id, array_to_string(array_agg(DISTINCT c._name), ',') as name
		FROM location l 
		join location_taxonomy lt
		on l.id = lt.location_id
		join classification c
		on lt.classification_id = c.id
		where c.taxonomy_id =(SELECT id FROM taxonomy where _name = 'Country')
		AND l.activity_id = aid and l._active = true and c._active = true
		group by l.activity_id) c
		on a.id = c.activity_id
		left join
		-- Activity Status
		(SELECT at.activity_id, array_to_string(array_agg(DISTINCT c._name), ',') as name
		FROM activity_taxonomy at
		join classification c
		on at.classification_id = c.id
		where c.taxonomy_id =(SELECT id FROM taxonomy where _name = 'Activity Status')
		AND at.activity_id = aid and c._active = true
		group by at.activity_id) s
		on a.id = s.activity_id
		left join
		-- financials
		(SELECT f.activity_id, sum(f._amount) as amount
		FROM financial f
		where f.activity_id = aid and f._active = true
		group by f.activity_id) as f
		on a.id = f.activity_id
		left join
		-- all partners
		(SELECT pp.activity_id, array_to_string(array_agg(DISTINCT o._name), ',') as partners, array_to_string(array_agg(DISTINCT c._name), ',') as role
		FROM participation pp
		join organization o
		on pp.organization_id = o.id
		left join participation_taxonomy ppt
		on pp.id = ppt.participation_id
		join classification c
		on ppt.classification_id = c.id
		where c.taxonomy_id = (SELECT id FROM taxonomy where _name = 'Organisation Role') AND (c._name = 'Implementing' OR c._name = 'Funding')
		and pp.activity_id = aid and pp._active = true and o._active = true and c._active = true
		group by pp.activity_id) pt
		on a.id = pt.activity_id
		left join
		-- locations
		(SELECT l.activity_id, array_to_string(array_agg(DISTINCT l._lat_dd || ' ' || l._long_dd), ',') as location
		FROM location l
		where l.activity_id = aid and l._active = true
		group by l.activity_id) l
		on a.id = l.activity_id
		left join
		-- regions
		(SELECT lb.activity_id, array_to_string(array_agg(DISTINCT feature_name), ',') as region
		FROM _location_boundary_features lb where boundary_name = 'GAUL Level 1' 
		group by lb.activity_id) g1		
		on a.id = g1.activity_id
		left join
		-- districts
		(SELECT lb.activity_id, array_to_string(array_agg(DISTINCT feature_name), ',') as district
		FROM _location_boundary_features lb where boundary_name = 'GAUL Level 2'
		group by lb.activity_id) g2		
		on a.id = g2.activity_id;
        counter := counter + 1;

	END LOOP; 

	END IF; 

  END LOOP;

  END IF;

  -- uncomment for testing csv result		
  -- filename := '''/Users/admin/Desktop/pmt-v/bmgftest.csv''';
  -- fileencoding = '''UTF8''';
  -- EXECUTE 'COPY(SELECT c1,c2,c3,c4,c5,c6,c7,c8,c9,c10,c11,c12,c13,c14,c15,c16,c17,c18,c19 FROM csv_data ORDER BY id) To ' || filename || ' With CSV ENCODING ' || fileencoding || ';'; 
  
    FOR rec IN SELECT row_to_json(j) FROM (
    SELECT c1,c2,c3,c4,c5,c6,c7,c8,c9,c10,c11,c12,c13,c14,c15,c16,c17,c18 FROM csv_data ORDER BY id
  ) j LOOP
	RETURN NEXT rec;
  END LOOP;

EXCEPTION WHEN others THEN
    GET STACKED DIAGNOSTICS error_msg = MESSAGE_TEXT;
    FOR rec IN (SELECT row_to_json(j) FROM(SELECT 'Internal Error - Contact your DBA with the following error message: ' || error_msg as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;	  	
END;$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100
  ROWS 1000;
ALTER FUNCTION pmt_export_bmgf(character varying, character varying, character varying, character varying, character varying, date, date, character varying)
  OWNER TO postgres;


-- Function: pmt_export_ethaim(character varying, character varying, character varying, character varying, character varying, date, date, character varying)

-- DROP FUNCTION pmt_export_ethaim(character varying, character varying, character varying, character varying, character varying, date, date, character varying);

CREATE OR REPLACE FUNCTION pmt_export_ethaim(data_group_ids character varying, classification_ids character varying, org_ids character varying, imp_org_ids character varying, fund_org_ids character varying, start_date date, end_date date, unassigned_taxonomy_ids character varying)
  RETURNS SETOF pmt_json_result_type AS
$BODY$
DECLARE
  activity_ids int[];
  parent_ids int[];
  no_parent_activities int[];
  children_ids int[];
  pid int;
  aid int;
  counter int;
  filter_classids integer array;
  filter_orgids integer array;
  filter text;
  disclaimer text;
  filename text;
  fileencoding text;
  db_version text;
  db_instance text;
  rec record;
  element record;
  error_msg text;
BEGIN
-- create temporary table to hold our data for the csv
  CREATE TEMPORARY TABLE csv_data (
      id int,c1 text,c2 text,c3 text,c4 text,c5 text,c6 text,c7 text,c8 text,c9 text,c10 text
     ,c11 text,c12 text,c13 text,c14 text,c15 text,c16 text,c17 text,c18 text, c19 text, c20 text, c21 text, c22 text, c23 text, c24 text, c25 text, c26 text, c27 text, c28 text
     ) ON COMMIT DROP;

  -- get database version
  FOR element IN SELECT * FROM json_each( (SELECT * FROM pmt_version()) ) LOOP
   IF element.key = 'pmt_version' THEN
	db_version = element.value;
	RAISE NOTICE 'db version: %', db_version;
   END IF;
  END LOOP;
  
  -- build version/date/filter line
  SELECT INTO filter * FROM pmt_filter_string($1,$2,$3,$4,$5,$6,$7,$8);
  RAISE NOTICE 'filters: %', filter;

  disclaimer := 'Disclaimer: TEXT';
  counter := 1;
 
  -- write the filter
  INSERT INTO csv_data (id,c1) SELECT counter, filter;
  counter := counter + 1;
  -- write the disclaimer
  INSERT INTO csv_data (id,c1) SELECT counter, disclaimer;
  counter := counter + 1;

  SELECT INTO activity_ids * FROM pmt_filter($1,$2,$3,$4,$5,$6,$7,$8);

  -- get activities with no parents
  SELECT INTO no_parent_activities array_agg(id) FROM ((SELECT id FROM activity WHERE id IN (SELECT unnest( (SELECT * FROM pmt_filter($1,$2,$3,$4,$5,$6,$7,$8)) )) AND parent_id IS NULL )
   EXCEPT
  SELECT DISTINCT parent_id FROM activity where parent_id in ((SELECT id FROM activity WHERE id IN (SELECT unnest( (SELECT * FROM pmt_filter($1,$2,$3,$4,$5,$6,$7,$8)) )) AND parent_id IS NULL ))) j;
   
   -- no activities 
   IF no_parent_activities IS NULL THEN
	no_parent_activities = activity_ids;
	RAISE NOTICE 'activity ids: %', activity_ids; 
   END IF;

  RAISE NOTICE 'non parent activities: %', no_parent_activities;

  -- get all parent activities
  SELECT INTO parent_ids array_agg(DISTINCT parent_id) FROM activity WHERE parent_id IN (SELECT id FROM activity WHERE id IN (SELECT unnest( (SELECT * FROM pmt_filter($1,$2,$3,$4,$5,$6,$7,$8)) )) and parent_id IS NULL);

   -- 1. Add header row and Loop through activities with no children or parents
   -- 2. Loop through parent activities & their children. Add header row for each parent & group of children
 
   -- activity ids with no children or parents

   IF no_parent_activities IS NOT NULL THEN
     
     -- Add one header row for this group of activities
     INSERT INTO csv_data (id,c1,c2,c3,c4,c5,c6,c7,c8,c9,c10,c11,c12,c13,c14,c15,c16,c17,c18,c19,c20,c21,c22,c23,c24,c25,c26,c27,c28)        	
     		SELECT  counter,
 			'Activity Data',
 			'PMT ActivityID',
			'Program_ID',
			'Program_Name',	
			'Project_ID',
			'Project_Title',
			'Funding_Source_Name',
			'Primary_Oecd_Code,Secondary_Oecd_Code',
			'Oecd Description',
			'Primary_Implementing_Agency_Name',
			'Crop/Livestock focus',
			'Project Objective',
			'Project_Start_Date',
			'Project_End_Date',
			'Project_Status',
			'Total_Amount_IN_USD',
			'Loan_Component_In_USD',
			'Grant_Component_In_USD',
			'National_vs_Regional',
			'Region_Name',
			'Zone_Name',
			'Woreda_Name',
			'Number of Locations',
			'Dac_Code',
			'OECD_Description',
			'Classification_By_Strategic_Objective',
			'Project_Contact_Name',
			'Project_Contact_Email';

     counter := counter + 1;

     FOREACH pid IN ARRAY no_parent_activities LOOP

		-- Add activity data row to csv
			INSERT INTO csv_data (id,c1,c2,c3,c4,c5,c6,c7,c8,c9,c10,c11,c12,c13,c14,c15,c16,c17,c18,c19,c20,c21,c22,c23,c24,c25,c26,c27,c28)         	
		SELECT  counter
			,''::text				-- Activity Data
			,a.id::text		        -- PMT ActivityID
			,si.code::text			-- ProgramID
			,si.name::text			-- Program Name
			,a._iati_identifier::text	-- Project ID
			,a._title::text			-- Project Title
			,fund.source::text		-- Funder Source Name
			,psc.code::text			-- Primary_Oecd_Code,Secondary_Oecd_Code
			,psc.sector::text			-- Oecd Description
			,imp.partners::text		-- Primary_Implementing_Agency_Name
			,cl.crops::text			-- Crops & LiveStock
			,a._objective::text		-- Objective
			,a._start_date::text		-- Start Date
			,a._end_date::text		-- End Date
			,s.name::text			-- Activity Status	
			,f.amount::text			-- Total_Amount_IN_USD
			,cloan.loan::text		-- Loan
			,cgrant.grant::text		-- Grant
			,cln.nationallocal::text	-- Nation/Regional
			,g1.admin1::text	  	-- Regional
			,g2.admin2::text	  	-- Zone
			,g3.admin3::text	  	-- Woreda
			,l.location::text		-- Number of Locations
			,sc.sectorcategory::text	-- Dac_Code
			,sc.description::text	-- OECD_Description
			,a._description::text	-- Classification_By_Strategic_Objective
			,co.contact::text		-- Contact
			,coe.email::text 		-- Contact Email

		FROM
		-- activity
		(SELECT a.id, a.opportunity_id, a._title, a._description, a._start_date, a._end_date, a._objective, a._iati_identifier
		FROM activity a
		where a.id = pid and a._active = true) a
		left join 
		-- Sub-Initiative
		(SELECT at.activity_id, array_to_string(array_agg(DISTINCT c._name), ',') as name, '''' || array_to_string(array_agg(DISTINCT c._code), ',') || '''' as code
		FROM activity_taxonomy at
		join classification c
		on at.classification_id = c.id
		where c.taxonomy_id = (SELECT id FROM taxonomy where _name = 'ATA Program')
		and at.activity_id = pid and c._active = true
		group by at.activity_id) as si
		on a.id = si.activity_id
		left join
		-- Activity Status
		(SELECT at.activity_id, array_to_string(array_agg(DISTINCT c._name), ',') as name
		FROM activity_taxonomy at
		join classification c
		on at.classification_id = c.id
		where c.taxonomy_id =(SELECT id FROM taxonomy where _name = 'Activity Status')
		AND at.activity_id = pid and c._active = true
		group by at.activity_id) s
		on a.id = s.activity_id
		left join
		-- Primary and Secondary Code & Oecd Description
		(SELECT at.activity_id, array_to_string(array_agg(DISTINCT c._name), ',') as sector, '''' || array_to_string(array_agg(DISTINCT c._code), ',') || '''' as code
		FROM activity_taxonomy at
		join classification c
		on at.classification_id = c.id
		where c.taxonomy_id = (SELECT id FROM taxonomy where _name = 'Sector')
		and at.activity_id = pid and c._active = true
		group by at.activity_id) as psc
		on a.id = psc.activity_id
		left join
		-- CropLivestock
		(SELECT at.activity_id, array_to_string(array_agg(DISTINCT c._name), ',') as crops
		FROM activity_taxonomy at
		join classification c
		on at.classification_id = c.id
		where c.taxonomy_id = (SELECT id FROM taxonomy where _name = 'ATA Crops and Livestock')
		and at.activity_id = pid and c._active = true
		group by at.activity_id) as cl
		on a.id = cl.activity_id
		left join
		-- Sector Category
		(SELECT at.activity_id, array_to_string(array_agg(DISTINCT c._name), ',') as sectorcategory, array_to_string(array_agg(DISTINCT c._name), ',') as description
		FROM activity_taxonomy at
		join classification c
		on at.classification_id = c.id
		where c.taxonomy_id = (SELECT id FROM taxonomy where _name = 'Sector Category')
		and at.activity_id = pid and c._active = true
		group by at.activity_id) as sc
		on a.id = sc.activity_id
		left join
		-- Loan
		(SELECT f.activity_id, sum(f._amount) as loan
		FROM financial f left join financial_taxonomy ft on f.id = ft.financial_id 
		left join _taxonomy_classifications tc on ft.classification_id = tc.classification_id where tc.classification = 'LOAN'
		and f.activity_id = pid and f._active = true
		group by f.activity_id) as cloan
		on a.id = cloan.activity_id
		left join
		-- Grant
		(SELECT activity_id, sum(f._amount) as grant
		FROM financial f left join financial_taxonomy ft on f.id = ft.financial_id 
		left join _taxonomy_classifications tc on ft.classification_id = tc.classification_id where tc.classification = 'GRANT'
		and f.activity_id = pid 
		and f._active = true
		group by f.activity_id) cgrant
		on a.id = cgrant.activity_id
		left join
		-- National/Local
		(SELECT at.activity_id, array_to_string(array_agg(DISTINCT c._name), ',') as nationallocal
		FROM activity_taxonomy at
		join classification c
		on at.classification_id = c.id
		where c.taxonomy_id = (SELECT id FROM taxonomy where _name = 'National/Local')
		and at.activity_id = pid and c._active = true
		group by at.activity_id) as cln
		on a.id = cln.activity_id
		left join
		-- financials
		(SELECT f.activity_id, sum(f._amount) as amount
		FROM financial f
		where f.activity_id = pid and f._active = true
		group by f.activity_id) as f
		on a.id = f.activity_id
		left join
		-- all funders
		(SELECT pp.activity_id, array_to_string(array_agg(DISTINCT o._name), ',') as source
		FROM participation pp
		join organization o
		on pp.organization_id = o.id
		left join participation_taxonomy ppt
		on pp.id = ppt.participation_id
		join classification c
		on ppt.classification_id = c.id
		where c.taxonomy_id = (SELECT id FROM taxonomy where _name = 'Organisation Role') AND (c._name = 'Funding')
		and pp.activity_id = pid and pp._active = true and o._active = true and c._active = true
		group by pp.activity_id) fund
		on a.id = fund.activity_id
		left join
		-- all partners
		(SELECT pp.activity_id, array_to_string(array_agg(DISTINCT o._name), ',') as partners
		FROM participation pp
		join organization o
		on pp.organization_id = o.id
		left join participation_taxonomy ppt
		on pp.id = ppt.participation_id
		join classification c
		on ppt.classification_id = c.id
		where c.taxonomy_id = (SELECT id FROM taxonomy where _name = 'Organisation Role') AND (c._name = 'Implementing')
		and pp.activity_id = pid and pp._active = true and o._active = true and c._active = true
		group by pp.activity_id) imp
		on a.id = imp.activity_id
		left join
		-- location count
		(SELECT l.activity_id, count(DISTINCT l.id) as location
		FROM location l
		where l.activity_id = pid and l._active = true
		group by l.activity_id) l
		on a.id = l.activity_id
		left join
		-- Contact
		(SELECT ac.activity_id, array_to_string(array_agg(DISTINCT _first_name || ' ' || _last_name), ',') as contact
		FROM contact c join activity_contact ac on ac.contact_id = c.id 
		where c._active = true and ac.activity_id = pid
		group by ac.activity_id) co
		on a.id =  co.activity_id
		left join
		-- Contact Email
		(SELECT ac.activity_id, array_to_string(array_agg(DISTINCT _email), ',') as email
		FROM contact c join activity_contact ac on ac.contact_id = c.id 
		where c._active = true and ac.activity_id = pid
		group by ac.activity_id) coe
		on a.id = coe.activity_id
		left join
		-- Admin1
		(SELECT lb.activity_id, array_to_string(array_agg(DISTINCT feature_name), ',') as admin1
		FROM _location_boundary_features lb where boundary_name = 'OCHA Ethiopia Administrative Level 1' 
		group by lb.activity_id) g1		
		on a.id = g1.activity_id
		left join
		-- Admin2
		(SELECT lb.activity_id, array_to_string(array_agg(DISTINCT feature_name), ',') as admin2
		FROM _location_boundary_features lb where boundary_name = 'OCHA Ethiopia Administrative Level 2'
		group by lb.activity_id) g2
		on a.id = g2.activity_id	
		left join
		-- Admin3
		(SELECT lb.activity_id, array_to_string(array_agg(DISTINCT feature_name), ',') as admin3
		FROM _location_boundary_features lb where boundary_name = 'OCHA Ethiopia Administrative Level 3'
		group by lb.activity_id) g3		
		on a.id = g3.activity_id;
        counter := counter + 1;

  END LOOP;
  END IF;


     IF parent_ids IS NOT NULL THEN
  	 -- Loop through parent_ids
     FOREACH pid IN ARRAY parent_ids LOOP
     RAISE NOTICE 'Preparing activity id: %', pid;	

     -- Add parent header to csv
     INSERT INTO csv_data (id,c1,c2,c3,c4,c5,c6,c7,c8,c9,c10,c11,c12,c13,c14,c15,c16,c17,c18,c19,c20,c21,c22,c23,c24,c25,c26,c27,c28)        	
     		SELECT  counter,
 			'Activity Data',
 			'PMT ActivityID',
			'Program_ID',
			'Program_Name',	
			'Project_ID',
			'Project_Title',
			'Funding_Source_Name',
			'Primary_Oecd_Code,Secondary_Oecd_Code',
			'Oecd Description',
			'Primary_Implementing_Agency_Name',
			'Crop/Livestock focus',
			'Project Objective',
			'Project_Start_Date',
			'Project_End_Date',
			'Project_Status',
			'Total_Amount_IN_USD',
			'Loan_Component_In_USD',
			'Grant_Component_In_USD',
			'National_vs_Regional',
			'Region_Name',
			'Zone_Name',
			'Woreda_Name',
			'Number of Locations',
			'Dac_Code',
			'OECD_Description',
			'Classification_By_Strategic_Objective',
			'Project_Contact_Name',
			'Project_Contact_Email';

			-- Add parent data row to csv
    INSERT INTO csv_data (id,c1,c2,c3,c4,c5,c6,c7,c8,c9,c10,c11,c12,c13,c14,c15,c16,c17,c18,c19,c20,c21,c22,c23,c24,c25,c26,c27,c28)         	
		SELECT  counter
			,''::text				-- Activity Data
			,a.id::text		        -- PMT ActivityID
			,si.code::text			-- ProgramID
			,si.name::text			-- Program Name
			,a._iati_identifier::text	-- Project ID
			,a._title::text			-- Project Title
			,fund.source::text		-- Funder Source Name
			,psc.code::text			-- Primary_Oecd_Code,Secondary_Oecd_Code
			,psc.sector::text			-- Oecd Description
			,imp.partners::text		-- Primary_Implementing_Agency_Name
			,cl.crops::text			-- Crops & LiveStock
			,a._objective::text		-- Objective
			,a._start_date::text		-- Start Date
			,a._end_date::text		-- End Date
			,s.name::text			-- Activity Status	
			,f.amount::text			-- Total_Amount_IN_USD
			,cloan.loan::text		-- Loan
			,cgrant.grant::text		-- Grant
			,cln.nationallocal::text	-- Nation/Regional
			,g1.admin1::text	  	-- Regional
			,g2.admin2::text	  	-- Zone
			,g3.admin3::text	  	-- Woreda
			,l.location::text		-- Number of Locations
			,sc.sectorcategory::text	-- Dac_Code
			,sc.description::text	-- OECD_Description
			,a._description::text	-- Classification_By_Strategic_Objective
			,co.contact::text		-- Contact
			,coe.email::text 		-- Contact Email

		FROM
		-- activity
		(SELECT a.id, a.opportunity_id, a._title, a._description, a._start_date, a._end_date, a._objective, a._iati_identifier
		FROM activity a
		where a.id = pid and a._active = true) a
		left join 
		-- Sub-Initiative
		(SELECT at.activity_id, array_to_string(array_agg(DISTINCT c._name), ',') as name, '''' || array_to_string(array_agg(DISTINCT c._code), ',') || '''' as code
		FROM activity_taxonomy at
		join classification c
		on at.classification_id = c.id
		where c.taxonomy_id = (SELECT id FROM taxonomy where _name = 'ATA Program')
		and at.activity_id = pid and c._active = true
		group by at.activity_id) as si
		on a.id = si.activity_id
		left join
		-- Activity Status
		(SELECT at.activity_id, array_to_string(array_agg(DISTINCT c._name), ',') as name
		FROM activity_taxonomy at
		join classification c
		on at.classification_id = c.id
		where c.taxonomy_id =(SELECT id FROM taxonomy where _name = 'Activity Status')
		AND at.activity_id = pid and c._active = true
		group by at.activity_id) s
		on a.id = s.activity_id
		left join
		-- Primary and Secondary Code & Oecd Description
		(SELECT at.activity_id, array_to_string(array_agg(DISTINCT c._name), ',') as sector, '''' || array_to_string(array_agg(DISTINCT c._code), ',') || '''' as code
		FROM activity_taxonomy at
		join classification c
		on at.classification_id = c.id
		where c.taxonomy_id = (SELECT id FROM taxonomy where _name = 'Sector')
		and at.activity_id = pid and c._active = true
		group by at.activity_id) as psc
		on a.id = psc.activity_id
		left join
		-- CropLivestock
		(SELECT at.activity_id, array_to_string(array_agg(DISTINCT c._name), ',') as crops
		FROM activity_taxonomy at
		join classification c
		on at.classification_id = c.id
		where c.taxonomy_id = (SELECT id FROM taxonomy where _name = 'ATA Crops and Livestock')
		and at.activity_id = pid and c._active = true
		group by at.activity_id) as cl
		on a.id = cl.activity_id
		left join
		-- Sector Category
		(SELECT at.activity_id, array_to_string(array_agg(DISTINCT c._name), ',') as sectorcategory, array_to_string(array_agg(DISTINCT c._name), ',') as description
		FROM activity_taxonomy at
		join classification c
		on at.classification_id = c.id
		where c.taxonomy_id = (SELECT id FROM taxonomy where _name = 'Sector Category')
		and at.activity_id = pid and c._active = true
		group by at.activity_id) as sc
		on a.id = sc.activity_id
		left join
		-- Loan
		(SELECT f.activity_id, sum(f._amount) as loan
		FROM financial f left join financial_taxonomy ft on f.id = ft.financial_id 
		left join _taxonomy_classifications tc on ft.classification_id = tc.classification_id where tc.classification = 'LOAN'
		and f.activity_id = pid and f._active = true
		group by f.activity_id) as cloan
		on a.id = cloan.activity_id
		left join
		-- Grant
		(SELECT f.activity_id, sum(f._amount) as grant
		FROM financial f left join financial_taxonomy ft on f.id = ft.financial_id 
		left join _taxonomy_classifications tc on ft.classification_id = tc.classification_id where tc.classification = 'GRANT'
		and f.activity_id = pid and f._active = true
		group by f.activity_id) as cgrant 
		on a.id = cgrant.activity_id
		left join
		-- National/Local
		(SELECT at.activity_id, array_to_string(array_agg(DISTINCT c._name), ',') as nationallocal
		FROM activity_taxonomy at
		join classification c
		on at.classification_id = c.id
		where c.taxonomy_id = (SELECT id FROM taxonomy where _name = 'National/Local')
		and at.activity_id = pid and c._active = true
		group by at.activity_id) as cln
		on a.id = cln.activity_id
		left join
		-- financials
		(SELECT f.activity_id, sum(f._amount) as amount
		FROM financial f
		where f.activity_id = pid and f._active = true
		group by f.activity_id) as f
		on a.id = f.activity_id
		left join
		-- all funders
		(SELECT pp.activity_id, array_to_string(array_agg(DISTINCT o._name), ',') as source
		FROM participation pp
		join organization o
		on pp.organization_id = o.id
		left join participation_taxonomy ppt
		on pp.id = ppt.participation_id
		join classification c
		on ppt.classification_id = c.id
		where c.taxonomy_id = (SELECT id FROM taxonomy where _name = 'Organisation Role') AND (c._name = 'Funding')
		and pp.activity_id = pid and pp._active = true and o._active = true and c._active = true
		group by pp.activity_id) fund
		on a.id = fund.activity_id
		left join
		-- all partners
		(SELECT pp.activity_id, array_to_string(array_agg(DISTINCT o._name), ',') as partners
		FROM participation pp
		join organization o
		on pp.organization_id = o.id
		left join participation_taxonomy ppt
		on pp.id = ppt.participation_id
		join classification c
		on ppt.classification_id = c.id
		where c.taxonomy_id = (SELECT id FROM taxonomy where _name = 'Organisation Role') AND (c._name = 'Implementing')
		and pp.activity_id = pid and pp._active = true and o._active = true and c._active = true
		group by pp.activity_id) imp
		on a.id = imp.activity_id
		left join
		-- location count
		(SELECT l.activity_id, count(DISTINCT l.id) as location
		FROM location l
		where l.activity_id = pid and l._active = true
		group by l.activity_id) l
		on a.id = l.activity_id
		left join
		-- Contact
		(SELECT ac.activity_id, array_to_string(array_agg(DISTINCT _first_name || ' ' || _last_name), ',') as contact
		FROM contact c join activity_contact ac on ac.contact_id = c.id 
		where c._active = true and ac.activity_id = pid
		group by ac.activity_id) co
		on a.id =  co.activity_id
		left join
		-- Contact Email
		(SELECT ac.activity_id, array_to_string(array_agg(DISTINCT _email), ',') as email
		FROM contact c join activity_contact ac on ac.contact_id = c.id 
		where c._active = true and ac.activity_id = pid
		group by ac.activity_id) coe
		on a.id = coe.activity_id
		left join
		-- Admin1
		(SELECT lb.activity_id, array_to_string(array_agg(DISTINCT feature_name), ',') as admin1
		FROM _location_boundary_features lb where boundary_name = 'OCHA Ethiopia Administrative Level 1' 
		group by lb.activity_id) g1		
		on a.id = g1.activity_id
		left join
		-- Admin2
		(SELECT lb.activity_id, array_to_string(array_agg(DISTINCT feature_name), ',') as admin2
		FROM _location_boundary_features lb where boundary_name = 'OCHA Ethiopia Administrative Level 2'
		group by lb.activity_id) g2
		on a.id = g2.activity_id	
		left join
		-- Admin3
		(SELECT lb.activity_id, array_to_string(array_agg(DISTINCT feature_name), ',') as admin3
		FROM _location_boundary_features lb where boundary_name = 'OCHA Ethiopia Administrative Level 3'
		group by lb.activity_id) g3		
		on a.id = g3.activity_id;
        counter := counter + 1;

        	-- get children
	SELECT INTO children_ids array_agg(id) FROM activity a WHERE parent_id = pid;

	IF children_ids IS NOT NULL THEN
	
	RAISE NOTICE 'Children ids: %', children_ids;	

        -- Loop through children
	FOREACH aid IN ARRAY children_ids LOOP

				INSERT INTO csv_data (id,c1,c2,c3,c4,c5,c6,c7,c8,c9,c10,c11,c12,c13,c14,c15,c16,c17,c18,c19,c20,c21,c22,c23,c24,c25,c26,c27,c28)         	
		SELECT  counter
			,''::text				-- Activity Data
			,a.id::text		        -- PMT ActivityID
			,si.code::text			-- ProgramID
			,si.name::text			-- Program Name
			,a._iati_identifier::text	-- Project ID
			,a._title::text			-- Project Title
			,fund.source::text		-- Funder Source Name
			,psc.code::text			-- Primary_Oecd_Code,Secondary_Oecd_Code
			,psc.sector::text			-- Oecd Description
			,imp.partners::text		-- Primary_Implementing_Agency_Name
			,cl.crops::text			-- Crops & LiveStock
			,a._objective::text		-- Objective
			,a._start_date::text		-- Start Date
			,a._end_date::text		-- End Date
			,s.name::text			-- Activity Status	
			,f.amount::text			-- Total_Amount_IN_USD
			,cloan.loan::text		-- Loan
			,cgrant.grant::text		-- Grant
			,cln.nationallocal::text	-- Nation/Regional
			,g1.admin1::text	  	-- Regional
			,g2.admin2::text	  	-- Zone
			,g3.admin3::text	  	-- Woreda
			,l.location::text		-- Number of Locations
			,sc.sectorcategory::text	-- Dac_Code
			,sc.description::text	-- OECD_Description
			,a._description::text	-- Classification_By_Strategic_Objective
			,co.contact::text		-- Contact
			,coe.email::text 		-- Contact Email	
		FROM
		-- activity
		(SELECT a.id, a.opportunity_id, a._title, a._description, a._start_date, a._end_date, a._objective, a._iati_identifier
		FROM activity a
		where a.id = pid and a._active = true) a
		left join 
		-- Sub-Initiative
		(SELECT at.activity_id, array_to_string(array_agg(DISTINCT c._name), ',') as name, '''' || array_to_string(array_agg(DISTINCT c._code), ',') || '''' as code
		FROM activity_taxonomy at
		join classification c
		on at.classification_id = c.id
		where c.taxonomy_id = (SELECT id FROM taxonomy where _name = 'ATA Program')
		and at.activity_id = pid and c._active = true
		group by at.activity_id) as si
		on a.id = si.activity_id
		left join
		-- Activity Status
		(SELECT at.activity_id, array_to_string(array_agg(DISTINCT c._name), ',') as name
		FROM activity_taxonomy at
		join classification c
		on at.classification_id = c.id
		where c.taxonomy_id =(SELECT id FROM taxonomy where _name = 'Activity Status')
		AND at.activity_id = pid and c._active = true
		group by at.activity_id) s
		on a.id = s.activity_id
		left join
		-- Primary and Secondary Code & Oecd Description
		(SELECT at.activity_id, '''' || array_to_string(array_agg(c._code), ',') || '''' as code, array_to_string(array_agg(c._name), ',') as name
		FROM activity_taxonomy at
		join classification c
		on at.classification_id = c.id
		where c.taxonomy_id = (SELECT id FROM taxonomy where _name = 'Sector')
		and at.activity_id = pid and c._active = true
		group by at.activity_id) as psc
		on a.id = psc.activity_id
		left join
		-- CropLivestock
		(SELECT at.activity_id, array_to_string(array_agg(DISTINCT c._name), ',') as crops
		FROM activity_taxonomy at
		join classification c
		on at.classification_id = c.id
		where c.taxonomy_id = (SELECT id FROM taxonomy where _name = 'ATA Crops and Livestock')
		and at.activity_id = pid and c._active = true
		group by at.activity_id) as cl
		on a.id = cl.activity_id
		left join
		-- Sector Category
		(SELECT at.activity_id, array_to_string(array_agg(DISTINCT c._name), ',') as sectorcategory, array_to_string(array_agg(DISTINCT c._name), ',') as description
		FROM activity_taxonomy at
		join classification c
		on at.classification_id = c.id
		where c.taxonomy_id = (SELECT id FROM taxonomy where _name = 'Sector Category')
		and at.activity_id = pid and c._active = true
		group by at.activity_id) as sc
		on a.id = sc.activity_id
		left join
		-- Loan
		(SELECT f.activity_id, sum(f._amount) as loan
		FROM financial f left join financial_taxonomy ft on f.id = ft.financial_id 
		left join _taxonomy_classifications tc on ft.classification_id = tc.classification_id where tc.classification = 'LOAN'
		and f.activity_id = pid and f._active = true
		group by f.activity_id) as cloan
		on a.id = cloan.activity_id
		left join
		-- Grant
		(SELECT f.activity_id, sum(f._amount) as grant
		FROM financial f left join financial_taxonomy ft on f.id = ft.financial_id 
		left join _taxonomy_classifications tc on ft.classification_id = tc.classification_id where tc.classification = 'GRANT'
		and f.activity_id = pid and f._active = true
		group by f.activity_id) as cgrant 
		on a.id = cgrant.activity_id
		left join
		-- National/Local
		(SELECT at.activity_id, array_to_string(array_agg(DISTINCT c._name), ',') as nationallocal
		FROM activity_taxonomy at
		join classification c
		on at.classification_id = c.id
		where c.taxonomy_id = (SELECT id FROM taxonomy where _name = 'National/Local')
		and at.activity_id = pid and c._active = true
		group by at.activity_id) as cln
		on a.id = cln.activity_id
		left join
		-- financials
		(SELECT f.activity_id, sum(f._amount) as amount
		FROM financial f
		where f.activity_id = pid and f._active = true
		group by f.activity_id) as f
		on a.id = f.activity_id
		left join
		-- all funders
		(SELECT pp.activity_id, array_to_string(array_agg(DISTINCT o._name), ',') as source
		FROM participation pp
		join organization o
		on pp.organization_id = o.id
		left join participation_taxonomy ppt
		on pp.id = ppt.participation_id
		join classification c
		on ppt.classification_id = c.id
		where c.taxonomy_id = (SELECT id FROM taxonomy where _name = 'Organisation Role') AND (c._name = 'Funding')
		and pp.activity_id = pid and pp._active = true and o._active = true and c._active = true
		group by pp.activity_id) fund
		on a.id = fund.activity_id
		left join
		-- all partners
		(SELECT pp.activity_id, array_to_string(array_agg(DISTINCT o._name), ',') as partners
		FROM participation pp
		join organization o
		on pp.organization_id = o.id
		left join participation_taxonomy ppt
		on pp.id = ppt.participation_id
		join classification c
		on ppt.classification_id = c.id
		where c.taxonomy_id = (SELECT id FROM taxonomy where _name = 'Organisation Role') AND (c._name = 'Implementing')
		and pp.activity_id = pid and pp._active = true and o._active = true and c._active = true
		group by pp.activity_id) imp
		on a.id = imp.activity_id
		left join
		-- location count
		(SELECT l.activity_id, count(DISTINCT l.id) as location
		FROM location l
		where l.activity_id = pid and l._active = true
		group by l.activity_id) l
		on a.id = l.activity_id
		left join
		-- Contact
		(SELECT ac.activity_id, array_to_string(array_agg(DISTINCT _first_name || ' ' || _last_name), ',') as contact
		FROM contact c join activity_contact ac on ac.contact_id = c.id 
		where c._active = true and ac.activity_id = pid
		group by ac.activity_id) co
		on a.id =  co.activity_id
		left join
		-- Contact Email
		(SELECT ac.activity_id, array_to_string(array_agg(DISTINCT _email), ',') as email
		FROM contact c join activity_contact ac on ac.contact_id = c.id 
		where c._active = true and ac.activity_id = pid
		group by ac.activity_id) coe
		on a.id = coe.activity_id
		left join
		-- Admin1
		(SELECT lb.activity_id, array_to_string(array_agg(DISTINCT feature_name), ',') as admin1
		FROM _location_boundary_features lb where boundary_name = 'OCHA Ethiopia Administrative Level 1' 
		group by lb.activity_id) g1		
		on a.id = g1.activity_id
		left join
		-- Admin2
		(SELECT lb.activity_id, array_to_string(array_agg(DISTINCT feature_name), ',') as admin2
		FROM _location_boundary_features lb where boundary_name = 'OCHA Ethiopia Administrative Level 2'
		group by lb.activity_id) g2
		on a.id = g2.activity_id	
		left join
		-- Admin3
		(SELECT lb.activity_id, array_to_string(array_agg(DISTINCT feature_name), ',') as admin3
		FROM _location_boundary_features lb where boundary_name = 'OCHA Ethiopia Administrative Level 3'
		group by lb.activity_id) g3		
		on a.id = g3.activity_id;
        counter := counter + 1;

	END LOOP; 

	END IF; 

  END LOOP;

  END IF;

  -- uncomment for testing csv result		
  -- filename := '''/Users/admin/Desktop/pmt-v/ethaim.csv''';
  -- fileencoding = '''UTF8''';
  -- EXECUTE 'COPY(SELECT c1,c2,c3,c4,c5,c6,c7,c8,c9,c10,c11,c12,c13,c14,c15,c16,c17,c18,c19,c20,c21,c22,c23,c24,c25,c26,c27,c28 FROM csv_data ORDER BY id) To ' || filename || ' With CSV ENCODING ' || fileencoding || ';'; 
  
    FOR rec IN SELECT row_to_json(j) FROM (
    SELECT c1,c2,c3,c4,c5,c6,c7,c8,c9,c10,c11,c12,c13,c14,c15,c16,c17,c18 FROM csv_data ORDER BY id
  ) j LOOP
	RETURN NEXT rec;
  END LOOP;

EXCEPTION WHEN others THEN
    GET STACKED DIAGNOSTICS error_msg = MESSAGE_TEXT;
    FOR rec IN (SELECT row_to_json(j) FROM(SELECT 'Internal Error - Contact your DBA with the following error message: ' || error_msg as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;	  	
END;$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100
  ROWS 1000;
ALTER FUNCTION pmt_export_ethaim(character varying, character varying, character varying, character varying, character varying, date, date, character varying)
  OWNER TO postgres;

-- Function: pmt_export_tanaim(character varying, character varying, character varying, character varying, character varying, date, date, character varying)

-- DROP FUNCTION pmt_export_tanaim(character varying, character varying, character varying, character varying, character varying, date, date, character varying);

CREATE OR REPLACE FUNCTION pmt_export_tanaim(data_group_ids character varying, classification_ids character varying, org_ids character varying, imp_org_ids character varying, fund_org_ids character varying, start_date date, end_date date, unassigned_taxonomy_ids character varying)
  RETURNS SETOF pmt_json_result_type AS
$BODY$
DECLARE
  activity_ids int[];
  parent_ids int[];
  no_parent_activities int[];
  children_ids int[];
  pid int;
  aid int;
  counter int;
  filter_classids integer array;
  filter_orgids integer array;
  filter text;
  disclaimer text;
  filename text;
  fileencoding text;
  db_version text;
  db_instance text;
  rec record;
  element record;
  error_msg text;
BEGIN
  -- create temporary table to hold our data for the csv
  CREATE TEMPORARY TABLE csv_data (
      id int,c1 text,c2 text,c3 text,c4 text,c5 text,c6 text,c7 text,c8 text,c9 text,c10 text
     ,c11 text,c12 text,c13 text,c14 text,c15 text,c16 text,c17 text,c18 text, c19 text, c20 text, c21 text
     ) ON COMMIT DROP;

  -- get database version
  FOR element IN SELECT * FROM json_each( (SELECT * FROM pmt_version()) ) LOOP
   IF element.key = 'pmt_version' THEN
	db_version = element.value;
	RAISE NOTICE 'db version: %', db_version;
   END IF;
  END LOOP;
  
  -- build version/date/filter line
  SELECT INTO filter * FROM pmt_filter_string($1,$2,$3,$4,$5,$6,$7,$8);
  RAISE NOTICE 'filters: %', filter;

  disclaimer := 'Disclaimer: TEXT';
  counter := 1;
 
  -- write the filter
  INSERT INTO csv_data (id,c1) SELECT counter, filter;
  counter := counter + 1;
  -- write the disclaimer
  INSERT INTO csv_data (id,c1) SELECT counter, disclaimer;
  counter := counter + 1;

  SELECT INTO activity_ids * FROM pmt_filter($1,$2,$3,$4,$5,$6,$7,$8);

  -- get activities with no parents
  SELECT INTO no_parent_activities array_agg(id) FROM ((SELECT id FROM activity WHERE id IN (SELECT unnest( (SELECT * FROM pmt_filter($1,$2,$3,$4,$5,$6,$7,$8)) )) AND parent_id IS NULL )
   EXCEPT
   SELECT DISTINCT parent_id FROM activity where parent_id in ((SELECT id FROM activity WHERE id IN (SELECT unnest( (SELECT * FROM pmt_filter($1,$2,$3,$4,$5,$6,$7,$8)) )) AND parent_id IS NULL ))) j;
   
   -- no activities 
   IF no_parent_activities IS NULL THEN
	no_parent_activities = activity_ids;
	RAISE NOTICE 'activity ids: %', activity_ids; 
   END IF;

  RAISE NOTICE 'non parent activities: %', no_parent_activities;

  -- get all parent activities
  SELECT INTO parent_ids array_agg(DISTINCT parent_id) FROM activity WHERE parent_id IN (SELECT id FROM activity WHERE id IN (SELECT unnest( (SELECT * FROM pmt_filter($1,$2,$3,$4,$5,$6,$7,$8)) )) and parent_id IS NULL);

   -- 1. Add header row and Loop through activities with no children or parents
   -- 2. Loop through parent activities & their children. Add header row for each parent & group of children
 
   -- activity ids with no children or parents

   IF no_parent_activities IS NOT NULL THEN
     
     -- Add one header row for this group of activities
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

     FOREACH pid IN ARRAY no_parent_activities LOOP

		-- Add activity data row to csv
			INSERT INTO csv_data (id,c1,c2,c3,c4,c5,c6,c7,c8,c9,c10,c11,c12,c13,c14,c15,c16,c17,c18,c19,c20)        	
		SELECT  counter
			,''::text			-- Activity Data
			,a.id::text		-- PMT ActivityID
			,a._iati_identifier::text	-- S_No
			,a._title::text			-- ProgramName/Sub-Category
			,a._description::text		-- ProgramDescription
			,acc.name::text			-- DevelopmentPartners
			,fund.name::text		-- ImplementingPartner
			,imp.name::text			-- LocalPartners_Collaborators
			,ic.name::text			-- InterventionCategory
			,isc.name::text			-- InterventionSub-Category
			,a._content::text		-- Activities
			,s.name::text			-- Activity Status	
			,c.name::text			-- Country
			,g1.region::text	  	-- Region
			,g2.district::text		-- District
			,a.target_beneficiaries::text	-- TargetBeneficiaries
			,cl.name::text			-- Crops_Livestock
			,a._start_date::text		-- Start Date
			,a._end_date::text		-- End Date
			,f.amount::text			-- InvestmentAmount			
		FROM
		-- activity
		(SELECT a.id, a._iati_identifier, a._title, a._description, a._start_date, a._end_date, a.target_beneficiaries, a._content
		FROM activity a
		where a.id = pid and a._active = true) a
		left join 
		-- Category
		(SELECT at.activity_id, array_to_string(array_agg(DISTINCT c._name), ',') as name
		FROM activity_taxonomy at
		join classification c
		on at.classification_id = c.id
		where c.taxonomy_id = (SELECT id FROM taxonomy where _name = 'Category')
		and at.activity_id = pid and c._active = true
		group by at.activity_id) as ic
		on a.id = ic.activity_id
		left join
		-- Sub-Category
		(SELECT at.activity_id, array_to_string(array_agg(DISTINCT c._name), ',') as name
		FROM activity_taxonomy at
		join classification c
		on at.classification_id = c.id
		where c.taxonomy_id = (SELECT id FROM taxonomy where _name = 'Sub-Category')
		and at.activity_id = pid and c._active = true
		group by at.activity_id) as isc
		on a.id = isc.activity_id
		left join
		-- Country
		(SELECT l.activity_id, array_to_string(array_agg(DISTINCT c._name), ',') as name
		FROM location l 
		join location_taxonomy lt
		on l.id = lt.location_id
		join classification c
		on lt.classification_id = c.id
		where c.taxonomy_id =(SELECT id FROM taxonomy where _name = 'Country')
		AND l.activity_id = pid and l._active = true and c._active = true
		group by l.activity_id) c
		on a.id = c.activity_id
		left join
		-- Activity Status
		(SELECT at.activity_id, array_to_string(array_agg(DISTINCT c._name), ',') as name
		FROM activity_taxonomy at
		join classification c
		on at.classification_id = c.id
		where c.taxonomy_id =(SELECT id FROM taxonomy where _name = 'Activity Status')
		AND at.activity_id = pid and c._active = true
		group by at.activity_id) s
		on a.id = s.activity_id
		left join
		-- Crops and Livestock
		(SELECT at.activity_id, array_to_string(array_agg(DISTINCT c._name), ',') as name
		FROM activity_taxonomy at
		join classification c
		on at.classification_id = c.id
		where c.taxonomy_id =(SELECT id FROM taxonomy where _name = 'Crops and Livestock')
		AND at.activity_id = pid and c._active = true
		group by at.activity_id) cl
		on a.id = cl.activity_id
		left join
		-- financials
		(SELECT f.activity_id, sum(f._amount) as amount
		FROM financial f
		where f.activity_id = pid and f._active = true
		group by f.activity_id) as f
		on a.id = f.activity_id
		left join
		-- accountable
		(SELECT pp.activity_id, array_to_string(array_agg(DISTINCT o._name), ',') as name, array_to_string(array_agg(DISTINCT c._name), ',') as role
		FROM participation pp
		join organization o
		on pp.organization_id = o.id
		left join participation_taxonomy ppt
		on pp.id = ppt.participation_id
		join classification c
		on ppt.classification_id = c.id
		where c.taxonomy_id = (SELECT id FROM taxonomy where _name = 'Organisation Role') AND (c._name = 'Accountable')
		and pp.activity_id = pid and pp._active = true and o._active = true and c._active = true
		group by pp.activity_id) acc
		on a.id = acc.activity_id
		left join
		-- funding
		(SELECT pp.activity_id, array_to_string(array_agg(DISTINCT o._name), ',') as name, array_to_string(array_agg(DISTINCT c._name), ',') as role
		FROM participation pp
		join organization o
		on pp.organization_id = o.id
		left join participation_taxonomy ppt
		on pp.id = ppt.participation_id
		join classification c
		on ppt.classification_id = c.id
		where c.taxonomy_id = (SELECT id FROM taxonomy where _name = 'Organisation Role') AND (c._name = 'Funding')
		and pp.activity_id = pid and pp._active = true and o._active = true and c._active = true
		group by pp.activity_id) fund
		on a.id = fund.activity_id
		left join
		-- implementing
		(SELECT pp.activity_id, array_to_string(array_agg(DISTINCT o._name), ',') as name, array_to_string(array_agg(DISTINCT c._name), ',') as role
		FROM participation pp
		join organization o
		on pp.organization_id = o.id
		left join participation_taxonomy ppt
		on pp.id = ppt.participation_id
		join classification c
		on ppt.classification_id = c.id
		where c.taxonomy_id = (SELECT id FROM taxonomy where _name = 'Organisation Role') AND (c._name = 'Implementing')
		and pp.activity_id = pid and pp._active = true and o._active = true and c._active = true
		group by pp.activity_id) imp
		on a.id = imp.activity_id
		left join
		-- regions
		(SELECT lb.activity_id, array_to_string(array_agg(DISTINCT feature_name), ',') as region
		FROM _location_boundary_features lb where boundary_name = 'GAUL Level 1' 
		group by lb.activity_id) g1		
		on a.id = g1.activity_id
		left join
		-- districts
		(SELECT lb.activity_id, array_to_string(array_agg(DISTINCT feature_name), ',') as district
		FROM _location_boundary_features lb where boundary_name = 'GAUL Level 2'
		group by lb.activity_id) g2		
		on a.id = g2.activity_id;
        counter := counter + 1;

  END LOOP;
  END IF;


     IF parent_ids IS NOT NULL THEN
  	 -- Loop through parent_ids
     FOREACH pid IN ARRAY parent_ids LOOP
     RAISE NOTICE 'Preparing activity id: %', pid;	

     -- Add parent header to csv
     INSERT INTO csv_data (id,c1,c2,c3,c4,c5,c6,c7,c8,c9,c10,c11,c12,c13,c14,c15,c16,c17,c18,c19,c20,c21)        	
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
			,'InvestmentAmount (Tanzanian Shilling)'
			,'ParentID';
     counter := counter + 1;

			-- Add parent data row to csv
     					INSERT INTO csv_data (id,c1,c2,c3,c4,c5,c6,c7,c8,c9,c10,c11,c12,c13,c14,c15,c16,c17,c18,c19,c20,c21)        	
		SELECT  counter
			,''::text			-- Activity Data
			,a.id::text		-- PMT ActivityID
			,a._iati_identifier::text	-- S_No
			,a._title::text			-- ProgramName/Sub-Category
			,a._description::text		-- ProgramDescription
			,acc.name::text			-- DevelopmentPartners
			,fund.name::text		-- ImplementingPartner
			,imp.name::text			-- LocalPartners_Collaborators
			,ic.name::text			-- InterventionCategory
			,isc.name::text			-- InterventionSub-Category
			,a._content::text		-- Activities
			,s.name::text			-- Activity Status	
			,c.name::text			-- Country
			,g1.region::text	  	-- Region
			,g2.district::text		-- District
			,a.target_beneficiaries::text	-- TargetBeneficiaries
			,cl.name::text			-- Crops_Livestock
			,a._start_date::text		-- Start Date
			,a._end_date::text		-- End Date
			,f.amount::text			-- InvestmentAmount		
			,a.parent_id::text 		-- Parent ActivityID	
		FROM
		-- activity
		(SELECT a.id, a._iati_identifier, a._title, a._description, a._start_date, a._end_date, a.target_beneficiaries, a._content, a.parent_id
		FROM activity a
		where a.id = pid and a._active = true) a
		left join 
		-- Category
		(SELECT at.activity_id, array_to_string(array_agg(DISTINCT c._name), ',') as name
		FROM activity_taxonomy at
		join classification c
		on at.classification_id = c.id
		where c.taxonomy_id = (SELECT id FROM taxonomy where _name = 'Category')
		and at.activity_id = pid and c._active = true
		group by at.activity_id) as ic
		on a.id = ic.activity_id
		left join
		-- Sub-Category
		(SELECT at.activity_id, array_to_string(array_agg(DISTINCT c._name), ',') as name
		FROM activity_taxonomy at
		join classification c
		on at.classification_id = c.id
		where c.taxonomy_id = (SELECT id FROM taxonomy where _name = 'Sub-Category')
		and at.activity_id = pid and c._active = true
		group by at.activity_id) as isc
		on a.id = isc.activity_id
		left join
		-- Country
		(SELECT l.activity_id, array_to_string(array_agg(DISTINCT c._name), ',') as name
		FROM location l 
		join location_taxonomy lt
		on l.id = lt.location_id
		join classification c
		on lt.classification_id = c.id
		where c.taxonomy_id =(SELECT id FROM taxonomy where _name = 'Country')
		AND l.activity_id = pid and l._active = true and c._active = true
		group by l.activity_id) c
		on a.id = c.activity_id
		left join
		-- Activity Status
		(SELECT at.activity_id, array_to_string(array_agg(DISTINCT c._name), ',') as name
		FROM activity_taxonomy at
		join classification c
		on at.classification_id = c.id
		where c.taxonomy_id =(SELECT id FROM taxonomy where _name = 'Activity Status')
		AND at.activity_id = pid and c._active = true
		group by at.activity_id) s
		on a.id = s.activity_id
		left join
		-- Crops and Livestock
		(SELECT at.activity_id, array_to_string(array_agg(DISTINCT c._name), ',') as name
		FROM activity_taxonomy at
		join classification c
		on at.classification_id = c.id
		where c.taxonomy_id =(SELECT id FROM taxonomy where _name = 'Crops and Livestock')
		AND at.activity_id = pid and c._active = true
		group by at.activity_id) cl
		on a.id = cl.activity_id
		left join
		-- financials
		(SELECT f.activity_id, sum(f._amount) as amount
		FROM financial f
		where f.activity_id = pid and f._active = true
		group by f.activity_id) as f
		on a.id = f.activity_id
		left join
		-- accountable
		(SELECT pp.activity_id, array_to_string(array_agg(DISTINCT o._name), ',') as name, array_to_string(array_agg(DISTINCT c._name), ',') as role
		FROM participation pp
		join organization o
		on pp.organization_id = o.id
		left join participation_taxonomy ppt
		on pp.id = ppt.participation_id
		join classification c
		on ppt.classification_id = c.id
		where c.taxonomy_id = (SELECT id FROM taxonomy where _name = 'Organisation Role') AND (c._name = 'Accountable')
		and pp.activity_id = pid and pp._active = true and o._active = true and c._active = true
		group by pp.activity_id) acc
		on a.id = acc.activity_id
		left join
		-- funding
		(SELECT pp.activity_id, array_to_string(array_agg(DISTINCT o._name), ',') as name, array_to_string(array_agg(DISTINCT c._name), ',') as role
		FROM participation pp
		join organization o
		on pp.organization_id = o.id
		left join participation_taxonomy ppt
		on pp.id = ppt.participation_id
		join classification c
		on ppt.classification_id = c.id
		where c.taxonomy_id = (SELECT id FROM taxonomy where _name = 'Organisation Role') AND (c._name = 'Funding')
		and pp.activity_id = pid and pp._active = true and o._active = true and c._active = true
		group by pp.activity_id) fund
		on a.id = fund.activity_id
		left join
		-- implementing
		(SELECT pp.activity_id, array_to_string(array_agg(DISTINCT o._name), ',') as name, array_to_string(array_agg(DISTINCT c._name), ',') as role
		FROM participation pp
		join organization o
		on pp.organization_id = o.id
		left join participation_taxonomy ppt
		on pp.id = ppt.participation_id
		join classification c
		on ppt.classification_id = c.id
		where c.taxonomy_id = (SELECT id FROM taxonomy where _name = 'Organisation Role') AND (c._name = 'Implementing')
		and pp.activity_id = pid and pp._active = true and o._active = true and c._active = true
		group by pp.activity_id) imp
		on a.id = imp.activity_id
		left join
		-- regions
		(SELECT lb.activity_id, array_to_string(array_agg(DISTINCT feature_name), ',') as region
		FROM _location_boundary_features lb where boundary_name = 'GAUL Level 1' 
		group by lb.activity_id) g1		
		on a.id = g1.activity_id
		left join
		-- districts
		(SELECT lb.activity_id, array_to_string(array_agg(DISTINCT feature_name), ',') as district
		FROM _location_boundary_features lb where boundary_name = 'GAUL Level 2'
		group by lb.activity_id) g2		
		on a.id = g2.activity_id;
        counter := counter + 1;

        	-- get children
	SELECT INTO children_ids array_agg(id) FROM activity a WHERE parent_id = pid;

	IF children_ids IS NOT NULL THEN
	
	RAISE NOTICE 'Children ids: %', children_ids;	

        -- Loop through children
	FOREACH aid IN ARRAY children_ids LOOP

				INSERT INTO csv_data (id,c1,c2,c3,c4,c5,c6,c7,c8,c9,c10,c11,c12,c13,c14,c15,c16,c17,c18,c19,c20,c21)        	
		SELECT  counter
			,''::text			-- Activity Data
			,a.id::text		-- PMT ActivityID
			,a._iati_identifier::text	-- S_No
			,a._title::text			-- ProgramName/Sub-Category
			,a._description::text		-- ProgramDescription
			,acc.name::text			-- DevelopmentPartners
			,fund.name::text		-- ImplementingPartner
			,imp.name::text			-- LocalPartners_Collaborators
			,ic.name::text			-- InterventionCategory
			,isc.name::text			-- InterventionSub-Category
			,a._content::text		-- Activities
			,s.name::text			-- Activity Status	
			,c.name::text			-- Country
			,g1.region::text	  	-- Region
			,g2.district::text		-- District
			,a.target_beneficiaries::text	-- TargetBeneficiaries
			,cl.name::text			-- Crops_Livestock
			,a._start_date::text		-- Start Date
			,a._end_date::text		-- End Date
			,f.amount::text			-- InvestmentAmount	
			,a.parent_id::text		-- Parent Activity ID		
		FROM
		-- activity
		(SELECT a.id, a._iati_identifier, a._title, a._description, a._start_date, a._end_date, a.target_beneficiaries, a._content, a.parent_id
		FROM activity a
		where a.id = aid and a._active = true) a
		left join 
		-- Category
		(SELECT at.activity_id, array_to_string(array_agg(DISTINCT c._name), ',') as name
		FROM activity_taxonomy at
		join classification c
		on at.classification_id = c.id
		where c.taxonomy_id = (SELECT id FROM taxonomy where _name = 'Category')
		and at.activity_id = aid and c._active = true
		group by at.activity_id) as ic
		on a.id = ic.activity_id
		left join
		-- Sub-Category
		(SELECT at.activity_id, array_to_string(array_agg(DISTINCT c._name), ',') as name
		FROM activity_taxonomy at
		join classification c
		on at.classification_id = c.id
		where c.taxonomy_id = (SELECT id FROM taxonomy where _name = 'Sub-Category')
		and at.activity_id = aid and c._active = true
		group by at.activity_id) as isc
		on a.id = isc.activity_id
		left join
		-- Country
		(SELECT l.activity_id, array_to_string(array_agg(DISTINCT c._name), ',') as name
		FROM location l 
		join location_taxonomy lt
		on l.id = lt.location_id
		join classification c
		on lt.classification_id = c.id
		where c.taxonomy_id =(SELECT id FROM taxonomy where _name = 'Country')
		AND l.activity_id = aid and l._active = true and c._active = true
		group by l.activity_id) c
		on a.id = c.activity_id
		left join
		-- Activity Status
		(SELECT at.activity_id, array_to_string(array_agg(DISTINCT c._name), ',') as name
		FROM activity_taxonomy at
		join classification c
		on at.classification_id = c.id
		where c.taxonomy_id =(SELECT id FROM taxonomy where _name = 'Activity Status')
		AND at.activity_id = aid and c._active = true
		group by at.activity_id) s
		on a.id = s.activity_id
		left join
		-- Crops and Livestock
		(SELECT at.activity_id, array_to_string(array_agg(DISTINCT c._name), ',') as name
		FROM activity_taxonomy at
		join classification c
		on at.classification_id = c.id
		where c.taxonomy_id =(SELECT id FROM taxonomy where _name = 'Crops and Livestock')
		AND at.activity_id = aid and c._active = true
		group by at.activity_id) cl
		on a.id = cl.activity_id
		left join
		-- financials
		(SELECT f.activity_id, sum(f._amount) as amount
		FROM financial f
		where f.activity_id = aid and f._active = true
		group by f.activity_id) as f
		on a.id = f.activity_id
		left join
		-- accountable
		(SELECT pp.activity_id, array_to_string(array_agg(DISTINCT o._name), ',') as name, array_to_string(array_agg(DISTINCT c._name), ',') as role
		FROM participation pp
		join organization o
		on pp.organization_id = o.id
		left join participation_taxonomy ppt
		on pp.id = ppt.participation_id
		join classification c
		on ppt.classification_id = c.id
		where c.taxonomy_id = (SELECT id FROM taxonomy where _name = 'Organisation Role') AND (c._name = 'Accountable')
		and pp.activity_id = aid and pp._active = true and o._active = true and c._active = true
		group by pp.activity_id) acc
		on a.id = acc.activity_id
		left join
		-- funding
		(SELECT pp.activity_id, array_to_string(array_agg(DISTINCT o._name), ',') as name, array_to_string(array_agg(DISTINCT c._name), ',') as role
		FROM participation pp
		join organization o
		on pp.organization_id = o.id
		left join participation_taxonomy ppt
		on pp.id = ppt.participation_id
		join classification c
		on ppt.classification_id = c.id
		where c.taxonomy_id = (SELECT id FROM taxonomy where _name = 'Organisation Role') AND (c._name = 'Funding')
		and pp.activity_id = aid and pp._active = true and o._active = true and c._active = true
		group by pp.activity_id) fund
		on a.id = fund.activity_id
		left join
		-- implementing
		(SELECT pp.activity_id, array_to_string(array_agg(DISTINCT o._name), ',') as name, array_to_string(array_agg(DISTINCT c._name), ',') as role
		FROM participation pp
		join organization o
		on pp.organization_id = o.id
		left join participation_taxonomy ppt
		on pp.id = ppt.participation_id
		join classification c
		on ppt.classification_id = c.id
		where c.taxonomy_id = (SELECT id FROM taxonomy where _name = 'Organisation Role') AND (c._name = 'Implementing')
		and pp.activity_id = aid and pp._active = true and o._active = true and c._active = true
		group by pp.activity_id) imp
		on a.id = imp.activity_id
		left join
		-- regions
		(SELECT lb.activity_id, array_to_string(array_agg(DISTINCT feature_name), ',') as region
		FROM _location_boundary_features lb where boundary_name = 'GAUL Level 1' 
		group by lb.activity_id) g1		
		on a.id = g1.activity_id
		left join
		-- districts
		(SELECT lb.activity_id, array_to_string(array_agg(DISTINCT feature_name), ',') as district
		FROM _location_boundary_features lb where boundary_name = 'GAUL Level 2'
		group by lb.activity_id) g2		
		on a.id = g2.activity_id;
        counter := counter + 1;


	END LOOP; 

	END IF; 

  END LOOP;

  END IF;

  -- uncomment for testing csv result		
  --filename := '''/Users/admin/Desktop/pmt-v/tanaim.csv''';
  --fileencoding = '''UTF8''';
  --EXECUTE 'COPY(SELECT c1,c2,c3,c4,c5,c6,c7,c8,c9,c10,c11,c12,c13,c14,c15,c16,c17,c18,c19,c20,c21 FROM csv_data ORDER BY id) To ' || filename || ' With CSV ENCODING ' || fileencoding || ';'; 
  
    FOR rec IN SELECT row_to_json(j) FROM (
    SELECT c1,c2,c3,c4,c5,c6,c7,c8,c9,c10,c11,c12,c13,c14,c15,c16,c17,c18 FROM csv_data ORDER BY id
  ) j LOOP
	RETURN NEXT rec;
  END LOOP;

EXCEPTION WHEN others THEN
    GET STACKED DIAGNOSTICS error_msg = MESSAGE_TEXT;
    FOR rec IN (SELECT row_to_json(j) FROM(SELECT 'Internal Error - Contact your DBA with the following error message: ' || error_msg as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;	  	
END;$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100
  ROWS 1000;
ALTER FUNCTION pmt_export_tanaim(character varying, character varying, character varying, character varying, character varying, date, date, character varying)
  OWNER TO postgres;

