/******************************************************************
Change Script 2.0.8.76
1. activity_participants - new view listing activity participants and role
2. partnerlink_sankey_nodes - new materialized view to support partnerlink
3. partnerlink_sankey_links - new materialized view to support partnerlink
4. pmt_partner_sankey - d3 sankey partner link fiterable function
******************************************************************/
INSERT INTO version(version, iteration, changeset) VALUES (2.0, 8, 76);
-- select * from version order by changeset desc;

/******************************************************************
  Testing/Validation

  vacuum
  analyze
  
  select * from activity_participants;
  select * from partnerlink_sankey_nodes;			      
  select * from partnerlink_sankey_links;

  select * from taxonomy_classifications;

  select * from pmt_partner_sankey('','','',null,null); --2.7s
  -- tanzania
  select * from pmt_partner_sankey('244','','',null,null); --1.7s
  -- bmgf, tanzania
  select * from pmt_partner_sankey('768,244','','',null,null); --.9s
  -- agra, bmgf (org)
  select * from pmt_partner_sankey('768','13','',null,null); --1.8s
  -- date range
  select * from pmt_partner_sankey('768','13','','1-1-2010','12-31-2010'); --.2s

******************************************************************/

/******************************************************************
  activity_participants
******************************************************************/
DROP VIEW IF EXISTS activity_participants CASCADE;

CREATE OR REPLACE VIEW activity_participants AS 
SELECT distinct * FROM (	
select
a.activity_id
,a.title
,CASE WHEN fund.organization_id IS NULL THEN 1 ELSE fund.organization_id END as fund_id
,CASE WHEN fund.name IS NULL OR fund.name = '' THEN 'Funder Not Reported' ELSE fund.name END as fund_name
,CASE WHEN acct.organization_id IS NULL THEN 2 ELSE acct.organization_id END as acct_id
,CASE WHEN acct.name IS NULL OR acct.name = '' THEN 'Grantee Not Reported' ELSE acct.name END as acct_name
,CASE WHEN impl.organization_id IS NULL THEN 3 ELSE impl.organization_id END as impl_id
,CASE WHEN impl.name IS NULL OR impl.name = '' THEN 'Partner Not Reported' ELSE impl.name END as impl_name
,(select count(location_id) from location where activity_id = a.activity_id) as loc_ct
from activity a
join project p
on a.project_id = p.project_id
left join
-- Accountable (Grantee)
(select * from
(select p_acct.project_id, a.activity_id, p_acct.organization_id, p_acct.name, p_acct.classification
from 	
(select pp.project_id, pp.activity_id, pp.organization_id, o.name, tc.classification
from participation pp
left join participation_taxonomy ppt
on pp.participation_id = ppt.participation_id
join taxonomy_classifications tc
on ppt.classification_id = tc.classification_id
join organization o
on pp.organization_id = o.organization_id
where pp.active = true and pp.activity_id is null and tc.classification = 'Accountable') p_acct
join
activity a
on p_acct.project_id = a.project_id) as p_acct
union all
select pp.project_id, pp.activity_id, pp.organization_id, o.name, tc.classification
from participation pp
left join participation_taxonomy ppt
on pp.participation_id = ppt.participation_id
join taxonomy_classifications tc
on ppt.classification_id = tc.classification_id
join organization o
on pp.organization_id = o.organization_id
where pp.active = true and pp.activity_id is not null and tc.classification = 'Accountable') as acct
on a.activity_id = acct.activity_id
left join
-- Funding (Funder)
(select * from
(select p_acct.project_id, a.activity_id, p_acct.organization_id, p_acct.name, p_acct.classification
from 	
(select pp.project_id, pp.activity_id, pp.organization_id, o.name, tc.classification
from participation pp
left join participation_taxonomy ppt
on pp.participation_id = ppt.participation_id
join taxonomy_classifications tc
on ppt.classification_id = tc.classification_id
join organization o
on pp.organization_id = o.organization_id
where pp.active = true and pp.activity_id is null and tc.classification = 'Funding') p_acct
join
activity a
on p_acct.project_id = a.project_id) as p_acct
union all
select pp.project_id, pp.activity_id, pp.organization_id, o.name, tc.classification
from participation pp
left join participation_taxonomy ppt
on pp.participation_id = ppt.participation_id
join taxonomy_classifications tc
on ppt.classification_id = tc.classification_id
join organization o
on pp.organization_id = o.organization_id
where pp.active = true and pp.activity_id is not null and tc.classification = 'Funding') as fund
on a.activity_id = fund.activity_id
left join
-- Implementing (Partner)
(select * from
(select p_acct.project_id, a.activity_id, p_acct.organization_id, p_acct.name, p_acct.classification
from 	
(select pp.project_id, pp.activity_id, pp.organization_id, o.name, tc.classification
from participation pp
left join participation_taxonomy ppt
on pp.participation_id = ppt.participation_id
join taxonomy_classifications tc
on ppt.classification_id = tc.classification_id
join organization o
on pp.organization_id = o.organization_id
where pp.active = true and pp.activity_id is null and tc.classification = 'Implementing') p_acct
join
activity a
on p_acct.project_id = a.project_id) as p_acct
union all
select pp.project_id, pp.activity_id, pp.organization_id, o.name, tc.classification
from participation pp
left join participation_taxonomy ppt
on pp.participation_id = ppt.participation_id
join taxonomy_classifications tc
on ppt.classification_id = tc.classification_id
join organization o
on pp.organization_id = o.organization_id
where pp.active = true and pp.activity_id is not null and tc.classification = 'Implementing') as impl
on a.activity_id = impl.activity_id
where a.active = true
order by a.project_id, a.activity_id
) as selection;  

/******************************************************************
  partnerlink_sankey_nodes
******************************************************************/
DROP MATERIALIZED VIEW IF EXISTS partnerlink_sankey_nodes CASCADE;

CREATE MATERIALIZED VIEW partnerlink_sankey_nodes AS
SELECT DISTINCT ap.fund_name AS name,
ap.fund_id::numeric AS node,
0 AS level,
ap.activity_id
FROM activity_participants ap
UNION ALL
SELECT DISTINCT ap.acct_name AS name,
ap.acct_id::numeric + 0.1 AS node,
1 AS level,
ap.activity_id
FROM activity_participants ap
UNION ALL
SELECT DISTINCT ap.impl_name AS name,
ap.impl_id::numeric + 0.2 AS node,
2 AS level,
ap.activity_id
FROM activity_participants ap
UNION ALL
SELECT DISTINCT ap.title AS name,
ap.activity_id::numeric + 0.3 AS node,
3 AS level,
ap.activity_id
FROM activity_participants ap
ORDER BY 2; 

-- Materialized view index
CREATE INDEX partnerlink_sankey_nodes_idx on partnerlink_sankey_nodes(name, node, level);
CREATE INDEX partnerlink_sankey_nodes_a_idx on partnerlink_sankey_nodes(name, node ASC, level);
CREATE INDEX partnerlink_sankey_nodes_id_idx on partnerlink_sankey_nodes(activity_id);
CREATE INDEX partnerlink_sankey_nodes_node_idx on partnerlink_sankey_nodes(node);

/******************************************************************
  partnerlink_sankey_links
******************************************************************/
DROP MATERIALIZED VIEW IF EXISTS partnerlink_sankey_links CASCADE;

CREATE MATERIALIZED VIEW partnerlink_sankey_links AS
-- link query
SELECT f_g.f AS source, -- funder (accountable)
0 AS source_level,	-- source node level (0-2)
f_g.g AS target,	-- grantee (funding)
1 AS target_level,	-- target nodel level(1-3)
f_g.link,		-- text representation of relationship (source organization_id + '_' + target organization_id + 0.1)
f_g.activity_id		-- activity_id
FROM ( 
-- funder & grantee
SELECT ap.fund_id AS f,
ap.acct_id::numeric + 0.1 AS g,
(ap.fund_id || '_'::text) || (ap.acct_id::numeric + 0.1) AS link,
ap.activity_id
FROM activity_participants ap
) f_g

UNION ALL
SELECT g_p.g AS source,  -- grantee (funding)
1 AS source_level,	 -- source node level (0-2)
g_p.p AS target_node,	 -- partner (implementing)
2 AS target_level,	 -- target nodel level (1-3)
g_p.link,		 -- text representation of relationship (source organization_id + 1.0 + '_' + target organization_id + 0.2)
g_p.activity_id		 -- activity_id
FROM ( 
-- grantee & partner
SELECT ap.acct_id::numeric + 0.1 AS g,
ap.impl_id::numeric + 0.2 AS p,
((ap.acct_id::numeric + 0.1) || '_'::text) || (ap.impl_id::numeric + 0.2) AS link,
ap.activity_id
FROM activity_participants ap
) g_p
UNION ALL
SELECT p_a.p AS source,  -- partner (implementing)
2 AS source_level,	 -- source node level (0-2) 
p_a.a AS target,    	 -- activity title
3 AS target_level,	 -- target node level (1-3)
p_a.link,		 -- text representation of relationship (source organization_id + 0.2 + '_' + target organization_id + 0.3)
p_a.activity_id		 -- activity_id
FROM ( SELECT ap.impl_id::numeric + 0.2 AS p,
ap.activity_id::numeric + 0.3 AS a,
((ap.impl_id::numeric + 0.2) || '_'::text) || (ap.activity_id::numeric + 0.3) AS link,
ap.activity_id
FROM activity_participants ap
) p_a;

-- Materialized view index
CREATE INDEX partnerlink_sankey_links_id_idx on partnerlink_sankey_links(activity_id);
CREATE INDEX partnerlink_sankey_links_node_idx on partnerlink_sankey_links(source,target);
CREATE INDEX partnerlink_sankey_links_idx on partnerlink_sankey_links(source,source_level,target,target_level,link);
CREATE INDEX partnerlink_sankey_links_sla_idx on partnerlink_sankey_links(source_level,activity_id);


/******************************************************************
  pmt_partner_sankey
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_partner_sankey(classification_ids character varying, organization_ids character varying, unassigned_tax_ids character varying, 
start_date date, end_date date)
RETURNS SETOF pmt_json_result_type AS 
$$
DECLARE
  rec record;
  filter_classids integer array;
  filter_orgids integer array;
  include_taxids integer array;
  dynamic_where1 text array;
  dynamic_where2 text array;
  dynamic_where3 text;
  dynamic_where4 text;
  built_where text array;
  execute_statement text;
  i integer;
BEGIN	
	--RAISE NOTICE 'Beginning execution of the pmt_partner_sankey function...';

	-- Both classification & organization filters are null so get everything
	IF ($1 is null OR $1 = '') AND ($2 is null OR $2 = '') AND ($3 is null OR $3 = '') AND ($4 is null OR $5 is null) THEN
		 execute_statement := 'SELECT row_to_json(sankey.*) AS sankey ' ||
				'FROM (	' ||
				'SELECT (SELECT array_to_json(array_agg(row_to_json(nodejson.*))) AS array_to_json ' ||
				'FROM ( ' ||
					-- node query
					'SELECT DISTINCT n.name ' ||
					',n.node ' ||
					',n.level ' ||
					'FROM partnerlink_sankey_nodes AS n ' ||
					'ORDER BY 2 ) AS nodejson ' ||
				') as nodes, ( ' ||
				'SELECT array_to_json(array_agg(row_to_json(linkjson.*))) AS array_to_json ' ||
				'FROM (  ' ||
				-- link query
				'SELECT l.source ' ||
				',l.source_level ' ||
				',l.target ' ||
				',l.target_level ' ||
				',l.link ' ||
				',COUNT(activity_id) as value ' ||
				'FROM partnerlink_sankey_links l ' ||			
				'GROUP BY 1,2,3,4,5 ' ||
				'ORDER BY 2, 6 DESC ' ||            
				') linkjson) AS links ' ||
			') sankey;';

	-- filtering	
	ELSE
	   -- filter by classification ids
	   IF ($1 is not null AND $1 <> '') THEN

	      -- Create an int array from classification ids list
		SELECT * INTO filter_classids FROM pmt_validate_classifications($1);

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
		  dynamic_where2 := array_append(dynamic_where2, '(' || array_to_string(built_where, ' OR ') || ')');
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
		dynamic_where2 := array_append(dynamic_where2, '(' || array_to_string(built_where, ' OR ') || ')');
		
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
	      dynamic_where4 := '(' || array_to_string(built_where, ' OR ') || ')';
		
	   END IF;
	   
	   -- filter by date range
	   IF ($4 is not null AND $5 is not null) THEN
		dynamic_where2 := array_append(dynamic_where2, '(start_date > ''' || $4 || ''' AND end_date < ''' || $5 || ''')');
	   END IF;		
	   										
	  -- prepare statement					
	  -- RAISE NOTICE '   + First where statement: %', array_to_string(dynamic_where1, ' AND ');
	  -- RAISE NOTICE '   + Second where statement: %', array_to_string(dynamic_where2, ' AND ');
	  -- RAISE NOTICE '   + Third where statement: %', dynamic_where3;
	  -- RAISE NOTICE '   + Forth where statement: %', dynamic_where4;

	execute_statement := 'SELECT row_to_json(sankey.*) AS sankey ' ||
				'FROM (	' ||
				'SELECT (SELECT array_to_json(array_agg(row_to_json(nodejson.*))) AS array_to_json ' ||
				'FROM ( ' ||
					-- node query
					'SELECT DISTINCT n.name ' ||
					',n.node ' ||
					',n.level ' ||
					'FROM partnerlink_sankey_nodes AS n ' ||
					'WHERE n.activity_id IN ' ||
						'(SELECT DISTINCT activity_id FROM location_lookup ';
	IF dynamic_where2 IS NOT NULL THEN          
           IF dynamic_where4 IS NOT NULL THEN
              execute_statement := execute_statement || ' WHERE ' ||  array_to_string(dynamic_where2, ' AND ')  || ' OR ' || dynamic_where4;
           ELSE
              execute_statement := execute_statement || ' WHERE ' ||  array_to_string(dynamic_where2, ' AND ') || ' ';
           END IF;
        ELSE 
          IF dynamic_where4 IS NOT NULL THEN
              execute_statement := execute_statement || ' WHERE ' || dynamic_where4 || ' ';                       
          END IF;
        END IF;

	execute_statement := execute_statement || ')ORDER BY 2 ) AS nodejson ' ||
				') as nodes, ( ' ||
				'SELECT array_to_json(array_agg(row_to_json(linkjson.*))) AS array_to_json ' ||
				'FROM (  ' ||
				-- link query
				'SELECT l.source ' ||
				',l.source_level ' ||
				',l.target ' ||
				',l.target_level ' ||
				',l.link ' ||
				',COUNT(activity_id) as value ' ||
				'FROM partnerlink_sankey_links l ' ||
				'WHERE l.activity_id IN ' ||
						'(SELECT DISTINCT activity_id FROM location_lookup ';
	IF dynamic_where2 IS NOT NULL THEN          
           IF dynamic_where4 IS NOT NULL THEN
              execute_statement := execute_statement || ' WHERE ' ||  array_to_string(dynamic_where2, ' AND ')  || ' OR ' || dynamic_where4;
           ELSE
              execute_statement := execute_statement || ' WHERE ' ||  array_to_string(dynamic_where2, ' AND ') || ' ';
           END IF;
        ELSE 
          IF dynamic_where4 IS NOT NULL THEN
              execute_statement := execute_statement || ' WHERE ' || dynamic_where4 || ' ';                       
          END IF;
        END IF;		
        
	execute_statement := execute_statement || ') GROUP BY 1,2,3,4,5 ' ||
				'ORDER BY 2, 6 DESC ' ||            
				') linkjson) AS links ' ||
			') sankey;';	
	END IF;	

	--SET work_mem='3MB';				
	-- execute statement		
	RAISE NOTICE 'execute: %', execute_statement;			  
	FOR rec IN EXECUTE execute_statement
	LOOP
	RETURN NEXT rec;
	END LOOP;

	--RESET work_mem;
END;$$ LANGUAGE plpgsql; 

ALTER FUNCTION pmt_partner_sankey(character varying, character varying, character varying, date, date) SET work_mem = '3MB';

-- update permissions
GRANT USAGE ON SCHEMA public TO pmt_read;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO pmt_read;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO pmt_read;
GRANT USAGE ON SCHEMA public TO pmt_write;
GRANT SELECT,INSERT ON ALL TABLES IN SCHEMA public TO pmt_write;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO pmt_write;
