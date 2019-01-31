-- updated
SELECT 
	filter.activity_id AS a_id
	, filter.title AS a_name
	, filter.description AS a_desc
	, filter.start_date as a_date1
	, f.amount
	, l.gaul 
	,(SELECT array_to_json(array_agg(row_to_json(o))) FROM 	(SELECT ot.organization_id as o_id, o.name, classification as c
	FROM organization_lookup ot JOIN taxonomy_classifications tc ON tc.classification_id = ANY(ot.classification_ids)
	JOIN organization o ON ot.organization_id = o.organization_id WHERE taxonomy = 'Organisation Role' AND ot.activity_id = filter.activity_id ) as o
	) organizations
	,(SELECT array_to_json(array_agg(row_to_json(z))) FROM 	(SELECT DISTINCT taxonomy as t, classification as c
	FROM organization_lookup ot JOIN taxonomy_classifications tc ON tc.classification_id = ANY(ot.classification_ids)
	WHERE taxonomy <> 'Organisation Role' AND ot.activity_id = filter.activity_id ) as z) taxonomy
FROM ( 
	SELECT DISTINCT t1.activity_id, a.title, a.description, a.start_date
	FROM  (SELECT * FROM organization_lookup ) as t1 
	JOIN (SELECT activity_id, title, description, start_date, end_date from activity) as a 
	ON t1.activity_id = a.activity_id  
	WHERE (classification_ids @> ARRAY[769]) OR (not (taxonomy_ids @> ARRAY[15]))
) as filter 
LEFT JOIN (
	SELECT activity_id, array_to_string(array_agg(gaul0_name || ', ' || gaul1_name), '; ') as gaul 
	FROM location_lookup 
	GROUP BY activity_id
) as l 
ON filter.activity_id = l.activity_id 
LEFT JOIN (
	SELECT activity_id, sum(amount) as amount 
	FROM financial 
	GROUP BY activity_id
) as f 
ON filter.activity_id = f.activity_id  
ORDER BY a_name ASC
LIMIT 10
OFFSET 0

select * from taxonomy_classifications where taxonomy = 'Country' -- Bolivia (50)
select * from pmt_data_groups()
-- select * from  pmt_activity_listview('769', '', '15', null,null, 'a_name ASC', 10, 0);

SELECT 	filter.activity_id AS a_id, filter.title AS a_name, f_orgs.orgs as f_orgs, i_orgs.orgs as i_orgs
	, tax1.classes as tax1
FROM ( 
	SELECT DISTINCT t1.activity_id, a.title
	FROM  (SELECT * FROM organization_lookup ) as t1 
	JOIN (SELECT activity_id, title from activity) as a 
	ON t1.activity_id = a.activity_id  
	WHERE (classification_ids @> ARRAY[769]) OR (not (taxonomy_ids @> ARRAY[15]))
) as filter 
LEFT JOIN (SELECT ot.activity_id, array_to_string(array_agg(DISTINCT o.name), ',') as orgs
	FROM organization_lookup ot JOIN taxonomy_classifications tc ON tc.classification_id = ANY(ot.classification_ids) 
	JOIN organization o ON ot.organization_id = o.organization_id WHERE taxonomy = 'Organisation Role' AND classification = 'Funding'
	GROUP BY ot.activity_id ) f_orgs ON f_orgs.activity_id = filter.activity_id
LEFT JOIN (SELECT ot.activity_id, array_to_string(array_agg(DISTINCT o.name), ',') as orgs
	FROM organization_lookup ot JOIN taxonomy_classifications tc ON tc.classification_id = ANY(ot.classification_ids) 
	JOIN organization o ON ot.organization_id = o.organization_id WHERE taxonomy = 'Organisation Role' AND classification = 'Implementing'
	GROUP BY ot.activity_id) i_orgs ON i_orgs.activity_id = filter.activity_id
LEFT JOIN
(
	SELECT  ot.activity_id, array_to_string(array_agg(DISTINCT tc.classification), ',') as classes
	FROM organization_lookup ot 
	JOIN taxonomy_classifications tc 
	ON tc.classification_id = ANY(ot.classification_ids)
	WHERE taxonomy_id = 15
	GROUP BY ot.activity_id
) tax1
ON tax1.activity_id = filter.activity_id
ORDER BY a_name ASC 
LIMIT 10 
