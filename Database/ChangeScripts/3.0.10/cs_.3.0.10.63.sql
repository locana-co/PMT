/******************************************************************
Change Script 3.0.10.63
1. add location constraints to _point and _admin_level fields
  (ensure all fields have values via a data script prior to setting)
2. remove functions that will not be updated for 3.0. 
3. remove _feature_area from _location_boundary_features view
4. remove _feature_area from tanaim_aaz view & recreate tanaim_nbs
5. remove _feature_area from location_boundary
6. update pmt_activity function to remove _feature_area
7. add _group to boundary
8. update pmt_boundary_hierarchy to allow filter for in-use features
9. update pmt_upd_boundary_features to alter logic to only collect
boundary features for boundaries appropriate for mapping level
10. update trigger function upd_geometry_formats to remove georef 
11. update pmt_locations_for_boundaries to correct parameter validation error
12. update pmt_activities to add boundary filter
13. update ALL active locations
******************************************************************/
INSERT INTO version(_version, _iteration, _changeset) VALUES (3.0, 10, 63);
-- select * from version order by _iteration desc, _changeset desc;

/*************************************************************************
  1. add location constraints to _point and _admin_level fields
  (ensure all fields have values via a data script prior to setting)
*************************************************************************/
ALTER TABLE location ADD CONSTRAINT chk_location_point CHECK (_point IS NOT NULL) NOT VALID;
ALTER TABLE location ADD CONSTRAINT chk_location_admin_level CHECK (_admin_level IS NOT NULL) NOT VALID;

/*************************************************************************
  2. remove functions that will not be updated for 3.0.     
*************************************************************************/
DROP FUNCTION IF EXISTS pmt_activities_by_tax(integer, integer, character varying);
DROP FUNCTION IF EXISTS pmt_activity_listview(character varying, character varying, character varying, date, date, character varying, text, integer, integer);
DROP FUNCTION IF EXISTS pmt_activity_listview_ct(character varying, character varying, character varying, date, date);
DROP FUNCTION IF EXISTS pmt_locations_by_org(integer, integer, character varying);
DROP FUNCTION IF EXISTS pmt_locations_by_tax(integer, character varying, character varying);
DROP FUNCTION IF EXISTS pmt_locations_by_tax(integer, integer, character varying);
DROP FUNCTION IF EXISTS pmt_sector_compare(character varying, character varying);
DROP FUNCTION IF EXISTS pmt_stat_activity_by_district(integer, character varying, character varying, integer);
DROP FUNCTION IF EXISTS pmt_stat_counts(character varying, character varying, character varying, date, date);
DROP FUNCTION IF EXISTS pmt_stat_locations(character varying, character varying, character varying, date, date);
DROP FUNCTION IF EXISTS pmt_stat_orgs_by_activity(integer, character varying, character varying, character varying, date, date);
DROP FUNCTION IF EXISTS pmt_stat_orgs_by_district(integer, character varying, character varying, integer, integer);
DROP FUNCTION IF EXISTS pmt_stat_partner_network(character varying);
DROP FUNCTION IF EXISTS pmt_stat_pop_by_district(character varying, character varying);
DROP FUNCTION IF EXISTS tanaim_activity(integer);

/*************************************************************************
 3. remove _feature_area from _location_boundary_features view
*************************************************************************/
DROP VIEW IF EXISTS tanaim_aaz;
DROP VIEW IF EXISTS tanaim_nbs;
DROP VIEW IF EXISTS _location_boundary_features;

CREATE OR REPLACE VIEW _location_boundary_features AS 
 SELECT l.id AS location_id,
    l.activity_id,
    lb.boundary_id,
    b._name AS boundary_name,
    lb.feature_id,
    lb._feature_name AS feature_name
   FROM location l
     JOIN location_boundary lb ON l.id = lb.location_id
     JOIN boundary b ON lb.boundary_id = b.id
  ORDER BY l.id, lb.boundary_id; 

/*************************************************************************
 4. remove _feature_area from tanaim_aaz view & recreate tanaim_nbs
*************************************************************************/
CREATE OR REPLACE VIEW tanaim_aaz AS 
 SELECT DISTINCT a.id AS activity_id,
    a._title AS title,
    dg.classification AS data_group,
    c.category,
    sc.sub_category,
    l.id AS location_id,
    l._lat_dd,
    l._long_dd,
    l._point,
        CASE
            WHEN lb._feature_name::text = 'Arusha'::text THEN 'Northern'::character varying
            WHEN lb._feature_name::text = 'Dodoma'::text THEN 'Central'::character varying
            WHEN lb._feature_name::text = 'Singida'::text THEN 'Central'::character varying
            WHEN lb._feature_name::text = 'Dar es Salaam'::text THEN 'Eastern'::character varying
            WHEN lb._feature_name::text = 'Kigoma'::text THEN 'Western'::character varying
            WHEN lb._feature_name::text = 'Morogoro'::text THEN 'Eastern'::character varying
            WHEN lb._feature_name::text = 'Pemba North'::text THEN 'Eastern'::character varying
            WHEN lb._feature_name::text = 'Pemba South'::text THEN 'Eastern'::character varying
            WHEN lb._feature_name::text = 'Pwani'::text THEN 'Eastern'::character varying
            WHEN lb._feature_name::text = 'Tanga'::text THEN 'Eastern'::character varying
            WHEN lb._feature_name::text = 'Unguja North'::text THEN 'Eastern'::character varying
            WHEN lb._feature_name::text = 'Unguja South'::text THEN 'Eastern'::character varying
            WHEN lb._feature_name::text = 'Unguja Urban West'::text THEN 'Eastern'::character varying
            WHEN lb._feature_name::text = 'Kagera'::text THEN 'Lake'::character varying
            WHEN lb._feature_name::text = 'Mara'::text THEN 'Lake'::character varying
            WHEN lb._feature_name::text = 'Mwanza'::text THEN 'Lake'::character varying
            WHEN lb._feature_name::text = 'Shinyanga'::text THEN 'Lake'::character varying
            WHEN lb._feature_name::text = 'Arusha'::text THEN 'Northern'::character varying
            WHEN lb._feature_name::text = 'Kilimanjaro'::text THEN 'Northern'::character varying
            WHEN lb._feature_name::text = 'Manyara'::text THEN 'Northern'::character varying
            WHEN lb._feature_name::text = 'Lindi'::text THEN 'Southern '::character varying
            WHEN lb._feature_name::text = 'Mtwara'::text THEN 'Southern '::character varying
            WHEN lb._feature_name::text = 'Iringa'::text THEN 'Southern Highlands'::character varying
            WHEN lb._feature_name::text = 'Mbeya'::text THEN 'Southern Highlands'::character varying
            WHEN lb._feature_name::text = 'Rukwa'::text THEN 'Southern Highlands'::character varying
            WHEN lb._feature_name::text = 'Ruvuma'::text THEN 'Southern Highlands'::character varying
            WHEN lb._feature_name::text = 'Tabora'::text THEN 'Western'::character varying
            ELSE lb._feature_name
        END AS aaz
   FROM activity a
     JOIN location l ON a.id = l.activity_id
     LEFT JOIN location_boundary lb ON l.id = lb.location_id
     LEFT JOIN _taxonomy_classifications dg ON a.data_group_id = dg.classification_id
     LEFT JOIN activity_taxonomy at ON a.id = at.activity_id
     LEFT JOIN _taxonomy_classifications tc ON at.classification_id = tc.classification_id
     LEFT JOIN ( SELECT at_1.activity_id,
            at_1.classification_id,
            tc_1.classification AS category
           FROM activity_taxonomy at_1
             JOIN _taxonomy_classifications tc_1 ON at_1.classification_id = tc_1.classification_id
          WHERE tc_1.taxonomy::text = 'Category'::text) c ON a.id = c.activity_id
     LEFT JOIN ( SELECT at_1.activity_id,
            at_1.classification_id,
            tc_1.classification AS sub_category
           FROM activity_taxonomy at_1
             JOIN _taxonomy_classifications tc_1 ON at_1.classification_id = tc_1.classification_id
          WHERE tc_1.taxonomy::text = 'Sub-Category'::text) sc ON a.id = sc.activity_id
  WHERE a._active = true AND lb.boundary_id = (( SELECT boundary.id
           FROM boundary
          WHERE boundary._spatial_table::text = 'gaul1'::text)) AND (l.id IN ( SELECT location_taxonomy.location_id
           FROM location_taxonomy
          WHERE location_taxonomy.classification_id = (( SELECT _taxonomy_classifications.classification_id
                   FROM _taxonomy_classifications
                  WHERE _taxonomy_classifications.taxonomy::text = 'Country'::text AND _taxonomy_classifications.classification::text = 'TANZANIA, UNITED REPUBLIC OF'::text)))) AND NOT (a.id IN ( SELECT activity_taxonomy.activity_id
           FROM activity_taxonomy
          WHERE activity_taxonomy.classification_id = (( SELECT _taxonomy_classifications.classification_id
                   FROM _taxonomy_classifications
                  WHERE _taxonomy_classifications.taxonomy::text = 'National/Local'::text AND _taxonomy_classifications.classification::text = 'National'::text))))
  ORDER BY a.id;

CREATE OR REPLACE VIEW tanaim_nbs AS 
 SELECT a.id AS activity_id,
    a._title AS title,
    l.id AS location_id,
    l._lat_dd AS lat_dd,
    l._long_dd AS long_dd,
    l._point AS point,
    ( SELECT lbf.feature_name
           FROM _location_boundary_features lbf
          WHERE lbf.boundary_id = (( SELECT boundary.id
                   FROM boundary
                  WHERE boundary._name::text = 'GAUL Level 0'::text)) AND lbf.location_id = l.id
         LIMIT 1) AS "Country (Gaul0)",
    ( SELECT lbf.feature_name
           FROM _location_boundary_features lbf
          WHERE lbf.boundary_id = (( SELECT boundary.id
                   FROM boundary
                  WHERE boundary._name::text = 'GAUL Level 1'::text)) AND lbf.location_id = l.id
         LIMIT 1) AS "Region (Gaul1)",
    ( SELECT lbf.feature_name
           FROM _location_boundary_features lbf
          WHERE lbf.boundary_id = (( SELECT boundary.id
                   FROM boundary
                  WHERE boundary._name::text = 'GAUL Level 2'::text)) AND lbf.location_id = l.id
         LIMIT 1) AS "District (Gaul2)",
    ( SELECT lbf.feature_name
           FROM _location_boundary_features lbf
          WHERE lbf.boundary_id = (( SELECT boundary.id
                   FROM boundary
                  WHERE boundary._name::text = 'NBS Tanzania Regions'::text)) AND lbf.location_id = l.id
         LIMIT 1) AS "Region (NBS2)",
    ( SELECT lbf.feature_name
           FROM _location_boundary_features lbf
          WHERE lbf.boundary_id = (( SELECT boundary.id
                   FROM boundary
                  WHERE boundary._name::text = 'NBS Tanzania Districts'::text)) AND lbf.location_id = l.id
         LIMIT 1) AS "District (NBS1)"
   FROM activity a
     JOIN location l ON a.id = l.activity_id
  WHERE (l.id IN ( SELECT _location_boundary_features.location_id
           FROM _location_boundary_features
          WHERE _location_boundary_features.feature_name::text = 'United Republic of Tanzania'::text))
  ORDER BY a.id, a._title;
   
/*************************************************************************
 5. remove _feature_area from location_boundary
*************************************************************************/
ALTER TABLE location_boundary DROP COLUMN _feature_area;


/******************************************************************
6. update pmt_activity function to remove _feature_area
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
				'select l.id, l._admin1, l._admin2, l._admin3 ' ||
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
   
/*************************************************************************
 7. add _group to boundary
*************************************************************************/
ALTER TABLE boundary ADD COLUMN _group character varying;
UPDATE boundary SET _group = 'global' WHERE _spatial_table = 'gaul0';
UPDATE boundary SET _group = 'global' WHERE _spatial_table = 'gaul1';
UPDATE boundary SET _group = 'global' WHERE _spatial_table = 'gaul2';
UPDATE boundary SET _group = 'tza' WHERE _spatial_table = 'nbs_tza_1';
UPDATE boundary SET _group = 'tza' WHERE _spatial_table = 'nbs_tza_2';
UPDATE boundary SET _group = 'global' WHERE _spatial_table = 'continent';
UPDATE boundary SET _group = 'eth' WHERE _spatial_table = 'eth_1';
UPDATE boundary SET _group = 'eth' WHERE _spatial_table = 'eth_2';
UPDATE boundary SET _group = 'eth' WHERE _spatial_table = 'eth_3';
UPDATE boundary SET _group = 'global' WHERE _spatial_table = 'gadm0';
UPDATE boundary SET _group = 'global' WHERE _spatial_table = 'gadm1';
UPDATE boundary SET _group = 'global' WHERE _spatial_table = 'gadm2';
UPDATE boundary SET _group = 'global' WHERE _spatial_table = 'gadm3';
UPDATE boundary SET _group = 'eth' WHERE _spatial_table = 'eth_acc';
UPDATE boundary SET _group = 'eth' WHERE _spatial_table = 'eth_acc_dissolved';

/******************************************************************
8. update pmt_boundary_hierarchy to allow filter to in-use features
  select * from pmt_boundary_hierarchy('gadm','0,1,2','Ethiopia','2237');
  select * from pmt_boundary_hierarchy('unocha','1,2,3',null,'2237');
******************************************************************/
DROP FUNCTION IF EXISTS pmt_boundary_hierarchy(character varying, character varying, character varying);
CREATE OR REPLACE FUNCTION pmt_boundary_hierarchy(boundary_type character varying, admin_levels character varying, filter_features character varying, data_group_ids character varying) RETURNS SETOF pmt_json_result_type AS
$$
DECLARE
  valid_boundary_type character varying;
  dg_ids int[];
  valid_dg_ids int[];
  boundary_ids integer[];
  boundary_tables text[];
  boundary_id integer;
  boundary_table text;
  parent_admin integer;
  query_string text;
  count integer;
  idx integer;
  execute_statement text;    
  rec record;
  error_msg text;
BEGIN

  -- validate and process boundary_type parameter
  IF $1 IS NOT NULL THEN
    -- validate the boundary type
    SELECT INTO valid_boundary_type DISTINCT _type FROM boundary WHERE _type = $1 AND _active = true;
    IF valid_boundary_type IS NULL THEN
      FOR rec IN SELECT row_to_json(j) FROM( SELECT 'missing valid required parameter' AS error ) as j LOOP RETURN NEXT rec; END LOOP;
    END IF;
  ELSE
    FOR rec IN SELECT row_to_json(j) FROM( SELECT 'missing required parameter' AS error ) as j LOOP RETURN NEXT rec; END LOOP;
  END IF;
  -- process admin_levels parameter and collect boundary ids
  IF $2 IS NOT NULL THEN
    -- collect boundary ids for requested admin levels
    SELECT INTO boundary_ids array_agg(id) FROM (SELECT id FROM boundary WHERE _type = valid_boundary_type AND ARRAY[_admin_level] <@ string_to_array($2, ',')::int[] ORDER BY _admin_level) AS b;
    SELECT INTO boundary_tables array_agg(_spatial_table::text) FROM (SELECT _spatial_table FROM boundary WHERE _type = valid_boundary_type AND ARRAY[_admin_level] <@ string_to_array($2, ',')::int[] ORDER BY _admin_level DESC) AS b;
    -- if admin levels requested results in no boundaries, use all boundaries for the given type
    IF array_length(boundary_ids, 1) <= 0 OR boundary_ids IS NULL THEN
      SELECT INTO boundary_ids array_agg(id) FROM (SELECT id FROM boundary WHERE _type = valid_boundary_type ORDER BY _admin_level) as b;
      SELECT INTO boundary_tables array_agg(_spatial_table::text) FROM (SELECT _spatial_table FROM boundary WHERE _type = valid_boundary_type ORDER BY _admin_level DESC) as b;
    END IF;    
  ELSE
    -- collect all boundary ids for the given type if no admin levels are specified
    SELECT INTO boundary_ids array_agg(id) FROM (SELECT id FROM boundary WHERE _type = valid_boundary_type ORDER BY _admin_level) as b;
    SELECT INTO boundary_tables array_agg(_spatial_table::text) FROM (SELECT _spatial_table FROM boundary WHERE _type = valid_boundary_type ORDER BY _admin_level DESC) as b;
  END IF;
  -- validate and process data_group_ids parameter
  IF $4 IS NOT NULL THEN
    dg_ids:= string_to_array($4, ',')::int[];
    -- validate the data groups id
    SELECT INTO valid_dg_ids array_agg(id)::int[] FROM classification WHERE taxonomy_id = 1 AND _active=true AND id = ANY(dg_ids);
  END IF;

  -- begin execution statement
  execute_statement := 'SELECT ';
  
  count := 0;
  FOREACH boundary_id IN ARRAY boundary_ids LOOP
    execute_statement := execute_statement || boundary_id || ' as b' || count || ', ';
    count := count + 1;
  END LOOP;

  count := 0;
  FOREACH boundary_id IN ARRAY boundary_ids LOOP
    execute_statement := execute_statement || '(SELECT array_to_json(array_agg(row_to_json(b' || count || '))) FROM ( ';
    execute_statement := execute_statement || 'SELECT id, _name as n ';
    -- if not the last element add a comma
    IF (count + 1) < array_length(boundary_ids, 1) THEN
      execute_statement := execute_statement || ',';
    END IF;    
    count := count + 1;
  END LOOP;
  
  count := array_length(boundary_tables, 1);
  idx := 1;
  FOREACH boundary_table IN ARRAY boundary_tables LOOP
    count := count - 1;
    IF count <> 0 THEN
      execute_statement := execute_statement || 'FROM ' || boundary_table || ' '; 
      execute_statement := execute_statement || 'WHERE _' || boundary_tables[idx + 1] || '_name = ' || boundary_tables[idx + 1] || '._name ';
      -- restrict returned results by data group id(s)
      IF array_length(valid_dg_ids, 1) > 0 THEN
        execute_statement := execute_statement || 'AND id IN (SELECT feature_id FROM location_boundary WHERE location_id IN (SELECT id FROM location WHERE activity_id ' ||
        'IN(SELECT id FROM activity WHERE data_group_id = ANY(ARRAY[' || array_to_string(valid_dg_ids, ',') || ']) )) AND boundary_id = ' || boundary_table || '.boundary_id)';
      END IF;      
      execute_statement := execute_statement || ') b' || count || ' ) as b ';  
    ELSE
      execute_statement := execute_statement || 'FROM ' || boundary_table || ' ';
      IF $3 IS NOT NULL OR $3 <> '' THEN
        SELECT INTO query_string array_to_string(array_agg(query), ',') FROM ( SELECT quote_literal(trim(unnest(string_to_array(lower($3), ',')))) as query) as foo;
        execute_statement := execute_statement || 'WHERE lower(_name) IN (' || query_string || ')'; 
	-- restrict returned results by data group id(s)
        IF array_length(valid_dg_ids, 1) > 0 THEN
          execute_statement := execute_statement || 'AND id IN (SELECT feature_id FROM location_boundary WHERE location_id IN (SELECT id FROM location WHERE activity_id ' ||
          'IN(SELECT id FROM activity WHERE data_group_id = ANY(ARRAY[' || array_to_string(valid_dg_ids, ',') || ']) )) AND boundary_id = ' || boundary_table || '.boundary_id)';
        END IF; 
      ELSE
        -- restrict returned results by data group id(s)
        IF array_length(valid_dg_ids, 1) > 0 THEN
          execute_statement := execute_statement || 'WHERE id IN (SELECT feature_id FROM location_boundary WHERE location_id IN (SELECT id FROM location WHERE activity_id ' ||
          'IN(SELECT id FROM activity WHERE data_group_id = ANY(ARRAY[' || array_to_string(valid_dg_ids, ',') || ']) )) AND boundary_id = ' || boundary_table || '.boundary_id)';
        END IF; 
      END IF;
      execute_statement := execute_statement || ') b' || count || ') as boundaries'; 
    END IF; 
    idx := idx + 1;     
  END LOOP;
	
  RAISE NOTICE 'Execute statement: %', execute_statement;			

  FOR rec IN EXECUTE 'SELECT row_to_json(j) FROM (' || execute_statement || ')j' LOOP  		
	RETURN NEXT rec;
  END LOOP;
 
EXCEPTION WHEN others THEN 
  GET STACKED DIAGNOSTICS error_msg = MESSAGE_TEXT;  
    RAISE NOTICE 'Internal Error - Contact your DBA with the following error message: %', error_msg;
    
END;$$ LANGUAGE plpgsql;

/******************************************************************
 9. update pmt_upd_boundary_features to alter logic to only collect
boundary features for boundaries appropriate for mapping level 
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
10. update trigger function upd_geometry_formats to remove georef
******************************************************************/
-- upd_geometry_formats
DROP FUNCTION IF EXISTS upd_geometry_formats();
CREATE OR REPLACE FUNCTION pmt_upd_geometry_formats()
RETURNS trigger AS $pmt_upd_geometry_formats$
BEGIN	
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

RETURN NEW;
END;
$pmt_upd_geometry_formats$ LANGUAGE plpgsql; 
DROP TRIGGER IF EXISTS pmt_upd_geometry_formats ON location;
CREATE TRIGGER pmt_upd_geometry_formats BEFORE INSERT OR UPDATE ON location
    FOR EACH ROW EXECUTE PROCEDURE pmt_upd_geometry_formats();
    
 /******************************************************************
11. update pmt_locations_for_boundaries to correct parameter validation error
  SELECT * FROM pmt_locations_for_boundaries(8,'768',null,null,null,null,null,null,null,null,null); 
  SELECT * FROM pmt_locations_for_boundaries(8,'768','797',null,null,null,'1/1/2012','12/31/2018',null,null,null)
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_locations_for_boundaries(boundary_id integer, data_group_ids character varying,
  classification_ids character varying, org_ids character varying, imp_org_ids character varying, fund_org_ids character varying, 
  start_date date, end_date date, unassigned_taxonomy_ids character varying, activity_ids character varying, boundary_filter json)
RETURNS SETOF pmt_json_result_type AS 
$$
DECLARE
  valid_boundary_id integer; 
  execute_statement text;
  filtered_activity_ids int[];
  boundary_json json;
  boundary_filters text[];
  boundary_statement text;
  boundary_activity_ids int[];
  a_ids int[];
  valid_activity_ids int[];
  json record; 
  rec record;
  error_msg text;
BEGIN  
  -- validate and process boundary_id parameter
  IF $1 IS NOT NULL THEN
    SELECT INTO valid_boundary_id id FROM boundary WHERE id = $1;    
    -- exit if boundary id is not valid
    IF valid_boundary_id IS NULL THEN 
       FOR rec IN SELECT row_to_json(j) FROM( SELECT 'invalid parameter' AS error ) as j
	LOOP
        RETURN NEXT rec;    
       END LOOP;
    END IF;
  ELSE
    FOR rec IN SELECT row_to_json(j) FROM( SELECT 'missing required parameter' AS error ) as j
    LOOP
      RETURN NEXT rec;    
    END LOOP;    
  END IF;

  -- get the filtered activity ids
  SELECT INTO filtered_activity_ids * FROM pmt_filter($2,$3,$4,$5,$6,$7,$8,$9);
   
  -- get the list of activity ids
  IF ($10 IS NOT NULL OR $10 <> '' ) THEN
    a_ids:= string_to_array($10, ',')::int[];
    SELECT INTO valid_activity_ids array_agg(id) FROM activity WHERE _active = true AND id = ANY(a_ids);
  END IF;
  
  -- get the filtered activity ids by boundary
  IF ($11 IS NOT NULL) THEN
    RAISE NOTICE 'json was not null';      
    FOR boundary_json IN (SELECT * FROM json_array_elements($11)) LOOP
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
  
  -- prepare the execution statement
  execute_statement:= 'SELECT feature_id as id, count(distinct CASE WHEN parent_id IS NULL THEN activity_id WHEN parent_id IS NOT NULL THEN parent_id ELSE NULL END) as p, ' ||
		'count(distinct activity_id) as a, count(distinct location_id) as l, boundary_id as b FROM _filter_boundaries ' ||
		'WHERE activity_id = ANY(ARRAY[' || array_to_string(filtered_activity_ids, ',') || ']) ';

  -- add filter for boundary		
  IF array_length(boundary_activity_ids, 1) > 0 THEN
    execute_statement:= execute_statement || 'AND activity_id = ANY(ARRAY[' || array_to_string(boundary_activity_ids, ',') || ']) ';
  END IF;

  -- add filter for activities in list
  IF array_length(valid_activity_ids, 1) > 0 THEN
    execute_statement:= execute_statement || 'AND activity_id = ANY(ARRAY[' || array_to_string(valid_activity_ids, ',') || ']) ';
  END IF;
  
  execute_statement:= execute_statement || 'AND boundary_id = ' || valid_boundary_id || ' GROUP BY 1,5';

  RAISE NOTICE 'Execute statement: %', execute_statement;			

  FOR rec IN EXECUTE 'SELECT row_to_json(j) FROM (' || execute_statement || ')j' LOOP  		
	RETURN NEXT rec;
  END LOOP;

EXCEPTION WHEN others THEN 
  GET STACKED DIAGNOSTICS error_msg = MESSAGE_TEXT;  
    RAISE NOTICE 'Internal Error - Contact your DBA with the following error message: %', error_msg;

END;$$ LANGUAGE plpgsql;


/******************************************************************
12. update pmt_activities to add boundary filter
   select * from pmt_activities('2237',null,null,null,null,null,null,null,null,'[{"b": 12, "ids": [1]}]'); 
   select * from pmt_activities('769',null,null,null,'13',null,null,null,null); 
******************************************************************/
DROP FUNCTION IF EXISTS pmt_activities(character varying, character varying, character varying, character varying, character varying, date, date, character varying, character varying);
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
		'LEFT JOIN (SELECT id, _name FROM _activity_participants WHERE classification = ''Funding'') o ON a.id = o.id '
		'WHERE classification IS NULL OR classification = ''Incoming Funds'' OR classification = ''Commitment'' ' ||
		'GROUP BY 1,2,3,4,5,7,8 ';


  RAISE NOTICE 'Execute statement: %', execute_statement;

  FOR rec IN EXECUTE 'SELECT row_to_json(j) FROM (' || execute_statement || ')j' LOOP
	RETURN NEXT rec;
  END LOOP;

EXCEPTION WHEN others THEN
  GET STACKED DIAGNOSTICS error_msg = MESSAGE_TEXT;
    RAISE NOTICE 'Internal Error - Contact your DBA with the following error message: %', error_msg;

END;$$ LANGUAGE plpgsql;

/******************************************************************
13. update ALL active locations
******************************************************************/    
UPDATE location SET _title = _title WHERE _active = true;

-- update permissions
GRANT USAGE ON SCHEMA public TO pmt_read;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO pmt_read;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO pmt_read;
GRANT USAGE ON SCHEMA public TO pmt_write;
GRANT SELECT,INSERT ON ALL TABLES IN SCHEMA public TO pmt_write;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO pmt_write;