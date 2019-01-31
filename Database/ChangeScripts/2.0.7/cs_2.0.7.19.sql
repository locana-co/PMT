/******************************************************************
Change Script 2.0.7.19 - Consolidated.
1. pmt_activity_details -  adding more complete details.
******************************************************************/
INSERT INTO config(version, iteration, changeset) VALUES (2.0, 7, 19);
-- select * from config order by changeset desc;

-- SELECT * FROM  pmt_activity_details(2039);

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
				SELECT DISTINCT tc.taxonomy, tc.classification,
				(select name from organization where organization_id = ol.organization_id and tc.taxonomy = 'Organisation Role') as org
				FROM organization_lookup ol
				JOIN taxonomy_classifications  tc
				ON tc.classification_id = ANY(ARRAY[ol.classification_ids])		
				WHERE ol.activity_id = a.activity_id
				ORDER BY taxonomy
				) t
		) as taxonomy				
		-- locations
		,(
			SELECT array_to_json(array_agg(row_to_json(l))) FROM (
				SELECT DISTINCT ll.location_id, gaul0_name, gaul1_name, gaul2_name, l.lat_dd as lat, l.long_dd as long
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

-- update permissions
GRANT USAGE ON SCHEMA public TO pmt_read;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO pmt_read;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO pmt_read;
GRANT USAGE ON SCHEMA public TO pmt_write;
GRANT SELECT,INSERT ON ALL TABLES IN SCHEMA public TO pmt_write;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO pmt_write;