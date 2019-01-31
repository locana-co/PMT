/******************************************************************
Change Script 2.0.7.1.a
1. update bmgf application data after reload
******************************************************************/
INSERT INTO config(version, iteration, changeset) VALUES (2.0, 7, 1);
-- select * from config order by version, iteration, changeset, updated_date;

-- Set all users to Reader role
TRUNCATE TABLE user_role;
INSERT INTO user_role(user_id, role_id) SELECT user_id, (SELECT role_id FROM role WHERE name = 'Reader') FROM "user";

-- Update a small set of users to elevated
UPDATE user_role SET role_id = (SELECT role_id FROM role WHERE name = 'Super') WHERE user_id = (SELECT user_id from "user" WHERE username = 'sparadee');
UPDATE user_role SET role_id = (SELECT role_id FROM role WHERE name = 'Super') WHERE user_id = (SELECT user_id from "user" WHERE username = 'super');
UPDATE user_role SET role_id = (SELECT role_id FROM role WHERE name = 'Editor') WHERE user_id = (SELECT user_id from "user" WHERE username = 'editor');

-- encrypt passwords
UPDATE "user" SET password = crypt(password, gen_salt('bf', 10));
