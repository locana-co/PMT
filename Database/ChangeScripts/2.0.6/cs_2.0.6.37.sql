/******************************************************************
Change Script 2.0.6.37 - Consolidated.
1. pmt_filter_iati - add database instance to file name for server
process to use in determining email message content.
******************************************************************/
INSERT INTO config(version, iteration, changeset) VALUES (2.0, 6, 37);
-- select * from config order by version, iteration, changeset, updated_date;

CREATE OR REPLACE FUNCTION pmt_filter_iati(classification_ids character varying, organization_ids character varying, unassigned_tax_ids character varying, start_date date, end_date date, email text)
RETURNS BOOLEAN AS 
$$
DECLARE
  activities int[];
  execute_statement text;
  filename text;
  db_instance text;
BEGIN

SELECT INTO activities string_to_array(array_to_string(array_agg(a_ids), ','), ',')::int[] FROM pmt_filter_projects($1,$2,$3,$4,$5);
RAISE NOTICE 'Activities: %', array_to_string(activities, ',') ;
IF activities IS NOT NULL THEN
 -- get the database instance (information is used by the server process to use instance specific email message when emailing file)
 SELECT INTO db_instance * FROM current_database();
 filename := '''/usr/local/pmt_dir/' || $6 || '_' || lower(db_instance) || '.xml''';
 execute_statement:= 'COPY( ' ||
	  -- activities
	 'SELECT xmlelement(name "iati-activities", xmlattributes(current_date as "generated-datetime", ''1.03'' as "version"),  ' ||
		'( ' ||
		-- activity
		'SELECT xmlagg(xmlelement(name "iati-activity", xmlattributes(to_char(a.updated_date, ''YYYY-MM-DD'') as "last-updated-datetime"),  ' ||
					'xmlelement(name "title", a.title), ' ||
					'xmlelement(name "description", a.description), ' ||
					'xmlelement(name "activity-date", xmlattributes(''start-planned'' as "type", to_char(a.start_date, ''YYYY-MM-DD'') as "iso-date"), ''''), ' ||
					'xmlelement(name "activity-date", xmlattributes(''end-planned'' as "type", to_char(a.end_date, ''YYYY-MM-DD'') as "iso-date"), ''''), ' ||
					-- budget
					'( ' ||					
						'SELECT xmlagg(xmlelement(name "budget",  ' ||
							'xmlelement(name "period-start", xmlattributes(to_char(f.start_date, ''YYYY-MM-DD'') as "iso-date"), ''''), ' ||
							'xmlelement(name "period-end", xmlattributes(to_char(f.end_date, ''YYYY-MM-DD'') as "iso-date"), ''''), ' ||
							'xmlelement(name "value",  f.amount) ' ||
						')) ' ||	
						'FROM financial f ' ||
						'WHERE f.activity_id = a.activity_id ' ||
					'), ' ||
					-- sector	
					'( ' ||
						'SELECT xmlagg(xmlelement(name "sector", xmlattributes(c.iati_code as "code"), c.iati_name))	 ' ||
						'FROM activity_taxonomy at ' ||
						'JOIN classification c ' ||
						'ON at.classification_id = c.classification_id	 ' ||
						'WHERE taxonomy_id = 15 AND at.activity_id = a.activity_id ' ||
					'), ' ||
					-- location
					'( ' ||
						'SELECT xmlagg(xmlelement(name "location",  ' ||
									'xmlelement(name "coordinates", xmlattributes(l.lat_dd as "latitude",l.long_dd as "longitude"), ''''), ' ||
									'xmlelement(name "adinistrative",  ' ||
											'xmlattributes( ' ||
												'( ' ||
												'SELECT c.iati_code ' ||
												'FROM location_taxonomy lt ' ||
												'JOIN classification c ' ||
												'ON lt.classification_id = c.classification_id ' ||
												'WHERE taxonomy_id = (SELECT taxonomy_id FROM taxonomy WHERE name = ''Country'') AND location_id = l.location_id ' ||
												'LIMIT 1 ' ||
												') as "code"), ' ||
											'(  ' ||
											'SELECT array_to_string(array_agg(name), '','') ' ||
											'FROM location_boundary_features ' ||
											'WHERE location_id = l.location_id ' ||
											')) ' ||
							      ') ' ||
							') ' ||
						'FROM location l ' ||
						'WHERE l.activity_id = a.activity_id ' ||
					') ' ||
				') ' ||
			') ' ||
		'FROM activity a		 ' ||
		'WHERE a.activity_id = ANY(ARRAY [' || array_to_string(activities, ',') || ']) ' ||
		') ' ||
	') ' ||
	') To ' || filename || ';'; 

	EXECUTE execute_statement;
	RETURN TRUE;
ELSE	
	RETURN FALSE;
END IF;

RETURN TRUE;

END;$$ LANGUAGE plpgsql;