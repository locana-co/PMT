/******************************************************************
Change Script 2.0.6._

on hold until jubal talks with the client on editing workflow
1. 
******************************************************************/
UPDATE config SET changeset = _ , updated_date = current_date WHERE "version" = 2.0 AND iteration = 6;
-- SELECT pmt_version();

SELECT * FROM(
SELECT (xpath('/iati-activity/iati-identifier/text()', node.xml))[1]::text AS "iati-identifier"  
,(xpath('/iati-activity/reporting-org/text()', node.xml))[1]::text AS "reporting-org", (xpath('/iati-activity/reporting-org/@type', node.xml))[1]::text AS "reporting-org_type"
,(xpath('/iati-activity/title/text()', node.xml))[1]::text AS "title"
,(xpath('/iati-activity/participating-org/text()', node.xml))::text[] AS "participating-org",(xpath('/iati-activity/participating-org/@role', node.xml))::text[] AS "participating-org_role",(xpath('/iati-activity/participating-org/@type', node.xml))::text[] AS "participating-org_type"
,(xpath('/iati-activity/recipient-country/text()', node.xml))::text[] AS "recipient-country",(xpath('/iati-activity/recipient-country/@code', node.xml))::text[] AS "recipient-country_code" ,(xpath('/iati-activity/recipient-country/@percentage', node.xml))::text[] AS "recipient-country_percentage"
,(xpath('/iati-activity/description/text()', node.xml))[1]::text AS "description"
,(xpath('/iati-activity/activity-date/@iso-date', node.xml))::text[] AS "activity-date", (xpath('/iati-activity/activity-date/@type', node.xml))::text[] AS "activity-date_type"
,(xpath('/iati-activity/activity-status/text()', node.xml))[1]::text AS "activity-status",(xpath('/iati-activity/activity-status/@code', node.xml))[1]::text AS "activity-status_code"
,(xpath('/iati-activity/sector/text()', node.xml))::text[] AS "sector", (xpath('/iati-activity/sector/@code', node.xml))::text[] AS "sector_code"
,(xpath('/iati-activity/transaction', node.xml))::xml[] AS "transaction"
,(xpath('/iati-activity/contact-info', node.xml))::xml[] AS "contact-info"
,(xpath('/iati-activity/location', node.xml))::xml[] AS "location"
,(xpath('/iati-activity/budget', node.xml))::xml[] AS "budget"
FROM(SELECT unnest(xpath('/iati-activities/iati-activity', xml))::xml AS xml from xml
WHERE project_id = 1) AS node) foo
WHERE title = '' or title is null


select a.project_id, a.activity_id, a.title, a.description, a.start_date, a.end_date, a.active
from activity a
left join(
select * from activity_taxonomy at
join classification c
on at.classification_id = c.classification_id
where taxonomy_id = (select taxonomy_id from taxonomy where name = 'Sector')
) foo
on a.activity_id = foo.activity_id
where foo.name is null and project_id = 3
order by a.project_id, a.activity_id, a.title

select * from pmt_data_groups();
SELECT xml_id, project_id, action, type, taxonomy, data_group, error FROM xml where project_id is not null order by project_id;
