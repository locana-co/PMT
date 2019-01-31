/******************************************************************
Change Script 2.0.7.5 - Consolidated
1. map - new entity for storing and saving map configurations
******************************************************************/
INSERT INTO config(version, iteration, changeset) VALUES (2.0, 7, 5);
-- select * from config order by version, iteration, changeset, updated_date;

-- Map
CREATE TABLE "map"
(
	"map_id"		SERIAL				NOT NULL
	,"user_id"		integer 			NOT NULL		
	,"title"		character varying		
	,"description"		character varying
	,"extent"		character varying
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

