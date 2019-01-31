/******************************************************************
Change Script 3.0.10.96
1. new pmt_validate_details function
2. new edit_detail_taxonomy function
3. update pmt_activity function to add contact _title
4. update pmt_activity_detail to match pmt_activity
******************************************************************/
INSERT INTO version(_version, _iteration, _changeset) VALUES (3.0, 10, 96);
-- select * from version order by _iteration desc, _changeset desc;

/******************************************************************
 1. create new pmt_validate_details function 
 select * from pmt_validate_details('156,169,171,26373');
 select * from detail
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_validate_details(detail_ids character varying) RETURNS integer[] AS $$
DECLARE 
  valid_detail_ids INT[];
  filter_detail_ids INT[];
  error_msg text;
BEGIN 
     IF $1 IS NULL THEN    
       RETURN valid_detail_ids;
     END IF;

     filter_detail_ids := string_to_array($1, ',')::int[];
     
     SELECT INTO valid_detail_ids array_agg(DISTINCT id)::INT[] FROM (SELECT id FROM detail WHERE _active = true AND id = ANY(filter_detail_ids) ORDER BY id) AS d;
     
     RETURN valid_detail_ids;
     
EXCEPTION WHEN others THEN
  GET STACKED DIAGNOSTICS error_msg = MESSAGE_TEXT;
  RAISE NOTICE 'Internal Error - Contact your DBA with the following error message: %', error_msg;
  RETURN FALSE;

END; 
$$ LANGUAGE 'plpgsql';

/******************************************************************
2. new pmt_edit_detail_taxonomy function
select * from pmt_edit_detail_taxonomy(1,34,'1863','2450',null,'replace') -- pass
select * from pmt_edit_detail_taxonomy(1,34,'1863','2453',null,'add') -- pass
select * from pmt_edit_detail_taxonomy(1,34,'1863','2450',null,'delete') -- pass

 select d.id, d._amount, tc.taxonomy_id, tc.classification_id, tc.classification from
 (select * from detail where _active = true and _amount is not null) d
 left join detail_taxonomy dt
 on d.id = dt.detail_id
 left join _taxonomy_classifications tc
 on dt.classification_id = tc.classification_id
 where d.id = 1863

******************************************************************/
CREATE OR REPLACE FUNCTION pmt_edit_detail_taxonomy(instance_id integer, user_id integer, detail_ids character varying, classification_ids character varying, taxonomy_ids character varying, edit_action pmt_edit_action) RETURNS SETOF pmt_json_result_type AS  
$$
DECLARE
  valid_classification_ids integer[]; 	-- valid classification_ids from parameter
  valid_detail_ids integer[];     	-- valid detail_ids from parameter
  valid_taxonomy_ids integer[];     	-- valid taxonomy_ids from parameter
  a_id integer;				-- activity_id
  d_id integer; 		      	-- detail_id
  c_id integer;       			-- classification_id
  t_id integer;       			-- taxonomy_id
  dt_id integer;      			-- detail_taxonomy detail_id
  tc record;        			-- taxonomy_classifications record
  rec record;
  error_msg text;
BEGIN 

  -- instance_id is required for all operations
  IF ($1 IS NULL) THEN
    FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: instance_id is a required parameter for all operations.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
  END IF;
  -- user_id is required for all operations
  IF ($2 IS NULL) THEN
    FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: user_id is a required parameter for all operations.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
  END IF;
  -- detail_ids is required for all operations
  IF ($3 IS NULL OR $3 = '') THEN
    FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: detail_ids is a required parameter for all operations.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
  END IF;
  -- edit_action is required for all operations
  IF ($6 IS NULL) THEN
    FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: edit_action is a required parameter for all operations.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
  END IF;
  -- classification_ids are required for add & replace, and delete only if taxonomy_ids is null
  -- taxonomy_ids is only required for delete, if classification_ids is null
  IF ($6 = 'delete') THEN
    -- classification_ids OR taxonomy_ids are required for delete
    IF ($4 IS NULL OR $4 = '') AND ($5 IS NULL OR $5 = '') THEN
      FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: classification_ids or taxonomy_ids are a required parameter for delete operations.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
    END IF;
  ELSE
    -- classification_ids are required for add & replace
    IF ($4 IS NULL OR $4 = '') THEN
      FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: classification_ids is a required parameter for all operations.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
    END IF;
  END IF;
    
  -- validate detail_ids
  SELECT INTO valid_detail_ids * FROM pmt_validate_details($3);
  -- validate classification_ids
  SELECT INTO valid_classification_ids * FROM pmt_validate_classifications($4);
  -- validate taxonomy_ids
  SELECT INTO valid_taxonomy_ids * FROM pmt_validate_taxonomies($5);
    
  -- must provide a min of one valid detail_id to continue
  IF valid_detail_ids IS NULL THEN
    FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: Must provide at least one valid detail_id.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
  END IF;

  IF $6 = 'delete' THEN
    -- must provide a min of one valid classification_id or taxonomy_id to continue
    IF valid_classification_ids IS NULL AND valid_taxonomy_ids IS NULL THEN
      FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: Must provide at least one valid classification_id or taxonomy_id.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
    END IF;
  ELSE
    -- must provide a min of one valid classification_id to continue
    IF valid_classification_ids IS NULL THEN
      FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: Must provide at least one valid classification_id.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
    END IF;
  END IF;
  
  -- on delete actions with taxonomy_ids
  IF $6 = 'delete' AND valid_taxonomy_ids IS NOT NULL THEN
    -- loop through the valid taxonomy ids
    FOR t_id IN EXECUTE 'SELECT id FROM taxonomy WHERE id = ANY(ARRAY[' || array_to_string(valid_taxonomy_ids, ',') || '])' LOOP
      FOREACH d_id IN ARRAY valid_financial_ids LOOP 
        SELECT INTO a_id activity_id FROM financial WHERE id = d_id;
        -- validate users authority to add/delete/update an activity's financial classifications (use update for all taxonomy operations)
	IF (SELECT * FROM pmt_validate_user_authority($1, $2, a_id, null, 'update')) THEN 
          EXECUTE 'DELETE FROM financial_taxonomy WHERE financial_id ='|| d_id ||' AND classification_id IN (SELECT id FROM classification WHERE taxonomy_id = '|| t_id || ') AND _field = ''id'''; 
          RAISE NOTICE 'Delete Record: %', 'Remove association to taxonomy id ('|| t_id ||') for financial id ('|| d_id ||')';	   
        ELSE
          RAISE NOTICE'User does not have update authorization on activity (id: %), which is required to edit activity financials.', a_id;
        END IF;
      END LOOP;
    END LOOP;    
    -- editing completed successfullly
    FOR rec IN (SELECT row_to_json(j) FROM(select $3 as activity_ids, 'Success' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN; 
  END IF;
  
  -- loop through sets of valid classification_ids by taxonomy
  FOR tc IN EXECUTE 'SELECT taxonomy_id::integer, array_agg(classification_id)::integer[] AS classification_id FROM _taxonomy_classifications  tc ' ||
	'WHERE classification_id = ANY(ARRAY['|| array_to_string(valid_classification_ids, ',') || ']) GROUP BY taxonomy_id ORDER BY taxonomy_id ' LOOP       
    -- operations based on edit_action
    CASE $6  
      WHEN 'delete' THEN
        FOREACH d_id IN ARRAY valid_detail_ids LOOP 
          SELECT INTO a_id activity_id FROM detail WHERE id = d_id;
          -- validate users authority to add/delete/update an activity's detail classifications (use update for all taxonomy operations)
	  IF (SELECT * FROM pmt_validate_user_authority($1, $2, a_id, null, 'update')) THEN 
            EXECUTE 'DELETE FROM detail_taxonomy WHERE detail_id ='|| d_id ||' AND classification_id = ANY(ARRAY['|| array_to_string(tc.classification_id, ',') ||']) AND _field = ''id'''; 
            RAISE NOTICE 'Delete Record: %', 'Remove association to classification_id(s) ('|| array_to_string(tc.classification_id, ',') ||') for detail id ('|| d_id ||')';	   
          ELSE
            RAISE NOTICE'User does not have update authorization on activity (id: %), which is required to edit activity details.', a_id;
          END IF;
        END LOOP;
      WHEN 'replace' THEN
        FOREACH d_id IN ARRAY valid_detail_ids LOOP 
          SELECT INTO a_id activity_id FROM detail WHERE id = d_id;
          -- validate users authority to add/delete/update an activity's detail classifications (use update for all taxonomy operations)
	  IF (SELECT * FROM pmt_validate_user_authority($1, $2, a_id, null, 'update')) THEN 
            -- remove all classifications for given taxonomy 
            EXECUTE 'DELETE FROM detail_taxonomy WHERE detail_id ='|| d_id ||' AND classification_id in ' ||
                 '(SELECT classification_id FROM _taxonomy_classifications WHERE taxonomy_id = '|| tc.taxonomy_id||') AND _field = ''id''';
            RAISE NOTICE 'Delete Record: %', 'Remove association to taxonomy_id ('|| tc.taxonomy_id ||') for detail id ('|| d_id ||')';
            -- insert all classification_ids for this taxonomy
	    EXECUTE 'INSERT INTO detail_taxonomy(detail_id, classification_id, _field) SELECT '|| d_id ||', id, ''id'' FROM ' ||
	       'classification WHERE id IN (' || array_to_string(tc.classification_id, ',') || ')'; 
            RAISE NOTICE 'Add Record: %', 'detail_id ('|| d_id ||') is now associated to classification_ids ('|| array_to_string(tc.classification_id, ',') ||').';  
          ELSE
            RAISE NOTICE'User does not have update authorization on activity (id: %), which is required to edit activity detail taxonomies.', a_id;
          END IF;
        END LOOP;
      -- add (DEFAULT)
      ELSE
        FOREACH d_id IN ARRAY valid_detail_ids LOOP 
          SELECT INTO a_id activity_id FROM detail WHERE id = d_id;
          FOREACH c_id IN ARRAY tc.classification_id LOOP
            -- validate users authority to add/delete/update an activity's detail classifications (use update for all taxonomy operations)
	    IF (SELECT * FROM pmt_validate_user_authority($1, $2, a_id, null, 'update')) THEN 
              -- check to see if this classification is already assoicated to the activity
              SELECT INTO dt_id detail_id FROM detail_taxonomy as ft WHERE ft.detail_id = d_id AND ft.classification_id = c_id LIMIT 1;
              IF dt_id IS NULL THEN
                EXECUTE 'INSERT INTO detail_taxonomy(detail_id, classification_id, _field) VALUES ('|| d_id ||', '|| c_id ||', ''id'')';
                RAISE NOTICE 'Add Record: %', 'Finicial_id ('|| d_id ||') is now associated to classification_id ('|| c_id ||').'; 
              ELSE
                RAISE NOTICE'Add Record: %', 'This detail_id ('|| d_id ||') already has an association to this classification_id ('|| c_id ||').';                
              END IF;
            ELSE
              RAISE NOTICE'User does not have update authorization on activity (id: %), which is required to edit activity detail taxonomies.', a_id;
            END IF;
          END LOOP;
        END LOOP;
    END CASE;
  END LOOP;    

  -- editing completed successfullly
  FOR rec IN (SELECT row_to_json(j) FROM(select $3 as detail_ids, 'Success' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN; 
 	
EXCEPTION WHEN others THEN
  GET STACKED DIAGNOSTICS error_msg = MESSAGE_TEXT;
  FOR rec IN (SELECT row_to_json(j) FROM(select d_id as id, 'Internal Error - Contact your DBA with the following error message: ' || error_msg as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;	  

END;$$ LANGUAGE plpgsql;


/******************************************************************
3. update pmt_activity function to add contact _title
  SELECT * FROM pmt_activity(29859);
  select * from activity where parent_id is null
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_activity(activity_id integer) RETURNS SETOF pmt_json_result_type AS 
$$
DECLARE
  rec record;
  invalid_return_columns text[];
  return_columns text;
  execute_statement text;
  data_message text;
BEGIN
  IF $1 IS NOT NULL THEN	
    -- set columns that are not to be returned 
    invalid_return_columns := ARRAY['_active', '_retired_by', '_created_by', '_created_date'];
    -- get list of columns to return
    SELECT INTO return_columns array_to_string(array_agg('a.' || column_name::text), ', ') FROM information_schema.columns 
    WHERE table_schema='public' AND table_name='activity' AND column_name != ALL(invalid_return_columns);

    -- dynamically build the execute statment	
    execute_statement := 'SELECT ' || return_columns || ', (SELECT _name FROM classification WHERE id = data_group_id) as data_group' || 
				', (SELECT _title FROM activity WHERE id = a.parent_id) as parent_title, l.ct ';

    -- taxonomy	
    execute_statement := execute_statement || ',(SELECT array_to_json(array_agg(row_to_json(t))) FROM ( ' ||
				'select tc.taxonomy_id, tc.taxonomy, tc.classification_id, tc.classification, tc._code ' ||
				'from activity_taxonomy at ' ||
				'join _taxonomy_classifications  tc ' ||
				'on at.classification_id = tc.classification_id ' ||
				'and at.activity_id = ' || $1 ||
				') t ) as taxonomy ';
    -- organizations			
    execute_statement := execute_statement || ',(SELECT array_to_json(array_agg(row_to_json(p))) FROM ( ' ||
				'select _name as organization, _url as url, _address1 as address,  ' ||
				'_city as city, _state_providence as state_providence, _postal_code as zip, _country as country, r.classification as role, ' ||
				'array_to_string(array_agg(t.classification),'','') as type, i.classification as prime ' ||
				'from ' || 
				'(select * from ' ||
				'(select id as participation_id, organization_id from participation where _active = true and activity_id = ' ||  $1 || ') p ' ||
				'join organization o  ' ||
				'on p.organization_id = o.id) o ' ||
				'left join ' ||
				'(select * from _organization_lookup where taxonomy = ''Organisation Role'') r ' ||
				'on r.activity_id = ' ||  $1 || ' and r.organization_id = o.id ' ||
				'left join ' ||
				'(select * from _organization_lookup where taxonomy = ''Organisation Type'') t ' ||
				'on t.activity_id = ' ||  $1 || ' and t.organization_id = o.id ' ||
				'left join  ' ||
				'(select * from _organization_lookup where taxonomy = ''Implementing Types'') i ' ||
				'on i.activity_id = ' ||  $1 || ' and i.organization_id = o.id ' ||
				'group by 1,2,3,4,5,6,7,8,10 ' ||
				') p ) as organizations ';
    -- contacts
    execute_statement := execute_statement || ',(SELECT array_to_json(array_agg(row_to_json(c))) FROM ( ' ||
				'select c.id, c._first_name, c._last_name, c._email, c.organization_id, o._name, c._title ' ||
				'from activity_contact ac ' ||
				'join contact c ' ||
				'on ac.contact_id = c.id ' ||
				'left join organization o ' ||
				'on c.organization_id = o.id ' ||
				'where c._active = true and ac.activity_id = ' || $1 ||
				') c ) as contacts ';	
    -- details
    execute_statement := execute_statement || ',(SELECT array_to_json(array_agg(row_to_json(d))) FROM ( ' ||
				'select d.id, d._title, d._description, d._amount, (SELECT array_to_json(array_agg(row_to_json(t))) FROM ( ' ||
				'select distinct tc.taxonomy_id, tc.taxonomy, tc.classification_id, tc.classification, tc._code ' ||
				'from detail_taxonomy dt ' ||
				'join _taxonomy_classifications tc ' ||
				'on dt.classification_id = tc.classification_id ' ||
				'and dt.detail_id = d.id ' ||
				') t ) as taxonomy ' ||
				'from detail d ' ||				
				'where d._active = true and d.activity_id = ' || $1 ||
				') d ) as details ';	

    -- financials
    execute_statement := execute_statement || ',(SELECT array_to_json(array_agg(row_to_json(f))) FROM ( ' ||
				'select f.id, f._amount, f._start_date, f._end_date '  ||
						',(SELECT _name FROM organization WHERE id = provider_id) as provider' ||
						',(SELECT _name FROM organization WHERE id = recipient_id) as recipient' ||
						', (SELECT array_to_json(array_agg(row_to_json(t))) FROM ( ' ||
						'select tc.taxonomy_id, tc.taxonomy, tc.classification_id, tc.classification, tc._code ' ||
						'from financial_taxonomy ft ' ||
						'join _taxonomy_classifications tc ' ||
						'on ft.classification_id = tc.classification_id ' ||
						'and ft.financial_id = f.id ' ||
						') t ) as taxonomy ' ||
				'from financial f ' ||		
				'where f._active = true and f.activity_id = ' || $1 ||
				') f ) as financials ';
											
     -- locations
    execute_statement := execute_statement || ',(SELECT array_agg(l.id)::int[]  ' ||
				'from location l ' ||		
				'where l._active = true and l.activity_id = ' || $1 ||
				') as location_ids ';	

    -- locations
    execute_statement := execute_statement || ',(SELECT array_to_json(array_agg(row_to_json(l))) FROM (  ' ||
				'select l.id, l._admin0, l._admin1, l._admin2, l._admin3, l._admin_level ' ||
					', (SELECT array_to_json(array_agg(row_to_json(t))) FROM ( ' ||
					'select tc.taxonomy_id, tc.taxonomy, tc.classification_id, tc.classification, tc._code ' ||
					'from location_taxonomy lt ' ||
					'join _taxonomy_classifications tc ' ||
					'on lt.classification_id = tc.classification_id ' ||
					'and lt.location_id = l.id ' ||
					') t ) as taxonomy ' ||
					', (SELECT array_to_json(array_agg(row_to_json(b))) FROM ( ' ||
					'select lb.boundary_id, lb.feature_id, lb._feature_name ' ||
					'from location_boundary lb ' ||					
					'where lb.location_id = l.id ' ||
					') b ) as boundaries ' ||
				'from location l ' ||		
				'where l._active = true and l.activity_id = ' || $1 ||
				') l ) as locations ';		

    -- children
    execute_statement := execute_statement || ',(SELECT array_to_json(array_agg(row_to_json(a))) FROM (  ' ||
				'select a.id, a._title ' ||					
				'from activity a ' ||		
				'where a._active = true and a.parent_id = ' || $1 ||
				') a ) as children ';	
													
								
    -- activity
    execute_statement := execute_statement || 'from (select * from activity a where a._active = true and a.id = ' || $1 || ') a ';
    -- locations
    execute_statement := execute_statement || 'left join ' ||
				'(select ll.activity_id, count(distinct ll.location_id) as ct ' ||
				'from _location_lookup ll ' ||
				'where ll.activity_id = ' || $1 ||
				'group by ll.activity_id) l ' ||
				'on a.id = l.activity_id ';


RAISE NOTICE 'Execute statement: %', execute_statement;			

FOR rec IN EXECUTE 'SELECT row_to_json(j) FROM (' || execute_statement || ')j' LOOP  		
	RETURN NEXT rec;
END LOOP;
   END IF;
END;$$ LANGUAGE plpgsql;


/******************************************************************
  4. update pmt_activity_detail to match pmt_activity
  select * from pmt_activity_detail(29859);
*******************************************************************/
CREATE OR REPLACE FUNCTION pmt_activity_detail(activity_id integer) RETURNS SETOF pmt_json_result_type AS $$
DECLARE
  rec record;
  invalid_return_columns text[];
  return_columns text;
  execute_statement text;
  data_message text;
BEGIN
  IF $1 IS NOT NULL THEN	
    -- get list of columns to return
    SELECT INTO return_columns array_to_string(array_agg('a.' || column_name::text), ', ') FROM information_schema.columns 
    WHERE table_schema='public' AND table_name='activity';

    -- dynamically build the execute statment	
    execute_statement := 'SELECT ' || return_columns || ', (SELECT _name FROM classification WHERE id = data_group_id) as data_group' || 
				', (SELECT _title FROM activity WHERE id = a.parent_id) as parent_title, l.ct ';

    -- taxonomy	
    execute_statement := execute_statement || ',(SELECT array_to_json(array_agg(row_to_json(t))) FROM ( ' ||
				'select tc.taxonomy_id, tc.taxonomy, tc.classification_id, tc.classification, tc._code ' ||
				'from activity_taxonomy at ' ||
				'join _taxonomy_classifications  tc ' ||
				'on at.classification_id = tc.classification_id ' ||
				'and at.activity_id = ' || $1 ||
				') t ) as taxonomy ';
    -- organizations			
    execute_statement := execute_statement || ',(SELECT array_to_json(array_agg(row_to_json(p))) FROM ( ' ||
				'select o.participation_id as p_id, o.id, o._name, r.classification as role, r.classification_id as role_id, ' ||
				't.classification as type, t.classification_id as type_id, i.classification as imp_type, i.classification_id as imp_type_id ' ||
				'from ' || 
				'(select * from ' ||
				'(select id as participation_id, organization_id from participation where _active = true and activity_id = ' ||  $1 || ') p ' ||
				'join organization o  ' ||
				'on p.organization_id = o.id) o ' ||
				'left join ' ||
				'(select * from _organization_lookup where taxonomy = ''Organisation Role'') r ' ||
				'on r.activity_id = ' ||  $1 || ' and r.organization_id = o.id ' ||
				'left join ' ||
				'(select * from _organization_lookup where taxonomy = ''Organisation Type'') t ' ||
				'on t.activity_id = ' ||  $1 || ' and t.organization_id = o.id ' ||
				'left join  ' ||
				'(select * from _organization_lookup where taxonomy = ''Implementing Types'') i ' ||
				'on i.activity_id = ' ||  $1 || ' and i.organization_id = o.id ' ||
				') p ) as organizations ';
				
    -- contacts
    execute_statement := execute_statement || ',(SELECT array_to_json(array_agg(row_to_json(c))) FROM ( ' ||
				'select c.id, c._first_name, c._last_name, c._title, c._email, c.organization_id, o._name ' ||
				'from activity_contact ac ' ||
				'join contact c ' ||
				'on ac.contact_id = c.id ' ||
				'left join organization o ' ||
				'on c.organization_id = o.id ' ||
				'where c._active = true and ac.activity_id = ' || $1 ||
				') c ) as contacts ';	

    -- financials
    execute_statement := execute_statement || ',(SELECT array_to_json(array_agg(row_to_json(f))) FROM ( ' ||
				'select f.id, f._amount, f._start_date, f._end_date'  ||
						',provider_id' ||
						',(SELECT _name FROM organization WHERE id = provider_id) as provider' ||
						',recipient_id' ||
						',(SELECT _name FROM organization WHERE id = recipient_id) as recipient' ||
						', (SELECT array_to_json(array_agg(row_to_json(t))) FROM ( ' ||
						'select tc.taxonomy_id, tc.taxonomy, tc.classification_id, tc.classification, tc._code ' ||
						'from financial_taxonomy ft ' ||
						'join _taxonomy_classifications tc ' ||
						'on ft.classification_id = tc.classification_id ' ||
						'and ft.financial_id = f.id ' ||
						') t ) as taxonomy ' ||
				'from financial f ' ||		
				'where f._active = true and f.activity_id = ' || $1 ||
				') f ) as financials ';

    -- locations
    execute_statement := execute_statement || ',(SELECT array_to_json(array_agg(row_to_json(l))) FROM (  ' ||
				'select l.id, l._admin0, l._admin1, l._admin2, l._admin3, l._admin_level, l.boundary_id, l.feature_id ' ||
				'from location l ' ||		
				'where l._active = true and l.activity_id = ' || $1 ||
				') l ) as locations ';		
    -- details
    execute_statement := execute_statement || ',(SELECT array_to_json(array_agg(row_to_json(d))) FROM (  ' ||
				'select d.id, d._title, d._description, d._amount, (SELECT array_to_json(array_agg(row_to_json(t))) FROM ( ' ||
				'select distinct tc.taxonomy_id, tc.taxonomy, tc.classification_id, tc.classification, tc._code ' ||
				'from detail_taxonomy dt ' ||
				'join _taxonomy_classifications tc ' ||
				'on dt.classification_id = tc.classification_id ' ||
				'and dt.detail_id = d.id ' ||
				') t ) as taxonomy ' ||
				'from detail d ' ||				
				'where d._active = true and d.activity_id = ' || $1 ||				
				') d ) as details ';	
					
    -- children
    execute_statement := execute_statement || ',(SELECT array_to_json(array_agg(row_to_json(a))) FROM (  ' ||
				'select a.id, a._title ' ||					
				'from activity a ' ||		
				'where a._active = true and a.parent_id = ' || $1 ||
				') a ) as children ';	
													
								
    -- activity
    execute_statement := execute_statement || 'from (select * from activity a where a._active = true and a.id = ' || $1 || ') a ';
    -- locations
    execute_statement := execute_statement || 'left join ' ||
				'(select ll.activity_id, count(distinct ll.location_id) as ct ' ||
				'from _location_lookup ll ' ||
				'where ll.activity_id = ' || $1 || ' ' ||
				'group by ll.activity_id) l ' ||
				'on a.id = l.activity_id ';


  RAISE NOTICE 'Execute statement: %', execute_statement;			

  FOR rec IN EXECUTE 'SELECT row_to_json(j) FROM (' || execute_statement || ')j' LOOP  		
	RETURN NEXT rec;
  END LOOP;
END IF;

END;$$ LANGUAGE plpgsql;

-- update permissions
GRANT USAGE ON SCHEMA public TO pmt_read;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO pmt_read;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO pmt_read;
GRANT USAGE ON SCHEMA public TO pmt_write;
GRANT SELECT,INSERT ON ALL TABLES IN SCHEMA public TO pmt_write;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO pmt_write;