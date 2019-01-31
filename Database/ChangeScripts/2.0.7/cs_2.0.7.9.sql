/******************************************************************
Change Script 2.0.7.9 -  Consolidated.
1. pmt_stat_orgs_by_district - add data group filter.
2. pmt_stat_activity_by_district - add data group filter.
******************************************************************/
INSERT INTO config(version, iteration, changeset) VALUES (2.0, 7, 9);
-- select * from config order by version, iteration, changeset, updated_date;

-- drop functions (old)
DROP FUNCTION IF EXISTS pmt_stat_orgs_by_district(character varying, integer, integer)  CASCADE;
DROP FUNCTION IF EXISTS pmt_stat_activity_by_district(character varying, integer)  CASCADE;
-- drop functions (new)
DROP FUNCTION IF EXISTS pmt_stat_orgs_by_district(integer, character varying, integer, integer)  CASCADE;
DROP FUNCTION IF EXISTS pmt_stat_activity_by_district(integer, character varying, integer)  CASCADE;

-- drop types
DROP TYPE IF EXISTS pmt_stat_orgs_by_district_result CASCADE;
DROP TYPE IF EXISTS pmt_stat_activity_by_district_result CASCADE;

-- create types
CREATE TYPE pmt_stat_orgs_by_district_result AS (response json);
CREATE TYPE pmt_stat_activity_by_district_result AS (response json);


--select * from pmt_stat_orgs_by_district(769, 'Abia', null, null)
--select * from pmt_stat_activity_by_district(769, 'Morogoro', 23)

/******************************************************************
  pmt_stat_orgs_by_district
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_stat_orgs_by_district(data_group_id integer, region character varying, org_role_id integer, top_limit integer)
RETURNS SETOF pmt_stat_orgs_by_district_result AS 
$$
DECLARE
  limit_by integer;
  org_c_id integer;
  valid_data_group_id integer;
  execute_statement text;
  rec record;
BEGIN
-- regionName is required
IF $2 IS NOT NULL AND $2 <> '' THEN

   -- validate data group id
   IF $1 IS NOT NULL THEN
	SELECT INTO valid_data_group_id classification_id FROM taxonomy_classifications WHERE taxonomy = 'Data Group' AND classification_id = $1;
   END IF;
   
   -- set default organization role classification to 'Accountable'  
   IF $3 IS NULL THEN
     org_c_id := (select classification_id from taxonomy_classifications where taxonomy = 'Organisation Role' and classification = 'Accountable');
   -- validate classification_id
   ELSE
     select into org_c_id classification_id from taxonomy_classifications where taxonomy = 'Organisation Role' and classification_id = $3;
     IF org_c_id IS NULL THEN
       org_c_id := (select classification_id from taxonomy_classifications where taxonomy = 'Organisation Role' and classification = 'Accountable');
     END IF;
   END IF;

   -- set default limit to 3
   IF $4 IS NULL OR $4 < 1 THEN
     limit_by := 3;
   ELSE
     limit_by := $4;
   END IF;
   
   execute_statement :=  'select row_to_json(j) from (select gaul1_name as region, name as district,(SELECT array_to_json(array_agg(row_to_json(b))) FROM ( ' ||
				'select ol.organization_id as o_id, o.name, count(l.activity_id) as a_ct ' ||
				'from organization_lookup ol ' ||
				'join ' ||
				'(select distinct activity_id, gaul1_name, gaul2_name  ' ||
				'from location_lookup where lower(gaul1_name) = trim(lower('|| quote_literal($2) ||'))';

  IF valid_data_group_id IS NOT NULL THEN
    execute_statement :=  execute_statement || ' AND classification_ids @> ARRAY[' || valid_data_group_id || '] ';
  END IF;

  execute_statement :=  execute_statement || ') as l ' ||
				'on ol.activity_id = l.activity_id ' ||
				'join organization o ' ||
				'on ol.organization_id = o.organization_id ' ||
				'where ol.classification_ids @> ARRAY[' || org_c_id || '] ' ||
				'and l.gaul2_name = g.name ' ||
				'group by ol.organization_id, o.name ' ||
				'order by a_ct desc ' ||
				'limit ' || limit_by ||
				') b) as orgs  ' ||
			'from gaul2 g ' ||
			'where lower(gaul1_name) = trim(lower('|| quote_literal($2) ||')) order by name) j';

   RAISE NOTICE 'Execute statement: %', execute_statement;
   FOR rec IN EXECUTE execute_statement LOOP
     RETURN NEXT rec; 
   END LOOP;   
END IF;   
END;$$ LANGUAGE plpgsql;
/******************************************************************
  pmt_stat_activity_by_district
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_stat_activity_by_district(data_group_id integer, regionName character varying, activity_taxonomy_id integer)
RETURNS SETOF pmt_stat_activity_by_district_result AS 
$$
DECLARE
  valid_data_group_id integer;
  is_valid_taxonomy boolean;
  execute_statement text;
  rec record;
BEGIN
-- regionName and activity_taxonomy_id are required
IF ($2 IS NOT NULL AND $2 <> '')  AND ($3 IS NOT NULL) THEN
   -- validate data group id
   IF $1 IS NOT NULL THEN
	SELECT INTO valid_data_group_id classification_id FROM taxonomy_classifications WHERE taxonomy = 'Data Group' AND classification_id = $1;
   END IF;
  -- validate taxonomy id
  select into is_valid_taxonomy * from pmt_validate_taxonomy($3);
  -- must have valid taxonomy id
  IF is_valid_taxonomy THEN	

    execute_statement :=  'select row_to_json(j) from (select gaul1_name as region, name as district,(SELECT array_to_json(array_agg(row_to_json(b))) FROM ( ' ||
				'select tl.classification_id as c_id, c.name, count(distinct tl.activity_id) as a_ct ' ||
				'from taxonomy_lookup tl ' ||
				'join ' ||
				'(select distinct activity_id, gaul1_name, gaul2_name  ' ||
				'from location_lookup where lower(gaul1_name) = trim(lower('|| quote_literal($2) ||'))';

  IF valid_data_group_id IS NOT NULL THEN
    execute_statement :=  execute_statement || ' AND classification_ids @> ARRAY[' || valid_data_group_id || '] ';
  END IF;

  execute_statement :=  execute_statement || ') as l ' ||
				'on tl.activity_id = l.activity_id ' ||
				'join classification c ' ||
				'on tl.classification_id = c.classification_id ' ||
				'where tl.taxonomy_id = ' || $3 ||
				'and l.gaul2_name = g.name ' ||
				'group by tl.classification_id, c.name ' ||
				'order by a_ct desc ' ||
				') b) as activities   ' ||
			'from gaul2 g ' ||
			'where lower(gaul1_name) = trim(lower('|| quote_literal($2) ||')) order by name) j';

     RAISE NOTICE 'Execute statement: %', execute_statement;
     FOR rec IN EXECUTE execute_statement LOOP
       RETURN NEXT rec; 
     END LOOP;   
   END IF;
END IF;   
END;$$ LANGUAGE plpgsql;

-- update permissions
GRANT USAGE ON SCHEMA public TO pmt_read;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO pmt_read;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO pmt_read;
GRANT USAGE ON SCHEMA public TO pmt_write;
GRANT SELECT,INSERT ON ALL TABLES IN SCHEMA public TO pmt_write;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO pmt_write;