/******************************************************************
Change Script 2.0.9.8
1. project table -  new custom field for "program lead center"
******************************************************************/
INSERT INTO version(version, iteration, changeset) VALUES (2.0, 9, 8);
-- select * from version order by iteration desc, changeset desc;

ALTER TABLE project ADD COLUMN program_lead_center character varying;

-- update permissions
GRANT USAGE ON SCHEMA public TO pmt_read;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO pmt_read;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO pmt_read;
GRANT USAGE ON SCHEMA public TO pmt_write;
GRANT SELECT,INSERT ON ALL TABLES IN SCHEMA public TO pmt_write;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO pmt_write;