/******************************************************************
Change Script 3.0.10.11
1. update pmt_validate_activities function for v3.0 data 
   model
2. update pmt_validate_taxonomy function for v3.0 data 
   model
3. update & rename pmt_locations_by_polygon function for v3.0 data 
   model
4. update _activity_taxonomies view to include ids
5. update _activity_participants view to include ids
6. create pmt_activity_count_by_taxonomy function
7. create pmt_activity_count_by_participants function
******************************************************************/
INSERT INTO version(_version, _iteration, _changeset) VALUES (3.0, 10, 11);
-- select * from version order by _iteration desc, _changeset desc;

/******************************************************************
1. update pmt_validate_activities function for v3.0 data 
   model
  select * from pmt_validate_activities('14893,14895,1'); 
******************************************************************/
-- update function (update activity table column names)
CREATE OR REPLACE FUNCTION pmt_validate_activities(activity_ids character varying) RETURNS integer[] AS
$$
DECLARE 
  valid_activity_ids INT[];
  filter_activity_ids INT[];
BEGIN 
     IF $1 IS NULL THEN    
       RETURN valid_activity_ids;
     END IF;

     filter_activity_ids := string_to_array($1, ',')::int[];
     
     SELECT INTO valid_activity_ids array_agg(DISTINCT id)::INT[] FROM (SELECT id FROM activity WHERE _active = true AND id = ANY(filter_activity_ids) ORDER BY id) AS t;
     
     RETURN valid_activity_ids;

EXCEPTION
     WHEN others THEN RETURN NULL;
END;$$ LANGUAGE plpgsql; 

/******************************************************************
2. update pmt_validate_taxonomy function for v3.0 data 
   model
  select * from pmt_validate_taxonomy(23); 
******************************************************************/
-- update function (update taxonomy table column names)
CREATE OR REPLACE FUNCTION pmt_validate_taxonomy(id integer)RETURNS boolean AS
$$
DECLARE valid_id integer;
BEGIN 
     IF $1 IS NULL THEN    
       RETURN false;
     END IF;    
     
     SELECT INTO valid_id taxonomy.id FROM taxonomy WHERE _active = true AND taxonomy.id = $1;	 
     
     IF valid_id IS NULL THEN
      RETURN false;
     ELSE 
      RETURN true;
     END IF;
     
EXCEPTION WHEN others THEN
    RETURN FALSE;
END;$$ LANGUAGE plpgsql; 

/******************************************************************
3. update & rename pmt_locations_by_polygon function for v3.0 data 
   model, remove overloaded function
  select * from pmt_activities_by_polygon('POLYGON((-16.473 13.522,-16.469 13.186,-16.764 13.185,-16.797 13.491,-16.472 13.517,-16.473 13.522))'); 
******************************************************************/
-- delete old function(s)
DROP FUNCTION IF EXISTS pmt_locations_by_polygon(text);
DROP FUNCTION IF EXISTS pmt_locations_by_polygon(text, character varying);
-- create new function (renamed)
CREATE OR REPLACE FUNCTION pmt_activities_by_polygon(wktpolygon character varying) RETURNS SETOF pmt_json_result_type AS $$
DECLARE
  wkt text;
  rec record;
  error_msg text;
BEGIN  
  -- validate that incoming WKT is a polygon and that it is all uppercase
  IF (upper(substring(trim($1) from 1 for 7)) = 'POLYGON') THEN
    -- RAISE NOTICE 'WKT: %', $1;
    wkt := replace(lower(trim($1)), 'polygon', 'POLYGON');    
    -- RAISE NOTICE 'WKT Fixed: %', wkt; 

    -- list activities within wkt polygon
    FOR rec IN (
    SELECT row_to_json(j)
    FROM(
	SELECT array_to_json(array_agg(DISTINCT l.activity_id)) As activity_ids
	FROM location l
	WHERE _active = true
	AND ST_Contains(ST_GeomFromText(wkt, 4326), l._point)
	)j
    ) LOOP		
      RETURN NEXT rec;
    END LOOP;
    
  ELSE
    FOR rec IN (SELECT row_to_json(j) FROM (SELECT 'WKT must be of type POLYGON' as error) j ) LOOP		
      RETURN NEXT rec;
    END LOOP;	
  END IF;

  EXCEPTION WHEN others THEN 
      GET STACKED DIAGNOSTICS error_msg = MESSAGE_TEXT;  
    RAISE NOTICE 'Internal Error - Contact your DBA with the following error message: %', error_msg;
    
END;$$ LANGUAGE plpgsql; 

/******************************************************************
4. update _activity_taxonomies view to include ids
  select * from _activity_taxonomies;
******************************************************************/
DROP VIEW _activity_taxonomies;
CREATE OR REPLACE VIEW _activity_taxonomies AS 
 SELECT a.id,
    a._title,
    a.data_group_id,
    dg.classification AS data_group,
    tc.taxonomy_id,
    tc.taxonomy,
    tc.classification_id,
    tc.classification
   FROM activity a
     JOIN activity_taxonomy at ON a.id = at.activity_id
     JOIN _taxonomy_classifications tc ON at.classification_id = tc.classification_id
     LEFT JOIN _taxonomy_classifications dg ON a.data_group_id = dg.classification_id
  WHERE a._active = true
  ORDER BY a.id;

/******************************************************************
5. update _activity_participants view to include ids
  select * from _activity_participants;
******************************************************************/
DROP VIEW _activity_participants;
CREATE OR REPLACE VIEW _activity_participants AS 
 SELECT a.id,
    a._title,
    a.data_group_id,
    dg.classification AS data_group,
    o._name,
    tc.classification_id,
    tc.classification
   FROM activity a
     LEFT JOIN participation pp ON a.id = pp.activity_id
     LEFT JOIN participation_taxonomy ppt ON pp.id = ppt.participation_id
     LEFT JOIN _taxonomy_classifications tc ON ppt.classification_id = tc.classification_id
     LEFT JOIN organization o ON pp.organization_id = o.id
     LEFT JOIN _taxonomy_classifications dg ON a.data_group_id = dg.classification_id
  WHERE a._active = true AND pp._active = true
  ORDER BY a.id;
    
/******************************************************************
6. create pmt_activity_count_by_taxonomy function
  select * from pmt_activity_count_by_taxonomy(23, '14893,14895');   
******************************************************************/
-- create new function
CREATE OR REPLACE FUNCTION pmt_activity_count_by_taxonomy(tax_id int, activity_ids character varying) RETURNS SETOF pmt_json_result_type AS
$$
DECLARE
  rec record;
  is_valid_taxonomy_id boolean;
  valid_taxonomy_id integer;
  valid_activity_ids integer[];
  execute_statement text;
  error_msg text;
BEGIN
  -- both tax_id and activity_ids parameters are required
  IF $1 IS NULL OR $2 IS NULL THEN
    FOR rec IN (SELECT row_to_json(j) FROM(select 'Error: Both parameters are required.' as message) j) LOOP  RETURN NEXT rec; END LOOP; 
    RETURN;
  END IF;
  
  -- validate taxonomy id
  SELECT INTO is_valid_taxonomy_id * FROM pmt_validate_taxonomy($1);    
  IF is_valid_taxonomy_id THEN 
    valid_taxonomy_id := $1;
  ELSE 
    FOR rec IN (SELECT row_to_json(j) FROM(select 'Error: valid taxonomy is required.' as message) j) LOOP  RETURN NEXT rec; END LOOP; 
    RETURN;
  END IF;
    
  -- get valid activity_ids
  SELECT INTO valid_activity_ids * FROM pmt_validate_activities($2);

  -- must have at least on valid activity id to continue
  IF array_length(valid_activity_ids, 1) > 0 THEN
    -- count selected activities by taxonomy
    execute_statement := 'SELECT taxonomy, classification, count(DISTINCT id) as activity_ct ' ||
			 'FROM _activity_taxonomies  ' ||
			 'WHERE id = ANY(ARRAY['|| array_to_string(valid_activity_ids, ',') || ']) ' ||
			 'AND taxonomy_id = ' || valid_taxonomy_id || ' ' ||
			 'GROUP BY 1,2';

    RAISE NOTICE 'Execute statement: %', execute_statement;			

    FOR rec IN EXECUTE 'SELECT row_to_json(j) FROM (' || execute_statement || ')j' LOOP  		
	RETURN NEXT rec;
    END LOOP;
  ELSE
    FOR rec IN (SELECT row_to_json(j) FROM(select 'Error: Must have at least one valid activity id' as message) j) LOOP RETURN NEXT rec; END LOOP; 
    RETURN;
  END IF;

  EXCEPTION WHEN others THEN 
  GET STACKED DIAGNOSTICS error_msg = MESSAGE_TEXT;  
    RAISE NOTICE 'Internal Error - Contact your DBA with the following error message: %', error_msg;
    	
END;$$ LANGUAGE plpgsql; 

/******************************************************************
7. create pmt_activity_count_by_participants function
  select * from pmt_activity_count_by_participants(497, '1767,3188'); 
******************************************************************/
-- create new function
CREATE OR REPLACE FUNCTION pmt_activity_count_by_participants(classification_id integer, activity_ids character varying) RETURNS SETOF pmt_json_result_type AS
$$
DECLARE
  rec record;
  valid_classification_id integer;
  valid_activity_ids integer[];
  execute_statement text;
  error_msg text;
BEGIN
  -- both classification_id and activity_ids parameters required 
  IF $1 IS NULL OR $2 IS NULL THEN
    FOR rec IN (SELECT row_to_json(j) FROM(select 'Error: Both parameters are required.' as message) j) LOOP  RETURN NEXT rec; END LOOP; 
    RETURN;
  END IF;
 
  -- validate classification_id
  SELECT INTO valid_classification_id id FROM classification WHERE taxonomy_id = (SELECT id FROM taxonomy WHERE _name = 'Organisation Role') AND id = $1;
  IF valid_classification_id IS NULL THEN 
    FOR rec IN (SELECT row_to_json(j) FROM(select 'Error: Valid Organizational Role classification is required.' as message) j) LOOP  RETURN NEXT rec; END LOOP; 
    RETURN;
  END IF;  

  -- validate activity_ids
  SELECT INTO valid_activity_ids * FROM pmt_validate_activities($2);

  -- must have at least on valid activity id to continue
  IF array_length(valid_activity_ids, 1) > 0 THEN
    -- count selected activities by organization 
    execute_statement := 'SELECT array_to_json(array_agg(row_to_json(t))) AS organizations FROM ' ||
			 '(SELECT _name AS name, count(DISTINCT id) AS activity_ct ' ||
			 'FROM _activity_participants ' ||
			 'WHERE id = ANY(ARRAY['|| array_to_string(valid_activity_ids, ',') || ']) ' ||
			 'AND classification_id = ' || valid_classification_id ||
			 'GROUP BY _name ' ||
			 'ORDER BY activity_ct DESC) t';

    RAISE NOTICE 'Execute statement: %', execute_statement;			

    FOR rec IN EXECUTE 'SELECT row_to_json(j) FROM (' || execute_statement || ')j' LOOP  		
      RETURN NEXT rec;
    END LOOP;
  ELSE
    FOR rec IN (SELECT row_to_json(j) FROM(select 'Error: Must have at least one valid activity id' as message) j) LOOP RETURN NEXT rec; END LOOP; 
    RETURN;
  END IF;
  
  EXCEPTION WHEN others THEN 
  GET STACKED DIAGNOSTICS error_msg = MESSAGE_TEXT;  
    RAISE NOTICE 'Internal Error - Contact your DBA with the following error message: %', error_msg;
  
END;$$ LANGUAGE plpgsql; 

-- update permissions
GRANT USAGE ON SCHEMA public TO pmt_read;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO pmt_read;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO pmt_read;
GRANT USAGE ON SCHEMA public TO pmt_write;
GRANT SELECT,INSERT ON ALL TABLES IN SCHEMA public TO pmt_write;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO pmt_write;

