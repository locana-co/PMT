/******************************************************************
Change Script 3.0.10.15
1. optimize filter views
2. add new filter view to support unassigned taxonomies
3. update pmt_filter function to add unassigned taxonomy filter
4. update pmt_locations_for_boundaries to add unassigned taxonomy filter
5. update pmt_activity_ids_by_boundary to add unassigned taxonomy filter
6. update pmt_partner_sankey to add unassigned taxonomy filter
7. update pmt_activity_count to add unassigned taxonomy filter
******************************************************************/
INSERT INTO version(_version, _iteration, _changeset) VALUES (3.0, 10, 15);
-- select * from version order by _iteration desc, _changeset desc;

/******************************************************************
 1. optimize filter views
******************************************************************/
-- filter view for boundaries
DROP VIEW IF EXISTS _filter_boundaries;
CREATE OR REPLACE VIEW _filter_boundaries AS 
SELECT a.id as activity_id, a.data_group_id, l.id as location_id, lb.feature_id, lb.boundary_id
  FROM (SELECT id, data_group_id FROM activity WHERE _active = true) a
  LEFT JOIN (SELECT id, activity_id FROM location WHERE _active = true) l
  ON a.id = l.activity_id
  LEFT JOIN location_boundary lb 
  ON l.id = lb.location_id;  
-- filter view for taxonomies
DROP VIEW IF EXISTS _filter_taxonomies;
CREATE OR REPLACE VIEW _filter_taxonomies AS
SELECT a.id as activity_id, a.data_group_id, l.id as location_id, c.taxonomy_id, at.classification_id
  FROM (SELECT id, data_group_id FROM activity WHERE _active = true) a
  LEFT JOIN (SELECT id, activity_id FROM location WHERE _active = true) l
  ON a.id = l.activity_id
  LEFT JOIN activity_taxonomy at
  ON a.id = at.activity_id
  LEFT JOIN (SELECT id, taxonomy_id FROM classification WHERE _active = true) c
  ON at.classification_id = c.id
  UNION ALL
  SELECT a.id, a.data_group_id, l.id, c.taxonomy_id, lt.classification_id
  FROM (SELECT id, data_group_id FROM activity WHERE _active = true) a
  LEFT JOIN (SELECT id, activity_id FROM location WHERE _active = true) l
  ON a.id = l.activity_id
  LEFT JOIN location_taxonomy lt
  ON l.id = lt.location_id
  LEFT JOIN (SELECT id, taxonomy_id FROM classification WHERE _active = true) c
  ON lt.classification_id = c.id;
-- filter view for organizations 
 DROP VIEW IF EXISTS _filter_organizations;
 CREATE OR REPLACE VIEW _filter_organizations AS 
  SELECT a.id as activity_id, a.data_group_id, tc.classification as role, array_agg(p.organization_id) as organization_ids
  FROM (SELECT id, data_group_id FROM activity WHERE _active = true) a
  LEFT JOIN (SELECT id, organization_id, activity_id FROM participation WHERE _active = true) p
  ON a.id = p.activity_id
  LEFT JOIN participation_taxonomy pt
  ON p.id = pt.participation_id
  LEFT JOIN _taxonomy_classifications tc
  ON pt.classification_id = tc.classification_id
  GROUP BY 1,2,3
  ORDER BY 1;  

/******************************************************************
 2. add new filter view to support unassigned taxonomies
******************************************************************/
-- filter view for unassigned taxonomies
DROP VIEW IF EXISTS _filter_unassigned;
CREATE OR REPLACE VIEW _filter_unassigned AS
SELECT activity_id, data_group_id, assigned, (SELECT array_agg(id) FROM taxonomy WHERE id <> ALL(assigned)) as unassigned FROM 
(SELECT activity_id, data_group_id, array_agg(taxonomy_id) as assigned FROM (
        SELECT a.id as activity_id, a.data_group_id, l.id as location_id, t.taxonomy_id FROM
	(
		SELECT id, data_group_id 
		FROM activity 
		WHERE _active = true
	) a
	LEFT JOIN
	(
		SELECT id, activity_id 
		FROM location 
		WHERE _active = true
	) l
	ON a.id = l.activity_id
	LEFT JOIN 
	(
		SELECT DISTINCT at.activity_id, tc.taxonomy_id 
		FROM activity_taxonomy at
		JOIN _taxonomy_classifications tc
		ON at.classification_id = tc.classification_id
	) t
	ON a.id = t.activity_id
	UNION ALL
	SELECT a.id as activity_id, a.data_group_id, l.id as location_id, t.taxonomy_id FROM
	(
		SELECT id, data_group_id 
		FROM activity 
		WHERE _active = true
	) a
	LEFT JOIN
	(
		SELECT id, activity_id 
		FROM location 
		WHERE _active = true
	) l
	ON a.id = l.activity_id
	LEFT JOIN 
	(
		SELECT DISTINCT lt.location_id, tc.taxonomy_id 
		FROM location_taxonomy lt
		JOIN _taxonomy_classifications tc
		ON lt.classification_id = tc.classification_id
	) t
	ON l.id = t.location_id	
) as at
GROUP BY 1,2) as a;

/*************************************************************************
  3. create pmt_filter function to add unassigned taxonomy filter
     select * from pmt_filter('768','816,819','13','','','1/1/2012','12/31/2018','22');
     select * from pmt_filter(null,null,null,null,null,null,null,null);
*************************************************************************/
-- drop old function 
DROP FUNCTION IF EXISTS pmt_filter(character varying, character varying, character varying, character varying, character varying, date, date);
-- create new function with new parameter
CREATE OR REPLACE FUNCTION pmt_filter(data_group_ids character varying, classification_ids character varying, org_ids character varying,
imp_org_ids character varying, fund_org_ids character varying, start_date date, end_date date, unassigned_taxonomy_ids character varying) RETURNS integer[] AS 
$$
DECLARE 
  execute_statement text;
  org_statement text;
  tax_statement text;
  activity_statement text;
  dg_ids int[];
  c_ids int[];
  imp_ids int[];
  fund_ids int[];
  o_ids int[];
  t_ids int[];
  valid_dg_ids int[];  
  valid_c_ids int[];  
  valid_imp_ids int[];  
  valid_fund_ids int[]; 
  valid_o_ids int[];
  valid_t_ids int[];
  dg_where text;
  org_where text[];
  tax_where text[];
  date_where text[];
  unassigned_where text;
  cls record;
  activities_id int[];
  error_msg text;
BEGIN 

  -- validate and process data_group_ids parameter
  IF $1 IS NOT NULL THEN
    dg_ids:= string_to_array($1, ',')::int[];
    -- validate the data groups id
    SELECT INTO valid_dg_ids array_agg(id)::int[] FROM classification WHERE taxonomy_id = 1 AND _active=true AND id = ANY(dg_ids);
  END IF;
  -- validate and process classification_ids parameter
  IF $2 IS NOT NULL THEN
    c_ids:= string_to_array($2, ',')::int[];
    -- validate the classification ids
    SELECT INTO valid_c_ids array_agg(id)::int[] FROM classification WHERE _active=true AND id = ANY(c_ids);
  END IF;
  -- validate and process org_ids parameter
  IF $3 IS NOT NULL THEN
    o_ids:= string_to_array($3, ',')::int[];
    -- validate the org ids
    SELECT INTO valid_o_ids array_agg(id)::int[] FROM organization WHERE _active=true AND id = ANY(o_ids);
  END IF;
  -- validate and process imp_org_ids parameter
  IF $4 IS NOT NULL THEN
    imp_ids:= string_to_array($4, ',')::int[];
    -- validate the org ids
    SELECT INTO valid_imp_ids array_agg(id)::int[] FROM organization WHERE _active=true AND id = ANY(imp_ids);
  END IF;
  -- validate and process fund_org_ids parameter
  IF $5 IS NOT NULL THEN
    fund_ids:= string_to_array($5, ',')::int[];
    -- validate the org ids
    SELECT INTO valid_fund_ids array_agg(id)::int[] FROM organization WHERE _active=true AND id = ANY(fund_ids);
  END IF;
  -- validate and process unassigned_taxonomy_ids parameter
  IF $8 IS NOT NULL THEN
    t_ids:= string_to_array($8, ',')::int[];
    -- validate the taxonomy ids
    SELECT INTO valid_t_ids array_agg(id)::int[] FROM taxonomy WHERE _active=true AND id = ANY(t_ids);
  END IF;
  
  -- restrict returned results by data group id(s)
  IF array_length(valid_dg_ids, 1) > 0 THEN
    dg_where := 'data_group_id = ANY(ARRAY[' || array_to_string(valid_dg_ids, ',') || ']) ';
  END IF;
  -- restrict returned results by classification id(s)
  IF array_length(valid_c_ids, 1) > 0 THEN
    FOR cls IN EXECUTE 'SELECT taxonomy_id, array_agg(id) as c FROM classification WHERE _active = true AND id = ANY(ARRAY[' || array_to_string(valid_c_ids, ',') || ']) GROUP BY 1 ORDER BY 1' LOOP
      tax_where := array_append(tax_where, '(taxonomy_id = ' || cls.taxonomy_id || ' AND classification_id = ANY(ARRAY[' || array_to_string(cls.c, ',') || ']))');
    END LOOP;
  END IF;
  -- restrict returned results by org id(s)
  IF array_length(valid_o_ids, 1) > 0 THEN
    org_where := array_append(org_where, '(organization_ids && ARRAY[' || array_to_string(valid_o_ids, ',') || '])');
  END IF;
  -- restrict returned results by implmenting org id(s)
  IF array_length(valid_imp_ids, 1) > 0 THEN
    org_where := array_append(org_where, '(organization_ids && ARRAY[' || array_to_string(valid_imp_ids, ',') || '] AND role = ''Implementing'')');
  END IF;
  -- restrict returned results by funding org id(s)
  IF array_length(valid_fund_ids, 1) > 0 THEN
    org_where := array_append(org_where, '(organization_ids && ARRAY[' || array_to_string(valid_fund_ids, ',') || '] AND role = ''Funding'')');
  END IF;
  -- restrict returned results by start date
  IF $6 IS NOT NULL THEN
    date_where := array_append(date_where, '_start_date >= ' || quote_literal($6));
  END IF;
  -- restrict returned results by end date
  IF $7 IS NOT NULL THEN
    date_where := array_append(date_where, '_end_date <= ' || quote_literal($7));
  END IF;
  -- restrict returned results by unassigned taxonomy id(s)
  IF array_length(valid_t_ids, 1) > 0 THEN
    unassigned_where := 'unassigned @> ARRAY[' || array_to_string(valid_t_ids, ',') || '] ';
  END IF;

  -- RAISE NOTICE 'Data group where statement: %', dg_where;
  -- RAISE NOTICE 'Classification where statement: %', tax_where;
  -- RAISE NOTICE 'Organization where statement: %', org_where;
  -- RAISE NOTICE 'Date where statement: %', date_where;

  -- prepare _filter_taxonomies statement
  IF array_length(tax_where, 1) > 0 THEN
    tax_statement := 'SELECT DISTINCT activity_id FROM _filter_taxonomies WHERE (' || array_to_string(tax_where, ' AND ') || ') ';
  END IF;
  -- prepare _filter_organizations statement
  IF array_length(org_where, 1) > 0 THEN
    org_statement := 'SELECT DISTINCT activity_id FROM _filter_organizations WHERE (' || array_to_string(org_where, ' AND ') || ') ';
  END IF;
  -- prepare activity statement
  activity_statement:= 'SELECT DISTINCT id as activity_id FROM activity WHERE _active = true ';
  IF array_length(date_where, 1) > 0 THEN
    activity_statement := activity_statement || 'AND (' || array_to_string(date_where, ' AND ') || ') ';
  END IF;
  IF dg_where IS NOT NULL THEN
    activity_statement := activity_statement || 'AND (' || dg_where || ') ';
  END IF;   

  -- build execution statement
  execute_statement := 'SELECT array_agg(DISTINCT activity_id)::int[] as activities FROM ( ';
  -- RAISE NOTICE 'Execute statement begins: %', execute_statement;
  -- two filters, requires a join
  IF tax_statement IS NOT NULL AND org_statement IS NOT NULL THEN
    execute_statement := execute_statement || 'SELECT activity_id, count(*) ct FROM ( ' || tax_statement || ' UNION ALL ' || org_statement ||
	') a GROUP BY 1 ';
    -- add the unassigned taxonomy filter if needed
    IF unassigned_where IS NOT NULL THEN
      execute_statement := execute_statement || 'UNION ALL SELECT activity_id, 2 FROM _filter_unassigned WHERE ' || unassigned_where || ' ';
    END IF;  
    execute_statement := execute_statement || ') a WHERE ct > 1 AND activity_id IN ( ' || activity_statement || ' )';     	
    RAISE NOTICE 'Execute statement (two filters): %', execute_statement;
  ELSE
    -- one filter
    IF tax_statement IS NOT NULL OR org_statement IS NOT NULL THEN
      IF tax_statement IS NOT NULL THEN
        execute_statement := execute_statement || tax_statement;
      END IF;
      IF org_statement IS NOT NULL THEN
        execute_statement := execute_statement || org_statement;
      END IF;
      -- add the unassigned taxonomy filter if needed
      IF unassigned_where IS NOT NULL THEN
        execute_statement := execute_statement || 'UNION ALL SELECT activity_id FROM _filter_unassigned WHERE ' || unassigned_where;
      END IF; 
      execute_statement := execute_statement ||  ') a WHERE activity_id IN ( ' || activity_statement || ' )';
      RAISE NOTICE 'Execute statement (one filter): %', execute_statement;
    END IF;
  END IF;
  
  -- no filters
  IF tax_statement IS NULL AND org_statement IS NULL THEN
    -- add the unassigned taxonomy filter if needed
    IF unassigned_where IS NOT NULL THEN
      execute_statement := execute_statement || 'SELECT activity_id FROM _filter_unassigned WHERE ' || unassigned_where || 
      ') a WHERE activity_id IN ( ' || activity_statement || ' )';
    ELSE
      execute_statement := execute_statement || activity_statement || ' ) as a'; 
    END IF;     
    RAISE NOTICE 'Execute statement (no filters): %', execute_statement;   
  END IF;
  
  RAISE NOTICE 'Execute statement: %', execute_statement;
  EXECUTE execute_statement INTO activities_id;
  RETURN activities_id;

EXCEPTION WHEN others THEN 
  GET STACKED DIAGNOSTICS error_msg = MESSAGE_TEXT;  
    RAISE NOTICE 'Internal Error - Contact your DBA with the following error message: %', error_msg;
    	
END;$$ LANGUAGE plpgsql;


 /******************************************************************
4. update pmt_locations_for_boundaries to add unassigned taxonomy filter
  SELECT * FROM pmt_locations_for_boundaries(8,'768','816,819','13','','1/1/2012','12/31/2018','22'); --bmgf
******************************************************************/
DROP FUNCTION IF EXISTS pmt_locations_for_boundaries(integer, character varying, character varying, character varying, character varying, date, date);
CREATE OR REPLACE FUNCTION pmt_locations_for_boundaries(boundary_id integer, data_group_ids character varying,
  classification_ids character varying, imp_org_ids character varying, fund_org_ids character varying, start_date date, end_date date,
  unassigned_taxonomy_ids character varying)
RETURNS SETOF pmt_json_result_type AS 
$$
DECLARE
  valid_boundary_id integer; 
  execute_statement text;
  filtered_activity_ids int[]; 
  rec record;
  error_msg text;
BEGIN  
  -- validate and process boundary_id parameter
  IF $1 IS NOT NULL THEN
    SELECT INTO valid_boundary_id id FROM boundary WHERE id = $1;    
    -- exit if boundary id is not valid
    IF valid_boundary_id IS NULL THEN 
       FOR rec IN SELECT row_to_json(j) FROM( SELECT 'invalid parameter' AS error ) as j
	LOOP
        RETURN NEXT rec;    
       END LOOP;
    END IF;
  ELSE
    FOR rec IN SELECT row_to_json(j) FROM( SELECT 'missing required parameter' AS error ) as j
    LOOP
      RETURN NEXT rec;    
    END LOOP;    
  END IF;

  -- get the filtered activity ids
  SELECT INTO filtered_activity_ids * FROM pmt_filter($2,$3,null,$4,$5,$6,$7,$8);

  -- prepare the execution statement
  execute_statement:= 'SELECT feature_id as id, count(distinct activity_id) as a, count(distinct location_id) as l, boundary_id as b FROM _filter_boundaries ' ||
		'WHERE activity_id = ANY(ARRAY[' || array_to_string(filtered_activity_ids, ',') || ']) AND boundary_id = ' || valid_boundary_id || ' GROUP BY 1,4';

  RAISE NOTICE 'Execute statement: %', execute_statement;			

  FOR rec IN EXECUTE 'SELECT row_to_json(j) FROM (' || execute_statement || ')j' LOOP  		
	RETURN NEXT rec;
  END LOOP;

EXCEPTION WHEN others THEN 
  GET STACKED DIAGNOSTICS error_msg = MESSAGE_TEXT;  
    RAISE NOTICE 'Internal Error - Contact your DBA with the following error message: %', error_msg;

END;$$ LANGUAGE plpgsql;

/******************************************************************
5. update pmt_activity_ids_by_boundary to add unassigned taxonomy filter
  SELECT * FROM pmt_activity_ids_by_boundary(8, 4,'768','816,819','13','','1/1/2012','12/31/2018','22'); --bmgf
******************************************************************/
DROP FUNCTION IF EXISTS pmt_activity_ids_by_boundary(integer, integer, character varying, character varying, character varying, character varying,date,date);
CREATE OR REPLACE FUNCTION pmt_activity_ids_by_boundary(boundary_id integer, feature_id integer, data_group_ids character varying, 
classification_ids character varying, imp_org_ids character varying, fund_org_ids character varying, start_date date, end_date date,
unassigned_taxonomy_ids character varying)
RETURNS SETOF pmt_json_result_type AS 
$$
DECLARE
  valid_boundary_id integer;
  execute_statement text;
  filtered_activity_ids int[]; 
  rec record;
  error_msg text;
BEGIN  
  -- validate and process boundary_id parameter
  IF $1 IS NOT NULL AND $2 IS NOT NULL THEN
    SELECT INTO valid_boundary_id id FROM boundary WHERE id = $1;    
    -- exit if boundary id is not valid
    IF valid_boundary_id IS NULL THEN 
       FOR rec IN SELECT row_to_json(j) FROM( SELECT 'invalid parameter' AS error ) as j
	LOOP
        RETURN NEXT rec;    
       END LOOP;
    END IF;
  ELSE
    FOR rec IN SELECT row_to_json(j) FROM( SELECT 'missing required parameter' AS error ) as j
    LOOP
      RETURN NEXT rec;    
    END LOOP;    
  END IF;

  -- get the filtered activity ids
  SELECT INTO filtered_activity_ids * FROM pmt_filter($3,$4,null,$5,$6,$7,$8,$9);
  
  -- prepare the execution statement
  execute_statement:= 'SELECT id, _title FROM activity WHERE ARRAY[id] <@ ( SELECT array_agg(DISTINCT activity_id) FROM _filter_boundaries ' ||
		'WHERE activity_id = ANY(ARRAY[' || array_to_string(filtered_activity_ids, ',') || ']) AND boundary_id = ' || valid_boundary_id || ' AND feature_id = ' || $2;
 
  RAISE NOTICE 'Execute statement: %', execute_statement;			

  FOR rec IN EXECUTE 'SELECT row_to_json(j) FROM (' || execute_statement || '))j' LOOP  		
	RETURN NEXT rec;
  END LOOP;
  
EXCEPTION WHEN others THEN 
  GET STACKED DIAGNOSTICS error_msg = MESSAGE_TEXT;  
    RAISE NOTICE 'Internal Error - Contact your DBA with the following error message: %', error_msg;
     
END;$$ LANGUAGE plpgsql;

/*************************************************************************
  6. update pmt_partner_sankey to add unassigned taxonomy filter
     select * from pmt_partner_sankey(null,null,null,null,null);
     select * from pmt_partner_sankey('768',null,null,null,null);
     select * from pmt_partner_sankey('768','831','','1/1/2012','12/31/2018');
*************************************************************************/
DROP FUNCTION IF EXISTS pmt_partner_sankey(character varying, character varying, character varying, date, date);
CREATE OR REPLACE FUNCTION pmt_partner_sankey(data_group_ids character varying, classification_ids character varying, 
organization_ids character varying, start_date date, end_date date, unassigned_taxonomy_ids character varying)
RETURNS SETOF pmt_json_result_type AS 
$$
DECLARE
  filtered_activity_ids int[];
  execute_statement text;
  rec record;
  error_msg text;
BEGIN	

  RAISE NOTICE 'Beginning execution of the pmt_partner_sankey function...';
  
  -- get the filtered activity ids
  SELECT INTO filtered_activity_ids * FROM pmt_filter($1,$2,$3,null,null,$4,$5,$6);

  -- prepare the execution statement
  execute_statement := 'SELECT row_to_json(sankey.*) AS sankey ' ||
				'FROM (	' ||
				'SELECT (SELECT array_to_json(array_agg(row_to_json(nodejson.*))) AS array_to_json FROM ' ||
					-- node query
					'(SELECT DISTINCT name, node, level FROM _partnerlink_sankey_nodes ' ||
					'WHERE activity_id = ANY(ARRAY[' || array_to_string(filtered_activity_ids, ',') || '])' ||
					'ORDER BY 2 ) AS nodejson ' ||
				') as nodes' ||
				', (SELECT array_to_json(array_agg(row_to_json(linkjson.*))) AS array_to_json FROM (  ' ||
					-- link query
					'SELECT source, source_level, target, target_level, link, COUNT(activity_id) as value ' ||
					'FROM _partnerlink_sankey_links ' ||
					'WHERE activity_id = ANY(ARRAY[' || array_to_string(filtered_activity_ids, ',') || '])' ||			
					'GROUP BY 1,2,3,4,5 ORDER BY 2, 6 DESC ' ||            
				') linkjson) AS links ' ||
			') sankey;';
					
  -- execute statement		
  RAISE NOTICE 'execute: %', execute_statement;			  

  FOR rec IN EXECUTE execute_statement LOOP
    RETURN NEXT rec;
  END LOOP;

EXCEPTION WHEN others THEN 
  GET STACKED DIAGNOSTICS error_msg = MESSAGE_TEXT;  
    RAISE NOTICE 'Internal Error - Contact your DBA with the following error message: %', error_msg;
	
END;$$ LANGUAGE plpgsql; 

-- Specifies the amount of memory to be used by internal sort operations and hash tables before writing to temporary disk files
ALTER FUNCTION pmt_partner_sankey(character varying, character varying, character varying, date, date, character varying) SET work_mem = '6MB';


 /******************************************************************
7. update pmt_activity_count to add unassigned taxonomy filter
  SELECT * FROM pmt_activity_count('768','2212,831','1681','','1/1/2012','12/31/2018',null); --bmgf
******************************************************************/
DROP FUNCTION IF EXISTS pmt_activity_count(character varying, character varying, character varying, character varying, date, date);
CREATE OR REPLACE FUNCTION pmt_activity_count(data_group_ids character varying, classification_ids character varying, 
imp_org_ids character varying, fund_org_ids character varying, start_date date, end_date date, unassigned_taxonomy_ids character varying)
RETURNS SETOF pmt_json_result_type AS 
$$
DECLARE
  execute_statement text;
  filtered_activity_ids int[]; 
  rec record;
  error_msg text;
BEGIN  

  -- get the filtered activity ids
  SELECT INTO filtered_activity_ids * FROM pmt_filter($1,$2,null,$3,$4,$5,$6,$7);

  -- prepare the execution statement
  execute_statement:= 'SELECT CASE WHEN count(distinct location_id) > 0 THEN count(distinct activity_id) ELSE 0 END as ct FROM _filter_boundaries ' ||
		'WHERE activity_id = ANY(ARRAY[' || array_to_string(filtered_activity_ids, ',') || '])';

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