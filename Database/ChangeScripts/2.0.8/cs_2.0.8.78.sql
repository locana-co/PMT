/******************************************************************
Change Script 2.0.8.78
1. refresh_partnerlink_sankey - new function to refresh the 
partner link sankey views. 
******************************************************************/
INSERT INTO version(version, iteration, changeset) VALUES (2.0, 8, 78);
-- select * from version order by changeset desc;

-- function to support the partnerlink_sankey views
CREATE OR REPLACE FUNCTION refresh_partnerlink_sankey() RETURNS integer AS $$
BEGIN
    RAISE NOTICE 'Refreshing partnerlink_sankey views...';
    REFRESH MATERIALIZED VIEW partnerlink_sankey_links;
    REFRESH MATERIALIZED VIEW partnerlink_sankey_nodes;     
    RAISE NOTICE 'Done partnerlink_sankey views.';
    RETURN 1;
END;
$$ LANGUAGE plpgsql;

SELECT refresh_partnerlink_sankey();

-- update permissions
GRANT USAGE ON SCHEMA public TO pmt_read;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO pmt_read;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO pmt_read;
GRANT USAGE ON SCHEMA public TO pmt_write;
GRANT SELECT,INSERT ON ALL TABLES IN SCHEMA public TO pmt_write;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO pmt_write;