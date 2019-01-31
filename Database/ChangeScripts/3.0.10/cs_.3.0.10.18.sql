/******************************************************************
Change Script 3.0.10.18

1. Load temporary tables for processing
2. Update the gadm2 table with preprocessed data
3. Drop temporary tables
4. Create new function to get country & region for 2x2
5. Create new function to get 2x2 data for a country/region

Prerequisites:
Load the following files into the data directory:
  1. ../ChangeScripts/3.0.10/WorkingFiles/eth_gadm2_2x2.csv
  2. ../ChangeScripts/3.0.10/WorkingFiles/eth_gadm2_poppov.csv
  3. ../ChangeScripts/3.0.10/WorkingFiles/tza_gadm2_2x2.csv
  4. ../ChangeScripts/3.0.10/WorkingFiles/tza_gadm2_poppov.csv
******************************************************************/
INSERT INTO version(_version, _iteration, _changeset) VALUES (3.0, 10, 18);
-- select * from version order by _iteration desc, _changeset desc;

/**************************************************
 1. Load temporary tables for processing
**************************************************/
DROP TABLE IF EXISTS tmp_eth_poppov;
CREATE TABLE tmp_eth_poppov (
	"id"			integer
	,"pov_sum"		character varying
	,"povsource"		character varying
	,"pop_sum"		character varying
	,"popsource"		character varying
);

COPY tmp_eth_poppov FROM 'eth_gadm2_poppov.csv' DELIMITER ',' CSV HEADER ENCODING 'windows-1251';

-- SELECT * FROM tmp_eth_poppov;

DROP TABLE IF EXISTS tmp_eth_2x2;
CREATE TABLE tmp_eth_2x2 (
	"id"			integer
	,"gadm0_name"		character varying
	,"gadm1_name"		character varying
	,"name"			character varying
	,"integer2x2"		character varying
	,"agpot_prox2mark"	character varying
	,"area"			character varying
	,"areasource"		character varying
);

COPY tmp_eth_2x2 FROM 'eth_gadm2_2x2.csv' DELIMITER ',' CSV HEADER ENCODING 'windows-1251';

-- SELECT * FROM tmp_eth_2x2;

DROP TABLE IF EXISTS tmp_tza_poppov;
CREATE TABLE tmp_tza_poppov (
	"id"			integer
	,"pov_sum"		character varying
	,"povsource"		character varying
	,"pop_sum"		character varying
	,"popsource"		character varying
);

COPY tmp_tza_poppov FROM 'tza_gadm2_poppov.csv' DELIMITER ',' CSV HEADER ENCODING 'windows-1251';

-- SELECT * FROM tmp_tza_poppov;

DROP TABLE IF EXISTS tmp_tza_2x2;
CREATE TABLE tmp_tza_2x2 (
	"id"			integer
	,"gadm0_name"		character varying
	,"gadm1_name"		character varying
	,"name"			character varying
	,"integer2x2"		character varying
	,"agpot_prox2mark"	character varying
	,"area"			character varying
	,"areasource"		character varying
);

COPY tmp_tza_2x2 FROM 'tza_gadm2_2x2.csv' DELIMITER ',' CSV HEADER ENCODING 'windows-1251';

-- SELECT * FROM tmp_tza_2x2;

/**************************************************
 2. Update the gadm2 table with preprocessed data
**************************************************/
-- add new columns for preprocessed data
ALTER TABLE gadm2 ADD COLUMN pop_total numeric;
ALTER TABLE gadm2 ADD COLUMN pop_source character varying;
ALTER TABLE gadm2 ADD COLUMN pov_total numeric;
ALTER TABLE gadm2 ADD COLUMN pov_source character varying;
ALTER TABLE gadm2 ADD COLUMN market_access character varying;
ALTER TABLE gadm2 ADD COLUMN area numeric;
ALTER TABLE gadm2 ADD COLUMN area_source character varying;

-- update gadm2 with population and poverty data
UPDATE gadm2 SET pop_total = pop_sum::numeric, pop_source = popsource, pov_total = pov_sum::numeric, pov_source = povsource, _updated_by = 'cs_.3.0.10.18'
FROM (SELECT gadm2.id, _gadm0_name, _gadm1_name, _name, pov_sum, pop_sum, povsource, popsource
FROM gadm2
JOIN 
(SELECT * FROM tmp_eth_poppov
UNION ALL
SELECT * FROM tmp_tza_poppov) as d
ON gadm2.id = d.id) as u
WHERE gadm2.id = u.id;
-- update gadm2 with ag potential to market access
UPDATE gadm2 SET market_access = agpot_prox2mark, area = u.area::numeric, area_source = areasource, _updated_by = 'cs_.3.0.10.18'
FROM (SELECT gadm2.id, _gadm0_name, _gadm1_name, _name, agpot_prox2mark, d.area, areasource
FROM gadm2
JOIN 
(SELECT * FROM tmp_eth_2x2
UNION ALL
SELECT * FROM tmp_tza_2x2) as d
ON gadm2.id = d.id) as u
WHERE gadm2.id = u.id;
-- if market access is null then assign n/a
UPDATE gadm2 SET market_access = 'n/a' WHERE market_access IS NULL and _gadm0_name IN ('Tanzania', 'Ethiopia');
-- SELECT id, _gadm0_name, _gadm1_name, _name, pov_total, pop_total, pov_source, pop_source, market_access, area, area_source FROM gadm2 WHERE _updated_by = 'cs_.3.0.10.18'
/**************************************************
 3. Drop temporary tables
**************************************************/
DROP TABLE IF EXISTS tmp_eth_poppov;
DROP TABLE IF EXISTS tmp_eth_2x2;
DROP TABLE IF EXISTS tmp_tza_poppov;
DROP TABLE IF EXISTS tmp_tza_2x2;

/**************************************************
 4. Create new function to get country & region for 2x2
 SELECT * FROM pmt_2x2_regions();
**************************************************/
CREATE OR REPLACE FUNCTION pmt_2x2_regions()
RETURNS SETOF pmt_json_result_type AS 
$$
DECLARE
  execute_statement text;
  rec record;
  error_msg text;
BEGIN  
  -- prepare execution statement
  execute_statement := 'SELECT id, _name, ST_AsText(ST_SetSRID(ST_Extent(_polygon),4326)) as extent, ' ||
			'(SELECT array_to_json(array_agg(row_to_json(r))) FROM (SELECT id, _name FROM gadm1 WHERE _gadm0_name = gadm0._name ORDER BY 2 ' ||
			') as r) as regions  ' ||
			'FROM gadm0 ' ||
			'WHERE _name IN (SELECT DISTINCT _gadm0_name FROM gadm2 WHERE area IS NOT NULL) ' ||
			'GROUP BY 1,2 ';

  RAISE NOTICE 'Execute statement: %', execute_statement;
  FOR rec IN EXECUTE 'SELECT row_to_json(j) FROM (' || execute_statement || ')j' LOOP  		
	RETURN NEXT rec;
  END LOOP;

EXCEPTION WHEN others THEN 
  GET STACKED DIAGNOSTICS error_msg = MESSAGE_TEXT;  
    RAISE NOTICE 'Internal Error - Contact your DBA with the following error message: %', error_msg;

END;$$ LANGUAGE plpgsql;

/**************************************************
 5. Create new function to get 2x2 data for a country/region
 SELECT * FROM pmt_2x2('Ethiopia', 'Oromia');
**************************************************/
CREATE OR REPLACE FUNCTION pmt_2x2(country character varying, region character varying)
RETURNS SETOF pmt_json_result_type AS 
$$
DECLARE
  execute_statement text;
  valid_country text;
  valid_region text;
  rec record;
  error_msg text;
BEGIN
  -- validate country name for 2x2 from gadm2
  IF $1 IS NULL OR $1 = '' THEN
    FOR rec IN SELECT row_to_json(j) FROM( SELECT 'Must provide valid country parameter.' AS error ) as j LOOP RETURN NEXT rec; END LOOP;
  ELSE    
    SELECT INTO valid_country _gadm0_name FROM gadm2 WHERE lower(_gadm0_name) = lower($1);
    IF valid_country IS NULL THEN
      FOR rec IN SELECT row_to_json(j) FROM( SELECT 'Must provide valid country parameter.' AS error ) as j LOOP RETURN NEXT rec; END LOOP;
    END IF;
  END IF;  
  -- validate region name for 2x2 from gadm2
  IF $2 IS NULL OR $2 = '' THEN
    FOR rec IN SELECT row_to_json(j) FROM( SELECT 'Must provide valid region parameter for provided country.' AS error ) as j LOOP RETURN NEXT rec; END LOOP;
  ELSE    
    SELECT INTO valid_region _gadm1_name FROM gadm2 WHERE lower(_gadm1_name) = lower($2) AND _gadm0_name = valid_country;
    IF valid_region IS NULL THEN
      FOR rec IN SELECT row_to_json(j) FROM( SELECT 'Must provide valid region parameter for provided country.' AS error ) as j LOOP RETURN NEXT rec; END LOOP;
    END IF;
  END IF;       
  -- prepare execution statement
  execute_statement := 'SELECT categories.order, ' ||
			'label as category, ' || 
			'array_to_string(array_agg(district),'', '') as districts,  ' ||
			'(CASE WHEN sum(area) > 0 THEN sum(area) ELSE 0 END) as area, ' ||
			'(CASE WHEN sum(pop_total) > 0 THEN sum(pop_total) ELSE 0 END) as pop, ' ||
			'(CASE WHEN sum(pop_total)/sum(area) > 0 THEN sum(pop_total)/sum(area) ELSE 0 END) as popden, ' ||
			'(CASE WHEN sum(pov_total)/sum(area) > 0 THEN sum(pov_total)/sum(area) ELSE 0 END) as povden ' ||
			'FROM  ' ||
			'(SELECT ''Low-Low'' as label, ''lo-lo'' as data, 0 as order ' ||
			'UNION ALL ' ||
			'SELECT ''Low-Hi'' as label, ''lo-hi'' as data, 1 as order ' ||
			'UNION ALL ' ||
			'SELECT ''Hi-Low'' as label, ''hi-lo'' as data, 2 as order ' ||
			'UNION ALL ' ||
			'SELECT ''Hi-Hi'' as label, ''hi-hi'' as data, 3 as order ' ||
			'UNION ALL ' ||
			'SELECT ''n/a'' as label, ''n/a'' as data, 4 as order) as categories ' ||
			'LEFT JOIN  ' ||
			'(SELECT market_access, _name as district, area, pop_total, pov_total ' ||
			'FROM gadm2  ' ||
			'WHERE _gadm0_name = ' || quote_literal(valid_country) || ' AND _gadm1_name = ' || quote_literal(valid_region) || ') as d ' ||
			'ON categories.data = d.market_access ' ||
			'GROUP BY 1,2 ' ||
			'ORDER BY categories.order';

  RAISE NOTICE 'Execute statement: %', execute_statement;
  FOR rec IN EXECUTE 'SELECT row_to_json(j) FROM (' || execute_statement || ')j' LOOP  		
	RETURN NEXT rec;
  END LOOP;
  
EXCEPTION WHEN others THEN 
  GET STACKED DIAGNOSTICS error_msg = MESSAGE_TEXT;  
    RAISE NOTICE 'Internal Error - Contact your DBA with the following error message: %', error_msg;

END;$$ LANGUAGE plpgsql;

-- update permissions
GRANT USAGE ON SCHEMA public TO pmt_read;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO pmt_read;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO pmt_read;
GRANT USAGE ON SCHEMA public TO pmt_write;
GRANT SELECT,INSERT ON ALL TABLES IN SCHEMA public TO pmt_write;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO pmt_write;