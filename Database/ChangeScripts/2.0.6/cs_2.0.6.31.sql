/******************************************************************
Change Script 2.0.6.31 - Consolidated.
1. organization_lookup - adding start and end dates.
******************************************************************/
INSERT INTO config(version, iteration, changeset) VALUES (2.0, 6, 31);
-- select * from config order by version, iteration, changeset, updated_date;

-- select * from pmt_stat_counts('59,94,107,126,160,186,244,256,768', '', '', '1-1-2009', '12-31-2017')

ALTER TABLE organization_lookup ADD COLUMN "start_date" date;
ALTER TABLE organization_lookup ADD COLUMN "end_date" date;

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

	EXECUTE 'INSERT INTO organization_lookup(project_id, activity_id, organization_id, start_date, end_date, taxonomy_ids,classification_ids,location_ids) ' ||
		'SELECT project_id, activity_id, organization_id, start_date, end_date, array_agg(distinct taxonomy_id) as taxonomy_ids, array_agg(distinct classification_id) as classification_ids, array_agg(distinct location_id) as location_ids ' ||
		'FROM taxonomy_lookup  ' ||
		'GROUP BY project_id, activity_id, organization_id, start_date, end_date';

	
    RAISE NOTICE 'Done refreshing taxonomy_lookup.';
    RETURN 1;
END;
$$ LANGUAGE plpgsql;

-- TRUNCATE TABLE organization_lookup;

-- INSERT INTO organization_lookup(project_id, activity_id, organization_id, start_date, end_date, taxonomy_ids,classification_ids,location_ids)
-- SELECT project_id, activity_id, organization_id, start_date, end_date, array_agg(distinct taxonomy_id) as taxonomy_ids, array_agg(distinct classification_id) as classification_ids, array_agg(distinct location_id) as location_ids
-- FROM taxonomy_lookup
-- GROUP BY project_id, activity_id, organization_id, start_date, end_date;

-- SELECT refresh_taxonomy_lookup();		
-- VACUUM;
-- ANALYZE;