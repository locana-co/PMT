/******************************************************************
Change Script 3.0.10.65
1. update pmt_upd_boundary_features to only execute when boundary
feature or point is updated
2. update trigger function pmt_upd_geometry_formats to only execute 
when point is updated
3. update pmt_activity function to add _admin_level
******************************************************************/
INSERT INTO version(_version, _iteration, _changeset) VALUES (3.0, 10, 65);
-- select * from version order by _iteration desc, _changeset desc;

/******************************************************************
1. update pmt_upd_boundary_features to only execute when boundary
feature or point is updated
******************************************************************/
-- upd_boundary_features
CREATE OR REPLACE FUNCTION pmt_upd_boundary_features()
RETURNS trigger AS $pmt_upd_boundary_features$
DECLARE
  calculate boolean;
  boundary record;
  feature record;
  ft record;
  feature_spatial_table text;
  feature_group text;
  simple_polygon_boundary text;
  simple_polygon_feature text;
  feature_statement text;
  error_msg text;
BEGIN

    calculate:= false;
  -- only need to update the geometry information if the point has changed
  IF TG_OP = 'UPDATE' THEN
      -- only need to update the boundary information if the boundary_id, feature_id or point values change
    IF ((NEW.boundary_id <> OLD.boundary_id) OR (NEW.boundary_id IS NULL AND OLD.boundary_id IS NOT NULL) OR (NEW.boundary_id IS NOT NULL AND OLD.boundary_id IS NULL)
      OR (NEW.feature_id <> OLD.feature_id) OR (NEW.feature_id IS NULL AND OLD.feature_id IS NOT NULL) OR (NEW.feature_id IS NOT NULL AND OLD.feature_id IS NULL)
      OR (ST_Equals(NEW._point,OLD._point)=false) OR (NEW._point IS NULL AND OLD._point IS NOT NULL) OR (NEW._point IS NOT NULL AND OLD._point IS NULL)) THEN
        calculate:=true;
    END IF;
  ELSE
    IF NEW._point IS NOT NULL THEN
      calculate:=true;
    END IF;
  END IF;
  

  IF calculate THEN
    -- Remove all existing location boundary information for this location (to be recreated by this trigger)
    EXECUTE 'DELETE FROM location_boundary WHERE location_id = ' || NEW.id;
    RAISE NOTICE 'Refreshing boundary features for id % ...', NEW.id; 

    -- if the location is an exact location (point), then intersect all boundaries
    IF (NEW.boundary_id IS NULL AND NEW.feature_id IS NULL) THEN
      -- loop through each available boundary
      FOR boundary IN SELECT * FROM boundary LOOP
        -- find the feature in the boundary, interescted by our point
        FOR feature IN EXECUTE 'SELECT * FROM ' || quote_ident(boundary._spatial_table)  || ' WHERE ST_Intersects(ST_PointFromText(''' || 
		ST_AsText(NEW._point) || ''', 4326), _polygon)' LOOP
	  -- RAISE NOTICE 'Found intersecting boundary for %', boundary._spatial_table;
	  -- for each intersected feature, record its values in the location_boundary table
	  EXECUTE 'INSERT INTO location_boundary VALUES (' || NEW.id || ', ' || feature.boundary_id || ', ' || feature.id || ', ' || quote_literal(feature._name) || ')';
	  -- assign all associated taxonomy classification from intersected features to new location
	  FOR ft IN (SELECT * FROM feature_taxonomy WHERE feature_taxonomy.feature_id = feature.id AND feature_taxonomy.boundary_id = feature.boundary_id) LOOP	  
	    IF ft IS NOT NULL THEN
	    -- RAISE NOTICE 'Found feature taxonomy for feature id %', ft.feature_id;
	    -- RAISE NOTICE 'Found feature taxonomy as classification id %', ft.classification_id;
	      -- replace all previous taxonomy classification associations with new for the given taxonomy
  	      DELETE FROM location_taxonomy WHERE location_id = NEW.id AND classification_id IN 
		(SELECT classification_id FROM _taxonomy_classifications WHERE taxonomy_id = (SELECT taxonomy_id FROM classification WHERE classification.id = ft.classification_id));    
	      INSERT INTO location_taxonomy VALUES (NEW.id, ft.classification_id, 'id');
	    END IF;
	  END LOOP;
        END LOOP;	
      END LOOP;
    -- if the location is polygon feature, then only intersect boundaries that are less than or equal administrative levels
    ELSE
      -- get the spatial table of the location feature
      SELECT INTO feature_spatial_table _spatial_table FROM boundary WHERE id = NEW.boundary_id; 
      -- get the boundary group of the location feature
      SELECT INTO feature_group _group FROM boundary WHERE id = NEW.boundary_id; 
      -- loop through each available boundary that has an administrative level equal to or less than the location feature
      FOR boundary IN SELECT * FROM boundary WHERE (_admin_level IS NULL OR _admin_level <= NEW._admin_level) AND (_group = 'global' OR _group = feature_group)  LOOP
        -- get the simple polygon column for the boundary
        EXECUTE 'SELECT column_name FROM information_schema.columns WHERE table_name = ''' || quote_ident(boundary._spatial_table)  || ''' AND column_name = ''_polygon_simple_med''' INTO simple_polygon_boundary;
        -- get the simple polygon column for the feature
        EXECUTE 'SELECT column_name FROM information_schema.columns WHERE table_name = ''' || quote_ident(feature_spatial_table)  || ''' AND column_name = ''_polygon_simple_med''' INTO simple_polygon_feature;
        -- boundary and feature are the same
        IF boundary._spatial_table = feature_spatial_table THEN 
          feature_statement := 'SELECT id, boundary_id, _name FROM ' || quote_ident(feature_spatial_table)  || ' WHERE id = ' || NEW.feature_id;
          -- find the feature in the boundary, interescted by our point
          FOR feature IN EXECUTE feature_statement LOOP
	    EXECUTE 'INSERT INTO location_boundary VALUES (' || NEW.id || ', ' || feature.boundary_id || ', ' || feature.id || ', ' || quote_literal(feature._name) || ')';	  
          END LOOP;
        -- boundary and feature are different do an intersection
        ELSE    
          -- boundary has a simple polygon
          IF simple_polygon_boundary IS NOT NULL THEN
            RAISE NOTICE 'Boundary % has a simplified polgon', boundary._spatial_table;
            IF simple_polygon_feature IS NOT NULL THEN
              RAISE NOTICE 'Feature % has a simplified polgon', feature_spatial_table;
              feature_statement := 'SELECT b.id, b.boundary_id, b._name FROM ' || quote_ident(boundary._spatial_table)  || ' b, ' ||
	        '(SELECT _polygon_simple_med FROM ' || quote_ident(feature_spatial_table)  || ' WHERE id = ' || NEW.feature_id || ') l ' ||
	        'WHERE ST_Intersects(b._polygon_simple_med, l._polygon_simple_med) AND (ST_Area(ST_Intersection(b._polygon_simple_med, l._polygon_simple_med))/ST_Area(l._polygon_simple_med)) > .85';
            ELSE
	      RAISE NOTICE 'Feature % does not have a simplified polgon', feature_spatial_table;
              feature_statement := 'SELECT b.id, b.boundary_id, b._name FROM ' || quote_ident(boundary._spatial_table)  || ' b, ' ||
	        '(SELECT _polygon FROM ' || quote_ident(feature_spatial_table)  || ' WHERE id = ' || NEW.feature_id || ') l ' ||
	        'WHERE ST_Intersects(b._polygon_simple_med, l._polygon) AND (ST_Area(ST_Intersection(b._polygon_simple_med, l._polygon))/ST_Area(l._polygon)) > .85';
            END IF;	
          -- boundary does not have a simple polygon
          ELSE
	  RAISE NOTICE 'Boundary % does NOT have a simplified polgon',boundary._spatial_table;
            IF simple_polygon_feature IS NOT NULL THEN
              RAISE NOTICE 'Feature % has a simplified polgon', feature_spatial_table;
	      feature_statement := 'SELECT b.id, b.boundary_id, b._name FROM ' || quote_ident(boundary._spatial_table)  || ' b, ' ||
	        '(SELECT _polygon_simple_med FROM ' || quote_ident(feature_spatial_table)  || ' WHERE id = ' || NEW.feature_id || ') l ' ||
	        'WHERE ST_Intersects(b._polygon, l._polygon_simple_med) AND (ST_Area(ST_Intersection(b._polygon, l._polygon_simple_med))/ST_Area(l._polygon_simple_med)) > .85';
	    ELSE	
	      RAISE NOTICE 'Feature % does not have a simplified polgon', feature_spatial_table;
	      feature_statement := 'SELECT b.id, b.boundary_id, b._name FROM ' || quote_ident(boundary._spatial_table)  || ' b, ' ||
	        '(SELECT _polygon FROM ' || quote_ident(feature_spatial_table)  || ' WHERE id = ' || NEW.feature_id || ') l ' ||
	        'WHERE ST_Intersects(b._polygon, l._polygon) AND (ST_Area(ST_Intersection(b._polygon, l._polygon))/ST_Area(l._polygon)) > .85';
	    END IF;
          END IF;
          -- find the feature in the boundary, interescted by our point
          FOR feature IN EXECUTE feature_statement LOOP
	    -- RAISE NOTICE 'Found intersecting boundary for %', boundary._spatial_table;
	    -- for each intersected feature, record its values in the location_boundary table
	    EXECUTE 'INSERT INTO location_boundary VALUES (' || NEW.id || ', ' || feature.boundary_id || ', ' || feature.id || ', ' || quote_literal(feature._name) || ')';
	    -- assign all associated taxonomy classification from intersected features to new location
	    FOR ft IN (SELECT * FROM feature_taxonomy WHERE feature_taxonomy.feature_id = feature.id AND feature_taxonomy.boundary_id = feature.boundary_id) LOOP	  
	      IF ft IS NOT NULL THEN
	        -- RAISE NOTICE 'Found feature taxonomy for feature id %', ft.feature_id;
	        -- RAISE NOTICE 'Found feature taxonomy as classification id %', ft.classification_id;
	        -- replace all previous taxonomy classification associations with new for the given taxonomy
  	        DELETE FROM location_taxonomy WHERE location_id = NEW.id AND classification_id IN 
	    	  (SELECT classification_id FROM _taxonomy_classifications WHERE taxonomy_id = (SELECT taxonomy_id FROM classification WHERE classification.id = ft.classification_id));    
	        INSERT INTO location_taxonomy VALUES (NEW.id, ft.classification_id, 'id');
	      END IF;
	    END LOOP;
          END LOOP;
        END IF;	
      END LOOP;
    END IF;  
  END IF;
  
RETURN NEW;

EXCEPTION WHEN others THEN 
  GET STACKED DIAGNOSTICS error_msg = MESSAGE_TEXT;  
    RAISE NOTICE 'Internal Error - Contact your DBA with the following error message: %', ' Location id (' || NEW.id || ') - ' || error_msg;
END;
$pmt_upd_boundary_features$ LANGUAGE plpgsql; 
DROP TRIGGER IF EXISTS pmt_upd_boundary_features ON location;
CREATE TRIGGER pmt_upd_boundary_features AFTER INSERT OR UPDATE ON location
    FOR EACH ROW EXECUTE PROCEDURE pmt_upd_boundary_features();

    
/******************************************************************
2. update trigger function pmt_upd_geometry_formats to only execute 
when point is updated
******************************************************************/
-- upd_geometry_formats
DROP FUNCTION IF EXISTS upd_geometry_formats();
CREATE OR REPLACE FUNCTION pmt_upd_geometry_formats()
RETURNS trigger AS $pmt_upd_geometry_formats$
DECLARE
  calculate boolean;
BEGIN	
  calculate:= false;
  -- only need to update the geometry information if the point has changed
  IF TG_OP = 'UPDATE' THEN
    IF ((ST_Equals(NEW._point,OLD._point)=false) OR (NEW._point IS NULL AND OLD._point IS NOT NULL) OR (NEW._point IS NOT NULL AND OLD._point IS NULL))THEN
      calculate:=true;
    END IF;
  ELSE
    IF NEW._point IS NOT NULL THEN
      calculate:=true;
    END IF;
  END IF;
  
  IF calculate THEN
    RAISE NOTICE 'Refreshing geometry formats for id % ...', NEW.id;
    IF ST_IsEmpty(NEW._point) THEN
      -- no geometry
      RAISE NOTICE 'The point was empty cannot format.';
    ELSE	
      NEW._lat_dd := CAST(substring(ST_AsLatLonText(NEW._point, 'D.DDDDDD') from 0 for position(' ' in ST_AsLatLonText(NEW._point, 'D.DDDDDD'))) AS decimal);
      --RAISE NOTICE 'Latitude Decimal Degrees: %', NEW._lat_dd;
      NEW._long_dd := CAST(substring(ST_AsLatLonText(NEW._point, 'D.DDDDDD') from position(' ' in ST_AsLatLonText(NEW._point, 'D.DDDDDD')) for octet_length(ST_AsLatLonText(NEW._point, 'D.DDDDDD')) - position(' ' in ST_AsLatLonText(NEW._point, 'D.DDDDDD')) ) AS decimal);
      --RAISE NOTICE 'Longitude Decimal Degrees: %', NEW._long_dd;
      NEW._latlong := ST_AsLatLonText(NEW._point, 'D°M''S"C');
      --RAISE NOTICE 'The Latitude/Longitude is: %', NEW._latlong;
      NEW._x := CAST(ST_X(ST_Transform(ST_SetSRID(NEW._point,4326),3857)) AS integer); 
      --RAISE NOTICE 'The x is: %', NEW._x;
      NEW._y := CAST(ST_Y(ST_Transform(ST_SetSRID(NEW._point,4326),3857)) AS integer);
      --RAISE NOTICE 'The y is: %', NEW._y;
      -- Remember when location was added/updated
      NEW._updated_date := current_timestamp;			
    END IF;
  END IF;

RETURN NEW;

END;
$pmt_upd_geometry_formats$ LANGUAGE plpgsql; 
DROP TRIGGER IF EXISTS pmt_upd_geometry_formats ON location;
CREATE TRIGGER pmt_upd_geometry_formats BEFORE INSERT OR UPDATE ON location
    FOR EACH ROW EXECUTE PROCEDURE pmt_upd_geometry_formats();

/******************************************************************
3. update pmt_activity function to add _admin_level
  SELECT * FROM pmt_activity(23608);
  SELECT * FROM pmt_activity(12791);  
******************************************************************/
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
    invalid_return_columns := ARRAY['_active', '_retired_by', '_created_by', '_created_date'];
    -- get list of columns to return
    SELECT INTO return_columns array_to_string(array_agg('a.' || column_name::text), ', ') FROM information_schema.columns 
    WHERE table_schema='public' AND table_name='activity' AND column_name != ALL(invalid_return_columns);

    -- dynamically build the execute statment	
    execute_statement := 'SELECT ' || return_columns || ', (SELECT _name FROM classification WHERE id = data_group_id) as data_group' || 
				', (SELECT _title FROM activity WHERE id = a.parent_id) as parent_title, l.ct ';

    -- taxonomy	
    execute_statement := execute_statement || ',(SELECT array_to_json(array_agg(row_to_json(t))) FROM ( ' ||
				'select tc.taxonomy_id, tc.taxonomy, tc.classification_id, tc.classification, tc._code ' ||
				'from activity_taxonomy at ' ||
				'join _taxonomy_classifications  tc ' ||
				'on at.classification_id = tc.classification_id ' ||
				'and at.activity_id = ' || $1 ||
				') t ) as taxonomy ';
    -- organizations			
    execute_statement := execute_statement || ',(SELECT array_to_json(array_agg(row_to_json(p))) FROM ( ' ||
				'select _name as organization, classification as role, _url as url, _address1 as address, '  ||
				'_city as city, _state_providence as state_providence, _postal_code as zip, _country as country ' ||
				'from _organization_lookup ol join organization o on ol.organization_id = o.id ' ||
				'where activity_id = ' || $1 ||
				') p ) as organizations ';
				
    -- contacts
    execute_statement := execute_statement || ',(SELECT array_to_json(array_agg(row_to_json(c))) FROM ( ' ||
				'select c.id, c._first_name, c._last_name, c._email, c.organization_id, o._name ' ||
				'from activity_contact ac ' ||
				'join contact c ' ||
				'on ac.contact_id = c.id ' ||
				'left join organization o ' ||
				'on c.organization_id = o.id ' ||
				'where c._active = true and ac.activity_id = ' || $1 ||
				') c ) as contacts ';	
    -- details
    execute_statement := execute_statement || ',(SELECT array_to_json(array_agg(row_to_json(d))) FROM ( ' ||
				'select d.id, d._title, d._description, d._amount ' ||
				'from detail d ' ||				
				'where d._active = true and d.activity_id = ' || $1 ||
				') d ) as details ';					

    -- financials
    execute_statement := execute_statement || ',(SELECT array_to_json(array_agg(row_to_json(f))) FROM ( ' ||
				'select f.id, f._amount, f._start_date, f._end_date '  ||
						',(SELECT _name FROM organization WHERE id = provider_id) as provider' ||
						',(SELECT _name FROM organization WHERE id = recipient_id) as recipient' ||
						', (SELECT array_to_json(array_agg(row_to_json(t))) FROM ( ' ||
						'select tc.taxonomy_id, tc.taxonomy, tc.classification_id, tc.classification, tc._code ' ||
						'from financial_taxonomy ft ' ||
						'join _taxonomy_classifications tc ' ||
						'on ft.classification_id = tc.classification_id ' ||
						'and ft.financial_id = f.id ' ||
						') t ) as taxonomy ' ||
				'from financial f ' ||		
				'where f._active = true and f.activity_id = ' || $1 ||
				') f ) as financials ';
											
     -- locations
    execute_statement := execute_statement || ',(SELECT array_agg(l.id)::int[]  ' ||
				'from location l ' ||		
				'where l._active = true and l.activity_id = ' || $1 ||
				') as location_ids ';	

    -- locations
    execute_statement := execute_statement || ',(SELECT array_to_json(array_agg(row_to_json(l))) FROM (  ' ||
				'select l.id, l._admin1, l._admin2, l._admin3, l._admin_level ' ||
					', (SELECT array_to_json(array_agg(row_to_json(t))) FROM ( ' ||
					'select tc.taxonomy_id, tc.taxonomy, tc.classification_id, tc.classification, tc._code ' ||
					'from location_taxonomy lt ' ||
					'join _taxonomy_classifications tc ' ||
					'on lt.classification_id = tc.classification_id ' ||
					'and lt.location_id = l.id ' ||
					') t ) as taxonomy ' ||
					', (SELECT array_to_json(array_agg(row_to_json(b))) FROM ( ' ||
					'select lb.boundary_id, lb.feature_id, lb._feature_name ' ||
					'from location_boundary lb ' ||					
					'where lb.location_id = l.id ' ||
					') b ) as boundaries ' ||
				'from location l ' ||		
				'where l._active = true and l.activity_id = ' || $1 ||
				') l ) as locations ';		

    -- children
    execute_statement := execute_statement || ',(SELECT array_to_json(array_agg(row_to_json(a))) FROM (  ' ||
				'select a.id, a._title ' ||					
				'from activity a ' ||		
				'where a._active = true and a.parent_id = ' || $1 ||
				') a ) as children ';	
													
								
    -- activity
    execute_statement := execute_statement || 'from (select * from activity a where a._active = true and a.id = ' || $1 || ') a ';
    -- locations
    execute_statement := execute_statement || 'left join ' ||
				'(select ll.activity_id, count(distinct ll.location_id) as ct ' ||
				'from _location_lookup ll ' ||
				'where ll.activity_id = ' || $1 ||
				'group by ll.activity_id) l ' ||
				'on a.id = l.activity_id ';


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