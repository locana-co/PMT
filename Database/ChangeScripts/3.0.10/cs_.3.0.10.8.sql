/******************************************************************
Change Script 3.0.10.8
1. Adjust table schema of GADM level 0 spatial table (REQUIRES table import before executing this script, see prerequistes)
2. Adjust table schema of GADM level 1 spatial table (REQUIRES table import before executing this script, see prerequistes)
3. Adjust table schema of GADM level 2 spatial table (REQUIRES table import before executing this script, see prerequistes)
4. Adjust table schema of GADM level 3 spatial table (REQUIRES table import before executing this script, see prerequistes)
5. Ensure upd_boundary_features is up to date (no changes)
6. Update all active location for new boundaries
 
Prerequistes:
1. download and extract GADM import sql: s3 /spatialdev/projects/PMT/gadm_2.8.tar.gz
2. execute each sql file from the command line (i.e. psql -U postgres -d <database> -f <file>)
  a. gadm_adm0.sql
  b. gadm_adm1.sql
  c. gadm_adm2.sql
  d. gadm_adm3.sql
******************************************************************/
INSERT INTO version(_version, _iteration, _changeset) VALUES (3.0, 10, 8);
-- select * from version order by _iteration desc, _changeset desc;
/******************************************************************
 1. update loaded gadm_adm0 table to adhere to PMT standards
******************************************************************/
-- change name
ALTER TABLE gadm_adm0 RENAME TO gadm0;
-- change primary key name
ALTER INDEX gadm_adm0_pkey RENAME TO gadm0_pkey;
-- add boundary record
INSERT INTO boundary (_name, _description, _spatial_table, _version, _source, _created_by, _updated_by)
  VALUES('GADM Level 0','Global Administrative Areas - Level 0 - Countries', 'gadm0', '2015', 'http://www.gadm.org/', 'cs_.3.0.10.8', 'cs_.3.0.10.8');
-- update existing fields to adhere to pmt field naming convention
ALTER TABLE gadm0 RENAME COLUMN gid TO id;
ALTER TABLE gadm0 RENAME COLUMN iso TO _code;
ALTER TABLE gadm0 RENAME COLUMN name_engli TO _name;
ALTER TABLE gadm0 RENAME COLUMN geom TO _polygon;
-- remove unused columns
ALTER TABLE gadm0 DROP COLUMN shape_leng;
ALTER TABLE gadm0 DROP COLUMN shape_area;
ALTER TABLE gadm0 DROP COLUMN objectid;
ALTER TABLE gadm0 DROP COLUMN id_0;
-- add boundary id
ALTER TABLE gadm0 ADD COLUMN boundary_id integer;
UPDATE gadm0 SET boundary_id = (SELECT id FROM boundary WHERE _spatial_table = 'gadm0');
ALTER TABLE gadm0 ADD CONSTRAINT fk_gadm0_boundary_id FOREIGN KEY (boundary_id) REFERENCES boundary; 
-- add additional pmt required fields
ALTER TABLE gadm0 ADD COLUMN _label character varying;
-- add _point field and populate with centroid
ALTER TABLE gadm0 ADD COLUMN _point geometry;
ALTER TABLE gadm0 ADD CONSTRAINT chk_gadm0_geotype_point CHECK (geometrytype(_point) = 'POINT'::text OR _point IS NULL);
ALTER TABLE gadm0 ADD CONSTRAINT chk_gadm0_srid_point CHECK (ST_SRID(_point) = 4326);
UPDATE gadm0 SET _point = ST_GeomFromText(ST_AsText(ST_Centroid(_polygon)), 4326);
-- add additional pmt required fields
ALTER TABLE gadm0 ADD COLUMN _active boolean NOT NULL DEFAULT true;
ALTER TABLE gadm0 ADD COLUMN _retired_by integer;
ALTER TABLE gadm0 ADD COLUMN _created_by character varying(150);
ALTER TABLE gadm0 ADD COLUMN _created_date timestamp without time zone NOT NULL DEFAULT ('now'::text)::date;
ALTER TABLE gadm0 ADD COLUMN _updated_by character varying(150);
ALTER TABLE gadm0 ADD COLUMN _updated_date timestamp without time zone NOT NULL DEFAULT ('now'::text)::date;
UPDATE gadm0 SET _label = _name, _created_by = 'cs_.3.0.10.8', _updated_by = 'cs_.3.0.10.8';
-- set correct srid
SELECT UpdateGeometrySRID('public', 'gadm0', '_polygon', 4326);
-- add constraints
ALTER TABLE gadm0 ADD CONSTRAINT chk_gadm0_created_by CHECK (_created_by IS NOT NULL) NOT VALID;
ALTER TABLE gadm0 ADD CONSTRAINT chk_gadm0_updated_by CHECK (_updated_by IS NOT NULL) NOT VALID;
ALTER TABLE gadm0 ADD CONSTRAINT chk_gadm0_geotype_polygon CHECK (geometrytype(_polygon) = 'MULTIPOLYGON'::text OR _polygon IS NULL);
ALTER TABLE gadm0 ADD CONSTRAINT chk_gadm0_srid_polygon CHECK (ST_SRID(_polygon) = 4326);
-- create indexes
CREATE INDEX idx_gadm0_polygon ON gadm0 USING GIST(_polygon);
CREATE INDEX idx_gadm0_point ON gadm0 USING GIST(_point);
CREATE INDEX idx_gadm0_name ON gadm0 ((lower(_name)));
/******************************************************************
 2. update loaded gadm_adm1 table to adhere to PMT standards
******************************************************************/
-- change name
ALTER TABLE gadm_adm1 RENAME TO gadm1;
-- change primary key name
ALTER INDEX gadm_adm1_pkey RENAME TO gadm1_pkey;
-- add boundary record
INSERT INTO boundary (_name, _description, _spatial_table, _version, _source, _created_by, _updated_by)
  VALUES('GADM Level 1','Global Administrative Areas - Level 1', 'gadm1', '2015', 'http://www.gadm.org/', 'cs_.3.0.10.8', 'cs_.3.0.10.8');
-- update existing fields to adhere to pmt field naming convention
ALTER TABLE gadm1 RENAME COLUMN gid TO id;
ALTER TABLE gadm1 RENAME COLUMN name_1 TO _name;
ALTER TABLE gadm1 RENAME COLUMN geom TO _polygon;
ALTER TABLE gadm1 RENAME COLUMN name_0 TO _gadm0_name;
-- remove unused columns
ALTER TABLE gadm1 DROP COLUMN objectid;
ALTER TABLE gadm1 DROP COLUMN id_0;
ALTER TABLE gadm1 DROP COLUMN id_1;
ALTER TABLE gadm1 DROP COLUMN iso;
ALTER TABLE gadm1 DROP COLUMN shape_leng;
ALTER TABLE gadm1 DROP COLUMN shape_area;
-- add boundary id
ALTER TABLE gadm1 ADD COLUMN boundary_id integer;
UPDATE gadm1 SET boundary_id = (SELECT id FROM boundary WHERE _spatial_table = 'gadm1');
ALTER TABLE gadm1 ADD CONSTRAINT fk_gadm1_boundary_id FOREIGN KEY (boundary_id) REFERENCES boundary; 
-- add additional pmt required fields
ALTER TABLE gadm1 ADD COLUMN _code character varying(50);
ALTER TABLE gadm1 ADD COLUMN _label character varying;
-- add _point field and populate with centroid
ALTER TABLE gadm1 ADD COLUMN _point geometry;
ALTER TABLE gadm1 ADD CONSTRAINT chk_gadm1_geotype_point CHECK (geometrytype(_point) = 'POINT'::text OR _point IS NULL);
ALTER TABLE gadm1 ADD CONSTRAINT chk_gadm1_srid_point CHECK (ST_SRID(_point) = 4326);
UPDATE gadm1 SET _point = ST_GeomFromText(ST_AsText(ST_Centroid(_polygon)), 4326);
-- add additional pmt required fields
ALTER TABLE gadm1 ADD COLUMN _active boolean NOT NULL DEFAULT true;
ALTER TABLE gadm1 ADD COLUMN _retired_by integer;
ALTER TABLE gadm1 ADD COLUMN _created_by character varying(150);
ALTER TABLE gadm1 ADD COLUMN _created_date timestamp without time zone NOT NULL DEFAULT ('now'::text)::date;
ALTER TABLE gadm1 ADD COLUMN _updated_by character varying(150);
ALTER TABLE gadm1 ADD COLUMN _updated_date timestamp without time zone NOT NULL DEFAULT ('now'::text)::date;
UPDATE gadm1 SET _label = _name, _created_by = 'cs_.3.0.10.8', _updated_by = 'cs_.3.0.10.8';
-- set correct srid
SELECT UpdateGeometrySRID('public', 'gadm1', '_polygon', 4326);
-- add constraints
ALTER TABLE gadm1 ADD CONSTRAINT chk_gadm1_created_by CHECK (_created_by IS NOT NULL) NOT VALID;
ALTER TABLE gadm1 ADD CONSTRAINT chk_gadm1_updated_by CHECK (_updated_by IS NOT NULL) NOT VALID;
ALTER TABLE gadm1 ADD CONSTRAINT chk_gadm1_geotype_polygon CHECK (geometrytype(_polygon) = 'MULTIPOLYGON'::text OR _polygon IS NULL);
ALTER TABLE gadm1 ADD CONSTRAINT chk_gadm1_srid_polygon CHECK (ST_SRID(_polygon) = 4326);
-- create indexes
CREATE INDEX idx_gadm1_polygon ON gadm1 USING GIST(_polygon);
CREATE INDEX idx_gadm1_point ON gadm1 USING GIST(_point);
CREATE INDEX idx_gadm1_name ON gadm1 ((lower(_name)));
/******************************************************************
 3. update loaded gadm_adm2 table to adhere to PMT standards
******************************************************************/
-- change name
ALTER TABLE gadm_adm2 RENAME TO gadm2;
-- change primary key name
ALTER INDEX gadm_adm2_pkey RENAME TO gadm2_pkey;
-- add boundary record
INSERT INTO boundary (_name, _description, _spatial_table, _version, _source, _created_by, _updated_by)
  VALUES('GADM Level 2','Global Administrative Areas - Level 2', 'gadm2', '2015', 'http://www.gadm.org/', 'cs_.3.0.10.8', 'cs_.3.0.10.8');
-- update existing fields to adhere to pmt field naming convention
ALTER TABLE gadm2 RENAME COLUMN gid TO id;
ALTER TABLE gadm2 RENAME COLUMN name_2 TO _name;
ALTER TABLE gadm2 RENAME COLUMN geom TO _polygon;
ALTER TABLE gadm2 RENAME COLUMN name_0 TO _gadm0_name;
ALTER TABLE gadm2 RENAME COLUMN name_1 TO _gadm1_name;
-- remove unused columns
ALTER TABLE gadm2 DROP COLUMN objectid;
ALTER TABLE gadm2 DROP COLUMN id_0;
ALTER TABLE gadm2 DROP COLUMN id_1;
ALTER TABLE gadm2 DROP COLUMN id_2;
ALTER TABLE gadm2 DROP COLUMN iso;
ALTER TABLE gadm2 DROP COLUMN shape_leng;
ALTER TABLE gadm2 DROP COLUMN shape_area;
-- add boundary id
ALTER TABLE gadm2 ADD COLUMN boundary_id integer;
UPDATE gadm2 SET boundary_id = (SELECT id FROM boundary WHERE _spatial_table = 'gadm2');
ALTER TABLE gadm2 ADD CONSTRAINT fk_gadm2_boundary_id FOREIGN KEY (boundary_id) REFERENCES boundary; 
-- add additional pmt required fields
ALTER TABLE gadm2 ADD COLUMN _code character varying(50);
ALTER TABLE gadm2 ADD COLUMN _label character varying;
-- add _point field and populate with centroid
ALTER TABLE gadm2 ADD COLUMN _point geometry;
ALTER TABLE gadm2 ADD CONSTRAINT chk_gadm2_geotype_point CHECK (geometrytype(_point) = 'POINT'::text OR _point IS NULL);
ALTER TABLE gadm2 ADD CONSTRAINT chk_gadm2_srid_point CHECK (ST_SRID(_point) = 4326);
UPDATE gadm2 SET _point = ST_GeomFromText(ST_AsText(ST_Centroid(_polygon)), 4326);
-- add additional pmt required fields
ALTER TABLE gadm2 ADD COLUMN _active boolean NOT NULL DEFAULT true;
ALTER TABLE gadm2 ADD COLUMN _retired_by integer;
ALTER TABLE gadm2 ADD COLUMN _created_by character varying(150);
ALTER TABLE gadm2 ADD COLUMN _created_date timestamp without time zone NOT NULL DEFAULT ('now'::text)::date;
ALTER TABLE gadm2 ADD COLUMN _updated_by character varying(150);
ALTER TABLE gadm2 ADD COLUMN _updated_date timestamp without time zone NOT NULL DEFAULT ('now'::text)::date;
UPDATE gadm2 SET _label = _name, _created_by = 'cs_.3.0.10.8', _updated_by = 'cs_.3.0.10.8';
-- set correct srid
SELECT UpdateGeometrySRID('public', 'gadm2', '_polygon', 4326);
-- add constraints
ALTER TABLE gadm2 ADD CONSTRAINT chk_gadm2_created_by CHECK (_created_by IS NOT NULL) NOT VALID;
ALTER TABLE gadm2 ADD CONSTRAINT chk_gadm2_updated_by CHECK (_updated_by IS NOT NULL) NOT VALID;
ALTER TABLE gadm2 ADD CONSTRAINT chk_gadm2_geotype_polygon CHECK (geometrytype(_polygon) = 'MULTIPOLYGON'::text OR _polygon IS NULL);
ALTER TABLE gadm2 ADD CONSTRAINT chk_gadm2_srid_polygon CHECK (ST_SRID(_polygon) = 4326);
-- create indexes
CREATE INDEX idx_gadm2_polygon ON gadm2 USING GIST(_polygon);
CREATE INDEX idx_gadm2_point ON gadm2 USING GIST(_point);
CREATE INDEX idx_gadm2_name ON gadm2 ((lower(_name)));
/******************************************************************
 4. update loaded gadm_adm3 table to adhere to PMT standards
******************************************************************/
-- change name
ALTER TABLE gadm_adm3 RENAME TO gadm3;
-- change primary key name
ALTER INDEX gadm_adm3_pkey RENAME TO gadm3_pkey;
-- add boundary record
INSERT INTO boundary (_name, _description, _spatial_table, _version, _source, _created_by, _updated_by)
  VALUES('GADM Level 3','Global Administrative Areas - Level 3', 'gadm3', '2015', 'http://www.gadm.org/', 'cs_.3.0.10.8', 'cs_.3.0.10.8');
-- update existing fields to adhere to pmt field naming convention
ALTER TABLE gadm3 RENAME COLUMN gid TO id;
ALTER TABLE gadm3 RENAME COLUMN name_3 TO _name;
ALTER TABLE gadm3 RENAME COLUMN geom TO _polygon;
ALTER TABLE gadm3 RENAME COLUMN name_0 TO _gadm0_name;
ALTER TABLE gadm3 RENAME COLUMN name_1 TO _gadm1_name;
ALTER TABLE gadm3 RENAME COLUMN name_2 TO _gadm2_name;
-- remove unused columns
ALTER TABLE gadm3 DROP COLUMN objectid;
ALTER TABLE gadm3 DROP COLUMN id_0;
ALTER TABLE gadm3 DROP COLUMN id_1;
ALTER TABLE gadm3 DROP COLUMN id_2;
ALTER TABLE gadm3 DROP COLUMN id_3;
ALTER TABLE gadm3 DROP COLUMN iso;
ALTER TABLE gadm3 DROP COLUMN shape_leng;
ALTER TABLE gadm3 DROP COLUMN shape_area;
-- add boundary id
ALTER TABLE gadm3 ADD COLUMN boundary_id integer;
UPDATE gadm3 SET boundary_id = (SELECT id FROM boundary WHERE _spatial_table = 'gadm3');
ALTER TABLE gadm3 ADD CONSTRAINT fk_gadm3_boundary_id FOREIGN KEY (boundary_id) REFERENCES boundary; 
-- add additional pmt required fields
ALTER TABLE gadm3 ADD COLUMN _code character varying(50);
ALTER TABLE gadm3 ADD COLUMN _label character varying;
-- add _point field and populate with centroid
ALTER TABLE gadm3 ADD COLUMN _point geometry;
ALTER TABLE gadm3 ADD CONSTRAINT chk_gadm3_geotype_point CHECK (geometrytype(_point) = 'POINT'::text OR _point IS NULL);
ALTER TABLE gadm3 ADD CONSTRAINT chk_gadm3_srid_point CHECK (ST_SRID(_point) = 4326);
UPDATE gadm3 SET _point = ST_GeomFromText(ST_AsText(ST_Centroid(_polygon)), 4326);
-- add additional pmt required fields
ALTER TABLE gadm3 ADD COLUMN _active boolean NOT NULL DEFAULT true;
ALTER TABLE gadm3 ADD COLUMN _retired_by integer;
ALTER TABLE gadm3 ADD COLUMN _created_by character varying(150);
ALTER TABLE gadm3 ADD COLUMN _created_date timestamp without time zone NOT NULL DEFAULT ('now'::text)::date;
ALTER TABLE gadm3 ADD COLUMN _updated_by character varying(150);
ALTER TABLE gadm3 ADD COLUMN _updated_date timestamp without time zone NOT NULL DEFAULT ('now'::text)::date;
UPDATE gadm3 SET _label = _name, _created_by = 'cs_.3.0.10.8', _updated_by = 'cs_.3.0.10.8';
-- set correct srid
SELECT UpdateGeometrySRID('public', 'gadm3', '_polygon', 4326);
-- add constraints
ALTER TABLE gadm3 ADD CONSTRAINT chk_gadm3_created_by CHECK (_created_by IS NOT NULL) NOT VALID;
ALTER TABLE gadm3 ADD CONSTRAINT chk_gadm3_updated_by CHECK (_updated_by IS NOT NULL) NOT VALID;
ALTER TABLE gadm3 ADD CONSTRAINT chk_gadm3_geotype_polygon CHECK (geometrytype(_polygon) = 'MULTIPOLYGON'::text OR _polygon IS NULL);
ALTER TABLE gadm3 ADD CONSTRAINT chk_gadm3_srid_polygon CHECK (ST_SRID(_polygon) = 4326);
-- create indexes
CREATE INDEX idx_gadm3_polygon ON gadm3 USING GIST(_polygon);
CREATE INDEX idx_gadm3_point ON gadm3 USING GIST(_point);
CREATE INDEX idx_gadm3_name ON gadm3 ((lower(_name)));
/******************************************************************
 5. Ensure upd_boundary_features is updated (no changes)
******************************************************************/
DROP FUNCTION IF EXISTS upd_boundary_features();
CREATE OR REPLACE FUNCTION pmt_upd_boundary_features()
RETURNS trigger AS $pmt_upd_boundary_features$
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
  -- Remove all existing location boundary information for this location (to be recreated by this trigger)
  EXECUTE 'DELETE FROM location_boundary WHERE location_id = ' || NEW.id;
  RAISE NOTICE 'Refreshing boundary features for id % ...', NEW.id;

  -- if a boundary_id and feature_id are provided then get a centroid of the requested feature to serve as the point
  -- locations can be polygons by making an association to an existing boundary feature
  IF (SELECT * FROM pmt_validate_boundary_feature(NEW.boundary_id, NEW.feature_id)) THEN
    SELECT INTO spatialtable _spatial_table FROM boundary b WHERE _active = true AND b.id = NEW.boundary_id;
    -- get centroid and assign as NEW._point
    execute_statement := 'SELECT ST_Transform(ST_Centroid((SELECT _polygon FROM ' || quote_ident(spatialtable) || ' WHERE id = ' || NEW.feature_id || ' LIMIT 1)),4326)' ;
    EXECUTE execute_statement INTO centroid;
    IF (centroid IS NOT NULL) THEN	      
      NEW._point := centroid;
      -- RAISE NOTICE '---> Centroid of boundary assigned based on boundary assoication.';
    END IF;
  END IF; 

  -- if a point is provided or assigned above then find all the boundary features 
  -- that are intersected by the point
  IF (NEW._point IS NOT NULL) THEN
    -- loop through each available boundary
    FOR boundary IN SELECT * FROM boundary LOOP
      -- find the feature in the boundary, interescted by our point
      FOR feature IN EXECUTE 'SELECT * FROM ' || quote_ident(boundary._spatial_table)  || ' WHERE ST_Intersects(ST_PointFromText(''' || 
		ST_AsText(NEW._point) || ''', 4326), _polygon)' LOOP
	-- for each intersected feature, record its values in the location_boundary table
	EXECUTE 'INSERT INTO location_boundary VALUES (' || NEW.id || ', ' || feature.boundary_id || ', ' || feature.id || ', ' || 
		ST_Area(feature._polygon) || ', ' || quote_literal(feature._name) || ')';
	-- RAISE NOTICE '---> Creating a boundary assoication for boundary: %', boundary._spatial_table;
	-- assign all associated taxonomy classification from intersected features to new location
	FOR ft IN (SELECT * FROM feature_taxonomy WHERE feature_id = feature.id) LOOP
	  -- replace all previous taxonomy classification associations with new for the given taxonomy
	  DELETE FROM location_taxonomy WHERE location_id = NEW.id AND classification_id IN 
		(SELECT classification_id FROM _taxonomy_classifications WHERE taxonomy_id = (SELECT taxonomy_id FROM classification WHERE classification.id = ft.classification_id));    
	  INSERT INTO location_taxonomy VALUES (NEW.id, ft.classification_id, 'id');
	  -- RAISE NOTICE '------> Creating a taxonomy assoication for id: %', ft.classification_id;
	END LOOP;
      END LOOP;	
    END LOOP;
  END IF;

RETURN NEW;

END;
$pmt_upd_boundary_features$ LANGUAGE plpgsql; 
DROP TRIGGER IF EXISTS pmt_upd_boundary_features ON location;
CREATE TRIGGER pmt_upd_boundary_features AFTER INSERT OR UPDATE ON location
    FOR EACH ROW EXECUTE PROCEDURE pmt_upd_boundary_features();

/******************************************************************
 6. Update all active location for new boundaries
******************************************************************/
UPDATE location SET _title = _title WHERE _active = true;
