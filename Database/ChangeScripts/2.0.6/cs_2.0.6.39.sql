/******************************************************************
Change Script 2.0.6.39 - Consolidated.
1. process_xml - bug fix. Wasn't picking up sector codes if sector
elements had no text.
******************************************************************/
INSERT INTO config(version, iteration, changeset) VALUES (2.0, 6, 39);
-- select * from config order by version, iteration, changeset, updated_date;

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
			    || ',(xpath(''/iati-activity/reporting-org/text()'', node.xml))[1]::text AS "reporting-org", (xpath(''/iati-activity/reporting-org/@type'', node.xml))[1]::text AS "reporting-org_type" '
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

			    -- Create a activity record and connect to the created project
			    EXECUTE 'INSERT INTO activity (project_id, title, description, created_by, created_date, updated_by, updated_date) VALUES( ' 
			    || p_id || ', ' || coalesce(quote_literal(activity."title"),'NULL') || ', ' 
			    || coalesce(quote_literal(activity."description"),'NULL') || ', ' 
			    || quote_literal(E'IATI XML Import') || ', ' || quote_literal(current_date) || ', ' || quote_literal(E'IATI XML Import') || ', ' || quote_literal(current_date) 
			    || ') RETURNING activity_id;' INTO a_id;
			    
			    
			    RAISE NOTICE ' +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++';
			    RAISE NOTICE ' + Activity id % was added to the database.', a_id; 				    
			    RAISE NOTICE ' + Adding activity:  %', activity."iati-identifier";		-- not a PMT attribute and not written to the database
			    RAISE NOTICE '   - Reporting org:  %', activity."reporting-org";		
			    RAISE NOTICE '      - Type:  %', activity."reporting-org_type";
			    RAISE NOTICE '   - Title:  %', activity."title";
			    RAISE NOTICE '   - Description:  %', activity."description";
			    
			    idx := 1;
			    FOREACH i IN ARRAY activity."participating-org" LOOP
				-- Does this org exist in the database?
				SELECT INTO record_id organization.organization_id::integer FROM organization WHERE lower(name) = lower(i);
				IF record_id IS NOT NULL THEN
				    -- Create a participation record
				    EXECUTE 'INSERT INTO participation(project_id, activity_id, organization_id, created_by, created_date, updated_by, updated_date) VALUES( ' 
				    || p_id || ', ' || a_id || ', ' || record_id || ', ' 
				    || quote_literal(E'IATI XML Import') || ', ' || quote_literal(current_date) || ', ' || quote_literal(E'IATI XML Import') || ', ' || quote_literal(current_date) 
				    || ') RETURNING participation_id;' INTO participation_id;				   
				ELSE
				    -- Create a organization record
				    EXECUTE 'INSERT INTO organization(name, created_by, created_date, updated_by, updated_date) VALUES( ' 
				    || coalesce(quote_literal(i),'NULL') || ', ' 
				    || quote_literal(E'IATI XML Import') || ', ' || quote_literal(current_date) || ', ' || quote_literal(E'IATI XML Import') || ', ' || quote_literal(current_date) 
				    || ') RETURNING organization_id;' INTO o_id;
				    -- Create a participation record
				    EXECUTE 'INSERT INTO participation(project_id, activity_id, organization_id, created_by, created_date, updated_by, updated_date) VALUES( ' 
				    || p_id || ', ' || a_id || ', ' || o_id || ', ' 
				    || quote_literal(E'IATI XML Import') || ', ' || quote_literal(current_date) || ', ' || quote_literal(E'IATI XML Import') || ', ' || quote_literal(current_date) 
				    || ') RETURNING participation_id;' INTO participation_id;
				END IF;
				-- Does this value exist in our taxonomy?
				SELECT INTO record_id classification_id::integer FROM taxonomy_classifications WHERE lower(iati_code) = lower(activity."participating-org_role"[idx]) AND iati_codelist = 'Organisation Role';
				IF record_id IS NOT NULL THEN
				   -- add the taxonomy to the participation record
			           EXECUTE 'INSERT INTO participation_taxonomy(participation_id, classification_id, field) VALUES( ' || participation_id || ', ' || record_id || ', ''participation_id'');';
				END IF;
				-- Does this value exist in our taxonomy?
				SELECT INTO record_id classification_id::integer FROM taxonomy_classifications WHERE lower(iati_code) = lower(activity."participating-org_type"[idx]) AND iati_codelist = 'Organisation Type';
				IF record_id IS NOT NULL THEN
				   -- Does the organization have this taxonomy assigned?
				   SELECT INTO record_id organization_taxonomy.organization_id::integer FROM organization_taxonomy WHERE organization_taxonomy.organization_id = o_id AND organization_taxonomy.classification_id = record_id;
				   IF record_id IS NULL THEN
				      -- add the taxonomy to the organization record
			              EXECUTE 'INSERT INTO organization_taxonomy(organization_id, classification_id, field) VALUES( ' || o_id || ', ' || record_id || ', ''organization_id'');';
			           END IF;
				END IF;				  
				RAISE NOTICE '   - Participating org:  %', i;
				RAISE NOTICE '      - Role:  %', activity."participating-org_role"[idx];
				RAISE NOTICE '      - Type:  %', activity."participating-org_type"[idx];
				idx := idx + 1;
			    END LOOP;	
			    idx := 1;
			    FOREACH i IN ARRAY activity."recipient-country" LOOP
			        IF activity."recipient-country_code"[idx] IS NOT NULL THEN
			           -- Does this value exist in our taxonomy?
			           SELECT INTO record_id classification_id::integer FROM taxonomy_classifications WHERE lower(iati_code) = lower(activity."recipient-country_code"[idx]) AND iati_codelist = 'Country';
				   IF record_id IS NOT NULL THEN
				      -- add the taxonomy to the activity record
				      EXECUTE 'INSERT INTO activity_taxonomy(activity_id, classification_id, field) VALUES( ' || a_id || ', ' || record_id || ', ''activity_id'');';
				   END IF;	
			        END IF;
				RAISE NOTICE '   - Recipient country:  %', i;
				RAISE NOTICE '      - Code:  %', activity."recipient-country_code"[idx];
				IF activity."recipient-country_percentage"[idx] IS NULL THEN
					RAISE NOTICE '      - Percentage:  100';
				ELSE				
					RAISE NOTICE '      - Percentage:  %', activity."recipient-country_percentage"[idx];
				END IF;
				idx := idx + 1;
			    END LOOP;			    		   
			    idx := 1;
			    FOREACH i IN ARRAY activity."activity-date" LOOP
			       IF i <> ''  AND pmt_isdate(i) THEN
			          CASE 
			            WHEN lower(activity."activity-date_type"[idx]) = 'start-planned' OR lower(activity."activity-date_type"[idx]) = 'start-actual' THEN				    
			               EXECUTE 'UPDATE activity SET start_date=' || coalesce(quote_nullable(i)) || ' WHERE activity_id =' || a_id || ';'; 
			            WHEN lower(activity."activity-date_type"[idx]) = 'end-planned' OR lower(activity."activity-date_type"[idx]) = 'end-actual' THEN
			               EXECUTE 'UPDATE activity SET end_date=' || coalesce(quote_nullable(i)) || ' WHERE activity_id =' || a_id || ';'; 
			            ELSE
			               EXECUTE 'UPDATE activity SET start_date=' || coalesce(quote_nullable(i)) || ' WHERE activity_id =' || a_id || ';'; 
			          END CASE;
			       END IF;
			       			
				RAISE NOTICE '   - Activity date:  %', i;				
				RAISE NOTICE '      - Type:  %', activity."activity-date_type"[idx];    
				idx := idx + 1;
			    END LOOP;
			    IF 	activity."activity-status_code" IS NOT NULL THEN
			        -- Does this value exist in our taxonomy?
			        SELECT INTO record_id classification_id::integer FROM taxonomy_classifications WHERE lower(iati_code) = lower(activity."activity-status_code") AND iati_codelist = 'Activity Staus';
				IF record_id IS NOT NULL THEN
				   -- add the taxonomy to the activity record
				   EXECUTE 'INSERT INTO activity_taxonomy(activity_id, classification_id, field) VALUES( ' || a_id || ', ' || record_id || ', ''activity_id'');';
				END IF;	
			    END IF;
			    RAISE NOTICE '   - Activity status:  %', activity."activity-status";
			    RAISE NOTICE '      - Code:  %', activity."activity-status_code";
			    idx := 1;
			    FOREACH i IN ARRAY activity."sector_code" LOOP
				IF activity."sector_code"[idx] IS NOT NULL THEN
				   -- Does this value exist in our taxonomy?
				   SELECT INTO class_id classification_id::integer FROM taxonomy_classifications WHERE lower(iati_code) = lower(activity."sector_code"[idx]) AND iati_codelist = 'Sector';
				   IF class_id IS NOT NULL THEN
				      -- does this activity already have this sector assigned?
				      SELECT INTO record_id activity_id::integer FROM activity_taxonomy WHERE activity_id = a_id AND classification_id = class_id;
				      IF record_id IS NULL THEN
				         -- add the taxonomy to the activity record
				         EXECUTE 'INSERT INTO activity_taxonomy(activity_id, classification_id, field) VALUES( ' || a_id || ', ' || class_id || ', ''activity_id'');';
				      END IF;
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
				RAISE NOTICE '   - Sector:  %', i;
				RAISE NOTICE '      - Code:  %', activity."sector_code"[idx];
				RAISE NOTICE '      - Category: %', lower(substring(activity."sector_code"[idx] from 1 for 3));
				idx := idx + 1;
			    END LOOP;			    
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
				     RAISE NOTICE '   - Transaction: ';
				     RAISE NOTICE '      - Type:  %', transact."transaction-type";
				     RAISE NOTICE '      - Provider-org:  %', transact."provider-org";
				     RAISE NOTICE '      - Value:  $%', ROUND(CAST(transact."value" as numeric), 2);				
				     RAISE NOTICE '        - Value Date:  $%', transact."value-date";				
				     RAISE NOTICE '        - Currency:  $%', transact."currency";
				     RAISE NOTICE '      - Date:  %', transact."transaction-date";	
				  ELSE
				   RAISE NOTICE 'Transaction value is null or invalid. No record will be written.';
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
				    RAISE NOTICE '      - Organisation:  %', contact."organisation";
				    RAISE NOTICE '      - Person-name:  %', contact."person-name";
				    RAISE NOTICE '      - Email:  %', contact."email";
				    RAISE NOTICE '      - Telephone:  %', contact."telephone";
				    RAISE NOTICE '      - Mailing-address:  %', contact."mailing-address";
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
				       RAISE NOTICE '      - Name:  %', loc."name";
				       RAISE NOTICE '      - Country Code:  %', loc."country";
				       RAISE NOTICE '      - Latitude:  %', loc."latitude";
				       RAISE NOTICE '      - Longitude:  %', loc."longitude";
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
				       RAISE NOTICE '      - Value:  %', budget."value";
				       RAISE NOTICE '         - Currency:  %', budget."value-currency";
				       RAISE NOTICE '      - Start Date:  %', budget."period-start";
				       RAISE NOTICE '      - End Date:  %', budget."period-end";
				    ELSE
				       RAISE NOTICE 'Budget value is null or invalid. Record will not be written.';
 				    END IF; 				    				    
				END LOOP;
			    END LOOP;
			    -- Add reporting organization
			    -- Does this org exist in the database?
			    SELECT INTO record_id organization.organization_id::integer FROM organization WHERE lower(name) = lower(activity."reporting-org");
			    IF record_id IS NOT NULL THEN
				o_id := record_id;
				--Check for a participation record
				SELECT INTO record_id participation.participation_id::integer FROM participation WHERE participation.project_id = p_id AND participation.activity_id = a_id AND participation.organization_id = o_id;
				IF record_id IS NOT NULL THEN
				   -- Update the participation record
				   EXECUTE 'UPDATE participation SET reporting_org= true WHERE participation_id =' || record_id || ';'; 
				ELSE
				   -- Create the participation record
				   EXECUTE 'INSERT INTO participation(project_id, activity_id, organization_id, reporting_org, created_by, created_date, updated_by, updated_date) VALUES( ' 
				    || p_id || ', ' || a_id || ', ' || o_id || ', true , '
				    || quote_literal(E'IATI XML Import') || ', ' || quote_literal(current_date) || ', ' || quote_literal(E'IATI XML Import') || ', ' || quote_literal(current_date) 
				    || ') RETURNING participation_id;' INTO participation_id;
				END IF;
			    ELSE
				-- Create a organization record
				    EXECUTE 'INSERT INTO organization(name, created_by, created_date, updated_by, updated_date) VALUES( ' 
				    || coalesce(quote_literal(activity."reporting-org"),'NULL') || ', ' 
				    || quote_literal(E'IATI XML Import') || ', ' || quote_literal(current_date) || ', ' || quote_literal(E'IATI XML Import') || ', ' || quote_literal(current_date) 
				    || ') RETURNING organization_id;' INTO o_id;
				-- Create the participation record
				EXECUTE 'INSERT INTO participation(project_id, activity_id, organization_id, reporting_org, created_by, created_date, updated_by, updated_date) VALUES( ' 
				    || p_id || ', ' || a_id || ', ' || o_id || ', true , '
				    || quote_literal(E'IATI XML Import') || ', ' || quote_literal(current_date) || ', ' || quote_literal(E'IATI XML Import') || ', ' || quote_literal(current_date) 
				    || ') RETURNING participation_id;' INTO participation_id;
			    END IF;
			    -- Does this value exist in our taxonomy?
			    SELECT INTO record_id classification_id::integer FROM taxonomy_classifications WHERE lower(iati_code) = lower(activity."reporting-org_type") AND iati_codelist = 'Organisation Type';
				IF record_id IS NOT NULL THEN
				   -- Does the organization have this taxonomy assigned?
				   SELECT INTO record_id organization_taxonomy.organization_id::integer FROM organization_taxonomy WHERE organization_taxonomy.organization_id = o_id AND organization_taxonomy.classification_id = record_id;
				   IF record_id IS NULL THEN
				      SELECT INTO record_id classification_id::integer FROM taxonomy_classifications WHERE lower(iati_code) = lower(activity."reporting-org_type") AND iati_codelist = 'Organisation Type';
				      -- add the taxonomy to the organization record
			              EXECUTE 'INSERT INTO organization_taxonomy(organization_id, classification_id, field) VALUES( ' || o_id || ', ' || record_id || ', ''organization_id'');';
			           END IF;
				END IF;	
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