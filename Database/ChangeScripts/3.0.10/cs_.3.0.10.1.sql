/******************************************************************
Change Script 3.0.10.1

1. drop project tables and all views
2. update all views & remove project based views
3. update selected functions
4. create new function to support consistantcy checks
5. add constraints
6. update selected triggers
7. create new trigger on the version table to ease development
8. create missing taxonomy table detail_taxonomy
9. create updated_date trigger on all tables to manage update datestamps
******************************************************************/
INSERT INTO version(_version, _iteration, _changeset) VALUES (3.0, 10, 1);
-- select * from version order by iteration desc, changeset desc;

/*************************************************************************
  1. drop project tables and all views
*************************************************************************/
-- drop project tables and project fields
DROP TABLE IF EXISTS project CASCADE;
DROP TABLE IF EXISTS project_contact CASCADE;
DROP TABLE IF EXISTS project_taxonomy CASCADE;
ALTER TABLE activity DROP COLUMN IF EXISTS project_id;
ALTER TABLE location DROP COLUMN IF EXISTS project_id;
ALTER TABLE detail DROP COLUMN IF EXISTS project_id;
ALTER TABLE financial DROP COLUMN IF EXISTS project_id;
ALTER TABLE participation DROP COLUMN IF EXISTS project_id;
ALTER TABLE iati_import DROP COLUMN IF EXISTS project_id;

-- drop all views
DROP VIEW IF EXISTS accountable_organizations CASCADE;
DROP VIEW IF EXISTS project_taxonomies CASCADE;
DROP VIEW IF EXISTS taxonomy_classifications CASCADE;
DROP VIEW IF EXISTS accountable_project_participants CASCADE;
DROP VIEW IF EXISTS active_project_activities CASCADE;
DROP VIEW IF EXISTS activity_contacts CASCADE;
DROP VIEW IF EXISTS activity_participants CASCADE;
DROP VIEW IF EXISTS activity_taxonomies CASCADE;
DROP VIEW IF EXISTS activity_taxonomy_xwalks CASCADE;
DROP VIEW IF EXISTS data_change_report CASCADE;
DROP VIEW IF EXISTS data_loading_report CASCADE;
DROP VIEW IF EXISTS data_validation_report CASCADE;
DROP VIEW IF EXISTS entity_taxonomy CASCADE;
DROP VIEW IF EXISTS gaul_lookup CASCADE;
DROP VIEW IF EXISTS location_boundary_features CASCADE;
DROP VIEW IF EXISTS project_taxonomy_xwalks CASCADE;
DROP VIEW IF EXISTS organization_participation CASCADE;
DROP VIEW IF EXISTS project_activity_points CASCADE;
DROP VIEW IF EXISTS project_contacts CASCADE;
DROP VIEW IF EXISTS tags CASCADE;
DROP VIEW IF EXISTS tanaim_aaz CASCADE;
DROP VIEW IF EXISTS tanaim_nbs CASCADE;
DROP VIEW IF EXISTS taxonomy_xwalks CASCADE;
DROP MATERIALIZED VIEW IF EXISTS taxonomy_lookup CASCADE;
DROP MATERIALIZED VIEW IF EXISTS location_lookup CASCADE;
DROP MATERIALIZED VIEW IF EXISTS organization_lookup CASCADE;

/*************************************************************************
  2. update all views & remove project based views
*************************************************************************/
-- accountable_organizations
CREATE OR REPLACE VIEW _accountable_organizations
AS SELECT DISTINCT o.id, o._name, count(DISTINCT p.activity_id) as num_activities
FROM participation p
JOIN participation_taxonomy pt
ON p.id = pt.participation_id
JOIN organization o
ON p.organization_id = o.id
WHERE pt.classification_id = 
(SELECT id FROM classification WHERE _name = 'Accountable' AND taxonomy_id = (SELECT id FROM taxonomy WHERE _name = 'Organisation Role'))
and o._active = true and p._active = true
GROUP BY o.id, o._name
ORDER BY o._name;

-- active_project_activities
CREATE OR REPLACE VIEW _active_activities
AS SELECT DISTINCT a.id as activity_id, a.data_group_id, l.id as location_id, pp.organization_id as organization_id, pp.id as participation_id, a._start_date, a._end_date, l._x,l._y, l._georef
FROM activity a
JOIN location l
ON a.id = l.activity_id
JOIN participation pp
ON a.id = pp.activity_id
WHERE a._active = true AND l._active = true AND pp._active = true
ORDER BY a.id, l.id, pp.organization_id;

-- taxonomy_classifications
CREATE OR REPLACE VIEW  _taxonomy_classifications AS
(SELECT t.id as taxonomy_id, t._name as taxonomy, t._is_category, t.parent_id as taxonomy_parent_id, t._iati_codelist, t._description, 
c.id as classification_id, c._name as classification, c._code, c.parent_id as classification_parent_id, c._iati_code, c._iati_name
FROM taxonomy t
JOIN classification c
ON t.id = c.taxonomy_id
WHERE t._active = true and c._active = true
ORDER BY t.id, c.id);

-- activity_contacts
CREATE OR REPLACE VIEW _activity_contacts AS 
SELECT a.id as activity_id, a.data_group_id,
a._title,
c._salutation,
c._first_name,
c._last_name
FROM activity a
LEFT JOIN activity_contact ac 
ON a.id = ac.activity_id
JOIN contact c 
ON ac.contact_id = c.id
ORDER BY a.id;

-- activity_participants (rename: _partnerlink_participants)
CREATE OR REPLACE VIEW _partnerlink_participants AS 
SELECT DISTINCT * FROM (	
SELECT a.id as activity_id, a._title as title
,CASE WHEN fund.organization_id IS NULL THEN 1 ELSE fund.organization_id END as fund_id
,CASE WHEN fund._name IS NULL OR fund._name = '' THEN 'Funder Not Reported' ELSE fund._name END as fund_name
,CASE WHEN acct.organization_id IS NULL THEN 2 ELSE acct.organization_id END as acct_id
,CASE WHEN acct._name IS NULL OR acct._name = '' THEN 'Grantee Not Reported' ELSE acct._name END as acct_name
,CASE WHEN impl.organization_id IS NULL THEN 3 ELSE impl.organization_id END as impl_id
,CASE WHEN impl._name IS NULL OR impl._name = '' THEN 'Partner Not Reported' ELSE impl._name END as impl_name
,(SELECT count(id) FROM location WHERE activity_id = a.id) as loc_ct
FROM activity a
LEFT JOIN
-- Accountable (Grantee)
(SELECT pp.activity_id, pp.organization_id, o._name, tc.classification
FROM participation pp
LEFT JOIN participation_taxonomy ppt
ON pp.id = ppt.participation_id
JOIN _taxonomy_classifications tc
ON ppt.classification_id = tc.classification_id
JOIN organization o
ON pp.organization_id = o.id
WHERE pp._active = true AND tc.classification = 'Accountable') as acct
ON a.id = acct.activity_id
LEFT JOIN
-- Funding (Funder)
(SELECT pp.activity_id, pp.organization_id, o._name, tc.classification
FROM participation pp
LEFT JOIN participation_taxonomy ppt
ON pp.id = ppt.participation_id
JOIN _taxonomy_classifications tc
ON ppt.classification_id = tc.classification_id
JOIN organization o
ON pp.organization_id = o.id
WHERE pp._active = true AND tc.classification = 'Funding') as fund
ON a.id = fund.activity_id
LEFT JOIN
-- Implementing (Partner)
(SELECT pp.activity_id, pp.organization_id, o._name, tc.classification
FROM participation pp
LEFT JOIN participation_taxonomy ppt
ON pp.id = ppt.participation_id
JOIN _taxonomy_classifications tc
ON ppt.classification_id = tc.classification_id
JOIN organization o
ON pp.organization_id = o.id
WHERE pp._active = true AND tc.classification = 'Implementing') as impl
ON a.id = impl.activity_id
WHERE a._active = true
ORDER BY a.id
) as selection;

-- activity_participants (new view)
CREATE OR REPLACE VIEW _activity_participants AS
SELECT a.id, a._title, a.data_group_id, dg.classification as data_group, o._name, tc.classification
FROM activity a
LEFT JOIN participation pp
ON a.id = pp.activity_id
LEFT JOIN participation_taxonomy ppt
ON pp.id = ppt.participation_id
LEFT JOIN _taxonomy_classifications tc
ON ppt.classification_id = tc.classification_id
LEFT JOIN organization o
ON pp.organization_id = o.id
LEFT JOIN _taxonomy_classifications dg
ON a.data_group_id = dg.classification_id
WHERE a._active = true AND pp._active = true
ORDER BY a.id;

-- activity_taxonomies
CREATE OR REPLACE VIEW _activity_taxonomies AS 
SELECT a.id, a._title, a.data_group_id, dg.classification as data_group, tc.taxonomy, tc.classification
FROM activity a
JOIN activity_taxonomy at 
ON a.id = at.activity_id
JOIN _taxonomy_classifications tc
ON at.classification_id = tc.classification_id
LEFT JOIN _taxonomy_classifications dg
ON a.data_group_id = dg.classification_id
WHERE a._active = true
ORDER BY a.id;

-- activity_taxonomy_xwalks
CREATE OR REPLACE VIEW  _activity_taxonomy_xwalks AS
SELECT a.id, a._title, a.data_group_id, dg.classification as data_group, tco.taxonomy as origin_taxonomy, tco.classification as origin_classification, tcl.taxonomy as linked_taxonomy, tcl.classification as linked_classification
FROM activity a
LEFT JOIN _taxonomy_classifications dg
ON a.data_group_id = dg.classification_id
JOIN activity_taxonomy at 
ON a.id = at.activity_id
JOIN _taxonomy_classifications tco
ON at.classification_id = tco.classification_id
JOIN taxonomy_xwalk tx
ON at.classification_id = tx.origin_classification_id
JOIN _taxonomy_classifications tcl
ON tx.linked_classification_id = tcl.classification_id
ORDER BY a.id;

-- data_change_report
CREATE OR REPLACE VIEW _data_change_report
AS SELECT ds.script, array_to_string(array_agg(distinct ds.action), ',') as action, array_to_string(array_agg(distinct ds.entity), ',') as entity, MAX(ds.date) as date
FROM (
-- activity
SELECT distinct _created_by as script, 'create' as action, 'activity' as entity, _created_date::timestamp::date as date
FROM activity
WHERE _created_by  NOT IN ('PMT 1.0 Record')
UNION ALL 
SELECT distinct _updated_by as script, 'update' as action, 'activity' as entity, _updated_date::timestamp::date as date
FROM activity
WHERE _updated_by  NOT IN ('PMT 1.0 Record')
UNION ALL
-- location
SELECT distinct _created_by as script, 'create' as action, 'location' as entity, _created_date::timestamp::date as date
FROM location
WHERE _created_by  NOT IN ('PMT 1.0 Record')
UNION ALL 
SELECT distinct _updated_by as script, 'update' as action, 'location' as entity, _updated_date::timestamp::date as date
FROM location
WHERE _updated_by  NOT IN ('PMT 1.0 Record')
UNION ALL
-- participation
SELECT distinct _created_by as script, 'create' as action, 'participation' as entity, _created_date::timestamp::date as date
FROM participation
WHERE _created_by  NOT IN ('PMT 1.0 Record')
UNION ALL 
SELECT distinct _updated_by as script, 'update' as action, 'participation' as entity, _updated_date::timestamp::date as date
FROM participation
WHERE _updated_by  NOT IN ('PMT 1.0 Record')
UNION ALL
-- boundary
SELECT distinct _created_by as script, 'create' as action, 'boundary' as entity, _created_date::timestamp::date as date
FROM boundary
WHERE _created_by  NOT IN ('PMT 1.0 Record')
UNION ALL 
SELECT distinct _updated_by as script, 'update' as action, 'boundary' as entity, _updated_date::timestamp::date as date
FROM boundary
WHERE _updated_by  NOT IN ('PMT 1.0 Record')
UNION ALL
-- contact
SELECT distinct _created_by as script, 'create' as action, 'contact' as entity, _created_date::timestamp::date as date
FROM contact
WHERE _created_by  NOT IN ('PMT 1.0 Record')
UNION ALL 
SELECT distinct _updated_by as script, 'update' as action, 'contact' as entity, _updated_date::timestamp::date as date
FROM contact
WHERE _updated_by  NOT IN ('PMT 1.0 Record')
UNION ALL
-- detail
SELECT distinct _created_by as script, 'create' as action, 'detail' as entity, _created_date::timestamp::date as date
FROM detail
WHERE _created_by  NOT IN ('PMT 1.0 Record')
UNION ALL 
SELECT distinct _updated_by as script, 'update' as action, 'detail' as entity, _updated_date::timestamp::date as date
FROM detail
WHERE _updated_by  NOT IN ('PMT 1.0 Record')
UNION ALL
-- financial
SELECT distinct _created_by as script, 'create' as action, 'financial' as entity, _created_date::timestamp::date as date
FROM financial
WHERE _created_by  NOT IN ('PMT 1.0 Record')
UNION ALL 
SELECT distinct _updated_by as script, 'update' as action, 'financial' as entity, _updated_date::timestamp::date as date
FROM financial
WHERE _updated_by  NOT IN ('PMT 1.0 Record')
UNION ALL
-- organization
SELECT distinct _created_by as script, 'create' as action, 'organization' as entity, _created_date::timestamp::date as date
FROM organization
WHERE _created_by  NOT IN ('PMT 1.0 Record')
UNION ALL 
SELECT distinct _updated_by as script, 'update' as action, 'organization' as entity, _updated_date::timestamp::date as date
FROM organization
WHERE _updated_by  NOT IN ('PMT 1.0 Record')
UNION ALL
-- result
SELECT distinct _created_by as script, 'create' as action, 'result' as entity, _created_date::timestamp::date as date
FROM result
WHERE _created_by  NOT IN ('PMT 1.0 Record')
UNION ALL 
SELECT distinct _updated_by as script, 'update' as action, 'result' as entity, _updated_date::timestamp::date as date
FROM result
WHERE _updated_by  NOT IN ('PMT 1.0 Record')
UNION ALL
-- classification
SELECT distinct _created_by as script, 'create' as action, 'classification' as entity, _created_date::timestamp::date as date
FROM classification
WHERE _created_by  NOT IN ('PMT 1.0 Record')
UNION ALL 
SELECT distinct _updated_by as script, 'update' as action, 'classification' as entity, _updated_date::timestamp::date as date
FROM classification
WHERE _updated_by  NOT IN ('PMT 1.0 Record')
UNION ALL
-- taxonomy
SELECT distinct _created_by as script, 'create' as action, 'taxonomy' as entity, _created_date::timestamp::date as date
FROM taxonomy
WHERE _created_by  NOT IN ('PMT 1.0 Record')
UNION ALL 
SELECT distinct _updated_by as script, 'update' as action, 'taxonomy' as entity, _updated_date::timestamp::date as date
FROM taxonomy
WHERE _updated_by  NOT IN ('PMT 1.0 Record')
UNION ALL
-- role
SELECT distinct _created_by as script, 'create' as action, 'role' as entity, _created_date::timestamp::date as date
FROM role
WHERE _created_by  NOT IN ('PMT 1.0 Record')
UNION ALL 
SELECT distinct _updated_by as script, 'update' as action, 'role' as entity, _updated_date::timestamp::date as date
FROM role
WHERE _updated_by  NOT IN ('PMT 1.0 Record')
UNION ALL
-- user
SELECT distinct _created_by as script, 'create' as action, 'user' as entity, _created_date::timestamp::date as date
FROM "users"
WHERE _created_by  NOT IN ('PMT 1.0 Record')
UNION ALL 
SELECT distinct _updated_by as script, 'update' as action, 'user' as entity, _updated_date::timestamp::date as date
FROM "users"
WHERE _updated_by  NOT IN ('PMT 1.0 Record')
UNION ALL
-- taxonomy_xwalk
SELECT distinct _created_by as script, 'create' as action, 'taxonomy_xwalk' as entity, _created_date::timestamp::date as date
FROM taxonomy_xwalk
WHERE _created_by  NOT IN ('PMT 1.0 Record')
UNION ALL 
SELECT distinct _updated_by as script, 'update' as action, 'taxonomy_xwalk' as entity, _updated_date::timestamp::date as date
FROM taxonomy_xwalk
WHERE _updated_by  NOT IN ('PMT 1.0 Record')
) ds
GROUP BY 1
ORDER BY 4 DESC, 1 DESC;

-- data_loading_report
CREATE OR REPLACE VIEW _data_loading_report
AS SELECT 'activity' as "table", COUNT(*) AS "total record count", (SELECT COUNT(*) FROM activity WHERE _active = true) AS "active record count", 0 AS "core PMT count", '' as "comments" FROM activity
UNION ALL
SELECT 'activity_contact' as "table", COUNT(*) AS "total record count", (SELECT COUNT(*) FROM activity_contact) AS "active record count", 0 AS "core PMT count", '' as "comments" FROM activity_contact
UNION ALL
SELECT 'activity_taxonomy' as "table", COUNT(*) AS "total record count", (SELECT COUNT(*) FROM activity_taxonomy) AS "active record count", 0 AS "core PMT count", '' as "comments" FROM activity_taxonomy
UNION ALL
SELECT 'boundary' as "table", COUNT(*) AS "total record count", (SELECT COUNT(*) FROM boundary WHERE _active = true) AS "active record count", 3 AS "core PMT count", 'Correct count reflects minimum count on default PMT install.' as "comments" FROM boundary			
UNION ALL
SELECT 'boundary_taxonomy' as "table", COUNT(*) AS "total record count", (SELECT COUNT(*) FROM boundary_taxonomy) AS "active record count", 0 AS "core PMT count", '' as "comments" FROM boundary_taxonomy			
UNION ALL
SELECT 'config' as "table", COUNT(*) AS "total record count", (SELECT COUNT(*) FROM config) AS "active record count", 1 AS "core PMT count", 'PMT system table.' as "comments" FROM config			
UNION ALL
SELECT 'contact' as "table", COUNT(*) AS "total record count", (SELECT COUNT(*) FROM contact WHERE _active = true) AS "active record count", 0 AS "core PMT count", '' as "comments" FROM contact			
UNION ALL
SELECT 'contact_taxonomy' as "table", COUNT(*) AS "total record count", (SELECT COUNT(*) FROM contact_taxonomy) AS "active record count", 0 AS "core PMT count", '' as "comments" FROM contact_taxonomy
UNION ALL
SELECT 'detail' as "table", COUNT(*) AS "total record count", (SELECT COUNT(*) FROM detail WHERE _active = true) AS "active record count", 0 AS "core PMT count", '' as "comments" FROM detail
UNION ALL
SELECT 'feature_taxonomy' as "table", COUNT(*) AS "total record count", (SELECT COUNT(*) FROM feature_taxonomy) AS "active record count", 277 AS "core PMT count", 'Correct count reflects minimum count on default PMT install.' as "comments" FROM feature_taxonomy
UNION ALL
SELECT 'financial' as "table", COUNT(*) AS "total record count", (SELECT COUNT(*) FROM financial WHERE _active = true) AS "active record count", 0 AS "core PMT count", '' as "comments" FROM financial
UNION ALL
SELECT 'financial_taxonomy' as "table", COUNT(*) AS "total record count", (SELECT COUNT(*) FROM financial_taxonomy) AS "active record count", 0 AS "core PMT count", '' as "comments" FROM financial_taxonomy
UNION ALL
SELECT 'gaul0' as "table", COUNT(*) AS "total record count", (SELECT COUNT(*) FROM gaul0 WHERE _active = true) AS "active record count", 277 AS "core PMT count", 'Core count reflects minimum count on default PMT install.' as "comments" FROM gaul0
UNION ALL
SELECT 'gaul1' as "table", COUNT (*) AS "total record count", (SELECT COUNT(*) FROM gaul1 WHERE _active = true) AS "active record count", 3469 AS "core PMT count", 'Core count reflects minimum count on default PMT install.' as "comments" FROM gaul1
UNION ALL
SELECT 'gaul2' as "table", COUNT(*) AS "total record count", (SELECT COUNT(*) FROM gaul2 WHERE _active = true) AS "active record count", 37378 AS "core PMT count", 'Core count reflects minimum count on default PMT install.' as "comments" FROM gaul2
UNION ALL
SELECT 'location' as "table", COUNT(*) AS "total record count", (SELECT COUNT(*) FROM location WHERE _active = true) AS "active record count", 0 AS "core PMT count", '' as "comments" FROM location 
UNION ALL
SELECT 'location_boundary' as "table", COUNT(*) AS "total record count", (SELECT COUNT(*) FROM location_boundary) AS "active record count", 0 AS "core PMT count", '' as "comments" FROM location_boundary
UNION ALL
SELECT 'location_taxonomy' as "table", COUNT(*) AS "total record count", (SELECT COUNT(*) FROM location_taxonomy) AS "active record count", 0 AS "core PMT count", '' as "comments" FROM location_taxonomy
UNION ALL
SELECT 'map' as "table", COUNT(*) AS "total record count", (SELECT COUNT(*) FROM map WHERE _active = true) AS "active record count", 0 AS "core PMT count", '' as "comments" FROM map
UNION ALL
SELECT 'organization' as "table", COUNT(*) AS "total record count", (SELECT COUNT(*) FROM organization WHERE _active = true) AS "active record count", 0 AS "core PMT count", '' as "comments" FROM organization
UNION ALL
SELECT 'organization_taxonomy' as "table", COUNT(*) AS "total record count", (SELECT COUNT(*) FROM organization_taxonomy) AS "active record count", 0 AS "core PMT count", '' as "comments" FROM organization_taxonomy	
UNION ALL
SELECT 'participation' as "table", COUNT(*) AS "total record count", (SELECT COUNT(*) FROM participation WHERE _active = true) AS "active record count", 0 AS "core PMT count", '' as "comments" FROM participation
UNION ALL
SELECT 'participation_taxonomy' as "table", COUNT(*) AS "total record count", (SELECT COUNT(*) FROM participation_taxonomy) AS "active record count", 0 AS "core PMT count", '' as "comments" FROM participation_taxonomy
UNION ALL
SELECT 'result' as "table", COUNT(*) AS "total record count", (SELECT COUNT(*) FROM result WHERE _active = true) AS "active record count", 0 AS "core PMT count", '' as "comments" FROM result
UNION ALL
SELECT 'result_taxonomy' as "table", COUNT(*) AS "total record count", (SELECT COUNT(*) FROM result_taxonomy) AS "active record count", 0 AS "core PMT count", '' as "comments" FROM result_taxonomy
UNION ALL
SELECT 'role' as "table", COUNT(*) AS "total record count", (SELECT COUNT(*) FROM role WHERE _active = true) AS "active record count", 4 AS "core PMT count", 'Core count reflects minimum count on default PMT install.' as "comments" FROM role
UNION ALL
SELECT 'taxonomy_xwalk' as "table", COUNT(*) AS "total record count", (SELECT COUNT(*) FROM taxonomy_xwalk WHERE _active = true) AS "active record count", 0 AS "core PMT count", 'Core count reflects minimum count on default PMT install.' as "comments" FROM taxonomy_xwalk
UNION ALL
SELECT 'user_activity_role' as "table", COUNT(*) AS "total record count", (SELECT COUNT(*) FROM user_activity_role WHERE _active = true) AS "active record count", 0 AS "core PMT count", '' as "comments" FROM user_activity_role
UNION ALL
SELECT 'user_log' as "table", COUNT(*) AS "total record count", (SELECT COUNT(*) FROM user_log) AS "active record count", 0 AS "core PMT count", '' as "comments" FROM user_log
UNION ALL
SELECT 'users' as "table", COUNT(*) AS "total record count", (SELECT COUNT(*) FROM users WHERE _active = true) AS "active record count", 0 AS "core PMT count", '' as "comments" FROM users
UNION ALL
SELECT 'version' as "table", COUNT(*) AS "total record count", (SELECT COUNT(*) FROM version) AS "active record count", 0 AS "core PMT count", 'PMT system table.' as "comments" FROM version
UNION ALL
SELECT 'classification' as "table", COUNT(*) AS "total record count", (SELECT COUNT(*) FROM classification WHERE _active = true) AS "active record count", 1657 AS "core PMT count", 'Core count reflects minimum count on default PMT install.' as "comments" FROM classification
UNION ALL
SELECT 'taxonomy' as "table", COUNT(*) AS "total record count", (SELECT COUNT(*) FROM taxonomy WHERE _active = true) AS "active record count", 22 AS "core PMT count", 'Core count reflects minimum count on default PMT install.' as "comments" FROM taxonomy;

-- data_validation_report
CREATE OR REPLACE VIEW _data_validation_report AS
SELECT 'Orphaned locations' AS Test,
(SELECT COUNT(*) FROM location WHERE activity_id NOT IN (SELECT id FROM activity)) AS Result,
0 AS Expected
UNION ALL
SELECT 'Orphaned financial' AS Test,
(SELECT COUNT(*) FROM financial WHERE activity_id NOT IN (SELECT id FROM activity)) AS Result,
0 AS Expected
UNION ALL
SELECT 'Orphaned participation' AS Test,
(SELECT COUNT(*) FROM participation WHERE activity_id NOT IN (SELECT id FROM activity) 
OR organization_id NOT IN (SELECT id FROM organization)) AS Result,
0 AS Expected
UNION ALL
SELECT 'Orphaned activity contact' AS Test,
(SELECT COUNT(*) FROM activity_contact WHERE activity_id NOT IN (SELECT id FROM activity)) AS Result,
0 AS Expected
UNION ALL
SELECT 'Orphaned contact' AS Test,
(SELECT COUNT(*) FROM contact WHERE organization_id NOT IN (SELECT id FROM organization)) AS Result,
0 AS Expected
UNION ALL
SELECT 'Orphaned detail' AS Test,
(SELECT COUNT(*) FROM detail WHERE activity_id NOT IN (SELECT id FROM activity)) AS Result,
0 AS Expected
UNION ALL
SELECT 'Orphaned result' AS Test,
(SELECT COUNT(*) FROM result WHERE activity_id NOT IN (SELECT id FROM activity) ) AS Result,
0 AS Expected
UNION ALL
SELECT 'Orphaned activity taxonomy' AS Test,
(SELECT COUNT(*) FROM activity_taxonomy WHERE activity_id NOT IN (SELECT id FROM activity)) AS Result,
0 AS Expected
UNION ALL
SELECT 'Orphaned contact taxonomy' AS Test,
(SELECT COUNT(*) FROM contact_taxonomy WHERE contact_id NOT IN (SELECT id FROM contact)) AS Result,
0 AS Expected
UNION ALL
SELECT 'Orphaned financial taxonomy' AS Test,
(SELECT COUNT(*) FROM financial_taxonomy WHERE financial_id NOT IN (SELECT id FROM financial)) AS Result,
0 AS Expected
UNION ALL
SELECT 'Orphaned location taxonomy' AS Test,
(SELECT COUNT(*) FROM location_taxonomy WHERE location_id NOT IN (SELECT id FROM location)) AS Result,
0 AS Expected
UNION ALL
SELECT 'Orphaned organization taxonomy' AS Test,
(SELECT COUNT(*) FROM organization_taxonomy WHERE organization_id NOT IN (SELECT id FROM organization)) AS Result,
0 AS Expected
UNION ALL
SELECT 'Orphaned participation taxonomy' AS Test,
(SELECT COUNT(*) FROM participation_taxonomy WHERE participation_id NOT IN (SELECT id FROM participation)) AS Result,
0 AS Expected
UNION ALL
SELECT 'Orphaned result taxonomy' AS Test,
(SELECT COUNT(*) FROM result_taxonomy WHERE result_id NOT IN (SELECT id FROM result)) AS Result,
0 AS Expected
UNION ALL
SELECT 'Orphaned location boundary' AS Test,
(SELECT COUNT(*) FROM location_boundary WHERE location_id NOT IN (SELECT id FROM location)) AS Result,
0 AS Expected
UNION ALL
SELECT 'Activity without location' AS Test,
(SELECT COUNT(*) FROM activity WHERE id NOT IN (SELECT activity_id FROM location) AND _active = true) AS Result,
0 AS Expected
UNION ALL
SELECT 'Activity without participation' AS Test,
(SELECT COUNT(*) FROM activity WHERE id NOT IN (SELECT activity_id FROM participation) AND _active = true) AS Result,
0 AS Expected
UNION ALL
SELECT 'Active detail with inactive activity' AS Test,
(SELECT COUNT(*) FROM detail WHERE _active = true AND activity_id IN (SELECT id FROM activity WHERE _active = false)) AS Result,
0 AS Expected
UNION ALL
SELECT 'Active financial with inactive activity' AS Test,
(SELECT COUNT(*) FROM financial WHERE _active = true AND activity_id IN (SELECT id FROM activity WHERE _active = false)) AS Result,
0 AS Expected
UNION ALL
SELECT 'Active location with inactive activity' AS Test,
(SELECT COUNT(*) FROM location WHERE _active = true AND activity_id IN (SELECT id FROM activity WHERE _active = false)) AS Result,
0 AS Expected
UNION ALL
SELECT 'Active participation with inactive activity' AS Test,
(SELECT COUNT(*) FROM participation WHERE _active = true AND activity_id IN (SELECT id FROM activity WHERE _active = false)) AS Result,
0 AS Expected
UNION ALL
SELECT 'Active participation with inactive organization' AS Test,
(SELECT COUNT(*) FROM participation WHERE _active = true AND organization_id IN (SELECT id FROM organization WHERE _active = false)) AS Result,
0 AS Expected
UNION ALL
SELECT 'Active result with inactive activity' AS Test,
(SELECT COUNT(*) FROM result WHERE _active = true AND activity_id IN (SELECT id FROM activity WHERE _active = false)) AS Result,
0 AS Expected
UNION ALL
SELECT 'Duplicate organization' AS Test,
(SELECT COUNT(ct) FROM (SELECT _name, count(*) AS ct FROM organization WHERE _active = true GROUP BY 1) as foo WHERE ct > 1) AS Result,
0 AS Expected
UNION ALL
SELECT 'Inactive classification in use by active activity' AS Test,
(SELECT COUNT(*) FROM activity_taxonomy WHERE classification_id NOT IN (SELECT id from classification where _active = true) 
 AND activity_id IN (SELECT id FROM activity WHERE _active = true)) AS Result,
0 As Expected
UNION ALL
SELECT 'Inactive classification_id on boundary' AS Test,
(SELECT COUNT(*) FROM boundary_taxonomy WHERE classification_id NOT IN (SELECT id from classification where _active = true) 
 AND boundary_id IN (SELECT id FROM boundary WHERE _active = true)) AS Result,
0 As Expected
UNION ALL
SELECT 'Inactive classification_id on contact' AS Test,
(SELECT COUNT(*) FROM contact_taxonomy WHERE classification_id NOT IN (SELECT id from classification where _active = true) 
AND contact_id IN (SELECT id FROM contact WHERE _active = true)) AS Result,
0 As Expected
UNION ALL
SELECT 'Inactive classification_id on feature' AS Test,
(SELECT COUNT(*) FROM feature_taxonomy WHERE classification_id NOT IN (SELECT id from classification where _active = true)) AS Result,
0 As Expected
UNION ALL
SELECT 'Inactive classification_id on financial' AS Test,
(SELECT COUNT(*) FROM financial_taxonomy WHERE classification_id NOT IN (SELECT id from classification where _active = true) 
AND financial_id IN (SELECT id FROM financial WHERE _active = true)) AS Result,
0 As Expected
UNION ALL
SELECT 'Inactive classification_id on location' AS Test,
(SELECT COUNT(*) FROM location_taxonomy WHERE classification_id NOT IN (SELECT id from classification where _active = true) 
AND location_id IN (SELECT id FROM location WHERE _active = true)) AS Result,
0 As Expected
UNION ALL
SELECT 'Inactive classification_id on organization' AS Test,
(SELECT COUNT(*) FROM organization_taxonomy WHERE classification_id NOT IN (SELECT id from classification where _active = true) 
AND organization_id IN (SELECT id FROM organization WHERE _active = true)) AS Result,
0 As Expected
UNION ALL
SELECT 'Inactive classification_id on result' AS Test,
(SELECT COUNT(*) FROM result_taxonomy WHERE classification_id NOT IN (SELECT id from classification where _active = true) 
AND result_id IN (SELECT result_id FROM result WHERE _active = true)) AS Result,
0 As Expected;

-- entity_taxonomy
CREATE OR REPLACE VIEW _entity_taxonomy AS 
SELECT participation_taxonomy.participation_id AS id,
    participation_taxonomy.classification_id,
    participation_taxonomy._field AS field
   FROM participation_taxonomy
UNION ALL
 SELECT activity_taxonomy.activity_id AS id,
    activity_taxonomy.classification_id,
    activity_taxonomy._field AS field
   FROM activity_taxonomy
UNION ALL
 SELECT location_taxonomy.location_id AS id,
    location_taxonomy.classification_id,
    location_taxonomy._field AS field
   FROM location_taxonomy
UNION ALL
 SELECT organization_taxonomy.organization_id AS id,
    organization_taxonomy.classification_id,
    organization_taxonomy._field AS field
   FROM organization_taxonomy;

-- entity_taxonomy
CREATE OR REPLACE VIEW _gaul_lookup AS 
 SELECT gaul2._code AS code,
    gaul2._name AS name,
    'District'::text AS type,
    gaul2._gaul0_name AS gaul0_name,
    gaul2._gaul1_name AS gaul1_name,
    gaul2._name AS gaul2_name,
    st_asgeojson(box2d(gaul2._polygon)::geometry) AS bounds
   FROM gaul2
UNION
 SELECT DISTINCT gaul1._code AS code,
    gaul1._name AS name,
    'Region'::text AS type,
    gaul2._gaul0_name AS gaul0_name,
    gaul1._name AS gaul1_name,
    NULL::text AS gaul2_name,
    st_asgeojson(box2d(gaul1._polygon)::geometry) AS bounds
   FROM gaul1
     JOIN gaul2 ON gaul1._name::text = gaul2._gaul1_name::text
UNION
 SELECT DISTINCT gaul0._code AS code,
    gaul0._name AS name,
    'Country'::text AS type,
    gaul0._name AS gaul0_name,
    NULL::text AS gaul1_name,
    NULL::text AS gaul2_name,
    st_asgeojson(box2d(gaul0._polygon)::geometry) AS bounds
   FROM gaul0;

-- location_boundary_features
CREATE OR REPLACE VIEW _location_boundary_features AS 
SELECT l.id as location_id, 
	l.activity_id,
	lb.boundary_id,
	b._name as boundary_name,
	lb._feature_name as feature_name,
	lb._feature_area as feature_area
FROM location l
JOIN location_boundary lb 
ON l.id = lb.location_id
JOIN boundary b 
ON lb.boundary_id = b.id
ORDER BY 1, 3;

-- organization_participation
CREATE OR REPLACE VIEW _organization_participation
AS SELECT p.activity_id, a.data_group_id, dg.classification as data_group, o.id as organization_id, o._name 
FROM organization o
JOIN participation p
ON o.id = p.organization_id
JOIN activity a
ON p.activity_id = a.id
LEFT JOIN _taxonomy_classifications dg
ON a.data_group_id = dg.classification_id
WHERE o._active = true AND p._active = true
ORDER BY p.activity_id;

-- partnerlink_sankey_nodes
CREATE MATERIALIZED VIEW _partnerlink_sankey_nodes AS
SELECT DISTINCT pp.fund_name AS name,
pp.fund_id::numeric AS node,
0 AS level,
pp.activity_id
FROM _partnerlink_participants pp
UNION ALL
SELECT DISTINCT pp.acct_name AS name,
pp.acct_id::numeric + 0.1 AS node,
1 AS level,
pp.activity_id
FROM _partnerlink_participants pp
UNION ALL
SELECT DISTINCT pp.impl_name AS name,
pp.impl_id::numeric + 0.2 AS node,
2 AS level,
pp.activity_id
FROM _partnerlink_participants pp
UNION ALL
SELECT DISTINCT pp.title AS name,
pp.activity_id::numeric + 0.3 AS node,
3 AS level,
pp.activity_id
FROM _partnerlink_participants pp
ORDER BY 2; 

-- Materialized view indexes
CREATE INDEX partnerlink_sankey_nodes_idx on _partnerlink_sankey_nodes(name, node, level);
CREATE INDEX partnerlink_sankey_nodes_a_idx on _partnerlink_sankey_nodes(name, node ASC, level);
CREATE INDEX partnerlink_sankey_nodes_id_idx on _partnerlink_sankey_nodes(activity_id);
CREATE INDEX partnerlink_sankey_nodes_node_idx on _partnerlink_sankey_nodes(node);

-- partnerlink_sankey_links
CREATE MATERIALIZED VIEW _partnerlink_sankey_links AS
-- link query
SELECT f_g.f AS source, -- funder (accountable)
0 AS source_level,	-- source node level (0-2)
f_g.g AS target,	-- grantee (funding)
1 AS target_level,	-- target nodel level(1-3)
f_g.link,		-- text representation of relationship (source organization_id + '_' + target organization_id + 0.1)
f_g.activity_id		-- activity_id
FROM ( 
-- funder & grantee
SELECT pp.fund_id AS f,
pp.acct_id::numeric + 0.1 AS g,
(pp.fund_id || '_'::text) || (pp.acct_id::numeric + 0.1) AS link,
pp.activity_id
FROM _partnerlink_participants pp
) f_g
UNION ALL
SELECT g_p.g AS source,  -- grantee (funding)
1 AS source_level,	 -- source node level (0-2)
g_p.p AS target_node,	 -- partner (implementing)
2 AS target_level,	 -- target nodel level (1-3)
g_p.link,		 -- text representation of relationship (source organization_id + 1.0 + '_' + target organization_id + 0.2)
g_p.activity_id		 -- activity_id
FROM ( 
-- grantee & partner
SELECT pp.acct_id::numeric + 0.1 AS g,
pp.impl_id::numeric + 0.2 AS p,
((pp.acct_id::numeric + 0.1) || '_'::text) || (pp.impl_id::numeric + 0.2) AS link,
pp.activity_id
FROM _partnerlink_participants pp
) g_p
UNION ALL
SELECT p_a.p AS source,  -- partner (implementing)
2 AS source_level,	 -- source node level (0-2) 
p_a.a AS target,    	 -- activity title
3 AS target_level,	 -- target node level (1-3)
p_a.link,		 -- text representation of relationship (source organization_id + 0.2 + '_' + target organization_id + 0.3)
p_a.activity_id		 -- activity_id
FROM ( SELECT pp.impl_id::numeric + 0.2 AS p,
pp.activity_id::numeric + 0.3 AS a,
((pp.impl_id::numeric + 0.2) || '_'::text) || (pp.activity_id::numeric + 0.3) AS link,
pp.activity_id
FROM _partnerlink_participants pp
) p_a;

-- Materialized view indexes
CREATE INDEX partnerlink_sankey_links_id_idx on _partnerlink_sankey_links(activity_id);
CREATE INDEX partnerlink_sankey_links_node_idx on _partnerlink_sankey_links(source,target);
CREATE INDEX partnerlink_sankey_links_idx on _partnerlink_sankey_links(source,source_level,target,target_level,link);
CREATE INDEX partnerlink_sankey_links_sla_idx on _partnerlink_sankey_links(source_level,activity_id);

-- project activity points
CREATE OR REPLACE VIEW _activity_points AS
SELECT a.id as activity_id, a._title as activity_title, a.data_group_id, 
	dg.classification as data_group, l.id as location_id, l._point 
FROM activity a
JOIN location l
ON a.id = l.activity_id
LEFT JOIN _taxonomy_classifications dg
ON a.data_group_id = dg.classification_id
WHERE a._active = true AND l._active = true;

-- tags
CREATE OR REPLACE VIEW _tags
AS SELECT DISTINCT TRIM(regexp_split_to_table(_tags, ',')) as tag 
from activity;

-- tanaim_aaz (instance specific view)
CREATE OR REPLACE VIEW  tanaim_aaz AS
SELECT DISTINCT a.id as activity_id, a._title as title, dg.classification as data_group, 
c.category, sc.sub_category, l.id as location_id, l._lat_dd, l._long_dd, l._point, lb._feature_name,
(CASE 
    WHEN lb._feature_name = 'Arusha' then 'Northern' 
    WHEN lb._feature_name = 'Dodoma' then 'Central'
    WHEN lb._feature_name = 'Singida' then 'Central'
    WHEN lb._feature_name = 'Dar es Salaam' then 'Eastern'
    WHEN lb._feature_name = 'Kigoma' then 'Western'
    WHEN lb._feature_name = 'Morogoro' then 'Eastern'
    WHEN lb._feature_name = 'Pemba North' then 'Eastern'
    WHEN lb._feature_name = 'Pemba South' then 'Eastern'
    WHEN lb._feature_name = 'Pwani' then 'Eastern'
    WHEN lb._feature_name = 'Tanga' then 'Eastern'
    WHEN lb._feature_name = 'Unguja North' then 'Eastern'
    WHEN lb._feature_name = 'Unguja South' then 'Eastern'
    WHEN lb._feature_name = 'Unguja Urban West' then 'Eastern'
    WHEN lb._feature_name = 'Kagera' then 'Lake'
    WHEN lb._feature_name = 'Mara' then 'Lake'
    WHEN lb._feature_name = 'Mwanza' then 'Lake'
    WHEN lb._feature_name = 'Shinyanga' then 'Lake'
    WHEN lb._feature_name = 'Arusha' then 'Northern'
    WHEN lb._feature_name = 'Kilimanjaro' then 'Northern'
    WHEN lb._feature_name = 'Manyara' then 'Northern'
    WHEN lb._feature_name = 'Lindi' then 'Southern '
    WHEN lb._feature_name = 'Mtwara' then 'Southern '
    WHEN lb._feature_name = 'Iringa' then 'Southern Highlands'
    WHEN lb._feature_name = 'Mbeya' then 'Southern Highlands'
    WHEN lb._feature_name = 'Rukwa' then 'Southern Highlands'
    WHEN lb._feature_name = 'Ruvuma' then 'Southern Highlands'
    WHEN lb._feature_name = 'Tabora' then 'Western'
    ELSE lb._feature_name END
) as AAZ
FROM activity a
JOIN location l
ON a.id = l.activity_id
LEFT JOIN location_boundary lb
ON l.id = lb.location_id
LEFT JOIN _taxonomy_classifications dg
ON a.data_group_id = dg.classification_id
LEFT JOIN activity_taxonomy at
ON a.id = at.activity_id
LEFT JOIN _taxonomy_classifications tc
ON at.classification_id = tc.classification_id
-- collect assoications to 'Category' taxonomy
LEFT JOIN (
	SELECT at.activity_id, at.classification_id, tc.classification as category
	FROM activity_taxonomy at
	JOIN _taxonomy_classifications tc
	ON at.classification_id = tc.classification_id
	WHERE tc.taxonomy = 'Category'
) c
ON a.id = c.activity_id
-- collect assoications to 'Sub-Category' taxonomy
LEFT JOIN (
	SELECT at.activity_id, at.classification_id, tc.classification as sub_category
	FROM activity_taxonomy at
	JOIN _taxonomy_classifications tc
	ON at.classification_id = tc.classification_id
	WHERE tc.taxonomy = 'Sub-Category'
) sc
ON a.id = sc.activity_id
-- only active activities and boundary intersections with gaul1
WHERE a._active = true AND lb.boundary_id = (SELECT id FROM boundary WHERE _spatial_table = 'gaul1')
-- only locations in Tanzania
AND l.id IN (SELECT location_id FROM location_taxonomy WHERE classification_id = (SELECT classification_id FROM _taxonomy_classifications 
	WHERE taxonomy = 'Country' and classification = 'TANZANIA, UNITED REPUBLIC OF'))
-- only activities without a 'National' classification from the 'National/Local' Taxonomy	
AND a.id NOT IN (SELECT activity_id FROM activity_taxonomy WHERE classification_id = 
	(SELECT classification_id FROM _taxonomy_classifications WHERE taxonomy = 'National/Local' AND classification = 'National'))
ORDER BY 1;

-- tanaim_nbs (instance specific view)
CREATE OR REPLACE VIEW  tanaim_nbs AS 
SELECT 	a.id AS activity_id
	,a._title as title
	,l.id AS location_id
	,l._lat_dd AS lat_dd
	,l._long_dd AS long_dd
	,l._point AS point
	,(SELECT feature_name FROM _location_boundary_features lbf WHERE lbf.boundary_id = (SELECT id FROM boundary WHERE _name = 'GAUL Level 0') AND lbf.location_id = l.id LIMIT 1) as "Country (Gaul0)"
	,(SELECT feature_name FROM _location_boundary_features lbf WHERE lbf.boundary_id = (SELECT id FROM boundary WHERE _name = 'GAUL Level 1') AND lbf.location_id = l.id LIMIT 1) as "Region (Gaul1)"
	,(SELECT feature_name FROM _location_boundary_features lbf WHERE lbf.boundary_id = (SELECT id FROM boundary WHERE _name = 'GAUL Level 2') AND lbf.location_id = l.id LIMIT 1) as "District (Gaul2)"	
	,(SELECT feature_name FROM _location_boundary_features lbf WHERE lbf.boundary_id = (SELECT id FROM boundary WHERE _name = 'NBS Tanzania Regions') AND lbf.location_id = l.id LIMIT 1) as "Region (NBS2)"
	,(SELECT feature_name FROM _location_boundary_features lbf WHERE lbf.boundary_id = (SELECT id FROM boundary WHERE _name = 'NBS Tanzania Districts') AND lbf.location_id = l.id LIMIT 1) as "District (NBS1)"
FROM activity a
JOIN location l
ON a.id = l.activity_id
WHERE l.id IN (SELECT location_id FROM _location_boundary_features WHERE feature_name = 'United Republic of Tanzania')
ORDER BY 1,2;

-- taxonomy_xwalks
CREATE OR REPLACE VIEW  _taxonomy_xwalks AS
SELECT origin.origin_taxonomy_id, origin.origin_taxonomy, origin.origin_classification_id, origin.origin_classification 
,linked.linked_taxonomy_id, linked.linked_taxonomy, linked.linked_classification_id, linked.linked_classification, linked._direction
FROM
(SELECT tx.origin_taxonomy_id, tc.taxonomy as origin_taxonomy, tx.origin_classification_id, tc.classification as origin_classification
FROM taxonomy_xwalk tx
JOIN _taxonomy_classifications tc
ON tx.origin_taxonomy_id = tc.taxonomy_id AND tx.origin_classification_id = tc.classification_id) origin
JOIN
(SELECT tx.origin_taxonomy_id, tx.origin_classification_id, tx.linked_taxonomy_id, tc.taxonomy as linked_taxonomy, tx.linked_classification_id, tc.classification as linked_classification, tx._direction
FROM taxonomy_xwalk tx
JOIN _taxonomy_classifications tc
ON tx.linked_taxonomy_id = tc.taxonomy_id AND tx.linked_classification_id = tc.classification_id) linked
ON origin.origin_taxonomy_id = linked.origin_taxonomy_id AND origin.origin_classification_id = linked.origin_classification_id
ORDER BY 2,4,6,8;

-- taxonomy_lookup
CREATE OR REPLACE VIEW _taxonomy_lookup AS
SELECT DISTINCT a.id as activity_id, a.data_group_id, l.id as location_id, a._start_date AS start_date, a._end_date AS end_date, tax.taxonomy_id, tax.classification_id
FROM activity a
JOIN location l
ON a.id = l.activity_id
LEFT JOIN
(SELECT at.activity_id, c.taxonomy_id, at.classification_id
FROM activity_taxonomy at
JOIN classification c
ON at.classification_id = c.id
UNION ALL
SELECT l.activity_id, c.taxonomy_id, lt.classification_id
FROM location_taxonomy lt
JOIN location l
ON l.id = lt.location_id 
JOIN classification c
ON lt.classification_id = c.id) as tax
ON a.id = tax.activity_id
WHERE a._active = true AND l._active = true;

-- location_lookup
CREATE OR REPLACE VIEW _location_lookup AS
SELECT l.activity_id, a.data_group_id, l.id as location_id, l._x as x, l._y as y, l._lat_dd as lat_dd, l._long_dd as long_dd, b.id as boundary_id, b._name as boundary
,lb._feature_name as feature_name
FROM location l
JOIN activity a
ON l.activity_id = a.id
LEFT JOIN location_boundary lb
ON l.id = lb.location_id
JOIN boundary b
ON lb.boundary_id = b.id
WHERE l._active = TRUE AND a._active = TRUE AND b._active = TRUE;

-- organization_lookup
CREATE OR REPLACE VIEW _organization_lookup AS
SELECT a.id as activity_id, a.data_group_id, o.id as organization_id, o._name as organization, tc.taxonomy_id,  tc.taxonomy, tc.classification_id, tc.classification
FROM activity a
LEFT JOIN participation p
ON a.id = p.activity_id
LEFT JOIN organization o
ON p.organization_id = o.id
LEFT JOIN participation_taxonomy pt
ON p.id = pt.participation_id
LEFT JOIN _taxonomy_classifications tc
ON pt.classification_id = tc.classification_id
WHERE a._active = TRUE AND p._active = TRUE AND o._active = TRUE
ORDER BY 1,3;

-- BMGF project overview (parent activities with taxonomy)
DROP VIEW IF EXISTS bmgf_project_overview;
CREATE OR REPLACE VIEW bmgf_project_overview AS
SELECT a.id, a._title, a.opportunity_id, a._created_by, a._created_date, a._updated_by, a._updated_date
,(SELECT array_agg(_name) FROM activity_taxonomy JOIN classification ON classification_id=id WHERE classification_id IN (SELECT id FROM classification WHERE taxonomy_id=22) AND activity_id = a.id) as "Focus Crops"
,(SELECT array_agg(_name) FROM activity_taxonomy JOIN classification ON classification_id=id WHERE classification_id IN (SELECT id FROM classification WHERE taxonomy_id=18) AND activity_id = a.id) as "Activity Status"
,(SELECT array_agg(_name) FROM activity_taxonomy JOIN classification ON classification_id=id WHERE classification_id IN (SELECT id FROM classification WHERE taxonomy_id=17) AND activity_id = a.id) as "Sub-Initiative"
,(SELECT array_agg(_name) FROM activity_taxonomy JOIN classification ON classification_id=id WHERE classification_id IN (SELECT id FROM classification WHERE taxonomy_id=23) AND activity_id = a.id) as "Initiative"
,(SELECT array_agg(_name) FROM activity_taxonomy JOIN classification ON classification_id=id WHERE classification_id IN (SELECT id FROM classification WHERE taxonomy_id=24) AND activity_id = a.id) as "Nutrient Focus"
,(SELECT array_agg(_name) FROM activity_taxonomy JOIN classification ON classification_id=id WHERE classification_id IN (SELECT id FROM classification WHERE taxonomy_id=25) AND activity_id = a.id) as "Nutrient Indicator"
,(SELECT array_agg(_name) FROM activity_taxonomy JOIN classification ON classification_id=id WHERE classification_id IN (SELECT id FROM classification WHERE taxonomy_id=26) AND activity_id = a.id) as "Extension Type"
FROM activity a
WHERE a.data_group_id = 768 AND a.parent_id IS NULL AND a._active = true;

/*************************************************************************
  3. update selected functions
*************************************************************************/
-- pmt_validate_boundary_feature
CREATE OR REPLACE FUNCTION pmt_validate_boundary_feature(boundary_id integer, feature_id integer) RETURNS boolean AS $$
DECLARE valid_id integer;
	spatialtable text;
	execute_statement text;
BEGIN 
     IF $1 IS NULL OR $2 IS NULL THEN    
       RETURN false;
     END IF;    

     SELECT INTO spatialtable _spatial_table FROM boundary WHERE boundary.id = $1;	

     IF spatialtable IS NOT NULL THEN
       execute_statement := 'SELECT id FROM ' || quote_ident(spatialtable) || ' WHERE id = ' || $2 ;
       EXECUTE execute_statement INTO valid_id;
     ELSE
       RETURN false;
     END IF;
     
     IF valid_id IS NULL THEN
      RETURN false;
     ELSE 
      RETURN true;
     END IF;
     
EXCEPTION WHEN OTHERS THEN
    RETURN FALSE;
END; 
$$ LANGUAGE 'plpgsql';   

/*************************************************************************
  4. create new function to support consistantcy checks
*************************************************************************/
-- pmt_is_data_group
CREATE OR REPLACE FUNCTION pmt_is_data_group(classification_id integer) RETURNS boolean AS $$
DECLARE 
	taxonomy_id integer;
BEGIN 
     IF $1 IS NULL THEN    
       RETURN false;
     END IF;    

     SELECT INTO taxonomy_id classification.taxonomy_id FROM classification WHERE classification.id = $1;	

     IF taxonomy_id IS NOT NULL AND taxonomy_id = 1 THEN
       RETURN TRUE; 
     ELSE
       RETURN FALSE;
     END IF;
     
EXCEPTION WHEN OTHERS THEN
    RETURN FALSE;
END; 
$$ LANGUAGE 'plpgsql'; 

-- pmt_is_data_group
CREATE OR REPLACE FUNCTION pmt_is_data_group(name character varying(255)) RETURNS boolean AS $$
DECLARE 
  taxonomy_id integer;
BEGIN 
     IF $1 IS NULL THEN    
       RETURN false;
     END IF;    

     SELECT INTO taxonomy_id classification.taxonomy_id FROM classification WHERE lower(classification._name) = lower($1);	

     IF taxonomy_id IS NOT NULL AND taxonomy_id = 1 THEN
       RETURN TRUE; 
     ELSE
       RETURN FALSE;
     END IF;
     
EXCEPTION WHEN OTHERS THEN
    RETURN FALSE;
END; 
$$ LANGUAGE 'plpgsql'; 

/*************************************************************************
  5. add constraints
*************************************************************************/
ALTER TABLE activity ADD CONSTRAINT fk_activity_parent_id FOREIGN KEY (parent_id) REFERENCES activity;
ALTER TABLE activity ADD CONSTRAINT fk_activity_dg FOREIGN KEY (data_group_id) REFERENCES classification;
ALTER TABLE activity ADD CONSTRAINT chk_activity_dg_chk CHECK (pmt_is_data_group(data_group_id)) NOT VALID;
ALTER TABLE activity ADD CONSTRAINT chk_activity_created_by CHECK (_created_by IS NOT NULL) NOT VALID;
ALTER TABLE activity ADD CONSTRAINT chk_activity_updated_by CHECK (_updated_by IS NOT NULL) NOT VALID;
ALTER TABLE activity ADD CONSTRAINT fk_activity_iati_import FOREIGN KEY (iati_import_id) REFERENCES iati_import;
ALTER TABLE activity_contact ADD CONSTRAINT fk_activity_contact_activity_id FOREIGN KEY (activity_id) REFERENCES activity;
ALTER TABLE activity_contact ADD CONSTRAINT fk_activity_contact_contact_id FOREIGN KEY (contact_id) REFERENCES contact;
ALTER TABLE activity_taxonomy ADD CONSTRAINT fk_activity_taxonomy_activity_id FOREIGN KEY (activity_id) REFERENCES activity;
ALTER TABLE activity_taxonomy ADD CONSTRAINT fk_activity_taxonomy_classification_id FOREIGN KEY (classification_id) REFERENCES classification;
ALTER TABLE boundary ADD CONSTRAINT chk_boundary_created_by CHECK (_created_by IS NOT NULL) NOT VALID;
ALTER TABLE boundary ADD CONSTRAINT chk_boundary_updated_by CHECK (_updated_by IS NOT NULL) NOT VALID;
ALTER TABLE boundary_taxonomy ADD CONSTRAINT fk_boundary_taxonomy_activity_id FOREIGN KEY (boundary_id) REFERENCES boundary;
ALTER TABLE boundary_taxonomy ADD CONSTRAINT fk_boundary_taxonomy_classification_id FOREIGN KEY (classification_id) REFERENCES classification;
ALTER TABLE classification ADD CONSTRAINT fk_classification_parent_id FOREIGN KEY (parent_id) REFERENCES classification;
ALTER TABLE classification ADD CONSTRAINT fk_classification_taxonomy_id FOREIGN KEY (taxonomy_id) REFERENCES taxonomy;
ALTER TABLE classification ADD CONSTRAINT chk_classification_created_by CHECK (_created_by IS NOT NULL) NOT VALID;
ALTER TABLE classification ADD CONSTRAINT chk_classification_updated_by CHECK (_updated_by IS NOT NULL) NOT VALID;
ALTER TABLE contact ADD CONSTRAINT fk_contact_organization_id FOREIGN KEY (organization_id) REFERENCES organization;
ALTER TABLE contact ADD CONSTRAINT chk_contact_created_by CHECK (_created_by IS NOT NULL) NOT VALID;
ALTER TABLE contact ADD CONSTRAINT chk_contact_updated_by CHECK (_updated_by IS NOT NULL) NOT VALID;
ALTER TABLE contact_taxonomy ADD CONSTRAINT fk_contact_taxonomy_contact_id FOREIGN KEY (contact_id) REFERENCES contact;
ALTER TABLE contact_taxonomy ADD CONSTRAINT fk_contact_taxonomy_classification_id FOREIGN KEY (classification_id) REFERENCES classification;
ALTER TABLE detail ADD CONSTRAINT fk_detail_activity_id FOREIGN KEY (activity_id) REFERENCES activity;
ALTER TABLE detail ADD CONSTRAINT chk_detail_created_by CHECK (_created_by IS NOT NULL) NOT VALID;
ALTER TABLE detail ADD CONSTRAINT chk_detail_updated_by CHECK (_updated_by IS NOT NULL) NOT VALID;
ALTER TABLE feature_taxonomy ADD CONSTRAINT fk_feature_taxonomy_boundary_id FOREIGN KEY (boundary_id) REFERENCES boundary;
ALTER TABLE feature_taxonomy ADD CONSTRAINT fk_feature_taxonomy_classification_id FOREIGN KEY (classification_id) REFERENCES classification;
ALTER TABLE feature_taxonomy ADD CONSTRAINT chk_feature_taxonomy_feature_id CHECK (pmt_validate_boundary_feature(boundary_id, feature_id)) NOT VALID;
ALTER TABLE financial ADD CONSTRAINT fk_financial_activity_id FOREIGN KEY (activity_id) REFERENCES activity;
ALTER TABLE financial ADD CONSTRAINT fk_financial_provider_id FOREIGN KEY (provider_id) REFERENCES organization;
ALTER TABLE financial ADD CONSTRAINT fk_financial_recipient_id FOREIGN KEY (recipient_id) REFERENCES organization;
ALTER TABLE financial ADD CONSTRAINT chk_financial_created_by CHECK (_created_by IS NOT NULL) NOT VALID;
ALTER TABLE financial ADD CONSTRAINT chk_financial_updated_by CHECK (_updated_by IS NOT NULL) NOT VALID;
ALTER TABLE financial_taxonomy ADD CONSTRAINT fk_financial_taxonomy_financial_id FOREIGN KEY (financial_id) REFERENCES financial;
ALTER TABLE financial_taxonomy ADD CONSTRAINT fk_financial_taxonomy_classification_id FOREIGN KEY (classification_id) REFERENCES classification;
ALTER TABLE gaul0 ADD CONSTRAINT fk_gaul0_boundary_id FOREIGN KEY (boundary_id) REFERENCES boundary;
ALTER TABLE gaul0 ADD CONSTRAINT chk_gaul0_created_by CHECK (_created_by IS NOT NULL) NOT VALID;
ALTER TABLE gaul0 ADD CONSTRAINT chk_gaul0_updated_by CHECK (_updated_by IS NOT NULL) NOT VALID;
ALTER TABLE gaul1 ADD CONSTRAINT fk_gaul1_boundary_id FOREIGN KEY (boundary_id) REFERENCES boundary;
ALTER TABLE gaul1 ADD CONSTRAINT chk_gaul1_created_by CHECK (_created_by IS NOT NULL) NOT VALID;
ALTER TABLE gaul1 ADD CONSTRAINT chk_gaul1_updated_by CHECK (_updated_by IS NOT NULL) NOT VALID;
ALTER TABLE gaul2 ADD CONSTRAINT fk_gaul2_boundary_id FOREIGN KEY (boundary_id) REFERENCES boundary;
ALTER TABLE gaul2 ADD CONSTRAINT chk_gaul2_created_by CHECK (_created_by IS NOT NULL) NOT VALID;
ALTER TABLE gaul2 ADD CONSTRAINT chk_gaul2_updated_by CHECK (_updated_by IS NOT NULL) NOT VALID;
ALTER TABLE iati_import ADD CONSTRAINT chk_iati_import_created_by CHECK (_created_by IS NOT NULL) NOT VALID;
ALTER TABLE location ADD CONSTRAINT fk_location_activity_id FOREIGN KEY (activity_id) REFERENCES activity;
ALTER TABLE location ADD CONSTRAINT fk_location_boundary_id FOREIGN KEY (boundary_id) REFERENCES boundary;
ALTER TABLE location ADD CONSTRAINT chk_location_feature_id CHECK ((boundary_id IS NULL AND feature_id IS NULL) OR (pmt_validate_boundary_feature(boundary_id, feature_id))) NOT VALID;
ALTER TABLE location ADD CONSTRAINT chk_location_created_by CHECK (_created_by IS NOT NULL) NOT VALID;
ALTER TABLE location ADD CONSTRAINT chk_location_updated_by CHECK (_updated_by IS NOT NULL) NOT VALID;
ALTER TABLE location_boundary ADD CONSTRAINT fk_location_boundary_location_id FOREIGN KEY (location_id) REFERENCES location;
ALTER TABLE location_boundary ADD CONSTRAINT fk_location_boundary_boundary_id FOREIGN KEY (boundary_id) REFERENCES boundary;
ALTER TABLE location_boundary ADD CONSTRAINT chk_location_boundary_feature_id CHECK (pmt_validate_boundary_feature(boundary_id, feature_id)) NOT VALID;
ALTER TABLE location_taxonomy ADD CONSTRAINT fk_location_taxonomy_location_id FOREIGN KEY (location_id) REFERENCES location;
ALTER TABLE location_taxonomy ADD CONSTRAINT fk_location_taxonomy_classification_id FOREIGN KEY (classification_id) REFERENCES classification;
ALTER TABLE map ADD CONSTRAINT fk_map_user_id FOREIGN KEY (user_id) REFERENCES users;
ALTER TABLE map ADD CONSTRAINT chk_map_created_by CHECK (_created_by IS NOT NULL) NOT VALID;
ALTER TABLE map ADD CONSTRAINT chk_map_updated_by CHECK (_updated_by IS NOT NULL) NOT VALID;
ALTER TABLE nbs_tza_1 ADD CONSTRAINT fk_nbs_tza_1_boundary_id FOREIGN KEY (boundary_id) REFERENCES boundary;
ALTER TABLE nbs_tza_1 ADD CONSTRAINT chk_nbs_tza_1_created_by CHECK (_created_by IS NOT NULL) NOT VALID;
ALTER TABLE nbs_tza_1 ADD CONSTRAINT chk_nbs_tza_1_updated_by CHECK (_updated_by IS NOT NULL) NOT VALID;
ALTER TABLE nbs_tza_2 ADD CONSTRAINT fk_nbs_tza_2_boundary_id FOREIGN KEY (boundary_id) REFERENCES boundary;
ALTER TABLE nbs_tza_2 ADD CONSTRAINT chk_nbs_tza_2_created_by CHECK (_created_by IS NOT NULL) NOT VALID;
ALTER TABLE nbs_tza_2 ADD CONSTRAINT chk_nbs_tza_2_updated_by CHECK (_updated_by IS NOT NULL) NOT VALID;
ALTER TABLE organization ADD CONSTRAINT chk_organization_name CHECK (_name IS NOT NULL) NOT VALID;
ALTER TABLE organization ADD CONSTRAINT chk_organization_created_by CHECK (_created_by IS NOT NULL) NOT VALID;
ALTER TABLE organization ADD CONSTRAINT chk_organization_updated_by CHECK (_updated_by IS NOT NULL) NOT VALID;
ALTER TABLE organization ADD CONSTRAINT fk_organization_iati_import FOREIGN KEY (iati_import_id) REFERENCES iati_import;
ALTER TABLE organization_taxonomy ADD CONSTRAINT fk_organization_taxonomy_organization_id FOREIGN KEY (organization_id) REFERENCES organization;
ALTER TABLE organization_taxonomy ADD CONSTRAINT fk_organization_taxonomy_classification_id FOREIGN KEY (classification_id) REFERENCES classification;
ALTER TABLE participation ADD CONSTRAINT chk_participation_activity_id CHECK (activity_id IS NOT NULL) NOT VALID;
ALTER TABLE participation ADD CONSTRAINT chk_participation_created_by CHECK (_created_by IS NOT NULL) NOT VALID;
ALTER TABLE participation ADD CONSTRAINT chk_participation_updated_by CHECK (_updated_by IS NOT NULL) NOT VALID;
ALTER TABLE participation_taxonomy ADD CONSTRAINT fk_participation_taxonomy_participation_id FOREIGN KEY (participation_id) REFERENCES participation;
ALTER TABLE participation_taxonomy ADD CONSTRAINT fk_participation_taxonomy_classification_id FOREIGN KEY (classification_id) REFERENCES classification;
ALTER TABLE result ADD CONSTRAINT fk_result_activity_id FOREIGN KEY (activity_id) REFERENCES activity;
ALTER TABLE result ADD CONSTRAINT chk_result_created_by CHECK (_created_by IS NOT NULL) NOT VALID;
ALTER TABLE result ADD CONSTRAINT chk_result_updated_by CHECK (_updated_by IS NOT NULL) NOT VALID;
ALTER TABLE result_taxonomy ADD CONSTRAINT fk_result_taxonomy_result_id FOREIGN KEY (result_id) REFERENCES result;
ALTER TABLE result_taxonomy ADD CONSTRAINT fk_result_taxonomy_classification_id FOREIGN KEY (classification_id) REFERENCES classification;
ALTER TABLE taxonomy ADD CONSTRAINT fk_taxonomy_parent_id FOREIGN KEY (parent_id) REFERENCES taxonomy;
ALTER TABLE taxonomy ADD CONSTRAINT chk_taxonomy_created_by CHECK (_created_by IS NOT NULL) NOT VALID;
ALTER TABLE taxonomy ADD CONSTRAINT chk_taxonomy_updated_by CHECK (_updated_by IS NOT NULL) NOT VALID;
ALTER TABLE taxonomy_xwalk ADD CONSTRAINT fk_taxonomy_xwalk_origin_tax_id FOREIGN KEY (origin_taxonomy_id) REFERENCES taxonomy;
ALTER TABLE taxonomy_xwalk ADD CONSTRAINT fk_taxonomy_xwalk_linked_tax_id FOREIGN KEY (linked_taxonomy_id) REFERENCES taxonomy;
ALTER TABLE taxonomy_xwalk ADD CONSTRAINT fk_taxonomy_xwalk_origin_class_id FOREIGN KEY (origin_classification_id) REFERENCES classification;
ALTER TABLE taxonomy_xwalk ADD CONSTRAINT fk_taxonomy_xwalk_linked_class_id FOREIGN KEY (linked_classification_id) REFERENCES classification;
ALTER TABLE taxonomy_xwalk ADD CONSTRAINT chk_taxonomy_xwalk_created_by CHECK (_created_by IS NOT NULL) NOT VALID;
ALTER TABLE taxonomy_xwalk ADD CONSTRAINT chk_taxonomy_xwalk_updated_by CHECK (_updated_by IS NOT NULL) NOT VALID;
ALTER TABLE user_activity_role ADD CONSTRAINT chk_user_activity_role_created_by CHECK (_created_by IS NOT NULL) NOT VALID;
ALTER TABLE user_activity_role ADD CONSTRAINT chk_user_activity_role_updated_by CHECK (_updated_by IS NOT NULL) NOT VALID;
ALTER TABLE users ADD CONSTRAINT fk_users_role_id FOREIGN KEY (role_id) REFERENCES role;
ALTER TABLE users ADD CONSTRAINT fk_users_organization_id FOREIGN KEY (organization_id) REFERENCES organization;
ALTER TABLE users ADD CONSTRAINT chk_users_created_by CHECK (_created_by IS NOT NULL) NOT VALID;
ALTER TABLE users ADD CONSTRAINT chk_users_updated_by CHECK (_updated_by IS NOT NULL) NOT VALID;

/*************************************************************************
  6. update selected triggers
*************************************************************************/
-- upd_geometry_formats
DROP FUNCTION IF EXISTS upd_geometry_formats();
CREATE OR REPLACE FUNCTION pmt_upd_geometry_formats()
RETURNS trigger AS $pmt_upd_geometry_formats$
    DECLARE
	id integer;
	rec record;
	latitude character varying;		-- latitude
	longitude character varying;		-- longitude
	lat_dd decimal;				-- latitude decimal degrees
	long_dd decimal;			-- longitude decimal degrees
	lat_d integer;				-- latitude degrees
	lat_m integer;				-- latitude mintues
	lat_s integer;				-- latitude seconds
	lat_c character varying(3);		-- latitude direction (N,E,W,S)
	long_d integer;				-- longitude degrees
	long_m integer;				-- longitude minutes
	long_s integer;				-- longitude seconds
	long_c character varying(3);		-- longitude direction (N,E,W,S)
	news_lat_d integer;			-- starting latitude degrees (news rule)
	news_lat_m integer;			-- starting latitude mintues (news rule)
	news_lat_s integer;			-- starting latitude seconds (news rule)
	news_lat_add boolean;			-- news flag for operation N,E(+) W,S(-)
	news_long_d integer;			-- starting longitude degrees (news rule)
	news_long_m integer;			-- starting longitude mintues (news rule)
	news_long_s integer;			-- starting longitude seconds (news rule)
	news_long_add boolean;			-- news flag for operation N,E(+) W,S(-)
	news_lat_div1 integer; 			-- news rule division #1 latitude
	news_lat_div2 integer; 			-- news rule division #2 latitude
	news_lat_div3 integer; 			-- news rule division #3 latitude
	news_lat_div4 integer; 			-- news rule division #4 latitude
	news_long_div1 integer; 		-- news rule division #1 longitude
	news_long_div2 integer; 		-- news rule division #2 longitude
	news_long_div3 integer; 		-- news rule division #3 longitude	
	news_long_div4 integer; 		-- news rule division #4 longitude	
	georef text ARRAY[4];			-- georef (long then lat)
	alpha text ARRAY[24];			-- georef grid
    BEGIN	
	-- calculate GEOREF format from lat/long using the Federation of Americation Scientists (FAS) NEWS method
	RAISE NOTICE 'Refreshing geometry formats for id % ...', NEW.id;
	-- alphanumerical relationship array ('O' & 'I" are not used in GEOREF)
	alpha := '{"A","B","C","D","E","F","G","H","J","K","L","M","N","P","Q","R","S","T","U","V","W","X","Y","Z"}';

	IF ST_IsEmpty(NEW._point) THEN
		-- no geometry
		RAISE NOTICE 'The point was empty cannot format.';
	ELSE	
		-- get latitude and longitude from geometry
		latitude := substring(ST_AsLatLonText(NEW._point, 'D°M''S"C') from 0 for position(' ' in ST_AsLatLonText(NEW._point, 'D°M''S"C')));
		longitude := substring(ST_AsLatLonText(NEW._point, 'D°M''S"C') from position(' ' in ST_AsLatLonText(NEW._point, 'D°M''S"C')) for octet_length(ST_AsLatLonText(NEW._point, 'D°M''S"C')) - position(' ' in ST_AsLatLonText(NEW._point, 'D°M''S"C')) );
		
		--RAISE NOTICE 'Latitude/Longitude Decimal Degrees: %', ST_AsLatLonText(NEW._point, 'D.DDDDDD'); 
		--RAISE NOTICE 'Latitude Decimal Degrees: %', substring(ST_AsLatLonText(NEW._point, 'D.DDDDDD') from 0 for position(' ' in ST_AsLatLonText(NEW._point, 'D.DDDDDD')));
		NEW._lat_dd := CAST(substring(ST_AsLatLonText(NEW._point, 'D.DDDDDD') from 0 for position(' ' in ST_AsLatLonText(NEW._point, 'D.DDDDDD'))) AS decimal);
		--RAISE NOTICE 'Longitude Decimal Degrees: %', substring(ST_AsLatLonText(NEW._point, 'D.DDDDDD') from position(' ' in ST_AsLatLonText(NEW._point, 'D.DDDDDD')) for octet_length(ST_AsLatLonText(NEW._point, 'D.DDDDDD')) - position(' ' in ST_AsLatLonText(NEW._point, 'D.DDDDDD')) );
		NEW._long_dd := CAST(substring(ST_AsLatLonText(NEW._point, 'D.DDDDDD') from position(' ' in ST_AsLatLonText(NEW._point, 'D.DDDDDD')) for octet_length(ST_AsLatLonText(NEW._point, 'D.DDDDDD')) - position(' ' in ST_AsLatLonText(NEW._point, 'D.DDDDDD')) ) AS decimal);
		--RAISE NOTICE 'The latitude is: %', latitude;
		--RAISE NOTICE 'The longitude is: %', longitude;
		NEW._latlong := ST_AsLatLonText(NEW._point, 'D°M''S"C');
		--RAISE NOTICE 'The latlong is: %', NEW._latlong;
		NEW._x := CAST(ST_X(ST_Transform(ST_SetSRID(NEW._point,4326),3857)) AS integer); 
		--RAISE NOTICE 'The x is: %', NEW._x;
		NEW._y := CAST(ST_Y(ST_Transform(ST_SetSRID(NEW._point,4326),3857)) AS integer);
		--RAISE NOTICE 'The y is: %', NEW._y;
		
		lat_d := NULLIF(substring(latitude from 0 for position('°' in latitude)), '')::int;
		lat_m := NULLIF(substring(latitude from position('°' in latitude)+1 for position('''' in latitude) - position('°' in latitude)-1), '')::int;
		lat_s := NULLIF(substring(latitude from position('''' in latitude)+1 for position('"' in latitude) - position('''' in latitude)-1), '')::int;
		lat_c := NULLIF(substring(latitude from position('"' in latitude)+1 for position('"' in latitude) - position('''' in latitude)-1), '')::character varying(3);
		--RAISE NOTICE 'The length of latitude: %', length(trim(latitude));
		--RAISE NOTICE 'The length of longitude: %', length(trim(longitude));
		--RAISE NOTICE 'The lat (dmsc): %', lat_d || ' ' || lat_m || ' ' || lat_s || ' ' || lat_c; 
		long_d := NULLIF(substring(longitude from 0 for position('°' in longitude)), '')::int;
		long_m := NULLIF(substring(longitude from position('°' in longitude)+1 for position('''' in longitude) - position('°' in longitude)-1), '')::int;
		long_s := NULLIF(substring(longitude from position('''' in longitude)+1 for position('"' in longitude) - position('''' in longitude)-1), '')::int;
		long_c := NULLIF(substring(longitude from position('"' in longitude)+1 for position('"' in longitude) - position('''' in longitude)-1), '')::character varying(3);
		--RAISE NOTICE 'The long (dmsc): %', long_d || ' ' || long_m || ' ' || long_s || ' ' || long_c; 
		--calculate longitude using NEWS rule
		CASE long_c -- longitude direction
			WHEN 'N' THEN -- north
				-- 90°00'00" (starting longitude) + longitude
				news_long_d = 90;
				news_long_add := true;
				news_long_m := 0;
				news_long_s := 0;
			WHEN 'E' THEN
				--180°00'00" (starting longitude) + longitude
				news_long_d = 180;
				news_long_add := true;
				news_long_m := 0;
				news_long_s := 0;
			WHEN 'W' THEN	
				--180°00'00" (starting longitude) - longitude
				news_long_add := false;
				-- if minutes and seconds is zero we don't need to borrow to subtract
				IF long_m = 0 AND long_s = 0 THEN
					news_long_d = 180;
					news_long_m := 0;
					news_long_s := 0;
				-- if not zero we need to borrow so 180°00'00" becomes 179°59'60"
				ELSE
					news_long_d = 179;
					news_long_m := 59;
					news_long_s := 60;
				END IF;
			WHEN 'S' THEN
				-- 90°00'00" (starting longitude) - longitude
				news_long_add := false;
				-- if minutes and seconds is zero we don't need to borrow to subtract
				IF long_m = 0 AND long_s = 0 THEN
					news_long_d = 90;
					news_long_m := 0;
					news_long_s := 0;
				-- if not zero we need to borrow so 90°00'00" becomes 89°59'60"
				ELSE
					news_long_d = 89;
					news_long_m := 59;
					news_long_s := 60;
				END IF;	
			ELSE
			-- bad direction or null
		END CASE;
		
		IF news_long_add THEN
			news_long_div1 := (news_long_d + long_d) / 15;
			news_long_div2 := (news_long_d + long_d) % 15;
			news_long_div3 := news_long_m + long_m;
			news_long_div4 := news_long_s + long_s;
		ELSE
			news_long_div1 := (news_long_d - long_d) / 15;
			news_long_div2 := (news_long_d - long_d) % 15;
			news_long_div3 := news_long_m - long_m;
			news_long_div4 := news_long_s - long_s;
		END IF;
		
		--calculate latitude using NEWS rule
		CASE lat_c -- latitude direction
			WHEN 'N' THEN -- north
				-- 90°00'00" (starting latitude) + latitude
				news_lat_d = 90;
				news_lat_add := true;
				news_lat_m := 0;
				news_lat_s := 0;
			WHEN 'E' THEN
				--180°00'00" (starting latitude) + latitude
				news_lat_d = 180;
				news_lat_add := true;
				news_lat_m := 0;
				news_lat_s := 0;
			WHEN 'W' THEN	
				--180°00'00" (starting latitude) - latitude
				news_lat_add := false;				
				-- if minutes and seconds is zero we don't need to borrow to subtract
				IF lat_m = 0 AND lat_s = 0 THEN
					news_lat_d = 180;
					news_lat_m := 0;
					news_lat_s := 0;
				-- if not zero we need to borrow so 180°00'00" becomes 179°59'60"
				ELSE
					news_lat_d = 179;
					news_lat_m := 59;
					news_lat_s := 60;
				END IF;			
			WHEN 'S' THEN
				-- 90°00'00" (starting latitude) - latitude
				news_lat_add := false;			
				-- if minutes and seconds is zero we don't need to borrow to subtract
				IF lat_m = 0 AND lat_s = 0 THEN
					news_lat_d = 90;
					news_lat_m := 0;
					news_lat_s := 0;
				-- if not zero we need to borrow so 90°00'00" becomes 89°59'60"
				ELSE
					news_lat_d = 89;
					news_lat_m := 59;
					news_lat_s := 60;
				END IF;				
			ELSE
			--null or bad direction
		END CASE;
		
		IF news_lat_add THEN
			news_lat_div1 := (news_lat_d + lat_d) / 15;
			news_lat_div2 := (news_lat_d + lat_d) % 15;
			news_lat_div3 := news_lat_m + lat_m;
			news_lat_div4 := news_lat_s + lat_s;
		ELSE
			news_lat_div1 := (news_lat_d - lat_d) / 15;
			news_lat_div2 := (news_lat_d - lat_d) % 15;
			news_lat_div3 := news_lat_m - lat_m;
			news_lat_div4 := news_lat_s - lat_s;
		END IF;

		--RAISE NOTICE 'The news long div1,2,3,4: %', news_long_div1 || ', ' || news_long_div2 || ', ' || to_char(news_long_div3, '00') || ', ' || to_char(news_long_div4, '00') ; 
		--RAISE NOTICE 'The news lat div1,2,3,4: %', news_lat_div1 || ', ' || news_lat_div2 || ', ' ||  to_char(news_lat_div3, '00')  || ', ' || to_char(news_lat_div4, '00'); 
		
		-- set georef format
		NEW._georef := alpha[news_long_div1+1] || alpha[news_lat_div1+1] || alpha[news_long_div2+1] || alpha[news_lat_div2+1] || trim(both ' ' from to_char(news_long_div3, '00')) 
		|| trim(both ' ' from to_char(news_long_div4, '00'))  || trim(both ' ' from to_char(news_lat_div3, '00')) || trim(both ' ' from to_char(news_lat_div4, '00'));
		--RAISE NOTICE 'The georef: %', NEW._georef;			
		-- Remember when location was added/updated
		NEW._updated_date := current_timestamp;
				
        END IF;
        
        RETURN NEW;
    END;
$pmt_upd_geometry_formats$ LANGUAGE plpgsql; 
DROP TRIGGER IF EXISTS pmt_upd_geometry_formats ON location;
CREATE TRIGGER pmt_upd_geometry_formats BEFORE INSERT OR UPDATE ON location
    FOR EACH ROW EXECUTE PROCEDURE pmt_upd_geometry_formats();
    
-- upd_boundary_features
DROP FUNCTION IF EXISTS upd_boundary_features();
CREATE OR REPLACE FUNCTION pmt_upd_boundary_features()
RETURNS trigger AS $pmt_upd_boundary_features$
DECLARE
  boundary RECORD;
  feature RECORD;
  ft RECORD;
  rec RECORD;
  spatialtable text;
  execute_statement text;
  centroid geometry;
  id integer;
BEGIN
  -- Remove all existing location boundary information for this location (to be recreated by this trigger)
  EXECUTE 'DELETE FROM location_boundary WHERE location_id = ' || NEW.id;
  --RAISE NOTICE 'Refreshing boundary features for id % ...', NEW.id;

  -- if a boundary_id and feature_id are provided then get a centroid of the requested feature to serve as the point
  -- locations can be polygons by making an association to an existing boundary feature
  IF (SELECT * FROM pmt_validate_boundary_feature(NEW.boundary_id, NEW.feature_id)) THEN
    SELECT INTO spatialtable _spatial_table FROM boundary b WHERE _active = true AND b.id = NEW.boundary_id;
    -- get centroid and assign as NEW._point
    execute_statement := 'SELECT ST_Transform(ST_Centroid((SELECT _polygon FROM ' || quote_ident(spatialtable) || ' WHERE id = ' || NEW.feature_id || ' LIMIT 1)),4326)' ;
    EXECUTE execute_statement INTO centroid;
    IF (centroid IS NOT NULL) THEN	      
      NEW._point := centroid;
      -- RAISE NOTICE 'Centroid of boundary assigned';
    END IF;
  END IF; 

  -- if a point is provided or assigned above then find all the boundary features 
  -- that are intersected by the point
  IF (NEW._point IS NOT NULL) THEN
    -- loop through each available boundary
    FOR boundary IN SELECT * FROM boundary LOOP
      -- find the feature in the boundary, interescted by our point
      FOR feature IN EXECUTE 'SELECT * FROM ' || quote_ident(boundary._spatial_table)  || ' WHERE ST_Intersects(ST_PointFromText(''' || 
		ST_AsText(NEW._point) || ''', 4326), _polygon)' LOOP
	-- for each intersected feature, record its values in the location_boundary table
	EXECUTE 'INSERT INTO location_boundary VALUES (' || NEW.id || ', ' || feature.boundary_id || ', ' || feature.id || ', ' || 
		ST_Area(feature._polygon) || ', ' || quote_literal(feature._name) || ')';
	-- assign all associated taxonomy classification from intersected features to new location
	FOR ft IN (SELECT * FROM feature_taxonomy WHERE feature_id = feature.id) LOOP
	  -- replace all previous taxonomy classification associations with new for the given taxonomy
	  DELETE FROM location_taxonomy WHERE location_id = NEW.id AND classification_id IN 
		(SELECT classification_id FROM _taxonomy_classifications WHERE taxonomy_id = (SELECT taxonomy_id FROM classification WHERE classification.id = ft.classification_id));    
	  INSERT INTO location_taxonomy VALUES (NEW.id, ft.classification_id, 'id');
	END LOOP;
      END LOOP;	
    END LOOP;
  END IF;

RETURN NEW;

END;
$pmt_upd_boundary_features$ LANGUAGE plpgsql; 
DROP TRIGGER IF EXISTS pmt_upd_boundary_features ON location;
CREATE TRIGGER pmt_upd_boundary_features AFTER INSERT OR UPDATE ON location
    FOR EACH ROW EXECUTE PROCEDURE pmt_upd_boundary_features();

-- update all location_boundary entries
UPDATE location SET _title = _title WHERE _active = true;

/*************************************************************************
  7. create new trigger on the version table to ease development
*************************************************************************/
CREATE OR REPLACE FUNCTION pmt_upd_version()
RETURNS trigger AS $pmt_upd_version$
DECLARE
  version_record record; -- the latest version record matching NEW
BEGIN
  SELECT INTO version_record * FROM version WHERE _version = NEW._version AND _iteration = NEW._iteration AND _changeset = NEW._changeset ORDER BY id DESC LIMIT 1;
  IF version_record IS NOT NULL THEN
    UPDATE version SET _updated_date = current_date WHERE id = version_record.id;
    RETURN NULL;
  ELSE
    RETURN NEW;
  END IF;
END;
$pmt_upd_version$ LANGUAGE plpgsql; 
DROP TRIGGER IF EXISTS pmt_upd_version ON version;
CREATE TRIGGER pmt_upd_version BEFORE INSERT ON version
    FOR EACH ROW EXECUTE PROCEDURE pmt_upd_version();

/*************************************************************************
  8. create missing taxonomy table detail_taxonomy
*************************************************************************/
CREATE TABLE "detail_taxonomy"
(
	"detail_id"		integer				NOT NULL
	,"classification_id"	integer				NOT NULL
	,"field"		character varying(50)		NULL
	,CONSTRAINT detail_taxonomy_id PRIMARY KEY(detail_id,classification_id,field)
);

/*************************************************************************
  9. create updated_date trigger on all tables to manage update datestamps
*************************************************************************/
-- activity
CREATE OR REPLACE FUNCTION pmt_upd_activity_updated() RETURNS trigger AS $$
BEGIN
    NEW._updated_date = current_date;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql; 
DROP TRIGGER IF EXISTS pmt_upd_activity_updated ON activity;
CREATE TRIGGER pmt_upd_activity_updated BEFORE UPDATE ON activity
    FOR EACH ROW EXECUTE PROCEDURE pmt_upd_activity_updated();
-- boundary
CREATE OR REPLACE FUNCTION pmt_upd_boundary_updated() RETURNS trigger AS $$
BEGIN
    NEW._updated_date = current_date;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql; 
DROP TRIGGER IF EXISTS pmt_upd_boundary_updated ON boundary;
CREATE TRIGGER pmt_upd_boundary_updated BEFORE UPDATE ON boundary
    FOR EACH ROW EXECUTE PROCEDURE pmt_upd_boundary_updated();    
-- classification
CREATE OR REPLACE FUNCTION pmt_upd_classification_updated() RETURNS trigger AS $$
BEGIN
    NEW._updated_date = current_date;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql; 
DROP TRIGGER IF EXISTS pmt_upd_classification_updated ON classification;
CREATE TRIGGER pmt_upd_classification_updated BEFORE UPDATE ON classification
    FOR EACH ROW EXECUTE PROCEDURE pmt_upd_classification_updated();   
-- config
CREATE OR REPLACE FUNCTION pmt_upd_config_updated() RETURNS trigger AS $$
BEGIN
    NEW._updated_date = current_date;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql; 
DROP TRIGGER IF EXISTS pmt_upd_config_updated ON config;
CREATE TRIGGER pmt_upd_config_updated BEFORE UPDATE ON config
    FOR EACH ROW EXECUTE PROCEDURE pmt_upd_config_updated();            
-- contact
CREATE OR REPLACE FUNCTION pmt_upd_contact_updated() RETURNS trigger AS $$
BEGIN
    NEW._updated_date = current_date;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql; 
DROP TRIGGER IF EXISTS pmt_upd_contact_updated ON contact;
CREATE TRIGGER pmt_upd_contact_updated BEFORE UPDATE ON contact
    FOR EACH ROW EXECUTE PROCEDURE pmt_upd_contact_updated();
-- detail
CREATE OR REPLACE FUNCTION pmt_upd_detail_updated() RETURNS trigger AS $$
BEGIN
    NEW._updated_date = current_date;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql; 
DROP TRIGGER IF EXISTS pmt_upd_detail_updated ON detail;
CREATE TRIGGER pmt_upd_detail_updated BEFORE UPDATE ON detail
    FOR EACH ROW EXECUTE PROCEDURE pmt_upd_detail_updated();           
-- financial
CREATE OR REPLACE FUNCTION pmt_upd_financial_updated() RETURNS trigger AS $$
BEGIN
    NEW._updated_date = current_date;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql; 
DROP TRIGGER IF EXISTS pmt_upd_financial_updated ON financial;
CREATE TRIGGER pmt_upd_financial_updated BEFORE UPDATE ON financial
    FOR EACH ROW EXECUTE PROCEDURE pmt_upd_financial_updated();
-- location
CREATE OR REPLACE FUNCTION pmt_upd_location_updated() RETURNS trigger AS $$
BEGIN
    NEW._updated_date = current_date;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql; 
DROP TRIGGER IF EXISTS pmt_upd_location_updated ON location;
CREATE TRIGGER pmt_upd_location_updated BEFORE UPDATE ON location
    FOR EACH ROW EXECUTE PROCEDURE pmt_upd_location_updated();    
-- map
CREATE OR REPLACE FUNCTION pmt_upd_map_updated() RETURNS trigger AS $$
BEGIN
    NEW._updated_date = current_date;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql; 
DROP TRIGGER IF EXISTS pmt_upd_map_updated ON map;
CREATE TRIGGER pmt_upd_map_updated BEFORE UPDATE ON map
    FOR EACH ROW EXECUTE PROCEDURE pmt_upd_map_updated();  
-- organization
CREATE OR REPLACE FUNCTION pmt_upd_organization_updated() RETURNS trigger AS $$
BEGIN
    NEW._updated_date = current_date;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql; 
DROP TRIGGER IF EXISTS pmt_upd_organization_updated ON organization;
CREATE TRIGGER pmt_upd_organization_updated BEFORE UPDATE ON organization
    FOR EACH ROW EXECUTE PROCEDURE pmt_upd_organization_updated();   
-- participation
CREATE OR REPLACE FUNCTION pmt_upd_participation_updated() RETURNS trigger AS $$
BEGIN
    NEW._updated_date = current_date;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql; 
DROP TRIGGER IF EXISTS pmt_upd_participation_updated ON participation;
CREATE TRIGGER pmt_upd_participation_updated BEFORE UPDATE ON participation
    FOR EACH ROW EXECUTE PROCEDURE pmt_upd_participation_updated();     
-- result
CREATE OR REPLACE FUNCTION pmt_upd_result_updated() RETURNS trigger AS $$
BEGIN
    NEW._updated_date = current_date;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql; 
DROP TRIGGER IF EXISTS pmt_upd_result_updated ON result;
CREATE TRIGGER pmt_upd_result_updated BEFORE UPDATE ON result
    FOR EACH ROW EXECUTE PROCEDURE pmt_upd_result_updated();       
-- role
CREATE OR REPLACE FUNCTION pmt_upd_role_updated() RETURNS trigger AS $$
BEGIN
    NEW._updated_date = current_date;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql; 
DROP TRIGGER IF EXISTS pmt_upd_role_updated ON role;
CREATE TRIGGER pmt_upd_role_updated BEFORE UPDATE ON role
    FOR EACH ROW EXECUTE PROCEDURE pmt_upd_role_updated();   
-- taxonomy
CREATE OR REPLACE FUNCTION pmt_upd_taxonomy_updated() RETURNS trigger AS $$
BEGIN
    NEW._updated_date = current_date;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql; 
DROP TRIGGER IF EXISTS pmt_upd_taxonomy_updated ON taxonomy;
CREATE TRIGGER pmt_upd_taxonomy_updated BEFORE UPDATE ON taxonomy
    FOR EACH ROW EXECUTE PROCEDURE pmt_upd_taxonomy_updated();               
-- taxonomy_xwalk
CREATE OR REPLACE FUNCTION pmt_upd_taxonomy_xwalk_updated() RETURNS trigger AS $$
BEGIN
    NEW._updated_date = current_date;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql; 
DROP TRIGGER IF EXISTS pmt_upd_taxonomy_xwalk_updated ON taxonomy_xwalk;
CREATE TRIGGER pmt_upd_taxonomy_xwalk_updated BEFORE UPDATE ON taxonomy_xwalk
    FOR EACH ROW EXECUTE PROCEDURE pmt_upd_taxonomy_xwalk_updated();         
-- user_activity_role
CREATE OR REPLACE FUNCTION pmt_upd_user_activity_role_updated() RETURNS trigger AS $$
BEGIN
    NEW._updated_date = current_date;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql; 
DROP TRIGGER IF EXISTS pmt_upd_user_activity_role_updated ON user_activity_role;
CREATE TRIGGER pmt_upd_user_activity_role_updated BEFORE UPDATE ON user_activity_role
    FOR EACH ROW EXECUTE PROCEDURE pmt_upd_user_activity_role_updated();    
-- users
CREATE OR REPLACE FUNCTION pmt_upd_users_updated() RETURNS trigger AS $$
BEGIN
    NEW._updated_date = current_date;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql; 
DROP TRIGGER IF EXISTS pmt_upd_users_updated ON users;
CREATE TRIGGER pmt_upd_users_updated BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE PROCEDURE pmt_upd_users_updated();                