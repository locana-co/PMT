/******************************************************************
Change Script 2.0.7.7 - Consolidated
1. pmt_user_salt - function for getting salt for a specific user
2. pmt_user_auth - function for authenticating a user using hash/salted password.
******************************************************************/
INSERT INTO config(version, iteration, changeset) VALUES (2.0, 7, 7);
-- select * from config order by version, iteration, changeset, updated_date;

-- select * from "user";
-- select * from pmt_user_salt(1);
-- select * from pmt_user_auth('reader', (crypt('reader', (select * from pmt_user_salt(1)))))
-- SELECT * FROM pmt_user_auth('reader', '$2a$10$.V0ETMIAW6O9z2wekwMG1.PuaYpuJmZTO1W3GCwOOF3Uyfjrrede');
-- select (crypt('reader', (select * from pmt_user_salt(1))))

DROP FUNCTION IF EXISTS pmt_user_auth(character varying, character varying) CASCADE;
DROP FUNCTION IF EXISTS pmt_user_salt(integer) CASCADE;

DROP TYPE IF EXISTS pmt_user_auth_result_type CASCADE;

CREATE TYPE pmt_user_auth_result_type AS (response json);

/******************************************************************
  pmt_user_auth
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_user_auth(username character varying(255), password character varying(255)) RETURNS 
SETOF pmt_user_auth_result_type AS $$
DECLARE 
  valid_user_id integer;
  rec record;
BEGIN 
  SELECT INTO valid_user_id "user".user_id FROM "user" WHERE "user".username = $1 AND "user".password = $2;
  IF valid_user_id IS NOT NULL THEN
    FOR rec IN (SELECT row_to_json(j) FROM( 
	SELECT user_id, first_name, last_name, "user".username, email, "user".organization_id
	, (SELECT name FROM organization WHERE organization_id = "user".organization_id) as organization, "user".data_group_id
	, (SELECT classification FROM taxonomy_classifications WHERE classification_id = "user".data_group_id) as data_group,(
	SELECT array_to_json(array_agg(row_to_json(r))) FROM ( SELECT r.role_id, r.name FROM role r 
	JOIN user_role ur ON r.role_id = ur.role_id WHERE ur.user_id = "user".user_id) r ) as roles 
	FROM "user" WHERE "user".user_id = valid_user_id
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


-- update permissions
GRANT USAGE ON SCHEMA public TO pmt_read;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO pmt_read;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO pmt_read;
GRANT USAGE ON SCHEMA public TO pmt_write;
GRANT SELECT,INSERT ON ALL TABLES IN SCHEMA public TO pmt_write;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO pmt_write;