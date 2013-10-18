/*********************************************************************
	Application Database Creation Script	
This script will create or replace the entire PMT application database 
structure. 
**********************************************************************/
-- Enable PLPGSQL language;
CREATE OR REPLACE LANGUAGE plpgsql;

-- Drop Tables (if they exist)
DROP TABLE IF EXISTS "user" CASCADE;

/*****************************************************************
ENTITY -- a thing with distinct and independent existence.
Create the ENTITIES:
	1.  user			
******************************************************************/
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