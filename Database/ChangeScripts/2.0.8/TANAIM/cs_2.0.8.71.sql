/******************************************************************
Change Script 2.0.8.71
1. tanaim_aaz - tanaim specific view for Agriculture Adminisrative
Zones.
******************************************************************/
INSERT INTO version(version, iteration, changeset) VALUES (2.0, 8, 71);
-- select * from version order by changeset desc;

CREATE OR REPLACE VIEW  tanaim_aaz AS
(select at.project_id, at.activity_id, at.title as activity_title, at.dg as data_group, at.tanaim_category as category, at.tanaim_sub_category as sub_category, l.location_id, l.lat_dd, l.long_dd,l.point, g.name as gaul_region, 
(
	case 
		when g.name = 'Arusha' then 'Northern' 
		when g.name = 'Dodoma' then 'Central'
		when g.name = 'Singida' then 'Central'
		when g.name = 'Dar es Salaam' then 'Eastern'
		when g.name = 'Kigoma' then 'Western'
		when g.name = 'Morogoro' then 'Eastern'
		when g.name = 'Pemba North' then 'Eastern'
		when g.name = 'Pemba South' then 'Eastern'
		when g.name = 'Pwani' then 'Eastern'
		when g.name = 'Tanga' then 'Eastern'
		when g.name = 'Unguja North' then 'Eastern'
		when g.name = 'Unguja South' then 'Eastern'
		when g.name = 'Unguja Urban West' then 'Eastern'
		when g.name = 'Kagera' then 'Lake'
		when g.name = 'Mara' then 'Lake'
		when g.name = 'Mwanza' then 'Lake'
		when g.name = 'Shinyanga' then 'Lake'
		when g.name = 'Arusha' then 'Northern'
		when g.name = 'Kilimanjaro' then 'Northern'
		when g.name = 'Manyara' then 'Northern'
		when g.name = 'Lindi' then 'Southern '
		when g.name = 'Mtwara' then 'Southern '
		when g.name = 'Iringa' then 'Southern Highlands'
		when g.name = 'Mbeya' then 'Southern Highlands'
		when g.name = 'Rukwa' then 'Southern Highlands'
		when g.name = 'Ruvuma' then 'Southern Highlands'
		when g.name = 'Tabora' then 'Western'
		else g.name end
) as AAZ
from
(select a.project_id, a.activity_id, a.title, dg.classification as dg, tanaim1.classification as tanaim_category, tanaim2.classification as tanaim_sub_category
from activity a
left join
(select pt.project_id, pt.classification_id, tc.classification
from project_taxonomy pt
join taxonomy_classifications tc
on pt.classification_id = tc.classification_id
where pt.classification_id IN (SELECT classification_id FROM taxonomy_classifications WHERE taxonomy = 'Data Group')) dg
on a.project_id = dg.project_id
left join(
select a.project_id, a.activity_id, pt.classification_id, tc.classification
from project_taxonomy pt
join activity a
on pt.project_id = a.project_id
join taxonomy_classifications tc
on pt.classification_id = tc.classification_id
where pt.classification_id IN (SELECT classification_id FROM taxonomy_classifications WHERE taxonomy = 'Category')
union all
select a.project_id, a.activity_id, at.classification_id, tc.classification
from activity_taxonomy at
join activity a
on at.activity_id = a.activity_id
join taxonomy_classifications tc
on at.classification_id = tc.classification_id
where at.classification_id IN (SELECT classification_id FROM taxonomy_classifications WHERE taxonomy = 'Category')
) tanaim1
on a.project_id = tanaim1.project_id and a.activity_id = tanaim1.activity_id
left join
(select at.activity_id, at.classification_id, tc.classification
from activity_taxonomy at
join taxonomy_classifications tc
on at.classification_id = tc.classification_id
where at.classification_id IN (SELECT classification_id FROM taxonomy_classifications WHERE taxonomy = 'Sub-Category')) tanaim2
on a.activity_id = tanaim2.activity_id
where a.active = true) as at
join location l
on at.activity_id = l.activity_id
join location_boundary lb
on l.location_id = lb.location_id
join gaul1 g
on g.feature_id = lb.feature_id
where l.location_id in (select location_id from location_taxonomy where classification_id = (select classification_id from taxonomy_classifications where taxonomy = 'Country' and classification = 'TANZANIA, UNITED REPUBLIC OF'))
and lb.boundary_id = (select boundary_id from boundary where spatial_table = 'gaul1')
and at.activity_id not in (select activity_id from activity_taxonomy where classification_id = (select classification_id from taxonomy_classifications where taxonomy = 'National/Local' and classification = 'National'))
order by 1,2);


-- update permissions
GRANT USAGE ON SCHEMA public TO pmt_read;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO pmt_read;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO pmt_read;
GRANT USAGE ON SCHEMA public TO pmt_write;
GRANT SELECT,INSERT ON ALL TABLES IN SCHEMA public TO pmt_write;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO pmt_write;