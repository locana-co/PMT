/******************************************************************
Change Script 2.0.8.70
1. taxonomy_xwalk - add new table for storing x-walks between
taxonomies
2. taxonomy_xwalks - new view of taxonomy_xwalk table
3. project_taxonomy_xwalks - custom view of existing xwalks by
project
4. activity_taxonomy_xwalks - custom view of existing xwalks by
activity
5. data_validation_report - update the report with a new test to 
make sure all projects have a data group.
******************************************************************/
INSERT INTO version(version, iteration, changeset) VALUES (2.0, 8, 70);
-- select * from version order by changeset desc;

DROP TABLE IF EXISTS  taxonomy_xwalk CASCADE;

--Taxonomy Xwalk
CREATE TABLE "taxonomy_xwalk"
(
	"taxonomy_xwalk_id"		SERIAL				NOT NULL
	,"origin_taxonomy_id"		integer 			NOT NULL
	,"linked_taxonomy_id"		integer 			NOT NULL
	,"origin_classification_id"	integer 			NOT NULL
	,"linked_classification_id"	integer 			NOT NULL
	,"direction"			character varying(5)		NOT NULL DEFAULT 'ONE'	
	,"active"		boolean				NOT NULL DEFAULT TRUE
	,"retired_by"		integer	
	,"created_by" 		character varying(50)
	,"created_date" 	timestamp without time zone 	NOT NULL DEFAULT current_date
	,"updated_by" 		character varying(50)
	,"updated_date" 	timestamp without time zone 	NOT NULL DEFAULT current_date
	,CONSTRAINT taxonomy_xwalk_id PRIMARY KEY(taxonomy_xwalk_id)
);

CREATE OR REPLACE VIEW  taxonomy_xwalks AS
(SELECT origin.origin_taxonomy_id, origin.origin_taxonomy, origin.origin_classification_id, origin.origin_classification 
,linked.linked_taxonomy_id, linked.linked_taxonomy, linked.linked_classification_id, linked.linked_classification, linked.direction
FROM
(SELECT tx.origin_taxonomy_id, tc.taxonomy as origin_taxonomy, tx.origin_classification_id, tc.classification as origin_classification
FROM taxonomy_xwalk tx
JOIN taxonomy_classifications tc
ON tx.origin_taxonomy_id = tc.taxonomy_id AND tx.origin_classification_id = tc.classification_id) origin
JOIN
(SELECT tx.origin_taxonomy_id, tx.origin_classification_id, tx.linked_taxonomy_id, tc.taxonomy as linked_taxonomy, tx.linked_classification_id, tc.classification as linked_classification, tx.direction
FROM taxonomy_xwalk tx
JOIN taxonomy_classifications tc
ON tx.linked_taxonomy_id = tc.taxonomy_id AND tx.linked_classification_id = tc.classification_id) linked
ON origin.origin_taxonomy_id = linked.origin_taxonomy_id AND origin.origin_classification_id = linked.origin_classification_id
ORDER BY 2,4,6,8);


-- view: project by taxonomy
CREATE OR REPLACE VIEW  project_taxonomy_xwalks AS
(select p.project_id, p.title, dg.classification as data_group, bmgf.classification as bmgf_initiative, agra.classification as agra_program, tanaim.classification as tanaim_category
from project p
left join
(select pt.project_id, pt.classification_id, tc.classification
from project_taxonomy pt
join taxonomy_classifications tc
on pt.classification_id = tc.classification_id
where pt.classification_id IN (SELECT classification_id FROM taxonomy_classifications WHERE taxonomy = 'Data Group')) dg
on p.project_id = dg.project_id
left join
(select pt.project_id, pt.classification_id, tc.classification
from project_taxonomy pt
join taxonomy_classifications tc
on pt.classification_id = tc.classification_id
where pt.classification_id IN (SELECT classification_id FROM taxonomy_classifications WHERE taxonomy = 'Initiative')) bmgf
on p.project_id = bmgf.project_id
left join
(select pt.project_id, pt.classification_id, tc.classification
from project_taxonomy pt
join taxonomy_classifications tc
on pt.classification_id = tc.classification_id
where pt.classification_id IN (SELECT classification_id FROM taxonomy_classifications WHERE taxonomy = 'Program')) agra
on p.project_id = agra.project_id
left join
(select pt.project_id, pt.classification_id, tc.classification
from project_taxonomy pt
join taxonomy_classifications tc
on pt.classification_id = tc.classification_id
where pt.classification_id IN (SELECT classification_id FROM taxonomy_classifications WHERE taxonomy = 'Category')) tanaim
on p.project_id = tanaim.project_id
where p.active = true
order by 3);

CREATE OR REPLACE VIEW  activity_taxonomy_xwalks AS
(select a.project_id, a.activity_id, a.title, dg.classification as dg, agra.classification as agra_sub_program, bmgf.classification as bmgf_sub_initiative
, tanaim1.classification as tanaim_category, tanaim2.classification as tanaim_sub_category
from activity a
left join
(select pt.project_id, pt.classification_id, tc.classification
from project_taxonomy pt
join taxonomy_classifications tc
on pt.classification_id = tc.classification_id
where pt.classification_id IN (SELECT classification_id FROM taxonomy_classifications WHERE taxonomy = 'Data Group')) dg
on a.project_id = dg.project_id
left join
(select at.activity_id, at.classification_id, tc.classification
from activity_taxonomy at
join taxonomy_classifications tc
on at.classification_id = tc.classification_id
where at.classification_id IN (SELECT classification_id FROM taxonomy_classifications WHERE taxonomy = 'Sub-Program')) agra
on a.activity_id = agra.activity_id
left join
(select at.activity_id, at.classification_id, tc.classification
from activity_taxonomy at
join taxonomy_classifications tc
on at.classification_id = tc.classification_id
where at.classification_id IN (SELECT classification_id FROM taxonomy_classifications WHERE taxonomy = 'Sub-Initiative')) bmgf
on a.activity_id = bmgf.activity_id
left join
(select at.activity_id, at.classification_id, tc.classification
from activity_taxonomy at
join taxonomy_classifications tc
on at.classification_id = tc.classification_id
where at.classification_id IN (SELECT classification_id FROM taxonomy_classifications WHERE taxonomy = 'Category')) tanaim1
on a.activity_id = tanaim1.activity_id
left join
(select at.activity_id, at.classification_id, tc.classification
from activity_taxonomy at
join taxonomy_classifications tc
on at.classification_id = tc.classification_id
where at.classification_id IN (SELECT classification_id FROM taxonomy_classifications WHERE taxonomy = 'Sub-Category')) tanaim2
on a.activity_id = tanaim2.activity_id
where a.active = true
order by 4);

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
SELECT 'Inactive classification_id on activity' AS Test,
(SELECT COUNT(*) FROM activity_taxonomy WHERE classification_id NOT IN (SELECT classification_id from classification where active = true)) AS Result,
0 As Expected
UNION ALL
SELECT 'Inactive classification_id on boundary' AS Test,
(SELECT COUNT(*) FROM boundary_taxonomy WHERE classification_id NOT IN (SELECT classification_id from classification where active = true)) AS Result,
0 As Expected
UNION ALL
SELECT 'Inactive classification_id on contact' AS Test,
(SELECT COUNT(*) FROM contact_taxonomy WHERE classification_id NOT IN (SELECT classification_id from classification where active = true)) AS Result,
0 As Expected
UNION ALL
SELECT 'Inactive classification_id on feature' AS Test,
(SELECT COUNT(*) FROM feature_taxonomy WHERE classification_id NOT IN (SELECT classification_id from classification where active = true)) AS Result,
0 As Expected
UNION ALL
SELECT 'Inactive classification_id on financial' AS Test,
(SELECT COUNT(*) FROM financial_taxonomy WHERE classification_id NOT IN (SELECT classification_id from classification where active = true)) AS Result,
0 As Expected
UNION ALL
SELECT 'Inactive classification_id on location' AS Test,
(SELECT COUNT(*) FROM location_taxonomy WHERE classification_id NOT IN (SELECT classification_id from classification where active = true)) AS Result,
0 As Expected
UNION ALL
SELECT 'Inactive classification_id on organization' AS Test,
(SELECT COUNT(*) FROM organization_taxonomy WHERE classification_id NOT IN (SELECT classification_id from classification where active = true)) AS Result,
0 As Expected
UNION ALL
SELECT 'Inactive classification_id on project' AS Test,
(SELECT COUNT(*) FROM project_taxonomy WHERE classification_id NOT IN (SELECT classification_id from classification where active = true)) AS Result,
0 As Expected
UNION ALL
SELECT 'Inactive classification_id on result' AS Test,
(SELECT COUNT(*) FROM result_taxonomy WHERE classification_id NOT IN (SELECT classification_id from classification where active = true)) AS Result,
0 As Expected
UNION ALL
SELECT 'Project without a Data Group' AS Test,
(SELECT COUNT (p.*) FROM project p LEFT JOIN project_taxonomy pt ON p.project_id = pt.project_id WHERE p.active = true AND pt.classification_id IS NULL
AND pt.classification_id IN (SELECT classification_id FROM taxonomy_classifications WHERE taxonomy = 'Data Group')) AS Result,
0 As Expected
UNION ALL
SELECT 'Project more than one Data Group' AS Test,
(SELECT COUNT(*) FROM (SELECT p.project_id, COUNT(*) as ct FROM project p LEFT JOIN project_taxonomy pt ON p.project_id = pt.project_id WHERE p.active = true AND pt.classification_id IN (SELECT classification_id FROM taxonomy_classifications WHERE taxonomy = 'Data Group') GROUP BY p.project_id) as dg WHERE dg.ct > 1) AS Result,
0 As Expected;

-- update permissions
GRANT USAGE ON SCHEMA public TO pmt_read;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO pmt_read;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO pmt_read;
GRANT USAGE ON SCHEMA public TO pmt_write;
GRANT SELECT,INSERT ON ALL TABLES IN SCHEMA public TO pmt_write;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO pmt_write;