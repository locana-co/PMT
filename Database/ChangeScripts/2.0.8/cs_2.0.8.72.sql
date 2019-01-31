/******************************************************************
Change Script 2.0.8.72
1. pmt_validate_financials - add functionality to take in multiple 
fiancial_ids
2. pmt_edit_financial_taxonomy - new function that allows user to 
edit taxonomy relationship of specific financial_ids
******************************************************************/
INSERT INTO version(version, iteration, changeset) VALUES (2.0, 8, 72);
-- select * from version order by changeset desc;

-- Create pmt_validate_financials function
-- DROP FUNCTION pmt_validate_locations(character varying);

CREATE OR REPLACE FUNCTION pmt_validate_financials(financial_ids character varying)
  RETURNS integer[] AS
$BODY$
DECLARE 
  valid_financial_ids INT[];
  filter_financial_ids INT[];
BEGIN 
     IF $1 IS NULL THEN    
       RETURN valid_financial_ids;
     END IF;

     filter_financial_ids := string_to_array($1, ',')::int[];
     
     SELECT INTO valid_financial_ids array_agg(DISTINCT financial_id)::INT[] FROM (SELECT financial_id FROM financial WHERE active = true AND financial_id = ANY(filter_financial_ids) ORDER BY financial_id) AS t;
     
     RETURN valid_financial_ids;

EXCEPTION
     WHEN others THEN RETURN NULL;
END; 
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION pmt_validate_financials(character varying)
  OWNER TO postgres;
GRANT EXECUTE ON FUNCTION pmt_validate_locations(character varying) TO postgres;
GRANT EXECUTE ON FUNCTION pmt_validate_locations(character varying) TO public;
GRANT EXECUTE ON FUNCTION pmt_validate_locations(character varying) TO pmt_read;
GRANT EXECUTE ON FUNCTION pmt_validate_locations(character varying) TO pmt_write;

-- Drop old function (Dont remove old function on databases with active applications)
-- DROP FUNCTION IF EXISTS pmt_edit_financial_taxonomy(character varying, character varying, integer, pmt_edit_action)  CASCADE;

-- New Drop Statement for updated function
DROP FUNCTION IF EXISTS pmt_edit_financial_taxonomy(integer, character varying, character varying, character varying, pmt_edit_action)  CASCADE;

/******************************************************************
   TESTING
   
 57 - reader (read)
 54 - editor (read,create,update)
 55 - super (read,create,update,delete)

-- reader (expected return: false)
select * from pmt_edit_financial_taxonomy(57,'7944,7945,7946,7947,7948','419',null,'add') -- pass
select * from pmt_edit_financial_taxonomy(57,'7944,7945,7946,7947,7948','419',null,'delete') -- pass
select * from pmt_edit_financial_taxonomy(57,'7944,7945,7946,7947,7948','419',null,'replace') -- pass
select * from pmt_edit_financial_taxonomy(57,'7944,7945,7946,7947,7948',null,null,'add') -- pass

-- super (expected return: true)
select * from pmt_edit_financial_taxonomy(27,'8061,8062,8063,8064,8065,8066,8067','419',null,'delete') -- pass
select * from pmt_edit_financial_taxonomy(27,'8061,8062,8063,8064,8065,8066,8067','419',null,'add') -- pass
select * from pmt_edit_financial_taxonomy(27,'8061,8062,8063,8064,8065,8066,8067','420',null,'replace') -- pass
select * from pmt_edit_financial_taxonomy(27,'8061,8062,8063,8064,8065,8066,8067','419',null,'replace') -- pass
select * from pmt_edit_financial_taxonomy(27,'8061,8062,8063,8064,8065,8066,8067',null,'6','delete') -- pass

-- back to orginal values
select * from pmt_edit_financial_taxonomy(27,'8061,8062,8063,8064,8065,8066,8067','419',null,'add') -- pass

-- all 419
select * from financial_taxonomy where financial_id in (8061,8062,8063,8064,8065,8066,8067)

-- There are no financial_ids in financial_taxonomy with an user that has "editor" rights
******************************************************************/

/******************************************************************
   pmt_edit_financial_taxonomy
******************************************************************/   
CREATE OR REPLACE FUNCTION pmt_edit_financial_taxonomy(user_id integer, financial_ids character varying, classification_id character varying, remove_taxonomy_ids character varying, edit_action pmt_edit_action)
  RETURNS boolean AS
$BODY$
DECLARE
  valid_classification_ids integer[]; -- valid classification_ids from parameter
  valid_financial_ids integer[];     -- valid financial_ids from parameter
  valid_taxonomy_ids integer[];     -- valid taxonomy_ids from parameter
  f_id integer;       -- financial_id
  c_id integer;       -- classification_id
  p_id integer;       -- project_id
  t_id integer;       -- taxonomy_id
  ft_id integer;      -- financial_taxonomy financial_id
  tc record;        -- taxonomy_classifications record
  error_msg1 text;
  error_msg2 text;
  error_msg3 text; 
BEGIN 

  -- first and second parameters are required AND either the third OR the fourth parameter is required
  IF ($1 IS NOT NULL) AND ($2 is not null AND $2 <> '') AND (($3 is not null AND $3 <> '') OR ($4 is not null AND $4 <> '')) THEN
  
    -- validate financial_ids
    SELECT INTO valid_financial_ids * FROM pmt_validate_financials($2);
    -- validate classification_ids
    SELECT INTO valid_classification_ids * FROM pmt_validate_classifications($3);
    -- validate taxonomy_ids
    SELECT INTO valid_taxonomy_ids * FROM pmt_validate_taxonomies($4);
    
     -- must provide a min of one valid financial_id to continue
    IF valid_financial_ids IS NULL THEN
      RAISE NOTICE 'Error: Must provide a valid financial_id.';
      RETURN false;
    END IF;
        
    -- must provide a valid classification_id OR a valid taxonomy_id to continue
    IF valid_classification_ids IS NULL AND valid_taxonomy_ids IS NULL THEN
      RAISE NOTICE 'Error: Must provide a valid classification_id or taxonomy_id.';
      RETURN false;
    END IF;

    IF (valid_classification_ids IS NOT NULL) THEN
    -- loop through sets of valid classification_ids by taxonomy
    FOR tc IN EXECUTE 'SELECT taxonomy_id::integer, array_agg(classification_id)::integer[] AS classification_id FROM taxonomy_classifications  tc ' ||
    'WHERE classification_id = ANY(ARRAY['|| array_to_string(valid_classification_ids, ',') || ']) GROUP BY taxonomy_id ORDER BY taxonomy_id ' LOOP     
          
      -- operations based on edit_action
      CASE $5
        WHEN 'delete' THEN
          FOREACH f_id IN ARRAY valid_financial_ids LOOP 
            SELECT INTO p_id project_id from financial where financial_id = f_id;
            -- validate users authority to perform an update action on this financial (use update permission for delete of taxonomy relationships)
             IF (SELECT * FROM pmt_validate_user_authority($1, p_id, 'update')) THEN
               EXECUTE 'DELETE FROM financial_taxonomy WHERE financial_id ='|| f_id ||' AND classification_id = ANY(ARRAY['|| array_to_string(tc.classification_id, ',') ||']) AND field = ''financial_id'' OR field = ''amount''';
              RAISE NOTICE 'Delete Record: %', 'Remove association to classification_id(s) ('|| array_to_string(tc.classification_id, ',') ||') for financial_id ('|| f_id ||')';
            ELSE
              RAISE NOTICE 'Error: The requested edit action requires the user to have UPDATE rights to this project: %', p_id;
        RETURN FALSE; 
      END IF;      
          END LOOP;
        WHEN 'replace' THEN
          FOREACH f_id IN ARRAY valid_financial_ids LOOP 
            SELECT INTO p_id project_id from financial where financial_id = f_id;
            --validate user authority to perform a create action on this request
            IF (SELECT * FROM pmt_validate_user_authority($1, p_id, 'update')) AND (SELECT * FROM pmt_validate_user_authority($1, p_id, 'create')) THEN
              -- remove all classifications for given taxonomy 
              EXECUTE 'DELETE FROM financial_taxonomy WHERE financial_id ='|| f_id ||' AND classification_id in ' ||
                      '(SELECT classification_id FROM taxonomy_classifications WHERE taxonomy_id = '|| tc.taxonomy_id||') AND field = ''financial_id''';
              RAISE NOTICE 'Delete Record: %', 'Remove association to taxonomy_id ('|| tc.taxonomy_id ||') for financial_id ('|| f_id ||')';
              -- insert all classification_ids for this taxonomy
        EXECUTE 'INSERT INTO financial_taxonomy(financial_id, classification_id, field) SELECT '|| f_id ||', classification_id, ''financial_id'' FROM ' ||
          'classification WHERE classification_id IN (' || array_to_string(tc.classification_id, ',') || ')'; 
              RAISE NOTICE 'Add Record: %', 'financial_id ('|| f_id ||') is now associated to classification_ids ('|| array_to_string(tc.classification_id, ',') ||').';
            ELSE
              RAISE NOTICE 'Error: The requested edit action requires the user to have UPDATE and CREATE rights to this project: %', p_id;
              RETURN FALSE;
            END IF;  
          END LOOP;
        -- add (DEFAULT)
        ELSE
          FOREACH f_id IN ARRAY valid_financial_ids LOOP 
            SELECT INTO p_id project_id from financial where financial_id = f_id;
            -- validate users authority to perform a create action on this project
            IF (SELECT * FROM pmt_validate_user_authority($1, p_id, 'create')) THEN 
              FOREACH c_id IN ARRAY tc.classification_id LOOP
                -- check to see if this classification is already assoicated to the financial
                SELECT INTO ft_id financial_id FROM financial_taxonomy as at WHERE at.financial_id = f_id AND at.classification_id = c_id LIMIT 1;
                IF ft_id IS NULL THEN
                  EXECUTE 'INSERT INTO financial_taxonomy(financial_id, classification_id, field) VALUES ('|| f_id ||', '|| c_id ||', ''financial_id'')';
                  RAISE NOTICE 'Add Record: %', 'financial_id ('|| f_id ||') is now associated to classification_id ('|| c_id ||').'; 
                ELSE
                  RAISE NOTICE'Add Record: %', 'This financial_id ('|| f_id ||') already has an association to this classification_id ('|| c_id ||').';                
                END IF;
              END LOOP;
            ELSE
              RAISE NOTICE 'Error: The requested edit action requires the user to have CREATE rights to this project: %', p_id;
        RETURN FALSE; 
      END IF;
          END LOOP;
        END CASE;
    END LOOP;  
    END IF;
    
    -- if remove_taxonomy_ids contains valid taxonomy_ids remove all associations to the taxonomy(ies) contained
    IF (valid_taxonomy_ids IS NOT NULL) THEN
      FOREACH t_id IN ARRAY valid_taxonomy_ids LOOP 
        FOREACH f_id IN ARRAY valid_financial_ids LOOP 
          SELECT INTO p_id project_id from financial where financial_id = f_id;
          --validate user authority to perform a create action on this request
          IF (SELECT * FROM pmt_validate_user_authority($1, p_id, 'update')) AND (SELECT * FROM pmt_validate_user_authority($1, p_id, 'create')) THEN
            -- remove all classifications for given taxonomy 
            EXECUTE 'DELETE FROM financial_taxonomy WHERE financial_id ='|| f_id ||' AND classification_id in ' ||
                    '(SELECT classification_id FROM taxonomy_classifications WHERE taxonomy_id = '|| t_id ||') AND field = ''financial_id''';
            RAISE NOTICE 'Delete Record: %', 'Remove association to taxonomy_id ('|| t_id ||') for actvity_id ('|| f_id ||')';           
           ELSE
              RAISE NOTICE 'Error: The requested edit action requires the user to have UPDATE and CREATE rights to this project: %', p_id;
              RETURN FALSE;
           END IF;  
         END LOOP;
      END LOOP;
    END IF;
    
    -- return successful execution
    RETURN true;
  -- first three parameters are required 
  ELSE
   RAISE NOTICE 'Error: Must provide user_id, financial_ids AND either classification_ids or remove_taxonomy_id parameters.';
    RETURN false;
  END IF;   

  EXCEPTION WHEN others THEN
   GET STACKED DIAGNOSTICS error_msg1 = MESSAGE_TEXT,
      error_msg2 = PG_EXCEPTION_DETAIL,
      error_msg3 = PG_EXCEPTION_HINT;
                          
  RAISE NOTICE 'Error: %', error_msg1;                          
  RETURN FALSE; 
END;$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION pmt_edit_financial_taxonomy(integer, character varying, character varying, character varying, pmt_edit_action)
  OWNER TO postgres;
GRANT EXECUTE ON FUNCTION pmt_edit_financial_taxonomy(integer, character varying, character varying, character varying, pmt_edit_action) TO public;
GRANT EXECUTE ON FUNCTION pmt_edit_financial_taxonomy(integer, character varying, character varying, character varying, pmt_edit_action) TO postgres;
GRANT EXECUTE ON FUNCTION pmt_edit_financial_taxonomy(integer, character varying, character varying, character varying, pmt_edit_action) TO pmt_read;
GRANT EXECUTE ON FUNCTION pmt_edit_financial_taxonomy(integer, character varying, character varying, character varying, pmt_edit_action) TO pmt_write;
