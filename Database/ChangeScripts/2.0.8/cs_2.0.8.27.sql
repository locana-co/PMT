/******************************************************************
Change Script 2.0.8.27 - consolidated.
1. Removal of all unique json response types and consolidating to 
a single json result type for all functions. 
******************************************************************/
INSERT INTO version(version, iteration, changeset) VALUES (2.0, 8, 27);
-- select * from version order by changeset desc;

-- SELECT  proname FROM pg_catalog.pg_namespace n JOIN pg_catalog.pg_proc p ON pronamespace = n.oid WHERE   nspname = 'public' and proname like 'pmt_%';
-- before & after (73)
-- SELECT typname FROM pg_catalog.pg_type WHERE typname like 'pmt_%' order by typname;
-- before (35) after (9)

--Drop Functions
DROP FUNCTION IF EXISTS pmt_activity(integer)  CASCADE;
DROP FUNCTION IF EXISTS pmt_activity_details(integer) CASCADE;
DROP FUNCTION IF EXISTS pmt_activity_listview(character varying, character varying, character varying, date, date, character varying, text, integer, integer) CASCADE;
DROP FUNCTION IF EXISTS pmt_auth_user(character varying, character varying) CASCADE;
DROP FUNCTION IF EXISTS pmt_auto_complete(character varying, character varying) CASCADE;
DROP FUNCTION IF EXISTS pmt_contacts()  CASCADE;
DROP FUNCTION IF EXISTS pmt_countries(text) CASCADE;
DROP FUNCTION IF EXISTS pmt_edit_contact(integer, integer, json)  CASCADE;
DROP FUNCTION IF EXISTS pmt_global_search(text)  CASCADE;
DROP FUNCTION IF EXISTS pmt_infobox_menu(text)  CASCADE;
DROP FUNCTION IF EXISTS pmt_infobox_activity(integer)  CASCADE;
DROP FUNCTION IF EXISTS pmt_infobox_activity_contact(integer)  CASCADE;
DROP FUNCTION IF EXISTS pmt_infobox_activity_desc(integer)  CASCADE;
DROP FUNCTION IF EXISTS pmt_infobox_activity_stats(integer)  CASCADE;
DROP FUNCTION IF EXISTS pmt_infobox_project_contact(integer)  CASCADE;
DROP FUNCTION IF EXISTS pmt_infobox_project_desc(integer)  CASCADE;
DROP FUNCTION IF EXISTS pmt_infobox_project_info(integer, integer)  CASCADE;
DROP FUNCTION IF EXISTS pmt_infobox_project_stats(integer)  CASCADE;
DROP FUNCTION IF EXISTS pmt_locations_by_polygon(text) CASCADE;
DROP FUNCTION IF EXISTS pmt_org_inuse(character varying) CASCADE;
DROP FUNCTION IF EXISTS pmt_orgs()  CASCADE;
DROP FUNCTION IF EXISTS pmt_project_listview(integer, character varying, character varying, character varying, date, date, text, integer, integer) CASCADE;
DROP FUNCTION IF EXISTS pmt_sector_compare(character varying, character varying)  CASCADE;
DROP FUNCTION IF EXISTS pmt_stat_counts(character varying, character varying, character varying, date, date) CASCADE;
DROP FUNCTION IF EXISTS pmt_stat_activity_by_district(integer, character varying, character varying, integer)  CASCADE;
DROP FUNCTION IF EXISTS pmt_stat_activity_by_tax(integer, character varying, character varying, character varying, date, date) CASCADE;
DROP FUNCTION IF EXISTS pmt_stat_locations(character varying, character varying, character varying, date, date) CASCADE;
DROP FUNCTION IF EXISTS pmt_stat_partner_network(character varying)  CASCADE;
DROP FUNCTION IF EXISTS pmt_stat_pop_by_district(character varying, character varying)  CASCADE;
DROP FUNCTION IF EXISTS pmt_stat_project_by_tax(integer, character varying, character varying, character varying, date, date) CASCADE;
DROP FUNCTION IF EXISTS pmt_stat_orgs_by_activity(integer, character varying, character varying, character varying, date, date) CASCADE;
DROP FUNCTION IF EXISTS pmt_stat_orgs_by_district(integer, character varying, character varying, integer, integer)  CASCADE;
DROP FUNCTION IF EXISTS pmt_tax_inuse(integer, character varying, character varying)  CASCADE;
DROP FUNCTION IF EXISTS pmt_taxonomies(character varying)  CASCADE;
DROP FUNCTION IF EXISTS pmt_user_auth(character varying, character varying) CASCADE;
DROP FUNCTION IF EXISTS pmt_users();

DROP TYPE IF EXISTS pmt_activity_details_result_type CASCADE;
DROP TYPE IF EXISTS pmt_activity_listview_result CASCADE;
DROP TYPE IF EXISTS pmt_auth_user_result_type CASCADE;
DROP TYPE IF EXISTS pmt_auto_complete_result_type CASCADE;
DROP TYPE IF EXISTS pmt_contacts_result_type CASCADE;
DROP TYPE IF EXISTS pmt_countries_result_type CASCADE;
DROP TYPE IF EXISTS pmt_edit_contact_result_type CASCADE;
DROP TYPE IF EXISTS pmt_global_search_result_type CASCADE;
DROP TYPE IF EXISTS pmt_infobox_result_type CASCADE;
DROP TYPE IF EXISTS pmt_locations_by_polygon_result_type CASCADE;
DROP TYPE IF EXISTS pmt_org_inuse_result_type CASCADE;
DROP TYPE IF EXISTS pmt_orgs_result_type CASCADE;
DROP TYPE IF EXISTS pmt_project_listview_result CASCADE;
DROP TYPE IF EXISTS pmt_sector_compare_result_type CASCADE;
DROP TYPE IF EXISTS pmt_stat_counts_result CASCADE;
DROP TYPE IF EXISTS pmt_stat_activity_by_district_result CASCADE;
DROP TYPE IF EXISTS pmt_stat_activity_by_tax_result CASCADE;
DROP TYPE IF EXISTS pmt_stat_locations_result CASCADE;
DROP TYPE IF EXISTS pmt_stat_partner_network_result CASCADE;
DROP TYPE IF EXISTS pmt_stat_pop_by_district_result CASCADE;
DROP TYPE IF EXISTS pmt_stat_project_by_tax_result CASCADE;
DROP TYPE IF EXISTS pmt_stat_orgs_by_activity_result CASCADE;
DROP TYPE IF EXISTS pmt_stat_orgs_by_district_result CASCADE;
DROP TYPE IF EXISTS pmt_tax_inuse_result_type CASCADE;
DROP TYPE IF EXISTS pmt_taxonomies_result_type CASCADE;
DROP TYPE IF EXISTS pmt_user_auth_result_type CASCADE;
DROP TYPE IF EXISTS pmt_users_result_type CASCADE;

-- new drop
DROP TYPE IF EXISTS pmt_json_result_type CASCADE;
-- new create
CREATE TYPE pmt_json_result_type AS (response json);

/******************************************************************
   pmt_activity
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_activity(activity_id integer) RETURNS SETOF pmt_json_result_type AS $$
DECLARE
  rec record;
  invalid_return_columns text[];
  return_columns text;
  execute_statement text;
  data_message text;
BEGIN
  IF $1 IS NOT NULL THEN	
    -- set columns that are not to be returned 
    invalid_return_columns := ARRAY['active', 'retired_by', 'created_by', 'created_date'];
    -- get list of columns to return
    SELECT INTO return_columns array_to_string(array_agg('a.' || column_name::text), ', ') FROM information_schema.columns 
    WHERE table_schema='public' AND table_name='activity' AND column_name != ALL(invalid_return_columns);

    -- dynamically build the execute statment	
    execute_statement := 'SELECT ' || return_columns || ', l.location_ct, l.admin_bnds, f.amount ';

    -- taxonomy	
    execute_statement := execute_statement || ',(SELECT array_to_json(array_agg(row_to_json(t))) FROM ( ' ||
				'select tc.taxonomy_id, tc.taxonomy, tc.classification_id, tc.classification ' ||
				'from activity_taxonomy at ' ||
				'join taxonomy_classifications  tc ' ||
				'on at.classification_id = tc.classification_id ' ||
				'and at.activity_id = ' || $1 ||
				') t ) as taxonomy ';
    -- organizations			
    execute_statement := execute_statement || ',(SELECT array_to_json(array_agg(row_to_json(p))) FROM ( ' ||
				'select o.organization_id, o.name, tc.taxonomy_id, tc.taxonomy, tc.classification_id, tc.classification ' ||
				'from participation pp ' ||
				'join organization o ' ||
				'on pp.organization_id = o.organization_id ' ||
				'left join participation_taxonomy ppt ' ||
				'on pp.participation_id = ppt.participation_id ' ||
				'join taxonomy_classifications tc ' ||
				'on ppt.classification_id = tc.classification_id ' ||
				'where pp.active = true and o.active = true ' ||
				'and pp.activity_id = ' || $1 ||
				') p ) as organizations ';
    -- contacts
    execute_statement := execute_statement || ',(SELECT array_to_json(array_agg(row_to_json(c))) FROM ( ' ||
				'select c.contact_id, c.first_name, c.last_name, c.email, c.organization_id, o.name ' ||
				'from activity_contact ac ' ||
				'join contact c ' ||
				'on ac.contact_id = c.contact_id ' ||
				'left join organization o ' ||
				'on c.organization_id = o.organization_id ' ||
				'where c.active = true and ac.activity_id = ' || $1 ||
				') c ) as contacts ';				
     -- locations
    execute_statement := execute_statement || ',(SELECT array_to_json(array_agg(row_to_json(l))) FROM ( ' ||
				'select l.location_id, l.lat_dd, l.long_dd, l.x, l.y, l.georef ' ||
				'from location l ' ||				
				'where l.active = true and l.activity_id = ' || $1 ||
				') l ) as locations ';		
								
    -- activity
    execute_statement := execute_statement || 'from (select * from activity a where a.active = true and a.activity_id = ' || $1 || ') a ';
    -- locations
    execute_statement := execute_statement || 'left join ' ||
				'(select ll.activity_id, count(distinct ll.location_id) as location_ct, array_to_string(array_agg(distinct ll.gaul0_name || '','' || ll.gaul1_name || '','' || ll.gaul2_name), '';'') as admin_bnds ' ||
				'from location_lookup ll ' ||
				'where ll.activity_id = ' || $1 ||
				'group by ll.activity_id) l ' ||
				'on a.activity_id = l.activity_id ';
    -- financial	
    execute_statement := execute_statement || 'left join  ' ||
				'(select f.activity_id, sum(f.amount) as amount ' ||
				'from financial f ' ||				
				'where f.active = true and f.activity_id = ' || $1 ||
				'group by f.activity_id) f ' ||
				'on a.activity_id = f.activity_id ';

--	RAISE NOTICE 'Execute statement: %', execute_statement;			

	FOR rec IN EXECUTE 'SELECT row_to_json(j) FROM (' || execute_statement || ')j' LOOP  		
		RETURN NEXT rec;
	END LOOP;
   END IF;
END;$$ LANGUAGE plpgsql;
/******************************************************************
  pmt_activity_details
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_activity_details(a_id integer) RETURNS SETOF pmt_json_result_type AS $$
DECLARE
  valid_activity_id integer;
  rec record;
BEGIN  

  IF ( $1 IS NULL ) THEN
     FOR rec IN (SELECT row_to_json(j) FROM(select null as message) j) LOOP  RETURN NEXT rec; END LOOP;
  ELSE
    -- Is activity_id active and valid?
    SELECT INTO valid_activity_id activity_id FROM activity WHERE activity_id = $1 and active = true;

    IF valid_activity_id IS NOT NULL THEN
      FOR rec IN (
	    SELECT row_to_json(j)
	    FROM
	    (			
				SELECT a.activity_id AS a_id, coalesce(a.label, a.title) AS title, a.description AS desc,a.start_date, a.end_date, a.tags
		, f.amount
		-- taxonomy
		,(
			SELECT array_to_json(array_agg(row_to_json(t))) FROM (
				SELECT DISTINCT tc.taxonomy, tc.classification,
				(select name from organization where organization_id = ol.organization_id and tc.taxonomy = 'Organisation Role') as org
				FROM organization_lookup ol
				JOIN taxonomy_classifications  tc
				ON tc.classification_id = ANY(ARRAY[ol.classification_ids])		
				WHERE ol.activity_id = a.activity_id
				ORDER BY taxonomy
				) t
		) as taxonomy				
		-- locations
		,(
			SELECT array_to_json(array_agg(row_to_json(l))) FROM (
				SELECT DISTINCT ll.location_id, gaul0_name, gaul1_name, gaul2_name, l.lat_dd as lat, l.long_dd as long
				FROM location_lookup ll
				LEFT JOIN location l
				ON ll.location_id = l.location_id
				WHERE ll.activity_id = a.activity_id
				) l 
		) as locations		
		FROM activity a
		-- financials
		LEFT JOIN
		(SELECT activity_id, sum(amount) as amount FROM financial WHERE activity_id = $1 GROUP BY activity_id ) as f
		ON f.activity_id = a.activity_id					
		WHERE a.active = true and a.activity_id = $1
	     ) j
	    ) LOOP		
	      RETURN NEXT rec;
	    END LOOP;	
    ELSE
      FOR rec IN (SELECT row_to_json(j) FROM(select 'activity_id is not valid or active.' as message) j) LOOP  RETURN NEXT rec; END LOOP;
    END IF;           
  END IF;		
END;$$ LANGUAGE plpgsql;
/******************************************************************
  pmt_activity_listview
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_activity_listview(classification_ids character varying, organization_ids character varying, unassigned_tax_ids character varying, 
start_date date, end_date date, report_taxonomy_ids character varying, orderby text, limit_rec integer, offset_rec integer)
RETURNS SETOF pmt_json_result_type AS $$
DECLARE  
  filter_classids integer array;
  filter_orgids integer array;
  include_taxids integer array;  
  reporting_taxids integer array;
  rec record;  
  dynamic_where1 text array;
  dynamic_where2 text;
  dynamic_join text;
  dynamic_select text;
  join_ct integer;
  built_where text array; 
  execute_statement text;
  count_statement text;
  paging_statement text;
  record_count integer;
  i integer;
BEGIN

    -- filter by classification ids
    IF ($1 is not null AND $1 <> '') THEN
      RAISE NOTICE '   + The classification filter is: %.', string_to_array($1, ',')::int[];

	SELECT INTO filter_classids * FROM pmt_validate_classifications($1);

	IF filter_classids IS NOT NULL THEN
	  -- Loop through each taxonomy classification group to contruct the where statement 
	  FOR rec IN( SELECT tc.taxonomy_id, array_agg(tc.classification_id) AS filter_array 
	  FROM taxonomy_classifications tc WHERE classification_id = ANY(filter_classids) GROUP BY tc.taxonomy_id
	  ) LOOP				
		built_where := null;
		-- for each classification add to the where statement
		FOREACH i IN ARRAY rec.filter_array LOOP 
		  built_where :=  array_append(built_where, 'classification_ids @> ARRAY['|| i ||']');
		END LOOP;
		-- add each classification within the same taxonomy to the where joined by 'OR'
		dynamic_where1 := array_append(dynamic_where1, '(' || array_to_string(built_where, ' OR ') || ')');
	  END LOOP;			
	END IF;
    END IF;
   
    -- filter by organization ids
    IF ($2 is not null AND $2 <> '') THEN
      RAISE NOTICE '   + The organization filter is: %.', string_to_array($2, ',')::int[];

      -- Create an int array from organization ids list
	filter_orgids := string_to_array($2, ',')::int[];

      -- Loop through the organization_ids and construct the where statement
	built_where := null;
	FOREACH i IN ARRAY filter_orgids LOOP
		built_where :=  array_append(built_where, 't1.organization_id = '|| i );
	END LOOP;
	-- Add the complied org statements to the where
	dynamic_where1 := array_append(dynamic_where1, '(' || array_to_string(built_where, ' OR ') || ')');
	
   END IF;

    -- include values with unassigned taxonomy(ies)
    IF ($3 is not null AND $3 <> '') THEN
      RAISE NOTICE '   + The include unassigned is: %.', string_to_array($3, ',')::int[];

      -- Create an int array from unassigned ids list
      include_taxids := string_to_array($3, ',')::int[];				

      -- Loop through the organization_ids and construct the where statement
      built_where := null;
      FOREACH i IN ARRAY include_taxids LOOP
	built_where :=  array_append(built_where, 'not (taxonomy_ids @> ARRAY['|| i ||'])');
      END LOOP;			
      -- Add the complied org statements to the where
      dynamic_where2 := '(' || array_to_string(built_where, ' OR ') || ')';
	
    END IF;
    
    -- filter by date range
    IF ($4 is not null AND $5 is not null) THEN
	dynamic_where1 := array_append(dynamic_where1, '(t1.start_date > ''' || $4 || ''' AND t1.end_date < ''' || $5 || ''')');
    END IF;	

    -- -- report by taxonomy(ies)
    IF $6 IS NOT NULL AND $6 <> '' THEN      
      -- validate taxonomy ids
      SELECT INTO reporting_taxids * FROM pmt_validate_taxonomies($6);

      join_ct := 1;

      IF reporting_taxids IS NOT NULL THEN
        -- Loop through the reporting taxonomy_ids and construct the join statements      
        FOREACH i IN ARRAY reporting_taxids LOOP
          -- prepare join statements
	  IF dynamic_join IS NOT NULL THEN
            dynamic_join := dynamic_join || ' LEFT JOIN (SELECT  ot.activity_id, array_to_string(array_agg(DISTINCT tc.classification), '','') as classes ' ||
					'FROM organization_lookup ot  JOIN taxonomy_classifications tc ON tc.classification_id = ANY(ot.classification_ids) ' ||
					'WHERE taxonomy_id = ' || i || ' GROUP BY ot.activity_id ) tax' || join_ct || ' ON tax' || join_ct || '.activity_id = filter.activity_id';
          ELSE
            dynamic_join := ' LEFT JOIN (SELECT  ot.activity_id, array_to_string(array_agg(DISTINCT tc.classification), '','') as classes ' ||
					'FROM organization_lookup ot  JOIN taxonomy_classifications tc ON tc.classification_id = ANY(ot.classification_ids) ' ||
					'WHERE taxonomy_id = ' || i || ' GROUP BY ot.activity_id ) tax' || join_ct || ' ON tax' || join_ct || '.activity_id = filter.activity_id';
          END IF;
          -- prepare select statements
          IF dynamic_select IS NOT NULL THEN
            dynamic_select := dynamic_select || ', tax' || join_ct || '.classes as tax' || join_ct || ' ';
          ELSE
            dynamic_select := ', tax' || join_ct || '.classes as tax' || join_ct || ' ';
          END IF;
          join_ct := join_ct + 1;
        END LOOP;			
      END IF;
    END IF;
    
    -- create dynamic paging statment
    IF $7 IS NOT NULL AND $7 <> '' THEN      
      IF paging_statement IS NOT NULL THEN
        paging_statement := paging_statement || 'ORDER BY ' || $7 || ' ';
      ELSE
        paging_statement := ' ORDER BY ' || $7 || ' ';
      END IF;
    END IF;		    
    IF $8 IS NOT NULL AND $8 > 0 THEN
      IF paging_statement IS NOT NULL THEN
        paging_statement := paging_statement || 'LIMIT ' || $8 || ' ';
      ELSE
        paging_statement := ' LIMIT ' || $8 || ' ';
      END IF;
    END IF;		
    IF $9 IS NOT NULL AND $9 > 0 THEN
      IF paging_statement IS NOT NULL THEN
        paging_statement := paging_statement || 'OFFSET ' || $9 || ' ';
      ELSE
        paging_statement := ' OFFSET ' || $9 || ' ';
      END IF;      
    END IF;		

    -- prepare statement																
    RAISE NOTICE '   + First where statement: %', array_to_string(dynamic_where1, ' AND ');
    RAISE NOTICE '   + Second where statement: %', dynamic_where2;
    RAISE NOTICE '   + The join statement: %', dynamic_join;
    RAISE NOTICE '   + The select statement: %', dynamic_select;
    RAISE NOTICE '   + The paging statement: %', paging_statement;
		
    -- prepare statement for the selection
    execute_statement := 'SELECT filter.activity_id AS a_id, filter.title AS a_name, f_orgs.orgs as f_orgs, i_orgs.orgs as i_orgs ';

    IF dynamic_select IS NOT NULL THEN
      execute_statement := execute_statement || dynamic_select;
    END IF;

    execute_statement := execute_statement ||			
			-- filter
			'FROM ( SELECT DISTINCT t1.activity_id, a.title FROM  ' ||			
			'(SELECT * FROM organization_lookup ) as t1 ' ||
				-- activity
			'JOIN (SELECT activity_id, title from activity) as a ' ||
			'ON t1.activity_id = a.activity_id ';			
			
    -- append where statements			
    IF dynamic_where1 IS NOT NULL THEN          
      IF dynamic_where2 IS NOT NULL THEN
        execute_statement := execute_statement || ' WHERE ' ||  array_to_string(dynamic_where1, ' AND ')  || ' OR ' || dynamic_where2;
      ELSE
        execute_statement := execute_statement || ' WHERE ' ||  array_to_string(dynamic_where1, ' AND ') || ' ';
      END IF;
    ELSE 
      IF dynamic_where2 IS NOT NULL THEN
        execute_statement := execute_statement || ' WHERE ' || dynamic_where2 || ' ';                       
      END IF;
    END IF;		

    execute_statement := execute_statement || ') as filter ' ||
			-- organiztions (funding)
			'LEFT JOIN (SELECT ot.activity_id, array_to_string(array_agg(DISTINCT o.name), '','') as orgs ' ||
			'FROM organization_lookup ot JOIN taxonomy_classifications tc ON tc.classification_id = ANY(ot.classification_ids) ' ||
			'JOIN organization o ON ot.organization_id = o.organization_id WHERE taxonomy = ''Organisation Role'' AND classification = ''Funding'' ' ||
			'GROUP BY ot.activity_id ) f_orgs ON f_orgs.activity_id = filter.activity_id ' ||
			-- organiztions (implementing); 	
			'LEFT JOIN (SELECT ot.activity_id, array_to_string(array_agg(DISTINCT o.name), '','') as orgs ' ||
			'FROM organization_lookup ot JOIN taxonomy_classifications tc ON tc.classification_id = ANY(ot.classification_ids) ' ||
			'JOIN organization o ON ot.organization_id = o.organization_id WHERE taxonomy = ''Organisation Role'' AND classification = ''Implementing'' '||
			'GROUP BY ot.activity_id) i_orgs ON i_orgs.activity_id = filter.activity_id ';
    		
     IF dynamic_join IS NOT NULL THEN
      execute_statement := execute_statement || dynamic_join;
    END IF;
    
    -- if there is a paging request then add it
    IF paging_statement IS NOT NULL THEN 
      execute_statement := execute_statement || ' ' || paging_statement;
    END IF;
    
    -- execute statement		
    RAISE NOTICE 'execute: %', 'SELECT row_to_json(j) FROM (' || execute_statement || ')j';	   
     
    FOR rec IN EXECUTE 'SELECT row_to_json(j) FROM (' || execute_statement || ')j' LOOP     
	RETURN NEXT rec;
    END LOOP;	

END;$$ LANGUAGE plpgsql;
/******************************************************************
  pmt_auth_user
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_auth_user(username character varying(255), password character varying(255)) RETURNS 
SETOF pmt_json_result_type AS $$
DECLARE 
  valid_user_id integer;
  rec record;
BEGIN 
  SELECT INTO valid_user_id "user".user_id FROM "user" WHERE "user".username = $1 AND crypt($2, "user".password) = "user".password;
  IF valid_user_id IS NOT NULL THEN
    FOR rec IN (SELECT row_to_json(j) FROM( 
	SELECT user_id, first_name, last_name, "user".username, email, "user".organization_id
	, (SELECT name FROM organization WHERE organization_id = "user".organization_id) as organization, "user".data_group_id
	, (SELECT classification FROM taxonomy_classifications WHERE classification_id = "user".data_group_id) as data_group,(
	SELECT array_to_json(array_agg(row_to_json(r))) FROM ( SELECT r.role_id, r.name FROM role r 
	JOIN user_role ur ON r.role_id = ur.role_id WHERE ur.user_id = "user".user_id) r ) as roles 
	FROM "user" WHERE "user".username = $1 AND crypt($2, "user".password) = "user".password
      ) j ) LOOP		
        RETURN NEXT rec;
    END LOOP;			  
  ELSE
    FOR rec IN (SELECT row_to_json(j) FROM( SELECT 'Invalid username or password.' AS message ) j ) LOOP		
        RETURN NEXT rec;
    END LOOP;	
  END IF;
END; 
$$ LANGUAGE 'plpgsql';
/******************************************************************
  pmt_auto_complete
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_auto_complete(project_fields character varying, activity_fields character varying)
RETURNS SETOF pmt_json_result_type AS 
$$
DECLARE
  execute_statement text;
  requested_project_cols text[];
  valid_project_cols text[];
  requested_activity_cols text[];
  valid_activity_cols text[];
  col text;
  rec record;
BEGIN
  IF ( $1 IS NULL OR $1 = '') AND ( $2 IS NULL OR $2 = '')  THEN
   --  no parameters, return nothing
  ELSE
    -- validate parameters	
    IF ($1 IS NOT NULL AND $1 <> '') THEN
      -- parse input to array
      requested_project_cols := string_to_array(replace($1, ' ', ''), ',');      
      RAISE NOTICE 'Requested columns: %', requested_project_cols;
      -- validate column names
      SELECT INTO valid_project_cols array_agg(column_name::text) FROM information_schema.columns WHERE table_name='project' and column_name = ANY(requested_project_cols);
      RAISE NOTICE 'Valid columns: %', valid_project_cols;    
    END IF;
    IF ($2 IS NOT NULL AND $2 <> '') THEN
      -- parse input to array
      requested_activity_cols := string_to_array(replace($2, ' ', ''), ',');      
      RAISE NOTICE 'Requested columns: %', requested_activity_cols;
      -- validate column names
      SELECT INTO valid_activity_cols array_agg(column_name::text) FROM information_schema.columns WHERE table_name='activity' and column_name = ANY(requested_activity_cols);
      RAISE NOTICE 'Valid columns: %', valid_activity_cols;    
    END IF;

    IF valid_project_cols IS NOT NULL THEN
    FOREACH col IN ARRAY valid_project_cols LOOP
      IF execute_statement IS NULL THEN
        IF col = 'tags'::text THEN
          execute_statement := 'SELECT array_agg(DISTINCT trim(both substring(val, 0, 100))) as autocomplete FROM (SELECT DISTINCT regexp_split_to_table(' || col || ', E''\\,'')::text as val FROM project WHERE active = true ';
        ELSE
          execute_statement := 'SELECT array_agg(DISTINCT trim(both substring(val, 0, 100))) as autocomplete FROM (SELECT DISTINCT regexp_split_to_table(' || col || ', E''\\,'')::text as val FROM project WHERE active = true ';
        END IF;        
      ELSE
        IF col = 'tags'::text THEN
          execute_statement := execute_statement || ' UNION ALL SELECT DISTINCT regexp_split_to_table(' || col || ', E''\\,'')::text as val  FROM project WHERE active = true  ';
        ELSE
          execute_statement := execute_statement || ' UNION ALL SELECT DISTINCT regexp_split_to_table(' || col || ', E''\\,'')::text as val  FROM project WHERE active = true  ';
        END IF;        
      END IF;      
    END LOOP;
    END IF;
    IF valid_activity_cols IS NOT NULL THEN
    FOREACH col IN ARRAY valid_activity_cols LOOP
      IF execute_statement IS NULL THEN
        IF col = 'tags'::text THEN
          execute_statement := 'SELECT array_agg(DISTINCT trim(val)) as autocomplete FROM (SELECT  DISTINCT regexp_split_to_table(' || col || ', E''\\,'')::text as val  FROM activity WHERE active = true ';
        ELSE
          execute_statement := 'SELECT array_agg(DISTINCT trim(val)) as autocomplete FROM (SELECT  DISTINCT regexp_split_to_table(' || col || ', E''\\,'')::text as val  FROM activity WHERE active = true ';
        END IF;        
      ELSE
        IF col = 'tags'::text THEN
          execute_statement := execute_statement || ' UNION ALL SELECT DISTINCT regexp_split_to_table(' || col || ', E''\\,'')::text as val  FROM activity WHERE active = true ';
        ELSE
          execute_statement := execute_statement || ' UNION ALL SELECT DISTINCT regexp_split_to_table(' || col || ', E''\\,'')::text as val  FROM activity WHERE active = true ';
        END IF;        
      END IF;       
    END LOOP;
    END IF;
    RAISE NOTICE 'Execute statement: %', execute_statement;
    IF execute_statement IS NOT NULL THEN
      FOR rec IN EXECUTE 'SELECT row_to_json(j) FROM (' || execute_statement || ')ac WHERE val IS NOT NULL AND val <> '''')j' LOOP     
	RETURN NEXT rec;
      END LOOP;
    END IF;
             
  END IF; -- empty parameters		
END;$$ LANGUAGE plpgsql;
/******************************************************************
   pmt_contacts
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_contacts() RETURNS SETOF pmt_json_result_type AS $$
DECLARE
  rec record;
BEGIN	
  
  FOR rec IN ( SELECT row_to_json(j) FROM ( 
    SELECT c.contact_id as c_id, first_name, last_name, email, organization_id as o_id,
	(SELECT name FROM organization where organization_id = c.organization_id) as org
    FROM contact c
    ORDER BY last_name, first_name) j
  ) LOOP		
	RETURN NEXT rec;
  END LOOP;	  
END;$$ LANGUAGE plpgsql;
/******************************************************************
  pmt_countries
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_countries(classification_ids text) RETURNS SETOF pmt_json_result_type AS $$
DECLARE
  filter_classids int[];
  rec record;
BEGIN
  -- return all countries
  IF ($1 is null OR $1 = '') THEN
  FOR rec IN (
    SELECT row_to_json(j)
    FROM
    (	
	SELECT c.classification_id as c_id, lower(c.classification) as name, ST_AsGeoJSON(Box2D(ST_Collect(polygon))) as bounds
	FROM  gaul0 g
	JOIN feature_taxonomy t
	ON g.feature_id = t.feature_id
	JOIN taxonomy_classifications c
	ON t.classification_id = c.classification_id
	GROUP BY c.classification_id, c.classification
	ORDER BY c.classification
     ) j   
  ) LOOP		
    RETURN NEXT rec;
  END LOOP;	
  -- return filtered countries
  ELSE
    -- Create an int array from classification ids list
    filter_classids := string_to_array($1, ',')::int[];	
    
    FOR rec IN (
    SELECT row_to_json(j)
    FROM
    (	
	SELECT c.classification_id as c_id, lower(c.classification) as name, ST_AsGeoJSON(Box2D(ST_Collect(polygon))) as bounds
	FROM gaul0 g
	JOIN feature_taxonomy t
	ON g.feature_id = t.feature_id
	JOIN taxonomy_classifications c
	ON t.classification_id = c.classification_id
	WHERE c.classification_id = ANY(filter_classids)
	GROUP BY c.classification_id, c.classification
	ORDER BY c.classification
     ) j
    ) LOOP		
      RETURN NEXT rec;
    END LOOP;	
    
  END IF;		
END;$$ LANGUAGE plpgsql;
/******************************************************************
   pmt_edit_contact
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_edit_contact(user_id integer, contact_id integer, key_value_data json) RETURNS SETOF pmt_json_result_type AS $$
DECLARE
  new_contact_id integer;
  c_id integer;
  json record;
  column_record record;
  execute_statement text;
  invalid_editing_columns text[];
  user_name text;
  rec record;
  error_msg1 text;
  error_msg2 text;
  error_msg3 text;
BEGIN	
  -- set columns that are not editable via the parameters 
  invalid_editing_columns := ARRAY['contact_id', 'active', 'retired_by', 'created_by', 'created_date', 'updated_by', 'updated_date'];
  
  -- user and data parameters are required (next versions will have a flag for deletion)
  IF ($1 IS NULL) OR ($3 IS NULL) THEN   
    FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: Must included user_id and json data parameters.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
  END IF; 

  -- get users name
  SELECT INTO user_name username FROM "user" WHERE "user".user_id = $1;

  -- if contact_id is null then validate users authroity to create a new contact record  
  IF ($2 IS NULL) THEN
    IF (SELECT * FROM pmt_validate_user_authority($1, null, 'create')) THEN
      EXECUTE 'INSERT INTO contact(created_by, updated_by) VALUES (' || quote_literal(user_name) || ',' || quote_literal(user_name) || ') RETURNING contact_id;' INTO new_contact_id;
      RAISE NOTICE 'Created new contact with id: %', new_contact_id;
    ELSE
      FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: User does NOT have authority to create a new contact.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
    END IF;
  -- validate contact_id if provided and validate users authority to update an existing record  
  ELSE      
    IF (SELECT * FROM pmt_validate_contact($2)) THEN 
      -- validate users authority to 'update' this contact
      IF (SELECT * FROM pmt_validate_user_authority($1, null, 'update')) THEN   
      ELSE
        FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: User does NOT have authority to update an existing contact.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
      END IF;
    ELSE
      FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: Invalid contact_id.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
    END IF;
  END IF;
             
  -- assign the contact_id to use in statements
  IF new_contact_id IS NOT NULL THEN
    c_id := new_contact_id;
  ELSE
    c_id := $2;
  END IF;
  
  -- loop through the columns of the contact table        
  FOR json IN (SELECT * FROM json_each_text($3)) LOOP
    RAISE NOTICE 'JSON key/value: %', json.key || ':' || json.value;
    -- get the column information for column that user is requesting to edit	
    FOR column_record IN (SELECT * FROM information_schema.columns WHERE table_schema='public' AND table_name='contact' AND column_name != ALL(invalid_editing_columns) AND column_name = json.key) LOOP 
      RAISE NOTICE 'Editing column: %', column_record.column_name;
      RAISE NOTICE 'Assigning new value: %', json.value;
      execute_statement := null;
      CASE column_record.data_type 
        WHEN 'integer', 'numeric' THEN              
          IF (SELECT pmt_isnumeric(json.value)) THEN
            execute_statement := 'UPDATE contact SET ' || column_record.column_name || ' = ' || json.value || ' WHERE contact_id = ' || c_id; 
          END IF;
        ELSE
          -- if the value has the text null then assign the column value null
          IF (lower(json.value) = 'null') THEN
            execute_statement := 'UPDATE contact SET ' || column_record.column_name || ' = null WHERE contact_id = ' || c_id; 
          ELSE
            execute_statement := 'UPDATE contact SET ' || column_record.column_name || ' = ' || quote_literal(json.value) || ' WHERE contact_id = ' || c_id; 
          END IF;
      END CASE;
      IF execute_statement IS NOT NULL THEN
        RAISE NOTICE 'Statement: %', execute_statement;
        EXECUTE execute_statement;
                
        EXECUTE 'UPDATE contact SET updated_by = ' || quote_literal(user_name) || ', updated_date = ' || quote_literal(current_date) || ' WHERE  contact_id = ' || c_id;
      END IF;
    END LOOP;
  END LOOP;
  -- editing completed successfullly
  FOR rec IN (SELECT row_to_json(j) FROM(select c_id as id, 'Success' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
   
EXCEPTION WHEN others THEN
    GET STACKED DIAGNOSTICS error_msg1 = MESSAGE_TEXT,
                          error_msg2 = PG_EXCEPTION_DETAIL,
                          error_msg3 = PG_EXCEPTION_HINT;
    FOR rec IN (SELECT row_to_json(j) FROM(select c_id as id, 'Internal Error - Contact your DBA with the following error message: ' || error_msg1 as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;	  
END;$$ LANGUAGE plpgsql;
/******************************************************************
   pmt_global_search
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_global_search(search_text text)
RETURNS SETOF pmt_json_result_type AS 
$$
DECLARE
  rec record;
  json_rec record;
  column_rec record;
  error_msg text;
BEGIN
  IF ($1 IS NULL OR $1 = '') THEN
    -- must include all parameters, return error
    FOR rec IN (SELECT row_to_json(j) FROM(SELECT 'Error: Must include search_text data parameter.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
  ELSE
    FOR rec IN (
    SELECT row_to_json(j)
    FROM
    (	
	SELECT p.type, p.id, p.title, p.desc, p.tags, p.p_ids, p.a_ids FROM (
	SELECT 'p'::text AS "type", p.project_id AS id, coalesce(p.label, p.title) AS title, (lower(p.title) LIKE '%' || lower($1) || '%') AS in_title, 
	p.description AS desc, (lower(p.description) LIKE '%' || lower($1) || '%') AS in_desc, 
	p.tags, (lower(p.tags) LIKE '%' || lower($1) || '%') AS in_tags, array_agg(distinct p.project_id) as p_ids, array_agg(distinct l.activity_id) as a_ids
	-- , ST_AsGeoJSON(ST_Envelope(ST_UNION(l.point))) AS bbox, array_agg(l.location_id) AS l_ids
	FROM project p
	LEFT JOIN activity l
	ON p.project_id = l.project_id
	WHERE p.active = true and
	(lower(p.title) LIKE '%' || lower($1) || '%' or lower(p.description) LIKE '%' || lower($1) || '%' or lower(p.tags) LIKE '%' || lower($1) || '%')
	GROUP BY p.project_id, p.title, p.description, p.tags
	ORDER BY in_title desc, in_tags desc, in_desc desc) AS p
	UNION ALL
	SELECT a.type, a.id, a.title, a.desc, a.tags, a.p_ids, a.a_ids FROM (
	SELECT 'a'::text AS "type", a.activity_id AS id, coalesce(a.label, a.title) AS title, (lower(a.title) LIKE '%' || lower($1) || '%') AS in_title, 
	a.description AS desc, (lower(a.description) LIKE '%' || lower($1) || '%') AS in_desc, 
	a.tags, (lower(a.tags) LIKE '%' || lower($1) || '%') AS in_tags, array_agg(distinct a.project_id) as p_ids, array_agg(distinct a.activity_id) as a_ids
	-- , ST_AsGeoJSON(ST_Envelope(ST_UNION(l.point))) AS bbox, array_agg(l.location_id) AS l_ids
	FROM activity a
	WHERE a.active = true and
	(lower(a.title) LIKE '%' || lower($1) || '%' or lower(a.description) LIKE '%' || lower($1) || '%' or lower(a.tags) LIKE '%' || lower($1) || '%')
	GROUP BY a.activity_id, a.title, a.description, a.tags
	ORDER BY in_title desc, in_tags desc, in_desc desc) AS a
     ) j
    ) LOOP		
      RETURN NEXT rec;
    END LOOP;	
    
  END IF;
  	
EXCEPTION WHEN others THEN
    GET STACKED DIAGNOSTICS error_msg = MESSAGE_TEXT;
    FOR rec IN (SELECT row_to_json(j) FROM(SELECT 'Internal Error - Contact your DBA with the following error message: ' || error_msg as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;	  	
END;$$ LANGUAGE plpgsql;
/******************************************************************
  pmt_infobox_menu
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_infobox_menu(location_ids text) RETURNS SETOF pmt_json_result_type AS $$
DECLARE
  filter_locids int[]; 
  rec record;
BEGIN
	IF $1 IS NOT NULL OR $1 <> '' THEN
		-- Create an int array from location ids list
		filter_locids := string_to_array($1, ',')::int[];
				
		FOR rec IN (
		select row_to_json(p)
		from (
		   select project.project_id as p_id, title, bounds,
			(	
			select array_to_json(array_agg(row_to_json(a)))
			from(
			   select distinct activity.activity_id as a_id, title
			   from activity 
			   join (select distinct project_id, activity_id 
				 from taxonomy_lookup
				 where location_id = ANY(filter_locids)
				 ) as t1
			   on activity.activity_id = t1.activity_id
			  where activity.project_id = project.project_id
			) a
			) as activities
		   from project   
		   join (select distinct tl.project_id,  ST_AsGeoJSON(Box2D(ST_Collect(l.point))) as bounds
			 from taxonomy_lookup tl
			 join location l
			 on tl.location_id = l.location_id
			 where tl.location_id = ANY(filter_locids)
			 group by tl.project_id
			 ) as t2
		   on project.project_id = t2.project_id
		   ) p
		) LOOP		
			RETURN NEXT rec;
		END LOOP;
	END IF;
END;$$ LANGUAGE plpgsql;
/******************************************************************
  pmt_infobox_project_info
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_infobox_project_info(project_id integer, tax_id integer) RETURNS SETOF pmt_json_result_type AS $$
DECLARE
  valid_taxonomy_id boolean;
  t_id integer;
  rec record;
  data_message text;
BEGIN	
   IF $1 IS NOT NULL THEN	
	-- set no data message
	data_message := 'No Data Entered';

	-- validate and process taxonomy_id parameter
	SELECT INTO valid_taxonomy_id * FROM pmt_validate_taxonomy($2);

	IF valid_taxonomy_id THEN
	  t_id := $2;
	ELSE
	  t_id := 1;
	END IF;
	
	FOR rec IN (
	select row_to_json(j)
	from
	(	
		-- project general information
		select p.project_id
		      ,coalesce(p.label, p.title, data_message) as title				
		      ,coalesce(pp.name, data_message) as org_name
		      ,coalesce(pp.url, data_message) as org_url
		      ,coalesce(sector.name, data_message) as sector
		      ,coalesce(p.tags, data_message) as keywords
		      ,coalesce(p.url, data_message) as project_url
		      ,(select array_to_json(array_agg(row_to_json(c))) from (
			select l.lat_dd as lat, l.long_dd as long, array_to_string(array_agg(DISTINCT lt.classification_id), ',') as c_id
			from location l
			left join taxonomy_lookup lt
			on l.location_id = lt.location_id
			where l.project_id = $1  and l.active = true and lt.taxonomy_id = t_id
			group by  l.lat_dd, l.long_dd
		      ) c ) as l_ids
		from
		-- project
		(select p.project_id, p.title, p.label, p.tags, p.url
		from project p
		where p.project_id = $1 and p.active = true) p
		left join		
		-- participants
		(select pp.project_id, array_to_string(array_agg(distinct o.name), ',') as name, array_to_string(array_agg(distinct o.url), ',') as url
		from participation pp
		join organization o
		on pp.organization_id = o.organization_id
		left join participation_taxonomy ppt
		on pp.participation_id = ppt.participation_id
		join classification c
		on ppt.classification_id = c.classification_id 
		where c.taxonomy_id = (select taxonomy_id from taxonomy where name = 'Organisation Role') 
		AND pp.project_id = $1 and pp.active = true and o.active = true and c.active = true
		group by pp.project_id) pp
		on p.project_id = pp.project_id
		left join
		-- Sector
		(select p.project_id, array_to_string(array_agg(c.name), ',') as name
		from project p 
		join project_taxonomy pt
		on p.project_id = pt.project_id
		join classification c
		on pt.classification_id = c.classification_id
		where c.taxonomy_id = (select taxonomy_id from taxonomy where name = 'Sector')
		and p.project_id = $1 and p.active = true and c.active = true
		group by p.project_id) as sector
		on p.project_id = sector.project_id
	) j
	) LOOP		
		RETURN NEXT rec;
	END LOOP;
   END IF;
END;$$ LANGUAGE plpgsql;
/******************************************************************
  pmt_infobox_project_stats
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_infobox_project_stats(project_id integer) RETURNS SETOF pmt_json_result_type AS $$
DECLARE
  rec record;
  data_message text;
BEGIN
   IF $1 IS NOT NULL THEN		
	-- set no data message
	data_message := 'No Data Entered';
	
	FOR rec IN (
	select row_to_json(j)
	from
	(
		select p.project_id
		       ,p.start_date
		       ,p.end_date
		       ,coalesce(s.name, data_message) as sector
		       ,f.amount as grant
		from
		-- project
		(select p.project_id, p.start_date, p.end_date
		from project p
		where p.active = true and p.project_id = $1) p
		left join
		-- sector
		(select pt.project_id, array_to_string(array_agg(distinct c.name), ',') as  name
		from project_taxonomy pt
		join classification c
		on pt.classification_id = c.classification_id
		where c.active = true and c.taxonomy_id = (select taxonomy_id from taxonomy where name = 'Sector')
		AND pt.project_id = $1
		group by pt.project_id) as s
		on p.project_id = s.project_id
		left join
		-- financials
		(select f.project_id, sum(f.amount) as amount
		from financial f
		where f.activity_id is null and f.active = true and f.project_id = $1
		group by f.project_id) as f
		on p.project_id = f.project_id
	) j
	) LOOP		
		RETURN NEXT rec;
	END LOOP;
   END IF;
END;$$ LANGUAGE plpgsql;
/******************************************************************
  pmt_infobox_project_desc
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_infobox_project_desc(project_id integer) RETURNS SETOF pmt_json_result_type AS $$
DECLARE
  rec record;
  data_message text;
BEGIN
   IF $1 IS NOT NULL THEN		
	-- set no data message
	data_message := 'No Data Entered';
	
	FOR rec IN (
	select row_to_json(j)
	from
	(
		select p.project_id
			,coalesce(p.title, data_message) as title
		       ,coalesce(p.description, data_message) as description
		from project p
		where p.active = true and p.project_id = $1	
	) j
	) LOOP		
		RETURN NEXT rec;
	END LOOP;
   END IF;
END;$$ LANGUAGE plpgsql;
/******************************************************************
  pmt_infobox_project_contact
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_infobox_project_contact(project_id integer) RETURNS SETOF pmt_json_result_type AS $$
DECLARE
  rec record;
  data_message text;
BEGIN
   IF $1 IS NOT NULL THEN		
	-- set no data message
	data_message := 'No Data Entered';
	
	FOR rec IN (
	select row_to_json(j)
	from
	(
		select 
			 p.project_id
			,coalesce(pt.partners, data_message) as partners 
			,coalesce(c.contacts, data_message) as contacts
		from
		-- project
		(select p.project_id
		from project p
		where p.active = true and p.project_id = $1) p
		left join
		-- all partners
		(select pp.project_id, array_to_string(array_agg(distinct o.name), ',') as partners
		from participation pp
		join organization o
		on pp.organization_id = o.organization_id
		left join participation_taxonomy ppt
		on pp.participation_id = ppt.participation_id
		join classification c
		on ppt.classification_id = c.classification_id
		where  pp.active = true and o.active = true and c.active = true
		and c.taxonomy_id = (select taxonomy_id from taxonomy where name = 'Organisation Role') AND (c.name = 'Implementing')
		and pp.activity_id is null and pp.project_id = $1
		group by pp.project_id) pt
		on p.project_id = pt.project_id
		left join
		-- contacts
		(select pc.project_id, array_to_string(array_agg(distinct c.first_name || ' ' || c.last_name), ',') as contacts
		from project_contact pc
		join contact c
		on pc.contact_id = c.contact_id
		where c.active = true and pc.project_id = $1
		group by pc.project_id) c
		on p.project_id = c.project_id
		
	) j
	) LOOP		
		RETURN NEXT rec;
	END LOOP;
   END IF;
END;$$ LANGUAGE plpgsql;
/******************************************************************
  pmt_infobox_activity_stats
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_infobox_activity_stats(activity_id integer) RETURNS SETOF pmt_json_result_type AS $$
DECLARE
  rec record;
  data_message text;
BEGIN
   IF $1 IS NOT NULL THEN		
	-- set no data message
	data_message := 'No Data Entered';
	
	FOR rec IN (
	select row_to_json(j)
	from
	(	
		select a.activity_id
		       ,a.start_date
		       ,a.end_date
		       ,coalesce(si.name, data_message) as sector
		       ,coalesce(s.name, data_message) as status
		       ,coalesce(l.name, data_message) as location
		       ,coalesce(a.tags, data_message) as keywords 				
		from
		-- activity
		(select a.activity_id, a.start_date, a.end_date, a.tags
		from activity a
		where a.active = true and a.activity_id = $1) a
		left join
		-- Location
		(select l.activity_id, array_to_string(array_agg(distinct l.gaul2_name || ', ' || l.gaul1_name || ', ' || l.gaul0_name ), ',') as name
		from location_lookup l		
		where l.activity_id = $1
		group by l.activity_id) as l
		on a.activity_id =  l.activity_id
		left join 
		-- Sector
		(select at.activity_id, array_to_string(array_agg(distinct c.name), ',') as name
		from activity_taxonomy at
		join classification c
		on at.classification_id = c.classification_id
		where c.active = true and c.taxonomy_id = (select taxonomy_id from taxonomy where name = 'Sector')
		and at.activity_id = $1
		group by at.activity_id) as si
		on a.activity_id = si.activity_id
		left join
		-- Activity Status
		(select at.activity_id, array_to_string(array_agg(distinct c.name), ',') as name
		from activity_taxonomy at
		join classification c
		on at.classification_id = c.classification_id
		where  c.active = true
		and c.taxonomy_id =(select taxonomy_id from taxonomy where name = 'Activity Status')
		AND at.activity_id = $1
		group by at.activity_id) s
		on a.activity_id = s.activity_id
	) j
	) LOOP		
		RETURN NEXT rec;
	END LOOP;
   END IF;
END;$$ LANGUAGE plpgsql;
/******************************************************************
  pmt_infobox_activity_desc
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_infobox_activity_desc(activity_id integer) RETURNS SETOF pmt_json_result_type AS $$
DECLARE
  rec record;
  data_message text;
BEGIN
   IF $1 IS NOT NULL THEN		
	-- set no data message
	data_message := 'No Data Entered';
	
	FOR rec IN (
	select row_to_json(j)
	from
	(
		select a.activity_id
		       ,coalesce(a.description, data_message) as description
		from activity a
		where a.active = true and a.activity_id = $1	
	) j
	) LOOP		
		RETURN NEXT rec;
	END LOOP;
   END IF;
END;$$ LANGUAGE plpgsql;
/******************************************************************
  pmt_infobox_activity_contact
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_infobox_activity_contact(activity_id integer) RETURNS SETOF pmt_json_result_type AS $$
DECLARE
  rec record;
  data_message text;
BEGIN
   IF $1 IS NOT NULL THEN		
	-- set no data message
	data_message := 'No Data Entered';
	
	FOR rec IN (
	select row_to_json(j)
	from
	(
		select  a.activity_id
		       ,coalesce(pt.partners, data_message) as partners 
		       ,coalesce(c.contacts, data_message) as contacts
		from
		-- activity
		(select a.activity_id, a.start_date, a.end_date
		from activity a
		where a.active = true and a.activity_id = $1) a
		left join
		-- all partners
		(select pp.activity_id, array_to_string(array_agg(distinct o.name), ',') as partners
		from participation pp
		join organization o
		on pp.organization_id = o.organization_id
		left join participation_taxonomy ppt
		on pp.participation_id = ppt.participation_id
		join classification c
		on ppt.classification_id = c.classification_id
		where pp.active = true and o.active = true and c.active = true 
		and c.taxonomy_id = (select taxonomy_id from taxonomy where name = 'Organisation Role') AND (c.name = 'Implementing' OR c.name = 'Funding')
		and pp.activity_id = $1
		group by pp.activity_id) pt
		on a.activity_id = pt.activity_id
		left join
		-- contacts
		(select ac.activity_id, array_to_string(array_agg(distinct c.first_name || ' ' || c.last_name), ',') as contacts
		from activity_contact ac
		join contact c
		on ac.contact_id = c.contact_id
		where c.active = true and ac.activity_id = $1
		group by ac.activity_id) c
		on a.activity_id = c.activity_id	
	) j
	) LOOP		
		RETURN NEXT rec;
	END LOOP;
   END IF;
END;$$ LANGUAGE plpgsql;
/******************************************************************
   pmt_infobox_activity
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_infobox_activity(activity_id integer) RETURNS SETOF pmt_json_result_type AS $$
DECLARE
  rec record;
  invalid_return_columns text[];
  return_columns text;
  execute_statement text;
  data_message text;
BEGIN
  IF $1 IS NOT NULL THEN	
    -- set columns that are not to be returned 
    invalid_return_columns := ARRAY['active', 'retired_by', 'created_by', 'created_date'];
    -- get list of columns to return
    SELECT INTO return_columns array_to_string(array_agg('a.' || column_name::text), ', ') FROM information_schema.columns 
    WHERE table_schema='public' AND table_name='activity' AND column_name != ALL(invalid_return_columns);

    -- dynamically build the execute statment	
    execute_statement := 'SELECT ' || return_columns || ', l.location_ct, l.admin_bnds ';
    -- -- taxonomy	
    execute_statement := execute_statement || ',(SELECT array_to_json(array_agg(row_to_json(t))) FROM ( ' ||
				'select tc.taxonomy_id, tc.taxonomy, tc.classification_id, tc.classification ' ||
				'from activity_taxonomy at ' ||
				'join taxonomy_classifications  tc ' ||
				'on at.classification_id = tc.classification_id ' ||
				'and at.activity_id = ' || $1 ||
				') t ) as taxonomy ';
    -- partners			
    execute_statement := execute_statement || ',(SELECT array_to_json(array_agg(row_to_json(p))) FROM ( ' ||
				'select o.organization_id, o.name, tc.taxonomy_id, tc.taxonomy, tc.classification_id, tc.classification ' ||
				'from participation pp ' ||
				'join organization o ' ||
				'on pp.organization_id = o.organization_id ' ||
				'left join participation_taxonomy ppt ' ||
				'on pp.participation_id = ppt.participation_id ' ||
				'join taxonomy_classifications tc ' ||
				'on ppt.classification_id = tc.classification_id ' ||
				'where pp.active = true and o.active = true ' ||
				'and tc.taxonomy = ''Organisation Role'' and (tc.classification = ''Implementing'' OR tc.classification= ''Funding'') ' ||
				'and pp.activity_id = ' || $1 ||
				') p ) as partners ';
    -- contacts
    execute_statement := execute_statement || ',(SELECT array_to_json(array_agg(row_to_json(c))) FROM ( ' ||
				'select c.contact_id, c.first_name, c.last_name, c.organization_id, o.name ' ||
				'from activity_contact ac ' ||
				'join contact c ' ||
				'on ac.contact_id = c.contact_id ' ||
				'left join organization o ' ||
				'on c.organization_id = o.organization_id ' ||
				'where c.active = true and ac.activity_id = ' || $1 ||
				') c ) as contacts ';				
    -- activity
    execute_statement := execute_statement || 'from (select * from activity a where a.active = true and a.activity_id = ' || $1 || ') a ';
    -- locations
    execute_statement := execute_statement || 'left join ' ||
				'(select ll.activity_id, count(ll.location_id) as location_ct, array_to_string(array_agg(distinct ll.gaul0_name || '','' || ll.gaul1_name || '','' || ll.gaul2_name), '';'') as admin_bnds ' ||
				'from location_lookup ll ' ||
				'where ll.activity_id = ' || $1 ||
				'group by ll.activity_id) l ' ||
				'on a.activity_id = l.activity_id ';

	FOR rec IN EXECUTE 'SELECT row_to_json(j) FROM (' || execute_statement || ')j' LOOP  		
		RETURN NEXT rec;
	END LOOP;
   END IF;
END;$$ LANGUAGE plpgsql;
/******************************************************************
  pmt_locations_by_polygon
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_locations_by_polygon(wktPolygon text) RETURNS SETOF pmt_json_result_type AS $$
DECLARE
  wkt text;
  rec record;
BEGIN  
  -- validate the incoming WKT is a polygon and that it is all uppercase
  IF (upper(substring(trim($1) from 1 for 7)) = 'POLYGON') THEN
    RAISE NOTICE 'WKT: %', $1;
    wkt := replace(lower(trim($1)), 'polygon', 'POLYGON');    
    RAISE NOTICE 'WKT Fixed: %', wkt;  

    FOR rec IN (
    SELECT row_to_json(j)
    FROM(	
	SELECT sel.title, sel.location_ct, sel.avg_km,
		(SELECT array_to_json(array_agg(row_to_json(c))) FROM (
			SELECT location_id, lat_dd, long_dd,
				(SELECT array_to_json(array_agg(row_to_json(t))) FROM (
					SELECT DISTINCT tc.taxonomy_id, tc.taxonomy, tc.classification_id, tc.classification
					FROM taxonomy_lookup tl
					JOIN taxonomy_classifications tc
					ON tl.classification_id = tc.classification_id
					WHERE location_id = l.location_id
					AND tc.taxonomy <> 'Organisation Role'
				) t) as taxonomy,
				(SELECT array_to_json(array_agg(row_to_json(t))) FROM (
					SELECT DISTINCT o.organization_id, o.name, tc.taxonomy_id, tc.taxonomy, tc.classification_id, tc.classification
					FROM taxonomy_lookup tl
					JOIN taxonomy_classifications tc
					ON tl.classification_id = tc.classification_id
					JOIN organization o
					ON tl.organization_id = o.organization_id
					WHERE location_id = l.location_id
					AND tc.taxonomy = 'Organisation Role'
				) t) as organizations
			FROM location l
			WHERE location_id = ANY(sel.location_ids)
		) c) as locations
	FROM(
		SELECT calc.activity_id 
			,(SELECT title FROM activity a WHERE a.activity_id = calc.activity_id) AS title 
			,count(location_id) AS location_ct
			,array_agg(location_id) AS location_ids
			,round(avg(dist_km)) AS avg_km 
		FROM(
			SELECT location_id, activity_id, round(CAST(
				ST_Distance_Spheroid(ST_Centroid(ST_GeomFromText(wkt, 4326)), point, 'SPHEROID["WGS 84",6378137,298.257223563]') As numeric),2)*.001 As dist_km
			FROM location
			WHERE ST_Contains(ST_GeomFromText(wkt, 4326), point)
			AND active = true
		) as calc
		GROUP BY calc.activity_id
	) as sel 
     ) j
    ) LOOP		
      RETURN NEXT rec;
    END LOOP;	
      
  ELSE
    FOR rec IN (SELECT row_to_json(j) FROM (SELECT 'WKT must be of type POLYGON' as error) j ) LOOP		
      RETURN NEXT rec;
    END LOOP;	
  END IF;	
END;$$ LANGUAGE plpgsql;
/******************************************************************
  pmt_org_inuse
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_org_inuse(classification_ids character varying) RETURNS SETOF pmt_json_result_type AS $$
DECLARE
  valid_classification_ids int[];
  dynamic_where1 text array;
  built_where text array;
  execute_statement text;
  i integer;
  rec record;
BEGIN
  -- validate classification_ids parameter
  IF $1 IS NOT NULL OR $1 <> '' THEN
    SELECT INTO valid_classification_ids * FROM pmt_validate_classifications($1);    
    RAISE NOTICE 'Valid classifications: %', valid_classification_ids;
  END IF;

  -- create dynamic where from valid classification_ids
  IF valid_classification_ids IS NOT NULL THEN
    -- Loop through each taxonomy classification group to contruct the where statement 
    FOR rec IN( SELECT tc.taxonomy_id, array_agg(tc.classification_id) AS filter_array 
    FROM taxonomy_classifications tc WHERE classification_id = ANY(valid_classification_ids) GROUP BY tc.taxonomy_id
    ) LOOP				
	built_where := null;
	-- for each classification add to the where statement
	FOREACH i IN ARRAY rec.filter_array LOOP 
	  built_where :=  array_append(built_where, 'classification_ids @> ARRAY['|| i ||']');
	END LOOP;
	-- add each classification within the same taxonomy to the where joined by 'OR'
	dynamic_where1 := array_append(dynamic_where1, '(' || array_to_string(built_where, ' OR ') || ')');
    END LOOP;			
  END IF;
  
  -- prepare statement
  execute_statement := 'select row_to_json(j) from ( select org_order.organization_id as o_id, o.name ' ||
			'from ( select organization_id, count(distinct activity_id) as a_ct ' ||
			'from organization_lookup '; 
  IF dynamic_where1 IS NOT NULL THEN          
    execute_statement := execute_statement || 'where ' ||  array_to_string(dynamic_where1, ' AND ') ;
  END IF;

  execute_statement := execute_statement ||'group by organization_id ' ||
			') as org_order ' ||				 
			'join organization o on org_order.organization_id = o.organization_id ' || 
			'order by org_order.a_ct desc ) j';
  
  RAISE NOTICE 'Where: %', dynamic_where1;	
  RAISE NOTICE 'Execute: %', execute_statement;
  		    
  -- execute statement
  FOR rec IN EXECUTE execute_statement	    
  LOOP
    RETURN NEXT rec;    
  END LOOP;
END;$$ LANGUAGE plpgsql;
/******************************************************************
   pmt_orgs
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_orgs() RETURNS SETOF pmt_json_result_type AS $$
DECLARE
  rec record;
BEGIN	
  
  FOR rec IN ( SELECT row_to_json(j) FROM ( 
    SELECT organization_id as o_id, name
    FROM organization
    ORDER BY name) j
  ) LOOP		
	RETURN NEXT rec;
  END LOOP;	  
END;$$ LANGUAGE plpgsql;
/******************************************************************
  pmt_project_listview
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_project_listview(tax_id integer, classification_ids character varying, organization_ids character varying, unassigned_tax_ids character varying, 
start_date date, end_date date, orderby text, limit_rec integer, offset_rec integer) RETURNS SETOF pmt_json_result_type AS $$
DECLARE
  valid_taxonomy_id boolean;
  report_by_category boolean; 
  report_taxonomy_id integer;
  filter_classids integer array;
  filter_orgids integer array;
  include_taxids integer array;  
  rec record;  
  dynamic_where1 text array;
  dynamic_where2 text;
  built_where text array; 
  execute_statement text;
  count_statement text;
  paging_statement text;
  record_count integer;
  i integer;
BEGIN

-- validate and process taxonomy_id parameter
SELECT INTO valid_taxonomy_id * FROM pmt_validate_taxonomy($1); 

-- Must have valid taxonomy_id parameter to continue
IF NOT valid_taxonomy_id THEN
  RAISE NOTICE '   + A taxonomy is required.';
-- Has a valid taxonomy_id parameter 
ELSE
  report_taxonomy_id := $1;
  -- is this taxonomy a category?
  SELECT INTO report_by_category is_category FROM taxonomy WHERE taxonomy_id = (report_taxonomy_id);      
  -- yes, this is a category taxonomy
  IF report_by_category THEN
    -- what are the root taxonomy(ies) of the category taxonomy
    SELECT INTO report_taxonomy_id * FROM pmt_category_root(report_taxonomy_id, null);		    
    IF report_taxonomy_id IS NULL THEN
      -- there is no root taxonomy
      report_taxonomy_id := $1;
      report_by_category := false;
    END IF;
  END IF;

    -- filter by classification ids
    IF ($2 is not null AND $2 <> '') THEN
      RAISE NOTICE '   + The classification filter is: %.', string_to_array($2, ',')::int[];

	SELECT INTO filter_classids * FROM pmt_validate_classifications($2);

	IF filter_classids IS NOT NULL THEN
	  -- Loop through each taxonomy classification group to contruct the where statement 
	  FOR rec IN( SELECT tc.taxonomy_id, array_agg(tc.classification_id) AS filter_array 
	  FROM taxonomy_classifications tc WHERE classification_id = ANY(filter_classids) GROUP BY tc.taxonomy_id
	  ) LOOP				
		built_where := null;
		-- for each classification add to the where statement
		FOREACH i IN ARRAY rec.filter_array LOOP 
		  built_where :=  array_append(built_where, 'classification_ids @> ARRAY['|| i ||']');
		END LOOP;
		-- add each classification within the same taxonomy to the where joined by 'OR'
		dynamic_where1 := array_append(dynamic_where1, '(' || array_to_string(built_where, ' OR ') || ')');
	  END LOOP;			
	END IF;
    END IF;
   
    -- filter by organization ids
    IF ($3 is not null AND $3 <> '') THEN
      RAISE NOTICE '   + The organization filter is: %.', string_to_array($3, ',')::int[];

      -- Create an int array from organization ids list
	filter_orgids := string_to_array($3, ',')::int[];

      -- Loop through the organization_ids and construct the where statement
	built_where := null;
	FOREACH i IN ARRAY filter_orgids LOOP
		built_where :=  array_append(built_where, 'organization_ids @> ARRAY['|| i ||']');
	END LOOP;
	-- Add the complied org statements to the where
	dynamic_where1 := array_append(dynamic_where1, '(' || array_to_string(built_where, ' OR ') || ')');
	
   END IF;

    -- include values with unassigned taxonomy(ies)
    IF ($4 is not null AND $4 <> '') THEN
      RAISE NOTICE '   + The include unassigned is: %.', string_to_array($4, ',')::int[];

      -- Create an int array from unassigned ids list
      include_taxids := string_to_array($4, ',')::int[];				

      -- Loop through the organization_ids and construct the where statement
      built_where := null;
      FOREACH i IN ARRAY include_taxids LOOP
	built_where :=  array_append(built_where, 'not (taxonomy_ids @> ARRAY['|| i ||'])');
      END LOOP;			
      -- Add the complied org statements to the where
      dynamic_where2 := '(' || array_to_string(built_where, ' OR ') || ')';
	
    END IF;

    -- filter by date range
    IF ($5 is not null AND $6 is not null) THEN
	dynamic_where1 := array_append(dynamic_where1, '(filter.start_date > ''' || $5 || ''' AND filter.end_date < ''' || $6 || ''')');
    END IF;	
	   
    -- create dynamic paging statment
    IF $7 IS NOT NULL AND $7 <> '' THEN
      IF paging_statement IS NOT NULL THEN
        paging_statement := paging_statement || 'ORDER BY ' || $5 || ' ';
      ELSE
        paging_statement := ' ORDER BY ' || $7 || ' ';
      END IF;
    END IF;		    
    IF $8 IS NOT NULL AND $8 > 0 THEN
      IF paging_statement IS NOT NULL THEN
        paging_statement := paging_statement || 'LIMIT ' || $8 || ' ';
      ELSE
        paging_statement := ' LIMIT ' || $8 || ' ';
      END IF;
    END IF;		
    IF $9 IS NOT NULL AND $9 > 0 THEN
      IF paging_statement IS NOT NULL THEN
        paging_statement := paging_statement || 'OFFSET ' || $9 || ' ';
      ELSE
        paging_statement := ' OFFSET ' || $9 || ' ';
      END IF;      
    END IF;	

    -- prepare statement				
    RAISE NOTICE '   + The reporting taxonomy is: %', $1;
    RAISE NOTICE '   + The base taxonomy is: % ', report_taxonomy_id;												
    RAISE NOTICE '   + First where statement: %', array_to_string(dynamic_where1, ' AND ');
    RAISE NOTICE '   + Second where statement: %', dynamic_where2;
    RAISE NOTICE '   + The paging statement: %', paging_statement;

     -- prepare statement for the selection
    execute_statement := 'select distinct  p.project_id AS p_id ,p.title ,p.activity_ids AS a_ids ,pa.orgs AS org ,pf.funding_orgs AS f_orgs ,i.c_name ' ||
			 'from ' ||
			 -- project/activity
			 '(select p.project_id, p.title, p.opportunity_id, array_agg(filter.activity_id) as activity_ids from project p ' ||
			 -- filter
			 'join (SELECT project_id, start_date, end_date, activity_id, array_agg(distinct taxonomy_id) as taxonomy_ids, array_agg(distinct classification_id) as classification_ids ' ||
			 ',array_agg(distinct organization_id) as organization_ids FROM taxonomy_lookup GROUP BY project_id, start_date, end_date, activity_id) as filter on p.project_id = filter.project_id ';

    -- append where statements			
    IF dynamic_where1 IS NOT NULL THEN          
      IF dynamic_where2 IS NOT NULL THEN
        execute_statement := execute_statement || ' WHERE ' ||  array_to_string(dynamic_where1, ' AND ')  || ' OR ' || dynamic_where2;
      ELSE
        execute_statement := execute_statement || ' WHERE ' ||  array_to_string(dynamic_where1, ' AND ') || ' ';
      END IF;
    ELSE 
      IF dynamic_where2 IS NOT NULL THEN
        execute_statement := execute_statement || ' WHERE ' || dynamic_where2 || ' ';                       
      END IF;
    END IF;				 

    execute_statement := execute_statement || '  GROUP BY p.project_id, p.title, p.opportunity_id ) p left join ' ||
			-- participants (Accountable)
			'(select pp.project_id, array_to_string(array_agg(distinct o.name), '','') as orgs from participation pp join organization o on pp.organization_id = o.organization_id ' ||
			'left join participation_taxonomy ppt on pp.participation_id = ppt.participation_id join classification c on ppt.classification_id = c.classification_id ' ||
			'where c.taxonomy_id = (select taxonomy_id from taxonomy where name = ''Organisation Role'') AND c.name = ''Accountable'' group by pp.project_id) pa on p.project_id = pa.project_id left join ' ||
			-- participants (Funding)
			'(select pp.project_id, array_to_string(array_agg(distinct o.name), '','') as funding_orgs from participation pp join organization o on pp.organization_id = o.organization_id ' ||
			'left join participation_taxonomy ppt on pp.participation_id = ppt.participation_id join classification c on ppt.classification_id = c.classification_id ' ||
			'where c.taxonomy_id = (select taxonomy_id from taxonomy where name = ''Organisation Role'') AND (c.name = ''Funding'') group by pp.project_id) pf on p.project_id = pf.project_id left join ' ||
			-- project taxonomy
			'(select pt.project_id, array_to_string(array_agg(distinct c.name), '','') as  c_name from project_taxonomy pt join classification c on pt.classification_id = c.classification_id ' ||
			'where c.taxonomy_id = ' || $1 || ' group by pt.project_id) as i on p.project_id = i.project_id	';

    -- if there is a paging request then add it
    IF paging_statement IS NOT NULL THEN 
      execute_statement := execute_statement || ' ' || paging_statement;
    END IF;
    
    -- execute statement		
    RAISE NOTICE 'execute: %', 'SELECT row_to_json(j) FROM (' || execute_statement || ')j';	        
		
    FOR rec IN EXECUTE 'SELECT row_to_json(j) FROM (' || execute_statement || ')j' LOOP     
	RETURN NEXT rec;
    END LOOP;
    
END IF; -- Must have valid taxonomy_id parameter to continue			
END;$$ LANGUAGE plpgsql;
/******************************************************************
   pmt_sector_compare
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_sector_compare(classification_ids character varying, order_by character varying) RETURNS SETOF pmt_json_result_type AS 
$$
DECLARE
  filter_classids integer array;
  built_where text array; 
  dynamic_where1 text array;
  dynamic_orderby text;
  execute_statement text;
  i integer;
  rec record;
BEGIN	

    -- filter by classification ids
    IF ($1 is not null AND $1 <> '') THEN
      RAISE NOTICE '   + The classification filter is: %.', string_to_array($1, ',')::int[];

	SELECT INTO filter_classids * FROM pmt_validate_classifications($1);

	IF filter_classids IS NOT NULL THEN
	  -- Loop through each taxonomy classification group to contruct the where statement 
	  FOR rec IN( SELECT tc.taxonomy_id, array_agg(tc.classification_id) AS filter_array 
	  FROM taxonomy_classifications tc WHERE classification_id = ANY(filter_classids) GROUP BY tc.taxonomy_id
	  ) LOOP				
		built_where := null;
		-- for each classification add to the where statement
		FOREACH i IN ARRAY rec.filter_array LOOP 
		  built_where :=  array_append(built_where, 'classification_ids @> ARRAY['|| i ||']');
		END LOOP;
		-- add each classification within the same taxonomy to the where joined by 'OR'
		dynamic_where1 := array_append(dynamic_where1, '(' || array_to_string(built_where, ' OR ') || ')');
	  END LOOP;			
	END IF;
    END IF;

    -- create dynamic order statement
    IF $2 IS NOT NULL AND $2 <> '' THEN 
      dynamic_orderby := 'ORDER BY ' || $2 || ' ';
    END IF;

    -- prepare statement																
    RAISE NOTICE '   + First where statement: %', array_to_string(dynamic_where1, ' AND ');

    execute_statement := 'SELECT a.activity_id as a_id, tc.classification_id as c_id, tc.classification as sector, a.content as import ' ||
			'FROM activity a LEFT JOIN (SELECT * FROM activity_taxonomy WHERE classification_id IN ' ||
			'(SELECT classification_id FROM taxonomy_classifications WHERE iati_codelist = ''Sector'' AND taxonomy = ''Sector'')) AS at ' ||
			'ON a.activity_id = at.activity_id JOIN taxonomy_classifications tc ON at.classification_id = tc.classification_id ';
			
    -- append where statements			
    IF dynamic_where1 IS NOT NULL THEN 
      execute_statement := execute_statement || 'WHERE  a.activity_id IN (SELECT activity_id FROM location_lookup WHERE ' ||  array_to_string(dynamic_where1, ' AND ') || ') ';
    END IF;

    -- append order statements
    IF dynamic_orderby IS NOT NULL THEN 
      execute_statement := execute_statement || dynamic_orderby;
    END IF;
    
    -- execute statement		
    RAISE NOTICE 'execute: %', 'SELECT row_to_json(j) FROM (' || execute_statement || ')j';	   
     
    FOR rec IN EXECUTE 'SELECT row_to_json(j) FROM (' || execute_statement || ')j' LOOP     
	RETURN NEXT rec;
    END LOOP;	
	  
END;$$ LANGUAGE plpgsql;
/******************************************************************
  pmt_stat_counts
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_stat_counts(classification_ids character varying, organization_ids character varying, unassigned_tax_ids character varying, 
start_date date, end_date date) RETURNS SETOF pmt_json_result_type AS $$
DECLARE
  rec record;
  filter_classids integer array;
  filter_orgids integer array;
  include_taxids integer array;
  dynamic_where1 text array;  
  dynamic_org_where text array;
  dynamic_where2 text;
  org_where text array;
  built_where text array;
  where_statement text;
  execute_statement text;
  i integer;
  num_projects integer;
  num_activities integer;
  num_orgs integer;
  num_districts integer;
BEGIN
  -- filter by classification ids
   IF ($1 is not null AND $1 <> '') THEN

      -- Create an int array from classification ids list
	filter_classids := string_to_array($1, ',')::int[];

      -- Loop through each taxonomy classification group to contruct the where statement 
	FOR rec IN( 
	SELECT tc.taxonomy_id, array_agg(tc.classification_id) AS filter_array 
	FROM taxonomy_classifications tc 
	WHERE classification_id = ANY(filter_classids) GROUP BY tc.taxonomy_id
	) LOOP				
	  built_where := null;
	  -- for each classification add to the where statement
	  FOREACH i IN ARRAY rec.filter_array LOOP				
		built_where :=  array_append(built_where, 'classification_ids @> ARRAY['|| i ||']');
	  END LOOP;
	  -- add each classification within the same taxonomy to the where joined by 'OR'
	  dynamic_where1 := array_append(dynamic_where1, '(' || array_to_string(built_where, ' OR ') || ')');
	  dynamic_org_where := array_append(dynamic_org_where, '(' || array_to_string(built_where, ' OR ') || ')');
	END LOOP;			
   END IF;
   
   -- filter by organization ids
   IF ($2 is not null AND $2 <> '') THEN

      -- Create an int array from organization ids list
	filter_orgids := string_to_array($2, ',')::int[];		

      -- Loop through the organization_ids and construct the where statement
	built_where := null;
	FOREACH i IN ARRAY filter_orgids LOOP
		built_where :=  array_append(built_where, 'organization_ids @> ARRAY['|| i ||']');
		org_where := array_append(org_where, 'organization_id = ' || i ||' ');
	END LOOP;
	-- Add the complied org statements to the where
	dynamic_where1 := array_append(dynamic_where1, '(' || array_to_string(built_where, ' OR ') || ')');
	dynamic_org_where := array_append(dynamic_org_where, '(' || array_to_string(org_where, ' OR ') || ')');
   END IF;
   -- include unassigned taxonomy ids
   IF ($3 is not null AND $3 <> '') THEN
   
      -- Create an int array from unassigned ids list
      include_taxids := string_to_array($3, ',')::int[];				

      -- Loop through the organization_ids and construct the where statement
      built_where := null;
      FOREACH i IN ARRAY include_taxids LOOP
	built_where :=  array_append(built_where, 'not (taxonomy_ids @> ARRAY['|| i ||'])');
      END LOOP;		

      -- Add the complied org statements to the where
      dynamic_where2 := '(' || array_to_string(built_where, ' OR ') || ')';
	
   END IF;
   
   -- filter by date range
   IF ($4 is not null AND $5 is not null) THEN
	dynamic_where1 := array_append(dynamic_where1, '(start_date > ''' || $4 || ''' AND end_date < ''' || $5 || ''')');
	dynamic_org_where := array_append(dynamic_org_where, '(start_date > ''' || $4 || ''' AND end_date < ''' || $5 || ''')');
   END IF;	
   
   -- prepare where statement
   IF dynamic_where1 IS NOT NULL THEN          
    IF dynamic_where2 IS NOT NULL THEN
      where_statement := array_to_string(dynamic_where1, ' AND ')  || ' OR ' || dynamic_where2;
    ELSE
      where_statement :=  array_to_string(dynamic_where1, ' AND ') || ' ';
    END IF;
   ELSE 
    IF dynamic_where2 IS NOT NULL THEN
      where_statement :=  dynamic_where2 || ' ';                       
    END IF;
   END IF;

   -- number of projects
   execute_statement := 'SELECT count(DISTINCT project_id)::int FROM location_lookup ';
   IF where_statement IS NOT NULL THEN 	execute_statement := execute_statement || ' WHERE ' || where_statement;  END IF;
   RAISE NOTICE 'Number of projects : %', execute_statement;
   EXECUTE execute_statement INTO num_projects;   
   
   -- number of activities
   execute_statement := 'SELECT count(DISTINCT activity_id)::int FROM location_lookup ';
   IF where_statement IS NOT NULL THEN 	execute_statement := execute_statement || ' WHERE ' || where_statement;  END IF;
   RAISE NOTICE 'Number of activities : %', execute_statement;
   EXECUTE execute_statement INTO num_activities;

    -- number of districts
   execute_statement := 'SELECT count(DISTINCT lbf.name)::int FROM (SELECT location_id ' ||
			'FROM location_lookup ';
   IF where_statement IS NOT NULL THEN 	execute_statement := execute_statement || ' WHERE ' || where_statement;  END IF;
   execute_statement := execute_statement || ') as l JOIN location_boundary_features lbf ON l.location_id = lbf.location_id ' ||
			'WHERE lbf.boundary_id = (SELECT boundary_id FROM boundary WHERE spatial_table = ''gaul2'')';
   RAISE NOTICE 'Number of districts : %', execute_statement;			
   EXECUTE execute_statement INTO num_districts;
   
   -- number of orgs
   execute_statement := 'SELECT count(DISTINCT organization_id)::int FROM organization_lookup ' ||
			'WHERE (classification_ids @> ARRAY[(select classification_id from classification where taxonomy_id = (select taxonomy_id from taxonomy where name = ''Organisation Role'') AND iati_name = ''Implementing'')]) ';

    -- prepare where statement
   IF dynamic_org_where IS NOT NULL THEN          
    IF dynamic_where2 IS NOT NULL THEN
      where_statement := array_to_string(dynamic_org_where, ' AND ')  || ' OR ' || dynamic_where2;
    ELSE
      where_statement :=  array_to_string(dynamic_org_where, ' AND ') || ' ';
    END IF;
   ELSE 
    IF dynamic_where2 IS NOT NULL THEN
      where_statement :=  dynamic_where2 || ' ';                       
    END IF;
   END IF;
   			
   IF where_statement IS NOT NULL THEN 	execute_statement := execute_statement || ' AND ' || where_statement;  END IF;
   RAISE NOTICE 'Number of orgs : %', execute_statement;
   EXECUTE execute_statement INTO num_orgs;

  
   
   FOR rec IN EXECUTE 'select row_to_json(t) from (SELECT ' || 
   'coalesce('|| num_projects || ', 0) as p_ct, ' || 
   'coalesce('|| num_activities || ', 0) as a_ct, ' || 
   'coalesce('|| num_orgs || ', 0) as o_ct, ' || 
   'coalesce('|| num_districts || ', 0) as d_ct ' || 
   ') t;' LOOP
     RETURN NEXT rec; 
   END LOOP;
   	
END;$$ LANGUAGE plpgsql;
/******************************************************************
  pmt_stat_activity_by_district
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_stat_activity_by_district(data_group_id integer, country character varying, region character varying, activity_taxonomy_id integer)
RETURNS SETOF pmt_json_result_type AS $$
DECLARE
  valid_data_group_id integer;
  is_valid_taxonomy boolean;
  execute_statement text;
  rec record;
BEGIN
-- country, region and activity_taxonomy_id are required
IF ($2 IS NOT NULL AND $2 <> '') AND ($3 IS NOT NULL AND $3 <> '') AND ($4 IS NOT NULL) THEN
   -- validate data group id
   IF $1 IS NOT NULL THEN
	SELECT INTO valid_data_group_id classification_id FROM taxonomy_classifications WHERE taxonomy = 'Data Group' AND classification_id = $1;
   END IF;
  -- validate taxonomy id
  select into is_valid_taxonomy * from pmt_validate_taxonomy($4);
  -- must have valid taxonomy id
  IF is_valid_taxonomy THEN	

    execute_statement :=  'select row_to_json(j) from (select gaul1_name as region, name as district,(SELECT array_to_json(array_agg(row_to_json(b))) FROM ( ' ||
				'select tl.classification_id as c_id, c.name, count(distinct tl.activity_id) as a_ct ' ||
				'from taxonomy_lookup tl ' ||
				'join ' ||
				'(select distinct activity_id, gaul1_name, gaul2_name  ' ||
				'from location_lookup where lower(gaul1_name) = trim(lower('|| quote_literal($3) ||')) and lower(gaul0_name) = trim(lower('|| quote_literal($2) ||')) ';

  IF valid_data_group_id IS NOT NULL THEN
    execute_statement :=  execute_statement || ' AND classification_ids @> ARRAY[' || valid_data_group_id || '] ';
  END IF;

  execute_statement :=  execute_statement || ') as l ' ||
				'on tl.activity_id = l.activity_id ' ||
				'join classification c ' ||
				'on tl.classification_id = c.classification_id ' ||
				'where tl.taxonomy_id = ' || $4 ||
				'and l.gaul2_name = g.name ' ||
				'group by tl.classification_id, c.name ' ||
				'order by a_ct desc ' ||
				') b) as activities   ' ||
			'from gaul2 g ' ||
			'where lower(gaul1_name) = trim(lower('|| quote_literal($3) ||')) and lower(gaul0_name) = trim(lower('|| quote_literal($2) ||')) order by name) j';

     RAISE NOTICE 'Execute statement: %', execute_statement;
     FOR rec IN EXECUTE execute_statement LOOP
       RETURN NEXT rec; 
     END LOOP;   
   END IF;
END IF;   
END;$$ LANGUAGE plpgsql;
/******************************************************************
  pmt_stat_activity_by_tax
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_stat_activity_by_tax(tax_id integer, classification_ids character varying, organization_ids character varying, unassigned_tax_ids character varying, 
start_date date, end_date date) RETURNS SETOF pmt_json_result_type AS $$
DECLARE
  rec record;
  valid_taxonomy_id boolean;
  filter_classids integer array;
  filter_orgids integer array;
  include_taxids integer array;
  dynamic_where1 text array;
  dynamic_where2 text;
  built_where text array;
  where_statement text;
  execute_statement text;
  i integer;
BEGIN
-- validate and process taxonomy_id parameter
SELECT INTO valid_taxonomy_id * FROM pmt_validate_taxonomy($1); 

-- Must have taxonomy_id parameter to continue
IF NOT valid_taxonomy_id THEN
   RAISE NOTICE '   + A taxonomy is required.';
ELSE
   -- filter by classification ids
   IF ($2 is not null AND $2 <> '') THEN

      -- Create an int array from classification ids list
	filter_classids := string_to_array($2, ',')::int[];

      -- Loop through each taxonomy classification group to contruct the where statement 
	FOR rec IN( 
	SELECT tc.taxonomy_id, array_agg(tc.classification_id) AS filter_array 
	FROM taxonomy_classifications tc 
	WHERE classification_id = ANY(filter_classids) GROUP BY tc.taxonomy_id
	) LOOP				
	  built_where := null;
	  -- for each classification add to the where statement
	  FOREACH i IN ARRAY rec.filter_array LOOP				
		built_where :=  array_append(built_where, 'classification_ids @> ARRAY['|| i ||']');
	  END LOOP;
	  -- add each classification within the same taxonomy to the where joined by 'OR'
	  dynamic_where1 := array_append(dynamic_where1, '(' || array_to_string(built_where, ' OR ') || ')');
	END LOOP;			
   END IF;
   
   -- filter by organization ids
   IF ($3 is not null AND $3 <> '') THEN

      -- Create an int array from organization ids list
	filter_orgids := string_to_array($3, ',')::int[];		

      -- Loop through the organization_ids and construct the where statement
	built_where := null;
	FOREACH i IN ARRAY filter_orgids LOOP
		built_where :=  array_append(built_where, 'organization_ids @> ARRAY['|| i ||']');
	END LOOP;
	-- Add the complied org statements to the where
	dynamic_where1 := array_append(dynamic_where1, '(' || array_to_string(built_where, ' OR ') || ')');
	
   END IF;
   -- include unassigned taxonomy ids
   IF ($4 is not null AND $4 <> '') THEN
   
      -- Create an int array from unassigned ids list
      include_taxids := string_to_array($4, ',')::int[];				

      -- Loop through the organization_ids and construct the where statement
      built_where := null;
      FOREACH i IN ARRAY include_taxids LOOP
	built_where :=  array_append(built_where, 'not (taxonomy_ids @> ARRAY['|| i ||'])');
      END LOOP;		

      -- Add the complied org statements to the where
      dynamic_where2 := '(' || array_to_string(built_where, ' OR ') || ')';
	
   END IF;
   
   -- filter by date range
   IF ($5 is not null AND $6 is not null) THEN
	dynamic_where1 := array_append(dynamic_where1, '(start_date > ''' || $5 || ''' AND end_date < ''' || $6 || ''')');
   END IF;	
   
   -- prepare where statement
   IF dynamic_where1 IS NOT NULL THEN          
    IF dynamic_where2 IS NOT NULL THEN
      where_statement := array_to_string(dynamic_where1, ' AND ')  || ' OR ' || dynamic_where2;
    ELSE
      where_statement :=  array_to_string(dynamic_where1, ' AND ') || ' ';
    END IF;
   ELSE 
    IF dynamic_where2 IS NOT NULL THEN
      where_statement :=  dynamic_where2 || ' ';                       
    END IF;
   END IF;

   execute_statement :=  'select row_to_json(j) FROM (SELECT report_by.classification_id as c_id, count(DISTINCT a.activity_id) as a_ct FROM ' ||
			 '(SELECT DISTINCT activity_id FROM location_lookup ';
   IF where_statement IS NOT NULL THEN 	execute_statement := execute_statement || ' WHERE ' || where_statement;  END IF;
   execute_statement :=  execute_statement || ')as a LEFT JOIN (SELECT activity_id,classification_id FROM taxonomy_lookup WHERE taxonomy_id = ' || $1 || ') as report_by ' ||
			 'ON a.activity_id = report_by.activity_id GROUP BY classification_id) as j';
   
 
   FOR rec IN EXECUTE execute_statement LOOP
     RETURN NEXT rec; 
   END LOOP;
   
END IF; -- must have valid taxonomy   	
END;$$ LANGUAGE plpgsql;
/******************************************************************
  pmt_stat_locations
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_stat_locations(classification_ids character varying, organization_ids character varying, unassigned_tax_ids character varying, 
start_date date, end_date date) RETURNS SETOF pmt_json_result_type AS $$
DECLARE
  rec record;
  filter_classids integer array;
  filter_orgids integer array;
  include_taxids integer array;
  dynamic_where1 text array;
  dynamic_where2 text;
  built_where text array;
  where_statement text;
  execute_statement text;
  i integer;
  num_projects integer;
  num_activities integer;
  num_orgs integer;
  num_districts integer;
BEGIN
  -- filter by classification ids
   IF ($1 is not null AND $1 <> '') THEN

      -- Create an int array from classification ids list
	filter_classids := string_to_array($1, ',')::int[];

      -- Loop through each taxonomy classification group to contruct the where statement 
	FOR rec IN( 
	SELECT tc.taxonomy_id, array_agg(tc.classification_id) AS filter_array 
	FROM taxonomy_classifications tc 
	WHERE classification_id = ANY(filter_classids) GROUP BY tc.taxonomy_id
	) LOOP				
	  built_where := null;
	  -- for each classification add to the where statement
	  FOREACH i IN ARRAY rec.filter_array LOOP				
		built_where :=  array_append(built_where, 'classification_ids @> ARRAY['|| i ||']');
	  END LOOP;
	  -- add each classification within the same taxonomy to the where joined by 'OR'
	  dynamic_where1 := array_append(dynamic_where1, '(' || array_to_string(built_where, ' OR ') || ')');
	END LOOP;			
   END IF;
   
   -- filter by organization ids
   IF ($2 is not null AND $2 <> '') THEN

      -- Create an int array from organization ids list
	filter_orgids := string_to_array($2, ',')::int[];		

      -- Loop through the organization_ids and construct the where statement
	built_where := null;
	FOREACH i IN ARRAY filter_orgids LOOP
		built_where :=  array_append(built_where, 'organization_ids @> ARRAY['|| i ||']');
	END LOOP;
	-- Add the complied org statements to the where
	dynamic_where1 := array_append(dynamic_where1, '(' || array_to_string(built_where, ' OR ') || ')');
	
   END IF;
   -- include unassigned taxonomy ids
   IF ($3 is not null AND $3 <> '') THEN
   
      -- Create an int array from unassigned ids list
      include_taxids := string_to_array($3, ',')::int[];				

      -- Loop through the organization_ids and construct the where statement
      built_where := null;
      FOREACH i IN ARRAY include_taxids LOOP
	built_where :=  array_append(built_where, 'not (taxonomy_ids @> ARRAY['|| i ||'])');
      END LOOP;		

      -- Add the complied org statements to the where
      dynamic_where2 := '(' || array_to_string(built_where, ' OR ') || ')';
	
   END IF;
   
   -- filter by date range
   IF ($4 is not null AND $5 is not null) THEN
	dynamic_where1 := array_append(dynamic_where1, '(start_date > ''' || $4 || ''' AND end_date < ''' || $5 || ''')');
   END IF;	
   
   -- prepare where statement
   IF dynamic_where1 IS NOT NULL THEN          
    IF dynamic_where2 IS NOT NULL THEN
      where_statement := array_to_string(dynamic_where1, ' AND ')  || ' OR ' || dynamic_where2;
    ELSE
      where_statement :=  array_to_string(dynamic_where1, ' AND ') || ' ';
    END IF;
   ELSE 
    IF dynamic_where2 IS NOT NULL THEN
      where_statement :=  dynamic_where2 || ' ';                       
    END IF;
   END IF;

   -- locations
   execute_statement := 'select row_to_json(t) from (SELECT filter.location_id as l_id, l.lat_dd, l.long_dd FROM ' ||
			'(SELECT location_id FROM location_lookup ';
			
   IF where_statement IS NOT NULL THEN 	execute_statement := execute_statement || ' WHERE ' || where_statement;  END IF;
   
   execute_statement := execute_statement || ') as filter JOIN location l ON filter.location_id = l.location_id) as t';
   
   
   FOR rec IN EXECUTE execute_statement LOOP
     RETURN NEXT rec; 
   END LOOP;
   	
END;$$ LANGUAGE plpgsql;
/******************************************************************
  pmt_stat_partner_network
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_stat_partner_network(country_ids character varying) RETURNS SETOF pmt_json_result_type AS $$
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
/******************************************************************
  pmt_stat_pop_by_district
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_stat_pop_by_district(country character varying, region character varying) RETURNS SETOF pmt_json_result_type AS $$
DECLARE
  valid_data_group_id integer;
  execute_statement text;
  rec record;
BEGIN
-- country & region are required
IF ($1 IS NOT NULL AND $1 <> '') AND ($2 IS NOT NULL AND $2 <> '') THEN
   
   execute_statement :=  'select row_to_json(j) from (select gaul1_name as region, name as district, pop_total, pop_poverty, pop_rural, pop_poverty_rural, pop_source ' ||
				'from gaul2 ' ||
				'where lower(gaul0_name) = trim(lower('|| quote_literal($1) ||')) and lower(gaul1_name) = trim(lower('|| quote_literal($2) ||')) order by name) j';

   RAISE NOTICE 'Execute statement: %', execute_statement;
   FOR rec IN EXECUTE execute_statement LOOP
     RETURN NEXT rec; 
   END LOOP;   
END IF;   
END;$$ LANGUAGE plpgsql;
/******************************************************************
  pmt_stat_project_by_tax
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_stat_project_by_tax(tax_id integer, classification_ids character varying, organization_ids character varying, unassigned_tax_ids character varying, 
start_date date, end_date date) RETURNS SETOF pmt_json_result_type AS $$
DECLARE
  rec record;
  valid_taxonomy_id boolean;
  filter_classids integer array;
  filter_orgids integer array;
  include_taxids integer array;
  dynamic_where1 text array;
  dynamic_where2 text;
  built_where text array;
  where_statement text;
  execute_statement text;
  i integer;
BEGIN
-- validate and process taxonomy_id parameter
SELECT INTO valid_taxonomy_id * FROM pmt_validate_taxonomy($1); 

-- Must have taxonomy_id parameter to continue
IF NOT valid_taxonomy_id THEN
   RAISE NOTICE '   + A taxonomy is required.';
ELSE
   -- filter by classification ids
   IF ($2 is not null AND $2 <> '') THEN

      -- Create an int array from classification ids list
	filter_classids := string_to_array($2, ',')::int[];

      -- Loop through each taxonomy classification group to contruct the where statement 
	FOR rec IN( 
	SELECT tc.taxonomy_id, array_agg(tc.classification_id) AS filter_array 
	FROM taxonomy_classifications tc 
	WHERE classification_id = ANY(filter_classids) GROUP BY tc.taxonomy_id
	) LOOP				
	  built_where := null;
	  -- for each classification add to the where statement
	  FOREACH i IN ARRAY rec.filter_array LOOP				
		built_where :=  array_append(built_where, 'classification_ids @> ARRAY['|| i ||']');
	  END LOOP;
	  -- add each classification within the same taxonomy to the where joined by 'OR'
	  dynamic_where1 := array_append(dynamic_where1, '(' || array_to_string(built_where, ' OR ') || ')');
	END LOOP;			
   END IF;
   
   -- filter by organization ids
   IF ($3 is not null AND $3 <> '') THEN

      -- Create an int array from organization ids list
	filter_orgids := string_to_array($3, ',')::int[];		

      -- Loop through the organization_ids and construct the where statement
	built_where := null;
	FOREACH i IN ARRAY filter_orgids LOOP
		built_where :=  array_append(built_where, 'organization_ids @> ARRAY['|| i ||']');
	END LOOP;
	-- Add the complied org statements to the where
	dynamic_where1 := array_append(dynamic_where1, '(' || array_to_string(built_where, ' OR ') || ')');
	
   END IF;
   -- include unassigned taxonomy ids
   IF ($4 is not null AND $4 <> '') THEN
   
      -- Create an int array from unassigned ids list
      include_taxids := string_to_array($4, ',')::int[];				

      -- Loop through the organization_ids and construct the where statement
      built_where := null;
      FOREACH i IN ARRAY include_taxids LOOP
	built_where :=  array_append(built_where, 'not (taxonomy_ids @> ARRAY['|| i ||'])');
      END LOOP;		

      -- Add the complied org statements to the where
      dynamic_where2 := '(' || array_to_string(built_where, ' OR ') || ')';
	
   END IF;
   
   -- filter by date range
   IF ($5 is not null AND $6 is not null) THEN
	dynamic_where1 := array_append(dynamic_where1, '(start_date > ''' || $5 || ''' AND end_date < ''' || $6 || ''')');
   END IF;	
   
   -- prepare where statement
   IF dynamic_where1 IS NOT NULL THEN          
    IF dynamic_where2 IS NOT NULL THEN
      where_statement := array_to_string(dynamic_where1, ' AND ')  || ' OR ' || dynamic_where2;
    ELSE
      where_statement :=  array_to_string(dynamic_where1, ' AND ') || ' ';
    END IF;
   ELSE 
    IF dynamic_where2 IS NOT NULL THEN
      where_statement :=  dynamic_where2 || ' ';                       
    END IF;
   END IF;

   execute_statement :=  'select row_to_json(j) FROM (SELECT report_by.classification_id as c_id, count(DISTINCT a.project_id) as p_ct FROM ' ||
			 '(SELECT DISTINCT project_id FROM location_lookup ';
   IF where_statement IS NOT NULL THEN 	execute_statement := execute_statement || ' WHERE ' || where_statement;  END IF;
   execute_statement :=  execute_statement || ')as a LEFT JOIN (SELECT project_id,classification_id FROM taxonomy_lookup WHERE taxonomy_id = ' || $1 || ') as report_by ' ||
			 'ON a.project_id = report_by.project_id GROUP BY classification_id) as j';
   
   RAISE NOTICE 'Execute statement: %', execute_statement;
   
   FOR rec IN EXECUTE execute_statement LOOP
     RETURN NEXT rec; 
   END LOOP;
   
END IF; -- must have valid taxonomy   	
END;$$ LANGUAGE plpgsql;
/******************************************************************
  pmt_stat_orgs_by_activity
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_stat_orgs_by_activity(tax_id integer, classification_ids character varying, organization_ids character varying, unassigned_tax_ids character varying, 
start_date date, end_date date) RETURNS SETOF pmt_json_result_type AS $$
DECLARE
  rec record;
  valid_taxonomy_id boolean;
  filter_classids integer array;
  filter_orgids integer array;
  include_taxids integer array;
  dynamic_where1 text array;
  dynamic_where2 text;
  built_where text array;
  where_statement text;
  execute_statement text;
  i integer;
BEGIN
-- validate and process taxonomy_id parameter
SELECT INTO valid_taxonomy_id * FROM pmt_validate_taxonomy($1); 

-- Must have taxonomy_id parameter to continue
IF NOT valid_taxonomy_id THEN
   RAISE NOTICE '   + A taxonomy is required.';
ELSE
   -- filter by classification ids
   IF ($2 is not null AND $2 <> '') THEN

      -- Create an int array from classification ids list
	filter_classids := string_to_array($2, ',')::int[];

      -- Loop through each taxonomy classification group to contruct the where statement 
	FOR rec IN( 
	SELECT tc.taxonomy_id, array_agg(tc.classification_id) AS filter_array 
	FROM taxonomy_classifications tc 
	WHERE classification_id = ANY(filter_classids) GROUP BY tc.taxonomy_id
	) LOOP				
	  built_where := null;
	  -- for each classification add to the where statement
	  FOREACH i IN ARRAY rec.filter_array LOOP				
		built_where :=  array_append(built_where, 'classification_ids @> ARRAY['|| i ||']');
	  END LOOP;
	  -- add each classification within the same taxonomy to the where joined by 'OR'
	  dynamic_where1 := array_append(dynamic_where1, '(' || array_to_string(built_where, ' OR ') || ')');
	END LOOP;			
   END IF;
   
   -- filter by organization ids
   IF ($3 is not null AND $3 <> '') THEN

      -- Create an int array from organization ids list
	filter_orgids := string_to_array($3, ',')::int[];		

      -- Loop through the organization_ids and construct the where statement
	built_where := null;
	FOREACH i IN ARRAY filter_orgids LOOP
		built_where :=  array_append(built_where, 'organization_id = '|| i );
	END LOOP;
	-- Add the complied org statements to the where
	dynamic_where1 := array_append(dynamic_where1, '(' || array_to_string(built_where, ' OR ') || ')');
	
   END IF;
   -- include unassigned taxonomy ids
   IF ($4 is not null AND $4 <> '') THEN
   
      -- Create an int array from unassigned ids list
      include_taxids := string_to_array($4, ',')::int[];				

      -- Loop through the organization_ids and construct the where statement
      built_where := null;
      FOREACH i IN ARRAY include_taxids LOOP
	built_where :=  array_append(built_where, 'not (taxonomy_ids @> ARRAY['|| i ||'])');
      END LOOP;		

      -- Add the complied org statements to the where
      dynamic_where2 := '(' || array_to_string(built_where, ' OR ') || ')';
	
   END IF;
   
   -- filter by date range
   IF ($5 is not null AND $6 is not null) THEN
	dynamic_where1 := array_append(dynamic_where1, '(start_date > ''' || $5 || ''' AND end_date < ''' || $6 || ''')');
   END IF;	
   
   -- prepare where statement
   IF dynamic_where1 IS NOT NULL THEN          
    IF dynamic_where2 IS NOT NULL THEN
      where_statement := array_to_string(dynamic_where1, ' AND ')  || ' OR ' || dynamic_where2;
    ELSE
      where_statement :=  array_to_string(dynamic_where1, ' AND ') || ' ';
    END IF;
   ELSE 
    IF dynamic_where2 IS NOT NULL THEN
      where_statement :=  dynamic_where2 || ' ';                       
    END IF;
   END IF;

   execute_statement :=  'SELECT row_to_json(j) FROM ( SELECT top.o_id, o.name, top.a_ct, top.a_by_tax FROM( SELECT lu.organization_id as o_id,  count(DISTINCT lu.activity_id) as a_ct ' ||
			',(SELECT array_to_json(array_agg(row_to_json(b))) FROM (SELECT classification_id as c_id, count(distinct activity_id) AS a_ct ' ||
			'FROM taxonomy_lookup WHERE taxonomy_id = ' || $1 || ' AND organization_id = lu.organization_id  AND activity_id = ANY(array_agg(DISTINCT lu.activity_id)) GROUP BY classification_id ) b ) as a_by_tax ' ||
			'FROM organization_lookup lu ' ||
			'WHERE (classification_ids @> ARRAY[(select classification_id from classification where taxonomy_id = (select taxonomy_id from taxonomy where name = ''Organisation Role'') AND iati_name = ''Accountable'')]) ';
   IF where_statement IS NOT NULL THEN 	execute_statement := execute_statement || ' AND ' || where_statement;  END IF;			
   execute_statement :=  execute_statement || 'GROUP BY lu.organization_id ORDER BY a_ct desc LIMIT 10 ) as top JOIN organization o ON top.o_id = o.organization_id ) as j';

   RAISE NOTICE 'Execute statement: %', execute_statement;
   FOR rec IN EXECUTE execute_statement LOOP
     RETURN NEXT rec; 
   END LOOP;
   
END IF; -- must have valid taxonomy   	
END;$$ LANGUAGE plpgsql;
/******************************************************************
  pmt_stat_orgs_by_district
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_stat_orgs_by_district(data_group_id integer, country character varying, region character varying, org_role_id integer, top_limit integer)
RETURNS SETOF pmt_json_result_type AS $$
DECLARE
  limit_by integer;
  org_c_id integer;
  valid_data_group_id integer;
  execute_statement text;
  rec record;
BEGIN
-- country & region is required
IF ($2 IS NOT NULL AND $2 <> '') AND ($3 IS NOT NULL AND $3 <> '') THEN

   -- validate data group id
   IF $1 IS NOT NULL THEN
	SELECT INTO valid_data_group_id classification_id FROM taxonomy_classifications WHERE taxonomy = 'Data Group' AND classification_id = $1;
   END IF;
   
   -- set default organization role classification to 'Accountable'  
   IF $4 IS NULL THEN
     org_c_id := (select classification_id from taxonomy_classifications where taxonomy = 'Organisation Role' and classification = 'Accountable');
   -- validate classification_id
   ELSE
     select into org_c_id classification_id from taxonomy_classifications where taxonomy = 'Organisation Role' and classification_id = $4;
     IF org_c_id IS NULL THEN
       org_c_id := (select classification_id from taxonomy_classifications where taxonomy = 'Organisation Role' and classification = 'Accountable');
     END IF;
   END IF;

   -- set default limit to 3
   IF $5 IS NULL OR $5 < 1 THEN
     limit_by := 3;
   ELSE
     limit_by := $5;
   END IF;
   
   execute_statement :=  'select row_to_json(j) from (select gaul1_name as region, name as district,(SELECT array_to_json(array_agg(row_to_json(b))) FROM ( ' ||
				'select ol.organization_id as o_id, o.name, count(l.activity_id) as a_ct ' ||
				'from organization_lookup ol ' ||
				'join ' ||
				'(select distinct activity_id, gaul1_name, gaul2_name  ' ||
				'from location_lookup where lower(gaul1_name) = trim(lower('|| quote_literal($3) ||')) and lower(gaul0_name) = trim(lower('|| quote_literal($2) ||'))';

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
			'where lower(gaul1_name) = trim(lower('|| quote_literal($3) ||')) and lower(gaul0_name) = trim(lower('|| quote_literal($2) ||')) order by name) j';

   RAISE NOTICE 'Execute statement: %', execute_statement;
   FOR rec IN EXECUTE execute_statement LOOP
     RETURN NEXT rec; 
   END LOOP;   
END IF;   
END;$$ LANGUAGE plpgsql;
/******************************************************************
  pmt_tax_inuse
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_tax_inuse(data_group_id integer, taxonomy_ids character varying, country_ids character varying) RETURNS SETOF pmt_json_result_type AS 
$$
DECLARE
  valid_classification_id boolean;
  valid_classification_ids int[];
  valid_country_ids int[];
  dynamic_where1 text;
  dynamic_where2 text;
  exectute_statement text;
  data_group_id integer;
  filter_taxids int[];
  rec record;
BEGIN
  -- confirm the passed id is a valid data group
  SELECT INTO data_group_id classification_id FROM taxonomy_classifications WHERE taxonomy = 'Data Group' AND classification_id = $1;

  -- if data group exists validate and filter	
  IF data_group_id IS NOT NULL THEN
    dynamic_where1 := ' where project_id in (select distinct project_id from taxonomy_lookup where classification_id =' || data_group_id || ')';
    dynamic_where2 := ' where project_id in (select distinct project_id from taxonomy_lookup where classification_id =' || data_group_id || ')';
  END IF;
  
  -- if taxonomy_ids exists validate and filter
  IF $2 IS NOT NULL OR $2 <> '' THEN
    SELECT INTO filter_taxids * FROM pmt_validate_taxonomies($2);
    IF filter_taxids IS NOT NULL THEN
      IF dynamic_where2 IS NULL THEN
        dynamic_where2 := ' where taxonomy_id = ANY(ARRAY[' || array_to_string(filter_taxids, ',') || '])';
      ELSE
        dynamic_where2 := dynamic_where2 || ' and taxonomy_id = ANY(ARRAY[' || array_to_string(filter_taxids, ',')  || '])';
      END IF;    
    END IF;
  END IF;

   --  if country_ids exists validate and filter
  IF $3 IS NOT NULL OR $3 <> '' THEN
    SELECT INTO valid_classification_ids * FROM pmt_validate_classifications($3);
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
      IF dynamic_where1 IS NOT NULL THEN
        dynamic_where1 := dynamic_where1 || ' and location_id in (select location_id from taxonomy_lookup where classification_id = ANY(ARRAY[' || array_to_string(valid_country_ids, ',')  || ']))';
      ELSE
        dynamic_where1 := ' where location_id in (select location_id from taxonomy_lookup where classification_id = ANY(ARRAY[' || array_to_string(valid_country_ids, ',')  || ']))';
      END IF;
      IF dynamic_where2 IS NOT NULL THEN
        dynamic_where2 := dynamic_where2 || ' and location_id in (select location_id from taxonomy_lookup where classification_id = ANY(ARRAY[' || array_to_string(valid_country_ids, ',')  || ']))';
      ELSE
        dynamic_where2 := ' where location_id in (select location_id from taxonomy_lookup where classification_id = ANY(ARRAY[' || array_to_string(valid_country_ids, ',')  || ']))';
      END IF;           
    END IF; 
  END IF;
  
  -- prepare statement
  exectute_statement := 'select row_to_json(t) from ( ' ||
	 'select taxonomy.taxonomy_id as t_id, taxonomy.name, taxonomy.is_category as is_cat, taxonomy.category_id as cat_id,( ' ||
	  'select array_to_json(array_agg(row_to_json(c))) ' ||
	   'from ( ' ||
	    'select class_order.classification_id as c_id, c.category_id as cat_id, c.name ' ||
	    'from (select taxonomy_id, classification_id, category_id, count(distinct location_id) as location_count ' ||
	    'from taxonomy_lookup ';
  
  IF dynamic_where1 IS NOT NULL THEN
    exectute_statement := exectute_statement || ' ' || dynamic_where1 || ' ';
  END IF;

  exectute_statement := exectute_statement || ' group by taxonomy_id, classification_id, category_id ' ||
	     ') as class_order ' ||
	    'join classification c ' ||
	    'on class_order.classification_id = c.classification_id ' ||
	    'where class_order.taxonomy_id = taxonomy.taxonomy_id ' ||
	    'order by class_order.location_count desc ' ||
	    ') c ) as classifications ' ||
	'from (select tl.taxonomy_id, t.name, t.is_category, t.category_id ' ||
	'from (select distinct taxonomy_id ' ||   
	'from taxonomy_lookup ';

  IF dynamic_where2 IS NOT NULL THEN
     exectute_statement := exectute_statement || ' ' || dynamic_where2 || ' ';
  END IF;

  exectute_statement := exectute_statement || ') tl join taxonomy t ' ||
	'on tl.taxonomy_id = t.taxonomy_id ' ||
	'order by t.name) as taxonomy ' ||
	') t ';
	
  RAISE NOTICE 'Execute: %', exectute_statement;
  		    
  -- execute statement
  FOR rec IN EXECUTE exectute_statement	    
  LOOP
    RETURN NEXT rec;    
  END LOOP;
END;$$ LANGUAGE plpgsql;
/******************************************************************
  pmt_taxonomies
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_taxonomies(taxonomy_ids character varying) RETURNS SETOF pmt_json_result_type AS 
$$
DECLARE
  valid_taxonomy_ids int[];  
  dynamic_where1 text;
  dynamic_where2 text;
  exectute_statement text;
  data_group_id integer;
  filter_taxids int[];
  rec record;
BEGIN	 
  
  -- if taxonomy_ids exists validate and filter
  IF $1 IS NOT NULL OR $1 <> '' THEN
    SELECT INTO valid_taxonomy_ids * FROM pmt_validate_taxonomies($1);
    IF valid_taxonomy_ids IS NOT NULL THEN
       -- get categories/sub-categories of related taxonomies
       SELECT INTO filter_taxids array_agg(taxonomy_id)::INT[] FROM taxonomy WHERE taxonomy_id = ANY(valid_taxonomy_ids) OR category_id = ANY(valid_taxonomy_ids) AND active = true;
      dynamic_where1 := ' where taxonomy_id = ANY(ARRAY[' || array_to_string(filter_taxids, ',') || '])';  
      dynamic_where2 := ' where taxonomy_id = ANY(ARRAY[' || array_to_string(filter_taxids, ',') || '])';  
    END IF;
  END IF;
  
  -- prepare statement
  exectute_statement := 'select row_to_json(t) from ( ' ||
	 'select taxonomy.taxonomy_id as t_id, taxonomy.taxonomy as name, taxonomy.is_category as is_cat, taxonomy.taxonomy_category_id as cat_id, ( ' ||
	  'select array_to_json(array_agg(row_to_json(c))) ' ||
	   'from ( ' ||
	    'select class_order.classification_id as c_id, class_order.cat_id, class_order.classification as name ' ||
	    'from (select taxonomy_id, classification_id, classification, classification_category_id as cat_id ' ||
	    'from taxonomy_classifications ';
  
  IF dynamic_where1 IS NOT NULL THEN
    exectute_statement := exectute_statement || ' ' || dynamic_where1 || ' ';
  END IF;

  exectute_statement := exectute_statement || ' group by taxonomy_id, classification_id, classification, classification_category_id  ' ||
	     ') as class_order ' ||
	    'where class_order.taxonomy_id = taxonomy.taxonomy_id ' ||
	    ') c ) as classifications ' ||
	'from (select DISTINCT taxonomy_id, taxonomy, is_category, taxonomy_category_id ' ||  
	'from taxonomy_classifications ';

  IF dynamic_where2 IS NOT NULL THEN
     exectute_statement := exectute_statement || ' ' || dynamic_where2 || ' ';
  END IF;

  exectute_statement := exectute_statement || 'order by taxonomy) as taxonomy ' ||
	') t ';
	
  --RAISE NOTICE 'Execute: %', exectute_statement;
  		    
  -- execute statement
  FOR rec IN EXECUTE exectute_statement	    
  LOOP
    RETURN NEXT rec;    
  END LOOP;
END;$$ LANGUAGE plpgsql;
/******************************************************************
  pmt_user_auth
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_user_auth(username character varying(255), password character varying(255)) RETURNS 
SETOF pmt_json_result_type AS $$
DECLARE 
  valid_user_id integer;
  authorization_source auth_source;
  valid_data_group_id integer;
  user_organization_id integer;
  user_data_group_id integer;  
  authorized_project_ids integer[];
  role_super boolean;	
  rec record;
BEGIN 
  SELECT INTO valid_user_id "user".user_id FROM "user" WHERE "user".username = $1 AND "user".password = $2;
  IF valid_user_id IS NOT NULL THEN
    -- determine editing authorization source
    SELECT INTO authorization_source edit_auth_source from config LIMIT 1;	
    CASE authorization_source
       -- authorization determined by organization affiliation
        WHEN 'organization' THEN
         -- get users organization_id
         SELECT INTO user_organization_id organization_id FROM "user" WHERE "user".user_id = valid_user_id;   
	 -- validate users organization_id	
         IF (SELECT * FROM pmt_validate_organization(user_organization_id)) THEN
           -- get list of project_ids user has authority to edit
           SELECT INTO authorized_project_ids array_agg(DISTINCT p.project_id)::int[] FROM participation_taxonomy pt JOIN participation p ON pt.participation_id = p.participation_id
           WHERE p.organization_id = user_organization_id AND pt.classification_id IN (SELECT classification_id FROM taxonomy_classifications WHERE taxonomy = 'Organisation Role' and classification = 'Accountable');
         END IF;
       -- authorization determined by data group affiliation
       WHEN 'data_group' THEN
         -- get users data_group_id
         SELECT INTO user_data_group_id data_group_id FROM "user" WHERE "user".user_id = valid_user_id;  
         -- validate users data_group_id
	 SELECT INTO valid_data_group_id classification_id::integer FROM taxonomy_classifications WHERE classification_id = user_data_group_id AND taxonomy = 'Data Group';
	 IF (valid_data_group_id IS NOT NULL) THEN
           -- get list of project_ids user has authority to edit
           SELECT INTO authorized_project_ids array_agg(DISTINCT pt.project_id)::int[] FROM project_taxonomy pt 
           WHERE pt.classification_id IN (SELECT classification_id FROM taxonomy_classifications WHERE taxonomy = 'Data Group' and classification_id = user_data_group_id);          
         END IF;
       ELSE
    END CASE;

    -- check to see if user has a role with "SUPER" rights (if so they have full adminsitrative editing rights to the database)
    SELECT INTO role_super super FROM role WHERE role_id = (SELECT role_id FROM user_role WHERE user_role.user_id = valid_user_id);
    IF role_super THEN
      -- if super user than all project ids are authorized
      SELECT INTO authorized_project_ids array_agg(DISTINCT p.project_id)::int[] FROM project p;
    END IF;
    
    FOR rec IN (SELECT row_to_json(j) FROM( 
	SELECT user_id, first_name, last_name, "user".username, email, "user".organization_id
	,(SELECT name FROM organization WHERE organization_id = "user".organization_id) as organization, "user".data_group_id
	,(SELECT classification FROM taxonomy_classifications WHERE classification_id = "user".data_group_id) as data_group
	,array_to_string(authorized_project_ids, ',') as authorized_project_ids
	,(SELECT array_to_json(array_agg(row_to_json(r))) FROM ( SELECT r.role_id, r.name FROM role r 
	JOIN user_role ur ON r.role_id = ur.role_id WHERE ur.user_id = "user".user_id) r ) as roles 
	FROM "user" WHERE "user".user_id = valid_user_id
      ) j ) LOOP		
        RETURN NEXT rec;
    END LOOP;
    -- log user activity
    INSERT INTO user_activity(user_id, username, status) VALUES (valid_user_id, $1, 'success');		  
  ELSE
    FOR rec IN (SELECT row_to_json(j) FROM( SELECT 'Invalid username or password.' AS message ) j ) LOOP		
        RETURN NEXT rec;
    END LOOP;	
    -- log user activity
    INSERT INTO user_activity(username, status) VALUES ($1, 'fail');		  
  END IF;
END; 
$$ LANGUAGE 'plpgsql';
/******************************************************************
  pmt_users
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_users() RETURNS SETOF pmt_json_result_type AS $$
DECLARE 
  rec record;
BEGIN 
  FOR rec IN (SELECT row_to_json(j) FROM( SELECT u.user_id, u.first_name, u.last_name, u.username, u.email, u.organization_id
	, (SELECT name FROM organization WHERE organization_id = u.organization_id) as organization, u.data_group_id
	, (SELECT classification FROM taxonomy_classifications WHERE classification_id = u.data_group_id) as data_group, (
	SELECT array_to_json(array_agg(row_to_json(r))) FROM ( SELECT role_id, name FROM role WHERE role_id = ur.role_id) r ) as roles
    FROM "user" u LEFT JOIN user_role ur ON u.user_id = ur.user_id JOIN role r ON ur.role_id = r.role_id
    ) j ) LOOP		
    RETURN NEXT rec;
  END LOOP;			  
END; 
$$ LANGUAGE 'plpgsql';

-- update permissions
GRANT USAGE ON SCHEMA public TO pmt_read;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO pmt_read;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO pmt_read;
GRANT USAGE ON SCHEMA public TO pmt_write;
GRANT SELECT,INSERT ON ALL TABLES IN SCHEMA public TO pmt_write;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO pmt_write;