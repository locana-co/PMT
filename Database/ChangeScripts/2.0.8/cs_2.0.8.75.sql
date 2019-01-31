/******************************************************************
Change Script 2.0.8.75
1. data_change_report - new view to display a listing of all the 
data scripts run against the database.
******************************************************************/
INSERT INTO version(version, iteration, changeset) VALUES (2.0, 8, 75);
-- select * from version order by changeset desc;

-- SELECT * FROM data_change_report
CREATE OR REPLACE VIEW data_change_report
AS SELECT ds.script, array_to_string(array_agg(distinct ds.action), ',') as action, array_to_string(array_agg(distinct ds.entity), ',') as entity, MAX(ds.date) as date
FROM (
-- project
SELECT distinct created_by as script, 'create' as action, 'project' as entity, created_date::timestamp::date as date
FROM project
WHERE created_by  NOT IN ('PMT 1.0 Record')
UNION ALL
SELECT distinct updated_by as script, 'update' as action, 'project' as entity, updated_date::timestamp::date as date
FROM project
WHERE updated_by  NOT IN ('PMT 1.0 Record')
UNION ALL
-- activity
SELECT distinct created_by as script, 'create' as action, 'activity' as entity, created_date::timestamp::date as date
FROM activity
WHERE created_by  NOT IN ('PMT 1.0 Record')
UNION ALL 
SELECT distinct updated_by as script, 'update' as action, 'activity' as entity, updated_date::timestamp::date as date
FROM activity
WHERE updated_by  NOT IN ('PMT 1.0 Record')
UNION ALL
-- location
SELECT distinct created_by as script, 'create' as action, 'location' as entity, created_date::timestamp::date as date
FROM location
WHERE created_by  NOT IN ('PMT 1.0 Record')
UNION ALL 
SELECT distinct updated_by as script, 'update' as action, 'location' as entity, updated_date::timestamp::date as date
FROM location
WHERE updated_by  NOT IN ('PMT 1.0 Record')
UNION ALL
-- participation
SELECT distinct created_by as script, 'create' as action, 'participation' as entity, created_date::timestamp::date as date
FROM participation
WHERE created_by  NOT IN ('PMT 1.0 Record')
UNION ALL 
SELECT distinct updated_by as script, 'update' as action, 'participation' as entity, updated_date::timestamp::date as date
FROM participation
WHERE updated_by  NOT IN ('PMT 1.0 Record')
UNION ALL
-- boundary
SELECT distinct created_by as script, 'create' as action, 'boundary' as entity, created_date::timestamp::date as date
FROM boundary
WHERE created_by  NOT IN ('PMT 1.0 Record')
UNION ALL 
SELECT distinct updated_by as script, 'update' as action, 'boundary' as entity, updated_date::timestamp::date as date
FROM boundary
WHERE updated_by  NOT IN ('PMT 1.0 Record')
UNION ALL
-- contact
SELECT distinct created_by as script, 'create' as action, 'contact' as entity, created_date::timestamp::date as date
FROM contact
WHERE created_by  NOT IN ('PMT 1.0 Record')
UNION ALL 
SELECT distinct updated_by as script, 'update' as action, 'contact' as entity, updated_date::timestamp::date as date
FROM contact
WHERE updated_by  NOT IN ('PMT 1.0 Record')
UNION ALL
-- detail
SELECT distinct created_by as script, 'create' as action, 'detail' as entity, created_date::timestamp::date as date
FROM detail
WHERE created_by  NOT IN ('PMT 1.0 Record')
UNION ALL 
SELECT distinct updated_by as script, 'update' as action, 'detail' as entity, updated_date::timestamp::date as date
FROM detail
WHERE updated_by  NOT IN ('PMT 1.0 Record')
UNION ALL
-- financial
SELECT distinct created_by as script, 'create' as action, 'financial' as entity, created_date::timestamp::date as date
FROM financial
WHERE created_by  NOT IN ('PMT 1.0 Record')
UNION ALL 
SELECT distinct updated_by as script, 'update' as action, 'financial' as entity, updated_date::timestamp::date as date
FROM financial
WHERE updated_by  NOT IN ('PMT 1.0 Record')
UNION ALL
-- organization
SELECT distinct created_by as script, 'create' as action, 'organization' as entity, created_date::timestamp::date as date
FROM organization
WHERE created_by  NOT IN ('PMT 1.0 Record')
UNION ALL 
SELECT distinct updated_by as script, 'update' as action, 'organization' as entity, updated_date::timestamp::date as date
FROM organization
WHERE updated_by  NOT IN ('PMT 1.0 Record')
UNION ALL
-- result
SELECT distinct created_by as script, 'create' as action, 'result' as entity, created_date::timestamp::date as date
FROM result
WHERE created_by  NOT IN ('PMT 1.0 Record')
UNION ALL 
SELECT distinct updated_by as script, 'update' as action, 'result' as entity, updated_date::timestamp::date as date
FROM result
WHERE updated_by  NOT IN ('PMT 1.0 Record')
UNION ALL
-- classification
SELECT distinct created_by as script, 'create' as action, 'classification' as entity, created_date::timestamp::date as date
FROM classification
WHERE created_by  NOT IN ('PMT 1.0 Record')
UNION ALL 
SELECT distinct updated_by as script, 'update' as action, 'classification' as entity, updated_date::timestamp::date as date
FROM classification
WHERE updated_by  NOT IN ('PMT 1.0 Record')
UNION ALL
-- taxonomy
SELECT distinct created_by as script, 'create' as action, 'taxonomy' as entity, created_date::timestamp::date as date
FROM taxonomy
WHERE created_by  NOT IN ('PMT 1.0 Record')
UNION ALL 
SELECT distinct updated_by as script, 'update' as action, 'taxonomy' as entity, updated_date::timestamp::date as date
FROM taxonomy
WHERE updated_by  NOT IN ('PMT 1.0 Record')
UNION ALL
-- role
SELECT distinct created_by as script, 'create' as action, 'role' as entity, created_date::timestamp::date as date
FROM role
WHERE created_by  NOT IN ('PMT 1.0 Record')
UNION ALL 
SELECT distinct updated_by as script, 'update' as action, 'role' as entity, updated_date::timestamp::date as date
FROM role
WHERE updated_by  NOT IN ('PMT 1.0 Record')
UNION ALL
-- user
SELECT distinct created_by as script, 'create' as action, 'user' as entity, created_date::timestamp::date as date
FROM "user"
WHERE created_by  NOT IN ('PMT 1.0 Record')
UNION ALL 
SELECT distinct updated_by as script, 'update' as action, 'user' as entity, updated_date::timestamp::date as date
FROM "user"
WHERE updated_by  NOT IN ('PMT 1.0 Record')
UNION ALL
-- taxonomy_xwalk
SELECT distinct created_by as script, 'create' as action, 'taxonomy_xwalk' as entity, created_date::timestamp::date as date
FROM taxonomy_xwalk
WHERE created_by  NOT IN ('PMT 1.0 Record')
UNION ALL 
SELECT distinct updated_by as script, 'update' as action, 'taxonomy_xwalk' as entity, updated_date::timestamp::date as date
FROM taxonomy_xwalk
WHERE updated_by  NOT IN ('PMT 1.0 Record')
) ds
GROUP BY 1
ORDER BY 4 DESC, 1 DESC;

-- update permissions
GRANT USAGE ON SCHEMA public TO pmt_read;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO pmt_read;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO pmt_read;
GRANT USAGE ON SCHEMA public TO pmt_write;
GRANT SELECT,INSERT ON ALL TABLES IN SCHEMA public TO pmt_write;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO pmt_write;