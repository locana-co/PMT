/******************************************************************
Change Script 2.0.8.22 - consolidated.
1. pmt_stat_partner_network - added country_ids parameter for filter
by country, and additional level of children.
******************************************************************/
INSERT INTO version(version, iteration, changeset) VALUES (2.0, 8, 22);
-- select * from version order by changeset desc;

-- old
DROP FUNCTION IF EXISTS pmt_stat_partner_network()  CASCADE;
-- new
DROP FUNCTION IF EXISTS pmt_stat_partner_network(character varying)  CASCADE;

DROP TYPE IF EXISTS pmt_stat_partner_network_result CASCADE;

CREATE TYPE pmt_stat_partner_network_result AS (response json);

-- SELECT * FROM pmt_stat_partner_network(null);
-- SELECT * FROM pmt_stat_partner_network('244');
-- select * from taxonomy_classifications where taxonomy = 'Country'

/******************************************************************
  pmt_stat_partner_network
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_stat_partner_network(country_ids character varying)
RETURNS SETOF pmt_stat_partner_network_result AS 
$$
DECLARE
  valid_classification_ids int[];
  valid_country_ids int[];
  rec record;
  exectute_statement text;
  dynamic_where text;
BEGIN

  --  if country_ids exists validate and filter
  IF $1 IS NOT NULL OR $1 <> '' THEN
    SELECT INTO valid_classification_ids * FROM pmt_validate_classifications($1);
    RAISE NOTICE 'valid classification ids: %', valid_classification_ids;
    IF valid_classification_ids IS NOT NULL THEN
      SELECT INTO valid_country_ids array_agg(DISTINCT c.classification_id)::INT[] 
      FROM (
        SELECT classification.classification_id 
        FROM classification 
        WHERE active = true 
        AND classification.classification_id = ANY(valid_classification_ids)
        AND classification.taxonomy_id = (SELECT taxonomy.taxonomy_id FROM taxonomy WHERE iati_codelist = 'Country')
         ORDER BY classification.classification_id
      ) as c;
    END IF;
    
    IF valid_country_ids IS NOT NULL THEN
        dynamic_where := ' AND (location_ids <@ ARRAY[(select array_agg(location_id) from taxonomy_lookup where classification_id = ANY(ARRAY[' || array_to_string(valid_country_ids, ',')  || ']))]) ';      
    END IF;   
    
  END IF;
  
  -- prepare statement
  exectute_statement := 'SELECT array_to_json(array_agg(row_to_json(x))) ' ||
	'FROM ( ' ||
		-- Funding Orgs
		'SELECT f.name as name, f.organization_id as o_id, ' ||
			'(SELECT array_to_json(array_agg(row_to_json(y))) ' ||
			'FROM ( ' ||
				-- Accountable Orgs
				'SELECT ac.name as name, ' ||
					'(SELECT array_to_json(array_agg(row_to_json(z))) ' ||
					'FROM ( ' ||
						-- Implementing Orgs
						'SELECT i.name as name, ' ||
							'(SELECT array_to_json(array_agg(row_to_json(a)))  ' ||
							'FROM ( ' ||
								'SELECT a.title as name ' ||
								'FROM activity a ' ||
								'WHERE activity_id = ANY(i.activity_ids) ' ||
							')a) as children ' ||
						'FROM ( ' ||
						'SELECT ol.organization_id, o.name, array_agg(activity_id) as activity_ids ' ||
						'FROM organization_lookup ol ' ||
						'JOIN organization o ' ||
						'ON ol.organization_id = o.organization_id ' ||
						'WHERE (classification_ids @> ARRAY[(select classification_id from classification where taxonomy_id = (select taxonomy_id from taxonomy where name = ''Organisation Role'')  ' ||
						'AND iati_name = ''Implementing'')]) AND (ac.activity_ids @> ARRAY[ol.activity_id]) ' ||
						'GROUP BY ol.organization_id, o.name ' ||
						') i ' ||
					') z) as children ' ||
				'FROM ( ' ||
				'SELECT ol.organization_id, o.name, array_agg(activity_id) as activity_ids ' ||
				'FROM organization_lookup ol ' ||
				'JOIN organization o ' ||
				'ON ol.organization_id = o.organization_id ' ||
				'WHERE (classification_ids @> ARRAY[(select classification_id from classification where taxonomy_id = (select taxonomy_id from taxonomy where name = ''Organisation Role'')  ' ||
				'AND iati_name = ''Accountable'')]) AND (f.activity_ids @> ARRAY[ol.activity_id]) ' ||
				'GROUP BY ol.organization_id, o.name ' ||
				') ac ' ||
			') y) as children ' ||
		'FROM ' ||
		'(SELECT DISTINCT ol.organization_id, o.name, array_agg(activity_id) as activity_ids ' ||
		'FROM organization_lookup ol ' ||
		'JOIN organization o ' ||
		'ON ol.organization_id = o.organization_id ' ||
		'WHERE (classification_ids @> ARRAY[(select classification_id from classification where taxonomy_id = (select taxonomy_id from taxonomy where name = ''Organisation Role'')  ' ||
		'AND iati_name = ''Funding'')])  ';

		IF dynamic_where IS NOT NULL THEN
			exectute_statement := exectute_statement || dynamic_where;
		END IF;

		exectute_statement := exectute_statement || 'GROUP BY ol.organization_id, o.name) as f ' ||
		') x ';

   RAISE NOTICE 'Execute: %', exectute_statement;
   
   -- exectute the prepared statement	
   FOR rec IN EXECUTE exectute_statement LOOP
	RETURN NEXT rec; 
   END LOOP;
   
END;$$ LANGUAGE plpgsql;

-- update permissions
GRANT USAGE ON SCHEMA public TO pmt_read;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO pmt_read;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO pmt_read;
GRANT USAGE ON SCHEMA public TO pmt_write;
GRANT SELECT,INSERT ON ALL TABLES IN SCHEMA public TO pmt_write;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO pmt_write;