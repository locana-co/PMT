/******************************************************************
Change Script 2.0.8.1 - consolidated.
1. process_xml 
2. pmt_sector_compare
3. pmt_edit_activity_taxonomy
******************************************************************/
INSERT INTO config(version, iteration, changeset) VALUES (2.0, 8, 1);
-- select * from config order by changeset desc;

DROP MATERIALIZED VIEW IF EXISTS location_lookup CASCADE;
DROP MATERIALIZED VIEW IF EXISTS organization_lookup CASCADE;
DROP MATERIALIZED VIEW IF EXISTS taxonomy_lookup CASCADE;
DROP VIEW active_project_activities;
ALTER TABLE "participation" DROP IF EXISTS reporting_org;

ALTER TABLE "activity" ADD iati_identifier character varying(50);

/******************************************************************
  process_xml
******************************************************************/
CREATE OR REPLACE FUNCTION process_xml()
RETURNS TRIGGER AS $process_xml$
    DECLARE
	t_id integer;
	p_id integer;			-- project_id
	a_id integer;			-- activity_id
	financial_id integer;
	o_id integer;			-- organization_id
	class_id integer;		-- classification_id
	participation_id integer;
	l_id integer;	
	recordcount integer;
	codelist record;
	activity record;
	transact record;
	contact record;
	loc record;
	budget record;
	i text;
	record_id integer;
	idx integer;
	lat numeric;
	long numeric;
	error text;
	has_valid_sector boolean;
	sector_text text array;
BEGIN	
        RAISE NOTICE 'Function process_xml() fired by INSERT or UPDATE on table xml.';
	-- Extract from the xml document the type and name of the document
	NEW.type := unnest(xpath('name()',NEW.xml))::character varying;
	NEW.taxonomy := regexp_replace((xpath('//'||NEW.type||'/@name',NEW.xml))[1]::text, '(\w)([A-Z])', '\1 \2' ); 	
	NEW.taxonomy := regexp_replace(NEW.taxonomy, '(\w)([A-Z])', '\1 \2' ); 	
		
	RAISE NOTICE 'Processing a IATI document of type:  %', NEW.type;

	-- Determine what to do with the document based on its type
	CASE UPPER(NEW.type) 
		WHEN 'CODELIST' THEN
		-- This is an IATI codelist xml document
		-- We'll process the document and update the database taxonomy with its information
			-- Does this codelist exist in the database?
			SELECT INTO recordcount COUNT(*)::integer FROM taxonomy WHERE iati_codelist = NEW.taxonomy;			
			--Add the codelist	
			IF( recordcount = 0) THEN
				-- if this is the Sector codelist, collect categories first then the sectors linking the two together
				IF UPPER(NEW.taxonomy) = 'SECTOR' THEN	
					-- Add Sector Category record
					  EXECUTE 'INSERT INTO taxonomy (name, description, iati_codelist, is_category, created_by, updated_by) VALUES( ' 
					  || quote_literal(NEW.taxonomy || ' Category') || ', ' || quote_literal('IATI Standards. The IATI codelists ensure activity and organisation information is comparable between different publishers.') || ', ' 
					  || quote_literal(NEW.taxonomy) || ',TRUE, ' || quote_literal(E'IATI XML Import') || ', ' || quote_literal(E'IATI XML Import') || ') RETURNING taxonomy_id;' INTO t_id;
					  RAISE NOTICE ' + Adding the % to the database:', NEW.type || ' for ' || NEW.taxonomy || ' Category'; 
					  RAISE NOTICE ' + Taxonomy id: %', t_id; 	
					  -- Iterate over all the values in the xml file
					  FOR codelist IN EXECUTE 'SELECT (xpath(''/' || replace(NEW.taxonomy, ' ', '') || '/category/text()'', node.xml))[1]::text AS code, ' 
					   || '(xpath(''/' || replace(NEW.taxonomy, ' ', '') || '/category-name/text()'', node.xml))[1]::text AS name, '
					   || '(xpath(''/' || replace(NEW.taxonomy, ' ', '') || '/category-description/text()'', node.xml))[1]::text AS description '
					   || 'FROM(SELECT unnest(xpath(''/' || NEW.type || '/' || replace(NEW.taxonomy, ' ', '') || ''', $1.xml))::xml AS xml) AS node;' USING NEW LOOP					
						-- Does this classification exist in the database?
						SELECT INTO recordcount COUNT(*)::integer FROM classification WHERE taxonomy_id = t_id AND iati_name = codelist.name;
						IF( recordcount = 0) THEN
						  -- Add classification record
						  EXECUTE 'INSERT INTO classification (taxonomy_id, code, name, description, iati_code, iati_name, iati_description, created_by, created_date, updated_by, updated_date) VALUES( ' 
						  || t_id || ', ' ||quote_literal(codelist.code)|| ', ' || quote_literal(codelist.name)|| ', ' || coalesce(quote_literal(codelist.description),'NULL') || ', ' ||quote_literal(codelist.code)|| ', ' 
						  || quote_literal(codelist.name)|| ', ' || coalesce(quote_literal(codelist.description),'NULL') || ', '
						  || quote_literal(E'IATI XML Import') || ', ' ||quote_literal(current_date) || ', ' || quote_literal(E'IATI XML Import') || ', ' || quote_literal(current_date) || ');';						
						  RAISE NOTICE '    - Adding taxonomy classification:  %', codelist.name;			
						END IF;
					  END LOOP;
				        
					-- Add Sector records
					EXECUTE 'INSERT INTO taxonomy (name, description, iati_codelist, category_id, created_by, updated_by) VALUES( ' 
					|| quote_literal(NEW.taxonomy) || ', ' || quote_literal('IATI Standards. The IATI codelists ensure activity and organisation information is comparable between different publishers.') || ', ' 
					|| quote_literal(NEW.taxonomy) || ', ' || t_id || ', ' || quote_literal(E'IATI XML Import')  || ', ' || quote_literal(E'IATI XML Import') || ') RETURNING taxonomy_id;' INTO t_id;
					RAISE NOTICE ' + Adding the % to the database:', NEW.type || ' for ' || NEW.taxonomy; 
					RAISE NOTICE ' + Taxonomy id: %', t_id; 	
					-- Iterate over all the values in the xml file
					FOR codelist IN EXECUTE 'SELECT (xpath(''/' || replace(NEW.taxonomy, ' ', '') || '/code/text()'', node.xml))[1]::text AS code, ' 
					   || '(xpath(''/' || replace(NEW.taxonomy, ' ', '') || '/name/text()'', node.xml))[1]::text AS name, '
					   || '(xpath(''/' || replace(NEW.taxonomy, ' ', '') || '/description/text()'', node.xml))[1]::text AS description '
					   || 'FROM(SELECT unnest(xpath(''/' || NEW.type || '/' || replace(NEW.taxonomy, ' ', '') || ''', $1.xml))::xml AS xml) AS node;' USING NEW LOOP
					         -- Does this value exist in our taxonomy? 
						 SELECT INTO class_id classification_id::integer FROM taxonomy_classifications WHERE lower(iati_code) = lower(substring(trim(codelist.code) from 1 for 3)) AND iati_codelist = 'Sector';
						   IF class_id IS NOT NULL THEN
						      -- Add classification record
							EXECUTE 'INSERT INTO classification (taxonomy_id, code, name, description, iati_code, iati_name, iati_description, category_id, created_by, created_date, updated_by, updated_date) VALUES( ' 
							|| t_id || ', ' ||quote_literal(codelist.code)|| ', ' || quote_literal(codelist.name)|| ', ' || coalesce(quote_literal(codelist.description),'NULL') || ', ' ||quote_literal(codelist.code)|| ', '
							|| quote_literal(codelist.name)|| ', ' || coalesce(quote_literal(codelist.description),'NULL') || ', ' || class_id || ', '
							|| quote_literal(E'IATI XML Import') || ', ' ||quote_literal(current_date) || ', ' || quote_literal(E'IATI XML Import') || ', ' || quote_literal(current_date) || ');';							
							RAISE NOTICE '    - Adding taxonomy classification:  %', codelist.name;	
						   ELSE
						      -- Add classification record
							EXECUTE 'INSERT INTO classification (taxonomy_id, code, name, description, iati_code, iati_name, iati_description, created_by, created_date, updated_by, updated_date) VALUES( ' 
							|| t_id || ', ' ||quote_literal(codelist.code)|| ', ' || quote_literal(codelist.name)|| ', ' || coalesce(quote_literal(codelist.description),'NULL') || ', ' ||quote_literal(codelist.code)|| ', '
							|| quote_literal(codelist.name)|| ', ' || coalesce(quote_literal(codelist.description),'NULL') || ', '
							|| quote_literal(E'IATI XML Import') || ', ' ||quote_literal(current_date) || ', ' || quote_literal(E'IATI XML Import') || ', ' || quote_literal(current_date) || ');';							
							RAISE NOTICE '    - Adding taxonomy classification:  %', codelist.name;
						   END IF;															
					END LOOP;				
				-- if this is any other codelist
				ELSE
					-- Add taxonomy record				
					EXECUTE 'INSERT INTO taxonomy (name, description, iati_codelist, created_by, created_date, updated_by, updated_date) VALUES( ' 
					|| quote_literal(NEW.taxonomy) || ', ' || quote_literal('IATI Standards. The IATI codelists ensure activity and organisation information is comparable between different publishers.') || ', ' || quote_literal(NEW.taxonomy) || ', ' || quote_literal(E'IATI XML Import') || ', ' 
					|| quote_literal(current_date) || ', ' || quote_literal(E'IATI XML Import') || ', ' || quote_literal(current_date) || ') RETURNING taxonomy_id;' INTO t_id;
					RAISE NOTICE ' + Adding the % to the database:', NEW.type || ' for ' || NEW.taxonomy; 
					RAISE NOTICE ' + Taxonomy id: %', t_id; 	
					-- Iterate over all the values in the xml file
					FOR codelist IN EXECUTE 'SELECT (xpath(''/' || replace(NEW.taxonomy, ' ', '') || '/code/text()'', node.xml))[1]::text AS code, ' 
					   || '(xpath(''/' || replace(NEW.taxonomy, ' ', '') || '/name/text()'', node.xml))[1]::text AS name, '
					   || '(xpath(''/' || replace(NEW.taxonomy, ' ', '') || '/description/text()'', node.xml))[1]::text AS description '
					   || 'FROM(SELECT unnest(xpath(''/' || NEW.type || '/' || replace(NEW.taxonomy, ' ', '') || ''', $1.xml))::xml AS xml) AS node;' USING NEW LOOP					
						-- Add classification record
						EXECUTE 'INSERT INTO classification (taxonomy_id, code, name, description, iati_code, iati_name, iati_description, created_by, created_date, updated_by, updated_date) VALUES( ' 
						|| t_id || ', ' ||quote_literal(codelist.code)|| ', ' || quote_literal(codelist.name)|| ', ' || coalesce(quote_literal(codelist.description),'NULL') || ', ' ||quote_literal(codelist.code)|| ', '
						|| quote_literal(codelist.name)|| ', ' || coalesce(quote_literal(codelist.description),'NULL') || ', '
						|| quote_literal(E'IATI XML Import') || ', ' ||quote_literal(current_date) || ', ' || quote_literal(E'IATI XML Import') || ', ' || quote_literal(current_date) || ');';							
						RAISE NOTICE '    - Adding taxonomy classification:  %', codelist.name;			
					END LOOP;	
				END IF;						
			-- Codelist exists
			ELSE			
			RAISE NOTICE ' + The % already exists the database and will not be processed agian from this function.', NEW.type || ' for ' || NEW.taxonomy; 
			-- once the iati code lists are entered they should be managed manually by the dba. This keeps the logic simple.
			-- In future releases we may add an updating process and support in the data model to track the multiple versions 
			-- of codelists. For now this feature is only intended to help implementers of PMT get the latest IATI codelists 
			-- loaded into their database quickly and easily without any understanding of the data model.
			error := 'The ' || NEW.type || ' for ' || NEW.taxonomy || ' already exists the database and will not be processed agian from this function.'; 
			NEW.xml := null;
			NEW.error := error;
			END IF;						
		WHEN 'IATI-ACTIVITIES' THEN 
		-- This is an IATI activity xml document
		IF NEW.data_group IS NULL THEN
		  error := 'The data_group field is required for the import of an IATI-Activities document. The data_group field expects a new or existing classification name from the Data Group taxonomy. All data imported will be group in the provided data group.';
		  NEW.xml := null;
		  NEW.error := error;
		  RAISE NOTICE '-- ERROR: %', error;
		ELSE
			-- Does this value exist in our taxonomy?
			SELECT INTO record_id classification_id::integer FROM taxonomy_classifications WHERE lower(classification) = trim(lower(NEW.data_group)) AND taxonomy = 'Data Group';
			IF record_id IS NULL THEN
			   -- add the new classification to the Data Group taxonomy
			   EXECUTE 'INSERT INTO classification(taxonomy_id, name, created_by, created_date, updated_by, updated_date) VALUES ((SELECT taxonomy_id FROM taxonomy WHERE name = ''Data Group''), ' || quote_literal(trim(NEW.data_group))
				   ||  ', ' || quote_literal(E'IATI XML Import') || ', ' ||quote_literal(current_date) || ', ' || quote_literal(E'IATI XML Import') || ', ' || quote_literal(current_date) || ') RETURNING classification_id;' INTO class_id;
			ELSE
			   class_id := record_id;
			END IF;
				
			-- Create a project record to connect all the activities in the incoming file
			EXECUTE 'INSERT INTO project (title, created_by, created_date, updated_by, updated_date) VALUES( ' 
			|| quote_literal(E'IATI Activities XML Import') || ', ' || quote_literal(E'IATI XML Import') || ', ' 
			|| quote_literal(current_date) || ', ' || quote_literal(E'IATI XML Import') || ', ' || quote_literal(current_date) || ') RETURNING project_id;' INTO p_id;
			RAISE NOTICE ' + Project id % was added to the database.', p_id; 	
			NEW.project_id = p_id;

			-- Assign the project to the requested Data Group taxonomy
			EXECUTE 'INSERT INTO project_taxonomy(project_id, classification_id, field) VALUES ( '
			|| p_id  || ', ' || class_id || ', ''project_id'');';
						
			-- iterate over all the activities in the the document
			FOR activity IN EXECUTE 'SELECT (xpath(''/iati-activity/iati-identifier/text()'', node.xml))[1]::text AS "iati-identifier" ' 
			    || ',(xpath(''/iati-activity/title/text()'', node.xml))[1]::text AS "title" '		    
			    || ',(xpath(''/iati-activity/participating-org/text()'', node.xml))::text[] AS "participating-org",(xpath(''/iati-activity/participating-org/@role'', node.xml))::text[] AS "participating-org_role",(xpath(''/iati-activity/participating-org/@type'', node.xml))::text[] AS "participating-org_type"  '
			    || ',(xpath(''/iati-activity/recipient-country/text()'', node.xml))::text[] AS "recipient-country",(xpath(''/iati-activity/recipient-country/@code'', node.xml))::text[] AS "recipient-country_code" ,(xpath(''/iati-activity/recipient-country/@percentage'', node.xml))::text[] AS "recipient-country_percentage"'
			    || ',(xpath(''/iati-activity/description/text()'', node.xml))[1]::text AS "description" '
			    || ',(xpath(''/iati-activity/activity-date/@iso-date'', node.xml))::text[] AS "activity-date", (xpath(''/iati-activity/activity-date/@type'', node.xml))::text[] AS "activity-date_type"  '
			    || ',(xpath(''/iati-activity/activity-status/text()'', node.xml))[1]::text AS "activity-status",(xpath(''/iati-activity/activity-status/@code'', node.xml))[1]::text AS "activity-status_code" '
			    || ',(xpath(''/iati-activity/sector/text()'', node.xml))::text[] AS "sector", (xpath(''/iati-activity/sector/@code'', node.xml))::text[] AS "sector_code"  '
			    || ',(xpath(''/iati-activity/transaction'', node.xml))::xml[] AS "transaction"'
			    || ',(xpath(''/iati-activity/contact-info'', node.xml))::xml[] AS "contact-info"'
			    || ',(xpath(''/iati-activity/location'', node.xml))::xml[] AS "location"'
			    || ',(xpath(''/iati-activity/budget'', node.xml))::xml[] AS "budget"'
			    || 'FROM(SELECT unnest(xpath(''/' || NEW.type || '/iati-activity'', $1.xml))::xml AS xml) AS node;'  USING NEW LOOP

			    -- the activity must at least have a title
			    IF activity."title" IS NOT NULL or activity."title" <> '' THEN
			            -- Initialize the valid_sector flag to false
			            has_valid_sector := false;			            
				    -- Create a activity record and connect to the created project
				    EXECUTE 'INSERT INTO activity (project_id, title, description, iati_identifier, created_by, created_date, updated_by, updated_date) VALUES( ' 
				    || p_id || ', ' || coalesce(quote_literal(trim(activity."title")),'NULL') || ', ' || coalesce(quote_literal(trim(activity."description")),'NULL') || ', ' 
				    || coalesce(quote_literal(activity."iati-identifier"),'NULL') || ', ' 
				    || quote_literal(E'IATI XML Import') || ', ' || quote_literal(current_date) || ', ' || quote_literal(E'IATI XML Import') || ', ' || quote_literal(current_date) 
				    || ') RETURNING activity_id;' INTO a_id;
				    
				    
--				    RAISE NOTICE ' +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++';
				    RAISE NOTICE ' + Activity id % was added to the database.', a_id; 				    
-- 				    RAISE NOTICE ' + Adding activity:  %', activity."iati-identifier";
-- 				    RAISE NOTICE '   - Title:  %', activity."title";
-- 				    RAISE NOTICE '   - Description:  %', activity."description";
 				    
				    idx := 1;
				    FOREACH i IN ARRAY activity."participating-org" LOOP
					-- Does this org exist in the database?
					SELECT INTO record_id organization.organization_id::integer FROM organization WHERE lower(name) = lower(trim(i));
					IF record_id IS NOT NULL THEN
					    -- Create a participation record
					    EXECUTE 'INSERT INTO participation(project_id, activity_id, organization_id, created_by, created_date, updated_by, updated_date) VALUES( ' 
					    || p_id || ', ' || a_id || ', ' || record_id || ', ' 
					    || quote_literal(E'IATI XML Import') || ', ' || quote_literal(current_date) || ', ' || quote_literal(E'IATI XML Import') || ', ' || quote_literal(current_date) 
					    || ') RETURNING participation_id;' INTO participation_id;				   
					ELSE
					    -- Create a organization record
					    EXECUTE 'INSERT INTO organization(name, created_by, created_date, updated_by, updated_date) VALUES( ' 
					    || coalesce(quote_literal(trim(i)),'NULL') || ', ' 
					    || quote_literal(E'IATI XML Import') || ', ' || quote_literal(current_date) || ', ' || quote_literal(E'IATI XML Import') || ', ' || quote_literal(current_date) 
					    || ') RETURNING organization_id;' INTO o_id;
					    -- Create a participation record
					    EXECUTE 'INSERT INTO participation(project_id, activity_id, organization_id, created_by, created_date, updated_by, updated_date) VALUES( ' 
					    || p_id || ', ' || a_id || ', ' || o_id || ', ' 
					    || quote_literal(E'IATI XML Import') || ', ' || quote_literal(current_date) || ', ' || quote_literal(E'IATI XML Import') || ', ' || quote_literal(current_date) 
					    || ') RETURNING participation_id;' INTO participation_id;
					END IF;
					-- Does this value exist in our taxonomy?
					SELECT INTO record_id classification_id::integer FROM taxonomy_classifications WHERE lower(iati_code) = lower(trim(activity."participating-org_role"[idx])) AND iati_codelist = 'Organisation Role';
					IF record_id IS NOT NULL THEN
					   -- add the taxonomy to the participation record
					   EXECUTE 'INSERT INTO participation_taxonomy(participation_id, classification_id, field) VALUES( ' || participation_id || ', ' || record_id || ', ''participation_id'');';
					END IF;
					-- Does this value exist in our taxonomy?
					SELECT INTO record_id classification_id::integer FROM taxonomy_classifications WHERE lower(iati_code) = lower(trim(activity."participating-org_type"[idx])) AND iati_codelist = 'Organisation Type';
					IF record_id IS NOT NULL THEN
					   -- Does the organization have this taxonomy assigned?
					   SELECT INTO record_id organization_taxonomy.organization_id::integer FROM organization_taxonomy WHERE organization_taxonomy.organization_id = o_id AND organization_taxonomy.classification_id = record_id;
					   IF record_id IS NULL THEN
					      -- add the taxonomy to the organization record
					      EXECUTE 'INSERT INTO organization_taxonomy(organization_id, classification_id, field) VALUES( ' || o_id || ', ' || record_id || ', ''organization_id'');';
					   END IF;
					END IF;				  
 					RAISE NOTICE '   - Participating org:  %', i;
-- 					RAISE NOTICE '      - Role:  %', activity."participating-org_role"[idx];
-- 					RAISE NOTICE '      - Type:  %', activity."participating-org_type"[idx];
					idx := idx + 1;
				    END LOOP;	
				    idx := 1;
				    FOREACH i IN ARRAY activity."recipient-country" LOOP
					IF activity."recipient-country_code"[idx] IS NOT NULL THEN
					   -- Does this value exist in our taxonomy?
					   SELECT INTO record_id classification_id::integer FROM taxonomy_classifications WHERE lower(iati_code) = lower(trim(activity."recipient-country_code"[idx])) AND iati_codelist = 'Country';
					   IF record_id IS NOT NULL THEN
					      -- add the taxonomy to the activity record
					      EXECUTE 'INSERT INTO activity_taxonomy(activity_id, classification_id, field) VALUES( ' || a_id || ', ' || record_id || ', ''activity_id'');';
					   END IF;	
					END IF;
 					RAISE NOTICE '   - Recipient country:  %', i;
-- 					RAISE NOTICE '      - Code:  %', activity."recipient-country_code"[idx];					
					idx := idx + 1;
				    END LOOP;			    		   
				    idx := 1;
				    FOREACH i IN ARRAY activity."activity-date" LOOP
				       IF i <> ''  AND pmt_isdate(trim(i)) THEN
					  CASE 
					    WHEN lower(trim(activity."activity-date_type"[idx])) = 'start-planned' OR lower(trim(activity."activity-date_type"[idx])) = 'start-actual' THEN				    
					       EXECUTE 'UPDATE activity SET start_date=' || coalesce(quote_nullable(trim(i))) || ' WHERE activity_id =' || a_id || ';'; 
					    WHEN lower(trim(activity."activity-date_type"[idx])) = 'end-planned' OR lower(trim(activity."activity-date_type"[idx])) = 'end-actual' THEN
					       EXECUTE 'UPDATE activity SET end_date=' || coalesce(quote_nullable(trim(i))) || ' WHERE activity_id =' || a_id || ';'; 
					    ELSE
					       EXECUTE 'UPDATE activity SET start_date=' || coalesce(quote_nullable(trim(i))) || ' WHERE activity_id =' || a_id || ';'; 
					  END CASE;
				       END IF;
							
 					RAISE NOTICE '   - Activity date:  %', i;				
-- 					RAISE NOTICE '      - Type:  %', activity."activity-date_type"[idx];    
					idx := idx + 1;
				    END LOOP;
				    IF 	activity."activity-status_code" IS NOT NULL THEN
					-- Does this value exist in our taxonomy?
					SELECT INTO record_id classification_id::integer FROM taxonomy_classifications WHERE lower(iati_code) = lower(trim(activity."activity-status_code")) AND iati_codelist = 'Activity Staus';
					IF record_id IS NOT NULL THEN
					   -- add the taxonomy to the activity record
					   EXECUTE 'INSERT INTO activity_taxonomy(activity_id, classification_id, field) VALUES( ' || a_id || ', ' || record_id || ', ''activity_id'');';
					END IF;	
				    END IF;
 				    RAISE NOTICE '   - Activity status:  %', activity."activity-status";
-- 				    RAISE NOTICE '      - Code:  %', activity."activity-status_code";
				    
				    idx := 1;
				    FOREACH i IN ARRAY activity."sector_code" LOOP
					IF activity."sector_code"[idx] IS NOT NULL THEN					   
					   -- Does this value exist in our taxonomy?
					   SELECT INTO class_id classification_id::integer FROM taxonomy_classifications WHERE lower(iati_code) = lower(trim(activity."sector_code"[idx])) AND iati_codelist = 'Sector';
					   IF class_id IS NOT NULL THEN
					     IF has_valid_sector THEN
					       -- This activity has more than one valid sector, remove all Sectors and assign it the multi-sector Sector
					       EXECUTE 'DELETE FROM activity_taxonomy WHERE activity_id = ' || a_id || ' AND classification_id IN (SELECT classification_id FROM taxonomy_classifications WHERE iati_codelist = ''Sector'');';  
					       EXECUTE 'INSERT INTO activity_taxonomy(activity_id, classification_id, field) VALUES( ' || a_id || ', ' || (SELECT classification_id FROM taxonomy_classifications WHERE iati_codelist = 'Sector' AND iati_code = '43010' LIMIT 1) || ', ''activity_id'');';
					       EXECUTE 'INSERT INTO activity_taxonomy(activity_id, classification_id, field) VALUES( ' || a_id || ', ' || (SELECT classification_id FROM taxonomy_classifications WHERE iati_codelist = 'Sector' AND iati_code = '430' LIMIT 1) || ', ''activity_id'');';
					       RAISE NOTICE '       - Multi-Sector assignement:  %', a_id;
					     ELSE
					      -- This activity has a valid sector, set the flag for the first valid sector found
					      has_valid_sector := true;
					      -- does this activity already have this sector assigned?
					      SELECT INTO record_id activity_id::integer FROM activity_taxonomy WHERE activity_id = a_id AND classification_id = class_id;
					      IF record_id IS NULL THEN
						 -- add the taxonomy to the activity record
						 EXECUTE 'INSERT INTO activity_taxonomy(activity_id, classification_id, field) VALUES( ' || a_id || ', ' || class_id || ', ''activity_id'');';
					      END IF;
					      -- Does this value exist in our taxonomy? 
					      SELECT INTO class_id classification_id::integer FROM taxonomy_classifications WHERE lower(iati_code) = lower(substring(trim(activity."sector_code"[idx]) from 1 for 3)) AND iati_codelist = 'Sector';
					      IF class_id IS NOT NULL THEN
					        -- does this activity already have this sector assigned?
					        SELECT INTO record_id activity_id::integer FROM activity_taxonomy WHERE activity_id = a_id AND classification_id = class_id;
					        IF record_id IS NULL THEN
						   -- add the taxonomy to the activity record
						   EXECUTE 'INSERT INTO activity_taxonomy(activity_id, classification_id, field) VALUES( ' || a_id || ', ' || class_id || ', ''activity_id'');';
					        END IF;
					      END IF;
					    END IF;
					   END IF;					   
					END IF;				
 					RAISE NOTICE '   - Sector:  %', i;
-- 					RAISE NOTICE '      - Code:  %', activity."sector_code"[idx];
-- 					RAISE NOTICE '      - Category: %', lower(substring(activity."sector_code"[idx] from 1 for 3));
					idx := idx + 1;
				    END LOOP;	
				    -- If there was no valid sector assign, assign the sector Sectors not Specified	 				    
				    IF NOT has_valid_sector THEN
				      EXECUTE 'INSERT INTO activity_taxonomy(activity_id, classification_id, field) VALUES( ' || a_id || ', ' || (SELECT classification_id FROM taxonomy_classifications WHERE iati_codelist = 'Sector' AND iati_code = '99810' LIMIT 1) || ', ''activity_id'');';
				      EXECUTE 'INSERT INTO activity_taxonomy(activity_id, classification_id, field) VALUES( ' || a_id || ', ' || (SELECT classification_id FROM taxonomy_classifications WHERE iati_codelist = 'Sector' AND iati_code = '998' LIMIT 1) || ', ''activity_id'');';
 				      RAISE NOTICE '       - Unassinged Sector:  %', a_id;
				    END IF;
				    -- Collect all the Sector text and store in content field
				    sector_text := null;
				    FOREACH i IN ARRAY activity."sector" LOOP
				      sector_text :=  array_append(sector_text, i );
				    END LOOP;	
				    EXECUTE 'UPDATE activity SET content = ' || coalesce(quote_literal(array_to_string(sector_text, ',')),'NULL') || ' WHERE activity_id = ' || a_id || ';'; 			    
				    RAISE NOTICE '       - Loading conent:  %', a_id;
				    FOREACH i IN ARRAY activity."transaction" LOOP
					FOR transact IN EXECUTE 'SELECT (xpath(''/transaction/transaction-type/text()'', '''|| i ||'''))[1]::text AS "transaction-type" ' 
					  || ',(xpath(''/transaction/provider-org/text()'', '''|| i ||'''))[1]::text AS "provider-org"'
					  || ',(xpath(''/transaction/value/text()'', '''|| i ||'''))[1]::text AS "value"'
					  || ',(xpath(''/transaction/value/@currency'', '''|| i ||'''))[1]::text AS "currency"'
					  || ',(xpath(''/transaction/value/@value-date'', '''|| i ||'''))[1]::text AS "value-date"'
					  || ',(xpath(''/transaction/transaction-date/@iso-date'', '''|| i ||'''))[1]::text AS "transaction-date"'
					  || ';' LOOP
					  -- Must have a valid value to write
					  IF transact."value" IS NOT NULL AND pmt_isnumeric(transact."value") THEN	
					     -- if there is a transaction-date element use it to populate date values
					     IF transact."transaction-date" IS NOT NULL AND transact."transaction-date" <> '' THEN
						-- Create a financial record 
						EXECUTE 'INSERT INTO financial (project_id, activity_id, amount, start_date, created_by, created_date, updated_by, updated_date) VALUES( ' 
						|| p_id || ', ' || a_id || ', ' || ROUND(CAST(transact."value" as numeric), 2) || ', ' || coalesce(quote_literal(transact."transaction-date"),'NULL') || ', ' 
						|| quote_literal(E'IATI XML Import') || ', ' || quote_literal(current_date) || ', ' || quote_literal(E'IATI XML Import') || ', ' || quote_literal(current_date) 
						|| ') RETURNING financial_id;' INTO financial_id;
					     -- if there isnt a transaction-date element use value-date attribute from the value element to populate date values	
					     ELSE
						-- Create a financial record
						EXECUTE 'INSERT INTO financial (project_id, activity_id, amount, start_date, created_by, created_date, updated_by, updated_date) VALUES( ' 
						|| p_id || ', ' || a_id || ', ' || ROUND(CAST(transact."value" as numeric), 2) || ', ' || coalesce(quote_literal(transact."value-date"),'NULL') || ', ' 
						|| quote_literal(E'IATI XML Import') || ', ' || quote_literal(current_date) || ', ' || quote_literal(E'IATI XML Import') || ', ' || quote_literal(current_date) 
						|| ') RETURNING financial_id;' INTO financial_id;
					     END IF;
					     IF transact."currency" IS NOT NULL AND transact."currency" <> '' THEN
						  -- Does this value exist in our taxonomy?
						  SELECT INTO record_id classification_id::integer FROM taxonomy_classifications WHERE lower(iati_code) = lower(transact."currency") AND iati_codelist = 'Currency';
						  IF record_id IS NOT NULL THEN
						     -- add the taxonomy to the financial record
						     EXECUTE 'INSERT INTO financial_taxonomy(financial_id, classification_id, field) VALUES( ' || financial_id || ', ' || record_id || ', ''amount'');';
						  END IF;	
					     END IF;
					     
 					     RAISE NOTICE ' + Financial id % was added to the database.', financial_id; 		   
-- 					     RAISE NOTICE '   - Transaction: ';
-- 					     RAISE NOTICE '      - Type:  %', transact."transaction-type";
-- 					     RAISE NOTICE '      - Provider-org:  %', transact."provider-org";
-- 					     RAISE NOTICE '      - Value:  $%', ROUND(CAST(transact."value" as numeric), 2);				
-- 					     RAISE NOTICE '        - Value Date:  $%', transact."value-date";				
-- 					     RAISE NOTICE '        - Currency:  $%', transact."currency";
-- 					     RAISE NOTICE '      - Date:  %', transact."transaction-date";	
					  ELSE
-- 					   RAISE NOTICE 'Transaction value is null or invalid. No record will be written.';
					  END IF;				  
					END LOOP;
				    END LOOP;
				    FOREACH i IN ARRAY activity."contact-info" LOOP
					FOR contact IN EXECUTE 'SELECT (xpath(''/contact-info/organisation/text()'', '|| quote_literal(i) ||'))[1]::text AS "organisation" ' 
					  || ',(xpath(''/contact-info/person-name/text()'', '|| quote_literal(i) ||'))[1]::text AS "person-name"'
					  || ',(xpath(''/contact-info/email/text()'', '|| quote_literal(i) ||'))[1]::text AS "email"'
					  || ',(xpath(''/contact-info/telephone/text()'', '|| quote_literal(i) ||'))[1]::text AS "telephone"'
					  || ',(xpath(''/contact-info/mailing-address/text()'', '|| quote_literal(i) ||'))[1]::text AS "mailing-address"'
					  || ';' LOOP			   
 					    RAISE NOTICE '   - Contact info:  ';
-- 					    RAISE NOTICE '      - Organisation:  %', contact."organisation";
-- 					    RAISE NOTICE '      - Person-name:  %', contact."person-name";
-- 					    RAISE NOTICE '      - Email:  %', contact."email";
-- 					    RAISE NOTICE '      - Telephone:  %', contact."telephone";
-- 					    RAISE NOTICE '      - Mailing-address:  %', contact."mailing-address";
					END LOOP;
				    END LOOP;			    		
				    FOREACH i IN ARRAY activity."location" LOOP
					FOR loc IN EXECUTE 'SELECT (xpath(''/location/coordinates/@latitude'', '|| quote_literal(i) ||'))[1]::text AS "latitude" ' 
					  || ',(xpath(''/location/coordinates/@longitude'', '|| quote_literal(i) ||'))[1]::text AS "longitude" '
					  || ',(xpath(''/location/name/text()'', '|| quote_literal(i) ||'))[1]::text AS "name" '
					  || ',(xpath(''/location/administrative/@country'', '|| quote_literal(i) ||'))[1]::text AS "country" '
					  || ';' LOOP	
					    IF loc."latitude" IS NOT NULL AND loc."longitude" IS NOT NULL 
					    AND pmt_isnumeric(loc."latitude") AND pmt_isnumeric(loc."longitude") THEN
					       lat := loc."latitude"::numeric;
					       long := loc."longitude"::numeric;
					       IF lat >= -90 AND lat <= 90 AND long >= -180 AND long <= 180 THEN
						-- Create a location record and connect to the activity
					       EXECUTE 'INSERT INTO location(activity_id, project_id, title, point, created_by, created_date, updated_by, updated_date) VALUES( ' 
					       || a_id || ', ' || p_id || ', ' || coalesce(quote_literal(loc."name"),'NULL') || ', ' 
					       || 'ST_GeomFromText(''POINT(' || loc."longitude" || ' ' || loc."latitude" || ')'', 4326)' || ', ' 
					       || quote_literal(E'IATI XML Import') || ', ' || quote_literal(current_date) || ', ' || quote_literal(E'IATI XML Import') || ', ' || quote_literal(current_date) 
					       || ')RETURNING location_id;' INTO l_id;
					       IF loc."country" IS NOT NULL AND loc."country" <> '' THEN
						  -- Does this value exist in our taxonomy?
						  SELECT INTO record_id classification_id::integer FROM taxonomy_classifications WHERE lower(iati_code) = lower(loc."country") AND iati_codelist = 'Country';
						  class_id := record_id;
						  IF class_id IS NOT NULL THEN
						     -- Does this relationship exist already?
						     SELECT INTO record_id location_id::integer FROM location_taxonomy WHERE location_id = l_id AND classification_id =  class_id;   
						     IF record_id IS NULL THEN
							-- add the taxonomy to the location record
							EXECUTE 'INSERT INTO location_taxonomy(location_id, classification_id, field) VALUES( ' || l_id || ', ' || class_id || ', ''location_id'');';
						     END IF;
						  END IF;	
					       END IF;
 					       RAISE NOTICE '   - Location:  ';
-- 					       RAISE NOTICE '      - Name:  %', loc."name";
-- 					       RAISE NOTICE '      - Country Code:  %', loc."country";
-- 					       RAISE NOTICE '      - Latitude:  %', loc."latitude";
-- 					       RAISE NOTICE '      - Longitude:  %', loc."longitude";
					       ELSE
						  RAISE NOTICE 'Either or both latitude and longitude values were out of range. Record will not be written.';
					       END IF;
					    ELSE
					       RAISE NOTICE 'Either or both latitude and longitude values were null or invalid. Record will not be written.';
					    END IF;				    
					END LOOP;
				    END LOOP;
				    FOREACH i IN ARRAY activity."budget" LOOP
					FOR budget IN EXECUTE 'SELECT (xpath(''/budget/value/text()'', '|| quote_literal(i) ||'))[1]::text AS "value" ' 
					  || ',(xpath(''/budget/value/@currency'', '|| quote_literal(i) ||'))[1]::text AS "value-currency" '
					  || ',(xpath(''/budget/value/@value-date'', '|| quote_literal(i) ||'))[1]::text AS "value-date" '
					  || ',(xpath(''/budget/period-start/@iso-date'', '|| quote_literal(i) ||'))[1]::text AS "period-start" '
					  || ',(xpath(''/budget/period-end/@iso-date'', '|| quote_literal(i) ||'))[1]::text AS "period-end" '
					  || ';' LOOP	
					    IF budget."value" IS NOT NULL AND pmt_isnumeric(budget."value") THEN 
						-- if there is a period-start element use it to populate date values
						IF budget."period-start" IS NOT NULL AND budget."period-start" <> '' THEN
						   -- Create a financial record with start and end dates
						   EXECUTE 'INSERT INTO financial (project_id, activity_id, amount, start_date, end_date, created_by, created_date, updated_by, updated_date) VALUES( ' 
						   || p_id || ', ' || a_id || ', ' || budget."value" || ', ' || coalesce(quote_literal(budget."period-start"),'NULL') || ', ' 
						   || coalesce(quote_literal(budget."period-end"),'NULL') || ', ' 
						   || quote_literal(E'IATI XML Import') || ', ' || quote_literal(current_date) || ', ' || quote_literal(E'IATI XML Import') || ', ' || quote_literal(current_date) 
						   || ') RETURNING financial_id;' INTO financial_id;
						-- if there isnt a period-start element use value-date attribute from the value element to populate date values	
						ELSE
						   -- Create a financial record with start date
						   EXECUTE 'INSERT INTO financial (project_id, activity_id, amount, start_date, created_by, created_date, updated_by, updated_date) VALUES( ' 
						   || p_id || ', ' || a_id || ', ' || budget."value" || ', ' || coalesce(quote_literal(budget."value-date"),'NULL') || ', '  
						   || quote_literal(E'IATI XML Import') || ', ' || quote_literal(current_date) || ', ' || quote_literal(E'IATI XML Import') || ', ' || quote_literal(current_date) 
						   || ') RETURNING financial_id;' INTO financial_id;
						END IF;
						IF budget."value-currency" IS NOT NULL AND budget."value-currency" <> '' THEN
						  -- Does this value exist in our taxonomy?
						  SELECT INTO record_id classification_id::integer FROM taxonomy_classifications WHERE lower(iati_code) = lower(budget."value-currency") AND iati_codelist = 'Currency';
						  IF record_id IS NOT NULL THEN
						     -- add the taxonomy to the financial record
						     EXECUTE 'INSERT INTO financial_taxonomy(financial_id, classification_id, field) VALUES( ' || financial_id || ', ' || record_id || ', ''amount'');';
						  END IF;	
					       END IF;
 					       RAISE NOTICE '   - Budget:  ';
-- 					       RAISE NOTICE '      - Value:  %', budget."value";
-- 					       RAISE NOTICE '         - Currency:  %', budget."value-currency";
-- 					       RAISE NOTICE '      - Start Date:  %', budget."period-start";
-- 					       RAISE NOTICE '      - End Date:  %', budget."period-end";
					    ELSE
-- 					       RAISE NOTICE 'Budget value is null or invalid. Record will not be written.';
					    END IF; 				    				    
					END LOOP;
				    END LOOP;
				    -- Add reporting organization
				    -- Does this org exist in the database?
	-- 			    SELECT INTO record_id organization.organization_id::integer FROM organization WHERE lower(name) = lower(activity."reporting-org");
	-- 			    IF record_id IS NOT NULL THEN
	-- 				o_id := record_id;
	-- 				--Check for a participation record
	-- 				SELECT INTO record_id participation.participation_id::integer FROM participation WHERE participation.project_id = p_id AND participation.activity_id = a_id AND participation.organization_id = o_id;
	-- 				IF record_id IS NOT NULL THEN
	-- 				   -- Update the participation record
	-- 				   EXECUTE 'UPDATE participation SET reporting_org= true WHERE participation_id =' || record_id || ';'; 
	-- 				ELSE
	-- 				   -- Create the participation record
	-- 				   EXECUTE 'INSERT INTO participation(project_id, activity_id, organization_id, reporting_org, created_by, created_date, updated_by, updated_date) VALUES( ' 
	-- 				    || p_id || ', ' || a_id || ', ' || o_id || ', true , '
	-- 				    || quote_literal(E'IATI XML Import') || ', ' || quote_literal(current_date) || ', ' || quote_literal(E'IATI XML Import') || ', ' || quote_literal(current_date) 
	-- 				    || ') RETURNING participation_id;' INTO participation_id;
	-- 				END IF;
	-- 			    ELSE
	-- 				-- Create a organization record
	-- 				    EXECUTE 'INSERT INTO organization(name, created_by, created_date, updated_by, updated_date) VALUES( ' 
	-- 				    || coalesce(quote_literal(activity."reporting-org"),'NULL') || ', ' 
	-- 				    || quote_literal(E'IATI XML Import') || ', ' || quote_literal(current_date) || ', ' || quote_literal(E'IATI XML Import') || ', ' || quote_literal(current_date) 
	-- 				    || ') RETURNING organization_id;' INTO o_id;
	-- 				-- Create the participation record
	-- 				EXECUTE 'INSERT INTO participation(project_id, activity_id, organization_id, reporting_org, created_by, created_date, updated_by, updated_date) VALUES( ' 
	-- 				    || p_id || ', ' || a_id || ', ' || o_id || ', true , '
	-- 				    || quote_literal(E'IATI XML Import') || ', ' || quote_literal(current_date) || ', ' || quote_literal(E'IATI XML Import') || ', ' || quote_literal(current_date) 
	-- 				    || ') RETURNING participation_id;' INTO participation_id;
	-- 			    END IF;
				    -- Does this value exist in our taxonomy?
				   --  SELECT INTO record_id classification_id::integer FROM taxonomy_classifications WHERE lower(iati_code) = lower(activity."reporting-org_type") AND iati_codelist = 'Organisation Type';
-- 					IF record_id IS NOT NULL THEN
-- 					   -- Does the organization have this taxonomy assigned?
-- 					   SELECT INTO record_id organization_taxonomy.organization_id::integer FROM organization_taxonomy WHERE organization_taxonomy.organization_id = o_id AND organization_taxonomy.classification_id = record_id;
-- 					   IF record_id IS NULL THEN
-- 					      SELECT INTO record_id classification_id::integer FROM taxonomy_classifications WHERE lower(iati_code) = lower(activity."reporting-org_type") AND iati_codelist = 'Organisation Type';
-- 					      -- add the taxonomy to the organization record
-- 					      EXECUTE 'INSERT INTO organization_taxonomy(organization_id, classification_id, field) VALUES( ' || o_id || ', ' || record_id || ', ''organization_id'');';
-- 					   END IF;
-- 					END IF;
			    END IF; -- the activity must have at least a title to be imported	
			END LOOP;
		END IF;	
		ELSE
		-- If we aren't expecting this xml document type 
		-- then we will not put its information in our database
		error := 'The ' || NEW.type || ' document type is unexpected and will not be processed.'; 
		NEW.xml := null;
		NEW.error := error;
	END CASE;
	
	RAISE NOTICE 'Function process_xml() completed.';
		
	RETURN NEW;
    END;
$process_xml$ LANGUAGE plpgsql; 
DROP TRIGGER IF EXISTS process_xml ON xml;
CREATE TRIGGER process_xml BEFORE INSERT ON xml
    FOR EACH ROW EXECUTE PROCEDURE process_xml();            


-- all ACTIVE project activities
CREATE OR REPLACE VIEW active_project_activities
AS SELECT DISTINCT * FROM
(SELECT DISTINCT p.project_id as project_id, a.activity_id as activity_id, l.location_id as location_id, pp.organization_id as organization_id, pp.participation_id as participation_id, a.start_date as activity_start, a.end_date as activity_end
, l.x,l.y, l.georef as georef
FROM project p
JOIN activity a
ON p.project_id = a.project_id
JOIN location l
ON a.activity_id = l.activity_id
JOIN participation pp
ON (p.project_id = pp.project_id AND pp.activity_id IS NULL) 
WHERE a.active = true and p.active = true and l.active = true and pp.active = true
UNION 
SELECT DISTINCT p.project_id as project_id, a.activity_id as activity_id, l.location_id as location_id, pp.organization_id as organization_id, pp.participation_id as participation_id, a.start_date as activity_start, a.end_date as activity_end
, l.x,l.y, l.georef as georef
FROM project p
JOIN activity a
ON p.project_id = a.project_id
JOIN location l
ON a.activity_id = l.activity_id
JOIN participation pp
ON (p.project_id = pp.project_id AND a.activity_id = pp.activity_id)
WHERE a.active = true and p.active = true and l.active = true and pp.active = true) as foo
ORDER BY project_id, activity_id, location_id, organization_id;

/*****************************************************************
No changes just have to drop and recreate due to dependencys
******************************************************************/
-- taxonomy_lookup
CREATE MATERIALIZED VIEW taxonomy_lookup AS
(SELECT project_id, activity_id, location_id, organization_id, participation_id, start_date, end_date, x, y, georef, t.taxonomy_id, foo.classification_id
FROM(SELECT pa.project_id, pa.activity_id, pa.location_id, pa.organization_id, pa.participation_id, pa.activity_start as start_date, pa.activity_end as end_date, pa.x, pa.y, pa.georef, pt.classification_id
FROM active_project_activities pa
JOIN project_taxonomy pt
ON pa.project_id = pt.project_id AND field ='project_id'
UNION
SELECT pa.project_id, pa.activity_id, pa.location_id, pa.organization_id, pa.participation_id, pa.activity_start as start_date, pa.activity_end as end_date, pa.x, pa.y, pa.georef, at.classification_id
FROM active_project_activities pa
JOIN activity_taxonomy at
ON pa.activity_id = at.activity_id AND field ='activity_id'
UNION
SELECT pa.project_id, pa.activity_id, pa.location_id, pa.organization_id, pa.participation_id, pa.activity_start as start_date, pa.activity_end as end_date, pa.x, pa.y, pa.georef, lt.classification_id
FROM active_project_activities pa
JOIN location_taxonomy lt
ON pa.location_id = lt.location_id AND field ='location_id'
UNION
SELECT pa.project_id, pa.activity_id, pa.location_id, pa.organization_id, pa.participation_id, pa.activity_start as start_date, pa.activity_end as end_date, pa.x, pa.y, pa.georef, ot.classification_id 
FROM active_project_activities pa
JOIN organization_taxonomy ot
ON pa.organization_id = ot.organization_id AND field ='organization_id'
UNION
SELECT pa.project_id, pa.activity_id, pa.location_id, pa.organization_id, pa.participation_id, pa.activity_start as start_date, pa.activity_end as end_date, pa.x, pa.y, pa.georef, pt.classification_id
FROM active_project_activities pa
JOIN participation_taxonomy pt
ON pa.participation_id = pt.participation_id AND field ='participation_id'
) as foo
JOIN classification c
ON foo.classification_id = c.classification_id
JOIN taxonomy t
ON c.taxonomy_id = t.taxonomy_id);

-- location_lookup
CREATE MATERIALIZED VIEW location_lookup AS
(SELECT project_id, activity_id, location_id, start_date, end_date, x, y, georef, array_agg(distinct taxonomy_id) as taxonomy_ids, array_agg(distinct classification_id) as classification_ids, array_agg(distinct organization_id) as organization_ids,
(SELECT lbf.name FROM location_boundary_features lbf WHERE taxonomy_lookup.location_id = lbf.location_id AND lbf.boundary_id = 1 LIMIT 1) as gaul0_name,
(SELECT lbf.name FROM location_boundary_features lbf WHERE taxonomy_lookup.location_id = lbf.location_id AND lbf.boundary_id = 2 LIMIT 1) as gaul1_name,
(SELECT lbf.name FROM location_boundary_features lbf WHERE taxonomy_lookup.location_id = lbf.location_id AND lbf.boundary_id = 3 LIMIT 1) as gaul2_name
FROM taxonomy_lookup
GROUP BY project_id, activity_id, location_id, start_date, end_date, x, y, georef);

-- organization_lookup
CREATE MATERIALIZED VIEW organization_lookup AS
(SELECT project_id, activity_id, organization_id, start_date, end_date, array_agg(distinct taxonomy_id) as taxonomy_ids, array_agg(distinct classification_id) as classification_ids, array_agg(distinct location_id) as location_ids
FROM taxonomy_lookup
GROUP BY project_id, activity_id, organization_id, start_date, end_date);

-- function to support the taxonomy_lookup table
CREATE OR REPLACE FUNCTION refresh_taxonomy_lookup() RETURNS integer AS $$
BEGIN
    RAISE NOTICE 'Refreshing lookup views...';
    REFRESH MATERIALIZED VIEW taxonomy_lookup;
    REFRESH MATERIALIZED VIEW location_lookup;  
    REFRESH MATERIALIZED VIEW organization_lookup;
    RAISE NOTICE 'Done refreshing lookup views.';
    RETURN 1;
END;
$$ LANGUAGE plpgsql;
-- SELECT refresh_taxonomy_lookup();

-- select * from pmt_sector_compare(null, null); --all
-- select * from pmt_sector_compare('', 'a_id'); --all
-- select * from pmt_sector_compare('768,769,756', ''); -- AFDB, Bolivia (data groups) "Sectors not specified"
-- select * from pmt_sector_compare('769,756', 'import'); -- Bolivia (data groups) "Sectors not specified"

DROP FUNCTION IF EXISTS pmt_sector_compare(character varying, character varying)  CASCADE;

--Drop Types  (if it exists)
DROP TYPE IF EXISTS pmt_sector_compare_result_type CASCADE;
CREATE TYPE pmt_sector_compare_result_type AS (response json);
/******************************************************************
   pmt_sector_compare
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_sector_compare(classification_ids character varying, order_by character varying) RETURNS SETOF pmt_sector_compare_result_type AS 
$$
DECLARE
  filter_classids integer array;
  built_where text array; 
  dynamic_where1 text array;
  dynamic_orderby text;
  execute_statement text;
  i integer;
  rec record;
BEGIN	

    -- filter by classification ids
    IF ($1 is not null AND $1 <> '') THEN
      RAISE NOTICE '   + The classification filter is: %.', string_to_array($1, ',')::int[];

	SELECT INTO filter_classids * FROM pmt_validate_classifications($1);

	IF filter_classids IS NOT NULL THEN
	  -- Loop through each taxonomy classification group to contruct the where statement 
	  FOR rec IN( SELECT tc.taxonomy_id, array_agg(tc.classification_id) AS filter_array 
	  FROM taxonomy_classifications tc WHERE classification_id = ANY(filter_classids) GROUP BY tc.taxonomy_id
	  ) LOOP				
		built_where := null;
		-- for each classification add to the where statement
		FOREACH i IN ARRAY rec.filter_array LOOP 
		  built_where :=  array_append(built_where, 'classification_ids @> ARRAY['|| i ||']');
		END LOOP;
		-- add each classification within the same taxonomy to the where joined by 'OR'
		dynamic_where1 := array_append(dynamic_where1, '(' || array_to_string(built_where, ' OR ') || ')');
	  END LOOP;			
	END IF;
    END IF;

    -- create dynamic order statement
    IF $2 IS NOT NULL AND $2 <> '' THEN 
      dynamic_orderby := 'ORDER BY ' || $2 || ' ';
    END IF;

    -- prepare statement																
    RAISE NOTICE '   + First where statement: %', array_to_string(dynamic_where1, ' AND ');

    execute_statement := 'SELECT a.activity_id as a_id, tc.classification_id as c_id, tc.classification as sector, a.content as import ' ||
			'FROM activity a LEFT JOIN (SELECT * FROM activity_taxonomy WHERE classification_id IN ' ||
			'(SELECT classification_id FROM taxonomy_classifications WHERE iati_codelist = ''Sector'' AND taxonomy = ''Sector'')) AS at ' ||
			'ON a.activity_id = at.activity_id JOIN taxonomy_classifications tc ON at.classification_id = tc.classification_id ';
			
    -- append where statements			
    IF dynamic_where1 IS NOT NULL THEN 
      execute_statement := execute_statement || 'WHERE  a.activity_id IN (SELECT activity_id FROM location_lookup WHERE ' ||  array_to_string(dynamic_where1, ' AND ') || ') ';
    END IF;

    -- append order statements
    IF dynamic_orderby IS NOT NULL THEN 
      execute_statement := execute_statement || dynamic_orderby;
    END IF;
    
    -- execute statement		
    RAISE NOTICE 'execute: %', 'SELECT row_to_json(j) FROM (' || execute_statement || ')j';	   
     
    FOR rec IN EXECUTE 'SELECT row_to_json(j) FROM (' || execute_statement || ')j' LOOP     
	RETURN NEXT rec;
    END LOOP;	
	  
END;$$ LANGUAGE plpgsql;

-- select * from refresh_taxonomy_lookup(); -- (6-21s)

-- select * from pmt_sector_compare('769,756,757', 'a_id');
-- select * from pmt_edit_activity_taxonomy('5526,99999,2335,2336', 757, 'add');
-- select * from pmt_edit_activity_taxonomy('5526,99999', 757, 'delete');
-- select * from pmt_edit_activity_taxonomy('5526,99999,2335,2336', 756, 'replace');

--DROP TYPE IF EXISTS edit_action CASCADE;

--DROP FUNCTION IF EXISTS pmt_edit_activity_taxonomy(character varying, integer, edit_action)  CASCADE;

CREATE TYPE edit_action AS ENUM ('add','delete','replace');


/******************************************************************
   pmt_edit_activity_taxonomy
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_edit_activity_taxonomy(activity_ids character varying, classification_id integer, edit_action edit_action) RETURNS BOOLEAN AS 
$$
DECLARE
  valid_classification_id boolean;
  valid_activity_ids integer[];
  msg text;
  record_id integer;
  t_id integer;
  i integer;
  rec record;
BEGIN	

  -- first and second parameters are required
  IF ($1 is not null AND $1 <> '') AND ($2 IS NOT NULL) THEN
  
    -- validate classification_id
    SELECT INTO valid_classification_id * FROM pmt_validate_classification($2);
    -- must provide a valid classification_id to continue
    IF NOT valid_classification_id THEN
      RAISE NOTICE 'Error: Must provide a valid classification_id.';
      RETURN false;
    END IF;
    -- validate activity_ids
    SELECT INTO valid_activity_ids array_agg(DISTINCT activity_id) FROM activity WHERE activity_id = ANY(string_to_array($1, ',')::int[]);
    -- must provide a min of one valid activity_id to continue
    IF valid_activity_ids IS NOT NULL THEN
      -- get the taxonomy_id of the classification_id
      SELECT INTO t_id taxonomy_id FROM taxonomy_classifications tc WHERE tc.classification_id = $2;
      IF t_id IS NOT NULL THEN
        -- operations based on edit_action
        CASE $3
          WHEN 'add' THEN
            FOREACH i IN ARRAY valid_activity_ids LOOP 
             SELECT INTO record_id activity_id FROM activity_taxonomy as at WHERE at.activity_id = i AND at.classification_id = $2 LIMIT 1;
             IF record_id IS NULL THEN
               EXECUTE 'INSERT INTO activity_taxonomy(activity_id, classification_id, field) VALUES ('|| i ||', '|| $2 ||', ''activity_id'')';
               RAISE NOTICE 'Add Record: %', 'Activity_id ('|| i ||') is now associated to classification_id ('|| $2 ||').'; 
             ELSE
               RAISE NOTICE'Add Record: %', 'This activity_id ('|| i ||') already has an association to this classification_id ('|| $2 ||').';                
             END IF;
            END LOOP;
          WHEN 'delete' THEN
            FOREACH i IN ARRAY valid_activity_ids LOOP 
              EXECUTE 'DELETE FROM activity_taxonomy WHERE activity_id ='|| i ||' AND classification_id = '|| $2 ||' AND field = ''activity_id'''; 
              RAISE NOTICE 'Delete Record: %', 'Remove association to classification_id ('|| $2 ||') for actvity_id ('|| i ||')';
            END LOOP;
          WHEN 'replace' THEN
            FOREACH i IN ARRAY valid_activity_ids LOOP 
              EXECUTE 'DELETE FROM activity_taxonomy WHERE activity_id ='|| i ||' AND classification_id in (SELECT classification_id FROM taxonomy_classifications WHERE taxonomy_id = '|| t_id||') AND field = ''activity_id''';
              RAISE NOTICE 'Delete Record: %', 'Remove association to taxonomy_id ('|| t_id ||') for actvity_id ('|| i ||')';
	      EXECUTE 'INSERT INTO activity_taxonomy(activity_id, classification_id, field) VALUES ('|| i ||', '|| $2 ||', ''activity_id'')'; 
              RAISE NOTICE 'Add Record: %', 'Activity_id ('|| i ||') is now associated to classification_id ('|| $2 ||').';
            END LOOP;
          ELSE
            FOREACH i IN ARRAY valid_activity_ids LOOP 
             SELECT INTO record_id activity_id FROM activity_taxonomy as at WHERE at.activity_id = i AND at.classification_id = $2 LIMIT 1;
             IF record_id IS NULL THEN
               EXECUTE 'INSERT INTO activity_taxonomy(activity_id, classification_id, field) VALUES ('|| i ||', '|| $2 ||', ''activity_id'')';
               RAISE NOTICE 'Add Record: %', 'Activity_id ('|| i ||') is now associated to classification_id ('|| $2 ||').'; 
             ELSE
               RAISE NOTICE'Add Record: %', 'This activity_id ('|| i ||') already has an association to this classification_id ('|| $2 ||').';                
             END IF;
            END LOOP;
        END CASE;
        RETURN true;
      ELSE
        RAISE NOTICE 'Error: There is no taxonomy_id for given classification_id.';
	RETURN false;
      END IF;
    ELSE
      RAISE NOTICE 'Error: Must provide at least one valid activity_id.';
      RETURN false;
    END IF;
  ELSE
    RAISE NOTICE 'Error: Must provide all parameters.';
    RETURN false;
  END IF; 	  
END;$$ LANGUAGE plpgsql;

-- update permissions
GRANT USAGE ON SCHEMA public TO pmt_read;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO pmt_read;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO pmt_read;
GRANT USAGE ON SCHEMA public TO pmt_write;
GRANT SELECT,INSERT ON ALL TABLES IN SCHEMA public TO pmt_write;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO pmt_write;