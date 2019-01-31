/***********************************************************
  Testing CRP User Authentication Model
***********************************************************/
INSERT INTO role(name, description, read, "create", update, delete, super, security, created_by, updated_by) 
    VALUES ('Publisher', 'Publisher role. Currently no different than Editor. Placeholder for publish model.', TRUE, TRUE, TRUE, TRUE, FALSE, FALSE, 'CRP Role', 'CRP Role');
UPDATE role SET "delete" = true WHERE role_id = 2;
UPDATE "user" SET role_id = 3 WHERE user_id = 3;
SELECT * FROM role;

-- John Program Officer (Database Level Reader)
select * from pmt_edit_user(3,null,'{"email":"john@email.com", "username":"john", "password":"john1234", "first_name":"John", "last_name":"Program Officer"}', false);
-- Jane Program Officer (Database Level Reader)
select * from pmt_edit_user(3,null,'{"email":"jane@email.com", "username":"jane", "password":"jane1234", "first_name":"Jane", "last_name":"Program Officer"}', false);
-- Bob Administrator (Database Level Administrator)
select * from pmt_edit_user(3,null,'{"email":"bob@email.com", "username":"bob", "password":"bob1234", "first_name":"Bob", "last_name":"Administrator", "role_id":4}', false);

SELECT * FROM "user";

-- John Program Officer
select * from pmt_edit_user_project_role(6,4,5,15,null, false);-- CRP-2
select * from pmt_edit_user_project_role(6,4,2,16,null, false);-- CRP-4
-- Jane Program Officer
select * from pmt_edit_user_project_role(6,5,2,15,null, false);-- CRP-2
select * from pmt_edit_user_project_role(6,5,5,16,null, false);-- CRP-4
-- Bob Administrator
select * from pmt_edit_user_project_role(6,6,4,null,978, false);-- CRP (Data Group)

------------------------------------------------------------------
-- User			CRP-2(15)	CRP-4(16)	Taxonomy
-------------------------------------------------------------------
-- John Program Officer	Publisher	Editor
-- Jane Program Officer	Editor		Publisher	
-- Bob Administrator					Administrator for CRP (Data Group)-978
-- Super					

SELECT (select username from "user" where user_id = upr.user_id), 
(select label from project where project_id = upr.project_id), 
(select name from role where role_id=upr.role_id) FROM user_project_role upr;

-- pmt_user_auth
select * from pmt_user_auth('john','$2a$10$7x7KlEQ2L6tM.4Paigh/hOJh7XQRgAor4l62X5L527fkeg8Y0Q13y');
select * from pmt_user_auth('jane','$2a$10$wpcnTuPQ8jo.RFPI0L.WveTcYCX.nfca0EMYpjAJ66saRHyxw3U6W');
select * from pmt_user_auth('bob','$2a$10$Nl29XV2eNXyJ5LobdmiGPuL1ikOSTM.cAEX.ITL4Ri09uisyeg7Qq');

-- pmt_project_users
select * from pmt_project_users(15);
select * from pmt_project_users(16);
select * from pmt_project_users(2);

-- pmt_user
select * from pmt_user(4); 
select * from pmt_user(5); 
select * from pmt_user(6); 

-- pmt_users
select * from pmt_users();

-- pmt_edit_project;
select * from pmt_edit_project(4,null,'{"title": "testing", "url":"www.google.com"}', false);
select * from pmt_edit_project(6,null,'{"title": "testing", "url":"www.google.com"}', false);
select * from pmt_project_users(37);
select * from pmt_edit_project(6,37,null, true);
select * from pmt_edit_project(5,15,null, true);

select * from pmt_validate_user_authority(4, null, 'create');
select * from pmt_validate_user_authority(4, 15, 'create');
select * from pmt_validate_user_authority(4, 15, 'delete');
select * from pmt_validate_user_authority(6, 15, 'delete');

-- -- add two addtional users
-- select * from pmt_edit_user(3,null,'{"email":"info@spatialdev.com", "username":"administrator", "password":"administrator", "first_name":"administrator", "last_name":"(pmt testing user)", "role_id":4}', false);
-- select * from pmt_edit_user(3,null,'{"email":"info@spatialdev.com", "username":"publisher", "password":"publisher", "first_name":"publisher", "last_name":"(crp testing user)"}', false);

/*********************************************************** 
  Testing PMT User Authentication Model
***********************************************************/
-- add some data to my user for testing
INSERT INTO user_project_role (user_id, role_id, project_id) VALUES (34, 2, 732); -- BMGF
INSERT INTO user_project_role (user_id, role_id, project_id) VALUES (34, 2, 775); -- PSD
INSERT INTO user_project_role (user_id, role_id, project_id) VALUES (34, 3, 667); -- AGRA
INSERT INTO user_project_role (user_id, role_id, classification_id) VALUES (34, 2, 1068); -- AWG (Data Group)
INSERT INTO user_project_role (user_id, role_id, classification_id) VALUES (34, 2, 824); -- Access & Markets (Initiative)

UPDATE "user" SET role_id = 3 WHERE username = 'sparadee';
select * from role