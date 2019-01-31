
/************************************************************
 Creates permissions on the server for PMT instances
************************************************************/

-------------------------------------------
-- STEP 1
-- creates a server user
-- perform once per server
-------------------------------------------
CREATE USER pmt_read WITH PASSWORD 'password';
CREATE USER pmt_write WITH PASSWORD 'password';

-------------------------------------------
-- STEP 2
-- allows connection to specific database
-- perform once per database instance
--
-- IMPORTANT - change to database name
-------------------------------------------
GRANT CONNECT ON DATABASE <database_name> TO pmt_read;
GRANT CONNECT ON DATABASE <database_name> TO pmt_write;

-------------------------------------------
-- STEP 3
-- permissions
-- perform once per database instance
-------------------------------------------
GRANT USAGE ON SCHEMA public TO pmt_read;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO pmt_read;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO pmt_read;

GRANT USAGE ON SCHEMA public TO pmt_write;
GRANT SELECT,INSERT ON ALL TABLES IN SCHEMA public TO pmt_write;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO pmt_write;
-- temporary solution for BMGF to allow execution of pmt_filter_csv()
ALTER USER pmt_write WITH SUPERUSER;
