/******************************************************************
Change Script 2.0.8.30 - consolidated.
1. pmt_global_search - add data group id to returned results
******************************************************************/
INSERT INTO version(version, iteration, changeset) VALUES (2.0, 8, 30);
-- select * from version order by changeset desc;

-- select * from pmt_global_search('cotton');

CREATE OR REPLACE FUNCTION pmt_global_search(search_text text) RETURNS SETOF pmt_json_result_type AS $$
DECLARE
  rec record;
  json_rec record;
  column_rec record;
  error_msg text;
BEGIN
  IF ($1 IS NULL OR $1 = '') THEN
    -- must include all parameters, return error
    FOR rec IN (SELECT row_to_json(j) FROM(SELECT 'Error: Must include search_text data parameter.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
  ELSE
    FOR rec IN (
    SELECT row_to_json(j)
    FROM
    (	
	SELECT p.type, p.id, p.title, p.desc, p.tags, p.p_ids, p.a_ids, dg_id FROM (
	SELECT 'p'::text AS "type", p.project_id AS id, coalesce(p.label, p.title) AS title, (lower(p.title) LIKE '%' || lower($1) || '%') AS in_title, 
	p.description AS desc, (lower(p.description) LIKE '%' || lower($1) || '%') AS in_desc, 
	p.tags, (lower(p.tags) LIKE '%' || lower($1) || '%') AS in_tags, array_agg(distinct p.project_id) as p_ids, array_agg(distinct l.activity_id) as a_ids
	, array_agg(distinct pt.classification_id) as dg_id
	-- , ST_AsGeoJSON(ST_Envelope(ST_UNION(l.point))) AS bbox, array_agg(l.location_id) AS l_ids
	FROM project p
	LEFT JOIN activity l
	ON p.project_id = l.project_id
	LEFT JOIN project_taxonomy pt
	ON p.project_id = pt.project_id
	WHERE p.active = true and l.active = true and pt.classification_id IN (SELECT classification_id FROM taxonomy_classifications WHERE taxonomy = 'Data Group') and
	(lower(p.title) LIKE '%' || lower($1) || '%' or lower(p.description) LIKE '%' || lower($1) || '%' or lower(p.tags) LIKE '%' || lower($1) || '%')
	GROUP BY p.project_id, p.title, p.description, p.tags
	ORDER BY in_title desc, in_tags desc, in_desc desc) AS p
	UNION ALL
	SELECT a.type, a.id, a.title, a.desc, a.tags, a.p_ids, a.a_ids, dg_id FROM (
	SELECT 'a'::text AS "type", a.activity_id AS id, coalesce(a.label, a.title) AS title, (lower(a.title) LIKE '%' || lower($1) || '%') AS in_title, 
	a.description AS desc, (lower(a.description) LIKE '%' || lower($1) || '%') AS in_desc, 
	a.tags, (lower(a.tags) LIKE '%' || lower($1) || '%') AS in_tags, array_agg(distinct a.project_id) as p_ids, array_agg(distinct a.activity_id) as a_ids
	, array_agg(distinct pt.classification_id) as dg_id
	-- , ST_AsGeoJSON(ST_Envelope(ST_UNION(l.point))) AS bbox, array_agg(l.location_id) AS l_ids
	FROM activity a
	LEFT JOIN project_taxonomy pt
	ON a.project_id = pt.project_id
	WHERE a.active = true and pt.classification_id IN (SELECT classification_id FROM taxonomy_classifications WHERE taxonomy = 'Data Group') and
	(lower(a.title) LIKE '%' || lower($1) || '%' or lower(a.description) LIKE '%' || lower($1) || '%' or lower(a.tags) LIKE '%' || lower($1) || '%')
	GROUP BY a.activity_id, a.title, a.description, a.tags
	ORDER BY in_title desc, in_tags desc, in_desc desc) AS a
     ) j
    ) LOOP		
      RETURN NEXT rec;
    END LOOP;	
    
  END IF;
  	
EXCEPTION WHEN others THEN
    GET STACKED DIAGNOSTICS error_msg = MESSAGE_TEXT;
    FOR rec IN (SELECT row_to_json(j) FROM(SELECT 'Internal Error - Contact your DBA with the following error message: ' || error_msg as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;	  	
END;$$ LANGUAGE plpgsql;

-- update permissions
GRANT USAGE ON SCHEMA public TO pmt_read;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO pmt_read;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO pmt_read;
GRANT USAGE ON SCHEMA public TO pmt_write;
GRANT SELECT,INSERT ON ALL TABLES IN SCHEMA public TO pmt_write;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO pmt_write;