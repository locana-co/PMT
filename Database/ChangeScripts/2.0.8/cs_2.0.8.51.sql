/******************************************************************
Change Script 2.0.8.51 - consolidated.
1. activity - adding two new fields plan_start_date, plan_end_date
******************************************************************/
INSERT INTO version(version, iteration, changeset) VALUES (2.0, 8, 51);
-- select * from version order by changeset desc;

-- update location table
ALTER TABLE "activity" ADD plan_start_date date;
ALTER TABLE "activity" ADD plan_end_date date;

-- update permissions
GRANT USAGE ON SCHEMA public TO pmt_read;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO pmt_read;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO pmt_read;
GRANT USAGE ON SCHEMA public TO pmt_write;
GRANT SELECT,INSERT ON ALL TABLES IN SCHEMA public TO pmt_write;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO pmt_write;