/******************************************************************
Change Script 2.0.6.18 - Consolidated

1. bmgf_global_search - global text search for project and activties:
title, description, opportunity_id and tag
******************************************************************/
UPDATE config SET changeset = 18, updated_date = current_date WHERE "version" = 2.0 AND iteration = 6;
-- SELECT pmt_version();

-- select * from bmgf_global_search('chicken');
-- SELECT * FROM bmgf_global_search('OPP1007117')

CREATE TYPE bmgf_global_search_result_type AS (response json);

-- bmgf_global_search
CREATE OR REPLACE FUNCTION bmgf_global_search(search_text text)
RETURNS SETOF bmgf_global_search_result_type AS 
$$
DECLARE
  rec record;
BEGIN
  IF ( lower($1)is null OR lower($1) = '') THEN
  
  ELSE

    FOR rec IN (
    SELECT row_to_json(j)
    FROM
    (	
	SELECT p.type, p.id, p.title, p.desc, p.opp_id, p.tags, p.p_ids, p.a_ids FROM (
	SELECT 'p'::text AS "type", p.project_id AS id, coalesce(p.label, p.title) AS title, (lower(p.title) LIKE '%' || lower($1) || '%') AS in_title, 
	p.description AS desc, (lower(p.description) LIKE '%' || lower($1) || '%') AS in_desc, p.opportunity_id AS opp_id, (lower(p.opportunity_id) LIKE '%' || lower($1) || '%') AS in_opp, 
	p.tags, (lower(p.tags) LIKE '%' || lower($1) || '%') AS in_tags, array_agg(distinct p.project_id) as p_ids, array_agg(distinct l.activity_id) as a_ids
	-- , ST_AsGeoJSON(ST_Envelope(ST_UNION(l.point))) AS bbox, array_agg(l.location_id) AS l_ids
	FROM project p
	LEFT JOIN activity l
	ON p.project_id = l.project_id
	WHERE p.active = true and
	(lower(p.title) LIKE '%' || lower($1) || '%' or lower(p.description) LIKE '%' || lower($1) || '%' or lower(p.opportunity_id) LIKE '%' || lower($1) || '%' or lower(p.tags) LIKE '%' || lower($1) || '%')
	GROUP BY p.project_id, p.title, p.description, p.opportunity_id, p.tags
	ORDER BY in_opp desc, in_title desc, in_tags desc, in_desc desc) AS p
	UNION ALL
	SELECT a.type, a.id, a.title, a.desc, a.opp_id, a.tags, a.p_ids, a.a_ids FROM (
	SELECT 'a'::text AS "type", a.activity_id AS id, coalesce(a.label, a.title) AS title, (lower(a.title) LIKE '%' || lower($1) || '%') AS in_title, 
	a.description AS desc, (lower(a.description) LIKE '%' || lower($1) || '%') AS in_desc, a.opportunity_id AS opp_id, (lower(a.opportunity_id) LIKE '%' || lower($1) || '%') AS in_opp, 
	a.tags, (lower(a.tags) LIKE '%' || lower($1) || '%') AS in_tags, array_agg(distinct a.project_id) as p_ids, array_agg(distinct a.activity_id) as a_ids
	-- , ST_AsGeoJSON(ST_Envelope(ST_UNION(l.point))) AS bbox, array_agg(l.location_id) AS l_ids
	FROM activity a
	WHERE a.active = true and
	(lower(a.title) LIKE '%' || lower($1) || '%' or lower(a.description) LIKE '%' || lower($1) || '%' or lower(a.opportunity_id) LIKE '%' || lower($1) || '%' or lower(a.tags) LIKE '%' || lower($1) || '%')
	GROUP BY a.activity_id, a.title, a.description, a.opportunity_id, a.tags
	ORDER BY in_opp desc, in_title desc, in_tags desc, in_desc desc) AS a
     ) j
    ) LOOP		
      RETURN NEXT rec;
    END LOOP;	
    
  END IF;		
END;$$ LANGUAGE plpgsql;