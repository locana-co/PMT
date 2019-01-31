/******************************************************************
Change Script 2.0.8.37 - consolidated.
1. pmt_projects - new function to retrieve all projects
1. pmt_activities - new function to retrieve all activities
******************************************************************/
INSERT INTO version(version, iteration, changeset) VALUES (2.0, 8, 37);
-- select * from version order by changeset desc;

DROP FUNCTION IF EXISTS pmt_projects()  CASCADE;
DROP FUNCTION IF EXISTS pmt_activities()  CASCADE;

-- select * from pmt_projects();
-- select * from pmt_activities();

/******************************************************************
  pmt_projects
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_projects() RETURNS SETOF pmt_json_result_type AS $$
DECLARE 
  error_msg1 text;
  error_msg2 text;
  error_msg3 text; 
  rec record;
BEGIN 

    FOR rec IN (SELECT row_to_json(j) FROM(

	SELECT p.project_id, p.title, ((SELECT array_agg(activity_id)::int[] FROM activity a WHERE a.project_id = p.project_id AND a.active = true)) as activity_ids
	FROM project p
	WHERE p.active = true
	ORDER BY p.title
	
	) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
     
EXCEPTION WHEN others THEN
    GET STACKED DIAGNOSTICS error_msg1 = MESSAGE_TEXT,
                          error_msg2 = PG_EXCEPTION_DETAIL,
                          error_msg3 = PG_EXCEPTION_HINT;
    FOR rec IN (SELECT row_to_json(j) FROM(SELECT 'Internal Error - Contact your DBA with the following error message: ' || error_msg1 as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;	 
END; 
$$ LANGUAGE 'plpgsql';
/******************************************************************
  pmt_activities
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_activities() RETURNS SETOF pmt_json_result_type AS $$
DECLARE 
  error_msg1 text;
  error_msg2 text;
  error_msg3 text; 
  rec record;
BEGIN 

    FOR rec IN (SELECT row_to_json(j) FROM(

	SELECT a.activity_id, a.title, ((SELECT array_agg(location_id)::int[] FROM location l WHERE l.activity_id = a.activity_id AND l.active = true)) as location_ids
	FROM activity a
	WHERE a.active = true
	ORDER BY a.title
	
	) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
     
EXCEPTION WHEN others THEN
    GET STACKED DIAGNOSTICS error_msg1 = MESSAGE_TEXT,
                          error_msg2 = PG_EXCEPTION_DETAIL,
                          error_msg3 = PG_EXCEPTION_HINT;
    FOR rec IN (SELECT row_to_json(j) FROM(SELECT 'Internal Error - Contact your DBA with the following error message: ' || error_msg1 as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;	 
END; 
$$ LANGUAGE 'plpgsql';

-- update permissions
GRANT USAGE ON SCHEMA public TO pmt_read;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO pmt_read;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO pmt_read;
GRANT USAGE ON SCHEMA public TO pmt_write;
GRANT SELECT,INSERT ON ALL TABLES IN SCHEMA public TO pmt_write;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO pmt_write;