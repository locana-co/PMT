/******************************************************************
Change Script 3.0.10.29

1. update pmt_partner_sankey to put back unreported funders, grantees,
and partners from the returned data
******************************************************************/
INSERT INTO version(_version, _iteration, _changeset) VALUES (3.0, 10, 29);
-- select * from version order by _iteration desc, _changeset desc;

REFRESH MATERIALIZED VIEW _partnerlink_sankey_nodes;
REFRESH MATERIALIZED VIEW _partnerlink_sankey_links;

/*************************************************************************
  1. update pmt_partner_sankey to remove unreported funders, grantees,
and partners from the returned data
     select * from pmt_partner_sankey(null,null,null,null,null,null);
     select * from pmt_partner_sankey('2209',null,null,null,null,null);
     select * from pmt_partner_sankey('768','831','','1/1/2012','12/31/2018');
*************************************************************************/
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
					'WHERE activity_id = ANY(ARRAY[' || array_to_string(filtered_activity_ids, ',') || ']) ' ||
					-- 'AND node NOT IN (1,2.1,3.2) ' ||
					'ORDER BY 2 ) AS nodejson ' ||
				') as nodes' ||
				', (SELECT array_to_json(array_agg(row_to_json(linkjson.*))) AS array_to_json FROM (  ' ||
					-- link query
					'SELECT source, source_level, target, target_level, link, COUNT(activity_id) as value ' ||
					'FROM _partnerlink_sankey_links ' ||
					'WHERE activity_id = ANY(ARRAY[' || array_to_string(filtered_activity_ids, ',') || ']) ' ||
					-- 'AND source NOT IN (1,2.1,3.2) AND target NOT IN (1,2.1,3.2) ' ||			
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


-- update permissions
GRANT USAGE ON SCHEMA public TO pmt_read;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO pmt_read;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO pmt_read;
GRANT USAGE ON SCHEMA public TO pmt_write;
GRANT SELECT,INSERT ON ALL TABLES IN SCHEMA public TO pmt_write;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO pmt_write;