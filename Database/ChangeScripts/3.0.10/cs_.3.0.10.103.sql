/******************************************************************
Change Script 3.0.10.103
1. create pmt_activity_detail overloaded method
2. create pmt_boundary_match to match location to boundaries
3. update _activity_taxonomies to return _code
4. update function pmt_classifications to return _code
******************************************************************/
INSERT INTO version(_version, _iteration, _changeset) VALUES (3.0, 10, 103);
-- select * from version order by _iteration desc, _changeset desc;

/******************************************************************
  1. update pmt_activity_detail to match pmt_activity
  select * from pmt_activity_detail(ARRAY[29571,29589,29859,29557]);
  select * from activity where _active= true;
*******************************************************************/
CREATE OR REPLACE FUNCTION pmt_activity_detail(activity_id integer[]) RETURNS SETOF pmt_json_result_type AS $$
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
				'and at.activity_id = ANY(ARRAY[' || array_to_string($1, ',')  || ']) ' ||  
				') t ) as taxonomy ';
    -- organizations			
    execute_statement := execute_statement || ',(SELECT array_to_json(array_agg(row_to_json(p))) FROM ( ' ||
				'select o.participation_id as p_id, o.id, o._name, r.classification as role, r.classification_id as role_id, ' ||
				't.classification as type, t.classification_id as type_id, i.classification as imp_type, i.classification_id as imp_type_id ' ||
				'from ' || 
				'(select * from ' ||
				'(select id as participation_id, organization_id from participation where _active = true and activity_id = ANY(ARRAY[' || array_to_string($1, ',')  || ']) ) p ' ||
				'join organization o  ' ||
				'on p.organization_id = o.id) o ' ||
				'left join ' ||
				'(select * from _organization_lookup where taxonomy = ''Organisation Role'') r ' ||
				'on r.activity_id = ANY(ARRAY[' || array_to_string($1, ',')  || ']) and r.organization_id = o.id ' ||
				'left join ' ||
				'(select * from _organization_lookup where taxonomy = ''Organisation Type'') t ' ||
				'on t.activity_id = ANY(ARRAY[' || array_to_string($1, ',')  || ']) and t.organization_id = o.id ' ||
				'left join  ' ||
				'(select * from _organization_lookup where taxonomy = ''Implementing Types'') i ' ||
				'on i.activity_id = ANY(ARRAY[' || array_to_string($1, ',')  || ']) and i.organization_id = o.id ' ||
				') p ) as organizations ';
				
    -- contacts
    execute_statement := execute_statement || ',(SELECT array_to_json(array_agg(row_to_json(c))) FROM ( ' ||
				'select c.id, c._first_name, c._last_name, c._title, c._email, c.organization_id, o._name ' ||
				'from activity_contact ac ' ||
				'join contact c ' ||
				'on ac.contact_id = c.id ' ||
				'left join organization o ' ||
				'on c.organization_id = o.id ' ||
				'where c._active = true and ac.activity_id = ANY(ARRAY[' || array_to_string($1, ',')  || ']) ' ||  
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
				'where f._active = true and f.activity_id = ANY(ARRAY[' || array_to_string($1, ',')  || ']) ' ||  
				') f ) as financials ';

    -- locations
    execute_statement := execute_statement || ',(SELECT array_to_json(array_agg(row_to_json(l))) FROM (  ' ||
				'select l.id, l._admin0, l._admin1, l._admin2, l._admin3, l._admin_level, l.boundary_id, l.feature_id ' ||
				'from location l ' ||		
				'where l._active = true and l.activity_id = ANY(ARRAY[' || array_to_string($1, ',')  || ']) ' ||  
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
				'where d._active = true and d.activity_id = ANY(ARRAY[' || array_to_string($1, ',')  || ']) ' ||  				
				') d ) as details ';	
					
    -- children
    execute_statement := execute_statement || ',(SELECT array_to_json(array_agg(row_to_json(a))) FROM (  ' ||
				'select a.id, a._title ' ||					
				'from activity a ' ||		
				'where a._active = true and a.parent_id = ANY(ARRAY[' || array_to_string($1, ',')  || ']) ' ||  
				') a ) as children ';	
													
								
    -- activity
    execute_statement := execute_statement || 'from (select * from activity a where a._active = true and a.id = ANY(ARRAY[' || array_to_string($1, ',')  || ']) ' ||   ') a ';
    -- locations
    execute_statement := execute_statement || 'left join ' ||
				'(select ll.activity_id, count(distinct ll.location_id) as ct ' ||
				'from _location_lookup ll ' ||
				'where ll.activity_id = ANY(ARRAY[' || array_to_string($1, ',')  || ']) ' ||   ' ' ||
				'group by ll.activity_id) l ' ||
				'on a.id = l.activity_id ';


  RAISE NOTICE 'Execute statement: %', execute_statement;			

  FOR rec IN EXECUTE 'SELECT row_to_json(j) FROM (' || execute_statement || ')j' LOOP  		
	RETURN NEXT rec;
  END LOOP;
END IF;

END;$$ LANGUAGE plpgsql;

/******************************************************************
  2. create pmt_boundary_match to match location to boundaries
  select * from pmt_boundary_match('gadm', '[{ "id": null,"feature_id": null,"boundary_id": null,"_admin0": "Kenya","_admin1": null,"_admin2": null,"_admin_level": 0,"_iati_identifier": "2007 PASS 001"}]');
  select * from pmt_boundary_match('gadm', '[{ "id": null,"feature_id": null,"boundary_id": null,"_admin0": "Kenya","_admin1": null,"_admin2": null,"_admin_level": 0,"_iati_identifier": "2007 PASS 001"},{ "id": null,"feature_id": null,"boundary_id": null,"_admin0": "Tanzania","_admin1": null,"_admin2": null,"_admin_level": 0,"_iati_identifier": "2007 PASS 001"}]');
  select * from pmt_boundary_match('gadm', '[{ "id": null,"feature_id": null,"boundary_id": null,"_admin0": "Kenya","_admin1": "Nairobi","_admin2": null,"_admin_level": 1,"_iati_identifier": "2007 PASS 001"},{ "id": null,"feature_id": null,"boundary_id": null,"_admin0": "Tanzania","_admin1": null,"_admin2": null,"_admin_level": 0,"_iati_identifier": "2007 PASS 001"}]');
  select * from pmt_boundary_match('gadm', '[{ "id": null,"feature_id": null,"boundary_id": null,"_admin0": "Kenya","_admin1": "Nairobi","_admin2": "Roysambu","_admin_level": 2,"_iati_identifier": "2007 PASS 001"},{ "id": null,"feature_id": null,"boundary_id": null,"_admin0": "Kenya","_admin1": "Nairobi","_admin2": null,"_admin_level": 1,"_iati_identifier": "2007 PASS 001"},{ "id": null,"feature_id": null,"boundary_id": null,"_admin0": "Kenya","_admin1": null,"_admin2": null,"_admin_level": 0,"_iati_identifier": "2007 PASS 001"}]');
  select * from boundary
  select * from gadm2 WHERE _gadm0_name = 'Kenya'
*******************************************************************/
CREATE OR REPLACE FUNCTION pmt_boundary_match(boundary_type character varying, locations json) RETURNS SETOF pmt_json_result_type AS $$
DECLARE
  _b0 text;
  _b1 text;
  _b2 text;
  level int;
  iati text;
  boundary record;
  feature record;
  location_id int;
  count int;
  idx int;
  boundary_levels int[];
  location_json json;
  json record;
  rec record;
  statements text;
  execute_statements text[];
  execute_statement text;
  error_msg text;
BEGIN
  -- validate boundary type
  IF ($1 IS NOT NULL) AND ($1 <> '') THEN
    -- SELECT array_agg(id) FROM (SELECT id FROM boundary WHERE _type = 'gadm' ORDER BY _admin_level) as b
    SELECT INTO boundary_levels array_agg(id) FROM (SELECT id FROM boundary WHERE _type = $1 ORDER BY _admin_level) as b;
    IF boundary_levels IS NULL THEN
      FOR rec IN (SELECT row_to_json(j) FROM(select 'Error: boundary_type was not valid and is a required parameter.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
    END IF;
  ELSE
    FOR rec IN (SELECT row_to_json(j) FROM(select 'Error: boundary_type is a required parameter.' as message) j) LOOP  RETURN NEXT rec; END LOOP; RETURN;
  END IF;
  -- begin execution statement
  execute_statement := ' ';

  -- get the filtered activity ids by boundary
  IF ($2 IS NOT NULL) THEN
    RAISE NOTICE 'json was not null';      
    FOR location_json IN (SELECT * FROM json_array_elements($2)) LOOP
      RAISE NOTICE 'location_json: %', location_json;
      -- '[{ "id": null,"feature_id": null,"boundary_id": null,"_admin0": "Kenya","_admin1": null,"_admin2": null,"_admin_level": 0,"_iati_identifier": "2007 PASS 001"}]'
      -- -- select * from json_extract_path_text('{ "id": null,"feature_id": null,"boundary_id": null,"_admin0": "Kenya","_admin1": null,"_admin2": null,"_admin_level": 0,"_iati_identifier": "2007 PASS 001"}','_admin0') 
      SELECT INTO _b0 json_extract_path_text(location_json,'_admin0');
      SELECT INTO _b1 json_extract_path_text(location_json,'_admin1');
      SELECT INTO _b2 json_extract_path_text(location_json,'_admin2');
      SELECT INTO iati json_extract_path_text(location_json,'_iati_identifier');
      SELECT INTO level json_extract_path_text(location_json,'_admin_level')::int;
      SELECT INTO location_id json_extract_path_text(location_json,'id')::int;
      RAISE NOTICE 'admin level: %', level;
      RAISE NOTICE 'boundary ids levels: %', boundary_levels;
      RAISE NOTICE 'admin 0: %', _b0;
      RAISE NOTICE 'admin 1: %', _b1;
      RAISE NOTICE 'admin 2: %', _b2;
      RAISE NOTICE 'iati: %', iati;
      -- locate boundary feature by provided admin level
      CASE level
        -- admin level 2
        WHEN 2 THEN
          FOR boundary IN SELECT * FROM boundary WHERE id = boundary_levels[3] LOOP
            RAISE NOTICE 'search boundary: %', boundary._name;
	    -- find the feature in the boundary by supplied name
            execute_statement := execute_statement || 'SELECT boundary_id, id as feature_id, _' || quote_ident(boundary_type)  || '0_name as _admin0, _' || quote_ident(boundary_type)  || '1_name as _admin1, _name as _admin2, 2 as _admin_level, ' || quote_literal(iati) || ' as _iati_identifier FROM ' || quote_ident(boundary._spatial_table)  || ' WHERE _name = ' || quote_literal(_b2) || ' UNION ALL ';
          END LOOP;
        -- admin level 1
        WHEN 1 THEN
          FOR boundary IN SELECT * FROM boundary WHERE id = boundary_levels[2] LOOP
            RAISE NOTICE 'search boundary: %', boundary._name;
	    -- find the feature in the boundary by supplied name
            execute_statement:= execute_statement || 'SELECT boundary_id, id as feature_id, _' || quote_ident(boundary_type)  || '0_name as _admin0, _name as _admin1, null as _admin2, 1 as _admin_level, ' || quote_literal(iati) || ' as _iati_identifier FROM ' || quote_ident(boundary._spatial_table)  || ' WHERE _name = ' || quote_literal(_b1) || ' UNION ALL ';
          END LOOP;
        -- admin level 0
        ELSE
          RAISE NOTICE 'searching boundary id: %', boundary_levels[1];
          FOR boundary IN SELECT * FROM boundary WHERE id = boundary_levels[1] LOOP
            RAISE NOTICE 'search boundary: %', boundary;
	    -- find the feature in the boundary by supplied name
            execute_statement:= execute_statement || 'SELECT boundary_id, id as feature_id, _name as _admin0, null as _admin1, null as _admin2, 0 as _admin_level, ' || quote_literal(iati) || ' as _iati_identifier FROM ' || quote_ident(boundary._spatial_table)  || ' WHERE _name = ' || quote_literal(_b0) || ' UNION ALL '; 
          END LOOP;
      END CASE;  -- boundary level switch (0,1,2) 
    END LOOP; -- json location object array loop
  END IF;	

  RAISE NOTICE 'Execute statement: %', left(execute_statement, length(execute_statement)-10);			

  FOR rec IN EXECUTE 'SELECT row_to_json(j) FROM (' || left(execute_statement, length(execute_statement)-10) || ')j' LOOP  		
	RETURN NEXT rec;
  END LOOP;

EXCEPTION WHEN others THEN 
  GET STACKED DIAGNOSTICS error_msg = MESSAGE_TEXT;  
    RAISE NOTICE 'Internal Error - Contact your DBA with the following error message: %', error_msg;

END;$$ LANGUAGE plpgsql;


/******************************************************************
3. update _activity_taxonomies to return _code
  select * from _activity_taxonomies;
******************************************************************/

DROP MATERIALIZED VIEW IF EXISTS _activity_family_taxonomies;
DROP VIEW IF EXISTS _activity_taxonomies;

CREATE OR REPLACE VIEW _activity_taxonomies AS 
 SELECT a.id,
    a.parent_id,
    a._title,
    a.data_group_id,
    dg.classification AS data_group,
    at._field,
    tc.taxonomy_id,
    tc.taxonomy,
    tc.taxonomy_parent_id,
    tc.classification_id,
    tc.classification,
    tc._iati_name,
    tc._code,
    tc.classification_parent_id
   FROM activity a
     JOIN activity_taxonomy at ON a.id = at.activity_id
     JOIN _taxonomy_classifications tc ON at.classification_id = tc.classification_id
     LEFT JOIN _taxonomy_classifications dg ON a.data_group_id = dg.classification_id
  WHERE a._active = true
  ORDER BY a.id;
  
-- NO CHANGE - DROP/RECREATE DUE TO DEPENDENTCY
CREATE MATERIALIZED VIEW _activity_family_taxonomies AS 
 SELECT af.parent_id,
    af.child_id,
    af._title,
    af.data_group_id,
    m.amount,
    t.taxonomy_id,
    t.taxonomy,
    t.classification_id,
    t.classification,
    t._field
   FROM ( SELECT _activity_family.parent_id,
            _activity_family.child_id,
            _activity_family._title,
            _activity_family.data_group_id
           FROM _activity_family) af
     LEFT JOIN ( SELECT _activity_financials.id,
            sum(_activity_financials._amount) AS amount
           FROM _activity_financials
          WHERE _activity_financials.transaction_type IS NULL OR _activity_financials.transaction_type::text = ''::text OR (_activity_financials.transaction_type::text = ANY (ARRAY['Incoming Funds'::character varying, 'Commitment'::character varying]::text[]))
          GROUP BY _activity_financials.id) m ON af.parent_id = m.id
     LEFT JOIN ( SELECT _activity_taxonomies.id,
            _activity_taxonomies.taxonomy_id,
            _activity_taxonomies.taxonomy,
            _activity_taxonomies.classification_id,
            _activity_taxonomies.classification,
            _activity_taxonomies._field
           FROM _activity_taxonomies) t ON af.parent_id = t.id OR af.child_id = t.id
WITH DATA;

/******************************************************************
4. update function pmt_classifications to return _code
  select * from pmt_classifications(79, '2237', null, true);
  select * from pmt_classifications(79, null, null, true);
  select * from pmt_classifications(79, '2237', null, false);
   select * from pmt_classifications(15, '2237', null, false);
   select * from pmt_classifications(18, null, null, false);
   select * from taxonomy
******************************************************************/
CREATE OR REPLACE FUNCTION pmt_classifications(taxonomy_id integer, data_group_ids character varying, instance_id integer, locations_only boolean) RETURNS SETOF pmt_json_result_type AS
$$
DECLARE
  valid_taxonomy record; 
  dg_ids int[];
  valid_dg_ids int[]; 
  rec record;
  execute_statement text;
  error_msg text;
BEGIN

  -- validate and process taxonomy_id parameter (required)
  IF $1 IS NOT NULL THEN
    -- validate the taxonomy id
    SELECT INTO valid_taxonomy * FROM taxonomy WHERE id = $1 AND _active = true;
    IF valid_taxonomy IS NULL THEN
      FOR rec IN SELECT row_to_json(j) FROM( SELECT 'missing valid required parameter' AS error ) as j LOOP RETURN NEXT rec; END LOOP;
    END IF;
  ELSE
    FOR rec IN SELECT row_to_json(j) FROM( SELECT 'missing required parameter' AS error ) as j LOOP RETURN NEXT rec; END LOOP;
  END IF;
  -- validate and process data_group_ids parameter
  IF $2 IS NOT NULL THEN
    dg_ids:= string_to_array($2, ',')::int[];
    -- validate the data groups id
    SELECT INTO valid_dg_ids array_agg(id)::int[] FROM classification c WHERE c.taxonomy_id = 1 AND _active=true AND id = ANY(dg_ids);
  ELSE
    IF $3 IS NOT NULL THEN
      SELECT INTO valid_dg_ids instance.data_group_ids FROM instance WHERE id = $3;
    END IF;
  END IF;

  -- if data groups are given return in-use classifications only
  IF array_length(valid_dg_ids, 1) > 0 THEN
    IF (valid_taxonomy._is_category) THEN
      execute_statement := 'SELECT at.classification_id as id, at.classification as c, at._code as code, at._iati_name as iati, count(DISTINCT at.parent_id) as ct,(SELECT array_to_json(array_agg(row_to_json(t))) FROM ( ' ||
	'	SELECT classification_id as id, classification as c, _code as code, _iati_name as iati, count(DISTINCT parent_id) as ct FROM _activity_taxonomies ' ||
	'	WHERE classification_parent_id = at.classification_id AND data_group_id = ANY(ARRAY[' || array_to_string(valid_dg_ids, ',') || ']) ';
      IF locations_only THEN
        execute_statement := execute_statement || 'AND id IN (SELECT activity_id FROM _location_lookup WHERE data_group_id = ANY(ARRAY[' || array_to_string(valid_dg_ids, ',') || '])) ';
      END IF;
      execute_statement := execute_statement || 'GROUP BY 1,2,3,4 )t ) as children ' ||
	 'FROM _activity_taxonomies at WHERE at.taxonomy_id = ' || $1 || 'AND data_group_id = ANY(ARRAY[' || array_to_string(valid_dg_ids, ',') || ']) ';
      IF locations_only THEN
        execute_statement := execute_statement || 'AND id IN (SELECT activity_id FROM _location_lookup WHERE data_group_id = ANY(ARRAY[' || array_to_string(valid_dg_ids, ',') || '])) ';
      END IF;
    ELSE
      execute_statement := 'SELECT classification_id as id, classification as c, _code as code, _iati_name as iati, count(DISTINCT id) as ct FROM _activity_taxonomies at WHERE at.taxonomy_id = ' || $1 || 
	' AND data_group_id = ANY(ARRAY[' || array_to_string(valid_dg_ids, ',') || ']) ';
      IF locations_only THEN
        execute_statement := execute_statement || 'AND id IN (SELECT activity_id FROM _location_lookup WHERE data_group_id = ANY(ARRAY[' || array_to_string(valid_dg_ids, ',') || '])) ';
      END IF;
    END IF;
    execute_statement := execute_statement || 'GROUP BY 1,2,3,4';
  -- otherwise return all classifications
  ELSE
    IF (valid_taxonomy._is_category) THEN
      execute_statement := 'SELECT classification_id as id, classification as c, _code as code, _iati_name as iati, null as ct,(SELECT array_to_json(array_agg(row_to_json(t))) FROM ( ' ||
	' SELECT classification_id as id, classification as c, _code as code, at._iati_name as iati, null as ct FROM _taxonomy_classifications WHERE classification_parent_id = tc.classification_id )t ) as children ' ||
	' FROM _taxonomy_classifications tc  WHERE taxonomy_id = ' || $1;
    ELSE
      execute_statement := 'SELECT classification_id as id, classification as c, _code as code, _iati_name as iati, null as ct FROM _taxonomy_classifications tc WHERE tc.taxonomy_id = ' || $1;
    END IF;
END IF;
		
  RAISE NOTICE 'Execute statement: %', execute_statement;			

  FOR rec IN EXECUTE 'SELECT row_to_json(j) FROM (' || execute_statement || ')j' LOOP  		
	RETURN NEXT rec;
  END LOOP;
 
EXCEPTION WHEN others THEN 
  GET STACKED DIAGNOSTICS error_msg = MESSAGE_TEXT;  
    RAISE NOTICE 'Internal Error - Contact your DBA with the following error message: %', error_msg;
    
END;$$ LANGUAGE plpgsql;
