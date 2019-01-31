/******************************************************************
Change Script 3.0.10.62
1. remove the map table from _data_loading_report view
2. remove map table
3. update _active_activities view to remove location fields
4. remove location fields: _georef, _geographic_id, _geographic_level
5. add location fields: _admin0, _admin_level
6. temp drop location triggers: pmt_upd_boundary_features & pmt_upd_geometry_formats
******************************************************************/
INSERT INTO version(_version, _iteration, _changeset) VALUES (3.0, 10, 62);
-- select * from version order by _iteration desc, _changeset desc;

/******************************************************************
1. remove the map table from _data_loading_report view
******************************************************************/
DROP VIEW _data_loading_report;
CREATE OR REPLACE VIEW _data_loading_report AS 
 SELECT 'activity'::text AS "table",
    count(*) AS "total record count",
    ( SELECT count(*) AS count
           FROM activity activity_1
          WHERE activity_1._active = true) AS "active record count",
    0 AS "core PMT count",
    ''::text AS comments
   FROM activity
UNION ALL
 SELECT 'activity_contact'::text AS "table",
    count(*) AS "total record count",
    ( SELECT count(*) AS count
           FROM activity_contact activity_contact_1) AS "active record count",
    0 AS "core PMT count",
    ''::text AS comments
   FROM activity_contact
UNION ALL
 SELECT 'activity_taxonomy'::text AS "table",
    count(*) AS "total record count",
    ( SELECT count(*) AS count
           FROM activity_taxonomy activity_taxonomy_1) AS "active record count",
    0 AS "core PMT count",
    ''::text AS comments
   FROM activity_taxonomy
UNION ALL
 SELECT 'boundary'::text AS "table",
    count(*) AS "total record count",
    ( SELECT count(*) AS count
           FROM boundary boundary_1
          WHERE boundary_1._active = true) AS "active record count",
    3 AS "core PMT count",
    'Correct count reflects minimum count on default PMT install.'::text AS comments
   FROM boundary
UNION ALL
 SELECT 'boundary_taxonomy'::text AS "table",
    count(*) AS "total record count",
    ( SELECT count(*) AS count
           FROM boundary_taxonomy boundary_taxonomy_1) AS "active record count",
    0 AS "core PMT count",
    ''::text AS comments
   FROM boundary_taxonomy
UNION ALL
 SELECT 'config'::text AS "table",
    count(*) AS "total record count",
    ( SELECT count(*) AS count
           FROM config config_1) AS "active record count",
    1 AS "core PMT count",
    'PMT system table.'::text AS comments
   FROM config
UNION ALL
 SELECT 'contact'::text AS "table",
    count(*) AS "total record count",
    ( SELECT count(*) AS count
           FROM contact contact_1
          WHERE contact_1._active = true) AS "active record count",
    0 AS "core PMT count",
    ''::text AS comments
   FROM contact
UNION ALL
 SELECT 'contact_taxonomy'::text AS "table",
    count(*) AS "total record count",
    ( SELECT count(*) AS count
           FROM contact_taxonomy contact_taxonomy_1) AS "active record count",
    0 AS "core PMT count",
    ''::text AS comments
   FROM contact_taxonomy
UNION ALL
 SELECT 'detail'::text AS "table",
    count(*) AS "total record count",
    ( SELECT count(*) AS count
           FROM detail detail_1
          WHERE detail_1._active = true) AS "active record count",
    0 AS "core PMT count",
    ''::text AS comments
   FROM detail
UNION ALL
 SELECT 'feature_taxonomy'::text AS "table",
    count(*) AS "total record count",
    ( SELECT count(*) AS count
           FROM feature_taxonomy feature_taxonomy_1) AS "active record count",
    277 AS "core PMT count",
    'Correct count reflects minimum count on default PMT install.'::text AS comments
   FROM feature_taxonomy
UNION ALL
 SELECT 'financial'::text AS "table",
    count(*) AS "total record count",
    ( SELECT count(*) AS count
           FROM financial financial_1
          WHERE financial_1._active = true) AS "active record count",
    0 AS "core PMT count",
    ''::text AS comments
   FROM financial
UNION ALL
 SELECT 'financial_taxonomy'::text AS "table",
    count(*) AS "total record count",
    ( SELECT count(*) AS count
           FROM financial_taxonomy financial_taxonomy_1) AS "active record count",
    0 AS "core PMT count",
    ''::text AS comments
   FROM financial_taxonomy
UNION ALL
 SELECT 'gaul0'::text AS "table",
    count(*) AS "total record count",
    ( SELECT count(*) AS count
           FROM gaul0 gaul0_1
          WHERE gaul0_1._active = true) AS "active record count",
    277 AS "core PMT count",
    'Core count reflects minimum count on default PMT install.'::text AS comments
   FROM gaul0
UNION ALL
 SELECT 'gaul1'::text AS "table",
    count(*) AS "total record count",
    ( SELECT count(*) AS count
           FROM gaul1 gaul1_1
          WHERE gaul1_1._active = true) AS "active record count",
    3469 AS "core PMT count",
    'Core count reflects minimum count on default PMT install.'::text AS comments
   FROM gaul1
UNION ALL
 SELECT 'gaul2'::text AS "table",
    count(*) AS "total record count",
    ( SELECT count(*) AS count
           FROM gaul2 gaul2_1
          WHERE gaul2_1._active = true) AS "active record count",
    37378 AS "core PMT count",
    'Core count reflects minimum count on default PMT install.'::text AS comments
   FROM gaul2
UNION ALL
 SELECT 'location'::text AS "table",
    count(*) AS "total record count",
    ( SELECT count(*) AS count
           FROM location location_1
          WHERE location_1._active = true) AS "active record count",
    0 AS "core PMT count",
    ''::text AS comments
   FROM location
UNION ALL
 SELECT 'location_boundary'::text AS "table",
    count(*) AS "total record count",
    ( SELECT count(*) AS count
           FROM location_boundary location_boundary_1) AS "active record count",
    0 AS "core PMT count",
    ''::text AS comments
   FROM location_boundary
UNION ALL
 SELECT 'location_taxonomy'::text AS "table",
    count(*) AS "total record count",
    ( SELECT count(*) AS count
           FROM location_taxonomy location_taxonomy_1) AS "active record count",
    0 AS "core PMT count",
    ''::text AS comments
   FROM location_taxonomy
UNION ALL
 SELECT 'organization'::text AS "table",
    count(*) AS "total record count",
    ( SELECT count(*) AS count
           FROM organization organization_1
          WHERE organization_1._active = true) AS "active record count",
    0 AS "core PMT count",
    ''::text AS comments
   FROM organization
UNION ALL
 SELECT 'organization_taxonomy'::text AS "table",
    count(*) AS "total record count",
    ( SELECT count(*) AS count
           FROM organization_taxonomy organization_taxonomy_1) AS "active record count",
    0 AS "core PMT count",
    ''::text AS comments
   FROM organization_taxonomy
UNION ALL
 SELECT 'participation'::text AS "table",
    count(*) AS "total record count",
    ( SELECT count(*) AS count
           FROM participation participation_1
          WHERE participation_1._active = true) AS "active record count",
    0 AS "core PMT count",
    ''::text AS comments
   FROM participation
UNION ALL
 SELECT 'participation_taxonomy'::text AS "table",
    count(*) AS "total record count",
    ( SELECT count(*) AS count
           FROM participation_taxonomy participation_taxonomy_1) AS "active record count",
    0 AS "core PMT count",
    ''::text AS comments
   FROM participation_taxonomy
UNION ALL
 SELECT 'result'::text AS "table",
    count(*) AS "total record count",
    ( SELECT count(*) AS count
           FROM result result_1
          WHERE result_1._active = true) AS "active record count",
    0 AS "core PMT count",
    ''::text AS comments
   FROM result
UNION ALL
 SELECT 'result_taxonomy'::text AS "table",
    count(*) AS "total record count",
    ( SELECT count(*) AS count
           FROM result_taxonomy result_taxonomy_1) AS "active record count",
    0 AS "core PMT count",
    ''::text AS comments
   FROM result_taxonomy
UNION ALL
 SELECT 'role'::text AS "table",
    count(*) AS "total record count",
    ( SELECT count(*) AS count
           FROM role role_1
          WHERE role_1._active = true) AS "active record count",
    4 AS "core PMT count",
    'Core count reflects minimum count on default PMT install.'::text AS comments
   FROM role
UNION ALL
 SELECT 'taxonomy_xwalk'::text AS "table",
    count(*) AS "total record count",
    ( SELECT count(*) AS count
           FROM taxonomy_xwalk taxonomy_xwalk_1
          WHERE taxonomy_xwalk_1._active = true) AS "active record count",
    0 AS "core PMT count",
    'Core count reflects minimum count on default PMT install.'::text AS comments
   FROM taxonomy_xwalk
UNION ALL
 SELECT 'user_activity_role'::text AS "table",
    count(*) AS "total record count",
    ( SELECT count(*) AS count
           FROM user_activity_role user_activity_role_1
          WHERE user_activity_role_1._active = true) AS "active record count",
    0 AS "core PMT count",
    ''::text AS comments
   FROM user_activity_role
UNION ALL
 SELECT 'user_log'::text AS "table",
    count(*) AS "total record count",
    ( SELECT count(*) AS count
           FROM user_log user_log_1) AS "active record count",
    0 AS "core PMT count",
    ''::text AS comments
   FROM user_log
UNION ALL
 SELECT 'users'::text AS "table",
    count(*) AS "total record count",
    ( SELECT count(*) AS count
           FROM users users_1
          WHERE users_1._active = true) AS "active record count",
    0 AS "core PMT count",
    ''::text AS comments
   FROM users
UNION ALL
 SELECT 'version'::text AS "table",
    count(*) AS "total record count",
    ( SELECT count(*) AS count
           FROM version version_1) AS "active record count",
    0 AS "core PMT count",
    'PMT system table.'::text AS comments
   FROM version
UNION ALL
 SELECT 'classification'::text AS "table",
    count(*) AS "total record count",
    ( SELECT count(*) AS count
           FROM classification classification_1
          WHERE classification_1._active = true) AS "active record count",
    1657 AS "core PMT count",
    'Core count reflects minimum count on default PMT install.'::text AS comments
   FROM classification
UNION ALL
 SELECT 'taxonomy'::text AS "table",
    count(*) AS "total record count",
    ( SELECT count(*) AS count
           FROM taxonomy taxonomy_1
          WHERE taxonomy_1._active = true) AS "active record count",
    22 AS "core PMT count",
    'Core count reflects minimum count on default PMT install.'::text AS comments
   FROM taxonomy;
   
/******************************************************************
2. remove the map table
******************************************************************/
DROP TABLE map;

/******************************************************************
3. update _active_activities view to remove location fields
******************************************************************/
DROP VIEW IF EXISTS _active_activities;
CREATE OR REPLACE VIEW _active_activities AS 
 SELECT DISTINCT a.id AS activity_id,
    a.data_group_id,
    l.id AS location_id,
    pp.organization_id,
    pp.id AS participation_id,
    a._start_date,
    a._end_date,
    l._x,
    l._y
   FROM activity a
     JOIN location l ON a.id = l.activity_id
     JOIN participation pp ON a.id = pp.activity_id
  WHERE a._active = true AND l._active = true AND pp._active = true
  ORDER BY a.id, l.id, pp.organization_id;
  
/******************************************************************
4. remove location fields: _georef, _geographic_id, _geographic_level
******************************************************************/
ALTER TABLE location DROP COLUMN _georef;
ALTER TABLE location DROP COLUMN _geographic_id;
ALTER TABLE location DROP COLUMN _geographic_level;

/******************************************************************
5. add location fields: _admin0, _admin_level
******************************************************************/
ALTER TABLE location ADD COLUMN _admin0 character varying;
ALTER TABLE location ADD COLUMN _admin_level integer;
 
/******************************************************************
6. temp drop location triggers: pmt_upd_boundary_features & 
pmt_upd_geometry_formats
******************************************************************/
DROP TRIGGER pmt_upd_boundary_features ON location;
DROP TRIGGER pmt_upd_geometry_formats ON location;
   
-- update permissions
GRANT USAGE ON SCHEMA public TO pmt_read;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO pmt_read;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO pmt_read;
GRANT USAGE ON SCHEMA public TO pmt_write;
GRANT SELECT,INSERT ON ALL TABLES IN SCHEMA public TO pmt_write;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO pmt_write;