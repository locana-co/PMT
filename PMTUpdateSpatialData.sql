/**************************************************************
The GAUL multi-polygons have some oddities in them. Dump the 
polygons and recollect them to fix the issue.
***************************************************************/

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
