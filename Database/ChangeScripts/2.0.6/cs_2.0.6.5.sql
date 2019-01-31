/******************************************************************
Change Script 2.0.6.5 - Consolidated

1. Change to the spatial data processing. Instead of creating a 
data dump table for gual, going to update the gaul geometry in 
place. 
******************************************************************/
UPDATE config SET changeset = 5, updated_date = current_date WHERE "version" = 2.0 AND iteration = 6;
-- select * from pmt_version()

/******************************************************************
  UpdatePMTSpatialData.sql
******************************************************************/
-- number of locations without association to a boundary feature:
-- (1) 4665
-- (2) 1069
-- (3) 298
select l.location_id, lb.boundary_id
from location l
left join (select * from location_boundary where boundary_id = 3) lb
on l.location_id = lb.location_id
where lb.boundary_id is null

-- update gaul0
UPDATE gaul0 AS g 
SET polygon = foo.polygon
FROM (SELECT f.feature_id,ST_Collect(f.geom) as polygon FROM
(SELECT feature_id,(ST_DumpRings(polygon)).geom AS geom from gaul0) as f
GROUP BY f.feature_id) as foo
WHERE g.feature_id = foo.feature_id;

-- update gaul1
UPDATE gaul1 AS g 
SET polygon = foo.polygon
FROM (SELECT f.feature_id,ST_Collect(f.geom) as polygon FROM
(SELECT feature_id,(ST_DumpRings(polygon)).geom AS geom from gaul1) as f
GROUP BY f.feature_id) as foo
WHERE g.feature_id = foo.feature_id;

-- update gaul2
UPDATE gaul2 AS g 
SET polygon = foo.polygon
FROM (SELECT f.feature_id,ST_Collect(f.geom) as polygon FROM
(SELECT feature_id,(ST_DumpRings(polygon)).geom AS geom from gaul2) as f
GROUP BY f.feature_id) as foo
WHERE g.feature_id = foo.feature_id;

-- cause all locations to be updated (run for change script only)
update location set description = null;

-- update looup
select * from refresh_taxonomy_lookup();

-- vacuum, analyze
vacuum;
analyze;

-- test update success:
-- (1) 44
-- (2) 44
-- (3) 45
select l.location_id, lb.boundary_id
from location l
left join (select * from location_boundary where boundary_id = 1) lb
on l.location_id = lb.location_id
where lb.boundary_id is null
