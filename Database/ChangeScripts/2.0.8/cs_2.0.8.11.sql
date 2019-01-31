/******************************************************************
Change Script 2.0.8.11
1. pmt_stat_partner_network - new function to support partner network
graph
******************************************************************/
INSERT INTO version(version, iteration, changeset) VALUES (2.0, 8, 11);
-- select * from version order by changeset desc;

DROP FUNCTION IF EXISTS pmt_stat_partner_network()  CASCADE;
DROP TYPE IF EXISTS pmt_stat_partner_network_result CASCADE;

CREATE TYPE pmt_stat_partner_network_result AS (response json);

-- SELECT * FROM pmt_stat_partner_network();

/******************************************************************
  pmt_stat_partner_network
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_stat_partner_network()
RETURNS SETOF pmt_stat_partner_network_result AS 
$$
DECLARE
  rec record;
BEGIN
 FOR rec IN (
	SELECT array_to_json(array_agg(row_to_json(x))) 
	FROM (
		-- Funding Orgs
		SELECT f.name as name, f.organization_id as o_id,
			(SELECT array_to_json(array_agg(row_to_json(x))) 
			FROM (
				-- Implementing Orgs
				SELECT i.name as name,
					(SELECT array_to_json(array_agg(row_to_json(a))) 
					FROM (
						SELECT a.title as name
						FROM activity a
						WHERE activity_id = ANY(i.activity_ids)
					)a) as children
				FROM (
				SELECT ol.organization_id, o.name, array_agg(activity_id) as activity_ids				
				FROM organization_lookup ol
				JOIN organization o
				ON ol.organization_id = o.organization_id
				WHERE (classification_ids @> ARRAY[(select classification_id from classification where taxonomy_id = (select taxonomy_id from taxonomy where name = 'Organisation Role') 
				AND iati_name = 'Implementing')]) AND (f.activity_ids @> ARRAY[ol.activity_id])
				GROUP BY ol.organization_id, o.name
				) i
			) x) as children
		FROM
		(SELECT DISTINCT ol.organization_id, o.name, array_agg(activity_id) as activity_ids		
		FROM organization_lookup ol
		JOIN organization o
		ON ol.organization_id = o.organization_id
		WHERE (classification_ids @> ARRAY[(select classification_id from classification where taxonomy_id = (select taxonomy_id from taxonomy where name = 'Organisation Role') 
		AND iati_name = 'Funding')]) 
		GROUP BY ol.organization_id, o.name) as f
	) x
  ) LOOP
	RETURN NEXT rec; 
   END LOOP;
END;$$ LANGUAGE plpgsql;

-- update permissions
GRANT USAGE ON SCHEMA public TO pmt_read;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO pmt_read;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO pmt_read;
GRANT USAGE ON SCHEMA public TO pmt_write;
GRANT SELECT,INSERT ON ALL TABLES IN SCHEMA public TO pmt_write;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO pmt_write;