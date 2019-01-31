/******************************************************************
Change Script 2.0.8.9 - consolidated.
1. pmt_edit_activity - new function for editing an activity.
******************************************************************/
INSERT INTO version(version, iteration, changeset) VALUES (2.0, 8, 9);
-- select * from version order by changeset desc;

DROP FUNCTION IF EXISTS pmt_edit_activity(integer, integer, json)  CASCADE;

-- SELECT * FROM pmt_validate_user_authority(34, 733) -- bmgf
-- SELECT * FROM pmt_validate_user_authority(1, 1) -- oam
-- select * from activity where project_id = 733
-- select * from activity where project_id = 3
-- select * from "user"

-- select * from pmt_edit_activity(34,14863,'{"title": "x - Project Objective 1", "description":"x - Market opportunities, Policies and Partnerships", "start_date":"9-2-2012", "opportunity_id": "null", "active" : "false"}');
-- select * from pmt_edit_activity(34,14863,'{"title": "Project Objective 1", "description":"Market opportunities, Policies and Partnerships", "start_date":"9-2-2011", "opportunity_id": "OPP1005131"}');
-- select * from pmt_edit_activity(1,14863,'{"title": "Project Objective 1", "description":"Market opportunities, Policies and Partnerships", "start_date":"9-2-2011", "opportunity_id": "OPP1005131"}');
-- select * from pmt_edit_activity(1,1,'{"title": "GUARANTEE FACILITY MAGHREB LEASING ALGERIE"}');
-- select * from pmt_edit_activity(1,11291,'{"title": "Digital Radio Equipment"}');
/******************************************************************
   pmt_edit_activity
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_edit_activity(user_id integer, activity_id integer, key_value_data json) RETURNS BOOLEAN AS 
$$
DECLARE
  p_id integer;
  json record;
  column_record record;
  execute_statement text;
  invalid_editing_columns text[];
  user_name text;
BEGIN	
  -- set columns that are not editable via the parameters 
  invalid_editing_columns := ARRAY['activity_id','project_id', 'active', 'retired_by', 'created_by', 'created_date', 'updated_by', 'updated_date'];
  
  -- ALL parameters are required (next versions will allow null activity_id as new activity and have a flag for deletion
  -- for now all authorization types = update)
  IF ($1 IS NOT NULL) AND ($2 IS NOT NULL) AND ($3 IS NOT NULL) THEN
    -- validate activity_id
    IF (SELECT * FROM pmt_validate_activity($2)) THEN
      -- get project_id for activity
      SELECT INTO p_id project_id FROM activity WHERE activity.activity_id = $2;
      -- validate users authority to 'update' this project
      IF (SELECT * FROM pmt_validate_user_authority($1, p_id, 'update')) THEN
        -- we have a authorized user and a valid activity lets edit...
        
        -- loop through the columns of the activity table        
        FOR json IN (SELECT * FROM json_each_text($3)) LOOP
          RAISE NOTICE 'JSON key/value: %', json.key || ':' || json.value;
          -- SELECT * FROM information_schema.columns WHERE table_schema='public' AND table_name='activity' AND column_name != ALL(ARRAY['activity_id','project_id', 'active', 'retired_by', 'created_by', 'created_date', 'updated_by', 'updated_date']) AND column_name = 'title';

	  -- get the column information for column that user is requesting to edit	
          FOR column_record IN (SELECT * FROM information_schema.columns WHERE table_schema='public' AND table_name='activity' AND column_name != ALL(invalid_editing_columns) AND column_name = json.key) LOOP 
            --IF column_record IS NOT NULL THEN
              RAISE NOTICE 'Editing column: %', column_record.column_name;
              RAISE NOTICE 'Assigning new value: %', json.value;
              execute_statement := null;
              CASE column_record.data_type 
                WHEN 'integer', 'numeric' THEN              
                 IF (SELECT pmt_isnumeric(json.value)) THEN
                   execute_statement := 'UPDATE activity SET ' || column_record.column_name || ' = ' || json.value || ' WHERE activity_id = ' || $2; 
                 END IF;
                ELSE
                  -- if the value has the text null then assign the column value null
                  IF (lower(json.value) = 'null') THEN
                    execute_statement := 'UPDATE activity SET ' || column_record.column_name || ' = null WHERE activity_id = ' || $2; 
                  ELSE
                    execute_statement := 'UPDATE activity SET ' || column_record.column_name || ' = ' || quote_literal(json.value) || ' WHERE activity_id = ' || $2; 
                  END IF;
              END CASE;
              IF execute_statement IS NOT NULL THEN
                RAISE NOTICE 'Statement: %', execute_statement;
                EXECUTE execute_statement;
                SELECT INTO user_name username FROM "user" WHERE "user".user_id = $1;
                EXECUTE 'UPDATE activity SET updated_by = ' || quote_literal(user_name) || ', updated_date = ' || quote_literal(current_date) || ' WHERE  activity_id = ' || $2;
              END IF;
          END LOOP;
        END LOOP;
        RETURN TRUE;     
      ELSE
        RAISE NOTICE 'Error: User does NOT have authority to edit this project.';
	RETURN FALSE;
      END IF;      
    ELSE
      RAISE NOTICE 'Error: Invalid activity_id.';
      RETURN FALSE;
    END IF;
  ELSE
    RAISE NOTICE 'Error: Must provide all parameters.';
    RETURN false;
  END IF; 
  
EXCEPTION WHEN others THEN
    RETURN FALSE;  	  
END;$$ LANGUAGE plpgsql;

-- update permissions
GRANT USAGE ON SCHEMA public TO pmt_read;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO pmt_read;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO pmt_read;
GRANT USAGE ON SCHEMA public TO pmt_write;
GRANT SELECT,INSERT ON ALL TABLES IN SCHEMA public TO pmt_write;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO pmt_write;