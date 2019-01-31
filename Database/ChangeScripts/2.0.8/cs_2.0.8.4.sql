/******************************************************************
Change Script 2.0.8.4 - consolidated.
1. pmt_locations_by_polygon -  new function for querying locations
by polygon. returns activity title of locations found, number of locations
by activity, average distance from polygon centroid and object of
actual locations.
******************************************************************/
INSERT INTO config(version, iteration, changeset) VALUES (2.0, 8, 4);
-- select * from config order by changeset desc;

-- SRID: 4326 (WGS84)
-- SRID: 3785 (Mercator)

-- drop statement
DROP FUNCTION IF EXISTS pmt_locations_by_polygon(text) CASCADE;

DROP TYPE IF EXISTS pmt_locations_by_polygon_result_type CASCADE;

CREATE TYPE pmt_locations_by_polygon_result_type AS (response json);


-- get wktPolygon using mapper
-- select * from pmt_locations_by_polygon('POLYGON((-15.801 13.558,-15.446 13.554,-15.501 13.249,-15.770 13.325,-15.800 13.555,-15.801 13.558))'); -- should give two
-- select * from pmt_locations_by_polygon('POLYGON((-16.473 13.522,-16.469 13.186,-16.764 13.185,-16.797 13.491,-16.472 13.517,-16.473 13.522))'); -- should give two
-- select * from pmt_locations_by_polygon(' polygon((-2.303 4.931,-1.696 4.955,-1.908 4.668,-2.237 4.733,-2.301 4.933,-2.303 4.931))');
-- select * from pmt_locations_by_polygon('Line((34.037 -4.028,39.398 -4.093,39.552 -9.394,33.927 -9.307,34.048 -4.028,34.037 -4.028))'); -- should error
/******************************************************************
  pmt_locations_by_polygon
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_locations_by_polygon(wktPolygon text) RETURNS SETOF pmt_locations_by_polygon_result_type AS 
$$
DECLARE
  wkt text;
  rec record;
BEGIN  
  -- validate the incoming WKT is a polygon and that it is all uppercase
  IF (upper(substring(trim($1) from 1 for 7)) = 'POLYGON') THEN
    RAISE NOTICE 'WKT: %', $1;
    wkt := replace(lower(trim($1)), 'polygon', 'POLYGON');    
    RAISE NOTICE 'WKT Fixed: %', wkt;  

    FOR rec IN (
    SELECT row_to_json(j)
    FROM(	
	SELECT sel.title, sel.location_ct, sel.avg_km,
		(SELECT array_to_json(array_agg(row_to_json(c))) FROM (
			SELECT location_id, lat_dd, long_dd
			FROM location
			WHERE location_id = ANY(sel.location_ids)
		) c) as locations
	FROM(
		SELECT calc.activity_id 
			,(SELECT title FROM activity a WHERE a.activity_id = calc.activity_id) AS title 
			,count(location_id) AS location_ct
			,array_agg(location_id) AS location_ids
			,round(avg(dist_km)) AS avg_km 
		FROM(
			SELECT location_id, activity_id, round(CAST(
				ST_Distance_Spheroid(ST_Centroid(ST_GeomFromText(wkt, 4326)), point, 'SPHEROID["WGS 84",6378137,298.257223563]') As numeric),2)*.001 As dist_km
			FROM location
			WHERE ST_Contains(ST_GeomFromText(wkt, 4326), point)
			AND active = true
		) as calc
		GROUP BY calc.activity_id
	) as sel 
     ) j
    ) LOOP		
      RETURN NEXT rec;
    END LOOP;	
      
  ELSE
    FOR rec IN (SELECT row_to_json(j) FROM (SELECT 'WKT must be of type POLYGON' as error) j ) LOOP		
      RETURN NEXT rec;
    END LOOP;	
  END IF;	
END;$$ LANGUAGE plpgsql;

-- update permissions
GRANT USAGE ON SCHEMA public TO pmt_read;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO pmt_read;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO pmt_read;
GRANT USAGE ON SCHEMA public TO pmt_write;
GRANT SELECT,INSERT ON ALL TABLES IN SCHEMA public TO pmt_write;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO pmt_write;