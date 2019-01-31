/******************************************************************
Change Script 3.0.10.71
1. update pmt_user_orgs to be aware of instances and include any 
organization in use by the data groups of the instance
******************************************************************/
INSERT INTO version(_version, _iteration, _changeset) VALUES (3.0, 10, 71);
-- select * from version order by _iteration desc, _changeset desc;

/******************************************************************
1. update instance table to inforce organization_id
******************************************************************/ 
ALTER TABLE instance ALTER COLUMN organization_id SET NOT NULL;

/******************************************************************
 1. create pmt_user_orgs function
  SELECT * FROM pmt_user_orgs(1);
  select * from organization where _name like '%Public%'
******************************************************************/
DROP FUNCTION IF EXISTS pmt_user_orgs();
CREATE OR REPLACE FUNCTION pmt_user_orgs(instance_id integer) RETURNS SETOF pmt_json_result_type AS $$
DECLARE 
  instance_record record;
  rec record;
  error_msg text;
BEGIN 
  -- instance_id is required for all operations
  IF ($1 IS NULL) THEN
    FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: instance_id is a required parameter.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
  ELSE
    -- instance_id must be valid
    SELECT INTO instance_record * FROM instance WHERE id = $1;
    IF instance_record IS NULL THEN
      FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: A valid instance_id is a required.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
    END IF;
  END IF;

  FOR rec IN (
	SELECT row_to_json(j) FROM( 
	-- get all organizations in use by instance users
	SELECT DISTINCT o.id, o._name
	FROM (SELECT DISTINCT organization_id FROM users WHERE id IN (SELECT user_id FROM user_instance WHERE user_instance.instance_id = instance_record.id)) u
	JOIN (SELECT id, _name FROM organization WHERE _active = true) o
	ON u.organization_id = o.id
	UNION ALL
	-- get all organizations in use by instance data groups
	SELECT o.id, o._name
	FROM (SELECT DISTINCT organization_id FROM _activity_participants WHERE data_group_id = ANY(instance_record.data_group_ids) AND classification = 'Accountable') a	
	JOIN (SELECT id, _name FROM organization WHERE _active = true) o
	ON a.organization_id = o.id
	UNION ALL
	-- get the instance organization
	SELECT id, _name
	FROM organization WHERE id = instance_record.organization_id
	ORDER BY 2
	) j 
    ) LOOP		
    RETURN NEXT rec;
  END LOOP;	
  
EXCEPTION WHEN others THEN 
  GET STACKED DIAGNOSTICS error_msg = MESSAGE_TEXT;  
    RAISE NOTICE 'Internal Error - Contact your DBA with the following error message: %', error_msg;
    FOR rec IN (SELECT row_to_json(j) FROM( SELECT 'An error occured, please contact the administrator.' AS message ) j ) LOOP		
        RETURN NEXT rec;
    END LOOP;    		 
END; 
$$ LANGUAGE 'plpgsql';

-- update permissions
GRANT USAGE ON SCHEMA public TO pmt_read;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO pmt_read;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO pmt_read;
GRANT USAGE ON SCHEMA public TO pmt_write;
GRANT SELECT,INSERT ON ALL TABLES IN SCHEMA public TO pmt_write;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO pmt_write;