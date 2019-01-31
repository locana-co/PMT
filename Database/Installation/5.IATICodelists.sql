/************************************************************
PMT Database Installation STEP #5

 Load the IATI codelists into Taxonomy from the Postgres 
 data directory.

 IMPORTANT!!! Run these commands in order and follow the 
 instructions provided.
************************************************************/
---------
-- STEP 1
---------
-- run this command it will give you a path 
SHOW data_directory;

---------
-- STEP 2
---------
-- copy all of the .xml files in the gitrepo folder IATICodelists to the root directory 
-- of the path given by the command above

---------
-- STEP 3
---------
-- run the following commands to load the xml files from the data directory into the xml table
-- via trigger that executes on each insert
INSERT INTO iati_import (_action, _xml, _created_by) VALUES('insert',convert_from(pmt_bytea_import('ActivityScope.xml'), 'utf8')::xml, 'postgres');
INSERT INTO iati_import (_action, _xml, _created_by) VALUES('insert',convert_from(pmt_bytea_import('ActivityStatus.xml'), 'utf8')::xml, 'postgres');
INSERT INTO iati_import (_action, _xml, _created_by) VALUES('insert',convert_from(pmt_bytea_import('Country.xml'), 'utf8')::xml, 'postgres');
INSERT INTO iati_import (_action, _xml, _created_by) VALUES('insert',convert_from(pmt_bytea_import('Currency.xml'), 'utf8')::xml, 'postgres');
INSERT INTO iati_import (_action, _xml, _created_by) VALUES('insert',convert_from(pmt_bytea_import('FinanceType-category.xml'), 'utf8')::xml, 'postgres');
INSERT INTO iati_import (_action, _xml, _created_by) VALUES('insert',convert_from(pmt_bytea_import('FinanceType.xml'), 'utf8')::xml, 'postgres');
INSERT INTO iati_import (_action, _xml, _created_by) VALUES('insert',convert_from(pmt_bytea_import('GazetteerAgency.xml'), 'utf8')::xml, 'postgres');
INSERT INTO iati_import (_action, _xml, _created_by) VALUES('insert',convert_from(pmt_bytea_import('GeographicExactness.xml'), 'utf8')::xml, 'postgres');
INSERT INTO iati_import (_action, _xml, _created_by) VALUES('insert',convert_from(pmt_bytea_import('GeographicLocationClass.xml'), 'utf8')::xml, 'postgres');
INSERT INTO iati_import (_action, _xml, _created_by) VALUES('insert',convert_from(pmt_bytea_import('GeographicLocationReach.xml'), 'utf8')::xml, 'postgres');
INSERT INTO iati_import (_action, _xml, _created_by) VALUES('insert',convert_from(pmt_bytea_import('GeographicVocabulary.xml'), 'utf8')::xml, 'postgres');
INSERT INTO iati_import (_action, _xml, _created_by) VALUES('insert',convert_from(pmt_bytea_import('GeographicalPrecision.xml'), 'utf8')::xml, 'postgres');
INSERT INTO iati_import (_action, _xml, _created_by) VALUES('insert',convert_from(pmt_bytea_import('Language.xml'), 'utf8')::xml, 'postgres');
INSERT INTO iati_import (_action, _xml, _created_by) VALUES('insert',convert_from(pmt_bytea_import('LocationType-category.xml'), 'utf8')::xml, 'postgres');
INSERT INTO iati_import (_action, _xml, _created_by) VALUES('insert',convert_from(pmt_bytea_import('LocationType.xml'), 'utf8')::xml, 'postgres');
INSERT INTO iati_import (_action, _xml, _created_by) VALUES('insert',convert_from(pmt_bytea_import('OrganisationRole.xml'), 'utf8')::xml, 'postgres');
INSERT INTO iati_import (_action, _xml, _created_by) VALUES('insert',convert_from(pmt_bytea_import('OrganisationType.xml'), 'utf8')::xml, 'postgres');
INSERT INTO iati_import (_action, _xml, _created_by) VALUES('insert',convert_from(pmt_bytea_import('ResultType.xml'), 'utf8')::xml, 'postgres');
INSERT INTO iati_import (_action, _xml, _created_by) VALUES('insert',convert_from(pmt_bytea_import('SectorCategory.xml'), 'utf8')::xml, 'postgres');
INSERT INTO iati_import (_action, _xml, _created_by) VALUES('insert',convert_from(pmt_bytea_import('Sector.xml'), 'utf8')::xml, 'postgres');
INSERT INTO iati_import (_action, _xml, _created_by) VALUES('insert',convert_from(pmt_bytea_import('TransactionType.xml'), 'utf8')::xml, 'postgres');
