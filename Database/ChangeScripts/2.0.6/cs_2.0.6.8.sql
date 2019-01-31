/******************************************************************
Change Script 2.0.6.8 - Consolidated

1. pmt_countries - cs 2.0.6.7 caused an error in pmt_counties. Removed
the ring dump statement and call polygon to Box2d directly.
******************************************************************/
UPDATE config SET changeset = 8, updated_date = current_date WHERE "version" = 2.0 AND iteration = 6;
-- SELECT pmt_version();

-- test
-- select * from pmt_countries((select array_to_string(array_agg(classification_id), ',') from taxonomy_classifications 
--     where taxonomy = 'Country' and upper(classification) = 
--     ANY(ARRAY['BURKINA FASO', 'ETHIOPIA', 'GHANA','INDIA','MALI','NIGERIA','UGANDA','TANZANIA, UNITED REPUBLIC OF'])));

/******************************************************************
  pmt_countries
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_countries(classification_ids text)
RETURNS SETOF pmt_countries_result_type AS 
$$
DECLARE
  filter_classids int[];
  rec record;
BEGIN
  -- return all countries
  IF ($1 is null OR $1 = '') THEN
  FOR rec IN (
    SELECT row_to_json(j)
    FROM
    (	
	SELECT c.classification_id as c_id, lower(c.classification) as name, ST_AsGeoJSON(Box2D(ST_Collect(polygon))) as bounds
	FROM  gaul0 g
	JOIN feature_taxonomy t
	ON g.feature_id = t.feature_id
	JOIN taxonomy_classifications c
	ON t.classification_id = c.classification_id
	GROUP BY c.classification_id, c.classification
	ORDER BY c.classification
     ) j   
  ) LOOP		
    RETURN NEXT rec;
  END LOOP;	
  -- return filtered countries
  ELSE
    -- Create an int array from classification ids list
    filter_classids := string_to_array($1, ',')::int[];	
    
    FOR rec IN (
    SELECT row_to_json(j)
    FROM
    (	
	SELECT c.classification_id as c_id, lower(c.classification) as name, ST_AsGeoJSON(Box2D(ST_Collect(polygon))) as bounds
	FROM gaul0 g
	JOIN feature_taxonomy t
	ON g.feature_id = t.feature_id
	JOIN taxonomy_classifications c
	ON t.classification_id = c.classification_id
	WHERE c.classification_id = ANY(filter_classids)
	GROUP BY c.classification_id, c.classification
	ORDER BY c.classification
     ) j
    ) LOOP		
      RETURN NEXT rec;
    END LOOP;	
    
  END IF;		
END;$$ LANGUAGE plpgsql;