/******************************************************************
Change Script 2.0.8.74
1. activity - new custom fields for CRP.
******************************************************************/
INSERT INTO version(version, iteration, changeset) VALUES (2.0, 8, 74);
-- select * from version order by changeset desc;

-- update activity table
ALTER TABLE "activity" ADD code character varying;
ALTER TABLE "activity" ADD notes character varying;

-- update permissions
GRANT USAGE ON SCHEMA public TO pmt_read;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO pmt_read;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO pmt_read;
GRANT USAGE ON SCHEMA public TO pmt_write;
GRANT SELECT,INSERT ON ALL TABLES IN SCHEMA public TO pmt_write;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO pmt_write;