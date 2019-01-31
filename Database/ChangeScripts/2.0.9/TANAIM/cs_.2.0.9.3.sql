/******************************************************************
Change Script 2.0.9.3
1. location_boundary_features - update to include new NBS boundary
2. tanaim_nbs - new view to compare nbs to gaul.
******************************************************************/
INSERT INTO version(version, iteration, changeset) VALUES (2.0, 9, 3);
-- select * from version order by iteration desc, changeset desc;

DROP MATERIALIZED VIEW location_lookup;
DROP VIEW location_boundary_features;

CREATE OR REPLACE VIEW location_boundary_features
AS SELECT l.location_id, l.activity_id, b.boundary_id, b.name as boundary_name, lb.feature_area, g0.name
FROM location l
JOIN location_boundary lb
ON l.location_id = lb.location_id
JOIN boundary b
ON lb.boundary_id = b.boundary_id
JOIN gaul0 g0
ON lb.feature_id = g0.feature_id AND lb.boundary_id = g0.boundary_id
--WHERE l.location_id = 123
UNION ALL
SELECT l.location_id, l.activity_id, b.boundary_id,  b.name as boundary_name, lb.feature_area, g1.name
FROM location l
JOIN location_boundary lb
ON l.location_id = lb.location_id
JOIN boundary b
ON lb.boundary_id = b.boundary_id
JOIN gaul1 g1
ON lb.feature_id = g1.feature_id AND lb.boundary_id = g1.boundary_id
--WHERE l.location_id = 123
UNION ALL
SELECT l.location_id, l.activity_id, b.boundary_id,  b.name as boundary_name, lb.feature_area, g2.name
FROM location l
JOIN location_boundary lb
ON l.location_id = lb.location_id
JOIN boundary b
ON lb.boundary_id = b.boundary_id
JOIN gaul2 g2
ON lb.feature_id = g2.feature_id AND lb.boundary_id = g2.boundary_id
--WHERE l.location_id = 123
UNION ALL
SELECT l.location_id, l.activity_id, b.boundary_id,  b.name as boundary_name, lb.feature_area, nbs1.name
FROM location l
JOIN location_boundary lb
ON l.location_id = lb.location_id
JOIN boundary b
ON lb.boundary_id = b.boundary_id
JOIN nbs_tza_1 nbs1
ON lb.feature_id = nbs1.feature_id AND lb.boundary_id = nbs1.boundary_id
--WHERE l.location_id = 123
UNION ALL
SELECT l.location_id, l.activity_id, b.boundary_id,  b.name as boundary_name, lb.feature_area, nbs2.name
FROM location l
JOIN location_boundary lb
ON l.location_id = lb.location_id
JOIN boundary b
ON lb.boundary_id = b.boundary_id
JOIN nbs_tza_2 nbs2
ON lb.feature_id = nbs2.feature_id AND lb.boundary_id = nbs2.boundary_id
--WHERE l.location_id = 123
ORDER BY location_id, boundary_id;

CREATE MATERIALIZED VIEW location_lookup AS
(SELECT project_id, activity_id, location_id, start_date, end_date, x, y, georef, array_agg(distinct taxonomy_id) as taxonomy_ids, array_agg(distinct classification_id) as classification_ids, array_agg(distinct organization_id) as organization_ids,
(SELECT lbf.name FROM location_boundary_features lbf WHERE taxonomy_lookup.location_id = lbf.location_id AND lbf.boundary_id = 1 LIMIT 1) as gaul0_name,
(SELECT lbf.name FROM location_boundary_features lbf WHERE taxonomy_lookup.location_id = lbf.location_id AND lbf.boundary_id = 2 LIMIT 1) as gaul1_name,
(SELECT lbf.name FROM location_boundary_features lbf WHERE taxonomy_lookup.location_id = lbf.location_id AND lbf.boundary_id = 3 ORDER BY lbf.feature_area LIMIT 1) as gaul2_name
FROM taxonomy_lookup
GROUP BY project_id, activity_id, location_id, start_date, end_date, x, y, georef);

-- Create index for location_lookup
CREATE INDEX location_lookup_project_id_idx on location_lookup(project_id);
CREATE INDEX location_lookup_activity_id_idx on location_lookup(activity_id);
CREATE INDEX location_lookup_location_id_idx on location_lookup(location_id);
CREATE INDEX location_lookup_start_date_idx on location_lookup(start_date);
CREATE INDEX location_lookup_end_date_idx on location_lookup(end_date);
CREATE INDEX location_lookup_gaul0_name_idx on location_lookup(gaul0_name);
CREATE INDEX location_lookup_gaul1_name_idx on location_lookup(gaul1_name);
CREATE INDEX location_lookup_gaul2_name_idx on location_lookup(gaul2_name);


CREATE OR REPLACE VIEW  tanaim_nbs AS (
SELECT 	a.project_id
	,a.activity_id
	,a.title as activity_title
	,l.location_id
	,l.lat_dd
	,l.long_dd
	,l.point
	,(SELECT name FROM location_boundary_features lbf WHERE lbf.boundary_id = (SELECT boundary_id FROM boundary WHERE name = 'GAUL Level 0') AND lbf.location_id = l.location_id LIMIT 1) as "Country (Gaul0)"
	,(SELECT name FROM location_boundary_features lbf WHERE lbf.boundary_id = (SELECT boundary_id FROM boundary WHERE name = 'GAUL Level 1') AND lbf.location_id = l.location_id LIMIT 1) as "Region (Gaul1)"
	,(SELECT name FROM location_boundary_features lbf WHERE lbf.boundary_id = (SELECT boundary_id FROM boundary WHERE name = 'GAUL Level 2') AND lbf.location_id = l.location_id LIMIT 1) as "District (Gaul2)"	
	,(SELECT name FROM location_boundary_features lbf WHERE lbf.boundary_id = (SELECT boundary_id FROM boundary WHERE name = 'NBS Tanzania Regions') AND lbf.location_id = l.location_id LIMIT 1) as "Region (NBS2)"
	,(SELECT name FROM location_boundary_features lbf WHERE lbf.boundary_id = (SELECT boundary_id FROM boundary WHERE name = 'NBS Tanzania Districts') AND lbf.location_id = l.location_id LIMIT 1) as "District (NBS1)"
FROM activity a
JOIN location l
ON a.activity_id = l.activity_id
WHERE l.location_id in (select location_id from location_boundary_features where name = 'United Republic of Tanzania')
order by 1,2);


-- update permissions
GRANT USAGE ON SCHEMA public TO pmt_read;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO pmt_read;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO pmt_read;
GRANT USAGE ON SCHEMA public TO pmt_write;
GRANT SELECT,INSERT ON ALL TABLES IN SCHEMA public TO pmt_write;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO pmt_write;