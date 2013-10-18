/************************************************************
 Load the IATI codelists into Taxonomy from the Postgres 
 data directory.
************************************************************/
-- IMPORTANT!!! Run these commands in order and follow the instructions provided 

---------
-- STEP 1
---------
-- run this command it will give you a path 
SHOW data_directory;

---------
-- STEP 2
---------
-- copy all of the .xml files in the git repo folder IATICodelists to the root directory 
-- of the path given by the command above

---------
-- STEP 3
---------
-- run the following commands to load the xml files from the data directory into the xml table
-- there is a trigger (process_xml()) that executes on each insert
INSERT INTO xml (action, xml) VALUES('insert',convert_from(bytea_import('ActivityDateType.xml'), 'utf8')::xml);
INSERT INTO xml (action, xml) VALUES('insert',convert_from(bytea_import('AidType.xml'), 'utf8')::xml);
INSERT INTO xml (action, xml) VALUES('insert',convert_from(bytea_import('CollaborationType.xml'), 'utf8')::xml);
INSERT INTO xml (action, xml) VALUES('insert',convert_from(bytea_import('Country.xml'), 'utf8')::xml);
INSERT INTO xml (action, xml) VALUES('insert',convert_from(bytea_import('Currency.xml'), 'utf8')::xml);
INSERT INTO xml (action, xml) VALUES('insert',convert_from(bytea_import('FinanceType.xml'), 'utf8')::xml);
INSERT INTO xml (action, xml) VALUES('insert',convert_from(bytea_import('LocationType.xml'), 'utf8')::xml);
INSERT INTO xml (action, xml) VALUES('insert',convert_from(bytea_import('OrganisationIdentifier.xml'), 'utf8')::xml);
INSERT INTO xml (action, xml) VALUES('insert',convert_from(bytea_import('OrganisationRole.xml'), 'utf8')::xml);
INSERT INTO xml (action, xml) VALUES('insert',convert_from(bytea_import('OrganisationType.xml'), 'utf8')::xml);
INSERT INTO xml (action, xml) VALUES('insert',convert_from(bytea_import('Region.xml'), 'utf8')::xml);
INSERT INTO xml (action, xml) VALUES('insert',convert_from(bytea_import('ResultType.xml'), 'utf8')::xml);
INSERT INTO xml (action, xml) VALUES('insert',convert_from(bytea_import('Sector.xml'), 'utf8')::xml);
