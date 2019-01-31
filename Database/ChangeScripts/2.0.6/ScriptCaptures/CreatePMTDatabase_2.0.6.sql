/*********************************************************************
	PMT Database Creation Script	
This script will create or replace the entire PMT database structure. 
**********************************************************************/
-- Enable PLPGSQL language;
CREATE OR REPLACE LANGUAGE plpgsql;

-- Enable PostGIS (includes raster)
CREATE EXTENSION IF NOT EXISTS postgis; 

-- Drop Spatial Tables (comment this section out if you have built your spatial tables once)
-- To comment use: ' -- '
DROP TABLE IF EXISTS  boundary CASCADE;					
DROP TABLE IF EXISTS  gaul0 CASCADE;			
DROP TABLE IF EXISTS  gaul1 CASCADE;			
DROP TABLE IF EXISTS  gaul2 CASCADE;				

-- Drop Tables (if they exist)
DROP TABLE IF EXISTS  activity CASCADE;
DROP TABLE IF EXISTS  activity_contact CASCADE;
DROP TABLE IF EXISTS  activity_taxonomy CASCADE;
DROP TABLE IF EXISTS  boundary_taxonomy CASCADE;	
DROP TABLE IF EXISTS  classification CASCADE;
DROP TABLE IF EXISTS  config CASCADE;
DROP TABLE IF EXISTS  contact CASCADE;
DROP TABLE IF EXISTS  contact_taxonomy CASCADE;
DROP TABLE IF EXISTS  detail CASCADE;
DROP TABLE IF EXISTS  feature_taxonomy CASCADE;
DROP TABLE IF EXISTS  financial CASCADE;
DROP TABLE IF EXISTS  financial_taxonomy CASCADE;
DROP TABLE IF EXISTS  location CASCADE;
DROP TABLE IF EXISTS  location_boundary CASCADE;
DROP TABLE IF EXISTS  location_taxonomy CASCADE;
DROP TABLE IF EXISTS  organization CASCADE;
DROP TABLE IF EXISTS  organization_taxonomy CASCADE;
DROP TABLE IF EXISTS  participation CASCADE;
DROP TABLE IF EXISTS  participation_taxonomy CASCADE;
DROP TABLE IF EXISTS  project CASCADE;
DROP TABLE IF EXISTS  project_contact CASCADE;
DROP TABLE IF EXISTS  project_taxonomy CASCADE;
DROP TABLE IF EXISTS  result CASCADE;
DROP TABLE IF EXISTS  result_taxonomy CASCADE;
DROP TABLE IF EXISTS  taxonomy CASCADE;
DROP TABLE IF EXISTS taxonomy_lookup CASCADE;
DROP TABLE IF EXISTS "user" CASCADE;
DROP TABLE IF EXISTS  xml CASCADE;

--Drop Views  (if they exist)
DROP VIEW IF EXISTS accountable_project_participants;
DROP VIEW IF EXISTS accountable_organizations;
DROP VIEW IF EXISTS active_project_activities;
DROP VIEW IF EXISTS activity_contacts;
DROP VIEW IF EXISTS activity_taxonomies;
DROP VIEW IF EXISTS location_boundary_features;
DROP VIEW IF EXISTS organization_participation; 
DROP VIEW IF EXISTS project_activity_points; 
DROP VIEW IF EXISTS project_contacts; 
DROP VIEW IF EXISTS project_taxonomies;
DROP VIEW IF EXISTS tags; 
DROP VIEW IF EXISTS taxonomy_classifications; 

--Drop Functions
DROP FUNCTION IF EXISTS refresh_taxonomy_lookup() CASCADE;
DROP FUNCTION IF EXISTS pmt_activities_by_tax(Integer, Integer, character varying) CASCADE;
DROP FUNCTION IF EXISTS pmt_bytea_import(TEXT, OUT bytea) CASCADE;
DROP FUNCTION IF EXISTS pmt_isnumeric(text) CASCADE;
DROP FUNCTION IF EXISTS pmt_isdate(text) CASCADE;
DROP FUNCTION IF EXISTS pmt_category_root(integer, integer) CASCADE;
DROP FUNCTION IF EXISTS pmt_countries(text) CASCADE;
DROP FUNCTION IF EXISTS pmt_data_groups() CASCADE;
DROP FUNCTION IF EXISTS pmt_locations_by_org(integer,integer,character varying) CASCADE;
DROP FUNCTION IF EXISTS pmt_locations_by_tax(integer, integer,character varying) CASCADE;
DROP FUNCTION IF EXISTS pmt_filter_locations(integer, character varying, character varying, character varying, date, date) CASCADE;
DROP FUNCTION IF EXISTS pmt_filter_projects(character varying, character varying, character varying, date, date) CASCADE;
DROP FUNCTION IF EXISTS pmt_filter_orgs(character varying, character varying, date, date) CASCADE;
DROP FUNCTION IF EXISTS pmt_infobox_menu(text)  CASCADE;
DROP FUNCTION IF EXISTS pmt_tax_inuse(integer, character varying, character varying)  CASCADE;
DROP FUNCTION IF EXISTS pmt_taxonomies(character varying)  CASCADE;
DROP FUNCTION IF EXISTS pmt_validate_classification(integer)  CASCADE;
DROP FUNCTION IF EXISTS pmt_validate_classifications(character varying)  CASCADE;
DROP FUNCTION IF EXISTS pmt_validate_taxonomy(integer)  CASCADE;
DROP FUNCTION IF EXISTS pmt_validate_taxonomies(character varying)  CASCADE;
DROP FUNCTION IF EXISTS pmt_validate_activities(character varying)  CASCADE;
DROP FUNCTION IF EXISTS pmt_validate_activity(integer)  CASCADE;
DROP FUNCTION IF EXISTS pmt_version()  CASCADE;

--Drop Types  (if it exists)
DROP TYPE IF EXISTS entity;
DROP TYPE IF EXISTS pmt_activities_by_tax_result_type;
DROP TYPE IF EXISTS pmt_countries_result_type;
DROP TYPE IF EXISTS pmt_data_groups_result_type;
DROP TYPE IF EXISTS pmt_locations_by_org_result_type;
DROP TYPE IF EXISTS pmt_locations_by_tax_result_type;
DROP TYPE IF EXISTS pmt_filter_locations_result;
DROP TYPE IF EXISTS pmt_filter_projects_result;
DROP TYPE IF EXISTS pmt_filter_orgs_result;
DROP TYPE IF EXISTS pmt_tax_inuse_result_type;
DROP TYPE IF EXISTS pmt_taxonomies_result_type;
DROP TYPE IF EXISTS pmt_version_result_type;
DROP TYPE IF EXISTS pmt_infobox_result_type;

/*****************************************************************
ENTITY -- a thing with distinct and independent existence.
Create the ENTITIES:
	1.  activity			
	2.  boundary			
	3.  contact
	4.  config
	5.  detail
	6.  financial			
	7.  gaul0 	(spatial)	
	8.  gaul1 	(spatial)	
	9.  gaul2 	(spatial)	
	10. location 	(spatial)	
	11. organization
	12. participation		
	13. project			
	14. result
	15. user
	16. xml
******************************************************************/
--Activity
CREATE TABLE "activity"
(
	"activity_id"		SERIAL				NOT NULL
	,"project_id"		integer 			NOT NULL		
	,"title"		character varying		
	,"label"		character varying
	,"description"		character varying
	,"content"		character varying
	,"start_date"		date
	,"end_date"		date
	,"tags"			character varying
	,"active"		boolean				NOT NULL DEFAULT TRUE
	,"retired_by"		integer	
	,"created_by" 		character varying(50)
	,"created_date" 	timestamp without time zone 	NOT NULL DEFAULT current_date
	,"updated_by" 		character varying(50)
	,"updated_date" 	timestamp without time zone 	NOT NULL DEFAULT current_date
	,CONSTRAINT activity_id PRIMARY KEY(activity_id)
);
--Boundary
CREATE TABLE "boundary"
(
	"boundary_id"		SERIAL 				NOT NULL
	,"name"			character varying(250)
	,"description" 		character varying
	,"spatial_table"	character varying(50)
	,"version" 		character varying(50)
	,"source"	 	character varying(150)
	,"active"		boolean				NOT NULL DEFAULT TRUE
	,"retired_by"		integer
	,"created_by" 		character varying(50)
	,"created_date" 	timestamp without time zone 	NOT NULL DEFAULT current_date
	,"updated_by" 		character varying(50)
	,"updated_date" 	timestamp without time zone 	NOT NULL DEFAULT current_date	
	,CONSTRAINT boundary_id PRIMARY KEY(boundary_id)
	
);
-- Configuration
CREATE TABLE "config" 
(
	"config_id" 		SERIAL				NOT NULL
	,"version"		numeric(2,1)
	,"iteration" 		integer
	,"changeset" 		integer
	,"app_db"		character varying(25)
	,"app_db_server"	text
	,"download_dir"		text
	,"created_date" 	timestamp without time zone 	NOT NULL DEFAULT current_date
	,"updated_date" 	timestamp without time zone 	NOT NULL DEFAULT current_date
	,CONSTRAINT config_id PRIMARY KEY(config_id)
);
-- add the current configuration information
INSERT INTO config(version, iteration, changeset, app_db, app_db_server, download_dir) 
VALUES (2.0, 6, 0, 'app1', 'localhost', 'C:/Program Files/PostgreSQL/9.2/data');
--Contact
CREATE TABLE "contact"
(
	"contact_id"		SERIAL				NOT NULL
	,"organization_id"	integer 		
	,"salutation" 		character varying(16)
	,"first_name" 		character varying(64)
	,"initial" 		character varying(1)
	,"last_name" 		character varying(128)
	,"title" 		character varying(75)
	,"address1" 		character varying(150)
	,"address2" 		character varying(150)
	,"city" 		character varying(30)
	,"state_providence" 	character varying(50)
	,"postal_code" 		character varying(32)
	,"country" 		character varying(50)
	,"direct_phone" 	character varying(21)
	,"mobile_phone" 	character varying(21)
	,"fax" 			character varying(21)
	,"email" 		character varying(100)	
	,"url" 			character varying(100)
	,"active"		boolean				NOT NULL DEFAULT TRUE
	,"retired_by"		integer
	,"created_by" 		character varying(50)
	,"created_date" 	timestamp without time zone 	NOT NULL DEFAULT current_date
	,"updated_by" 		character varying(50)
	,"updated_date" 	timestamp without time zone 	NOT NULL DEFAULT current_date	
	,CONSTRAINT contact_id PRIMARY KEY(contact_id)
	
);
-- Detail
CREATE TABLE "detail"
(
	"detail_id"		SERIAL 				NOT NULL
	,"project_id"		integer				NOT NULL
	,"activity_id"		integer
	,"title"		character varying		
	,"description"		character varying
	,"amount"		numeric(12,2)
	,"active"		boolean				NOT NULL DEFAULT TRUE
	,"retired_by"		integer
	,"created_by" 		character varying(50)
	,"created_date" 	timestamp without time zone 	NOT NULL DEFAULT current_date
	,"updated_by" 		character varying(50)
	,"updated_date" 	timestamp without time zone 	NOT NULL DEFAULT current_date	
	,CONSTRAINT detail_id PRIMARY KEY(detail_id)
	
);
--Financial
CREATE TABLE "financial"
(
	"financial_id"		SERIAL 				NOT NULL
	,"project_id"		integer				NOT NULL
	,"activity_id"		integer
	,"amount"		numeric(100,2)
	,"start_date"		date
	,"end_date"		date
	,"active"		boolean				NOT NULL DEFAULT TRUE
	,"retired_by"		integer
	,"created_by" 		character varying(50)
	,"created_date" 	timestamp without time zone 	NOT NULL DEFAULT current_date
	,"updated_by" 		character varying(50)
	,"updated_date" 	timestamp without time zone 	NOT NULL DEFAULT current_date	
	,CONSTRAINT financial_id PRIMARY KEY(financial_id)
	
);
--GAUL Level 0
CREATE TABLE "gaul0"
(
	"feature_id"		SERIAL 				NOT NULL
	,"boundary_id"		integer
	,"code"			character varying(50)
	,"name"			character varying
	,"label"		character varying
	,"polygon"		geometry
	,"polygon_simple_med"	geometry
	,"polygon_simple_high"	geometry
	,"active"		boolean				NOT NULL DEFAULT TRUE
	,"retired_by"		integer
	,"created_by" 		character varying(50)
	,"created_date" 	timestamp without time zone 	NOT NULL DEFAULT current_date
	,"updated_by" 		character varying(50)
	,"updated_date" 	timestamp without time zone 	NOT NULL DEFAULT current_date	
	,CONSTRAINT gual0_id PRIMARY KEY(feature_id)	
	,CONSTRAINT gual0_geotype_polygon CHECK (geometrytype(polygon) = 'POLYGON'::text OR geometrytype(polygon) = 'MULTIPOLYGON'::text OR polygon IS NULL)
	,CONSTRAINT gual0_srid_polygon CHECK (ST_SRID(polygon) = 4326)
);
CREATE INDEX idx_gaul0_geom ON gaul0 USING GIST(polygon);
--GAUL Level 1
CREATE TABLE "gaul1"
(
	"feature_id"		SERIAL 				NOT NULL
	,"boundary_id"		integer
	,"code"			character varying(50)
	,"name"			character varying
	,"gaul0_name"		character varying
	,"label"		character varying
	,"polygon"		geometry
	,"polygon_simple_med"	geometry
	,"polygon_simple_high"	geometry
	,"active"		boolean				NOT NULL DEFAULT TRUE
	,"retired_by"		integer
	,"created_by" 		character varying(50)
	,"created_date" 	timestamp without time zone 	NOT NULL DEFAULT current_date
	,"updated_by" 		character varying(50)
	,"updated_date" 	timestamp without time zone 	NOT NULL DEFAULT current_date	
	,CONSTRAINT gual1_id PRIMARY KEY(feature_id)	
	,CONSTRAINT gual1_geotype_polygon CHECK (geometrytype(polygon) = 'POLYGON'::text OR geometrytype(polygon) = 'MULTIPOLYGON'::text OR polygon IS NULL)
	,CONSTRAINT gual1_srid_polygon CHECK (ST_SRID(polygon) = 4326)
);
CREATE INDEX idx_gaul1_geom ON gaul1 USING GIST(polygon);
--GAUL Level 2
CREATE TABLE "gaul2"
(
	"feature_id"		SERIAL 				NOT NULL
	,"boundary_id"		integer
	,"code"			character varying(50)
	,"name"			character varying
	,"gaul0_name"		character varying
	,"gaul1_name"		character varying
	,"label"		character varying
	,"polygon"		geometry
	,"polygon_simple_med"	geometry
	,"polygon_simple_high"	geometry
	,"active"		boolean				NOT NULL DEFAULT TRUE
	,"retired_by"		integer
	,"created_by" 		character varying(50)
	,"created_date" 	timestamp without time zone 	NOT NULL DEFAULT current_date
	,"updated_by" 		character varying(50)
	,"updated_date" 	timestamp without time zone 	NOT NULL DEFAULT current_date	
	,CONSTRAINT gual2_id PRIMARY KEY(feature_id)	
	,CONSTRAINT gual2_geotype_polygon CHECK (geometrytype(polygon) = 'POLYGON'::text OR geometrytype(polygon) = 'MULTIPOLYGON'::text OR polygon IS NULL)
	,CONSTRAINT gual2_srid_polygon CHECK (ST_SRID(polygon) = 4326)
);
CREATE INDEX idx_gaul2_geom ON gaul2 USING GIST(polygon);
--Location
CREATE TABLE "location"
(
	"location_id"		SERIAL 				NOT NULL
	,"project_id"		integer 			NOT NULL
	,"activity_id"		integer 			NOT NULL	
	,"title"		character varying
	,"description"		character varying
	,"x"			integer
	,"y"			integer
	,"lat_dd"		decimal
	,"long_dd"		decimal		
	,"latlong"		character varying(100)
	,"georef"		character varying(20)
	,"point"		geometry
	,"active"		boolean				NOT NULL DEFAULT TRUE	
	,"retired_by"		integer
	,"created_by" 		character varying(50)
	,"created_date" 	timestamp without time zone 	NOT NULL DEFAULT current_date
	,"updated_by" 		character varying(50)
	,"updated_date" 	timestamp without time zone 	NOT NULL DEFAULT current_date
	,CONSTRAINT location_id PRIMARY KEY(location_id)
);
CREATE INDEX idx_location_geom ON public.location USING GIST(point);
--Organization
CREATE TABLE "organization"
(
	"organization_id"	SERIAL				NOT NULL
	,"name"			character varying(255)
	,"address1" 		character varying(150)
	,"address2" 		character varying(150)
	,"city" 		character varying(30)
	,"state_providence" 	character varying(50)
	,"postal_code" 		character varying(32)
	,"country" 		character varying(50)
	,"direct_phone" 	character varying(21)
	,"mobile_phone" 	character varying(21)
	,"fax" 			character varying(21)
	,"email" 		character varying(50)	
	,"url" 			character varying(100)
	,"created_by" 		character varying(50)
	,"active"		boolean				NOT NULL DEFAULT TRUE
	,"retired_by"		integer
	,"created_date" 	timestamp without time zone 	NOT NULL DEFAULT current_date
	,"updated_by" 		character varying(50)
	,"updated_date" 	timestamp without time zone 	NOT NULL DEFAULT current_date	
	,CONSTRAINT organization_id PRIMARY KEY(organization_id)
	
);
--Participation
CREATE TABLE "participation"
(
	"participation_id"	SERIAL				NOT NULL
	,"project_id"		integer 			NOT NULL
	,"activity_id"		integer		
	,"organization_id"	integer				NOT NULL
	,"reporting_org"	boolean				NOT NULL DEFAULT FALSE
	,"active"		boolean				NOT NULL DEFAULT TRUE
	,"retired_by"		integer
	,"created_by" 		character varying(50)
	,"created_date" 	timestamp without time zone 	NOT NULL DEFAULT current_date
	,"updated_by" 		character varying(50)
	,"updated_date" 	timestamp without time zone 	NOT NULL DEFAULT current_date
	,CONSTRAINT participation_id PRIMARY KEY(participation_id)
);
--Project
CREATE TABLE "project"
(
	"project_id"		SERIAL				NOT NULL 
	,"title"		character varying		
	,"label"		character varying
	,"description"		character varying
	,"url"			character varying
	,"start_date"		date
	,"end_date"		date	
	,"tags"			character varying
	,"active"		boolean				NOT NULL DEFAULT TRUE
	,"retired_by"		integer
	,"created_by" 		character varying(50)
	,"created_date" 	timestamp without time zone 	NOT NULL DEFAULT current_date
	,"updated_by" 		character varying(50)
	,"updated_date" 	timestamp without time zone 	NOT NULL DEFAULT current_date
	,CONSTRAINT project_id PRIMARY KEY(project_id)
);
--Result
CREATE TABLE "result"
(
	"result_id"		SERIAL 				NOT NULL
	,"activity_id"		integer 			NOT NULL
	,"title"		character varying
	,"description"		character varying
	,"active"		boolean				NOT NULL DEFAULT TRUE
	,"retired_by"		integer
	,"created_by" 		character varying(50)
	,"created_date" 	timestamp without time zone 	NOT NULL DEFAULT current_date
	,"updated_by" 		character varying(50)
	,"updated_date" 	timestamp without time zone 	NOT NULL DEFAULT current_date
	,CONSTRAINT result_id PRIMARY KEY(result_id)
);
-- User
CREATE TABLE "user"
(
	"user_id"		SERIAL				NOT NULL		
	,"first_name" 		character varying(150)
	,"last_name" 		character varying(150)
	,"username"		character varying(255)
	,"email"		character varying(255)
	,"password"		character varying(255)	
	,"active"		boolean				NOT NULL DEFAULT TRUE
	,"retired_by"		integer	
	,"created_by" 		character varying(50)
	,"created_date" 	timestamp without time zone 	NOT NULL DEFAULT now()
	,"updated_by" 		character varying(50)
	,"updated_date" 	timestamp without time zone 	NOT NULL DEFAULT now()
	,CONSTRAINT user_id PRIMARY KEY(user_id)
);
-- XML
CREATE TABLE "xml"
(
	"xml_id" 		SERIAL				NOT NULL
	,"project_id"		integer
	,"action" 		character varying(25)
	,"type" 		character varying(50)
	,"taxonomy"		character varying(100)
	,"data_group"		character varying(100)
	,"error"		text
	,"xml" 			xml
	,CONSTRAINT xml_id PRIMARY KEY(xml_id)
);
/*****************************************************************
TAXONOMY -- the science or technique of classification.
Create TAXONOMY:
	1. Taxonomy
	2. Classification
******************************************************************/
CREATE TABLE "taxonomy"
(
	"taxonomy_id"		SERIAL				NOT NULL 
	,"name"			character varying(255)	
	,"description"		character varying	
	,"iati_codelist"	character varying(100)
	,"category_id"		integer
	,"is_category"		boolean				NOT NULL DEFAULT FALSE
	,"active"		boolean				NOT NULL DEFAULT TRUE
	,"retired_by"		integer
	,"created_by" 		character varying(50)
	,"created_date" 	timestamp without time zone 	NOT NULL DEFAULT current_date
	,"updated_by" 		character varying(50)
	,"updated_date" 	timestamp without time zone 	NOT NULL DEFAULT current_date
	,CONSTRAINT taxonomy_id PRIMARY KEY(taxonomy_id)
	
);
-- insert core taxonomy
INSERT INTO taxonomy(name, description, iati_codelist, created_by, created_date, updated_by, updated_date) VALUES (N'Data Group', N'Utilized by core functionality to group projects and all associated data.', null, N'PMT Core Taxonomy', current_date, N'PMT Core Taxonomy', current_date);
CREATE TABLE "classification"
(
	"classification_id"	SERIAL				NOT NULL 
	,"taxonomy_id"		integer 
	,"identifier"		integer
	,"code"			character varying(25)			
	,"name"			character varying(255)	
	,"description"		character varying		
	,"min"			decimal
	,"max"			decimal	
	,"iati_code"		character varying(25)
	,"iati_name"		character varying(255)
	,"iati_description"	character varying
	,"category_id"		integer
	,"active"		boolean				NOT NULL DEFAULT TRUE
	,"retired_by"		integer
	,"created_by" 		character varying(50)
	,"created_date" 	timestamp without time zone 	NOT NULL DEFAULT current_date
	,"updated_by" 		character varying(50)
	,"updated_date" 	timestamp without time zone 	NOT NULL DEFAULT current_date
	,CONSTRAINT classification_id PRIMARY KEY(classification_id)
);
/*****************************************************************
JUNCTION -- tables that support relationships between two entities
Create JUNCTIONS:
	1.  activity_contact 
	2.  activity_taxonomy
	3.  boundary_taxonomy	
	4.  contact_taxonomy
	5.  feature_taxonomy
	6.  financial_taxonomy
	7.  location_boundary
	8.  location_taxonomy
	9.  organization_taxonomy
	10. participation_taxonomy
	11. project_contact 
	12. project_taxonomy 
	13. result_taxonomy
******************************************************************/
--activity_contact
CREATE TABLE "activity_contact"
(
	"activity_id"		integer				NOT NULL
	,"contact_id"		integer				NOT NULL
	,CONSTRAINT activity_contact_id PRIMARY KEY(activity_id,contact_id)
);
--activity_taxonomy
CREATE TABLE "activity_taxonomy"
(
	"activity_id"		integer				NOT NULL
	,"classification_id"	integer				NOT NULL
	,"field"		character varying(50)		NULL
	,CONSTRAINT activity_taxonomy_id PRIMARY KEY(activity_id,classification_id,field)
);
--boundary_taxonomy
CREATE TABLE "boundary_taxonomy"
(
	"boundary_id"		integer				NOT NULL
	,"classification_id"	integer				NOT NULL
	,"field"		character varying(50)		NULL
	,CONSTRAINT boundary_taxonomy_id PRIMARY KEY(boundary_id,classification_id,field)
);
--contact_taxonomy
CREATE TABLE "contact_taxonomy"
(
	"contact_id"		integer				NOT NULL
	,"classification_id"	integer				NOT NULL
	,"field"		character varying(50)		NULL
	,CONSTRAINT contact_taxonomy_id PRIMARY KEY(contact_id,classification_id,field)
);
--feature_taxonomy
CREATE TABLE "feature_taxonomy"
(
	"feature_id"		integer				NOT NULL
	,"boundary_id"		integer				NOT NULL
	,"classification_id"	integer				NOT NULL
	,"field"		character varying(50)		NULL
	,CONSTRAINT feature_taxonomy_id PRIMARY KEY(feature_id,boundary_id,classification_id,field)
);
--financial_taxonomy
CREATE TABLE "financial_taxonomy"
(
	"financial_id"		integer				NOT NULL
	,"classification_id"	integer				NOT NULL
	,"field"		character varying(50)		NULL
	,CONSTRAINT financial_taxonomy_id PRIMARY KEY(financial_id,classification_id,field)
);
--location_boundary
CREATE TABLE "location_boundary"
(
	"location_id"		integer				NOT NULL
	,"boundary_id"		integer				NOT NULL
	,"feature_id"		integer				NOT NULL
	,CONSTRAINT location_boundary_id PRIMARY KEY(location_id,boundary_id,feature_id)
);
--location_taxonomy
CREATE TABLE "location_taxonomy"
(
	"location_id"		integer				NOT NULL
	,"classification_id"	integer				NOT NULL
	,"field"		character varying(50)		NULL
	,CONSTRAINT location_taxonomy_id PRIMARY KEY(location_id,classification_id,field)
);
--organization_taxonomy
CREATE TABLE "organization_taxonomy"
(
	"organization_id"	integer				NOT NULL
	,"classification_id"	integer				NOT NULL
	,"field"		character varying(50)		NULL
	,CONSTRAINT organization_taxonomy_id PRIMARY KEY(organization_id,classification_id,field)
);
--participation_taxonomy
CREATE TABLE "participation_taxonomy"
(
	"participation_id"	integer				NOT NULL
	,"classification_id"	integer				NOT NULL
	,"field"		character varying(50)		NULL
	,CONSTRAINT participation_taxonomy_id PRIMARY KEY(participation_id,classification_id,field)
);
--project_contact
CREATE TABLE "project_contact"
(
	"project_id"		integer				NOT NULL
	,"contact_id"		integer				NOT NULL
	,CONSTRAINT project_contact_id PRIMARY KEY(project_id,contact_id)
);
--project_taxonomy
CREATE TABLE "project_taxonomy"
(
	"project_id"		integer				NOT NULL
	,"classification_id"	integer				NOT NULL
	,"field"		character varying(50)		NULL
	,CONSTRAINT project_taxonomy_id PRIMARY KEY(project_id,classification_id,field)
);
--result_taxonomy
CREATE TABLE "result_taxonomy"
(
	"result_id"		integer				NOT NULL
	,"classification_id"	integer				NOT NULL
	,"field"		character varying(50)		NULL
	,CONSTRAINT result_taxonomy_id PRIMARY KEY(result_id,classification_id,field)
);
/*****************************************************************
MATERIALIZED VIEWS -- The version of Postgres (9.2) doesn't support
materialized views. So these tables and associated functions are
designed to support this database functionality until PMT is upgraded
to a version supporting materialized views (Postgres 9.3 or higher)
Create MATERIALIZED VIEWS:
	1. taxonomy_lookup
******************************************************************/
CREATE TABLE "taxonomy_lookup"
(
	"taxonomy_lookup_id"	SERIAL				NOT NULL
	,"project_id"		integer 					
	,"activity_id"		integer 
	,"location_id"		integer 
	,"organization_id"	integer 
	,"participation_id"	integer 
	,"start_date"		date
	,"end_date"		date
	,"x"			integer
	,"y"			integer
	,"georef"		character varying(20)
	,"taxonomy_id"		integer 
	,"classification_id"	integer 
	,CONSTRAINT taxonomy_lookup_id PRIMARY KEY(taxonomy_lookup_id)
);

-- function to support the taxonomy_lookup table
CREATE OR REPLACE FUNCTION refresh_taxonomy_lookup() RETURNS integer AS $$
BEGIN
    RAISE NOTICE 'Refreshing taxonomy_lookup...';

        EXECUTE 'TRUNCATE TABLE taxonomy_lookup';
        EXECUTE 'INSERT INTO taxonomy_lookup(project_id, activity_id, location_id, organization_id, participation_id, start_date, end_date, x, y, georef, taxonomy_id, classification_id) '
                || 'SELECT project_id, activity_id, location_id, organization_id, participation_id, activity_start, activity_end, x, y, georef, t.taxonomy_id, foo.classification_id ' 
		|| 'FROM(SELECT pa.project_id, pa.activity_id, pa.location_id, pa.organization_id, pa.participation_id, pa.activity_start, pa.activity_end, pa.x, pa.y, pa.georef, et.classification_id '
		|| 'FROM active_project_activities pa '
		|| 'JOIN entity_taxonomy et '
		|| 'ON pa.project_id = et.id AND field = ''project_id'' '
		|| 'UNION '
		|| 'SELECT pa.project_id, pa.activity_id, pa.location_id, pa.organization_id, pa.participation_id, pa.activity_start, pa.activity_end, pa.x, pa.y, pa.georef, et.classification_id '
		|| 'FROM active_project_activities pa '
		|| 'JOIN entity_taxonomy et '
		|| 'ON pa.activity_id = et.id AND field = ''activity_id'' '
		|| 'UNION '
		|| 'SELECT pa.project_id, pa.activity_id, pa.location_id, pa.organization_id, pa.participation_id, pa.activity_start, pa.activity_end, pa.x, pa.y, pa.georef, et.classification_id '
		|| 'FROM active_project_activities pa '
		|| 'JOIN entity_taxonomy et '
		|| 'ON pa.location_id = et.id AND field = ''location_id'' '
		|| 'UNION '
		|| 'SELECT pa.project_id, pa.activity_id, pa.location_id, pa.organization_id, pa.participation_id, pa.activity_start, pa.activity_end, pa.x, pa.y, pa.georef, et.classification_id ' 
		|| 'FROM active_project_activities pa '
		|| 'JOIN entity_taxonomy et '
		|| 'ON pa.organization_id = et.id AND field = ''organization_id'' '
		|| 'UNION '
		|| 'SELECT pa.project_id, pa.activity_id, pa.location_id, pa.organization_id, pa.participation_id, pa.activity_start, pa.activity_end, pa.x, pa.y, pa.georef, et.classification_id '
		|| 'FROM active_project_activities pa '
		|| 'JOIN entity_taxonomy et '
		|| 'ON pa.participation_id = et.id AND field = ''participation_id'' '
		|| ') as foo '
		|| 'JOIN classification c '
		|| 'ON foo.classification_id = c.classification_id '
		|| 'JOIN taxonomy t '
		|| 'ON c.taxonomy_id = t.taxonomy_id ';

    RAISE NOTICE 'Done refreshing taxonomy_lookup.';
    RETURN 1;
END;
$$ LANGUAGE plpgsql;
-- SELECT refresh_taxonomy_lookup();
/*****************************************************************
TRIGGERS -- is procedural code that is automatically executed in 
response to certain events on a particular table or view. Possible 
events: new record, updated record, deleted record.
Create TRIGGERS:
	1. upd_geometry_formats - before a location record is created
	or updated, the geometry is formated as lat/long, georef
	and x&y coordinates. Updates location table's x, y, latlong 
	and georef fields respectively.
	2. upd_boundary_features - before a location record is 
	created or updated, the relationship between the point and
	any boundary feature that contains it, is captured. Updates 
	location_boundary table records related to current location.
	3. process_xml - before a xml record is created, the xml file 
	stored in the xml field is processed if it is a recognized 
	format (e.g. IATI codelist, IATI activity)
******************************************************************/

/******************************************************************
  upd_geometry_formats
******************************************************************/
CREATE OR REPLACE FUNCTION upd_geometry_formats()
RETURNS trigger AS $upd_geometry_formats$
    DECLARE
	id integer;
	rec record;
	latitude character varying;		-- latitude
	longitude character varying;		-- longitude
	lat_dd decimal;				-- latitude decimal degrees
	long_dd decimal;			-- longitude decimal degrees
	lat_d integer;				-- latitude degrees
	lat_m integer;				-- latitude mintues
	lat_s integer;				-- latitude seconds
	lat_c character varying(3);		-- latitude direction (N,E,W,S)
	long_d integer;				-- longitude degrees
	long_m integer;				-- longitude minutes
	long_s integer;				-- longitude seconds
	long_c character varying(3);		-- longitude direction (N,E,W,S)
	news_lat_d integer;			-- starting latitude degrees (news rule)
	news_lat_m integer;			-- starting latitude mintues (news rule)
	news_lat_s integer;			-- starting latitude seconds (news rule)
	news_lat_add boolean;			-- news flag for operation N,E(+) W,S(-)
	news_long_d integer;			-- starting longitude degrees (news rule)
	news_long_m integer;			-- starting longitude mintues (news rule)
	news_long_s integer;			-- starting longitude seconds (news rule)
	news_long_add boolean;			-- news flag for operation N,E(+) W,S(-)
	news_lat_div1 integer; 			-- news rule division #1 latitude
	news_lat_div2 integer; 			-- news rule division #2 latitude
	news_lat_div3 integer; 			-- news rule division #3 latitude
	news_lat_div4 integer; 			-- news rule division #4 latitude
	news_long_div1 integer; 		-- news rule division #1 longitude
	news_long_div2 integer; 		-- news rule division #2 longitude
	news_long_div3 integer; 		-- news rule division #3 longitude	
	news_long_div4 integer; 		-- news rule division #4 longitude	
	georef text ARRAY[4];			-- georef (long then lat)
	alpha text ARRAY[24];			-- georef grid
    BEGIN	
	-- calculate GEOREF format from lat/long using the Federation of Americation Scientists (FAS) NEWS method
	RAISE NOTICE 'Refreshing geometry formats for location_id % ...', NEW.location_id;
	-- alphanumerical relationship array ('O' & 'I" are not used in GEOREF)
	alpha := '{"A","B","C","D","E","F","G","H","J","K","L","M","N","P","Q","R","S","T","U","V","W","X","Y","Z"}';

	IF ST_IsEmpty(NEW.point) THEN
		-- no geometry
		RAISE NOTICE 'The point was empty cannot format.';
	ELSE	
		-- get latitude and longitude from geometry
		latitude := substring(ST_AsLatLonText(NEW.point, 'D°M''S"C') from 0 for position(' ' in ST_AsLatLonText(NEW.point, 'D°M''S"C')));
		longitude := substring(ST_AsLatLonText(NEW.point, 'D°M''S"C') from position(' ' in ST_AsLatLonText(NEW.point, 'D°M''S"C')) for octet_length(ST_AsLatLonText(NEW.point, 'D°M''S"C')) - position(' ' in ST_AsLatLonText(NEW.point, 'D°M''S"C')) );
		
		--RAISE NOTICE 'Latitude/Longitude Decimal Degrees: %', ST_AsLatLonText(NEW.point, 'D.DDDDDD'); 
		--RAISE NOTICE 'Latitude Decimal Degrees: %', substring(ST_AsLatLonText(NEW.point, 'D.DDDDDD') from 0 for position(' ' in ST_AsLatLonText(NEW.point, 'D.DDDDDD')));
		NEW.lat_dd := CAST(substring(ST_AsLatLonText(NEW.point, 'D.DDDDDD') from 0 for position(' ' in ST_AsLatLonText(NEW.point, 'D.DDDDDD'))) AS decimal);
		--RAISE NOTICE 'Longitude Decimal Degrees: %', substring(ST_AsLatLonText(NEW.point, 'D.DDDDDD') from position(' ' in ST_AsLatLonText(NEW.point, 'D.DDDDDD')) for octet_length(ST_AsLatLonText(NEW.point, 'D.DDDDDD')) - position(' ' in ST_AsLatLonText(NEW.point, 'D.DDDDDD')) );
		NEW.long_dd := CAST(substring(ST_AsLatLonText(NEW.point, 'D.DDDDDD') from position(' ' in ST_AsLatLonText(NEW.point, 'D.DDDDDD')) for octet_length(ST_AsLatLonText(NEW.point, 'D.DDDDDD')) - position(' ' in ST_AsLatLonText(NEW.point, 'D.DDDDDD')) ) AS decimal);
		--RAISE NOTICE 'The latitude is: %', latitude;
		--RAISE NOTICE 'The longitude is: %', longitude;
		NEW.latlong := ST_AsLatLonText(NEW.point, 'D°M''S"C');
		--RAISE NOTICE 'The latlong is: %', NEW.latlong;
		NEW.x := CAST(ST_X(ST_Transform(ST_SetSRID(NEW.point,4326),3857)) AS integer); 
		--RAISE NOTICE 'The x is: %', NEW.x;
		NEW.y := CAST(ST_Y(ST_Transform(ST_SetSRID(NEW.point,4326),3857)) AS integer);
		--RAISE NOTICE 'The y is: %', NEW.y;
		
		lat_d := NULLIF(substring(latitude from 0 for position('°' in latitude)), '')::int;
		lat_m := NULLIF(substring(latitude from position('°' in latitude)+1 for position('''' in latitude) - position('°' in latitude)-1), '')::int;
		lat_s := NULLIF(substring(latitude from position('''' in latitude)+1 for position('"' in latitude) - position('''' in latitude)-1), '')::int;
		lat_c := NULLIF(substring(latitude from position('"' in latitude)+1 for position('"' in latitude) - position('''' in latitude)-1), '')::character varying(3);
		--RAISE NOTICE 'The length of latitude: %', length(trim(latitude));
		--RAISE NOTICE 'The length of longitude: %', length(trim(longitude));
		--RAISE NOTICE 'The lat (dmsc): %', lat_d || ' ' || lat_m || ' ' || lat_s || ' ' || lat_c; 
		long_d := NULLIF(substring(longitude from 0 for position('°' in longitude)), '')::int;
		long_m := NULLIF(substring(longitude from position('°' in longitude)+1 for position('''' in longitude) - position('°' in longitude)-1), '')::int;
		long_s := NULLIF(substring(longitude from position('''' in longitude)+1 for position('"' in longitude) - position('''' in longitude)-1), '')::int;
		long_c := NULLIF(substring(longitude from position('"' in longitude)+1 for position('"' in longitude) - position('''' in longitude)-1), '')::character varying(3);
		--RAISE NOTICE 'The long (dmsc): %', long_d || ' ' || long_m || ' ' || long_s || ' ' || long_c; 
		--calculate longitude using NEWS rule
		CASE long_c -- longitude direction
			WHEN 'N' THEN -- north
				-- 90°00'00" (starting longitude) + longitude
				news_long_d = 90;
				news_long_add := true;
				news_long_m := 0;
				news_long_s := 0;
			WHEN 'E' THEN
				--180°00'00" (starting longitude) + longitude
				news_long_d = 180;
				news_long_add := true;
				news_long_m := 0;
				news_long_s := 0;
			WHEN 'W' THEN	
				--180°00'00" (starting longitude) - longitude
				news_long_add := false;
				-- if minutes and seconds is zero we don't need to borrow to subtract
				IF long_m = 0 AND long_s = 0 THEN
					news_long_d = 180;
					news_long_m := 0;
					news_long_s := 0;
				-- if not zero we need to borrow so 180°00'00" becomes 179°59'60"
				ELSE
					news_long_d = 179;
					news_long_m := 59;
					news_long_s := 60;
				END IF;
			WHEN 'S' THEN
				-- 90°00'00" (starting longitude) - longitude
				news_long_add := false;
				-- if minutes and seconds is zero we don't need to borrow to subtract
				IF long_m = 0 AND long_s = 0 THEN
					news_long_d = 90;
					news_long_m := 0;
					news_long_s := 0;
				-- if not zero we need to borrow so 90°00'00" becomes 89°59'60"
				ELSE
					news_long_d = 89;
					news_long_m := 59;
					news_long_s := 60;
				END IF;	
			ELSE
			-- bad direction or null
		END CASE;
		
		IF news_long_add THEN
			news_long_div1 := (news_long_d + long_d) / 15;
			news_long_div2 := (news_long_d + long_d) % 15;
			news_long_div3 := news_long_m + long_m;
			news_long_div4 := news_long_s + long_s;
		ELSE
			news_long_div1 := (news_long_d - long_d) / 15;
			news_long_div2 := (news_long_d - long_d) % 15;
			news_long_div3 := news_long_m - long_m;
			news_long_div4 := news_long_s - long_s;
		END IF;
		
		--calculate latitude using NEWS rule
		CASE lat_c -- latitude direction
			WHEN 'N' THEN -- north
				-- 90°00'00" (starting latitude) + latitude
				news_lat_d = 90;
				news_lat_add := true;
				news_lat_m := 0;
				news_lat_s := 0;
			WHEN 'E' THEN
				--180°00'00" (starting latitude) + latitude
				news_lat_d = 180;
				news_lat_add := true;
				news_lat_m := 0;
				news_lat_s := 0;
			WHEN 'W' THEN	
				--180°00'00" (starting latitude) - latitude
				news_lat_add := false;				
				-- if minutes and seconds is zero we don't need to borrow to subtract
				IF lat_m = 0 AND lat_s = 0 THEN
					news_lat_d = 180;
					news_lat_m := 0;
					news_lat_s := 0;
				-- if not zero we need to borrow so 180°00'00" becomes 179°59'60"
				ELSE
					news_lat_d = 179;
					news_lat_m := 59;
					news_lat_s := 60;
				END IF;			
			WHEN 'S' THEN
				-- 90°00'00" (starting latitude) - latitude
				news_lat_add := false;			
				-- if minutes and seconds is zero we don't need to borrow to subtract
				IF lat_m = 0 AND lat_s = 0 THEN
					news_lat_d = 90;
					news_lat_m := 0;
					news_lat_s := 0;
				-- if not zero we need to borrow so 90°00'00" becomes 89°59'60"
				ELSE
					news_lat_d = 89;
					news_lat_m := 59;
					news_lat_s := 60;
				END IF;				
			ELSE
			--null or bad direction
		END CASE;
		
		IF news_lat_add THEN
			news_lat_div1 := (news_lat_d + lat_d) / 15;
			news_lat_div2 := (news_lat_d + lat_d) % 15;
			news_lat_div3 := news_lat_m + lat_m;
			news_lat_div4 := news_lat_s + lat_s;
		ELSE
			news_lat_div1 := (news_lat_d - lat_d) / 15;
			news_lat_div2 := (news_lat_d - lat_d) % 15;
			news_lat_div3 := news_lat_m - lat_m;
			news_lat_div4 := news_lat_s - lat_s;
		END IF;

		--RAISE NOTICE 'The news long div1,2,3,4: %', news_long_div1 || ', ' || news_long_div2 || ', ' || to_char(news_long_div3, '00') || ', ' || to_char(news_long_div4, '00') ; 
		--RAISE NOTICE 'The news lat div1,2,3,4: %', news_lat_div1 || ', ' || news_lat_div2 || ', ' ||  to_char(news_lat_div3, '00')  || ', ' || to_char(news_lat_div4, '00'); 
		
		-- set georef format
		NEW.georef := alpha[news_long_div1+1] || alpha[news_lat_div1+1] || alpha[news_long_div2+1] || alpha[news_lat_div2+1] || trim(both ' ' from to_char(news_long_div3, '00')) 
		|| trim(both ' ' from to_char(news_long_div4, '00'))  || trim(both ' ' from to_char(news_lat_div3, '00')) || trim(both ' ' from to_char(news_lat_div4, '00'));
		--RAISE NOTICE 'The georef: %', NEW.georef;			
		-- Remember when location was added/updated
		NEW.updated_date := current_timestamp;
		-- RAISE NOTICE 'Begin dynamic location logic... ';
		FOR rec IN ( SELECT feature_id FROM  gaul0_dump WHERE ST_Intersects(NEW.point, polygon)) LOOP
		  -- RAISE NOTICE 'Intersected GUAL0 feature id: %',rec.feature_id; 
		  SELECT INTO id classification_id FROM feature_taxonomy WHERE feature_id = rec.feature_id;
		  IF id IS NOT NULL THEN	
		    DELETE FROM location_taxonomy WHERE location_id = NEW.location_id AND classification_id IN (SELECT classification_id FROM taxonomy_classifications WHERE taxonomy = 'Country');
		    INSERT INTO location_taxonomy VALUES (NEW.location_id, id, 'location_id');
		  END IF;
		END LOOP;
        END IF;
        
        RETURN NEW;
    END;
$upd_geometry_formats$ LANGUAGE plpgsql; 
DROP TRIGGER IF EXISTS upd_geometry_formats ON location;
CREATE TRIGGER upd_geometry_formats BEFORE INSERT OR UPDATE ON location
    FOR EACH ROW EXECUTE PROCEDURE upd_geometry_formats();
/******************************************************************
  upd_boundary_features
******************************************************************/
CREATE OR REPLACE FUNCTION upd_boundary_features()
RETURNS trigger AS $upd_boundary_features$
    DECLARE
	boundary RECORD;
	feature RECORD;
    BEGIN
	--RAISE NOTICE 'Refreshing boundary features for location_id % ...', NEW.location_id;
	EXECUTE 'DELETE FROM location_boundary WHERE location_id = ' || NEW.location_id;
		
	FOR boundary IN SELECT * FROM boundary LOOP
		--RAISE NOTICE 'Add % boundary features ...', quote_ident(boundary.spatial_table);
		FOR feature IN EXECUTE 'SELECT * FROM ' || quote_ident(boundary.spatial_table)  || ' WHERE ST_Intersects(ST_PointFromText(''' ||
			ST_AsText(NEW.point) || ''', 4326), polygon)' LOOP
			EXECUTE 'INSERT INTO location_boundary VALUES (' || NEW.location_id || ', ' || 
			feature.boundary_id || ', ' || feature.feature_id || ')';
		END LOOP;
				
	END LOOP;
	RETURN NEW;
    END;
$upd_boundary_features$ LANGUAGE plpgsql; 
DROP TRIGGER IF EXISTS upd_boundary_features ON location;
CREATE TRIGGER upd_boundary_features BEFORE INSERT OR UPDATE ON location
    FOR EACH ROW EXECUTE PROCEDURE upd_boundary_features();
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
			    FOREACH i IN ARRAY activity."sector" LOOP
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
/*****************************************************************
Functions -- is procedural code that is executed when called.
Create FUNCTIONS:
	1.  pmt_bytea_import - written by Jack Douglas**. Used in 
	combination with PostgreSQL convert_from() to import xml
	documents as an xml data type from a file directory.
	2.  pmt_isnumeric - used to validate numeric values from text
	3.  pmt_isdate - used to validate date values from text
	4.  pmt_data_groups - returns all data groups
	5.  pmt_version - returns the current version of the database
	6.  pmt_locations_by_tax - all locations reporting by a
	taxonomy. 
	7.  pmt_locations_by_org - 
	8.  pmt_filter_locations - filters locations by classifications,
	organizations and date ranges and reports by a taxonomy.
	9.  pmt_filter_projects - filters projects by classifications,
	organizations and date ranges.	
	10. pmt_filter_orgs - filters organizations by classifications,
	organizations and date ranges.
	11. pmt_countries - returns json of all countries or a filtered
	list of countries
	12. pmt_tax_inuse - returns nested json of all taxonomy/classifications
	in use. accepts a data group classification id. if null gives all 
	in use, otherwise just taxonomy/classification in use by given 
	data group.
	13. pmt_taxonomies - returns nested json of requested/all 
	active taxonomy/classifications.
	14. pmt_validate_classifications - accepts ids and returns array of
	valid classification ids.
	15. pmt_validate_classification - returns boolean of validity of passed
	classification id.
	16. pmt_validate_taxonomies - accepts ids and returns array of
	valid taxonomy ids.
	17. pmt_validate_taxonomy - returns boolean of validity of passed
	taxonomy id.
	18. pmt_category_root - returns the root taxonomy(ies) to any give category
	taxonomy.
	19. pmt_activities_by_tax - returns activity id and title and classification_ids
	based on reporting taxonomy.
	20. pmt_validate_activity -
	21. pmt_validate_activities - 
	22. pmt_infobox_menu - 
	
**Citations:
Douglas, Jack. "SQL to read XML from file into PostgreSQL database." 
StackExchange Database Administrators Nov 2011. Web. 02 Aug 2013 
http://dba.stackexchange.com/questions/8172/sql-to-read-xml-from-file-into-postgresql-database	
Jack Douglas StackExchange Profile: http://dba.stackexchange.com/users/1396/jack-douglas
******************************************************************/

-- create types for all functions
CREATE TYPE pmt_activities_by_tax_result_type AS (a_id integer, title character varying, c_ids text);
CREATE TYPE pmt_data_groups_result_type AS (c_id integer, name text);
CREATE TYPE pmt_version_result_type AS (version text, last_update date, created date);
CREATE TYPE pmt_locations_by_org_result_type AS (l_id integer, x integer, y integer, r_ids text);
CREATE TYPE pmt_locations_by_tax_result_type AS (l_id integer, x integer, y integer, r_ids text);
CREATE TYPE pmt_filter_locations_result AS (l_id integer, g_id character varying(20),  r_ids text); 
CREATE TYPE pmt_filter_projects_result AS (p_id integer, a_ids text);  
CREATE TYPE pmt_filter_orgs_result AS (o_id integer, name character varying(255));  
CREATE TYPE pmt_countries_result_type AS (response json);
CREATE TYPE pmt_tax_inuse_result_type AS (response json);
CREATE TYPE pmt_taxonomies_result_type AS (response json);
CREATE TYPE pmt_infobox_result_type AS (response json);

/******************************************************************
  pmt_bytea_import
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_bytea_import(p_path TEXT, p_result OUT bytea) 
   LANGUAGE plpgsql AS $$
DECLARE
  l_oid oid;
  r record;
BEGIN
  p_result := '';
  SELECT lo_import(p_path) INTO l_oid;
  FOR r IN ( SELECT data 
             FROM pg_largeobject 
             WHERE loid = l_oid 
             ORDER BY pageno ) LOOP
    p_result = p_result || r.data;
  END LOOP;
  perform lo_unlink(l_oid);
END;$$;
/******************************************************************
 pmt_isnumeric 
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_isnumeric(text) RETURNS BOOLEAN AS $$
DECLARE x NUMERIC;
BEGIN
    x = $1::NUMERIC;
    RETURN TRUE;
EXCEPTION WHEN others THEN
    RETURN FALSE;
END;
$$ LANGUAGE plpgsql IMMUTABLE;
/******************************************************************
  pmt_isdate 
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_isdate(text) RETURNS boolean AS $$
DECLARE a DATE;
BEGIN 
     IF $1 IS NULL THEN    
       RETURN 'f';
     END IF;
     
     a := $1::timestamp;
     RETURN 't';

EXCEPTION
     WHEN others THEN RETURN 'f';
END; 
$$ LANGUAGE 'plpgsql';
/******************************************************************
   pmt_data_groups
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_data_groups()
RETURNS SETOF pmt_data_groups_result_type AS 
$$
DECLARE
  rec record;
BEGIN	
  -- collect locations 
  FOR rec IN (SELECT classification_id as c_id, classification::text as name FROM taxonomy_classifications WHERE taxonomy = 'Data Group') LOOP		
	RETURN NEXT rec;
  END LOOP;	  
END;$$ LANGUAGE plpgsql;

-- show version of pmt
CREATE OR REPLACE FUNCTION pmt_version() RETURNS SETOF pmt_version_result_type AS 
$$
DECLARE
  rec record;
BEGIN	
  -- collect locations 
  FOR rec IN (SELECT version::text||'.'||iteration::text||'.'||changeset::text AS pmt_version, updated_date::date, created_date::date FROM config ) LOOP		
	RETURN NEXT rec;
  END LOOP;	  
END;$$ LANGUAGE plpgsql;
/******************************************************************
  pmt_locations_by_tax
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_locations_by_tax(tax_id Integer, data_group Integer, country_ids character varying)
RETURNS SETOF pmt_locations_by_tax_result_type AS 
$$
DECLARE
  data_group_id integer;
  valid_country_ids int[];
  valid_classification_ids int[];
  valid_taxonomy_id boolean;
  report_by_category boolean; 
  report_taxonomy_id integer;
  dynamic_where1 text;
  dynamic_where2 text;
  dynamic_join text;
  execute_statement text;
--  new_c_ids text;
  rec record;
BEGIN
  report_by_category := false; -- intialize to false  
  
  -- validate and process taxonomy_id parameter
  IF $1 IS NOT NULL THEN
    SELECT INTO valid_taxonomy_id * FROM pmt_validate_taxonomy($1);    
    -- has valid taxonomy id
    IF valid_taxonomy_id THEN 
       report_taxonomy_id := $1;
      -- is this taxonomy a category?
      SELECT INTO report_by_category is_category FROM taxonomy WHERE taxonomy_id = (report_taxonomy_id);      
      -- yes, this is a category taxonomy
      IF report_by_category THEN
        -- what are the root taxonomy(ies) of the category taxonomy
        SELECT INTO report_taxonomy_id * FROM pmt_category_root(report_taxonomy_id, data_group);
        -- there are root taxonomy(ies)
        IF report_taxonomy_id IS NOT NULL THEN
           -- RAISE NOTICE 'report_taxonomy_id: %', report_taxonomy_id;
        ELSE
          report_taxonomy_id := $1;
          report_by_category := false;
        END IF;
      END IF;
      
      -- add the taxonomy to the report_by selection
      dynamic_where2 := ' WHERE taxonomy_id = ' || report_taxonomy_id || ' ';
      
    END IF;	
  END IF;

  -- RAISE NOTICE 'report_taxonomy_id: %', report_taxonomy_id;
  -- RAISE NOTICE 'report_by_category: %', report_by_category;
  
  -- validate and process data_group parameter
  IF $2 IS NOT NULL THEN
    -- check that the data group exists
    SELECT INTO data_group_id classification.classification_id FROM classification WHERE classification.classification_id = $2 AND classification.taxonomy_id = (SELECT taxonomy.taxonomy_id FROM taxonomy WHERE name = 'Data Group');
    RAISE NOTICE 'data group: %', data_group_id;
    -- add where statement if data group is valid
    IF data_group_id IS NOT NULL THEN	
      dynamic_where1 := ' WHERE classification_id = ' || data_group_id || ' ';
    END IF;    
  END IF;

  -- validate and process country_ids parameter
  IF $3 IS NOT NULL OR $3 <> '' THEN
    SELECT INTO valid_classification_ids * FROM pmt_validate_classifications($3);
    RAISE NOTICE 'valid classification ids: %', valid_classification_ids;
    IF valid_classification_ids IS NOT NULL THEN
      SELECT INTO valid_country_ids array_agg(DISTINCT classification_id)::INT[] 
      FROM (
        SELECT classification_id 
        FROM classification 
        WHERE active = true 
        AND classification_id = ANY(valid_classification_ids)
        AND classification.taxonomy_id = (SELECT taxonomy.taxonomy_id FROM taxonomy WHERE iati_codelist = 'Country')
         ORDER BY classification_id
      ) as c;	
    END IF;
    
    IF valid_country_ids IS NOT NULL THEN
      dynamic_join := 'JOIN (SELECT DISTINCT location_id, x, y, georef FROM taxonomy_lookup WHERE classification_id = ANY(ARRAY[' || array_to_string(valid_country_ids, ',')  || '])) AS country ' ||
		      'ON t2.location_id = country.location_id ';
    END IF; 
  END IF;
  
  -- prepare statement
  execute_statement := 'SELECT t2.location_id as l_id, t2.x, t2.y,  array_to_string(array_agg(DISTINCT report_by.classification_id), '','') AS c_ids ' ||
		       'FROM ( SELECT DISTINCT location_id, x, y, georef FROM taxonomy_lookup ';		      	      
		       
  IF dynamic_where1 IS NOT NULL THEN
    execute_statement := execute_statement || dynamic_where1 || ' ';   
  END IF;		       
  execute_statement := execute_statement || ' ORDER BY georef) AS t2 ';
  IF dynamic_join IS NOT NULL THEN
    execute_statement := execute_statement || dynamic_join || ' ';
  END IF;
  execute_statement := execute_statement || 'LEFT JOIN (SELECT location_id, classification_id FROM taxonomy_lookup ';
  IF dynamic_where2 IS NOT NULL THEN
    execute_statement := execute_statement || dynamic_where2 || ' ';   
  END IF;
  execute_statement := execute_statement || '  ORDER BY georef) AS report_by ' ||
		       'ON t2.location_id = report_by.location_id ' ||
		       'GROUP BY l_id, t2.x, t2.y, t2.georef ' ||
		       'ORDER BY t2.georef';
  -- execute statement
  -- RAISE NOTICE 'Execute statement: %', execute_statement;
  FOR rec IN EXECUTE execute_statement	    
  LOOP
   IF report_by_category THEN 
      SELECT INTO rec.c_ids array_to_string(array_agg(DISTINCT category_id), ',') FROM classification WHERE classification_id = ANY(string_to_array(rec.c_ids, ',')::int[]);
      RETURN NEXT rec;
    ELSE
      RETURN NEXT rec;    
    END IF;
  END LOOP;
  
END;$$ LANGUAGE plpgsql;
/******************************************************************
  pmt_locations_by_org
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_locations_by_org(classification_id Integer, data_group Integer, country_ids character varying)
RETURNS SETOF pmt_locations_by_org_result_type AS 
$$
DECLARE
  data_group_id integer;
  valid_classification_id boolean;
  valid_country_ids int[];
  valid_classification_ids int[];
  dynamic_where1 text;
  dynamic_where2 text;
  dynamic_join text;
  execute_statement text;
  rec record;
BEGIN

  -- validate and process classification_id parameter
  IF $1 IS NOT NULL THEN
    SELECT INTO valid_classification_id * FROM pmt_validate_classification($1);    
    -- has valid classification id
    IF valid_classification_id THEN
      dynamic_where2 := ' WHERE classification_id = ' || $1 || ' ';
    END IF;	
  END IF;

  -- validate and process data_group parameter
  IF $2 IS NOT NULL THEN
    -- check that the data group exists
    SELECT INTO data_group_id classification.classification_id FROM classification WHERE classification.classification_id = $2 AND classification.taxonomy_id = (SELECT taxonomy.taxonomy_id FROM taxonomy WHERE name = 'Data Group');
    RAISE NOTICE 'data group: %', data_group_id;
    -- add where statement if data group is valid
    IF data_group_id IS NOT NULL THEN	
      dynamic_where1 := ' WHERE classification_id = ' || data_group_id || ' ';
    END IF;    
  END IF;

  -- validate and process country_ids parameter
  IF $3 IS NOT NULL OR $3 <> '' THEN
    SELECT INTO valid_classification_ids * FROM pmt_validate_classifications($3);
    RAISE NOTICE 'valid classification ids: %', valid_classification_ids;
    IF valid_classification_ids IS NOT NULL THEN
      SELECT INTO valid_country_ids array_agg(DISTINCT c.classification_id)::INT[] 
      FROM (
        SELECT classification.classification_id 
        FROM classification 
        WHERE active = true 
        AND classification.classification_id = ANY(valid_classification_ids)
        AND classification.taxonomy_id = (SELECT taxonomy.taxonomy_id FROM taxonomy WHERE iati_codelist = 'Country')
         ORDER BY classification.classification_id
      ) as c;	
    END IF;
    
    IF valid_country_ids IS NOT NULL THEN
      dynamic_join := 'JOIN (SELECT DISTINCT location_id, x, y, georef FROM taxonomy_lookup WHERE classification_id = ANY(ARRAY[' || array_to_string(valid_country_ids, ',')  || '])) AS country ' ||
		      'ON t2.location_id = country.location_id ';
    END IF; 
  END IF;

  -- prepare statement
  execute_statement := 'SELECT t2.location_id as l_id, t2.x, t2.y,  array_to_string(array_agg(DISTINCT report_by.organization_id), '','') AS o_ids ' ||
		       'FROM ( SELECT DISTINCT location_id, x, y, georef FROM taxonomy_lookup ';		      	      
		       
  IF dynamic_where1 IS NOT NULL THEN
    execute_statement := execute_statement || dynamic_where1 || ' ';   
  END IF;		       
  execute_statement := execute_statement || ' ORDER BY georef) AS t2 ';
  IF dynamic_join IS NOT NULL THEN
    execute_statement := execute_statement || dynamic_join || ' ';
  END IF;
  execute_statement := execute_statement || 'LEFT JOIN (SELECT location_id, organization_id FROM taxonomy_lookup ';
  IF dynamic_where2 IS NOT NULL THEN
    execute_statement := execute_statement || dynamic_where2 || ' ';   
  END IF;
  execute_statement := execute_statement || '  ORDER BY georef) AS report_by ' ||
		       'ON t2.location_id = report_by.location_id ' ||
		       'GROUP BY l_id, t2.x, t2.y, t2.georef ' ||
		       'ORDER BY t2.georef';
   
  -- execute statement
  -- RAISE NOTICE 'Execute statement: %', execute_statement;
  FOR rec IN EXECUTE execute_statement	    
  LOOP
    RETURN NEXT rec;    
  END LOOP;
  
END;$$ LANGUAGE plpgsql;
/******************************************************************
  pmt_filter_locations
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_filter_locations(tax_id integer, classification_ids character varying, organization_ids character varying, 
 unassigned_tax_ids character varying, start_date date, end_date date)
RETURNS SETOF pmt_filter_locations_result AS 
$$
DECLARE
  rec record;
  valid_taxonomy_id boolean;
  report_by_category boolean; 
  report_taxonomy_id integer;
  filter_classids integer array;
  filter_orgids integer array;
  include_taxids integer array;
  dynamic_where2 text array; 
  dynamic_where4 text;
  built_where text array;
  execute_statement text;
  i integer;
BEGIN
	RAISE NOTICE 'Beginning execution of the pmt_filter_location function...';

	-- validate and process taxonomy_id parameter
	SELECT INTO valid_taxonomy_id * FROM pmt_validate_taxonomy($1); 
	
	-- Must have taxonomy_id parameter to continue
	IF NOT valid_taxonomy_id THEN
	   RAISE NOTICE '   + A taxonomy is required.';
	ELSE	
		   		
		  report_taxonomy_id := $1;
		  -- is this taxonomy a category?
		  SELECT INTO report_by_category is_category FROM taxonomy WHERE taxonomy_id = (report_taxonomy_id);      
		  -- yes, this is a category taxonomy
		  IF report_by_category THEN
		    -- what are the root taxonomy(ies) of the category taxonomy
		    SELECT INTO report_taxonomy_id * FROM pmt_category_root(report_taxonomy_id, null);		    
		    IF report_taxonomy_id IS NULL THEN
		      -- there is no root taxonomy
		      report_taxonomy_id := $1;
		      report_by_category := false;
		    END IF;
		  END IF;		      
		    
		-- The all filters are null so get everything and report by the taxonomy
		IF ($2 is null OR $2 = '') AND ($3 is null OR $3 = '') AND ($4 is null OR $4 = '') AND ($5 is null OR $6 is null) THEN
			RAISE NOTICE '   + No classification or organization or date filter.';
			RAISE NOTICE '   + The reporting taxonomy is: %.', $1;
			
			FOR rec IN SELECT t2.location_id as l_id, t2.georef as g_id, array_to_string(array_agg(DISTINCT report_by.classification_id), ',') as cl_id
			FROM
			(SELECT DISTINCT location_id, georef, array_agg(classification_id) as classification_ids
					FROM taxonomy_lookup	
					GROUP BY location_id, georef
					ORDER BY location_id, georef
			) AS t2
			LEFT JOIN
			(SELECT * FROM taxonomy_lookup 
			WHERE taxonomy_lookup.taxonomy_id = report_taxonomy_id) AS report_by 
			ON t2.location_id = report_by.location_id
			GROUP BY t2.location_id, t2.georef	
			ORDER BY t2.georef LOOP
		          -- if reporting by a category then swap the classification_ids
			  IF report_by_category THEN 
			    SELECT INTO rec.cl_id array_to_string(array_agg(DISTINCT category_id), ',') FROM classification WHERE classification_id = ANY(string_to_array(rec.cl_id, ',')::int[]);
			    RETURN NEXT rec;
			  ELSE
			    RETURN NEXT rec;    
			  END IF;
			END LOOP;
		-- filtering	
		ELSE
		   -- filter by classification ids
		   IF ($2 is not null AND $2 <> '') THEN
		      RAISE NOTICE '   + The classification filter is: %.', string_to_array($2, ',')::int[];

			SELECT INTO filter_classids * FROM pmt_validate_classifications($2);

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
				dynamic_where2 := array_append(dynamic_where2, '(' || array_to_string(built_where, ' OR ') || ')');
			  END LOOP;			
			END IF;
		   END IF;
		   
		   -- filter by organization ids
		   IF ($3 is not null AND $3 <> '') THEN
		      RAISE NOTICE '   + The organization filter is: %.', string_to_array($3, ',')::int[];

		      -- Create an int array from organization ids list
			filter_orgids := string_to_array($3, ',')::int[];

		      -- Loop through the organization_ids and construct the where statement
			built_where := null;
			FOREACH i IN ARRAY filter_orgids LOOP
				built_where :=  array_append(built_where, 'organization_ids @> ARRAY['|| i ||']');
			END LOOP;
			-- Add the complied org statements to the where
			dynamic_where2 := array_append(dynamic_where2, '(' || array_to_string(built_where, ' OR ') || ')');
			
		   END IF;

		   -- include values with unassigned taxonomy(ies)
		   IF ($4 is not null AND $4 <> '') THEN
		      RAISE NOTICE '   + The include unassigned is: %.', string_to_array($4, ',')::int[];

		      -- Create an int array from unassigned ids list
		      include_taxids := string_to_array($4, ',')::int[];				

		      -- Loop through the organization_ids and construct the where statement
		      built_where := null;
		      FOREACH i IN ARRAY include_taxids LOOP
			built_where :=  array_append(built_where, 'not (taxonomy_ids @> ARRAY['|| i ||'])');
		      END LOOP;			
		      -- Add the complied org statements to the where
		      dynamic_where4 := '(' || array_to_string(built_where, ' OR ') || ')';
			
		   END IF;

		   -- filter by date range
		   IF ($5 is not null AND $6 is not null) THEN
			RAISE NOTICE '   + The date filter is: %.', $5 || ' & ' || $6;
			dynamic_where2 := array_append(dynamic_where2, '(start_date > ''' || $5 || ''' AND end_date < ''' || $6 || ''')');
		   END IF;
		   
		   -- prepare statement				
		   RAISE NOTICE '   + The reporting taxonomy is: %.', $1;												
		   RAISE NOTICE '   + Second where statement: %', array_to_string(dynamic_where2, ' AND ');
		   RAISE NOTICE '   + Forth where statement: %', dynamic_where4;

		   execute_statement := 'SELECT t2.location_id as l_id, t2.georef as g_id, array_to_string(array_agg(DISTINCT report_by.classification_id), '','') as cl_id ' ||
				'FROM( ' ||
				'SELECT DISTINCT t1.location_id, t1.georef, t1.classification_ids FROM ' ||
				'(SELECT DISTINCT location_id, georef, start_date, end_date, array_agg(distinct taxonomy_id) as taxonomy_ids, array_agg(distinct classification_id) as classification_ids, array_agg(distinct organization_id) as organization_ids ' ||
				'FROM taxonomy_lookup GROUP BY location_id, georef, start_date, end_date ' ||
				-- 'ORDER BY location_id, georef, start_date, end_date ' ||
				') AS t1 ';
				
		  IF dynamic_where2 IS NOT NULL THEN          
		    IF dynamic_where4 IS NOT NULL THEN
		      execute_statement := execute_statement || ' WHERE ' ||  array_to_string(dynamic_where2, ' AND ')  || ' OR ' || dynamic_where4;
		    ELSE
		      execute_statement := execute_statement || ' WHERE ' ||  array_to_string(dynamic_where2, ' AND ') || ' ';
		    END IF;
		  ELSE 
		    IF dynamic_where4 IS NOT NULL THEN
		      execute_statement := execute_statement || ' WHERE ' || dynamic_where4 || ' ';                       
		    END IF;
		  END IF;	
		  			
		  execute_statement := execute_statement || ') as t2 ' ||
				'LEFT JOIN ' ||
				'(SELECT * FROM taxonomy_lookup  ' ||
				'WHERE taxonomy_lookup.taxonomy_id = ' || report_taxonomy_id || ') AS report_by  ' ||
				'ON t2.location_id = report_by.location_id ' ||
				'GROUP BY t2.location_id, t2.georef ' ||	
				'ORDER BY t2.georef ';  

		-- execute statement		
		RAISE NOTICE 'execute: %', execute_statement;		
		FOR rec IN EXECUTE execute_statement				
		 LOOP
		  IF report_by_category THEN 
		    SELECT INTO rec.cl_id array_to_string(array_agg(DISTINCT category_id), ',') FROM classification WHERE classification_id = ANY(string_to_array(rec.cl_id, ',')::int[]);
		    RETURN NEXT rec;
		  ELSE
		    RETURN NEXT rec;    
		  END IF;
		END LOOP;	
	END IF;
    END IF;
END;$$ LANGUAGE plpgsql;
/******************************************************************
  pmt_filter_projects
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_filter_projects(classification_ids character varying, organization_ids character varying, unassigned_tax_ids character varying, 
start_date date, end_date date)
RETURNS SETOF pmt_filter_projects_result AS 
$$
DECLARE
  rec record;
  filter_classids integer array;
  filter_orgids integer array;
  include_taxids integer array;
  dynamic_where1 text array;
  dynamic_where2 text array;
  dynamic_where3 text;
  dynamic_where4 text;
  built_where text array;
  execute_statement text;
  i integer;
BEGIN
	--RAISE NOTICE 'Beginning execution of the pmt_filter_project function...';

	-- Both classification & organization filters are null so get everything
	IF ($1 is null OR $1 = '') AND ($2 is null OR $2 = '') AND ($3 is null OR $3 = '') AND ($4 is null OR $5 is null) THEN
		--RAISE NOTICE '   + No classification or organization or date filter.';
		FOR rec IN SELECT project_id as p_id, array_to_string(array_agg(DISTINCT activity_id), ',') as a_ids
		   FROM taxonomy_lookup			
		   GROUP BY project_id	
		   ORDER BY project_id 
		LOOP
			RETURN NEXT rec;
		END LOOP;
	-- filtering	
	ELSE
	   -- filter by classification ids
	   IF ($1 is not null AND $1 <> '') THEN

	      -- Create an int array from classification ids list
		filter_classids := string_to_array($1, ',')::int[];

	      -- Loop through each taxonomy classification group to contruct the where statement 
		FOR rec IN( 
		SELECT tc.taxonomy_id, array_agg(tc.classification_id) AS filter_array 
		FROM taxonomy_classifications tc 
		WHERE classification_id = ANY(filter_classids) GROUP BY tc.taxonomy_id
		) LOOP				
		  built_where := null;
		  -- for each classification add to the where statement
		  FOREACH i IN ARRAY rec.filter_array LOOP				
			built_where :=  array_append(built_where, 'classification_ids @> ARRAY['|| i ||']');
		  END LOOP;
		  -- add each classification within the same taxonomy to the where joined by 'OR'
		  dynamic_where2 := array_append(dynamic_where2, '(' || array_to_string(built_where, ' OR ') || ')');
		END LOOP;			
	   END IF;
	   -- filter by organization ids
	   IF ($2 is not null AND $2 <> '') THEN

	      -- Create an int array from organization ids list
		filter_orgids := string_to_array($2, ',')::int[];		

	      -- Loop through the organization_ids and construct the where statement
		built_where := null;
		FOREACH i IN ARRAY filter_orgids LOOP
			built_where :=  array_append(built_where, 'organization_ids @> ARRAY['|| i ||']');
		END LOOP;
		-- Add the complied org statements to the where
		dynamic_where2 := array_append(dynamic_where2, '(' || array_to_string(built_where, ' OR ') || ')');
		
	   END IF;
	   -- include unassigned taxonomy ids
	   IF ($3 is not null AND $3 <> '') THEN
	   
	      -- Create an int array from unassigned ids list
	      include_taxids := string_to_array($3, ',')::int[];				

	      -- Loop through the organization_ids and construct the where statement
	      built_where := null;
	      FOREACH i IN ARRAY include_taxids LOOP
		built_where :=  array_append(built_where, 'not (taxonomy_ids @> ARRAY['|| i ||'])');
	      END LOOP;		

	      -- Add the complied org statements to the where
	      dynamic_where4 := '(' || array_to_string(built_where, ' OR ') || ')';
		
	   END IF;
	   
	   -- filter by date range
	   IF ($4 is not null AND $5 is not null) THEN
		dynamic_where2 := array_append(dynamic_where2, '(start_date > ''' || $4 || ''' AND end_date < ''' || $5 || ''')');
	   END IF;		
	   										
	  -- prepare statement					
	   RAISE NOTICE '   + First where statement: %', array_to_string(dynamic_where1, ' AND ');
	   RAISE NOTICE '   + Second where statement: %', array_to_string(dynamic_where2, ' AND ');
	   RAISE NOTICE '   + Third where statement: %', dynamic_where3;
	   RAISE NOTICE '   + Forth where statement: %', dynamic_where4;

	  execute_statement := 'SELECT t2.project_id as p_id, array_to_string(array_agg(DISTINCT t2.activity_id), '','') as a_ids ' ||
			'FROM( ' ||
			'SELECT DISTINCT t1.project_id, t1.activity_id, t1.location_id, t1.georef, t1.classification_ids FROM ' ||
			'(SELECT DISTINCT project_id, activity_id, location_id, georef, start_date, end_date, array_agg(distinct taxonomy_id) as taxonomy_ids, ' ||
			'array_agg(distinct classification_id) as classification_ids, array_agg(distinct organization_id) as organization_ids ' ||
			'FROM taxonomy_lookup GROUP BY project_id, activity_id, location_id, georef, start_date, end_date ' ||
			') AS t1 ';
			
	  IF dynamic_where2 IS NOT NULL THEN          
            IF dynamic_where4 IS NOT NULL THEN
              execute_statement := execute_statement || ' WHERE ' ||  array_to_string(dynamic_where2, ' AND ')  || ' OR ' || dynamic_where4;
            ELSE
              execute_statement := execute_statement || ' WHERE ' ||  array_to_string(dynamic_where2, ' AND ') || ' ';
            END IF;
          ELSE 
            IF dynamic_where4 IS NOT NULL THEN
              execute_statement := execute_statement || ' WHERE ' || dynamic_where4 || ' ';                       
            END IF;
          END IF;
          
	  execute_statement := execute_statement || ') as t2 ' ||			
			'GROUP BY t2.project_id ' ||	
			'ORDER BY t2.project_id ';

	  -- execute statement		
          RAISE NOTICE 'execute: %', execute_statement;			  
	  FOR rec IN EXECUTE execute_statement
	  LOOP
	    RETURN NEXT rec;
	  END LOOP;	
	END IF;	
END;$$ LANGUAGE plpgsql;
/******************************************************************
  pmt_filter_orgs
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_filter_orgs(classification_ids character varying, organization_ids character varying, start_date date, end_date date)
RETURNS SETOF pmt_filter_orgs_result AS 
$$
DECLARE
  rec record;
  filter_classids integer array;
  filter_orgids integer array;
  dynamic_where1 text array;
  dynamic_where2 text array;
  built_where text array;
  i integer;
BEGIN
	RAISE NOTICE 'Beginning execution of the pmt_filter_org function...';

	-- Both classification & organization filters are null so get everything
	IF ($1 is null OR $1 = '') AND ($2 is null OR $2 = '')  AND ($3 is null OR $4 is null) THEN
		--RAISE NOTICE '   + No classification or organization or date filter.';
		FOR rec IN SELECT tl.organization_id as o_id, o.name FROM
		   (SELECT DISTINCT organization_id
		   FROM taxonomy_lookup) AS tl
		   JOIN organization o
		   ON tl.organization_id = o.organization_id		
		   ORDER BY o.name
		LOOP
			RETURN NEXT rec;
		END LOOP;
	-- filtering	
	ELSE
	   -- filter by classification ids
	   IF ($1 is not null AND $1 <> '') THEN
	      --RAISE NOTICE '   + The classification filter is: %.', string_to_array($1, ',')::int[];

	      -- Create an int array from classification ids list
		filter_classids := string_to_array($1, ',')::int[];

	      -- build first where statement	
	      dynamic_where1 := array_append(dynamic_where1, 'classification_id = ANY(ARRAY[' ||array_to_string(filter_classids, ',') || ']) ');
		
	      -- Loop through each taxonomy classification group to contruct the where statement 
	      --RAISE NOTICE '   + Beginning to build the dynamic where statement for classifications.';
		FOR rec IN( 
		SELECT tc.taxonomy_id, array_agg(tc.classification_id) AS filter_array 
		FROM taxonomy_classifications tc 
		WHERE classification_id = ANY(filter_classids) GROUP BY tc.taxonomy_id
		) LOOP				
			built_where := null;
			-- for each classification add to the where statement
			FOREACH i IN ARRAY rec.filter_array
			LOOP				
				built_where :=  array_append(built_where, 'classification_ids @> ARRAY['|| i ||']');
				--RAISE NOTICE '      - Adding % to the where statement.', 'classification_ids @> ARRAY['|| i ||']';
			END LOOP;
			-- add each classification within the same taxonomy to the where joined by 'OR'
			dynamic_where2 := array_append(dynamic_where2, '(' || array_to_string(built_where, ' OR ') || ')');
		END LOOP;			
	   END IF;
	   -- filter by organization ids
	   IF ($2 is not null AND $2 <> '') THEN
	      --RAISE NOTICE '   + The organization filter is: %.', string_to_array($2, ',')::int[];

	      -- Create an int array from organization ids list
		filter_orgids := string_to_array($2, ',')::int[];
			
	      dynamic_where1 := array_append(dynamic_where1, 'organization_id = ANY(ARRAY[' ||array_to_string(filter_orgids, ',') || ']) ');
	      dynamic_where2 := array_append(dynamic_where2, 't1.organization_id = ANY(ARRAY[' ||array_to_string(filter_orgids, ',') || ']) ');
		
	   END IF;

	   IF ($3 is not null AND $4 is not null) THEN
		--RAISE NOTICE '   + The date filter is: %.', $3 || ' & ' || $4;
		dynamic_where1 := array_append(dynamic_where1, '(start_date > ''' || $3 || ''' AND end_date < ''' || $4 || ''')');
		dynamic_where2 := array_append(dynamic_where2, '(start_date > ''' || $3 || ''' AND end_date < ''' || $4 || ''')');
	   END IF;												
						
	   --RAISE NOTICE '   + First where statement: %', array_to_string(dynamic_where1, ' AND ');
	   --RAISE NOTICE '   + Second where statement: %', array_to_string(dynamic_where2, ' AND ');
	   
		FOR rec IN EXECUTE
			'SELECT t2.organization_id as o_id, t2.name ' ||
			'FROM( ' ||
			'SELECT DISTINCT t1.project_id, t1.activity_id, t1.location_id, t1.georef, t1.classification_ids, t1.organization_id, o.name FROM ' ||
			'(SELECT DISTINCT project_id, activity_id, location_id, organization_id, georef, start_date, end_date, array_agg(classification_id) as classification_ids ' ||
			'FROM taxonomy_lookup ' ||
			'WHERE ' || array_to_string(dynamic_where1, ' AND ') ||
			'GROUP BY project_id, activity_id, location_id, organization_id, georef, start_date, end_date ' ||
			') AS t1 ' ||
			'LEFT JOIN organization o ON t1.organization_id = o.organization_id ' ||
			'WHERE ' || array_to_string(dynamic_where2, ' AND ') ||
			') as t2 ' ||			
			'GROUP BY t2.organization_id, t2.name ' ||	
			'ORDER BY t2.name, t2.organization_id '  
			 LOOP
				RETURN NEXT rec;
			END LOOP;	
	END IF;
END;$$ LANGUAGE plpgsql;
/******************************************************************
  pmt_countries
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_countries(classification_ids text)
RETURNS SETOF pmt_countries_result_type AS 
$$
DECLARE
  filter_classids int[];
  rec record;
BEGIN
  -- return all countries
  IF ($1 is null OR $1 = '') THEN
  FOR rec IN (
    SELECT row_to_json(j)
    FROM
    (	
	SELECT c.classification_id as c_id, lower(c.classification) as name, ST_AsGeoJSON(Box2D(ST_Collect(geom))) as bounds
	FROM 
	(SELECT feature_id, (ST_DumpRings(polygon)).geom as geom FROM gaul0) g
	JOIN feature_taxonomy t
	ON g.feature_id = t.feature_id
	JOIN taxonomy_classifications c
	ON t.classification_id = c.classification_id
	GROUP BY c.classification_id, c.classification
	ORDER BY c.classification
     ) j   
  ) LOOP		
    RETURN NEXT rec;
  END LOOP;	
  -- return filtered countries
  ELSE
    -- Create an int array from classification ids list
    filter_classids := string_to_array($1, ',')::int[];	
    
    FOR rec IN (
    SELECT row_to_json(j)
    FROM
    (	
	SELECT c.classification_id as c_id, lower(c.classification) as name, ST_AsGeoJSON(Box2D(ST_Collect(geom))) as bounds
	FROM 
	(SELECT feature_id, (ST_DumpRings(polygon)).geom as geom FROM gaul0) g
	JOIN feature_taxonomy t
	ON g.feature_id = t.feature_id
	JOIN taxonomy_classifications c
	ON t.classification_id = c.classification_id
	WHERE c.classification_id = ANY(filter_classids)
	GROUP BY c.classification_id, c.classification
	ORDER BY c.classification
     ) j
    ) LOOP		
      RETURN NEXT rec;
    END LOOP;	
    
  END IF;		
END;$$ LANGUAGE plpgsql;
/******************************************************************
  pmt_tax_inuse
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_tax_inuse(data_group_id integer, taxonomy_ids character varying, country_ids character varying)
RETURNS SETOF pmt_tax_inuse_result_type AS 
$$
DECLARE
  valid_classification_id boolean;
  valid_classification_ids int[];
  valid_country_ids int[];
  dynamic_where1 text;
  dynamic_where2 text;
  exectute_statement text;
  data_group_id integer;
  filter_taxids int[];
  rec record;
BEGIN
  -- confirm the passed id is a valid data group
  SELECT INTO data_group_id classification_id FROM taxonomy_classifications WHERE taxonomy = 'Data Group' AND classification_id = $1;

  -- if data group exists validate and filter	
  IF data_group_id IS NOT NULL THEN
    dynamic_where1 := ' where project_id in (select distinct project_id from taxonomy_lookup where classification_id =' || data_group_id || ')';
    dynamic_where2 := ' where project_id in (select distinct project_id from taxonomy_lookup where classification_id =' || data_group_id || ')';
  END IF;
  
  -- if taxonomy_ids exists validate and filter
  IF $2 IS NOT NULL OR $2 <> '' THEN
    SELECT INTO filter_taxids * FROM pmt_validate_taxonomies($2);
    IF filter_taxids IS NOT NULL THEN
      IF dynamic_where2 IS NULL THEN
        dynamic_where2 := ' where taxonomy_id = ANY(ARRAY[' || array_to_string(filter_taxids, ',') || '])';
      ELSE
        dynamic_where2 := dynamic_where2 || ' and taxonomy_id = ANY(ARRAY[' || array_to_string(filter_taxids, ',')  || '])';
      END IF;    
    END IF;
  END IF;

   --  if country_ids exists validate and filter
  IF $3 IS NOT NULL OR $3 <> '' THEN
    SELECT INTO valid_classification_ids * FROM pmt_validate_classifications($3);
    RAISE NOTICE 'valid classification ids: %', valid_classification_ids;
    IF valid_classification_ids IS NOT NULL THEN
      SELECT INTO valid_country_ids array_agg(DISTINCT c.classification_id)::INT[] 
      FROM (
        SELECT classification.classification_id 
        FROM classification 
        WHERE active = true 
        AND classification.classification_id = ANY(valid_classification_ids)
        AND classification.taxonomy_id = (SELECT taxonomy.taxonomy_id FROM taxonomy WHERE iati_codelist = 'Country')
         ORDER BY classification.classification_id
      ) as c;
    END IF;
    
    IF valid_country_ids IS NOT NULL THEN
      IF dynamic_where1 IS NOT NULL THEN
        dynamic_where1 := dynamic_where1 || ' and location_id in (select location_id from taxonomy_lookup where classification_id = ANY(ARRAY[' || array_to_string(valid_country_ids, ',')  || ']))';
      ELSE
        dynamic_where1 := ' where location_id in (select location_id from taxonomy_lookup where classification_id = ANY(ARRAY[' || array_to_string(valid_country_ids, ',')  || ']))';
      END IF;
      IF dynamic_where2 IS NOT NULL THEN
        dynamic_where2 := dynamic_where2 || ' and location_id in (select location_id from taxonomy_lookup where classification_id = ANY(ARRAY[' || array_to_string(valid_country_ids, ',')  || ']))';
      ELSE
        dynamic_where2 := ' where location_id in (select location_id from taxonomy_lookup where classification_id = ANY(ARRAY[' || array_to_string(valid_country_ids, ',')  || ']))';
      END IF;           
    END IF; 
  END IF;
  
  -- prepare statement
  exectute_statement := 'select row_to_json(t) from ( ' ||
	 'select taxonomy.taxonomy_id as t_id, taxonomy.name, taxonomy.is_category as is_cat, taxonomy.category_id as cat_id,( ' ||
	  'select array_to_json(array_agg(row_to_json(c))) ' ||
	   'from ( ' ||
	    'select class_order.classification_id as c_id, class_order.category_id as cat_id, c.name ' ||
	    'from (select taxonomy_id, classification_id, category_id, count(distinct location_id) as location_count ' ||
	    'from taxonomy_lookup ';
  
  IF dynamic_where1 IS NOT NULL THEN
    exectute_statement := exectute_statement || ' ' || dynamic_where1 || ' ';
  END IF;

  exectute_statement := exectute_statement || ' group by taxonomy_id, classification_id, category_id ' ||
	     ') as class_order ' ||
	    'join classification c ' ||
	    'on class_order.classification_id = c.classification_id ' ||
	    'where class_order.taxonomy_id = taxonomy.taxonomy_id ' ||
	    'order by class_order.location_count desc ' ||
	    ') c ) as classifications ' ||
	'from (select tl.taxonomy_id, t.name, t.is_category, t.category_id ' ||
	'from (select distinct taxonomy_id ' ||   
	'from taxonomy_lookup ';

  IF dynamic_where2 IS NOT NULL THEN
     exectute_statement := exectute_statement || ' ' || dynamic_where2 || ' ';
  END IF;

  exectute_statement := exectute_statement || ') tl join taxonomy t ' ||
	'on tl.taxonomy_id = t.taxonomy_id ' ||
	'order by t.name) as taxonomy ' ||
	') t ';
	
  RAISE NOTICE 'Execute: %', exectute_statement;
  		    
  -- execute statement
  FOR rec IN EXECUTE exectute_statement	    
  LOOP
    RETURN NEXT rec;    
  END LOOP;
END;$$ LANGUAGE plpgsql;
/******************************************************************
  pmt_taxonomies
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_taxonomies(taxonomy_ids character varying)
RETURNS SETOF pmt_taxonomies_result_type AS 
$$
DECLARE
  valid_taxonomy_ids int[];  
  dynamic_where1 text;
  dynamic_where2 text;
  exectute_statement text;
  data_group_id integer;
  filter_taxids int[];
  rec record;
BEGIN	 
  
  -- if taxonomy_ids exists validate and filter
  IF $1 IS NOT NULL OR $1 <> '' THEN
    SELECT INTO valid_taxonomy_ids * FROM pmt_validate_taxonomies($1);
    IF valid_taxonomy_ids IS NOT NULL THEN
       -- get categories/sub-categories of related taxonomies
       SELECT INTO filter_taxids array_agg(taxonomy_id)::INT[] FROM taxonomy WHERE taxonomy_id = ANY(valid_taxonomy_ids) OR category_id = ANY(valid_taxonomy_ids) AND active = true;
      dynamic_where1 := ' where taxonomy_id = ANY(ARRAY[' || array_to_string(filter_taxids, ',') || '])';  
      dynamic_where2 := ' where taxonomy_id = ANY(ARRAY[' || array_to_string(filter_taxids, ',') || '])';  
    END IF;
  END IF;
  
  -- prepare statement
  exectute_statement := 'select row_to_json(t) from ( ' ||
	 'select taxonomy.taxonomy_id as t_id, taxonomy.taxonomy as name, taxonomy.is_category as is_cat, taxonomy.taxonomy_category_id as cat_id, ( ' ||
	  'select array_to_json(array_agg(row_to_json(c))) ' ||
	   'from ( ' ||
	    'select class_order.classification_id as c_id, class_order.cat_id, class_order.classification as name ' ||
	    'from (select taxonomy_id, classification_id, classification, classification_category_id as cat_id ' ||
	    'from taxonomy_classifications ';
  
  IF dynamic_where1 IS NOT NULL THEN
    exectute_statement := exectute_statement || ' ' || dynamic_where1 || ' ';
  END IF;

  exectute_statement := exectute_statement || ' group by taxonomy_id, classification_id, classification, classification_category_id  ' ||
	     ') as class_order ' ||
	    'where class_order.taxonomy_id = taxonomy.taxonomy_id ' ||
	    ') c ) as classifications ' ||
	'from (select DISTINCT taxonomy_id, taxonomy, is_category, taxonomy_category_id ' ||  
	'from taxonomy_classifications ';

  IF dynamic_where2 IS NOT NULL THEN
     exectute_statement := exectute_statement || ' ' || dynamic_where2 || ' ';
  END IF;

  exectute_statement := exectute_statement || 'order by taxonomy) as taxonomy ' ||
	') t ';
	
  --RAISE NOTICE 'Execute: %', exectute_statement;
  		    
  -- execute statement
  FOR rec IN EXECUTE exectute_statement	    
  LOOP
    RETURN NEXT rec;    
  END LOOP;
END;$$ LANGUAGE plpgsql;
/******************************************************************
  pmt_validate_classifications
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_validate_classifications(classification_ids character varying) RETURNS INT[] AS $$
DECLARE 
  valid_classification_ids INT[];
  filter_classification_ids INT[];
BEGIN 
     IF $1 IS NULL THEN    
       RETURN valid_classification_ids;
     END IF;

     filter_classification_ids := string_to_array($1, ',')::int[];
     
     SELECT INTO valid_classification_ids array_agg(DISTINCT classification_id)::INT[] FROM (SELECT classification_id FROM classification WHERE active = true AND classification_id = ANY(filter_classification_ids) ORDER BY classification_id) as c;	 
     
     RETURN valid_classification_ids;

EXCEPTION
     WHEN others THEN RETURN NULL;
END; 
$$ LANGUAGE 'plpgsql';
/******************************************************************
  pmt_validate_classification
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_validate_classification(id integer) RETURNS boolean AS $$
DECLARE valid_id integer;
BEGIN 
     IF $1 IS NULL THEN    
       RETURN FALSE;
     END IF;    
     
     SELECT INTO valid_id classification_id FROM classification WHERE active = true AND classification_id = $1;	 

     IF valid_id IS NULL THEN
      RETURN FALSE;
     ELSE 
      RETURN TRUE;
     END IF;
     
EXCEPTION WHEN others THEN
    RETURN FALSE;
END; 
$$ LANGUAGE 'plpgsql';
/******************************************************************
  pmt_validate_taxonomies
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_validate_taxonomies(taxonomy_ids character varying) RETURNS INT[] AS $$
DECLARE 
  valid_taxonomy_ids INT[];
  filter_taxonomy_ids INT[];
BEGIN 
     IF $1 IS NULL THEN    
       RETURN valid_taxonomy_ids;
     END IF;

     filter_taxonomy_ids := string_to_array($1, ',')::int[];
     
     SELECT INTO valid_taxonomy_ids array_agg(DISTINCT taxonomy_id)::INT[] FROM (SELECT taxonomy_id FROM taxonomy WHERE active = true AND taxonomy_id = ANY(filter_taxonomy_ids) ORDER BY taxonomy_id) AS t;
     
     RETURN valid_taxonomy_ids;

EXCEPTION
     WHEN others THEN RETURN NULL;
END; 
$$ LANGUAGE 'plpgsql';
/******************************************************************
  pmt_validate_taxonomy
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_validate_taxonomy(id integer) RETURNS boolean AS $$
DECLARE valid_id integer;
BEGIN 
     IF $1 IS NULL THEN    
       RETURN false;
     END IF;    
     
     SELECT INTO valid_id taxonomy_id FROM taxonomy WHERE active = true AND taxonomy_id = $1;	 

     IF valid_id IS NULL THEN
      RETURN false;
     ELSE 
      RETURN true;
     END IF;
     
EXCEPTION WHEN others THEN
    RETURN FALSE;
END; 
$$ LANGUAGE 'plpgsql';
/******************************************************************
  pmt_category_root
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_category_root(id integer, data_group integer) RETURNS INT AS $$
DECLARE 
  valid_taxonomy_id boolean;
  base_taxonomy_ids integer[];
  base_taxonomy_id integer;
  data_group_id integer;
  is_current_category boolean;
  dynamic_where1 text;
  dynamic_where2 text;
  execute_statement text;
  sub_category record;
  subsub_category record;
  rec record;
BEGIN 

     IF $1 IS NULL THEN    
       RETURN base_taxonomy_ids;
     END IF;
     -- validation test
     SELECT INTO valid_taxonomy_id * FROM pmt_validate_taxonomy($1);
     -- is a valid taxonomy
     IF valid_taxonomy_id THEN
       -- is the current taxonomy a category?
       SELECT INTO is_current_category is_category FROM taxonomy WHERE taxonomy_id = $1;
         -- Yes, loop through the sub-category(ies)
         IF is_current_category THEN
           FOR sub_category IN (SELECT taxonomy_id, is_category FROM taxonomy WHERE category_id = $1) LOOP
           -- RAISE NOTICE 'sub category: %', sub_category.taxonomy_id || ' ' || sub_category.is_category;
             -- is the sub-category a category?
             IF sub_category.is_category THEN
               -- Yes, loop through the sub-sub-category(ies) 
               FOR subsub_category IN (SELECT taxonomy.taxonomy_id, taxonomy.is_category FROM taxonomy WHERE category_id = sub_category.taxonomy_id) LOOP
                 IF subsub_category.is_category THEN
                   -- this is currently the limit in category depth for PMT (this could be expanded)
                 ELSE
                   -- No, this is a base taxonomy for the given category, collect it
                   base_taxonomy_ids := array_append(base_taxonomy_ids, subsub_category.taxonomy_id);
                 END IF;
               END LOOP;               
             ELSE
               -- No, this is a base taxonomy for the given category, collect it
               base_taxonomy_ids := array_append(base_taxonomy_ids, sub_category.taxonomy_id);
             END IF;
           END LOOP;
         ELSE
           -- No, this is a base taxonomy
	   base_taxonomy_ids := array_append(base_taxonomy_ids, $1);
         END IF;
     ELSE
     END IF;
     
     -- validate and process data_group parameter
     IF $2 IS NOT NULL THEN
       -- check that the data group exists
       SELECT INTO data_group_id classification.classification_id FROM classification WHERE classification.classification_id = $2 AND classification.taxonomy_id = (SELECT taxonomy.taxonomy_id FROM taxonomy WHERE name = 'Data Group');
       -- RAISE NOTICE 'data group: %', data_group_id;
       -- add where statement if data group is valid
       IF data_group_id IS NOT NULL THEN	
          dynamic_where1 := ' and project_id in (select distinct project_id from taxonomy_lookup where classification_id =' || data_group_id || ')';
          dynamic_where2 := ' and project_id in (select distinct project_id from taxonomy_lookup where classification_id =' || data_group_id || ')';
       END IF;    
     END IF;
     
     -- prepare statement
     execute_statement := 'SELECT taxonomy_id ' 
	|| ' FROM (SELECT taxonomy_id, count(location_id) as rec_count ' 
        || ' FROM taxonomy_lookup '
        || ' WHERE taxonomy_id = ANY(ARRAY[' || array_to_string(base_taxonomy_ids, ',') || ']) ';
        
     IF dynamic_where1 IS NOT NULL THEN
	execute_statement := execute_statement || ' ' || dynamic_where1 || ' ';
     END IF;

     execute_statement := execute_statement || ' GROUP BY taxonomy_id) t2 JOIN '
        || '(SELECT MAX(t1.rec_count) as rec_max FROM '
	|| '(SELECT count(location_id) as rec_count '
	|| 'FROM taxonomy_lookup ' 
     	|| 'WHERE taxonomy_id = ANY(ARRAY[' || array_to_string(base_taxonomy_ids, ',') || ']) ';

     IF dynamic_where2 IS NOT NULL THEN
	execute_statement := execute_statement || ' ' || dynamic_where2 || ' ';
     END IF;
      	
     execute_statement := execute_statement || 'GROUP BY taxonomy_id) t1 ) t3 '
     	|| 'ON t2.rec_count = t3.rec_max LIMIT 1;';

     -- determine root taxonomy to return by popularity
       FOR rec IN EXECUTE execute_statement	    
	  LOOP
	    base_taxonomy_id := rec.taxonomy_id;
	  END LOOP;
      
     RETURN base_taxonomy_id;

 EXCEPTION
      WHEN others THEN RETURN NULL;
END; 
$$ LANGUAGE 'plpgsql';
/******************************************************************
  pmt_activities_by_tax 
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_activities_by_tax(tax_id Integer, data_group Integer, country_ids character varying)
RETURNS SETOF pmt_activities_by_tax_result_type AS $$
DECLARE
  data_group_id integer;
  valid_country_ids int[];
  valid_classification_ids int[];
  filter_ids int[];
  valid_taxonomy_id boolean;
  report_by_category boolean; 
  report_taxonomy_id integer;
  dynamic_where1 text;
  dynamic_where2 text;
  dynamic_join text;
  execute_statement text;
--  new_c_ids text;
  rec record;
BEGIN
  report_by_category := false; -- intialize to false  
  
  -- validate and process taxonomy_id parameter
  IF $1 IS NOT NULL THEN
    SELECT INTO valid_taxonomy_id * FROM pmt_validate_taxonomy($1);    
    -- has valid taxonomy id
    IF valid_taxonomy_id THEN 
       report_taxonomy_id := $1;
      -- is this taxonomy a category?
      SELECT INTO report_by_category is_category FROM taxonomy WHERE taxonomy_id = (report_taxonomy_id);      
      -- yes, this is a category taxonomy
      IF report_by_category THEN
        -- what are the root taxonomy(ies) of the category taxonomy
        SELECT INTO report_taxonomy_id * FROM pmt_category_root(report_taxonomy_id, data_group);
        -- there are root taxonomy(ies)
        IF report_taxonomy_id IS NOT NULL THEN
           -- RAISE NOTICE 'report_taxonomy_id: %', report_taxonomy_id;
        ELSE
          report_taxonomy_id := $1;
          report_by_category := false;
        END IF;
      END IF;
      
      -- add the taxonomy to the report_by selection
      dynamic_where2 := ' WHERE taxonomy_id = ' || report_taxonomy_id || ' ';
      
    END IF;	
  END IF;
  
  -- validate and process data_group parameter
  IF $2 IS NOT NULL THEN
    -- check that the data group exists
    SELECT INTO data_group_id classification.classification_id FROM classification WHERE classification.classification_id = $2 AND classification.taxonomy_id = (SELECT taxonomy.taxonomy_id FROM taxonomy WHERE name = 'Data Group');
    RAISE NOTICE 'data group: %', data_group_id;
    -- add where statement if data group is valid
    IF data_group_id IS NOT NULL THEN	
       filter_ids := array_append(filter_ids, data_group_id);
      dynamic_where1 := ' WHERE classification_id = ' || data_group_id || ' ';
    END IF;    
  END IF;

  -- validate and process country_ids parameter
  IF $3 IS NOT NULL OR $3 <> '' THEN
    SELECT INTO valid_classification_ids * FROM pmt_validate_classifications($3);
    RAISE NOTICE 'valid classification ids: %', valid_classification_ids;
    IF valid_classification_ids IS NOT NULL THEN
      SELECT INTO valid_country_ids array_agg(DISTINCT classification_id)::INT[] 
      FROM (
        SELECT classification_id 
        FROM classification 
        WHERE active = true 
        AND classification_id = ANY(valid_classification_ids)
        AND classification.taxonomy_id = (SELECT taxonomy.taxonomy_id FROM taxonomy WHERE iati_codelist = 'Country')
         ORDER BY classification_id
      ) as c;	
    END IF;
    
    IF valid_country_ids IS NOT NULL THEN
      filter_ids := valid_country_ids;
      IF data_group_id IS NOT NULL THEN
      filter_ids := array_append(filter_ids, data_group_id);
      END IF;
    END IF; 
    
  END IF;
  
  -- prepare statement
  execute_statement := 'SELECT DISTINCT t1.activity_id,a.title, array_to_string(array_agg(DISTINCT report_by.classification_id), '','') AS c_ids FROM ' ||
			'(SELECT DISTINCT activity_id, array_agg(distinct taxonomy_id) as taxonomy_ids, array_agg(classification_id) as classification_ids, array_agg(organization_id) as organization_ids ' ||
			'FROM taxonomy_lookup  ' ||
			'GROUP BY activity_id ' ||
			') AS t1  ' ||
			'LEFT JOIN (SELECT * FROM taxonomy_lookup ';
  IF report_taxonomy_id IS NOT NULL THEN
   execute_statement := execute_statement || ' WHERE taxonomy_id = ' || report_taxonomy_id || ' ';
  END IF; 
  execute_statement := execute_statement || ') AS report_by ' ||	
			'ON t1.activity_id = report_by.activity_id ' ||
			'JOIN (SELECT activity_id, title FROM activity) as a ' ||
			'ON a.activity_id = t1.activity_id ';
  IF filter_ids IS NOT NULL THEN
   execute_statement := execute_statement || 'WHERE classification_ids @> ARRAY [' || array_to_string(filter_ids, ',') || '] ';
  END IF;			

  execute_statement := execute_statement || 'GROUP BY t1.activity_id,a.title';		      	      
		       
  -- execute statement
  RAISE NOTICE 'Execute statement: %', execute_statement;
  FOR rec IN EXECUTE execute_statement LOOP
   IF report_by_category THEN 
      SELECT INTO rec.c_ids array_to_string(array_agg(DISTINCT category_id), ',') FROM classification WHERE classification_id = ANY(string_to_array(rec.c_ids, ',')::int[]);
      RETURN NEXT rec;
    ELSE
      RETURN NEXT rec;    
    END IF;
  END LOOP; 
END; 
$$ LANGUAGE 'plpgsql';
/******************************************************************
  pmt_validate_activities
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_validate_activities(activity_ids character varying) RETURNS INT[] AS $$
DECLARE 
  valid_activity_ids INT[];
  filter_activity_ids INT[];
BEGIN 
     IF $1 IS NULL THEN    
       RETURN valid_activity_ids;
     END IF;

     filter_activity_ids := string_to_array($1, ',')::int[];
     
     SELECT INTO valid_activity_ids array_agg(DISTINCT activity_id)::INT[] FROM (SELECT activity_id FROM activity WHERE active = true AND activity_id = ANY(filter_activity_ids) ORDER BY activity_id) AS t;
     
     RETURN valid_activity_ids;

EXCEPTION
     WHEN others THEN RETURN NULL;
END; 
$$ LANGUAGE 'plpgsql';
/******************************************************************
  pmt_validate_activity
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_validate_activity(id integer) RETURNS boolean AS $$
DECLARE valid_id integer;
BEGIN 
     IF $1 IS NULL THEN    
       RETURN false;
     END IF;    
     
     SELECT INTO valid_id activity_id FROM activity WHERE active = true AND activity_id = $1;	 

     IF valid_id IS NULL THEN
      RETURN false;
     ELSE 
      RETURN true;
     END IF;
     
EXCEPTION WHEN others THEN
    RETURN FALSE;
END; 
$$ LANGUAGE 'plpgsql';
/******************************************************************
  pmt_infobox_menu
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_infobox_menu(location_ids text)
RETURNS SETOF pmt_infobox_result_type AS 
$$
DECLARE
  filter_locids int[]; 
  rec record;
BEGIN
	IF $1 IS NOT NULL OR $1 <> '' THEN
		-- Create an int array from location ids list
		filter_locids := string_to_array($1, ',')::int[];
				
		FOR rec IN (
		select row_to_json(p)
		from (
		   select project.project_id as p_id, title, bounds,
			(	
			select array_to_json(array_agg(row_to_json(a)))
			from(
			   select distinct activity.activity_id as a_id, title
			   from activity 
			   join (select distinct project_id, activity_id 
				 from taxonomy_lookup
				 where location_id = ANY(filter_locids)
				 ) as t1
			   on activity.activity_id = t1.activity_id
			  where activity.project_id = project.project_id
			) a
			) as activities
		   from project   
		   join (select distinct tl.project_id,  ST_AsGeoJSON(Box2D(ST_Collect(l.point))) as bounds
			 from taxonomy_lookup tl
			 join location l
			 on tl.location_id = l.location_id
			 where tl.location_id = ANY(filter_locids)
			 group by tl.project_id
			 ) as t2
		   on project.project_id = t2.project_id
		   ) p
		) LOOP		
			RETURN NEXT rec;
		END LOOP;
	END IF;
END;$$ LANGUAGE plpgsql;

/*****************************************************************
VIEWS -- under development and not final. Currently for the 
purpose checking validitiy of data migration.
******************************************************************/
-------------------------------------------------------------------
-- project activity points
-------------------------------------------------------------------
-- all
CREATE OR REPLACE VIEW project_activity_points
    AS SELECT p.project_id, p.title as project_title, a.activity_id, a.title as activity_title, l.location_id, l.point 
FROM project p
JOIN activity a
ON p.project_id = a.project_id
JOIN location l
ON a.activity_id = l.activity_id;
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
WHERE a.active = true and p.active = true and l.active = true 
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
WHERE a.active = true and p.active = true and l.active = true ) as foo
ORDER BY project_id, activity_id, location_id, organization_id;
-------------------------------------------------------------------
-- taxonomy
-------------------------------------------------------------------
-- available taxonomy
CREATE OR REPLACE VIEW taxonomy_classifications
AS SELECT t.taxonomy_id, t.name as taxonomy, t.is_category, t.category_id as taxonomy_category_id, t.iati_codelist, t.description, c.classification_id, c.name as classification, c.category_id as classification_category_id, c.iati_code, c.iati_name
FROM taxonomy t
JOIN classification c
ON t.taxonomy_id = c.taxonomy_id
WHERE t.active = true and c.active = true
ORDER BY t.taxonomy_id, c.classification_id;
-- project taxonomy
CREATE OR REPLACE VIEW project_taxonomies
AS SELECT p.project_id, p.title as project_title, t.name as taxonomy, c.name as classification
FROM project p
JOIN project_taxonomy pt
on p.project_id = pt.project_id
JOIN classification c
on pt.classification_id = c.classification_id
JOIN taxonomy t
ON c.taxonomy_id = t.taxonomy_id
WHERE p.active = true AND c.active = true
ORDER BY p.project_id;
-- activity taxonomy
CREATE OR REPLACE VIEW activity_taxonomies
AS SELECT a.project_id, p.title as project_title, a.activity_id, a.title as activity_title, t.name as taxonomy, c.name as classification
FROM activity a
JOIN project p
ON a.project_id = p.project_id
JOIN activity_taxonomy at
on a.activity_id = at.activity_id
JOIN classification c
on at.classification_id = c.classification_id
JOIN taxonomy t
ON c.taxonomy_id = t.taxonomy_id
WHERE a.active = true and c.active = true
ORDER BY a.project_id, a.activity_id;
-- entity_taxonomy
CREATE OR REPLACE VIEW entity_taxonomy
AS
SELECT participation_id as id, classification_id, field FROM participation_taxonomy
UNION ALL
SELECT project_id as id, classification_id, field FROM project_taxonomy
UNION ALL
SELECT activity_id as id, classification_id, field FROM activity_taxonomy
UNION ALL
SELECT location_id as id, classification_id, field FROM location_taxonomy
UNION ALL
SELECT organization_id as id, classification_id, field FROM organization_taxonomy;
-------------------------------------------------------------------
-- organization participation in projects and activities
-------------------------------------------------------------------
CREATE OR REPLACE VIEW organization_participation
AS SELECT p.project_id, p.activity_id, o.* 
FROM organization o
JOIN participation p
ON o.organization_id = p.organization_id
ORDER BY p.project_id, p.activity_id;
-- Accountable Organizations
CREATE OR REPLACE VIEW accountable_organizations
AS SELECT DISTINCT o.organization_id, o.name, pt.classification_id 
FROM participation p
JOIN participation_taxonomy pt
ON p.participation_id = pt.participation_id
JOIN organization o
ON p.organization_id = o.organization_id
WHERE pt.classification_id = 
(SELECT classification_id FROM classification WHERE name = 'Accountable' AND taxonomy_id = (SELECT taxonomy_id FROM taxonomy WHERE name = 'Organisation Role'))
ORDER BY o.name;
-- Accountable Project Participants
CREATE OR REPLACE VIEW accountable_project_participants
AS SELECT p.project_id AS p_id, p.title, p.a_ids, organization.name AS org,  p.initiatives AS init
FROM participation
  -- participation records with no taxonomy will be dropped
  JOIN participation_taxonomy 
  ON participation_taxonomy.participation_id = participation.participation_id    
  JOIN organization 
  ON organization.organization_id = participation.organization_id   
  LEFT JOIN (
	SELECT project.project_id, at.a_ids, project.title, project.active, pt.classifications AS initiatives 
	FROM project 
	LEFT JOIN (
		-- projects with Initiative taxonomy
		SELECT project_id, array_to_string(array_agg(classification), ',') AS classifications 
		FROM project_taxonomies 
		WHERE taxonomy = 'Initiative' 
		GROUP BY project_id
		) pt -- 222 rows
	ON project.project_id = pt.project_id
	LEFT JOIN ( 
		-- active activities
		SELECT array_to_string(array_agg(activity_id), ',') AS a_ids, project_id 
		FROM activity 
		WHERE active = TRUE 
		GROUP BY project_id
		) at -- 219 rows
	ON project.project_id = at.project_id
	) p 
  ON participation.project_id = p.project_id 
  JOIN taxonomy_classifications 
  ON taxonomy_classifications.classification_id = participation_taxonomy.classification_id 
WHERE 
 participation_taxonomy.classification_id = (SELECT classification_id FROM classification WHERE name = 'Accountable' AND taxonomy_id = (SELECT taxonomy_id FROM taxonomy WHERE name = 'Organisation Role')) AND 
 p.active = TRUE AND
 organization.active = TRUE
ORDER BY p.project_id;
-------------------------------------------------------------------
-- contacts
-------------------------------------------------------------------
-- project contacts
CREATE OR REPLACE VIEW project_contacts
AS SELECT p.project_id,p.title as project_title, c.salutation, c.first_name, c.last_name
FROM project p
LEFT JOIN project_contact pc
ON p.project_id = pc.project_id
JOIN contact c
ON pc.contact_id = c.contact_id
ORDER BY p.project_id;
-- activity contacts
CREATE OR REPLACE VIEW activity_contacts
AS SELECT a.project_id,p.title as project_title, a.activity_id, a.title as action_title, c.salutation, c.first_name, c.last_name
FROM activity a
LEFT JOIN activity_contact ac
ON a.activity_id = ac.activity_id
JOIN project p
ON a.project_id = p.project_id
JOIN contact c
ON ac.contact_id = c.contact_id
ORDER BY a.project_id, a.activity_id;
-------------------------------------------------------------------
-- Get all boundary information for a location
-------------------------------------------------------------------
CREATE OR REPLACE VIEW location_boundary_features
AS SELECT l.location_id, l.activity_id, b.boundary_id, b.name as boundary_name, g0.name
FROM location l
JOIN location_boundary lb
ON l.location_id = lb.location_id
JOIN boundary b
ON lb.boundary_id = b.boundary_id
JOIN gaul0 g0
ON lb.feature_id = g0.feature_id AND lb.boundary_id = g0.boundary_id
--WHERE l.location_id = 123
UNION ALL
SELECT l.location_id, l.activity_id, b.boundary_id,  b.name as boundary_name, g1.name
FROM location l
JOIN location_boundary lb
ON l.location_id = lb.location_id
JOIN boundary b
ON lb.boundary_id = b.boundary_id
JOIN gaul1 g1
ON lb.feature_id = g1.feature_id AND lb.boundary_id = g1.boundary_id
--WHERE l.location_id = 123
UNION ALL
SELECT l.location_id, l.activity_id, b.boundary_id,  b.name as boundary_name, g2.name
FROM location l
JOIN location_boundary lb
ON l.location_id = lb.location_id
JOIN boundary b
ON lb.boundary_id = b.boundary_id
JOIN gaul2 g2
ON lb.feature_id = g2.feature_id AND lb.boundary_id = g2.boundary_id
ORDER BY location_id, boundary_id;
--WHERE l.location_id = 123
-------------------------------------------------------------------
-- Misc
-------------------------------------------------------------------
CREATE OR REPLACE VIEW tags
AS SELECT DISTINCT tag
FROM
(SELECT DISTINCT TRIM(regexp_split_to_table(tags, ',')) as tag 
from activity
UNION ALL
SELECT DISTINCT TRIM(regexp_split_to_table(tags, ',')) as tag 
from project) t;
-- gual_lookup
CREATE OR REPLACE VIEW gaul_lookup AS  
SELECT code, name, gaul0_name, gaul1_name, name AS gaul2_name, ST_AsGeoJSON(Box2D(polygon)) AS bounds 
FROM gaul2
UNION
SELECT DISTINCT gaul1.code, gaul1.name, gaul2.gaul0_name, gaul1.name AS gaul1_name, null AS gaul2_name, ST_AsGeoJSON(Box2D(gaul1.polygon))  AS bounds 
FROM gaul1 
JOIN gaul2 ON gaul1.name = gaul2.gaul1_name
UNION
SELECT DISTINCT gaul0.code, gaul0.name, gaul0.name, null AS gaul1_name, null AS gaul2_name, ST_AsGeoJSON(Box2D(gaul0.polygon))  AS bounds 
FROM gaul0;
