/******************************************************************
Change Script 3.0.10.0

1. add new custom activity field (remarks)
******************************************************************/
INSERT INTO version(_version, _iteration, _changeset) VALUES (3.0, 10, 0);
-- select * from version order by _iteration desc, _changeset desc;

-- new parent_activity_id field for linking activities
ALTER TABLE activity ADD COLUMN remarks character varying;

-- update permissions
GRANT USAGE ON SCHEMA public TO pmt_read;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO pmt_read;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO pmt_read;
GRANT USAGE ON SCHEMA public TO pmt_write;
GRANT SELECT,INSERT ON ALL TABLES IN SCHEMA public TO pmt_write;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO pmt_write;