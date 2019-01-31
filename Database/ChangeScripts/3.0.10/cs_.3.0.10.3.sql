/******************************************************************
Change Script 3.0.10.3
1. update pmt_data_groups for new naming convention changes
2. update pmt_validate_user_authority to remove project
3. update pmt_iati_import to remove project and 'replace all' option
4. create new function pmt_etl_iati_codelist to process the IATI 
codelist xml documents  
5. create new function pmt_etl_iati_activities_v104 to process the 
version 1.04 IATI activity xml documents
6. create new function pmt_etl_iati_activities_v201 to process the 
version 2.01 IATI activity xml documents
7. create new trigger pmt_iati_preprocess to pre-process the IATI xml 
documents to collect important information needed for processing, this 
information is then recorded in the iati_import table.
8. create new trigger pmt_iati_evaluate to evaluate the IATI xml 
documents and determine which version and ETL process to call
******************************************************************/
INSERT INTO version(_version, _iteration, _changeset) VALUES (3.0, 10, 3);
-- select * from version order by _iteration desc, _changeset desc;

/******************************************************************
  pmt_data_groups
  -- update pmt_data_groups for new naming convention changes
  -- select * from pmt_data_groups();
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_data_groups()
RETURNS SETOF pmt_data_groups_result_type AS 
$$
DECLARE
  rec record;
BEGIN	
  -- collect all active data groups 
  FOR rec IN (SELECT classification_id as c_id, classification::text as name FROM _taxonomy_classifications WHERE taxonomy = 'Data Group') LOOP		
	RETURN NEXT rec;
  END LOOP;	  
END;$$ LANGUAGE plpgsql;

/******************************************************************
  pmt_validate_user_authority
  -- update pmt_validate_user_authority to remove project_id  
  select * from pmt_validate_user_authority(34, null, 'create');
******************************************************************/
DROP FUNCTION IF EXISTS pmt_validate_user_authority(integer, integer, pmt_auth_crud);
CREATE OR REPLACE FUNCTION pmt_validate_user_authority(user_id integer, activity_id integer, auth_type pmt_auth_crud) RETURNS boolean AS $$
DECLARE 
	users_authority record;
	error_msg text;
	role_crud boolean;
BEGIN 
     -- user and authorization type parameters are required
     IF $1 IS NULL  OR $3 IS NULL THEN    
       RAISE NOTICE 'Missing required parameters';
       RETURN FALSE;
     END IF; 
     
     -- check to see if user has a role with "SUPER" rights (if so they have full adminsitrative editing rights to the database)
     SELECT INTO role_crud _super FROM role WHERE id = (SELECT role_id FROM users WHERE users.id = $1);

     IF role_crud THEN
       RAISE NOTICE 'User is a Super User';
       RETURN TRUE;
     END IF;  
     
     -- No activity_id, the requesting authorization at the database level
     IF $2 IS NULL THEN
       -- Only authorization type valid at the database level is CREATE
       -- (determine if user is allowed to create new records)
       IF auth_type = 'create' THEN
         SELECT INTO role_crud _create FROM role WHERE id = (SELECT role_id FROM users WHERE users.id  = $1);	           
         IF role_crud THEN
	   RETURN TRUE;
         ELSE
	   RETURN FALSE;
         END IF;
       ELSE
         RETURN FALSE;
       END IF;
     END IF;

     -- determine if user has access to the requested activity
     FOR users_authority IN (SELECT * FROM (SELECT ua.activity_id, ua.role_id FROM user_activity_role ua WHERE ua.user_id = $1 AND ua.classification_id IS NULL AND ua.active = true UNION ALL
     SELECT at.activity_id, ua.role_id FROM user_activity_role ua JOIN activity_taxonomy at ON ua.classification_id = at.classification_id WHERE ua.user_id = $1 AND ua.classification_id IS NOT NULL AND ua.active = true) auth 
     WHERE auth.activity_id = $2) LOOP
       -- get users authorization type based on their role
       CASE auth_type
	 WHEN 'create' THEN
	   SELECT INTO role_crud _create FROM role WHERE id = users_authority.role_id;	    
	 WHEN 'read' THEN
	   SELECT INTO role_crud _read FROM role WHERE id = users_authority.role_id;	    
	 WHEN 'update' THEN
	   SELECT INTO role_crud _update FROM role WHERE id = users_authority.role_id;	    
  	 WHEN 'delete' THEN
	   SELECT INTO role_crud _delete FROM role WHERE id = users_authority.role_id;	    
	 ELSE
	   RETURN FALSE;
       END CASE; 

       -- determine if the authorization type is allowed by user role
       IF role_crud THEN
	 RETURN TRUE;
       ELSE
         RAISE NOTICE 'User does not have requested authorization type (%) for requested activity', $3;
	 RETURN FALSE;
       END IF;             
     END LOOP;

     RAISE NOTICE 'Activity id (%) NOT in authorized activities.', $2;
     RETURN FALSE;    
    
EXCEPTION WHEN others THEN
     GET STACKED DIAGNOSTICS error_msg = MESSAGE_TEXT;  
    RAISE NOTICE 'Internal Error - Contact your DBA with the following error message: %', error_msg;
    RETURN FALSE;
END; 
$$ LANGUAGE 'plpgsql';

/******************************************************************
  pmt_iati_import
  -- update pmt_iati_import to remove project, remove 'replace all' 
  option & add user_id
  SELECT * FROM pmt_iati_import(34, 'SectorCategory.xml', 'UTF8', 'Test');
  SELECT * FROM classification WHERE taxonomy_id = 1;
******************************************************************/
DROP FUNCTION IF EXISTS pmt_iati_import(text, character varying, boolean);
CREATE OR REPLACE FUNCTION pmt_iati_import(user_id integer, file_path text, file_encoding text, data_group character varying(255)) RETURNS boolean AS $$
DECLARE 
  data_group_name character varying; -- the data group classification name for all loaded activities
  username text;  -- the username for the user loading the data
  error_msg1 text; -- error message for database execeptions
  error_msg2 text; -- error message for database execeptions
  error_msg3 text; -- error message for database execeptions
BEGIN  
     -- all options are required    
     IF ($1 IS NULL) OR ($2 IS NULL) OR ($3 IS NULL) OR ($4 IS NULL) THEN
       RAISE NOTICE 'Required parameter not provided.';
       RETURN FALSE;
     END IF;   

     -- validate user authority
     IF (SELECT * FROM pmt_validate_user_authority($1, null, 'create')) THEN
       SELECT INTO username _username FROM users WHERE id = $1;
     ELSE
       RAISE NOTICE 'User does not have authority to create activities.';
       RETURN FALSE;
     END IF;
    
     -- validate data group or create if it does not exist
     IF (SELECT * FROM pmt_is_data_group($4)) THEN
       -- get the classification id for the data group
       SELECT INTO data_group_name _name FROM classification WHERE taxonomy_id = (SELECT id FROM taxonomy WHERE _name = 'Data Group') AND _active = TRUE AND lower(_name) = lower($4);
     ELSE
       -- create new data group classification
       INSERT INTO classification(taxonomy_id, _name, _created_by, _updated_by) 
       VALUES ((SELECT id FROM taxonomy WHERE _name = 'Data Group'), trim($4), username, username) 
       RETURNING _name INTO data_group_name;
     END IF;

     -- load the xml data into the iati_import table, where a trigger is listening for a new record
     -- the trigger will then process the data for inclusion in the PMT
     IF (data_group_name IS NOT NULL) AND (data_group_name != '') THEN

       INSERT INTO iati_import (_action, _xml, _data_group, _created_by) 
	 VALUES('insert',convert_from(pmt_bytea_import($2), $3)::xml, data_group_name, username);     
       RAISE NOTICE 'The XML document was loaded into the database. See the iati_import table for more information.';     
       RETURN TRUE;
     ELSE
       RAISE NOTICE 'Data group was not validated.';
       RETURN FALSE;
     END IF;
          
EXCEPTION WHEN others THEN
    GET STACKED DIAGNOSTICS error_msg1 = MESSAGE_TEXT,
                          error_msg2 = PG_EXCEPTION_DETAIL,
                          error_msg3 = PG_EXCEPTION_HINT;
    RAISE NOTICE 'Internal Error - Contact your DBA with the following error message: (pmt_iati_import) %', error_msg1;	 
  RETURN FALSE;
END; 

$$ LANGUAGE 'plpgsql';

/******************************************************************
  pmt_etl_iati_codelist
  -- create new function to process the IATI codelist xml documents
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_etl_iati_codelist(iati_import_id integer) RETURNS boolean AS $$
-- Extracts data from xml document, transforms the data to be PMT compatable and loads the
-- data into the PMT database. Function should only be called from the pmt_iati_evaluate 
-- trigger, which ensures proper usage of the function.
-- Parameters: iati_import_id (the iati_import id of the record to process)
DECLARE 
  iati record; -- the target iati_import record
  codelist_ct integer; -- number of codelists existing
  codelist_category text; -- the codelist category
  taxonomy_name text; -- the name of the taxonomy derived from the codelist name
  t_id integer; -- the taxonomy id for current taxonomy
  metadata record; -- to hold the metadata object from the xml document
  codelist record; -- to hold the codelist-item object from the xml document
  parent_taxonomy record; -- to hold the parent taxonomy record
  parent_classification record; -- to hold the parent classification record
  error_msg1 text; -- error message for database execeptions
  error_msg2 text; -- error message for database execeptions
  error_msg3 text; -- error message for database execeptions
BEGIN  
  SELECT INTO iati * FROM iati_import WHERE id = iati_import_id;
  -- does this codelist exist in the database?
  SELECT INTO codelist_ct COUNT(*)::integer FROM taxonomy WHERE _iati_codelist = iati._codelist;
  -- if the codelist doesn't exist, then load it
  IF (codelist_ct = 0) THEN
    -- does the codelist have a codelist category
    codelist_category := (xpath('/codelist/@category-codelist',iati._xml))[1]::text; 
    RAISE NOTICE 'Category: %', codelist_category;
    -- does not depend on any other codelist
    IF codelist_category IS NULL OR codelist_category = '' THEN  
      -- the metadata for the taxonomy  
      FOR metadata IN EXECUTE 'SELECT (xpath(''/metadata/name/narrative/text()'', node.xml))[1]::text AS "name" ' 
			    || ',(xpath(''/metadata/description/narrative/text()'', node.xml))[1]::text AS "description" '
			    || 'FROM(SELECT unnest(xpath(''/codelist/metadata'', '|| quote_literal(iati._xml) ||'))::xml AS xml) AS node;' LOOP
      END LOOP;

      RAISE NOTICE ' + Adding the % to the database:', iati._type || ' for ' || metadata."name"; 
      RAISE NOTICE ' + Description: %', metadata."description";

      -- Add taxonomy record				
      EXECUTE 'INSERT INTO taxonomy (_name, _description, _iati_codelist, _created_by, _updated_by) VALUES( ' 
	|| quote_literal(metadata."name") || ', ' || coalesce(quote_literal(trim(regexp_replace(metadata."description", '\s\s+|\t|\n|\r', ' ', 'g'))), 'NULL') || 
	', ' || quote_literal(iati._codelist) || ', ' || quote_literal(E'IATI XML Import') || ', ' || quote_literal(E'IATI XML Import') || ') RETURNING id;' INTO t_id;
	

      RAISE NOTICE ' + Taxonomy id: %', t_id; 	

      -- Iterate over all the values in the xml file
      FOR codelist IN EXECUTE 'SELECT (xpath(''/codelist-item/code/text()'', node.xml))[1]::text AS "code" ' 
			    || ',(xpath(''/codelist-item/name/narrative/text()'', node.xml))[1]::text AS "name" '
			    || ',(xpath(''/codelist-item/description/narrative/text()'', node.xml))[1]::text AS "description" '
			    || 'FROM(SELECT unnest(xpath(''/codelist/codelist-items/codelist-item'', '|| quote_literal(iati._xml) ||'))::xml AS xml) AS node;' LOOP
        -- Add classification record
	EXECUTE 'INSERT INTO classification (taxonomy_id, _code, _name, _description, _iati_code, _iati_name, _iati_description, _created_by, _updated_by) VALUES( ' 
	|| t_id || ', ' ||quote_literal(codelist.code)|| ', ' || quote_literal(codelist.name)|| ', ' || coalesce(quote_literal(codelist.description),'NULL') || ', ' ||quote_literal(codelist.code)|| ', '
	|| quote_literal(codelist.name)|| ', ' || coalesce(quote_literal(codelist.description),'NULL') || ', '
	|| quote_literal(E'IATI XML Import') || ', ' || quote_literal(E'IATI XML Import') || ');';							
	RAISE NOTICE '    - Adding taxonomy classification:  %', codelist.name;				    
      END LOOP;
      
    -- has an assoicated codelist that must be loaded first
    ELSE
    RAISE NOTICE 'In the associated codelist codeset';
      -- check to see if the parent codelist is loaded
      SELECT INTO parent_taxonomy * FROM taxonomy WHERE _iati_codelist = codelist_category LIMIT 1;
      IF parent_taxonomy IS NULL THEN        
        -- the parent taxonomy must be loaded before procesing the related codelist, report error
        error_msg1 := 'This codelist has a category codelist (' || codelist_category || ') that must be loaded first.';
        UPDATE iati_import SET _error = error_msg1 WHERE id = iati.id;
        -- remove xml document
        UPDATE iati_import SET _xml = null WHERE id = iati.id;
      ELSE
        RAISE NOTICE 'Parent Taxonomy: %', parent_taxonomy._name;
        -- update the parent taxonomy's is_category flag to true
        UPDATE taxonomy SET _is_category = TRUE WHERE id = parent_taxonomy.id;

        -- the metadata for the taxonomy  
        FOR metadata IN EXECUTE 'SELECT (xpath(''/metadata/name/narrative/text()'', node.xml))[1]::text AS "name" ' 
			    || ',(xpath(''/metadata/description/narrative/text()'', node.xml))[1]::text AS "description" '
			    || 'FROM(SELECT unnest(xpath(''/codelist/metadata'', '|| quote_literal(iati._xml) ||'))::xml AS xml) AS node;' LOOP
        END LOOP;
      
        RAISE NOTICE ' + Adding the % to the database:', iati._type || ' for ' || metadata."name"; 
        RAISE NOTICE ' + Name: %', metadata."name";

        -- Add taxonomy record				
        EXECUTE 'INSERT INTO taxonomy (_name, _description, _iati_codelist, parent_id, _created_by, _updated_by) VALUES( ' 
	  || quote_literal(metadata."name") || ', ' || coalesce(quote_literal(trim(regexp_replace(metadata."description", '\s\s+|\t|\n|\r', ' ', 'g'))), 'NULL') || 
	  ', ' || quote_literal(iati._codelist) || ', ' || parent_taxonomy.id || ', ' || quote_literal(E'IATI XML Import') || ', ' || quote_literal(E'IATI XML Import') || ') RETURNING id;' INTO t_id;
	
        RAISE NOTICE ' + Taxonomy id: %', t_id; 	

        -- Iterate over all the values in the xml file
        FOR codelist IN EXECUTE 'SELECT (xpath(''/codelist-item/code/text()'', node.xml))[1]::text AS "code" ' 
			    || ',(xpath(''/codelist-item/name/narrative/text()'', node.xml))[1]::text AS "name" '
			    || ',(xpath(''/codelist-item/description/narrative/text()'', node.xml))[1]::text AS "description" '
			    || ',(xpath(''/codelist-item/category/text()'', node.xml))[1]::text AS "category" '
			    || 'FROM(SELECT unnest(xpath(''/codelist/codelist-items/codelist-item'', '|| quote_literal(iati._xml) ||'))::xml AS xml) AS node;' LOOP
          -- find the parent classification
          SELECT INTO parent_classification * FROM classification WHERE taxonomy_id = parent_taxonomy.id AND _iati_code = codelist."category" LIMIT 1;			    
          -- Add classification record
	  EXECUTE 'INSERT INTO classification (taxonomy_id, _code, _name, _description, _iati_code, _iati_name, _iati_description, parent_id, _created_by, _updated_by) VALUES( ' 
	    || t_id || ', ' ||quote_literal(codelist.code)|| ', ' || quote_literal(codelist.name)|| ', ' || coalesce(quote_literal(codelist.description),'NULL') || ', ' ||quote_literal(codelist.code)|| ', '
	    || quote_literal(codelist.name)|| ', ' || coalesce(quote_literal(codelist.description),'NULL') || ', '
	    || coalesce(parent_classification.id, NULL) ||  ', ' || quote_literal(E'IATI XML Import') || ', ' || quote_literal(E'IATI XML Import') || ');';							
	  RAISE NOTICE '    - Adding taxonomy classification:  %', codelist.name;				    
        END LOOP;
      END IF;
    END IF;    
  -- if the codelist is already loaded, update error message in table  
  ELSE
    -- once the iati code lists are entered they should be managed manually by the dba. This keeps the logic simple.
    -- In future releases we may add an updating process and support in the data model to track the multiple versions 
    -- of codelists. For now this feature is only intended to help implementers of PMT get the latest IATI codelists 
    -- loaded into their database quickly and easily without any understanding of the data model.
    UPDATE iati_import SET _error = 'The ' || iati._type || ' for ' || iati._codelist || ' already exists the database and will not be processed agian from this function.'
      WHERE id = iati_import_id;
    -- remove xml document
    UPDATE iati_import SET _xml = null WHERE id = iati_import_id;
  END IF;
  
  RETURN TRUE; 
   	   
EXCEPTION WHEN others THEN
    GET STACKED DIAGNOSTICS error_msg1 = MESSAGE_TEXT,
                          error_msg2 = PG_EXCEPTION_DETAIL,
                          error_msg3 = PG_EXCEPTION_HINT;
    RAISE NOTICE 'Internal Error - Contact your DBA with the following error message: (pmt_etl_iati_codelist) %', error_msg1;
    UPDATE iati_import SET _error = 'There was an unexpected error in the pmt_etl_iati_codelist function: ' || error_msg1
      WHERE id = iati_import_id;
    -- remove xml document
    --UPDATE iati_import SET _xml = null WHERE id = iati_import_id;
  RETURN FALSE;
END; 

$$ LANGUAGE 'plpgsql';

/******************************************************************
  pmt_etl_iati_activities_v201
  -- create new function to process the IATI activity xml documents
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_etl_iati_activities_v201(iati_import_id integer) RETURNS boolean AS $$
-- Extracts data from xml document, transforms the data to be PMT compatable and loads the
-- data into the PMT database. Function should only be called from the pmt_iati_evaluate 
-- trigger, which ensures proper usage of the function.
-- Parameters: iati_import_id (the iati_import id of the record to process)
DECLARE 
  a_id integer; -- the id of the activity created
  c_id integer; -- the id of a found classification
  o_id integer; -- the id of a found organization
  p_id integer; -- the id of the participation record created
  n_id integer; -- the id of the contact record created
  l_id integer; -- the id of the location record created
  f_id integer; -- the id of the financial record created
  iati record; -- the target iati_import record
  activity record; -- the activity record
  title record;	-- for iterating over multiple narratives
  description record;	-- for iterating over multiple narratives
  participant record; -- for iterating over multiple narratives
  activity_date record; -- for iterating over multiple narratives
  contact record; -- for iterating over multiple narratives
  location record; -- for iterating over multiple narratives
  sector record; -- for iterating over multiple narratives
  budget record; -- for iterating over multiple narratives
  disbursement record; -- for iterating over multiple narratives
  transaction record; -- for iterating over multiple narratives
  related_activity record; -- for iterating over multiple narratives
  data_group record; -- the data group record for this data load
  sector_vocab record; -- the sector vocabulary classification record for current sector
  org_role record; -- the organisation role classification for current participation org
  pt record; -- participation_taxonomy record
  ot record; -- organization_taxonomy record
  lat text; -- the latitude value for a location
  long text; -- the longitude value for a location
  first_name text; -- the parsed first name for a contact
  last_name text; -- the parsed last name for a contact
  current_value text; -- the current value of a field in question
  failed_activities integer; -- count of failed activities
  loaded_activities integer; -- count of loaded activities
  error text; -- single error message
  error_concat text; -- single error message concatenated
  error_msgs text[]; -- error messages collected through loading process
  error_msg1 text; -- error message for database execeptions
  error_msg2 text; -- error message for database execeptions
  error_msg3 text; -- error message for database execeptions
BEGIN  
  SELECT INTO iati * FROM iati_import WHERE id = iati_import_id;
  -- validate required information
  IF iati._data_group IS NULL OR iati._data_group = '' THEN
    RAISE NOTICE 'The data group was not validated during the workflow.';
    UPDATE iati_import SET _error = 'The data group field is null, but required for loading activities. An error has occurred in the workflow.' WHERE id = iati_import_id;
    -- remove xml document
    UPDATE iati_import SET _xml = null WHERE id = iati_import_id;
    RETURN FALSE;
  ELSE
    SELECT INTO data_group * FROM _taxonomy_classifications WHERE classification = iati._data_group AND taxonomy = 'Data Group';
    RAISE NOTICE 'The data group is: %', data_group;
  END IF;
  -- set counters
  loaded_activities:=0;
  failed_activities:=0;  
  -- loop through the activities 
  FOR activity IN SELECT (xpath('/iati-activity/iati-identifier/text()', node.xml))[1]::text AS "iati-identifier"
	,(xpath('/iati-activity/title/narrative', node.xml)) AS "titles"
	,(xpath('/iati-activity/description', node.xml)) AS "descriptions"
	,(xpath('/iati-activity/participating-org', node.xml)) AS "participants"
	,(xpath('/iati-activity/activity-status/@code', node.xml))[1]::text AS "activity-status"
	,(xpath('/iati-activity/activity-date', node.xml)) AS "activity-dates"
	,(xpath('/iati-activity/contact-info', node.xml)) AS "contacts"
	,(xpath('/iati-activity/activity-scope/@code', node.xml))[1]::text AS "activity-scope"
	,(xpath('/iati-activity/location', node.xml)) AS "locations"
	,(xpath('/iati-activity/sector', node.xml)) AS "sectors"
	,(xpath('/iati-activity/budget', node.xml)) AS "budgets"
	,(xpath('/iati-activity/planned-disbursement', node.xml)) AS "planned-disbursements"
	,(xpath('/iati-activity/transaction', node.xml)) AS "transactions"
	,(xpath('/iati-activity/related-activity', node.xml)) AS "related-activity"
	FROM(SELECT unnest(xpath('/iati-activities/iati-activity', _xml::xml))::xml AS xml FROM iati_import where id = $1) AS node LOOP
    a_id:= 0;
    
    /*************************************************************************************
       title
       IATI Rule: This element should occur once and only once (within each parent element)
       PMT Rule: This element is required to create a record in the PMT. Create activity
       and load title into _title.  Gather language taxonomy for field, if NOT english (en).
    *************************************************************************************/
    FOR title IN SELECT xpath('/narrative/text()', unnest(activity."titles")) as "title"
	,xpath('/narrative/@xml:lang', unnest(activity."titles")) as "language"  LOOP
      RAISE NOTICE '    +++++++ The activity "title": %', title."title"[1];
      -- create activity, if the activity has not been created yet and we have a title
      IF a_id = 0 AND (title."title" IS NOT NULL OR trim(title."title"[1]::text) <> '') THEN
        INSERT INTO activity (_title, data_group_id, iati_import_id, _created_by, _updated_by) 
		VALUES (trim(title."title"[1]::text), data_group.classification_id, iati.id, iati._created_by, iati._created_by) 
		RETURNING id INTO a_id;
	-- add the language taxonomy if the code is NOT en for english	
	IF trim(title."language"[1]::text) <> '' AND trim(title."language"[1]::text) <> 'en' AND trim(title."language"[1]::text) IS NOT NULL THEN
	  SELECT INTO c_id classification_id FROM _taxonomy_classifications WHERE _iati_codelist = 'Language' AND _iati_code = trim(title."language"[1]::text) LIMIT 1;
	  IF c_id IS NOT NULL THEN
	    INSERT INTO activity_taxonomy (activity_id, classification_id, _field) VALUES (a_id, c_id, '_title');
	  END IF;
	END IF;
      -- update the activity title, only if the language is english
      ELSIF a_id > 0 AND (trim(title."title"[1]::text) IS NOT NULL OR trim(title."title"[1]::text) <> '') THEN
        IF trim(title."language"[1]::text) = 'en' THEN
          EXECUTE 'UPDATE activity SET _title = ' || quote_literal(trim(title."title"[1]::text)) || ' WHERE id =' || a_id;
          -- remove language taxonomies if associated
          DELETE FROM activity_taxonomy WHERE activity_id = a_id AND _field = '_title' AND classification_id 
		IN (SELECT classification_id FROM _taxonomy_classifications WHERE _iati_codelist = 'Language');
        END IF;
      END IF;
    END LOOP;    
    -- if an activity wasn't created continue on
    IF a_id = 0 THEN
      failed_activities := failed_activities + 1;
      CONTINUE;
    ELSE
      loaded_activities:= loaded_activities + 1;
    END IF;
    /*************************************************************************************
       iati-identifier
       IATI Rule: This element should occur once and only once (within each parent element)
       PMT Rule: Load into activity._iati_identifier
    *************************************************************************************/  
    IF activity."iati-identifier" IS NOT NULL AND activity."iati-identifier" <> '' THEN
      RAISE NOTICE '    +++++++ The activity "iati-identifier": %', activity."iati-identifier";
      EXECUTE 'UPDATE activity SET _iati_identifier = ' || quote_literal(trim(activity."iati-identifier")) || ' WHERE id =' || a_id;
    END IF;
    /*************************************************************************************
       description
       IATI Rule: This element should occur at least once (within each parent element)
       PMT Rule: Load description into the activity table. The field  loaded depends on 
       type: 1=_description, 2=_objective, all others=_content. Gather language taxonomy
       for field, if NOT english (en).
    *************************************************************************************/      
    FOR description IN SELECT xpath('/description/@type', unnest(activity."descriptions")) as "type"
	,xpath('/description/narrative/text()', unnest(activity."descriptions")) as "description"
	,xpath('/description/narrative/@xml:lang', unnest(activity."descriptions")) as "language" LOOP
      RAISE NOTICE '    +++++++ The activity "description": %', description;       
      IF trim(description."description"[1]::text) IS NOT NULL AND trim(description."description"[1]::text) <> '' THEN
       -- activity table field is determined by type
        CASE (description."type"[1]::text)
          -- description
          WHEN '1' THEN
            -- get the current description value from the table
            SELECT INTO current_value _description::text FROM activity WHERE id = a_id;
            -- update the activity description if its empty
            IF current_value IS NULL OR current_value = '' THEN
              EXECUTE 'UPDATE activity SET _description = ' || quote_literal(trim(description."description"[1]::text)) || ' WHERE id =' || a_id;
              -- add the language taxonomy if the code is NOT en for english	
	      IF trim(description."language"[1]::text) <> '' AND trim(description."language"[1]::text) <> 'en' AND trim(description."language"[1]::text) IS NOT NULL THEN
	        SELECT INTO c_id classification_id FROM _taxonomy_classifications WHERE _iati_codelist = 'Language' AND _iati_code = trim(description."language"[1]::text) LIMIT 1;
	        IF c_id IS NOT NULL THEN
	          INSERT INTO activity_taxonomy (activity_id, classification_id, _field) VALUES (a_id, c_id, '_description');
	        END IF;
	      END IF;
            ELSE
              -- only update the description if the language is english
              IF trim(description."language"[1]::text) = 'en' THEN
		EXECUTE 'UPDATE activity SET _description = ' || quote_literal(trim(description."description"[1]::text)) || ' WHERE id =' || a_id;
		-- remove language taxonomies if associated
                DELETE FROM activity_taxonomy WHERE activity_id = a_id AND _field = '_description' AND classification_id 
			IN (SELECT classification_id FROM _taxonomy_classifications WHERE _iati_codelist = 'Language');
	      END IF;
            END IF;
          -- objective
          WHEN '2' THEN           
            -- get the current description value from the table
            SELECT INTO current_value _objective::text FROM activity WHERE id = a_id;
            -- update the activity description if its empty
            IF current_value IS NULL OR current_value = '' THEN
              EXECUTE 'UPDATE activity SET _objective = ' || quote_literal(trim(description."description"[1]::text)) || ' WHERE id =' || a_id;
              -- add the language taxonomy if the code is NOT en for english	
	      IF trim(description."language"[1]::text) <> '' AND trim(description."language"[1]::text) <> 'en' AND trim(description."language"[1]::text) IS NOT NULL THEN
	        SELECT INTO c_id classification_id FROM _taxonomy_classifications WHERE _iati_codelist = 'Language' AND _iati_code = trim(description."language"[1]::text) LIMIT 1;
	        IF c_id IS NOT NULL THEN
	          INSERT INTO activity_taxonomy (activity_id, classification_id, _field) VALUES (a_id, c_id, '_objective');
	        END IF;
	      END IF;
            ELSE
              -- only update the description if the language is english
              IF trim(description."language"[1]::text) = 'en' THEN
		EXECUTE 'UPDATE activity SET _objective = ' || quote_literal(trim(description."description"[1]::text)) || ' WHERE id =' || a_id;
		-- remove language taxonomies if associated
                DELETE FROM activity_taxonomy WHERE activity_id = a_id AND _field = '_objective' AND classification_id 
			IN (SELECT classification_id FROM _taxonomy_classifications WHERE _iati_codelist = 'Language');
	      END IF;
            END IF;
          -- content
          ELSE            
            -- get the current description value from the table
            SELECT INTO current_value _content::text FROM activity WHERE id = a_id;
            -- update the activity description if its empty
            IF current_value IS NULL OR current_value = '' THEN
              EXECUTE 'UPDATE activity SET _content = ' || quote_literal(trim(description."description"[1]::text)) || ' WHERE id =' || a_id;
              -- add the language taxonomy if the code is NOT en for english	
	      IF trim(description."language"[1]::text) <> '' AND trim(description."language"[1]::text) <> 'en' AND trim(description."language"[1]::text) IS NOT NULL THEN
	        SELECT INTO c_id classification_id FROM _taxonomy_classifications WHERE _iati_codelist = 'Language' AND _iati_code = trim(description."language"[1]::text) LIMIT 1;
	        IF c_id IS NOT NULL THEN
	          INSERT INTO activity_taxonomy (activity_id, classification_id, _field) VALUES (a_id, c_id, '_content');
	        END IF;
	      END IF;
            ELSE
              -- only update the description if the language is english
              IF trim(description."language"[1]::text) = 'en' THEN
		EXECUTE 'UPDATE activity SET _content = ' || quote_literal(trim(description."description"[1]::text)) || ' WHERE id =' || a_id;
		-- remove language taxonomies if associated
                DELETE FROM activity_taxonomy WHERE activity_id = a_id AND _field = '_content' AND classification_id 
			IN (SELECT classification_id FROM _taxonomy_classifications WHERE _iati_codelist = 'Language');
	      END IF;
            END IF;
        END CASE; 
      END IF;        
    END LOOP;
    /*************************************************************************************
       activity-date
       IATI Rule: This element should occur at least once (within each parent element)
       PMT Rule: Load dates into the activity table. The field loaded depends on 
       type: 1=_plan_start_date, 2=_start_date, 3=_plan_end_date & all others=_end_date. 
    *************************************************************************************/     
    FOR activity_date IN SELECT xpath('/activity-date/@iso-date', unnest(activity."activity-dates")) as "date"
       ,xpath('/activity-date/@type', unnest(activity."activity-dates")) as "type" LOOP
      RAISE NOTICE '    +++++++ The activity "activity_date": %', activity_date; 
      IF trim(activity_date."date"[1]::text) IS NOT NULL AND trim(activity_date."date"[1]::text) <> '' THEN
        CASE (activity_date."type"[1]::text)
          -- planned start date
          WHEN '1' THEN
	    EXECUTE 'UPDATE activity SET _plan_start_date = ' || quote_literal(trim(activity_date."date"[1]::text)) || ' WHERE id =' || a_id;
          -- actual start date
          WHEN '2' THEN           
            EXECUTE 'UPDATE activity SET _start_date = ' || quote_literal(trim(activity_date."date"[1]::text)) || ' WHERE id =' || a_id;
          -- planned end date
          WHEN '3' THEN   
            EXECUTE 'UPDATE activity SET _plan_end_date = ' || quote_literal(trim(activity_date."date"[1]::text)) || ' WHERE id =' || a_id;        
          -- actual end date
          ELSE            
            EXECUTE 'UPDATE activity SET _end_date = ' || quote_literal(trim(activity_date."date"[1]::text)) || ' WHERE id =' || a_id;
        END CASE; 
      END IF;      
    END LOOP;
    /*************************************************************************************
       activity-scope
       IATI Rule: This element should occur no more than once (within each parent element)
       PMT Rule: Load as activity taxonomy. Taxonomy = Activity Scope
    *************************************************************************************/ 
    IF trim(activity."activity-scope") <> '' AND trim(activity."activity-scope") IS NOT NULL THEN
      RAISE NOTICE '    +++++++ The activity "activity-scope": %', activity."activity-scope";
      SELECT INTO c_id classification_id FROM _taxonomy_classifications WHERE _iati_codelist = 'ActivityScope' 
		AND _iati_code = trim(activity."activity-scope") LIMIT 1;
      IF c_id IS NOT NULL THEN
        INSERT INTO activity_taxonomy (activity_id, classification_id, _field) VALUES (a_id, c_id, 'id');
      END IF;
    END IF;    
    /*************************************************************************************
       activity-status
       IATI Rule: This element should occur once and only once (within each parent element)
       PMT Rule: Load as activity taxonomy. Taxonomy = Activity Status
    *************************************************************************************/ 
    IF trim(activity."activity-status") <> '' AND trim(activity."activity-status") IS NOT NULL THEN
      RAISE NOTICE '    +++++++ The activity "activity-status": %', activity."activity-status"; 
      SELECT INTO c_id classification_id FROM _taxonomy_classifications WHERE _iati_codelist = 'ActivityStatus' 
		AND _iati_code = trim(activity."activity-status") LIMIT 1;
      IF c_id IS NOT NULL THEN
        INSERT INTO activity_taxonomy (activity_id, classification_id, _field) VALUES (a_id, c_id, 'id');
      END IF;
    END IF;
    /*************************************************************************************
       sector
       IATI Rule: This element may occur any number of times
       PMT Rule: Load as activity taxonomy.Taxonomy is Sector or Sector Category based on 
       Sector Vocabulary taxonomy in sector-vocab.
    *************************************************************************************/ 
    FOR sector IN SELECT  xpath('/sector/@code', unnest(activity."sectors")) as "sector-code"  
	,xpath('/sector/@vocabulary', unnest(activity."sectors")) as "sector-vocab"  
	,xpath('/sector/@percent', unnest(activity."sectors")) as "sector-percent" LOOP
      RAISE NOTICE '    +++++++ The activity "sector": %', sector; 
      -- add sector taxonomy, if code exsits
      IF trim(sector."sector-code"[1]::text) IS NOT NULL AND trim(sector."sector-code"[1]::text) <> '' THEN
        -- if vocab exists, look it up
        IF trim(sector."sector-vocab"[1]::text) IS NOT NULL AND trim(sector."sector-vocab"[1]::text) <> '' THEN
          -- determine which taxonomy to use  
          SELECT INTO sector_vocab * FROM _taxonomy_classifications WHERE _iati_codelist = 'SectorVocabulary' 
		AND _iati_code = trim(sector."sector-vocab"[1]::text) LIMIT 1;
          IF sector_vocab._iati_code IS NOT NULL THEN
            CASE (sector_vocab._iati_code)
              -- Sector
              WHEN '1' THEN
                SELECT INTO c_id classification_id FROM _taxonomy_classifications WHERE _iati_codelist = 'Sector' 
		    AND _iati_code = trim(sector."sector-code"[1]::text) LIMIT 1;
                IF c_id IS NOT NULL THEN
                  INSERT INTO activity_taxonomy (activity_id, classification_id, _field) VALUES (a_id, c_id, 'id');
                END IF;
              -- Sector Category
              WHEN '2' THEN
                SELECT INTO c_id classification_id FROM _taxonomy_classifications WHERE _iati_codelist = 'SectorCategory' 
    		AND _iati_code = trim(sector."sector-code"[1]::text) LIMIT 1;
                IF c_id IS NOT NULL THEN
                  INSERT INTO activity_taxonomy (activity_id, classification_id, _field) VALUES (a_id, c_id, 'id');
                END IF;
              -- Not Supported
                  ELSE
               -- record error
               error:= 'The Sector Vocabulary "'|| sector_vocab.classification || '" is not supported. ';
               IF  error_msgs @> array[error] THEN
               ELSE
                 error_msgs:= array_append(error_msgs, error);
               END IF;            
            END CASE;
          -- no matching code, try sector
          ELSE
            SELECT INTO c_id classification_id FROM _taxonomy_classifications WHERE _iati_codelist = 'Sector' 
		    AND _iati_code = trim(sector."sector-code"[1]::text) LIMIT 1;
            IF c_id IS NOT NULL THEN
              INSERT INTO activity_taxonomy (activity_id, classification_id, _field) VALUES (a_id, c_id, 'id');
            END IF;
          END IF;
        -- if vocab is omitted, assume DAC 5 (Sector)
        ELSE
          SELECT INTO c_id classification_id FROM _taxonomy_classifications WHERE _iati_codelist = 'Sector' 
		AND _iati_code = trim(sector."sector-code"[1]::text) LIMIT 1;
          IF c_id IS NOT NULL THEN
            INSERT INTO activity_taxonomy (activity_id, classification_id, _field) VALUES (a_id, c_id, 'id');
          END IF;
        END IF;
      END IF;     
    END LOOP;
    /*************************************************************************************
       participant-org
       IATI Rule: This element should occur at least once (within each parent element)
       PMT Rule: Load as participation. Add organization if not found in the PMT. Participation
       taxonomy is collected from role for Organisation Role. The role attribute is required.
    *************************************************************************************/ 
    FOR participant IN SELECT xpath('/participating-org/@role', unnest(activity."participants")) as "role"
       ,xpath('/participating-org/@type', unnest(activity."participants")) as "type"
       ,xpath('/participating-org/narrative/@xml:lang', unnest(activity."participants")) as "language"
       ,xpath('/participating-org/narrative/text()', unnest(activity."participants")) as "participant" LOOP
      RAISE NOTICE '    +++++++ The activity "participants": %', participant; 
      -- if there is an organization name in the narrative element continue
      IF trim(participant."participant"[1]::text) IS NOT NULL AND trim(participant."participant"[1]::text) <> '' THEN
        -- lookup the organisation role
        SELECT INTO org_role * FROM _taxonomy_classifications WHERE _iati_codelist = 'OrganisationRole' 
		AND _iati_code = trim(participant."role"[1]::text) LIMIT 1;       	
        -- role attribute is require to load organization participation
        IF org_role.classification_id IS NOT NULL THEN
          -- lookup organization
          SELECT INTO o_id id FROM organization WHERE lower(_name) = lower(trim(participant."participant"[1]::text)) ORDER BY id LIMIT 1;
          -- create the organization record, if it doesnt exist
          IF o_id IS NULL THEN
            INSERT INTO organization (_name, iati_import_id, _created_by, _updated_by) VALUES (trim(participant."participant"[1]::text), 
		iati.id, iati._created_by, iati._created_by) RETURNING id INTO o_id;
          END IF;  
          -- lookup organisation type
          SELECT INTO c_id classification_id FROM _taxonomy_classifications WHERE _iati_codelist = 'OrganisationType' 
		AND _iati_code = trim(participant."type"[1]::text) LIMIT 1;
	  SELECT INTO ot * FROM organization_taxonomy WHERE organization_id = o_id AND classification_id = c_id AND _field = 'id' LIMIT 1;	
	  -- add organisation type taxonomy if it doesnt exist
	  IF c_id IS NOT NULL AND ot.organization_id IS NULL THEN
	    INSERT INTO organization_taxonomy (organization_id, classification_id, _field) VALUES (o_id, c_id, 'id');
	  END IF;
          -- add the participation record if it doesnt exist
          SELECT INTO p_id id FROM participation WHERE activity_id = a_id AND organization_id = o_id LIMIT 1;
          IF p_id IS NULL THEN
            INSERT INTO participation (activity_id, organization_id, _created_by, _updated_by) 
		VALUES (a_id, o_id, quote_literal(iati._created_by), quote_literal(iati._created_by)) RETURNING id INTO p_id;
	  END IF;
	  -- add organisation role taxonomy if it doesnt exist
	  SELECT INTO pt * FROM participation_taxonomy WHERE participation_id = p_id AND classification_id = org_role.classification_id AND _field = 'id' LIMIT 1;
	  IF pt IS NULL THEN
	    INSERT INTO participation_taxonomy (participation_id, classification_id, _field) VALUES (p_id, org_role.classification_id, 'id');
	  END IF;
	ELSE
	  RAISE NOTICE 'Org role was not found!! %', trim(participant."role"[1]::text)|| org_role;
	  -- record error
           error:= 'A participant was not loaded because the role attribute was not included on the participating-org element. ';
           IF  error_msgs @> array[error] THEN
           ELSE
             error_msgs:= array_append(error_msgs, error);
           END IF; 
        END IF;
      END IF;
    END LOOP;  
    /*************************************************************************************
       contact-info
       IATI Rule: This element may occur any number of times
       PMT Rule: Load as contact. Requires person-name.
    *************************************************************************************/      
    FOR contact IN SELECT (xpath('/contact-info/organisation/narrative/text()', unnest(activity."contacts")))[1] as "organization"       
	,(xpath('/contact-info/person-name/narrative/text()', unnest(activity."contacts")))[1] as "name"       
	,(xpath('/contact-info/job-title/narrative/text()', unnest(activity."contacts")))[1] as "title"  
	,(xpath('/contact-info/telephone/text()', unnest(activity."contacts")))[1] as "telephone"  
	,(xpath('/contact-info/email/text()', unnest(activity."contacts")))[1] as "email"  
	,(xpath('/contact-info/website/text()', unnest(activity."contacts")))[1] as "website" LOOP
      RAISE NOTICE '    +++++++ The activity "contact": %', contact; 
      -- if there is an organization name in the narrative element continue
      IF trim(contact."name"::text) IS NOT NULL AND trim(contact."name"::text) <> '' THEN
        n_id := null;
        -- parse the first and last names
        IF (position(' ' IN trim(contact."name"::text)) > 0) THEN
          first_name := substring(trim(contact."name"::text) from 1 for position(' ' IN trim(contact."name"::text)));
          last_name := substring(trim(contact."name"::text) from position(' ' IN trim(contact."name"::text))+1 for char_length(trim(contact."name"::text)));                   
        ELSE
          -- there is no space so just, set the contact name to the first name          
          first_name := trim(contact."name"::text);
          last_name := null;
        END IF;       
        -- check to see if the contact exists
        SELECT INTO n_id id FROM contact WHERE lower(_last_name) = lower(last_name) AND lower(_first_name) = lower(first_name);
        -- the contact record does not exist, create it
        IF n_id IS NULL THEN
	   -- create and return the contact record id    
          INSERT INTO contact (_first_name, _last_name, iati_import_id, _created_by, _updated_by) 
		VALUES (first_name, last_name, iati.id, iati._created_by, iati._created_by) 
		RETURNING id INTO n_id;
	  -- update contact with organization if avaiable
	  IF trim(contact."organization"::text) IS NOT NULL AND trim(contact."organization"::text) <> '' THEN 
	    SELECT INTO o_id id FROM organization WHERE lower(_name) = lower(trim(contact."organization"::text));
	    -- create the organization if it doesnt exist
	    IF o_id IS NULL THEN
              INSERT INTO organization (_name, iati_import_id, _created_by, _updated_by) VALUES (trim(contact."organization"::text), 
		iati.id, iati._created_by, iati._created_by) RETURNING id INTO o_id;
            END IF;
            -- add the organization to the contact
	    IF o_id IS NOT NULL THEN
	      UPDATE contact SET organization_id = o_id WHERE id = n_id;
	    END IF;
	  END IF;
	  -- update contact with title if avialable
	  IF trim(contact."title"::text) IS NOT NULL AND trim(contact."title"::text) <> '' THEN 
	    UPDATE contact SET _title = trim(contact."title"::text) WHERE id = n_id;
	  END IF;
	  -- update contact with direct phone if avialable
	  IF trim(contact."telephone"::text) IS NOT NULL AND trim(contact."telephone"::text) <> '' THEN 
	    UPDATE contact SET _direct_phone = trim(contact."telephone"::text) WHERE id = n_id;
	  END IF;
	  -- update contact with email if avialable
	  IF trim(contact."email"::text) IS NOT NULL AND trim(contact."email"::text) <> '' THEN 
	    UPDATE contact SET _email = trim(contact."email"::text) WHERE id = n_id;
	  END IF;
	  -- update contact with url if avialable
	  IF trim(contact."website"::text) IS NOT NULL AND trim(contact."website"::text) <> '' THEN 
	    UPDATE contact SET _url = trim(contact."website"::text) WHERE id = n_id;
	  END IF;
	END IF;	        
	-- connect to activity
	INSERT INTO activity_contact(activity_id, contact_id) VALUES (a_id, n_id);
      END IF;
    END LOOP; 
    /*************************************************************************************
       location
       IATI Rule: This element may occur any number of times
       PMT Rule: Load as location. 
    *************************************************************************************/     
    FOR location IN SELECT xpath('/location/location-reach/@code', unnest(activity."locations")) as "location-reach"  
           ,xpath('/location/location-id/@vocabulary', unnest(activity."locations")) as "location-id-vocab"
	   ,xpath('/location/location-id/@code', unnest(activity."locations")) as "location-id-code"	   
	   ,xpath('/location/name/narrative/text()', unnest(activity."locations")) as "name"
	   ,xpath('/location/name/narrative/@xml:lang', unnest(activity."locations")) as "name_lang"
	   ,xpath('/location/description/narrative/text()', unnest(activity."locations")) as "description"
	   ,xpath('/location/description/narrative/@xml:lang', unnest(activity."locations")) as "description_lang"
	   ,xpath('/location/administrative/@code', unnest(activity."locations")) as "administrative-code"
	   ,xpath('/location/administrative/@level', unnest(activity."locations")) as "administrative-level"
	   ,xpath('/location/administrative/@vocabulary', unnest(activity."locations")) as "administrative-vocab"
	   ,xpath('/location/point/@srsName', unnest(activity."locations")) as "point-srs"
	   ,xpath('/location/point/pos/text()', unnest(activity."locations")) as "point"
	   ,xpath('/location/exactness/@code', unnest(activity."locations")) as "exactness"
	   ,xpath('/location/location-class/@code', unnest(activity."locations")) as "location-class"
	   ,xpath('/location/feature-designation/@code', unnest(activity."locations")) as "feature-designation" LOOP
     RAISE NOTICE '    +++++++ The activity "location": %', location; 
     -- create a location associated to the activity
     INSERT INTO location(activity_id, _created_by, _updated_by) VALUES (a_id, iati._created_by, iati._created_by) RETURNING id INTO l_id;
     -- add geographic location reach taxonomy if exists
     IF trim(location."location-reach"[1]::text) IS NOT NULL AND trim(location."location-reach"[1]::text) <> '' THEN
       -- lookup geographic location reach
       SELECT INTO c_id classification_id FROM _taxonomy_classifications WHERE _iati_codelist = 'GeographicLocationReach' 
		AND _iati_code = trim(location."location-reach"[1]::text) LIMIT 1;
       IF c_id IS NOT NULL THEN
         INSERT INTO location_taxonomy (location_id, classification_id, _field) VALUES (l_id, c_id, 'id');
       END IF;
     END IF;
     -- add geographic vocabulary taxonomy if exists
     IF trim(location."location-id-vocab"[1]::text) IS NOT NULL AND trim(location."location-id-vocab"[1]::text) <> '' AND
        trim(location."location-id-code"[1]::text) IS NOT NULL AND trim(location."location-id-code"[1]::text) <> '' THEN
       -- lookup geographic vocabulary
       SELECT INTO c_id classification_id FROM _taxonomy_classifications WHERE _iati_codelist = 'GeographicVocabulary' 
		AND _iati_code = trim(location."location-id-vocab"[1]::text) LIMIT 1;
       IF c_id IS NOT NULL THEN
         INSERT INTO location_taxonomy (location_id, classification_id, _field) VALUES (l_id, c_id, 'id');
         UPDATE location SET _geographic_id = (location."location-id-code"[1]::text) WHERE id = l_id;
       END IF;
     END IF;
     -- add location title, if it exists
     IF trim(location."name"[1]::text) IS NOT NULL AND trim(location."name"[1]::text) <> '' THEN
       -- get the current title value from the table
       SELECT INTO current_value _title::text FROM location WHERE id = l_id;
       -- update the location title if its empty
       IF current_value IS NULL OR current_value = '' THEN
         UPDATE location SET _title = trim(location."name"[1]::text) WHERE id = l_id;
         -- add the language taxonomy if the code is NOT 'en' for english	
	 IF trim(location."name_lang"[1]::text) <> 'en' AND trim(location."name_lang"[1]::text) IS NOT NULL THEN
	   SELECT INTO c_id classification_id FROM _taxonomy_classifications WHERE _iati_codelist = 'Language' 
	     AND _iati_code = trim(location."name_lang"[1]::text) LIMIT 1;
	   IF c_id IS NOT NULL THEN
	     INSERT INTO location_taxonomy (location_id, classification_id, _field) VALUES (l_id, c_id, '_title');
	   END IF;
	 END IF;
       ELSE
         -- only update the description if the language is english
         IF trim(location."name_lang"[1]::text) = 'en' THEN
	   UPDATE location SET _title = trim(location."name"[1]::text) WHERE id = l_id;
           -- remove language taxonomies if associated
           DELETE FROM location_taxonomy WHERE location_id = l_id AND _field = '_title' AND classification_id 
		IN (SELECT classification_id FROM _taxonomy_classifications WHERE _iati_codelist = 'Language');
	 END IF;
       END IF;
     END IF;
     -- add location description, if it exists
     IF trim(location."description"[1]::text) IS NOT NULL AND trim(location."description"[1]::text) <> '' THEN
       -- get the current description value from the table
       SELECT INTO current_value _description::text FROM location WHERE id = l_id;
       -- update the location description if its empty
       IF current_value IS NULL OR current_value = '' THEN
         UPDATE location SET _description = trim(location."description"[1]::text) WHERE id = l_id;
         -- add the language taxonomy if the code is NOT 'en' for english	
	 IF trim(location."description_lang"[1]::text) <> 'en' AND trim(location."description_lang"[1]::text) IS NOT NULL THEN
	   SELECT INTO c_id classification_id FROM _taxonomy_classifications WHERE _iati_codelist = 'Language' 
	     AND _iati_code = trim(location."description_lang"[1]::text) LIMIT 1;
	   IF c_id IS NOT NULL THEN
	     INSERT INTO location_taxonomy (location_id, classification_id, _field) VALUES (l_id, c_id, '_description');
	   END IF;
	 END IF;
       ELSE
         -- only update the description if the language is english
         IF trim(location."description_lang"[1]::text) = 'en' THEN
	   UPDATE location SET _description = trim(location."description"[1]::text) WHERE id = l_id;
           -- remove language taxonomies if associated
           DELETE FROM location_taxonomy WHERE location_id = l_id AND _field = '_description' AND classification_id 
		IN (SELECT classification_id FROM _taxonomy_classifications WHERE _iati_codelist = 'Language');
	 END IF;
       END IF;
     END IF;
     -- add location administrative boundary information, if it exists
     IF trim(location."administrative-vocab"[1]::text) IS NOT NULL AND trim(location."administrative-vocab"[1]::text) <> '' THEN
        -- lookup geographic vocabulary
       SELECT INTO c_id classification_id FROM _taxonomy_classifications WHERE _iati_codelist = 'GeographicVocabulary' 
		AND _iati_code = trim(location."administrative-vocab"[1]::text) LIMIT 1;
       IF c_id IS NOT NULL THEN 
         -- remove geographic vocabulary taxonomies if associated
         DELETE FROM location_taxonomy WHERE location_id = l_id AND _field = 'id' AND classification_id 
		IN (SELECT classification_id FROM _taxonomy_classifications WHERE _iati_codelist = 'GeographicVocabulary');
	 -- add the geographic vocabulary taxonomy
	 INSERT INTO location_taxonomy (location_id, classification_id, _field) VALUES (l_id, c_id, 'id');         
       END IF;
       -- add the location geographic boundary code
       IF trim(location."administrative-code"[1]::text) IS NOT NULL AND trim(location."administrative-code"[1]::text) <> '' THEN
         UPDATE location SET _geographic_id = (location."administrative-code"[1]::text) WHERE id = l_id;
       END IF;
       -- add the location geographic level
       IF trim(location."administrative-level"[1]::text) IS NOT NULL AND trim(location."administrative-level"[1]::text) <> '' THEN
         UPDATE location SET _geographic_level = (location."administrative-level"[1]::text) WHERE id = l_id;
       END IF;
     END IF;
     -- add location, if it exists
     IF trim(location."point"[1]::text) IS NOT NULL AND trim(location."point"[1]::text) <> '' THEN
       lat := substring((location."point"[1]::text) from 0 for position(' ' in (location."point"[1]::text)));
       long := substring((location."point"[1]::text) from position(' ' in (location."point"[1]::text)) for length((location."point"[1]::text)));
       RAISE NOTICE 'Long & Lat: %', long || ' ' || lat;
       UPDATE location SET _point = ST_PointFromText('POINT(' || long || ' ' || lat || ')', 4326) WHERE id = l_id;
     END IF;
     -- add geographic exactness taxonomy if exists
     IF trim(location."exactness"[1]::text) IS NOT NULL AND trim(location."exactness"[1]::text) <> '' THEN
       -- lookup geographic exactness
       SELECT INTO c_id classification_id FROM _taxonomy_classifications WHERE _iati_codelist = 'GeographicExactness' 
		AND _iati_code = trim(location."exactness"[1]::text) LIMIT 1;
       IF c_id IS NOT NULL THEN
         INSERT INTO location_taxonomy (location_id, classification_id, _field) VALUES (l_id, c_id, 'id');
       END IF;
     END IF;
     -- add geographic location class taxonomy if exists
     IF trim(location."location-class"[1]::text) IS NOT NULL AND trim(location."location-class"[1]::text) <> '' THEN
       -- lookup geographic location class
       SELECT INTO c_id classification_id FROM _taxonomy_classifications WHERE _iati_codelist = 'GeographicLocationClass' 
		AND _iati_code = trim(location."location-class"[1]::text) LIMIT 1;
       IF c_id IS NOT NULL THEN
         INSERT INTO location_taxonomy (location_id, classification_id, _field) VALUES (l_id, c_id, 'id');
       END IF;
     END IF;
     -- add geographic location reach taxonomy if exists
     IF trim(location."location-reach"[1]::text) IS NOT NULL AND trim(location."location-reach"[1]::text) <> '' THEN
       -- lookup geographic location reach
       SELECT INTO c_id classification_id FROM _taxonomy_classifications WHERE _iati_codelist = 'GeographicLocationReach' 
		AND _iati_code = trim(location."location-reach"[1]::text) LIMIT 1;
       IF c_id IS NOT NULL THEN
         INSERT INTO location_taxonomy (location_id, classification_id, _field) VALUES (l_id, c_id, 'id');
       END IF;
     END IF;
     -- add location type taxonomy if exists
     IF trim(location."feature-designation"[1]::text) IS NOT NULL AND trim(location."feature-designation"[1]::text) <> '' THEN
       -- lookup location type
       SELECT INTO c_id classification_id FROM _taxonomy_classifications WHERE _iati_codelist = 'LocationType' 
		AND _iati_code = trim(location."feature-designation"[1]::text) LIMIT 1;
       IF c_id IS NOT NULL THEN
         INSERT INTO location_taxonomy (location_id, classification_id, _field) VALUES (l_id, c_id, 'id');
       END IF;
     END IF;
   END LOOP;
   /*************************************************************************************
       budget
       IATI Rule: This element may occur any number of times
       PMT Rule: Load as financial record. 
    *************************************************************************************/     
    FOR budget IN SELECT  xpath('/budget/@type', unnest(activity."budgets")) as "budget-type"  
	,xpath('/budget/period-start/@iso-date', unnest(activity."budgets")) as "budget-start"  
	,xpath('/budget/period-end/@iso-date', unnest(activity."budgets")) as "budget-end"  
	,xpath('/budget/value/@currency', unnest(activity."budgets")) as "budget-currency"
	,xpath('/budget/value/text()', unnest(activity."budgets")) as "budget-value" LOOP
      RAISE NOTICE '    +++++++ The activity "budget": %', budget;	
      -- add financial record if there is a value
      IF trim(budget."budget-value"[1]::text) IS NOT NULL AND trim(budget."budget-value"[1]::text) <> '' 
		AND (SELECT * FROM pmt_isnumeric(trim(budget."budget-value"[1]::text))) THEN
        INSERT INTO financial (activity_id, _amount, _created_by, _updated_by) 
		VALUES (a_id, ROUND(CAST(replace(trim(budget."budget-value"[1]::text), ',', '') as numeric), 2), 
		iati._created_by, iati._created_by) RETURNING id INTO f_id;
	-- add financial start date, if exists
	IF trim(budget."budget-start"[1]::text) IS NOT NULL AND trim(budget."budget-start"[1]::text) <> '' THEN	
	  EXECUTE 'UPDATE financial SET _start_date = ' || coalesce(quote_literal(trim(budget."budget-start"[1]::text)), 'NULL') ||
		' WHERE id = ' || f_id;
	END IF;
	-- add financial end date, if exists
	IF trim(budget."budget-end"[1]::text) IS NOT NULL AND trim(budget."budget-end"[1]::text) <> '' THEN	
	  EXECUTE 'UPDATE financial SET _end_date = ' || coalesce(quote_literal(trim(budget."budget-end"[1]::text)), 'NULL') ||
		' WHERE id = ' || f_id;
	END IF;
	-- add financial currency, if exists
	IF trim(budget."budget-currency"[1]::text) IS NOT NULL AND trim(budget."budget-currency"[1]::text) <> '' AND 
		trim(budget."budget-currency"[1]::text) <> 'USD' AND trim(budget."budget-currency"[1]::text) <> 'USN' AND
		trim(budget."budget-currency"[1]::text) <> 'USS' THEN
	  -- lookup currency
          SELECT INTO c_id classification_id FROM _taxonomy_classifications WHERE _iati_codelist = 'Currency' 
		AND _iati_code = trim(budget."budget-currency"[1]::text) LIMIT 1;
          IF c_id IS NOT NULL THEN
            INSERT INTO financial_taxonomy (financial_id, classification_id, _field) VALUES (f_id, c_id, 'id');
          END IF;
	END IF;	
      END IF;
    END LOOP;
    /*************************************************************************************
       planned-disbursement
       IATI Rule: This element may occur any number of times
       PMT Rule: Load as financial record. 
    *************************************************************************************/  
    FOR disbursement IN SELECT  xpath('/planned-disbursement/@type', unnest(activity."planned-disbursements")) as "disbursement-type"  
	,xpath('/planned-disbursement/period-start/@iso-date', unnest(activity."planned-disbursements")) as "disbursement-start"  
	,xpath('/planned-disbursement/period-end/@iso-date', unnest(activity."planned-disbursements")) as "disbursement-end"  
	,xpath('/planned-disbursement/value/@currency', unnest(activity."planned-disbursements")) as "disbursement-currency"
	,xpath('/planned-disbursement/value/text()', unnest(activity."planned-disbursements")) as "disbursement-value" LOOP
      RAISE NOTICE '    +++++++ The activity "disbursement": %', disbursement;
      -- add financial record if there is a value
      IF trim(disbursement."disbursement-value"[1]::text) IS NOT NULL AND trim(disbursement."disbursement-value"[1]::text) <> '' 
		AND (SELECT * FROM pmt_isnumeric(trim(disbursement."disbursement-value"[1]::text))) THEN
        INSERT INTO financial (activity_id, _amount, _created_by, _updated_by) 
		VALUES (a_id, ROUND(CAST(replace(trim(disbursement."disbursement-value"[1]::text), ',', '') as numeric), 2), 
		iati._created_by, iati._created_by) RETURNING id INTO f_id;
	-- add financial start date, if exists
	IF trim(disbursement."disbursement-start"[1]::text) IS NOT NULL AND trim(disbursement."disbursement-start"[1]::text) <> '' THEN	
	  EXECUTE 'UPDATE financial SET _start_date = ' || coalesce(quote_literal(trim(disbursement."disbursement-start"[1]::text)), 'NULL') ||
		' WHERE id = ' || f_id;
	END IF;
	-- add financial end date, if exists
	IF trim(disbursement."disbursement-end"[1]::text) IS NOT NULL AND trim(disbursement."disbursement-end"[1]::text) <> '' THEN	
	  EXECUTE 'UPDATE financial SET _end_date = ' || coalesce(quote_literal(trim(disbursement."disbursement-end"[1]::text)), 'NULL') ||
		' WHERE id = ' || f_id;
	END IF;	
	-- add financial currency, if exists
	IF trim(disbursement."disbursement-currency"[1]::text) IS NOT NULL AND trim(disbursement."disbursement-currency"[1]::text) <> '' AND 
		trim(disbursement."disbursement-currency"[1]::text) <> 'USD' AND trim(disbursement."disbursement-currency"[1]::text) <> 'USN' AND
		trim(disbursement."disbursement-currency"[1]::text) <> 'USS' THEN
	  -- lookup currency
          SELECT INTO c_id classification_id FROM _taxonomy_classifications WHERE _iati_codelist = 'Currency' 
		AND _iati_code = trim(disbursement."disbursement-currency"[1]::text) LIMIT 1;
          IF c_id IS NOT NULL THEN
            INSERT INTO financial_taxonomy (financial_id, classification_id, _field) VALUES (f_id, c_id, 'id');
          END IF;
	END IF;	
      END IF;
    END LOOP;
    /*************************************************************************************
       transaction
       IATI Rule: This element may occur any number of times
       PMT Rule: Load as financial record. 
    *************************************************************************************/
    FOR transaction IN SELECT  xpath('/transaction/transaction-type/@code', unnest(activity."transactions")) as "transaction-type"  
	,xpath('/transaction/transaction-date/@iso-date', unnest(activity."transactions")) as "transaction-date"    
	,xpath('/transaction/value/@currency', unnest(activity."transactions")) as "transaction-currency"
	,xpath('/transaction/value/text()', unnest(activity."transactions")) as "transaction-value" 
	,xpath('/transaction/finance-type/@code', unnest(activity."transactions")) as "finance-type"  
	,xpath('/transaction/sector/@code', unnest(activity."transactions")) as "sector-code"  
	,xpath('/transaction/sector/@vocabulary', unnest(activity."transactions")) as "sector-vocab" 
	,xpath('/transaction/provider-org/narrative/text()', unnest(activity."transactions")) as "provider-org" 
	,xpath('/transaction/receiver-org/narrative/text()', unnest(activity."transactions")) as "receiver-org" LOOP
      RAISE NOTICE '    +++++++ The activity "transaction": %', transaction;
      -- add financial record, if there is a value
      IF trim(transaction."transaction-value"[1]::text) IS NOT NULL AND trim(transaction."transaction-value"[1]::text) <> '' 
		AND (SELECT * FROM pmt_isnumeric(trim(transaction."transaction-value"[1]::text))) THEN
        INSERT INTO financial (activity_id, _amount, _created_by, _updated_by) 
		VALUES (a_id, ROUND(CAST(replace(trim(transaction."transaction-value"[1]::text), ',', '') as numeric), 2), 
		iati._created_by, iati._created_by) RETURNING id INTO f_id;
	-- add financial start and end date, if exists
	IF trim(transaction."transaction-date"[1]::text) IS NOT NULL AND trim(transaction."transaction-date"[1]::text) <> '' THEN	
	  EXECUTE 'UPDATE financial SET _start_date = ' || coalesce(quote_literal(trim(transaction."transaction-date"[1]::text)), 'NULL') ||
		', _end_date = ' || coalesce(quote_literal(trim(transaction."transaction-date"[1]::text)), 'NULL') || ' WHERE id = ' || f_id;
	END IF;	
	-- add currency taxonomy, if NOT US Dollar (USD, USN, USS)
	IF trim(transaction."transaction-currency"[1]::text) IS NOT NULL AND trim(transaction."transaction-currency"[1]::text) <> '' AND
		trim(transaction."transaction-currency"[1]::text) <> 'USD' AND trim(transaction."transaction-currency"[1]::text) <> 'USN' AND
		trim(transaction."transaction-currency"[1]::text) <> 'USS' THEN
	  -- lookup currency
          SELECT INTO c_id classification_id FROM _taxonomy_classifications WHERE _iati_codelist = 'Currency' 
		AND _iati_code = trim(transaction."transaction-currency"[1]::text) LIMIT 1;
          IF c_id IS NOT NULL THEN
            INSERT INTO financial_taxonomy (financial_id, classification_id, _field) VALUES (f_id, c_id, 'id');
          END IF;
	END IF;
	-- add finance type, if exists
	IF trim(transaction."finance-type"[1]::text) IS NOT NULL AND trim(transaction."finance-type"[1]::text) <> '' THEN
	  -- lookup finance type
          SELECT INTO c_id classification_id FROM _taxonomy_classifications WHERE _iati_codelist = 'FinanceType' 
		AND _iati_code = trim(transaction."finance-type"[1]::text) LIMIT 1;
          IF c_id IS NOT NULL THEN
            INSERT INTO financial_taxonomy (financial_id, classification_id, _field) VALUES (f_id, c_id, 'id');
          END IF;
	END IF;
	-- add finance transaction type, if exists
	IF trim(transaction."transaction-type"[1]::text) IS NOT NULL AND trim(transaction."transaction-type"[1]::text) <> '' THEN
	  -- lookup finance transaction type
          SELECT INTO c_id classification_id FROM _taxonomy_classifications WHERE _iati_codelist = 'TransactionType' 
		AND _iati_code = trim(transaction."transaction-type"[1]::text) LIMIT 1;
          IF c_id IS NOT NULL THEN
            INSERT INTO financial_taxonomy (financial_id, classification_id, _field) VALUES (f_id, c_id, 'id');
          END IF;
	END IF;
	-- update finance with provider organization if avaiable
	IF trim(transaction."provider-org"[1]::text) IS NOT NULL AND trim(transaction."provider-org"[1]::text) <> '' THEN 
	  SELECT INTO o_id id FROM organization WHERE lower(_name) = lower(trim(transaction."provider-org"[1]::text));
	  -- create the organization if it doesnt exist
	  IF o_id IS NULL THEN
            INSERT INTO organization (_name, iati_import_id, _created_by, _updated_by) VALUES (trim(transaction."provider-org"[1]::text), 
		iati.id, iati._created_by, iati._created_by) RETURNING id INTO o_id;
          END IF;
          -- add the organization to the financial
	  IF o_id IS NOT NULL THEN
	    UPDATE financial SET provider_id = o_id WHERE id = f_id;
	  END IF;
	END IF;
	-- update finance with receiver organization if avaiable
	IF trim(transaction."receiver-org"[1]::text) IS NOT NULL AND trim(transaction."receiver-org"[1]::text) <> '' THEN 
	  SELECT INTO o_id id FROM organization WHERE lower(_name) = lower(trim(transaction."receiver-org"[1]::text));
	  -- create the organization if it doesnt exist
	  IF o_id IS NULL THEN
            INSERT INTO organization (_name, iati_import_id, _created_by, _updated_by) VALUES (trim(transaction."receiver-org"[1]::text), 
		iati.id, iati._created_by, iati._created_by) RETURNING id INTO o_id;
          END IF;
          -- add the organization to the financial
	  IF o_id IS NOT NULL THEN
	    UPDATE financial SET recipient_id = o_id WHERE id = f_id;
	  END IF;
	END IF;
	-- add activity sector, if a code exists
	IF trim(transaction."sector-code"[1]::text) IS NOT NULL AND trim(transaction."sector-code"[1]::text) <> '' THEN	 
          -- get the sector type
	  IF trim(transaction."sector-vocab"[1]::text) IS NOT NULL AND trim(transaction."sector-vocab"[1]::text) <> '' THEN
            -- determine which taxonomy to use  
            SELECT INTO sector_vocab * FROM _taxonomy_classifications WHERE _iati_codelist = 'SectorVocabulary' 
		AND _iati_code = trim(transaction."sector-vocab"[1]::text) LIMIT 1;
            IF sector_vocab._iati_code IS NOT NULL THEN
              CASE (sector_vocab._iati_code)
                -- Sector
                WHEN '1' THEN
                  SELECT INTO c_id classification_id FROM _taxonomy_classifications WHERE _iati_codelist = 'Sector' 
		    AND _iati_code = trim(transaction."sector-code"[1]::text) LIMIT 1;
                  IF c_id IS NOT NULL THEN
                    INSERT INTO activity_taxonomy (activity_id, classification_id, _field) VALUES (a_id, c_id, 'id');
                  END IF;
                -- Sector Category
                WHEN '2' THEN
                  SELECT INTO c_id classification_id FROM _taxonomy_classifications WHERE _iati_codelist = 'SectorCategory' 
			AND _iati_code = trim(transaction."sector-code"[1]::text) LIMIT 1;
                  IF c_id IS NOT NULL THEN
                    INSERT INTO activity_taxonomy (activity_id, classification_id, _field) VALUES (a_id, c_id, 'id');
                  END IF;
                 -- Not Supported
                 ELSE
                   -- record error
                   error:= 'The Sector Vocabulary "'|| sector_vocab.classification || '" is not supported. ';
                   IF  error_msgs @> array[error] THEN
                   ELSE
                     error_msgs:= array_append(error_msgs, error);
                   END IF;            
              END CASE;
            -- no matching code, try sector
            ELSE
              SELECT INTO c_id classification_id FROM _taxonomy_classifications WHERE _iati_codelist = 'Sector' 
		    AND _iati_code = trim(transaction."sector-code"[1]::text) LIMIT 1;
              IF c_id IS NOT NULL THEN
                INSERT INTO activity_taxonomy (activity_id, classification_id, _field) VALUES (a_id, c_id, 'id');
              END IF;
            END IF;
          -- if vocab is omitted, assume DAC 5 (Sector)
          ELSE
            SELECT INTO c_id classification_id FROM _taxonomy_classifications WHERE _iati_codelist = 'Sector' 
		AND _iati_code = trim(sector."sector-code"[1]::text) LIMIT 1;
            IF c_id IS NOT NULL THEN
              INSERT INTO activity_taxonomy (activity_id, classification_id, _field) VALUES (a_id, c_id, 'id');
            END IF;     
	  END IF;
	END IF;
      END IF;	
    END LOOP;
    -- related-activity
    -- RULE: This element may occur any number of times.
    FOR related_activity IN SELECT  xpath('/related-activity/@ref', unnest(activity."related-activity")) as "related-activity-id" 
       ,xpath('/related-activity/@type', unnest(activity."related-activity")) as "related-activity-type" LOOP
      RAISE NOTICE '    +++++++ The activity "related_activity": %', related_activity;	       
   END LOOP;
   
  -- end of activity loop
  END LOOP;
  
  -- load all the errors & messages
  error:= 'Number of loaded activities: ' || loaded_activities || '. ';
  error_msgs:= array_append(error_msgs, error);
  error:= 'Number of failed activities: ' || failed_activities || '. ';
  error_msgs:= array_append(error_msgs, error); 
  FOREACH error IN ARRAY error_msgs LOOP
    SELECT INTO error_concat _error FROM iati_import WHERE id = iati_import_id;
    IF error_concat IS NULL THEN
      error_concat := error;
    ELSE
      error_concat := error_concat || error;
    END IF;
    UPDATE iati_import SET _error = error_concat WHERE id = iati_import_id;
  END LOOP;

  RETURN TRUE; 
   	   
EXCEPTION WHEN others THEN
    GET STACKED DIAGNOSTICS error_msg1 = MESSAGE_TEXT,
                          error_msg2 = PG_EXCEPTION_DETAIL,
                          error_msg3 = PG_EXCEPTION_HINT;
    RAISE NOTICE 'Internal Error - Contact your DBA with the following error message: (pmt_etl_iati_activities_v201) %', error_msg1;
    UPDATE iati_import SET _error = 'There was an unexpected error in the pmt_etl_iati_codelist function: ' || error_msg1
      WHERE id = iati_import_id;
    -- remove xml document
    --UPDATE iati_import SET _xml = null WHERE id = iati_import_id;
  RETURN FALSE;
END; 
$$ LANGUAGE 'plpgsql';

/******************************************************************
  pmt_etl_iati_activities_v104
  -- create new function to process the IATI activity xml documents
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_etl_iati_activities_v104(iati_import_id integer) RETURNS boolean AS $$
-- Extracts data from xml document, transforms the data to be PMT compatable and loads the
-- data into the PMT database. Function should only be called from the pmt_iati_evaluate 
-- trigger, which ensures proper usage of the function.
-- Parameters: iati_import_id (the iati_import id of the record to process)
DECLARE 
  a_id integer; -- the id of the activity created
  c_id integer; -- the id of a found classification
  o_id integer; -- the id of a found organization
  p_id integer; -- the id of the participation record created
  n_id integer; -- the id of the contact record created
  l_id integer; -- the id of the location record created
  f_id integer; -- the id of the financial record created
  iati record; -- the target iati_import record
  activity record; -- the activity record
  title record;	-- for iterating over multiple narratives
  description record;	-- for iterating over multiple narratives
  participant record; -- for iterating over multiple narratives
  activity_date record; -- for iterating over multiple narratives
  contact record; -- for iterating over multiple narratives
  location record; -- for iterating over multiple narratives
  sector record; -- for iterating over multiple narratives
  budget record; -- for iterating over multiple narratives
  disbursement record; -- for iterating over multiple narratives
  transaction record; -- for iterating over multiple narratives
  related_activity record; -- for iterating over multiple narratives
  data_group record; -- the data group record for this data load
  sector_vocab record; -- the sector vocabulary classification record for current sector
  org_role record; -- the organisation role classification for current participation org
  pt record; -- participation_taxonomy record
  ot record; -- organization_taxonomy record
  lat text; -- the latitude value for a location
  long text; -- the longitude value for a location
  first_name text; -- the parsed first name for a contact
  last_name text; -- the parsed last name for a contact  
  current_value text; -- the current value of a field in question
  failed_activities integer; -- count of failed activities
  loaded_activities integer; -- count of loaded activities
  error text; -- single error message
  error_concat text; -- single error message concatenated
  error_msgs text[]; -- error messages collected through loading process
  error_msg1 text; -- error message for database execeptions
  error_msg2 text; -- error message for database execeptions
  error_msg3 text; -- error message for database execeptions
BEGIN  
  SELECT INTO iati * FROM iati_import WHERE id = iati_import_id;
  -- validate required information
  IF iati._data_group IS NULL OR iati._data_group = '' THEN
    RAISE NOTICE 'The data group was not validated during the workflow.';
    UPDATE iati_import SET _error = 'The data group field is null, but required for loading activities. An error has occurred in the workflow.' WHERE id = iati_import_id;
    -- remove xml document
    UPDATE iati_import SET _xml = null WHERE id = iati_import_id;
    RETURN FALSE;
  ELSE
    SELECT INTO data_group * FROM _taxonomy_classifications WHERE classification = iati._data_group AND taxonomy = 'Data Group';
    RAISE NOTICE 'The data group is: %', data_group;
  END IF;
  -- set counters
  loaded_activities:=0;
  failed_activities:=0;  
  -- loop through the activities 
  FOR activity IN SELECT (xpath('/iati-activity/iati-identifier/text()', node.xml))[1]::text AS "iati-identifier"
	,(xpath('/iati-activity/title', node.xml)) AS "titles"
	,(xpath('/iati-activity/description', node.xml)) AS "descriptions"
	,(xpath('/iati-activity/participating-org', node.xml)) AS "participants"
	,(xpath('/iati-activity/activity-status/@code', node.xml))[1]::text AS "activity-status"
	,(xpath('/iati-activity/activity-date', node.xml)) AS "activity-dates"
	,(xpath('/iati-activity/contact-info', node.xml)) AS "contacts"
	,(xpath('/iati-activity/activity-scope/@code', node.xml))[1]::text AS "activity-scope"
	,(xpath('/iati-activity/location', node.xml)) AS "locations"
	,(xpath('/iati-activity/sector', node.xml)) AS "sectors"
	,(xpath('/iati-activity/budget', node.xml)) AS "budgets"
	,(xpath('/iati-activity/planned-disbursement', node.xml)) AS "planned-disbursements"
	,(xpath('/iati-activity/transaction', node.xml)) AS "transactions"
	,(xpath('/iati-activity/related-activity', node.xml)) AS "related-activity"
	FROM(SELECT unnest(xpath('/iati-activities/iati-activity', _xml::xml))::xml AS xml FROM iati_import where id = $1) AS node LOOP
    a_id:= 0;
    
    /*************************************************************************************
       title
       IATI Rule: This element should occur once and only once (within each parent element)
       PMT Rule: This element is required to create a record in the PMT. Create activity
       and load title into _title.  Gather language taxonomy for field, if NOT english (en).
    *************************************************************************************/
    FOR title IN SELECT xpath('/title/text()', unnest(activity."titles")) as "title"
	,xpath('/title/@xml:lang', unnest(activity."titles")) as "language"  LOOP
      RAISE NOTICE '    +++++++ The activity "title": %', title."title"[1];
      -- create activity, if the activity has not been created yet and we have a title
      IF a_id = 0 AND (title."title" IS NOT NULL OR trim(title."title"[1]::text) <> '') THEN
        INSERT INTO activity (_title, data_group_id, iati_import_id, _created_by, _updated_by) 
		VALUES (trim(title."title"[1]::text), data_group.classification_id, iati.id, iati._created_by, iati._created_by) 
		RETURNING id INTO a_id;
	-- add the language taxonomy if the code is NOT en for english	
	IF trim(title."language"[1]::text) <> '' AND trim(title."language"[1]::text) <> 'en' AND trim(title."language"[1]::text) IS NOT NULL THEN
	  SELECT INTO c_id classification_id FROM _taxonomy_classifications WHERE _iati_codelist = 'Language' AND _iati_code = trim(title."language"[1]::text) LIMIT 1;
	  IF c_id IS NOT NULL THEN
	    INSERT INTO activity_taxonomy (activity_id, classification_id, _field) VALUES (a_id, c_id, '_title');
	  END IF;
	END IF;
      -- update the activity title, only if the language is english
      ELSIF a_id > 0 AND (trim(title."title"[1]::text) IS NOT NULL OR trim(title."title"[1]::text) <> '') THEN
        IF trim(title."language"[1]::text) = 'en' THEN
          EXECUTE 'UPDATE activity SET _title = ' || quote_literal(trim(title."title"[1]::text)) || ' WHERE id =' || a_id;
          -- remove language taxonomies if associated
          DELETE FROM activity_taxonomy WHERE activity_id = a_id AND _field = '_title' AND classification_id 
		IN (SELECT classification_id FROM _taxonomy_classifications WHERE _iati_codelist = 'Language');
        END IF;
      END IF;
    END LOOP;    
    -- if an activity wasn't created continue on
    IF a_id = 0 THEN
      failed_activities := failed_activities + 1;
      CONTINUE;
    ELSE
      loaded_activities:= loaded_activities + 1;
    END IF;
    /*************************************************************************************
       iati-identifier
       IATI Rule: This element should occur once and only once (within each parent element)
       PMT Rule: Load into activity._iati_identifier
    *************************************************************************************/  
    IF activity."iati-identifier" IS NOT NULL AND activity."iati-identifier" <> '' THEN
      RAISE NOTICE '    +++++++ The activity "iati-identifier": %', activity."iati-identifier";
      EXECUTE 'UPDATE activity SET _iati_identifier = ' || quote_literal(trim(activity."iati-identifier")) || ' WHERE id =' || a_id;
    END IF;
    /*************************************************************************************
       description
       IATI Rule: This element should occur at least once (within each parent element)
       PMT Rule: Load description into the activity table. The field  loaded depends on 
       type: 1=_description, 2=_objective, all others=_content. Gather language taxonomy
       for field, if NOT english (en).
    *************************************************************************************/      
    FOR description IN SELECT xpath('/description/@type', unnest(activity."descriptions")) as "type"
	,xpath('/description/text()', unnest(activity."descriptions")) as "description"
	,xpath('/description/@xml:lang', unnest(activity."descriptions")) as "language" LOOP
      RAISE NOTICE '    +++++++ The activity "description": %', description;       
      IF trim(description."description"[1]::text) IS NOT NULL AND trim(description."description"[1]::text) <> '' THEN
       -- activity table field is determined by type
        CASE (description."type"[1]::text)
          -- description
          WHEN '1' THEN
            -- get the current description value from the table
            SELECT INTO current_value _description::text FROM activity WHERE id = a_id;
            -- update the activity description if its empty
            IF current_value IS NULL OR current_value = '' THEN
              EXECUTE 'UPDATE activity SET _description = ' || quote_literal(trim(description."description"[1]::text)) || ' WHERE id =' || a_id;
              -- add the language taxonomy if the code is NOT en for english	
	      IF trim(description."language"[1]::text) <> '' AND trim(description."language"[1]::text) <> 'en' AND trim(description."language"[1]::text) IS NOT NULL THEN
	        SELECT INTO c_id classification_id FROM _taxonomy_classifications WHERE _iati_codelist = 'Language' AND _iati_code = trim(description."language"[1]::text) LIMIT 1;
	        IF c_id IS NOT NULL THEN
	          INSERT INTO activity_taxonomy (activity_id, classification_id, _field) VALUES (a_id, c_id, '_description');
	        END IF;
	      END IF;
            ELSE
              -- only update the description if the language is english
              IF trim(description."language"[1]::text) = 'en' THEN
		EXECUTE 'UPDATE activity SET _description = ' || quote_literal(trim(description."description"[1]::text)) || ' WHERE id =' || a_id;
		-- remove language taxonomies if associated
                DELETE FROM activity_taxonomy WHERE activity_id = a_id AND _field = '_description' AND classification_id 
			IN (SELECT classification_id FROM _taxonomy_classifications WHERE _iati_codelist = 'Language');
	      END IF;
            END IF;
          -- objective
          WHEN '2' THEN           
            -- get the current description value from the table
            SELECT INTO current_value _objective::text FROM activity WHERE id = a_id;
            -- update the activity description if its empty
            IF current_value IS NULL OR current_value = '' THEN
              EXECUTE 'UPDATE activity SET _objective = ' || quote_literal(trim(description."description"[1]::text)) || ' WHERE id =' || a_id;
              -- add the language taxonomy if the code is NOT en for english	
	      IF trim(description."language"[1]::text) <> '' AND trim(description."language"[1]::text) <> 'en' AND trim(description."language"[1]::text) IS NOT NULL THEN
	        SELECT INTO c_id classification_id FROM _taxonomy_classifications WHERE _iati_codelist = 'Language' AND _iati_code = trim(description."language"[1]::text) LIMIT 1;
	        IF c_id IS NOT NULL THEN
	          INSERT INTO activity_taxonomy (activity_id, classification_id, _field) VALUES (a_id, c_id, '_objective');
	        END IF;
	      END IF;
            ELSE
              -- only update the description if the language is english
              IF trim(description."language"[1]::text) = 'en' THEN
		EXECUTE 'UPDATE activity SET _objective = ' || quote_literal(trim(description."description"[1]::text)) || ' WHERE id =' || a_id;
		-- remove language taxonomies if associated
                DELETE FROM activity_taxonomy WHERE activity_id = a_id AND _field = '_objective' AND classification_id 
			IN (SELECT classification_id FROM _taxonomy_classifications WHERE _iati_codelist = 'Language');
	      END IF;
            END IF;
          -- content
          ELSE            
            -- get the current description value from the table
            SELECT INTO current_value _content::text FROM activity WHERE id = a_id;
            -- update the activity description if its empty
            IF current_value IS NULL OR current_value = '' THEN
              EXECUTE 'UPDATE activity SET _content = ' || quote_literal(trim(description."description"[1]::text)) || ' WHERE id =' || a_id;
              -- add the language taxonomy if the code is NOT en for english	
	      IF trim(description."language"[1]::text) <> '' AND trim(description."language"[1]::text) <> 'en' AND trim(description."language"[1]::text) IS NOT NULL THEN
	        SELECT INTO c_id classification_id FROM _taxonomy_classifications WHERE _iati_codelist = 'Language' AND _iati_code = trim(description."language"[1]::text) LIMIT 1;
	        IF c_id IS NOT NULL THEN
	          INSERT INTO activity_taxonomy (activity_id, classification_id, _field) VALUES (a_id, c_id, '_content');
	        END IF;
	      END IF;
            ELSE
              -- only update the description if the language is english
              IF trim(description."language"[1]::text) = 'en' THEN
		EXECUTE 'UPDATE activity SET _content = ' || quote_literal(trim(description."description"[1]::text)) || ' WHERE id =' || a_id;
		-- remove language taxonomies if associated
                DELETE FROM activity_taxonomy WHERE activity_id = a_id AND _field = '_content' AND classification_id 
			IN (SELECT classification_id FROM _taxonomy_classifications WHERE _iati_codelist = 'Language');
	      END IF;
            END IF;
        END CASE; 
      END IF;        
    END LOOP;
    /*************************************************************************************
       activity-date
       IATI Rule: This element should occur at least once (within each parent element)
       PMT Rule: Load dates into the activity table. The field loaded depends on 
       type: 1=_plan_start_date, 2=_start_date, 3=_plan_end_date & all others=_end_date. 
    *************************************************************************************/     
    FOR activity_date IN SELECT xpath('/activity-date/@iso-date', unnest(activity."activity-dates")) as "date"
       ,xpath('/activity-date/@type', unnest(activity."activity-dates")) as "type" LOOP
      RAISE NOTICE '    +++++++ The activity "activity_date": %', activity_date; 
      IF trim(activity_date."date"[1]::text) IS NOT NULL AND trim(activity_date."date"[1]::text) <> '' THEN
        CASE (activity_date."type"[1]::text)
          -- planned start date
          WHEN 'start-planned' THEN
	    EXECUTE 'UPDATE activity SET _plan_start_date = ' || quote_literal(trim(activity_date."date"[1]::text)) || ' WHERE id =' || a_id;
          -- actual start date
          WHEN 'start-actual' THEN           
            EXECUTE 'UPDATE activity SET _start_date = ' || quote_literal(trim(activity_date."date"[1]::text)) || ' WHERE id =' || a_id;
          -- planned end date
          WHEN 'end-planned' THEN   
            EXECUTE 'UPDATE activity SET _plan_end_date = ' || quote_literal(trim(activity_date."date"[1]::text)) || ' WHERE id =' || a_id;        
          -- actual end date
          ELSE            
            EXECUTE 'UPDATE activity SET _end_date = ' || quote_literal(trim(activity_date."date"[1]::text)) || ' WHERE id =' || a_id;
        END CASE; 
      END IF;      
    END LOOP;
    /*************************************************************************************
       activity-scope
       IATI Rule: This element should occur no more than once (within each parent element)
       PMT Rule: Load as activity taxonomy. Taxonomy = Activity Scope
    *************************************************************************************/ 
    IF trim(activity."activity-scope") <> '' AND trim(activity."activity-scope") IS NOT NULL THEN
      RAISE NOTICE '    +++++++ The activity "activity-scope": %', activity."activity-scope";
      SELECT INTO c_id classification_id FROM _taxonomy_classifications WHERE _iati_codelist = 'ActivityScope' 
		AND _iati_code = trim(activity."activity-scope") LIMIT 1;
      IF c_id IS NOT NULL THEN
        INSERT INTO activity_taxonomy (activity_id, classification_id, _field) VALUES (a_id, c_id, 'id');
      END IF;
    END IF;    
    /*************************************************************************************
       activity-status
       IATI Rule: This element should occur once and only once (within each parent element)
       PMT Rule: Load as activity taxonomy. Taxonomy = Activity Status
    *************************************************************************************/ 
    IF trim(activity."activity-status") <> '' AND trim(activity."activity-status") IS NOT NULL THEN
      RAISE NOTICE '    +++++++ The activity "activity-status": %', activity."activity-status"; 
      SELECT INTO c_id classification_id FROM _taxonomy_classifications WHERE _iati_codelist = 'ActivityStatus' 
		AND _iati_code = trim(activity."activity-status") LIMIT 1;
      IF c_id IS NOT NULL THEN
        INSERT INTO activity_taxonomy (activity_id, classification_id, _field) VALUES (a_id, c_id, 'id');
      END IF;
    END IF;
    /*************************************************************************************
       sector
       IATI Rule: This element may occur any number of times
       PMT Rule: Load as activity taxonomy.Taxonomy is Sector or Sector Category based on 
       Sector Vocabulary taxonomy in sector-vocab.
    *************************************************************************************/ 
    FOR sector IN SELECT  xpath('/sector/@code', unnest(activity."sectors")) as "sector-code"  
	,xpath('/sector/@vocabulary', unnest(activity."sectors")) as "sector-vocab"  
	,xpath('/sector/@percent', unnest(activity."sectors")) as "sector-percent" LOOP
      RAISE NOTICE '    +++++++ The activity "sector": %', sector; 
      -- add sector taxonomy, if code exsits
      IF trim(sector."sector-code"[1]::text) IS NOT NULL AND trim(sector."sector-code"[1]::text) <> '' THEN
        -- if vocab exists, look it up
        IF trim(sector."sector-vocab"[1]::text) IS NOT NULL AND trim(sector."sector-vocab"[1]::text) <> '' THEN
          -- determine which taxonomy to use  
          SELECT INTO sector_vocab * FROM _taxonomy_classifications WHERE _iati_codelist = 'SectorVocabulary' 
		AND _iati_code = trim(sector."sector-vocab"[1]::text) LIMIT 1;
          IF sector_vocab._iati_code IS NOT NULL THEN
            CASE (sector_vocab._iati_code)
              -- Sector
              WHEN '1' THEN
                SELECT INTO c_id classification_id FROM _taxonomy_classifications WHERE _iati_codelist = 'Sector' 
		    AND _iati_code = trim(sector."sector-code"[1]::text) LIMIT 1;
                IF c_id IS NOT NULL THEN
                  INSERT INTO activity_taxonomy (activity_id, classification_id, _field) VALUES (a_id, c_id, 'id');
                END IF;
              -- Sector Category
              WHEN '2' THEN
                SELECT INTO c_id classification_id FROM _taxonomy_classifications WHERE _iati_codelist = 'SectorCategory' 
    		AND _iati_code = trim(sector."sector-code"[1]::text) LIMIT 1;
                IF c_id IS NOT NULL THEN
                  INSERT INTO activity_taxonomy (activity_id, classification_id, _field) VALUES (a_id, c_id, 'id');
                END IF;
              -- Not Supported
                  ELSE
               -- record error
               error:= 'The Sector Vocabulary "'|| sector_vocab.classification || '" is not supported. ';
               IF  error_msgs @> array[error] THEN
               ELSE
                 error_msgs:= array_append(error_msgs, error);
               END IF;            
            END CASE;
          -- no matching code, try sector
          ELSE
            SELECT INTO c_id classification_id FROM _taxonomy_classifications WHERE _iati_codelist = 'Sector' 
		    AND _iati_code = trim(sector."sector-code"[1]::text) LIMIT 1;
            IF c_id IS NOT NULL THEN
              INSERT INTO activity_taxonomy (activity_id, classification_id, _field) VALUES (a_id, c_id, 'id');
            END IF;
          END IF;
        -- if vocab is omitted, assume DAC 5 (Sector)
        ELSE
          SELECT INTO c_id classification_id FROM _taxonomy_classifications WHERE _iati_codelist = 'Sector' 
		AND _iati_code = trim(sector."sector-code"[1]::text) LIMIT 1;
          IF c_id IS NOT NULL THEN
            INSERT INTO activity_taxonomy (activity_id, classification_id, _field) VALUES (a_id, c_id, 'id');
          END IF;
        END IF;
      END IF;     
    END LOOP;
    /*************************************************************************************
       participant-org
       IATI Rule: This element should occur at least once (within each parent element)
       PMT Rule: Load as participation. Add organization if not found in the PMT. Participation
       taxonomy is collected from role for Organisation Role. The role attribute is required.
    *************************************************************************************/ 
    FOR participant IN SELECT xpath('/participating-org/@role', unnest(activity."participants")) as "role"
       ,xpath('/participating-org/@type', unnest(activity."participants")) as "type"
       ,xpath('/participating-org/@xml:lang', unnest(activity."participants")) as "language"
       ,xpath('/participating-org/text()', unnest(activity."participants")) as "participant" LOOP
      RAISE NOTICE '    +++++++ The activity "participants": %', participant; 
      -- if there is an organization name in the narrative element continue
      IF trim(participant."participant"[1]::text) IS NOT NULL AND trim(participant."participant"[1]::text) <> '' THEN
        -- lookup the organisation role
        SELECT INTO org_role * FROM _taxonomy_classifications WHERE _iati_codelist = 'OrganisationRole' 
		AND _iati_name = trim(participant."role"[1]::text) LIMIT 1;       	
        -- role attribute is require to load organization participation
        IF org_role.classification_id IS NOT NULL THEN
          -- lookup organization
          SELECT INTO o_id id FROM organization WHERE lower(_name) = lower(trim(participant."participant"[1]::text)) ORDER BY id LIMIT 1;
          RAISE NOTICE 'Looking for an organization, the id if found is: %', o_id;
          -- create the organization record, if it doesnt exist
          IF o_id IS NULL THEN
            RAISE NOTICE 'CREATING NEW ORGANIZATION: %', trim(participant."participant"[1]::text);
            INSERT INTO organization (_name, iati_import_id, _created_by, _updated_by) VALUES (trim(participant."participant"[1]::text), 
		iati.id, iati._created_by, iati._created_by) RETURNING id INTO o_id;
          END IF;  
          -- lookup organisation type
          SELECT INTO c_id classification_id FROM _taxonomy_classifications WHERE _iati_codelist = 'OrganisationType' 
		AND _iati_code = trim(participant."type"[1]::text) LIMIT 1;
	  SELECT INTO ot * FROM organization_taxonomy WHERE organization_id = o_id AND classification_id = c_id AND _field = 'id' LIMIT 1;	
	  -- add organisation type taxonomy if it doesnt exist
	  IF c_id IS NOT NULL AND ot.organization_id IS NULL THEN
	    INSERT INTO organization_taxonomy (organization_id, classification_id, _field) VALUES (o_id, c_id, 'id');
	  END IF;
          -- add the participation record if it doesnt exist
          SELECT INTO p_id id FROM participation WHERE activity_id = a_id AND organization_id = o_id LIMIT 1;
          IF p_id IS NULL THEN
            INSERT INTO participation (activity_id, organization_id, _created_by, _updated_by) 
		VALUES (a_id, o_id, quote_literal(iati._created_by), quote_literal(iati._created_by)) RETURNING id INTO p_id;
	  END IF;
	  -- add organisation role taxonomy if it doesnt exist
	  SELECT INTO pt * FROM participation_taxonomy WHERE participation_id = p_id AND classification_id = org_role.classification_id AND _field = 'id' LIMIT 1;
	  IF pt IS NULL THEN
	    INSERT INTO participation_taxonomy (participation_id, classification_id, _field) VALUES (p_id, org_role.classification_id, 'id');
	  END IF;
	ELSE
	  RAISE NOTICE 'Org role was not found!! %', trim(participant."role"[1]::text)|| org_role;
	  -- record error
           error:= 'A participant was not loaded because the role attribute was not included on the participating-org element. ';
           IF  error_msgs @> array[error] THEN
           ELSE
             error_msgs:= array_append(error_msgs, error);
           END IF; 
        END IF;
      END IF;
    END LOOP;  
    /*************************************************************************************
       contact-info
       IATI Rule: This element may occur any number of times
       PMT Rule: Load as contact. Requires person-name.
    *************************************************************************************/      
    FOR contact IN SELECT (xpath('/contact-info/organisation/text()', unnest(activity."contacts")))[1] as "organization"       
	,(xpath('/contact-info/person-name/text()', unnest(activity."contacts")))[1] as "name"       
	,(xpath('/contact-info/job-title/text()', unnest(activity."contacts")))[1] as "title"  
	,(xpath('/contact-info/telephone/text()', unnest(activity."contacts")))[1] as "telephone"  
	,(xpath('/contact-info/email/text()', unnest(activity."contacts")))[1] as "email"  
	,(xpath('/contact-info/website/text()', unnest(activity."contacts")))[1] as "website" LOOP
      RAISE NOTICE '    +++++++ The activity "contact": %', contact; 
      -- if there is an organization name in the narrative element continue
      IF trim(contact."name"::text) IS NOT NULL AND trim(contact."name"::text) <> '' THEN 
        n_id := null;
        -- parse the first and last names
        IF (position(' ' IN trim(contact."name"::text)) > 0) THEN
          first_name := substring(trim(contact."name"::text) from 1 for position(' ' IN trim(contact."name"::text)));
          last_name := substring(trim(contact."name"::text) from position(' ' IN trim(contact."name"::text))+1 for char_length(trim(contact."name"::text)));                   
        ELSE
          -- there is no space so just, set the contact name to the first name          
          first_name := trim(contact."name"::text);
          last_name := null;
        END IF;       
        -- check to see if the contact exists
        SELECT INTO n_id id FROM contact WHERE lower(_last_name) = lower(last_name) AND lower(_first_name) = lower(first_name);
        -- the contact record does not exist, create it
        IF n_id IS NULL THEN 
          -- create and return the contact record id    
          INSERT INTO contact (_first_name, iati_import_id, _created_by, _updated_by) 
		VALUES (TRIM(contact."name"::text), iati.id, iati._created_by, iati._created_by) 
		RETURNING id INTO n_id;
	  -- update contact with organization if avaiable
	  IF trim(contact."organization"::text) IS NOT NULL AND trim(contact."organization"::text) <> '' THEN 
	    SELECT INTO o_id id FROM organization WHERE lower(_name) = lower(trim(contact."organization"::text));
	    RAISE NOTICE 'Looking for an organization, the id if found is: %', o_id;
	    -- create the organization if it doesnt exist
	    IF o_id IS NULL THEN
	      RAISE NOTICE 'CREATING NEW ORGANIZATION: %', trim(contact."organization"::text);
              INSERT INTO organization (_name, iati_import_id, _created_by, _updated_by) VALUES (trim(contact."organization"::text), 
		iati.id, iati._created_by, iati._created_by) RETURNING id INTO o_id;
            END IF;
            -- add the organization to the contact
	    IF o_id IS NOT NULL THEN
	      UPDATE contact SET organization_id = o_id WHERE id = n_id;
	    END IF;
	  END IF;
	  -- update contact with title if avialable
	  IF trim(contact."title"::text) IS NOT NULL AND trim(contact."title"::text) <> '' THEN 
	    UPDATE contact SET _title = trim(contact."title"::text) WHERE id = n_id;
    	  END IF;
  	  -- update contact with direct phone if avialable
	  IF trim(contact."telephone"::text) IS NOT NULL AND trim(contact."telephone"::text) <> '' THEN 
	    UPDATE contact SET _direct_phone = trim(contact."telephone"::text) WHERE id = n_id;
	  END IF;
	  -- update contact with email if avialable
	  IF trim(contact."email"::text) IS NOT NULL AND trim(contact."email"::text) <> '' THEN 
	    UPDATE contact SET _email = trim(contact."email"::text) WHERE id = n_id;
	  END IF;
	  -- update contact with url if avialable
	  IF trim(contact."website"::text) IS NOT NULL AND trim(contact."website"::text) <> '' THEN 
	    UPDATE contact SET _url = trim(contact."website"::text) WHERE id = n_id;
	  END IF;
	  -- connect to activity
	  INSERT INTO activity_contact(activity_id, contact_id) VALUES (a_id, n_id);
        END IF;
      END IF;
    END LOOP; 
    /*************************************************************************************
       location
       IATI Rule: This element may occur any number of times
       PMT Rule: Load as location. 
    *************************************************************************************/     
    FOR location IN SELECT xpath('/location/location-reach/@code', unnest(activity."locations")) as "location-reach"  
           ,xpath('/location/location-id/@vocabulary', unnest(activity."locations")) as "location-id-vocab"
	   ,xpath('/location/location-id/@code', unnest(activity."locations")) as "location-id-code"	   
	   ,xpath('/location/name/text()', unnest(activity."locations")) as "name"
	   ,xpath('/location/name/@xml:lang', unnest(activity."locations")) as "name_lang"
	   ,xpath('/location/description/text()', unnest(activity."locations")) as "description"
	   ,xpath('/location/description/@xml:lang', unnest(activity."locations")) as "description_lang"
	   ,xpath('/location/administrative/@code', unnest(activity."locations")) as "administrative-code"
	   ,xpath('/location/administrative/@level', unnest(activity."locations")) as "administrative-level"
	   ,xpath('/location/administrative/@vocabulary', unnest(activity."locations")) as "administrative-vocab"
	   ,xpath('/location/point/@srsName', unnest(activity."locations")) as "point-srs"
	   ,xpath('/location/point/pos/text()', unnest(activity."locations")) as "point"
	   ,xpath('/location/exactness/@code', unnest(activity."locations")) as "exactness"
	   ,xpath('/location/location-class/@code', unnest(activity."locations")) as "location-class"
	   ,xpath('/location/location-type/@code', unnest(activity."locations")) as "location-type"
	   ,xpath('/location/feature-designation/@code', unnest(activity."locations")) as "feature-designation"
           ,xpath('/location/coordinates/@latitude', unnest(activity."locations")) as "latitude"	   
           ,xpath('/location/coordinates/@longitude', unnest(activity."locations")) as "longitude" LOOP
     RAISE NOTICE '    +++++++ The activity "location": %', location; 
     -- create a location associated to the activity
     INSERT INTO location(activity_id, _created_by, _updated_by) VALUES (a_id, iati._created_by, iati._created_by) RETURNING id INTO l_id;
     -- add geographic location reach taxonomy if exists
     IF trim(location."location-reach"[1]::text) IS NOT NULL AND trim(location."location-reach"[1]::text) <> '' THEN
       -- lookup geographic location reach
       SELECT INTO c_id classification_id FROM _taxonomy_classifications WHERE _iati_codelist = 'GeographicLocationReach' 
		AND _iati_code = trim(location."location-reach"[1]::text) LIMIT 1;
       IF c_id IS NOT NULL THEN
         INSERT INTO location_taxonomy (location_id, classification_id, _field) VALUES (l_id, c_id, 'id');
       END IF;
     END IF;
     -- add geographic vocabulary taxonomy if exists
     IF trim(location."location-id-vocab"[1]::text) IS NOT NULL AND trim(location."location-id-vocab"[1]::text) <> '' AND
        trim(location."location-id-code"[1]::text) IS NOT NULL AND trim(location."location-id-code"[1]::text) <> '' THEN
       -- lookup geographic vocabulary
       SELECT INTO c_id classification_id FROM _taxonomy_classifications WHERE _iati_codelist = 'GeographicVocabulary' 
		AND _iati_code = trim(location."location-id-vocab"[1]::text) LIMIT 1;
       IF c_id IS NOT NULL THEN
         INSERT INTO location_taxonomy (location_id, classification_id, _field) VALUES (l_id, c_id, 'id');
         UPDATE location SET _geographic_id = (location."location-id-code"[1]::text) WHERE id = l_id;
       END IF;
     END IF;
     -- add location title, if it exists
     IF trim(location."name"[1]::text) IS NOT NULL AND trim(location."name"[1]::text) <> '' THEN
       -- get the current title value from the table
       SELECT INTO current_value _title::text FROM location WHERE id = l_id;
       -- update the location title if its empty
       IF current_value IS NULL OR current_value = '' THEN
         UPDATE location SET _title = trim(location."name"[1]::text) WHERE id = l_id;
         -- add the language taxonomy if the code is NOT 'en' for english	
	 IF trim(location."name_lang"[1]::text) <> 'en' AND trim(location."name_lang"[1]::text) IS NOT NULL THEN
	   SELECT INTO c_id classification_id FROM _taxonomy_classifications WHERE _iati_codelist = 'Language' 
	     AND _iati_code = trim(location."name_lang"[1]::text) LIMIT 1;
	   IF c_id IS NOT NULL THEN
	     INSERT INTO location_taxonomy (location_id, classification_id, _field) VALUES (l_id, c_id, '_title');
	   END IF;
	 END IF;
       ELSE
         -- only update the description if the language is english
         IF trim(location."name_lang"[1]::text) = 'en' THEN
	   UPDATE location SET _title = trim(location."name"[1]::text) WHERE id = l_id;
           -- remove language taxonomies if associated
           DELETE FROM location_taxonomy WHERE location_id = l_id AND _field = '_title' AND classification_id 
		IN (SELECT classification_id FROM _taxonomy_classifications WHERE _iati_codelist = 'Language');
	 END IF;
       END IF;
     END IF;
     -- add location description, if it exists
     IF trim(location."description"[1]::text) IS NOT NULL AND trim(location."description"[1]::text) <> '' THEN
       -- get the current description value from the table
       SELECT INTO current_value _description::text FROM location WHERE id = l_id;
       -- update the location description if its empty
       IF current_value IS NULL OR current_value = '' THEN
         UPDATE location SET _description = trim(location."description"[1]::text) WHERE id = l_id;
         -- add the language taxonomy if the code is NOT 'en' for english	
	 IF trim(location."description_lang"[1]::text) <> 'en' AND trim(location."description_lang"[1]::text) IS NOT NULL THEN
	   SELECT INTO c_id classification_id FROM _taxonomy_classifications WHERE _iati_codelist = 'Language' 
	     AND _iati_code = trim(location."description_lang"[1]::text) LIMIT 1;
	   IF c_id IS NOT NULL THEN
	     INSERT INTO location_taxonomy (location_id, classification_id, _field) VALUES (l_id, c_id, '_description');
	   END IF;
	 END IF;
       ELSE
         -- only update the description if the language is english
         IF trim(location."description_lang"[1]::text) = 'en' THEN
	   UPDATE location SET _description = trim(location."description"[1]::text) WHERE id = l_id;
           -- remove language taxonomies if associated
           DELETE FROM location_taxonomy WHERE location_id = l_id AND _field = '_description' AND classification_id 
		IN (SELECT classification_id FROM _taxonomy_classifications WHERE _iati_codelist = 'Language');
	 END IF;
       END IF;
     END IF;
     -- add location administrative boundary information, if it exists
     IF trim(location."administrative-vocab"[1]::text) IS NOT NULL AND trim(location."administrative-vocab"[1]::text) <> '' THEN
        -- lookup geographic vocabulary
       SELECT INTO c_id classification_id FROM _taxonomy_classifications WHERE _iati_codelist = 'GeographicVocabulary' 
		AND _iati_code = trim(location."administrative-vocab"[1]::text) LIMIT 1;
       IF c_id IS NOT NULL THEN 
         -- remove geographic vocabulary taxonomies if associated
         DELETE FROM location_taxonomy WHERE location_id = l_id AND _field = 'id' AND classification_id 
		IN (SELECT classification_id FROM _taxonomy_classifications WHERE _iati_codelist = 'GeographicVocabulary');
	 -- add the geographic vocabulary taxonomy
	 INSERT INTO location_taxonomy (location_id, classification_id, _field) VALUES (l_id, c_id, 'id');         
       END IF;
       -- add the location geographic boundary code
       IF trim(location."administrative-code"[1]::text) IS NOT NULL AND trim(location."administrative-code"[1]::text) <> '' THEN
         UPDATE location SET _geographic_id = (location."administrative-code"[1]::text) WHERE id = l_id;
       END IF;
       -- add the location geographic level
       IF trim(location."administrative-level"[1]::text) IS NOT NULL AND trim(location."administrative-level"[1]::text) <> '' THEN
         UPDATE location SET _geographic_level = (location."administrative-level"[1]::text) WHERE id = l_id;
       END IF;
     END IF;
     -- add location, if it exists
     IF trim(location."point"[1]::text) IS NOT NULL AND trim(location."point"[1]::text) <> '' THEN
       lat := substring((location."point"[1]::text) from 0 for position(' ' in (location."point"[1]::text)));
       long := substring((location."point"[1]::text) from position(' ' in (location."point"[1]::text)) for length((location."point"[1]::text)));
       RAISE NOTICE 'Long & Lat: %', long || ' ' || lat;
       UPDATE location SET _point = ST_PointFromText('POINT(' || long || ' ' || lat || ')', 4326) WHERE id = l_id;
     END IF;
     -- add location, if it exists
     IF trim(location."latitude"[1]::text) IS NOT NULL AND trim(location."latitude"[1]::text) <> '' AND 
        trim(location."longitude"[1]::text) IS NOT NULL AND trim(location."longitude"[1]::text) <> '' THEN
       lat := trim(location."latitude"[1]::text);
       long := trim(location."longitude"[1]::text);
       RAISE NOTICE 'Long & Lat: %', long || ' ' || lat;
       UPDATE location SET _point = ST_PointFromText('POINT(' || long || ' ' || lat || ')', 4326) WHERE id = l_id;
     END IF;
     -- add geographic exactness taxonomy if exists
     IF trim(location."exactness"[1]::text) IS NOT NULL AND trim(location."exactness"[1]::text) <> '' THEN
       -- lookup geographic exactness
       SELECT INTO c_id classification_id FROM _taxonomy_classifications WHERE _iati_codelist = 'GeographicExactness' 
		AND _iati_code = trim(location."exactness"[1]::text) LIMIT 1;
       IF c_id IS NOT NULL THEN
         INSERT INTO location_taxonomy (location_id, classification_id, _field) VALUES (l_id, c_id, 'id');
       END IF;
     END IF;
     -- add geographic location class taxonomy if exists
     IF trim(location."location-class"[1]::text) IS NOT NULL AND trim(location."location-class"[1]::text) <> '' THEN
       -- lookup geographic location class
       SELECT INTO c_id classification_id FROM _taxonomy_classifications WHERE _iati_codelist = 'GeographicLocationClass' 
		AND _iati_code = trim(location."location-class"[1]::text) LIMIT 1;
       IF c_id IS NOT NULL THEN
         INSERT INTO location_taxonomy (location_id, classification_id, _field) VALUES (l_id, c_id, 'id');
       END IF;
     END IF;
     -- add geographic location type taxonomy if exists
     IF trim(location."location-type"[1]::text) IS NOT NULL AND trim(location."location-type"[1]::text) <> '' THEN
       -- lookup geographic location class
       SELECT INTO c_id classification_id FROM _taxonomy_classifications WHERE _iati_codelist = 'LocationType' 
		AND _iati_code = trim(location."location-type"[1]::text) LIMIT 1;
       IF c_id IS NOT NULL THEN
         INSERT INTO location_taxonomy (location_id, classification_id, _field) VALUES (l_id, c_id, 'id');
       END IF;
     END IF;
     -- add geographic location reach taxonomy if exists
     IF trim(location."location-reach"[1]::text) IS NOT NULL AND trim(location."location-reach"[1]::text) <> '' THEN
       -- lookup geographic location reach
       SELECT INTO c_id classification_id FROM _taxonomy_classifications WHERE _iati_codelist = 'GeographicLocationReach' 
		AND _iati_code = trim(location."location-reach"[1]::text) LIMIT 1;
       IF c_id IS NOT NULL THEN
         INSERT INTO location_taxonomy (location_id, classification_id, _field) VALUES (l_id, c_id, 'id');
       END IF;
     END IF;
     -- add location type taxonomy if exists
     IF trim(location."feature-designation"[1]::text) IS NOT NULL AND trim(location."feature-designation"[1]::text) <> '' THEN
       -- lookup location type
       SELECT INTO c_id classification_id FROM _taxonomy_classifications WHERE _iati_codelist = 'LocationType' 
		AND _iati_code = trim(location."feature-designation"[1]::text) LIMIT 1;
       IF c_id IS NOT NULL THEN
         INSERT INTO location_taxonomy (location_id, classification_id, _field) VALUES (l_id, c_id, 'id');
       END IF;
     END IF;
   END LOOP;
   /*************************************************************************************
       budget
       IATI Rule: This element may occur any number of times
       PMT Rule: Load as financial record. 
    *************************************************************************************/     
    FOR budget IN SELECT  xpath('/budget/@type', unnest(activity."budgets")) as "budget-type"  
	,xpath('/budget/period-start/@iso-date', unnest(activity."budgets")) as "budget-start"  
	,xpath('/budget/period-end/@iso-date', unnest(activity."budgets")) as "budget-end"  
	,xpath('/budget/value/@currency', unnest(activity."budgets")) as "budget-currency"
	,xpath('/budget/value/text()', unnest(activity."budgets")) as "budget-value" LOOP
      RAISE NOTICE '    +++++++ The activity "budget": %', budget;	
      -- add financial record if there is a value
      IF trim(budget."budget-value"[1]::text) IS NOT NULL AND trim(budget."budget-value"[1]::text) <> '' 
		AND (SELECT * FROM pmt_isnumeric(trim(budget."budget-value"[1]::text))) THEN
        INSERT INTO financial (activity_id, _amount, _created_by, _updated_by) 
		VALUES (a_id, ROUND(CAST(replace(trim(budget."budget-value"[1]::text), ',', '') as numeric), 2), 
		iati._created_by, iati._created_by) RETURNING id INTO f_id;
	-- add financial start date, if exists
	IF trim(budget."budget-start"[1]::text) IS NOT NULL AND trim(budget."budget-start"[1]::text) <> '' THEN	
	  EXECUTE 'UPDATE financial SET _start_date = ' || coalesce(quote_literal(trim(budget."budget-start"[1]::text)), 'NULL') ||
		' WHERE id = ' || f_id;
	END IF;
	-- add financial end date, if exists
	IF trim(budget."budget-end"[1]::text) IS NOT NULL AND trim(budget."budget-end"[1]::text) <> '' THEN	
	  EXECUTE 'UPDATE financial SET _end_date = ' || coalesce(quote_literal(trim(budget."budget-end"[1]::text)), 'NULL') ||
		' WHERE id = ' || f_id;
	END IF;
	-- add financial currency, if exists
	IF trim(budget."budget-currency"[1]::text) IS NOT NULL AND trim(budget."budget-currency"[1]::text) <> '' AND 
		trim(budget."budget-currency"[1]::text) <> 'USD' AND trim(budget."budget-currency"[1]::text) <> 'USN' AND
		trim(budget."budget-currency"[1]::text) <> 'USS' THEN
	  -- lookup currency
          SELECT INTO c_id classification_id FROM _taxonomy_classifications WHERE _iati_codelist = 'Currency' 
		AND _iati_code = trim(budget."budget-currency"[1]::text) LIMIT 1;
          IF c_id IS NOT NULL THEN
            INSERT INTO financial_taxonomy (financial_id, classification_id, _field) VALUES (f_id, c_id, 'id');
          END IF;
	END IF;	
      END IF;
    END LOOP;
    /*************************************************************************************
       planned-disbursement
       IATI Rule: This element may occur any number of times
       PMT Rule: Load as financial record. 
    *************************************************************************************/  
    FOR disbursement IN SELECT  xpath('/planned-disbursement/@type', unnest(activity."planned-disbursements")) as "disbursement-type"  
	,xpath('/planned-disbursement/period-start/@iso-date', unnest(activity."planned-disbursements")) as "disbursement-start"  
	,xpath('/planned-disbursement/period-end/@iso-date', unnest(activity."planned-disbursements")) as "disbursement-end"  
	,xpath('/planned-disbursement/value/@currency', unnest(activity."planned-disbursements")) as "disbursement-currency"
	,xpath('/planned-disbursement/value/text()', unnest(activity."planned-disbursements")) as "disbursement-value" LOOP
      RAISE NOTICE '    +++++++ The activity "disbursement": %', disbursement;
      -- add financial record if there is a value
      IF trim(disbursement."disbursement-value"[1]::text) IS NOT NULL AND trim(disbursement."disbursement-value"[1]::text) <> '' 
		AND (SELECT * FROM pmt_isnumeric(trim(disbursement."disbursement-value"[1]::text))) THEN
        INSERT INTO financial (activity_id, _amount, _created_by, _updated_by) 
		VALUES (a_id, ROUND(CAST(replace(trim(disbursement."disbursement-value"[1]::text), ',', '') as numeric), 2), 
		iati._created_by, iati._created_by) RETURNING id INTO f_id;
	-- add financial start date, if exists
	IF trim(disbursement."disbursement-start"[1]::text) IS NOT NULL AND trim(disbursement."disbursement-start"[1]::text) <> '' THEN	
	  EXECUTE 'UPDATE financial SET _start_date = ' || coalesce(quote_literal(trim(disbursement."disbursement-start"[1]::text)), 'NULL') ||
		' WHERE id = ' || f_id;
	END IF;
	-- add financial end date, if exists
	IF trim(disbursement."disbursement-end"[1]::text) IS NOT NULL AND trim(disbursement."disbursement-end"[1]::text) <> '' THEN	
	  EXECUTE 'UPDATE financial SET _end_date = ' || coalesce(quote_literal(trim(disbursement."disbursement-end"[1]::text)), 'NULL') ||
		' WHERE id = ' || f_id;
	END IF;	
	-- add financial currency, if exists
	IF trim(disbursement."disbursement-currency"[1]::text) IS NOT NULL AND trim(disbursement."disbursement-currency"[1]::text) <> '' AND 
		trim(disbursement."disbursement-currency"[1]::text) <> 'USD' AND trim(disbursement."disbursement-currency"[1]::text) <> 'USN' AND
		trim(disbursement."disbursement-currency"[1]::text) <> 'USS' THEN
	  -- lookup currency
          SELECT INTO c_id classification_id FROM _taxonomy_classifications WHERE _iati_codelist = 'Currency' 
		AND _iati_code = trim(disbursement."disbursement-currency"[1]::text) LIMIT 1;
          IF c_id IS NOT NULL THEN
            INSERT INTO financial_taxonomy (financial_id, classification_id, _field) VALUES (f_id, c_id, 'id');
          END IF;
	END IF;	
      END IF;
    END LOOP;
    /*************************************************************************************
       transaction
       IATI Rule: This element may occur any number of times
       PMT Rule: Load as financial record. 
    *************************************************************************************/
    FOR transaction IN SELECT  xpath('/transaction/transaction-type/@code', unnest(activity."transactions")) as "transaction-type"  
	,xpath('/transaction/transaction-date/@iso-date', unnest(activity."transactions")) as "transaction-date"    
	,xpath('/transaction/value/@currency', unnest(activity."transactions")) as "transaction-currency"
	,xpath('/transaction/value/text()', unnest(activity."transactions")) as "transaction-value" 
	,xpath('/transaction/finance-type/@code', unnest(activity."transactions")) as "finance-type"  
	,xpath('/transaction/sector/@code', unnest(activity."transactions")) as "sector-code"  
	,xpath('/transaction/sector/@vocabulary', unnest(activity."transactions")) as "sector-vocab"
	,xpath('/transaction/provider-org/text()', unnest(activity."transactions")) as "provider-org" 
	,xpath('/transaction/receiver-org/text()', unnest(activity."transactions")) as "receiver-org" LOOP
      RAISE NOTICE '    +++++++ The activity "transaction": %', transaction;
      -- add financial record, if there is a value
      IF trim(transaction."transaction-value"[1]::text) IS NOT NULL AND trim(transaction."transaction-value"[1]::text) <> '' 
		AND (SELECT * FROM pmt_isnumeric(trim(transaction."transaction-value"[1]::text))) THEN
        INSERT INTO financial (activity_id, _amount, _created_by, _updated_by) 
		VALUES (a_id, ROUND(CAST(replace(trim(transaction."transaction-value"[1]::text), ',', '') as numeric), 2), 
		iati._created_by, iati._created_by) RETURNING id INTO f_id;
	-- add financial start and end date, if exists
	IF trim(transaction."transaction-date"[1]::text) IS NOT NULL AND trim(transaction."transaction-date"[1]::text) <> '' THEN	
	  EXECUTE 'UPDATE financial SET _start_date = ' || coalesce(quote_literal(trim(transaction."transaction-date"[1]::text)), 'NULL') ||
		', _end_date = ' || coalesce(quote_literal(trim(transaction."transaction-date"[1]::text)), 'NULL') || ' WHERE id = ' || f_id;
	END IF;	
	-- add currency taxonomy, if NOT US Dollar (USD, USN, USS)
	IF trim(transaction."transaction-currency"[1]::text) IS NOT NULL AND trim(transaction."transaction-currency"[1]::text) <> '' AND
		trim(transaction."transaction-currency"[1]::text) <> 'USD' AND trim(transaction."transaction-currency"[1]::text) <> 'USN' AND
		trim(transaction."transaction-currency"[1]::text) <> 'USS' THEN
	  -- lookup currency
          SELECT INTO c_id classification_id FROM _taxonomy_classifications WHERE _iati_codelist = 'Currency' 
		AND _iati_code = trim(transaction."transaction-currency"[1]::text) LIMIT 1;
          IF c_id IS NOT NULL THEN
            INSERT INTO financial_taxonomy (financial_id, classification_id, _field) VALUES (f_id, c_id, 'id');
          END IF;
	END IF;
	-- add finance type, if exists
	IF trim(transaction."finance-type"[1]::text) IS NOT NULL AND trim(transaction."finance-type"[1]::text) <> '' THEN
	  -- lookup finance type
          SELECT INTO c_id classification_id FROM _taxonomy_classifications WHERE _iati_codelist = 'FinanceType' 
		AND _iati_code = trim(transaction."finance-type"[1]::text) LIMIT 1;
          IF c_id IS NOT NULL THEN
            INSERT INTO financial_taxonomy (financial_id, classification_id, _field) VALUES (f_id, c_id, 'id');
          END IF;
	END IF;
	-- add finance transaction type, if exists
	IF trim(transaction."transaction-type"[1]::text) IS NOT NULL AND trim(transaction."transaction-type"[1]::text) <> '' THEN
	  -- lookup finance transaction type
          SELECT INTO c_id classification_id FROM _taxonomy_classifications WHERE _iati_codelist = 'TransactionType' 
		AND _iati_code = trim(transaction."transaction-type"[1]::text) LIMIT 1;
          IF c_id IS NOT NULL THEN
            INSERT INTO financial_taxonomy (financial_id, classification_id, _field) VALUES (f_id, c_id, 'id');
          END IF;
	END IF;
	-- update finance with provider organization if avaiable
	IF trim(transaction."provider-org"[1]::text) IS NOT NULL AND trim(transaction."provider-org"[1]::text) <> '' THEN 
	  SELECT INTO o_id id FROM organization WHERE lower(_name) = lower(trim(transaction."provider-org"[1]::text));
	  -- create the organization if it doesnt exist
	  IF o_id IS NULL THEN
            INSERT INTO organization (_name, iati_import_id, _created_by, _updated_by) VALUES (trim(transaction."provider-org"[1]::text), 
		iati.id, iati._created_by, iati._created_by) RETURNING id INTO o_id;
          END IF;
          -- add the organization to the financial
	  IF o_id IS NOT NULL THEN
	    UPDATE financial SET provider_id = o_id WHERE id = f_id;
	  END IF;
	END IF;
	-- update finance with receiver organization if avaiable
	IF trim(transaction."receiver-org"[1]::text) IS NOT NULL AND trim(transaction."receiver-org"[1]::text) <> '' THEN 
	  SELECT INTO o_id id FROM organization WHERE lower(_name) = lower(trim(transaction."receiver-org"[1]::text));
	  -- create the organization if it doesnt exist
	  IF o_id IS NULL THEN
            INSERT INTO organization (_name, iati_import_id, _created_by, _updated_by) VALUES (trim(transaction."receiver-org"[1]::text), 
		iati.id, iati._created_by, iati._created_by) RETURNING id INTO o_id;
          END IF;
          -- add the organization to the financial
	  IF o_id IS NOT NULL THEN
	    UPDATE financial SET recipient_id = o_id WHERE id = f_id;
	  END IF;
	END IF;
	-- add activity sector, if a code exists
	IF trim(transaction."sector-code"[1]::text) IS NOT NULL AND trim(transaction."sector-code"[1]::text) <> '' THEN	 
          -- get the sector type
	  IF trim(transaction."sector-vocab"[1]::text) IS NOT NULL AND trim(transaction."sector-vocab"[1]::text) <> '' THEN
            -- determine which taxonomy to use  
            SELECT INTO sector_vocab * FROM _taxonomy_classifications WHERE _iati_codelist = 'SectorVocabulary' 
		AND _iati_code = trim(transaction."sector-vocab"[1]::text) LIMIT 1;
            IF sector_vocab._iati_code IS NOT NULL THEN
              CASE (sector_vocab._iati_code)
                -- Sector
                WHEN '1' THEN
                  SELECT INTO c_id classification_id FROM _taxonomy_classifications WHERE _iati_codelist = 'Sector' 
		    AND _iati_code = trim(transaction."sector-code"[1]::text) LIMIT 1;
                  IF c_id IS NOT NULL THEN
                    INSERT INTO activity_taxonomy (activity_id, classification_id, _field) VALUES (a_id, c_id, 'id');
                  END IF;
                -- Sector Category
                WHEN '2' THEN
                  SELECT INTO c_id classification_id FROM _taxonomy_classifications WHERE _iati_codelist = 'SectorCategory' 
			AND _iati_code = trim(transaction."sector-code"[1]::text) LIMIT 1;
                  IF c_id IS NOT NULL THEN
                    INSERT INTO activity_taxonomy (activity_id, classification_id, _field) VALUES (a_id, c_id, 'id');
                  END IF;
                 -- Not Supported
                 ELSE
                   -- record error
                   error:= 'The Sector Vocabulary "'|| sector_vocab.classification || '" is not supported. ';
                   IF  error_msgs @> array[error] THEN
                   ELSE
                     error_msgs:= array_append(error_msgs, error);
                   END IF;            
              END CASE;
            -- no matching code, try sector
            ELSE
              SELECT INTO c_id classification_id FROM _taxonomy_classifications WHERE _iati_codelist = 'Sector' 
		    AND _iati_code = trim(transaction."sector-code"[1]::text) LIMIT 1;
              IF c_id IS NOT NULL THEN
                INSERT INTO activity_taxonomy (activity_id, classification_id, _field) VALUES (a_id, c_id, 'id');
              END IF;
            END IF;
          -- if vocab is omitted, assume DAC 5 (Sector)
          ELSE
            SELECT INTO c_id classification_id FROM _taxonomy_classifications WHERE _iati_codelist = 'Sector' 
		AND _iati_code = trim(sector."sector-code"[1]::text) LIMIT 1;
            IF c_id IS NOT NULL THEN
              INSERT INTO activity_taxonomy (activity_id, classification_id, _field) VALUES (a_id, c_id, 'id');
            END IF;     
	  END IF;
	END IF;
      END IF;	
    END LOOP;
    -- related-activity
    -- RULE: This element may occur any number of times.
    FOR related_activity IN SELECT  xpath('/related-activity/@ref', unnest(activity."related-activity")) as "related-activity-id" 
       ,xpath('/related-activity/@type', unnest(activity."related-activity")) as "related-activity-type" LOOP
      RAISE NOTICE '    +++++++ The activity "related_activity": %', related_activity;	       
   END LOOP;
   
  -- end of activity loop
  END LOOP;
  
  -- load all the errors & messages
  error:= 'Number of loaded activities: ' || loaded_activities || '. ';
  error_msgs:= array_append(error_msgs, error);
  error:= 'Number of failed activities: ' || failed_activities || '. ';
  error_msgs:= array_append(error_msgs, error); 
  FOREACH error IN ARRAY error_msgs LOOP
    SELECT INTO error_concat _error FROM iati_import WHERE id = iati_import_id;
    IF error_concat IS NULL THEN
      error_concat := error;
    ELSE
      error_concat := error_concat || error;
    END IF;
    UPDATE iati_import SET _error = error_concat WHERE id = iati_import_id;
  END LOOP;

  RETURN TRUE; 
   	   
EXCEPTION WHEN others THEN
    GET STACKED DIAGNOSTICS error_msg1 = MESSAGE_TEXT,
                          error_msg2 = PG_EXCEPTION_DETAIL,
                          error_msg3 = PG_EXCEPTION_HINT;
    RAISE NOTICE 'Internal Error - Contact your DBA with the following error message: (pmt_etl_iati_activities_v201) %', error_msg1;
    UPDATE iati_import SET _error = 'There was an unexpected error in the pmt_etl_iati_codelist function: ' || error_msg1
      WHERE id = iati_import_id;
    -- remove xml document
    --UPDATE iati_import SET _xml = null WHERE id = iati_import_id;
  RETURN FALSE;
END; 
$$ LANGUAGE 'plpgsql';
/******************************************************************
  pmt_iati_preprocess
  -- create new trigger to pre-process the IATI xml documents to
  collect important information needed for processing, this information
  is then recorded in the iati_import table.
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_iati_preprocess()
RETURNS TRIGGER AS $pmt_iati_preprocess$
DECLARE 
  data_group_name character varying; -- the data group classification name for all loaded activities
  username text;  -- the username for the user loading the data
  error_msg1 text; -- error message for database execeptions
  error_msg2 text; -- error message for database execeptions
  error_msg3 text; -- error message for database execeptions
  _version text; -- text type for version to mediate the converstion to numeric data type
BEGIN  	
  
  -- extract from the xml document the type (codelist or iati-activities) and insert into table
  NEW._type := unnest(xpath('name()',NEW._xml))::character varying;
  -- extract the name of the document and format (only codelist types have names, which becomes the taxonomy name) and insert into table
  NEW._codelist := (xpath('//'||NEW._type||'/@name',NEW._xml))[1]::text; 		
  -- extract the version as text
  _version := (xpath('//'||NEW._type||'/@version',NEW._xml))[1]::text;
  -- if there is a version, record
  IF (_version IS NOT NULL) OR (_version != '') THEN
    -- convert text version to numeric and insert into the table
    NEW._version := to_number(_version, '9D99');
  END IF;
  RETURN NEW;
END;
$pmt_iati_preprocess$ LANGUAGE plpgsql; 
DROP TRIGGER IF EXISTS pmt_iati_preprocess ON iati_import;
CREATE TRIGGER pmt_iati_preprocess BEFORE INSERT ON iati_import
    FOR EACH ROW EXECUTE PROCEDURE pmt_iati_preprocess();
/******************************************************************
  pmt_iati_evaluate
  -- create new trigger to evaluate the IATI xml documents and
  determine which version and ETL process to call
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_iati_evaluate()
RETURNS TRIGGER AS $pmt_iati_evaluate$
DECLARE 
  error_msg1 text; -- error message for database execeptions
  error_msg2 text; -- error message for database execeptions
  error_msg3 text; -- error message for database execeptions
BEGIN  	

  -- determine how to process xml document based on type
  CASE UPPER(NEW._type) 
    WHEN 'CODELIST' THEN
      -- process the code list
      RAISE NOTICE 'Processing IATI codelist';
      PERFORM pmt_etl_iati_codelist(NEW.id); 
    WHEN 'IATI-ACTIVITIES' THEN
      -- determine what version to process
      RAISE NOTICE 'Processing IATI activities';
      CASE (NEW._version)
        WHEN 2.01 THEN
          RAISE NOTICE '  ... IATI Activity Schema version 2.01';
          PERFORM pmt_etl_iati_activities_v201(NEW.id);
        WHEN 1.04 THEN
          RAISE NOTICE '  ... IATI Activity Schema version 1.04';
          PERFORM pmt_etl_iati_activities_v104(NEW.id);
        ELSE
          -- we haven't developed an ETL for this version record error
          NEW._error := 'The PMT does not have an ETL process for the "' || NEW._version || '" version of the IATI Activity schema at this time. Please notify the database administrator.';
      END CASE;
    ELSE
      -- unexpected xml document type, remove the xml document from the table       
      NEW._xml := null; 
       -- record the above error in the table
      NEW._error := 'The "' || NEW._type || '" document type is unexpected and will not be processed.';
  END CASE;
	
  RETURN NEW;
END;
$pmt_iati_evaluate$ LANGUAGE plpgsql; 
DROP TRIGGER IF EXISTS pmt_iati_evaluate ON iati_import;
CREATE TRIGGER pmt_iati_evaluate AFTER INSERT ON iati_import
    FOR EACH ROW EXECUTE PROCEDURE pmt_iati_evaluate();

-- add new taxonomies
INSERT INTO iati_import (_action, _xml, _created_by) VALUES('insert',convert_from(pmt_bytea_import('ActivityScope.xml'), 'utf8')::xml, 'cs_.3.0.10.3');
INSERT INTO iati_import (_action, _xml, _created_by) VALUES('insert',convert_from(pmt_bytea_import('FinanceType-category.xml'), 'utf8')::xml, 'cs_.3.0.10.3');
INSERT INTO iati_import (_action, _xml, _created_by) VALUES('insert',convert_from(pmt_bytea_import('FinanceType.xml'), 'utf8')::xml, 'cs_.3.0.10.3');
INSERT INTO iati_import (_action, _xml, _created_by) VALUES('insert',convert_from(pmt_bytea_import('GazetteerAgency.xml'), 'utf8')::xml, 'cs_.3.0.10.3');
INSERT INTO iati_import (_action, _xml, _created_by) VALUES('insert',convert_from(pmt_bytea_import('GeographicExactness.xml'), 'utf8')::xml, 'cs_.3.0.10.3');
INSERT INTO iati_import (_action, _xml, _created_by) VALUES('insert',convert_from(pmt_bytea_import('GeographicLocationClass.xml'), 'utf8')::xml, 'cs_.3.0.10.3');
INSERT INTO iati_import (_action, _xml, _created_by) VALUES('insert',convert_from(pmt_bytea_import('GeographicLocationReach.xml'), 'utf8')::xml, 'cs_.3.0.10.3');
INSERT INTO iati_import (_action, _xml, _created_by) VALUES('insert',convert_from(pmt_bytea_import('GeographicVocabulary.xml'), 'utf8')::xml, 'cs_.3.0.10.3');
INSERT INTO iati_import (_action, _xml, _created_by) VALUES('insert',convert_from(pmt_bytea_import('GeographicalPrecision.xml'), 'utf8')::xml, 'cs_.3.0.10.3');
INSERT INTO iati_import (_action, _xml, _created_by) VALUES('insert',convert_from(pmt_bytea_import('Language.xml'), 'utf8')::xml, 'cs_.3.0.10.3');
INSERT INTO iati_import (_action, _xml, _created_by) VALUES('insert',convert_from(pmt_bytea_import('SectorVocabulary.xml'), 'utf8')::xml, 'cs_.3.0.10.3');
INSERT INTO iati_import (_action, _xml, _created_by) VALUES('insert',convert_from(pmt_bytea_import('TransactionType.xml'), 'utf8')::xml, 'cs_.3.0.10.3');

-- Add IATI Data
  -- African Development Bank
  INSERT INTO classification (taxonomy_id, _name, _created_by, _updated_by) VALUES (1, 'AfDB', 'cs_.3.0.10.3', 'cs_.3.0.10.3');
  INSERT INTO iati_import (_action, _data_group, _xml, _created_by) VALUES('insert', 'AfDB', convert_from(pmt_bytea_import('afdb-burkinafaso'), 'ISO_8859_5')::xml, 'cs_.3.0.10.3');  
  INSERT INTO iati_import (_action, _data_group, _xml, _created_by) VALUES('insert', 'AfDB', convert_from(pmt_bytea_import('afdb-ethiopia'), 'ISO_8859_5')::xml, 'cs_.3.0.10.3');
  INSERT INTO iati_import (_action, _data_group, _xml, _created_by) VALUES('insert', 'AfDB', convert_from(pmt_bytea_import('afdb-ghana'), 'ISO_8859_5')::xml, 'cs_.3.0.10.3');
  INSERT INTO iati_import (_action, _data_group, _xml, _created_by) VALUES('insert', 'AfDB', convert_from(pmt_bytea_import('afdb-mali'), 'ISO_8859_5')::xml, 'cs_.3.0.10.3');
  INSERT INTO iati_import (_action, _data_group, _xml, _created_by) VALUES('insert', 'AfDB', convert_from(pmt_bytea_import('afdb-nigeria'), 'ISO_8859_5')::xml, 'cs_.3.0.10.3');
  INSERT INTO iati_import (_action, _data_group, _xml, _created_by) VALUES('insert', 'AfDB', convert_from(pmt_bytea_import('afdb-tanzania'), 'ISO_8859_5')::xml, 'cs_.3.0.10.3');
  INSERT INTO iati_import (_action, _data_group, _xml, _created_by) VALUES('insert', 'AfDB', convert_from(pmt_bytea_import('afdb-uganda'), 'ISO_8859_5')::xml, 'cs_.3.0.10.3');
  -- World Bank
  INSERT INTO classification (taxonomy_id, _name, _created_by, _updated_by) VALUES (1, 'World Bank', 'cs_.3.0.10.3', 'cs_.3.0.10.3');
  INSERT INTO iati_import (_action, _data_group, _xml, _created_by) VALUES('insert', 'World Bank', convert_from(pmt_bytea_import('worldbank-bd'), 'ISO_8859_5')::xml, 'cs_.3.0.10.3'); 
  INSERT INTO iati_import (_action, _data_group, _xml, _created_by) VALUES('insert', 'World Bank', convert_from(pmt_bytea_import('worldbank-bf'), 'ISO_8859_5')::xml, 'cs_.3.0.10.3');
  INSERT INTO iati_import (_action, _data_group, _xml, _created_by) VALUES('insert', 'World Bank', convert_from(pmt_bytea_import('worldbank-et'), 'ISO_8859_5')::xml, 'cs_.3.0.10.3');
  INSERT INTO iati_import (_action, _data_group, _xml, _created_by) VALUES('insert', 'World Bank', convert_from(pmt_bytea_import('worldbank-gh'), 'ISO_8859_5')::xml, 'cs_.3.0.10.3');
  INSERT INTO iati_import (_action, _data_group, _xml, _created_by) VALUES('insert', 'World Bank', convert_from(pmt_bytea_import('worldbank-ml'), 'ISO_8859_5')::xml, 'cs_.3.0.10.3');
  INSERT INTO iati_import (_action, _data_group, _xml, _created_by) VALUES('insert', 'World Bank', convert_from(pmt_bytea_import('worldbank-ng'), 'ISO_8859_5')::xml, 'cs_.3.0.10.3');
  INSERT INTO iati_import (_action, _data_group, _xml, _created_by) VALUES('insert', 'World Bank', convert_from(pmt_bytea_import('worldbank-tz'), 'ISO_8859_5')::xml, 'cs_.3.0.10.3');
  INSERT INTO iati_import (_action, _data_group, _xml, _created_by) VALUES('insert', 'World Bank', convert_from(pmt_bytea_import('worldbank-ug'), 'ISO_8859_5')::xml, 'cs_.3.0.10.3');
  
-- update permissions
GRANT USAGE ON SCHEMA public TO pmt_read;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO pmt_read;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO pmt_read;
GRANT USAGE ON SCHEMA public TO pmt_write;
GRANT SELECT,INSERT ON ALL TABLES IN SCHEMA public TO pmt_write;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO pmt_write;