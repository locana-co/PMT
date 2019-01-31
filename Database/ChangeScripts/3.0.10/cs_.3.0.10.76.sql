/******************************************************************
Change Script 3.0.10.76
1. create a function to get activity details specifically for editing
2. update the tanaim export to address missing elements
3. create function to force update of boundary features for a location
4. update pmt_upd_boundary_features to allow global layers to intersect
 country specific layers
******************************************************************/
INSERT INTO version(_version, _iteration, _changeset) VALUES (3.0, 10, 76);
-- select * from version order by _iteration desc, _changeset desc;

/******************************************************************
1. create a function to get activity details specifically for editing 
  SELECT * FROM pmt_full_record(23608);
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_full_record(activity_id integer) RETURNS SETOF pmt_json_result_type AS 
$$
DECLARE
  rec record;
  invalid_return_columns text[];
  return_columns text;
  execute_statement text;
  data_message text;
BEGIN
  IF $1 IS NOT NULL THEN	
    -- get list of columns to return
    SELECT INTO return_columns array_to_string(array_agg('a.' || column_name::text), ', ') FROM information_schema.columns 
    WHERE table_schema='public' AND table_name='activity';

    -- dynamically build the execute statment	
    execute_statement := 'SELECT ' || return_columns || ', (SELECT _name FROM classification WHERE id = data_group_id) as data_group' || 
				', (SELECT _title FROM activity WHERE id = a.parent_id) as parent_title, l.ct ';

    -- taxonomy	
    execute_statement := execute_statement || ',(SELECT array_to_json(array_agg(row_to_json(t))) FROM ( ' ||
				'select tc.taxonomy_id, tc.taxonomy, tc.classification_id, tc.classification, tc._code ' ||
				'from activity_taxonomy at ' ||
				'join _taxonomy_classifications  tc ' ||
				'on at.classification_id = tc.classification_id ' ||
				'and at.activity_id = ' || $1 ||
				') t ) as taxonomy ';
    -- organizations			
    execute_statement := execute_statement || ',(SELECT array_to_json(array_agg(row_to_json(p))) FROM ( ' ||
				'select o.id, _name, classification_id, classification '  ||
				'from _organization_lookup ol join organization o on ol.organization_id = o.id ' ||
				'where activity_id = ' || $1 ||
				') p ) as organizations ';
				
    -- contacts
    execute_statement := execute_statement || ',(SELECT array_to_json(array_agg(row_to_json(c))) FROM ( ' ||
				'select c.id, c._first_name, c._last_name, c._email, c.organization_id, o._name ' ||
				'from activity_contact ac ' ||
				'join contact c ' ||
				'on ac.contact_id = c.id ' ||
				'left join organization o ' ||
				'on c.organization_id = o.id ' ||
				'where c._active = true and ac.activity_id = ' || $1 ||
				') c ) as contacts ';	

    -- financials
    execute_statement := execute_statement || ',(SELECT array_to_json(array_agg(row_to_json(f))) FROM ( ' ||
				'select f.id, f._amount, f._start_date, f._end_date'  ||
						',provider_id' ||
						',(SELECT _name FROM organization WHERE id = provider_id) as provider' ||
						',recipient_id' ||
						',(SELECT _name FROM organization WHERE id = recipient_id) as recipient' ||
						', (SELECT array_to_json(array_agg(row_to_json(t))) FROM ( ' ||
						'select tc.taxonomy_id, tc.taxonomy, tc.classification_id, tc.classification, tc._code ' ||
						'from financial_taxonomy ft ' ||
						'join _taxonomy_classifications tc ' ||
						'on ft.classification_id = tc.classification_id ' ||
						'and ft.financial_id = f.id ' ||
						') t ) as taxonomy ' ||
				'from financial f ' ||		
				'where f._active = true and f.activity_id = ' || $1 ||
				') f ) as financials ';

    -- locations
    execute_statement := execute_statement || ',(SELECT array_to_json(array_agg(row_to_json(l))) FROM (  ' ||
				'select l.id, l._admin0, l._admin1, l._admin2, l._admin3, l._admin_level, l.boundary_id, l.feature_id ' ||
				'from location l ' ||		
				'where l._active = true and l.activity_id = ' || $1 ||
				') l ) as locations ';		

    -- children
    execute_statement := execute_statement || ',(SELECT array_to_json(array_agg(row_to_json(a))) FROM (  ' ||
				'select a.id, a._title ' ||					
				'from activity a ' ||		
				'where a._active = true and a.parent_id = ' || $1 ||
				') a ) as children ';	
													
								
    -- activity
    execute_statement := execute_statement || 'from (select * from activity a where a._active = true and a.id = ' || $1 || ') a ';
    -- locations
    execute_statement := execute_statement || 'left join ' ||
				'(select ll.activity_id, count(distinct ll.location_id) as ct ' ||
				'from _location_lookup ll ' ||
				'where ll.activity_id = ' || $1 ||
				'group by ll.activity_id) l ' ||
				'on a.id = l.activity_id ';


RAISE NOTICE 'Execute statement: %', execute_statement;			

FOR rec IN EXECUTE 'SELECT row_to_json(j) FROM (' || execute_statement || ')j' LOOP  		
	RETURN NEXT rec;
END LOOP;
   END IF;
END;$$ LANGUAGE plpgsql;

/******************************************************************
2. update the tanaim export to address missing elements
******************************************************************/
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
    SELECT c1,c2,c3,c4,c5,c6,c7,c8,c9,c10,c11,c12,c13,c14,c15,c16,c17,c18,c19,c20,c21 FROM csv_data ORDER BY id
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

/******************************************************************
 3. create function to force update of boundary features for a
 location
   select * from pmt_update_location_boundries(45519);
 ******************************************************************/
CREATE OR REPLACE FUNCTION pmt_update_location_boundries(location_id integer) RETURNS boolean AS 
$$
DECLARE
  location_rec record;
  boundary record;
  feature record;
  ft record;
  feature_spatial_table text;
  feature_group text;
  simple_polygon_boundary text;
  simple_polygon_feature text;
  feature_statement text;
  error_msg text;
BEGIN
  IF $1 IS NOT NULL THEN
    SELECT INTO location_rec * FROM location WHERE id = $1;	
    -- Remove all existing location boundary information for this location (to be recreated by this trigger)
    EXECUTE 'DELETE FROM location_boundary WHERE location_id = ' || $1;
    RAISE NOTICE 'Refreshing boundary features for id % ...', $1; 

    -- if the location is an exact location (point), then intersect all boundaries
    IF (location_rec.boundary_id IS NULL AND location_rec.feature_id IS NULL) THEN
      -- loop through each available boundary
      FOR boundary IN SELECT * FROM boundary LOOP
        -- find the feature in the boundary, interescted by our point
        FOR feature IN EXECUTE 'SELECT * FROM ' || quote_ident(boundary._spatial_table)  || ' WHERE ST_Intersects(ST_PointFromText(''' || 
		ST_AsText(location_rec._point) || ''', 4326), _polygon)' LOOP
	  -- RAISE NOTICE 'Found intersecting boundary for %', boundary._spatial_table;
	  -- for each intersected feature, record its values in the location_boundary table
	  EXECUTE 'INSERT INTO location_boundary VALUES (' || $1 || ', ' || feature.boundary_id || ', ' || feature.id || ', ' || quote_literal(feature._name) || ')';
	  -- assign all associated taxonomy classification from intersected features to new location
	  FOR ft IN (SELECT * FROM feature_taxonomy WHERE feature_taxonomy.feature_id = feature.id AND feature_taxonomy.boundary_id = feature.boundary_id) LOOP	  
	    IF ft IS NOT NULL THEN
	    -- RAISE NOTICE 'Found feature taxonomy for feature id %', ft.feature_id;
	    -- RAISE NOTICE 'Found feature taxonomy as classification id %', ft.classification_id;
	      -- replace all previous taxonomy classification associations with new for the given taxonomy
  	      DELETE FROM location_taxonomy WHERE location_taxonomy.location_id = $1 AND classification_id IN 
		(SELECT classification_id FROM _taxonomy_classifications WHERE taxonomy_id = (SELECT taxonomy_id FROM classification WHERE classification.id = ft.classification_id));    
	      INSERT INTO location_taxonomy VALUES ($1, ft.classification_id, 'id');
	    END IF;
	  END LOOP;
        END LOOP;	
      END LOOP;
    -- if the location is polygon feature, then only intersect boundaries that are less than or equal administrative levels
    ELSE
      -- get the spatial table of the location feature
      SELECT INTO feature_spatial_table _spatial_table FROM boundary WHERE id = location_rec.boundary_id; 
      -- get the boundary group of the location feature
      SELECT INTO feature_group _group FROM boundary WHERE id = location_rec.boundary_id; 
      -- loop through each available boundary that has an administrative level equal to or less than the location feature
      FOR boundary IN SELECT * FROM boundary WHERE (_admin_level IS NULL OR _admin_level <= location_rec._admin_level)  LOOP
        IF (feature_group = 'global') OR (boundary._group = 'global') OR (feature_group = boundary._group) THEN     
        -- get the simple polygon column for the boundary
        EXECUTE 'SELECT column_name FROM information_schema.columns WHERE table_name = ''' || quote_ident(boundary._spatial_table)  || ''' AND column_name = ''_polygon_simple_med''' INTO simple_polygon_boundary;
        -- get the simple polygon column for the feature
        EXECUTE 'SELECT column_name FROM information_schema.columns WHERE table_name = ''' || quote_ident(feature_spatial_table)  || ''' AND column_name = ''_polygon_simple_med''' INTO simple_polygon_feature;
        -- boundary and feature are the same
        IF boundary._spatial_table = feature_spatial_table THEN 
          feature_statement := 'SELECT id, boundary_id, _name FROM ' || quote_ident(feature_spatial_table)  || ' WHERE id = ' || location_rec.feature_id;
          -- find the feature in the boundary, interescted by our point
          FOR feature IN EXECUTE feature_statement LOOP
	    EXECUTE 'INSERT INTO location_boundary VALUES (' || $1 || ', ' || feature.boundary_id || ', ' || feature.id || ', ' || quote_literal(feature._name) || ')';	  
          END LOOP;
        -- boundary and feature are different do an intersection
        ELSE    
          -- boundary has a simple polygon
          IF simple_polygon_boundary IS NOT NULL THEN
            RAISE NOTICE 'Boundary % has a simplified polgon', boundary._spatial_table;
            IF simple_polygon_feature IS NOT NULL THEN
              RAISE NOTICE 'Feature % has a simplified polgon', feature_spatial_table;
              feature_statement := 'SELECT b.id, b.boundary_id, b._name FROM ' || quote_ident(boundary._spatial_table)  || ' b, ' ||
	        '(SELECT _polygon_simple_med FROM ' || quote_ident(feature_spatial_table)  || ' WHERE id = ' || location_rec.feature_id || ') l ' ||
	        'WHERE ST_Intersects(b._polygon_simple_med, l._polygon_simple_med) AND (ST_Area(ST_Intersection(b._polygon_simple_med, l._polygon_simple_med))/ST_Area(l._polygon_simple_med)) > .85';
            ELSE
	      RAISE NOTICE 'Feature % does not have a simplified polgon', feature_spatial_table;
              feature_statement := 'SELECT b.id, b.boundary_id, b._name FROM ' || quote_ident(boundary._spatial_table)  || ' b, ' ||
	        '(SELECT _polygon FROM ' || quote_ident(feature_spatial_table)  || ' WHERE id = ' || location_rec.feature_id || ') l ' ||
	        'WHERE ST_Intersects(b._polygon_simple_med, l._polygon) AND (ST_Area(ST_Intersection(b._polygon_simple_med, l._polygon))/ST_Area(l._polygon)) > .85';
            END IF;	
          -- boundary does not have a simple polygon
          ELSE
	  RAISE NOTICE 'Boundary % does NOT have a simplified polgon',boundary._spatial_table;
            IF simple_polygon_feature IS NOT NULL THEN
              RAISE NOTICE 'Feature % has a simplified polgon', feature_spatial_table;
	      feature_statement := 'SELECT b.id, b.boundary_id, b._name FROM ' || quote_ident(boundary._spatial_table)  || ' b, ' ||
	        '(SELECT _polygon_simple_med FROM ' || quote_ident(feature_spatial_table)  || ' WHERE id = ' || location_rec.feature_id || ') l ' ||
	        'WHERE ST_Intersects(b._polygon, l._polygon_simple_med) AND (ST_Area(ST_Intersection(b._polygon, l._polygon_simple_med))/ST_Area(l._polygon_simple_med)) > .85';
	    ELSE	
	      RAISE NOTICE 'Feature % does not have a simplified polgon', feature_spatial_table;
	      feature_statement := 'SELECT b.id, b.boundary_id, b._name FROM ' || quote_ident(boundary._spatial_table)  || ' b, ' ||
	        '(SELECT _polygon FROM ' || quote_ident(feature_spatial_table)  || ' WHERE id = ' || location_rec.feature_id || ') l ' ||
	        'WHERE ST_Intersects(b._polygon, l._polygon) AND (ST_Area(ST_Intersection(b._polygon, l._polygon))/ST_Area(l._polygon)) > .85';
	    END IF;
          END IF;
          -- find the feature in the boundary, interescted by our point
          FOR feature IN EXECUTE feature_statement LOOP
	    -- RAISE NOTICE 'Found intersecting boundary for %', boundary._spatial_table;
	    -- for each intersected feature, record its values in the location_boundary table
	    EXECUTE 'INSERT INTO location_boundary VALUES (' || $1 || ', ' || feature.boundary_id || ', ' || feature.id || ', ' || quote_literal(feature._name) || ')';
	    -- assign all associated taxonomy classification from intersected features to new location
	    FOR ft IN (SELECT * FROM feature_taxonomy WHERE feature_taxonomy.feature_id = feature.id AND feature_taxonomy.boundary_id = feature.boundary_id) LOOP	  
	      IF ft IS NOT NULL THEN
	        -- RAISE NOTICE 'Found feature taxonomy for feature id %', ft.feature_id;
	        -- RAISE NOTICE 'Found feature taxonomy as classification id %', ft.classification_id;
	        -- replace all previous taxonomy classification associations with new for the given taxonomy
  	        DELETE FROM location_taxonomy WHERE location_taxonomy.location_id = $1 AND classification_id IN 
	    	  (SELECT classification_id FROM _taxonomy_classifications WHERE taxonomy_id = (SELECT taxonomy_id FROM classification WHERE classification.id = ft.classification_id));    
	        INSERT INTO location_taxonomy VALUES ($1, ft.classification_id, 'id');
	      END IF;
	    END LOOP;
          END LOOP;
        END IF;	
        END IF;
      END LOOP;
    END IF;  
    RETURN TRUE;
  END IF;
  RETURN FALSE;
END;$$ LANGUAGE plpgsql;

/******************************************************************
 4. update pmt_upd_boundary_features to allow global layers to intersect
 country specific layers
******************************************************************/
-- upd_boundary_features
CREATE OR REPLACE FUNCTION pmt_upd_boundary_features()
RETURNS trigger AS $pmt_upd_boundary_features$
DECLARE
  boundary record;
  feature record;
  ft record;
  feature_spatial_table text;
  feature_group text;
  simple_polygon_boundary text;
  simple_polygon_feature text;
  feature_statement text;
  error_msg text;
BEGIN
  -- Remove all existing location boundary information for this location (to be recreated by this trigger)
  EXECUTE 'DELETE FROM location_boundary WHERE location_id = ' || NEW.id;
  RAISE NOTICE 'Refreshing boundary features for id % ...', NEW.id; 

  -- if the location is an exact location (point), then intersect all boundaries
  IF (NEW.boundary_id IS NULL AND NEW.feature_id IS NULL) THEN
    -- loop through each available boundary
    FOR boundary IN SELECT * FROM boundary LOOP
      -- find the feature in the boundary, interescted by our point
      FOR feature IN EXECUTE 'SELECT * FROM ' || quote_ident(boundary._spatial_table)  || ' WHERE ST_Intersects(ST_PointFromText(''' || 
		ST_AsText(NEW._point) || ''', 4326), _polygon)' LOOP
	-- RAISE NOTICE 'Found intersecting boundary for %', boundary._spatial_table;
	-- for each intersected feature, record its values in the location_boundary table
	EXECUTE 'INSERT INTO location_boundary VALUES (' || NEW.id || ', ' || feature.boundary_id || ', ' || feature.id || ', ' || quote_literal(feature._name) || ')';
	-- assign all associated taxonomy classification from intersected features to new location
	FOR ft IN (SELECT * FROM feature_taxonomy WHERE feature_taxonomy.feature_id = feature.id AND feature_taxonomy.boundary_id = feature.boundary_id) LOOP	  
	  IF ft IS NOT NULL THEN
	  -- RAISE NOTICE 'Found feature taxonomy for feature id %', ft.feature_id;
	  -- RAISE NOTICE 'Found feature taxonomy as classification id %', ft.classification_id;
	    -- replace all previous taxonomy classification associations with new for the given taxonomy
  	    DELETE FROM location_taxonomy WHERE location_id = NEW.id AND classification_id IN 
		(SELECT classification_id FROM _taxonomy_classifications WHERE taxonomy_id = (SELECT taxonomy_id FROM classification WHERE classification.id = ft.classification_id));    
	    INSERT INTO location_taxonomy VALUES (NEW.id, ft.classification_id, 'id');
	  END IF;
	END LOOP;
      END LOOP;	
    END LOOP;
  -- if the location is polygon feature, then only intersect boundaries that are less than or equal administrative levels
  ELSE
    -- get the spatial table of the location feature
    SELECT INTO feature_spatial_table _spatial_table FROM boundary WHERE id = NEW.boundary_id; 
    -- get the boundary group of the location feature
    SELECT INTO feature_group _group FROM boundary WHERE id = NEW.boundary_id; 
    -- loop through each available boundary that has an administrative level equal to or less than the location feature
    FOR boundary IN SELECT * FROM boundary WHERE (_admin_level IS NULL OR _admin_level <= location_rec._admin_level)  LOOP
      IF (feature_group = 'global') OR (boundary._group = 'global') OR (feature_group = boundary._group) THEN     
      -- get the simple polygon column for the boundary
      EXECUTE 'SELECT column_name FROM information_schema.columns WHERE table_name = ''' || quote_ident(boundary._spatial_table)  || ''' AND column_name = ''_polygon_simple_med''' INTO simple_polygon_boundary;
      -- get the simple polygon column for the feature
      EXECUTE 'SELECT column_name FROM information_schema.columns WHERE table_name = ''' || quote_ident(feature_spatial_table)  || ''' AND column_name = ''_polygon_simple_med''' INTO simple_polygon_feature;
      -- boundary and feature are the same
      IF boundary._spatial_table = feature_spatial_table THEN 
        feature_statement := 'SELECT id, boundary_id, _name FROM ' || quote_ident(feature_spatial_table)  || ' WHERE id = ' || NEW.feature_id;
        -- find the feature in the boundary, interescted by our point
        FOR feature IN EXECUTE feature_statement LOOP
	  EXECUTE 'INSERT INTO location_boundary VALUES (' || NEW.id || ', ' || feature.boundary_id || ', ' || feature.id || ', ' || quote_literal(feature._name) || ')';	  
        END LOOP;
      -- boundary and feature are different do an intersection
      ELSE    
        -- boundary has a simple polygon
        IF simple_polygon_boundary IS NOT NULL THEN
          RAISE NOTICE 'Boundary % has a simplified polgon', boundary._spatial_table;
          IF simple_polygon_feature IS NOT NULL THEN
            RAISE NOTICE 'Feature % has a simplified polgon', feature_spatial_table;
            feature_statement := 'SELECT b.id, b.boundary_id, b._name FROM ' || quote_ident(boundary._spatial_table)  || ' b, ' ||
	      '(SELECT _polygon_simple_med FROM ' || quote_ident(feature_spatial_table)  || ' WHERE id = ' || NEW.feature_id || ') l ' ||
	      'WHERE ST_Intersects(b._polygon_simple_med, l._polygon_simple_med) AND (ST_Area(ST_Intersection(b._polygon_simple_med, l._polygon_simple_med))/ST_Area(l._polygon_simple_med)) > .85';
          ELSE
	    RAISE NOTICE 'Feature % does not have a simplified polgon', feature_spatial_table;
            feature_statement := 'SELECT b.id, b.boundary_id, b._name FROM ' || quote_ident(boundary._spatial_table)  || ' b, ' ||
	      '(SELECT _polygon FROM ' || quote_ident(feature_spatial_table)  || ' WHERE id = ' || NEW.feature_id || ') l ' ||
	      'WHERE ST_Intersects(b._polygon_simple_med, l._polygon) AND (ST_Area(ST_Intersection(b._polygon_simple_med, l._polygon))/ST_Area(l._polygon)) > .85';
          END IF;	
        -- boundary does not have a simple polygon
        ELSE
	RAISE NOTICE 'Boundary % does NOT have a simplified polgon',boundary._spatial_table;
          IF simple_polygon_feature IS NOT NULL THEN
            RAISE NOTICE 'Feature % has a simplified polgon', feature_spatial_table;
	    feature_statement := 'SELECT b.id, b.boundary_id, b._name FROM ' || quote_ident(boundary._spatial_table)  || ' b, ' ||
	      '(SELECT _polygon_simple_med FROM ' || quote_ident(feature_spatial_table)  || ' WHERE id = ' || NEW.feature_id || ') l ' ||
	      'WHERE ST_Intersects(b._polygon, l._polygon_simple_med) AND (ST_Area(ST_Intersection(b._polygon, l._polygon_simple_med))/ST_Area(l._polygon_simple_med)) > .85';
	  ELSE	
	    RAISE NOTICE 'Feature % does not have a simplified polgon', feature_spatial_table;
	    feature_statement := 'SELECT b.id, b.boundary_id, b._name FROM ' || quote_ident(boundary._spatial_table)  || ' b, ' ||
	      '(SELECT _polygon FROM ' || quote_ident(feature_spatial_table)  || ' WHERE id = ' || NEW.feature_id || ') l ' ||
	      'WHERE ST_Intersects(b._polygon, l._polygon) AND (ST_Area(ST_Intersection(b._polygon, l._polygon))/ST_Area(l._polygon)) > .85';
	  END IF;
        END IF;
        -- find the feature in the boundary, interescted by our point
        FOR feature IN EXECUTE feature_statement LOOP
	  -- RAISE NOTICE 'Found intersecting boundary for %', boundary._spatial_table;
	  -- for each intersected feature, record its values in the location_boundary table
	  EXECUTE 'INSERT INTO location_boundary VALUES (' || NEW.id || ', ' || feature.boundary_id || ', ' || feature.id || ', ' || quote_literal(feature._name) || ')';
	  -- assign all associated taxonomy classification from intersected features to new location
	  FOR ft IN (SELECT * FROM feature_taxonomy WHERE feature_taxonomy.feature_id = feature.id AND feature_taxonomy.boundary_id = feature.boundary_id) LOOP	  
	    IF ft IS NOT NULL THEN
	      -- RAISE NOTICE 'Found feature taxonomy for feature id %', ft.feature_id;
	      -- RAISE NOTICE 'Found feature taxonomy as classification id %', ft.classification_id;
	      -- replace all previous taxonomy classification associations with new for the given taxonomy
  	      DELETE FROM location_taxonomy WHERE location_id = NEW.id AND classification_id IN 
		(SELECT classification_id FROM _taxonomy_classifications WHERE taxonomy_id = (SELECT taxonomy_id FROM classification WHERE classification.id = ft.classification_id));    
	      INSERT INTO location_taxonomy VALUES (NEW.id, ft.classification_id, 'id');
	    END IF;
	  END LOOP;
        END LOOP;
      END IF;
      END IF;	
    END LOOP;
  END IF;

RETURN NEW;

EXCEPTION WHEN others THEN 
  GET STACKED DIAGNOSTICS error_msg = MESSAGE_TEXT;  
    RAISE NOTICE 'Internal Error - Contact your DBA with the following error message: %', ' Location id (' || NEW.id || ') - ' || error_msg;
END;
$pmt_upd_boundary_features$ LANGUAGE plpgsql; 
DROP TRIGGER IF EXISTS pmt_upd_boundary_features ON location;
CREATE TRIGGER pmt_upd_boundary_features AFTER INSERT OR UPDATE ON location
    FOR EACH ROW EXECUTE PROCEDURE pmt_upd_boundary_features();


-- update permissions
GRANT USAGE ON SCHEMA public TO pmt_read;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO pmt_read;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO pmt_read;
GRANT USAGE ON SCHEMA public TO pmt_write;
GRANT SELECT,INSERT ON ALL TABLES IN SCHEMA public TO pmt_write;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO pmt_write;