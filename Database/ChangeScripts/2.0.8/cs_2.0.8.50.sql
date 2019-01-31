/******************************************************************
Change Script 2.0.8.50 - consolidated.
1. location  - add new fields to allow for featuer assoication to 
any boundary feature
2. pmt_validate_boundary_feature - new function to validate 
boundary_id/feature_id pairs
3. upd_boundary_features - update to create centroid when boundary_id
and feature_id are present and valid
4. pmt_activity - removing location object and replacing with location
id array, and adding code to the return taxonomy object
5. pmt_validate_locations - new function to validate a comma delimetd
string of location_ids
6. pmt_locations - new function to request location information for one
or more locations
7. pmt_project - adding code to the returned taxonomy object
******************************************************************/
INSERT INTO version(version, iteration, changeset) VALUES (2.0, 8, 50);
-- select * from version order by changeset desc;

-- test (pmt_validate_boundary_feature)
-- select * from pmt_validate_boundary_feature(1, 300)
-- select * from pmt_validate_boundary_feature(1, 14)

-- test (upd_boundary_features)
-- select * from location_boundary_features where location_id = 79564 -- check intersections
-- select tc.classification, tc.taxonomy from location_taxonomy lt join taxonomy_classifications tc on lt.classification_id = tc.classification_id where location_id = 79564 -- check associated taxonomy
-- select ST_AsText(point) from location where location_id = 79564 -- get point
-- select * from pmt_edit_location(34, 1, null, '{"point":"POINT(39.55078125 -10.444597722834862)"}', false); -- update location
-- select * from pmt_edit_location(3, 79564, null, '{"boundary_id":3,"feature_id":25675}', false); -- update location

-- test (pmt_activity)
-- select * from pmt_activity(10813)

-- test (pmt_validate_locations)
-- select * from pmt_validate_locations('23,10,1,3')

-- test (pmt_locations)
-- select * from pmt_locations('79564,39489')

-- select * from pmt_activity(1)


-- update location table
ALTER TABLE "location" ADD boundary_id integer;
ALTER TABLE "location" ADD feature_id integer;

/******************************************************************
  pmt_validate_boundary_feature
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_validate_boundary_feature(boundary_id integer, feature_id integer) RETURNS boolean AS $$
DECLARE valid_id integer;
	spatialtable text;
	execute_statement text;
BEGIN 
     IF $1 IS NULL OR $2 IS NULL THEN    
       RETURN false;
     END IF;    

     SELECT INTO spatialtable spatial_table FROM boundary WHERE active = true AND boundary.boundary_id = $1;	
     RAISE NOTICE 'spatialtable: % ...', spatialtable; 

     IF spatialtable IS NOT NULL THEN
       execute_statement := 'SELECT feature_id FROM ' || quote_ident(spatialtable) || ' WHERE feature_id = ' || $2 ;
       EXECUTE execute_statement INTO valid_id;
       RAISE NOTICE 'valid_id : % ...', valid_id; 
     ELSE
       RETURN false;
     END IF;
     
     IF valid_id IS NULL THEN
      RETURN false;
     ELSE 
      RETURN true;
     END IF;
     
EXCEPTION WHEN OTHERS THEN
    RETURN FALSE;
END; 
$$ LANGUAGE 'plpgsql';   

-- upd_boundary_features
CREATE OR REPLACE FUNCTION upd_boundary_features()
RETURNS trigger AS $upd_boundary_features$
    DECLARE
	boundary RECORD;
	feature RECORD;
	ft RECORD;
	rec RECORD;
	spatialtable text;
	execute_statement text;
	centroid geometry;
	id integer;
    BEGIN
      --RAISE NOTICE 'Refreshing boundary features for location_id % ...', NEW.location_id;
      EXECUTE 'DELETE FROM location_boundary WHERE location_id = ' || NEW.location_id;

      IF (SELECT * FROM pmt_validate_boundary_feature(NEW.boundary_id, NEW.feature_id)) THEN
        SELECT INTO spatialtable spatial_table FROM boundary b WHERE active = true AND b.boundary_id = NEW.boundary_id;
        -- get centroid and assign as NEW.point
        execute_statement := 'SELECT ST_Transform(ST_Centroid((SELECT polygon FROM ' || quote_ident(spatialtable) || ' WHERE feature_id = ' || NEW.feature_id || ' LIMIT 1)),4326)' ;
        EXECUTE execute_statement INTO centroid;
	IF (centroid IS NOT NULL) THEN	
	  RAISE NOTICE 'Centroid of boundary assigned';
          NEW.point := centroid;
        END IF;
      END IF; 
        
      -- Only process if there is a point value
      IF (NEW.point IS NOT NULL) THEN
	
	FOR boundary IN SELECT * FROM boundary LOOP
		--RAISE NOTICE 'Add % boundary features ...', quote_ident(boundary.spatial_table);
		FOR feature IN EXECUTE 'SELECT * FROM ' || quote_ident(boundary.spatial_table)  || ' WHERE ST_Intersects(ST_PointFromText(''' ||
			ST_AsText(NEW.point) || ''', 4326), polygon)' LOOP
		  -- For each boundary locate intersecting features and record them in the location_boundary table
		  EXECUTE 'INSERT INTO location_boundary VALUES (' || NEW.location_id || ', ' || feature.boundary_id || ', ' || feature.feature_id || ')';
		  -- Assign all associated taxonomy classification from intersected features to new location
		  FOR ft IN (SELECT * FROM feature_taxonomy WHERE feature_id = feature.feature_id) LOOP
		    -- Replace all previous taxonomy associates with new
		    DELETE FROM location_taxonomy WHERE location_id = NEW.location_id AND classification_id IN (SELECT classification_id FROM taxonomy_classifications WHERE taxonomy_id = (SELECT taxonomy_id FROM classification WHERE classification_id = ft.classification_id));    
		    INSERT INTO location_taxonomy VALUES (NEW.location_id, ft.classification_id, 'location_id');
		  END LOOP;
		END LOOP;
				
	END LOOP;
      END IF;
      
      RETURN NEW;
      
    END;
$upd_boundary_features$ LANGUAGE plpgsql; 
DROP TRIGGER IF EXISTS upd_boundary_features ON location;
CREATE TRIGGER upd_boundary_features BEFORE INSERT OR UPDATE ON location
    FOR EACH ROW EXECUTE PROCEDURE upd_boundary_features();
    
-- pmt_activity
CREATE OR REPLACE FUNCTION pmt_activity(activity_id integer) RETURNS SETOF pmt_json_result_type AS 
$$
DECLARE
  rec record;
  invalid_return_columns text[];
  return_columns text;
  execute_statement text;
  data_message text;
BEGIN
  IF $1 IS NOT NULL THEN	
    -- set columns that are not to be returned 
    invalid_return_columns := ARRAY['active', 'retired_by', 'created_by', 'created_date'];
    -- get list of columns to return
    SELECT INTO return_columns array_to_string(array_agg('a.' || column_name::text), ', ') FROM information_schema.columns 
    WHERE table_schema='public' AND table_name='activity' AND column_name != ALL(invalid_return_columns);

    -- dynamically build the execute statment	
    execute_statement := 'SELECT ' || return_columns || ', l.location_ct, l.admin_bnds ';

    -- taxonomy	
    execute_statement := execute_statement || ',(SELECT array_to_json(array_agg(row_to_json(t))) FROM ( ' ||
				'select tc.taxonomy_id, tc.taxonomy, tc.classification_id, tc.classification, tc.code ' ||
				'from activity_taxonomy at ' ||
				'join taxonomy_classifications  tc ' ||
				'on at.classification_id = tc.classification_id ' ||
				'and at.activity_id = ' || $1 ||
				') t ) as taxonomy ';
    -- organizations			
    execute_statement := execute_statement || ',(SELECT array_to_json(array_agg(row_to_json(p))) FROM ( ' ||
				'select pp.participation_id, o.organization_id, o.name, o.url'  ||
						', (SELECT array_to_json(array_agg(row_to_json(t))) FROM ( ' ||
						'select tc.taxonomy_id, tc.taxonomy, tc.classification_id, tc.classification, tc.code ' ||
						'from participation_taxonomy pt ' ||
						'join taxonomy_classifications tc ' ||
						'on pt.classification_id = tc.classification_id ' ||
						'and pt.participation_id = pp.participation_id ' ||
						') t ) as taxonomy ' ||
				'from participation pp ' ||
				'join organization o ' ||
				'on pp.organization_id = o.organization_id ' ||				
				'where pp.active = true and o.active = true ' ||
				'and pp.activity_id = ' || $1 ||
				') p ) as organizations ';
    -- contacts
    execute_statement := execute_statement || ',(SELECT array_to_json(array_agg(row_to_json(c))) FROM ( ' ||
				'select c.contact_id, c.first_name, c.last_name, c.email, c.organization_id, o.name ' ||
				'from activity_contact ac ' ||
				'join contact c ' ||
				'on ac.contact_id = c.contact_id ' ||
				'left join organization o ' ||
				'on c.organization_id = o.organization_id ' ||
				'where c.active = true and ac.activity_id = ' || $1 ||
				') c ) as contacts ';	
    -- details
    execute_statement := execute_statement || ',(SELECT array_to_json(array_agg(row_to_json(d))) FROM ( ' ||
				'select d.detail_id, d.title, d.description, d.amount ' ||
				'from detail d ' ||				
				'where d.active = true and d.activity_id = ' || $1 ||
				') d ) as details ';					

    -- financials
    execute_statement := execute_statement || ',(SELECT array_to_json(array_agg(row_to_json(f))) FROM ( ' ||
				'select f.financial_id, f.amount'  ||
						', (SELECT array_to_json(array_agg(row_to_json(t))) FROM ( ' ||
						'select tc.taxonomy_id, tc.taxonomy, tc.classification_id, tc.classification, tc.code ' ||
						'from financial_taxonomy ft ' ||
						'join taxonomy_classifications tc ' ||
						'on ft.classification_id = tc.classification_id ' ||
						'and ft.financial_id = f.financial_id ' ||
						') t ) as taxonomy ' ||
				'from financial f ' ||		
				'where f.active = true and f.activity_id = ' || $1 ||
				') f ) as financials ';
											
     -- locations
    execute_statement := execute_statement || ',(SELECT array_agg(l.location_id)::int[]  ' ||
				'from location l ' ||		
				'where l.active = true and l.activity_id = ' || $1 ||
				') as location_ids ';			
								
    -- activity
    execute_statement := execute_statement || 'from (select * from activity a where a.active = true and a.activity_id = ' || $1 || ') a ';
    -- locations
    execute_statement := execute_statement || 'left join ' ||
				'(select ll.activity_id, count(distinct ll.location_id) as location_ct, array_to_string(array_agg(distinct ll.gaul0_name || '','' || ll.gaul1_name || '','' || ll.gaul2_name), '';'') as admin_bnds ' ||
				'from location_lookup ll ' ||
				'where ll.activity_id = ' || $1 ||
				'group by ll.activity_id) l ' ||
				'on a.activity_id = l.activity_id ';


	RAISE NOTICE 'Execute statement: %', execute_statement;			

	FOR rec IN EXECUTE 'SELECT row_to_json(j) FROM (' || execute_statement || ')j' LOOP  		
		RETURN NEXT rec;
	END LOOP;
   END IF;
END;$$ LANGUAGE plpgsql;
/******************************************************************
  pmt_validate_locations
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_validate_locations(location_ids character varying) RETURNS INT[] AS $$
DECLARE 
  valid_location_ids INT[];
  filter_location_ids INT[];
BEGIN 
     IF $1 IS NULL THEN    
       RETURN valid_location_ids;
     END IF;

     filter_location_ids := string_to_array($1, ',')::int[];
     
     SELECT INTO valid_location_ids array_agg(DISTINCT location_id)::INT[] FROM (SELECT location_id FROM location WHERE active = true AND location_id = ANY(filter_location_ids) ORDER BY location_id) AS t;
     
     RETURN valid_location_ids;

EXCEPTION
     WHEN others THEN RETURN NULL;
END; 
$$ LANGUAGE 'plpgsql';
/******************************************************************
  pmt_locations
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
    invalid_return_columns := ARRAY['active', 'retired_by', 'created_by', 'created_date', 'point'];
    -- get list of columns to return
    SELECT INTO return_columns array_to_string(array_agg('l.' || column_name::text), ', ') FROM information_schema.columns 
    WHERE table_schema='public' AND table_name='location' AND column_name != ALL(invalid_return_columns);
    IF (valid_location_ids IS NOT NULL) THEN
      -- dynamically build boundary_features
      FOR rec IN (SELECT spatial_table FROM boundary) LOOP  		
        boundary_tables := array_append(boundary_tables, ' select boundary_id, feature_id, polygon from ' || rec.spatial_table || ' ');   
      END LOOP;
    
      boundary_features:= ' (' || array_to_string(boundary_tables, ' UNION ') || ') as boundary_features ';
    
      -- dynamically build the execute statment	
      execute_statement := 'SELECT ' || return_columns || ' ';

      -- taxonomy	
      execute_statement := execute_statement || ',(SELECT array_to_json(array_agg(row_to_json(t))) FROM ( ' ||
				'select tc.taxonomy_id, tc.taxonomy, tc.classification_id, tc.classification, tc.code ' ||
				'from location_taxonomy lt ' ||
				'join taxonomy_classifications  tc ' ||
				'on lt.classification_id = tc.classification_id ' ||
				'and lt.location_id = l.location_id'
				') t ) as taxonomy ';       							
      -- point
      execute_statement := execute_statement || ', ST_AsGeoJSON(point) as point ';  				
      -- polygon
      execute_statement := execute_statement || ', (SELECT ST_AsGeoJSON(polygon) FROM ' || boundary_features || ' WHERE boundary_id = l.boundary_id AND feature_id = l.feature_id) as polygon ';  
   				
      -- location
      execute_statement := execute_statement || 'from (select * from location l where l.active = true and l.location_id = ANY(ARRAY[' || array_to_string(valid_location_ids, ',') || '])) l ';    


      RAISE NOTICE 'Execute statement: %', execute_statement;			

      FOR rec IN EXECUTE 'SELECT row_to_json(j) FROM (' || execute_statement || ')j' LOOP  		
	  RETURN NEXT rec;
      END LOOP;
      ELSE
         FOR rec IN (SELECT row_to_json(j) FROM(select 'Error: No valid location ids: ' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
      END IF;
   END IF;
END;$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION pmt_project(project_id integer) RETURNS SETOF pmt_json_result_type AS $$
DECLARE
  rec record;
  invalid_return_columns text[];
  return_columns text;
  execute_statement text;
  data_message text;
BEGIN
  IF $1 IS NOT NULL THEN	
    -- set columns that are not to be returned 
    invalid_return_columns := ARRAY['active', 'retired_by', 'created_by', 'created_date'];
    -- get list of columns to return
    SELECT INTO return_columns array_to_string(array_agg('p.' || column_name::text), ', ') FROM information_schema.columns 
    WHERE table_schema='public' AND table_name='project' AND column_name != ALL(invalid_return_columns);

    -- dynamically build the execute statment	
    execute_statement := 'SELECT ' || return_columns;

    -- taxonomy	
    execute_statement := execute_statement || ',(SELECT array_to_json(array_agg(row_to_json(t))) FROM ( ' ||
				'select tc.taxonomy_id, tc.taxonomy, tc.classification_id, tc.classification, tc.code ' ||
				'from project_taxonomy pt ' ||
				'join taxonomy_classifications  tc ' ||
				'on pt.classification_id = tc.classification_id ' ||
				'and pt.project_id = ' || $1 ||
				') t ) as taxonomy ';
    -- organizations			
    execute_statement := execute_statement || ',(SELECT array_to_json(array_agg(row_to_json(p))) FROM ( ' ||
				'select pp.participation_id, o.organization_id, o.name, o.url'  ||
						', (SELECT array_to_json(array_agg(row_to_json(t))) FROM ( ' ||
						'select tc.taxonomy_id, tc.taxonomy, tc.classification_id, tc.classification, tc.code ' ||
						'from participation_taxonomy pt ' ||
						'join taxonomy_classifications tc ' ||
						'on pt.classification_id = tc.classification_id ' ||
						'and pt.participation_id = pp.participation_id ' ||
						') t ) as taxonomy ' ||
				'from participation pp ' ||
				'join organization o ' ||
				'on pp.organization_id = o.organization_id ' ||				
				'where pp.active = true and o.active = true ' ||
				'and pp.activity_id is null and pp.project_id = ' || $1 ||
				') p ) as organizations ';
    -- contacts
    execute_statement := execute_statement || ',(SELECT array_to_json(array_agg(row_to_json(c))) FROM ( ' ||
				'select c.contact_id, c.first_name, c.last_name, c.email, c.organization_id, o.name ' ||
				'from project_contact pc ' ||
				'join contact c ' ||
				'on pc.contact_id = c.contact_id ' ||
				'left join organization o ' ||
				'on c.organization_id = o.organization_id ' ||
				'where c.active = true and pc.project_id = ' || $1 ||
				') c ) as contacts ';					
    -- details
    execute_statement := execute_statement || ',(SELECT array_to_json(array_agg(row_to_json(d))) FROM ( ' ||
				'select d.detail_id, d.title, d.description, d.amount ' ||
				'from detail d ' ||				
				'where d.active = true and d.activity_id is null and d.project_id = ' || $1 ||
				') d ) as details ';

    -- financials
    execute_statement := execute_statement || ',(SELECT array_to_json(array_agg(row_to_json(f))) FROM ( ' ||
				'select f.financial_id, f.amount'  ||
						', (SELECT array_to_json(array_agg(row_to_json(t))) FROM ( ' ||
						'select tc.taxonomy_id, tc.taxonomy, tc.classification_id, tc.classification, tc.code ' ||
						'from financial_taxonomy ft ' ||
						'join taxonomy_classifications tc ' ||
						'on ft.classification_id = tc.classification_id ' ||
						'and ft.financial_id = f.financial_id ' ||
						') t ) as taxonomy ' ||
				'from financial f ' ||				
				'where f.active = true and f.activity_id is null and f.project_id = ' || $1 ||
				') f ) as financials ';
												
    -- activities
    execute_statement := execute_statement || ',(SELECT array_agg(a.activity_id)::int[]  ' ||
				'from activity a ' ||		
				'where a.active = true and a.project_id = ' || $1 ||
				') as activity_ids ';		
				
    -- locations
    execute_statement := execute_statement || ',(SELECT array_agg(l.location_id)::int[]  ' ||
				'from location l ' ||		
				'where l.active = true and l.project_id = ' || $1 ||
				') as location_ids ';		
								
    -- project
    execute_statement := execute_statement || 'from (select * from project p where p.active = true and p.project_id = ' || $1 || ') p ';
   

	RAISE NOTICE 'Execute statement: %', execute_statement;			

	FOR rec IN EXECUTE 'SELECT row_to_json(j) FROM (' || execute_statement || ')j' LOOP  		
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