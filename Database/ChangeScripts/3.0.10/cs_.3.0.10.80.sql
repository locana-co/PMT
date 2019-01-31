/******************************************************************
Change Script 3.0.10.80
1. update the _data_change_report to include new tables
******************************************************************/
INSERT INTO version(_version, _iteration, _changeset) VALUES (3.0, 10, 80);
-- select * from version order by _iteration desc, _changeset desc;

/******************************************************************
1. update the _data_change_report to include new tables
  select * from _data_change_report
******************************************************************/
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
-- boundary
SELECT distinct _created_by as script, 'create' as action, 'boundary' as entity, _created_date::timestamp::date as date
FROM boundary
WHERE _created_by  NOT IN ('PMT 1.0 Record')
UNION ALL 
SELECT distinct _updated_by as script, 'update' as action, 'boundary' as entity, _updated_date::timestamp::date as date
FROM boundary
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
-- contact
SELECT distinct _created_by as script, 'create' as action, 'contact' as entity, _created_date::timestamp::date as date
FROM contact
WHERE _created_by  NOT IN ('PMT 1.0 Record')
UNION ALL 
SELECT distinct _updated_by as script, 'update' as action, 'contact' as entity, _updated_date::timestamp::date as date
FROM contact
WHERE _updated_by  NOT IN ('PMT 1.0 Record')
UNION ALL
-- continent
SELECT distinct _created_by as script, 'create' as action, 'continent' as entity, _created_date::timestamp::date as date
FROM continent
WHERE _created_by  NOT IN ('PMT 1.0 Record')
UNION ALL 
SELECT distinct _updated_by as script, 'update' as action, 'continent' as entity, _updated_date::timestamp::date as date
FROM continent
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
-- gadm0
SELECT distinct _created_by as script, 'create' as action, 'gadm0' as entity, _created_date::timestamp::date as date
FROM gadm0
WHERE _created_by  NOT IN ('PMT 1.0 Record')
UNION ALL 
SELECT distinct _updated_by as script, 'update' as action, 'gadm0' as entity, _updated_date::timestamp::date as date
FROM gadm0
WHERE _updated_by  NOT IN ('PMT 1.0 Record')
UNION ALL
-- gadm1
SELECT distinct _created_by as script, 'create' as action, 'gadm1' as entity, _created_date::timestamp::date as date
FROM gadm1
WHERE _created_by  NOT IN ('PMT 1.0 Record')
UNION ALL 
SELECT distinct _updated_by as script, 'update' as action, 'gadm1' as entity, _updated_date::timestamp::date as date
FROM gadm1
WHERE _updated_by  NOT IN ('PMT 1.0 Record')
UNION ALL
-- gadm2
SELECT distinct _created_by as script, 'create' as action, 'gadm2' as entity, _created_date::timestamp::date as date
FROM gadm2
WHERE _created_by  NOT IN ('PMT 1.0 Record')
UNION ALL 
SELECT distinct _updated_by as script, 'update' as action, 'gadm2' as entity, _updated_date::timestamp::date as date
FROM gadm2
WHERE _updated_by  NOT IN ('PMT 1.0 Record')
UNION ALL
-- gadm3
SELECT distinct _created_by as script, 'create' as action, 'gadm3' as entity, _created_date::timestamp::date as date
FROM gadm3
WHERE _created_by  NOT IN ('PMT 1.0 Record')
UNION ALL 
SELECT distinct _updated_by as script, 'update' as action, 'gadm3' as entity, _updated_date::timestamp::date as date
FROM gadm3
WHERE _updated_by  NOT IN ('PMT 1.0 Record')
UNION ALL
-- gaul0
SELECT distinct _created_by as script, 'create' as action, 'gaul0' as entity, _created_date::timestamp::date as date
FROM gaul0
WHERE _created_by  NOT IN ('PMT 1.0 Record')
UNION ALL 
SELECT distinct _updated_by as script, 'update' as action, 'gaul0' as entity, _updated_date::timestamp::date as date
FROM gaul0
WHERE _updated_by  NOT IN ('PMT 1.0 Record')
UNION ALL
-- gaul1
SELECT distinct _created_by as script, 'create' as action, 'gaul1' as entity, _created_date::timestamp::date as date
FROM gaul1
WHERE _created_by  NOT IN ('PMT 1.0 Record')
UNION ALL 
SELECT distinct _updated_by as script, 'update' as action, 'gaul1' as entity, _updated_date::timestamp::date as date
FROM gaul1
WHERE _updated_by  NOT IN ('PMT 1.0 Record')
UNION ALL
-- gaul2
SELECT distinct _created_by as script, 'create' as action, 'gaul2' as entity, _created_date::timestamp::date as date
FROM gaul2
WHERE _created_by  NOT IN ('PMT 1.0 Record')
UNION ALL 
SELECT distinct _updated_by as script, 'update' as action, 'gaul2' as entity, _updated_date::timestamp::date as date
FROM gaul2
WHERE _updated_by  NOT IN ('PMT 1.0 Record')
UNION ALL
-- iati_import
SELECT distinct _created_by as script, 'create' as action, 'iati_import' as entity, _created_date::timestamp::date as date
FROM iati_import
WHERE _created_by  NOT IN ('PMT 1.0 Record')
UNION ALL
-- instance
SELECT distinct _created_by as script, 'create' as action, 'instance' as entity, _created_date::timestamp::date as date
FROM instance
WHERE _created_by  NOT IN ('PMT 1.0 Record')
UNION ALL 
SELECT distinct _updated_by as script, 'update' as action, 'instance' as entity, _updated_date::timestamp::date as date
FROM instance
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
-- organization
SELECT distinct _created_by as script, 'create' as action, 'organization' as entity, _created_date::timestamp::date as date
FROM organization
WHERE _created_by  NOT IN ('PMT 1.0 Record')
UNION ALL 
SELECT distinct _updated_by as script, 'update' as action, 'organization' as entity, _updated_date::timestamp::date as date
FROM organization
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
-- result
SELECT distinct _created_by as script, 'create' as action, 'result' as entity, _created_date::timestamp::date as date
FROM result
WHERE _created_by  NOT IN ('PMT 1.0 Record')
UNION ALL 
SELECT distinct _updated_by as script, 'update' as action, 'result' as entity, _updated_date::timestamp::date as date
FROM result
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
-- stats_data
SELECT distinct _created_by as script, 'create' as action, 'stats_data' as entity, _created_date::timestamp::date as date
FROM stats_data
WHERE _created_by  NOT IN ('PMT 1.0 Record')
UNION ALL 
SELECT distinct _updated_by as script, 'update' as action, 'stats_data' as entity, _updated_date::timestamp::date as date
FROM stats_data
WHERE _updated_by  NOT IN ('PMT 1.0 Record')
UNION ALL
-- stats_metadata
SELECT distinct _created_by as script, 'create' as action, 'stats_metadata' as entity, _created_date::timestamp::date as date
FROM stats_metadata
WHERE _created_by  NOT IN ('PMT 1.0 Record')
UNION ALL 
SELECT distinct _updated_by as script, 'update' as action, 'stats_metadata' as entity, _updated_date::timestamp::date as date
FROM stats_metadata
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
-- taxonomy_xwalk
SELECT distinct _created_by as script, 'create' as action, 'taxonomy_xwalk' as entity, _created_date::timestamp::date as date
FROM taxonomy_xwalk
WHERE _created_by  NOT IN ('PMT 1.0 Record')
UNION ALL 
SELECT distinct _updated_by as script, 'update' as action, 'taxonomy_xwalk' as entity, _updated_date::timestamp::date as date
FROM taxonomy_xwalk
WHERE _updated_by  NOT IN ('PMT 1.0 Record')
UNION ALL
-- user_activity
SELECT distinct _created_by as script, 'create' as action, 'user_activity' as entity, _created_date::timestamp::date as date
FROM user_activity
WHERE _created_by  NOT IN ('PMT 1.0 Record')
UNION ALL 
SELECT distinct _updated_by as script, 'update' as action, 'user_activity' as entity, _updated_date::timestamp::date as date
FROM user_activity
WHERE _updated_by  NOT IN ('PMT 1.0 Record')
UNION ALL
-- user
SELECT distinct _created_by as script, 'create' as action, 'users' as entity, _created_date::timestamp::date as date
FROM "users"
WHERE _created_by  NOT IN ('PMT 1.0 Record')
UNION ALL 
SELECT distinct _updated_by as script, 'update' as action, 'users' as entity, _updated_date::timestamp::date as date
FROM "users"
WHERE _updated_by  NOT IN ('PMT 1.0 Record')
) ds
GROUP BY 1
ORDER BY 4 DESC, 1 DESC;