-- create dump table of gaul0 to single polygons in order to make location intersection query for taxonomy more effcient

-- create table
CREATE TABLE gaul0_dump
AS SELECT feature_id,(ST_DumpRings(polygon)).geom AS polygon from gaul0;
-- create pk
ALTER TABLE gaul0_dump ADD Column gaul0_dump_id serial PRIMARY KEY;
-- create index
CREATE INDEX idx_gaul0_dump_polygon
on gaul0_dump
USING gist(polygon);