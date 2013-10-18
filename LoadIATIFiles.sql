/************************************************************
 Load a IATI Activity xml document into PMT from the Postgres 
 data directory.
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
-- Change the 'file.xml' in the below statment to the name of your IATI Activity XML
-- document and update the encoding to reflect the encoding of your file. Common 
-- encodings: utf-8, ISO-8859-1, windows-1252, us-ascii, UTF-16
-- Then replace <data group name> with a string containing the data group name that 
-- you want the data within this file to be associated to. Example: 'World Bank'. 
-- If the data group you specify in the below statement does not exist it will be created
-- during the loading process.

INSERT INTO xml (action, xml, data_group) VALUES('insert',convert_from(bytea_import('file.xml'), 'utf-8')::xml, <data group name>);

---------
-- STEP 4
---------
SELECT refresh_taxonomy_lookup();

---------
-- STEP 5
---------
VACUUM;

---------
-- STEP 6
---------	
ANALYZE;

---------
-- STEP 7
---------
-- Run the following query to find the project number for the last xml document processed 
SELECT project_id FROM xml WHERE xml_id = (SELECT MAX(xml_id) FROM xml);

-- Update the following queries WHERE statements with the returned project_id to validate your imported data.
-- See comments beside each field for information on where the data is extracted from within the IATI Activity XML schema
/******************************************************
   Data Verification Queries     
******************************************************/
-- Loaded Activities (with Activity Taxonomy)
SELECT 
a.project_id				-- assigned by the database (all activites within a single IATI Activities xml document will be assigned to a single project)
,a.activity_id 				-- assigned by the database (each activity element will recieve a unique id)
,a.title 				-- IAIT activity.title
,a.description 				-- IAIT activity.description
,a.start_date 				-- IAIT activity.activity-date@type (type="start-planned" OR type="start-actual" OR no type attribute is specified)
,a.end_date 				-- IAIT activity.activity-date@type (type="end-planned" OR type="end-actual")
,c.iati_codelist		 	-- IAIT activity.sector@code OR activity.recipient-country@code OR activity.activity-status@code. Must be valid IATI Codelist value.
,c.iati_name				-- IAIT activity.sector@code OR activity.recipient-country@code OR activity.activity-status@code. Must be valid IATI Codelist value.
,c.taxonomy				-- PMT taxonomy name for displayed iati_codelist
,c.classification			-- PMT classification name for displayed iati_name
FROM activity a
LEFT JOIN activity_taxonomy at
ON a.activity_id = at.activity_id
LEFT JOIN taxonomy_classifications c
ON at.classification_id = c.classification_id
WHERE a.project_id = <enter your project_id>

-- Loaded Locations (with Location Taxonomy)
SELECT 
a.project_id				-- assigned by the database (all activites within a single IATI Activities xml document will be assigned to a single project)
,a.activity_id 				-- assigned by the database (each activity element will recieve a unique id)
,l.location_id				-- assigned by the database (each location element will recieve a unique id)
,l.title as "location title" 		-- IAIT activity.location.name
,l.latlong				-- IAIT activity.location.coordinates
,l.lat_dd, l.long_dd ,l.x, l.y, l.georef-- assigned by the database based on the creation of point geometry 
,c.iati_codelist		 	-- IAIT activity.location.administrative@country. Must be valid IATI Codelist value.
,c.iati_name				-- IAIT activity.location.administrative@country. Must be valid IATI Codelist value.
,c.taxonomy				-- PMT taxonomy name for displayed iati_codelist
,c.classification			-- PMT classification name for displayed iati_name
FROM activity a
LEFT JOIN location l
on a.activity_id = l.activity_id
LEFT JOIN location_taxonomy lt
ON l.location_id = lt.location_id
LEFT JOIN taxonomy_classifications c
ON lt.classification_id = c.classification_id
WHERE a.project_id = <enter your project_id>

-- Loaded Financial Data (with Financial Taxonomy)
SELECT 
a.project_id				-- assigned by the database (all activites within a single IATI Activities xml document will be assigned to a single project)
,a.activity_id 				-- assigned by the database (each activity element will recieve a unique id)
,f.financial_id				-- assigned by the database (each transaction/budget element will recieve a unique id)
,f.amount				-- IAIT activity.budget.value OR activity.transaction.value
,f.start_date				-- IAIT activity.budget.value@value-date OR activity.budget.period-start@iso-date OR activity.transaction.value@value-date OR activity.transaction.transaction-date@iso-date
,f.end_date				-- IATI activity.budget.period-end@iso-date
,c.iati_codelist		 	-- IAIT activity.budget.value@currency OR activity.transaction.value@currency. Must be valid IATI Codelist value.
,c.iati_name				-- IAIT activity.budget.value@currency OR activity.transaction.value@currency. Must be valid IATI Codelist value.
,c.taxonomy				-- PMT taxonomy name for displayed iati_codelist
,c.classification			-- PMT classification name for displayed iati_name
FROM activity a
LEFT JOIN financial f
ON a.activity_id = f.activity_id
LEFT JOIN financial_taxonomy ft
ON ft.financial_id = f.financial_id
LEFT JOIN taxonomy_classifications c
ON ft.classification_id = c.classification_id
WHERE a.project_id = <enter your project_id>

-- Loaded Organization Data (with Organization Taxonomy)
SELECT DISTINCT
o.organization_id			-- assigned by the database (each unique organization will recieve a unique id)
,o.name as "organization name"		-- IATI activity.participating-org OR activity.reporting-org
,c.iati_codelist		 	-- IAIT activity.participating-org@type or activity.reporting-org@type. Must be valid IATI Codelist value.
,c.iati_name				-- IAIT activity.participating-org@type or activity.reporting-org@type. Must be valid IATI Codelist value.
,c.taxonomy				-- PMT taxonomy name for displayed iati_codelist
,c.classification			-- PMT classification name for displayed iati_name
FROM participation pp
LEFT JOIN organization o
ON pp.organization_id = o.organization_id
LEFT JOIN organization_taxonomy ot
ON o.organization_id = ot.organization_id
LEFT JOIN taxonomy_classifications c
ON ot.classification_id = c.classification_id
WHERE pp.project_id = <enter your project_id>

-- Loaded Participation Data (with Participation Taxonomy)
SELECT 
p.project_id				-- assigned by the database (all activites within a single IATI Activities xml document will be assigned to a single project)
,a.activity_id 				-- assigned by the database (each activity element will recieve a unique id)
,o.organization_id			-- assigned by the database (each unique organization will recieve a unique id)
,o.name as "organization name"		-- IATI activity.participating-org OR activity.reporting-org
,pp.reporting_org			-- IATI activity.reporting-org
,c.iati_codelist		 	-- IAIT activity.participating-org@role. Must be valid IATI Codelist value.
,c.iati_name				-- IAIT activity.participating-org@role. Must be valid IATI Codelist value.
,c.taxonomy				-- PMT taxonomy name for displayed iati_codelist
,c.classification			-- PMT classification name for displayed iati_name
FROM project p
LEFT JOIN participation pp
ON p.project_id = pp.project_id
LEFT JOIN activity a
ON pp.activity_id = a.activity_id
LEFT JOIN organization o
ON pp.organization_id = o.organization_id
LEFT JOIN participation_taxonomy pt
ON pp.participation_id = pt.participation_id
LEFT JOIN taxonomy_classifications c
ON pt.classification_id = c.classification_id
WHERE a.project_id = <enter your project_id>

-- Export the results to csv
-- After executing the csv will be located in the Postgres data directory (see Step 1)
Copy (
-- copy one of the above select statements to export the results to csv
) To '/temp/data_validation.csv' With CSV;
