/******************************************************************
Change Script 2.0.8.62
1.pmt_edit_project_taxonomy - updating to allow multiple project_ids,
and multiple classification_ids.
******************************************************************/
INSERT INTO version(version, iteration, changeset) VALUES (2.0, 8, 62);
-- select * from version order by changeset desc;

/******************************************************************
   TESTING
   
 57 - reader (read)
 54 - editor (read,create,update)
 55 - super (read,create,update,delete)
 

 UPDATE "user" SET organization_id = 27 where user_id = 54;
 project_ids: 662,665,661,463,664,663,666
 Initiative taxonomy: 824,825,829,831,852
 Focus Crop: 816,817,819,820,821,822,823,853,854

-- reader (expected return: false) 
select * from pmt_edit_project_taxonomy(57,'463,664,663','824','add') -- pass
select * from pmt_edit_project_taxonomy(57,'463,664,663','824','delete') -- pass
select * from pmt_edit_project_taxonomy(57,'463,664,663','852','replace') -- pass

-- editor (expected return: true)
select * from pmt_edit_project_taxonomy(54,'662,665,661,463','829,831,819,820','add') -- pass
select * from pmt_edit_project_taxonomy(54,'662,665,661','819,'820','delete') -- pass
select * from pmt_edit_project_taxonomy(54,'662,665,661,463','829','delete') -- pass
select * from pmt_edit_project_taxonomy(54,'662,665,661,463','831','add') -- pass
select * from pmt_edit_project_taxonomy(54,'662,665,661,463','831','delete') -- pass

-- super (expected return: true)
select * from pmt_edit_project_taxonomy(55,'662,665,661,463','829,831,819,820','add') -- pass
select * from pmt_edit_project_taxonomy(55,'662,665,661','819,820','delete') -- pass
select * from pmt_edit_project_taxonomy(55,'662,665,661,463','829','delete') -- pass
select * from pmt_edit_project_taxonomy(55,'662,665,661,463','831','add') -- pass
select * from pmt_edit_project_taxonomy(55,'662,665,661,463',831,'delete') -- pass

select * from pmt_edit_project_taxonomy(55,'665,463','831','replace'); -- original data
select * from pmt_edit_project_taxonomy(55,'662','825','replace'); -- original data
select * from pmt_edit_project_taxonomy(55,'661','824','replace'); -- original data
select * from pmt_edit_project_taxonomy(55,'463','816,820,819,821,854','replace'); -- original data

select * from pmt_edit_project_taxonomy(null,'662,665,661,463','831','delete') -- pass (false)
select * from pmt_edit_project_taxonomy(55,null,'831','delete') -- pass (false)
select * from pmt_edit_project_taxonomy(55,'662,665,661,463',null, null) -- pass (false)
select * from pmt_edit_project_taxonomy(55,'662,665,661,463','9999', 'add') -- pass (false)

select pt.project_id, pt.classification_id, tc.taxonomy, tc.classification 
from project_taxonomy pt
join taxonomy_classifications tc
on pt.classification_id = tc.classification_id
where pt.project_id in (662,665,661,463) and tc.taxonomy in ('Initiative','Focus Crop')
order by project_id, taxonomy, pt.classification_id

******************************************************************/

-- Drop old function (Don't run on databases with active applications)
-- DROP FUNCTION IF EXISTS pmt_edit_project_taxonomy(integer, integer, integer, pmt_edit_action)  CASCADE;

-- New Drop Statement for updated function
DROP FUNCTION IF EXISTS pmt_edit_project_taxonomy(integer,character varying, character varying, pmt_edit_action)  CASCADE;

/******************************************************************
   pmt_edit_project_taxonomy
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_edit_project_taxonomy(user_id integer, project_ids character varying, classification_ids character varying, edit_action pmt_edit_action) RETURNS BOOLEAN AS 
$$
DECLARE
  valid_classification_ids integer[];	-- valid classification_ids from parameter
  valid_project_ids integer[];    	-- valid project_ids from parameter
  c_id integer;				-- classification_id
  p_id integer;				-- project_id
  pt_id integer;			-- project_taxonomy project_id
  tc record;				-- taxonomy_classifications record			-- 
  error_msg1 text;
  error_msg2 text;
  error_msg3 text; 
BEGIN	

  -- first three parameters are required 
  IF ($1 IS NOT NULL) AND ($2 is not null AND $2 <> '') AND ($3 is not null AND $3 <> '') THEN

    -- validate project_ids
    SELECT INTO valid_project_ids * FROM pmt_validate_projects($2);
    -- validate classification_ids
    SELECT INTO valid_classification_ids * FROM pmt_validate_classifications($3);      
     
    -- must provide a min of one valid project_id to continue
    IF valid_project_ids IS NULL THEN
      RAISE NOTICE 'Error: Must provide a valid project_id.';
      RETURN false;
    END IF; 
    
    -- must provide a min of one valid classification_id to continue
    IF valid_classification_ids IS NULL THEN
      RAISE NOTICE 'Error: Must provide a valid classification_id.';
      RETURN false;
    END IF; 

    -- loop through sets of valid classification_ids by taxonomy
    FOR tc IN EXECUTE 'SELECT taxonomy_id::integer, array_agg(classification_id)::integer[] AS classification_id FROM taxonomy_classifications  tc ' ||
		'WHERE classification_id = ANY(ARRAY['|| array_to_string(valid_classification_ids, ',') || ']) GROUP BY taxonomy_id ORDER BY taxonomy_id ' LOOP
		
      -- operations based on the requested edit action
      CASE $4          
        WHEN 'delete' THEN
         FOREACH p_id IN ARRAY valid_project_ids LOOP
          -- validate users authority to perform an update action on this project (use update permission for delete of taxonomy relationships)
          IF (SELECT * FROM pmt_validate_user_authority($1, p_id, 'update')) THEN               
            EXECUTE 'DELETE FROM project_taxonomy WHERE project_id ='|| p_id ||' AND classification_id = ANY(ARRAY['|| array_to_string(tc.classification_id, ',') ||']) AND field = ''project_id'''; 
            RAISE NOTICE 'Delete Record: %', 'Remove association to classification_id(s) ('|| array_to_string(tc.classification_id, ',') ||') for project_id ('|| p_id ||')';
          ELSE
            RAISE NOTICE 'Error: The requested edit action requires the user to have UPDATE rights to this project: %', p_id;
	    RETURN FALSE;
          END IF; 
        END LOOP;     
        WHEN 'replace' THEN
          FOREACH p_id IN ARRAY valid_project_ids LOOP
            -- validate users authority to perform an update and create action on this project
            IF (SELECT * FROM pmt_validate_user_authority($1, p_id, 'update')) AND (SELECT * FROM pmt_validate_user_authority($1, p_id, 'create')) THEN
              -- remove all classifications for given taxonomy 
              EXECUTE 'DELETE FROM project_taxonomy WHERE project_id ='|| p_id ||' AND classification_id in ' ||
		      '(SELECT classification_id FROM taxonomy_classifications WHERE taxonomy_id = '|| tc.taxonomy_id||') AND field = ''project_id''';
              RAISE NOTICE 'Delete Record: %', 'Remove association to taxonomy_id ('|| tc.taxonomy_id ||') for project_id ('|| p_id ||')';
	      -- insert all classification_ids for this taxonomy
	      EXECUTE 'INSERT INTO project_taxonomy(project_id, classification_id, field) SELECT '|| p_id ||', classification_id, ''project_id'' FROM ' ||
		      'classification WHERE classification_id IN (' || array_to_string(tc.classification_id, ',') || ')'; 
              RAISE NOTICE 'Add Record: %', 'project_id ('|| p_id ||') is now associated to classification_ids ('|| array_to_string(tc.classification_id, ',') ||').';
            ELSE
              RAISE NOTICE 'Error: The requested edit action requires the user to have UPDATE and CREATE rights to this project: %', p_id;
	      RETURN FALSE;
            END IF; 
          END LOOP;  
        ELSE
          FOREACH p_id IN ARRAY valid_project_ids LOOP
          -- validate users authority to perform a create action on this project
            IF (SELECT * FROM pmt_validate_user_authority($1, p_id, 'create')) THEN 
              FOREACH c_id IN ARRAY tc.classification_id LOOP
		-- check to see if this classification is already assoicated to the project
                SELECT INTO pt_id pt.project_id FROM project_taxonomy as pt WHERE pt.project_id = p_id AND pt.classification_id = c_id LIMIT 1;
                -- if no assoication, then add
                IF pt_id IS NULL THEN
                  EXECUTE 'INSERT INTO project_taxonomy(project_id, classification_id, field) VALUES ('|| p_id ||', '|| c_id ||', ''project_id'')';
                  RAISE NOTICE 'Add Record: %', 'project_id ('|| p_id ||') is now associated to classification_id ('|| c_id ||').'; 
                ELSE
                  RAISE NOTICE'Add Record: %', 'This project_id ('|| p_id ||') already has an association to this classification_id ('|| c_id ||').';                
                END IF;             
              END LOOP;
            ELSE
              RAISE NOTICE 'Error: The requested edit action requires the user to have CREATE rights to this project: %', p_id;
	      RETURN FALSE;
            END IF;
          END LOOP;         
        END CASE;
    END LOOP;
    -- return successful execution
    RETURN true;
  -- first three parameters are required 
  ELSE
   RAISE NOTICE 'Error: Must provide user_id, project_ids and classification_ids parameters.';
    RETURN false;
  END IF; 
  
  EXCEPTION WHEN others THEN
   GET STACKED DIAGNOSTICS error_msg1 = MESSAGE_TEXT,
		  error_msg2 = PG_EXCEPTION_DETAIL,
		  error_msg3 = PG_EXCEPTION_HINT;
                          
  RAISE NOTICE 'Error: %', error_msg1;                          
  RETURN FALSE; 
END;$$ LANGUAGE plpgsql;


-- update permissions
GRANT USAGE ON SCHEMA public TO pmt_read;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO pmt_read;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO pmt_read;
GRANT USAGE ON SCHEMA public TO pmt_write;
GRANT SELECT,INSERT ON ALL TABLES IN SCHEMA public TO pmt_write;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO pmt_write;