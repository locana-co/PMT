/******************************************************************
Change Script 3.0.10.75
1. Create function pmt_validate_username to check if username is
unique
******************************************************************/
INSERT INTO version(_version, _iteration, _changeset) VALUES (3.0, 10, 75);
-- select * from version order by _iteration desc, _changeset desc;

/******************************************************************
1. Create function pmt_validate_username to check if username is
unique
  select * from pmt_validate_username('sparadee');
  select * from pmt_validate_username('junebug');
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_validate_username(username character varying) RETURNS boolean AS
$$
DECLARE
  username_inuse text;
  error_msg text;
BEGIN

  IF $1 IS NOT NULL THEN
    SELECT INTO username_inuse _username FROM users WHERE _username = $1;
    IF username_inuse IS NULL THEN
      RETURN true;
    ELSE
      RETURN false;
    END IF;
  ELSE
    RAISE NOTICE 'Required username parameter was null.';
    RETURN false;
  END IF;
 
EXCEPTION WHEN others THEN 
  GET STACKED DIAGNOSTICS error_msg = MESSAGE_TEXT;  
    RAISE NOTICE 'Internal Error - Contact your DBA with the following error message: %', error_msg;
    RETURN false;
    
END;$$ LANGUAGE plpgsql;
  
-- update permissions
GRANT USAGE ON SCHEMA public TO pmt_read;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO pmt_read;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO pmt_read;
GRANT USAGE ON SCHEMA public TO pmt_write;
GRANT SELECT,INSERT ON ALL TABLES IN SCHEMA public TO pmt_write;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO pmt_write;