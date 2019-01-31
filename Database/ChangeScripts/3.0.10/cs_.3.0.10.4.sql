/******************************************************************
Change Script 3.0.10.4
1. add new continent spatial table (REQUIRES shapefile load before
executing this script)
2. update _location_lookup to support location presentation in the 
application by boundary
3. create new views to support centroid point generation for 
 PMT Viewer assets and filter logic
4. create new pmt_locations_for_boundaries function
5. create new pmt_activity_ids_by_boundary function
6. update pmt_activity function
7. update pmt_org_inuse function
8. update pmt_user_auth function
9. update pmt_user_salt function
10. update pmt_users function
11. create pmt_roles function
12. update pmt_orgs function
13. create pmt_user_orgs function
14. create pmt_dlt_boundary_features trigger
15. delete pmt_purge_project
16. update pmt_purge_activity
17. create pmt_purge_activities function

Prerequistes:
1. load continent shapefile (WorkingFiles: Continents.zip)
shp2pgsql -s 4210 "C:\Program Files\PostgreSQL\9.3\data\continent.shp" public.continent | psql -h localhost -d pmt10 -U postgres
******************************************************************/
INSERT INTO version(_version, _iteration, _changeset) VALUES (3.0, 10, 4);
-- select * from version order by _iteration desc, _changeset desc;

/******************************************************************
 1. add new continent spatial table
******************************************************************/
-- add boundary record
INSERT INTO boundary (_name, _description, _spatial_table, _created_by, _updated_by)
  VALUES('Continent','Continental boundaries', 'continent', 'cs_.3.0.10.4', 'cs_.3.0.10.4');
-- update existing fields to adhere to pmt field naming convention
ALTER TABLE continent RENAME COLUMN gid TO id;
ALTER TABLE continent RENAME COLUMN continent TO _name;
ALTER TABLE continent RENAME COLUMN geom TO _polygon;
-- add boundary id
ALTER TABLE continent ADD COLUMN boundary_id integer;
UPDATE continent SET boundary_id = (SELECT id FROM boundary WHERE _spatial_table = 'continent');
ALTER TABLE continent ADD CONSTRAINT fk_continent_boundary_id FOREIGN KEY (boundary_id) REFERENCES boundary; 
-- add additional pmt required fields
ALTER TABLE continent ADD COLUMN _code character varying(50);
ALTER TABLE continent ADD COLUMN _label character varying;
-- add _point field and populate with centroid
ALTER TABLE continent ADD COLUMN _point geometry;
ALTER TABLE continent ADD CONSTRAINT chk_continent_geotype_point CHECK (geometrytype(_point) = 'POINT'::text OR _point IS NULL);
ALTER TABLE continent ADD CONSTRAINT chk_continent_srid_point CHECK (ST_SRID(_point) = 4326);
UPDATE continent SET _point = ST_GeomFromText(ST_AsText(ST_Centroid(_polygon)), 4326);
-- add additional pmt required fields
ALTER TABLE continent ADD COLUMN _active boolean NOT NULL DEFAULT true;
ALTER TABLE continent ADD COLUMN _retired_by integer;
ALTER TABLE continent ADD COLUMN _created_by character varying(150);
ALTER TABLE continent ADD COLUMN _created_date timestamp without time zone NOT NULL DEFAULT ('now'::text)::date;
ALTER TABLE continent ADD COLUMN _updated_by character varying(150);
ALTER TABLE continent ADD COLUMN _updated_date timestamp without time zone NOT NULL DEFAULT ('now'::text)::date;
UPDATE continent SET _label = _name, _created_by = 'cs_.3.0.10.4', _updated_by = 'cs_.3.0.10.4';
-- set correct srid
SELECT UpdateGeometrySRID('public', 'continent', '_polygon', 4326);
-- update all locations with new boundary
UPDATE location SET _title = _title WHERE _active = true;

/******************************************************************
 2. update _location_lookup to support location presentation in the 
application by boundary
******************************************************************/
-- location_lookup
DROP VIEW _location_lookup;
CREATE OR REPLACE VIEW _location_lookup AS
SELECT l.activity_id, a.data_group_id, l.id as location_id, b.id as boundary_id, lb.feature_id as feature_id
--, l._lat_dd as lat_dd, l._long_dd as long_dd
FROM location l
JOIN activity a
ON l.activity_id = a.id
LEFT JOIN location_boundary lb
ON l.id = lb.location_id
JOIN boundary b
ON lb.boundary_id = b.id
WHERE l._active = TRUE AND a._active = TRUE AND b._active = TRUE;

-- SELECT * FROM _location_lookup WHERE data_group_id IN (768) AND boundary_id = 1
/******************************************************************
 3. create new views to support centroid point generation for 
 PMT Viewer assets and filter logic
******************************************************************/
-- gaul0_points
DROP VIEW IF EXISTS gaul0_points;
CREATE OR REPLACE VIEW gaul0_points AS
SELECT id, _point
FROM gaul0
WHERE id IN
(SELECT feature_id FROM location_boundary WHERE boundary_id = 1);
-- gaul1_points
DROP VIEW IF EXISTS gaul1_points;
CREATE OR REPLACE VIEW gaul1_points AS
SELECT id, _point
FROM gaul1
WHERE id IN
(SELECT feature_id FROM location_boundary WHERE boundary_id = 2);
-- gaul2_points
DROP VIEW IF EXISTS gaul2_points;
CREATE OR REPLACE VIEW gaul2_points AS
SELECT id, _point
FROM gaul2
WHERE id IN
(SELECT feature_id FROM location_boundary WHERE boundary_id = 3);
-- _remove old filter view
DROP VIEW IF EXISTS _filter;
-- filter view for boundaries
DROP VIEW IF EXISTS _filter_boundaries;
CREATE OR REPLACE VIEW _filter_boundaries AS 
SELECT a.id as activity_id, a.data_group_id, l.id as location_id, lb.feature_id, lb.boundary_id
  FROM (SELECT * FROM activity WHERE _active = true) a
  LEFT JOIN (SELECT * FROM location WHERE _active = true) l
  ON a.id = l.activity_id
  LEFT JOIN location_boundary lb 
  ON l.id = lb.location_id;  
-- filter view for taxonomies
DROP VIEW IF EXISTS _filter_taxonomies;
CREATE OR REPLACE VIEW _filter_taxonomies AS
SELECT a.id as activity_id, a.data_group_id, l.id as location_id, c.taxonomy_id, at.classification_id
  FROM (SELECT * FROM activity WHERE _active = true) a
  LEFT JOIN (SELECT * FROM location WHERE _active = true) l
  ON a.id = l.activity_id
  LEFT JOIN activity_taxonomy at
  ON a.id = at.activity_id
  LEFT JOIN (SELECT * FROM classification WHERE _active = true) c
  ON at.classification_id = c.id
  UNION ALL
  SELECT a.id, a.data_group_id, l.id, c.taxonomy_id, lt.classification_id
  FROM (SELECT * FROM activity WHERE _active = true) a
  LEFT JOIN (SELECT * FROM location WHERE _active = true) l
  ON a.id = l.activity_id
  LEFT JOIN location_taxonomy lt
  ON l.id = lt.location_id
  LEFT JOIN (SELECT * FROM classification WHERE _active = true) c
  ON lt.classification_id = c.id;
-- filter view for organizations 
 DROP VIEW IF EXISTS _filter_organizations;
 CREATE OR REPLACE VIEW _filter_organizations AS 
  SELECT a.id as activity_id, a.data_group_id, tc.classification as role, array_agg(p.organization_id) as organization_ids
  FROM (SELECT * FROM activity WHERE _active = true) a
  LEFT JOIN (SELECT * FROM participation WHERE _active = true) p
  ON a.id = p.activity_id
  LEFT JOIN participation_taxonomy pt
  ON p.id = pt.participation_id
  LEFT JOIN _taxonomy_classifications tc
  ON pt.classification_id = tc.classification_id
  GROUP BY 1,2,3
  ORDER BY 1;
/******************************************************************
4. create new pmt_locations_for_boundaries function
  SELECT * FROM pmt_locations_for_boundaries(8, '768', '','',''); --bmgf
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_locations_for_boundaries(boundary_id integer, data_group_ids character varying,
  classification_ids character varying, imp_org_ids character varying, fund_org_ids character varying)
RETURNS SETOF pmt_json_result_type AS 
$$
DECLARE
  valid_boundary_id integer;
  dg_ids int[];
  c_ids int[];
  imp_ids int[];
  fund_ids int[];
  valid_dg_ids int[];  
  valid_c_ids int[];  
  valid_imp_ids int[];  
  valid_fund_ids int[];  
  org_statement text;
  tax_statement text;
  execute_statement text;
  dg_where text;
  org_where text[];
  tax_where text[];
  tax_joins text[];
  w text;
  idx int;
  cls record;
  rec record;
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

  -- validate and process data_group_ids parameter
  IF $2 IS NOT NULL THEN
    dg_ids:= string_to_array($2, ',')::int[];
    -- validate the data groups id
    SELECT INTO valid_dg_ids array_agg(id)::int[] FROM classification WHERE taxonomy_id = 1 AND _active=true AND id = ANY(dg_ids);
  END IF;
   -- validate and process classification_ids parameter
  IF $3 IS NOT NULL THEN
    c_ids:= string_to_array($3, ',')::int[];
    -- validate the classification ids
    SELECT INTO valid_c_ids array_agg(id)::int[] FROM classification WHERE _active=true AND id = ANY(c_ids);
  END IF;
   -- validate and process imp_org_ids parameter
  IF $4 IS NOT NULL THEN
    imp_ids:= string_to_array($4, ',')::int[];
    -- validate the org ids
    SELECT INTO valid_imp_ids array_agg(id)::int[] FROM organization WHERE _active=true AND id = ANY(imp_ids);
  END IF;
   -- validate and process fund_org_ids parameter
  IF $5 IS NOT NULL THEN
    fund_ids:= string_to_array($5, ',')::int[];
    -- validate the org ids
    SELECT INTO valid_fund_ids array_agg(id)::int[] FROM organization WHERE _active=true AND id = ANY(fund_ids);
  END IF;
  
  execute_statement:= 'SELECT feature_id as id, count(distinct o.activity_id) as a, count(distinct location_id) as l, boundary_id as b FROM ';
  org_statement := '(SELECT distinct activity_id FROM _filter_organizations ';
  tax_statement := 'JOIN (SELECT distinct t1.activity_id FROM  ';
  
  -- restrict returned results by data group id(s)
  IF array_length(valid_dg_ids, 1) > 0 THEN
    dg_where := 'data_group_id = ANY(ARRAY[' || array_to_string(valid_dg_ids, ',') || ']) ';
  END IF;
   -- restrict returned results by classification id(s)
  IF array_length(valid_c_ids, 1) > 0 THEN
    FOR cls IN EXECUTE 'SELECT taxonomy_id, array_agg(id) as c FROM classification WHERE _active = true AND id = ANY(ARRAY[' || array_to_string(valid_c_ids, ',') || ']) GROUP BY 1 ORDER BY 1' LOOP
      tax_where := array_append(tax_where, '(taxonomy_id = ' || cls.taxonomy_id || ' AND classification_id = ANY(ARRAY[' || array_to_string(cls.c, ',') || ']))');
    END LOOP;
  END IF;
   -- restrict returned results by org id(s)
  IF array_length(valid_imp_ids, 1) > 0 THEN
    org_where := array_append(org_where, '(organization_ids && ARRAY[' || array_to_string(valid_imp_ids, ',') || '] AND role = ''Implementing'')');
  END IF;
   -- restrict returned results by org id(s)
  IF array_length(valid_fund_ids, 1) > 0 THEN
    org_where := array_append(org_where, '(organization_ids && ARRAY[' || array_to_string(valid_imp_ids, ',') || '] AND role = ''Funding'')');
  END IF;

  -- build statements
  IF dg_where IS NOT NULL THEN
    org_statement := org_statement || 'WHERE ' || dg_where;
  END IF;

  -- build _filter_taxonomies statement
  IF array_length(tax_where, 1) > 0 THEN
    idx := 1;
    FOREACH w IN ARRAY tax_where LOOP
      IF dg_where IS NOT NULL THEN
        IF idx = 1 THEN
          tax_joins := array_append(tax_joins, '(SELECT activity_id FROM _filter_taxonomies WHERE ' || dg_where ||
  	    ' AND ' || w || ') t' || idx);
        ELSE
          tax_joins := array_append(tax_joins, '(SELECT activity_id FROM _filter_taxonomies WHERE ' || dg_where ||
  	    ' AND ' || w || ') t' || idx || ' ON t' || idx - 1 || '.activity_id = t' || idx || '.activity_id ');
        END IF;
      ELSE 
        IF idx = 1 THEN
          tax_joins := array_append(tax_joins, '(SELECT activity_id FROM _filter_taxonomies WHERE ' ||  w || ') t' || idx);
        ELSE
          tax_joins := array_append(tax_joins, '(SELECT activity_id FROM _filter_taxonomies WHERE ' ||  w || ') t' || idx 
            || ' ON t' || idx - 1 || '.activity_id = t' || idx || '.activity_id ');
        END IF;        
      END IF;
      idx := idx + 1;
    END LOOP; 
    tax_statement := tax_statement || array_to_string(tax_joins, ' JOIN ');
  ELSE
    IF dg_where IS NOT NULL THEN
      tax_statement := tax_statement || '(SELECT activity_id FROM _filter_taxonomies WHERE ' || dg_where || ') t1';  
    ELSE
      tax_statement := tax_statement || '(SELECT activity_id FROM _filter_taxonomies ) t1';  
    END IF;    
  END IF;

  -- build _filter_organizations statement
  IF array_length(org_where, 1) > 0 THEN
    IF dg_where IS NOT NULL THEN
      org_statement := org_statement || ' AND (' || array_to_string(org_where, ' AND ') || ') ';
    ELSE 
      org_statement := org_statement || 'WHERE (' || array_to_string(org_where, ' AND ') || ') ';
    END IF;
  END IF;

  org_statement := org_statement || ') as o ';
  tax_statement := tax_statement || ') as c ';
  
  execute_statement:= execute_statement || org_statement || tax_statement ||
		'ON o.activity_id = c.activity_id ' ||
		'LEFT JOIN _filter_boundaries ab ON o.activity_id = ab.activity_id WHERE ab.boundary_id = ' || valid_boundary_id || 
		' GROUP BY 1,4';
 
  RAISE NOTICE 'Execute statement: %', execute_statement;			

  FOR rec IN EXECUTE 'SELECT row_to_json(j) FROM (' || execute_statement || ')j' LOOP  		
	RETURN NEXT rec;
  END LOOP;

END;$$ LANGUAGE plpgsql;

/******************************************************************
5. create new pmt_activity_ids_by_boundary function
  SELECT * FROM pmt_activity_ids_by_boundary(8, 3, '768', '','',''); --bmgf
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_activity_ids_by_boundary(boundary_id integer, feature_id integer, 
  data_group_ids character varying, classification_ids character varying, imp_org_ids character varying, 
  fund_org_ids character varying)
RETURNS SETOF pmt_json_result_type AS 
$$
DECLARE
  valid_boundary_id integer;
  dg_ids int[];
  c_ids int[];
  imp_ids int[];
  fund_ids int[];
  valid_dg_ids int[];  
  valid_c_ids int[];  
  valid_imp_ids int[];  
  valid_fund_ids int[];  
  org_statement text;
  tax_statement text;
  execute_statement text;
  dg_where text;
  org_where text[];
  tax_where text[];
  tax_joins text[];
  w text;
  idx int;
  cls record;
  rec record;
BEGIN  
  -- validate and process boundary_id parameter
  IF $1 IS NOT NULL AND $2 IS NOT NULL THEN
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

  -- validate and process data_group_ids parameter
  IF $3 IS NOT NULL THEN
    dg_ids:= string_to_array($3, ',')::int[];
    -- validate the data groups id
    SELECT INTO valid_dg_ids array_agg(id)::int[] FROM classification WHERE taxonomy_id = 1 AND _active=true AND id = ANY(dg_ids);
  END IF;
   -- validate and process classification_ids parameter
  IF $4 IS NOT NULL THEN
    c_ids:= string_to_array($4, ',')::int[];
    -- validate the classification ids
    SELECT INTO valid_c_ids array_agg(id)::int[] FROM classification WHERE _active=true AND id = ANY(c_ids);
  END IF;
   -- validate and process imp_org_ids parameter
  IF $5 IS NOT NULL THEN
    imp_ids:= string_to_array($5, ',')::int[];
    -- validate the org ids
    SELECT INTO valid_imp_ids array_agg(id)::int[] FROM organization WHERE _active=true AND id = ANY(imp_ids);
  END IF;
   -- validate and process fund_org_ids parameter
  IF $6 IS NOT NULL THEN
    fund_ids:= string_to_array($6, ',')::int[];
    -- validate the org ids
    SELECT INTO valid_fund_ids array_agg(id)::int[] FROM organization WHERE _active=true AND id = ANY(fund_ids);
  END IF;

  -- begin statements
  execute_statement:= 'SELECT array_agg(DISTINCT o.activity_id) as a FROM ';
  org_statement := '(SELECT distinct activity_id FROM _filter_organizations ';
  tax_statement := 'JOIN (SELECT distinct t1.activity_id FROM  ';

  -- restrict returned results by data group id(s)
  IF array_length(valid_dg_ids, 1) > 0 THEN
    dg_where := 'data_group_id = ANY(ARRAY[' || array_to_string(valid_dg_ids, ',') || ']) ';
  END IF;
   -- restrict returned results by classification id(s)
  IF array_length(valid_c_ids, 1) > 0 THEN
    FOR cls IN EXECUTE 'SELECT taxonomy_id, array_agg(id) as c FROM classification WHERE _active = true AND id = ANY(ARRAY[' || array_to_string(valid_c_ids, ',') || ']) GROUP BY 1 ORDER BY 1' LOOP
      tax_where := array_append(tax_where, '(taxonomy_id = ' || cls.taxonomy_id || ' AND classification_id = ANY(ARRAY[' || array_to_string(cls.c, ',') || ']))');
    END LOOP;
  END IF;
   -- restrict returned results by org id(s)
  IF array_length(valid_imp_ids, 1) > 0 THEN
    org_where := array_append(org_where, '(organization_ids && ARRAY[' || array_to_string(valid_imp_ids, ',') || '] AND role = ''Implementing'')');
  END IF;
   -- restrict returned results by org id(s)
  IF array_length(valid_fund_ids, 1) > 0 THEN
    org_where := array_append(org_where, '(organization_ids && ARRAY[' || array_to_string(valid_imp_ids, ',') || '] AND role = ''Funding'')');
  END IF;

   -- build statements
  IF dg_where IS NOT NULL THEN
    org_statement := org_statement || 'WHERE ' || dg_where;
  END IF;

  -- build _filter_taxonomies statement
  IF array_length(tax_where, 1) > 0 THEN
    idx := 1;
    FOREACH w IN ARRAY tax_where LOOP
      IF dg_where IS NOT NULL THEN
        IF idx = 1 THEN
          tax_joins := array_append(tax_joins, '(SELECT activity_id FROM _filter_taxonomies WHERE ' || dg_where ||
  	    ' AND ' || w || ') t' || idx);
        ELSE
          tax_joins := array_append(tax_joins, '(SELECT activity_id FROM _filter_taxonomies WHERE ' || dg_where ||
  	    ' AND ' || w || ') t' || idx || ' ON t' || idx - 1 || '.activity_id = t' || idx || '.activity_id ');
        END IF;
      ELSE 
        IF idx = 1 THEN
          tax_joins := array_append(tax_joins, '(SELECT activity_id FROM _filter_taxonomies WHERE ' ||  w || ') t' || idx);
        ELSE
          tax_joins := array_append(tax_joins, '(SELECT activity_id FROM _filter_taxonomies WHERE ' ||  w || ') t' || idx 
            || ' ON t' || idx - 1 || '.activity_id = t' || idx || '.activity_id ');
        END IF;        
      END IF;
      idx := idx + 1;
    END LOOP; 
    tax_statement := tax_statement || array_to_string(tax_joins, ' JOIN ');
  ELSE
    IF dg_where IS NOT NULL THEN
      tax_statement := tax_statement || '(SELECT activity_id FROM _filter_taxonomies WHERE ' || dg_where || ') t1';  
    ELSE
      tax_statement := tax_statement || '(SELECT activity_id FROM _filter_taxonomies ) t1';  
    END IF;    
  END IF;

  -- build _filter_organizations statement
  IF array_length(org_where, 1) > 0 THEN
    IF dg_where IS NOT NULL THEN
      org_statement := org_statement || ' AND (' || array_to_string(org_where, ' AND ') || ') ';
    ELSE 
      org_statement := org_statement || 'WHERE (' || array_to_string(org_where, ' AND ') || ') ';
    END IF;
  END IF;

  org_statement := org_statement || ') as o ';
  tax_statement := tax_statement || ') as c ';
  
  execute_statement:= execute_statement || org_statement || tax_statement ||
		'ON o.activity_id = c.activity_id ' ||
		'LEFT JOIN _filter_boundaries ab ON o.activity_id = ab.activity_id ' ||
		'WHERE ab.boundary_id = ' || valid_boundary_id || ' AND ab.feature_id = ' || $2;
 
  
  RAISE NOTICE 'Execute statement: %', execute_statement;			

  FOR rec IN EXECUTE 'SELECT row_to_json(j) FROM (' || execute_statement || ')j' LOOP  		
	RETURN NEXT rec;
  END LOOP;
  
END;$$ LANGUAGE plpgsql;
/******************************************************************
6. update pmt_activity function
  SELECT * FROM pmt_activity(23073);
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
    execute_statement := 'SELECT ' || return_columns || ', l.ct ';

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
				'select organization as o, classification as c '  ||
				'from _organization_lookup ' ||
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
					'select lb.boundary_id, lb.feature_id, lb._feature_area, lb._feature_name ' ||
					'from location_boundary lb ' ||					
					'where lb.location_id = l.id ' ||
					') b ) as boundaries ' ||
				'from location l ' ||		
				'where l._active = true and l.activity_id = ' || $1 ||
				') l ) as locations ';							
								
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

/******************************************************************
7. update pmt_org_inuse function
  SELECT * FROM pmt_org_inuse('768,769,1068,1069,1209,2209,2210,2241','497');  
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_org_inuse(data_group_ids character varying, org_role_ids character varying)
RETURNS SETOF pmt_json_result_type AS $$
DECLARE
  dg_ids int[];
  valid_dg_ids int[];
  role_ids int[];
  valid_role_ids int[];
  built_where text[];
  execute_statement text;
  i integer;
  rec record;
BEGIN
  -- validate and process data_group_ids parameter
  IF $1 IS NOT NULL OR $1 <> '' THEN
    dg_ids:= string_to_array($1, ',')::int[];
    -- validate the data groups ids
    SELECT INTO valid_dg_ids array_agg(id)::int[] FROM classification WHERE taxonomy_id = 1 AND _active=true AND id = ANY(dg_ids);
  END IF;
  
  -- validate org role ids parameter
  IF $2 IS NOT NULL OR $2 <> '' THEN
    role_ids:= string_to_array($2, ',')::int[];
    -- validate the org role ids
    SELECT INTO valid_role_ids array_agg(id)::int[] FROM classification WHERE taxonomy_id = (SELECT id FROM taxonomy WHERE _name = 'Organisation Role') 
	AND _active=true AND id = ANY(role_ids);
  END IF;
  
  execute_statement :=
    'SELECT organization_id as id, organization as n, count(DISTINCT activity_id) as ct, lower(substring(organization, 1, 1)) as o ' ||
    'FROM (SELECT * FROM _organization_lookup WHERE activity_id IN (SELECT activity_id FROM location WHERE _active = true)) as foo ';
  
  built_where := null;

  IF array_length(valid_dg_ids, 1) > 0 THEN			
    built_where := array_append(built_where, 'data_group_id = ANY(ARRAY[' || array_to_string(valid_dg_ids, ',') || ']) ');
  END IF;
  
  IF array_length(valid_role_ids, 1) > 0 THEN
    built_where := array_append(built_where, 'classification_id = ANY(ARRAY[' || array_to_string(valid_role_ids, ',') || ']) ');
  END IF;

  IF array_length(built_where, 1) > 0 THEN
    execute_statement := execute_statement || 'WHERE ' || array_to_string(built_where, ' AND ');
  END IF;

    execute_statement := execute_statement || 'GROUP BY 1,2 ORDER BY 2 ';
    
  RAISE NOTICE 'Execute statement: %', execute_statement;			

  FOR rec IN EXECUTE 'SELECT row_to_json(j) FROM (' || execute_statement || ')j' LOOP  		
    RETURN NEXT rec;
  END LOOP;
	
END;$$ LANGUAGE plpgsql;


/******************************************************************
8. update pmt_user_auth function
  select * from "user"
  select * from pmt_user_auth('guest','Mt.Ev3r3st');
  select * from pmt_user_auth('super','super');
  select * from pmt_user_auth('sparadee','Butt3rflies');
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_user_auth(username character varying(255), password character varying(255)) RETURNS 
SETOF pmt_json_result_type AS $$
DECLARE 
  valid_user_id integer;
  auth_success boolean;
  role_super boolean;	
  rec record;
BEGIN 
  -- determine if the password is valid for this user
  SELECT INTO auth_success (_password = crypt($2, _password)) AS pswmatch FROM users WHERE _username = $1 AND _active = true;

  IF (auth_success) THEN
    -- validate user and get user_id
    SELECT INTO valid_user_id users.id FROM users WHERE users._username = $1;
  END IF;
  
  IF valid_user_id IS NOT NULL THEN
    -- check to see if user has a role with "SUPER" rights (if so they have full adminsitrative editing rights to the database)
    SELECT INTO role_super _super FROM role WHERE id = (SELECT role_id FROM users WHERE id = valid_user_id);
    IF role_super THEN
        FOR rec IN (
	SELECT row_to_json(j) FROM(	 				
	SELECT u.id, u._first_name, u._last_name, u._username, u._email
	,u.organization_id
	,(SELECT _name FROM organization WHERE id = u.organization_id) as organization
	,u.role_id
	,(SELECT _name FROM role WHERE id = u.role_id) as role
	,(SELECT row_to_json(ra) FROM (SELECT _read,_create,_update,_delete,_super,_security FROM role WHERE id = u.role_id) ra) as role_auth
	,null as authorizations
	FROM users u
	WHERE u.id = valid_user_id
	) j
      ) LOOP		
        RETURN NEXT rec;
      END LOOP;
    -- get all the authorization information for the user
    ELSE
      FOR rec IN (
	SELECT row_to_json(j) FROM(	 				
	SELECT u.id, u._first_name, u._last_name, u._username, u._email
	,u.organization_id
	,(SELECT _name FROM organization WHERE id = u.organization_id) as organization
	,u.role_id
	,(SELECT _name FROM role WHERE id = u.role_id) as role
	,(SELECT row_to_json(ra) FROM (SELECT _read,_create,_update,_delete,_super,_security FROM role WHERE id = u.role_id) ra) as role_auth
	,(SELECT array_to_json(array_agg(row_to_json(r))) FROM (
			SELECT p.role_id, r._name as role, array_agg(p.activity_id) as activity_ids FROM
			(SELECT user_id, activity_id, role_id
			FROM user_activity_role
			WHERE user_id = u.id AND classification_id IS NULL
			UNION ALL
			SELECT ua.user_id, at.activity_id, ua.role_id
			FROM user_activity_role ua
			JOIN activity_taxonomy at
			ON ua.classification_id = at.classification_id
			WHERE ua.user_id = u.id AND ua.classification_id IS NOT NULL) p			
			JOIN role r
			ON p.role_id = r.id
			GROUP BY p.role_id, r._name) as r
		) as authorizations
	FROM users u
	WHERE u.id = valid_user_id	
	) j
      ) LOOP		
        RETURN NEXT rec;
      END LOOP;    
    END IF;
    -- log user activity
    INSERT INTO user_log(user_id, _username, _status) VALUES (valid_user_id, $1, 'success');		  
  ELSE
    FOR rec IN (SELECT row_to_json(j) FROM( SELECT 'Invalid username or password.' AS message ) j ) LOOP		
        RETURN NEXT rec;
    END LOOP;	
    -- log user activity
    INSERT INTO user_log(_username, _status) VALUES ($1, 'fail');		  
  END IF;
END; 
$$ LANGUAGE 'plpgsql';

/******************************************************************
 9. update pmt_user_salt function
  SELECT * FROM pmt_user_salt('sparadee');
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_user_salt(username text) RETURNS text AS $$
DECLARE 
  salt text;
BEGIN 
  SELECT INTO salt substring(_password from 1 for 29) from users where _username = $1;
  RETURN salt;
END; 
$$ LANGUAGE 'plpgsql';

/******************************************************************
 10. update pmt_users function
  SELECT * FROM pmt_users();
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_users() RETURNS SETOF pmt_json_result_type AS $$
DECLARE 
  rec record;
BEGIN 
  FOR rec IN (
	SELECT row_to_json(j) FROM( 
	SELECT u.id, u._first_name, u._last_name, u._username, u._email
	,u.organization_id
	,(SELECT _name FROM organization WHERE id = u.organization_id) as organization
	,u.role_id
	,(SELECT _name FROM role WHERE id = u.role_id) as role
	,u._active
	FROM users u
	) j 
    ) LOOP		
    RETURN NEXT rec;
  END LOOP;			  
END; 
$$ LANGUAGE 'plpgsql';

/******************************************************************
 11. create pmt_roles function
  SELECT * FROM pmt_roles();
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_roles() RETURNS SETOF pmt_json_result_type AS $$
DECLARE 
  rec record;
BEGIN 
  FOR rec IN (
	SELECT row_to_json(j) FROM( 
	SELECT id, _name, _active
	FROM role
	) j 
    ) LOOP		
    RETURN NEXT rec;
  END LOOP;			  
END; 
$$ LANGUAGE 'plpgsql';

/******************************************************************
 12. update pmt_orgs function
  SELECT * FROM pmt_orgs();
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_orgs() RETURNS SETOF pmt_json_result_type AS $$
DECLARE 
  rec record;
BEGIN 
  FOR rec IN (
	SELECT row_to_json(j) FROM( 
	SELECT id, _name
	FROM organization
	WHERE _active = true
	) j 
    ) LOOP		
    RETURN NEXT rec;
  END LOOP;			  
END; 
$$ LANGUAGE 'plpgsql';

/******************************************************************
 13. create pmt_user_orgs function
  SELECT * FROM pmt_user_orgs();
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_user_orgs() RETURNS SETOF pmt_json_result_type AS $$
DECLARE 
  rec record;
BEGIN 
  FOR rec IN (
	SELECT row_to_json(j) FROM( 
	SELECT DISTINCT o.id, o._name
	FROM users u
	JOIN organization o
	ON u.organization_id = o.id
	) j 
    ) LOOP		
    RETURN NEXT rec;
  END LOOP;			  
END; 
$$ LANGUAGE 'plpgsql';


/******************************************************************
 14. create pmt_dlt_boundary_features trigger
******************************************************************/    
-- dlt_boundary_features
DROP FUNCTION IF EXISTS pmt_dlt_boundary_features();
CREATE OR REPLACE FUNCTION pmt_dlt_boundary_features()
RETURNS trigger AS $pmt_dlt_boundary_features$
DECLARE

BEGIN
  -- Remove all existing location boundary information for this location
  EXECUTE 'DELETE FROM location_boundary WHERE location_id = ' || OLD.id;
  
RETURN OLD;

END;
$pmt_dlt_boundary_features$ LANGUAGE plpgsql; 
DROP TRIGGER IF EXISTS pmt_dlt_boundary_features ON location;
CREATE TRIGGER pmt_dlt_boundary_features BEFORE DELETE ON location
    FOR EACH ROW EXECUTE PROCEDURE pmt_dlt_boundary_features();
    
/******************************************************************
 15. delete pmt_purge_project function
******************************************************************/
DROP FUNCTION IF EXISTS pmt_purge_project(integer);

/******************************************************************
 16. update pmt_purge_activity function
******************************************************************/
DROP FUNCTION IF EXISTS pmt_purge_activity(integer);
CREATE OR REPLACE FUNCTION pmt_purge_activity(a_id integer) RETURNS boolean AS $$
DECLARE
  children int[];
  child_id int;
  activity_record record;
  error_msg text;
BEGIN 
  -- no parameter is provided, exit
  IF $1 IS NULL THEN    
    RETURN FALSE;
  END IF;
  -- validate activity_id
  SELECT INTO activity_record * FROM activity WHERE id = $1;
  IF activity_record IS NULL THEN
    -- id doesn't exsist, exit
    RETURN FALSE;
  ELSE
    -- collect the children activity ids if there are children
    SELECT INTO children array_agg(id) FROM activity WHERE parent_id = activity_record.id;    
  END IF;
  
  IF array_length(children,1)>0 THEN
    -- loop through all the children and purge each child activity
    FOREACH child_id IN ARRAY children LOOP
      -- Purge taxonomy associated data
      DELETE FROM activity_taxonomy WHERE activity_id = child_id;
      DELETE FROM financial_taxonomy WHERE financial_id IN (SELECT id FROM financial WHERE activity_id = child_id);
      DELETE FROM detail_taxonomy WHERE detail_id IN (SELECT id FROM detail WHERE activity_id = child_id);
      DELETE FROM result_taxonomy WHERE result_id IN (SELECT id FROM result WHERE activity_id = child_id);
      DELETE FROM location_taxonomy WHERE location_id IN (SELECT id FROM location WHERE activity_id = child_id);
      DELETE FROM participation_taxonomy WHERE participation_id IN (SELECT id FROM participation WHERE activity_id = child_id);
      -- purge related data
      DELETE FROM financial WHERE activity_id = child_id;
      DELETE FROM detail WHERE activity_id = child_id;
      DELETE FROM result WHERE activity_id = child_id;
      DELETE FROM activity_contact WHERE activity_id = child_id;
      DELETE FROM location WHERE activity_id = child_id;	
      DELETE FROM participation WHERE activity_id = child_id;
      -- purge user permissions
      DELETE FROM user_activity_role WHERE activity_id = child_id;
      -- purge the activity
      DELETE FROM activity WHERE id = child_id;
    END LOOP;
  END IF;

  -- purge the requested activity
  -- purge taxonomy associated data
  DELETE FROM activity_taxonomy WHERE activity_id = $1;
  DELETE FROM financial_taxonomy WHERE financial_id IN (SELECT id FROM financial WHERE activity_id = $1);
  DELETE FROM detail_taxonomy WHERE detail_id IN (SELECT id FROM detail WHERE activity_id = $1);
  DELETE FROM result_taxonomy WHERE result_id IN (SELECT id FROM result WHERE activity_id = $1);
  DELETE FROM location_taxonomy WHERE location_id IN (SELECT id FROM location WHERE activity_id = $1);
  DELETE FROM participation_taxonomy WHERE participation_id IN (SELECT id FROM participation WHERE activity_id = $1);
  -- purge related data
  DELETE FROM financial WHERE activity_id = $1;
  DELETE FROM detail WHERE activity_id = $1;
  DELETE FROM result WHERE activity_id = $1;
  DELETE FROM activity_contact WHERE activity_id = $1;
  DELETE FROM location WHERE activity_id = $1;	
  DELETE FROM participation WHERE activity_id = $1;
  -- purge user permissions
  DELETE FROM user_activity_role WHERE activity_id = $1;
  -- purge the activity
  DELETE FROM activity WHERE id = $1;
  -- return success				
  RETURN TRUE;

EXCEPTION
  -- some type of error occurred, return unsuccessful
     WHEN others THEN 
       GET STACKED DIAGNOSTICS error_msg = MESSAGE_TEXT;
       RAISE NOTICE 'Error: %', error_msg;
       RETURN FALSE;
END;  
$$ LANGUAGE 'plpgsql';

/******************************************************************
 17. create pmt_purge_activities function
******************************************************************/
DROP FUNCTION IF EXISTS pmt_purge_activities(int[]);
CREATE OR REPLACE FUNCTION pmt_purge_activities(a_id int[]) RETURNS boolean AS $$
DECLARE
  record_id int;
  error_msg text;
BEGIN 
  -- no parameter is provided, exit
  IF $1 IS NULL THEN    
    RETURN FALSE;
  END IF;
 
  IF array_length(a_id,1)>0 THEN
    -- loop through all the activity_ids and purge each activity
    FOREACH record_id IN ARRAY a_id LOOP
      EXECUTE 'SELECT * FROM pmt_purge_activity(' || record_id || ')';
    END LOOP;
  ELSE
    -- exit if array is empty
    RETURN FALSE;
  END IF;
  -- success
  RETURN TRUE;

EXCEPTION
  -- some type of error occurred, return unsuccessful
     WHEN others THEN 
       GET STACKED DIAGNOSTICS error_msg = MESSAGE_TEXT;
       RAISE NOTICE 'Error: %', error_msg;
       RETURN FALSE;
END;  
$$ LANGUAGE 'plpgsql';

-- update permissions
GRANT USAGE ON SCHEMA public TO pmt_read;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO pmt_read;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO pmt_read;
GRANT USAGE ON SCHEMA public TO pmt_write;
GRANT SELECT,INSERT ON ALL TABLES IN SCHEMA public TO pmt_write;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO pmt_write;