/******************************************************************
Change Script 2.0.7.8 - Consolidated.
1. map - add new field of type json.
******************************************************************/
INSERT INTO config(version, iteration, changeset) VALUES (2.0, 7, 8);
-- select * from config order by version, iteration, changeset, updated_date;

ALTER TABLE map ADD COLUMN filters json; 

-- update permissions
GRANT USAGE ON SCHEMA public TO pmt_read;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO pmt_read;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO pmt_read;
GRANT USAGE ON SCHEMA public TO pmt_write;
GRANT SELECT,INSERT ON ALL TABLES IN SCHEMA public TO pmt_write;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO pmt_write;