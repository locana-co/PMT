/******************************************************************
Change Script 3.0.10.2

1. add unit testing to test schema
2. add unit testing to test triggers
******************************************************************/
INSERT INTO version(_version, _iteration, _changeset) VALUES (3.0, 10, 2);
-- select * from version order by iteration desc, changeset desc;

-- unit_tests table
DROP TABLE IF EXISTS "unit_test";
CREATE TABLE "unit_test"
(
	"id"			SERIAL				NOT NULL
	,"_name"		character varying		NOT NULL
	,"_description"		character varying		
	,"_pass"		boolean
	,"_execution_sucess"    boolean			
	,"_created_date" 	timestamp without time zone 	NOT NULL DEFAULT current_date
	,CONSTRAINT unit_test_id PRIMARY KEY(id)
);

/******************************************************************
  test_execute_unit_tests
  SELECT * FROM test_execute_unit_tests();
  SELECT * FROM unit_test;
******************************************************************/
CREATE OR REPLACE FUNCTION test_execute_unit_tests() RETURNS text AS $$
DECLARE 
  msg text;
  passed_test integer;
  failed_test integer; 
  failed_exe integer; 
  total_test integer;  
  error_msg1 text;
  error_msg2 text;
  error_msg3 text;
BEGIN 
  -- truncate unit_test table
  TRUNCATE unit_test;
  
  -- execute all the unit tests
  PERFORM test_activity_schema();
  PERFORM test_activity_contact_schema();
  PERFORM test_activity_taxonomy_schema();
  PERFORM test_boundary_schema();
  PERFORM test_boundary_taxonomy_schema();
  PERFORM test_classification_schema();
  PERFORM test_config_schema();
  PERFORM test_contact_schema();
  PERFORM test_contact_taxonomy_schema();
  PERFORM test_detail_schema();
  PERFORM test_feature_taxonomy_schema();
  PERFORM test_financial_schema();
  PERFORM test_financial_taxonomy_schema();
  PERFORM test_iati_import_schema();
  PERFORM test_location_schema();
  PERFORM test_location_boundary_schema();
  PERFORM test_location_taxonomy_schema();
  PERFORM test_organization_schema();
  PERFORM test_organization_taxonomy_schema();
  PERFORM test_participation_schema();
  PERFORM test_participation_taxonomy_schema();
  PERFORM test_result_schema();
  PERFORM test_result_taxonomy_schema();
  PERFORM test_role_schema();
  PERFORM test_taxonomy_schema();
  PERFORM test_taxonomy_xwalk_schema();
  PERFORM test_user_activity_role_schema();
  PERFORM test_user_log_schema();
  PERFORM test_users_schema();
  PERFORM test_version_schema();
  PERFORM test_core_views();
  PERFORM test_upd_geometry_formats();
  
  -- collect the results
  SELECT INTO passed_test count(_pass) FROM unit_test WHERE _pass = true;
  SELECT INTO failed_test count(_pass) FROM unit_test WHERE _pass = false;
  SELECT INTO failed_exe count(_execution_sucess) FROM unit_test WHERE _execution_sucess = false;  
  SELECT INTO total_test count(*) FROM unit_test;
  
  -- message out the results
  msg:= 'Unit testing complete: pass (' || passed_test || ') fail (' || failed_test || ') execution_failures(' || failed_exe || ') total(' || total_test || ')';
  RETURN msg;
EXCEPTION WHEN others THEN
  GET STACKED DIAGNOSTICS error_msg1 = MESSAGE_TEXT,
                          error_msg2 = PG_EXCEPTION_DETAIL,
                          error_msg3 = PG_EXCEPTION_HINT;
  msg:= error_msg1 || ' : ' || error_msg2 || ' : ' || error_msg3;
  RETURN msg;                          
END; 
$$ LANGUAGE 'plpgsql';

/******************************************************************
  test_activity_schema
******************************************************************/
CREATE OR REPLACE FUNCTION test_activity_schema() RETURNS boolean AS $$
DECLARE 
  test_name text;
  test_description text;
  expected_columns text[];
  table_columns text[];
  pass boolean;
  msg text;
  error_msg1 text;
  error_msg2 text;
  error_msg3 text;
BEGIN 
  -- test/function name
  test_name := 'test_activity_schema';
  -- test description
  test_description := 'Ensure the activity table has ALL the core PMT fields.';
  -- list of expected core columns for the table we are testing
  expected_columns := ARRAY['id', 'data_group_id', 'parent_id', '_title', '_label', '_description', '_objective', '_content', 
			'_url', '_start_date', '_plan_start_date', '_end_date', '_plan_end_date', 
			'_tags', '_iati_identifier', 'iati_import_id', '_active', '_retired_by', '_created_by', 
			'_created_date', '_updated_by', '_updated_date']::text[];

  -- get all the columns from the table we are testing 
  SELECT INTO table_columns array_agg(column_name::text)::text[] FROM information_schema.columns WHERE table_schema = 'public'  AND table_name = 'activity';
  -- test
  SELECT INTO pass table_columns @> expected_columns;
  -- write results with name and description of test
  INSERT INTO unit_test (_name,_description, _pass, _execution_sucess) VALUES (test_name, test_description, pass, true);
  
  RETURN true;

  EXCEPTION WHEN others THEN
  GET STACKED DIAGNOSTICS error_msg1 = MESSAGE_TEXT,
                          error_msg2 = PG_EXCEPTION_DETAIL,
                          error_msg3 = PG_EXCEPTION_HINT;
  msg:= error_msg1 || ' : ' || error_msg2 || ' : ' || error_msg3;
  RAISE NOTICE 'An error executing %', test_name || ': ' || msg; 
  
  -- note the test execution failed with name and description of test
  INSERT INTO unit_test (_name,_description, _pass, _execution_sucess) VALUES (test_name, test_description, false, false);
  
  RETURN false;                          
END; 
$$ LANGUAGE 'plpgsql';

/******************************************************************
  test_activity_contact_schema
******************************************************************/
CREATE OR REPLACE FUNCTION test_activity_contact_schema() RETURNS boolean AS $$
DECLARE 
  test_name text;
  test_description text;
  expected_columns text[];
  table_columns text[];
  pass boolean;
  msg text;
  error_msg1 text;
  error_msg2 text;
  error_msg3 text;
BEGIN 
  -- test/function name
  test_name := 'test_activity_contact_schema';
  -- test description
  test_description := 'Ensure the activity_contact table has ONLY the core PMT fields.';
  -- list of expected core columns for the table we are testing
  expected_columns := ARRAY['activity_id','contact_id']::text[];

  -- get all the columns from the table we are testing 
  SELECT INTO table_columns array_agg(column_name::text)::text[] FROM information_schema.columns WHERE table_schema = 'public'  AND table_name = 'activity_contact';
  -- test
  SELECT INTO pass table_columns = expected_columns;
  -- write results with name and description of test
  INSERT INTO unit_test (_name,_description, _pass, _execution_sucess) VALUES (test_name, test_description, pass, true);
  
  RETURN true;

  EXCEPTION WHEN others THEN
  GET STACKED DIAGNOSTICS error_msg1 = MESSAGE_TEXT,
                          error_msg2 = PG_EXCEPTION_DETAIL,
                          error_msg3 = PG_EXCEPTION_HINT;
  msg:= error_msg1 || ' : ' || error_msg2 || ' : ' || error_msg3;
  RAISE NOTICE 'An error executing %', test_name || ': ' || msg;  
  
  -- note the test execution failed with name and description of test
  INSERT INTO unit_test (_name,_description, _pass, _execution_sucess) VALUES (test_name, test_description, false, false);
  
  RETURN false;                          
END; 
$$ LANGUAGE 'plpgsql';

/******************************************************************
  test_activity_taxonomy_schema
******************************************************************/
CREATE OR REPLACE FUNCTION test_activity_taxonomy_schema() RETURNS boolean AS $$
DECLARE 
  test_name text;
  test_description text;
  expected_columns text[];
  table_columns text[];
  pass boolean;
  msg text;
  error_msg1 text;
  error_msg2 text;
  error_msg3 text;
BEGIN 
  -- test/function name
  test_name := 'test_activity_taxonomy_schema';
  -- test description
  test_description := 'Ensure the activity_taxonomy table has ONLY the core PMT fields.';
  -- list of expected core columns for the table we are testing
  expected_columns := ARRAY['activity_id','classification_id','_field']::text[];

  -- get all the columns from the table we are testing 
  SELECT INTO table_columns array_agg(column_name::text)::text[] FROM information_schema.columns WHERE table_schema = 'public'  AND table_name = 'activity_taxonomy';
  -- test
  SELECT INTO pass table_columns = expected_columns;
  -- write results with name and description of test
  INSERT INTO unit_test (_name,_description, _pass, _execution_sucess) VALUES (test_name, test_description, pass, true);
  
  RETURN true;

  EXCEPTION WHEN others THEN
  GET STACKED DIAGNOSTICS error_msg1 = MESSAGE_TEXT,
                          error_msg2 = PG_EXCEPTION_DETAIL,
                          error_msg3 = PG_EXCEPTION_HINT;
  msg:= error_msg1 || ' : ' || error_msg2 || ' : ' || error_msg3;
  RAISE NOTICE 'An error executing %', test_name || ': ' || msg;  
  
  -- note the test execution failed with name and description of test
  INSERT INTO unit_test (_name,_description, _pass, _execution_sucess) VALUES (test_name, test_description, false, false);
  
  RETURN false;                          
END; 
$$ LANGUAGE 'plpgsql';

/******************************************************************
  test_boundary_schema
******************************************************************/
CREATE OR REPLACE FUNCTION test_boundary_schema() RETURNS boolean AS $$
DECLARE 
  test_name text;
  test_description text;
  expected_columns text[];
  table_columns text[];
  pass boolean;
  msg text;
  error_msg1 text;
  error_msg2 text;
  error_msg3 text;
BEGIN 
  -- test/function name
  test_name := 'test_boundary_schema';
  -- test description
  test_description := 'Ensure the boundary table has ONLY the core PMT fields.';
  -- list of expected core columns for the table we are testing
  expected_columns := ARRAY['id', '_name', '_description', '_spatial_table', '_version', '_source', '_active', 
	'_retired_by', '_created_by', '_created_date', '_updated_by', '_updated_date']::text[];

  -- get all the columns from the table we are testing 
  SELECT INTO table_columns array_agg(column_name::text)::text[] FROM information_schema.columns WHERE table_schema = 'public'  AND table_name = 'boundary';
  -- test
  SELECT INTO pass table_columns = expected_columns;
  -- write results with name and description of test
  INSERT INTO unit_test (_name,_description, _pass, _execution_sucess) VALUES (test_name, test_description, pass, true);
  
  RETURN true;

  EXCEPTION WHEN others THEN
  GET STACKED DIAGNOSTICS error_msg1 = MESSAGE_TEXT,
                          error_msg2 = PG_EXCEPTION_DETAIL,
                          error_msg3 = PG_EXCEPTION_HINT;
  msg:= error_msg1 || ' : ' || error_msg2 || ' : ' || error_msg3;
  RAISE NOTICE 'An error executing %', test_name || ': ' || msg;  
  
  -- note the test execution failed with name and description of test
  INSERT INTO unit_test (_name,_description, _pass, _execution_sucess) VALUES (test_name, test_description, false, false);
  
  RETURN false;                          
END; 
$$ LANGUAGE 'plpgsql';

/******************************************************************
  test_boundary_taxonomy_schema
******************************************************************/
CREATE OR REPLACE FUNCTION test_boundary_taxonomy_schema() RETURNS boolean AS $$
DECLARE 
  test_name text;
  test_description text;
  expected_columns text[];
  table_columns text[];
  pass boolean;
  msg text;
  error_msg1 text;
  error_msg2 text;
  error_msg3 text;
BEGIN 
  -- test/function name
  test_name := 'test_boundary_taxonomy_schema';
  -- test description
  test_description := 'Ensure the boundary_taxonomy table has ONLY the core PMT fields.';
  -- list of expected core columns for the table we are testing
  expected_columns := ARRAY['boundary_id','classification_id','_field']::text[];

  -- get all the columns from the table we are testing 
  SELECT INTO table_columns array_agg(column_name::text)::text[] FROM information_schema.columns WHERE table_schema = 'public'  AND table_name = 'boundary_taxonomy';
  -- test
  SELECT INTO pass table_columns = expected_columns;
  -- write results with name and description of test
  INSERT INTO unit_test (_name,_description, _pass, _execution_sucess) VALUES (test_name, test_description, pass, true);
  
  RETURN true;

  EXCEPTION WHEN others THEN
  GET STACKED DIAGNOSTICS error_msg1 = MESSAGE_TEXT,
                          error_msg2 = PG_EXCEPTION_DETAIL,
                          error_msg3 = PG_EXCEPTION_HINT;
  msg:= error_msg1 || ' : ' || error_msg2 || ' : ' || error_msg3;
  RAISE NOTICE 'An error executing %', test_name || ': ' || msg;  
  
  -- note the test execution failed with name and description of test
  INSERT INTO unit_test (_name,_description, _pass, _execution_sucess) VALUES (test_name, test_description, false, false);
  
  RETURN false;                          
END; 
$$ LANGUAGE 'plpgsql';

/******************************************************************
  test_classification_schema
******************************************************************/
CREATE OR REPLACE FUNCTION test_classification_schema() RETURNS boolean AS $$
DECLARE 
  test_name text;
  test_description text;
  expected_columns text[];
  table_columns text[];
  pass boolean;
  msg text;
  error_msg1 text;
  error_msg2 text;
  error_msg3 text;
BEGIN 
  -- test/function name
  test_name := 'test_classification_schema';
  -- test description
  test_description := 'Ensure the classification table has ONLY the core PMT fields.';
  -- list of expected core columns for the table we are testing
  expected_columns := ARRAY['id', 'taxonomy_id', '_code', '_name', '_description', '_iati_code', '_iati_name', 
	'_iati_description', 'parent_id', '_active', '_retired_by', '_created_by', '_created_date', '_updated_by', 
	'_updated_date']::text[];

  -- get all the columns from the table we are testing 
  SELECT INTO table_columns array_agg(column_name::text)::text[] FROM information_schema.columns WHERE table_schema = 'public'  AND table_name = 'classification';
  -- test
  SELECT INTO pass table_columns = expected_columns;
  -- write results with name and description of test
  INSERT INTO unit_test (_name,_description, _pass, _execution_sucess) VALUES (test_name, test_description, pass, true);
  
  RETURN true;

  EXCEPTION WHEN others THEN
  GET STACKED DIAGNOSTICS error_msg1 = MESSAGE_TEXT,
                          error_msg2 = PG_EXCEPTION_DETAIL,
                          error_msg3 = PG_EXCEPTION_HINT;
  msg:= error_msg1 || ' : ' || error_msg2 || ' : ' || error_msg3;
  RAISE NOTICE 'An error executing %', test_name || ': ' || msg;  
  
  -- note the test execution failed with name and description of test
  INSERT INTO unit_test (_name,_description, _pass, _execution_sucess) VALUES (test_name, test_description, false, false);
  
  RETURN false;                          
END; 
$$ LANGUAGE 'plpgsql';

/******************************************************************
  test_config_schema
******************************************************************/
CREATE OR REPLACE FUNCTION test_config_schema() RETURNS boolean AS $$
DECLARE 
  test_name text;
  test_description text;
  expected_columns text[];
  table_columns text[];
  pass boolean;
  msg text;
  error_msg1 text;
  error_msg2 text;
  error_msg3 text;
BEGIN 
  -- test/function name
  test_name := 'test_config_schema';
  -- test description
  test_description := 'Ensure the config table has ONLY the core PMT fields.';
  -- list of expected core columns for the table we are testing
  expected_columns := ARRAY['id', '_version', '_download_dir', '_created_date', '_updated_date']::text[];

  -- get all the columns from the table we are testing 
  SELECT INTO table_columns array_agg(column_name::text)::text[] FROM information_schema.columns WHERE table_schema = 'public'  AND table_name = 'config';
  -- test
  SELECT INTO pass table_columns = expected_columns;
  -- write results with name and description of test
  INSERT INTO unit_test (_name,_description, _pass, _execution_sucess) VALUES (test_name, test_description, pass, true);
  
  RETURN true;

  EXCEPTION WHEN others THEN
  GET STACKED DIAGNOSTICS error_msg1 = MESSAGE_TEXT,
                          error_msg2 = PG_EXCEPTION_DETAIL,
                          error_msg3 = PG_EXCEPTION_HINT;
  msg:= error_msg1 || ' : ' || error_msg2 || ' : ' || error_msg3;
  RAISE NOTICE 'An error executing %', test_name || ': ' || msg;  
  
  -- note the test execution failed with name and description of test
  INSERT INTO unit_test (_name,_description, _pass, _execution_sucess) VALUES (test_name, test_description, false, false);
  
  RETURN false;                          
END; 
$$ LANGUAGE 'plpgsql';

/******************************************************************
  test_contact_schema
******************************************************************/
CREATE OR REPLACE FUNCTION test_contact_schema() RETURNS boolean AS $$
DECLARE 
  test_name text;
  test_description text;
  expected_columns text[];
  table_columns text[];
  pass boolean;
  msg text;
  error_msg1 text;
  error_msg2 text;
  error_msg3 text;
BEGIN 
  -- test/function name
  test_name := 'test_contact_schema';
  -- test description
  test_description := 'Ensure the contact table has ALL the core PMT fields.';
  -- list of expected core columns for the table we are testing
  expected_columns := ARRAY['id', 'organization_id', '_salutation', '_first_name', '_initial', '_last_name', 
	'_title', '_address1', '_address2', '_city', '_state_providence', '_postal_code', '_country', 
	'_direct_phone', '_mobile_phone', '_fax', '_email', '_url', 'iati_import_id', '_active', '_retired_by',  
	'_created_by', '_created_date', '_updated_by', '_updated_date']::text[];

  -- get all the columns from the table we are testing 
  SELECT INTO table_columns array_agg(column_name::text)::text[] FROM information_schema.columns WHERE table_schema = 'public'  AND table_name = 'contact';
  -- test
  SELECT INTO pass table_columns @> expected_columns;
  -- write results with name and description of test
  INSERT INTO unit_test (_name,_description, _pass, _execution_sucess) VALUES (test_name, test_description, pass, true);
  
  RETURN true;

  EXCEPTION WHEN others THEN
  GET STACKED DIAGNOSTICS error_msg1 = MESSAGE_TEXT,
                          error_msg2 = PG_EXCEPTION_DETAIL,
                          error_msg3 = PG_EXCEPTION_HINT;
  msg:= error_msg1 || ' : ' || error_msg2 || ' : ' || error_msg3;
  RAISE NOTICE 'An error executing %', test_name || ': ' || msg;  
  
  -- note the test execution failed with name and description of test
  INSERT INTO unit_test (_name,_description, _pass, _execution_sucess) VALUES (test_name, test_description, false, false);
  
  RETURN false;                          
END; 
$$ LANGUAGE 'plpgsql';

/******************************************************************
  test_contact_taxonomy_schema
******************************************************************/
CREATE OR REPLACE FUNCTION test_contact_taxonomy_schema() RETURNS boolean AS $$
DECLARE 
  test_name text;
  test_description text;
  expected_columns text[];
  table_columns text[];
  pass boolean;
  msg text;
  error_msg1 text;
  error_msg2 text;
  error_msg3 text;
BEGIN 
  -- test/function name
  test_name := 'test_contact_taxonomy_schema';
  -- test description
  test_description := 'Ensure the contact_taxonomy table has ONLY the core PMT fields.';
  -- list of expected core columns for the table we are testing
  expected_columns := ARRAY['contact_id', 'classification_id', '_field']::text[];

  -- get all the columns from the table we are testing 
  SELECT INTO table_columns array_agg(column_name::text)::text[] FROM information_schema.columns WHERE table_schema = 'public'  AND table_name = 'contact_taxonomy';
  -- test
  SELECT INTO pass table_columns = expected_columns;
  -- write results with name and description of test
  INSERT INTO unit_test (_name,_description, _pass, _execution_sucess) VALUES (test_name, test_description, pass, true);
  
  RETURN true;

  EXCEPTION WHEN others THEN
  GET STACKED DIAGNOSTICS error_msg1 = MESSAGE_TEXT,
                          error_msg2 = PG_EXCEPTION_DETAIL,
                          error_msg3 = PG_EXCEPTION_HINT;
  msg:= error_msg1 || ' : ' || error_msg2 || ' : ' || error_msg3;
  RAISE NOTICE 'An error executing %', test_name || ': ' || msg;  
  
  -- note the test execution failed with name and description of test
  INSERT INTO unit_test (_name,_description, _pass, _execution_sucess) VALUES (test_name, test_description, false, false);
  
  RETURN false;                          
END; 
$$ LANGUAGE 'plpgsql';

/******************************************************************
  test_detail_schema
******************************************************************/
CREATE OR REPLACE FUNCTION test_detail_schema() RETURNS boolean AS $$
DECLARE 
  test_name text;
  test_description text;
  expected_columns text[];
  table_columns text[];
  pass boolean;
  msg text;
  error_msg1 text;
  error_msg2 text;
  error_msg3 text;
BEGIN 
  -- test/function name
  test_name := 'test_detail_schema';
  -- test description
  test_description := 'Ensure the detail table has ALL the core PMT fields.';
  -- list of expected core columns for the table we are testing
  expected_columns := ARRAY['id', 'activity_id', '_title', '_description', '_amount', '_active', '_retired_by', 
	'_created_by', '_created_date', '_updated_by', '_updated_date']::text[];

  -- get all the columns from the table we are testing 
  SELECT INTO table_columns array_agg(column_name::text)::text[] FROM information_schema.columns WHERE table_schema = 'public'  AND table_name = 'detail';
  -- test
  SELECT INTO pass table_columns @> expected_columns;
  -- write results with name and description of test
  INSERT INTO unit_test (_name,_description, _pass, _execution_sucess) VALUES (test_name, test_description, pass, true);
  
  RETURN true;

  EXCEPTION WHEN others THEN
  GET STACKED DIAGNOSTICS error_msg1 = MESSAGE_TEXT,
                          error_msg2 = PG_EXCEPTION_DETAIL,
                          error_msg3 = PG_EXCEPTION_HINT;
  msg:= error_msg1 || ' : ' || error_msg2 || ' : ' || error_msg3;
  RAISE NOTICE 'An error executing %', test_name || ': ' || msg;  
  
  -- note the test execution failed with name and description of test
  INSERT INTO unit_test (_name,_description, _pass, _execution_sucess) VALUES (test_name, test_description, false, false);
  
  RETURN false;                          
END; 
$$ LANGUAGE 'plpgsql';

/******************************************************************
  test_feature_taxonomy_schema
******************************************************************/
CREATE OR REPLACE FUNCTION test_feature_taxonomy_schema() RETURNS boolean AS $$
DECLARE 
  test_name text;
  test_description text;
  expected_columns text[];
  table_columns text[];
  pass boolean;
  msg text;
  error_msg1 text;
  error_msg2 text;
  error_msg3 text;
BEGIN 
  -- test/function name
  test_name := 'test_feature_taxonomy_schema';
  -- test description
  test_description := 'Ensure the feature_taxonomy table has ONLY the core PMT fields.';
  -- list of expected core columns for the table we are testing
  expected_columns := ARRAY['feature_id', 'boundary_id', 'classification_id', '_field']::text[];

  -- get all the columns from the table we are testing 
  SELECT INTO table_columns array_agg(column_name::text)::text[] FROM information_schema.columns WHERE table_schema = 'public'  AND table_name = 'feature_taxonomy';
  -- test
  SELECT INTO pass table_columns = expected_columns;
  -- write results with name and description of test
  INSERT INTO unit_test (_name,_description, _pass, _execution_sucess) VALUES (test_name, test_description, pass, true);
  
  RETURN true;

  EXCEPTION WHEN others THEN
  GET STACKED DIAGNOSTICS error_msg1 = MESSAGE_TEXT,
                          error_msg2 = PG_EXCEPTION_DETAIL,
                          error_msg3 = PG_EXCEPTION_HINT;
  msg:= error_msg1 || ' : ' || error_msg2 || ' : ' || error_msg3;
  RAISE NOTICE 'An error executing %', test_name || ': ' || msg;  
  
  -- note the test execution failed with name and description of test
  INSERT INTO unit_test (_name,_description, _pass, _execution_sucess) VALUES (test_name, test_description, false, false);
  
  RETURN false;                          
END; 
$$ LANGUAGE 'plpgsql';

/******************************************************************
  test_financial_schema
******************************************************************/
CREATE OR REPLACE FUNCTION test_financial_schema() RETURNS boolean AS $$
DECLARE 
  test_name text;
  test_description text;
  expected_columns text[];
  table_columns text[];
  pass boolean;
  msg text;
  error_msg1 text;
  error_msg2 text;
  error_msg3 text;
BEGIN 
  -- test/function name
  test_name := 'test_financial_schema';
  -- test description
  test_description := 'Ensure the financial table has ALL the core PMT fields.';
  -- list of expected core columns for the table we are testing
  expected_columns := ARRAY['id', 'activity_id', 'provider_id', 'recipient_id', '_amount', '_start_date', 
	'_end_date', '_active', '_retired_by', '_created_by', '_created_date', '_updated_by', '_updated_date']::text[];

  -- get all the columns from the table we are testing 
  SELECT INTO table_columns array_agg(column_name::text)::text[] FROM information_schema.columns WHERE table_schema = 'public'  AND table_name = 'financial';
  -- test
  SELECT INTO pass table_columns @> expected_columns;
  -- write results with name and description of test
  INSERT INTO unit_test (_name,_description, _pass, _execution_sucess) VALUES (test_name, test_description, pass, true);
  
  RETURN true;

  EXCEPTION WHEN others THEN
  GET STACKED DIAGNOSTICS error_msg1 = MESSAGE_TEXT,
                          error_msg2 = PG_EXCEPTION_DETAIL,
                          error_msg3 = PG_EXCEPTION_HINT;
  msg:= error_msg1 || ' : ' || error_msg2 || ' : ' || error_msg3;
  RAISE NOTICE 'An error executing %', test_name || ': ' || msg;  
  
  -- note the test execution failed with name and description of test
  INSERT INTO unit_test (_name,_description, _pass, _execution_sucess) VALUES (test_name, test_description, false, false);
  
  RETURN false;                          
END; 
$$ LANGUAGE 'plpgsql';

/******************************************************************
  test_financial_taxonomy_schema
******************************************************************/
CREATE OR REPLACE FUNCTION test_financial_taxonomy_schema() RETURNS boolean AS $$
DECLARE 
  test_name text;
  test_description text;
  expected_columns text[];
  table_columns text[];
  pass boolean;
  msg text;
  error_msg1 text;
  error_msg2 text;
  error_msg3 text;
BEGIN 
  -- test/function name
  test_name := 'test_financial_taxonomy_schema';
  -- test description
  test_description := 'Ensure the financial_taxonomy table has ONLY the core PMT fields.';
  -- list of expected core columns for the table we are testing
  expected_columns := ARRAY['financial_id', 'classification_id', '_field']::text[];

  -- get all the columns from the table we are testing 
  SELECT INTO table_columns array_agg(column_name::text)::text[] FROM information_schema.columns WHERE table_schema = 'public'  AND table_name = 'financial_taxonomy';
  -- test
  SELECT INTO pass table_columns = expected_columns;
  -- write results with name and description of test
  INSERT INTO unit_test (_name,_description, _pass, _execution_sucess) VALUES (test_name, test_description, pass, true);
  
  RETURN true;

  EXCEPTION WHEN others THEN
  GET STACKED DIAGNOSTICS error_msg1 = MESSAGE_TEXT,
                          error_msg2 = PG_EXCEPTION_DETAIL,
                          error_msg3 = PG_EXCEPTION_HINT;
  msg:= error_msg1 || ' : ' || error_msg2 || ' : ' || error_msg3;
  RAISE NOTICE 'An error executing %', test_name || ': ' || msg;  
  
  -- note the test execution failed with name and description of test
  INSERT INTO unit_test (_name,_description, _pass, _execution_sucess) VALUES (test_name, test_description, false, false);
  
  RETURN false;                          
END; 
$$ LANGUAGE 'plpgsql';

/******************************************************************
  test_iati_import_schema
******************************************************************/
CREATE OR REPLACE FUNCTION test_iati_import_schema() RETURNS boolean AS $$
DECLARE 
  test_name text;
  test_description text;
  expected_columns text[];
  table_columns text[];
  pass boolean;
  msg text;
  error_msg1 text;
  error_msg2 text;
  error_msg3 text;
BEGIN 
  -- test/function name
  test_name := 'test_iati_import_schema';
  -- test description
  test_description := 'Ensure the iati_import table has ONLY the core PMT fields.';
  -- list of expected core columns for the table we are testing
  expected_columns := ARRAY['id', '_action', '_type', '_codelist', '_data_group', '_version', 
	'_error', '_xml', '_created_by', '_created_date']::text[];

  -- get all the columns from the table we are testing 
  SELECT INTO table_columns array_agg(column_name::text)::text[] FROM information_schema.columns WHERE table_schema = 'public'  AND table_name = 'iati_import';
  -- test
  SELECT INTO pass table_columns = expected_columns;
  -- write results with name and description of test
  INSERT INTO unit_test (_name,_description, _pass, _execution_sucess) VALUES (test_name, test_description, pass, true);
  
  RETURN true;

  EXCEPTION WHEN others THEN
  GET STACKED DIAGNOSTICS error_msg1 = MESSAGE_TEXT,
                          error_msg2 = PG_EXCEPTION_DETAIL,
                          error_msg3 = PG_EXCEPTION_HINT;
  msg:= error_msg1 || ' : ' || error_msg2 || ' : ' || error_msg3;
  RAISE NOTICE 'An error executing %', test_name || ': ' || msg;  
  
  -- note the test execution failed with name and description of test
  INSERT INTO unit_test (_name,_description, _pass, _execution_sucess) VALUES (test_name, test_description, false, false);
  
  RETURN false;                          
END; 
$$ LANGUAGE 'plpgsql';

/******************************************************************
  test_location_schema
******************************************************************/
CREATE OR REPLACE FUNCTION test_location_schema() RETURNS boolean AS $$
DECLARE 
  test_name text;
  test_description text;
  expected_columns text[];
  table_columns text[];
  pass boolean;
  msg text;
  error_msg1 text;
  error_msg2 text;
  error_msg3 text;
BEGIN 
  -- test/function name
  test_name := 'test_location_schema';
  -- test description
  test_description := 'Ensure the location table has ALL the core PMT fields.';
  -- list of expected core columns for the table we are testing
  expected_columns := ARRAY['id', 'activity_id', 'boundary_id', 'feature_id', '_title', '_description', '_x', 
	'_y', '_lat_dd', '_long_dd', '_latlong', '_georef', '_admin1', '_admin2', '_admin3', '_admin4', '_point', 
	'_active', '_retired_by', '_created_by', '_created_date', '_updated_by', '_updated_date']::text[];

  -- get all the columns from the table we are testing 
  SELECT INTO table_columns array_agg(column_name::text)::text[] FROM information_schema.columns WHERE table_schema = 'public'  AND table_name = 'location';
  -- test
  SELECT INTO pass table_columns @> expected_columns;
  -- write results with name and description of test
  INSERT INTO unit_test (_name,_description, _pass, _execution_sucess) VALUES (test_name, test_description, pass, true);
  
  RETURN true;

  EXCEPTION WHEN others THEN
  GET STACKED DIAGNOSTICS error_msg1 = MESSAGE_TEXT,
                          error_msg2 = PG_EXCEPTION_DETAIL,
                          error_msg3 = PG_EXCEPTION_HINT;
  msg:= error_msg1 || ' : ' || error_msg2 || ' : ' || error_msg3;
  RAISE NOTICE 'An error executing %', test_name || ': ' || msg;  
  
  -- note the test execution failed with name and description of test
  INSERT INTO unit_test (_name,_description, _pass, _execution_sucess) VALUES (test_name, test_description, false, false);
  
  RETURN false;                          
END; 
$$ LANGUAGE 'plpgsql';

/******************************************************************
  test_location_boundary_schema
******************************************************************/
CREATE OR REPLACE FUNCTION test_location_boundary_schema() RETURNS boolean AS $$
DECLARE 
  test_name text;
  test_description text;
  expected_columns text[];
  table_columns text[];
  pass boolean;
  msg text;
  error_msg1 text;
  error_msg2 text;
  error_msg3 text;
BEGIN 
  -- test/function name
  test_name := 'test_location_boundary_schema';
  -- test description
  test_description := 'Ensure the location_boundary table has ONLY the core PMT fields.';
  -- list of expected core columns for the table we are testing
  expected_columns := ARRAY['location_id', 'boundary_id', 'feature_id', '_feature_area', '_feature_name']::text[];

  -- get all the columns from the table we are testing 
  SELECT INTO table_columns array_agg(column_name::text)::text[] FROM information_schema.columns WHERE table_schema = 'public'  AND table_name = 'location_boundary';
  -- test
  SELECT INTO pass table_columns = expected_columns;
  -- write results with name and description of test
  INSERT INTO unit_test (_name,_description, _pass, _execution_sucess) VALUES (test_name, test_description, pass, true);
  
  RETURN true;

  EXCEPTION WHEN others THEN
  GET STACKED DIAGNOSTICS error_msg1 = MESSAGE_TEXT,
                          error_msg2 = PG_EXCEPTION_DETAIL,
                          error_msg3 = PG_EXCEPTION_HINT;
  msg:= error_msg1 || ' : ' || error_msg2 || ' : ' || error_msg3;
  RAISE NOTICE 'An error executing %', test_name || ': ' || msg;  
  
  -- note the test execution failed with name and description of test
  INSERT INTO unit_test (_name,_description, _pass, _execution_sucess) VALUES (test_name, test_description, false, false);
  
  RETURN false;                          
END; 
$$ LANGUAGE 'plpgsql';

/******************************************************************
  test_location_taxonomy_schema
******************************************************************/
CREATE OR REPLACE FUNCTION test_location_taxonomy_schema() RETURNS boolean AS $$
DECLARE 
  test_name text;
  test_description text;
  expected_columns text[];
  table_columns text[];
  pass boolean;
  msg text;
  error_msg1 text;
  error_msg2 text;
  error_msg3 text;
BEGIN 
  -- test/function name
  test_name := 'test_location_taxonomy_schema';
  -- test description
  test_description := 'Ensure the location_taxonomy table has ONLY the core PMT fields.';
  -- list of expected core columns for the table we are testing
  expected_columns := ARRAY['location_id', 'classification_id', '_field']::text[];

  -- get all the columns from the table we are testing 
  SELECT INTO table_columns array_agg(column_name::text)::text[] FROM information_schema.columns WHERE table_schema = 'public'  AND table_name = 'location_taxonomy';
  -- test
  SELECT INTO pass table_columns = expected_columns;
  -- write results with name and description of test
  INSERT INTO unit_test (_name,_description, _pass, _execution_sucess) VALUES (test_name, test_description, pass, true);
  
  RETURN true;

  EXCEPTION WHEN others THEN
  GET STACKED DIAGNOSTICS error_msg1 = MESSAGE_TEXT,
                          error_msg2 = PG_EXCEPTION_DETAIL,
                          error_msg3 = PG_EXCEPTION_HINT;
  msg:= error_msg1 || ' : ' || error_msg2 || ' : ' || error_msg3;
  RAISE NOTICE 'An error executing %', test_name || ': ' || msg;  
  
  -- note the test execution failed with name and description of test
  INSERT INTO unit_test (_name,_description, _pass, _execution_sucess) VALUES (test_name, test_description, false, false);
  
  RETURN false;                          
END; 
$$ LANGUAGE 'plpgsql';

/******************************************************************
  test_organization_schema
******************************************************************/
CREATE OR REPLACE FUNCTION test_organization_schema() RETURNS boolean AS $$
DECLARE 
  test_name text;
  test_description text;
  expected_columns text[];
  table_columns text[];
  pass boolean;
  msg text;
  error_msg1 text;
  error_msg2 text;
  error_msg3 text;
BEGIN 
  -- test/function name
  test_name := 'test_organization_schema';
  -- test description
  test_description := 'Ensure the organization table has ALL the core PMT fields.';
  -- list of expected core columns for the table we are testing
  expected_columns := ARRAY['id', '_name', '_address1', '_address2', '_city', '_state_providence', '_postal_code', 
	'_country', '_direct_phone', '_mobile_phone', '_fax', '_url', 'iati_import_id', '_active', '_retired_by', '_created_by', 
	'_created_date', '_updated_by', '_updated_date']::text[];

  -- get all the columns from the table we are testing 
  SELECT INTO table_columns array_agg(column_name::text)::text[] FROM information_schema.columns WHERE table_schema = 'public'  AND table_name = 'organization';
  -- test
  SELECT INTO pass table_columns @> expected_columns;
  -- write results with name and description of test
  INSERT INTO unit_test (_name,_description, _pass, _execution_sucess) VALUES (test_name, test_description, pass, true);
  
  RETURN true;

  EXCEPTION WHEN others THEN
  GET STACKED DIAGNOSTICS error_msg1 = MESSAGE_TEXT,
                          error_msg2 = PG_EXCEPTION_DETAIL,
                          error_msg3 = PG_EXCEPTION_HINT;
  msg:= error_msg1 || ' : ' || error_msg2 || ' : ' || error_msg3;
  RAISE NOTICE 'An error executing %', test_name || ': ' || msg;  
  
  -- note the test execution failed with name and description of test
  INSERT INTO unit_test (_name,_description, _pass, _execution_sucess) VALUES (test_name, test_description, false, false);
  
  RETURN false;                          
END; 
$$ LANGUAGE 'plpgsql';

/******************************************************************
  test_organization_taxonomy_schema
******************************************************************/
CREATE OR REPLACE FUNCTION test_organization_taxonomy_schema() RETURNS boolean AS $$
DECLARE 
  test_name text;
  test_description text;
  expected_columns text[];
  table_columns text[];
  pass boolean;
  msg text;
  error_msg1 text;
  error_msg2 text;
  error_msg3 text;
BEGIN 
  -- test/function name
  test_name := 'test_organization_taxonomy_schema';
  -- test description
  test_description := 'Ensure the organization_taxonomy table has ONLY the core PMT fields.';
  -- list of expected core columns for the table we are testing
  expected_columns := ARRAY['organization_id', 'classification_id', '_field']::text[];

  -- get all the columns from the table we are testing 
  SELECT INTO table_columns array_agg(column_name::text)::text[] FROM information_schema.columns WHERE table_schema = 'public'  AND table_name = 'organization_taxonomy';
  -- test
  SELECT INTO pass table_columns = expected_columns;
  -- write results with name and description of test
  INSERT INTO unit_test (_name,_description, _pass, _execution_sucess) VALUES (test_name, test_description, pass, true);
  
  RETURN true;

  EXCEPTION WHEN others THEN
  GET STACKED DIAGNOSTICS error_msg1 = MESSAGE_TEXT,
                          error_msg2 = PG_EXCEPTION_DETAIL,
                          error_msg3 = PG_EXCEPTION_HINT;
  msg:= error_msg1 || ' : ' || error_msg2 || ' : ' || error_msg3;
  RAISE NOTICE 'An error executing %', test_name || ': ' || msg;  
  
  -- note the test execution failed with name and description of test
  INSERT INTO unit_test (_name,_description, _pass, _execution_sucess) VALUES (test_name, test_description, false, false);
  
  RETURN false;                          
END; 
$$ LANGUAGE 'plpgsql';

/******************************************************************
  test_participation_schema
******************************************************************/
CREATE OR REPLACE FUNCTION test_participation_schema() RETURNS boolean AS $$
DECLARE 
  test_name text;
  test_description text;
  expected_columns text[];
  table_columns text[];
  pass boolean;
  msg text;
  error_msg1 text;
  error_msg2 text;
  error_msg3 text;
BEGIN 
  -- test/function name
  test_name := 'test_participation_schema';
  -- test description
  test_description := 'Ensure the participation table has ALL the core PMT fields.';
  -- list of expected core columns for the table we are testing
  expected_columns := ARRAY['id', 'activity_id', 'organization_id', '_active', '_retired_by', 
	'_created_by', '_created_date', '_updated_by', '_updated_date']::text[];

  -- get all the columns from the table we are testing 
  SELECT INTO table_columns array_agg(column_name::text)::text[] FROM information_schema.columns WHERE table_schema = 'public'  AND table_name = 'participation';
  -- test
  SELECT INTO pass table_columns @> expected_columns;
  -- write results with name and description of test
  INSERT INTO unit_test (_name,_description, _pass, _execution_sucess) VALUES (test_name, test_description, pass, true);
  
  RETURN true;

  EXCEPTION WHEN others THEN
  GET STACKED DIAGNOSTICS error_msg1 = MESSAGE_TEXT,
                          error_msg2 = PG_EXCEPTION_DETAIL,
                          error_msg3 = PG_EXCEPTION_HINT;
  msg:= error_msg1 || ' : ' || error_msg2 || ' : ' || error_msg3;
  RAISE NOTICE 'An error executing %', test_name || ': ' || msg;  
  
  -- note the test execution failed with name and description of test
  INSERT INTO unit_test (_name,_description, _pass, _execution_sucess) VALUES (test_name, test_description, false, false);
  
  RETURN false;                          
END; 
$$ LANGUAGE 'plpgsql';

/******************************************************************
  test_participation_taxonomy_schema
******************************************************************/
CREATE OR REPLACE FUNCTION test_participation_taxonomy_schema() RETURNS boolean AS $$
DECLARE 
  test_name text;
  test_description text;
  expected_columns text[];
  table_columns text[];
  pass boolean;
  msg text;
  error_msg1 text;
  error_msg2 text;
  error_msg3 text;
BEGIN 
  -- test/function name
  test_name := 'test_participation_taxonomy_schema';
  -- test description
  test_description := 'Ensure the participation_taxonomy table has ONLY the core PMT fields.';
  -- list of expected core columns for the table we are testing
  expected_columns := ARRAY['participation_id', 'classification_id', '_field']::text[];

  -- get all the columns from the table we are testing 
  SELECT INTO table_columns array_agg(column_name::text)::text[] FROM information_schema.columns WHERE table_schema = 'public'  AND table_name = 'participation_taxonomy';
  -- test
  SELECT INTO pass table_columns = expected_columns;
  -- write results with name and description of test
  INSERT INTO unit_test (_name,_description, _pass, _execution_sucess) VALUES (test_name, test_description, pass, true);
  
  RETURN true;

  EXCEPTION WHEN others THEN
  GET STACKED DIAGNOSTICS error_msg1 = MESSAGE_TEXT,
                          error_msg2 = PG_EXCEPTION_DETAIL,
                          error_msg3 = PG_EXCEPTION_HINT;
  msg:= error_msg1 || ' : ' || error_msg2 || ' : ' || error_msg3;
  RAISE NOTICE 'An error executing %', test_name || ': ' || msg;  
  
  -- note the test execution failed with name and description of test
  INSERT INTO unit_test (_name,_description, _pass, _execution_sucess) VALUES (test_name, test_description, false, false);
  
  RETURN false;                          
END; 
$$ LANGUAGE 'plpgsql';

/******************************************************************
  test_result_schema
******************************************************************/
CREATE OR REPLACE FUNCTION test_result_schema() RETURNS boolean AS $$
DECLARE 
  test_name text;
  test_description text;
  expected_columns text[];
  table_columns text[];
  pass boolean;
  msg text;
  error_msg1 text;
  error_msg2 text;
  error_msg3 text;
BEGIN 
  -- test/function name
  test_name := 'test_result_schema';
  -- test description
  test_description := 'Ensure the result table has ALL the core PMT fields.';
  -- list of expected core columns for the table we are testing
  expected_columns := ARRAY['id', 'activity_id', '_title', '_description', '_active', '_retired_by', 
	'_created_by', '_created_date', '_updated_by', '_updated_date']::text[];

  -- get all the columns from the table we are testing 
  SELECT INTO table_columns array_agg(column_name::text)::text[] FROM information_schema.columns WHERE table_schema = 'public'  AND table_name = 'result';
  -- test
  SELECT INTO pass table_columns @> expected_columns;
  -- write results with name and description of test
  INSERT INTO unit_test (_name,_description, _pass, _execution_sucess) VALUES (test_name, test_description, pass, true);
  
  RETURN true;

  EXCEPTION WHEN others THEN
  GET STACKED DIAGNOSTICS error_msg1 = MESSAGE_TEXT,
                          error_msg2 = PG_EXCEPTION_DETAIL,
                          error_msg3 = PG_EXCEPTION_HINT;
  msg:= error_msg1 || ' : ' || error_msg2 || ' : ' || error_msg3;
  RAISE NOTICE 'An error executing %', test_name || ': ' || msg;  
  
  -- note the test execution failed with name and description of test
  INSERT INTO unit_test (_name,_description, _pass, _execution_sucess) VALUES (test_name, test_description, false, false);
  
  RETURN false;                          
END; 
$$ LANGUAGE 'plpgsql';

/******************************************************************
  test_result_taxonomy_schema
******************************************************************/
CREATE OR REPLACE FUNCTION test_result_taxonomy_schema() RETURNS boolean AS $$
DECLARE 
  test_name text;
  test_description text;
  expected_columns text[];
  table_columns text[];
  pass boolean;
  msg text;
  error_msg1 text;
  error_msg2 text;
  error_msg3 text;
BEGIN 
  -- test/function name
  test_name := 'test_result_taxonomy_schema';
  -- test description
  test_description := 'Ensure the result_taxonomy table has ONLY the core PMT fields.';
  -- list of expected core columns for the table we are testing
  expected_columns := ARRAY['result_id', 'classification_id', '_field']::text[];

  -- get all the columns from the table we are testing 
  SELECT INTO table_columns array_agg(column_name::text)::text[] FROM information_schema.columns WHERE table_schema = 'public'  AND table_name = 'result_taxonomy';
  -- test
  SELECT INTO pass table_columns = expected_columns;
  -- write results with name and description of test
  INSERT INTO unit_test (_name,_description, _pass, _execution_sucess) VALUES (test_name, test_description, pass, true);
  
  RETURN true;

  EXCEPTION WHEN others THEN
  GET STACKED DIAGNOSTICS error_msg1 = MESSAGE_TEXT,
                          error_msg2 = PG_EXCEPTION_DETAIL,
                          error_msg3 = PG_EXCEPTION_HINT;
  msg:= error_msg1 || ' : ' || error_msg2 || ' : ' || error_msg3;
  RAISE NOTICE 'An error executing %', test_name || ': ' || msg;  
  
  -- note the test execution failed with name and description of test
  INSERT INTO unit_test (_name,_description, _pass, _execution_sucess) VALUES (test_name, test_description, false, false);
  
  RETURN false;                          
END; 
$$ LANGUAGE 'plpgsql';

/******************************************************************
  test_role_schema
******************************************************************/
CREATE OR REPLACE FUNCTION test_role_schema() RETURNS boolean AS $$
DECLARE 
  test_name text;
  test_description text;
  expected_columns text[];
  table_columns text[];
  pass boolean;
  msg text;
  error_msg1 text;
  error_msg2 text;
  error_msg3 text;
BEGIN 
  -- test/function name
  test_name := 'test_role_schema';
  -- test description
  test_description := 'Ensure the role table has ONLY the core PMT fields.';
  -- list of expected core columns for the table we are testing
  expected_columns := ARRAY['id', '_name', '_description', '_read', '_create', '_update', 
	'_delete', '_super', '_security', '_active', '_retired_by', '_created_by', '_created_date', 
	'_updated_by', '_updated_date']::text[];

  -- get all the columns from the table we are testing 
  SELECT INTO table_columns array_agg(column_name::text)::text[] FROM information_schema.columns WHERE table_schema = 'public'  AND table_name = 'role';
  -- test
  SELECT INTO pass table_columns = expected_columns;
  -- write results with name and description of test
  INSERT INTO unit_test (_name,_description, _pass, _execution_sucess) VALUES (test_name, test_description, pass, true);
  
  RETURN true;

  EXCEPTION WHEN others THEN
  GET STACKED DIAGNOSTICS error_msg1 = MESSAGE_TEXT,
                          error_msg2 = PG_EXCEPTION_DETAIL,
                          error_msg3 = PG_EXCEPTION_HINT;
  msg:= error_msg1 || ' : ' || error_msg2 || ' : ' || error_msg3;
  RAISE NOTICE 'An error executing %', test_name || ': ' || msg;  
  
  -- note the test execution failed with name and description of test
  INSERT INTO unit_test (_name,_description, _pass, _execution_sucess) VALUES (test_name, test_description, false, false);
  
  RETURN false;                          
END; 
$$ LANGUAGE 'plpgsql';

/******************************************************************
  test_taxonomy_schema
******************************************************************/
CREATE OR REPLACE FUNCTION test_taxonomy_schema() RETURNS boolean AS $$
DECLARE 
  test_name text;
  test_description text;
  expected_columns text[];
  table_columns text[];
  pass boolean;
  msg text;
  error_msg1 text;
  error_msg2 text;
  error_msg3 text;
BEGIN 
  -- test/function name
  test_name := 'test_taxonomy_schema';
  -- test description
  test_description := 'Ensure the taxonomy table has ONLY the core PMT fields.';
  -- list of expected core columns for the table we are testing
  expected_columns := ARRAY['id', '_name', '_description', '_iati_codelist', 'parent_id', 
	'_is_category', '_active', '_retired_by', '_created_by', '_created_date', '_updated_by', 
	'_updated_date']::text[];

  -- get all the columns from the table we are testing 
  SELECT INTO table_columns array_agg(column_name::text)::text[] FROM information_schema.columns WHERE table_schema = 'public'  AND table_name = 'taxonomy';
  -- test
  SELECT INTO pass table_columns = expected_columns;
  -- write results with name and description of test
  INSERT INTO unit_test (_name,_description, _pass, _execution_sucess) VALUES (test_name, test_description, pass, true);
  
  RETURN true;

  EXCEPTION WHEN others THEN
  GET STACKED DIAGNOSTICS error_msg1 = MESSAGE_TEXT,
                          error_msg2 = PG_EXCEPTION_DETAIL,
                          error_msg3 = PG_EXCEPTION_HINT;
  msg:= error_msg1 || ' : ' || error_msg2 || ' : ' || error_msg3;
  RAISE NOTICE 'An error executing %', test_name || ': ' || msg;  
  
  -- note the test execution failed with name and description of test
  INSERT INTO unit_test (_name,_description, _pass, _execution_sucess) VALUES (test_name, test_description, false, false);
  
  RETURN false;                          
END; 
$$ LANGUAGE 'plpgsql';

/******************************************************************
  test_taxonomy_xwalk_schema
******************************************************************/
CREATE OR REPLACE FUNCTION test_taxonomy_xwalk_schema() RETURNS boolean AS $$
DECLARE 
  test_name text;
  test_description text;
  expected_columns text[];
  table_columns text[];
  pass boolean;
  msg text;
  error_msg1 text;
  error_msg2 text;
  error_msg3 text;
BEGIN 
  -- test/function name
  test_name := 'test_taxonomy_xwalk_schema';
  -- test description
  test_description := 'Ensure the taxonomy_xwalk table has ONLY the core PMT fields.';
  -- list of expected core columns for the table we are testing
  expected_columns := ARRAY['id', 'origin_taxonomy_id', 'linked_taxonomy_id', 'origin_classification_id', 
	'linked_classification_id', '_direction', '_active', '_retired_by', '_created_by', '_created_date', 
	'_updated_by', '_updated_date']::text[];

  -- get all the columns from the table we are testing 
  SELECT INTO table_columns array_agg(column_name::text)::text[] FROM information_schema.columns WHERE table_schema = 'public'  AND table_name = 'taxonomy_xwalk';
  -- test
  SELECT INTO pass table_columns = expected_columns;
  -- write results with name and description of test
  INSERT INTO unit_test (_name,_description, _pass, _execution_sucess) VALUES (test_name, test_description, pass, true);
  
  RETURN true;

  EXCEPTION WHEN others THEN
  GET STACKED DIAGNOSTICS error_msg1 = MESSAGE_TEXT,
                          error_msg2 = PG_EXCEPTION_DETAIL,
                          error_msg3 = PG_EXCEPTION_HINT;
  msg:= error_msg1 || ' : ' || error_msg2 || ' : ' || error_msg3;
  RAISE NOTICE 'An error executing %', test_name || ': ' || msg;  
  
  -- note the test execution failed with name and description of test
  INSERT INTO unit_test (_name,_description, _pass, _execution_sucess) VALUES (test_name, test_description, false, false);
  
  RETURN false;                          
END; 
$$ LANGUAGE 'plpgsql';

/******************************************************************
  test_user_activity_role_schema
******************************************************************/
CREATE OR REPLACE FUNCTION test_user_activity_role_schema() RETURNS boolean AS $$
DECLARE 
  test_name text;
  test_description text;
  expected_columns text[];
  table_columns text[];
  pass boolean;
  msg text;
  error_msg1 text;
  error_msg2 text;
  error_msg3 text;
BEGIN 
  -- test/function name
  test_name := 'test_user_activity_role_schema';
  -- test description
  test_description := 'Ensure the user_activity_role table has ONLY the core PMT fields.';
  -- list of expected core columns for the table we are testing
  expected_columns := ARRAY['id', 'user_id', 'role_id', 'activity_id', 'classification_id', '_active', 
	'_retired_by', '_created_by', '_created_date', '_updated_by', '_updated_date']::text[];

  -- get all the columns from the table we are testing 
  SELECT INTO table_columns array_agg(column_name::text)::text[] FROM information_schema.columns WHERE table_schema = 'public'  AND table_name = 'user_activity_role';
  -- test
  SELECT INTO pass table_columns = expected_columns;
  -- write results with name and description of test
  INSERT INTO unit_test (_name,_description, _pass, _execution_sucess) VALUES (test_name, test_description, pass, true);
  
  RETURN true;

  EXCEPTION WHEN others THEN
  GET STACKED DIAGNOSTICS error_msg1 = MESSAGE_TEXT,
                          error_msg2 = PG_EXCEPTION_DETAIL,
                          error_msg3 = PG_EXCEPTION_HINT;
  msg:= error_msg1 || ' : ' || error_msg2 || ' : ' || error_msg3;
  RAISE NOTICE 'An error executing %', test_name || ': ' || msg;  
  
  -- note the test execution failed with name and description of test
  INSERT INTO unit_test (_name,_description, _pass, _execution_sucess) VALUES (test_name, test_description, false, false);
  
  RETURN false;                          
END; 
$$ LANGUAGE 'plpgsql';

/******************************************************************
  test_user_log_schema
******************************************************************/
CREATE OR REPLACE FUNCTION test_user_log_schema() RETURNS boolean AS $$
DECLARE 
  test_name text;
  test_description text;
  expected_columns text[];
  table_columns text[];
  pass boolean;
  msg text;
  error_msg1 text;
  error_msg2 text;
  error_msg3 text;
BEGIN 
  -- test/function name
  test_name := 'test_user_log_schema';
  -- test description
  test_description := 'Ensure the user_log table has ONLY the core PMT fields.';
  -- list of expected core columns for the table we are testing
  expected_columns := ARRAY['id', 'user_id', '_username', '_access_date', '_status']::text[];

  -- get all the columns from the table we are testing 
  SELECT INTO table_columns array_agg(column_name::text)::text[] FROM information_schema.columns WHERE table_schema = 'public'  AND table_name = 'user_log';
  -- test
  SELECT INTO pass table_columns = expected_columns;
  -- write results with name and description of test
  INSERT INTO unit_test (_name,_description, _pass, _execution_sucess) VALUES (test_name, test_description, pass, true);
  
  RETURN true;

  EXCEPTION WHEN others THEN
  GET STACKED DIAGNOSTICS error_msg1 = MESSAGE_TEXT,
                          error_msg2 = PG_EXCEPTION_DETAIL,
                          error_msg3 = PG_EXCEPTION_HINT;
  msg:= error_msg1 || ' : ' || error_msg2 || ' : ' || error_msg3;
  RAISE NOTICE 'An error executing %', test_name || ': ' || msg;  
  
  -- note the test execution failed with name and description of test
  INSERT INTO unit_test (_name,_description, _pass, _execution_sucess) VALUES (test_name, test_description, false, false);
  
  RETURN false;                          
END; 
$$ LANGUAGE 'plpgsql';

/******************************************************************
  test_users_schema
******************************************************************/
CREATE OR REPLACE FUNCTION test_users_schema() RETURNS boolean AS $$
DECLARE 
  test_name text;
  test_description text;
  expected_columns text[];
  table_columns text[];
  pass boolean;
  msg text;
  error_msg1 text;
  error_msg2 text;
  error_msg3 text;
BEGIN 
  -- test/function name
  test_name := 'test_users_schema';
  -- test description
  test_description := 'Ensure the users table has ALL the core PMT fields.';
  -- list of expected core columns for the table we are testing
  expected_columns := ARRAY['id', 'organization_id', 'role_id', '_first_name', '_last_name', '_username', 
	'_email', '_password', '_active', '_retired_by', '_created_by', '_created_date', '_updated_by', 
	'_updated_date']::text[];

  -- get all the columns from the table we are testing 
  SELECT INTO table_columns array_agg(column_name::text)::text[] FROM information_schema.columns WHERE table_schema = 'public'  AND table_name = 'users';
  -- test
  SELECT INTO pass table_columns @> expected_columns;
  -- write results with name and description of test
  INSERT INTO unit_test (_name,_description, _pass, _execution_sucess) VALUES (test_name, test_description, pass, true);
  
  RETURN true;

  EXCEPTION WHEN others THEN
  GET STACKED DIAGNOSTICS error_msg1 = MESSAGE_TEXT,
                          error_msg2 = PG_EXCEPTION_DETAIL,
                          error_msg3 = PG_EXCEPTION_HINT;
  msg:= error_msg1 || ' : ' || error_msg2 || ' : ' || error_msg3;
  RAISE NOTICE 'An error executing %', test_name || ': ' || msg;  
  
  -- note the test execution failed with name and description of test
  INSERT INTO unit_test (_name,_description, _pass, _execution_sucess) VALUES (test_name, test_description, false, false);
  
  RETURN false;                          
END; 
$$ LANGUAGE 'plpgsql';

/******************************************************************
  test_version_schema
******************************************************************/
CREATE OR REPLACE FUNCTION test_version_schema() RETURNS boolean AS $$
DECLARE 
  test_name text;
  test_description text;
  expected_columns text[];
  table_columns text[];
  pass boolean;
  msg text;
  error_msg1 text;
  error_msg2 text;
  error_msg3 text;
BEGIN 
  -- test/function name
  test_name := 'test_version_schema';
  -- test description
  test_description := 'Ensure the version table has ONLY the core PMT fields.';
  -- list of expected core columns for the table we are testing
  expected_columns := ARRAY['id', '_version', '_iteration', '_changeset', '_created_date', '_updated_date']::text[];

  -- get all the columns from the table we are testing 
  SELECT INTO table_columns array_agg(column_name::text)::text[] FROM information_schema.columns WHERE table_schema = 'public'  AND table_name = 'version';
  -- test
  SELECT INTO pass table_columns = expected_columns;
  -- write results with name and description of test
  INSERT INTO unit_test (_name,_description, _pass, _execution_sucess) VALUES (test_name, test_description, pass, true);
  
  RETURN true;

  EXCEPTION WHEN others THEN
  GET STACKED DIAGNOSTICS error_msg1 = MESSAGE_TEXT,
                          error_msg2 = PG_EXCEPTION_DETAIL,
                          error_msg3 = PG_EXCEPTION_HINT;
  msg:= error_msg1 || ' : ' || error_msg2 || ' : ' || error_msg3;
  RAISE NOTICE 'An error executing %', test_name || ': ' || msg;  
  
  -- note the test execution failed with name and description of test
  INSERT INTO unit_test (_name,_description, _pass, _execution_sucess) VALUES (test_name, test_description, false, false);
  
  RETURN false;                          
END; 
$$ LANGUAGE 'plpgsql';

/******************************************************************
  test_version_schema
******************************************************************/
CREATE OR REPLACE FUNCTION test_version_schema() RETURNS boolean AS $$
DECLARE 
  test_name text;
  test_description text;
  expected_columns text[];
  table_columns text[];
  pass boolean;
  msg text;
  error_msg1 text;
  error_msg2 text;
  error_msg3 text;
BEGIN 
  -- test/function name
  test_name := 'test_version_schema';
  -- test description
  test_description := 'Ensure the version table has ONLY the core PMT fields.';
  -- list of expected core columns for the table we are testing
  expected_columns := ARRAY['id', '_version', '_iteration', '_changeset', '_created_date', '_updated_date']::text[];

  -- get all the columns from the table we are testing 
  SELECT INTO table_columns array_agg(column_name::text)::text[] FROM information_schema.columns WHERE table_schema = 'public'  AND table_name = 'version';
  -- test
  SELECT INTO pass table_columns = expected_columns;
  -- write results with name and description of test
  INSERT INTO unit_test (_name,_description, _pass, _execution_sucess) VALUES (test_name, test_description, pass, true);
  
  RETURN true;

  EXCEPTION WHEN others THEN
  GET STACKED DIAGNOSTICS error_msg1 = MESSAGE_TEXT,
                          error_msg2 = PG_EXCEPTION_DETAIL,
                          error_msg3 = PG_EXCEPTION_HINT;
  msg:= error_msg1 || ' : ' || error_msg2 || ' : ' || error_msg3;
  RAISE NOTICE 'An error executing %', test_name || ': ' || msg;  
  
  -- note the test execution failed with name and description of test
  INSERT INTO unit_test (_name,_description, _pass, _execution_sucess) VALUES (test_name, test_description, false, false);
  
  RETURN false;                          
END; 
$$ LANGUAGE 'plpgsql';

/******************************************************************
  test_core_views
******************************************************************/
CREATE OR REPLACE FUNCTION test_core_views() RETURNS boolean AS $$
DECLARE 
  test_name text;
  test_description text;
  expected_views text[];
  database_views text[];
  pass boolean;
  msg text;
  error_msg1 text;
  error_msg2 text;
  error_msg3 text;
BEGIN 
  -- test/function name
  test_name := 'test_core_views';
  -- test description
  test_description := 'Ensure ALL the core PMT views exists.';
  -- list of expected core views we are testing
  expected_views := ARRAY['_accountable_organizations','_active_activities','_taxonomy_classifications','_activity_contacts',
	'_partnerlink_participants','_activity_participants','_activity_taxonomies','_activity_taxonomy_xwalks','_data_change_report',
	'_data_loading_report','_data_validation_report','_entity_taxonomy','_gaul_lookup','_location_boundary_features','_organization_participation',
	'_activity_points','_tags','_taxonomy_xwalks','_taxonomy_lookup','_location_lookup','_organization_lookup']::text[];

  -- get all the views in the database
  SELECT INTO database_views array_agg(table_name::text)::text[] from INFORMATION_SCHEMA.views WHERE table_schema = 'public';
  -- test
  SELECT INTO pass database_views @> expected_views;
  -- write results with name and description of test
  INSERT INTO unit_test (_name,_description, _pass, _execution_sucess) VALUES (test_name, test_description, pass, true);
  
  RETURN true;

  EXCEPTION WHEN others THEN
  GET STACKED DIAGNOSTICS error_msg1 = MESSAGE_TEXT,
                          error_msg2 = PG_EXCEPTION_DETAIL,
                          error_msg3 = PG_EXCEPTION_HINT;
  msg:= error_msg1 || ' : ' || error_msg2 || ' : ' || error_msg3;
  RAISE NOTICE 'An error executing %', test_name || ': ' || msg; 
  
  -- note the test execution failed with name and description of test
  INSERT INTO unit_test (_name,_description, _pass, _execution_sucess) VALUES (test_name, test_description, false, false);
  
  RETURN false;                          
END; 
$$ LANGUAGE 'plpgsql';

/******************************************************************
  test_upd_geometry_formats
  SELECT * FROM test_upd_geometry_formats()
******************************************************************/
CREATE OR REPLACE FUNCTION test_upd_geometry_formats() RETURNS boolean AS $$
DECLARE 
  test_name text;
  test_description text;
  latitude numeric;
  longitude numeric;
  a_id integer;
  location_rec record;
  pass boolean;
  msg text;
  error_msg1 text;
  error_msg2 text;
  error_msg3 text;
BEGIN 
  -- test/function name
  test_name := 'test_upd_geometry_formats';
  -- test description
  test_description := 'Test the location table''s trigger (pmt_upd_geometry_formats).';
  -- generate a random latitude and longitude
  SELECT INTO latitude random() * 179 - 89 FROM generate_series(1,1);
  SELECT INTO longitude  random() * 359 - 179 FROM generate_series(1,1);
  -- get a valid activity id
  SELECT INTO a_id id FROM activity LIMIT 1;

  -- if the activity table is empty this test will fail
  IF a_id IS NULL THEN
    RETURN false;
  END IF;
  
  -- insert new point into location
  INSERT INTO location (activity_id, _point, _created_by, _updated_by) VALUES (a_id, ST_GeomFromText('POINT(' || longitude || ' ' || latitude || ')', 4326), 'test', 'test'); 

  -- test that the trigger has populated the format fields
  pass := true;
  FOR location_rec IN SELECT _x, _y, _lat_dd, _long_dd, _latlong, _georef FROM location WHERE _created_by = 'test' LOOP
    IF location_rec._x IS NULL THEN
      pass := false;
    END IF;
    IF location_rec._y IS NULL THEN
      pass := false;
    END IF;
    IF location_rec._lat_dd IS NULL THEN
      pass := false;
    END IF;
    IF location_rec._long_dd IS NULL THEN
      pass := false;
    END IF;
    IF location_rec._latlong IS NULL THEN
      pass := false;
    END IF;
    IF location_rec._georef IS NULL THEN
      pass := false;
    END IF;    
  END LOOP;

  -- clean up test
  DELETE FROM location WHERE _created_by = 'test';
  -- write results with name and description of test
  INSERT INTO unit_test (_name,_description, _pass, _execution_sucess) VALUES (test_name, test_description, pass, true);
  
  RETURN true;

  EXCEPTION WHEN others THEN
  GET STACKED DIAGNOSTICS error_msg1 = MESSAGE_TEXT,
                          error_msg2 = PG_EXCEPTION_DETAIL,
                          error_msg3 = PG_EXCEPTION_HINT;                  
  msg:= error_msg1 || ' : ' || error_msg2 || ' : ' || error_msg3;
  RAISE NOTICE 'An error executing %', test_name || ': ' || msg; 
   
    -- clean up test
  DELETE FROM location WHERE _created_by = 'test';       
   
  -- note the test execution failed with name and description of test
  INSERT INTO unit_test (_name,_description, _pass, _execution_sucess) VALUES (test_name, test_description, false, false);
  
  RETURN false;                          
END; 
$$ LANGUAGE 'plpgsql';