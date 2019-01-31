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
INSERT INTO xml (action, xml) VALUES('insert',convert_from(pmt_bytea_import('ActivityDateType.xml'), 'utf8')::xml);
INSERT INTO xml (action, xml) VALUES('insert',convert_from(pmt_bytea_import('AidType.xml'), 'utf8')::xml);
INSERT INTO xml (action, xml) VALUES('insert',convert_from(pmt_bytea_import('CollaborationType.xml'), 'utf8')::xml);
INSERT INTO xml (action, xml) VALUES('insert',convert_from(pmt_bytea_import('Country.xml'), 'utf8')::xml);
INSERT INTO xml (action, xml) VALUES('insert',convert_from(pmt_bytea_import('Currency.xml'), 'utf8')::xml);
INSERT INTO xml (action, xml) VALUES('insert',convert_from(pmt_bytea_import('FinanceType.xml'), 'utf8')::xml);
INSERT INTO xml (action, xml) VALUES('insert',convert_from(pmt_bytea_import('LocationType.xml'), 'utf8')::xml);
INSERT INTO xml (action, xml) VALUES('insert',convert_from(pmt_bytea_import('OrganisationIdentifier.xml'), 'utf8')::xml);
INSERT INTO xml (action, xml) VALUES('insert',convert_from(pmt_bytea_import('OrganisationRole.xml'), 'utf8')::xml);
INSERT INTO xml (action, xml) VALUES('insert',convert_from(pmt_bytea_import('OrganisationType.xml'), 'utf8')::xml);
INSERT INTO xml (action, xml) VALUES('insert',convert_from(pmt_bytea_import('Region.xml'), 'utf8')::xml);
INSERT INTO xml (action, xml) VALUES('insert',convert_from(pmt_bytea_import('ResultType.xml'), 'utf8')::xml);
INSERT INTO xml (action, xml) VALUES('insert',convert_from(pmt_bytea_import('Sector.xml'), 'utf8')::xml);

---------
-- STEP 4
---------
-- run the following commands to add 'PMT Sector Category' a PMT Core Taxonomy
-- a category for the IATI Sector codelist
INSERT INTO taxonomy(name, description, iati_codelist, is_category, created_by, updated_by) VALUES ( N'PMT Sector Category', N'Utilized by core functionality to compare disparate sets of data.',N'Sector', TRUE, N'PMT Core Taxonomy', N'PMT Core Taxonomy');
UPDATE taxonomy SET category_id = (select taxonomy_id from taxonomy where name = 'PMT Sector Category'), updated_by = N'PMT Core Taxonomy', updated_date = current_date WHERE taxonomy_id = (select taxonomy_id from taxonomy where name ='Sector Category');
-- add classifications to PMT Sector Category
INSERT INTO classification(taxonomy_id, name, created_by, updated_by) VALUES ((select taxonomy_id from taxonomy where name = 'PMT Sector Category'), N'Business and Finances', N'PMT Core Taxonomy', N'PMT Core Taxonomy');
INSERT INTO classification(taxonomy_id, name, created_by, updated_by) VALUES ((select taxonomy_id from taxonomy where name = 'PMT Sector Category'), N'Education and Research', N'PMT Core Taxonomy', N'PMT Core Taxonomy');
INSERT INTO classification(taxonomy_id, name, created_by, updated_by) VALUES ((select taxonomy_id from taxonomy where name = 'PMT Sector Category'), N'Emergancy Response/Preparation', N'PMT Core Taxonomy', N'PMT Core Taxonomy');
INSERT INTO classification(taxonomy_id, name, created_by, updated_by) VALUES ((select taxonomy_id from taxonomy where name = 'PMT Sector Category'), N'Environmental and Animals', N'PMT Core Taxonomy', N'PMT Core Taxonomy');
INSERT INTO classification(taxonomy_id, name, created_by, updated_by) VALUES ((select taxonomy_id from taxonomy where name = 'PMT Sector Category'), N'Government and Policy', N'PMT Core Taxonomy', N'PMT Core Taxonomy');
INSERT INTO classification(taxonomy_id, name, created_by, updated_by) VALUES ((select taxonomy_id from taxonomy where name = 'PMT Sector Category'), N'Health and Social Services', N'PMT Core Taxonomy', N'PMT Core Taxonomy');
INSERT INTO classification(taxonomy_id, name, created_by, updated_by) VALUES ((select taxonomy_id from taxonomy where name = 'PMT Sector Category'), N'Infrastructure and Industry', N'PMT Core Taxonomy', N'PMT Core Taxonomy');
INSERT INTO classification(taxonomy_id, name, created_by, updated_by) VALUES ((select taxonomy_id from taxonomy where name = 'PMT Sector Category'), N'Other', N'PMT Core Taxonomy', N'PMT Core Taxonomy');
INSERT INTO classification(taxonomy_id, name, created_by, updated_by) VALUES ((select taxonomy_id from taxonomy where name = 'PMT Sector Category'), N'Resources and Commodities', N'PMT Core Taxonomy', N'PMT Core Taxonomy');
INSERT INTO classification(taxonomy_id, name, created_by, updated_by) VALUES ((select taxonomy_id from taxonomy where name = 'PMT Sector Category'), N'Transportation and Communication', N'PMT Core Taxonomy', N'PMT Core Taxonomy');
-- add PMT Sector Category to Sector Category classifications
UPDATE classification SET category_id = (select classification_id from classification where name = 'Business and Finances' and taxonomy_id = (select taxonomy_id from taxonomy where name = 'PMT Sector Category')) WHERE lower(name) = lower('ACTION RELATING TO DEBT');
UPDATE classification SET category_id = (select classification_id from classification where name = 'Other' and taxonomy_id = (select taxonomy_id from taxonomy where name = 'PMT Sector Category')) WHERE lower(name) = lower('ADMINISTRATIVE COSTS OF DONORS');
UPDATE classification SET category_id = (select classification_id from classification where name = 'Resources and Commodities' and taxonomy_id = (select taxonomy_id from taxonomy where name = 'PMT Sector Category')) WHERE lower(name) = lower('AGRICULTURE');
UPDATE classification SET category_id = (select classification_id from classification where name = 'Business and Finances' and taxonomy_id = (select taxonomy_id from taxonomy where name = 'PMT Sector Category')) WHERE lower(name) = lower('BANKING AND FINANCIAL SERVICES');
UPDATE classification SET category_id = (select classification_id from classification where name = 'Education and Research' and taxonomy_id = (select taxonomy_id from taxonomy where name = 'PMT Sector Category')) WHERE lower(name) = lower('Basic education');
UPDATE classification SET category_id = (select classification_id from classification where name = 'Health and Social Services' and taxonomy_id = (select taxonomy_id from taxonomy where name = 'PMT Sector Category')) WHERE lower(name) = lower('Basic health');
UPDATE classification SET category_id = (select classification_id from classification where name = 'Business and Finances' and taxonomy_id = (select taxonomy_id from taxonomy where name = 'PMT Sector Category')) WHERE lower(name) = lower('BUSINESS AND OTHER SERVICES');
UPDATE classification SET category_id = (select classification_id from classification where name = 'Transportation and Communication' and taxonomy_id = (select taxonomy_id from taxonomy where name = 'PMT Sector Category')) WHERE lower(name) = lower('COMMUNICATION');
UPDATE classification SET category_id = (select classification_id from classification where name = 'Government and Policy' and taxonomy_id = (select taxonomy_id from taxonomy where name = 'PMT Sector Category')) WHERE lower(name) = lower('Conflict prevention and resolution, peace and security');
UPDATE classification SET category_id = (select classification_id from classification where name = 'Infrastructure and Industry' and taxonomy_id = (select taxonomy_id from taxonomy where name = 'PMT Sector Category')) WHERE lower(name) = lower('CONSTRUCTION');
UPDATE classification SET category_id = (select classification_id from classification where name = 'Resources and Commodities' and taxonomy_id = (select taxonomy_id from taxonomy where name = 'PMT Sector Category')) WHERE lower(name) = lower('Developmental food aid/Food security assistance');
UPDATE classification SET category_id = (select classification_id from classification where name = 'Emergancy Response/Preparation' and taxonomy_id = (select taxonomy_id from taxonomy where name = 'PMT Sector Category')) WHERE lower(name) = lower('Disaster prevention and preparedness');
UPDATE classification SET category_id = (select classification_id from classification where name = 'Education and Research' and taxonomy_id = (select taxonomy_id from taxonomy where name = 'PMT Sector Category')) WHERE lower(name) = lower('Education, level unspecified');
UPDATE classification SET category_id = (select classification_id from classification where name = 'Emergancy Response/Preparation' and taxonomy_id = (select taxonomy_id from taxonomy where name = 'PMT Sector Category')) WHERE lower(name) = lower('Emergency Response');
UPDATE classification SET category_id = (select classification_id from classification where name = 'Infrastructure and Industry' and taxonomy_id = (select taxonomy_id from taxonomy where name = 'PMT Sector Category')) WHERE lower(name) = lower('ENERGY GENERATION AND SUPPLY');
UPDATE classification SET category_id = (select classification_id from classification where name = 'Environmental and Animals' and taxonomy_id = (select taxonomy_id from taxonomy where name = 'PMT Sector Category')) WHERE lower(name) = lower('FISHING');
UPDATE classification SET category_id = (select classification_id from classification where name = 'Environmental and Animals' and taxonomy_id = (select taxonomy_id from taxonomy where name = 'PMT Sector Category')) WHERE lower(name) = lower('FORESTRY');
UPDATE classification SET category_id = (select classification_id from classification where name = 'Government and Policy' and taxonomy_id = (select taxonomy_id from taxonomy where name = 'PMT Sector Category')) WHERE lower(name) = lower('General budget support');
UPDATE classification SET category_id = (select classification_id from classification where name = 'Environmental and Animals' and taxonomy_id = (select taxonomy_id from taxonomy where name = 'PMT Sector Category')) WHERE lower(name) = lower('General environmental protection');
UPDATE classification SET category_id = (select classification_id from classification where name = 'Government and Policy' and taxonomy_id = (select taxonomy_id from taxonomy where name = 'PMT Sector Category')) WHERE lower(name) = lower('Government and civil society, general');
UPDATE classification SET category_id = (select classification_id from classification where name = 'Health and Social Services' and taxonomy_id = (select taxonomy_id from taxonomy where name = 'PMT Sector Category')) WHERE lower(name) = lower('Health, general');
UPDATE classification SET category_id = (select classification_id from classification where name = 'Infrastructure and Industry' and taxonomy_id = (select taxonomy_id from taxonomy where name = 'PMT Sector Category')) WHERE lower(name) = lower('INDUSTRY');
UPDATE classification SET category_id = (select classification_id from classification where name = 'Resources and Commodities' and taxonomy_id = (select taxonomy_id from taxonomy where name = 'PMT Sector Category')) WHERE lower(name) = lower('MINERAL RESOURCES AND MINING');
UPDATE classification SET category_id = (select classification_id from classification where name = 'Resources and Commodities' and taxonomy_id = (select taxonomy_id from taxonomy where name = 'PMT Sector Category')) WHERE lower(name) = lower('Other commodity assistance');
UPDATE classification SET category_id = (select classification_id from classification where name = 'Other' and taxonomy_id = (select taxonomy_id from taxonomy where name = 'PMT Sector Category')) WHERE lower(name) = lower('Other multisector');
UPDATE classification SET category_id = (select classification_id from classification where name = 'Health and Social Services' and taxonomy_id = (select taxonomy_id from taxonomy where name = 'PMT Sector Category')) WHERE lower(name) = lower('OTHER SOCIAL INFRASTRUCTURE AND SERVICES');
UPDATE classification SET category_id = (select classification_id from classification where name = 'Health and Social Services' and taxonomy_id = (select taxonomy_id from taxonomy where name = 'PMT Sector Category')) WHERE lower(name) = lower('POPULATION POLICIES/PROGRAMMES AND REPRODUCTIVE HEALTH');
UPDATE classification SET category_id = (select classification_id from classification where name = 'Education and Research' and taxonomy_id = (select taxonomy_id from taxonomy where name = 'PMT Sector Category')) WHERE lower(name) = lower('Post-secondary education');
UPDATE classification SET category_id = (select classification_id from classification where name = 'Emergancy Response/Preparation' and taxonomy_id = (select taxonomy_id from taxonomy where name = 'PMT Sector Category')) WHERE lower(name) = lower('Reconstruction relief and rehabilitation');
UPDATE classification SET category_id = (select classification_id from classification where name = 'Other' and taxonomy_id = (select taxonomy_id from taxonomy where name = 'PMT Sector Category')) WHERE lower(name) = lower('REFUGEES IN DONOR COUNTRIES');
UPDATE classification SET category_id = (select classification_id from classification where name = 'Education and Research' and taxonomy_id = (select taxonomy_id from taxonomy where name = 'PMT Sector Category')) WHERE lower(name) = lower('Secondary education');
UPDATE classification SET category_id = (select classification_id from classification where name = 'Other' and taxonomy_id = (select taxonomy_id from taxonomy where name = 'PMT Sector Category')) WHERE lower(name) = lower('SUPPORT TO NON- GOVERNMENTAL ORGANISATIONS (NGOs)');
UPDATE classification SET category_id = (select classification_id from classification where name = 'Business and Finances' and taxonomy_id = (select taxonomy_id from taxonomy where name = 'PMT Sector Category')) WHERE lower(name) = lower('TOURISM');
UPDATE classification SET category_id = (select classification_id from classification where name = 'Government and Policy' and taxonomy_id = (select taxonomy_id from taxonomy where name = 'PMT Sector Category')) WHERE lower(name) = lower('TRADE POLICY AND REGULATIONS AND TRADE-RELATED ADJUSTMENT');
UPDATE classification SET category_id = (select classification_id from classification where name = 'Transportation and Communication' and taxonomy_id = (select taxonomy_id from taxonomy where name = 'PMT Sector Category')) WHERE lower(name) = lower('TRANSPORT AND STORAGE');
UPDATE classification SET category_id = (select classification_id from classification where name = 'Other' and taxonomy_id = (select taxonomy_id from taxonomy where name = 'PMT Sector Category')) WHERE lower(name) = lower('UNALLOCATED/ UNSPECIFIED');
UPDATE classification SET category_id = (select classification_id from classification where name = 'Resources and Commodities' and taxonomy_id = (select taxonomy_id from taxonomy where name = 'PMT Sector Category')) WHERE lower(name) = lower('WATER AND SANITATION');
