/******************************************************************
Change Script 3.0.10.50
1. add new fields to boundary table: _type, _admin_level
******************************************************************/
INSERT INTO version(_version, _iteration, _changeset) VALUES (3.0, 10, 50);
-- select * from version order by _iteration desc, _changeset desc;

/******************************************************************
1. add new fields to boundary table: _type, _admin_level
******************************************************************/
ALTER TABLE boundary ADD COLUMN _type character varying;
ALTER TABLE boundary ADD COLUMN _admin_level integer;