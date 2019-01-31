/******************************************************************
Change Script 2.0.6.10 - Consolidated

1. location_lookup - creating additional lookup optimized for performance
2. organization_lookup - creating additional lookup optimized for performance
3. refresh_taxonomy_lookup - adding functionality to update additional
lookup tables.
******************************************************************/
UPDATE config SET changeset = 10, updated_date = current_date WHERE "version" = 2.0 AND iteration = 6;
-- SELECT pmt_version();

CREATE TABLE "organization_lookup"
(
	"organization_lookup_id" SERIAL				NOT NULL
	,"project_id"		integer 					
	,"activity_id"		integer 
	,"organization_id"	integer 	
	,"taxonomy_ids"		integer[] 
	,"classification_ids"	integer[] 
	,"location_ids"		integer[] 
	,CONSTRAINT organization_lookup_id PRIMARY KEY(organization_lookup_id)
);

-- Create index for organization_lookup
CREATE INDEX organization_lookup_project_id_idx on organization_lookup(project_id);
CREATE INDEX organization_lookup_activity_id_idx on organization_lookup(activity_id);
CREATE INDEX organization_lookup_location_id_idx on organization_lookup(organization_id);

CREATE TABLE "location_lookup"
(
	"location_lookup_id"	SERIAL				NOT NULL
	,"project_id"		integer 					
	,"activity_id"		integer 
	,"location_id"		integer 	
	,"start_date"		date
	,"end_date"		date
	,"x"			integer
	,"y"			integer
	,"georef"		character varying(20)
	,"taxonomy_ids"		integer[] 
	,"classification_ids"	integer[] 
	,"organization_ids"	integer[] 
	,CONSTRAINT location_lookup_id PRIMARY KEY(location_lookup_id)
);

-- Create index for location_lookup
CREATE INDEX location_lookup_project_id_idx on location_lookup(project_id);
CREATE INDEX location_lookup_activity_id_idx on location_lookup(activity_id);
CREATE INDEX location_lookup_location_id_idx on location_lookup(location_id);
CREATE INDEX location_lookup_start_date_idx on location_lookup(start_date);
CREATE INDEX location_lookup_end_date_idx on location_lookup(end_date);


-- function to support the taxonomy_lookup table
CREATE OR REPLACE FUNCTION refresh_taxonomy_lookup() RETURNS integer AS $$
BEGIN
    RAISE NOTICE 'Refreshing taxonomy_lookup...';

        EXECUTE 'TRUNCATE TABLE taxonomy_lookup';
        EXECUTE 'INSERT INTO taxonomy_lookup(project_id, activity_id, location_id, organization_id, participation_id, start_date, end_date, x, y, georef, taxonomy_id, classification_id) '
                || 'SELECT project_id, activity_id, location_id, organization_id, participation_id, activity_start, activity_end, x, y, georef, t.taxonomy_id, foo.classification_id ' 
		|| 'FROM(SELECT pa.project_id, pa.activity_id, pa.location_id, pa.organization_id, pa.participation_id, pa.activity_start, pa.activity_end, pa.x, pa.y, pa.georef, et.classification_id '
		|| 'FROM active_project_activities pa '
		|| 'JOIN entity_taxonomy et '
		|| 'ON pa.project_id = et.id AND field = ''project_id'' '
		|| 'UNION '
		|| 'SELECT pa.project_id, pa.activity_id, pa.location_id, pa.organization_id, pa.participation_id, pa.activity_start, pa.activity_end, pa.x, pa.y, pa.georef, et.classification_id '
		|| 'FROM active_project_activities pa '
		|| 'JOIN entity_taxonomy et '
		|| 'ON pa.activity_id = et.id AND field = ''activity_id'' '
		|| 'UNION '
		|| 'SELECT pa.project_id, pa.activity_id, pa.location_id, pa.organization_id, pa.participation_id, pa.activity_start, pa.activity_end, pa.x, pa.y, pa.georef, et.classification_id '
		|| 'FROM active_project_activities pa '
		|| 'JOIN entity_taxonomy et '
		|| 'ON pa.location_id = et.id AND field = ''location_id'' '
		|| 'UNION '
		|| 'SELECT pa.project_id, pa.activity_id, pa.location_id, pa.organization_id, pa.participation_id, pa.activity_start, pa.activity_end, pa.x, pa.y, pa.georef, et.classification_id ' 
		|| 'FROM active_project_activities pa '
		|| 'JOIN entity_taxonomy et '
		|| 'ON pa.organization_id = et.id AND field = ''organization_id'' '
		|| 'UNION '
		|| 'SELECT pa.project_id, pa.activity_id, pa.location_id, pa.organization_id, pa.participation_id, pa.activity_start, pa.activity_end, pa.x, pa.y, pa.georef, et.classification_id '
		|| 'FROM active_project_activities pa '
		|| 'JOIN entity_taxonomy et '
		|| 'ON pa.participation_id = et.id AND field = ''participation_id'' '
		|| ') as foo '
		|| 'JOIN classification c '
		|| 'ON foo.classification_id = c.classification_id '
		|| 'JOIN taxonomy t '
		|| 'ON c.taxonomy_id = t.taxonomy_id ';

    	EXECUTE 'TRUNCATE TABLE location_lookup';	

    	EXECUTE 'INSERT INTO location_lookup(project_id, activity_id, location_id, start_date, end_date, x, y, georef, taxonomy_ids, classification_ids, organization_ids) ' ||
		'SELECT project_id, activity_id, location_id, start_date, end_date, x, y, georef, array_agg(distinct taxonomy_id) as taxonomy_ids, array_agg(distinct classification_id) as classification_ids, array_agg(distinct organization_id) as organization_ids ' ||
		'FROM taxonomy_lookup ' ||
		'GROUP BY project_id, activity_id, location_id, start_date, end_date, x, y, georef';

	EXECUTE 'TRUNCATE TABLE organization_lookup';

	EXECUTE 'INSERT INTO organization_lookup(project_id, activity_id, organization_id, taxonomy_ids,classification_ids,location_ids) ' ||
		'SELECT project_id, activity_id, organization_id, array_agg(distinct taxonomy_id) as taxonomy_ids, array_agg(distinct classification_id) as classification_ids, array_agg(distinct location_id) as location_ids ' ||
		'FROM taxonomy_lookup  ' ||
		'GROUP BY project_id, activity_id, organization_id';

	
    RAISE NOTICE 'Done refreshing taxonomy_lookup.';
    RETURN 1;
END;
$$ LANGUAGE plpgsql;

-- SELECT refresh_taxonomy_lookup();

-- INSERT INTO location_lookup(project_id, activity_id, location_id, start_date, end_date, x, y, georef, taxonomy_ids, classification_ids, organization_ids) 
-- SELECT project_id, activity_id, location_id, start_date, end_date, x, y, georef, array_agg(distinct taxonomy_id) as taxonomy_ids, array_agg(distinct classification_id) as classification_ids, array_agg(distinct organization_id) as organization_ids 
-- FROM taxonomy_lookup 
-- GROUP BY project_id, activity_id, location_id, start_date, end_date, x, y, georef;

-- INSERT INTO organization_lookup(project_id, activity_id, organization_id, taxonomy_ids,classification_ids,location_ids)
-- SELECT project_id, activity_id, organization_id, array_agg(distinct taxonomy_id) as taxonomy_ids, array_agg(distinct classification_id) as classification_ids, array_agg(distinct location_id) as location_ids
-- FROM taxonomy_lookup
-- GROUP BY project_id, activity_id, organization_id;
		
-- VACUUM;
-- ANALYZE;