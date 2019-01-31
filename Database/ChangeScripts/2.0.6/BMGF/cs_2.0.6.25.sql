/******************************************************************
Change Script 2.0.6.25 - Consolidated.
1. pmt_infobox_project_info - add location data.
******************************************************************/
INSERT INTO config(version, iteration, changeset) VALUES (2.0, 6, 25);

-- info box project general information
CREATE OR REPLACE FUNCTION pmt_infobox_project_info(project_id integer, tax_id integer)
RETURNS SETOF pmt_infobox_result_type AS 
$$
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
		      ,coalesce(p.opportunity_id, data_message) as grant_id
		      ,coalesce(pp.name, data_message) as org_name
		      ,coalesce(pp.url, data_message) as org_url
		      ,coalesce(fc.focus_crop, data_message) as focus_crop
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
		(select p.project_id, p.title, p.label, p.opportunity_id, p.tags, p.url
		from project p
		where p.project_id = $1 and p.active = true) p
		left join		
		-- participants
		(select pp.project_id, array_to_string(array_agg(o.name), ',') as name, array_to_string(array_agg(o.url), ',') as url
		from participation pp
		join organization o
		on pp.organization_id = o.organization_id
		left join participation_taxonomy ppt
		on pp.participation_id = ppt.participation_id
		join classification c
		on ppt.classification_id = c.classification_id 
		where c.taxonomy_id = (select taxonomy_id from taxonomy where name = 'Organisation Role') AND c.name = 'Accountable'
		AND pp.project_id = $1 and pp.active = true and o.active = true and c.active = true
		group by pp.project_id) pp
		on p.project_id = pp.project_id
		left join
		-- focus crop
		(select p.project_id, array_to_string(array_agg(c.name), ',') as focus_crop
		from project p 
		join project_taxonomy pt
		on p.project_id = pt.project_id
		join classification c
		on pt.classification_id = c.classification_id
		where c.taxonomy_id = (select taxonomy_id from taxonomy where name = 'Focus Crop')
		and p.project_id = $1 and p.active = true and c.active = true
		group by p.project_id) as fc
		on p.project_id = fc.project_id
	) j
	) LOOP		
		RETURN NEXT rec;
	END LOOP;
   END IF;
END;$$ LANGUAGE plpgsql;


-- info box project stats
CREATE OR REPLACE FUNCTION pmt_infobox_project_stats(project_id integer)
RETURNS SETOF pmt_infobox_result_type AS 
$$
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
		       ,coalesce(i.name, data_message) as initiative
		       ,f.amount as grant
		from
		-- project
		(select p.project_id, p.start_date, p.end_date
		from project p
		where p.project_id = $1) p
		left join
		-- initiative
		(select pt.project_id, array_to_string(array_agg(distinct c.name), ',') as  name
		from project_taxonomy pt
		join classification c
		on pt.classification_id = c.classification_id
		where c.taxonomy_id = (select taxonomy_id from taxonomy where name = 'Initiative')
		AND pt.project_id = $1
		group by pt.project_id) as i
		on p.project_id = i.project_id
		left join
		-- financials
		(select f.project_id, sum(f.amount) as amount
		from financial f
		where f.activity_id is null and f.project_id = $1
		group by f.project_id) as f
		on p.project_id = f.project_id
	) j
	) LOOP		
		RETURN NEXT rec;
	END LOOP;
   END IF;
END;$$ LANGUAGE plpgsql;
