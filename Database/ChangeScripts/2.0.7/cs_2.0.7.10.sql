/******************************************************************
Change Script 2.0.7.10 - Consolidated.
1. converting all lookup tables to materialized views.
******************************************************************/
INSERT INTO config(version, iteration, changeset) VALUES (2.0, 7, 10);
-- select * from config order by version, iteration, changeset, updated_date;

DROP TABLE IF EXISTS location_lookup CASCADE;
DROP TABLE IF EXISTS organization_lookup CASCADE;
DROP TABLE IF EXISTS taxonomy_lookup CASCADE;

-- DROP MATERIALIZED VIEW IF EXISTS location_lookup;
-- DROP MATERIALIZED VIEW IF EXISTS organization_lookup;
-- DROP MATERIALIZED VIEW IF EXISTS taxonomy_lookup;

CREATE INDEX activity_taxonomy_activity_id_idx on activity_taxonomy(activity_id);
CREATE INDEX contact_taxonomy_contact_id_idx on contact_taxonomy(contact_id);
CREATE INDEX feature_taxonomy_feature_id_idx on feature_taxonomy(feature_id);
CREATE INDEX financial_taxonomy_financial_id_idx on financial_taxonomy(financial_id);
CREATE INDEX location_taxonomy_location_id_idx on location_taxonomy(location_id);
CREATE INDEX location_taxonomy_classification_id_idx on location_taxonomy(classification_id);
CREATE INDEX organization_taxonomy_organization_id_idx on organization_taxonomy(organization_id);
CREATE INDEX participation_taxonomy_participation_id_idx on participation_taxonomy(participation_id);
CREATE INDEX project_taxonomy_project_id_idx on project_taxonomy(project_id);
CREATE INDEX result_taxonomy_result_id_idx on result_taxonomy(result_id);

CREATE MATERIALIZED VIEW taxonomy_lookup AS
(SELECT project_id, activity_id, location_id, organization_id, participation_id, start_date, end_date, x, y, georef, t.taxonomy_id, foo.classification_id
FROM(SELECT pa.project_id, pa.activity_id, pa.location_id, pa.organization_id, pa.participation_id, pa.activity_start as start_date, pa.activity_end as end_date, pa.x, pa.y, pa.georef, pt.classification_id
FROM active_project_activities pa
JOIN project_taxonomy pt
ON pa.project_id = pt.project_id AND field ='project_id'
UNION
SELECT pa.project_id, pa.activity_id, pa.location_id, pa.organization_id, pa.participation_id, pa.activity_start as start_date, pa.activity_end as end_date, pa.x, pa.y, pa.georef, at.classification_id
FROM active_project_activities pa
JOIN activity_taxonomy at
ON pa.activity_id = at.activity_id AND field ='activity_id'
UNION
SELECT pa.project_id, pa.activity_id, pa.location_id, pa.organization_id, pa.participation_id, pa.activity_start as start_date, pa.activity_end as end_date, pa.x, pa.y, pa.georef, lt.classification_id
FROM active_project_activities pa
JOIN location_taxonomy lt
ON pa.location_id = lt.location_id AND field ='location_id'
UNION
SELECT pa.project_id, pa.activity_id, pa.location_id, pa.organization_id, pa.participation_id, pa.activity_start as start_date, pa.activity_end as end_date, pa.x, pa.y, pa.georef, ot.classification_id 
FROM active_project_activities pa
JOIN organization_taxonomy ot
ON pa.organization_id = ot.organization_id AND field ='organization_id'
UNION
SELECT pa.project_id, pa.activity_id, pa.location_id, pa.organization_id, pa.participation_id, pa.activity_start as start_date, pa.activity_end as end_date, pa.x, pa.y, pa.georef, pt.classification_id
FROM active_project_activities pa
JOIN participation_taxonomy pt
ON pa.participation_id = pt.participation_id AND field ='participation_id'
) as foo
JOIN classification c
ON foo.classification_id = c.classification_id
JOIN taxonomy t
ON c.taxonomy_id = t.taxonomy_id);

-- Create index for taxonomy_lookup
CREATE INDEX taxonomy_lookup_project_id_idx on taxonomy_lookup(project_id);
CREATE INDEX taxonomy_lookup_activity_id_idx on taxonomy_lookup(activity_id);
CREATE INDEX taxonomy_lookup_location_id_idx on taxonomy_lookup(location_id);
CREATE INDEX taxonomy_lookup_organization_id_idx on taxonomy_lookup(organization_id);
CREATE INDEX taxonomy_lookup_participation_id_idx on taxonomy_lookup(participation_id);
CREATE INDEX taxonomy_lookup_start_date_idx on taxonomy_lookup(start_date);
CREATE INDEX taxonomy_lookup_end_date_idx on taxonomy_lookup(end_date);
CREATE INDEX taxonomy_lookup_classification_id_idx on taxonomy_lookup(classification_id);
CREATE INDEX taxonomy_lookup_taxonomy_id_idx on taxonomy_lookup(taxonomy_id);

CREATE MATERIALIZED VIEW location_lookup AS
(SELECT project_id, activity_id, location_id, start_date, end_date, x, y, georef, array_agg(distinct taxonomy_id) as taxonomy_ids, array_agg(distinct classification_id) as classification_ids, array_agg(distinct organization_id) as organization_ids,
(SELECT lbf.name FROM location_boundary_features lbf WHERE taxonomy_lookup.location_id = lbf.location_id AND lbf.boundary_id = 1 LIMIT 1) as gaul0_name,
(SELECT lbf.name FROM location_boundary_features lbf WHERE taxonomy_lookup.location_id = lbf.location_id AND lbf.boundary_id = 2 LIMIT 1) as gaul1_name,
(SELECT lbf.name FROM location_boundary_features lbf WHERE taxonomy_lookup.location_id = lbf.location_id AND lbf.boundary_id = 3 LIMIT 1) as gaul2_name
FROM taxonomy_lookup
GROUP BY project_id, activity_id, location_id, start_date, end_date, x, y, georef);

CREATE MATERIALIZED VIEW organization_lookup AS
(SELECT project_id, activity_id, organization_id, start_date, end_date, array_agg(distinct taxonomy_id) as taxonomy_ids, array_agg(distinct classification_id) as classification_ids, array_agg(distinct location_id) as location_ids
FROM taxonomy_lookup
GROUP BY project_id, activity_id, organization_id, start_date, end_date);		

-- Create index for organization_lookup
CREATE INDEX organization_lookup_project_id_idx on organization_lookup(project_id);
CREATE INDEX organization_lookup_activity_id_idx on organization_lookup(activity_id);
CREATE INDEX organization_lookup_location_id_idx on organization_lookup(organization_id);
CREATE INDEX organization_lookup_start_date_idx on organization_lookup(start_date);
CREATE INDEX organization_lookup_end_date_idx on organization_lookup(end_date);

-- Create index for location_lookup
CREATE INDEX location_lookup_project_id_idx on location_lookup(project_id);
CREATE INDEX location_lookup_activity_id_idx on location_lookup(activity_id);
CREATE INDEX location_lookup_location_id_idx on location_lookup(location_id);
CREATE INDEX location_lookup_start_date_idx on location_lookup(start_date);
CREATE INDEX location_lookup_end_date_idx on location_lookup(end_date);
CREATE INDEX location_lookup_gaul0_name_idx on location_lookup(gaul0_name);
CREATE INDEX location_lookup_gaul1_name_idx on location_lookup(gaul1_name);
CREATE INDEX location_lookup_gaul2_name_idx on location_lookup(gaul2_name);

-- select * from refresh_taxonomy_lookup();
-- function to support the taxonomy_lookup table
CREATE OR REPLACE FUNCTION refresh_taxonomy_lookup() RETURNS integer AS $$
BEGIN
    RAISE NOTICE 'Refreshing lookup views...';
    REFRESH MATERIALIZED VIEW taxonomy_lookup;
    REFRESH MATERIALIZED VIEW location_lookup;  
    REFRESH MATERIALIZED VIEW organization_lookup;
    RAISE NOTICE 'Done refreshing lookup views.';
    RETURN 1;
END;
$$ LANGUAGE plpgsql;

-- update permissions
GRANT USAGE ON SCHEMA public TO pmt_read;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO pmt_read;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO pmt_read;
GRANT USAGE ON SCHEMA public TO pmt_write;
GRANT SELECT,INSERT ON ALL TABLES IN SCHEMA public TO pmt_write;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO pmt_write;