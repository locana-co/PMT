/******************************************************************
Change Script 2.0.8.57
1. data_validation_report - new view to validate data in the database
2. data_loading_report - update to reflect total and active record
counts. 
******************************************************************/
INSERT INTO version(version, iteration, changeset) VALUES (2.0, 8, 57);
-- select * from version order by changeset desc;

-- select * from data_validation_report
-- select * from data_loading_report

CREATE OR REPLACE VIEW data_validation_report
AS SELECT 'Projects have a data group' AS Test,
(SELECT COUNT(project_id) FROM project WHERE project_id 
NOT IN (SELECT project_id FROM project_taxonomy WHERE classification_id 
IN (SELECT classification_id FROM taxonomy_classifications WHERE taxonomy = 'Data Group'))) AS Result,
0 AS Expected
UNION ALL
SELECT 'Orphaned activity' AS Test,
(SELECT COUNT(*) FROM activity WHERE project_id NOT IN (SELECT project_id FROM project) ) AS Result,
0 AS Expected
UNION ALL
SELECT 'Orphaned locations' AS Test,
(SELECT COUNT(*) FROM location WHERE activity_id NOT IN (SELECT activity_id FROM activity) 
OR project_id NOT IN (SELECT project_id FROM project)) AS Result,
0 AS Expected
UNION ALL
SELECT 'Orphaned financial' AS Test,
(SELECT COUNT(*) FROM financial WHERE activity_id NOT IN (SELECT activity_id FROM activity) 
OR project_id NOT IN (SELECT project_id FROM project)) AS Result,
0 AS Expected
UNION ALL
SELECT 'Orphaned participation' AS Test,
(SELECT COUNT(*) FROM participation WHERE activity_id NOT IN (SELECT activity_id FROM activity) 
OR project_id NOT IN (SELECT project_id FROM project) 
OR organization_id NOT IN (SELECT organization_id FROM organization)) AS Result,
0 AS Expected
UNION ALL
SELECT 'Orphaned project contact' AS Test,
(SELECT COUNT(*) FROM project_contact WHERE project_id NOT IN (SELECT project_id FROM project)) AS Result,
0 AS Expected
UNION ALL
SELECT 'Orphaned activity contact' AS Test,
(SELECT COUNT(*) FROM activity_contact WHERE activity_id NOT IN (SELECT activity_id FROM activity)) AS Result,
0 AS Expected
UNION ALL
SELECT 'Orphaned contact' AS Test,
(SELECT COUNT(*) FROM contact WHERE organization_id NOT IN (SELECT organization_id FROM organization)) AS Result,
0 AS Expected
UNION ALL
SELECT 'Orphaned detail' AS Test,
(SELECT COUNT(*) FROM detail WHERE activity_id NOT IN (SELECT activity_id FROM activity) 
OR project_id NOT IN (SELECT project_id FROM project)) AS Result,
0 AS Expected
UNION ALL
SELECT 'Orphaned result' AS Test,
(SELECT COUNT(*) FROM result WHERE activity_id NOT IN (SELECT activity_id FROM activity) ) AS Result,
0 AS Expected
UNION ALL
SELECT 'Orphaned activity taxonomy' AS Test,
(SELECT COUNT(*) FROM activity_taxonomy WHERE activity_id NOT IN (SELECT activity_id FROM activity)) AS Result,
0 AS Expected
UNION ALL
SELECT 'Orphaned contact taxonomy' AS Test,
(SELECT COUNT(*) FROM contact_taxonomy WHERE contact_id NOT IN (SELECT contact_id FROM contact)) AS Result,
0 AS Expected
UNION ALL
SELECT 'Orphaned financial taxonomy' AS Test,
(SELECT COUNT(*) FROM financial_taxonomy WHERE financial_id NOT IN (SELECT financial_id FROM financial)) AS Result,
0 AS Expected
UNION ALL
SELECT 'Orphaned location taxonomy' AS Test,
(SELECT COUNT(*) FROM location_taxonomy WHERE location_id NOT IN (SELECT location_id FROM location)) AS Result,
0 AS Expected
UNION ALL
SELECT 'Orphaned organization taxonomy' AS Test,
(SELECT COUNT(*) FROM organization_taxonomy WHERE organization_id NOT IN (SELECT organization_id FROM organization)) AS Result,
0 AS Expected
UNION ALL
SELECT 'Orphaned participation taxonomy' AS Test,
(SELECT COUNT(*) FROM participation_taxonomy WHERE participation_id NOT IN (SELECT participation_id FROM participation)) AS Result,
0 AS Expected
UNION ALL
SELECT 'Orphaned project taxonomy' AS Test,
(SELECT COUNT(*) FROM project_taxonomy WHERE project_id NOT IN (SELECT project_id FROM project)) AS Result,
0 AS Expected
UNION ALL
SELECT 'Orphaned result taxonomy' AS Test,
(SELECT COUNT(*) FROM result_taxonomy WHERE result_id NOT IN (SELECT result_id FROM result)) AS Result,
0 AS Expected
UNION ALL
SELECT 'Orphaned location boundary' AS Test,
(SELECT COUNT(*) FROM location_boundary WHERE location_id NOT IN (SELECT location_id FROM location)) AS Result,
0 AS Expected
UNION ALL
SELECT 'Activity without location' AS Test,
(SELECT COUNT(*) FROM activity WHERE activity_id NOT IN (SELECT activity_id FROM location) AND active = true) AS Result,
0 AS Expected
UNION ALL
SELECT 'Project without activity' AS Test,
(SELECT COUNT(*) FROM project WHERE project_id NOT IN (SELECT project_id FROM activity) AND active = true) AS Result,
0 AS Expected
UNION ALL
SELECT 'Project without participation' AS Test,
(SELECT COUNT(*) FROM project WHERE project_id NOT IN (SELECT project_id FROM participation) AND active = true) AS Result,
0 AS Expected
UNION ALL
SELECT 'Activity without participation' AS Test,
(SELECT COUNT(*) FROM activity WHERE activity_id NOT IN (SELECT activity_id FROM participation) AND active = true) AS Result,
0 AS Expected
UNION ALL
SELECT 'Active activity with inactive project' AS Test,
(SELECT COUNT(*) FROM activity WHERE active = true AND project_id IN (SELECT project_id FROM project WHERE active = false)) AS Result,
0 AS Expected
UNION ALL
SELECT 'Active detail with inactive project' AS Test,
(SELECT COUNT(*) FROM detail WHERE active = true AND project_id IN (SELECT project_id FROM project WHERE active = false)) AS Result,
0 AS Expected
UNION ALL
SELECT 'Active detail with inactive activity' AS Test,
(SELECT COUNT(*) FROM detail WHERE active = true AND activity_id IN (SELECT activity_id FROM activity WHERE active = false)) AS Result,
0 AS Expected
UNION ALL
SELECT 'Active financial with inactive project' AS Test,
(SELECT COUNT(*) FROM financial WHERE active = true AND project_id IN (SELECT project_id FROM project WHERE active = false)) AS Result,
0 AS Expected
UNION ALL
SELECT 'Active financial with inactive activity' AS Test,
(SELECT COUNT(*) FROM financial WHERE active = true AND activity_id IN (SELECT activity_id FROM activity WHERE active = false)) AS Result,
0 AS Expected
UNION ALL
SELECT 'Active activity with inactive project' AS Test,
(SELECT COUNT(*) FROM activity WHERE active = true AND project_id IN (SELECT project_id FROM project WHERE active = false)) AS Result,
0 AS Expected
UNION ALL
SELECT 'Active location with inactive project' AS Test,
(SELECT COUNT(*) FROM location WHERE active = true AND project_id IN (SELECT project_id FROM project WHERE active = false)) AS Result,
0 AS Expected
UNION ALL
SELECT 'Active location with inactive activity' AS Test,
(SELECT COUNT(*) FROM location WHERE active = true AND activity_id IN (SELECT activity_id FROM activity WHERE active = false)) AS Result,
0 AS Expected
UNION ALL
SELECT 'Active participation with inactive project' AS Test,
(SELECT COUNT(*) FROM participation WHERE active = true AND project_id IN (SELECT project_id FROM project WHERE active = false)) AS Result,
0 AS Expected
UNION ALL
SELECT 'Active participation with inactive activity' AS Test,
(SELECT COUNT(*) FROM participation WHERE active = true AND activity_id IN (SELECT activity_id FROM activity WHERE active = false)) AS Result,
0 AS Expected
UNION ALL
SELECT 'Active participation with inactive organization' AS Test,
(SELECT COUNT(*) FROM participation WHERE active = true AND organization_id IN (SELECT organization_id FROM organization WHERE active = false)) AS Result,
0 AS Expected
UNION ALL
SELECT 'Active result with inactive activity' AS Test,
(SELECT COUNT(*) FROM result WHERE active = true AND activity_id IN (SELECT activity_id FROM activity WHERE active = false)) AS Result,
0 AS Expected
UNION ALL
SELECT 'Duplicate organization' AS Test,
(SELECT COUNT(ct) FROM (SELECT name, count(*) AS ct FROM organization GROUP BY 1) as foo WHERE ct > 1) AS Result,
0 AS Expected;

DROP VIEW data_loading_report;
CREATE OR REPLACE VIEW data_loading_report
AS SELECT 'activity table' as "table", COUNT(*) AS "total record count", (SELECT COUNT(*) FROM activity WHERE active = true) AS "active record count", 0 AS "core PMT count", '' as "comments" FROM activity
UNION ALL
SELECT 'activity_contact' as "table", COUNT(*) AS "total record count", (SELECT COUNT(*) FROM activity_contact) AS "active record count", 0 AS "core PMT count", '' as "comments" FROM activity_contact
UNION ALL
SELECT 'activity_taxonomy' as "table", COUNT(*) AS "total record count", (SELECT COUNT(*) FROM activity_taxonomy) AS "active record count", 0 AS "core PMT count", '' as "comments" FROM activity_taxonomy
UNION ALL
SELECT 'boundary table' as "table", COUNT(*) AS "total record count", (SELECT COUNT(*) FROM boundary WHERE active = true) AS "active record count", 3 AS "core PMT count", 'Correct count reflects minimum count on default PMT install.' as "comments" FROM boundary			
UNION ALL
SELECT 'boundary_taxonomy' as "table", COUNT(*) AS "total record count", (SELECT COUNT(*) FROM boundary_taxonomy) AS "active record count", 0 AS "core PMT count", '' as "comments" FROM boundary_taxonomy			
UNION ALL
SELECT 'contact table' as "table", COUNT(*) AS "total record count", (SELECT COUNT(*) FROM contact WHERE active = true) AS "active record count", 0 AS "core PMT count", '' as "comments" FROM contact			
UNION ALL
SELECT 'contact_taxonomy' as "table", COUNT(*) AS "total record count", (SELECT COUNT(*) FROM contact_taxonomy) AS "active record count", 0 AS "core PMT count", '' as "comments" FROM contact_taxonomy
UNION ALL
SELECT 'detail table' as "table", COUNT(*) AS "total record count", (SELECT COUNT(*) FROM detail WHERE active = true) AS "active record count", 0 AS "core PMT count", '' as "comments" FROM detail
UNION ALL
SELECT 'feature_taxonomy' as "table", COUNT(*) AS "total record count", (SELECT COUNT(*) FROM feature_taxonomy) AS "active record count", 277 AS "core PMT count", 'Correct count reflects minimum count on default PMT install.' as "comments" FROM feature_taxonomy
UNION ALL
SELECT 'financial table' as "table", COUNT(*) AS "total record count", (SELECT COUNT(*) FROM financial WHERE active = true) AS "active record count", 0 AS "core PMT count", '' as "comments" FROM financial
UNION ALL
SELECT 'financial_taxonomy' as "table", COUNT(*) AS "total record count", (SELECT COUNT(*) FROM financial_taxonomy) AS "active record count", 0 AS "core PMT count", '' as "comments" FROM financial_taxonomy
UNION ALL
SELECT 'gaul0 table' as "table", COUNT(*) AS "total record count", (SELECT COUNT(*) FROM gaul0 WHERE active = true) AS "active record count", 277 AS "core PMT count", 'Core count reflects minimum count on default PMT install.' as "comments" FROM gaul0
UNION ALL
SELECT 'gaul1 table' as "table", COUNT (*) AS "total record count", (SELECT COUNT(*) FROM gaul1 WHERE active = true) AS "active record count", 3469 AS "core PMT count", 'Core count reflects minimum count on default PMT install.' as "comments" FROM gaul1
UNION ALL
SELECT 'gaul2 table' as "table", COUNT(*) AS "total record count", (SELECT COUNT(*) FROM gaul2 WHERE active = true) AS "active record count", 37378 AS "core PMT count", 'Core count reflects minimum count on default PMT install.' as "comments" FROM gaul2
UNION ALL
SELECT 'location table' as "table", COUNT(*) AS "total record count", (SELECT COUNT(*) FROM location WHERE active = true) AS "active record count", 0 AS "core PMT count", '' as "comments" FROM location 
UNION ALL
SELECT 'location_boundary' as "table", COUNT(*) AS "total record count", (SELECT COUNT(*) FROM location_boundary) AS "active record count", 0 AS "core PMT count", '' as "comments" FROM location_boundary
UNION ALL
SELECT 'location_taxonomy' as "table", COUNT(*) AS "total record count", (SELECT COUNT(*) FROM location_taxonomy) AS "active record count", 0 AS "core PMT count", '' as "comments" FROM location_taxonomy
UNION ALL
SELECT 'map table' as "table", COUNT(*) AS "total record count", (SELECT COUNT(*) FROM map WHERE active = true) AS "active record count", 0 AS "core PMT count", '' as "comments" FROM map
UNION ALL
SELECT 'organization table' as "table", COUNT(*) AS "total record count", (SELECT COUNT(*) FROM organization WHERE active = true) AS "active record count", 0 AS "core PMT count", '' as "comments" FROM organization
UNION ALL
SELECT 'organization_taxonomy' as "table", COUNT(*) AS "total record count", (SELECT COUNT(*) FROM organization_taxonomy) AS "active record count", 0 AS "core PMT count", '' as "comments" FROM organization_taxonomy	
UNION ALL
SELECT 'participation table' as "table", COUNT(*) AS "total record count", (SELECT COUNT(*) FROM participation WHERE active = true) AS "active record count", 0 AS "core PMT count", '' as "comments" FROM participation
UNION ALL
SELECT 'participation_taxonomy' as "table", COUNT(*) AS "total record count", (SELECT COUNT(*) FROM participation_taxonomy) AS "active record count", 0 AS "core PMT count", '' as "comments" FROM participation_taxonomy
UNION ALL
SELECT 'project table' as "table", COUNT(*) AS "total record count", (SELECT COUNT(*) FROM project WHERE active = true) AS "active record count", 0 AS "core PMT count", '' as "comments" FROM project
UNION ALL
SELECT 'project_contact' as "table", COUNT(*) AS "total record count", (SELECT COUNT(*) FROM project_contact) AS "active record count", 0 AS "core PMT count", '' as "comments" FROM project_contact
UNION ALL
SELECT 'project_taxonomy' as "table", COUNT(*) AS "total record count", (SELECT COUNT(*) FROM project_taxonomy) AS "active record count", 0 AS "core PMT count", '' as "comments" FROM project_taxonomy
UNION ALL
SELECT 'result table' as "table", COUNT(*) AS "total record count", (SELECT COUNT(*) FROM result WHERE active = true) AS "active record count", 0 AS "core PMT count", '' as "comments" FROM result
UNION ALL
SELECT 'result_taxonomy' as "table", COUNT(*) AS "total record count", (SELECT COUNT(*) FROM result_taxonomy) AS "active record count", 0 AS "core PMT count", '' as "comments" FROM result_taxonomy
UNION ALL
SELECT 'role table' as "table", COUNT(*) AS "total record count", (SELECT COUNT(*) FROM role WHERE active = true) AS "active record count", 3 AS "core PMT count", 'Core count reflects minimum count on default PMT install.' as "comments" FROM role
UNION ALL
SELECT 'user table' as "table", COUNT(*) AS "total record count", (SELECT COUNT(*) FROM "user" WHERE active = true) AS "active record count", 0 AS "core PMT count", '' as "comments" FROM "user"
UNION ALL
SELECT 'user_role' as "table", COUNT(*) AS "total record count", (SELECT COUNT(*) FROM user_role) AS "active record count", 0 AS "core PMT count", '' as "comments" FROM user_role
UNION ALL
SELECT 'classification table' as "table", COUNT(*) AS "total record count", (SELECT COUNT(*) FROM classification WHERE active = true) AS "active record count", 772 AS "core PMT count", 'Core count reflects minimum count on default PMT install.' as "comments" FROM classification
UNION ALL
SELECT 'taxonomy table' as "table", COUNT(*) AS "total record count", (SELECT COUNT(*) FROM taxonomy WHERE active = true) AS "active record count", 16 AS "core PMT count", 'Core count reflects minimum count on default PMT install.' as "comments" FROM taxonomy;

-- update permissions
GRANT USAGE ON SCHEMA public TO pmt_read;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO pmt_read;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO pmt_read;
GRANT USAGE ON SCHEMA public TO pmt_write;
GRANT SELECT,INSERT ON ALL TABLES IN SCHEMA public TO pmt_write;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO pmt_write;