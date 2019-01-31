/******************************************************************
Change Script 2.0.6.14 - Consolidated

1. active_project_activities -  updating view to remove reporting_org
organizations, so they will be removed from the lookup tables.
******************************************************************/
UPDATE config SET changeset = 14, updated_date = current_date WHERE "version" = 2.0 AND iteration = 6;
-- SELECT pmt_version();

-- alter view
CREATE OR REPLACE VIEW active_project_activities
AS SELECT DISTINCT * FROM
(SELECT DISTINCT p.project_id as project_id, a.activity_id as activity_id, l.location_id as location_id, pp.organization_id as organization_id, pp.participation_id as participation_id, a.start_date as activity_start, a.end_date as activity_end
, l.x,l.y, l.georef as georef
FROM project p
JOIN activity a
ON p.project_id = a.project_id
JOIN location l
ON a.activity_id = l.activity_id
JOIN participation pp
ON (p.project_id = pp.project_id AND pp.activity_id IS NULL) 
WHERE a.active = true and p.active = true and l.active = true and pp.reporting_org = false
UNION 
SELECT DISTINCT p.project_id as project_id, a.activity_id as activity_id, l.location_id as location_id, pp.organization_id as organization_id, pp.participation_id as participation_id, a.start_date as activity_start, a.end_date as activity_end
, l.x,l.y, l.georef as georef
FROM project p
JOIN activity a
ON p.project_id = a.project_id
JOIN location l
ON a.activity_id = l.activity_id
JOIN participation pp
ON (p.project_id = pp.project_id AND a.activity_id = pp.activity_id)
WHERE a.active = true and p.active = true and l.active = true  and pp.reporting_org = false ) as foo
ORDER BY project_id, activity_id, location_id, organization_id;

-- refresh
select * from refresh_taxonomy_lookup();
vacuum;
analyze;

-- test
select * from pmt_org_inuse(null);