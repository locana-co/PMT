/******************************************************************
Change Script 2.0.7.24 - Consolidated.
1. taxonomy_classifications - converting from materialized
view back to view.
******************************************************************/
INSERT INTO config(version, iteration, changeset) VALUES (2.0, 7, 24);
-- select * from config order by changeset desc;

DROP MATERIALIZED VIEW IF EXISTS taxonomy_classifications CASCADE;
DROP VIEW IF EXISTS accountable_project_participants CASCADE;
DROP VIEW IF EXISTS taxonomy_classifications; 

CREATE OR REPLACE VIEW  taxonomy_classifications AS
(SELECT t.taxonomy_id, t.name as taxonomy, t.is_category, t.category_id as taxonomy_category_id, t.iati_codelist, t.description, c.classification_id, c.name as classification, c.category_id as classification_category_id, c.iati_code, c.iati_name
FROM taxonomy t
JOIN classification c
ON t.taxonomy_id = c.taxonomy_id
WHERE t.active = true and c.active = true
ORDER BY t.taxonomy_id, c.classification_id);

-- REMOVE Indexes
-- CREATE INDEX taxonomy_classifications_taxonomy_id_idx on taxonomy_classifications(taxonomy_id);
-- CREATE INDEX taxonomy_classifications_taxonomy_idx on taxonomy_classifications(taxonomy);
-- CREATE INDEX taxonomy_classifications_classification_id_idx on taxonomy_classifications(classification_id);
-- CREATE INDEX taxonomy_classifications_classification_idx on taxonomy_classifications(classification);

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

-- Analyze;

-- update permissions
GRANT USAGE ON SCHEMA public TO pmt_read;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO pmt_read;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO pmt_read;
GRANT USAGE ON SCHEMA public TO pmt_write;
GRANT SELECT,INSERT ON ALL TABLES IN SCHEMA public TO pmt_write;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO pmt_write;