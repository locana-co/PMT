/******************************************************************
Change Script 2.0.7.14 - Consolidated.
1. gaul2 - adding new column pop_source to track source of pop data
******************************************************************/
INSERT INTO config(version, iteration, changeset) VALUES (2.0, 7, 14);
-- select * from config order by version, iteration, changeset, updated_date;

ALTER TABLE "gaul2" ADD pop_source text;

-- update permissions
GRANT USAGE ON SCHEMA public TO pmt_read;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO pmt_read;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO pmt_read;
GRANT USAGE ON SCHEMA public TO pmt_write;
GRANT SELECT,INSERT ON ALL TABLES IN SCHEMA public TO pmt_write;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO pmt_write;