/******************************************************************
Change Script 2.0.7.15 - Consolidated.
1. pmt_stat_pop_by_district - new function for population statistics
by region/district.
******************************************************************/
INSERT INTO config(version, iteration, changeset) VALUES (2.0, 7, 15);
-- select * from config order by version, iteration, changeset, updated_date;

DROP FUNCTION IF EXISTS pmt_stat_pop_by_district(character varying)  CASCADE;
DROP TYPE IF EXISTS pmt_stat_pop_by_district_result CASCADE;
CREATE TYPE pmt_stat_pop_by_district_result AS (response json);

-- select * from pmt_stat_pop_by_district('morogoro');
/******************************************************************
  pmt_stat_pop_by_district
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_stat_pop_by_district(region character varying)
RETURNS SETOF pmt_stat_pop_by_district_result AS 
$$
DECLARE
  valid_data_group_id integer;
  execute_statement text;
  rec record;
BEGIN
-- regionName is required
IF $1 IS NOT NULL AND $1 <> '' THEN
   
   execute_statement :=  'select row_to_json(j) from (select gaul1_name as region, name as district, pop_total, pop_poverty, pop_rural, pop_poverty_rural, pop_source ' ||
				'from gaul2 ' ||
				'where lower(gaul1_name) = trim(lower('|| quote_literal($1) ||')) order by name) j';

   RAISE NOTICE 'Execute statement: %', execute_statement;
   FOR rec IN EXECUTE execute_statement LOOP
     RETURN NEXT rec; 
   END LOOP;   
END IF;   
END;$$ LANGUAGE plpgsql;

-- update permissions
GRANT USAGE ON SCHEMA public TO pmt_read;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO pmt_read;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO pmt_read;
GRANT USAGE ON SCHEMA public TO pmt_write;
GRANT SELECT,INSERT ON ALL TABLES IN SCHEMA public TO pmt_write;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO pmt_write;