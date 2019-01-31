/******************************************************************
Change Script 2.0.9.2
1. pmt_locations_by_polygon - new overloaded function selecting locations 
with a polygon, allowing a restriction by activity_id.
******************************************************************/
INSERT INTO version(version, iteration, changeset) VALUES (2.0, 9, 2);
-- select * from version order by iteration desc, changeset desc;

DROP FUNCTION IF EXISTS pmt_locations_by_polygon(text, character varying);
-- select activity_id from location where location_id in (81122,81121);
-- select * from pmt_locations_by_polygon('POLYGON((49.21875 12.297068292853803,49.21875 -22.593726063929296,18.017578125 -22.593726063929296,18.017578125 12.297068292853803,49.21875 12.297068292853803))', ''); -- should give two     
			   
CREATE OR REPLACE FUNCTION pmt_locations_by_polygon(wktPolygon text, exclude_activity_ids character varying) RETURNS SETOF pmt_json_result_type AS 
$$
DECLARE
  wkt text;
  rec record;
  valid_activity_ids integer[];
  execute_statement text;
BEGIN
  IF ($1 IS NULL) THEN
     FOR rec IN (SELECT row_to_json(j) FROM (SELECT 'Must provide a polygon as wkt.' as error) j ) LOOP RETURN NEXT rec; END LOOP;	
  END IF;
    
  -- validate the incoming WKT is a polygon and that it is all uppercase
  IF (upper(substring(trim($1) from 1 for 7)) = 'POLYGON') THEN
    RAISE NOTICE 'WKT: %', $1;
    wkt := replace(lower(trim($1)), 'polygon', 'POLYGON');    
    RAISE NOTICE 'WKT Fixed: %', wkt;  

    IF ($2 IS NOT NULL) THEN
      -- validate activity_ids
      SELECT INTO valid_activity_ids * FROM pmt_validate_activities($2);
    END IF;

    IF (valid_activity_ids IS NOT NULL) THEN
      execute_statement := 'SELECT location_id, lat_dd, long_dd FROM location ' ||
			   'WHERE ST_Contains(ST_GeomFromText(' || quote_literal(wkt) || ', 4326), point) AND active=true ' ||
			   'AND NOT (activity_id = ANY(ARRAY['|| array_to_string(valid_activity_ids, ',') || ']))';
    ELSE
        execute_statement := 'SELECT location_id, lat_dd, long_dd FROM location ' ||
			   'WHERE ST_Contains(ST_GeomFromText(' || quote_literal(wkt) || ', 4326), point) AND active=true ';
    END IF;
    
     FOR rec IN EXECUTE 'SELECT row_to_json(j) FROM (' || execute_statement || ')j' LOOP     
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

