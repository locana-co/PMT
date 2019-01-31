/******************************************************************
Change Script 2.0.7.1 - Condolidated
1. User table - updating.
2. Role table - new.
3. User_Role table - new.
4. pmt_users
5. pmt_create_user
6. pmt_update_user
7. pmt_validate_organization
8. pmt_validate_organizations
9. pmt_auth_user
******************************************************************/
INSERT INTO config(version, iteration, changeset) VALUES (2.0, 7, 1);
-- select * from config order by version, iteration, changeset, updated_date;

-- add extension for password encryption
CREATE EXTENSION pgcrypto;

-- drop data from user to add organization_id column
TRUNCATE TABLE "user";
ALTER TABLE "user" ADD organization_id integer	NOT NULL;
ALTER TABLE "user" ADD data_group_id integer NOT NULL;
ALTER TABLE "user" ALTER email SET NOT NULL;
ALTER TABLE "user" ALTER password SET NOT NULL;
ALTER TABLE "user" ALTER username SET NOT NULL;

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
-- user_role
CREATE TABLE "user_role"
(
	"user_id"		integer				NOT NULL
	,"role_id"		integer				NOT NULL
	,CONSTRAINT user_role_id PRIMARY KEY(user_id,role_id)
);

-- Add Basic PMT Core Roles
INSERT INTO role(name, description, read, "create", update, delete, super, created_by, updated_by) VALUES ('Reader', 'Reader role for read-only access to public data.', TRUE, FALSE, FALSE, FALSE, FALSE, 'PMT Core Role', 'PMT Core Role');
INSERT INTO role(name, description, read, "create", update, delete, super, created_by, updated_by) VALUES ('Editor', 'Editor role for read-only of all public data. Create and update rights to user data.', TRUE, TRUE, TRUE, FALSE, FALSE, 'PMT Core Role', 'PMT Core Role');
INSERT INTO role(name, description, read, "create", update, delete, super, created_by, updated_by) VALUES ('Super', 'Full access to all data.', TRUE, TRUE, TRUE, TRUE, TRUE, 'PMT Core Role', 'PMT Core Role');

DROP FUNCTION IF EXISTS pmt_validate_organization(integer)  CASCADE;
DROP FUNCTION IF EXISTS pmt_validate_organizations(character varying)  CASCADE;
DROP FUNCTION IF EXISTS pmt_create_user(integer, integer, character varying(255), character varying(255), character varying(255), character varying(150), character varying(150));
DROP FUNCTION IF EXISTS pmt_update_user(integer, integer, integer, character varying(255), character varying(255), character varying(255), character varying(150), character varying(150));
DROP FUNCTION IF EXISTS pmt_users();

CREATE TYPE pmt_users_result_type AS (response json);
CREATE TYPE pmt_auth_user_result_type AS (response json);

CREATE OR REPLACE FUNCTION pmt_users() RETURNS 
SETOF pmt_users_result_type AS $$
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

CREATE OR REPLACE FUNCTION pmt_auth_user(username character varying(255), password character varying(255)) RETURNS 
SETOF pmt_auth_user_result_type AS $$
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
