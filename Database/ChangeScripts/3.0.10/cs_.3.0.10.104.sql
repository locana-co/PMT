/******************************************************************
Change Script 3.0.10.104
1. update pmt_validate_organizations for latest data model
2. create pmt_replace_participation to allow for full reassignment
of participation records by Organisation Role
3. update pmt_activity_detail(int[]) overload to pmt_activity_details
4. create pmt_activities_all function to support call for deactivated 
activities
******************************************************************/
INSERT INTO version(_version, _iteration, _changeset) VALUES (3.0, 10, 104);
-- select * from version order by _iteration desc, _changeset desc;

/******************************************************************
1. update pmt_validate_organizations for latest data model
  select * FROM pmt_validate_organizations('3646');
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_validate_organizations(organization_ids character varying)
  RETURNS integer[] AS $$
DECLARE 
  valid_organization_ids INT[];
  filter_organization_ids INT[];
BEGIN 
     IF $1 IS NULL THEN    
       RETURN valid_organization_ids;
     END IF;

     filter_organization_ids := string_to_array($1, ',')::int[];
     
     SELECT INTO valid_organization_ids array_agg(DISTINCT id)::INT[] FROM (SELECT id FROM organization WHERE _active = true AND id = ANY(filter_organization_ids) ORDER BY id) as c;	 
     
     RETURN valid_organization_ids;
     
EXCEPTION WHEN others 
	THEN RETURN NULL;
	
END;$$ LANGUAGE plpgsql;

/******************************************************************
2. create pmt_replace_participation to allow for full reassignment
of participation records by Organisation Role

 select * from pmt_replace_participation(1,34,15796,496,'3261');
 select * from pmt_replace_participation(1,34,15796,496,'13');
 select * from pmt_replace_participation(1,34,13512,497,'3261');
 select * from pmt_replace_participation(1,34,13512,497,'763,1686,1685,1683');
     
 select id, count(distinct organization_id) from _activity_participants group by 1 order by 2
 select * from organization where _active = true order by _name
 select * from _activity_participants where id = 13512
 select * from _taxonomy_classifications tc where tc.taxonomy IN ('Organisation Role','Organisation Type','Implementing Types')
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_replace_participation(instance_id integer, user_id integer, activity_id integer, role_id integer, organization_ids character varying) RETURNS SETOF pmt_json_result_type AS 
$$
DECLARE
  o_ids integer[];  
  c_ids integer[];
  role_id integer; 
  class_ids integer[]; 
  username text;
  rec record;
  error_message text;
  error_msg text;
BEGIN 
  -- instance_id is required
  IF ($1 IS NULL) THEN
    FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: instance_id is a required parameter.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
  END IF;
  -- user_id is required
  IF ($2 IS NULL) THEN
    FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: user_id is a required parameter.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
  END IF;
  -- activity_id is required
  IF ($3 IS NULL) THEN
    FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: activity_id is a required parameter.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
  ELSE
     -- validate the associated activity record
    IF NOT (SELECT * FROM pmt_validate_activity($3)) THEN  
      FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: Invalid activity_id.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
    END IF;
  END IF;
  -- validate role_id
  IF ($4 IS NULL) THEN
    FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: role_id is a required parameter.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
  ELSE      
    SELECT INTO role_id tc.classification_id from _taxonomy_classifications tc where tc.taxonomy IN ('Organisation Role') AND tc.classification_id = $4;
    IF role_id IS NULL THEN
      FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: Provided role_id did not contain a valid Organisation Role taxonomy.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
    END IF;    
  END IF;
  -- organization_id is required
  IF ($5 IS NULL) AND ($5 <> '') THEN
    FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: organization_id is a required parameter.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
  ELSE
    SELECT INTO o_ids * FROM pmt_validate_organizations($5);
    -- validate the associated organization record
    IF o_ids IS NULL THEN  
      FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: No valid organization_id provided.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
    END IF;
  END IF;
  
  -- get users name
  SELECT INTO username _username FROM users WHERE users.id = $2;
  
  -- validate users authority to perform an update on the activity
  IF (SELECT * FROM pmt_validate_user_authority($1, $2, $3, null, 'update')) THEN      
    -- delete all taxonomy records for participation records using role_ids
    DELETE FROM participation_taxonomy WHERE (participation_id, classification_id) IN 
    (
      SELECT p.id, classification_id FROM 
        (SELECT * FROM participation p WHERE p.activity_id = $3) p 
        JOIN (SELECT * FROM participation_taxonomy WHERE classification_id = role_id ) pt 
        ON p.id = pt.participation_id
    );
    -- delete all organization records orphaned on activity
    DELETE FROM participation p WHERE (p.activity_id, p.organization_id) IN
      (SELECT id, organization_id FROM _activity_participants WHERE (id, organization_id) NOT IN 
	(SELECT id, organization_id FROM _activity_participants WHERE id = $3 AND classification_id 
		IN (SELECT classification_id from _taxonomy_classifications tc where tc.taxonomy IN ('Organisation Role'))) 
      AND id = $3);
    
    -- add new participating organizations
    INSERT INTO participation (activity_id, organization_id, _created_by, _updated_by) SELECT $3, id, username, username FROM organization WHERE id = ANY(o_ids) AND id NOT IN (SELECT organization_id FROM participation p  WHERE p.activity_id = $3);
    -- add new roles to participants
    INSERT INTO participation_taxonomy(participation_id, classification_id, _field)
	SELECT id, role_id, 'id' FROM participation p WHERE p.organization_id = ANY(o_ids) AND p.activity_id = $3;
  ELSE
    FOR rec IN (SELECT row_to_json(j) FROM(select null as id, 'Error: User does not have authority to update on this instance or activity.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
  END IF;
 
  -- editing completed successfullly
  FOR rec IN (SELECT row_to_json(j) FROM(select $3 as activity_id, 'Success' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;         
  
EXCEPTION WHEN others THEN
     GET STACKED DIAGNOSTICS error_msg = MESSAGE_TEXT;
    FOR rec IN (SELECT row_to_json(j) FROM(select $3 as activity_id, 'Internal Error - Contact your DBA with the following error message: ' || error_msg as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
      
END;$$ LANGUAGE plpgsql;


/******************************************************************
  3. update pmt_activity_detail(int[]) overload to pmt_activity_details
  select * from pmt_activity_details(null, 769, true, null, null); -- all active activities for data group AGRA
  select * from pmt_activity_details(null, 769, false, null, null); -- all active & inactive activities for data group AGRA
  select * from pmt_activity_details(null, 769, false, 200, null); -- all active & inactive activities for data group AGRA with record limit
  select * from pmt_activity_details(null, 769, false, 200, 200); -- all active & inactive activities for data group AGRA with record limit and offset
  select * from pmt_activity_details(ARRAY[14803,14804,17479,16233,18242,18241,16798], null, false, null, null); -- activities by list

  select * from activity where _active= true;
*******************************************************************/
DROP FUNCTION IF EXISTS pmt_activity_detail(integer[]);
CREATE OR REPLACE FUNCTION pmt_activity_details(activity_ids integer[], data_group_id integer, active_only boolean, limit_record integer, offset_record integer) RETURNS SETOF pmt_json_result_type AS $$
DECLARE
  rec record;
  ids integer[];
  invalid_return_columns text[];
  return_columns text;
  execute_statement text;
  data_message text;
BEGIN
  IF $1 IS NOT NULL THEN
    ids:= $1;
  END IF;
  IF $2 IS NOT NULL THEN
    IF active_only THEN
      SELECT INTO ids array_agg(id) FROM activity WHERE _active = true AND activity.data_group_id = $2;
    ELSE
      SELECT INTO ids array_agg(id) FROM activity WHERE activity.data_group_id = $2;
    END IF;    
  END IF;
  
  IF ids IS NOT NULL THEN	
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
				'and at.activity_id = a.id ' ||  
				') t ) as taxonomy ';
    -- organizations			
    execute_statement := execute_statement || ',(SELECT array_to_json(array_agg(row_to_json(p))) FROM ( ' ||
				'select o.participation_id as p_id, o.id, o._name, r.classification as role, r.classification_id as role_id, ' ||
				't.classification as type, t.classification_id as type_id, i.classification as imp_type, i.classification_id as imp_type_id ' ||
				'from ' || 
				'(select * from ' ||
				'(select id as participation_id, organization_id from participation where _active = true and activity_id = a.id ) p ' ||
				'join organization o  ' ||
				'on p.organization_id = o.id) o ' ||
				'left join ' ||
				'(select * from _organization_lookup where taxonomy = ''Organisation Role'') r ' ||
				'on r.activity_id = a.id and r.organization_id = o.id ' ||
				'left join ' ||
				'(select * from _organization_lookup where taxonomy = ''Organisation Type'') t ' ||
				'on t.activity_id = a.id and t.organization_id = o.id ' ||
				'left join  ' ||
				'(select * from _organization_lookup where taxonomy = ''Implementing Types'') i ' ||
				'on i.activity_id = a.id and i.organization_id = o.id ' ||
				') p ) as organizations ';
				
    -- contacts
    execute_statement := execute_statement || ',(SELECT array_to_json(array_agg(row_to_json(c))) FROM ( ' ||
				'select c.id, c._first_name, c._last_name, c._title, c._email, c.organization_id, o._name ' ||
				'from activity_contact ac ' ||
				'join contact c ' ||
				'on ac.contact_id = c.id ' ||
				'left join organization o ' ||
				'on c.organization_id = o.id ' ||
				'where c._active = true and ac.activity_id = a.id ' ||  
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
				'where f._active = true and f.activity_id = a.id ' ||  
				') f ) as financials ';

    -- locations
    execute_statement := execute_statement || ',(SELECT array_to_json(array_agg(row_to_json(l))) FROM (  ' ||
				'select l.id, l._admin0, l._admin1, l._admin2, l._admin3, l._admin_level, l.boundary_id, l.feature_id ' ||
				'from location l ' ||		
				'where l._active = true and l.activity_id = a.id ' ||  
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
				'where d._active = true and d.activity_id = a.id ' ||  				
				') d ) as details ';	
					
    -- children
    execute_statement := execute_statement || ',(SELECT array_to_json(array_agg(row_to_json(aa))) FROM (  ' ||
				'select p.id, p._title ' ||					
				'from activity p ' ||		
				'where p._active = true and p.parent_id = a.id ' ||  
				') aa ) as children ';	
													
								
    -- activity
    execute_statement := execute_statement || 'from (select * from activity a where a.id = ANY(ARRAY[' || array_to_string(ids, ',')  || ']) ';

    -- add record limit
    IF $4 IS NOT NULL THEN
      execute_statement := execute_statement || ' order by id limit ' || limit_record;
    END IF;
    -- add record offset
    IF $5 IS NOT NULL THEN
      execute_statement := execute_statement || ' offset ' || offset_record;
    END IF;

    execute_statement := execute_statement || ' ) a ';		
		
    -- locations
    execute_statement := execute_statement || 'left join ' ||
				'(select ll.activity_id, count(distinct ll.location_id) as ct ' ||
				'from _location_lookup ll ' ||
				'where ll.activity_id = ANY(ARRAY[' || array_to_string(ids, ',')  || ']) ' ||
				'group by ll.activity_id) l ' ||
				'on a.id = l.activity_id ';


  RAISE NOTICE 'Execute statement: %', execute_statement;			

  FOR rec IN EXECUTE 'SELECT row_to_json(j) FROM (' || execute_statement || ')j' LOOP  		
	RETURN NEXT rec;
  END LOOP;
END IF;

END;$$ LANGUAGE plpgsql;


/******************************************************************
4. create pmt_activities_all function to support call for deactivated 
activities
   select * from pmt_activities_all('769', false); -- all activities active true & false
   select * from pmt_activities_all('769', true); -- active activities only
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_activities_all(data_group_ids character varying, only_active boolean) RETURNS SETOF pmt_json_result_type AS
$$
DECLARE
  dg_ids int[];
  data_group_ids int[];
  execute_statement text; 
  json record;   
  rec record;
  error_msg text;
BEGIN
  -- validate data group ids
  IF $1 IS NOT NULL THEN
    dg_ids:= string_to_array($1, ',')::int[];
    SELECT INTO data_group_ids array_agg(id) FROM classification WHERE taxonomy_id = 1 AND id = ANY(dg_ids);
  END IF;
  
  execute_statement:= 'SELECT DISTINCT a.id, parent_id as pid, data_group_id as dgid, _iati_identifier as iati, (SELECT _name FROM classification WHERE id = data_group_id) as dg, ' ||
		'_title as t, _amount as a, a._start_date as sd, a._end_date as ed, array_agg( o._name) as f ' ||
		'FROM ( SELECT DISTINCT af.parent_id as id, null as parent_id, _iati_identifier, af.data_group_id, af._title, a._start_date, a._end_date ' ||
			'FROM ( ' || 
				'SELECT p.id AS parent_id, c.id AS child_id, p._title, p.data_group_id ' ||
				'FROM ( SELECT activity.id, activity._title, activity.data_group_id FROM activity ' ||
				'WHERE activity.parent_id IS NULL ';
				IF data_group_ids IS NOT NULL THEN
					execute_statement:= execute_statement || 'AND activity.data_group_id = ANY(ARRAY[' || array_to_string(data_group_ids, ',')  || ']) ';
				END IF;
				IF only_active THEN
					execute_statement:= execute_statement || 'AND activity._active = true ';
				END IF;

				
				
  execute_statement:= execute_statement || ') p LEFT JOIN ( SELECT activity.id, activity.parent_id FROM activity WHERE activity.parent_id IS NOT NULL ';
			        IF data_group_ids IS NOT NULL THEN
					execute_statement:= execute_statement || 'AND activity.data_group_id = ANY(ARRAY[' || array_to_string(data_group_ids, ',')  || ']) ';
				END IF;
				IF only_active THEN
					execute_statement:= execute_statement || 'AND activity._active = true ';
				END IF;

  execute_statement:= execute_statement || ') c ON p.id = c.parent_id ';

					
  execute_statement:= execute_statement || ') af JOIN activity a ON af.parent_id = a.id ) a' ||
  		' LEFT JOIN ( ' ||
			'SELECT DISTINCT f.activity_id, sum(_amount) as _amount FROM ( ' ||
			'SELECT id, activity_id, _amount, provider_id FROM financial WHERE _active = true) f ' ||
			' LEFT JOIN ( select financial_id, classification, _code ' ||
				' FROM financial_taxonomy ft ' ||
				' JOIN _taxonomy_classifications tc ' ||
				' on ft.classification_id = tc.classification_id ' ||
				' where tc.taxonomy = ''Transaction Type''' || 
				'OR classification IS NULL OR classification = ''Incoming Funds'' OR classification = ''Commitment'' ) as ft ' ||
		'ON ft.financial_id = f.id GROUP BY 1 ) f ON a.id = f.activity_id ' ||
		'LEFT JOIN (SELECT id, _name FROM _activity_participants WHERE classification = ''Funding'') o ON a.id = o.id ' ||
		'GROUP BY 1,2,3,4,5,6,7,8,9 ';


  RAISE NOTICE 'Execute statement: %', execute_statement;

  FOR rec IN EXECUTE 'SELECT row_to_json(j) FROM (' || execute_statement || ')j' LOOP
	RETURN NEXT rec;
  END LOOP;

EXCEPTION WHEN others THEN
  GET STACKED DIAGNOSTICS error_msg = MESSAGE_TEXT;
    RAISE NOTICE 'Internal Error - Contact your DBA with the following error message: %', error_msg;

END;$$ LANGUAGE plpgsql;
