/*********************************************************************
	PMT Database Creation Script	
This script will create or replace the entire PMT database structure. 
**********************************************************************/
-- Enable PLPGSQL language;
CREATE OR REPLACE LANGUAGE plpgsql;

-- Enable PostGIS (includes raster)
CREATE EXTENSION IF NOT EXISTS postgis; 

-- Enable Encryption
CREATE EXTENSION IF NOT EXISTS pgcrypto;

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
DROP TABLE IF EXISTS  map CASCADE;
DROP TABLE IF EXISTS  participation CASCADE;
DROP TABLE IF EXISTS  participation_taxonomy CASCADE;
DROP TABLE IF EXISTS  project CASCADE;
DROP TABLE IF EXISTS  project_contact CASCADE;
DROP TABLE IF EXISTS  project_taxonomy CASCADE;
DROP TABLE IF EXISTS  result CASCADE;
DROP TABLE IF EXISTS  result_taxonomy CASCADE;
DROP TABLE IF EXISTS  role CASCADE;
DROP TABLE IF EXISTS  taxonomy CASCADE;
DROP TABLE IF EXISTS "user" CASCADE;
DROP TABLE IF EXISTS  user_activity CASCADE;
DROP TABLE IF EXISTS  user_role CASCADE;
DROP TABLE IF EXISTS "version" CASCADE;
DROP TABLE IF EXISTS  xml CASCADE;

--Drop Views  (if they exist)
DROP VIEW IF EXISTS accountable_project_participants CASCADE;
DROP VIEW IF EXISTS accountable_organizations CASCADE;
DROP VIEW IF EXISTS active_project_activities CASCADE;
DROP VIEW IF EXISTS activity_contacts CASCADE;
DROP VIEW IF EXISTS activity_taxonomies CASCADE;
DROP VIEW IF EXISTS gaul_lookup CASCADE;
DROP VIEW IF EXISTS location_boundary_features CASCADE;
DROP VIEW IF EXISTS organization_participation CASCADE;
DROP VIEW IF EXISTS project_activity_points CASCADE;
DROP VIEW IF EXISTS project_contacts CASCADE;
DROP VIEW IF EXISTS project_taxonomies CASCADE;
DROP VIEW IF EXISTS tags CASCADE; 
DROP VIEW IF EXISTS taxonomy_classifications CASCADE;

DROP MATERIALIZED VIEW IF EXISTS location_lookup CASCADE;
DROP MATERIALIZED VIEW IF EXISTS organization_lookup CASCADE;
DROP MATERIALIZED VIEW IF EXISTS taxonomy_lookup CASCADE;

-- Drop Enumerators
DROP TYPE IF EXISTS pmt_auth_crud CASCADE;
DROP TYPE IF EXISTS pmt_auth_source CASCADE;
DROP TYPE IF EXISTS pmt_edit_action CASCADE;

-- Create Enumerators
CREATE TYPE pmt_auth_crud AS ENUM ('create','read','update','delete');
CREATE TYPE pmt_auth_source AS ENUM ('organization','data_group');
CREATE TYPE pmt_edit_action AS ENUM ('add','delete','replace');

--Drop Functions
DROP FUNCTION IF EXISTS refresh_taxonomy_lookup() CASCADE;
DROP FUNCTION IF EXISTS pmt_activate_activity(integer, integer, boolean)  CASCADE;
DROP FUNCTION IF EXISTS pmt_activate_project(integer, integer, boolean)  CASCADE;
DROP FUNCTION IF EXISTS pmt_activities()  CASCADE;
DROP FUNCTION IF EXISTS pmt_activities_by_tax(Integer, Integer, character varying) CASCADE;
DROP FUNCTION IF EXISTS pmt_activity(integer)  CASCADE;
DROP FUNCTION IF EXISTS pmt_activity_details(integer) CASCADE;
DROP FUNCTION IF EXISTS pmt_activity_listview(character varying, character varying, character varying, date, date, character varying, text, integer, integer) CASCADE;
DROP FUNCTION IF EXISTS pmt_activity_listview_ct(character varying, character varying, character varying, date, date) CASCADE;
DROP FUNCTION IF EXISTS pmt_auth_user(character varying, character varying) CASCADE;
DROP FUNCTION IF EXISTS pmt_auto_complete(character varying, character varying) CASCADE;
DROP FUNCTION IF EXISTS pmt_bytea_import(TEXT, OUT bytea) CASCADE;
DROP FUNCTION IF EXISTS pmt_iati_import(text, character varying, boolean) CASCADE;
DROP FUNCTION IF EXISTS pmt_isnumeric(text) CASCADE;
DROP FUNCTION IF EXISTS pmt_isdate(text) CASCADE;
DROP FUNCTION IF EXISTS pmt_category_root(integer, integer) CASCADE;
DROP FUNCTION IF EXISTS pmt_category_root(integer, character varying) CASCADE;
DROP FUNCTION IF EXISTS pmt_contacts()  CASCADE;
DROP FUNCTION IF EXISTS pmt_countries(text) CASCADE;
DROP FUNCTION IF EXISTS pmt_create_user(integer, integer, integer, character varying(255), character varying(255), character varying(255), character varying(150), character varying(150));
DROP FUNCTION IF EXISTS pmt_data_groups() CASCADE;
DROP FUNCTION IF EXISTS pmt_edit_activity(integer, integer, json, boolean)  CASCADE;
DROP FUNCTION IF EXISTS pmt_edit_activity_contact(integer, integer, integer, pmt_edit_action)  CASCADE;
DROP FUNCTION IF EXISTS pmt_edit_activity_taxonomy(character varying, integer, pmt_edit_action)  CASCADE;
DROP FUNCTION IF EXISTS pmt_edit_contact(integer, integer, json, boolean)  CASCADE;
DROP FUNCTION IF EXISTS pmt_edit_detail(integer, integer, integer, integer, json, boolean)  CASCADE;
DROP FUNCTION IF EXISTS pmt_edit_financial(integer, integer, integer, integer, json, boolean)  CASCADE;
DROP FUNCTION IF EXISTS pmt_edit_location(integer, integer, integer, json, boolean)  CASCADE;
DROP FUNCTION IF EXISTS pmt_edit_location_taxonomy(integer, integer, integer, pmt_edit_action)  CASCADE;
DROP FUNCTION IF EXISTS pmt_edit_organization(integer, integer, json, boolean)  CASCADE;
DROP FUNCTION IF EXISTS pmt_edit_participation(integer, integer, integer, integer, integer, integer, pmt_edit_action)  CASCADE;
DROP FUNCTION IF EXISTS pmt_edit_project(integer, integer, json, boolean)  CASCADE;
DROP FUNCTION IF EXISTS pmt_edit_project_contact(integer, integer, integer, pmt_edit_action)  CASCADE;
DROP FUNCTION IF EXISTS pmt_edit_project_taxonomy(integer, integer, integer, pmt_edit_action)  CASCADE;
DROP FUNCTION IF EXISTS pmt_filter_csv(character varying, character varying, character varying, date, date, text);
DROP FUNCTION IF EXISTS pmt_filter_iati(character varying, character varying, character varying, date, date, text) CASCADE;
DROP FUNCTION IF EXISTS pmt_filter_locations(integer, character varying, character varying, character varying, date, date) CASCADE;
DROP FUNCTION IF EXISTS pmt_filter_orgs(character varying, character varying, character varying, date, date) CASCADE;
DROP FUNCTION IF EXISTS pmt_filter_projects(character varying, character varying, character varying, date, date) CASCADE;
DROP FUNCTION IF EXISTS pmt_global_search(text)  CASCADE;
DROP FUNCTION IF EXISTS pmt_infobox_menu(text)  CASCADE;
DROP FUNCTION IF EXISTS pmt_infobox_activity(integer)  CASCADE;
DROP FUNCTION IF EXISTS pmt_infobox_activity_contact(integer)  CASCADE;
DROP FUNCTION IF EXISTS pmt_infobox_activity_desc(integer)  CASCADE;
DROP FUNCTION IF EXISTS pmt_infobox_activity_stats(integer)  CASCADE;
DROP FUNCTION IF EXISTS pmt_infobox_project_contact(integer)  CASCADE;
DROP FUNCTION IF EXISTS pmt_infobox_project_desc(integer)  CASCADE;
DROP FUNCTION IF EXISTS pmt_infobox_project_info(integer, integer)  CASCADE;
DROP FUNCTION IF EXISTS pmt_infobox_project_nutrition(integer)  CASCADE;
DROP FUNCTION IF EXISTS pmt_infobox_project_stats(integer)  CASCADE;
DROP FUNCTION IF EXISTS pmt_locations(character varying)  CASCADE;
DROP FUNCTION IF EXISTS pmt_locations_by_org(integer, integer, character varying) CASCADE;
DROP FUNCTION IF EXISTS pmt_locations_by_polygon(text) CASCADE;
DROP FUNCTION IF EXISTS pmt_locations_by_tax(integer, integer, character varying) CASCADE;
DROP FUNCTION IF EXISTS pmt_locations_by_tax(Integer, character varying, character varying) CASCADE;
DROP FUNCTION IF EXISTS pmt_org_inuse(character varying) CASCADE;
DROP FUNCTION IF EXISTS pmt_orgs()  CASCADE;
DROP FUNCTION IF EXISTS pmt_project(integer) CASCADE;
DROP FUNCTION IF EXISTS pmt_projects()  CASCADE;
DROP FUNCTION IF EXISTS pmt_project_listview(integer, character varying, character varying, character varying, date, date, text, integer, integer) CASCADE;
DROP FUNCTION IF EXISTS pmt_project_listview_ct(character varying, character varying, character varying, date, date) CASCADE;
DROP FUNCTION IF EXISTS pmt_purge_activity(integer) CASCADE;
DROP FUNCTION IF EXISTS pmt_purge_project(integer) CASCADE;
DROP FUNCTION IF EXISTS pmt_sector_compare(character varying, character varying)  CASCADE;
DROP FUNCTION IF EXISTS pmt_stat_counts(character varying, character varying, character varying, date, date) CASCADE;
DROP FUNCTION IF EXISTS pmt_stat_activity_by_district(integer, character varying, character varying, integer)  CASCADE;
DROP FUNCTION IF EXISTS pmt_stat_activity_by_tax(integer, character varying, character varying, character varying, date, date) CASCADE;
DROP FUNCTION IF EXISTS pmt_stat_locations(character varying, character varying, character varying, date, date) CASCADE;
DROP FUNCTION IF EXISTS pmt_stat_partner_network(character varying)  CASCADE;
DROP FUNCTION IF EXISTS pmt_stat_pop_by_district(character varying, character varying)  CASCADE;
DROP FUNCTION IF EXISTS pmt_stat_project_by_tax(integer, character varying, character varying, character varying, date, date) CASCADE;
DROP FUNCTION IF EXISTS pmt_stat_orgs_by_activity(integer, character varying, character varying, character varying, date, date) CASCADE;
DROP FUNCTION IF EXISTS pmt_stat_orgs_by_district(integer, character varying, character varying, integer, integer)  CASCADE;
DROP FUNCTION IF EXISTS pmt_tax_inuse(integer, character varying, character varying)  CASCADE;
DROP FUNCTION IF EXISTS pmt_taxonomies(character varying)  CASCADE;
DROP FUNCTION IF EXISTS pmt_update_user(integer, integer, integer, integer, character varying(255), character varying(255),  character varying(255), character varying(150), character varying(150));
DROP FUNCTION IF EXISTS pmt_user_auth(character varying, character varying) CASCADE;
DROP FUNCTION IF EXISTS pmt_user_salt(integer) CASCADE;
DROP FUNCTION IF EXISTS pmt_users();
DROP FUNCTION IF EXISTS pmt_validate_activities(character varying)  CASCADE;
DROP FUNCTION IF EXISTS pmt_validate_activity(integer)  CASCADE;
DROP FUNCTION IF EXISTS pmt_validate_boundary_feature(integer, integer)  CASCADE;
DROP FUNCTION IF EXISTS pmt_validate_classification(integer)  CASCADE;
DROP FUNCTION IF EXISTS pmt_validate_classifications(character varying)  CASCADE;
DROP FUNCTION IF EXISTS pmt_validate_contact(integer)  CASCADE;
DROP FUNCTION IF EXISTS pmt_validate_contacts(character varying)  CASCADE;
DROP FUNCTION IF EXISTS pmt_validate_detail(integer)  CASCADE;
DROP FUNCTION IF EXISTS pmt_validate_financial(integer)  CASCADE;
DROP FUNCTION IF EXISTS pmt_validate_location(integer)  CASCADE;
DROP FUNCTION IF EXISTS pmt_validate_locations(character varying)  CASCADE;
DROP FUNCTION IF EXISTS pmt_validate_organization(integer)  CASCADE;
DROP FUNCTION IF EXISTS pmt_validate_organizations(character varying)  CASCADE;
DROP FUNCTION IF EXISTS pmt_validate_project(integer)  CASCADE;
DROP FUNCTION IF EXISTS pmt_validate_projects(character varying)  CASCADE;
DROP FUNCTION IF EXISTS pmt_validate_taxonomy(integer)  CASCADE;
DROP FUNCTION IF EXISTS pmt_validate_taxonomies(character varying)  CASCADE;
DROP FUNCTION IF EXISTS pmt_validate_user_authority(integer, integer, pmt_auth_crud)  CASCADE;
DROP FUNCTION IF EXISTS pmt_version()  CASCADE;

--Drop Types  (if it exists)
DROP TYPE IF EXISTS pmt_activities_by_tax_result_type CASCADE;
DROP TYPE IF EXISTS pmt_data_groups_result_type CASCADE;
DROP TYPE IF EXISTS pmt_filter_locations_result CASCADE;
DROP TYPE IF EXISTS pmt_filter_orgs_result CASCADE;
DROP TYPE IF EXISTS pmt_filter_projects_result CASCADE;
DROP TYPE IF EXISTS pmt_json_result_type CASCADE;
DROP TYPE IF EXISTS pmt_locations_by_org_result_type CASCADE;
DROP TYPE IF EXISTS pmt_locations_by_tax_dd_result_type CASCADE;
DROP TYPE IF EXISTS pmt_locations_by_tax_result_type CASCADE;
DROP TYPE IF EXISTS pmt_version_result_type CASCADE;

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
	16. user_activity
	17. version
	18. xml
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
	,"plan_start_date"	date
	,"end_date"		date
	,"plan_end_date"	date
	,"tags"			character varying
	,"iati_identifier" 	character varying(50)
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
	,"download_dir"		text
	,"edit_auth_source"	pmt_auth_source			DEFAULT 'data_group'
	,"created_date" 	timestamp without time zone 	NOT NULL DEFAULT current_date
	,"updated_date" 	timestamp without time zone 	NOT NULL DEFAULT current_date
	,CONSTRAINT config_id PRIMARY KEY(config_id)
);
-- add the current configuration information
INSERT INTO config(version, download_dir) VALUES (2.0, '/var/lib/postgresql/9.3/main/');
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
	,"pop_total"		numeric(500,2)
	,"pop_poverty" 		numeric(500,2)
	,"pop_rural" 		numeric(500,2)
	,"pop_poverty_rural" 	numeric(500,2)
	,"pop_source"		text
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
	,"boundary_id"		integer
	,"feature_id"		integer
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
--Map
CREATE TABLE "map"
(
	"map_id"		SERIAL				NOT NULL
	,"user_id"		integer 			NOT NULL		
	,"title"		character varying		
	,"description"		character varying
	,"extent"		character varying
	,"filters"		json
	,"taxonomy_id"		integer
	,"organization_ids"	character varying
	,"classification_ids"	character varying
	,"unassigned_ids"	character varying
	,"location_ids"		character varying
	,"start_date"		date
	,"end_date"		date
	,"overlays"		character varying
	,"data_sources"		character varying
	,"public"		boolean				NOT NULL DEFAULT TRUE
	,"active"		boolean				NOT NULL DEFAULT TRUE
	,"retired_by"		integer	
	,"created_by" 		character varying(50)
	,"created_date" 	timestamp without time zone 	NOT NULL DEFAULT current_date
	,"updated_by" 		character varying(50)
	,"updated_date" 	timestamp without time zone 	NOT NULL DEFAULT current_date
	,CONSTRAINT map_id PRIMARY KEY(map_id)
);
--Organization
CREATE TABLE "organization"
(
	"organization_id"	SERIAL				NOT NULL
	,"name"			character varying
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
-- Role
CREATE TABLE "role"
(
	"role_id"		SERIAL				NOT NULL		
	,"name"			character varying		
	,"description"		character varying	
	,"read"			boolean				NOT NULL DEFAULT FALSE
	,"create"		boolean				NOT NULL DEFAULT FALSE
	,"update"		boolean				NOT NULL DEFAULT FALSE
	,"delete"		boolean				NOT NULL DEFAULT FALSE
	,"super"		boolean				NOT NULL DEFAULT FALSE
	,"active"		boolean				NOT NULL DEFAULT TRUE
	,"retired_by"		integer	
	,"created_by" 		character varying(50)
	,"created_date" 	timestamp without time zone 	NOT NULL DEFAULT current_date
	,"updated_by" 		character varying(50)
	,"updated_date" 	timestamp without time zone 	NOT NULL DEFAULT current_date
	,CONSTRAINT role_id PRIMARY KEY(role_id)
);
-- Add Basic PMT Core Roles
INSERT INTO role(name, description, read, "create", update, delete, super, created_by, updated_by) VALUES ('Reader', 'Reader role for read-only access to public data.', TRUE, FALSE, FALSE, FALSE, FALSE, 'PMT Core Role', 'PMT Core Role');
INSERT INTO role(name, description, read, "create", update, delete, super, created_by, updated_by) VALUES ('Editor', 'Editor role for read-only of all public data. Create and update rights to user data.', TRUE, TRUE, TRUE, FALSE, FALSE, 'PMT Core Role', 'PMT Core Role');
INSERT INTO role(name, description, read, "create", update, delete, super, created_by, updated_by) VALUES ('Super', 'Full access to all data.', TRUE, TRUE, TRUE, TRUE, TRUE, 'PMT Core Role', 'PMT Core Role');
-- User
CREATE TABLE "user"
(
	"user_id"		SERIAL				NOT NULL
	,"organization_id"	integer				NOT NULL
	,"data_group_id"	integer				NOT NULL 		
	,"first_name" 		character varying(150)
	,"last_name" 		character varying(150)
	,"username"		character varying(255)		NOT NULL
	,"email"		character varying(255)		NOT NULL
	,"password"		character varying(255)		NOT NULL
	,"active"		boolean				NOT NULL DEFAULT TRUE
	,"retired_by"		integer	
	,"created_by" 		character varying(50)
	,"created_date" 	timestamp without time zone 	NOT NULL DEFAULT now()
	,"updated_by" 		character varying(50)
	,"updated_date" 	timestamp without time zone 	NOT NULL DEFAULT now()
	,CONSTRAINT user_id PRIMARY KEY(user_id)
);
--User Activity
CREATE TABLE "user_activity"
(
	"user_activity_id"	SERIAL				NOT NULL
	,"user_id"		integer 			NULL			
	,"username"		character varying(255)		NOT NULL
	,"access_date" 		timestamp		 	NOT NULL DEFAULT current_timestamp
	,"status"		character varying(50)		NOT NULL 
	,CONSTRAINT user_activity_id PRIMARY KEY(user_activity_id)
);
-- Version
CREATE TABLE "version"
(
	"version_id"		SERIAL				NOT NULL
	,"version"		numeric(2,1)
	,"iteration" 		integer
	,"changeset" 		integer
	,"created_date" 	timestamp without time zone 	NOT NULL DEFAULT current_date
	,"updated_date" 	timestamp without time zone 	NOT NULL DEFAULT current_date
	,CONSTRAINT version_id PRIMARY KEY(version_id)
);
-- add the current version information
INSERT INTO version(version, iteration, changeset) VALUES (2.0, 8, 51);
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
-- user_role
CREATE TABLE "user_role"
(
	"user_id"		integer				NOT NULL
	,"role_id"		integer				NOT NULL
	,CONSTRAINT user_role_id PRIMARY KEY(user_id,role_id)
);
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
	ft RECORD;
	rec RECORD;
	spatialtable text;
	execute_statement text;
	centroid geometry;
	id integer;
    BEGIN
      --RAISE NOTICE 'Refreshing boundary features for location_id % ...', NEW.location_id;
      EXECUTE 'DELETE FROM location_boundary WHERE location_id = ' || NEW.location_id;

      IF (SELECT * FROM pmt_validate_boundary_feature(NEW.boundary_id, NEW.feature_id)) THEN
        SELECT INTO spatialtable spatial_table FROM boundary b WHERE active = true AND b.boundary_id = NEW.boundary_id;
        -- get centroid and assign as NEW.point
        execute_statement := 'SELECT ST_Transform(ST_Centroid((SELECT polygon FROM ' || quote_ident(spatialtable) || ' WHERE feature_id = ' || NEW.feature_id || ' LIMIT 1)),4326)' ;
        EXECUTE execute_statement INTO centroid;
	IF (centroid IS NOT NULL) THEN	
	  RAISE NOTICE 'Centroid of boundary assigned';
          NEW.point := centroid;
        END IF;
      END IF; 
        
      -- Only process if there is a point value
      IF (NEW.point IS NOT NULL) THEN
	
	FOR boundary IN SELECT * FROM boundary LOOP
		--RAISE NOTICE 'Add % boundary features ...', quote_ident(boundary.spatial_table);
		FOR feature IN EXECUTE 'SELECT * FROM ' || quote_ident(boundary.spatial_table)  || ' WHERE ST_Intersects(ST_PointFromText(''' ||
			ST_AsText(NEW.point) || ''', 4326), polygon)' LOOP
		  -- For each boundary locate intersecting features and record them in the location_boundary table
		  EXECUTE 'INSERT INTO location_boundary VALUES (' || NEW.location_id || ', ' || feature.boundary_id || ', ' || feature.feature_id || ')';
		  -- Assign all associated taxonomy classification from intersected features to new location
		  FOR ft IN (SELECT * FROM feature_taxonomy WHERE feature_id = feature.feature_id) LOOP
		    -- Replace all previous taxonomy associates with new
		    DELETE FROM location_taxonomy WHERE location_id = NEW.location_id AND classification_id IN (SELECT classification_id FROM taxonomy_classifications WHERE taxonomy_id = (SELECT taxonomy_id FROM classification WHERE classification_id = ft.classification_id));    
		    INSERT INTO location_taxonomy VALUES (NEW.location_id, ft.classification_id, 'location_id');
		  END LOOP;
		END LOOP;
				
	END LOOP;
      END IF;
      
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
					    || coalesce(quote_literal(trim(substring(i from 1 for 255))),'NULL') || ', ' 
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
					SELECT INTO class_id classification_id::integer FROM taxonomy_classifications WHERE lower(iati_code) = lower(activity."participating-org_type"[idx]) AND iati_codelist = 'Organisation Type';
					IF class_id IS NOT NULL THEN				
					  -- Does the organization have this taxonomy assigned?
					  SELECT INTO record_id organization_taxonomy.organization_id::integer FROM organization_taxonomy WHERE organization_taxonomy.organization_id = o_id AND organization_taxonomy.classification_id = class_id;
					  IF record_id IS NULL THEN
					    -- add the taxonomy to the organization record
			                    EXECUTE 'INSERT INTO organization_taxonomy(organization_id, classification_id, field) VALUES( ' || o_id || ', ' || class_id || ', ''organization_id'');';
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
					  IF transact."value" IS NOT NULL AND pmt_isnumeric(replace(transact."value", ',', '')) THEN	
					     -- if there is a transaction-date element use it to populate date values
					     IF transact."transaction-date" IS NOT NULL AND transact."transaction-date" <> '' THEN
						-- Create a financial record 
						EXECUTE 'INSERT INTO financial (project_id, activity_id, amount, start_date, created_by, created_date, updated_by, updated_date) VALUES( ' 
						|| p_id || ', ' || a_id || ', ' || ROUND(CAST(replace(transact."value", ',', '') as numeric), 2) || ', ' || coalesce(quote_literal(transact."transaction-date"),'NULL') || ', ' 
						|| quote_literal(E'IATI XML Import') || ', ' || quote_literal(current_date) || ', ' || quote_literal(E'IATI XML Import') || ', ' || quote_literal(current_date) 
						|| ') RETURNING financial_id;' INTO financial_id;
					     -- if there isnt a transaction-date element use value-date attribute from the value element to populate date values	
					     ELSE
						-- Create a financial record
						EXECUTE 'INSERT INTO financial (project_id, activity_id, amount, start_date, created_by, created_date, updated_by, updated_date) VALUES( ' 
						|| p_id || ', ' || a_id || ', ' || ROUND(CAST(replace(transact."value", ',', '') as numeric), 2) || ', ' || coalesce(quote_literal(transact."value-date"),'NULL') || ', ' 
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
					    IF budget."value" IS NOT NULL AND pmt_isnumeric(replace(budget."value", ',', '')) THEN 
						-- if there is a period-start element use it to populate date values
						IF budget."period-start" IS NOT NULL AND budget."period-start" <> '' THEN
						   -- Create a financial record with start and end dates
						   EXECUTE 'INSERT INTO financial (project_id, activity_id, amount, start_date, end_date, created_by, created_date, updated_by, updated_date) VALUES( ' 
						   || p_id || ', ' || a_id || ', ' || ROUND(CAST(replace(budget."value", ',', '') as numeric), 2)  || ', ' || coalesce(quote_literal(budget."period-start"),'NULL') || ', ' 
						   || coalesce(quote_literal(budget."period-end"),'NULL') || ', ' 
						   || quote_literal(E'IATI XML Import') || ', ' || quote_literal(current_date) || ', ' || quote_literal(E'IATI XML Import') || ', ' || quote_literal(current_date) 
						   || ') RETURNING financial_id;' INTO financial_id;
						-- if there isnt a period-start element use value-date attribute from the value element to populate date values	
						ELSE
						   -- Create a financial record with start date
						   EXECUTE 'INSERT INTO financial (project_id, activity_id, amount, start_date, created_by, created_date, updated_by, updated_date) VALUES( ' 
						   || p_id || ', ' || a_id || ', ' || ROUND(CAST(replace(budget."value", ',', '') as numeric), 2) || ', ' || coalesce(quote_literal(budget."value-date"),'NULL') || ', '  
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
 					       RAISE NOTICE '      - Value:  %', ROUND(CAST(replace(budget."value", ',', '') as numeric), 2);
 					       RAISE NOTICE '         - Currency:  %', budget."value-currency";
 					       RAISE NOTICE '      - Start Date:  %', budget."period-start";
 					       RAISE NOTICE '      - End Date:  %', budget."period-end";
					    ELSE
 					       RAISE NOTICE 'Budget value is null or invalid. Record will not be written.';
					    END IF; 				    				    
					END LOOP;
				    END LOOP;

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
/*****************************************************************
Functions -- is procedural code that is executed when called.
	See documentation.
******************************************************************/
CREATE TYPE pmt_activities_by_tax_result_type AS (a_id integer, title character varying, c_ids text);
CREATE TYPE pmt_data_groups_result_type AS (c_id integer, name text);
CREATE TYPE pmt_json_result_type AS (response json);
CREATE TYPE pmt_filter_locations_result AS (l_id integer, r_ids text);
CREATE TYPE pmt_filter_projects_result AS (p_id integer, a_ids text);  
CREATE TYPE pmt_filter_orgs_result AS (l_id integer, r_ids text); 
CREATE TYPE pmt_locations_by_org_result_type AS (l_id integer, x integer, y integer, r_ids text);
CREATE TYPE pmt_locations_by_tax_dd_result_type AS  (l_id integer, x integer, y integer, lat numeric, lng numeric, r_ids text);
CREATE TYPE pmt_locations_by_tax_result_type AS (l_id integer, x integer, y integer, r_ids text);
CREATE TYPE pmt_version_result_type AS (version text, last_update date, created date);

/******************************************************************
  pmt_activity_details
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_activity_details(a_id integer) RETURNS SETOF pmt_json_result_type AS $$
DECLARE
  valid_activity_id integer;
  rec record;
BEGIN  

  IF ( $1 IS NULL ) THEN
     FOR rec IN (SELECT row_to_json(j) FROM(select null as message) j) LOOP  RETURN NEXT rec; END LOOP;
  ELSE
    -- Is activity_id active and valid?
    SELECT INTO valid_activity_id activity_id FROM activity WHERE activity_id = $1 and active = true;

    IF valid_activity_id IS NOT NULL THEN
      FOR rec IN (
	    SELECT row_to_json(j)
	    FROM
	    (			
				SELECT a.activity_id AS a_id, coalesce(a.label, a.title) AS title, a.description AS desc,a.start_date, a.end_date, a.tags
		, f.amount
		-- taxonomy
		,(
			SELECT array_to_json(array_agg(row_to_json(t))) FROM (
				SELECT DISTINCT tc.taxonomy, tc.classification,
				(select name from organization where organization_id = ol.organization_id and tc.taxonomy = 'Organisation Role') as org
				FROM organization_lookup ol
				JOIN taxonomy_classifications  tc
				ON tc.classification_id = ANY(ARRAY[ol.classification_ids])		
				WHERE ol.activity_id = a.activity_id
				ORDER BY taxonomy
				) t
		) as taxonomy				
		-- locations
		,(
			SELECT array_to_json(array_agg(row_to_json(l))) FROM (
				SELECT DISTINCT ll.location_id, gaul0_name, gaul1_name, gaul2_name, l.lat_dd as lat, l.long_dd as long
				FROM location_lookup ll
				LEFT JOIN location l
				ON ll.location_id = l.location_id
				WHERE ll.activity_id = a.activity_id
				) l 
		) as locations		
		FROM activity a
		-- financials
		LEFT JOIN
		(SELECT activity_id, sum(amount) as amount FROM financial WHERE activity_id = $1 GROUP BY activity_id ) as f
		ON f.activity_id = a.activity_id					
		WHERE a.active = true and a.activity_id = $1
	     ) j
	    ) LOOP		
	      RETURN NEXT rec;
	    END LOOP;	
    ELSE
      FOR rec IN (SELECT row_to_json(j) FROM(select 'activity_id is not valid or active.' as message) j) LOOP  RETURN NEXT rec; END LOOP;
    END IF;           
  END IF;		
END;$$ LANGUAGE plpgsql;
/******************************************************************
  pmt_activity_listview
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_activity_listview(classification_ids character varying, organization_ids character varying, unassigned_tax_ids character varying, 
start_date date, end_date date, report_taxonomy_ids character varying, orderby text, limit_rec integer, offset_rec integer) RETURNS SETOF pmt_json_result_type AS $$
DECLARE  
  filter_classids integer array;
  filter_orgids integer array;
  include_taxids integer array;  
  reporting_taxids integer array;
  rec record;  
  dynamic_where1 text array;
  dynamic_where2 text;
  dynamic_join text;
  dynamic_select text;
  join_ct integer;
  built_where text array; 
  execute_statement text;
  count_statement text;
  paging_statement text;
  record_count integer;
  i integer;
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
   
    -- filter by organization ids
    IF ($2 is not null AND $2 <> '') THEN
      RAISE NOTICE '   + The organization filter is: %.', string_to_array($2, ',')::int[];

      -- Create an int array from organization ids list
	filter_orgids := string_to_array($2, ',')::int[];

      -- Loop through the organization_ids and construct the where statement
	built_where := null;
	FOREACH i IN ARRAY filter_orgids LOOP
		built_where :=  array_append(built_where, 't1.organization_id = '|| i );
	END LOOP;
	-- Add the complied org statements to the where
	dynamic_where1 := array_append(dynamic_where1, '(' || array_to_string(built_where, ' OR ') || ')');
	
   END IF;

    -- include values with unassigned taxonomy(ies)
    IF ($3 is not null AND $3 <> '') THEN
      RAISE NOTICE '   + The include unassigned is: %.', string_to_array($3, ',')::int[];

      -- Create an int array from unassigned ids list
      include_taxids := string_to_array($3, ',')::int[];				

      -- Loop through the organization_ids and construct the where statement
      built_where := null;
      FOREACH i IN ARRAY include_taxids LOOP
	built_where :=  array_append(built_where, 'not (taxonomy_ids @> ARRAY['|| i ||'])');
      END LOOP;			
      -- Add the complied org statements to the where
      dynamic_where2 := '(' || array_to_string(built_where, ' OR ') || ')';
	
    END IF;
    
    -- filter by date range
    IF ($4 is not null AND $5 is not null) THEN
	dynamic_where1 := array_append(dynamic_where1, '(t1.start_date > ''' || $4 || ''' AND t1.end_date < ''' || $5 || ''')');
    END IF;	

    -- -- report by taxonomy(ies)
    IF $6 IS NOT NULL AND $6 <> '' THEN      
      -- validate taxonomy ids
      SELECT INTO reporting_taxids * FROM pmt_validate_taxonomies($6);

      join_ct := 1;

      IF reporting_taxids IS NOT NULL THEN
        -- Loop through the reporting taxonomy_ids and construct the join statements      
        FOREACH i IN ARRAY reporting_taxids LOOP
          -- prepare join statements
	  IF dynamic_join IS NOT NULL THEN
            dynamic_join := dynamic_join || ' LEFT JOIN (SELECT  ot.activity_id, array_to_string(array_agg(DISTINCT tc.classification), '','') as classes ' ||
					'FROM organization_lookup ot  JOIN taxonomy_classifications tc ON tc.classification_id = ANY(ot.classification_ids) ' ||
					'WHERE taxonomy_id = ' || i || ' GROUP BY ot.activity_id ) tax' || join_ct || ' ON tax' || join_ct || '.activity_id = filter.activity_id';
          ELSE
            dynamic_join := ' LEFT JOIN (SELECT  ot.activity_id, array_to_string(array_agg(DISTINCT tc.classification), '','') as classes ' ||
					'FROM organization_lookup ot  JOIN taxonomy_classifications tc ON tc.classification_id = ANY(ot.classification_ids) ' ||
					'WHERE taxonomy_id = ' || i || ' GROUP BY ot.activity_id ) tax' || join_ct || ' ON tax' || join_ct || '.activity_id = filter.activity_id';
          END IF;
          -- prepare select statements
          IF dynamic_select IS NOT NULL THEN
            dynamic_select := dynamic_select || ', tax' || join_ct || '.classes as tax' || join_ct || ' ';
          ELSE
            dynamic_select := ', tax' || join_ct || '.classes as tax' || join_ct || ' ';
          END IF;
          join_ct := join_ct + 1;
        END LOOP;			
      END IF;
    END IF;
    
    -- create dynamic paging statment
    IF $7 IS NOT NULL AND $7 <> '' THEN      
      IF paging_statement IS NOT NULL THEN
        paging_statement := paging_statement || 'ORDER BY ' || $7 || ' ';
      ELSE
        paging_statement := ' ORDER BY ' || $7 || ' ';
      END IF;
    END IF;		    
    IF $8 IS NOT NULL AND $8 > 0 THEN
      IF paging_statement IS NOT NULL THEN
        paging_statement := paging_statement || 'LIMIT ' || $8 || ' ';
      ELSE
        paging_statement := ' LIMIT ' || $8 || ' ';
      END IF;
    END IF;		
    IF $9 IS NOT NULL AND $9 > 0 THEN
      IF paging_statement IS NOT NULL THEN
        paging_statement := paging_statement || 'OFFSET ' || $9 || ' ';
      ELSE
        paging_statement := ' OFFSET ' || $9 || ' ';
      END IF;      
    END IF;		

    -- prepare statement																
    RAISE NOTICE '   + First where statement: %', array_to_string(dynamic_where1, ' AND ');
    RAISE NOTICE '   + Second where statement: %', dynamic_where2;
    RAISE NOTICE '   + The join statement: %', dynamic_join;
    RAISE NOTICE '   + The select statement: %', dynamic_select;
    RAISE NOTICE '   + The paging statement: %', paging_statement;
		
    -- prepare statement for the selection
    execute_statement := 'SELECT filter.activity_id AS a_id, filter.title AS a_name, f_orgs.orgs as f_orgs, i_orgs.orgs as i_orgs ';

    IF dynamic_select IS NOT NULL THEN
      execute_statement := execute_statement || dynamic_select;
    END IF;

    execute_statement := execute_statement ||			
			-- filter
			'FROM ( SELECT DISTINCT t1.activity_id, a.title FROM  ' ||			
			'(SELECT * FROM organization_lookup ) as t1 ' ||
				-- activity
			'JOIN (SELECT activity_id, title from activity) as a ' ||
			'ON t1.activity_id = a.activity_id ';			
			
    -- append where statements			
    IF dynamic_where1 IS NOT NULL THEN          
      IF dynamic_where2 IS NOT NULL THEN
        execute_statement := execute_statement || ' WHERE ' ||  array_to_string(dynamic_where1, ' AND ')  || ' OR ' || dynamic_where2;
      ELSE
        execute_statement := execute_statement || ' WHERE ' ||  array_to_string(dynamic_where1, ' AND ') || ' ';
      END IF;
    ELSE 
      IF dynamic_where2 IS NOT NULL THEN
        execute_statement := execute_statement || ' WHERE ' || dynamic_where2 || ' ';                       
      END IF;
    END IF;		

    execute_statement := execute_statement || ') as filter ' ||
			-- organiztions (funding)
			'LEFT JOIN (SELECT ot.activity_id, array_to_string(array_agg(DISTINCT o.name), '','') as orgs ' ||
			'FROM organization_lookup ot JOIN taxonomy_classifications tc ON tc.classification_id = ANY(ot.classification_ids) ' ||
			'JOIN organization o ON ot.organization_id = o.organization_id WHERE iati_codelist = ''Organisation Role'' AND iati_name = ''Funding'' ' ||
			'GROUP BY ot.activity_id ) f_orgs ON f_orgs.activity_id = filter.activity_id ' ||
			-- organiztions (implementing); 	
			'LEFT JOIN (SELECT ot.activity_id, array_to_string(array_agg(DISTINCT o.name), '','') as orgs ' ||
			'FROM organization_lookup ot JOIN taxonomy_classifications tc ON tc.classification_id = ANY(ot.classification_ids) ' ||
			'JOIN organization o ON ot.organization_id = o.organization_id WHERE iati_codelist = ''Organisation Role'' AND iati_name = ''Implementing'' '||
			'GROUP BY ot.activity_id) i_orgs ON i_orgs.activity_id = filter.activity_id ';
    		
     IF dynamic_join IS NOT NULL THEN
      execute_statement := execute_statement || dynamic_join;
    END IF;
    
    -- if there is a paging request then add it
    IF paging_statement IS NOT NULL THEN 
      execute_statement := execute_statement || ' ' || paging_statement;
    END IF;
    
    -- execute statement		
    RAISE NOTICE 'execute: %', 'SELECT row_to_json(j) FROM (' || execute_statement || ')j';	   
     
    FOR rec IN EXECUTE 'SELECT row_to_json(j) FROM (' || execute_statement || ')j' LOOP     
	RETURN NEXT rec;
    END LOOP;	

END;$$ LANGUAGE plpgsql;
/******************************************************************
  pmt_activity_listview_ct
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_activity_listview_ct(classification_ids character varying, organization_ids character varying, unassigned_tax_ids character varying, start_date date, end_date date)
RETURNS INT AS 
$$
DECLARE
  valid_taxonomy_id boolean;
  report_by_category boolean; 
  report_taxonomy_id integer;
  filter_classids integer array;
  filter_orgids integer array;
  include_taxids integer array;  
  rec record;  
  dynamic_where1 text array;
  dynamic_where2 text;
  built_where text array; 
  execute_statement text;
  count_statement text;
  paging_statement text;
  record_count integer;
  i integer;
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
   
    -- filter by organization ids
    IF ($2 is not null AND $2 <> '') THEN
      RAISE NOTICE '   + The organization filter is: %.', string_to_array($2, ',')::int[];

      -- Create an int array from organization ids list
	filter_orgids := string_to_array($2, ',')::int[];

      -- Loop through the organization_ids and construct the where statement
	built_where := null;
	FOREACH i IN ARRAY filter_orgids LOOP
		built_where :=  array_append(built_where, 'organization_ids @> ARRAY['|| i ||']');
	END LOOP;
	-- Add the complied org statements to the where
	dynamic_where1 := array_append(dynamic_where1, '(' || array_to_string(built_where, ' OR ') || ')');
	
   END IF;

    -- include values with unassigned taxonomy(ies)
    IF ($3 is not null AND $3 <> '') THEN
      RAISE NOTICE '   + The include unassigned is: %.', string_to_array($3, ',')::int[];

      -- Create an int array from unassigned ids list
      include_taxids := string_to_array($3, ',')::int[];				

      -- Loop through the organization_ids and construct the where statement
      built_where := null;
      FOREACH i IN ARRAY include_taxids LOOP
	built_where :=  array_append(built_where, 'not (taxonomy_ids @> ARRAY['|| i ||'])');
      END LOOP;			
      -- Add the complied org statements to the where
      dynamic_where2 := '(' || array_to_string(built_where, ' OR ') || ')';
	
    END IF;

     -- filter by date range
    IF ($4 is not null AND $5 is not null) THEN
	dynamic_where1 := array_append(dynamic_where1, '(start_date > ''' || $4 || ''' AND end_date < ''' || $5 || ''')');
    END IF;
    
    -- prepare statement																
    RAISE NOTICE '   + First where statement: %', array_to_string(dynamic_where1, ' AND ');
    RAISE NOTICE '   + Second where statement: %', dynamic_where2;

    -- prepare the statement for the record count (can be leaner for faster exectution)
    count_statement := 'SELECT COUNT(DISTINCT a_id) FROM(SELECT DISTINCT filter.activity_id AS a_id, filter.organization_id as o_id ' ||
			'FROM (SELECT t1.activity_id, t1.organization_id FROM ' ||
			'(SELECT activity_id, organization_id, start_date, end_date, array_agg(distinct taxonomy_id) as taxonomy_ids, array_agg(distinct classification_id) as classification_ids, array_agg(distinct organization_id) as organization_ids ' ||
			'FROM taxonomy_lookup GROUP BY activity_id, organization_id, start_date, end_date ) as t1 ';			
   
    -- append where statements			
    IF dynamic_where1 IS NOT NULL THEN          
      IF dynamic_where2 IS NOT NULL THEN
        count_statement := count_statement || ' WHERE ' ||  array_to_string(dynamic_where1, ' AND ')  || ' OR ' || dynamic_where2;
      ELSE
        count_statement := count_statement || ' WHERE ' ||  array_to_string(dynamic_where1, ' AND ') || ' ';
      END IF;
    ELSE 
      IF dynamic_where2 IS NOT NULL THEN
        count_statement := count_statement || ' WHERE ' || dynamic_where2 || ' ';
      END IF;
    END IF;	

    count_statement := count_statement || ') as filter ) as count';	 
    
    -- get total record count
    EXECUTE count_statement INTO record_count;

    RETURN record_count;

END;$$ LANGUAGE plpgsql;
/******************************************************************
  pmt_auto_complete
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_auto_complete(project_fields character varying, activity_fields character varying) RETURNS SETOF pmt_json_result_type AS $$
DECLARE
  execute_statement text;
  requested_project_cols text[];
  valid_project_cols text[];
  requested_activity_cols text[];
  valid_activity_cols text[];
  col text;
  rec record;
BEGIN
  IF ( $1 IS NULL OR $1 = '') AND ( $2 IS NULL OR $2 = '')  THEN
   --  no parameters, return nothing
  ELSE
    -- validate parameters	
    IF ($1 IS NOT NULL AND $1 <> '') THEN
      -- parse input to array
      requested_project_cols := string_to_array(replace($1, ' ', ''), ',');      
      RAISE NOTICE 'Requested columns: %', requested_project_cols;
      -- validate column names
      SELECT INTO valid_project_cols array_agg(column_name::text) FROM information_schema.columns WHERE table_name='project' and column_name = ANY(requested_project_cols);
      RAISE NOTICE 'Valid columns: %', valid_project_cols;    
    END IF;
    IF ($2 IS NOT NULL AND $2 <> '') THEN
      -- parse input to array
      requested_activity_cols := string_to_array(replace($2, ' ', ''), ',');      
      RAISE NOTICE 'Requested columns: %', requested_activity_cols;
      -- validate column names
      SELECT INTO valid_activity_cols array_agg(column_name::text) FROM information_schema.columns WHERE table_name='activity' and column_name = ANY(requested_activity_cols);
      RAISE NOTICE 'Valid columns: %', valid_activity_cols;    
    END IF;

    IF valid_project_cols IS NOT NULL THEN
    FOREACH col IN ARRAY valid_project_cols LOOP
      IF execute_statement IS NULL THEN
        IF col = 'tags'::text THEN
          execute_statement := 'SELECT array_agg(DISTINCT trim(both substring(val, 0, 100))) as autocomplete FROM (SELECT DISTINCT regexp_split_to_table(' || col || ', E''\\,'')::text as val FROM project WHERE active = true ';
        ELSE
          execute_statement := 'SELECT array_agg(DISTINCT trim(both substring(val, 0, 100))) as autocomplete FROM (SELECT DISTINCT regexp_split_to_table(' || col || ', E''\\,'')::text as val FROM project WHERE active = true ';
        END IF;        
      ELSE
        IF col = 'tags'::text THEN
          execute_statement := execute_statement || ' UNION ALL SELECT DISTINCT regexp_split_to_table(' || col || ', E''\\,'')::text as val  FROM project WHERE active = true  ';
        ELSE
          execute_statement := execute_statement || ' UNION ALL SELECT DISTINCT regexp_split_to_table(' || col || ', E''\\,'')::text as val  FROM project WHERE active = true  ';
        END IF;        
      END IF;      
    END LOOP;
    END IF;
    IF valid_activity_cols IS NOT NULL THEN
    FOREACH col IN ARRAY valid_activity_cols LOOP
      IF execute_statement IS NULL THEN
        IF col = 'tags'::text THEN
          execute_statement := 'SELECT array_agg(DISTINCT trim(val)) as autocomplete FROM (SELECT  DISTINCT regexp_split_to_table(' || col || ', E''\\,'')::text as val  FROM activity WHERE active = true ';
        ELSE
          execute_statement := 'SELECT array_agg(DISTINCT trim(val)) as autocomplete FROM (SELECT  DISTINCT regexp_split_to_table(' || col || ', E''\\,'')::text as val  FROM activity WHERE active = true ';
        END IF;        
      ELSE
        IF col = 'tags'::text THEN
          execute_statement := execute_statement || ' UNION ALL SELECT DISTINCT regexp_split_to_table(' || col || ', E''\\,'')::text as val  FROM activity WHERE active = true ';
        ELSE
          execute_statement := execute_statement || ' UNION ALL SELECT DISTINCT regexp_split_to_table(' || col || ', E''\\,'')::text as val  FROM activity WHERE active = true ';
        END IF;        
      END IF;       
    END LOOP;
    END IF;
    RAISE NOTICE 'Execute statement: %', execute_statement;
    IF execute_statement IS NOT NULL THEN
      FOR rec IN EXECUTE 'SELECT row_to_json(j) FROM (' || execute_statement || ')ac WHERE val IS NOT NULL AND val <> '''')j' LOOP     
	RETURN NEXT rec;
      END LOOP;
    END IF;
             
  END IF; -- empty parameters		
END;$$ LANGUAGE plpgsql;
/******************************************************************
  pmt_project_listview
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_project_listview(tax_id integer, classification_ids character varying, organization_ids character varying, unassigned_tax_ids character varying, 
start_date date, end_date date, orderby text, limit_rec integer, offset_rec integer) RETURNS SETOF pmt_json_result_type AS $$
DECLARE
  valid_taxonomy_id boolean;
  report_by_category boolean; 
  report_taxonomy_id integer;
  filter_classids integer array;
  filter_orgids integer array;
  include_taxids integer array;  
  rec record;  
  dynamic_where1 text array;
  dynamic_where2 text;
  built_where text array; 
  execute_statement text;
  count_statement text;
  paging_statement text;
  record_count integer;
  i integer;
BEGIN

-- validate and process taxonomy_id parameter
SELECT INTO valid_taxonomy_id * FROM pmt_validate_taxonomy($1); 

-- Must have valid taxonomy_id parameter to continue
IF NOT valid_taxonomy_id THEN
  RAISE NOTICE '   + A taxonomy is required.';
-- Has a valid taxonomy_id parameter 
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
		dynamic_where1 := array_append(dynamic_where1, '(' || array_to_string(built_where, ' OR ') || ')');
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
	dynamic_where1 := array_append(dynamic_where1, '(' || array_to_string(built_where, ' OR ') || ')');
	
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
      dynamic_where2 := '(' || array_to_string(built_where, ' OR ') || ')';
	
    END IF;

    -- filter by date range
    IF ($5 is not null AND $6 is not null) THEN
	dynamic_where1 := array_append(dynamic_where1, '(filter.start_date > ''' || $5 || ''' AND filter.end_date < ''' || $6 || ''')');
    END IF;	
	   
    -- create dynamic paging statment
    IF $7 IS NOT NULL AND $7 <> '' THEN
      IF paging_statement IS NOT NULL THEN
        paging_statement := paging_statement || 'ORDER BY ' || $5 || ' ';
      ELSE
        paging_statement := ' ORDER BY ' || $7 || ' ';
      END IF;
    END IF;		    
    IF $8 IS NOT NULL AND $8 > 0 THEN
      IF paging_statement IS NOT NULL THEN
        paging_statement := paging_statement || 'LIMIT ' || $8 || ' ';
      ELSE
        paging_statement := ' LIMIT ' || $8 || ' ';
      END IF;
    END IF;		
    IF $9 IS NOT NULL AND $9 > 0 THEN
      IF paging_statement IS NOT NULL THEN
        paging_statement := paging_statement || 'OFFSET ' || $9 || ' ';
      ELSE
        paging_statement := ' OFFSET ' || $9 || ' ';
      END IF;      
    END IF;	

    -- prepare statement				
    RAISE NOTICE '   + The reporting taxonomy is: %', $1;
    RAISE NOTICE '   + The base taxonomy is: % ', report_taxonomy_id;												
    RAISE NOTICE '   + First where statement: %', array_to_string(dynamic_where1, ' AND ');
    RAISE NOTICE '   + Second where statement: %', dynamic_where2;
    RAISE NOTICE '   + The paging statement: %', paging_statement;

     -- prepare statement for the selection
    execute_statement := 'select distinct  p.project_id AS p_id ,p.title ,p.activity_ids AS a_ids ,pa.orgs AS org ,pf.funding_orgs AS f_orgs ,i.c_name ' ||
			 'from ' ||
			 -- project/activity
			 '(select p.project_id, p.title, p.opportunity_id, array_agg(filter.activity_id) as activity_ids from project p ' ||
			 -- filter
			 'join (SELECT project_id, start_date, end_date, activity_id, array_agg(distinct taxonomy_id) as taxonomy_ids, array_agg(distinct classification_id) as classification_ids ' ||
			 ',array_agg(distinct organization_id) as organization_ids FROM taxonomy_lookup GROUP BY project_id, start_date, end_date, activity_id) as filter on p.project_id = filter.project_id ';

    -- append where statements			
    IF dynamic_where1 IS NOT NULL THEN          
      IF dynamic_where2 IS NOT NULL THEN
        execute_statement := execute_statement || ' WHERE ' ||  array_to_string(dynamic_where1, ' AND ')  || ' OR ' || dynamic_where2;
      ELSE
        execute_statement := execute_statement || ' WHERE ' ||  array_to_string(dynamic_where1, ' AND ') || ' ';
      END IF;
    ELSE 
      IF dynamic_where2 IS NOT NULL THEN
        execute_statement := execute_statement || ' WHERE ' || dynamic_where2 || ' ';                       
      END IF;
    END IF;				 

    execute_statement := execute_statement || '  GROUP BY p.project_id, p.title, p.opportunity_id ) p left join ' ||
			-- participants (Accountable)
			'(select pp.project_id, array_to_string(array_agg(distinct o.name), '','') as orgs from participation pp join organization o on pp.organization_id = o.organization_id ' ||
			'left join participation_taxonomy ppt on pp.participation_id = ppt.participation_id join classification c on ppt.classification_id = c.classification_id ' ||
			'where c.taxonomy_id = (select taxonomy_id from taxonomy where name = ''Organisation Role'') AND c.name = ''Accountable'' group by pp.project_id) pa on p.project_id = pa.project_id left join ' ||
			-- participants (Funding)
			'(select pp.project_id, array_to_string(array_agg(distinct o.name), '','') as funding_orgs from participation pp join organization o on pp.organization_id = o.organization_id ' ||
			'left join participation_taxonomy ppt on pp.participation_id = ppt.participation_id join classification c on ppt.classification_id = c.classification_id ' ||
			'where c.taxonomy_id = (select taxonomy_id from taxonomy where name = ''Organisation Role'') AND (c.name = ''Funding'') group by pp.project_id) pf on p.project_id = pf.project_id left join ' ||
			-- project taxonomy
			'(select pt.project_id, array_to_string(array_agg(distinct c.name), '','') as  c_name from project_taxonomy pt join classification c on pt.classification_id = c.classification_id ' ||
			'where c.taxonomy_id = ' || $1 || ' group by pt.project_id) as i on p.project_id = i.project_id	';

    -- if there is a paging request then add it
    IF paging_statement IS NOT NULL THEN 
      execute_statement := execute_statement || ' ' || paging_statement;
    END IF;
    
    -- execute statement		
    RAISE NOTICE 'execute: %', 'SELECT row_to_json(j) FROM (' || execute_statement || ')j';	        
		
    FOR rec IN EXECUTE 'SELECT row_to_json(j) FROM (' || execute_statement || ')j' LOOP     
	RETURN NEXT rec;
    END LOOP;
    
END IF; -- Must have valid taxonomy_id parameter to continue			
END;$$ LANGUAGE plpgsql;
/******************************************************************
  pmt_project_listview_ct
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_project_listview_ct(classification_ids character varying, organization_ids character varying, unassigned_tax_ids character varying, start_date date, end_date date)
RETURNS INT AS 
$$
DECLARE
  valid_taxonomy_id boolean;
  report_by_category boolean; 
  report_taxonomy_id integer;
  filter_classids integer array;
  filter_orgids integer array;
  include_taxids integer array;  
  rec record;  
  dynamic_where1 text array;
  dynamic_where2 text;
  built_where text array; 
  execute_statement text;
  count_statement text;
  paging_statement text;
  record_count integer;
  i integer;
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
   
    -- filter by organization ids
    IF ($2 is not null AND $2 <> '') THEN
      RAISE NOTICE '   + The organization filter is: %.', string_to_array($2, ',')::int[];

      -- Create an int array from organization ids list
	filter_orgids := string_to_array($2, ',')::int[];

      -- Loop through the organization_ids and construct the where statement
	built_where := null;
	FOREACH i IN ARRAY filter_orgids LOOP
		built_where :=  array_append(built_where, 'organization_ids @> ARRAY['|| i ||']');
	END LOOP;
	-- Add the complied org statements to the where
	dynamic_where1 := array_append(dynamic_where1, '(' || array_to_string(built_where, ' OR ') || ')');
	
   END IF;

    -- include values with unassigned taxonomy(ies)
    IF ($3 is not null AND $3 <> '') THEN
      RAISE NOTICE '   + The include unassigned is: %.', string_to_array($3, ',')::int[];

      -- Create an int array from unassigned ids list
      include_taxids := string_to_array($3, ',')::int[];				

      -- Loop through the organization_ids and construct the where statement
      built_where := null;
      FOREACH i IN ARRAY include_taxids LOOP
	built_where :=  array_append(built_where, 'not (taxonomy_ids @> ARRAY['|| i ||'])');
      END LOOP;			
      -- Add the complied org statements to the where
      dynamic_where2 := '(' || array_to_string(built_where, ' OR ') || ')';
	
    END IF;

    -- filter by date range
    IF ($4 is not null AND $5 is not null) THEN
	dynamic_where1 := array_append(dynamic_where1, '(start_date > ''' || $4 || ''' AND end_date < ''' || $5 || ''')');
    END IF;
   
    -- prepare statement																
    RAISE NOTICE '   + First where statement: %', array_to_string(dynamic_where1, ' AND ');
    RAISE NOTICE '   + Second where statement: %', dynamic_where2;

    -- prepare the statement for the record count (can be leaner for faster exectution)
    count_statement := 'SELECT COUNT(distinct p_id) FROM(SELECT DISTINCT filter.project_id AS p_id, filter.organization_id as o_id ' ||
			'FROM (SELECT t1.project_id, t1.organization_id FROM ' ||
			'(SELECT project_id, organization_id, start_date, end_date, array_agg(distinct taxonomy_id) as taxonomy_ids, array_agg(distinct classification_id) as classification_ids, array_agg(distinct organization_id) as organization_ids ' ||
			'FROM taxonomy_lookup GROUP BY project_id, organization_id, start_date, end_date ) as t1 ';			
   
    -- append where statements			
    IF dynamic_where1 IS NOT NULL THEN          
      IF dynamic_where2 IS NOT NULL THEN
        count_statement := count_statement || ' WHERE ' ||  array_to_string(dynamic_where1, ' AND ')  || ' OR ' || dynamic_where2;
      ELSE
        count_statement := count_statement || ' WHERE ' ||  array_to_string(dynamic_where1, ' AND ') || ' ';
      END IF;
    ELSE 
      IF dynamic_where2 IS NOT NULL THEN
        count_statement := count_statement || ' WHERE ' || dynamic_where2 || ' ';
      END IF;
    END IF;	

    count_statement := count_statement || ') as filter ) as count';	 
    
    -- get total record count
    EXECUTE count_statement INTO record_count;

    RETURN record_count;

END;$$ LANGUAGE plpgsql;
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
/******************************************************************
   pmt_version
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_version() RETURNS SETOF pmt_version_result_type AS 
$$
DECLARE
  rec record;
BEGIN	
  FOR rec IN (  SELECT version::text||'.'||iteration::text||'.'||changeset::text AS pmt_version, updated_date::date as last_update, (SELECT created_date from config where config_id = (select min(config_id) from config))::date as created
		FROM version ORDER BY version, iteration, changeset DESC LIMIT 1 
		) LOOP		
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
  valid_classification_id boolean;
  report_by_category boolean; 
  report_taxonomy_id integer;
  built_where text array;
  dynamic_where1 text;
  dynamic_where2 text array;  
  execute_statement text;
  i integer;
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
    END IF;	
  END IF;

    -- validate and process country_ids parameter
  IF $3 IS NOT NULL OR $3 <> '' THEN
    SELECT INTO valid_classification_ids * FROM pmt_validate_classifications($3);
    RAISE NOTICE 'valid classification ids: %', valid_classification_ids;
  END IF;
    
  -- validate and process data_group parameter
  IF $2 IS NOT NULL THEN
    -- validate the classification id
    SELECT INTO valid_classification_id * FROM pmt_validate_classification($2);

    IF valid_classification_id THEN
      IF valid_classification_ids IS NOT NULL THEN
        valid_classification_ids := array_append(valid_classification_ids, $2);
      ELSE
        valid_classification_ids := array[$2];
      END IF;
    END IF;
  END IF;

  IF valid_classification_ids IS NOT NULL THEN
  -- Loop through each taxonomy classification group to contruct the where statement 
  FOR rec IN( SELECT tc.taxonomy_id, array_agg(tc.classification_id) AS filter_array 
  FROM taxonomy_classifications tc WHERE classification_id = ANY(valid_classification_ids) GROUP BY tc.taxonomy_id
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
  
  -- prepare statement
  execute_statement := 'SELECT t2.location_id as l_id, t2.x, t2.y, array_to_string(array_agg(DISTINCT report_by.classification_id), '','') as c_ids ' ||
				'FROM( ' ||
				'SELECT DISTINCT location_id, x, y, georef, classification_ids FROM location_lookup ';
				
  IF dynamic_where2 IS NOT NULL THEN          
    execute_statement := execute_statement || ' WHERE ' ||  array_to_string(dynamic_where2, ' AND ');
  END IF;

  IF report_taxonomy_id IS NULL THEN report_taxonomy_id := 1; END IF;
  
  execute_statement := execute_statement || ') as t2 ' ||
				'LEFT JOIN ' ||
				'(SELECT distinct location_id, classification_id FROM taxonomy_lookup  ' ||
				'WHERE taxonomy_lookup.taxonomy_id = ' || report_taxonomy_id || ') AS report_by  ' ||
				'ON t2.location_id = report_by.location_id ' ||
				'GROUP BY t2.location_id,t2.x, t2.y, t2.georef ' ||	
				'ORDER BY t2.georef ';  
  -- execute statement
  RAISE NOTICE 'Where statement: %', dynamic_where2;
  RAISE NOTICE 'Execute statement: %', execute_statement;
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
  pmt_locations_by_tax (overloaded method)
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_locations_by_tax(tax_id Integer, data_group character varying, country_ids character varying) RETURNS SETOF pmt_locations_by_tax_dd_result_type AS 
$$
DECLARE
  valid_data_group_ids int[];
  dg_id integer;
  valid_country_ids int[];
  valid_classification_ids int[];
  valid_taxonomy_id boolean;
  report_by_category boolean; 
  report_taxonomy_id integer;
  built_where text array;
  dynamic_where1 text;
  dynamic_where2 text array;  
  execute_statement text;
  i integer;
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
    END IF;	
  END IF;

    -- validate and process country_ids parameter
  IF $3 IS NOT NULL OR $3 <> '' THEN
    SELECT INTO valid_classification_ids * FROM pmt_validate_classifications($3);
    RAISE NOTICE 'valid classification ids: %', valid_classification_ids;
  END IF;
    
  -- validate and process data_group parameter
  IF $2 IS NOT NULL OR $2 <> '' THEN
    -- validate the classification id
    SELECT INTO valid_data_group_ids * FROM pmt_validate_classifications($2);

    IF valid_data_group_ids IS NOT NULL THEN
      IF valid_classification_ids IS NOT NULL THEN
        FOREACH dg_id IN ARRAY valid_data_group_ids LOOP
          valid_classification_ids := array_append(valid_classification_ids, dg_id);
        END LOOP;
      ELSE
        valid_classification_ids := valid_data_group_ids;
      END IF;
    END IF;
  END IF;

  IF valid_classification_ids IS NOT NULL THEN
  -- Loop through each taxonomy classification group to contruct the where statement 
  FOR rec IN( SELECT tc.taxonomy_id, array_agg(tc.classification_id) AS filter_array 
  FROM taxonomy_classifications tc WHERE classification_id = ANY(valid_classification_ids) GROUP BY tc.taxonomy_id
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
  
  -- prepare statement
  execute_statement := 'SELECT t2.location_id as l_id, t2.x, t2.y, t2.lat_dd, t2.long_dd, array_to_string(array_agg(DISTINCT report_by.classification_id), '','') as c_ids ' ||
				'FROM( ' ||
				'SELECT DISTINCT ll.location_id, ll.x, ll.y, l.lat_dd, l.long_dd, ll.georef, ll.classification_ids FROM location_lookup ll ' ||
				'JOIN location l ON ll.location_id = l.location_id ';
				
  IF dynamic_where2 IS NOT NULL THEN          
    execute_statement := execute_statement || ' WHERE ' ||  array_to_string(dynamic_where2, ' AND ');
  END IF;

  IF report_taxonomy_id IS NULL THEN report_taxonomy_id := 1; END IF;
  
  execute_statement := execute_statement || ') as t2 ' ||
				'LEFT JOIN ' ||
				'(SELECT distinct location_id, classification_id FROM taxonomy_lookup  ' ||
				'WHERE taxonomy_lookup.taxonomy_id = ' || report_taxonomy_id || ') AS report_by  ' ||
				'ON t2.location_id = report_by.location_id ' ||
				'GROUP BY t2.location_id, t2.x, t2.y, t2.lat_dd, t2.long_dd, t2.georef ' ||	
				'ORDER BY t2.georef ';  
  -- execute statement
  RAISE NOTICE 'Where statement: %', dynamic_where2;
  RAISE NOTICE 'Execute statement: %', execute_statement;
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
CREATE OR REPLACE FUNCTION pmt_locations_by_org(class_id Integer, data_group Integer, country_ids character varying)
RETURNS SETOF pmt_locations_by_org_result_type AS 
$$
DECLARE
  valid_classification_id boolean;
  valid_classification_ids int[];
  dynamic_where2 text array;
  dynamic_join text;
  built_where text array;
  i integer;
  execute_statement text;
  rec record;
BEGIN
  -- validate country_ids parameter
  IF $3 IS NOT NULL OR $3 <> '' THEN
    SELECT INTO valid_classification_ids * FROM pmt_validate_classifications($3);    
    RAISE NOTICE 'Valid classifications (country_ids): %', valid_classification_ids;
  END IF;
  
  -- validate and process classification_id parameter
  IF $1 IS NOT NULL THEN
    SELECT INTO valid_classification_id * FROM pmt_validate_classification($1);  
    RAISE NOTICE 'Valid classification id: %', valid_classification_id;  
    -- has valid classification id
    IF valid_classification_id THEN
      -- if the list of valid classification ids is not nulll add it
      IF valid_classification_ids IS NOT NULL THEN
        valid_classification_ids := array_append(valid_classification_ids, $1);
      -- if the list of valid classification ids is null, create it
      ELSE
        valid_classification_ids := array[$1];
      END IF;
    END IF;	
  END IF;

  -- validate and process data_group parameter
  IF $2 IS NOT NULL THEN
    SELECT INTO valid_classification_id * FROM pmt_validate_classification($2);    
    RAISE NOTICE 'Valid data group: %', valid_classification_id;  
    -- has valid classification id
    IF valid_classification_id THEN
      -- if the list of valid classification ids is not nulll add it
      IF valid_classification_ids IS NOT NULL THEN
        valid_classification_ids := array_append(valid_classification_ids, $2);
      -- if the list of valid classification ids is null, create it
      ELSE
        valid_classification_ids := array[$2];
      END IF;
    END IF;	   
  END IF;

  -- create dynamic where
  IF valid_classification_ids IS NOT NULL THEN
  -- Loop through each taxonomy classification group to contruct the where statement 
  FOR rec IN( SELECT tc.taxonomy_id, array_agg(tc.classification_id) AS filter_array 
  FROM taxonomy_classifications tc WHERE classification_id = ANY(valid_classification_ids) GROUP BY tc.taxonomy_id
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
  

  -- prepare statement
  execute_statement := 'SELECT ll.location_id, x, y, array_to_string(array_agg(ol.organization_id), '','') AS o_ids FROM location_lookup ll ' ||
		'JOIN (select distinct unnest(location_ids) as location_id, organization_id FROM organization_lookup';
				
  IF dynamic_where2 IS NOT NULL THEN          
    execute_statement := execute_statement || ' WHERE ' ||  array_to_string(dynamic_where2, ' AND ');
  END IF;

  execute_statement := execute_statement || ') as ol ON ll.location_id = ol.location_id GROUP BY ll.location_id, x, y, georef ORDER BY georef ';  
				   
  -- execute statement
  RAISE NOTICE 'Where statement: %', dynamic_where2;
  RAISE NOTICE 'Execute statement: %', execute_statement;
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
			
			FOR rec IN SELECT t2.location_id as l_id, array_to_string(array_agg(DISTINCT report_by.classification_id), ',') as cl_id
			FROM location_lookup AS t2
			LEFT JOIN
			(SELECT DISTINCT location_id, classification_id FROM taxonomy_lookup 
			WHERE taxonomy_id = report_taxonomy_id) AS report_by 
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

		   execute_statement := 'SELECT t2.location_id as l_id, array_to_string(array_agg(DISTINCT report_by.classification_id), '','') as cl_id ' ||
				'FROM( ' ||
				'SELECT location_id, georef, classification_ids FROM location_lookup ';
				
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
	  -- RAISE NOTICE '   + First where statement: %', array_to_string(dynamic_where1, ' AND ');
	  -- RAISE NOTICE '   + Second where statement: %', array_to_string(dynamic_where2, ' AND ');
	  -- RAISE NOTICE '   + Third where statement: %', dynamic_where3;
	  -- RAISE NOTICE '   + Forth where statement: %', dynamic_where4;

	  execute_statement := 'SELECT t2.project_id as p_id, array_to_string(array_agg(DISTINCT t2.activity_id), '','') as a_ids ' ||
			'FROM( ' ||
			'SELECT DISTINCT project_id, activity_id, location_id, georef, classification_ids ' ||
			'FROM location_lookup ';
			
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
CREATE OR REPLACE FUNCTION pmt_filter_orgs(classification_ids character varying, organization_ids character varying, unassigned_tax_ids character varying, 
start_date date, end_date date)
RETURNS SETOF pmt_filter_orgs_result AS 
$$
DECLARE
  rec record;
  filter_classids integer array;
  filter_orgids integer array;
  include_taxids integer array;
  dynamic_where1 text array;
  dynamic_where2 text;
  built_where text array;
  execute_statement text;
  i integer;
BEGIN
  -- filter by classification ids
  IF ($1 is not null AND $1 <> '') THEN
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
    dynamic_where1 := array_append(dynamic_where1, '(' || array_to_string(built_where, ' OR ') || ')');
  END IF;

  -- include values with unassigned taxonomy(ies)
  IF ($3 is not null AND $3 <> '') THEN
    -- Create an int array from unassigned ids list
    include_taxids := string_to_array($3, ',')::int[];				
    -- Loop through the organization_ids and construct the where statement
    built_where := null;
    FOREACH i IN ARRAY include_taxids LOOP
      built_where :=  array_append(built_where, 'not (taxonomy_ids @> ARRAY['|| i ||'])');
    END LOOP;			
    -- Add the complied org statements to the where
    dynamic_where2 := '(' || array_to_string(built_where, ' OR ') || ')';
  END IF;

  -- filter by date range
  IF ($4 is not null AND $5 is not null) THEN
    dynamic_where1 := array_append(dynamic_where1, '(start_date > ''' || $4 || ''' AND end_date < ''' || $5 || ''')');
  END IF;	

  RAISE NOTICE '   + Where1 statement: %', array_to_string(dynamic_where1, ' AND ');
  RAISE NOTICE '   + Where2 statement: %', dynamic_where2;
  
  -- prepare statement
  execute_statement := 'SELECT t1.location_id as l_id, array_to_string(t1.organization_ids, '','') as r_id  ' ||
			'FROM ( SELECT DISTINCT location_id, georef, start_date, end_date, array_agg(DISTINCT taxonomy_id) as taxonomy_ids, ' || 
			'array_agg(DISTINCT classification_id) as classification_ids, array_agg(DISTINCT organization_id) as organization_ids ' ||
			'FROM taxonomy_lookup GROUP BY location_id, georef, start_date, end_date ) AS t1  ';
			
  IF dynamic_where1 IS NOT NULL THEN          
    IF dynamic_where2 IS NOT NULL THEN
      execute_statement := execute_statement || ' WHERE ' ||  array_to_string(dynamic_where1, ' AND ')  || ' OR ' || dynamic_where2;
    ELSE
      execute_statement := execute_statement || ' WHERE ' ||  array_to_string(dynamic_where1, ' AND ') || ' ';
    END IF;
  ELSE 
    IF dynamic_where2 IS NOT NULL THEN
      execute_statement := execute_statement || ' WHERE ' || dynamic_where2 || ' ';                       
    END IF;
  END IF;

  execute_statement := execute_statement || 'ORDER BY t1.georef';

  -- execute statement		
  RAISE NOTICE 'Execute: %', execute_statement;		
  FOR rec IN EXECUTE execute_statement	LOOP
    RETURN NEXT rec;    
  END LOOP;	
		
END;$$ LANGUAGE plpgsql;
/******************************************************************
  pmt_org_inuse
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_org_inuse(classification_ids character varying) RETURNS SETOF pmt_json_result_type AS $$
DECLARE
  valid_classification_ids int[];
  dynamic_where1 text array;
  built_where text array;
  execute_statement text;
  i integer;
  rec record;
BEGIN
  -- validate classification_ids parameter
  IF $1 IS NOT NULL OR $1 <> '' THEN
    SELECT INTO valid_classification_ids * FROM pmt_validate_classifications($1);    
    RAISE NOTICE 'Valid classifications: %', valid_classification_ids;
  END IF;

  -- create dynamic where from valid classification_ids
  IF valid_classification_ids IS NOT NULL THEN
    -- Loop through each taxonomy classification group to contruct the where statement 
    FOR rec IN( SELECT tc.taxonomy_id, array_agg(tc.classification_id) AS filter_array 
    FROM taxonomy_classifications tc WHERE classification_id = ANY(valid_classification_ids) GROUP BY tc.taxonomy_id
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
  
  -- prepare statement
  execute_statement := 'select row_to_json(j) from ( select org_order.organization_id as o_id, o.name ' ||
			'from ( select organization_id, count(distinct activity_id) as a_ct ' ||
			'from organization_lookup '; 
  IF dynamic_where1 IS NOT NULL THEN          
    execute_statement := execute_statement || 'where ' ||  array_to_string(dynamic_where1, ' AND ') ;
  END IF;

  execute_statement := execute_statement ||'group by organization_id ' ||
			') as org_order ' ||				 
			'join organization o on org_order.organization_id = o.organization_id ' || 
			'order by org_order.a_ct desc ) j';
  
  RAISE NOTICE 'Where: %', dynamic_where1;	
  RAISE NOTICE 'Execute: %', execute_statement;
  		    
  -- execute statement
  FOR rec IN EXECUTE execute_statement	    
  LOOP
    RETURN NEXT rec;    
  END LOOP;
END;$$ LANGUAGE plpgsql;
/******************************************************************
  pmt_countries
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_countries(classification_ids text) RETURNS SETOF pmt_json_result_type AS $$
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
	SELECT c.classification_id as c_id, lower(c.classification) as name, ST_AsGeoJSON(Box2D(ST_Collect(polygon))) as bounds
	FROM  gaul0 g
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
	SELECT c.classification_id as c_id, lower(c.classification) as name, ST_AsGeoJSON(Box2D(ST_Collect(polygon))) as bounds
	FROM gaul0 g
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
CREATE OR REPLACE FUNCTION pmt_tax_inuse(data_group_id integer, taxonomy_ids character varying, country_ids character varying) RETURNS SETOF pmt_json_result_type AS $$
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
	    'select class_order.classification_id as c_id, c.category_id as cat_id, c.name ' ||
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
CREATE OR REPLACE FUNCTION pmt_taxonomies(taxonomy_ids character varying) RETURNS SETOF pmt_json_result_type AS $$
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
  pmt_validate_organizations
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_validate_organizations(organization_ids character varying) RETURNS INT[] AS $$
DECLARE 
  valid_organization_ids INT[];
  filter_organization_ids INT[];
BEGIN 
     IF $1 IS NULL THEN    
       RETURN valid_organization_ids;
     END IF;

     filter_organization_ids := string_to_array($1, ',')::int[];
     
     SELECT INTO valid_organization_ids array_agg(DISTINCT organization_id)::INT[] FROM (SELECT organization_id FROM organization WHERE active = true AND organization_id = ANY(filter_organization_ids) ORDER BY organization_id) as c;	 
     
     RETURN valid_organization_ids;

EXCEPTION
     WHEN others THEN RETURN NULL;
END; 
$$ LANGUAGE 'plpgsql';
/******************************************************************
  pmt_validate_organization
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_validate_organization(id integer) RETURNS boolean AS $$
DECLARE valid_id integer;
BEGIN 
     IF $1 IS NULL THEN    
       RETURN FALSE;
     END IF;    
     
     SELECT INTO valid_id organization_id FROM organization WHERE active = true AND organization_id = $1;	 

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
  pmt_infobox_menu
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_infobox_menu(location_ids text) RETURNS SETOF pmt_json_result_type AS $$
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
/******************************************************************
  pmt_infobox_project_info
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_infobox_project_info(project_id integer, tax_id integer) RETURNS SETOF pmt_json_result_type AS $$
DECLARE
  valid_taxonomy_id boolean;
  t_id integer;
  rec record;
  data_message text;
BEGIN	
   IF $1 IS NOT NULL THEN	
	-- set no data message
	data_message := 'No Data Entered';

	-- validate and process taxonomy_id parameter
	SELECT INTO valid_taxonomy_id * FROM pmt_validate_taxonomy($2);

	IF valid_taxonomy_id THEN
	  t_id := $2;
	ELSE
	  t_id := 1;
	END IF;
	
	FOR rec IN (
	select row_to_json(j)
	from
	(	
		-- project general information
		select p.project_id
		      ,coalesce(p.label, p.title, data_message) as title				
		      ,coalesce(pp.name, data_message) as org_name
		      ,coalesce(pp.url, data_message) as org_url
		      ,coalesce(sector.name, data_message) as sector
		      ,coalesce(p.tags, data_message) as keywords
		      ,coalesce(p.url, data_message) as project_url
		      ,(select array_to_json(array_agg(row_to_json(c))) from (
			select l.lat_dd as lat, l.long_dd as long, array_to_string(array_agg(DISTINCT lt.classification_id), ',') as c_id
			from location l
			left join taxonomy_lookup lt
			on l.location_id = lt.location_id
			where l.project_id = $1  and l.active = true and lt.taxonomy_id = t_id
			group by  l.lat_dd, l.long_dd
		      ) c ) as l_ids
		from
		-- project
		(select p.project_id, p.title, p.label, p.tags, p.url
		from project p
		where p.project_id = $1 and p.active = true) p
		left join		
		-- participants
		(select pp.project_id, array_to_string(array_agg(distinct o.name), ',') as name, array_to_string(array_agg(distinct o.url), ',') as url
		from participation pp
		join organization o
		on pp.organization_id = o.organization_id
		left join participation_taxonomy ppt
		on pp.participation_id = ppt.participation_id
		join classification c
		on ppt.classification_id = c.classification_id 
		where c.taxonomy_id = (select taxonomy_id from taxonomy where name = 'Organisation Role') 
		AND pp.project_id = $1 and pp.active = true and o.active = true and c.active = true
		group by pp.project_id) pp
		on p.project_id = pp.project_id
		left join
		-- Sector
		(select p.project_id, array_to_string(array_agg(c.name), ',') as name
		from project p 
		join project_taxonomy pt
		on p.project_id = pt.project_id
		join classification c
		on pt.classification_id = c.classification_id
		where c.taxonomy_id = (select taxonomy_id from taxonomy where name = 'Sector')
		and p.project_id = $1 and p.active = true and c.active = true
		group by p.project_id) as sector
		on p.project_id = sector.project_id
	) j
	) LOOP		
		RETURN NEXT rec;
	END LOOP;
   END IF;
END;$$ LANGUAGE plpgsql;
/******************************************************************
  pmt_infobox_project_stats
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_infobox_project_stats(project_id integer) RETURNS SETOF pmt_json_result_type AS $$
DECLARE
  rec record;
  data_message text;
BEGIN
   IF $1 IS NOT NULL THEN		
	-- set no data message
	data_message := 'No Data Entered';
	
	FOR rec IN (
	select row_to_json(j)
	from
	(
		select p.project_id
		       ,p.start_date
		       ,p.end_date
		       ,coalesce(s.name, data_message) as sector
		       ,f.amount as grant
		from
		-- project
		(select p.project_id, p.start_date, p.end_date
		from project p
		where p.active = true and p.project_id = $1) p
		left join
		-- sector
		(select pt.project_id, array_to_string(array_agg(distinct c.name), ',') as  name
		from project_taxonomy pt
		join classification c
		on pt.classification_id = c.classification_id
		where c.active = true and c.taxonomy_id = (select taxonomy_id from taxonomy where name = 'Sector')
		AND pt.project_id = $1
		group by pt.project_id) as s
		on p.project_id = s.project_id
		left join
		-- financials
		(select f.project_id, sum(f.amount) as amount
		from financial f
		where f.activity_id is null and f.active = true and f.project_id = $1
		group by f.project_id) as f
		on p.project_id = f.project_id
	) j
	) LOOP		
		RETURN NEXT rec;
	END LOOP;
   END IF;
END;$$ LANGUAGE plpgsql;
/******************************************************************
  pmt_infobox_project_desc
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_infobox_project_desc(project_id integer) RETURNS SETOF pmt_json_result_type AS $$
DECLARE
  rec record;
  data_message text;
BEGIN
   IF $1 IS NOT NULL THEN		
	-- set no data message
	data_message := 'No Data Entered';
	
	FOR rec IN (
	select row_to_json(j)
	from
	(
		select p.project_id
			,coalesce(p.title, data_message) as title
		       ,coalesce(p.description, data_message) as description
		from project p
		where p.active = true and p.project_id = $1	
	) j
	) LOOP		
		RETURN NEXT rec;
	END LOOP;
   END IF;
END;$$ LANGUAGE plpgsql;
/******************************************************************
  pmt_infobox_project_contact
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_infobox_project_contact(project_id integer) RETURNS SETOF pmt_json_result_type AS $$
DECLARE
  rec record;
  data_message text;
BEGIN
   IF $1 IS NOT NULL THEN		
	-- set no data message
	data_message := 'No Data Entered';
	
	FOR rec IN (
	select row_to_json(j)
	from
	(
		select 
			 p.project_id
			,coalesce(pt.partners, data_message) as partners 
			,coalesce(c.contacts, data_message) as contacts
		from
		-- project
		(select p.project_id
		from project p
		where p.active = true and p.project_id = $1) p
		left join
		-- all partners
		(select pp.project_id, array_to_string(array_agg(distinct o.name), ',') as partners
		from participation pp
		join organization o
		on pp.organization_id = o.organization_id
		left join participation_taxonomy ppt
		on pp.participation_id = ppt.participation_id
		join classification c
		on ppt.classification_id = c.classification_id
		where  pp.active = true and o.active = true and c.active = true
		and c.taxonomy_id = (select taxonomy_id from taxonomy where name = 'Organisation Role') AND (c.name = 'Implementing')
		and pp.activity_id is null and pp.project_id = $1
		group by pp.project_id) pt
		on p.project_id = pt.project_id
		left join
		-- contacts
		(select pc.project_id, array_to_string(array_agg(distinct c.first_name || ' ' || c.last_name), ',') as contacts
		from project_contact pc
		join contact c
		on pc.contact_id = c.contact_id
		where c.active = true and pc.project_id = $1
		group by pc.project_id) c
		on p.project_id = c.project_id
		
	) j
	) LOOP		
		RETURN NEXT rec;
	END LOOP;
   END IF;
END;$$ LANGUAGE plpgsql;
/******************************************************************
  pmt_infobox_activity_stats
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_infobox_activity_stats(activity_id integer) RETURNS SETOF pmt_json_result_type AS $$
DECLARE
  rec record;
  data_message text;
BEGIN
   IF $1 IS NOT NULL THEN		
	-- set no data message
	data_message := 'No Data Entered';
	
	FOR rec IN (
	select row_to_json(j)
	from
	(	
		select a.activity_id
		       ,a.start_date
		       ,a.end_date
		       ,coalesce(si.name, data_message) as sector
		       ,coalesce(s.name, data_message) as status
		       ,coalesce(l.name, data_message) as location
		       ,coalesce(a.tags, data_message) as keywords 				
		from
		-- activity
		(select a.activity_id, a.start_date, a.end_date, a.tags
		from activity a
		where a.active = true and a.activity_id = $1) a
		left join
		-- Location
		(select l.activity_id, array_to_string(array_agg(distinct l.gaul2_name || ', ' || l.gaul1_name || ', ' || l.gaul0_name ), ',') as name
		from location_lookup l		
		where l.activity_id = $1
		group by l.activity_id) as l
		on a.activity_id =  l.activity_id
		left join 
		-- Sector
		(select at.activity_id, array_to_string(array_agg(distinct c.name), ',') as name
		from activity_taxonomy at
		join classification c
		on at.classification_id = c.classification_id
		where c.active = true and c.taxonomy_id = (select taxonomy_id from taxonomy where name = 'Sector')
		and at.activity_id = $1
		group by at.activity_id) as si
		on a.activity_id = si.activity_id
		left join
		-- Activity Status
		(select at.activity_id, array_to_string(array_agg(distinct c.name), ',') as name
		from activity_taxonomy at
		join classification c
		on at.classification_id = c.classification_id
		where  c.active = true
		and c.taxonomy_id =(select taxonomy_id from taxonomy where name = 'Activity Status')
		AND at.activity_id = $1
		group by at.activity_id) s
		on a.activity_id = s.activity_id
	) j
	) LOOP		
		RETURN NEXT rec;
	END LOOP;
   END IF;
END;$$ LANGUAGE plpgsql;
/******************************************************************
  pmt_infobox_activity_desc
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_infobox_activity_desc(activity_id integer) RETURNS SETOF pmt_json_result_type AS $$
DECLARE
  rec record;
  data_message text;
BEGIN
   IF $1 IS NOT NULL THEN		
	-- set no data message
	data_message := 'No Data Entered';
	
	FOR rec IN (
	select row_to_json(j)
	from
	(
		select a.activity_id
		       ,coalesce(a.description, data_message) as description
		from activity a
		where a.active = true and a.activity_id = $1	
	) j
	) LOOP		
		RETURN NEXT rec;
	END LOOP;
   END IF;
END;$$ LANGUAGE plpgsql;
/******************************************************************
  pmt_infobox_activity_contact
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_infobox_activity_contact(activity_id integer) RETURNS SETOF pmt_json_result_type AS $$
DECLARE
  rec record;
  data_message text;
BEGIN
   IF $1 IS NOT NULL THEN		
	-- set no data message
	data_message := 'No Data Entered';
	
	FOR rec IN (
	select row_to_json(j)
	from
	(
		select  a.activity_id
		       ,coalesce(pt.partners, data_message) as partners 
		       ,coalesce(c.contacts, data_message) as contacts
		from
		-- activity
		(select a.activity_id, a.start_date, a.end_date
		from activity a
		where a.active = true and a.activity_id = $1) a
		left join
		-- all partners
		(select pp.activity_id, array_to_string(array_agg(distinct o.name), ',') as partners
		from participation pp
		join organization o
		on pp.organization_id = o.organization_id
		left join participation_taxonomy ppt
		on pp.participation_id = ppt.participation_id
		join classification c
		on ppt.classification_id = c.classification_id
		where pp.active = true and o.active = true and c.active = true 
		and c.taxonomy_id = (select taxonomy_id from taxonomy where name = 'Organisation Role') AND (c.name = 'Implementing' OR c.name = 'Funding')
		and pp.activity_id = $1
		group by pp.activity_id) pt
		on a.activity_id = pt.activity_id
		left join
		-- contacts
		(select ac.activity_id, array_to_string(array_agg(distinct c.first_name || ' ' || c.last_name), ',') as contacts
		from activity_contact ac
		join contact c
		on ac.contact_id = c.contact_id
		where c.active = true and ac.activity_id = $1
		group by ac.activity_id) c
		on a.activity_id = c.activity_id	
	) j
	) LOOP		
		RETURN NEXT rec;
	END LOOP;
   END IF;
END;$$ LANGUAGE plpgsql;
/******************************************************************
  pmt_stat_counts
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_stat_counts(classification_ids character varying, organization_ids character varying, unassigned_tax_ids character varying, 
start_date date, end_date date) RETURNS SETOF pmt_json_result_type AS $$
DECLARE
  rec record;
  filter_classids integer array;
  filter_orgids integer array;
  include_taxids integer array;
  dynamic_where1 text array;  
  dynamic_org_where text array;
  dynamic_where2 text;
  org_where text array;
  built_where text array;
  where_statement text;
  execute_statement text;
  i integer;
  num_projects integer;
  num_activities integer;
  num_orgs integer;
  num_districts integer;
BEGIN
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
	  dynamic_where1 := array_append(dynamic_where1, '(' || array_to_string(built_where, ' OR ') || ')');
	  dynamic_org_where := array_append(dynamic_org_where, '(' || array_to_string(built_where, ' OR ') || ')');
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
		org_where := array_append(org_where, 'organization_id = ' || i ||' ');
	END LOOP;
	-- Add the complied org statements to the where
	dynamic_where1 := array_append(dynamic_where1, '(' || array_to_string(built_where, ' OR ') || ')');
	dynamic_org_where := array_append(dynamic_org_where, '(' || array_to_string(org_where, ' OR ') || ')');
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
      dynamic_where2 := '(' || array_to_string(built_where, ' OR ') || ')';
	
   END IF;
   
   -- filter by date range
   IF ($4 is not null AND $5 is not null) THEN
	dynamic_where1 := array_append(dynamic_where1, '(start_date > ''' || $4 || ''' AND end_date < ''' || $5 || ''')');
	dynamic_org_where := array_append(dynamic_org_where, '(start_date > ''' || $4 || ''' AND end_date < ''' || $5 || ''')');
   END IF;	
   
   -- prepare where statement
   IF dynamic_where1 IS NOT NULL THEN          
    IF dynamic_where2 IS NOT NULL THEN
      where_statement := array_to_string(dynamic_where1, ' AND ')  || ' OR ' || dynamic_where2;
    ELSE
      where_statement :=  array_to_string(dynamic_where1, ' AND ') || ' ';
    END IF;
   ELSE 
    IF dynamic_where2 IS NOT NULL THEN
      where_statement :=  dynamic_where2 || ' ';                       
    END IF;
   END IF;

   -- number of projects
   execute_statement := 'SELECT count(DISTINCT project_id)::int FROM location_lookup ';
   IF where_statement IS NOT NULL THEN 	execute_statement := execute_statement || ' WHERE ' || where_statement;  END IF;
   RAISE NOTICE 'Number of projects : %', execute_statement;
   EXECUTE execute_statement INTO num_projects;   
   
   -- number of activities
   execute_statement := 'SELECT count(DISTINCT activity_id)::int FROM location_lookup ';
   IF where_statement IS NOT NULL THEN 	execute_statement := execute_statement || ' WHERE ' || where_statement;  END IF;
   RAISE NOTICE 'Number of activities : %', execute_statement;
   EXECUTE execute_statement INTO num_activities;

    -- number of districts
   execute_statement := 'SELECT count(DISTINCT lbf.name)::int FROM (SELECT location_id ' ||
			'FROM location_lookup ';
   IF where_statement IS NOT NULL THEN 	execute_statement := execute_statement || ' WHERE ' || where_statement;  END IF;
   execute_statement := execute_statement || ') as l JOIN location_boundary_features lbf ON l.location_id = lbf.location_id ' ||
			'WHERE lbf.boundary_id = (SELECT boundary_id FROM boundary WHERE spatial_table = ''gaul2'')';
   RAISE NOTICE 'Number of districts : %', execute_statement;			
   EXECUTE execute_statement INTO num_districts;
   
   -- number of orgs
   execute_statement := 'SELECT count(DISTINCT organization_id)::int FROM organization_lookup ' ||
			'WHERE (classification_ids @> ARRAY[(select classification_id from classification where taxonomy_id = (select taxonomy_id from taxonomy where name = ''Organisation Role'') AND iati_name = ''Implementing'')]) ';

    -- prepare where statement
   IF dynamic_org_where IS NOT NULL THEN          
    IF dynamic_where2 IS NOT NULL THEN
      where_statement := array_to_string(dynamic_org_where, ' AND ')  || ' OR ' || dynamic_where2;
    ELSE
      where_statement :=  array_to_string(dynamic_org_where, ' AND ') || ' ';
    END IF;
   ELSE 
    IF dynamic_where2 IS NOT NULL THEN
      where_statement :=  dynamic_where2 || ' ';                       
    END IF;
   END IF;
   			
   IF where_statement IS NOT NULL THEN 	execute_statement := execute_statement || ' AND ' || where_statement;  END IF;
   RAISE NOTICE 'Number of orgs : %', execute_statement;
   EXECUTE execute_statement INTO num_orgs;

  
   
   FOR rec IN EXECUTE 'select row_to_json(t) from (SELECT ' || 
   'coalesce('|| num_projects || ', 0) as p_ct, ' || 
   'coalesce('|| num_activities || ', 0) as a_ct, ' || 
   'coalesce('|| num_orgs || ', 0) as o_ct, ' || 
   'coalesce('|| num_districts || ', 0) as d_ct ' || 
   ') t;' LOOP
     RETURN NEXT rec; 
   END LOOP;
   	
END;$$ LANGUAGE plpgsql;
/******************************************************************
  pmt_stat_project_by_tax
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_stat_project_by_tax(tax_id integer, classification_ids character varying, organization_ids character varying, unassigned_tax_ids character varying, 
start_date date, end_date date) RETURNS SETOF pmt_json_result_type AS $$
DECLARE
  rec record;
  valid_taxonomy_id boolean;
  filter_classids integer array;
  filter_orgids integer array;
  include_taxids integer array;
  dynamic_where1 text array;
  dynamic_where2 text;
  built_where text array;
  where_statement text;
  execute_statement text;
  i integer;
BEGIN
-- validate and process taxonomy_id parameter
SELECT INTO valid_taxonomy_id * FROM pmt_validate_taxonomy($1); 

-- Must have taxonomy_id parameter to continue
IF NOT valid_taxonomy_id THEN
   RAISE NOTICE '   + A taxonomy is required.';
ELSE
   -- filter by classification ids
   IF ($2 is not null AND $2 <> '') THEN

      -- Create an int array from classification ids list
	filter_classids := string_to_array($2, ',')::int[];

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
	  dynamic_where1 := array_append(dynamic_where1, '(' || array_to_string(built_where, ' OR ') || ')');
	END LOOP;			
   END IF;
   
   -- filter by organization ids
   IF ($3 is not null AND $3 <> '') THEN

      -- Create an int array from organization ids list
	filter_orgids := string_to_array($3, ',')::int[];		

      -- Loop through the organization_ids and construct the where statement
	built_where := null;
	FOREACH i IN ARRAY filter_orgids LOOP
		built_where :=  array_append(built_where, 'organization_ids @> ARRAY['|| i ||']');
	END LOOP;
	-- Add the complied org statements to the where
	dynamic_where1 := array_append(dynamic_where1, '(' || array_to_string(built_where, ' OR ') || ')');
	
   END IF;
   -- include unassigned taxonomy ids
   IF ($4 is not null AND $4 <> '') THEN
   
      -- Create an int array from unassigned ids list
      include_taxids := string_to_array($4, ',')::int[];				

      -- Loop through the organization_ids and construct the where statement
      built_where := null;
      FOREACH i IN ARRAY include_taxids LOOP
	built_where :=  array_append(built_where, 'not (taxonomy_ids @> ARRAY['|| i ||'])');
      END LOOP;		

      -- Add the complied org statements to the where
      dynamic_where2 := '(' || array_to_string(built_where, ' OR ') || ')';
	
   END IF;
   
   -- filter by date range
   IF ($5 is not null AND $6 is not null) THEN
	dynamic_where1 := array_append(dynamic_where1, '(start_date > ''' || $5 || ''' AND end_date < ''' || $6 || ''')');
   END IF;	
   
   -- prepare where statement
   IF dynamic_where1 IS NOT NULL THEN          
    IF dynamic_where2 IS NOT NULL THEN
      where_statement := array_to_string(dynamic_where1, ' AND ')  || ' OR ' || dynamic_where2;
    ELSE
      where_statement :=  array_to_string(dynamic_where1, ' AND ') || ' ';
    END IF;
   ELSE 
    IF dynamic_where2 IS NOT NULL THEN
      where_statement :=  dynamic_where2 || ' ';                       
    END IF;
   END IF;

   execute_statement :=  'select row_to_json(j) FROM (SELECT report_by.classification_id as c_id, count(DISTINCT a.project_id) as p_ct FROM ' ||
			 '(SELECT DISTINCT project_id FROM location_lookup ';
   IF where_statement IS NOT NULL THEN 	execute_statement := execute_statement || ' WHERE ' || where_statement;  END IF;
   execute_statement :=  execute_statement || ')as a LEFT JOIN (SELECT project_id,classification_id FROM taxonomy_lookup WHERE taxonomy_id = ' || $1 || ') as report_by ' ||
			 'ON a.project_id = report_by.project_id GROUP BY classification_id) as j';
   
   RAISE NOTICE 'Execute statement: %', execute_statement;
   
   FOR rec IN EXECUTE execute_statement LOOP
     RETURN NEXT rec; 
   END LOOP;
   
END IF; -- must have valid taxonomy   	
END;$$ LANGUAGE plpgsql;
/******************************************************************
  pmt_stat_activity_by_tax
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_stat_activity_by_tax(tax_id integer, classification_ids character varying, organization_ids character varying, unassigned_tax_ids character varying, 
start_date date, end_date date) RETURNS SETOF pmt_json_result_type AS $$
DECLARE
  rec record;
  valid_taxonomy_id boolean;
  filter_classids integer array;
  filter_orgids integer array;
  include_taxids integer array;
  dynamic_where1 text array;
  dynamic_where2 text;
  built_where text array;
  where_statement text;
  execute_statement text;
  i integer;
BEGIN
-- validate and process taxonomy_id parameter
SELECT INTO valid_taxonomy_id * FROM pmt_validate_taxonomy($1); 

-- Must have taxonomy_id parameter to continue
IF NOT valid_taxonomy_id THEN
   RAISE NOTICE '   + A taxonomy is required.';
ELSE
   -- filter by classification ids
   IF ($2 is not null AND $2 <> '') THEN

      -- Create an int array from classification ids list
	filter_classids := string_to_array($2, ',')::int[];

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
	  dynamic_where1 := array_append(dynamic_where1, '(' || array_to_string(built_where, ' OR ') || ')');
	END LOOP;			
   END IF;
   
   -- filter by organization ids
   IF ($3 is not null AND $3 <> '') THEN

      -- Create an int array from organization ids list
	filter_orgids := string_to_array($3, ',')::int[];		

      -- Loop through the organization_ids and construct the where statement
	built_where := null;
	FOREACH i IN ARRAY filter_orgids LOOP
		built_where :=  array_append(built_where, 'organization_ids @> ARRAY['|| i ||']');
	END LOOP;
	-- Add the complied org statements to the where
	dynamic_where1 := array_append(dynamic_where1, '(' || array_to_string(built_where, ' OR ') || ')');
	
   END IF;
   -- include unassigned taxonomy ids
   IF ($4 is not null AND $4 <> '') THEN
   
      -- Create an int array from unassigned ids list
      include_taxids := string_to_array($4, ',')::int[];				

      -- Loop through the organization_ids and construct the where statement
      built_where := null;
      FOREACH i IN ARRAY include_taxids LOOP
	built_where :=  array_append(built_where, 'not (taxonomy_ids @> ARRAY['|| i ||'])');
      END LOOP;		

      -- Add the complied org statements to the where
      dynamic_where2 := '(' || array_to_string(built_where, ' OR ') || ')';
	
   END IF;
   
   -- filter by date range
   IF ($5 is not null AND $6 is not null) THEN
	dynamic_where1 := array_append(dynamic_where1, '(start_date > ''' || $5 || ''' AND end_date < ''' || $6 || ''')');
   END IF;	
   
   -- prepare where statement
   IF dynamic_where1 IS NOT NULL THEN          
    IF dynamic_where2 IS NOT NULL THEN
      where_statement := array_to_string(dynamic_where1, ' AND ')  || ' OR ' || dynamic_where2;
    ELSE
      where_statement :=  array_to_string(dynamic_where1, ' AND ') || ' ';
    END IF;
   ELSE 
    IF dynamic_where2 IS NOT NULL THEN
      where_statement :=  dynamic_where2 || ' ';                       
    END IF;
   END IF;

   execute_statement :=  'select row_to_json(j) FROM (SELECT report_by.classification_id as c_id, count(DISTINCT a.activity_id) as a_ct FROM ' ||
			 '(SELECT DISTINCT activity_id FROM location_lookup ';
   IF where_statement IS NOT NULL THEN 	execute_statement := execute_statement || ' WHERE ' || where_statement;  END IF;
   execute_statement :=  execute_statement || ')as a LEFT JOIN (SELECT activity_id,classification_id FROM taxonomy_lookup WHERE taxonomy_id = ' || $1 || ') as report_by ' ||
			 'ON a.activity_id = report_by.activity_id GROUP BY classification_id) as j';
   
 
   FOR rec IN EXECUTE execute_statement LOOP
     RETURN NEXT rec; 
   END LOOP;
   
END IF; -- must have valid taxonomy   	
END;$$ LANGUAGE plpgsql;
/******************************************************************
  pmt_stat_locations
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_stat_locations(classification_ids character varying, organization_ids character varying, unassigned_tax_ids character varying, 
start_date date, end_date date) RETURNS SETOF pmt_json_result_type AS $$
DECLARE
  rec record;
  filter_classids integer array;
  filter_orgids integer array;
  include_taxids integer array;
  dynamic_where1 text array;
  dynamic_where2 text;
  built_where text array;
  where_statement text;
  execute_statement text;
  i integer;
  num_projects integer;
  num_activities integer;
  num_orgs integer;
  num_districts integer;
BEGIN
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
	  dynamic_where1 := array_append(dynamic_where1, '(' || array_to_string(built_where, ' OR ') || ')');
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
	dynamic_where1 := array_append(dynamic_where1, '(' || array_to_string(built_where, ' OR ') || ')');
	
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
      dynamic_where2 := '(' || array_to_string(built_where, ' OR ') || ')';
	
   END IF;
   
   -- filter by date range
   IF ($4 is not null AND $5 is not null) THEN
	dynamic_where1 := array_append(dynamic_where1, '(start_date > ''' || $4 || ''' AND end_date < ''' || $5 || ''')');
   END IF;	
   
   -- prepare where statement
   IF dynamic_where1 IS NOT NULL THEN          
    IF dynamic_where2 IS NOT NULL THEN
      where_statement := array_to_string(dynamic_where1, ' AND ')  || ' OR ' || dynamic_where2;
    ELSE
      where_statement :=  array_to_string(dynamic_where1, ' AND ') || ' ';
    END IF;
   ELSE 
    IF dynamic_where2 IS NOT NULL THEN
      where_statement :=  dynamic_where2 || ' ';                       
    END IF;
   END IF;

   -- locations
   execute_statement := 'select row_to_json(t) from (SELECT filter.location_id as l_id, l.lat_dd, l.long_dd FROM ' ||
			'(SELECT location_id FROM location_lookup ';
			
   IF where_statement IS NOT NULL THEN 	execute_statement := execute_statement || ' WHERE ' || where_statement;  END IF;
   
   execute_statement := execute_statement || ') as filter JOIN location l ON filter.location_id = l.location_id) as t';
   
   
   FOR rec IN EXECUTE execute_statement LOOP
     RETURN NEXT rec; 
   END LOOP;
   	
END;$$ LANGUAGE plpgsql;
/******************************************************************
  pmt_stat_orgs_by_activity
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_stat_orgs_by_activity(tax_id integer, classification_ids character varying, organization_ids character varying, unassigned_tax_ids character varying, 
start_date date, end_date date) RETURNS SETOF pmt_json_result_type AS $$
DECLARE
  rec record;
  valid_taxonomy_id boolean;
  filter_classids integer array;
  filter_orgids integer array;
  include_taxids integer array;
  dynamic_where1 text array;
  dynamic_where2 text;
  built_where text array;
  where_statement text;
  execute_statement text;
  i integer;
BEGIN
-- validate and process taxonomy_id parameter
SELECT INTO valid_taxonomy_id * FROM pmt_validate_taxonomy($1); 

-- Must have taxonomy_id parameter to continue
IF NOT valid_taxonomy_id THEN
   RAISE NOTICE '   + A taxonomy is required.';
ELSE
   -- filter by classification ids
   IF ($2 is not null AND $2 <> '') THEN

      -- Create an int array from classification ids list
	filter_classids := string_to_array($2, ',')::int[];

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
	  dynamic_where1 := array_append(dynamic_where1, '(' || array_to_string(built_where, ' OR ') || ')');
	END LOOP;			
   END IF;
   
   -- filter by organization ids
   IF ($3 is not null AND $3 <> '') THEN

      -- Create an int array from organization ids list
	filter_orgids := string_to_array($3, ',')::int[];		

      -- Loop through the organization_ids and construct the where statement
	built_where := null;
	FOREACH i IN ARRAY filter_orgids LOOP
		built_where :=  array_append(built_where, 'organization_id = '|| i );
	END LOOP;
	-- Add the complied org statements to the where
	dynamic_where1 := array_append(dynamic_where1, '(' || array_to_string(built_where, ' OR ') || ')');
	
   END IF;
   -- include unassigned taxonomy ids
   IF ($4 is not null AND $4 <> '') THEN
   
      -- Create an int array from unassigned ids list
      include_taxids := string_to_array($4, ',')::int[];				

      -- Loop through the organization_ids and construct the where statement
      built_where := null;
      FOREACH i IN ARRAY include_taxids LOOP
	built_where :=  array_append(built_where, 'not (taxonomy_ids @> ARRAY['|| i ||'])');
      END LOOP;		

      -- Add the complied org statements to the where
      dynamic_where2 := '(' || array_to_string(built_where, ' OR ') || ')';
	
   END IF;
   
   -- filter by date range
   IF ($5 is not null AND $6 is not null) THEN
	dynamic_where1 := array_append(dynamic_where1, '(start_date > ''' || $5 || ''' AND end_date < ''' || $6 || ''')');
   END IF;	
   
   -- prepare where statement
   IF dynamic_where1 IS NOT NULL THEN          
    IF dynamic_where2 IS NOT NULL THEN
      where_statement := array_to_string(dynamic_where1, ' AND ')  || ' OR ' || dynamic_where2;
    ELSE
      where_statement :=  array_to_string(dynamic_where1, ' AND ') || ' ';
    END IF;
   ELSE 
    IF dynamic_where2 IS NOT NULL THEN
      where_statement :=  dynamic_where2 || ' ';                       
    END IF;
   END IF;

   execute_statement :=  'SELECT row_to_json(j) FROM ( SELECT top.o_id, o.name, top.a_ct, top.a_by_tax FROM( SELECT lu.organization_id as o_id,  count(DISTINCT lu.activity_id) as a_ct ' ||
			',(SELECT array_to_json(array_agg(row_to_json(b))) FROM (SELECT classification_id as c_id, count(distinct activity_id) AS a_ct ' ||
			'FROM taxonomy_lookup WHERE taxonomy_id = ' || $1 || ' AND organization_id = lu.organization_id  AND activity_id = ANY(array_agg(DISTINCT lu.activity_id)) GROUP BY classification_id ) b ) as a_by_tax ' ||
			'FROM organization_lookup lu ' ||
			'WHERE (classification_ids @> ARRAY[(select classification_id from classification where taxonomy_id = (select taxonomy_id from taxonomy where name = ''Organisation Role'') AND iati_name = ''Accountable'')]) ';
   IF where_statement IS NOT NULL THEN 	execute_statement := execute_statement || ' AND ' || where_statement;  END IF;			
   execute_statement :=  execute_statement || 'GROUP BY lu.organization_id ORDER BY a_ct desc LIMIT 10 ) as top JOIN organization o ON top.o_id = o.organization_id ) as j';

   RAISE NOTICE 'Execute statement: %', execute_statement;
   FOR rec IN EXECUTE execute_statement LOOP
     RETURN NEXT rec; 
   END LOOP;
   
END IF; -- must have valid taxonomy   	
END;$$ LANGUAGE plpgsql;
/******************************************************************
  pmt_filter_csv
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_filter_csv(classification_ids character varying, organization_ids character varying, unassigned_tax_ids character varying, start_date date, end_date date, email text) 
    RETURNS BOOLEAN AS $$
DECLARE
  project_ids int[];	
  activity_ids int[];
  pid int;
  aid int;
  counter int;
  filter_classids integer array;
  filter_orgids integer array;
  filter text;
  disclaimer text;
  filename text;
  db_version text;
  db_instance text;
  rec record;
BEGIN
  -- create temporary table to hold our data for the csv
  CREATE TEMPORARY TABLE csv_data (
      id int,c1 text,c2 text,c3 text,c4 text,c5 text,c6 text,c7 text,c8 text,c9 text,c10 text
     ,c11 text,c12 text,c13 text,c14 text,c15 text,c16 text,c17 text,c18 text
     ) ON COMMIT DROP;

  -- get database version
  SELECT INTO db_version version from pmt_version() LIMIT 1;
  
  -- build version/date/filter line
  filter := 'PMT 2.0, Database Version ' || db_version || ', Retrieval Date:' || CURRENT_DATE;

  IF ($1 is null OR $1 = '') AND ($2 is null OR $2 = '')  AND ($3 is null OR $4 is null) THEN
    filter := filter || ',Filters: none';	    
  ELSE
    filter_classids := string_to_array($1, ',')::int[]; 
    filter_orgids := string_to_array($2, ',')::int[]; 
    filter := filter || ',Filters: ';
    IF array_length(filter_classids, 1) > 0 THEN
      FOR rec IN (SELECT tc.taxonomy, array_to_string(array_agg(tc.classification), ',') AS classification FROM taxonomy_classifications tc 
	  WHERE classification_id = ANY(filter_classids) GROUP BY tc.taxonomy) LOOP
	  filter := filter || rec.taxonomy || '=' || rec.classification || ' | ';
      END LOOP;
    END IF;
    IF array_length(filter_orgids, 1) > 0 THEN
      FOR rec IN (SELECT array_to_string(array_agg(o.name), ',') as names FROM organization o WHERE organization_id = ANY(filter_orgids)) LOOP
         filter := filter || 'Organization=' || rec.names || ' | ';
      END LOOP;
    END IF;
    IF $3 is not null AND $4 is not null THEN
      filter := filter || 'DateRange=' || $3 || ' to ' || $4 || ' | ';
    END IF;
  END IF;

  disclaimer := 'Disclaimer: TEXT';
  
  -- get the project ids
  SELECT INTO project_ids array_agg(p_id)::int[] FROM pmt_filter_projects($1,$2,$3,$4,$5);
  RAISE NOTICE 'Project ids to export: %', project_ids;

  IF project_ids IS NOT NULL THEN
  -- start record counter, used to ensure the proper order of rows
  counter := 1;

  -- write the filter
  INSERT INTO csv_data (id,c1) SELECT counter, filter;
  counter := counter + 1;
  -- write the disclaimer
  INSERT INTO csv_data (id,c1) SELECT counter, disclaimer;
  counter := counter + 1;
  	
  -- loop through all projects
  FOREACH pid IN ARRAY project_ids LOOP
     RAISE NOTICE '  + Preparing project id: %', pid;
        -- insert project header
	INSERT INTO csv_data (id,c1,c2,c3,c4,c5,c6,c7,c8)	
		-- Project Query
		SELECT  counter
			,'Project Data' 
			,'PMT ProjectID'
			,'Project Name'
			,'Project Description'
			,'Data Group'
			,'Start Date'
			,'End Date'
			,'Total Budget';	
	counter := counter + 1;
	-- insert project data 
	INSERT INTO csv_data (id,c1,c2,c3,c4,c5,c6,c7,c8)	 
		select  counter
			,''::text			-- Project Data
			,p.project_id::text		-- PMT ProjectID
			,p.title::text			-- Project Name
			,p.description::text		-- Project Description
			,dg.name::text			-- Data Group
			,p.start_date::text		-- Start Date
			,p.end_date::text		-- End Date
			,f.amount::text			-- Total Budget
		from
		-- project
		(select p.project_id, p.title, p.description, p.start_date, p.end_date
		from project p
		where p.project_id = pid) p		
		left join
		-- data group
		(select pt.project_id, array_to_string(array_agg(c.name), ',') as name
		from project_taxonomy pt
		join classification c
		on pt.classification_id = c.classification_id
		where c.taxonomy_id = (select taxonomy_id from taxonomy where name = 'Data Group')
		AND pt.project_id = pid and c.active = true
		group by pt.project_id) as dg
		on p.project_id = dg.project_id
		left join		
		-- financials
		(select f.project_id, sum(f.amount) as amount
		from financial f
		where f.activity_id is null and f.project_id = pid and f.active = true
		group by f.project_id) as f
		on p.project_id = f.project_id;
     counter := counter + 1;
     
     -- get the activitiy ids
     SELECT INTO activity_ids string_to_array(a_ids, ',')::int[] FROM pmt_filter_projects($1,$2,$3,$4,$5) WHERE p_id = pid;
     RAISE NOTICE '  + Activity ids to export: %', activity_ids;
     -- insert activity header
     INSERT INTO csv_data (id,c1,c2,c3,c4,c5,c6,c7,c8,c9,c10,c11,c12,c13,c14)        	
     		SELECT  counter
			,'Activity Data' 
			,'PMT ActivityID'
			,'Activity Title'
			,'Activity Description'
			,'Sector - Name'
			,'Sector - Code'
			,'Latitude Longitude'
			,'Country'
			,'Funding Organization(s)'
			,'Implementing Organization(s)'
			,'Start Date'
			,'End Date'
			,'Total Budget'
			,'Activity Status';
     counter := counter + 1;
     -- loop through all activities
     FOREACH aid IN ARRAY activity_ids LOOP
        RAISE NOTICE '    + Preparing activity id: %', aid;	
        -- insert activity data
	INSERT INTO csv_data (id,c1,c2,c3,c4,c5,c6,c7,c8,c9,c10,c11,c12,c13,c14)         	
		select  counter
			,''::text			-- Activity Data
			,a.activity_id::text		-- PMT ActivityID
			,a.title::text			-- Activity Title
			,a.description::text		-- Activity Description
			,s.name::text			-- Sector name
			,s.code::text			-- Sector code
			,l.location::text		-- Latitude Longitude
			,c.name::text			-- Country			
			,fo.funding::text		-- Funding Orgs
			,io.implementing::text		-- Implementing Orgs
			,a.start_date::text		-- Start Date
			,a.end_date::text		-- End Date
			,f.amount::text			-- Total Bugdet
			,acs.name::text			-- Activity Status	
		from
		-- activity
		(select a.activity_id, a.title, a.description, a.start_date, a.end_date
		from activity a
		where a.activity_id = aid and a.active = true) a
		left join 
		-- Sector
		(select at.activity_id,array_to_string(array_agg(c.code), ',') as code, array_to_string(array_agg(c.name), ',') as name
		from activity_taxonomy at
		join classification c
		on at.classification_id = c.classification_id
		where c.taxonomy_id = (select taxonomy_id from taxonomy where iati_name = 'Sector')
		and at.activity_id = aid and c.active = true
		group by at.activity_id) as s
		on a.activity_id = s.activity_id
		left join
		-- Country
		(select l.activity_id, array_to_string(array_agg(c.name), ',') as name
		from location l 
		join location_taxonomy lt
		on l.location_id = lt.location_id
		join classification c
		on lt.classification_id = c.classification_id
		where c.taxonomy_id =(select taxonomy_id from taxonomy where name = 'Country')
		AND l.activity_id = aid and l.active = true and c.active = true
		group by l.activity_id) c
		on a.activity_id = c.activity_id
		left join
		-- Activity Status
		(select at.activity_id, array_to_string(array_agg(c.name), ',') as name
		from activity_taxonomy at
		join classification c
		on at.classification_id = c.classification_id
		where c.taxonomy_id =(select taxonomy_id from taxonomy where name = 'Activity Status')
		AND at.activity_id = aid and c.active = true
		group by at.activity_id) acs
		on a.activity_id = acs.activity_id
		left join
		-- financials
		(select f.activity_id, sum(f.amount) as amount
		from financial f
		where f.activity_id = aid and f.active = true
		group by f.activity_id) as f
		on a.activity_id = f.activity_id
		left join
		-- implementing orgs
		(select pp.activity_id, array_to_string(array_agg(o.name), ',') as implementing
		from participation pp
		join organization o
		on pp.organization_id = o.organization_id
		left join participation_taxonomy ppt
		on pp.participation_id = ppt.participation_id
		join classification c
		on ppt.classification_id = c.classification_id
		where c.taxonomy_id = (select taxonomy_id from taxonomy where name = 'Organisation Role') AND (c.iati_name = 'Implementing')
		and pp.activity_id = aid and pp.active = true and o.active = true and c.active = true
		group by pp.activity_id) io
		on a.activity_id = io.activity_id
		left join
		-- funding orgs
		(select pp.activity_id, array_to_string(array_agg(o.name), ',') as funding
		from participation pp
		join organization o
		on pp.organization_id = o.organization_id
		left join participation_taxonomy ppt
		on pp.participation_id = ppt.participation_id
		join classification c
		on ppt.classification_id = c.classification_id
		where c.taxonomy_id = (select taxonomy_id from taxonomy where name = 'Organisation Role') AND (c.iati_name = 'Funding')
		and pp.activity_id = aid and pp.active = true and o.active = true and c.active = true
		group by pp.activity_id) fo
		on a.activity_id = fo.activity_id
		left join
		-- locations
		(select l.activity_id, array_to_string(array_agg(DISTINCT l.lat_dd || ' ' || l.long_dd), ',') as location
		from location l
		where l.activity_id = aid and l.active = true
		group by l.activity_id) l
		on a.activity_id = l.activity_id;
        counter := counter + 1;
     END LOOP;     
  END LOOP;
    -- get the database instance (information is used by the server process to use instance specific email message when emailing file)
  SELECT INTO db_instance * FROM current_database();
  filename := '''/usr/local/pmt_dir/' || $6 || '_' || lower(db_instance) || '.csv''';
  EXECUTE 'COPY(SELECT c1,c2,c3,c4,c5,c6,c7,c8,c9,c10,c11,c12,c13,c14,c15,c16,c17,c18 FROM csv_data ORDER BY id) To ' || filename || ' With CSV;'; 
  RETURN TRUE;
  ELSE
    RETURN FALSE;
  END IF;
END;$$ LANGUAGE plpgsql;
/******************************************************************
  pmt_filter_iati
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_filter_iati(classification_ids character varying, organization_ids character varying, unassigned_tax_ids character varying, start_date date, end_date date, email text)
RETURNS BOOLEAN AS 
$$
DECLARE
  activities int[];
  execute_statement text;
  filename text;
  db_instance text;
BEGIN

SELECT INTO activities string_to_array(array_to_string(array_agg(a_ids), ','), ',')::int[] FROM pmt_filter_projects($1,$2,$3,$4,$5);
RAISE NOTICE 'Activities: %', array_to_string(activities, ',') ;
IF activities IS NOT NULL THEN
 -- get the database instance (information is used by the server process to use instance specific email message when emailing file)
 SELECT INTO db_instance * FROM current_database();
 filename := '''/usr/local/pmt_dir/' || $6 || '_' || lower(db_instance) || '.xml''';
 execute_statement:= 'COPY( ' ||
	  -- activities
	 'SELECT xmlelement(name "iati-activities", xmlattributes(current_date as "generated-datetime", ''1.03'' as "version"),  ' ||
		'( ' ||
		-- activity
		'SELECT xmlagg(xmlelement(name "iati-activity", xmlattributes(to_char(a.updated_date, ''YYYY-MM-DD'') as "last-updated-datetime"),  ' ||
					'xmlelement(name "title", a.title), ' ||
					'xmlelement(name "description", a.description), ' ||
					'xmlelement(name "activity-date", xmlattributes(''start-planned'' as "type", to_char(a.start_date, ''YYYY-MM-DD'') as "iso-date"), ''''), ' ||
					'xmlelement(name "activity-date", xmlattributes(''end-planned'' as "type", to_char(a.end_date, ''YYYY-MM-DD'') as "iso-date"), ''''), ' ||
					-- budget
					'( ' ||					
						'SELECT xmlagg(xmlelement(name "budget",  ' ||
							'xmlelement(name "period-start", xmlattributes(to_char(f.start_date, ''YYYY-MM-DD'') as "iso-date"), ''''), ' ||
							'xmlelement(name "period-end", xmlattributes(to_char(f.end_date, ''YYYY-MM-DD'') as "iso-date"), ''''), ' ||
							'xmlelement(name "value",  f.amount) ' ||
						')) ' ||	
						'FROM financial f ' ||
						'WHERE f.activity_id = a.activity_id ' ||
					'), ' ||
					-- participating organizations
					'( ' ||
						'SELECT xmlagg(xmlelement(name "participating-org", xmlattributes(c.iati_code as "role"), o.name)) ' ||
						'FROM participation pp ' ||
						'JOIN organization o ' ||
						'ON pp.organization_id = o.organization_id ' ||
						'JOIN participation_taxonomy pt ' ||
						'ON pp.participation_id = pt.participation_id ' ||
						'JOIN classification c ' ||
						'ON pt.classification_id = c.classification_id ' ||
						'WHERE pp.activity_id = a.activity_id  ' ||
					'), ' ||
					-- sector	
					'( ' ||
						'SELECT xmlagg(xmlelement(name "sector", xmlattributes(c.iati_code as "code"), c.iati_name))	 ' ||
						'FROM activity_taxonomy at ' ||
						'JOIN classification c ' ||
						'ON at.classification_id = c.classification_id	 ' ||
						'WHERE taxonomy_id = (SELECT taxonomy_id FROM taxonomy WHERE name = ''Sector'') AND at.activity_id = a.activity_id ' ||
					'), ' ||
					-- location
					'( ' ||
						'SELECT xmlagg(xmlelement(name "location",  ' ||
									'xmlelement(name "coordinates", xmlattributes(l.lat_dd as "latitude",l.long_dd as "longitude"), ''''), ' ||
									'xmlelement(name "adinistrative",  ' ||
											'xmlattributes( ' ||
												'( ' ||
												'SELECT c.iati_code ' ||
												'FROM location_taxonomy lt ' ||
												'JOIN classification c ' ||
												'ON lt.classification_id = c.classification_id ' ||
												'WHERE taxonomy_id = (SELECT taxonomy_id FROM taxonomy WHERE name = ''Country'') AND location_id = l.location_id ' ||
												'LIMIT 1 ' ||
												') as "code"), ' ||
											'(  ' ||
											'SELECT array_to_string(array_agg(name), '','') ' ||
											'FROM location_boundary_features ' ||
											'WHERE location_id = l.location_id ' ||
											')) ' ||
							      ') ' ||
							') ' ||
						'FROM location l ' ||
						'WHERE l.activity_id = a.activity_id ' ||
					') ' ||
				') ' ||
			') ' ||
		'FROM activity a		 ' ||
		'WHERE a.activity_id = ANY(ARRAY [' || array_to_string(activities, ',') || ']) ' ||
		') ' ||
	') ' ||
	') To ' || filename || ';'; 

	RAISE NOTICE 'Execute statement: %', execute_statement;
	EXECUTE execute_statement;
	RETURN TRUE;
ELSE	
	RETURN FALSE;
END IF;

RETURN TRUE;

END;$$ LANGUAGE plpgsql;
/******************************************************************
  pmt_purge_activity
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_purge_activity(a_id integer) RETURNS BOOLEAN AS $$
DECLARE 
BEGIN 
     IF $1 IS NULL THEN    
       RETURN FALSE;
     END IF;
	-- Purge data
	DELETE FROM activity_contact WHERE activity_id = $1;
	DELETE FROM activity_taxonomy WHERE activity_id = $1;
	DELETE FROM financial_taxonomy WHERE financial_id IN (SELECT financial_id FROM financial WHERE activity_id = $1);
	DELETE FROM financial WHERE activity_id = $1;
	DELETE FROM participation_taxonomy WHERE participation_id IN (SELECT participation_id FROM participation WHERE activity_id = $1);
	DELETE FROM detail WHERE activity_id = $1;
	DELETE FROM result_taxonomy WHERE result_id IN (SELECT result_id FROM result WHERE activity_id = $1);
	DELETE FROM result WHERE activity_id = $1;
	DELETE FROM location_taxonomy WHERE location_id IN (SELECT location_id FROM location WHERE activity_id = $1);
	DELETE FROM location_boundary WHERE location_id IN (SELECT location_id FROM location WHERE activity_id = $1);
	DELETE FROM activity WHERE activity_id = $1;
	DELETE FROM location WHERE activity_id = $1;
	DELETE FROM participation WHERE activity_id = $1;
	DELETE FROM contact_taxonomy WHERE contact_id IN (SELECT contact_id FROM contact WHERE contact_id NOT IN (SELECT DISTINCT contact_id FROM activity_contact) AND contact_id NOT IN (SELECT DISTINCT contact_id FROM project_contact));
	DELETE FROM contact WHERE contact_id NOT IN (SELECT DISTINCT contact_id FROM activity_contact) AND contact_id NOT IN (SELECT DISTINCT contact_id FROM project_contact);
	DELETE FROM organization_taxonomy WHERE organization_id IN (SELECT organization_id FROM organization WHERE organization_id NOT IN (SELECT DISTINCT organization_id FROM participation) AND organization_id NOT IN (SELECT DISTINCT organization_id FROM contact));
	DELETE FROM organization WHERE organization_id NOT IN (SELECT DISTINCT organization_id FROM participation) AND organization_id NOT IN (SELECT DISTINCT organization_id FROM contact);	
	PERFORM refresh_taxonomy_lookup();
     RETURN TRUE;

EXCEPTION
     WHEN others THEN RETURN FALSE;
END; 
$$ LANGUAGE 'plpgsql';
/******************************************************************
  pmt_iati_import
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_iati_import(file_path text, data_group_name character varying, replace_all boolean) RETURNS boolean AS $$
DECLARE 
  purge_project_ids integer[];
  purge_id integer;
  group_name text;
  new_project_id integer;
BEGIN      
     IF $1 IS NULL OR $2 IS NULL THEN    
       RETURN FALSE;
     END IF;    
     
     -- get project_ids to purge by data_group
     SELECT INTO purge_project_ids array_agg(project_id)::INT[] FROM project_taxonomy WHERE classification_id IN (SELECT c_id FROM pmt_data_groups() WHERE lower(name) = lower($2));

     -- data group 
     SELECT INTO group_name name FROM pmt_data_groups() WHERE lower(name) = lower($2);
     IF group_name = '' OR group_name IS NULL THEN
       group_name := $2;
     END IF;

     -- load new xml data
     IF group_name IS NOT NULL OR group_name <> '' THEN

       INSERT INTO xml (action, xml, data_group) VALUES('insert',convert_from(pmt_bytea_import($1), 'utf-8')::xml, group_name) RETURNING project_id INTO new_project_id;     
     
       IF purge_project_ids IS NULL THEN       
         PERFORM refresh_taxonomy_lookup();
       ELSE
         IF replace_all = TRUE THEN
           FOREACH purge_id IN ARRAY purge_project_ids LOOP
             PERFORM pmt_purge_project(purge_id);
           END LOOP;
         END IF;
       END IF;     
     
       RETURN TRUE;
     ELSE
       RETURN FALSE;
     END IF;
          
EXCEPTION WHEN others THEN
    RETURN FALSE;
END; 
$$ LANGUAGE 'plpgsql';
/******************************************************************
  pmt_purge_project
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_purge_project(p_id integer) RETURNS BOOLEAN AS $$
DECLARE 
BEGIN 
     IF $1 IS NULL THEN    
       RETURN FALSE;
     END IF;
	-- Purge data
	DELETE FROM activity_contact WHERE activity_id IN (SELECT activity_id FROM activity WHERE project_id = $1);
	DELETE FROM activity_taxonomy WHERE activity_id IN (SELECT activity_id FROM activity WHERE project_id = $1);
	DELETE FROM financial_taxonomy WHERE financial_id IN (SELECT financial_id FROM financial WHERE project_id = $1);
	DELETE FROM financial WHERE project_id = $1;
	DELETE FROM participation_taxonomy WHERE participation_id IN (SELECT participation_id FROM participation WHERE project_id = $1);
	DELETE FROM project_contact WHERE project_id = $1;
	DELETE FROM project_taxonomy WHERE project_id = $1;
	DELETE FROM detail WHERE project_id = $1;
	DELETE FROM result_taxonomy WHERE result_id IN (SELECT result_id FROM result WHERE activity_id IN (SELECT activity_id FROM activity WHERE project_id = $1));
	DELETE FROM result WHERE activity_id IN (SELECT activity_id FROM activity WHERE project_id = $1);
	DELETE FROM location_taxonomy WHERE location_id IN (SELECT location_id FROM location WHERE project_id = $1);
	DELETE FROM location_boundary WHERE location_id IN (SELECT location_id FROM location WHERE project_id = $1);
	DELETE FROM activity WHERE project_id = $1;
	DELETE FROM location WHERE project_id = $1;
	DELETE FROM participation WHERE project_id = $1;
	DELETE FROM project WHERE project_id = $1;
	DELETE FROM contact_taxonomy WHERE contact_id IN (SELECT contact_id FROM contact WHERE contact_id NOT IN (SELECT DISTINCT contact_id FROM activity_contact) AND contact_id NOT IN (SELECT DISTINCT contact_id FROM project_contact));
	DELETE FROM contact WHERE contact_id NOT IN (SELECT DISTINCT contact_id FROM activity_contact) AND contact_id NOT IN (SELECT DISTINCT contact_id FROM project_contact);
	DELETE FROM organization_taxonomy WHERE organization_id IN (SELECT organization_id FROM organization WHERE organization_id NOT IN (SELECT DISTINCT organization_id FROM participation) AND organization_id NOT IN (SELECT DISTINCT organization_id FROM contact));
	DELETE FROM organization WHERE organization_id NOT IN (SELECT DISTINCT organization_id FROM participation) AND organization_id NOT IN (SELECT DISTINCT organization_id FROM contact);	
        PERFORM refresh_taxonomy_lookup();
     RETURN TRUE;

EXCEPTION
     WHEN others THEN RETURN FALSE;
END; 
$$ LANGUAGE 'plpgsql';
/******************************************************************
  pmt_users
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_users() RETURNS SETOF pmt_json_result_type AS $$
DECLARE 
  rec record;
BEGIN 
  FOR rec IN (SELECT row_to_json(j) FROM( SELECT u.user_id, u.first_name, u.last_name, u.username, u.email, u.organization_id
	, (SELECT name FROM organization WHERE organization_id = u.organization_id) as organization, u.data_group_id
	, (SELECT classification FROM taxonomy_classifications WHERE classification_id = u.data_group_id) as data_group, (
	SELECT array_to_json(array_agg(row_to_json(r))) FROM ( SELECT role_id, name FROM role WHERE role_id = ur.role_id) r ) as roles
    FROM "user" u LEFT JOIN user_role ur ON u.user_id = ur.user_id JOIN role r ON ur.role_id = r.role_id
    ) j ) LOOP		
    RETURN NEXT rec;
  END LOOP;			  
END; 
$$ LANGUAGE 'plpgsql';
/******************************************************************
  pmt_auth_user
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_auth_user(username character varying(255), password character varying(255)) RETURNS SETOF pmt_json_result_type AS $$
DECLARE 
  valid_user_id integer;
  rec record;
BEGIN 
  SELECT INTO valid_user_id "user".user_id FROM "user" WHERE "user".username = $1 AND crypt($2, "user".password) = "user".password;
  IF valid_user_id IS NOT NULL THEN
    FOR rec IN (SELECT row_to_json(j) FROM( 
	SELECT user_id, first_name, last_name, "user".username, email, "user".organization_id
	, (SELECT name FROM organization WHERE organization_id = "user".organization_id) as organization, "user".data_group_id
	, (SELECT classification FROM taxonomy_classifications WHERE classification_id = "user".data_group_id) as data_group,(
	SELECT array_to_json(array_agg(row_to_json(r))) FROM ( SELECT r.role_id, r.name FROM role r 
	JOIN user_role ur ON r.role_id = ur.role_id WHERE ur.user_id = "user".user_id) r ) as roles 
	FROM "user" WHERE "user".username = $1 AND crypt($2, "user".password) = "user".password
      ) j ) LOOP		
        RETURN NEXT rec;
    END LOOP;			  
  ELSE
    FOR rec IN (SELECT row_to_json(j) FROM( SELECT 'Invalid username or password.' AS message ) j ) LOOP		
        RETURN NEXT rec;
    END LOOP;	
  END IF;
END; 
$$ LANGUAGE 'plpgsql';
/******************************************************************
  pmt_create_user
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_create_user(organization_id integer, data_group_id integer, role_id integer, username character varying(255), password character varying(255),  email character varying(255),
first_name character varying(150), last_name character varying(150)) RETURNS BOOLEAN AS $$
DECLARE 
  valid_organization_id boolean;
  valid_data_group_id integer;
  valid_role_id integer;
  new_user_id integer;
BEGIN 
  -- check for required parameters
  IF ($1 IS NULL) OR ($2 IS NULL)  OR ($3 IS NULL) OR ($4 IS NULL OR $4 = '') OR ($5 IS NULL OR $5 = '')  OR ($6 IS NULL OR $6 = '') THEN 
    RAISE NOTICE 'Missing a required parameter (organization_id, data_group_id, role_id, username, password or email)';
    RETURN FALSE;
  ELSE 
    -- validate organization_id
    SELECT INTO valid_organization_id * FROM pmt_validate_organization($1);  
    IF NOT valid_organization_id THEN
      RAISE NOTICE 'Invalid organization_id.';
      RETURN FALSE;
    END IF;

    -- validate data_group_id
    SELECT INTO valid_data_group_id classification_id FROM taxonomy_classifications WHERE classification_id = $2 AND taxonomy = 'Data Group';
    IF valid_data_group_id IS NULL THEN
      RAISE NOTICE 'Invalid data_group_id.';
      RETURN FALSE;
    END IF;
    
    -- validate role_id
    SELECT INTO valid_role_id role.role_id FROM role WHERE role.role_id = $3;  
    IF valid_role_id IS NULL THEN
      RAISE NOTICE 'Invalid role_id.';
      RETURN FALSE;
    END IF;
    
    -- create new user
    EXECUTE 'INSERT INTO "user"(organization_id, data_group_id, first_name, last_name, username, email, password, created_by, updated_by) VALUES (' || 
	$1 || ', ' || $2 || ', ' || coalesce(quote_literal($7),'NULL') || ', ' || coalesce(quote_literal($8),'NULL') || ', ' || coalesce(quote_literal($4),'NULL') || 
	', ' || coalesce(quote_literal($6),'NULL') || ', ' || coalesce(quote_literal(crypt($5, gen_salt('bf', 10))),'NULL') || ', ' || quote_literal(current_user) || ', ' || 
	quote_literal(current_user) || ') RETURNING user_id;' INTO new_user_id; 

    IF new_user_id IS NOT NULL THEN
      EXECUTE 'INSERT INTO user_role (user_id, role_id) VALUES(' || new_user_id || ', ' || valid_role_id || ');';
    ELSE
      RAISE NOTICE 'An error occured during new user insert.';
      RETURN FALSE;
    END IF;
	
  END IF;
  RETURN TRUE;

EXCEPTION
     WHEN others THEN RETURN FALSE;  
END; 
$$ LANGUAGE 'plpgsql';
/******************************************************************
  pmt_update_user
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_update_user(user_id integer, organization_id integer, data_group_id integer, role_id integer, username character varying(255), password character varying(255),  email character varying(255),
first_name character varying(150), last_name character varying(150)) RETURNS BOOLEAN AS $$
DECLARE 
  valid_organization_id boolean;
  valid_user_id integer;
  valid_role_id integer;
  valid_data_group_id integer;
BEGIN 
  -- check for required parameters
  IF ($1 IS NULL) THEN 
    RAISE NOTICE 'Missing a required parameter (user_id)';
    RETURN FALSE;
  ELSE 
    -- validate user_id
    SELECT INTO valid_user_id "user".user_id FROM "user" WHERE "user".user_id = $1;
    IF valid_user_id IS NULL THEN
      RAISE NOTICE 'Invalid user_id.';
      RETURN FALSE;
    END IF;
    
    -- update organization_id
    IF $2 IS NOT NULL THEN
      -- validate organization_id
      SELECT INTO valid_organization_id * FROM pmt_validate_organization($2);  
      IF NOT valid_organization_id THEN
        RAISE NOTICE 'Invalid organization_id.';
        RETURN FALSE;
      ELSE
        EXECUTE 'UPDATE "user" SET organization_id = ' || $2 || ' WHERE user_id = ' || valid_user_id || ';';
      END IF;
    END IF;
    
    -- update data_group
    IF $3 IS NOT NULL THEN  
      -- validate data_group_id
      SELECT INTO valid_data_group_id classification_id FROM taxonomy_classifications WHERE classification_id = $3 AND taxonomy = 'Data Group';
      IF valid_data_group_id IS NULL THEN
        RAISE NOTICE 'Invalid data_group_id.';
        RETURN FALSE;
      ELSE
        EXECUTE 'UPDATE "user" SET data_group_id = ' || $3 || ' WHERE user_id = ' || valid_user_id || ';';
      END IF;        
    END IF;

    -- update role
    IF $4 IS NOT NULL THEN 
      -- validate role_id
      SELECT INTO valid_role_id role.role_id FROM role WHERE role.role_id = $4;  
      IF valid_role_id IS NULL THEN
        RAISE NOTICE 'Invalid role_id.';
        RETURN FALSE;
      ELSE
        EXECUTE 'UPDATE "user_role" SET role_id = ' || $4 || ' WHERE user_id = ' || valid_user_id || ';';
      END IF;         
    END IF;
    
    -- update username
    IF $5 IS NOT NULL AND $5 <> '' THEN    
      EXECUTE 'UPDATE "user" SET username = ' || coalesce(quote_literal($5),'NULL') || ' WHERE user_id = ' || valid_user_id || ';';
    END IF;
    
    -- update password
    IF $6 IS NOT NULL AND $6 <> '' THEN    
      EXECUTE 'UPDATE "user" SET password = ' || coalesce(quote_literal(crypt($6, gen_salt('bf', 10))),'NULL') || ' WHERE user_id = ' || valid_user_id || ';';
    END IF;
    
    -- update email
    IF $7 IS NOT NULL AND $7 <> '' THEN    
      EXECUTE 'UPDATE "user" SET email = ' || coalesce(quote_literal($7),'NULL') || ' WHERE user_id = ' || valid_user_id || ';';
    END IF;
    
    -- update first name
    IF $8 IS NOT NULL AND $8 <> '' THEN    
      EXECUTE 'UPDATE "user" SET first_name = ' || coalesce(quote_literal($8),'NULL') || ' WHERE user_id = ' || valid_user_id || ';';
    END IF;
    
    -- update last name
    IF $9 IS NOT NULL AND $9 <> '' THEN    
      EXECUTE 'UPDATE "user" SET last_name = ' || coalesce(quote_literal($9),'NULL') || ' WHERE user_id = ' || valid_user_id || ';';
    END IF;    
    
  END IF;
  RETURN TRUE;
  
EXCEPTION
     WHEN others THEN RETURN FALSE;  
END; 
$$ LANGUAGE 'plpgsql';
/******************************************************************
  pmt_user_auth
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_user_auth(username character varying(255), password character varying(255)) RETURNS 
SETOF pmt_json_result_type AS $$
DECLARE 
  valid_user_id integer;
  authorization_source pmt_auth_source;
  valid_data_group_id integer;
  user_organization_id integer;
  user_data_group_id integer;  
  authorized_project_ids integer[];
  role_super boolean;	
  rec record;
BEGIN 
  SELECT INTO valid_user_id "user".user_id FROM "user" WHERE "user".username = $1 AND "user".password = $2;
  IF valid_user_id IS NOT NULL THEN
    -- determine editing authorization source
    SELECT INTO authorization_source edit_auth_source from config LIMIT 1;	
    CASE authorization_source
       -- authorization determined by organization affiliation
        WHEN 'organization' THEN
         -- get users organization_id
         SELECT INTO user_organization_id organization_id FROM "user" WHERE "user".user_id = valid_user_id;   
	 -- validate users organization_id	
         IF (SELECT * FROM pmt_validate_organization(user_organization_id)) THEN
           -- get list of project_ids user has authority to edit
           SELECT INTO authorized_project_ids array_agg(DISTINCT p.project_id)::int[] FROM participation_taxonomy pt JOIN participation p ON pt.participation_id = p.participation_id
           WHERE p.organization_id = user_organization_id AND pt.classification_id IN (SELECT classification_id FROM taxonomy_classifications WHERE taxonomy = 'Organisation Role' and classification = 'Accountable');
         END IF;
       -- authorization determined by data group affiliation
       WHEN 'data_group' THEN
         -- get users data_group_id
         SELECT INTO user_data_group_id data_group_id FROM "user" WHERE "user".user_id = valid_user_id;  
         -- validate users data_group_id
	 SELECT INTO valid_data_group_id classification_id::integer FROM taxonomy_classifications WHERE classification_id = user_data_group_id AND taxonomy = 'Data Group';
	 IF (valid_data_group_id IS NOT NULL) THEN
           -- get list of project_ids user has authority to edit
           SELECT INTO authorized_project_ids array_agg(DISTINCT pt.project_id)::int[] FROM project_taxonomy pt 
           WHERE pt.classification_id IN (SELECT classification_id FROM taxonomy_classifications WHERE taxonomy = 'Data Group' and classification_id = user_data_group_id);          
         END IF;
       ELSE
    END CASE;

    -- check to see if user has a role with "SUPER" rights (if so they have full adminsitrative editing rights to the database)
    SELECT INTO role_super super FROM role WHERE role_id = (SELECT role_id FROM user_role WHERE user_role.user_id = valid_user_id);
    IF role_super THEN
      -- if super user than all project ids are authorized
      SELECT INTO authorized_project_ids array_agg(DISTINCT p.project_id)::int[] FROM project p;
    END IF;
    
    FOR rec IN (SELECT row_to_json(j) FROM( 
	SELECT user_id, first_name, last_name, "user".username, email, "user".organization_id
	,(SELECT name FROM organization WHERE organization_id = "user".organization_id) as organization, "user".data_group_id
	,(SELECT classification FROM taxonomy_classifications WHERE classification_id = "user".data_group_id) as data_group
	,array_to_string(authorized_project_ids, ',') as authorized_project_ids
	,(SELECT array_to_json(array_agg(row_to_json(r))) FROM ( SELECT r.role_id, r.name FROM role r 
	JOIN user_role ur ON r.role_id = ur.role_id WHERE ur.user_id = "user".user_id) r ) as roles 
	FROM "user" WHERE "user".user_id = valid_user_id
      ) j ) LOOP		
        RETURN NEXT rec;
    END LOOP;
    -- log user activity
    INSERT INTO user_activity(user_id, username, status) VALUES (valid_user_id, $1, 'success');		  
  ELSE
    FOR rec IN (SELECT row_to_json(j) FROM( SELECT 'Invalid username or password.' AS message ) j ) LOOP		
        RETURN NEXT rec;
    END LOOP;	
    -- log user activity
    INSERT INTO user_activity(username, status) VALUES ($1, 'fail');		  
  END IF;
END; 
$$ LANGUAGE 'plpgsql';
/******************************************************************
  pmt_user_salt
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_user_salt(id integer) RETURNS text AS $$
DECLARE 
  salt text;
BEGIN 
  SELECT INTO salt substring(password from 1 for 29) from "user" where user_id = $1;
  RETURN salt;
END; 
$$ LANGUAGE 'plpgsql';
/******************************************************************
  pmt_stat_orgs_by_district
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_stat_orgs_by_district(data_group_id integer, country character varying, region character varying, org_role_id integer, top_limit integer)
RETURNS SETOF pmt_json_result_type AS $$
DECLARE
  limit_by integer;
  org_c_id integer;
  valid_data_group_id integer;
  execute_statement text;
  rec record;
BEGIN
-- country & region is required
IF ($2 IS NOT NULL AND $2 <> '') AND ($3 IS NOT NULL AND $3 <> '') THEN

   -- validate data group id
   IF $1 IS NOT NULL THEN
	SELECT INTO valid_data_group_id classification_id FROM taxonomy_classifications WHERE taxonomy = 'Data Group' AND classification_id = $1;
   END IF;
   
   -- set default organization role classification to 'Accountable'  
   IF $4 IS NULL THEN
     org_c_id := (select classification_id from taxonomy_classifications where taxonomy = 'Organisation Role' and classification = 'Accountable');
   -- validate classification_id
   ELSE
     select into org_c_id classification_id from taxonomy_classifications where taxonomy = 'Organisation Role' and classification_id = $4;
     IF org_c_id IS NULL THEN
       org_c_id := (select classification_id from taxonomy_classifications where taxonomy = 'Organisation Role' and classification = 'Accountable');
     END IF;
   END IF;

   -- set default limit to 3
   IF $5 IS NULL OR $5 < 1 THEN
     limit_by := 3;
   ELSE
     limit_by := $5;
   END IF;
   
   execute_statement :=  'select row_to_json(j) from (select gaul1_name as region, name as district,(SELECT array_to_json(array_agg(row_to_json(b))) FROM ( ' ||
				'select ol.organization_id as o_id, o.name, count(l.activity_id) as a_ct ' ||
				'from organization_lookup ol ' ||
				'join ' ||
				'(select distinct activity_id, gaul1_name, gaul2_name  ' ||
				'from location_lookup where lower(gaul1_name) = trim(lower('|| quote_literal($3) ||')) and lower(gaul0_name) = trim(lower('|| quote_literal($2) ||'))';

  IF valid_data_group_id IS NOT NULL THEN
    execute_statement :=  execute_statement || ' AND classification_ids @> ARRAY[' || valid_data_group_id || '] ';
  END IF;

  execute_statement :=  execute_statement || ') as l ' ||
				'on ol.activity_id = l.activity_id ' ||
				'join organization o ' ||
				'on ol.organization_id = o.organization_id ' ||
				'where ol.classification_ids @> ARRAY[' || org_c_id || '] ' ||
				'and l.gaul2_name = g.name ' ||
				'group by ol.organization_id, o.name ' ||
				'order by a_ct desc ' ||
				'limit ' || limit_by ||
				') b) as orgs  ' ||
			'from gaul2 g ' ||
			'where lower(gaul1_name) = trim(lower('|| quote_literal($3) ||')) and lower(gaul0_name) = trim(lower('|| quote_literal($2) ||')) order by name) j';

   RAISE NOTICE 'Execute statement: %', execute_statement;
   FOR rec IN EXECUTE execute_statement LOOP
     RETURN NEXT rec; 
   END LOOP;   
END IF;   
END;$$ LANGUAGE plpgsql;
/******************************************************************
  pmt_stat_activity_by_district
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_stat_activity_by_district(data_group_id integer, country character varying, region character varying, activity_taxonomy_id integer)
RETURNS SETOF pmt_json_result_type AS $$
DECLARE
  valid_data_group_id integer;
  is_valid_taxonomy boolean;
  execute_statement text;
  rec record;
BEGIN
-- country, region and activity_taxonomy_id are required
IF ($2 IS NOT NULL AND $2 <> '') AND ($3 IS NOT NULL AND $3 <> '') AND ($4 IS NOT NULL) THEN
   -- validate data group id
   IF $1 IS NOT NULL THEN
	SELECT INTO valid_data_group_id classification_id FROM taxonomy_classifications WHERE taxonomy = 'Data Group' AND classification_id = $1;
   END IF;
  -- validate taxonomy id
  select into is_valid_taxonomy * from pmt_validate_taxonomy($4);
  -- must have valid taxonomy id
  IF is_valid_taxonomy THEN	

    execute_statement :=  'select row_to_json(j) from (select gaul1_name as region, name as district,(SELECT array_to_json(array_agg(row_to_json(b))) FROM ( ' ||
				'select tl.classification_id as c_id, c.name, count(distinct tl.activity_id) as a_ct ' ||
				'from taxonomy_lookup tl ' ||
				'join ' ||
				'(select distinct activity_id, gaul1_name, gaul2_name  ' ||
				'from location_lookup where lower(gaul1_name) = trim(lower('|| quote_literal($3) ||')) and lower(gaul0_name) = trim(lower('|| quote_literal($2) ||')) ';

  IF valid_data_group_id IS NOT NULL THEN
    execute_statement :=  execute_statement || ' AND classification_ids @> ARRAY[' || valid_data_group_id || '] ';
  END IF;

  execute_statement :=  execute_statement || ') as l ' ||
				'on tl.activity_id = l.activity_id ' ||
				'join classification c ' ||
				'on tl.classification_id = c.classification_id ' ||
				'where tl.taxonomy_id = ' || $4 ||
				'and l.gaul2_name = g.name ' ||
				'group by tl.classification_id, c.name ' ||
				'order by a_ct desc ' ||
				') b) as activities   ' ||
			'from gaul2 g ' ||
			'where lower(gaul1_name) = trim(lower('|| quote_literal($3) ||')) and lower(gaul0_name) = trim(lower('|| quote_literal($2) ||')) order by name) j';

     RAISE NOTICE 'Execute statement: %', execute_statement;
     FOR rec IN EXECUTE execute_statement LOOP
       RETURN NEXT rec; 
     END LOOP;   
   END IF;
END IF;   
END;$$ LANGUAGE plpgsql;
/******************************************************************
  pmt_stat_pop_by_district
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_stat_pop_by_district(country character varying, region character varying) RETURNS SETOF pmt_json_result_type AS $$
DECLARE
  valid_data_group_id integer;
  execute_statement text;
  rec record;
BEGIN
-- country & region are required
IF ($1 IS NOT NULL AND $1 <> '') AND ($2 IS NOT NULL AND $2 <> '') THEN
   
   execute_statement :=  'select row_to_json(j) from (select gaul1_name as region, name as district, pop_total, pop_poverty, pop_rural, pop_poverty_rural, pop_source ' ||
				'from gaul2 ' ||
				'where lower(gaul0_name) = trim(lower('|| quote_literal($1) ||')) and lower(gaul1_name) = trim(lower('|| quote_literal($2) ||')) order by name) j';

   RAISE NOTICE 'Execute statement: %', execute_statement;
   FOR rec IN EXECUTE execute_statement LOOP
     RETURN NEXT rec; 
   END LOOP;   
END IF;   
END;$$ LANGUAGE plpgsql;
/******************************************************************
   pmt_sector_compare
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_sector_compare(classification_ids character varying, order_by character varying) RETURNS SETOF pmt_json_result_type AS 
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
/******************************************************************
   pmt_edit_activity_taxonomy
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_edit_activity_taxonomy(activity_ids character varying, classification_id integer, edit_action pmt_edit_action) RETURNS BOOLEAN AS 
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
/******************************************************************
  pmt_locations_by_polygon
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_locations_by_polygon(wktPolygon text) RETURNS SETOF pmt_json_result_type AS $$
DECLARE
  wkt text;
  rec record;
BEGIN  
  -- validate the incoming WKT is a polygon and that it is all uppercase
  IF (upper(substring(trim($1) from 1 for 7)) = 'POLYGON') THEN
    RAISE NOTICE 'WKT: %', $1;
    wkt := replace(lower(trim($1)), 'polygon', 'POLYGON');    
    RAISE NOTICE 'WKT Fixed: %', wkt;  

    FOR rec IN (
    SELECT row_to_json(j)
    FROM(	
	SELECT sel.title, sel.location_ct, sel.avg_km,
		(SELECT array_to_json(array_agg(row_to_json(c))) FROM (
			SELECT location_id, lat_dd, long_dd,
				(SELECT array_to_json(array_agg(row_to_json(t))) FROM (
					SELECT DISTINCT tc.taxonomy_id, tc.taxonomy, tc.classification_id, tc.classification
					FROM taxonomy_lookup tl
					JOIN taxonomy_classifications tc
					ON tl.classification_id = tc.classification_id
					WHERE location_id = l.location_id
					AND tc.taxonomy <> 'Organisation Role'
				) t) as taxonomy,
				(SELECT array_to_json(array_agg(row_to_json(t))) FROM (
					SELECT DISTINCT o.organization_id, o.name, tc.taxonomy_id, tc.taxonomy, tc.classification_id, tc.classification
					FROM taxonomy_lookup tl
					JOIN taxonomy_classifications tc
					ON tl.classification_id = tc.classification_id
					JOIN organization o
					ON tl.organization_id = o.organization_id
					WHERE location_id = l.location_id
					AND tc.taxonomy = 'Organisation Role'
				) t) as organizations
			FROM location l
			WHERE location_id = ANY(sel.location_ids)
		) c) as locations
	FROM(
		SELECT calc.activity_id 
			,(SELECT title FROM activity a WHERE a.activity_id = calc.activity_id) AS title 
			,count(location_id) AS location_ct
			,array_agg(location_id) AS location_ids
			,round(avg(dist_km)) AS avg_km 
		FROM(
			SELECT location_id, activity_id, round(CAST(
				ST_Distance_Spheroid(ST_Centroid(ST_GeomFromText(wkt, 4326)), point, 'SPHEROID["WGS 84",6378137,298.257223563]') As numeric),2)*.001 As dist_km
			FROM location
			WHERE ST_Contains(ST_GeomFromText(wkt, 4326), point)
			AND active = true
		) as calc
		GROUP BY calc.activity_id
	) as sel 
     ) j
    ) LOOP		
      RETURN NEXT rec;
    END LOOP;	
      
  ELSE
    FOR rec IN (SELECT row_to_json(j) FROM (SELECT 'WKT must be of type POLYGON' as error) j ) LOOP		
      RETURN NEXT rec;
    END LOOP;	
  END IF;	
END;$$ LANGUAGE plpgsql;
/******************************************************************
   pmt_contacts
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_contacts() RETURNS SETOF pmt_json_result_type AS $$
DECLARE
  rec record;
BEGIN	
  
  FOR rec IN ( SELECT row_to_json(j) FROM ( 
    SELECT c.contact_id as c_id, first_name, last_name, email, organization_id as o_id,
	(SELECT name FROM organization where organization_id = c.organization_id) as org
    FROM contact c
    ORDER BY last_name, first_name) j
  ) LOOP		
	RETURN NEXT rec;
  END LOOP;	  
END;$$ LANGUAGE plpgsql;
/******************************************************************
   pmt_orgs
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_orgs() RETURNS SETOF pmt_json_result_type AS $$
DECLARE
  rec record;
BEGIN	
  
  FOR rec IN ( SELECT row_to_json(j) FROM ( 
    SELECT organization_id as o_id, name
    FROM organization
    ORDER BY name) j
  ) LOOP		
	RETURN NEXT rec;
  END LOOP;	  
END;$$ LANGUAGE plpgsql;
/******************************************************************
  pmt_validate_user_authority
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_validate_user_authority(user_id integer, project_id integer, auth_type pmt_auth_crud) RETURNS boolean AS $$
DECLARE 
	user_organization_id integer;
	user_data_group_id integer;
	valid_data_group_id integer;
	authorized_project_ids integer[];
	authorized_project_id boolean;
	authorization_source pmt_auth_source;	
	role_crud boolean;
BEGIN 
     -- user and authorization type parameters are required
     IF $1 IS NULL  OR $3 IS NULL THEN    
       RAISE NOTICE 'Missing required parameters';
       RETURN FALSE;
     END IF;    

     -- check to see if user has a role with "SUPER" rights (if so they have full adminsitrative editing rights to the database)
     SELECT INTO role_crud super FROM role WHERE role_id = (SELECT role_id FROM user_role WHERE user_role.user_id = $1);

     IF role_crud THEN
       RAISE NOTICE 'User is a Super User';
       RETURN TRUE;
     END IF;

     -- get users authorization type based on their role
     CASE auth_type
	WHEN 'create' THEN
	  SELECT INTO role_crud "create" FROM role WHERE role_id = (SELECT role_id FROM user_role WHERE user_role.user_id = $1);	    
	WHEN 'read' THEN
	  SELECT INTO role_crud "read" FROM role WHERE role_id = (SELECT role_id FROM user_role WHERE user_role.user_id = $1);
	WHEN 'update' THEN
	  SELECT INTO role_crud "update" FROM role WHERE role_id = (SELECT role_id FROM user_role WHERE user_role.user_id = $1);
  	WHEN 'delete' THEN
	  SELECT INTO role_crud "delete" FROM role WHERE role_id = (SELECT role_id FROM user_role WHERE user_role.user_id = $1);
	ELSE
	  RETURN FALSE;
     END CASE;       

     -- If there is no project_id provided then validate based on users authorization type (CRUD)
     IF $2 IS NULL THEN       
       IF role_crud THEN
	 RETURN TRUE;
       ELSE
	 RETURN FALSE;
       END IF;
     END IF;
     
     -- determine editing authorization source
     SELECT INTO authorization_source edit_auth_source from config LIMIT 1;

     CASE authorization_source
       -- authorization determined by organization affiliation
       WHEN 'organization' THEN
         -- get users organization_id
         SELECT INTO user_organization_id organization_id FROM "user" WHERE "user".user_id = $1;   
	 -- validate users organization_id	
         IF (SELECT * FROM pmt_validate_organization(user_organization_id)) THEN
           RAISE NOTICE 'Organization id is valid: %', user_organization_id;
           -- get list of project_ids user has authority to edit
           SELECT INTO authorized_project_ids array_agg(DISTINCT p.project_id)::int[] FROM participation_taxonomy pt JOIN participation p ON pt.participation_id = p.participation_id
           WHERE p.organization_id = user_organization_id AND pt.classification_id IN (SELECT classification_id FROM taxonomy_classifications WHERE taxonomy = 'Organisation Role' and classification = 'Accountable');
           RAISE NOTICE 'Authorized project_ids: %', authorized_project_ids;
	 ELSE
	   RAISE NOTICE 'Organization id for user is NOT valid.';
	   RETURN FALSE;
         END IF;
       -- authorization determined by data group affiliation
       WHEN 'data_group' THEN
         -- get users data_group_id
         SELECT INTO user_data_group_id data_group_id FROM "user" WHERE "user".user_id = $1;  
         -- validate users data_group_id
	 SELECT INTO valid_data_group_id classification_id::integer FROM taxonomy_classifications WHERE classification_id = user_data_group_id AND taxonomy = 'Data Group';
	 IF (valid_data_group_id IS NOT NULL) THEN
           RAISE NOTICE 'Data Group id is valid: %', user_data_group_id;
           -- get list of project_ids user has authority to edit
           SELECT INTO authorized_project_ids array_agg(DISTINCT pt.project_id)::int[] FROM project_taxonomy pt 
           WHERE pt.classification_id IN (SELECT classification_id FROM taxonomy_classifications WHERE taxonomy = 'Data Group' and classification_id = user_data_group_id);          
           RAISE NOTICE 'Authorized project_ids: %', authorized_project_ids;
	 ELSE
	   RAISE NOTICE 'Data Group id for user is NOT valid.';
	   RETURN FALSE;
         END IF;
       ELSE
     END CASE;             

     IF authorized_project_ids IS NOT NULL THEN
       -- the requested project is in the list of authorized projects
       IF ($2 = ANY(authorized_project_ids)) THEN        
         RAISE NOTICE 'Project id (%) in authorized projects.', $2;
         -- determine if the authorization type is allowed by user role
         IF role_crud THEN
	   RETURN TRUE;
         ELSE
           RAISE NOTICE 'User does not have request authorization type: %', $3;
	   RETURN FALSE;
         END IF;
       ELSE
         RAISE NOTICE 'Project id (%) NOT in authorized projects.', $2;
	 RETURN FALSE;
       END IF;
     ELSE
        RAISE NOTICE 'There are NO authorized projects';
	RETURN FALSE;
     END IF;
    
EXCEPTION WHEN others THEN
    RETURN FALSE;
END; 
$$ LANGUAGE 'plpgsql';
/******************************************************************
   pmt_edit_activity
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_edit_activity(user_id integer, activity_id integer, project_id integer, key_value_data json, delete_record boolean default false) RETURNS SETOF pmt_json_result_type AS 
$$
DECLARE
  new_activity_id integer;
  p_id integer;
  a_id integer;
  json record;
  column_record record;
  execute_statement text;
  invalid_editing_columns text[];
  delete_response json;
  user_name text;
  rec record;
  error_msg1 text;
  error_msg2 text;
  error_msg3 text;
BEGIN	
  -- set columns that are not editable via the parameters 
  invalid_editing_columns := ARRAY['activity_id','project_id', 'active', 'retired_by', 'created_by', 'created_date', 'updated_by', 'updated_date'];
  
  -- user_id is required for all operations
  IF ($1 IS NOT NULL) THEN
    -- update/create operation
    IF NOT ($5) THEN
      -- json is required
      IF ($4 IS NULL) THEN
        FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: The json parameter is required for a create/update operation.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
      END IF;
      -- project_id is required if activity_id is null
      IF ($2 IS NULL) AND ($3 IS NULL) THEN
        FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: project_id is required for a create operation.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
      END IF;
    -- delete operation	
    ELSE
      -- activity_id is requried
      IF ($2 IS NULL) THEN
        FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: activity_id is required for a delete operation.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
      END IF;
    END IF;
  -- error if user_id    
  ELSE
    FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: user_id is a required parameter for all operations.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
  END IF; 

  -- get users name
  SELECT INTO user_name username FROM "user" WHERE "user".user_id = $1;

  -- if activity_id is null then validate users authroity to create a new activity record  
  IF ($2 IS NULL) THEN
    -- validate project_id
    IF (SELECT * FROM pmt_validate_project($3)) THEN       
      IF (SELECT * FROM pmt_validate_user_authority($1, $3, 'create')) THEN
        EXECUTE 'INSERT INTO activity(project_id, created_by, updated_by) VALUES (' || $3 || ',' || quote_literal(user_name) || ',' || quote_literal(user_name) || ') RETURNING activity_id;' INTO new_activity_id;
        RAISE NOTICE 'Created new activity with id: %', new_activity_id;
      ELSE
        FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: User does NOT have authority to create a new activity for project_id: ' || $3 as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
      END IF;
    ELSE
      FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: project_id is not valid.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
    END IF;
  -- validate activity_id if provided and validate users authority to update an existing record  
  ELSE
    -- get project_id for activity
    SELECT INTO p_id activity.project_id FROM activity WHERE activity.activity_id = $2;      
    -- validate activity_id
    IF (SELECT * FROM pmt_validate_activity($2)) THEN 
      -- validate users authority to 'delete' this activity
      IF ($5) THEN
        IF (SELECT * FROM pmt_validate_user_authority($1, p_id, 'delete')) THEN
        -- deactivate this activity          
          FOR rec IN (SELECT * FROM pmt_activate_activity($1, $2, false)) LOOP  RETURN NEXT rec; END LOOP; RETURN;
        ELSE
          FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: User does NOT have authority to delete this activity.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
        END IF;
      -- validate users authority to 'update' this activity
      ELSE        
        IF (SELECT * FROM pmt_validate_user_authority($1, p_id, 'update')) THEN   
        ELSE
          FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: User does NOT have authority to update this activity.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
        END IF;
      END IF;
    ELSE
      FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: Invalid activity_id.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
    END IF;
  END IF;

  -- assign the activity_id to use in statements
  IF new_activity_id IS NOT NULL THEN
    a_id := new_activity_id;
  ELSE
    a_id := $2;
  END IF;
    
  -- loop through the columns of the activity table        
  FOR json IN (SELECT * FROM json_each_text($4)) LOOP
    RAISE NOTICE 'JSON key/value: %', lower(json.key) || ':' || json.value;
    -- get the column information for column that user is requesting to edit	
    FOR column_record IN (SELECT * FROM information_schema.columns WHERE table_schema='public' AND table_name='activity' AND column_name != ALL(invalid_editing_columns) AND lower(column_name) = lower(json.key)) LOOP 
      RAISE NOTICE 'Editing column: %', column_record.column_name;
      RAISE NOTICE 'Assigning new value: %', json.value;
      execute_statement := null;
      CASE column_record.data_type 
        WHEN 'integer', 'numeric' THEN              
          IF (SELECT pmt_isnumeric(json.value)) THEN
            execute_statement := 'UPDATE activity SET ' || column_record.column_name || ' = ' || json.value || ' WHERE activity_id = ' || a_id; 
          END IF;
          IF (lower(json.value) = 'null') THEN
            execute_statement := 'UPDATE activity SET ' || column_record.column_name || ' = null WHERE activity_id = ' || a_id; 
          END IF;
        ELSE
          -- if the value has the text null then assign the column value null
          IF (lower(json.value) = 'null') THEN
            execute_statement := 'UPDATE activity SET ' || column_record.column_name || ' = null WHERE activity_id = ' || a_id; 
          ELSE
            execute_statement := 'UPDATE activity SET ' || column_record.column_name || ' = ' || quote_literal(json.value) || ' WHERE activity_id = ' || a_id; 
          END IF;
      END CASE;
      IF execute_statement IS NOT NULL THEN
        RAISE NOTICE 'Statement: %', execute_statement;
        EXECUTE execute_statement;
                
        EXECUTE 'UPDATE activity SET updated_by = ' || quote_literal(user_name) || ', updated_date = ' || quote_literal(current_date) || ' WHERE  activity_id = ' || a_id;
      END IF;
    END LOOP;
  END LOOP;
  -- editing completed successfullly
  FOR rec IN (SELECT row_to_json(j) FROM(select a_id as id, 'Success' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;         
  
EXCEPTION WHEN others THEN
     GET STACKED DIAGNOSTICS error_msg1 = MESSAGE_TEXT,
                          error_msg2 = PG_EXCEPTION_DETAIL,
                          error_msg3 = PG_EXCEPTION_HINT;
    FOR rec IN (SELECT row_to_json(j) FROM(select a_id as id, 'Internal Error - Contact your DBA with the following error message: ' || error_msg1 as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;	  
END;$$ LANGUAGE plpgsql;
/******************************************************************
  pmt_activate_activity
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_activate_activity(user_id integer, activity_id integer, activate boolean default true) RETURNS SETOF pmt_json_result_type AS  $$
DECLARE
  p_id integer;
  user_name text;
  rec record;
  error_msg1 text;
  error_msg2 text;
  error_msg3 text; 
BEGIN 
  -- user and activity_id parameters are required
  IF ($1 IS NOT NULL) AND ($2 IS NOT NULL) THEN
    -- get users name
    SELECT INTO user_name username FROM "user" WHERE "user".user_id = $1;
  ELSE
    FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: Must included user_id and activity_id data parameters.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
  END IF; 

  -- get project_id for activity
  SELECT INTO p_id project_id FROM activity WHERE activity.activity_id = $2;   

  -- validate activity_id
  IF p_id IS NOT NULL THEN  
    -- user must have 'delete' privilages to change active values
    IF (SELECT * FROM pmt_validate_user_authority($1, p_id, 'delete')) THEN
      -- set active values as requested       
      EXECUTE 'UPDATE activity SET active = ' || $3 || ', updated_by =' || quote_literal(user_name) || ', updated_date = ' || quote_literal(current_date) || ' WHERE activity.activity_id = ' || $2 || ';';
      EXECUTE 'UPDATE location SET active = ' || $3 || ', updated_by =' || quote_literal(user_name) || ', updated_date = ' || quote_literal(current_date) || ' WHERE location.activity_id = ' || $2 || ';';
      EXECUTE 'UPDATE financial SET active = ' || $3 || ', updated_by =' || quote_literal(user_name) || ', updated_date = ' || quote_literal(current_date) || ' WHERE financial.activity_id = ' || $2 || ';';
      EXECUTE 'UPDATE participation SET active = ' || $3 || ', updated_by =' || quote_literal(user_name) || ', updated_date = ' || quote_literal(current_date) || ' WHERE participation.activity_id = ' || $2 || ';';
      EXECUTE 'UPDATE detail SET active = ' || $3 || ', updated_by =' || quote_literal(user_name) || ', updated_date = ' || quote_literal(current_date) || ' WHERE detail.activity_id = ' || $2 || ';';
      EXECUTE 'UPDATE result SET active = ' || $3 || ', updated_by =' || quote_literal(user_name) || ', updated_date = ' || quote_literal(current_date) || ' WHERE result.activity_id = ' || $2 || ';';
    ELSE
      FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: User does NOT have authority to change the active status of this activity and its assoicated records.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
    END IF;
  ELSE
    FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: Invalid activity_id.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
  END IF;

   -- editing completed successfullly
  FOR rec IN (SELECT row_to_json(j) FROM(select $2 as id, 'Success' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;        
    	  
EXCEPTION WHEN others THEN
      GET STACKED DIAGNOSTICS error_msg1 = MESSAGE_TEXT,
                          error_msg2 = PG_EXCEPTION_DETAIL,
                          error_msg3 = PG_EXCEPTION_HINT;
    FOR rec IN (SELECT row_to_json(j) FROM(select $2 as id, 'Internal Error - Contact your DBA with the following error message: ' || error_msg1 as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;	 
END; 
$$ LANGUAGE 'plpgsql';
/******************************************************************
  pmt_activate_project
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_activate_project(user_id integer, project_id integer, activate boolean default true) RETURNS SETOF pmt_json_result_type AS  $$
DECLARE
  p_id integer;
  user_name text;
  rec record;
  error_msg1 text;
  error_msg2 text;
  error_msg3 text; 
BEGIN 
  -- user and activity_id parameters are required
  IF ($1 IS NOT NULL) AND ($2 IS NOT NULL) THEN
    -- get users name
    SELECT INTO user_name username FROM "user" WHERE "user".user_id = $1;
  ELSE
    FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: Must included user_id and project_id data parameters.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
  END IF; 

  -- user must have 'delete' privilages to change active values
  IF (SELECT * FROM pmt_validate_user_authority($1, p_id, 'delete')) THEN
    -- set active values as requested       
    EXECUTE 'UPDATE project SET active = ' || $3 || ', updated_by =' || quote_literal(user_name) || ', updated_date = ' || quote_literal(current_date) || ' WHERE project.project_id = ' || $2 || ';';
    EXECUTE 'UPDATE activity SET active = ' || $3 || ', updated_by =' || quote_literal(user_name) || ', updated_date = ' || quote_literal(current_date) || ' WHERE activity.project_id = ' || $2 || ';';
    EXECUTE 'UPDATE location SET active = ' || $3 || ', updated_by =' || quote_literal(user_name) || ', updated_date = ' || quote_literal(current_date) || ' WHERE location.project_id = ' || $2 || ';';
    EXECUTE 'UPDATE financial SET active = ' || $3 || ', updated_by =' || quote_literal(user_name) || ', updated_date = ' || quote_literal(current_date) || ' WHERE financial.project_id = ' || $2 || ';';
    EXECUTE 'UPDATE participation SET active = ' || $3 || ', updated_by =' || quote_literal(user_name) || ', updated_date = ' || quote_literal(current_date) || ' WHERE participation.project_id = ' || $2 || ';';
    EXECUTE 'UPDATE detail SET active = ' || $3 || ', updated_by =' || quote_literal(user_name) || ', updated_date = ' || quote_literal(current_date) || ' WHERE detail.project_id = ' || $2 || ';';    
  ELSE
    FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: User does NOT have authority to change the active status of this project and its assoicated records.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
  END IF;

   -- editing completed successfullly
  FOR rec IN (SELECT row_to_json(j) FROM(select $2 as id, 'Success' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;        
    	  
EXCEPTION WHEN others THEN
      GET STACKED DIAGNOSTICS error_msg1 = MESSAGE_TEXT,
                          error_msg2 = PG_EXCEPTION_DETAIL,
                          error_msg3 = PG_EXCEPTION_HINT;
    FOR rec IN (SELECT row_to_json(j) FROM(select $2 as id, 'Internal Error - Contact your DBA with the following error message: ' || error_msg1 as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;	 
END;
$$ LANGUAGE 'plpgsql';
/******************************************************************
  pmt_validate_contact
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_validate_contact(id integer) RETURNS boolean AS $$
DECLARE valid_id integer;
BEGIN 
     IF $1 IS NULL THEN    
       RETURN false;
     END IF;    
     
     SELECT INTO valid_id contact_id FROM contact WHERE active = true AND contact_id = $1;	 

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
  pmt_validate_contacts
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_validate_contacts(contact_ids character varying) RETURNS INT[] AS $$
DECLARE 
  valid_contact_ids INT[];
  filter_contact_ids INT[];
BEGIN 
     IF $1 IS NULL THEN    
       RETURN valid_contact_ids;
     END IF;

     filter_contact_ids := string_to_array($1, ',')::int[];
     
     SELECT INTO valid_contact_ids array_agg(DISTINCT contact_id)::INT[] FROM (SELECT contact_id FROM contact WHERE active = true AND contact_id = ANY(filter_contact_ids) ORDER BY contact_id) AS t;
     
     RETURN valid_contact_ids;

EXCEPTION
     WHEN others THEN RETURN NULL;
END; 
$$ LANGUAGE 'plpgsql';
/******************************************************************
   pmt_edit_activity_contact
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_edit_activity_contact(user_id integer, activity_id integer, contact_id integer, edit_action pmt_edit_action) RETURNS BOOLEAN AS 
$$
DECLARE
  p_id integer;
  record_id integer;
BEGIN	
  -- first three parameters are required 
  IF ($1 IS NOT NULL) AND ($2 IS NOT NULL) AND ($3 IS NOT NULL) THEN
    -- validate activity_id & contact_id
    IF (SELECT * FROM pmt_validate_activity($2)) AND (SELECT * FROM pmt_validate_contact($3)) THEN
      -- get project_id for activity
      SELECT INTO p_id project_id FROM activity WHERE activity.activity_id = $2;
      
      -- operations based on the requested edit action
      CASE $4
        WHEN 'delete' THEN
          -- validate users authority to perform an update action on this project
          IF (SELECT * FROM pmt_validate_user_authority($1, p_id, 'update')) THEN          
            EXECUTE 'DELETE FROM activity_contact WHERE activity_id ='|| $2 ||' AND contact_id = '|| $3; 
            RAISE NOTICE 'Delete Record: %', 'Remove association to contact_id ('|| $3 ||') for actvity_id ('|| $2 ||')';
          ELSE
            RAISE NOTICE 'Error: The requested edit action requires the user to have UPDATE rights to this project: %', p_id;
	    RETURN FALSE;
          END IF;           
        WHEN 'replace' THEN            
           -- validate users authority to perform an update and create action on this project
          IF (SELECT * FROM pmt_validate_user_authority($1, p_id, 'update')) AND (SELECT * FROM pmt_validate_user_authority($1, p_id, 'create')) THEN          
            EXECUTE 'DELETE FROM activity_contact WHERE activity_id ='|| $2;
            RAISE NOTICE 'Delete Record: %', 'Removed all contacts for actvity_id ('|| $2 ||')';
	    EXECUTE 'INSERT INTO activity_contact(activity_id, contact_id) VALUES ('|| $2 ||', '|| $3 ||')';
            RAISE NOTICE 'Add Record: %', 'Activity_id ('|| $2 ||') is now associated to contact_id ('|| $3 ||').'; 
          ELSE
            RAISE NOTICE 'Error: The requested edit action requires the user to have UPDATE and CREATE rights to this project: %', p_id;
	    RETURN FALSE;
          END IF;        
        ELSE
          -- validate users authority to perform a create action on this project
          IF (SELECT * FROM pmt_validate_user_authority($1, p_id, 'create')) THEN          
            SELECT INTO record_id ac.activity_id FROM activity_contact as ac WHERE ac.activity_id = $2 AND ac.contact_id = $3 LIMIT 1;
            IF record_id IS NULL THEN
              EXECUTE 'INSERT INTO activity_contact(activity_id, contact_id) VALUES ('|| $2 ||', '|| $3 ||')';
              RAISE NOTICE 'Add Record: %', 'Activity_id ('|| $2 ||') is now associated to contact_id ('|| $3 ||').'; 
            ELSE
              RAISE NOTICE'Add Record: %', 'This activity_id ('|| $2 ||') already has an association to this contact_id ('|| $3 ||').';                
            END IF;
          ELSE
            RAISE NOTICE 'Error: The requested edit action requires the user to have CREATE rights to this project: %', p_id;
	    RETURN FALSE;
          END IF;                  
      END CASE;
      -- edits are complete return successful
      RETURN TRUE;         
    ELSE
      RAISE NOTICE 'Error: Invalid activity_id or contact_id.';
      RETURN FALSE;
    END IF;
  ELSE
    RAISE NOTICE 'Error: Must provide all parameters.';
    RETURN false;
  END IF; 
  
EXCEPTION WHEN others THEN
    RETURN FALSE;  	  
END;$$ LANGUAGE plpgsql;
/******************************************************************
  pmt_stat_partner_network
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_stat_partner_network(country_ids character varying) RETURNS SETOF pmt_json_result_type AS $$
DECLARE
  valid_classification_ids int[];
  valid_country_ids int[];
  rec record;
  exectute_statement text;
  dynamic_where text;
BEGIN

  --  if country_ids exists validate and filter
  IF $1 IS NOT NULL OR $1 <> '' THEN
    SELECT INTO valid_classification_ids * FROM pmt_validate_classifications($1);
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
        dynamic_where := ' AND (location_ids <@ ARRAY[(select array_agg(location_id) from taxonomy_lookup where classification_id = ANY(ARRAY[' || array_to_string(valid_country_ids, ',')  || ']))]) ';      
    END IF;   
    
  END IF;
  
  -- prepare statement
  exectute_statement := 'SELECT array_to_json(array_agg(row_to_json(x))) ' ||
	'FROM ( ' ||
		-- Funding Orgs
		'SELECT f.name as name, f.organization_id as o_id, ' ||
			'(SELECT array_to_json(array_agg(row_to_json(y))) ' ||
			'FROM ( ' ||
				-- Accountable Orgs
				'SELECT ac.name as name, ' ||
					'(SELECT array_to_json(array_agg(row_to_json(z))) ' ||
					'FROM ( ' ||
						-- Implementing Orgs
						'SELECT i.name as name, ' ||
							'(SELECT array_to_json(array_agg(row_to_json(a)))  ' ||
							'FROM ( ' ||
								'SELECT a.title as name ' ||
								'FROM activity a ' ||
								'WHERE activity_id = ANY(i.activity_ids) ' ||
							')a) as children ' ||
						'FROM ( ' ||
						'SELECT ol.organization_id, o.name, array_agg(activity_id) as activity_ids ' ||
						'FROM organization_lookup ol ' ||
						'JOIN organization o ' ||
						'ON ol.organization_id = o.organization_id ' ||
						'WHERE (classification_ids @> ARRAY[(select classification_id from classification where taxonomy_id = (select taxonomy_id from taxonomy where name = ''Organisation Role'')  ' ||
						'AND iati_name = ''Implementing'')]) AND (ac.activity_ids @> ARRAY[ol.activity_id]) ' ||
						'GROUP BY ol.organization_id, o.name ' ||
						') i ' ||
					') z) as children ' ||
				'FROM ( ' ||
				'SELECT ol.organization_id, o.name, array_agg(activity_id) as activity_ids ' ||
				'FROM organization_lookup ol ' ||
				'JOIN organization o ' ||
				'ON ol.organization_id = o.organization_id ' ||
				'WHERE (classification_ids @> ARRAY[(select classification_id from classification where taxonomy_id = (select taxonomy_id from taxonomy where name = ''Organisation Role'')  ' ||
				'AND iati_name = ''Accountable'')]) AND (f.activity_ids @> ARRAY[ol.activity_id]) ' ||
				'GROUP BY ol.organization_id, o.name ' ||
				') ac ' ||
			') y) as children ' ||
		'FROM ' ||
		'(SELECT DISTINCT ol.organization_id, o.name, array_agg(activity_id) as activity_ids ' ||
		'FROM organization_lookup ol ' ||
		'JOIN organization o ' ||
		'ON ol.organization_id = o.organization_id ' ||
		'WHERE (classification_ids @> ARRAY[(select classification_id from classification where taxonomy_id = (select taxonomy_id from taxonomy where name = ''Organisation Role'')  ' ||
		'AND iati_name = ''Funding'')])  ';

		IF dynamic_where IS NOT NULL THEN
			exectute_statement := exectute_statement || dynamic_where;
		END IF;

		exectute_statement := exectute_statement || 'GROUP BY ol.organization_id, o.name) as f ' ||
		') x ';

   RAISE NOTICE 'Execute: %', exectute_statement;
   
   -- exectute the prepared statement	
   FOR rec IN EXECUTE exectute_statement LOOP
	RETURN NEXT rec; 
   END LOOP;
   
END;$$ LANGUAGE plpgsql;
/******************************************************************
   pmt_edit_contact
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_edit_contact(user_id integer, contact_id integer, key_value_data json, delete_record boolean default false) RETURNS SETOF pmt_json_result_type AS 
$$
DECLARE
  new_contact_id integer;
  c_id integer;
  json record;
  column_record record;
  execute_statement text;
  invalid_editing_columns text[];
  user_name text;
  rec record;
  error_msg1 text;
  error_msg2 text;
  error_msg3 text;
BEGIN	
  -- set columns that are not editable via the parameters 
  invalid_editing_columns := ARRAY['contact_id', 'active', 'retired_by', 'created_by', 'created_date', 'updated_by', 'updated_date'];
  
  -- user and data parameters are required
  IF ($1 IS NOT NULL) THEN
    IF NOT ($4) AND ($3 IS NULL) THEN
      FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: Must included json parameter when delete_record is false.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
    END IF;
  ELSE
    FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: Must included user_id parameter.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
  END IF; 

  -- get users name
  SELECT INTO user_name username FROM "user" WHERE "user".user_id = $1;

  -- if contact_id is null then validate users authroity to create a new contact record  
  IF ($2 IS NULL) THEN
    IF (SELECT * FROM pmt_validate_user_authority($1, null, 'create')) THEN
      EXECUTE 'INSERT INTO contact(created_by, updated_by) VALUES (' || quote_literal(user_name) || ',' || quote_literal(user_name) || ') RETURNING contact_id;' INTO new_contact_id;
      RAISE NOTICE 'Created new contact with id: %', new_contact_id;
    ELSE
      FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: User does NOT have authority to create a new contact.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
    END IF;
  -- validate contact_id if provided and validate users authority to update an existing record  
  ELSE      
    IF (SELECT * FROM pmt_validate_contact($2)) THEN 
      -- validate users authority to 'delete' this contact
      IF ($4) THEN
        IF (SELECT * FROM pmt_validate_user_authority($1, null, 'delete')) THEN
          -- deactivate this contact          
          EXECUTE 'UPDATE contact SET active = false WHERE contact.contact_id = ' || $2;
        ELSE
          FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: User does NOT have authority to delete this contact.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
        END IF;
      -- validate users authority to 'update' this contact
      ELSE          
        IF (SELECT * FROM pmt_validate_user_authority($1, null, 'update')) THEN   
        ELSE
          FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: User does NOT have authority to update an existing contact.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
        END IF;
      END IF;
    ELSE
      FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: Invalid contact_id.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
    END IF;
  END IF;
             
  -- assign the contact_id to use in statements
  IF new_contact_id IS NOT NULL THEN
    c_id := new_contact_id;
  ELSE
    c_id := $2;
  END IF;
  
  -- loop through the columns of the contact table        
  FOR json IN (SELECT * FROM json_each_text($3)) LOOP
    RAISE NOTICE 'JSON key/value: %', lower(json.key) || ':' || json.value;
    -- get the column information for column that user is requesting to edit	
    FOR column_record IN (SELECT * FROM information_schema.columns WHERE table_schema='public' AND table_name='contact' AND column_name != ALL(invalid_editing_columns) AND lower(column_name) = lower(json.key)) LOOP 
      RAISE NOTICE 'Editing column: %', column_record.column_name;
      RAISE NOTICE 'Assigning new value: %', json.value;
      execute_statement := null;
      CASE column_record.data_type 
        WHEN 'integer', 'numeric' THEN              
          IF (SELECT pmt_isnumeric(json.value)) THEN
            execute_statement := 'UPDATE contact SET ' || column_record.column_name || ' = ' || json.value || ' WHERE contact_id = ' || c_id; 
          END IF;
          IF (lower(json.value) = 'null') THEN
            execute_statement := 'UPDATE contact SET ' || column_record.column_name || ' = null WHERE contact_id = ' || c_id; 
          END IF;
        ELSE
          -- if the value has the text null then assign the column value null
          IF (lower(json.value) = 'null') THEN
            execute_statement := 'UPDATE contact SET ' || column_record.column_name || ' = null WHERE contact_id = ' || c_id; 
          ELSE
            execute_statement := 'UPDATE contact SET ' || column_record.column_name || ' = ' || quote_literal(json.value) || ' WHERE contact_id = ' || c_id; 
          END IF;
      END CASE;
      IF execute_statement IS NOT NULL THEN
        RAISE NOTICE 'Statement: %', execute_statement;
        EXECUTE execute_statement;
                
        EXECUTE 'UPDATE contact SET updated_by = ' || quote_literal(user_name) || ', updated_date = ' || quote_literal(current_date) || ' WHERE  contact_id = ' || c_id;
      END IF;
    END LOOP;
  END LOOP;
  -- editing completed successfullly
  FOR rec IN (SELECT row_to_json(j) FROM(select c_id as id, 'Success' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
   
EXCEPTION WHEN others THEN
    GET STACKED DIAGNOSTICS error_msg1 = MESSAGE_TEXT,
                          error_msg2 = PG_EXCEPTION_DETAIL,
                          error_msg3 = PG_EXCEPTION_HINT;
    FOR rec IN (SELECT row_to_json(j) FROM(select c_id as id, 'Internal Error - Contact your DBA with the following error message: ' || error_msg1 as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;	  
END;$$ LANGUAGE plpgsql;
/******************************************************************
   pmt_edit_participation
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_edit_participation(user_id integer, participation_id integer, project_id integer, activity_id integer, 
organization_id integer, classification_id integer, edit_action pmt_edit_action) RETURNS SETOF pmt_json_result_type AS 
$$
DECLARE
  p_id integer;
  o_id integer;  
  a_id integer;  
  c_id integer;  
  record_id integer;
  participation_records integer[];
  user_name text;
  rec record;
  error_msg1 text;
  error_msg2 text;
  error_msg3 text;
BEGIN	

  -- user parameter is required
  IF ($1 IS NULL) THEN
    FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: Must have user_id parameter.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
  END IF;
  -- get users name
  SELECT INTO user_name username FROM "user" WHERE "user".user_id = $1;
  -- validate participation_id if provided
  IF ($2 IS NOT NULL) THEN
    SELECT INTO record_id p.participation_id FROM participation p WHERE p.participation_id = $2 AND active = true;
    IF record_id IS NULL THEN
      FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: Provided participation_id is invalid or inactive.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;     
    END IF;    
  END IF;  
  -- validate project_id if provided
  IF ($3 IS NOT NULL) THEN
    SELECT INTO p_id p.project_id FROM project p WHERE p.project_id = $3 AND active = true;
    IF p_id IS NULL THEN
      FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: Provided project_id is invalid or inactive.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;          
    END IF;    
  END IF;
  -- validate activity_id if provided
  IF ($4 IS NOT NULL) THEN
    SELECT INTO a_id a.activity_id FROM activity a WHERE a.activity_id = $4 AND active = true;
    IF a_id IS NULL THEN
      FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: Provided activity_id is invalid or inactive.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;     
    ELSE
      SELECT INTO p_id a.project_id FROM activity a WHERE a.activity_id = a_id;
    END IF; 
       
  END IF;
  -- validate organization_id if provided
  IF ($5 IS NOT NULL) THEN
    SELECT INTO o_id o.organization_id FROM organization o WHERE o.organization_id = $5 AND active = true;
    IF o_id IS NULL THEN
      FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: Provided organization_id is invalid or inactive.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;     
    END IF;    
  END IF;
  -- validate classification_id if provided
  IF ($6 IS NOT NULL) THEN
    SELECT INTO c_id tc.classification_id from taxonomy_classifications tc where tc.taxonomy = 'Organisation Role' AND tc.classification_id = $6;
    IF c_id IS NULL THEN
      FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: Provided classification_id is not in the Organisation Role taxonomy or is inactive.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
    END IF;    
  END IF;
  
  -- operations based on the requested edit action
  CASE $7
    WHEN 'delete' THEN
      -- check for required parameters
      IF (record_id IS NULL) THEN 
        FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: Must have participation_id parameter when edit action is: ' || $7 as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;     
      END IF;  
      -- validate users authority to perform an update action on this project
      IF (SELECT * FROM pmt_validate_user_authority($1, p_id, 'update')) THEN
        EXECUTE 'DELETE FROM participation WHERE participation_id ='|| record_id; 
        EXECUTE 'DELETE FROM participation_taxonomy WHERE participation_id ='|| record_id; 
        RAISE NOTICE 'Delete Record: %', 'Removed participation and taxonomy associated to this participation_id ('|| record_id ||')';
      ELSE
        FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: The requested edit action requires the user to have UPDATE rights to this project: ' || p_id as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;     
      END IF;   
    WHEN 'replace' THEN            
      -- check for required parameters
      IF (p_id IS NULL) OR (o_id IS NULL) OR (c_id IS NULL) THEN
        FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: Must have project_id, organization_id and classification_id parameters when edit action is: ' || $7 as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;     
      END IF;
      -- validate users authority to perform an update and create action on this project
      IF (SELECT * FROM pmt_validate_user_authority($1, p_id, 'update')) AND (SELECT * FROM pmt_validate_user_authority($1, p_id, 'create')) THEN        
        IF a_id IS NOT NULL THEN
          -- activity participation
          SELECT INTO participation_records array_agg(p.participation_id)::int[] FROM participation p WHERE p.project_id = p_id AND p.activity_id = a_id;
          RAISE NOTICE 'Participation records to be deleted and replaced: %', participation_records;
          EXECUTE 'DELETE FROM participation WHERE participation_id = ANY(ARRAY['|| array_to_string(participation_records, ',')  || '])'; 
          EXECUTE 'DELETE FROM participation_taxonomy WHERE participation_id= ANY(ARRAY['|| array_to_string(participation_records, ',')  || '])'; 
          EXECUTE 'INSERT INTO participation(project_id, activity_id, organization_id, created_by, updated_by) VALUES (' || p_id || ',' || a_id || ',' || o_id || 
		',' || quote_literal(user_name) || ',' || quote_literal(user_name) || ') RETURNING participation_id;' INTO record_id;
          EXECUTE 'INSERT INTO participation_taxonomy(participation_id, classification_id, field) VALUES (' || record_id || ',' || c_id || ', ''participation_id'');';
          RAISE NOTICE 'Add Record: %', 'participation_id ('|| record_id ||') has organiztaion_id  ('|| o_id ||'), project_id ('|| p_id ||'), activity_id ('|| a_id ||
		') is now associated to classification_id ('|| c_id ||').'; 
        ELSE
          -- project participation
          SELECT INTO participation_records array_agg(p.participation_id)::int[]  FROM participation p WHERE p.project_id = p_id AND p.activity_id IS NULL;
          RAISE NOTICE 'Participation records to be deleted and replaced: %', participation_records;
          EXECUTE 'DELETE FROM participation WHERE participation_id = ANY(ARRAY['|| array_to_string(participation_records, ',') || '])'; 
          EXECUTE 'DELETE FROM participation_taxonomy WHERE participation_id = ANY(ARRAY['|| array_to_string(participation_records, ',') || '])'; 
          EXECUTE 'INSERT INTO participation(project_id, organization_id, created_by, updated_by) VALUES (' || p_id || ',' || o_id || 
		',' || quote_literal(user_name) || ',' || quote_literal(user_name) || ') RETURNING participation_id;' INTO record_id;
          EXECUTE 'INSERT INTO participation_taxonomy(participation_id, classification_id, field) VALUES (' || record_id || ',' || c_id || ', ''participation_id'');';
          RAISE NOTICE 'Add Record: %', 'participation_id ('|| record_id ||') has organiztaion_id  ('|| o_id ||'), project_id ('|| p_id ||') is now associated to classification_id ('|| c_id ||').'; 
        END IF;
      ELSE
        FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: The requested edit action requires the user to have UPDATE and CREATE rights to this project: ' || p_id as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;     
      END IF;
    ELSE
      -- check for required parameters
      IF (p_id IS NULL) OR (o_id IS NULL) OR (c_id IS NULL) THEN
        FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: Must have project_id, organization_id and classification_id parameters when edit action is: ' || $7 as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;     
      END IF;
      -- validate users authority to perform a create action on this project
      IF (SELECT * FROM pmt_validate_user_authority($1, p_id, 'create')) THEN
        IF a_id IS NOT NULL THEN
          -- activity participation          
          EXECUTE 'INSERT INTO participation(project_id, activity_id, organization_id, created_by, updated_by) VALUES (' || p_id || ',' || a_id || ',' || o_id || 
		',' || quote_literal(user_name) || ',' || quote_literal(user_name) || ') RETURNING participation_id;' INTO record_id;
          EXECUTE 'INSERT INTO participation_taxonomy(participation_id, classification_id, field) VALUES (' || record_id || ',' || c_id || ', ''participation_id'');';
          RAISE NOTICE 'Add Record: %', 'participation_id ('|| record_id ||') has organiztaion_id  ('|| o_id ||'), project_id ('|| p_id ||'), activity_id ('|| a_id ||
		') is now associated to classification_id ('|| c_id ||').'; 
        ELSE
          -- project participation          
          EXECUTE 'INSERT INTO participation(project_id, organization_id, created_by, updated_by) VALUES (' || p_id || ',' || o_id || 
		',' || quote_literal(user_name) || ',' || quote_literal(user_name) || ') RETURNING participation_id;' INTO record_id;
          EXECUTE 'INSERT INTO participation_taxonomy(participation_id, classification_id, field) VALUES (' || record_id || ',' || c_id || ', ''participation_id'');';
          RAISE NOTICE 'Add Record: %', 'participation_id ('|| record_id ||') has organiztaion_id  ('|| o_id ||'), project_id ('|| p_id ||') is now associated to classification_id ('|| c_id ||').'; 
        END IF;
      ELSE
        FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: The requested edit action requires the user to have CREATE rights to this project: ' || p_id as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;     
      END IF;        
  END CASE;

  -- editing completed successfullly
  FOR rec IN (SELECT row_to_json(j) FROM(select record_id as id, 'Success' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;         
  
EXCEPTION WHEN others THEN
     GET STACKED DIAGNOSTICS error_msg1 = MESSAGE_TEXT,
                          error_msg2 = PG_EXCEPTION_DETAIL,
                          error_msg3 = PG_EXCEPTION_HINT;
    FOR rec IN (SELECT row_to_json(j) FROM(select record_id as id, 'Internal Error - Contact your DBA with the following error message: ' || error_msg1 as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
      
END;$$ LANGUAGE plpgsql;
/******************************************************************
   pmt_infobox_activity
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_infobox_activity(activity_id integer) RETURNS SETOF pmt_json_result_type AS $$
DECLARE
  rec record;
  invalid_return_columns text[];
  return_columns text;
  execute_statement text;
  data_message text;
BEGIN
  IF $1 IS NOT NULL THEN	
    -- set columns that are not to be returned 
    invalid_return_columns := ARRAY['active', 'retired_by', 'created_by', 'created_date'];
    -- get list of columns to return
    SELECT INTO return_columns array_to_string(array_agg('a.' || column_name::text), ', ') FROM information_schema.columns 
    WHERE table_schema='public' AND table_name='activity' AND column_name != ALL(invalid_return_columns);

    -- dynamically build the execute statment	
    execute_statement := 'SELECT ' || return_columns || ', l.location_ct, l.admin_bnds ';
    -- -- taxonomy	
    execute_statement := execute_statement || ',(SELECT array_to_json(array_agg(row_to_json(t))) FROM ( ' ||
				'select tc.taxonomy_id, tc.taxonomy, tc.classification_id, tc.classification ' ||
				'from activity_taxonomy at ' ||
				'join taxonomy_classifications  tc ' ||
				'on at.classification_id = tc.classification_id ' ||
				'and at.activity_id = ' || $1 ||
				') t ) as taxonomy ';
    -- partners			
    execute_statement := execute_statement || ',(SELECT array_to_json(array_agg(row_to_json(p))) FROM ( ' ||
				'select o.organization_id, o.name, tc.taxonomy_id, tc.taxonomy, tc.classification_id, tc.classification ' ||
				'from participation pp ' ||
				'join organization o ' ||
				'on pp.organization_id = o.organization_id ' ||
				'left join participation_taxonomy ppt ' ||
				'on pp.participation_id = ppt.participation_id ' ||
				'join taxonomy_classifications tc ' ||
				'on ppt.classification_id = tc.classification_id ' ||
				'where pp.active = true and o.active = true ' ||
				'and tc.taxonomy = ''Organisation Role'' and (tc.classification = ''Implementing'' OR tc.classification= ''Funding'') ' ||
				'and pp.activity_id = ' || $1 ||
				') p ) as partners ';
    -- contacts
    execute_statement := execute_statement || ',(SELECT array_to_json(array_agg(row_to_json(c))) FROM ( ' ||
				'select c.contact_id, c.first_name, c.last_name, c.organization_id, o.name ' ||
				'from activity_contact ac ' ||
				'join contact c ' ||
				'on ac.contact_id = c.contact_id ' ||
				'left join organization o ' ||
				'on c.organization_id = o.organization_id ' ||
				'where c.active = true and ac.activity_id = ' || $1 ||
				') c ) as contacts ';				
    -- activity
    execute_statement := execute_statement || 'from (select * from activity a where a.active = true and a.activity_id = ' || $1 || ') a ';
    -- locations
    execute_statement := execute_statement || 'left join ' ||
				'(select ll.activity_id, count(ll.location_id) as location_ct, array_to_string(array_agg(distinct ll.gaul0_name || '','' || ll.gaul1_name || '','' || ll.gaul2_name), '';'') as admin_bnds ' ||
				'from location_lookup ll ' ||
				'where ll.activity_id = ' || $1 ||
				'group by ll.activity_id) l ' ||
				'on a.activity_id = l.activity_id ';

	FOR rec IN EXECUTE 'SELECT row_to_json(j) FROM (' || execute_statement || ')j' LOOP  		
		RETURN NEXT rec;
	END LOOP;
   END IF;
END;$$ LANGUAGE plpgsql;
/******************************************************************
   pmt_global_search
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_global_search(search_text text) RETURNS SETOF pmt_json_result_type AS $$
DECLARE
  rec record;
  json_rec record;
  column_rec record;
  error_msg text;
BEGIN
  IF ($1 IS NULL OR $1 = '') THEN
    -- must include all parameters, return error
    FOR rec IN (SELECT row_to_json(j) FROM(SELECT 'Error: Must include search_text data parameter.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
  ELSE
    FOR rec IN (
    SELECT row_to_json(j)
    FROM
    (	
	SELECT p.type, p.id, p.title, p.desc, p.tags, p.p_ids, p.a_ids, dg_id FROM (
	SELECT 'p'::text AS "type", p.project_id AS id, coalesce(p.label, p.title) AS title, (lower(p.title) LIKE '%' || lower($1) || '%') AS in_title, 
	p.description AS desc, (lower(p.description) LIKE '%' || lower($1) || '%') AS in_desc, 
	p.tags, (lower(p.tags) LIKE '%' || lower($1) || '%') AS in_tags, array_agg(distinct p.project_id) as p_ids, array_agg(distinct l.activity_id) as a_ids
	, array_agg(distinct pt.classification_id) as dg_id
	-- , ST_AsGeoJSON(ST_Envelope(ST_UNION(l.point))) AS bbox, array_agg(l.location_id) AS l_ids
	FROM project p
	LEFT JOIN activity l
	ON p.project_id = l.project_id
	LEFT JOIN project_taxonomy pt
	ON p.project_id = pt.project_id
	WHERE p.active = true and l.active = true and pt.classification_id IN (SELECT classification_id FROM taxonomy_classifications WHERE taxonomy = 'Data Group') and
	(lower(p.title) LIKE '%' || lower($1) || '%' or lower(p.description) LIKE '%' || lower($1) || '%' or lower(p.tags) LIKE '%' || lower($1) || '%')
	GROUP BY p.project_id, p.title, p.description, p.tags
	ORDER BY in_title desc, in_tags desc, in_desc desc) AS p
	UNION ALL
	SELECT a.type, a.id, a.title, a.desc, a.tags, a.p_ids, a.a_ids, dg_id FROM (
	SELECT 'a'::text AS "type", a.activity_id AS id, coalesce(a.label, a.title) AS title, (lower(a.title) LIKE '%' || lower($1) || '%') AS in_title, 
	a.description AS desc, (lower(a.description) LIKE '%' || lower($1) || '%') AS in_desc, 
	a.tags, (lower(a.tags) LIKE '%' || lower($1) || '%') AS in_tags, array_agg(distinct a.project_id) as p_ids, array_agg(distinct a.activity_id) as a_ids
	, array_agg(distinct pt.classification_id) as dg_id
	-- , ST_AsGeoJSON(ST_Envelope(ST_UNION(l.point))) AS bbox, array_agg(l.location_id) AS l_ids
	FROM activity a
	LEFT JOIN project_taxonomy pt
	ON a.project_id = pt.project_id
	WHERE a.active = true and pt.classification_id IN (SELECT classification_id FROM taxonomy_classifications WHERE taxonomy = 'Data Group') and
	(lower(a.title) LIKE '%' || lower($1) || '%' or lower(a.description) LIKE '%' || lower($1) || '%' or lower(a.tags) LIKE '%' || lower($1) || '%')
	GROUP BY a.activity_id, a.title, a.description, a.tags
	ORDER BY in_title desc, in_tags desc, in_desc desc) AS a
     ) j
    ) LOOP		
      RETURN NEXT rec;
    END LOOP;	
    
  END IF;
  	
EXCEPTION WHEN others THEN
    GET STACKED DIAGNOSTICS error_msg = MESSAGE_TEXT;
    FOR rec IN (SELECT row_to_json(j) FROM(SELECT 'Internal Error - Contact your DBA with the following error message: ' || error_msg as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;	  	
END;$$ LANGUAGE plpgsql;
/******************************************************************
   pmt_activity
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_activity(activity_id integer) RETURNS SETOF pmt_json_result_type AS 
$$
DECLARE
  rec record;
  invalid_return_columns text[];
  return_columns text;
  execute_statement text;
  data_message text;
BEGIN
  IF $1 IS NOT NULL THEN	
    -- set columns that are not to be returned 
    invalid_return_columns := ARRAY['active', 'retired_by', 'created_by', 'created_date'];
    -- get list of columns to return
    SELECT INTO return_columns array_to_string(array_agg('a.' || column_name::text), ', ') FROM information_schema.columns 
    WHERE table_schema='public' AND table_name='activity' AND column_name != ALL(invalid_return_columns);

    -- dynamically build the execute statment	
    execute_statement := 'SELECT ' || return_columns || ', l.location_ct, l.admin_bnds ';

    -- taxonomy	
    execute_statement := execute_statement || ',(SELECT array_to_json(array_agg(row_to_json(t))) FROM ( ' ||
				'select tc.taxonomy_id, tc.taxonomy, tc.classification_id, tc.classification, tc.code ' ||
				'from activity_taxonomy at ' ||
				'join taxonomy_classifications  tc ' ||
				'on at.classification_id = tc.classification_id ' ||
				'and at.activity_id = ' || $1 ||
				') t ) as taxonomy ';
    -- organizations			
    execute_statement := execute_statement || ',(SELECT array_to_json(array_agg(row_to_json(p))) FROM ( ' ||
				'select pp.participation_id, o.organization_id, o.name, o.url'  ||
						', (SELECT array_to_json(array_agg(row_to_json(t))) FROM ( ' ||
						'select tc.taxonomy_id, tc.taxonomy, tc.classification_id, tc.classification, tc.code ' ||
						'from participation_taxonomy pt ' ||
						'join taxonomy_classifications tc ' ||
						'on pt.classification_id = tc.classification_id ' ||
						'and pt.participation_id = pp.participation_id ' ||
						') t ) as taxonomy ' ||
				'from participation pp ' ||
				'join organization o ' ||
				'on pp.organization_id = o.organization_id ' ||				
				'where pp.active = true and o.active = true ' ||
				'and pp.activity_id = ' || $1 ||
				') p ) as organizations ';
    -- contacts
    execute_statement := execute_statement || ',(SELECT array_to_json(array_agg(row_to_json(c))) FROM ( ' ||
				'select c.contact_id, c.first_name, c.last_name, c.email, c.organization_id, o.name ' ||
				'from activity_contact ac ' ||
				'join contact c ' ||
				'on ac.contact_id = c.contact_id ' ||
				'left join organization o ' ||
				'on c.organization_id = o.organization_id ' ||
				'where c.active = true and ac.activity_id = ' || $1 ||
				') c ) as contacts ';	
    -- details
    execute_statement := execute_statement || ',(SELECT array_to_json(array_agg(row_to_json(d))) FROM ( ' ||
				'select d.detail_id, d.title, d.description, d.amount ' ||
				'from detail d ' ||				
				'where d.active = true and d.activity_id = ' || $1 ||
				') d ) as details ';					

    -- financials
    execute_statement := execute_statement || ',(SELECT array_to_json(array_agg(row_to_json(f))) FROM ( ' ||
				'select f.financial_id, f.amount'  ||
						', (SELECT array_to_json(array_agg(row_to_json(t))) FROM ( ' ||
						'select tc.taxonomy_id, tc.taxonomy, tc.classification_id, tc.classification, tc.code ' ||
						'from financial_taxonomy ft ' ||
						'join taxonomy_classifications tc ' ||
						'on ft.classification_id = tc.classification_id ' ||
						'and ft.financial_id = f.financial_id ' ||
						') t ) as taxonomy ' ||
				'from financial f ' ||		
				'where f.active = true and f.activity_id = ' || $1 ||
				') f ) as financials ';
											
     -- locations
    execute_statement := execute_statement || ',(SELECT array_agg(l.location_id)::int[]  ' ||
				'from location l ' ||		
				'where l.active = true and l.activity_id = ' || $1 ||
				') as location_ids ';			
								
    -- activity
    execute_statement := execute_statement || 'from (select * from activity a where a.active = true and a.activity_id = ' || $1 || ') a ';
    -- locations
    execute_statement := execute_statement || 'left join ' ||
				'(select ll.activity_id, count(distinct ll.location_id) as location_ct, array_to_string(array_agg(distinct ll.gaul0_name || '','' || ll.gaul1_name || '','' || ll.gaul2_name), '';'') as admin_bnds ' ||
				'from location_lookup ll ' ||
				'where ll.activity_id = ' || $1 ||
				'group by ll.activity_id) l ' ||
				'on a.activity_id = l.activity_id ';


	RAISE NOTICE 'Execute statement: %', execute_statement;			

	FOR rec IN EXECUTE 'SELECT row_to_json(j) FROM (' || execute_statement || ')j' LOOP  		
		RETURN NEXT rec;
	END LOOP;
   END IF;
END;$$ LANGUAGE plpgsql;
/******************************************************************
   pmt_project
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_project(project_id integer) RETURNS SETOF pmt_json_result_type AS $$
DECLARE
  rec record;
  invalid_return_columns text[];
  return_columns text;
  execute_statement text;
  data_message text;
BEGIN
  IF $1 IS NOT NULL THEN	
    -- set columns that are not to be returned 
    invalid_return_columns := ARRAY['active', 'retired_by', 'created_by', 'created_date'];
    -- get list of columns to return
    SELECT INTO return_columns array_to_string(array_agg('p.' || column_name::text), ', ') FROM information_schema.columns 
    WHERE table_schema='public' AND table_name='project' AND column_name != ALL(invalid_return_columns);

    -- dynamically build the execute statment	
    execute_statement := 'SELECT ' || return_columns;

    -- taxonomy	
    execute_statement := execute_statement || ',(SELECT array_to_json(array_agg(row_to_json(t))) FROM ( ' ||
				'select tc.taxonomy_id, tc.taxonomy, tc.classification_id, tc.classification, tc.code ' ||
				'from project_taxonomy pt ' ||
				'join taxonomy_classifications  tc ' ||
				'on pt.classification_id = tc.classification_id ' ||
				'and pt.project_id = ' || $1 ||
				') t ) as taxonomy ';
    -- organizations			
    execute_statement := execute_statement || ',(SELECT array_to_json(array_agg(row_to_json(p))) FROM ( ' ||
				'select pp.participation_id, o.organization_id, o.name, o.url'  ||
						', (SELECT array_to_json(array_agg(row_to_json(t))) FROM ( ' ||
						'select tc.taxonomy_id, tc.taxonomy, tc.classification_id, tc.classification, tc.code ' ||
						'from participation_taxonomy pt ' ||
						'join taxonomy_classifications tc ' ||
						'on pt.classification_id = tc.classification_id ' ||
						'and pt.participation_id = pp.participation_id ' ||
						') t ) as taxonomy ' ||
				'from participation pp ' ||
				'join organization o ' ||
				'on pp.organization_id = o.organization_id ' ||				
				'where pp.active = true and o.active = true ' ||
				'and pp.activity_id is null and pp.project_id = ' || $1 ||
				') p ) as organizations ';
    -- contacts
    execute_statement := execute_statement || ',(SELECT array_to_json(array_agg(row_to_json(c))) FROM ( ' ||
				'select c.contact_id, c.first_name, c.last_name, c.email, c.organization_id, o.name ' ||
				'from project_contact pc ' ||
				'join contact c ' ||
				'on pc.contact_id = c.contact_id ' ||
				'left join organization o ' ||
				'on c.organization_id = o.organization_id ' ||
				'where c.active = true and pc.project_id = ' || $1 ||
				') c ) as contacts ';					
    -- details
    execute_statement := execute_statement || ',(SELECT array_to_json(array_agg(row_to_json(d))) FROM ( ' ||
				'select d.detail_id, d.title, d.description, d.amount ' ||
				'from detail d ' ||				
				'where d.active = true and d.activity_id is null and d.project_id = ' || $1 ||
				') d ) as details ';

    -- financials
    execute_statement := execute_statement || ',(SELECT array_to_json(array_agg(row_to_json(f))) FROM ( ' ||
				'select f.financial_id, f.amount'  ||
						', (SELECT array_to_json(array_agg(row_to_json(t))) FROM ( ' ||
						'select tc.taxonomy_id, tc.taxonomy, tc.classification_id, tc.classification, tc.code ' ||
						'from financial_taxonomy ft ' ||
						'join taxonomy_classifications tc ' ||
						'on ft.classification_id = tc.classification_id ' ||
						'and ft.financial_id = f.financial_id ' ||
						') t ) as taxonomy ' ||
				'from financial f ' ||				
				'where f.active = true and f.activity_id is null and f.project_id = ' || $1 ||
				') f ) as financials ';
												
    -- activities
    execute_statement := execute_statement || ',(SELECT array_agg(a.activity_id)::int[]  ' ||
				'from activity a ' ||		
				'where a.active = true and a.project_id = ' || $1 ||
				') as activity_ids ';		
				
    -- locations
    execute_statement := execute_statement || ',(SELECT array_agg(l.location_id)::int[]  ' ||
				'from location l ' ||		
				'where l.active = true and l.project_id = ' || $1 ||
				') as location_ids ';		
								
    -- project
    execute_statement := execute_statement || 'from (select * from project p where p.active = true and p.project_id = ' || $1 || ') p ';
   

	RAISE NOTICE 'Execute statement: %', execute_statement;			

	FOR rec IN EXECUTE 'SELECT row_to_json(j) FROM (' || execute_statement || ')j' LOOP  		
		RETURN NEXT rec;
	END LOOP;
   END IF;
END;$$ LANGUAGE plpgsql;
/******************************************************************
  pmt_validate_project
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_validate_project(id integer) RETURNS boolean AS $$
DECLARE valid_id integer;
BEGIN 
     IF $1 IS NULL THEN    
       RETURN false;
     END IF;    
     
     SELECT INTO valid_id project_id FROM project WHERE active = true AND project_id = $1;	 

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
  pmt_validate_projects
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_validate_projects(project_ids character varying) RETURNS INT[] AS $$
DECLARE 
  valid_project_ids INT[];
  filter_project_ids INT[];
BEGIN 
     IF $1 IS NULL THEN    
       RETURN valid_project_ids;
     END IF;

     filter_project_ids := string_to_array($1, ',')::int[];
     
     SELECT INTO valid_project_ids array_agg(DISTINCT project_id)::INT[] FROM (SELECT project_id FROM project WHERE active = true AND project_id = ANY(filter_project_ids) ORDER BY project_id) AS t;
     
     RETURN valid_project_ids;

EXCEPTION
     WHEN others THEN RETURN NULL;
END; 
$$ LANGUAGE 'plpgsql';
/******************************************************************
   pmt_edit_project_contact
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_edit_project_contact(user_id integer, project_id integer, contact_id integer, edit_action pmt_edit_action) RETURNS BOOLEAN AS 
$$
DECLARE
  p_id integer;
  record_id integer;
  error_msg1 text;
  error_msg2 text;
  error_msg3 text;
BEGIN	
  -- first three parameters are required 
  IF ($1 IS NOT NULL) AND ($2 IS NOT NULL) AND ($3 IS NOT NULL) THEN
    -- validate project_id & contact_id
    IF (SELECT * FROM pmt_validate_project($2)) AND (SELECT * FROM pmt_validate_contact($3)) THEN
      p_id := $2;
      
      -- operations based on the requested edit action
      CASE $4
        WHEN 'delete' THEN
          -- validate users authority to perform an update action on this project
          IF (SELECT * FROM pmt_validate_user_authority($1, p_id, 'update')) THEN          
            EXECUTE 'DELETE FROM project_contact WHERE project_id ='|| $2 ||' AND contact_id = '|| $3; 
            RAISE NOTICE 'Delete Record: %', 'Remove association to contact_id ('|| $3 ||') for project_id ('|| $2 ||')';
          ELSE
            RAISE NOTICE 'Error: The requested edit action requires the user to have UPDATE rights to this project: %', p_id;
	    RETURN FALSE;
          END IF;           
        WHEN 'replace' THEN            
           -- validate users authority to perform an update and create action on this project
          IF (SELECT * FROM pmt_validate_user_authority($1, p_id, 'update')) AND (SELECT * FROM pmt_validate_user_authority($1, p_id, 'create')) THEN          
            EXECUTE 'DELETE FROM project_contact WHERE project_id ='|| $2;
            RAISE NOTICE 'Delete Record: %', 'Removed all contacts for project_id ('|| $2 ||')';
	    EXECUTE 'INSERT INTO project_contact(project_id, contact_id) VALUES ('|| $2 ||', '|| $3 ||')';
            RAISE NOTICE 'Add Record: %', 'project_id ('|| $2 ||') is now associated to contact_id ('|| $3 ||').'; 
          ELSE
            RAISE NOTICE 'Error: The requested edit action requires the user to have UPDATE and CREATE rights to this project: %', p_id;
	    RETURN FALSE;
          END IF;        
        ELSE
          -- validate users authority to perform a create action on this project
          IF (SELECT * FROM pmt_validate_user_authority($1, p_id, 'create')) THEN          
            SELECT INTO record_id pc.project_id FROM project_contact as pc WHERE pc.project_id = $2 AND pc.contact_id = $3 LIMIT 1;
            IF record_id IS NULL THEN
              EXECUTE 'INSERT INTO project_contact(project_id, contact_id) VALUES ('|| $2 ||', '|| $3 ||')';
              RAISE NOTICE 'Add Record: %', 'project_id ('|| $2 ||') is now associated to contact_id ('|| $3 ||').'; 
            ELSE
              RAISE NOTICE'Add Record: %', 'This project_id ('|| $2 ||') already has an association to this contact_id ('|| $3 ||').';                
            END IF;
          ELSE
            RAISE NOTICE 'Error: The requested edit action requires the user to have CREATE rights to this project: %', p_id;
	    RETURN FALSE;
          END IF;                  
      END CASE;
      -- edits are complete return successful
      RETURN TRUE;         
    ELSE
      RAISE NOTICE 'Error: Invalid project_id or contact_id.';
      RETURN FALSE;
    END IF;
  ELSE
    RAISE NOTICE 'Error: Must provide all parameters.';
    RETURN false;
  END IF; 
  
EXCEPTION WHEN others THEN
   GET STACKED DIAGNOSTICS error_msg1 = MESSAGE_TEXT,
		  error_msg2 = PG_EXCEPTION_DETAIL,
		  error_msg3 = PG_EXCEPTION_HINT;
    RAISE NOTICE 'Error: %', error_msg1;
    RETURN FALSE;  	  
END;$$ LANGUAGE plpgsql;
/******************************************************************
  pmt_projects
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_projects() RETURNS SETOF pmt_json_result_type AS $$
DECLARE 
  error_msg1 text;
  error_msg2 text;
  error_msg3 text; 
  rec record;
BEGIN 

    FOR rec IN (SELECT row_to_json(j) FROM(

	SELECT p.project_id, p.title, ((SELECT array_agg(activity_id)::int[] FROM activity a WHERE a.project_id = p.project_id AND a.active = true)) as activity_ids
	FROM project p
	WHERE p.active = true
	ORDER BY p.title
	
	) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
     
EXCEPTION WHEN others THEN
    GET STACKED DIAGNOSTICS error_msg1 = MESSAGE_TEXT,
                          error_msg2 = PG_EXCEPTION_DETAIL,
                          error_msg3 = PG_EXCEPTION_HINT;
    FOR rec IN (SELECT row_to_json(j) FROM(SELECT 'Internal Error - Contact your DBA with the following error message: ' || error_msg1 as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;	 
END; 
$$ LANGUAGE 'plpgsql';
/******************************************************************
  pmt_activities
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_activities() RETURNS SETOF pmt_json_result_type AS $$
DECLARE 
  error_msg1 text;
  error_msg2 text;
  error_msg3 text; 
  rec record;
BEGIN 

    FOR rec IN (SELECT row_to_json(j) FROM(

	SELECT a.activity_id, a.title, ((SELECT array_agg(location_id)::int[] FROM location l WHERE l.activity_id = a.activity_id AND l.active = true)) as location_ids
	FROM activity a
	WHERE a.active = true
	ORDER BY a.title
	
	) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
     
EXCEPTION WHEN others THEN
    GET STACKED DIAGNOSTICS error_msg1 = MESSAGE_TEXT,
                          error_msg2 = PG_EXCEPTION_DETAIL,
                          error_msg3 = PG_EXCEPTION_HINT;
    FOR rec IN (SELECT row_to_json(j) FROM(SELECT 'Internal Error - Contact your DBA with the following error message: ' || error_msg1 as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;	 
END; 
$$ LANGUAGE 'plpgsql';
/******************************************************************
   pmt_edit_project_taxonomy
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_edit_project_taxonomy(user_id integer, project_id integer, classification_id integer, edit_action pmt_edit_action) RETURNS BOOLEAN AS 
$$
DECLARE
  valid_classification_id boolean;
  valid_project_id integer;
  record_id integer;
  t_id integer;
  i integer;
  rec record;
  error_msg1 text;
  error_msg2 text;
  error_msg3 text; 
BEGIN	

  -- first three parameters are required 
  IF ($1 IS NOT NULL) AND ($2 IS NOT NULL) AND ($3 IS NOT NULL) THEN
  
    IF (SELECT * FROM pmt_validate_project($2)) AND (SELECT * FROM pmt_validate_classification($3)) THEN
  
      -- get the taxonomy_id of the classification_id
      SELECT INTO t_id taxonomy_id FROM taxonomy_classifications tc WHERE tc.classification_id = $3;
      
      IF t_id IS NOT NULL THEN
        -- operations based on the requested edit action
        CASE $4          
          WHEN 'delete' THEN
            -- validate users authority to perform an update action on this project
            IF (SELECT * FROM pmt_validate_user_authority($1, $2, 'update')) THEN 
              EXECUTE 'DELETE FROM project_taxonomy WHERE project_id ='|| $2 ||' AND classification_id = '|| $3 ||' AND field = ''project_id'''; 
              RAISE NOTICE 'Delete Record: %', 'Remove association to classification_id ('|| $3 ||') for project_id ('|| $2 ||')';
            ELSE
              RAISE NOTICE 'Error: The requested edit action requires the user to have UPDATE rights to this project: %', $2;
	      RETURN FALSE;
            END IF;     
          WHEN 'replace' THEN
             -- validate users authority to perform an update and create action on this project
            IF (SELECT * FROM pmt_validate_user_authority($1, $2, 'update')) AND (SELECT * FROM pmt_validate_user_authority($1, $2, 'create')) THEN
            
              EXECUTE 'DELETE FROM project_taxonomy WHERE project_id ='|| $2 ||' AND classification_id in (SELECT classification_id FROM taxonomy_classifications WHERE taxonomy_id = '|| t_id||') AND field = ''project_id''';
              RAISE NOTICE 'Delete Record: %', 'Remove association to taxonomy_id ('|| t_id ||') for project_id ('|| $2 ||')';
	      EXECUTE 'INSERT INTO project_taxonomy(project_id, classification_id, field) VALUES ('|| $2 ||', '|| $3 ||', ''project_id'')'; 
              RAISE NOTICE 'Add Record: %', 'project_id ('|| $2 ||') is now associated to classification_id ('|| $3 ||').';
            ELSE
              RAISE NOTICE 'Error: The requested edit action requires the user to have UPDATE and CREATE rights to this project: %', $2;
	      RETURN FALSE;
            END IF;  
          ELSE
            -- validate users authority to perform a create action on this project
            IF (SELECT * FROM pmt_validate_user_authority($1, $2, 'create')) THEN 
              
              SELECT INTO record_id pt.project_id FROM project_taxonomy as pt WHERE pt.project_id = $2 AND pt.classification_id = $3 LIMIT 1;
              IF record_id IS NULL THEN
               EXECUTE 'INSERT INTO project_taxonomy(project_id, classification_id, field) VALUES ('|| $2 ||', '|| $3 ||', ''project_id'')';
               RAISE NOTICE 'Add Record: %', 'project_id ('|| $2 ||') is now associated to classification_id ('|| $3 ||').'; 
             ELSE
               RAISE NOTICE'Add Record: %', 'This project_id ('|| $2 ||') already has an association to this classification_id ('|| $3 ||').';                
             END IF;
             
            ELSE
              RAISE NOTICE 'Error: The requested edit action requires the user to have CREATE rights to this project: %', $2;
	      RETURN FALSE;
            END IF;        
        END CASE;
        RETURN true;
      ELSE
        RAISE NOTICE 'Error: There is no taxonomy_id for given classification_id.';
	RETURN false;
      END IF;
      
    ELSE
      RAISE NOTICE 'Error: Invalid project_id or classification_id.';
      RETURN false;
    END IF;
  ELSE
    RAISE NOTICE 'Error: Must provide user_id, project_id and classification_id parameters.';
    RETURN false;
  END IF;
  
EXCEPTION WHEN others THEN
  GET STACKED DIAGNOSTICS error_msg1 = MESSAGE_TEXT,
		  error_msg2 = PG_EXCEPTION_DETAIL,
		  error_msg3 = PG_EXCEPTION_HINT;
                          
  RAISE NOTICE 'Error: %', error_msg1;                          
  RETURN FALSE;   	  
END;$$ LANGUAGE plpgsql;
/******************************************************************
   pmt_edit_project
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_edit_project(user_id integer, project_id integer, key_value_data json, delete_record boolean default false) RETURNS SETOF pmt_json_result_type AS 
$$
DECLARE
  new_project_id integer;
  p_id integer;
  json record;
  column_record record;
  execute_statement text;
  invalid_editing_columns text[];
  delete_response json;
  user_name text;
  rec record;
  error_msg1 text;
  error_msg2 text;
  error_msg3 text;
BEGIN	
  -- set columns that are not editable via the parameters 
  invalid_editing_columns := ARRAY['project_id', 'active', 'retired_by', 'created_by', 'created_date', 'updated_by', 'updated_date'];
  
  -- user and data parameters are required
  IF ($1 IS NOT NULL) THEN
    IF NOT ($4) AND ($3 IS NULL) THEN
      FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: Must included json parameter when delete_record is false.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
    END IF;
  ELSE
    FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: Must included user_id parameter.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
  END IF; 

  -- get users name
  SELECT INTO user_name username FROM "user" WHERE "user".user_id = $1;

  -- if project_id is null then validate users authroity to create a new project record  
  IF ($2 IS NULL) THEN
    IF (SELECT * FROM pmt_validate_user_authority($1, null, 'create')) THEN
      EXECUTE 'INSERT INTO project(created_by, updated_by) VALUES (' || quote_literal(user_name) || ',' || quote_literal(user_name) || ') RETURNING project_id;' INTO new_project_id;
      RAISE NOTICE 'Created new project with id: %', new_project_id;
    ELSE
      FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: User does NOT have authority to create a new project.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
    END IF;
  -- validate project_id if provided and validate users authority to update an existing record  
  ELSE
    -- validate project_id
    IF (SELECT * FROM pmt_validate_project($2)) THEN 
      -- validate users authority to 'delete' this project
      IF ($4) THEN
        IF (SELECT * FROM pmt_validate_user_authority($1, $2, 'delete')) THEN
        -- deactivate this project          
          FOR rec IN (SELECT * FROM pmt_activate_project($1, $2, false)) LOOP  RETURN NEXT rec; END LOOP; RETURN;
        ELSE
          FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: User does NOT have authority to delete this project.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
        END IF;
      -- validate users authority to 'update' this activity
      ELSE        
        IF (SELECT * FROM pmt_validate_user_authority($1, $2, 'update')) THEN   
        ELSE
          FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: User does NOT have authority to update this project.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
        END IF;
      END IF;
    ELSE
      FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: Invalid project_id.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
    END IF;
  END IF;

  -- assign the project_id to use in statements
  IF new_project_id IS NOT NULL THEN
    p_id := new_project_id;
  ELSE
    p_id := $2;
  END IF;
    
  -- loop through the columns of the contact table        
  FOR json IN (SELECT * FROM json_each_text($3)) LOOP
    RAISE NOTICE 'JSON key/value: %', lower(json.key) || ':' || json.value;
    -- get the column information for column that user is requesting to edit	
    FOR column_record IN (SELECT * FROM information_schema.columns WHERE table_schema='public' AND table_name='project' AND column_name != ALL(invalid_editing_columns) AND lower(column_name) = lower(json.key)) LOOP 
      RAISE NOTICE 'Editing column: %', column_record.column_name;
      RAISE NOTICE 'Assigning new value: %', json.value;
      execute_statement := null;
      CASE column_record.data_type 
        WHEN 'integer', 'numeric' THEN              
          IF (SELECT pmt_isnumeric(json.value)) THEN
            execute_statement := 'UPDATE project SET ' || column_record.column_name || ' = ' || json.value || ' WHERE project_id = ' || p_id; 
          END IF;
          IF (lower(json.value) = 'null') THEN
            execute_statement := 'UPDATE project SET ' || column_record.column_name || ' = null WHERE project_id = ' || p_id; 
          END IF;
        ELSE
          -- if the value has the text null then assign the column value null
          IF (lower(json.value) = 'null') THEN
            execute_statement := 'UPDATE project SET ' || column_record.column_name || ' = null WHERE project_id = ' || p_id; 
          ELSE
            execute_statement := 'UPDATE project SET ' || column_record.column_name || ' = ' || quote_literal(json.value) || ' WHERE project_id = ' || p_id; 
          END IF;
      END CASE;
      IF execute_statement IS NOT NULL THEN
        RAISE NOTICE 'Statement: %', execute_statement;
        EXECUTE execute_statement;
                
        EXECUTE 'UPDATE project SET updated_by = ' || quote_literal(user_name) || ', updated_date = ' || quote_literal(current_date) || ' WHERE  project_id = ' || p_id;
      END IF;
    END LOOP;
  END LOOP;
  -- editing completed successfullly
  FOR rec IN (SELECT row_to_json(j) FROM(select p_id as id, 'Success' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;         
  
EXCEPTION WHEN others THEN
     GET STACKED DIAGNOSTICS error_msg1 = MESSAGE_TEXT,
                          error_msg2 = PG_EXCEPTION_DETAIL,
                          error_msg3 = PG_EXCEPTION_HINT;
    FOR rec IN (SELECT row_to_json(j) FROM(select p_id as id, 'Internal Error - Contact your DBA with the following error message: ' || error_msg1 as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;	  
END;$$ LANGUAGE plpgsql;
/******************************************************************
  pmt_validate_detail
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_validate_detail(id integer) RETURNS boolean AS $$
DECLARE valid_id integer;
BEGIN 
     IF $1 IS NULL THEN    
       RETURN false;
     END IF;    
     
     SELECT INTO valid_id detail_id FROM detail WHERE active = true AND detail_id = $1;	 

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
   pmt_edit_detail
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_edit_detail(user_id integer, detail_id integer, project_id integer, activity_id integer, key_value_data json, delete_record boolean default false) 
RETURNS SETOF pmt_json_result_type AS 
$$
DECLARE
  new_detail_id integer;
  p_id integer;
  a_id integer;
  d_id integer;
  json record;
  column_record record;
  execute_statement text;
  invalid_editing_columns text[];
  delete_response json;
  user_name text;
  rec record;
  error_msg1 text;
  error_msg2 text;
  error_msg3 text;
BEGIN	
  -- set columns that are not editable via the parameters 
  invalid_editing_columns := ARRAY['detail_id', 'project_id', 'activity_id', 'active', 'retired_by', 'created_by', 'created_date', 'updated_by', 'updated_date'];
  
  -- validate required parameters
  -- user_id always required
  IF ($1 IS NOT NULL) THEN
    -- if delete_record = false then json is required
    IF NOT ($6) AND ($5 IS NULL) THEN
      FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: Must included json parameter when delete_record is false.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
    ELSE
      IF ($2 IS NULL) AND ($6) THEN
        FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: Must included detail_id when delete_record is true.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
      END IF;
    END IF;
    -- must supply a detail_id, a project_id or activity_id
    IF ($2 IS NULL) AND ($3 IS NULL) AND ($4 IS NULL) THEN
      FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: Must included project_id or activity_id parameter when detail_id parameter is null.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
    END IF;
  ELSE
    FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: Must included user_id parameter.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
  END IF; 

  -- get users name
  SELECT INTO user_name username FROM "user" WHERE "user".user_id = $1;

  -- if detail_id is null then validate users authroity to create a new detail record  
  IF ($2 IS NULL) THEN
  
    -- validate the associated project/activity records
    IF ($3 IS NOT NULL) THEN
      IF (SELECT * FROM pmt_validate_project($3)) THEN  
        p_id := $3;
      ELSE
        FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: Invalid project_id.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
      END IF;      
    END IF;
    
    IF ($4 IS NOT NULL) THEN
        IF (SELECT * FROM pmt_validate_activity($4)) THEN  
          a_id := $4;
          SELECT INTO p_id a.project_id FROM activity a WHERE a.activity_id = $4;
        ELSE
          FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: Invalid activity_id.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
        END IF;
    END IF; 

    IF p_id IS NOT NULL THEN
      IF (SELECT * FROM pmt_validate_user_authority($1, p_id, 'create')) THEN
        IF a_id IS NOT NULL THEN
          EXECUTE 'INSERT INTO detail(project_id, activity_id, created_by, updated_by) VALUES (' || p_id  || ',' || a_id || ',' || quote_literal(user_name) || ',' 
		|| quote_literal(user_name) || ') RETURNING detail_id;' INTO new_detail_id;
        ELSE
          EXECUTE 'INSERT INTO detail(project_id, created_by, updated_by) VALUES (' || p_id  || ',' || quote_literal(user_name) || ',' 
		|| quote_literal(user_name) || ') RETURNING detail_id;' INTO new_detail_id;
        END IF;
        
        RAISE NOTICE 'Created new detail with id: %', new_detail_id;
      ELSE
        FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: User does NOT have authority to create a new detail record for project id ' || p_id as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
      END IF;
    ELSE
      FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: Must provide a valid project_id.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
    END IF;
    
  -- validate detail_id if provided and validate users authority to update an existing record  
  ELSE  
    -- validate detail_id
    IF (SELECT * FROM pmt_validate_detail($2)) THEN 
      -- get project_id from detail record
      SELECT INTO p_id d.project_id FROM detail d WHERE d.detail_id = $2;      
      -- validate users authority to 'delete' this detail
      IF ($6) THEN
        IF (SELECT * FROM pmt_validate_user_authority($1, p_id, 'delete')) THEN
          -- deactivate this detail 
          EXECUTE 'UPDATE detail SET active = false WHERE detail_id = ' || $2;
        ELSE
          FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: User does NOT have authority to delete this detail for project id ' || p_id  as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
        END IF;
      -- validate users authority to 'update' this activity
      ELSE        
        IF (SELECT * FROM pmt_validate_user_authority($1, p_id, 'update')) THEN   
        ELSE
          FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: User does NOT have authority to update this project.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
        END IF;
      END IF;
    ELSE
      FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: Invalid detail_id.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
    END IF;
  END IF;

  -- assign the project_id to use in statements
  IF new_detail_id IS NOT NULL THEN
    d_id := new_detail_id;
  ELSE
    d_id := $2;
  END IF;
    
  -- loop through the columns of the detail table        
  FOR json IN (SELECT * FROM json_each_text($5)) LOOP
    RAISE NOTICE 'JSON key/value: %', lower(json.key) || ':' || json.value;
    -- get the column information for column that user is requesting to edit	
    FOR column_record IN (SELECT * FROM information_schema.columns WHERE table_schema='public' AND table_name='detail' AND column_name != ALL(invalid_editing_columns) AND lower(column_name) = lower(json.key)) LOOP 
      RAISE NOTICE 'Editing column: %', column_record.column_name;
      RAISE NOTICE 'Assigning new value: %', json.value;
      execute_statement := null;
      CASE column_record.data_type 
        WHEN 'integer', 'numeric' THEN              
          IF (SELECT pmt_isnumeric(json.value)) THEN
            execute_statement := 'UPDATE detail SET ' || column_record.column_name || ' = ' || json.value || ' WHERE detail_id = ' || d_id; 
          END IF;
          IF (lower(json.value) = 'null') THEN
            execute_statement := 'UPDATE detail SET ' || column_record.column_name || ' = null WHERE detail_id = ' || d_id; 
          END IF;
        ELSE
          -- if the value has the text null then assign the column value null
          IF (lower(json.value) = 'null') THEN
            execute_statement := 'UPDATE detail SET ' || column_record.column_name || ' = null WHERE detail_id = ' || d_id; 
          ELSE
            execute_statement := 'UPDATE detail SET ' || column_record.column_name || ' = ' || quote_literal(json.value) || ' WHERE detail_id = ' || d_id; 
          END IF;
      END CASE;
      IF execute_statement IS NOT NULL THEN
        RAISE NOTICE 'Statement: %', execute_statement;
        EXECUTE execute_statement;
                
        EXECUTE 'UPDATE detail SET updated_by = ' || quote_literal(user_name) || ', updated_date = ' || quote_literal(current_date) || ' WHERE  detail_id = ' || d_id;
      END IF;
    END LOOP;
  END LOOP;
  -- editing completed successfullly
  FOR rec IN (SELECT row_to_json(j) FROM(select d_id as id, 'Success' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;         
  
EXCEPTION WHEN others THEN
     GET STACKED DIAGNOSTICS error_msg1 = MESSAGE_TEXT,
                          error_msg2 = PG_EXCEPTION_DETAIL,
                          error_msg3 = PG_EXCEPTION_HINT;
    FOR rec IN (SELECT row_to_json(j) FROM(select d_id as id, 'Internal Error - Contact your DBA with the following error message: ' || error_msg1 as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;	  
END;$$ LANGUAGE plpgsql;
/******************************************************************
  pmt_validate_financial
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_validate_financial(id integer) RETURNS boolean AS $$
DECLARE valid_id integer;
BEGIN 
     IF $1 IS NULL THEN    
       RETURN false;
     END IF;    
     
     SELECT INTO valid_id financial_id FROM financial WHERE active = true AND financial_id = $1;	 

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
   pmt_edit_financial
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_edit_financial(user_id integer, financial_id integer, project_id integer, activity_id integer, key_value_data json, delete_record boolean default false) 
RETURNS SETOF pmt_json_result_type AS 
$$
DECLARE
  new_financial_id integer;
  p_id integer;
  a_id integer;
  f_id integer;
  json record;
  column_record record;
  execute_statement text;
  invalid_editing_columns text[];
  user_name text;
  rec record;
  error_msg1 text;
  error_msg2 text;
  error_msg3 text;
BEGIN	
  -- set columns that are not editable via the parameters 
  invalid_editing_columns := ARRAY['financial_id', 'project_id', 'activity_id', 'active', 'retired_by', 'created_by', 'created_date', 'updated_by', 'updated_date'];
  
  -- validate required parameters
  -- user_id always required
  IF ($1 IS NOT NULL) THEN
    -- if delete_record = false then json is required
    IF NOT ($6) AND ($5 IS NULL) THEN
      FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: Must included json parameter when delete_record is false.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
    ELSE
      IF ($2 IS NULL) AND ($6) THEN
        FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: Must included financial_id when delete_record is true.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
      END IF;
    END IF;
    -- must supply a financial_id, a project_id or activity_id
    IF ($2 IS NULL) AND ($3 IS NULL) AND ($4 IS NULL) THEN
      FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: Must included project_id or activity_id parameter when financial_id parameter is null.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
    END IF;
  ELSE
    FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: Must included user_id parameter.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
  END IF; 

  -- get users name
  SELECT INTO user_name username FROM "user" WHERE "user".user_id = $1;

  -- if financial_id is null then validate users authroity to create a new financial record  
  IF ($2 IS NULL) THEN
  
    -- validate the associated project/activity records
    IF ($3 IS NOT NULL) THEN
      IF (SELECT * FROM pmt_validate_project($3)) THEN  
        p_id := $3;
      ELSE
        FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: Invalid project_id.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
      END IF;      
    END IF;
    
    IF ($4 IS NOT NULL) THEN
        IF (SELECT * FROM pmt_validate_activity($4)) THEN  
          a_id := $4;
          SELECT INTO p_id a.project_id FROM activity a WHERE a.activity_id = $4;
        ELSE
          FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: Invalid activity_id.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
        END IF;
    END IF; 

    IF p_id IS NOT NULL THEN
      IF (SELECT * FROM pmt_validate_user_authority($1, p_id, 'create')) THEN
        IF a_id IS NOT NULL THEN
          EXECUTE 'INSERT INTO financial(project_id, activity_id, created_by, updated_by) VALUES (' || p_id  || ',' || a_id || ',' || quote_literal(user_name) || ',' 
		|| quote_literal(user_name) || ') RETURNING financial_id;' INTO new_financial_id;
        ELSE
          EXECUTE 'INSERT INTO financial(project_id, created_by, updated_by) VALUES (' || p_id  || ',' || quote_literal(user_name) || ',' 
		|| quote_literal(user_name) || ') RETURNING financial_id;' INTO new_financial_id;
        END IF;
        
        RAISE NOTICE 'Created new financial with id: %', new_financial_id;
      ELSE
        FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: User does NOT have authority to create a new financial record for project id ' || p_id as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
      END IF;
    ELSE
      FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: Must provide a valid project_id.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
    END IF;
    
  -- validate financial_id if provided and validate users authority to update an existing record  
  ELSE  
    -- validate financial_id
    IF (SELECT * FROM pmt_validate_financial($2)) THEN 
      -- get project_id from financial record
      SELECT INTO p_id f.project_id FROM financial f WHERE f.financial_id = $2;      
      -- validate users authority to 'delete' this financial
      IF ($6) THEN
        IF (SELECT * FROM pmt_validate_user_authority($1, p_id, 'delete')) THEN
          -- deactivate this financial 
          EXECUTE 'UPDATE financial SET active = false WHERE financial_id = ' || $2;
        ELSE
          FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: User does NOT have authority to delete this financial record for project id ' || p_id  as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
        END IF;
      -- validate users authority to 'update' this activity
      ELSE        
        IF (SELECT * FROM pmt_validate_user_authority($1, p_id, 'update')) THEN   
        ELSE
          FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: User does NOT have authority to update this project.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
        END IF;
      END IF;
    ELSE
      FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: Invalid financial_id.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
    END IF;
  END IF;

  -- assign the project_id to use in statements
  IF new_financial_id IS NOT NULL THEN
    f_id := new_financial_id;
  ELSE
    f_id := $2;
  END IF;
    
  -- loop through the columns of the contact table        
  FOR json IN (SELECT * FROM json_each_text($5)) LOOP
    RAISE NOTICE 'JSON key/value: %', lower(json.key) || ':' || json.value;
    -- get the column information for column that user is requesting to edit	
    FOR column_record IN (SELECT * FROM information_schema.columns WHERE table_schema='public' AND table_name='financial' AND column_name != ALL(invalid_editing_columns) AND lower(column_name) = lower(json.key)) LOOP 
      RAISE NOTICE 'Editing column: %', column_record.column_name;
      RAISE NOTICE 'Assigning new value: %', json.value;
      execute_statement := null;
      CASE column_record.data_type 
        WHEN 'integer', 'numeric' THEN              
          IF (SELECT pmt_isnumeric(json.value)) THEN
            execute_statement := 'UPDATE financial SET ' || column_record.column_name || ' = ' || json.value || ' WHERE financial_id = ' || f_id; 
          END IF;
          IF (lower(json.value) = 'null') THEN
            execute_statement := 'UPDATE financial SET ' || column_record.column_name || ' = null WHERE financial_id = ' || f_id; 
          END IF;
        ELSE
          -- if the value has the text null then assign the column value null
          IF (lower(json.value) = 'null') THEN
            execute_statement := 'UPDATE financial SET ' || column_record.column_name || ' = null WHERE financial_id = ' || f_id; 
          ELSE
            execute_statement := 'UPDATE financial SET ' || column_record.column_name || ' = ' || quote_literal(json.value) || ' WHERE financial_id = ' || f_id; 
          END IF;
      END CASE;
      IF execute_statement IS NOT NULL THEN
        RAISE NOTICE 'Statement: %', execute_statement;
        EXECUTE execute_statement;
                
        EXECUTE 'UPDATE financial SET updated_by = ' || quote_literal(user_name) || ', updated_date = ' || quote_literal(current_date) || ' WHERE  financial_id = ' || f_id;
      END IF;
    END LOOP;
  END LOOP;
  -- editing completed successfullly
  FOR rec IN (SELECT row_to_json(j) FROM(select f_id as id, 'Success' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;         
  
EXCEPTION WHEN others THEN
     GET STACKED DIAGNOSTICS error_msg1 = MESSAGE_TEXT,
                          error_msg2 = PG_EXCEPTION_DETAIL,
                          error_msg3 = PG_EXCEPTION_HINT;
    FOR rec IN (SELECT row_to_json(j) FROM(select f_id as id, 'Internal Error - Contact your DBA with the following error message: ' || error_msg1 as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;	  
END;$$ LANGUAGE plpgsql;
/******************************************************************
   pmt_edit_organization
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_edit_organization(user_id integer, organization_id integer, key_value_data json, delete_record boolean default false) RETURNS SETOF pmt_json_result_type AS 
$$
DECLARE
  new_organization_id integer;
  o_id integer;
  json record;
  column_record record;
  execute_statement text;
  invalid_editing_columns text[];
  user_name text;
  rec record;
  error_msg1 text;
  error_msg2 text;
  error_msg3 text;
BEGIN	
  -- set columns that are not editable via the parameters 
  invalid_editing_columns := ARRAY['organization_id', 'active', 'retired_by', 'created_by', 'created_date', 'updated_by', 'updated_date'];
  
  -- user and data parameters are required
  IF ($1 IS NOT NULL) THEN
    IF NOT ($4) AND ($3 IS NULL) THEN
      FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: Must included json parameter when delete_record is false.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
    END IF;
  ELSE
    FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: Must included user_id parameter.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
  END IF; 


  -- get users name
  SELECT INTO user_name username FROM "user" WHERE "user".user_id = $1;

  -- if organization_id is null then validate users authroity to create a new organization record  
  IF ($2 IS NULL) THEN
    IF (SELECT * FROM pmt_validate_user_authority($1, null, 'create')) THEN
      EXECUTE 'INSERT INTO organization(created_by, updated_by) VALUES (' || quote_literal(user_name) || ',' || quote_literal(user_name) || ') RETURNING organization_id;' INTO new_organization_id;
      RAISE NOTICE 'Created new organization with id: %', new_organization_id;
    ELSE
      FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: User does NOT have authority to create a new organization.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
    END IF;
  -- validate organization_id if provided and validate users authority to update an existing record  
  ELSE      
    IF (SELECT * FROM pmt_validate_organization($2)) THEN 
       -- validate users authority to 'delete' this organization
      IF ($4) THEN
        IF (SELECT * FROM pmt_validate_user_authority($1, null, 'delete')) THEN
          -- deactivate this organization          
          EXECUTE 'UPDATE organization SET active = false WHERE organization.organization_id = ' || $2;
        ELSE
          FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: User does NOT have authority to delete this organization.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
        END IF;
      -- validate users authority to 'update' this activity
      ELSE             
        IF (SELECT * FROM pmt_validate_user_authority($1, null, 'update')) THEN   
        ELSE
          FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: User does NOT have authority to update an existing organization.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
        END IF;
      END IF;
    ELSE
      FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: Invalid organization_id.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
    END IF;
  END IF;
             
  -- assign the organization_id to use in statements
  IF new_organization_id IS NOT NULL THEN
    o_id := new_organization_id;
  ELSE
    o_id := $2;
  END IF;
  
  -- loop through the columns of the organization table        
  FOR json IN (SELECT * FROM json_each_text($3)) LOOP
    RAISE NOTICE 'JSON key/value: %', lower(json.key) || ':' || json.value;
    -- get the column information for column that user is requesting to edit	
    FOR column_record IN (SELECT * FROM information_schema.columns WHERE table_schema='public' AND table_name='organization' AND column_name != ALL(invalid_editing_columns) AND lower(column_name) = lower(json.key)) LOOP 
      RAISE NOTICE 'Editing column: %', column_record.column_name;
      RAISE NOTICE 'Assigning new value: %', json.value;
      execute_statement := null;
      CASE column_record.data_type 
        WHEN 'integer', 'numeric' THEN              
          IF (SELECT pmt_isnumeric(json.value)) THEN
            execute_statement := 'UPDATE organization SET ' || column_record.column_name || ' = ' || json.value || ' WHERE organization_id = ' || o_id; 
          END IF;
           IF (lower(json.value) = 'null') THEN
            execute_statement := 'UPDATE organization SET ' || column_record.column_name || ' = null WHERE organization_id = ' || o_id; 
          END IF;
        ELSE
          -- if the value has the text null then assign the column value null
          IF (lower(json.value) = 'null') THEN
            execute_statement := 'UPDATE organization SET ' || column_record.column_name || ' = null WHERE organization_id = ' || o_id; 
          ELSE
            execute_statement := 'UPDATE organization SET ' || column_record.column_name || ' = ' || quote_literal(json.value) || ' WHERE organization_id = ' || o_id; 
          END IF;
      END CASE;
      IF execute_statement IS NOT NULL THEN
        RAISE NOTICE 'Statement: %', execute_statement;
        EXECUTE execute_statement;
                
        EXECUTE 'UPDATE organization SET updated_by = ' || quote_literal(user_name) || ', updated_date = ' || quote_literal(current_date) || ' WHERE  organization_id = ' || o_id;
      END IF;
    END LOOP;
  END LOOP;
  -- editing completed successfullly
  FOR rec IN (SELECT row_to_json(j) FROM(select o_id as id, 'Success' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
   
EXCEPTION WHEN others THEN
    GET STACKED DIAGNOSTICS error_msg1 = MESSAGE_TEXT,
                          error_msg2 = PG_EXCEPTION_DETAIL,
                          error_msg3 = PG_EXCEPTION_HINT;
    FOR rec IN (SELECT row_to_json(j) FROM(select o_id as id, 'Internal Error - organization your DBA with the following error message: ' || error_msg1 as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;	  
END;$$ LANGUAGE plpgsql;
/******************************************************************
  pmt_edit_location
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_edit_location(user_id integer, location_id integer, activity_id integer, key_value_data json, delete_record boolean default false) RETURNS SETOF pmt_json_result_type AS 
$$
DECLARE
  new_location_id integer;
  p_id integer;
  a_id integer;
  l_id integer;
  json record;
  column_record record;
  execute_statement text;
  invalid_editing_columns text[];
  delete_response json;
  user_name text;
  rec record;
  error_msg1 text;
  error_msg2 text;
  error_msg3 text;
BEGIN	
  -- set columns that are not editable via the parameters 
  invalid_editing_columns := ARRAY['location_id','activity_id','project_id', 'x', 'y', 'lat_dd', 'long_dd', 'latlong', 'georef', 
				   'active', 'retired_by', 'created_by', 'created_date', 'updated_by', 'updated_date'];
  
  -- user_id is required for all operations
  IF ($1 IS NOT NULL) THEN
    -- update/create operation
    IF NOT ($5) THEN
      -- json is required
      IF ($4 IS NULL) THEN
        FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: The json parameter is required for a create/update operation.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
      END IF;
      -- activity_id is required if location_id is null
      IF ($2 IS NULL) AND ($3 IS NULL) THEN
        FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: activity_id is required for a create operation.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
      END IF;
    -- delete operation	
    ELSE
      -- location_id is requried
      IF ($2 IS NULL) THEN
        FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: location_id is required for a delete operation.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
      END IF;
    END IF;
  -- error if user_id    
  ELSE
    FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: user_id is a required parameter for all operations.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
  END IF; 

  -- get users name
  SELECT INTO user_name username FROM "user" WHERE "user".user_id = $1;

  -- if location_id is null then validate users authroity to create a new location record  
  IF ($2 IS NULL) THEN
    -- validate activity_id
    IF (SELECT * FROM pmt_validate_activity($3)) THEN 
      SELECT INTO p_id a.project_id FROM activity a WHERE a.activity_id = $3;
      IF (SELECT * FROM pmt_validate_user_authority($1, p_id, 'create')) THEN
        EXECUTE 'INSERT INTO location(project_id, activity_id, created_by, updated_by) VALUES (' || p_id || ',' || $3 || ',' || quote_literal(user_name) || ',' || quote_literal(user_name) || ') RETURNING location_id;' INTO new_location_id;
        RAISE NOTICE 'Created new location with id: %', new_location_id;
      ELSE
        FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: User does NOT have authority to create a new location for activity_id: ' || $3 as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
      END IF;
    ELSE
      FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: activity_id is not valid.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
    END IF;
  -- validate location_id if provided and validate users authority to update an existing record  
  ELSE    
    -- validate location_id
    IF (SELECT * FROM pmt_validate_location($2)) THEN 
      -- get project_id and activity_id for location
      SELECT INTO p_id l.project_id FROM location l WHERE l.location_id = $2;      
      SELECT INTO a_id l.activity_id FROM location l WHERE l.location_id = $2;      
      -- validate users authority to 'delete' this activity
      IF ($5) THEN
        IF (SELECT * FROM pmt_validate_user_authority($1, p_id, 'delete')) THEN
          -- deactivate this activity          
          EXECUTE 'UPDATE location SET active = false, updated_by = ' || quote_literal(user_name) || ', updated_date = ' || quote_literal(current_date) || ' WHERE location_id = ' || $2;
        ELSE
          FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: User does NOT have authority to delete this location.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
        END IF;
      -- validate users authority to 'update' this activity
      ELSE        
        IF (SELECT * FROM pmt_validate_user_authority($1, p_id, 'update')) THEN   
        ELSE
          FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: User does NOT have authority to update this location.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
        END IF;
      END IF;
    ELSE
      FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: Invalid location_id.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
    END IF;
  END IF;

  -- assign the location_id to use in statements
  IF new_location_id IS NOT NULL THEN
    l_id := new_location_id;
  ELSE
    l_id := $2;
  END IF;
    
  -- loop through the columns of the activity table        
  FOR json IN (SELECT * FROM json_each_text($4)) LOOP
    RAISE NOTICE 'JSON key/value: %', lower(json.key) || ':' || json.value;
    -- get the column information for column that user is requesting to edit	
    FOR column_record IN (SELECT * FROM information_schema.columns WHERE table_schema='public' AND table_name='location' AND column_name != ALL(invalid_editing_columns) AND lower(column_name) = lower(json.key)) LOOP 
      RAISE NOTICE 'Editing column: %', column_record.column_name;
      RAISE NOTICE 'Assigning new value: %', json.value;
      RAISE NOTICE 'Column type: %', column_record.data_type;
      execute_statement := null;
      CASE column_record.data_type 
        WHEN 'integer', 'numeric' THEN              
          IF (SELECT pmt_isnumeric(json.value)) THEN
            execute_statement := 'UPDATE location SET ' || column_record.column_name || ' = ' || json.value || ' WHERE location_id = ' || l_id; 
          END IF;
          IF (lower(json.value) = 'null') THEN
            execute_statement := 'UPDATE location SET ' || column_record.column_name || ' = null WHERE location_id = ' || l_id; 
          END IF;
        WHEN 'USER-DEFINED' THEN
          IF(column_record.udt_name = 'geometry') THEN
	    -- per documenation assumes projection is (WGS84: 4326)
            execute_statement := 'UPDATE location SET ' || column_record.column_name || ' = ST_GeomFromText(' || quote_literal(json.value) || ', 4326) WHERE location_id = ' || l_id; 
          END IF;
        ELSE
          -- if the value has the text null then assign the column value null
          IF (lower(json.value) = 'null') THEN
            execute_statement := 'UPDATE location SET ' || column_record.column_name || ' = null WHERE location_id = ' || l_id; 
          ELSE
            execute_statement := 'UPDATE location SET ' || column_record.column_name || ' = ' || quote_literal(json.value) || ' WHERE location_id = ' || l_id; 
          END IF;
      END CASE;
      IF execute_statement IS NOT NULL THEN
        RAISE NOTICE 'Statement: %', execute_statement;
        EXECUTE execute_statement;
                
        EXECUTE 'UPDATE location SET updated_by = ' || quote_literal(user_name) || ', updated_date = ' || quote_literal(current_date) || ' WHERE  location_id = ' || l_id;
      END IF;
    END LOOP;
  END LOOP;
  -- editing completed successfullly
  FOR rec IN (SELECT row_to_json(j) FROM(select l_id as id, 'Success' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;         
  
EXCEPTION WHEN others THEN
     GET STACKED DIAGNOSTICS error_msg1 = MESSAGE_TEXT,
                          error_msg2 = PG_EXCEPTION_DETAIL,
                          error_msg3 = PG_EXCEPTION_HINT;
    FOR rec IN (SELECT row_to_json(j) FROM(select l_id as id, 'Internal Error - Contact your DBA with the following error message: ' || error_msg1 as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;	  
END;$$ LANGUAGE plpgsql;
/******************************************************************
  pmt_validate_location
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_validate_location(id integer) RETURNS boolean AS $$
DECLARE valid_id integer;
BEGIN 
     IF $1 IS NULL THEN    
       RETURN false;
     END IF;    
     
     SELECT INTO valid_id location_id FROM location WHERE active = true AND location_id = $1;	 

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
   pmt_edit_location_taxonomy
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_edit_location_taxonomy(user_id integer, location_id integer, classification_id integer, edit_action pmt_edit_action) RETURNS BOOLEAN AS 
$$
DECLARE
  valid_classification_id boolean;
  valid_location_id integer;
  record_id integer;
  t_id integer;
  i integer;
  rec record;
  error_msg1 text;
  error_msg2 text;
  error_msg3 text; 
BEGIN	

  -- first three parameters are required 
  IF ($1 IS NOT NULL) AND ($2 IS NOT NULL) AND ($3 IS NOT NULL) THEN
  
    IF (SELECT * FROM pmt_validate_location($2)) AND (SELECT * FROM pmt_validate_classification($3)) THEN
  
      -- get the taxonomy_id of the classification_id
      SELECT INTO t_id taxonomy_id FROM taxonomy_classifications tc WHERE tc.classification_id = $3;
      
      IF t_id IS NOT NULL THEN
        -- operations based on the requested edit action
        CASE $4          
          WHEN 'delete' THEN
            -- validate users authority to perform an update action on this location
            IF (SELECT * FROM pmt_validate_user_authority($1, $2, 'update')) THEN 
              EXECUTE 'DELETE FROM location_taxonomy WHERE location_id ='|| $2 ||' AND classification_id = '|| $3 ||' AND field = ''location_id'''; 
              RAISE NOTICE 'Delete Record: %', 'Remove association to classification_id ('|| $3 ||') for location_id ('|| $2 ||')';
            ELSE
              RAISE NOTICE 'Error: The requested edit action requires the user to have UPDATE rights to this location: %', $2;
	      RETURN FALSE;
            END IF;     
          WHEN 'replace' THEN
             -- validate users authority to perform an update and create action on this location
            IF (SELECT * FROM pmt_validate_user_authority($1, $2, 'update')) AND (SELECT * FROM pmt_validate_user_authority($1, $2, 'create')) THEN
            
              EXECUTE 'DELETE FROM location_taxonomy WHERE location_id ='|| $2 ||' AND classification_id in (SELECT classification_id FROM taxonomy_classifications WHERE taxonomy_id = '|| t_id||') AND field = ''location_id''';
              RAISE NOTICE 'Delete Record: %', 'Remove association to taxonomy_id ('|| t_id ||') for location_id ('|| $2 ||')';
	      EXECUTE 'INSERT INTO location_taxonomy(location_id, classification_id, field) VALUES ('|| $2 ||', '|| $3 ||', ''location_id'')'; 
              RAISE NOTICE 'Add Record: %', 'location_id ('|| $2 ||') is now associated to classification_id ('|| $3 ||').';
            ELSE
              RAISE NOTICE 'Error: The requested edit action requires the user to have UPDATE and CREATE rights to this location: %', $2;
	      RETURN FALSE;
            END IF;  
          ELSE
            -- validate users authority to perform a create action on this location
            IF (SELECT * FROM pmt_validate_user_authority($1, $2, 'create')) THEN 
              
              SELECT INTO record_id pt.location_id FROM location_taxonomy as pt WHERE pt.location_id = $2 AND pt.classification_id = $3 LIMIT 1;
              IF record_id IS NULL THEN
               EXECUTE 'INSERT INTO location_taxonomy(location_id, classification_id, field) VALUES ('|| $2 ||', '|| $3 ||', ''location_id'')';
               RAISE NOTICE 'Add Record: %', 'location_id ('|| $2 ||') is now associated to classification_id ('|| $3 ||').'; 
             ELSE
               RAISE NOTICE'Add Record: %', 'This location_id ('|| $2 ||') already has an association to this classification_id ('|| $3 ||').';                
             END IF;
             
            ELSE
              RAISE NOTICE 'Error: The requested edit action requires the user to have CREATE rights to this location: %', $2;
	      RETURN FALSE;
            END IF;        
        END CASE;
        RETURN true;
      ELSE
        RAISE NOTICE 'Error: There is no taxonomy_id for given classification_id.';
	RETURN false;
      END IF;
      
    ELSE
      RAISE NOTICE 'Error: Invalid location_id or classification_id.';
      RETURN false;
    END IF;
  ELSE
    RAISE NOTICE 'Error: Must provide user_id, location_id and classification_id parameters.';
    RETURN false;
  END IF;
  
EXCEPTION WHEN others THEN
  GET STACKED DIAGNOSTICS error_msg1 = MESSAGE_TEXT,
		  error_msg2 = PG_EXCEPTION_DETAIL,
		  error_msg3 = PG_EXCEPTION_HINT;
                          
  RAISE NOTICE 'Error: %', error_msg1;                          
  RETURN FALSE;   	  
END;$$ LANGUAGE plpgsql;
/******************************************************************
  pmt_validate_boundary_feature
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_validate_boundary_feature(boundary_id integer, feature_id integer) RETURNS boolean AS $$
DECLARE valid_id integer;
	spatialtable text;
	execute_statement text;
BEGIN 
     IF $1 IS NULL OR $2 IS NULL THEN    
       RETURN false;
     END IF;    

     SELECT INTO spatialtable spatial_table FROM boundary WHERE active = true AND boundary.boundary_id = $1;	
     RAISE NOTICE 'spatialtable: % ...', spatialtable; 

     IF spatialtable IS NOT NULL THEN
       execute_statement := 'SELECT feature_id FROM ' || quote_ident(spatialtable) || ' WHERE feature_id = ' || $2 ;
       EXECUTE execute_statement INTO valid_id;
       RAISE NOTICE 'valid_id : % ...', valid_id; 
     ELSE
       RETURN false;
     END IF;
     
     IF valid_id IS NULL THEN
      RETURN false;
     ELSE 
      RETURN true;
     END IF;
     
EXCEPTION WHEN OTHERS THEN
    RETURN FALSE;
END; 
$$ LANGUAGE 'plpgsql'; 
/******************************************************************
  pmt_validate_locations
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_validate_locations(location_ids character varying) RETURNS INT[] AS $$
DECLARE 
  valid_location_ids INT[];
  filter_location_ids INT[];
BEGIN 
     IF $1 IS NULL THEN    
       RETURN valid_location_ids;
     END IF;

     filter_location_ids := string_to_array($1, ',')::int[];
     
     SELECT INTO valid_location_ids array_agg(DISTINCT location_id)::INT[] FROM (SELECT location_id FROM location WHERE active = true AND location_id = ANY(filter_location_ids) ORDER BY location_id) AS t;
     
     RETURN valid_location_ids;

EXCEPTION
     WHEN others THEN RETURN NULL;
END; 
$$ LANGUAGE 'plpgsql';
/******************************************************************
  pmt_locations
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_locations(location_ids character varying) RETURNS SETOF pmt_json_result_type AS 
$$
DECLARE
  rec record;
  invalid_return_columns text[];
  valid_location_ids integer[];
  return_columns text;
  execute_statement text;
  boundary_features text;
  boundary_tables text[];
  data_message text;
BEGIN
  IF $1 IS NOT NULL THEN
    -- validate location_ids
    select into valid_location_ids * from pmt_validate_locations($1);
    -- set columns that are not to be returned 
    invalid_return_columns := ARRAY['active', 'retired_by', 'created_by', 'created_date', 'point'];
    -- get list of columns to return
    SELECT INTO return_columns array_to_string(array_agg('l.' || column_name::text), ', ') FROM information_schema.columns 
    WHERE table_schema='public' AND table_name='location' AND column_name != ALL(invalid_return_columns);
    IF (valid_location_ids IS NOT NULL) THEN
      -- dynamically build boundary_features
      FOR rec IN (SELECT spatial_table FROM boundary) LOOP  		
        boundary_tables := array_append(boundary_tables, ' select boundary_id, feature_id, polygon from ' || rec.spatial_table || ' ');   
      END LOOP;
    
      boundary_features:= ' (' || array_to_string(boundary_tables, ' UNION ') || ') as boundary_features ';
    
      -- dynamically build the execute statment	
      execute_statement := 'SELECT ' || return_columns || ' ';

      -- taxonomy	
      execute_statement := execute_statement || ',(SELECT array_to_json(array_agg(row_to_json(t))) FROM ( ' ||
				'select tc.taxonomy_id, tc.taxonomy, tc.classification_id, tc.classification, tc.code ' ||
				'from location_taxonomy lt ' ||
				'join taxonomy_classifications  tc ' ||
				'on lt.classification_id = tc.classification_id ' ||
				'and lt.location_id = l.location_id'
				') t ) as taxonomy ';       							
      -- point
      execute_statement := execute_statement || ', ST_AsGeoJSON(point) as point ';  				
      -- polygon
      execute_statement := execute_statement || ', (SELECT ST_AsGeoJSON(polygon) FROM ' || boundary_features || ' WHERE boundary_id = l.boundary_id AND feature_id = l.feature_id) as polygon ';  
   				
      -- location
      execute_statement := execute_statement || 'from (select * from location l where l.active = true and l.location_id = ANY(ARRAY[' || array_to_string(valid_location_ids, ',') || '])) l ';    


      RAISE NOTICE 'Execute statement: %', execute_statement;			

      FOR rec IN EXECUTE 'SELECT row_to_json(j) FROM (' || execute_statement || ')j' LOOP  		
	  RETURN NEXT rec;
      END LOOP;
      ELSE
         FOR rec IN (SELECT row_to_json(j) FROM(select 'Error: No valid location ids: ' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
      END IF;
   END IF;
END;$$ LANGUAGE plpgsql;
/******************************************************************
  pmt_category_root (overloaded method)
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_category_root(id integer, data_group character varying) RETURNS INT AS $$
DECLARE 
  valid_taxonomy_id boolean;
  base_taxonomy_ids integer[];
  base_taxonomy_id integer;
  data_group_ids integer[];
  classification_ids integer[];
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
           RAISE NOTICE 'sub category: %', sub_category.taxonomy_id || ' ' || sub_category.is_category;
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
       classification_ids := string_to_array($2, ',')::int[];
       -- check that the data group exists
       SELECT INTO data_group_ids array_agg(classification.classification_id) FROM classification WHERE classification.classification_id = ANY(classification_ids) AND classification.taxonomy_id = (SELECT taxonomy.taxonomy_id FROM taxonomy WHERE name = 'Data Group');
       RAISE NOTICE 'data groups: %', array_to_string(data_group_ids, ',');
       -- add where statement if data group is valid
       IF data_group_ids IS NOT NULL THEN	
          dynamic_where1 := ' and project_id in (select distinct project_id from taxonomy_lookup where classification_id = ANY(ARRAY[' || array_to_string(data_group_ids, ',') || ']))';
          dynamic_where2 := ' and project_id in (select distinct project_id from taxonomy_lookup where classification_id = ANY(ARRAY[' || array_to_string(data_group_ids, ',') || ']))';
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

     RAISE NOTICE 'Execute statement: %', execute_statement;
     
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
-------------------------------------------------------------------
-- taxonomy
-------------------------------------------------------------------
-- taxonomy_classifications
CREATE OR REPLACE VIEW  taxonomy_classifications AS
(SELECT t.taxonomy_id, t.name as taxonomy, t.is_category, t.category_id as taxonomy_category_id, t.iati_codelist, t.description, 
c.classification_id, c.name as classification, c.code, c.category_id as classification_category_id, c.iati_code, c.iati_name
FROM taxonomy t
JOIN classification c
ON t.taxonomy_id = c.taxonomy_id
WHERE t.active = true and c.active = true
ORDER BY t.taxonomy_id, c.classification_id);
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
WHERE o.active = true and p.active = true
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
and o.active = true and p.active = true
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
SELECT code, name, 'District' as "type", gaul0_name, gaul1_name, name AS gaul2_name, ST_AsGeoJSON(Box2D(polygon)) AS bounds
FROM gaul2
UNION
SELECT DISTINCT gaul1.code, gaul1.name, 'Region' as "type", gaul2.gaul0_name, gaul1.name AS gaul1_name, null AS gaul2_name, ST_AsGeoJSON(Box2D(gaul1.polygon))  AS bounds 
FROM gaul1 
JOIN gaul2 ON gaul1.name = gaul2.gaul1_name
UNION
SELECT DISTINCT gaul0.code, gaul0.name, 'Country' as "type", gaul0.name, null AS gaul1_name, null AS gaul2_name, ST_AsGeoJSON(Box2D(gaul0.polygon))  AS bounds 
FROM gaul0;
-------------------------------------------------------------------
-- Data Loading Report for record counts
-------------------------------------------------------------------
CREATE OR REPLACE VIEW data_loading_report
AS SELECT 'activity table' as "table", COUNT(*)::integer AS "current record count", 0 AS "correct record count", '' as "comments" FROM activity
UNION ALL
SELECT 'activity_contact junction table' as "table", COUNT(*)::integer AS "current record count", 0 AS "correct record count", '' as "comments" FROM activity_contact
UNION ALL
SELECT 'activity_taxonomy junction table' as "table", COUNT(*)::integer AS "current record count", 0 AS "correct record count", '' as "comments" FROM activity_taxonomy
UNION ALL
SELECT 'boundary table' as "table", COUNT(*) AS "current record count", 3 AS "correct record count", 'Correct count reflects minimum count on default PMT install.' as "comments" FROM boundary			
UNION ALL
SELECT 'boundary_taxonomy junction table' as "table", COUNT(*) AS "current record count", 0 AS "correct record count", '' as "comments" FROM boundary_taxonomy			
UNION ALL
SELECT 'contact table' as "table", COUNT(*) AS "current record count", 0 AS "correct record count", '' as "comments" FROM contact			
UNION ALL
SELECT 'contact_taxonomy junction table' as "table", COUNT(*) AS "current record count", 0 AS "correct record count", '' as "comments" FROM contact_taxonomy
UNION ALL
SELECT 'detail table' as "table", COUNT(*) AS "current record count", 0 AS "correct record count", '' as "comments" FROM detail
UNION ALL
SELECT 'feature_taxonomy junction table' as "table", COUNT(*) AS "current record count", 277 AS "correct record count", 'Correct count reflects minimum count on default PMT install.' as "comments" FROM feature_taxonomy
UNION ALL
SELECT 'financial table' as "table", COUNT(*) AS "current record count", 0 AS "correct record count", '' as "comments" FROM financial			
UNION ALL
SELECT 'financial_taxonomy junction table' as "table", COUNT(*) AS "current record count", 0 AS "correct record count", '' as "comments" FROM financial_taxonomy		
UNION ALL
SELECT 'gaul0 table' as "table", COUNT(*) AS "current record count", 277 AS "correct record count", 'Correct count reflects minimum count on default PMT install.' as "comments" FROM gaul0
UNION ALL
SELECT 'gaul1 table' as "table", COUNT (*) AS "current record count", 3469 AS "correct record count", 'Correct count reflects minimum count on default PMT install.' as "comments" FROM gaul1
UNION ALL
SELECT 'gaul2 table' as "table", COUNT(*) AS "current record count", 37378 AS "correct record count", 'Correct count reflects minimum count on default PMT install.' as "comments" FROM gaul2
UNION ALL
SELECT 'location table' as "table", COUNT(*) AS "current record count", 0 AS "correct record count", '' as "comments" FROM location 
UNION ALL
SELECT 'location_boundary junction table' as "table", COUNT(*) AS "current record count", 0 AS "correct record count", '' as "comments" FROM location_boundary
UNION ALL
SELECT 'location_taxonomy junction table' as "table", COUNT(*) AS "current record count", 0 AS "correct record count", '' as "comments" FROM location_taxonomy
UNION ALL
SELECT 'map table' as "table", COUNT(*) AS "current record count", 0 AS "correct record count", '' as "comments" FROM map		
UNION ALL
SELECT 'organization table' as "table", COUNT(*) AS "current record count", 0 AS "correct record count", '' as "comments" FROM organization		
UNION ALL
SELECT 'organization_taxonomy junction table' as "table", COUNT(*) AS "current record count", 0 AS "correct record count", '' as "comments" FROM organization_taxonomy	
UNION ALL
SELECT 'participation table' as "table", COUNT(*) AS "current record count", 0 AS "correct record count", '' as "comments" FROM participation
UNION ALL
SELECT 'participation_taxonomy junction table' as "table", COUNT(*) AS "current record count", 0 AS "correct record count", '' as "comments" FROM participation_taxonomy
UNION ALL
SELECT 'project table' as "table", COUNT(*) AS "current record count", 0 AS "correct record count", '' as "comments" FROM project			
UNION ALL
SELECT 'project_contact junction table' as "table", COUNT(*) AS "current record count", 0 AS "correct record count", '' as "comments" FROM project_contact
UNION ALL
SELECT 'project_taxonomy junction table' as "table", COUNT(*) AS "current record count", 0 AS "correct record count", '' as "comments" FROM project_taxonomy
UNION ALL
SELECT 'result table' as "table", COUNT(*) AS "current record count", 0 AS "correct record count", '' as "comments" FROM result			
UNION ALL
SELECT 'result_taxonomy junction table' as "table", COUNT(*) AS "current record count", 0 AS "correct record count", '' as "comments" FROM result_taxonomy
UNION ALL
SELECT 'role table' as "table", COUNT(*) AS "current record count", 3 AS "correct record count", 'Correct count reflects minimum count on default PMT install.' as "comments" FROM role
UNION ALL
SELECT 'user table' as "table", COUNT(*) AS "current record count", 0 AS "correct record count", '' as "comments" FROM "user"
UNION ALL
SELECT 'user_role junction table' as "table", COUNT(*) AS "current record count", 0 AS "correct record count", '' as "comments" FROM user_role
UNION ALL
SELECT 'classification table' as "table", COUNT(*) AS "current record count", 767 AS "correct record count", 'Correct count reflects minimum count on default PMT install.' as "comments" FROM classification
UNION ALL
SELECT 'taxonomy table' as "table", COUNT(*) AS "current record count", 16 AS "correct record count", 'Correct count reflects minimum count on default PMT install.' as "comments" FROM taxonomy;

/*****************************************************************
MATERIALIZED VIEWS -- The version of Postgres (9.2) doesn't support
materialized views. So these tables and associated functions are
designed to support this database functionality until PMT is upgraded
to a version supporting materialized views (Postgres 9.3 or higher)
Create MATERIALIZED VIEWS:
	1. taxonomy_lookup
	2. location_lookup
	3. organization_lookup
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