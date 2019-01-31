/******************************************************************
Change Script 2.0.6.15 - Consolidated

1. gual_lookup -  adding column for type: Country, Region or District
******************************************************************/
UPDATE config SET changeset = 15, updated_date = current_date WHERE "version" = 2.0 AND iteration = 6;
-- SELECT pmt_version();


-- SELECT code, name, gaul2_name, gaul1_name, gaul0_name, type, bounds as bbox FROM gaul_lookup WHERE LOWER(name) LIKE '%arusha%'

-- gual_lookup
DROP VIEW gaul_lookup;
CREATE OR REPLACE VIEW gaul_lookup AS  
SELECT code, name, 'District' as "type", gaul0_name, gaul1_name, name AS gaul2_name, ST_AsGeoJSON(Box2D(polygon)) AS bounds
FROM gaul2
UNION
SELECT DISTINCT gaul1.code, gaul1.name, 'Region' as "type", gaul2.gaul0_name, gaul1.name AS gaul1_name, null AS gaul2_name, ST_AsGeoJSON(Box2D(gaul1.polygon))  AS bounds 
FROM gaul1 
JOIN gaul2 ON gaul1.name = gaul2.gaul1_name
UNION
SELECT DISTINCT gaul0.code, gaul0.name, 'Country' as "type", gaul0.name, null AS gaul1_name, null AS gaul2_name, ST_AsGeoJSON(Box2D(gaul0.polygon))  AS bounds 
FROM gaul0;
