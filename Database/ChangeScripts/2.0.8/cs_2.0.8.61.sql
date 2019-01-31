/******************************************************************
Change Script 2.0.8.61
1. pmt_edit_activity_taxonomy- Add user validation for all user auth 
actions and update to allow multiple classification_ids.
******************************************************************/
INSERT INTO version(version, iteration, changeset) VALUES (2.0, 8, 61);
-- select * from version order by changeset desc;

/******************************************************************
   TESTING
   
 57 - reader (read)
 54 - editor (read,create,update)
 55 - super (read,create,update,delete)

 UPDATE "user" SET organization_id = 27 where user_id = 54;
 project_ids: 662,665,661,463,664,663,666
 activity_ids: 13264,13355,13361,13363,12972,12976,12980,12988,12990,12994,12995,12997,12998,12999,13003,13007,13010
 Sub-Initiative taxonomy: 771,773,774,778,779,780,783,784,786,788,791,849,850,851
 Crops and Livestock taxonomy: 1132,1133,1134,1135,1136,1137,1138,1139,1140,1141,1142,1143,1144

-- reader (expected return: false)
select * from pmt_edit_activity_taxonomy(57,'10814','788','add') -- pass
select * from pmt_edit_activity_taxonomy(57,'10814','788','delete') -- pass
select * from pmt_edit_activity_taxonomy(57,'10814','788','replace') -- pass

-- editor (expected return: true)
select * from pmt_edit_activity_taxonomy(54,'13264,13355,13361','774,1137,1138,778,779','add') -- pass
select * from pmt_edit_activity_taxonomy(54,'13355,13361','779','delete') -- pass
select * from pmt_edit_activity_taxonomy(54,'13264,13355,13361','1137,1138','delete') -- pass
select * from pmt_edit_activity_taxonomy(54,'13355,13361','783','add') -- pass

select * from pmt_edit_activity_taxonomy(54,'13355,13361','784','replace'); -- original data
select * from pmt_edit_activity_taxonomy(54,'13264','788','replace'); -- original data

-- super (expected return: true)
select * from pmt_edit_activity_taxonomy(55,'10814','788,784','add') -- pass
select * from pmt_edit_activity_taxonomy(55,'10814','788','delete')  -- pass
select * from pmt_edit_activity_taxonomy(55,'10814','849','add') -- pass
select * from pmt_edit_activity_taxonomy(55,'10814','791','replace') -- original data

select at.activity_id, at.classification_id, tc.taxonomy, tc.classification 
from activity_taxonomy at
join taxonomy_classifications tc
on at.classification_id = tc.classification_id
where at.activity_id in (13264,13355,13361)

select classification_id, classification, taxonomy from taxonomy_classifications where taxonomy  in ('Sub-Initiative','Crops and Livestock') order by taxonomy, classification
select activity_id from activity where active = true and project_id in (463,661,662,663,664,665,666)
select distinct taxonomy from activity_taxonomy at join taxonomy_classifications tc on at.classification_id = tc.classification_id 
******************************************************************/

-- Drop old function (Dont remove old function on databases with active applications)
-- DROP FUNCTION IF EXISTS pmt_edit_activity_taxonomy(character varying, integer, pmt_edit_action)  CASCADE;

-- New Drop Statement for updated function
DROP FUNCTION IF EXISTS pmt_edit_activity_taxonomy(integer, character varying, character varying, pmt_edit_action)  CASCADE;

/******************************************************************
   pmt_edit_activity_taxonomy
******************************************************************/   
CREATE OR REPLACE FUNCTION pmt_edit_activity_taxonomy(user_id integer, activity_ids character varying, classification_id character varying, edit_action pmt_edit_action) RETURNS BOOLEAN AS 
$$
DECLARE
  valid_classification_ids integer[];	-- valid classification_ids from parameter
  valid_activity_ids integer[];    	-- valid activity_ids from parameter
  a_id integer;				-- activity_id
  c_id integer;				-- classification_id
  p_id integer;				-- project_id
  at_id integer;			-- activity_taxonomy activity_id
  tc record;				-- taxonomy_classifications record			-- 
  error_msg1 text;
  error_msg2 text;
  error_msg3 text; 
BEGIN	

  -- first and second parameters are required
  IF ($1 IS NOT NULL) AND ($2 is not null AND $2 <> '') AND ($3 is not null AND $3 <> '') THEN
  
    -- validate activity_ids
    SELECT INTO valid_activity_ids * FROM pmt_validate_activities($2);
    -- validate classification_ids
    SELECT INTO valid_classification_ids * FROM pmt_validate_classifications($3);
    
     -- must provide a min of one valid activity_id to continue
    IF valid_activity_ids IS NULL THEN
      RAISE NOTICE 'Error: Must provide a valid activity_id.';
      RETURN false;
    END IF;
        
    -- must provide a valid classification_id to continue
    IF valid_classification_ids IS NULL THEN
      RAISE NOTICE 'Error: Must provide a valid classification_id.';
      RETURN false;
    END IF;

    -- loop through sets of valid classification_ids by taxonomy
    FOR tc IN EXECUTE 'SELECT taxonomy_id::integer, array_agg(classification_id)::integer[] AS classification_id FROM taxonomy_classifications  tc ' ||
		'WHERE classification_id = ANY(ARRAY['|| array_to_string(valid_classification_ids, ',') || ']) GROUP BY taxonomy_id ORDER BY taxonomy_id ' LOOP     
          
      -- operations based on edit_action
      CASE $4
        WHEN 'delete' THEN
          FOREACH a_id IN ARRAY valid_activity_ids LOOP 
            SELECT INTO p_id project_id from activity where activity_id = a_id;
            -- validate users authority to perform an update action on this activity (use update permission for delete of taxonomy relationships)
            IF (SELECT * FROM pmt_validate_user_authority($1, p_id, 'update')) THEN 
              EXECUTE 'DELETE FROM activity_taxonomy WHERE activity_id ='|| a_id ||' AND classification_id = ANY(ARRAY['|| array_to_string(tc.classification_id, ',') ||']) AND field = ''activity_id'''; 
              RAISE NOTICE 'Delete Record: %', 'Remove association to classification_id(s) ('|| array_to_string(tc.classification_id, ',') ||') for actvity_id ('|| a_id ||')';
            ELSE
              RAISE NOTICE 'Error: The requested edit action requires the user to have UPDATE rights to this project: %', p_id;
	      RETURN FALSE; 
	    END IF; 	   
          END LOOP;
        WHEN 'replace' THEN
          FOREACH a_id IN ARRAY valid_activity_ids LOOP 
            SELECT INTO p_id project_id from activity where activity_id = a_id;
            --validate user authority to perform a create action on this request
            IF (SELECT * FROM pmt_validate_user_authority($1, p_id, 'update')) AND (SELECT * FROM pmt_validate_user_authority($1, p_id, 'create')) THEN
              -- remove all classifications for given taxonomy 
              EXECUTE 'DELETE FROM activity_taxonomy WHERE activity_id ='|| a_id ||' AND classification_id in ' ||
                      '(SELECT classification_id FROM taxonomy_classifications WHERE taxonomy_id = '|| tc.taxonomy_id||') AND field = ''activity_id''';
              RAISE NOTICE 'Delete Record: %', 'Remove association to taxonomy_id ('|| tc.taxonomy_id ||') for actvity_id ('|| a_id ||')';
              -- insert all classification_ids for this taxonomy
	      EXECUTE 'INSERT INTO activity_taxonomy(activity_id, classification_id, field) SELECT '|| a_id ||', classification_id, ''activity_id'' FROM ' ||
		      'classification WHERE classification_id IN (' || array_to_string(tc.classification_id, ',') || ')'; 
              RAISE NOTICE 'Add Record: %', 'Activity_id ('|| a_id ||') is now associated to classification_ids ('|| array_to_string(tc.classification_id, ',') ||').';
            ELSE
              RAISE NOTICE 'Error: The requested edit action requires the user to have UPDATE and CREATE rights to this project: %', p_id;
              RETURN FALSE;
            END IF;  
          END LOOP;
        -- add (DEFAULT)
        ELSE
          FOREACH a_id IN ARRAY valid_activity_ids LOOP 
            SELECT INTO p_id project_id from activity where activity_id = a_id;
            -- validate users authority to perform a create action on this project
            IF (SELECT * FROM pmt_validate_user_authority($1, p_id, 'create')) THEN 
              FOREACH c_id IN ARRAY tc.classification_id LOOP
                -- check to see if this classification is already assoicated to the activity
                SELECT INTO at_id activity_id FROM activity_taxonomy as at WHERE at.activity_id = a_id AND at.classification_id = c_id LIMIT 1;
                IF at_id IS NULL THEN
                  EXECUTE 'INSERT INTO activity_taxonomy(activity_id, classification_id, field) VALUES ('|| a_id ||', '|| c_id ||', ''activity_id'')';
                  RAISE NOTICE 'Add Record: %', 'Activity_id ('|| a_id ||') is now associated to classification_id ('|| c_id ||').'; 
                ELSE
                  RAISE NOTICE'Add Record: %', 'This activity_id ('|| a_id ||') already has an association to this classification_id ('|| c_id ||').';                
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