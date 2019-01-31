/******************************************************************
Change Script 3.0.10.5
1. update pmt_validate_location
2. update pmt_validate_locations
3. update pmt_locations
******************************************************************/
INSERT INTO version(_version, _iteration, _changeset) VALUES (3.0, 10, 5);
-- select * from version order by _iteration desc, _changeset desc;
/******************************************************************
 1. update pmt_validate_location
    select * from pmt_validate_location(39498);
******************************************************************/
DROP FUNCTION pmt_validate_location(integer);
CREATE OR REPLACE FUNCTION pmt_validate_location(location_id integer) RETURNS boolean AS $$
DECLARE valid_id integer;
BEGIN 
     IF $1 IS NULL THEN    
       RETURN false;
     END IF;    
     
     SELECT INTO valid_id id FROM location WHERE _active = true AND id = $1;	 

     IF valid_id IS NULL THEN
      RETURN false;
     ELSE 
      RETURN true;
     END IF;
     
EXCEPTION WHEN others THEN
    RETURN FALSE; 
END;$$ LANGUAGE plpgsql;
/******************************************************************
 2. update pmt_validate_locations
    select * from pmt_validate_locations('39498,40255,9999999');
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_validate_locations(location_ids character varying) RETURNS integer[] AS $$
DECLARE 
  valid_location_ids INT[];
  filter_location_ids INT[];
BEGIN 
     IF $1 IS NULL THEN    
       RETURN valid_location_ids;
     END IF;

     filter_location_ids := string_to_array($1, ',')::int[];
     
     SELECT INTO valid_location_ids array_agg(DISTINCT id)::INT[] FROM (SELECT id FROM location WHERE _active = true AND id = ANY(filter_location_ids) ORDER BY id) AS t;
     
     RETURN valid_location_ids;

EXCEPTION
     WHEN others THEN RETURN NULL;
END;$$ LANGUAGE plpgsql; 
/******************************************************************
 3. update pmt_locations
   select * from pmt_locations('38942,38943,38941,38940');
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_locations(location_ids character varying) RETURNS SETOF pmt_json_result_type AS 
$$
DECLARE
 rec record;
  invalid_return_columns text[];
  valid_location_ids integer[];
  return_columns text;
  execute_statement text;
  boundary_features text;
  boundary_tables text[];
  data_message text;
BEGIN
  IF $1 IS NOT NULL THEN
    -- validate location_ids
    select into valid_location_ids * from pmt_validate_locations($1);
    -- set columns that are not to be returned 
    invalid_return_columns := ARRAY['_active', '_retired_by', '_created_by', '_created_date', '_point'];
    -- get list of columns to return
    SELECT INTO return_columns array_to_string(array_agg('l.' || column_name::text), ', ') FROM information_schema.columns 
    WHERE table_schema='public' AND table_name='location' AND column_name != ALL(invalid_return_columns);
    IF (valid_location_ids IS NOT NULL) THEN
      -- dynamically build boundary_features
      FOR rec IN (SELECT _spatial_table FROM boundary) LOOP  		
        boundary_tables := array_append(boundary_tables, ' select boundary_id, id, _polygon from ' || rec._spatial_table || ' ');   
      END LOOP;
    
      boundary_features:= ' (' || array_to_string(boundary_tables, ' UNION ') || ') as boundary_features ';
    
      -- dynamically build the execute statment	
      execute_statement := 'SELECT ' || return_columns || ' ';

      -- taxonomy	
      execute_statement := execute_statement || ',(SELECT array_to_json(array_agg(row_to_json(t))) FROM ( ' ||
				'select tc.taxonomy_id, tc.taxonomy, tc.classification_id, tc.classification, tc._code ' ||
				'from location_taxonomy lt ' ||
				'join _taxonomy_classifications  tc ' ||
				'on lt.classification_id = tc.classification_id ' ||
				'and lt.location_id = l.id'
				') t ) as taxonomy ';       							
      -- point
      execute_statement := execute_statement || ', ST_AsGeoJSON(_point) as point ';  				
      -- polygon
      execute_statement := execute_statement || ', (SELECT ST_AsGeoJSON(_polygon) FROM ' || boundary_features || ' WHERE boundary_id = l.boundary_id AND id = l.feature_id) as polygon ';  
   				
      -- location
      execute_statement := execute_statement || 'from (select * from location l where l._active = true and l.id = ANY(ARRAY[' || array_to_string(valid_location_ids, ',') || '])) l ';    


      RAISE NOTICE 'Execute statement: %', execute_statement;			

      FOR rec IN EXECUTE 'SELECT row_to_json(j) FROM (' || execute_statement || ')j' LOOP  		
	  RETURN NEXT rec;
      END LOOP;
      ELSE
         FOR rec IN (SELECT row_to_json(j) FROM(select 'Error: No valid location ids: ' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
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