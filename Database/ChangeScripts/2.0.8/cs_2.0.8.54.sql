/******************************************************************
Change Script 2.0.8.54 - consolidated.
1. location - adding new fields to support boundary geocoded 
location data.
******************************************************************/
INSERT INTO version(version, iteration, changeset) VALUES (2.0, 8, 54);
-- select * from version order by changeset desc;

-- update location table
ALTER TABLE "location" ADD region character varying;
ALTER TABLE "location" ADD district character varying;
ALTER TABLE "location" ADD ward character varying;
ALTER TABLE "location" ADD village character varying;

-- update permissions
GRANT USAGE ON SCHEMA public TO pmt_read;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO pmt_read;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO pmt_read;
GRANT USAGE ON SCHEMA public TO pmt_write;
GRANT SELECT,INSERT ON ALL TABLES IN SCHEMA public TO pmt_write;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO pmt_write;