/******************************************************************
Change Script 2.0.8.29 - consolidated.
1. change organization.name to character varying
******************************************************************/
INSERT INTO version(version, iteration, changeset) VALUES (2.0, 8, 29);
-- select * from version order by changeset desc;

DROP VIEW IF EXISTS accountable_project_participants CASCADE;
DROP VIEW IF EXISTS accountable_organizations CASCADE;
DROP VIEW IF EXISTS organization_participation CASCADE;

ALTER TABLE organization ALTER COLUMN name TYPE character varying;

-- Accountable Project Participants
CREATE OR REPLACE VIEW accountable_project_participants
AS SELECT p.project_id AS p_id, p.title, p.a_ids, organization.name AS org,  p.initiatives AS init
FROM participation
  -- participation records with no taxonomy will be dropped
  JOIN participation_taxonomy 
  ON participation_taxonomy.participation_id = participation.participation_id    
  JOIN organization 
  ON organization.organization_id = participation.organization_id   
  LEFT JOIN (
	SELECT project.project_id, at.a_ids, project.title, project.active, pt.classifications AS initiatives 
	FROM project 
	LEFT JOIN (
		-- projects with Initiative taxonomy
		SELECT project_id, array_to_string(array_agg(classification), ',') AS classifications 
		FROM project_taxonomies 
		WHERE taxonomy = 'Initiative' 
		GROUP BY project_id
		) pt -- 222 rows
	ON project.project_id = pt.project_id
	LEFT JOIN ( 
		-- active activities
		SELECT array_to_string(array_agg(activity_id), ',') AS a_ids, project_id 
		FROM activity 
		WHERE active = TRUE 
		GROUP BY project_id
		) at -- 219 rows
	ON project.project_id = at.project_id
	) p 
  ON participation.project_id = p.project_id 
  JOIN taxonomy_classifications 
  ON taxonomy_classifications.classification_id = participation_taxonomy.classification_id 
WHERE 
 participation_taxonomy.classification_id = (SELECT classification_id FROM classification WHERE name = 'Accountable' AND taxonomy_id = (SELECT taxonomy_id FROM taxonomy WHERE name = 'Organisation Role')) AND 
 p.active = TRUE AND
 organization.active = TRUE
ORDER BY p.project_id;

-- Accountable Organizations
CREATE OR REPLACE VIEW accountable_organizations
AS SELECT DISTINCT o.organization_id, o.name, pt.classification_id 
FROM participation p
JOIN participation_taxonomy pt
ON p.participation_id = pt.participation_id
JOIN organization o
ON p.organization_id = o.organization_id
WHERE pt.classification_id = 
(SELECT classification_id FROM classification WHERE name = 'Accountable' AND taxonomy_id = (SELECT taxonomy_id FROM taxonomy WHERE name = 'Organisation Role'))
and o.active = true and p.active = true
ORDER BY o.name;

CREATE OR REPLACE VIEW organization_participation
AS SELECT p.project_id, p.activity_id, o.* 
FROM organization o
JOIN participation p
ON o.organization_id = p.organization_id
WHERE o.active = true and p.active = true
ORDER BY p.project_id, p.activity_id;

-- update permissions
GRANT USAGE ON SCHEMA public TO pmt_read;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO pmt_read;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO pmt_read;
GRANT USAGE ON SCHEMA public TO pmt_write;
GRANT SELECT,INSERT ON ALL TABLES IN SCHEMA public TO pmt_write;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO pmt_write;