/************************************************************
 Load a IATI Activity xml document into PMT from the Postgres 
 data directory manually.
************************************************************/
---------
-- STEP 1
---------
-- run this command to get the location of the Postgres data directory
SHOW data_directory;

---------
-- STEP 2
---------
-- copy your IATI Activity XML document into the root directory of the 
-- path given be the above command

---------
-- STEP 3
---------
-- A) Replace <data group name> with a string containing the data group name that 
-- you want the data within this file to be associated to. This is the reporting
-- organization's name and in the IATI standard is  Example: 'World Bank'. 
-- If the data group you specify in the below statement does not exist it will be created
-- during the loading process.
-- B) Change the 'file.xml' in the below statment to the name of your IATI Activity XML
-- document and update the encoding to reflect the encoding of your file. Common 
-- encodings: utf-8, ISO-8859-1, windows-1252, us-ascii, UTF-16

INSERT INTO iati_import(_data_group, _xml, _created_by) VALUES ('<data group name>', convert_from(pmt_bytea_import('file.xml'), '<encoding>')::xml,'postgres');

---------
-- STEP 4
---------
VACUUM;

---------
-- STEP 5
---------	
ANALYZE;

---------
-- STEP 6
---------
-- Run the following query to find the id for the last xml document processed 
SELECT * FROM iati_import WHERE id = (SELECT MAX(id) FROM iati_import);

-- Update the following queries WHERE statements with the returned id to validate your imported data.
-- See comments beside each field for information on where the data is extracted from within the IATI Activity XML schema
/******************************************************
   Data Verification Queries     
******************************************************/
-- Loaded Activities
SELECT 
a.id	 				-- assigned by the database (each activity element will recieve a unique id)
,a._title 				-- IATI activity.title
,a._description 			-- IATI activity.description (type=1)
,a._objective 				-- IATI activity.description (type=2)
,a._content	 			-- IATI activity.description (type=3 & type=4)
,a._plan_start_date 			-- IATI activity.activity-date (type=1)
,a._start_date 				-- IATI activity.activity-date (type=2)
,a._plan_end_date 			-- IATI activity.activity-date (type=3)
,a._end_date 				-- IATI activity.activity-date (type=4 or null)
,a._iati_identifier			-- IATI activity.iati-identifier
FROM activity a
WHERE a.iati_import_id = <enter iati_import id>
ORDER BY 1

-- Loaded Activities (with Activity Taxonomy)
SELECT 
a.id	 				-- assigned by the database (each activity element will recieve a unique id)
,a._title 				-- IATI activity.title
,at._field				-- activity field taxonomy is applied too
,c._iati_codelist		 	-- IATI codelist name
,c._iati_name				-- IATI classification code from codelist
,c.taxonomy				-- PMT taxonomy name for displayed iati_codelist
,c.classification			-- PMT classification name for displayed iati_name
FROM activity a
LEFT JOIN activity_taxonomy at
ON a.id = at.activity_id
LEFT JOIN _taxonomy_classifications c
ON at.classification_id = c.classification_id
WHERE a.iati_import_id = <enter iati_import id>
ORDER BY 1

-- Loaded Organization Data (with Organization Taxonomy)
SELECT DISTINCT
o.id					-- assigned by the database (each unique organization will recieve a unique id)
,o._name as "organization name"		-- IATI activity.participating-org.narrative
,o.iati_import_id
,c._iati_codelist		 	-- IATI codelist name
,c._iati_name				-- IATI classification code
,c.taxonomy				-- PMT taxonomy name for displayed iati_codelist
,c.classification			-- PMT classification name for displayed iati_name
FROM organization o
LEFT JOIN organization_taxonomy ot
ON o.id = ot.organization_id
LEFT JOIN _taxonomy_classifications c
ON ot.classification_id = c.classification_id
WHERE o.iati_import_id = <enter iati_import id>
ORDER BY 1

-- Loaded Participation Data (with Participation Taxonomy)
SELECT 
a.id as activity_id			-- assigned by the database (each activity element will recieve a unique id)
,o.id as organization_id		-- assigned by the database (each unique organization will recieve a unique id)
,o._name as "organization name"		-- IATI activity.participating-org.narrative
,c._iati_codelist		 	-- IATI Codelist name.
,c._iati_name				-- IATI activity.participating-org@role. Must be valid IATI Codelist value.
,c.taxonomy				-- PMT taxonomy name for displayed iati_codelist
,c.classification			-- PMT classification name for displayed iati_name
FROM activity a
JOIN participation pp
ON pp.activity_id = a.id
LEFT JOIN organization o
ON pp.organization_id = o.id
LEFT JOIN participation_taxonomy pt
ON pp.id = pt.participation_id
LEFT JOIN _taxonomy_classifications c
ON pt.classification_id = c.classification_id
WHERE a.iati_import_id = <enter iati_import id>

-- Loaded Contact Data
SELECT DISTINCT
c.id					-- assigned by the database (each unique organization will recieve a unique id)
,c._first_name				-- IATI activity.contact-info.person-name.narrative
,c._title				-- IATI activity.contact-info.job-title.narrative
,c._direct_phone			-- IATI activity.contact-info.telephone
,c._email				-- IATI activity.contact-info.email
,c._url					-- IATI activity.contact-info.webiste
,o._name				-- IATI activity.contact-info.organisation.narrative
FROM contact c
LEFT JOIN organization o
ON c.organization_id = o.id
WHERE c.iati_import_id = <enter iati_import id>
ORDER BY 1

-- Loaded Locations (with Location Taxonomy)
SELECT 
a.id as "activity_id"			-- assigned by the database (each activity element will recieve a unique id)
,l.id as "location_id"			-- assigned by the database (each location element will recieve a unique id)
,l._title as "location title" 		-- IATI activity.location.name.narrative
,l._description		 		-- IATI activity.location.description.narrative
,l._geographic_id			-- IATI activity.location.location-id.code or activity.location.administrative.code
,l._geographic_level			-- IATI activity.location.administrative.level
,l._latlong				-- IATI activity.location.coordinates
,l._lat_dd, l._long_dd ,l._x, l._y, l._georef   -- assigned by the database based on the creation of point geometry 
,c._iati_codelist		 	-- IATI Codelist
,c._iati_name				-- IATI activity.location.administrative@country. Must be valid IATI Codelist value.
,c.taxonomy				-- PMT taxonomy name for displayed iati_codelist
,c.classification			-- PMT classification name for displayed iati_name
FROM activity a
LEFT JOIN location l
on a.id = l.activity_id
LEFT JOIN location_taxonomy lt
ON l.id = lt.location_id
LEFT JOIN _taxonomy_classifications c
ON lt.classification_id = c.classification_id
WHERE a.iati_import_id = <enter iati_import id>

-- Loaded Financial Data (with Financial Taxonomy)
SELECT 
a.id as activity_id 			-- assigned by the database (each activity element will recieve a unique id)
,f.id as financial_id			-- assigned by the database (each transaction/budget element will recieve a unique id)
,f._amount				-- IATI activity.budget.value OR activity.transaction.value
,f._start_date				-- IATI activity.budget.period-start.iso-date OR activity.budget.period-start@iso-date OR activity.transaction.value@value-date OR activity.transaction.transaction-date@iso-date
,f._end_date				-- IATI activity.budget.period-end.iso-date
,f.provider_id				-- IATI activity.transaction.provider-org
,f.recipient_id				-- IATI activity.transaction.reciever-org
,c._iati_codelist		 	-- IATI Codelist name
,c._iati_name				-- IATI activity.budget.value.currency OR activity.transaction.value@currency. Must be valid IATI Codelist value.
,c.taxonomy				-- PMT taxonomy name for displayed iati_codelist
,c.classification			-- PMT classification name for displayed iati_name
FROM activity a
LEFT JOIN financial f
ON a.id = f.activity_id
LEFT JOIN financial_taxonomy ft
ON ft.financial_id = f.id
LEFT JOIN _taxonomy_classifications c
ON ft.classification_id = c.classification_id
WHERE a.iati_import_id = <enter iati_import id>
ORDER BY 1,2

-- Export the results to csv
-- After executing the csv will be located in the path specified below
-- if executing on a server, ensure you & postgres have access to the 
-- 'To' path
Copy (
-- copy one of the above select statements to export the results to csv
) To '/temp/data_validation.csv' With CSV;
