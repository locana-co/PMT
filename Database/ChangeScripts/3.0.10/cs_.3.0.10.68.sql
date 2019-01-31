/******************************************************************
Change Script 3.0.10.68
1. update the user table dropping role_id
2. new function to validate an array of data groups
3. create new instance table, to store PMT Application instances
4. create user_instance table, to represent user roles in instances
5. rename user_activity_role table to user_activity, drop role_id
6. update user_log table, add instance
7. update role table to ensure unique names
******************************************************************/
INSERT INTO version(_version, _iteration, _changeset) VALUES (3.0, 10, 68);
-- select * from version order by _iteration desc, _changeset desc;

/******************************************************************
1. update the user table
******************************************************************/
ALTER TABLE users DROP COLUMN role_id;
-- select * from users

/******************************************************************
2. new function to validate array of data groups
  select * from pmt_are_data_group(ARRAY[1068,1069,2266,2267,768,769,9999]);
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_are_data_group(ids integer[]) RETURNS boolean AS $$
DECLARE 
  data_group_id integer;
  taxonomy_id integer;
  error_msg text;
BEGIN 
  IF $1 IS NULL THEN    
    RETURN false;
  END IF;    

  FOREACH data_group_id IN ARRAY ids LOOP
    SELECT INTO taxonomy_id classification.taxonomy_id FROM classification WHERE classification.id = data_group_id;
    IF taxonomy_id IS NULL OR taxonomy_id <> 1 THEN
	RETURN FALSE; 
    END IF;
  END LOOP;	

RETURN TRUE;
     
EXCEPTION WHEN OTHERS THEN
  GET STACKED DIAGNOSTICS error_msg = MESSAGE_TEXT;  
    RAISE NOTICE 'Internal Error - Contact your DBA with the following error message: %', error_msg;
    RETURN FALSE;
END; 
$$ LANGUAGE 'plpgsql'; 

/******************************************************************
3. create instance table
******************************************************************/
CREATE TABLE instance (
	id			SERIAL				NOT NULL
	,_theme			character varying		NOT NULL UNIQUE
	,_description		character varying
	,data_group_ids		integer[]			NOT NULL
	,_active 		boolean 			NOT NULL DEFAULT true
	,_retired_by 		integer
	,_created_by 		character varying(150)
	,_created_date 		timestamp without time zone NOT NULL DEFAULT ('now'::text)::date
	,_updated_by 		character varying(150)
	,_updated_date 		timestamp without time zone NOT NULL DEFAULT ('now'::text)::date
	,CONSTRAINT pk_instance_id PRIMARY KEY(id)	
	,CONSTRAINT chk_instance_dg_chk CHECK (pmt_are_data_group(data_group_ids)) NOT VALID
	,CONSTRAINT chk_instance_created_by CHECK (_created_by IS NOT NULL) NOT VALID
	,CONSTRAINT chk_instance_updated_by CHECK (_updated_by IS NOT NULL) NOT VALID
);
-- instance udpated date management
CREATE OR REPLACE FUNCTION pmt_upd_instance_updated() RETURNS trigger AS $$
BEGIN
    NEW._updated_date = current_date;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql; 
DROP TRIGGER IF EXISTS pmt_upd_instance_updated ON instance;
CREATE TRIGGER pmt_upd_instance_updated BEFORE UPDATE ON instance
    FOR EACH ROW EXECUTE PROCEDURE pmt_upd_instance_updated();

/******************************************************************
4. create user_instance table
******************************************************************/    
CREATE TABLE user_instance (
	instance_id 		integer		REFERENCES instance(id)
	,user_id		integer		REFERENCES users(id)
	,role_id		integer		REFERENCES role(id)
	,CONSTRAINT pk_user_instance PRIMARY KEY(instance_id, user_id)
);

/******************************************************************
5. update & rename user_activity_role table
******************************************************************/ 
-- rename user_activity_role to user_activity
ALTER TABLE user_activity_role RENAME TO user_activity;
ALTER TABLE user_activity DROP COLUMN role_id;
-- select * from user_activity

/******************************************************************
6. update user_log table add instance
******************************************************************/ 
ALTER TABLE user_log ADD COLUMN instance_id integer NOT NULL REFERENCES instance(id);
-- select * from user_activity

/******************************************************************
7. update role table to ensure unique names
******************************************************************/ 
ALTER TABLE role ADD CONSTRAINT chk_role_name_unique UNIQUE (_name);


-- update permissions
GRANT USAGE ON SCHEMA public TO pmt_read;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO pmt_read;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO pmt_read;
GRANT USAGE ON SCHEMA public TO pmt_write;
GRANT SELECT,INSERT ON ALL TABLES IN SCHEMA public TO pmt_write;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO pmt_write;