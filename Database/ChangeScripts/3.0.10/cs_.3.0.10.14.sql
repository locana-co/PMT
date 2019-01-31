/******************************************************************
Change Script 3.0.10.14

1. load world bank Africa Development Indicator (ADI) metadata data 
into a temporary table (tmp_adi_series)
2. load world bank Africa Development Indicator (ADI) data into a 
temporary table (tmp_adi_data)
3. load world bank Poverty & Equity Database metadata data into a 
temporary table (tmp_pov_series)
4. load world bank Poverty & Equity Database data into a temporary 
table (tmp_pov_data)
5. load world bank World Development Indicators (WDI) metadata data 
into a temporary table (tmp_wdi_series)
6. load world bankWorld Development Indicators (WDI) data into a 
temporary table (tmp_wdi_data)
7. create a new table in the data model to store statistical metadata
8. create a new table in the data model to store statistical data
9. create pmt_statistic_indicators to return available statistics
10. create pmt_statistic_data to return statistics for one or more
11. drop all temporary tables
******************************************************************/
INSERT INTO version(_version, _iteration, _changeset) VALUES (3.0, 10, 14);
-- select * from version order by _iteration desc, _changeset desc;

/**************************************************
 1. load world bank Africa Development Indicator (ADI)
 metadata data into a temporary table (tmp_adi_series)
**************************************************/
DROP TABLE IF EXISTS tmp_adi_series;
CREATE TABLE tmp_adi_series (
	"SeriesCode"           		character varying, 
	"Indicator Name"           	character varying, 
	"Short definition"           	character varying, 
	"Long definition"           	character varying, 
	"Source"           		character varying, 
	"Topic"           		character varying, 
	"Periodicity"           	character varying, 
	"Base Period"           	character varying, 
	"Aggregation method"           	character varying, 
	"Limitations and exceptions"    character varying, 
	"General comments"		character varying

);

COPY tmp_adi_series FROM 'ADI_Series.csv' DELIMITER ',' CSV HEADER ENCODING 'windows-1251';

ALTER TABLE tmp_adi_series ADD COLUMN id SERIAL;

ALTER TABLE tmp_adi_series ADD PRIMARY KEY (id);

-- SELECT * FROM tmp_adi_series;

/**************************************************
 2. load world bank Africa Development Indicator (ADI)
 data into a temporary table (tmp_adi_data)
**************************************************/
DROP TABLE IF EXISTS tmp_adi_data;
CREATE TABLE tmp_adi_data (
	"Country_Name_attr"	character varying,
	"Country__attrCode"	character varying,
	"Indicator_Name"	character varying,
	"Indicator_Code"	character varying,
	"1960"			character varying,
	"1961"			character varying,
	"1962"			character varying,
	"1963"			character varying,
	"1964"			character varying,
	"1965"			character varying,
	"1966"			character varying,
	"1967"			character varying,
	"1968"			character varying,
	"1969"			character varying,
	"1970"			character varying,
	"1971"			character varying,
	"1972"			character varying,
	"1973"			character varying,
	"1974"			character varying,
	"1975"			character varying,
	"1976"			character varying,
	"1977"			character varying,
	"1978"			character varying,
	"1979"			character varying,
	"1980"			character varying,
	"1981"			character varying,
	"1982"			character varying,
	"1983"			character varying,
	"1984"			character varying,
	"1985"			character varying,
	"1986"			character varying,	
	"1987"			character varying,
	"1988"			character varying,
	"1989"			character varying,
	"1990"			character varying,
	"1991"			character varying,
	"1992"			character varying,
	"1993"			character varying,
	"1994"			character varying,
	"1995"			character varying,
	"1996"			character varying,
	"1997"			character varying,
	"1998"			character varying,
	"1999"			character varying,
	"2000"			character varying,
	"2001"			character varying,
	"2002"			character varying,
	"2003"			character varying,
	"2004"			character varying,
	"2005"			character varying,
	"2006"			character varying,
	"2007"			character varying,
	"2008"			character varying,
	"2009"			character varying,
	"2010"			character varying,
	"2011"			character varying,
	"2012"           	character varying

);

COPY tmp_adi_data FROM 'ADI_Data.csv' DELIMITER ',' CSV HEADER ENCODING 'windows-1251';

ALTER TABLE tmp_adi_data ADD COLUMN id SERIAL;

ALTER TABLE tmp_adi_data ADD PRIMARY KEY (id);

-- SELECT * FROM tmp_adi_data LIMIT 100;

/**************************************************
 3. load world bank Poverty & Equity Database
 metadata data into a temporary table (tmp_pov_series)
**************************************************/
DROP TABLE IF EXISTS tmp_pov_series;
CREATE TABLE tmp_pov_series (
	"Series Code"			character varying,
	"Topic"				character varying,
	"Indicator Name"		character varying,
	"Short definition"		character varying,
	"Long definition"		character varying,
	"Unit of measure"		character varying,
	"Periodicity"			character varying,
	"Base Period"			character varying,
	"Other notes"			character varying,
	"Aggregation method"		character varying,
	"Limitations and exceptions"	character varying,
	"Notes from original source"	character varying,
	"General comments"		character varying,
	"Source"			character varying,
	"Statistical_methodology"	character varying,
	"Development relevance"		character varying,
	"Related source links"		character varying,
	"Other web links"		character varying,
	"Related indicators"		character varying,
	"License Type"			character varying
);

COPY tmp_pov_series FROM 'PovStats_Series.csv' DELIMITER ',' CSV HEADER ENCODING 'windows-1251';

ALTER TABLE tmp_pov_series ADD COLUMN id SERIAL;

ALTER TABLE tmp_pov_series ADD PRIMARY KEY (id);

-- SELECT * FROM tmp_pov_series;

/**************************************************
 4. load world bank Poverty & Equity Database
 data into a temporary table (tmp_pov_data)
**************************************************/
DROP TABLE IF EXISTS tmp_pov_data;
CREATE TABLE tmp_pov_data (
	"Country Name"		character varying,
	"Country Code"		character varying,
	"Indicator Name"	character varying,
	"Indicator Code"	character varying,
	"1974"			character varying,
	"1975"			character varying,
	"1976"			character varying,
	"1977"			character varying,
	"1978"			character varying,
	"1979"			character varying,
	"1980"			character varying,
	"1981"			character varying,
	"1982"			character varying,
	"1983"			character varying,
	"1984"			character varying,
	"1985"			character varying,
	"1986"			character varying,	
	"1987"			character varying,
	"1988"			character varying,
	"1989"			character varying,
	"1990"			character varying,
	"1991"			character varying,
	"1992"			character varying,
	"1993"			character varying,
	"1994"			character varying,
	"1995"			character varying,
	"1996"			character varying,
	"1997"			character varying,
	"1998"			character varying,
	"1999"			character varying,
	"2000"			character varying,
	"2001"			character varying,
	"2002"			character varying,
	"2003"			character varying,
	"2004"			character varying,
	"2005"			character varying,
	"2006"			character varying,
	"2007"			character varying,
	"2008"			character varying,
	"2009"			character varying,
	"2010"			character varying,
	"2011"			character varying,
	"2012"           	character varying,
	"2013"			character varying,
	"2014"			character varying

);

COPY tmp_pov_data FROM 'PovStats_Data.csv' DELIMITER ',' CSV HEADER ENCODING 'windows-1251';

ALTER TABLE tmp_pov_data ADD COLUMN id SERIAL;

ALTER TABLE tmp_pov_data ADD PRIMARY KEY (id);

-- SELECT * FROM tmp_pov_data;

/**************************************************
 5. load world bank World Development Indicators (WDI)
 metadata data into a temporary table (tmp_wdi_series)
**************************************************/
DROP TABLE IF EXISTS tmp_wdi_series;
CREATE TABLE tmp_wdi_series (
	"Series Code"			character varying,
	"Topic"				character varying,
	"Indicator Name"		character varying,
	"Short definition"		character varying,
	"Long definition"		character varying,
	"Unit of measure"		character varying,
	"Periodicity"			character varying,
	"Base Period"			character varying,
	"Other notes"			character varying,
	"Aggregation method"		character varying,
	"Limitations and exceptions"	character varying,
	"Notes from original source"	character varying,
	"General comments"		character varying,
	"Source"			character varying,
	"Statistical concept and methodology"		character varying,
	"Development relevance"		character varying,
	"Related source links"		character varying,
	"Other web links"		character varying,
	"Related indicators"		character varying,
	"License Type"			character varying
);

COPY tmp_wdi_series FROM 'WDI_Series.csv' DELIMITER ',' CSV HEADER ENCODING 'windows-1251';

ALTER TABLE tmp_wdi_series ADD COLUMN id SERIAL;

ALTER TABLE tmp_wdi_series ADD PRIMARY KEY (id);

-- SELECT * FROM tmp_wdi_series;

/**************************************************
 6. load world bankWorld Development Indicators (WDI)
 data into a temporary table (tmp_wdi_data)
**************************************************/
DROP TABLE IF EXISTS tmp_wdi_data;
CREATE TABLE tmp_wdi_data (
	"Country Name"		character varying,
	"Country Code"		character varying,
	"Indicator Name"	character varying,
	"Indicator Code"	character varying,
	"1960"			character varying,
	"1961"			character varying,
	"1962"			character varying,
	"1963"			character varying,
	"1964"			character varying,
	"1965"			character varying,
	"1966"			character varying,
	"1967"			character varying,
	"1968"			character varying,
	"1969"			character varying,
	"1970"			character varying,
	"1971"			character varying,
	"1972"			character varying,
	"1973"			character varying,
	"1974"			character varying,
	"1975"			character varying,
	"1976"			character varying,
	"1977"			character varying,
	"1978"			character varying,
	"1979"			character varying,
	"1980"			character varying,
	"1981"			character varying,
	"1982"			character varying,
	"1983"			character varying,
	"1984"			character varying,
	"1985"			character varying,
	"1986"			character varying,	
	"1987"			character varying,
	"1988"			character varying,
	"1989"			character varying,
	"1990"			character varying,
	"1991"			character varying,
	"1992"			character varying,
	"1993"			character varying,
	"1994"			character varying,
	"1995"			character varying,
	"1996"			character varying,
	"1997"			character varying,
	"1998"			character varying,
	"1999"			character varying,
	"2000"			character varying,
	"2001"			character varying,
	"2002"			character varying,
	"2003"			character varying,
	"2004"			character varying,
	"2005"			character varying,
	"2006"			character varying,
	"2007"			character varying,
	"2008"			character varying,
	"2009"			character varying,
	"2010"			character varying,
	"2011"			character varying,
	"2012"           	character varying,
	"2013"			character varying,
	"2014"			character varying,
	"2015"			character varying
);

COPY tmp_wdi_data FROM 'WDI_Data.csv' DELIMITER ',' CSV HEADER ENCODING 'windows-1251';

ALTER TABLE tmp_wdi_data ADD COLUMN id SERIAL;

ALTER TABLE tmp_wdi_data ADD PRIMARY KEY (id);

-- SELECT * FROM tmp_wdi_data LIMIT 100;

/**************************************************
 7. create a new table in the data model to store
 statistical metadata
**************************************************/
DROP TABLE IF EXISTS stats_metadata CASCADE;
CREATE TABLE stats_metadata (
	"id"           			SERIAL			NOT NULL
	,"_code"			character varying
	,"_name"			character varying	
	,"_description"           	character varying 	
	,"_source"           		character varying
	,"_category"           		character varying 
	,"_sub_category"           	character varying 
	,"_periodicity"           	character varying 
	,"_aggregation"           	character varying 
	,"_exceptions"			character varying 
	,"_comments"			character varying
	,"_dataset"			character varying
	,"_data_origin"			character varying
	,"_active"		boolean				NOT NULL DEFAULT TRUE
	,"_retired_by"		integer
	,"_created_by" 		character varying(150)
	,"_created_date" 	timestamp without time zone 	NOT NULL DEFAULT current_date
	,"_updated_by" 		character varying(150)
	,"_updated_date" 	timestamp without time zone 	NOT NULL DEFAULT current_date
	,CONSTRAINT pk_stats_metadata_id PRIMARY KEY(id)
);
ALTER TABLE stats_metadata ADD CONSTRAINT chk_stats_metadata_created_by CHECK (_created_by IS NOT NULL) NOT VALID;
ALTER TABLE stats_metadata ADD CONSTRAINT chk_stats_metadata_updated_by CHECK (_updated_by IS NOT NULL) NOT VALID;

INSERT INTO stats_metadata(_code, _name, _description, _source, _category, _sub_category, 
            _periodicity, _aggregation, _exceptions, _comments, _dataset, _data_origin,
            _created_by, _updated_by)
SELECT "SeriesCode", "Indicator Name", "Long definition", "Source"
, substring("Topic" from 0 for position(':' in "Topic")) as category
, trim(substring("Topic" from position(':' in "Topic")+1 for length("Topic"))) as subcategory
, "Periodicity", "Aggregation method", "Limitations and exceptions",  "General comments"
,'Africa Development Indicators (ADI)', 'http://data.worldbank.org','cs_.3.0.10.14','cs_.3.0.10.14'
FROM tmp_adi_series;

INSERT INTO stats_metadata(_code, _name, _description, _source, _category, _sub_category, 
            _periodicity, _aggregation, _exceptions, _comments, _dataset, _data_origin,
            _created_by, _updated_by)
SELECT "Series Code", "Indicator Name", "Long definition", "Source"
, substring("Topic" from 0 for position(':' in "Topic")) as category
, trim(substring("Topic" from position(':' in "Topic")+1 for length("Topic"))) as subcategory
, "Periodicity", "Aggregation method", "Limitations and exceptions",  "General comments"
,'Poverty and Equity Database', 'http://data.worldbank.org','cs_.3.0.10.14','cs_.3.0.10.14'
FROM tmp_pov_series;

INSERT INTO stats_metadata(_code, _name, _description, _source, _category, _sub_category, 
            _periodicity, _aggregation, _exceptions, _comments, _dataset, _data_origin,
            _created_by, _updated_by)
SELECT "Series Code", "Indicator Name", "Long definition", "Source"
, substring("Topic" from 0 for position(':' in "Topic")) as category
, trim(substring("Topic" from position(':' in "Topic")+1 for length("Topic"))) as subcategory
, "Periodicity", "Aggregation method", "Limitations and exceptions",  "General comments"
,'World Development Indicators (WDI)', 'http://data.worldbank.org','cs_.3.0.10.14','cs_.3.0.10.14'
FROM tmp_wdi_series;

/**************************************************
 8. create a new table in the data model to store
 statistical data
**************************************************/
DROP TABLE IF EXISTS stats_data;
CREATE TABLE stats_data (
	"id"           			SERIAL 
	,"stats_metadata_id"		integer
	,"_code"			character varying
	,"_name"			character varying
	,"_boundary_level"		integer	
	,"_data_type"			character varying
	,"_data"			character varying
	,"_2000" 			character varying
	,"_2001" 			character varying
	,"_2002" 			character varying
	,"_2003" 			character varying
	,"_2004" 			character varying
	,"_2005" 			character varying
	,"_2006" 			character varying
	,"_2007" 			character varying
	,"_2008" 			character varying
	,"_2009" 			character varying
	,"_2010"			character varying
	,"_2011"			character varying
	,"_2012"			character varying
	,"_2013"			character varying
	,"_2014"			character varying
	,"_2015"			character varying
	,"_2016"			character varying
	,"_active"			boolean				NOT NULL DEFAULT TRUE
	,"_retired_by"			integer
	,"_created_by" 			character varying(150)
	,"_created_date" 		timestamp without time zone 	NOT NULL DEFAULT current_date
	,"_updated_by" 			character varying(150)
	,"_updated_date" 		timestamp without time zone 	NOT NULL DEFAULT current_date
	,CONSTRAINT pk_stats_data_id PRIMARY KEY(id)
);
ALTER TABLE stats_data ADD CONSTRAINT fk_stats_metadata_id FOREIGN KEY (stats_metadata_id) REFERENCES stats_metadata;

INSERT INTO stats_data(stats_metadata_id, _code, _name, _boundary_level, _data_type, _2000, _2001,_2002, _2003, _2004, _2005, 
	_2006, _2007, _2008, _2009, _2010, _2011, _2012, _created_by, _updated_by)
SELECT stats_metadata.id, "Country__attrCode","Country_Name_attr", 0, 'continuous', "2000", "2001", "2002", "2003", "2004", "2005", "2006", "2007", 
       "2008", "2009", "2010", "2011", "2012",'cs_.3.0.10.14','cs_.3.0.10.14'
FROM tmp_adi_data
JOIN stats_metadata ON "Indicator_Code" = _code AND _dataset = 'Africa Development Indicators (ADI)'
WHERE "2000" IS NOT NULL OR "2001" IS NOT NULL OR "2002" IS NOT NULL OR "2003" IS NOT NULL OR "2004" IS NOT NULL OR "2005" IS NOT NULL OR "2006" IS NOT NULL OR "2007" IS NOT NULL OR 
"2008" IS NOT NULL OR "2009" IS NOT NULL OR "2010" IS NOT NULL OR "2011" IS NOT NULL OR "2012" IS NOT NULL;

INSERT INTO stats_data(stats_metadata_id, _code, _name, _boundary_level, _data_type, _2000, _2001,_2002, _2003, _2004, _2005, 
	_2006, _2007, _2008, _2009, _2010, _2011, _2012, _created_by, _updated_by)
SELECT stats_metadata.id, "Country Code","Country Name",0, 'continuous', "2000", "2001", "2002", "2003", "2004", "2005", "2006", "2007", 
       "2008", "2009", "2010", "2011", "2012",'cs_.3.0.10.14','cs_.3.0.10.14'
FROM tmp_pov_data
JOIN stats_metadata ON "Indicator Code" = _code AND _dataset = 'Poverty and Equity Database'
WHERE "2000" IS NOT NULL OR "2001" IS NOT NULL OR "2002" IS NOT NULL OR "2003" IS NOT NULL OR "2004" IS NOT NULL OR "2005" IS NOT NULL OR "2006" IS NOT NULL OR "2007" IS NOT NULL OR 
"2008" IS NOT NULL OR "2009" IS NOT NULL OR "2010" IS NOT NULL OR "2011" IS NOT NULL OR "2012" IS NOT NULL;

INSERT INTO stats_data(stats_metadata_id, _code, _name, _boundary_level, _data_type, _2000, _2001,_2002, _2003, _2004, _2005, 
	_2006, _2007, _2008, _2009, _2010, _2011, _2012, _created_by, _updated_by)
SELECT stats_metadata.id, "Country Code","Country Name",0, 'continuous', "2000", "2001", "2002", "2003", "2004", "2005", "2006", "2007", 
       "2008", "2009", "2010", "2011", "2012",'cs_.3.0.10.14','cs_.3.0.10.14'
FROM tmp_wdi_data
JOIN stats_metadata ON "Indicator Code" = _code AND _dataset = 'World Development Indicators (WDI)'
WHERE "2000" IS NOT NULL OR "2001" IS NOT NULL OR "2002" IS NOT NULL OR "2003" IS NOT NULL OR "2004" IS NOT NULL OR "2005" IS NOT NULL OR "2006" IS NOT NULL OR "2007" IS NOT NULL OR 
"2008" IS NOT NULL OR "2009" IS NOT NULL OR "2010" IS NOT NULL OR "2011" IS NOT NULL OR "2012" IS NOT NULL;

-- update the data that covers areas larger than a country level
UPDATE stats_data SET _boundary_level = null WHERE _code IN (SELECT sd._code FROM stats_data sd
LEFT JOIN gadm0 g ON sd._code = g._code
WHERE g._name IS NULL);

/******************************************************************
9. create pmt_statistic_indicators to return available statistics
   select * from pmt_statistic_indicators('KEN');
   select * from stats_metadata;
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_statistic_indicators(code text) RETURNS SETOF pmt_json_result_type AS
$$
DECLARE
  execute_statement text;
  error_msg text;
  rec record;
BEGIN

  execute_statement := 'SELECT s._category ' ||
			',(SELECT array_to_json(array_agg(row_to_json(sc))) FROM ( ' ||
				'SELECT sc._sub_category ' ||
				',(SELECT array_to_json(array_agg(row_to_json(i))) FROM ( ' ||
					'SELECT id, _name ' ||
					'FROM stats_metadata ' ||
					'WHERE id IN (SELECT stats_metadata_id FROM stats_data WHERE _active = true ';
					
					 IF code IS NOT NULL AND code <> '' THEN
					  execute_statement := execute_statement || 'AND _code = ' || quote_literal($1) || ') ';
					 END IF;
					 
  execute_statement := execute_statement || 'AND _sub_category = sc._sub_category ' ||
				') as i) as indicators ' ||
			'FROM ' ||
			'(SELECT DISTINCT _sub_category ' ||
			'FROM stats_metadata ' ||
			'WHERE id IN (SELECT stats_metadata_id FROM stats_data WHERE _active = true ';
			
			IF code IS NOT NULL AND code <> '' THEN
			  execute_statement := execute_statement || 'AND _code = ' || quote_literal($1) || ') ';
			END IF;

  execute_statement := execute_statement || 'AND _category = s._category) as sc ) as sc ' ||
			') as sub_categories ' ||
			'FROM ' ||
			'(SELECT DISTINCT _category ' ||
			'FROM stats_metadata ' ||
			'WHERE id IN (SELECT stats_metadata_id FROM stats_data WHERE _active = true '; 
			
			IF code IS NOT NULL AND code <> '' THEN
			  execute_statement := execute_statement || 'AND _code = ' || quote_literal($1) || ') ';
			END IF;

  execute_statement := execute_statement ||  ') as s'; 

  RAISE NOTICE 'Execute statement: %', execute_statement;

  FOR rec IN EXECUTE 'SELECT row_to_json(j) FROM (' || execute_statement || ')j' LOOP
    RETURN NEXT rec;
  END LOOP;
  
EXCEPTION WHEN others THEN 
  GET STACKED DIAGNOSTICS error_msg = MESSAGE_TEXT;  
    RAISE NOTICE 'Internal Error - Contact your DBA with the following error message: %', error_msg;
    
END;$$ LANGUAGE plpgsql;

/******************************************************************
10. create pmt_statistic_data to return statistics for one or more
   select * from pmt_statistic_data(1733,null);
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_statistic_data(indicator_id integer, code text) RETURNS SETOF pmt_json_result_type AS
$$
DECLARE
  valid_indicator_id integer;
  execute_statement text;
  error_msg text;
  rec record;
BEGIN

  --  validate indicator_id parameter, required
  IF $1 IS NULL THEN    
    FOR rec IN (SELECT row_to_json(j) FROM(SELECT 'Error: Must include a valid indicator id (see pmt_statistic_indicators).' as message) j) LOOP  RETURN NEXT rec; END LOOP; 
    RETURN;
  ELSE
    SELECT INTO valid_indicator_id id FROM stats_metadata WHERE id = $1;
    IF valid_indicator_id IS NULL THEN
      FOR rec IN (SELECT row_to_json(j) FROM(SELECT 'Error: Must include a valid indicator id (see pmt_statistic_indicators).' as message) j) LOOP  RETURN NEXT rec; END LOOP; 
      RETURN;
    END IF;
  END IF;

  execute_statement := 'SELECT (SELECT _name FROM stats_metadata WHERE id = 1733) as indicator, _name as boundary, ' ||
	'_2000::numeric, _2001::numeric, _2002::numeric, _2003::numeric, _2004::numeric, _2005::numeric ' ||
	',_2006::numeric, _2007::numeric, _2008::numeric, _2009::numeric, _2010::numeric, _2011::numeric, _2012::numeric ' ||
	',_2013::numeric, _2014::numeric, _2015::numeric, _2016::numeric ' ||
	'FROM stats_data ' ||
	'WHERE _active = true AND stats_metadata_id = ' || $1;

  IF code IS NOT NULL AND code <> '' THEN
    execute_statement := execute_statement || ' AND _code = ' || quote_literal($2);
   END IF;

  RAISE NOTICE 'Execute statement: %', execute_statement;

  FOR rec IN EXECUTE 'SELECT row_to_json(j) FROM (' || execute_statement || ')j' LOOP
    RETURN NEXT rec;
  END LOOP;
  
EXCEPTION WHEN others THEN 
  GET STACKED DIAGNOSTICS error_msg = MESSAGE_TEXT;  
    RAISE NOTICE 'Internal Error - Contact your DBA with the following error message: %', error_msg;
    
END;$$ LANGUAGE plpgsql;

DROP TABLE IF EXISTS tmp_adi_data;
DROP TABLE IF EXISTS tmp_adi_series;
DROP TABLE IF EXISTS tmp_pov_data;
DROP TABLE IF EXISTS tmp_pov_series;
DROP TABLE IF EXISTS tmp_wdi_data;
DROP TABLE IF EXISTS tmp_wdi_series;
