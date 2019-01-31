/******************************************************************
Change Script 2.0.8.59
1. data_validation_report - adding additional tests.
******************************************************************/
INSERT INTO version(version, iteration, changeset) VALUES (2.0, 8, 59);
-- select * from version order by changeset desc;

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
0 AS Expected
UNION ALL
SELECT 'Inactive classification_id from activity_taxonomy' AS Test,
(SELECT COUNT(*) FROM activity_taxonomy WHERE classification_id NOT IN (SELECT classification_id from classification where active = true)) AS Result,
0 As Expected
UNION ALL
SELECT 'Inactive classification_id from boundary_taxonomy' AS Test,
(SELECT COUNT(*) FROM boundary_taxonomy WHERE classification_id NOT IN (SELECT classification_id from classification where active = true)) AS Result,
0 As Expected
UNION ALL
SELECT 'Inactive classification_id from contact_taxonomy' AS Test,
(SELECT COUNT(*) FROM contact_taxonomy WHERE classification_id NOT IN (SELECT classification_id from classification where active = true)) AS Result,
0 As Expected
UNION ALL
SELECT 'Inactive classification_id from feature_taxonomy' AS Test,
(SELECT COUNT(*) FROM feature_taxonomy WHERE classification_id NOT IN (SELECT classification_id from classification where active = true)) AS Result,
0 As Expected
UNION ALL
SELECT 'Inactive classification_id from contact_taxonomy' AS Test,
(SELECT COUNT(*) FROM contact_taxonomy WHERE classification_id NOT IN (SELECT classification_id from classification where active = true)) AS Result,
0 As Expected
UNION ALL
SELECT 'Inactive classification_id from financial_taxonomy' AS Test,
(SELECT COUNT(*) FROM financial_taxonomy WHERE classification_id NOT IN (SELECT classification_id from classification where active = true)) AS Result,
0 As Expected
UNION ALL
SELECT 'Inactive classification_id from location_taxonomy' AS Test,
(SELECT COUNT(*) FROM location_taxonomy WHERE classification_id NOT IN (SELECT classification_id from classification where active = true)) AS Result,
0 As Expected
UNION ALL
SELECT 'Inactive classification_id from organization_taxonomy' AS Test,
(SELECT COUNT(*) FROM organization_taxonomy WHERE classification_id NOT IN (SELECT classification_id from classification where active = true)) AS Result,
0 As Expected
UNION ALL
SELECT 'Inactive classification_id from project_taxonomy' AS Test,
(SELECT COUNT(*) FROM project_taxonomy WHERE classification_id NOT IN (SELECT classification_id from classification where active = true)) AS Result,
0 As Expected
UNION ALL
SELECT 'Inactive classification_id from result_taxonomy' AS Test,
(SELECT COUNT(*) FROM result_taxonomy WHERE classification_id NOT IN (SELECT classification_id from classification where active = true)) AS Result,
0 As Expected;

-- update permissions
GRANT USAGE ON SCHEMA public TO pmt_read;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO pmt_read;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO pmt_read;
GRANT USAGE ON SCHEMA public TO pmt_write;
GRANT SELECT,INSERT ON ALL TABLES IN SCHEMA public TO pmt_write;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO pmt_write;