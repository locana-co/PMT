/******************************************************************
Change Script 3.0.10.30

1. create new function pmt_partner_sankey_activities for the 
partnerlink feature
******************************************************************/
INSERT INTO version(_version, _iteration, _changeset) VALUES (3.0, 10, 30);
-- select * from version order by _iteration desc, _changeset desc;

/*************************************************************************
  1. create new function pmt_partner_sankey_activities for the 
partnerlink feature
     select * from pmt_partner_sankey_activities('2209,2210','Grantee Not Reported',1);
     select * from pmt_partner_sankey_activities('',2450,0);
*************************************************************************/
DROP FUNCTION IF EXISTS pmt_partner_sankey_activities(character varying, integer, integer);
CREATE OR REPLACE FUNCTION pmt_partner_sankey_activities(data_group_ids character varying, organization character varying, partnerlink_level integer)
RETURNS SETOF pmt_json_result_type AS 
$$
DECLARE
  filtered_activity_ids int[];
  execute_statement text;
  rec record;
  error_msg text;
BEGIN	

    -- validate and process taxonomy_id parameter
  IF ($1 IS NULL OR $1 = '') OR ($2 IS NULL OR $2 = '') OR ($3 IS NULL) THEN
  
    FOR rec IN SELECT row_to_json(j) FROM( SELECT 'missing valid required parameter' AS error ) as j LOOP RETURN NEXT rec; END LOOP;
    
  ELSE
    
    -- get the filtered activity ids
    SELECT INTO filtered_activity_ids * FROM pmt_filter($1,null,null,null,null,null,null,null);

    -- prepare the execution statement
    execute_statement := 'SELECT DISTINCT activity_id, title FROM _partnerlink_participants ' ||
			'WHERE activity_id = ANY(ARRAY[' || array_to_string(filtered_activity_ids, ',') || ']) ';

    CASE partnerlink_level
      WHEN 0 THEN
        execute_statement := execute_statement || 'AND fund_name = ' || quote_literal(organization);
      WHEN 1 THEN
        execute_statement := execute_statement || 'AND acct_name = ' || quote_literal(organization);
      ELSE
        execute_statement := execute_statement || 'AND impl_name = ' || quote_literal(organization);
    END CASE;    
  									
    -- execute statement		
    RAISE NOTICE 'execute: %', execute_statement;			  

    FOR rec IN EXECUTE 'SELECT row_to_json(j) FROM (' || execute_statement || ')j' LOOP  		
      RETURN NEXT rec;
    END LOOP;
    
  END IF;
  
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