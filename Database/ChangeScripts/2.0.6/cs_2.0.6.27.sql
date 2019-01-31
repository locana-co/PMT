/******************************************************************
Change Script 2.0.6.27 - Consolidated.
1. pmt_activity_details - new function.
******************************************************************/
INSERT INTO config(version, iteration, changeset) VALUES (2.0, 6, 27);
-- select * from config order by version, iteration, changeset, updated_date;

-- select * from pmt_activity_details(1234);

CREATE TYPE pmt_activity_details_result_type AS (response json);

-- pmt_activity_details
CREATE OR REPLACE FUNCTION pmt_activity_details(a_id integer)
RETURNS SETOF pmt_activity_details_result_type AS 
$$
DECLARE
  valid_activity_id integer;
  rec record;
BEGIN  

  IF ( $1 IS NULL ) THEN
     FOR rec IN (SELECT row_to_json(j) FROM(select null as message) j) LOOP  RETURN NEXT rec; END LOOP;
  ELSE
    -- Is activity_id active and valid?
    SELECT INTO valid_activity_id activity_id FROM activity WHERE activity_id = $1 and active = true;

    IF valid_activity_id IS NOT NULL THEN
      FOR rec IN (
	    SELECT row_to_json(j)
	    FROM
	    (			
		SELECT a.activity_id AS a_id, coalesce(a.label, a.title) AS title, a.description AS desc,a.start_date, a.end_date, a.tags
		, f.amount
		-- taxonomy
		,(
			SELECT array_to_json(array_agg(row_to_json(t))) FROM (
				SELECT tc.taxonomy, tc.classification
				FROM taxonomy_lookup tl
				JOIN taxonomy_classifications  tc
				ON tl.classification_id = tc.classification_id
				WHERE tl.activity_id = a.activity_id
				) t
		) as taxonomy		
		-- locations
		,(
			SELECT array_to_json(array_agg(row_to_json(l))) FROM (
				SELECT ll.location_id, gaul0_name, gaul1_name, gaul2_name, l.lat_dd as lat, l.long_dd as long
				FROM location_lookup ll
				LEFT JOIN location l
				ON ll.location_id = l.location_id
				WHERE ll.activity_id = a.activity_id
				) l 
		) as locations		
		FROM activity a
		-- financials
		LEFT JOIN
		(SELECT activity_id, sum(amount) as amount FROM financial WHERE activity_id = $1 GROUP BY activity_id ) as f
		ON f.activity_id = a.activity_id					
		WHERE a.active = true and a.activity_id = $1
	     ) j
	    ) LOOP		
	      RETURN NEXT rec;
	    END LOOP;	
    ELSE
      FOR rec IN (SELECT row_to_json(j) FROM(select 'activity_id is not valid or active.' as message) j) LOOP  RETURN NEXT rec; END LOOP;
    END IF;           
  END IF;		
END;$$ LANGUAGE plpgsql;