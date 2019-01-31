/******************************************************************
Change Script 3.0.10.85
1. update _activity_contacts to include contact id
2. update _filter_taxonomies view to return only parent ids
3. create new function json_typeof to test json types
4. update pmt_orgs to return label
******************************************************************/
INSERT INTO version(_version, _iteration, _changeset) VALUES (3.0, 10, 85);
-- select * from version order by _iteration desc, _changeset desc;

/******************************************************************
1. update _activity_contacts to include contact id
select * from _activity_contacts
******************************************************************/
DROP VIEW _activity_contacts;

CREATE OR REPLACE VIEW _activity_contacts AS 
 SELECT a.id AS activity_id,
    c.id as contact_id,
    a.data_group_id,
    a._title,
    c._salutation,
    c._first_name,
    c._last_name
   FROM activity a
     LEFT JOIN activity_contact ac ON a.id = ac.activity_id
     JOIN contact c ON ac.contact_id = c.id
  ORDER BY a.id;

/*************************************************************************
  2. update _filter_taxonomies view to return only parent ids
     select * from _filter_taxonomies;
*************************************************************************/
CREATE OR REPLACE VIEW _filter_taxonomies AS 
 SELECT DISTINCT CASE WHEN a.parent_id IS NOT NULL THEN a.parent_id ELSE a.id END AS activity_id, --added
    a.data_group_id,
    l.id AS location_id,
    c.taxonomy_id,
    at.classification_id
   FROM ( SELECT activity.id,
	    activity.parent_id, -- added
            activity.data_group_id
           FROM activity
          WHERE activity._active = true) a
     LEFT JOIN ( SELECT location.id,
            location.activity_id
           FROM location
          WHERE location._active = true) l ON a.id = l.activity_id
     LEFT JOIN activity_taxonomy at ON a.id = at.activity_id
     LEFT JOIN ( SELECT classification.id,
            classification.taxonomy_id
           FROM classification
          WHERE classification._active = true) c ON at.classification_id = c.id
UNION ALL
 SELECT DISTINCT CASE WHEN a.parent_id IS NOT NULL THEN a.parent_id ELSE a.id END AS activity_id, --added
    a.data_group_id,
    l.id AS location_id,
    c.taxonomy_id,
    lt.classification_id
   FROM ( SELECT activity.id,
	   activity.parent_id, -- added
           activity.data_group_id
           FROM activity
          WHERE activity._active = true) a
     LEFT JOIN ( SELECT location.id,
            location.activity_id
           FROM location
          WHERE location._active = true) l ON a.id = l.activity_id
     LEFT JOIN location_taxonomy lt ON l.id = lt.location_id
     LEFT JOIN ( SELECT classification.id,
            classification.taxonomy_id
           FROM classification
          WHERE classification._active = true) c ON lt.classification_id = c.id;

/*************************************************************************
  3. create new function json_typeof to test json types
     select * from json_typeof('{"dogs":[{"name":"chow chow"}, {"name":"german sheppard"}]}');
     select * from json_typeof('["chow chow","german sheppard"]');
*************************************************************************/
CREATE OR REPLACE FUNCTION json_typeof(_json json) RETURNS text as
$$
  SELECT CASE substring(ltrim($1::text), 1, 1)
    WHEN '[' THEN 'array'
    WHEN '{' THEN 'object'
  END;
$$ language sql immutable;

/******************************************************************
4. update pmt_orgs to return label
   select * from pmt_orgs();
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_orgs() RETURNS SETOF pmt_json_result_type AS
$$
DECLARE 
  rec record;
BEGIN 
  FOR rec IN (
	SELECT row_to_json(j) FROM( 
	SELECT id, _name, _label
	FROM organization
	WHERE _active = true
	) j 
    ) LOOP		
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