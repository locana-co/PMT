/******************************************************************
Change Script 3.0.10.81
 1. fix pmt_upd_boundary_features functions so that location taxonomy
 is grabbed for the location feature, not just intersected features
 2. address error in pmt_activities on selecting financial information
******************************************************************/
INSERT INTO version(_version, _iteration, _changeset) VALUES (3.0, 10, 81);
-- select * from version order by _iteration desc, _changeset desc;

/******************************************************************
 1. fix pmt_upd_boundary_features functions so that location taxonomy
 is grabbed for the location feature, not just intersected features
******************************************************************/
-- upd_boundary_features
CREATE OR REPLACE FUNCTION pmt_upd_boundary_features()
RETURNS trigger AS $pmt_upd_boundary_features$
DECLARE
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
    FOR boundary IN SELECT * FROM boundary WHERE (_admin_level IS NULL OR _admin_level <= NEW._admin_level)  LOOP
      IF (feature_group = 'global') OR (boundary._group = 'global') OR (feature_group = boundary._group) THEN     
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
      END IF;	
    END LOOP;
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
2. address error in pmt_activities on selecting financial information
   select * from pmt_activities('2237',null,null,null,null,null,null,null,null,null); 
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_activities(data_group_ids character varying, classification_ids character varying, org_ids character varying,
imp_org_ids character varying, fund_org_ids character varying, start_date date, end_date date, unassigned_taxonomy_ids character varying, 
activity_ids character varying, boundary_filter json) RETURNS SETOF pmt_json_result_type AS
$$
DECLARE
  filtered_activity_ids int[];
  a_ids int[];
  valid_activity_ids int[];
  boundary_json json;
  boundary_filters text[];
  boundary_statement text;
  boundary_activity_ids int[];
  execute_statement text; 
  json record;   
  rec record;
  error_msg text;
BEGIN
  -- get the filtered activity ids
  SELECT INTO filtered_activity_ids * FROM pmt_filter($1,$2,$3,$4,$5,$6,$7,$8);

  -- get the list of activity ids
  IF ($9 IS NOT NULL OR $9 <> '' ) THEN
    a_ids:= string_to_array($9, ',')::int[];
    SELECT INTO valid_activity_ids array_agg(id) FROM activity WHERE _active = true AND id = ANY(a_ids);
  END IF;
 
  -- get the filtered activity ids by boundary
  IF ($10 IS NOT NULL) THEN
    RAISE NOTICE 'json was not null';      
    FOR boundary_json IN (SELECT * FROM json_array_elements($10)) LOOP
      FOR json IN (SELECT * FROM json_each_text(boundary_json)) LOOP
        -- RAISE NOTICE 'JSON key/value: %', lower(json.key) || ':' || json.value;          
        CASE json.key::text 
          WHEN 'b' THEN
            boundary_statement := ' (ll.boundary_id = ' || json.value::int;
          WHEN 'ids' THEN
            boundary_statement := boundary_statement || ' AND ll.feature_id = ANY(ARRAY' || json.value || ')) ';
            boundary_filters := array_append(boundary_filters, boundary_statement);
          ELSE
        END CASE;
      END LOOP;
    END LOOP;
    IF array_length(boundary_filters, 1) > 0 THEN
      EXECUTE 'SELECT array_agg(activity_id)::int[] FROM _location_lookup ll WHERE' ||  array_to_string(boundary_filters, 'OR') INTO boundary_activity_ids;
    END IF;
  END IF;
  
  execute_statement:= 'SELECT a.id, parent_id as pid, data_group_id as dgid, (SELECT _name FROM classification WHERE id = data_group_id) as dg, ' ||
		'_title as t, sum(_amount) as a, a._start_date as sd, a._end_date as ed, array_agg( o._name) as f' ||
		' FROM (SELECT id, parent_id, data_group_id, _title, _start_date, _end_date FROM activity WHERE _active = true AND id = ANY(ARRAY[' || array_to_string(filtered_activity_ids, ',') || ']) ';

  -- add filter for activities in list
  IF array_length(valid_activity_ids, 1) > 0 THEN
    execute_statement:= execute_statement || 'AND id = ANY(ARRAY[' || array_to_string(valid_activity_ids, ',') || ']) ';
  END IF;

  -- add filter for boundary		
  IF array_length(boundary_activity_ids, 1) > 0 THEN
    execute_statement:= execute_statement || 'AND id = ANY(ARRAY[' || array_to_string(boundary_activity_ids, ',') || ']) ';
  END IF;
  		
  execute_statement:= execute_statement || ') a' ||
  		' LEFT JOIN (SELECT id, activity_id, _amount, provider_id FROM financial WHERE _active = true) f ' ||
  		' ON a.id = f.activity_id ' ||
  		' LEFT JOIN ( select financial_id, classification, _code ' ||
				' FROM financial_taxonomy ft ' ||
				' JOIN _taxonomy_classifications tc ' ||
				' on ft.classification_id = tc.classification_id ' ||
				' where tc.taxonomy = ''Transaction Type''' || 
				'OR classification IS NULL OR classification = ''Incoming Funds'' OR classification = ''Commitment'' ) as ft ' ||
		'ON ft.financial_id = f.id ' ||
		'LEFT JOIN (SELECT id, _name FROM _activity_participants WHERE classification = ''Funding'') o ON a.id = o.id ' ||
		'GROUP BY 1,2,3,4,5,7,8 ';


  RAISE NOTICE 'Execute statement: %', execute_statement;

  FOR rec IN EXECUTE 'SELECT row_to_json(j) FROM (' || execute_statement || ')j' LOOP
	RETURN NEXT rec;
  END LOOP;

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