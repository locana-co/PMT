/******************************************************************
Change Script 3.0.10.21

1. create pmt_boundaries_by_point function
******************************************************************/
INSERT INTO version(_version, _iteration, _changeset) VALUES (3.0, 10, 21);
-- select * from version order by _iteration desc, _changeset desc;

/******************************************************************
1. create pmt_boundaries_by_point function
  select * from pmt_boundaries_by_point('POINT(38.758578 8.942346)'); 
  select * from pmt_boundaries_by_point(null);   
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_boundaries_by_point(wktpoint character varying) RETURNS SETOF pmt_json_result_type AS $$
DECLARE
  wkt text;
  spatial_table text;
  elem text;
  arr json[];
  rec record;
  error_msg text;
BEGIN 
  -- validate wktpoint parameter (required)
  IF $1 IS NULL OR $1 = '' THEN 
    FOR rec IN (SELECT row_to_json(r) FROM (SELECT 'The wktpoint parameter is required.' as error) r ) LOOP		
      RETURN NEXT rec;
    END LOOP;
  END IF;
   
  -- validate that incoming WKT is a Point and that it is all uppercase
  IF (upper(substring(trim($1) from 1 for 5)) = 'POINT') THEN
    -- RAISE NOTICE 'WKT: %', $1;
    wkt := replace(lower(trim($1)), 'point', 'POINT');    
    -- RAISE NOTICE 'WKT Fixed: %', wkt; 

    -- get boundary data from each spatial table
    FOR spatial_table IN SELECT _spatial_table FROM boundary LOOP

      -- get intersecting boundary names & ids if wkt point intersects 
      EXECUTE 'SELECT row_to_json(j) FROM (
	SELECT DISTINCT s.boundary_id AS boundary_id, ''' || spatial_table || ''' AS boundary_name,s.id AS feature_id,s._name AS feature_name
	FROM ' || spatial_table || ' s
	WHERE ST_Intersects(ST_SetSRID(''' || wkt || '''::geometry, 4326), s._polygon)
	LIMIT 1
	)j' INTO elem;

      -- add boundary data to array if boundary data is not empty
      IF elem <> '' THEN
        -- RAISE NOTICE 'elem: %', elem;      
        arr := array_append(arr, elem::json);
      END IF;
    END LOOP;

    -- return boundary results
    FOR rec IN (SELECT array_to_json(arr)) LOOP
      RETURN NEXT rec;
    END LOOP;
  -- if not wkt point, return error message  
  ELSE
    FOR rec IN (SELECT row_to_json(r) FROM (SELECT 'WKT must be of type POINT' as error) r ) LOOP		
      RETURN NEXT rec;
    END LOOP;	
  END IF;

  EXCEPTION WHEN others THEN 
    GET STACKED DIAGNOSTICS error_msg = MESSAGE_TEXT;  
    RAISE NOTICE 'Internal Error - Contact your DBA with the following error message: %', error_msg;
    
END;$$ LANGUAGE plpgsql; 

-- update permissions
GRANT USAGE ON SCHEMA public TO pmt_read;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO pmt_read;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO pmt_read;
GRANT USAGE ON SCHEMA public TO pmt_write;
GRANT SELECT,INSERT ON ALL TABLES IN SCHEMA public TO pmt_write;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO pmt_write;
