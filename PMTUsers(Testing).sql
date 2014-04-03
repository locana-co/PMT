/*********************************************
	PMT Core Testing Users

The below script is to add testing users to a
PMT database instance. Must have at least one
organization and one data group loaded.
*********************************************/

----------
-- Step 1
-- Find organization and data_group ids
----------
SELECT * FROM organization;
SELECT * FROM pmt_data_groups();

----------
-- Step 2
-- Update scripts with ids and run
----------
-- test reader user with Reader role
SELECT * FROM pmt_create_user(<organization_id>, <data_group_id>, (SELECT role_id FROM role WHERE name = 'Reader'), 'reader', 'reader', 'info@spatialdev.com', 'reader', '(pmt testing user)'); 
-- test editor user with Editor role
SELECT * FROM pmt_create_user(<organization_id>, <data_group_id>, (SELECT role_id FROM role WHERE name = 'Editor'), 'editor', 'editor', 'info@spatialdev.com', 'editor', '(pmt testing user)'); 
-- test super user with Super role
SELECT * FROM pmt_create_user(<organization_id>, <data_group_id>, (SELECT role_id FROM role WHERE name = 'Super'), 'super', 'super', 'info@spatialdev.com', 'super', '(pmt testing user)'); 

----------
-- Step 3
-- View users
----------
SELECT * FROM pmt_users();