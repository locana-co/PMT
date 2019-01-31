/******************************************************************
Change Script 3.0.10.40
1. update filter view to support unassigned taxonomies (fix issue 
with activities with no locations and no taxonomies at all)
******************************************************************/
INSERT INTO version(_version, _iteration, _changeset) VALUES (3.0, 10, 40);
-- select * from version order by _iteration desc, _changeset desc;

/******************************************************************
 2. update filter view to support unassigned taxonomies
******************************************************************/
-- filter view for unassigned taxonomies
DROP VIEW IF EXISTS _filter_unassigned;
CREATE OR REPLACE VIEW _filter_unassigned AS
SELECT activity_id, data_group_id, assigned, (SELECT array_agg(id) FROM taxonomy WHERE id <> ALL(assigned) and _active = true) as unassigned FROM 
(SELECT activity_id, data_group_id, array_agg(DISTINCT taxonomy_id) as assigned FROM (
	SELECT activity_id, data_group_id, location_id, taxonomy_id FROM
        (SELECT a.id as activity_id, a.data_group_id, l.id as location_id, t.taxonomy_id FROM
	(
		SELECT id, data_group_id 
		FROM activity 
		WHERE _active = true
	) a
	LEFT JOIN
	(
		SELECT id, activity_id 
		FROM location 
		WHERE _active = true
	) l
	ON a.id = l.activity_id
	LEFT JOIN 
	(
		SELECT DISTINCT at.activity_id, tc.taxonomy_id 
		FROM activity_taxonomy at
		JOIN _taxonomy_classifications tc
		ON at.classification_id = tc.classification_id
	) t
	ON a.id = t.activity_id
	UNION ALL
	SELECT a.id as activity_id, a.data_group_id, l.id as location_id, t.taxonomy_id FROM
	(
		SELECT id, data_group_id 
		FROM activity 
		WHERE _active = true
	) a
	LEFT JOIN
	(
		SELECT id, activity_id 
		FROM location 
		WHERE _active = true
	) l
	ON a.id = l.activity_id
	LEFT JOIN 
	(
		SELECT DISTINCT lt.location_id, tc.taxonomy_id 
		FROM location_taxonomy lt
		JOIN _taxonomy_classifications tc
		ON lt.classification_id = tc.classification_id
	) t
	ON l.id = t.location_id) u
	WHERE taxonomy_id IS NOT NULL
) as at
GROUP BY 1,2) as a
UNION ALL
SELECT a.id, data_group_id, null::int[] as assigned, array_agg(t.id) as unassigned
FROM (SELECT a.id, a.data_group_id, at.classification_id FROM (SELECT * FROM activity WHERE _active = true) a FULL JOIN activity_taxonomy at ON a.id = at.activity_id WHERE at.classification_id IS NULL) a
CROSS JOIN taxonomy t
GROUP BY 1,2,3;


-- update permissions
GRANT USAGE ON SCHEMA public TO pmt_read;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO pmt_read;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO pmt_read;
GRANT USAGE ON SCHEMA public TO pmt_write;
GRANT SELECT,INSERT ON ALL TABLES IN SCHEMA public TO pmt_write;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO pmt_write;