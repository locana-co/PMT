/******************************************************************
Change Script 2.0.6.30 - Consolidated.
1. pmt_iati_import - new function. import iati xml document into
the pmt.
******************************************************************/
INSERT INTO config(version, iteration, changeset) VALUES (2.0, 6, 30);
-- select * from config order by version, iteration, changeset, updated_date desc;

-- SELECT * FROM pmt_iati_import('/usr/local/pmt_iati/BoliviaIATI.xml', 'Bolivia', true);

DROP FUNCTION IF EXISTS pmt_iati_import(text, character varying, boolean) CASCADE;

CREATE OR REPLACE FUNCTION pmt_iati_import(file_path text, data_group_name character varying, replace_all boolean) RETURNS boolean AS $$
DECLARE 
  purge_project_ids integer[];
  purge_id integer;
  group_name text;
BEGIN 
     RAISE NOTICE 'path: %', $1;
     RAISE NOTICE 'group: %', $2;
     RAISE NOTICE 'tf: %', $3;
     
     IF $1 IS NULL OR $2 IS NULL THEN    
       RETURN FALSE;
     END IF;    
     
     -- get project_ids to purge by data_group
     SELECT INTO purge_project_ids array_agg(project_id)::INT[] FROM xml WHERE lower(data_group) = lower($2);

     -- data group 
     SELECT INTO group_name name FROM pmt_data_groups() WHERE lower(name) = lower($2);
     IF group_name = '' OR group_name IS NULL THEN
       group_name := $2;
     END IF;

	RAISE NOTICE 'path: %', $1;
	RAISE NOTICE 'data_group_name: %', data_group_name;
     -- load new xml data
     INSERT INTO xml (action, xml, data_group) VALUES('insert',convert_from(pmt_bytea_import($1), 'utf-8')::xml, group_name);     
     
     IF purge_project_ids IS NULL THEN
       PERFORM refresh_taxonomy_lookup();
     ELSE 
       IF replace_all = TRUE THEN
         FOREACH purge_id IN ARRAY purge_project_ids LOOP
           PERFORM pmt_purge_project(purge_id);
         END LOOP;
       END IF;
     END IF;
     RETURN TRUE;
     
-- EXCEPTION WHEN others THEN
--     RETURN FALSE;
END; 
$$ LANGUAGE 'plpgsql';
