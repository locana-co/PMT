/******************************************************************
Change Script 3.0.10.70
1. update instance table, add organization_id field
******************************************************************/
INSERT INTO version(_version, _iteration, _changeset) VALUES (3.0, 10, 70);
-- select * from version order by _iteration desc, _changeset desc;

/******************************************************************
 1. update instance table, add organization_id field
******************************************************************/
ALTER TABLE instance ADD COLUMN organization_id integer REFERENCES organization(id);