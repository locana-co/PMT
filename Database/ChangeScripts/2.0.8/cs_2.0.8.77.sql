/******************************************************************
Change Script 2.0.8.77
1. activity - add url to the activity field. 
******************************************************************/
INSERT INTO version(version, iteration, changeset) VALUES (2.0, 8, 77);
-- select * from version order by changeset desc;

ALTER TABLE activity ADD COLUMN url character varying;

-- update permissions
GRANT USAGE ON SCHEMA public TO pmt_read;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO pmt_read;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO pmt_read;
GRANT USAGE ON SCHEMA public TO pmt_write;
GRANT SELECT,INSERT ON ALL TABLES IN SCHEMA public TO pmt_write;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO pmt_write;