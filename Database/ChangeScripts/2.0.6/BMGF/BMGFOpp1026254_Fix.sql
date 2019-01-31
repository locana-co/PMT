-- use find/replace to replace below number with number returned from above   757(iteration#6) 765(iteration#5) 

UPDATE location SET point = ST_GeomFromText('POINT(-0.184042 5.618233)', 4326) WHERE activity_id = (SELECT activity_id FROM activity WHERE title = 'FairMatch Support' AND project_id = 757);
UPDATE location SET point = ST_GeomFromText('POINT(-0.184042 5.618233)', 4326) WHERE activity_id = (SELECT activity_id FROM activity WHERE title = 'TechnoServe' AND project_id = 757);

select * from refresh_taxonomy_lookup();

vacuum;

analyze;

