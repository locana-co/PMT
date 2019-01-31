/******************************************************************
Change Script 2.0.7.2 - Consolidated.
1. gaul2 - add population fields.
******************************************************************/
INSERT INTO config(version, iteration, changeset) VALUES (2.0, 7, 2);
-- select * from config order by version, iteration, changeset, updated_date;

ALTER TABLE "gaul2" ADD pop_total numeric(500,2);
ALTER TABLE "gaul2" ADD pop_poverty numeric(500,2);
ALTER TABLE "gaul2" ADD pop_rural numeric(500,2);
ALTER TABLE "gaul2" ADD pop_poverty_rural numeric(500,2);

