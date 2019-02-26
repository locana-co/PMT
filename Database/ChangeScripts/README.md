# Change Scripts

Change scripts are how we implement change management in the development of the PMT Database. To learn more about 
this process check out some of the below links:

- [Change Management in the PMT Database](#change-managment-in-the-pmt-database)

- [Change Script Process](#change-script-process)

- [Change Script Log](#change-scripts-log)

The current version is: **_3.0_**

The current iteration is: **_10_**

## Change Management in the PMT Database

Databases cannot participate in a code repository in the same way that an application does, where the code repository
provides a mechanism for version control and release management of source code. Unlike applications, databases are not
a collection of textual documents that are executed. Databases are an organized collection of data within a software
application. However the PMT database, like an application, is constantly under-going development, improvements and bug 
fixes and is in need of a method for version control and release management. This is especially important for PMT, 
because PMT is not just single database. PMT is a data model with specific tables, views and functions that are 
implemented in numerous PMT instances. Many of our clients have a PMT database and all of these databases need a 
mechanism for keeping up with the latest development. 

In order to meet this need, PMT uses change scripts to implement development changes. Change scripts are a change or a 
set of changes to the PMT database. Change scripts contain changes to the database model, functions, indexes, 
constraints or views. Change scripts do not contain changes to "data". **ALL** changes to the PMT database are done 
through a change script. Changes are **NEVER** implemented directly on the database through a database tool such as 
pgAdmin. Every change script inserts a record into the version table, so that for every instance of the PMT database 
we know what changes have been implemented on that instance.

The change script log is a listing of all the changes included in every change script. This is a running history of all
PMT changes. The version of the database indicates a major database version. The database iteration indicators a minor
database change. The database changeset is the number of change scripts occurring within a version and iteration of the
database. All change scripts should be executed in order by version, iteration and changeset.

## Change Script Process

Follow the below process for development on the PMT database:

1. Create a copy of the change script template file [cs\_template.3.0](cs_template.3.0).
2. Place the copy into the current database iteration's "InReview" folder: **3.0.10/InReview**
3. Rename the copy, following the change script naming convention of cs\_.3.0.10.<number of next change script>.sql. Note:
make sure to check the log for the next change set number.
4. Open the change script file and update title replacing the underscore (\_) with the number of the change script: 
  "Change Script 3.0.10.\_ "
5. Update the INSERT statement for version replacing the underscore (\_) with the change set number as well: 
```INSERT INTO version(version, iteration, changeset) VALUES (3.0, 10, _);```
6. Script changes below the header.
7. Record a summary of changes to **each entity**, see below example:
  ```
  /******************************************************************

  Change Script 2.0.9.4
  1. pmt_contacts - update to return only active contacts.
  2. pmt_orgs - update to return only active organizations.

  ******************************************************************/
  ```
8. Push changes to the repo and notify the database administrator the change script is ready for review.
9. Make any changes requested by the database administrator after review.

After a change script is complete, tested and has been reviewed, the database administrator will log the change script and
execute the change script on the appropriate databases instances.

Notable information regarding the development process:
* All development should always be done on a local instance of PMT, **NEVER** on the server.
* Changes that target unique aspects of client instance should be in a separate change script.
* Ensure you local instance of PMT is up-to-date with the latest change scripts.

## Change Scripts Log

### Database Version 3.0
|Iteration	|Changeset	|Entity			|Action			|Description	|
|:-----------:|:-----------:|:----------------|:----------------|:----------------------------------------------------------------	|
|	10	|	107	|	pmt_activity_detail	|	Additional Functionality	|	Update function to add _direct_phone.	|
|	10	|	107	|	pmt_activity	|	Additional Functionality	|	Update function to add _direct_phone.	|
|	10	|	106	|	pmt_classifications	|	Additional Functionality	|	Update function to address bug in SQL.	|
|	10	|	105	|	AGRA UPDATE	|	SKIPPABLE	|	NEEDS REVIEW & TESTING	|
|	10	|	104	|	pmt_validate_organizations	|	Additional Functionality	|	Update function for latest data model.	|
|	10	|	104	|	pmt_replace_participation	|	New Function	|	Create function to allow for full reassignment of participation records by Organisation Role.	|
|	10	|	104	|	pmt_activity_detail	|	Removing Function	|	Remove overloaded function.	|
|	10	|	104	|	pmt_activity_details	|	New Function	|	Create function to replace overloaded pmt_activity_detail(int[])	|
|	10	|	104	|	pmt_activities_all	|	New Function	|	Create function to support call for deactivated activities.	|
|	10	|	103	|	pmt_activity_detail	|	New Function	|	Create overloaded method to accept array of ids.	|
|	10	|	103	|	pmt_boundary_match	|	New Function	|	Create function to match location to boundaries.	|
|	10	|	103	|	_activity_taxonomies	|	Additional Functionality	|	Update to return _code.	|
|	10	|	103	|	pmt_classifications	|	Additional Functionality	|	Update function to return _code.	|
|	10	|	102	|	pmt_users	|	Additional Functionality	|	Update function to return new role.	|
|	10	|	102	|	pmt_edit_organization	|	Additional Functionality	|	Update function to authenticate properly.	|
|	10	|	102	|	pmt_validate_user_authority	|	Additional Functionality	|	Update function to base authority on role settings not role names.	|
|	10	|	101	|	pmt_classification_count	|	Additional Functionality	|	Update function to remove inactive child records.	|
|	10	|	101	|	pmt_taxonomy_search	|	Additional Functionality	|	Update function to exclude inactive.	|
|	10	|	100	|	pmt_taxonomy_search	|	Additional Functionality	|	Update function to remove exclusions.	|
|	10	|	99	|	pmt_activity_family_titles	|	Additional Functionality	|	Update function to allow classification_id assignment for given listing.	|
|	10	|	98	|	pmt_get_valid_id	|	New Function	|	Create new function to return valid parent activity.	|
|	10	|	98	|	pmt_edit_participation	|	Additional Functionality	|	Update function to allow other organization based taxonomies (Organisation Type & Implementing Types)	|
|	10	|	98	|	pmt_activity_family_titles	|	New Function	|	Create new function to support listing of related activities.	|
|	10	|	98	|	pmt_partner_pivot	|	Additional Functionality	|	Update function to ensure proper filtering of parent and child activities.	|
|	10	|	98	|	pmt_stat_activity_by_tax	|	Additional Functionality	|	Update function to address bug in classification filter.	|
|	10	|	97	|	pmt_classification_count	|	New Function	|	New function to provide filtered counts of classifications by taxonomy.	|
|	10	|	97	|	pmt_classification_search	|	New Function	|	New function to provide filtered list of classifications by taxonomy.	|
|	10	|	97	|	pmt_taxonomy_count	|	New Function	|	New function to provide filtered counts of taxonomies.	|
|	10	|	97	|	pmt_taxonomy_search	|	New Function	|	New function to provide filtered list of taxonomies.	|
|	10	|	97	|	pmt_edit_classification	|	New Function	|	New function to support editing of classifications.	|
|	10	|	97	|	pmt_edit_taxonomy	|	New Function	|	New function to support editing of taxonomies	|
|	10	|	97	|	pmt_taxonomies	|	Additional Functionality	|	Update function for latest data model.	|
|	10	|	97	|	taxonomy	|	Data Model	|	Updated taxonomy table to include fields to support ownership.	|
|	10	|	97	|	pmt_is_data_groups	|	New Function	|	New function to support data group validation.	|
|	10	|	96	|	pmt_activity_detail	|	Additional Functionality	|	Update function to match output from pmt_activity.	|
|	10	|	96	|	pmt_activity	|	Additional Functionality	|	Update function pmt_activity to add contact title.	|
|	10	|	96	|	pmt_edit_detail_taxonomy	|	New Function	|	New function for editing detail taxonomies.	|
|	10	|	96	|	pmt_validate_details	|	New Function	|	New function for validating detail ids.	|
|	10	|	95	|	pmt_activity	|	Additional Functionality	|	Update function to add implmenting type.	|
|	10	|	95	|	detail_taxonomy	|	Data Model	|	Update table for data model 3.0.	|
|	10	|	94	|	pmt_activities	|	Additional Functionality	|	Update function to address incorrect sum of investment data.	|
|	10	|	93	|	pmt_consolidate_orgs	|	Additional Functionality	|	Update function to adhere to PMT requirements and update missing entities.	|
|	10	|	93	|	pmt_stat_activity_by_tax	|	Additional Functionality	|	Update function  to addrss bug in classification filter.	|
|	10	|	93	|	pmt_edit_detail	|	Additional Functionality	|	Update function to adhere to new data model.	|
|	10	|	93	|	pmt_validate_detail	|	Additional Functionality	|	Update function to adhere to new data model.	|
|	10	|	92	|	pmt_stat_invest_by_funder	|	Additional Functionality	|	Update functionn to properly filter child activities.	|
|	10	|	92	|	pmt_org_inuse	|	Additional Functionality	|	Remove location requirement.	|
|	10	|	91	|	pmt_activity	|	Additional Functionality	|	Add organization type taxonomy.	|
|	10	|	90	|	pmt_activity_detail	|	Additional Functionality	|	Address counting issues (parent -> child).	|
|	10	|	90	|	pmt_activities	|	Additional Functionality	|	Address counting issues (parent -> child).	|
|	10	|	90	|	pmt_activity_ids_by_boundary	|	Additional Functionality	|	Address counting issues (parent -> child).	|
|	10	|	90	|	pmt_locations_for_boundaries	|	Additional Functionality	|	Address counting issues (parent -> child).	|
|	10	|	90	|	pmt_activity_count	|	Additional Functionality	|	Address counting issues (parent -> child).	|
|	10	|	89	|	pmt_edit_organization	|	Additional Functionality	|	Fix error with nulls.	|
|	10	|	89	|	pmt_consolidate_orgs	|	New Function	|	Create new function to allow consolidation of organizations.	|
|	10	|	89	|	pmt_activity_detail	|	Additional Functionality	|	Add organization taxonomy.	|
|	10	|	89	|	pmt_users	|	Additional Functionality	|	Fix field order causing mix of phone/email.	|
|	10	|	89	|	pmt_classifications	|	Additional Functionality	|	Return associated child classification if parent.	|
|	10	|	89	|	_activity_taxonomies	|	Data Model	|	Add parent id fields.	|
|	10	|	88	|	pmt_edit_contact	|	Additional Functionality	|	Update function to adhere to new data model.	|
|	10	|	88	|	pmt_exists_activity_contact	|	New Function	|	Create new function to determine existing relationships to a contact.	|
|	10	|	88	|	pmt_validate_contacts	|	Additional Functionality	|	Update function to adhere to new data model.	|
|	10	|	88	|	pmt_validate_contact	|	Additional Functionality	|	Update function to adhere to new data model.	|
|	10	|	88	|	pmt_contacts	|	Additional Functionality	|	Update function and rename output fields.	|
|	10	|	88	|	pmt_activity_detail	|	Additional Functionality	|	Update returned contact information.	|
|	10	|	87	|	pmt_find_users	|	Additional Functionality	|	Update function to return phone.	|
|	10	|	87	|	pmt_users	|	Additional Functionality	|	Update functions (including overloaded method) to return phone.	|
|	10	|	87	|	users	|	Data Model	|	Add new field for phone to users table.	|
|	10	|	87	|	pmt_orgs	|	Additional Functionality	|	Update function to add url.	|
|	10	|	87	|	pmt_edit_organization	|	Additional Functionality	|	Update function to adhere to new data model.	|
|	10	|	87	|	pmt_boundary_search	|	New Function	|	Create a new function to search PMT boundary features by name and return matches.	|
|	10	|	86	|	pmt_contacts	|	Additional Functionality	|	Update function to adhere to new data model.	|
|	10	|	85	|	pmt_orgs	|	Additional Functionality	|	Update to return label.	|
|	10	|	85	|	json_typeof	|	New Function	|	New function to support evaluation of JSON types.	|
|	10	|	85	|	_filter_taxonomies	|	Additional Functionality	|	Update to return only parent ids.	|
|	10	|	85	|	_activity_contacts	|	Additional Functionality	|	Update to include contact id.	|
|	10	|	84	|	pmt_edit_activity	|	Additional Functionality	|	Update function to add user authentication on new activities when user role is Editor.	|
|	10	|	83	|	pmt_users	|	Additional Functionality	|	Update both pmt_users methods to exclude the public access user.	|
|	10	|	82	|	pmt_edit_location	|	Additional Functionality	|	Update function to automatically assign location taxonomies as appropriate.	|
|	10	|	82	|	pmt_refresh_views	|	New Function	|	New function to refresh all materialized views.	|
|	10	|	81	|	pmt_activities	|	Additional Functionality	|	Update function to address error in returning financial information.	|
|	10	|	81	|	pmt_upd_boundary_features	|	Additional Functionality	|	Fix error in function to ensure location taxonomy is grabbed for the location feature, not just intersected features.	|
|	10	|	80	|	_data_change_report	|	Data Model	|	Update view to include all new tables.	|
|	10	|	79	|	pmt_users	|	Additional Functionality	|	Update overloaded pmt_users method to include classifications information.	|
|	10	|	78	|	pmt_recalculate_location_boundaries	|	Removing Function	|	Rename to pmt_recalculate_location_boundaries to pmt_update_location_boundries and delete duplicated function pmt_update_location_boundries.	|
|	10	|	78	|	pmt_user	|	Removing Function	|	Remove functions that will not be updated for 3.0.	|
|	10	|	78	|	pmt_countries	|	Removing Function	|	Remove functions that will not be updated for 3.0.	|
|	10	|	78	|	pmt_upd_boundary_features	|	Additional Functionality	|	Addressing bug in function.	|
|	10	|	78	|	pmt_edit_location	|	Additional Functionality	|	Updating function for new data model and application requirements.	|
|	10	|	78	|	pmt_full_record	|	Additional Functionality	|	Updating function to return participation id. Rename to pmt_activity_detail.	|
|	10	|	78	|	pmt_edit_participation	|	Additional Functionality	|	Updating function for new data model and application requirements.	|
|	10	|	78	|	pmt_edit_financial_taxonomy	|	Additional Functionality	|	Updating function for new data model and application requirements.	|
|	10	|	78	|	pmt_edit_financial	|	Additional Functionality	|	Updating function for new data model and application requirements.	|
|	10	|	78	|	pmt_edit_activity_taxonomy	|	Additional Functionality	|	Updating function for new data model and application requirements.	|
|	10	|	78	|	pmt_edit_activity	|	Additional Functionality	|	Updating function for new data model and application requirements.	|
|	10	|	78	|	pmt_validate_participation	|	Additional Functionality	|	Updating function for new data model and application requirements.	|
|	10	|	78	|	pmt_validate_financials	|	Additional Functionality	|	Updating function for new data model and application requirements.	|
|	10	|	78	|	pmt_validate_financial	|	Additional Functionality	|	Updating function for new data model and application requirements.	|
|	10	|	78	|	pmt_validate_taxonomies	|	Additional Functionality	|	Updating function for new data model and application requirements.	|
|	10	|	78	|	_user_instances	|	Additional Functionality	|	Add data group information.	|
|	10	|	78	|	pmt_activate_activity	|	Additional Functionality	|	Updating function for new data model and application requirements.	|
|	10	|	78	|	pmt_purge_activity	|	Additional Functionality	|	Updating function for new data model and application requirements.	|
|	10	|	78	|	pmt_validate_activity	|	Additional Functionality	|	Updating function for new data model and application requirements.	|
|	10	|	78	|	pmt_validate_user_authority	|	Additional Functionality	|	Update function to use correct logic for create authorization.	|
|	10	|	77	|	pmt_users	|	Additional Functionality	|	Update overloaded method to include authorization information.	|
|	10	|	76	|	pmt_upd_boundary_features	|	Additional Functionality	|	Update function to allow global boundary locations intersection of a private boundary.	|
|	10	|	76	|	pmt_update_location_boundries	|	New Function	|	New function to support regeneration of location boundary features without a record update.	|
|	10	|	76	|	pmt_export_tanaim	|	Additional Functionality	|	Update function to address missing exported elements.	|
|	10	|	76	|	pmt_full_record	|	New Function	|	Create a new function to get activity details specifically for editing.	|
|	10	|	75	|	pmt_validate_username	|	New Function	|	New function to validate username is available.	|
|	10	|	74	|	pmt_classifications	|	Additional Functionality	|	Update funtion to allow instance id parameter.	|
|	10	|	73	|	pmt_edit_user_activity	|	New Function	|	New function to support management of user authorizations on activities.	|
|	10	|	73	|	user_activity	|	Data Model	|	Add unique constraint to table for user_id, activity_id & classification_id.	|
|	10	|	73	|	pmt_user_auth	|	Additional Functionality	|	Update function to ensure only authorized data groups are included in autorizations for taxonomies.	|
|	10	|	73	|	pmt_validate_user_authority	|	Additional Functionality	|	Update function to support new permissions model.	| 
|	10	|	72	|	user_instance	|	Data Model	|	Set role_id as required.	|
|	10	|	72	|	users	|	Data Model	|	Set first & last name fields as required.	|
|	10	|	72	|	pmt_find_users	|	New Function	|	Create new function function to provide validation assistance for duplication of users.	|
|	10	|	71	|	instance	|	Additional Functionality	|	Update table to add not null constraint to organization_id.	|
|	10	|	71	|	pmt_user_orgs	|	Additional Functionality	|	Update function to accept instance id and only include any organization in use by the data groups or users of the instance.	|
|	10	|	70	|	instance	|	Data Model	|	Update table adding organization_id.	|
|	10	|	69	|	pmt_edit_user	|	Additional Functionality	|	Update function to support new permissions model.	|
|	10	|	69	|	pmt_users	|	New Function	|	New overloaded method to support filtering by instance.	|
|	10	|	69	|	pmt_users	|	Additional Functionality	|	Update function to support new permissions model.	|
|	10	|	69	|	_user_instances	|	Data Model	|	New core view for users by role and instance.	|
|	10	|	69	|	pmt_user_auth	|	Additional Functionality	|	Update function to support new permissions model.	|
|	10	|	68	|	role	|	Data Model	|	Update role table with check constraint to ensure unique name.	|
|	10	|	68	|	user_log	|	Data Model	|	Update table adding instance id.	|
|	10	|	68	|	user_activity_role	|	Data Model	|	Rename table user_activity_role to user_activity. Drop the role_id field.	|
|	10	|	68	|	user_instance	|	Data Model	|	Create new user_instance table, to represent user roles in instances.	|
|	10	|	68	|	instance	|	Data Model	|	Create new instance table, to store PMT Application instances.	|
|	10	|	68	|	pmt_are_data_group	|	New Function	|	Create new function to validate an array of data groups.	|
|	10	|	68	|	users	|	Data Model	|	Update the users table, dropping role_id.	|
|	10	|	67	|	pmt_recalculate_location_boundaries	|	New Function	|	Create new function to support recalculating the intersected boundaries for a location when no record field changes are needed.	|
|	10	|	66	|	pmt_stat_activity_by_tax	|	Additional Functionality	|	Update function to properly sort null values.	|
|	10	|	65	|	pmt_upd_boundary_features	|	Additional Functionality	|	Update function to only execute when boundary feature or point is updated.	|
|	10	|	65	|	pmt_upd_geometry_formats	|	Additional Functionality	|	Update function to only execute when boundary feature or point is updated.	|
|	10	|	65	|	pmt_activity	|	Additional Functionality	|	Update function to add _admin_level.	|
|	10	|	64	|	pmt_classifications	|	New function	|	Create new function to return classifications for a single taxonomy with usage counts.	|
|	10	|	64	|	pmt_tax_inuse	|	Removing Function	|	Remove functions that will not be updated for 3.0.	|
|	10	|	63	|	pmt_activities	|	Additional Functionality	|	Update function to add boundary filter.	|
|	10	|	63	|	pmt_locations_for_boundaries	|	Additional Functionality	|	Update function to correct parameter validation error.	|
|	10	|	63	|	pmt_upd_boundary_features	|	Additional Functionality	|	Update function to alter logic to only collect boundary features for boundaries appropriate for mapping level.	|
|	10	|	63	|	pmt_boundary_hierarchy	|	Additional Functionality	|	Update function to allow filter for in-use features.	|
|	10	|	63	|	boundary	|	Data Model	|	Add new field: _group.	|
|	10	|	63	|	pmt_activity	|	Additional Functionality	|	Update function to remove _feature_area.	|
|	10	|	63	|	location_boundary	|	Data Model	|	Remove _feature_area from table.	|
|	10	|	63	|	tanaim_nbs	|	Data Model	|	Remove _feature_area from view.	|
|	10	|	63	|	tanaim_aaz	|	Data Model	|	Remove _feature_area from view.	|
|	10	|	63	|	_location_boundary_features	|	Data Model	|	Remove _feature_area from view.	|
|	10	|	63	|	tanaim_activity	|	Removing Function	|	Remove functions that will not be updated for 3.0.	|
|	10	|	63	|	pmt_stat_pop_by_district	|	Removing Function	|	Remove functions that will not be updated for 3.0.	|
|	10	|	63	|	pmt_stat_partner_network	|	Removing Function	|	Remove functions that will not be updated for 3.0.	|
|	10	|	63	|	pmt_stat_orgs_by_district	|	Removing Function	|	Remove functions that will not be updated for 3.0.	|
|	10	|	63	|	pmt_stat_orgs_by_activity	|	Removing Function	|	Remove functions that will not be updated for 3.0.	|
|	10	|	63	|	pmt_stat_locations	|	Removing Function	|	Remove functions that will not be updated for 3.0.	|
|	10	|	63	|	pmt_stat_counts	|	Removing Function	|	Remove functions that will not be updated for 3.0.	|
|	10	|	63	|	pmt_stat_activity_by_district	|	Removing Function	|	Remove functions that will not be updated for 3.0.	|
|	10	|	63	|	pmt_sector_compare	|	Removing Function	|	Remove functions that will not be updated for 3.0.	|
|	10	|	63	|	pmt_locations_by_tax	|	Removing Function	|	Remove functions that will not be updated for 3.0.	|
|	10	|	63	|	pmt_locations_by_org	|	Removing Function	|	Remove functions that will not be updated for 3.0.	|
|	10	|	63	|	pmt_activity_listview_ct	|	Removing Function	|	Remove functions that will not be updated for 3.0.	|
|	10	|	63	|	pmt_activity_listview	|	Removing Function	|	Remove functions that will not be updated for 3.0.	|
|	10	|	63	|	pmt_activities_by_tax	|	Removing Function	|	Remove functions that will not be updated for 3.0.	|
|	10	|	63	|	location	|	Data Model	|	Add constraints to _point and _admin_level fields.	|
|	10	|	62	|	upd_geometry_formats	|	Additional Functionality	|	Update trigger function upd_geometry_formats to remove georef calculations.	|
|	10	|	62	|	location	|	Data Model	|	Add new fields: _admin0, _admin_level.	|
|	10	|	62	|	location	|	Data Model	|	Remove fields: _georef, _geographic_id, _geographic_level.	|
|	10	|	62	|	_active_activities	|	Data Model	|	Update the _active_activities view to remove location fields that will be removed.	|
|	10	|	62	|	map	|	Data Model	|	Drop the map table from the data model.	|
|	10	|	62	|	_data_loading_report	|	Data Model	|	Remove the map table from the _data_loading_report view.	|
|	10	|	61	|	pmt_boundary_feature	|	Additional Functionality	|	Update function to provide feature information for all non-standard boundaries.	|
|	10	|	60	|	pmt_stat_by_org	|	Additional Functionality	|	Update function to return activity ids.	|
|	10	|	59	|	pmt_stat_activity_by_tax	|	Additional Functionality	|	Update function to return activity ids.	|
|	10	|	58	|	pmt_activity_count	|	Additional Functionality	|	Update function to address bug when sending activity_ids parameters.	|
|	10	|	57	|	pmt_filter	|	Additional Functionality	|	Update function to to ensure AND across filters and OR within filters.	|
|	10	|	57	|	pmt_stat_activity_by_tax	|	Additional Functionality	|	Update function to add record limit and proper calculation of aggregated classification information.	|
|	10	|	56	|	pmt_activity_ids_by_boundary	|	Additional Functionality	|	Update function to address error in returning parent activities.	|
|	10	|	55	|	pmt_activity_count	|	Additional Functionality	|	Update function to only count parent activities.	|
|	10	|	55	|	pmt_activity_ids_by_boundary	|	Additional Functionality	|	Update function to only return parent activities.	|
|	10	|	55	|	pmt_locations_for_boundaries	|	Additional Functionality	|	Update function to return parent activity counts.	|
|	10	|	55	|	_filter_boundaries	|	Additional Functionality	|	Update view to add parent id.	|
|	10	|	54	|	pmt_activity_titles	|	New function	|	Create function to return title list for activities.	|
|	10	|	54	|	pmt_stat_invest_by_funder	|	Additional Functionality	|	Update function to return activity ids.	|
|	10	|	54	|	pmt_filter	|	Additional Functionality	|	Update function to address mutliple classification filter bug.	|
|	10	|	53	|	pmt_activities	|	Additional Functionality	|	Update function to remove duplicate providers and update return object to reduce size.	|
|	10	|	53	|	pmt_overview_stats	|	Additional Functionality	|	Update function to allow multiple features ids.	|
|	10	|	53	|	pmt_filter	|	Additional Functionality	|	Update function to address bug in multiple organization parameters for different roles.	|
|	10	|	53	|	pmt_activities_by_polygon	|	Additional Functionality	|	Update function to add activity_ids and boundary filters.	|
|	10	|	53	|	pmt_activity_count	|	Additional Functionality	|	Update function to add organization id filter (without role).	|
|	10	|	53	|	pmt_activity_ids_by_boundary	|	Additional Functionality	|	Update function to add organization id filter (without role).	|
|	10	|	53	|	pmt_locations_for_boundaries	|	Additional Functionality	|	Update function to add organization id filter (without role).	|
|	10	|	52	|	pmt_activities	|	Additional Functionality	|	Update pmt_activities to add activity ids filter.	|
|	10	|	51	|	pmt_global_search	|	Additional Functionality	|	Updated function to include a data group filter and to return only an array of activity ids.	|
|	10	|	51	|	pmt_activity_count	|	Additional Functionality	|	Updated function to include an activity id and boundary filter.	|
|	10	|	51	|	pmt_activity_ids_by_boundary	|	Additional Functionality	|	Updated function to include an activity id and boundary filter.	|
|	10	|	51	|	pmt_locations_for_boundaries	|	Additional Functionality	|	Updated function to include an activity id and boundary filter.	|
|	10	|	51	|	pmt_boundary_hierarchy	|	New function	|	New function for constructing a nested boundary menu.	|
|	10	|	50	|	boundary	|	Data Model	|	Add new fields to boundary table: _type, _admin_level	|
|	10	|	49	|	pmt_boundary_pivot	|	Additional Functionality	|	Update funtion to address issues.	|
|	10	|	48	|	pmt_boundary_feature	|	New function	|	New function pmt_boundary_feature to provide feature information for a specific boundary feature.	|
|	10	|	47	|	pmt_activities	|	Additional Functionality	|	Update function to add start and end dates.	|
|	10	|	46	|	pmt_stat_activity_by_tax	|	Additional Functionality	|	Update pmt_stat_activity_by_tax address errors in calculations.	|
|	10	|	46	|	_activity_family_taxonomies	|	Data Model	|	Create materialized view _activity_family_taxonomies to support taxonomy queries on parent -> child relationships where financials are on the parent only and taxonomies are on all levels.	|
|	10	|	46	|	_activity_taxonomies	|	Data Model	|	Update _activity_taxonomies view to add _field field.	|
|	10	|	46	|	pmt_overview_stats	|	Additional Functionality	|	Update pmt_overview_stats to address errors investment aggregations.	|
|	10	|	46	|	pmt_activity_by_invest	|	Additional Functionality	|	Update pmt_activity_by_invest function properly query top activities based on fiancial information from the parent, while considering all activity locations.	|
|	10	|	46	|	_activity_family_finacials	|	Data Model	|	Create materialized view _activity_family_finacials to support finanaical queries on parent -> child relationships where financials are on the parent only.	|
|	10	|	46	|	_activity_family	|	Data Model	|	Create view _activity_family to support parent -> child queries.	|
|	10	|	45	|	pmt_boundary_pivot	|	Additional Functionality	|	Updating function to address errors.	|
|	10	|	45	|	_location_boundary_features	|	Data Model	|	Add feature id to view.	|
|	10	|	44	|	pmt_stat_activity_by_tax	|	Additional Functionality	|	Updating function to add toggle for aggregating children.	|
|	10	|	43	|	pmt_activity_by_invest	|	Additional Functionality	|	Updating function to remove children and allow requested fields to be returned.	|
|	10	|	42	|	pmt_overview_stats	|	Additional Functionality	|	Updating function to remove children from activity and finanical counts.	|
|	10	|	42	|	_activity_taxonomies	|	Additional Functionality	|	Updating to include parent_id.	|
|	10	|	42	|	_activity_participants	|	Additional Functionality	|	Updating to include parent_id.	|
|	10	|	42	|	_activity_financials	|	Additional Functionality	|	Updating to include parent_id.	|
|	10	|	41	|	pmt_upd_boundary_features	|	Additional Functionality	|	Update trigger to allow custom points for polygon features.	|
|	10	|	40	|	_filter_unassigned	|	Data Model	|	Update filter view to address activities with no locations and those with no taxonomy assignments.	|
|	10	|	39	|	pmt_boundary_pivot	|	New function	|	Create new function to pivot organization data on taxonomy and boundary.	|
|	10	|	38	|	pmt_activity_by_invest	|	New function	|	Create new function to provide top x activities by investment amount.	|
|	10	|	37	|	pmt_stat_activity_by_tax	|	Additional Functionality	|	Update function to address calculation errors.	|
|	10	|	37	|	_taxonomy_xwalks	|	Data Model	|	Update view to correct duplication issue.	|
|	10	|	37	|	pmt_update_crosswalks	|	New function	|	Create new function to refresh crosswalk data for a data group.	|
|	10	|	36	|	pmt_overview_stats	|	Additional Functionality	|	Update function to allow region filter.	|
|	10	|	35	|	pmt_stat_by_org	|	New function	|	Create new function to provide activity counts by organization and role.	|
|	10	|	35	|	pmt_stat_invest_by_funder	|	Additional Functionality	|	Update function to use region filter over classification, add record limit parameter.	|
|	10	|	35	|	pmt_stat_activity_by_tax	|	Additional Functionality	|	Update function to allow region filter.	|
|	10	|	34	|	pmt_export_tanaim	|	Additional Functionality	|	Update function to use filter string function.	|
|	10	|	34	|	pmt_export_ethaim	|	Additional Functionality	|	Update function to use filter string function.	|
|	10	|	34	|	pmt_export_bmgf	|	Additional Functionality	|	Update function to use filter string function.	|
|	10	|	34	|	pmt_export	|	Additional Functionality	|	Update function to use filter string function.	|
|	10	|	34	|	pmt_filter_string	|	New function	|	New function to support centralized funcitonality for formating filter strings on exports.	|
|	10	|	33	|	_activity_financials	|	Data Model	|	New financial view.	|
|	10	|	33	|	pmt_overview_stats	|	New function	|	New function to provide overview statistics.	|
|	10	|	33	|	pmt_stat_activity_by_tax	|	Additional Functionality	|	Update function to use new financial view for calculations.	|
|	10	|	33	|	pmt_partner_pivot	|	Additional Functionality	|	Update function to allow for region filter.	|
|	10	|	32	|	pmt_activities_by_polygon	|	Additional Functionality	|	Update function to allow for filtering.	|
|	10	|	32	|	pmt_activities	|	Additional Functionality	|	Update function  to add currency code & classification.	|
|	10	|	31	|	pmt_activity	|	Additional Functionality	|	Update function to include parent/child related record information.	|
|	10	|	30	|	pmt_partner_sankey_activities	|	Additional Functionality	|	create new function pmt_partner_sankey_activities for the partnerlink feature.	|
|	10	|	29	|	pmt_partner_sankey	|	Additional Functionality	|	Replacing unreported relationships, refresh materialized views.	|
|	10	|	28	|	pmt_partner_pivot	|	Additional Functionality	|	Update to include additional information for application functionality.	|
|	10	|	27	|	pmt_partner_pivot	|	Additional Functionality	|	Update function to handle apostrophies in column data.	|
|	10	|	26	|	pmt_upd_boundary_features	|	Additional Functionality	|	Fix issue on assigning feature taxonomy from boundary intersect.	|
|	10	|	25	|	pmt_boundary_extents	|	New function	|	New function to get extent of a boundary feature(s).	|
|	10	|	24	|	pmt_boundary_filter	|	New function	|	New function to filter boundary features.	|
|	10	|	23	|	bmgf_global_search	|	Removing Function	|	Function no longer supported or required.	|
|	10	|	23	|	bmgf_infobox_project_info	|	Removing Function	|	Function no longer supported or required.	|
|	10	|	23	|	bmgf_locations_by_tax	|	Removing Function	|	Function no longer supported or required.	|
|	10	|	23	|	bmgf_project_list	|	Removing Function	|	Function no longer supported or required.	|
|	10	|	23	|	pmt_validate_projects	|	Removing Function	|	Function no longer supported or required.	|
|	10	|	23	|	pmt_validate_project	|	Removing Function	|	Function no longer supported or required.	|
|	10	|	23	|	pmt_stat_project_by_tax	|	Removing Function	|	Function no longer supported or required.	|
|	10	|	23	|	pmt_projects	|	Removing Function	|	Function no longer supported or required.	|
|	10	|	23	|	pmt_project_users	|	Removing Function	|	Function no longer supported or required.	|
|	10	|	23	|	pmt_project_listview_ct	|	Removing Function	|	Function no longer supported or required.	|
|	10	|	23	|	pmt_project_listview	|	Removing Function	|	Function no longer supported or required.	|
|	10	|	23	|	pmt_project	|	Removing Function	|	Function no longer supported or required.	|
|	10	|	23	|	pmt_infobox_project_info	|	Removing Function	|	Function no longer supported or required.	|
|	10	|	23	|	pmt_infobox_menu	|	Removing Function	|	Function no longer supported or required.	|
|	10	|	23	|	pmt_infobox_activity	|	Removing Function	|	Function no longer supported or required.	|
|	10	|	23	|	pmt_filter_projects	|	Removing Function	|	Function no longer supported or required.	|
|	10	|	23	|	pmt_filter_orgs	|	Removing Function	|	Function no longer supported or required.	|
|	10	|	23	|	pmt_filter_locations	|	Removing Function	|	Function no longer supported or required.	|
|	10	|	23	|	pmt_edit_user_project_role	|	Removing Function	|	Function no longer supported or required.	|
|	10	|	23	|	pmt_edit_project_taxonomy	|	Removing Function	|	Function no longer supported or required.	|
|	10	|	23	|	pmt_edit_project_contact	|	Removing Function	|	Function no longer supported or required.	|
|	10	|	23	|	pmt_edit_project	|	Removing Function	|	Function no longer supported or required.	|
|	10	|	23	|	pmt_activate_project	|	Removing Function	|	Function no longer supported or required.	|
|	10	|	23	|	pmt_activities	|	Additional Functionality	|	Updating function for new data model and application requirements.	|
|	10	|	23	|	pmt_partner_pivot	|	New function	|	New function to support partner pivot feature in application.	|
|	10	|	23	|	_activity_participants	|	Data Model	|	Updated view to include id and label	|
|	10	|	23	|	organization	|	Data Model	|	Adding new label field to organization for abbriviation of organization names.	|
|	10	|	23	|	pmt_stat_invest_by_funder	|	New function	|	New function to support investments by funding organization feature in application.	|
|	10	|	23	|	pmt_stat_activity_by_tax	|	Additional Functionality	|	Updating function for new data model and application requirements.	|
|	10	|	22	|	pmt_activity	|	Additional Functionality	|	Adding additional organization information.	|
|	10	|	21	|	pmt_boundaries_by_point	|	New function	|	New function to get all intersected boundaries for a given wkt point.	|
|	10	|	20	|	pmt_partner_sankey	|	Additional Functionality	|	Removing unreported funder, grantee & partners from the returned data.	|
|	10	|	19	|	pmt_activity	|	Additional Functionality	|	Adding new return fields to function to support application logic.	|
|	10	|	18	|	pmt_2x2	|	New function	|	New function to get 2x2 data for a country/region.	|
|	10	|	18	|	pmt_2x2_regions	|	New function	|	New function to get participating country & regions for the 2x2 tool.	|
|	10	|	18	|	gadm2	|	Data Model	|	Add new fields for 2x2: pop_total,pop_source,pov_total,pov_source,market_access,area,area_source	|
|	10	|	17	|	pmt_activity_count	|	Additional Functionality	|	Update function to include boundary so counts reflect map (some activities are mapped in the water).	|
|	10	|	16	|	pmt_export_ethaim	|	New function	|	Create new custom export function for ethaim data.	|
|	10	|	16	|	tanaim_filter_csv	|	Additional Functionality	|	Rename function to pmt_export_tanaim and update for latest data model.	|
|	10	|	16	|	bmgf_filter_csv	|	Additional Functionality	|	Rename function to pmt_export_bmgf and update for latest data model.	|
|	10	|	16	|	pmt_filter_csv	|	Additional Functionality	|	Rename function to pmt_export and update for latest data model.	|
|	10	|	16	|	pmt_version	|	Additional Functionality	|	Update function for latest data model.	|
|	10	|	15	|	pmt_activity_count	|	Additional Functionality	|	Update function to support filtering on unassigned taxonimes.	|
|	10	|	15	|	pmt_partner_sankey	|	Additional Functionality	|	Update function to support filtering on unassigned taxonimes.	|
|	10	|	15	|	pmt_activity_ids_by_boundary	|	Additional Functionality	|	Update function to support filtering on unassigned taxonimes.	|
|	10	|	15	|	pmt_locations_for_boundaries	|	Additional Functionality	|	Update function to support filtering on unassigned taxonimes.	|
|	10	|	15	|	pmt_filter	|	Additional Functionality	|	Update function to support filtering on unassigned taxonimes.	|
|	10	|	15	|	_filter_unassigned	|	Data Model	|	Create new filter view for unassigned taxonomies.	|
|	10	|	15	|	_filter_organizations	|	Data Model	|	Optimize filter view.	|
|	10	|	15	|	_filter_taxonomies	|	Data Model	|	Optimize filter view.	|
|	10	|	15	|	_filter_boundaries	|	Data Model	|	Optimize filter view.	|
|	10	|	14	|	pmt_statistic_data	|	New function	|	New function to return statistics for a indicator.	|
|	10	|	14	|	pmt_statistic_indicators	|	New function	|	New function to return available in indicators for statistics.	|
|	10	|	14	|	stats_data	|	Data Model	|	New table to store the statistic data for indicators.	|
|	10	|	14	|	stats_metadata	|	Data Model	|	New table to store the metadata for statistic indicators.	|
|	10	|	13	|	pmt_auto_complete	|	Additional Functionality	|	Update function to support application needs & latest data model.	|
|	10	|	13	|	pmt_global_search	|	Additional Functionality	|	Update function to support application needs & latest data model.	|
|	10	|	12	|	pmt_activity_count	|	New function	|	New function to provide total count of activities for a given filter.	|
|	10	|	11	|	pmt_activity_count_by_participants	|	New function	|	New function to provide count of activities by organization for a specific organization role.
|	10	|	11	|	pmt_activity_count_by_taxonomy	|	New function	|	New function to provide count of activities in a list of activites that are assigned a classification in requested taxonomy. 
|	10	|	11	|	_activity_participants	|	Data Model	|	Update view to include ids for classification.
|	10	|	11	|	_activity_taxonomies	|	Data Model	|	Update view to include ids for taxonomy and classification.
|	10	|	11	|	pmt_locations_by_polygon	|	Data Model	|	Renamed pmt_activities_by_polygon and updated to support latest data model.
|	10	|	11	|	pmt_validate_taxonomy	|	Additional Functionality	|	Update function to support latest data model.
|	10	|	11	|	pmt_validate_activities	|	Additional Functionality	|	Update function to support latest data model.
|	10	|	10	|	pmt_users	|	Additional Functionality	|	Update function to return last login timestamp.	|
|	10	|	9	|	pmt_partner_sankey	|	Additional Functionality	|	Update function to support application needs & latest data model.	|
|	10	|	9	|	pmt_activity_ids_by_boundary	|	Additional Functionality	|	Update function to use centralized filter logic (pmt_fliter).	|
|	10	|	9	|	pmt_locations_for_boundaries	|	Additional Functionality	|	Update function to use centralized filter logic (pmt_fliter).	|
|	10	|	9	|	pmt_filter	|	New function	|	Create new function to centralize the filter logic.	|
|	10	|	9	|	pmt_validate_classifications	|	Additional Functionality	|	Update function to support latest data model.	|
|	10	|	9	|	pmt_validate_classification	|	Additional Functionality	|	Update function to support latest data model.	|
|	10	|	8	|	gadm3	|	Data Model	|	Adding GADM boundaries to the data model.	|
|	10	|	8	|	gadm2	|	Data Model	|	Adding GADM boundaries to the data model.	|
|	10	|	8	|	gadm1	|	Data Model	|	Adding GADM boundaries to the data model.	|
|	10	|	8	|	gadm0	|	Data Model	|	Adding GADM boundaries to the data model.	|
|	10	|	7	|	pmt_activity_ids_by_boundary	|	Additional Functionality	|	Add data filter capability & return title.	|
|	10	|	7	|	pmt_locations_for_boundaries	|	Additional Functionality	|	Add data filter capability.	|
|	10	|	6	|	pmt_edit_user	|	Additional Functionality	|	Update function to support application needs & latest data model.	|
|	10	|	6	|	users	|	Data Model	|	Add unique constraint to users._username.	|
|	10	|	6	|	pmt_validate_organization	|	Additional Functionality	|	Update function to support application needs & latest data model.	|
|	10	|	5	|	pmt_locations	|	Additional Functionality	|	Update function to support application needs & latest data model.	|
|	10	|	5	|	pmt_validate_locations	|	Additional Functionality	|	Update function to support application needs & latest data model.	|
|	10	|	5	|	pmt_validate_location	|	Additional Functionality	|	Update function to support application needs & latest data model.	|
|	10	|	4	|	pmt_purge_activities	|	New function	|	Create new function to delete multiple activities.	|
|	10	|	4	|	pmt_purge_activity	|	Additional Functionality	|	Update function to adhere to new data model.	|
|	10	|	4	|	pmt_purge_project	|	Removing Function	|	Project is no longer an entity in the data model.	|
|	10	|	4	|	pmt_dlt_boundary_features	|	New trigger	|	Data management on delete from location table.	|
|	10	|	4	|	pmt_user_orgs	|	New function	|	Create function to support application needs.	|
|	10	|	4	|	pmt_orgs	|	Additional Functionality	|	Update function to support application needs & latest data model.	|
|	10	|	4	|	pmt_roles	|	New function	|	Create function to support application needs.	|
|	10	|	4	|	pmt_users	|	Additional Functionality	|	Update function to support application needs & latest data model.	|
|	10	|	4	|	pmt_user_salt	|	Additional Functionality	|	Update function to support application needs & latest data model.	|
|	10	|	4	|	pmt_user_auth	|	Additional Functionality	|	Update function to support application needs & latest data model.	|
|	10	|	4	|	pmt_org_inuse	|	Additional Functionality	|	Update function to support application needs & latest data model.	|
|	10	|	4	|	pmt_activity	|	Additional Functionality	|	Update function to support application needs & latest data model.	|
|	10	|	4	|	pmt_activity_ids_by_boundary	|	New function	|	New function to support application; returns activity ids for a given boundary feature.	|
|	10	|	4	|	pmt_locations_for_boundaries	|	New function	|	New function to support application; returns location and activity counts by boundary feature for a requested boundary.	|
|	10	|	4	|	gaul2_points	|	Data Model	|	New view to support point generation for application usage.	|
|	10	|	4	|	gaul1_points	|	Data Model	|	New view to support point generation for application usage.	|
|	10	|	4	|	gaul0_points	|	Data Model	|	New view to support point generation for application usage.	|
|	10	|	4	|	_location_lookup	|	Data Model	|	Update view to support location rollups to boundaries.	|
|	10	|	4	|	continent	|	Data Model	|	Add new continent spatial table (boundary file), to allow location rollups to continent level.	|
|	10	|	3	|	pmt_iati_evaluate	|	New trigger	|	Create new trigger to evaluate the IATI xml documents and determine which version and ETL process to call.	|
|	10	|	3	|	pmt_iati_preprocess	|	New trigger	|	Create new trigger to pre-process the IATI xml documents to collect important information needed for processing, this information is then recorded in the iati_import table.	|
|	10	|	3	|	pmt_etl_iati_activities_v201	|	New function	|	Create new function to process the version 2.01 IATI activity xml document.	|
|	10	|	3	|	pmt_etl_iati_activities_v104	|	New function	|	Create new function to process the version 1.04 IATI activity xml document.	|
|	10	|	3	|	pmt_etl_iati_codelist	|	New function	|	New function to process the IATI codelist xml documents.	|
|	10	|	3	|	pmt_iati_import	|	Additional Functionality	|	Update function to remove project, the "replace all" option and update for data model changes.	|
|	10	|	3	|	pmt_validate_user_authority	|	Additional Functionality	|	Update function to remove project and update for data model changes.	|
|	10	|	3	|	pmt_data_groups	|	Additional Functionality	|	Update function for new naming conventions/data model changes.	|
|	10	|	2	|	test_activity_schema	|	New function	|	New function to test if activity table has all the core fields.	|
|	10	|	2	|	test_activity_contact_schema	|	New function	|	New function to test if activity_contact table has all the core fields.	|
|	10	|	2	|	test_activity_taxonomy_schema	|	New function	|	New function to test if activity_taxonomy table has all the core fields.	|
|	10	|	2	|	test_boundary_schema	|	New function	|	New function to test if boundary table has all the core fields.	|
|	10	|	2	|	test_boundary_taxonomy_schema	|	New function	|	New function to test if boundary_taxonomy table has all the core fields.	|
|	10	|	2	|	test_classification_schema	|	New function	|	New function to test if classification table has all the core fields.	|
|	10	|	2	|	test_config_schema	|	New function	|	New function to test if config table has all the core fields.	|
|	10	|	2	|	test_contact_schema	|	New function	|	New function to test if contact table has all the core fields.	|
|	10	|	2	|	test_contact_taxonomy_schema	|	New function	|	New function to test if contact_taxonomy table has all the core fields.	|
|	10	|	2	|	test_detail_schema	|	New function	|	New function to test if detail table has all the core fields.	|
|	10	|	2	|	test_feature_taxonomy_schema	|	New function	|	New function to test if feature_taxonomy table has all the core fields.	|
|	10	|	2	|	test_financial_schema	|	New function	|	New function to test if financial table has all the core fields.	|
|	10	|	2	|	test_financial_taxonomy_schema	|	New function	|	New function to test if financial_taxonomy table has all the core fields.	|
|	10	|	2	|	test_location_schema	|	New function	|	New function to test if location table has all the core fields.	|
|	10	|	2	|	test_location_boundary_schema	|	New function	|	New function to test if location_boundary table has all the core fields.	|
|	10	|	2	|	test_location_taxonomy_schema	|	New function	|	New function to test if location_taxonomy table has all the core fields.	|
|	10	|	2	|	test_organization_schema	|	New function	|	New function to test if organization table has all the core fields.	|
|	10	|	2	|	test_organization_taxonomy_schema	|	New function	|	New function to test if organization_taxonomy table has all the core fields.	|
|	10	|	2	|	test_participation_schema	|	New function	|	New function to test if participation table has all the core fields.	|
|	10	|	2	|	test_participation_taxonomy_schema	|	New function	|	New function to test if participation_taxonomy table has all the core fields.	|
|	10	|	2	|	test_result_schema	|	New function	|	New function to test if result table has all the core fields.	|
|	10	|	2	|	test_result_taxonomy_schema	|	New function	|	New function to test if result_taxonomy table has all the core fields.	|
|	10	|	2	|	test_role_schema	|	New function	|	New function to test if role table has all the core fields.	|
|	10	|	2	|	test_taxonomy_schema	|	New function	|	New function to test if taxonomy table has all the core fields.	|
|	10	|	2	|	test_taxonomy_xwalk_schema	|	New function	|	New function to test if taxonomy_xwalk table has all the core fields.	|
|	10	|	2	|	test_user_activity_role_schema	|	New function	|	New function to test if user_activity_role table has all the core fields.	|
|	10	|	2	|	test_user_log_schema	|	New function	|	New function to test if user_log table has all the core fields.	|
|	10	|	2	|	test_users_schema	|	New function	|	New function to test if users table has all the core fields.	|
|	10	|	2	|	test_version_schema	|	New function	|	New function to test if version table has all the core fields.	|
|	10	|	2	|	test_xml_schema	|	New function	|	New function to test if xml table has all the core fields.	|
|	10	|	2	|	test_core_views	|	New function	|	New function to test if all core views are present in the database.	|
|	10	|	2	|	test_upd_geometry_formats	|	New function	|	New function to test pmt_upd_geometry_formats.	|
|	10	|	2	|	test_execute_unit_tests	|	New function	|	New function to execute all unit test functions.	|
|	10	|	2	|	unit_tests	|	Data Model	|	New table to store results of unit tests.	|
|	10	|	1	|	upd_boundary_features	|	Additional Functionality	|	Update to collect feature name, remove project references and adhere to model changes. Rename pmt_upd_boundary_features.	|
|	10	|	1	|	upd_geometry_formats	|	Additional Functionality	|	Update to remove project references and adhere to model changes. Rename pmt_upd_geometry_formats.	|
|	10	|	1	|	All entities	|	Data Model	|	Adding database constraints.	|
|	10	|	1	|	pmt_is_datagroup	|	New function	|	New function to support constraint checks for data group classifications.	|
|	10	|	1	|	pmt_validate_boundary_feature	|	Additional Functionality	|	Remove active requirement for validating boundary features.	|
|	10	|	1	|	_activity_participants	|	Data Model	|	New view.	|
|	10	|	1	|	accountable_organizations	|	Data Model	|	Removed classification_id and added activity count. Renamed _accountable_organizations.	|
|	10	|	1	|	accountable_project_participants	|	Data Model	|	Dropped view.	|
|	10	|	1	|	active_project_activities	|	Data Model	|	Renamed to _active_activites and removed project references.	|
|	10	|	1	|	activity_contacts	|	Data Model	|	Rename_activity_contacts and removed project references.	|
|	10	|	1	|	activity_participants	|	Data Model	|	Rename_partnerlink_participants and removed project references.	|
|	10	|	1	|	activity_taxonomies	|	Data Model	|	Rename _activity_taxonomies, removed project references and added data_group_id.	|
|	10	|	1	|	activity_taxonomy_xwalks	|	Data Model	|	Rewrote to be non-instance specific and renamed _activity_taxonomy_xwalks.	|
|	10	|	1	|	data_change_report	|	Data Model	|	Renamed _data_change_report and removed project references.	|
|	10	|	1	|	data_loading_report	|	Data Model	|	Renamed _data_loading_report and removed project references.	|
|	10	|	1	|	data_validation_report	|	Data Model	|	Renamed _data_validation_report and removed project references.	|
|	10	|	1	|	entity_taxonomy	|	Data Model	|	Renamed _entity_taxonomy and removed project references.	|
|	10	|	1	|	gaul_lookup	|	Data Model	|	Renamed _gaul_lookup and removed project references.	|
|	10	|	1	|	location_boundary_features	|	Data Model	|	Renamed _location_boundary_features, rewrote to be non-instance specific and removed project references.	|
|	10	|	1	|	location_lookup	|	Data Model	|	Redesigned. No longer materialized view. Renamed _location_lookup.	|
|	10	|	1	|	organization_lookup	|	Data Model	|	Redesigned. No longer materialized view. Renamed _organization_lookup.	|
|	10	|	1	|	organization_participation	|	Data Model	|	Renamed _organization_participation, remove unsued fields and removed project references.	|
|	10	|	1	|	partnerlink_sankey_links	|	Data Model	|	Renamed _partnerlink_sankey_links and removed project references.	|
|	10	|	1	|	partnerlink_sankey_nodes	|	Data Model	|	Renamed _partnerlink_sankey_nodes and removed project references.	|
|	10	|	1	|	project_activity_points	|	Data Model	|	Renamed _activity_points and removed project references.	|
|	10	|	1	|	project_contacts	|	Data Model	|	Dropped view.	|
|	10	|	1	|	project_taxonomies	|	Data Model	|	Dropped view.	|
|	10	|	1	|	project_taxonomy_xwalks	|	Data Model	|	Dropped view.	|
|	10	|	1	|	tags	|	Data Model	|	Renamed _tags and removed project references.	|
|	10	|	1	|	tanaim_aaz	|	Data Model	|	Removed project references.	|
|	10	|	1	|	tanaim_nbs	|	Data Model	|	Removed project references.	|
|	10	|	1	|	taxonomy_classifications	|	Data Model	|	Renamed _taxonomy_classifications and removed project references.	|
|	10	|	1	|	taxonomy_lookup	|	Data Model	|	Redesigned. No longer materialized view. Renamed _taxonomy_lookup.	|
|	10	|	1	|	taxonomy_xwalks	|	Data Model	|	Renamed _taxonomy_xwalks and removed project references.	|
|	10	|	1	|	xml	|	Data Model	|	Dropped project_id.	|
|	10	|	1	|	participation	|	Data Model	|	Dropped project_id.	|
|	10	|	1	|	financial	|	Data Model	|	Dropped project_id.	|
|	10	|	1	|	detail	|	Data Model	|	Dropped project_id.	|
|	10	|	1	|	location	|	Data Model	|	Dropped project_id.	|
|	10	|	1	|	activity	|	Data Model	|	Dropped project_id.	|
|	10	|	1	|	project_taxonomy	|	Data Model	|	Dropped table.	|
|	10	|	1	|	project_contact	|	Data Model	|	Dropped table.	|
|	10	|	1	|	project	|	Data Model	|	Dropped table.	|
|	10	|	0	|	All entities	|	Data Model	|	Major upgrade to remove project from the data model. Each instance has a change set specific to it. All are numbered at 0.	|

### Database Version 2.0
|Iteration	|Changeset	|Entity			|Action			|Description	|
|:-----------:	|:-----------:	|:---------------------	|:----------------------|:----------------------------------------------------------------------------------------------------------------------------------------------------	|
|	9	|	9	|	pmt_users	|	Additional Functionality	|	Return active.	|
|	9	|	8	|	project	|	Data Model	|	New field for project: program_lead_center **(CRP Only)**	|
|	9	|	7	|	pmt_edit_participation	|	Additional Functionality	|	Update to reactivate records when requested add/replace exists.	|
|	9	|	6	|	pmt_purge_activity	|	Additional Functionality	|	Update to remove logic that removes unused organizations and contacts.	|
|	9	|	6	|	pmt_purge_project	|	Additional Functionality	|	Update to remove logic that removes unused organizations and contacts.	|
|	9	|	5	|	pmt_edit_participation	|	Additional Functionality	|	Bug: delete operation failing because project_id is not collected before authorization. Change delete and replace operations to retire records instead of deleting.	|
|	9	|	4	|	pmt_contacts	|	Additional Functionality	|	Updating function to return only active records.	|
|	9	|	4	|	pmt_orgs	|	Additional Functionality	|	Updating function to return only active records.	|
|	9	|	3	|	location_boundary_features	|	Additional Functionality	|	Update to include new NBS boundary (TANAIM only)	|
|	9	|	3	|	tanaim_nbs	|	Data Model	|	New view to compare nbs to gaul (TANAIM only)	|
|	9	|	2	|	pmt_locations_by_polygon	|	New Function	|	New overloaded function to allow request to be restricted by activity.	|
|	9	|	1	|	pmt_clone_activity	|	New Function	|	New function for copying an activity.	|
|	9	|	0	|	pmt_activate_project	|	Additional Functionality	|	Bug: project_id was always null for validating project authorization.	|
|	9	|	0	|	pmt_edit_user_project_role	|	New Function	|	New function for editing a user's project role.	|
|	9	|	0	|	pmt_validate_role	|	New Function	|	New function for validating a role id.	|
|	9	|	0	|	pmt_validate_user	|	New Function	|	New function for validating a user id.	|
|	9	|	0	|	pmt_edit_user	|	New Function	|	New function for editing a user.	|
|	9	|	0	|	pmt_project_users	|	New Function	|	New function for getting user authorization information for a single project.	|
|	9	|	0	|	pmt_user	|	New Function	|	New function for getting authorization information for a single user.	|
|	9	|	0	|	pmt_users	|	Additional Functionality	|	Updating to use new user authentication model.	|
|	9	|	0	|	pmt_edit_project	|	Additional Functionality	|	Updating to use new user authentication model.	|
|	9	|	0	|	pmt_validate_user_authority	|	Additional Functionality	|	Updating to use new user authentication model.	|
|	9	|	0	|	pmt_user_auth	|	Additional Functionality	|	Updating to use new user authentication model.	|
|	9	|	0	|	user_project_role	|	Data Model	|	New table for administring role based permissions on the project level.	|
|	9	|	0	|	user	|	Data Model	|	Adding role_id column. Removing data_group_id. Removing requriement for organization_id. Adding constraints.	|
|	9	|	0	|	pmt_auth_source	|	Data Model	|	Removing enum.	|
|	9	|	0	|	config	|	Data Model	|	Remove edit_auth_source (no longer enforcing single edit authorization for an instance)	|
|	9	|	0	|	role	|	Additional Functionality	|	Adding new permission "security" to allow roles to grant security permissions. Add new "Administrator" role to PMT Core roles.	|
|	9	|	0	|	data_loading_report	|	Additional Functionality	|	Removing query for user_role.	|
|	9	|	0	|	user_role	|	Data Model	|	Removing table.	|
|	9	|	0	|	pmt_auth_user	|	Removing Function	|	Removing a scheduled deprecated function.	|
|	9	|	0	|	pmt_create_user	|	Removing Function	|	Removing a scheduled deprecated function.	|
|	9	|	0	|	pmt_update_user	|	Removing Function	|	Removing a scheduled deprecated function.	|
|	9	|	0	|	bmgf_infobox_activity_contact	|	Removing Function	|	Removing a scheduled deprecated function.	|
|	9	|	0	|	bmgf_infobox_activity_desc	|	Removing Function	|	Removing a scheduled deprecated function.	|
|	9	|	0	|	bmgf_infobox_activity_stats	|	Removing Function	|	Removing a scheduled deprecated function.	|
|	9	|	0	|	pmt_infobox_activity_contact	|	Removing Function	|	Removing a scheduled deprecated function.	|
|	9	|	0	|	pmt_infobox_activity_desc	|	Removing Function	|	Removing a scheduled deprecated function.	|
|	9	|	0	|	pmt_infobox_activity_stats	|	Removing Function	|	Removing a scheduled deprecated function.	|
|	9	|	0	|	pmt_activity_details	|	Removing Function	|	Removing a scheduled deprecated function.	|
|	9	|	0	|	bmgf_infobox_project_contact	|	Removing Function	|	Removing a scheduled deprecated function.	|
|	9	|	0	|	bmgf_infobox_project_desc	|	Removing Function	|	Removing a scheduled deprecated function.	|
|	9	|	0	|	bmgf_infobox_project_info	|	Removing Function	|	Removing a scheduled deprecated function.	|
|	9	|	0	|	bmgf_infobox_project_nutrition	|	Removing Function	|	Removing a scheduled deprecated function.	|
|	9	|	0	|	bmgf_infobox_project_stats	|	Removing Function	|	Removing a scheduled deprecated function.	|
|	9	|	0	|	pmt_infobox_project_contact	|	Removing Function	|	Removing a scheduled deprecated function.	|
|	9	|	0	|	pmt_infobox_project_desc	|	Removing Function	|	Removing a scheduled deprecated function.	|
|	9	|	0	|	pmt_infobox_project_info	|	Removing Function	|	Removing a scheduled deprecated function.	|
|	9	|	0	|	pmt_infobox_project_stats	|	Removing Function	|	Removing a scheduled deprecated function.	|
|	8	|	78	|	refresh_partnerlink_sankey	|	New Function	|	New function for refreshing the partnerlink sankey views.	|
|	8	|	77	|	activity	|	Data Model	|	New field for activity: url.	|
|	8	|	76	|	pmt_partner_sankey	|	New Function	|	New filterable function to support the d3 sankey partner link.	|
|	8	|	76	|	partnerlink_sankey_links	|	Data Model	|	New materialized view to support the pmt_partner_sankey function.	|
|	8	|	76	|	partnerlink_sankey_nodes	|	Data Model	|	New materialized view to support the pmt_partner_sankey function.	|
|	8	|	76	|	activity_participants	|	Data Model	|	New view listing all participants by activity.	|
|	8	|	75	|	data_change_report	|	Data Model	|	New view to list data change scripts and actions performed on entities.	|
|	8	|	74	|	activity	|	Data Model	|	Custom CRP fields on the activity table: notes, code	|
|	8	|	73	|	data_validation_report	|	Data Model	|	Update the validation report to include additional tests.	|
|	8	|	72	|	pmt_edit_financial_taxonomy	|	New Function	|	New function to edit financial taxonomies.	|
|	8	|	72	|	pmt_validate_financials	|	New Function	|	New function to validate multiple financial_id.	|
|	8	|	71	|	tanaim_aaz	|	Data Model	|	Custome TanAIM view for Agriculture Adminisrtative Zones.	|
|	8	|	70	|	data_validation_report	|	Additional Functionality	|	Updating view for additional logic tests.	|
|	8	|	70	|	activity_taxonomy_xwalks	|	Data Model	|	New custom view for existing xwalks.	|
|	8	|	70	|	project_taxonomy_xwalks	|	Data Model	|	New custom view for existing xwalks.	|
|	8	|	70	|	taxonomy_xwalks	|	Data Model	|	New view for taxonomy xwalk table.	|
|	8	|	70	|	taxonomy_xwalk	|	Data Model	|	New table for storing taxonomy xwalk information.	|
|	8	|	69	|	**Rejected change set**	|	**Rejected change set**	|	**Rejected change set**	
|	8	|	68	|	pmt_taxonomies	|	Additional Functionality	|	Adding code to the returned object.	|
|	8	|	67	|	pmt_edit_location_taxonomy	|	Additional Functionality	|	Updating to include logic to remove associations to an entire taxonomy(ies).	|
|	8	|	66	|	pmt_edit_project_taxonomy	|	Additional Functionality	|	Updating to include logic to remove associations to an entire taxonomy(ies).	|
|	8	|	66	|	pmt_edit_activity_taxonomy	|	Additional Functionality	|	Updating to include logic to remove associations to an entire taxonomy(ies).	|
|	8	|	65	|	pmt_project	|	Additional Functionality	|	Updating to include  start_date and end_date for returned financial object.	|
|	8	|	65	|	pmt_activity	|	Additional Functionality	|	Updating to include  start_date and end_date for returned financial object.	|
|	8	|	64	|	pmt_edit_participation_taxonomy	|	Additional Functionality	|	Updating to allow multiple participation_ids and multiple classification_ids.	|
|	8	|	63	|	pmt_edit_location_taxonomy	|	Additional Functionality	|	Updating to allow multiple location_ids and multiple classification_ids.	|
|	8	|	62	|	pmt_edit_project_taxonomy	|	Additional Functionality	|	Updating to allow multiple project_ids and multiple classification_ids.	|
|	8	|	61	|	pmt_edit_activity_taxonomy	|	Additional Functionality	|	Adding user validation and updating to accept multiple classification_ids.	|
|	8	|	60	|	pmt_orgs	|	Additional Functionality	|	Updated to only return active organizations.	|
|	8	|	59	|	data_validation_report	|	Additional Functionality	|	Adding additional tests for taxonomy.	|
|	8	|	58	|	pmt_edit_participation	|	Additional Functionality	|	Updating function to allow multiple classifiction_ids to support one to many taxonomy assignments per a single participation record.	|
|	8	|	58	|	pmt_edit_participation_taxonomy	|	Additional Functionality	|	New function to edit participation taxonomy relationships.	|
|	8	|	58	|	pmt_validate_participation	|	Additional Functionality	|	New function to validate a single participation_id	|
|	8	|	58	|	pmt_validate_participations	|	Additional Functionality	|	New function to validate multiple particpation_ids	|
|	8	|	57	|	data_loading_report	|	Additional Functionality	|	Update to reflect total and active record counts. 	|
|	8	|	57	|	data_validation_report	|	Data Model	|	New view to validate data in the database	|
|	8	|	56	|	tanaim_activity	|	New Function	|	New function with specific location format for tanaim.	|
|	8	|	55	|	location_boundary	|	Additional Functionality	|	Add feature_area column to store total feature area.	|
|	8	|	55	|	upd_boundary_features	|	Additional Functionality	|	Added calculation of the area of an intersected gaul feature.	|
|	8	|	55	|	location_boundary_features	|	Additional Functionality	|	Added feature_area column to view.	|
|	8	|	55	|	location_lookup	|	Additional Functionality	|	Added logic to select the smallest area in multiple selected gaul 2 features.	|
|	8	|	54	|	location	|	Data Model **(TANAIM Only)**	|	Add four additional fields to the TANAIM database location table to support original data values.	|
|	8	|	53	|	pmt_activity_listview	|	Additional Functionality	|	Alter lookup for organization role to iati_name field to support custom naming of the iati codelist.	|
|	8	|	52	|	pmt_category_root	|	New Function	|	New overloaded function to allow requests for multiple data groups as well	|
|	8	|	51	|	activity 	|	Data Model	|	Adding two new fields plan_start_date, plan_end_date	|
|	8	|	50	|	pmt_project	|	Additional Functionality	|	Adding code to the returned taxonomy object.	|
|	8	|	50	|	pmt_locations	|	New Function	|	New function to request location information for one or more locations.	|
|	8	|	50	|	pmt_validate_locations	|	New Function	|	New function to validate a comma delimited string of location_ids.	|
|	8	|	50	|	pmt_activity	|	Additional Functionality	|	Remove location object and replacing with location_id array and adding code to the return taxonomy object.	|
|	8	|	50	|	upd_boundary_features	|	Additional Functionality	|	Updated to create centroid when boundary_id and feature_id  are present and valid.	|
|	8	|	50	|	pmt_validate_boundary_feature	|	New Function	|	New function to validate boundary_id/feature_id pairs.	|
|	8	|	50	|	location	|	Data Model	|	Adding new fields to allow for feature association to any boundary feature.	|
|	8	|	49	|	pmt_edit_location_taxonomy	|	New Function	|	New function to add, replace and delete the relationship between a location and a taxonomy.	|
|	8	|	48	|	pmt_validate_location	|	New Function	|	New function to validate a location_id.	|
|	8	|	48	|	upd_boundary_features	|	Additional Functionality	|	Updated to check for null point, in order to allow a location record to be created without a point.	|
|	8	|	48	|	pmt_edit_location	|	New Function	|	New function to edit a location.	|
|	8	|	47	|	pmt_edit_participation	|	Additional Functionality	|	Remove requirement of project_id for activity participation editing and change the return object to be json.	|
|	8	|	46	|	pmt_project	|	Additional Functionality	|	Adding participation_id for organization to support editing.	|
|	8	|	46	|	pmt_activity	|	Additional Functionality	|	Adding participation_id for organization to support editing.	|
|	8	|	45	|	pmt_project	|	Additional Functionality	|	Adding taxonomy object instead of repeating associated records.	|
|	8	|	45	|	pmt_activity	|	Additional Functionality	|	Updating to remove sumation of financial information and replacing with a financial object. Adding taxonomy objects instead of repeating associated records.	|
|	8	|	44	|	pmt_project	|	Additional Functionality	|	Updating to remove sumation of financial information and replacing with a financial object.	|
|	8	|	43	|	pmt_edit_participation	|	Bug Fix	|	Bug fix, incorrect parameter in classification_id validation logic.	|
|	8	|	42	|	pmt_edit_contact	|	Additional Functionality	|	Update function to allow deletion of contacts.	|
|	8	|	42	|	pmt_edit_organization	|	New Function	|	New function to create, update and delete a organization.	|
|	8	|	41	|	pmt_edit_financial	|	New Function	|	New function to create, update and delete a financial record.	|
|	8	|	41	|	pmt_validate_financial	|	New Function	|	New function to validate active financial id.	|
|	8	|	40	|	pmt_edit_detail	|	New Function	|	New function to create, update and delete a detail.	|
|	8	|	40	|	pmt_validate_detail	|	New Function	|	New function to validate active detail id.	|
|	8	|	39	|	pmt_edit_project	|	New Function	|	New function to create, update and delete a project.	|
|	8	|	38	|	pmt_edit_project_taxonomy	|	New Function	|	New function to add, replace and delete the relationship between a project and a taxonomy.	|
|	8	|	37	|	pmt_activities	|	New Function	|	New function to retreive a listing of all activities.	|
|	8	|	37	|	pmt_projects	|	New Function	|	New function to retreive a listing of all projects.	|
|	8	|	36	|	pmt_edit_project_contact	|	New Function	|	New function to add, replace and delete the relationship between a project and a contact.	|
|	8	|	36	|	pmt_validate_projects	|	New Function	|	New function to validate active project ids.	|
|	8	|	36	|	pmt_validate_project	|	New Function	|	New function to validate an active project id.	|
|	8	|	35	|	enumerator types	|	Data Model	|	Implementing the pmt_ naming convention on the custom enumerator data types: auth_crud, auth_source, edit_action	|
|	8	|	34	|	pmt_activate_project	|	New Function	|	New function for activating/deactivating a project and its related records.	|
|	8	|	34	|	pmt_activate_activity	|	New Function	|	New function for activating/deactivating an activity and its related records.	|
|	8	|	34	|	pmt_edit_activity	|	Additional Functionality	|	Update to allow deletion and return id and message values.	|
|	8	|	33	|	pmt_project	|	New Function	|	New function for getting all information related to a single project.	|
|	8	|	32	|	tanaim_filter_csv	|	New Function **(TANAIM Only)**	|	New function for exporting data from tanaim as csv **(TANAIM ONLY)**	|
|	8	|	31	|	bmgf_filter_csv	|	Additional Functionality **(BMGF Only)**	|	Adding region to export **(BMGF ONLY)**	|
|	8	|	30	|	pmt_global_search	|	Additional Functionality	|	Adding data group id to returned results.	|
|	8	|	29	|	organization name field	|	Data Model	|	Updating organization.name field to be character varying (max).	|
|	8	|	28	|	pmt_locations_by_tax	|	New Function	|	Overloaded method. New function accepting multiple data groups.	|
|	8	|	27	|	json result types	|	Data Model	|	Removal of all unique json response types and consolidating to a single json result type for all functions. 	|
|	8	|	26	|	pmt_locations_by_polygon	|	Additional Functionality	|	Added taxonomy and organization objects to returned locations.	|
|	8	|	25	|	taxonomy_classifications	|	Additional Functionality	|	Adding the code field to the view.	|
|	8	|	24	|	pmt_iati_import	|	Additional Functionality	|	Added logic to only purge existing projects, instead of any project listed in the xml table associated to the data group.	|
|	8	|	24	|	pmt_filter_iati	|	Additional Functionality	|	Added logic to export participating organization records in order to fufill PMT minimum requirements for upload	|
|	8	|	24	|	process_xml	|	Additional Functionality	|	Updated trigger to remove commas (,) from budget and transactional values so they do not fail to get loaded.	|
|	8	|	23	|	pmt_activity	|	New Function	|	New function to provide all infobox info for an activity, to replace pmt_infobox_activity.	|
|	8	|	22	|	pmt_stat_partner_network	|	Additional Functionality	|	Added country_ids parameter for filter by country, and additional level of children.	|
|	8	|	21	|	pmt_global_search	|	New Function	|	New function for searching textual fields in activity and project (similar to bmgf function).	|
|	8	|	20	|	user_activity	|	Data Model	|	New table for storing user activity.	|
|	8	|	20	|	pmt_user_auth	|	Additional Functionality	|	Adding user activity logging.	|
|	8	|	19	|	pmt_edit_contact	|	Additional Functionality	|	Change return value from boolean to json in order to return id and message values. 	|
|	8	|	18	|	process_xml	|	Bug Fix	|	Bug fix when entering organisation type taxonomy.	|
|	8	|	17	|	bmgf_locations_by_tax	|	New Function **(BMGF Only)**	|	New function for bmgf instances to allow adding lat/long fields to return, without disturbing other instances. This function is intended to be temporary. **(BMGF Only)**	|
|	8	|	16	|	pmt_infobox_activity	|	New Function	|	New function to provide all infobox info for an activity, including necessary id values to support editing. This function will be replacing all activity infobox functions for bmgf and pmt.	|
|	8	|	15	|	pmt_user_auth	|	Additional Functionality	|	Adding authorized project_ids (user has authorization to edit).	|
|	8	|	14	|	process_xml	|	Bug Fix	|	Bug fix, trim incoming organization names to ensure they do not exceed our 255 character limitation.	|
|	8	|	13	|	pmt_edit_participation	|	New Function	|	New function to create/edit participationof organizations in projects/activities.	|
|	8	|	12	|	pmt_edit_contact	|	New Function	|	New function to create/edit contacts.	|
|	8	|	11	|	pmt_stat_partner_network	|	New Function	|	New function to support the partner network graph.	|
|	8	|	10	|	pmt_validate_contacts	|	New Function	|	New function to validate a list of contact_ids.	|
|	8	|	10	|	pmt_validate_contact	|	New Function	|	New function to validate a contact_id.	|
|	8	|	10	|	pmt_edit_activity_contact	|	New Function	|	New function to edit the relationship between an activity and a contact.	|
|	8	|	9	|	pmt_edit_activity	|	New Function	|	New function for editing an activity.	|
|	8	|	8	|	pmt_locations_by_org	|	Bug Fix	|	Bug fix, was not filtering properly when using an organization taxonomy.	|
|	8	|	7	|	version	|	Data Model	|	Rename config table to version and remove the app_dir field. 	|
|	8	|	7	|	pmt_version	|	Additional Functionality	|	Update function to use version table after rename from config.	|
|	8	|	7	|	config	|	Data Model	|	New table for supporting instance configuration.	|
|	8	|	7	|	pmt_validate_user_authority	|	New Function	|	New function to validate a user and project to determine if user has authorization to edit the given project.	|
|	8	|	6	|	pmt_contacts	|	New Function	|	New function to get all contacts.	|
|	8	|	6	|	pmt_orgs	|	New Function	|	New function to get all organizations.	|
|	8	|	5	|	bmgf_infobox_project_info	|	Additional Functionality	|	adding location_ids	|
|	8	|	4	|	pmt_locations_by_polygon	|	New Function	|	New function for selecting locations within a given polygon by activity with a calculated distance from polygon centroid.	|
|	8	|	3	|	pmt_filter_locations	|	Bug Fix	|	Bug fix, was returning g_id when no optional parameters were passed.	|
|	8	|	2	|	pmt_auto_complete	|	Additional Functionality	|	Split out tags (comma dilemited) if requested.	|
|	8	|	1	|	pmt_edit_activity_taxonomy	|	New Function	|	New function for performing the edits to the taxonomy/activity relationship.	|
|	8	|	1	|	pmt_sector_compare	|	New Function	|	New function for comparing the assigned Sector to the text value in the IATI Activity Sector xml element(s).	|
|	8	|	1	|	process_xml	|	Additional Functionality	|	1) Activities, that at minimum, do not contain a title are NOT imported.  2) Activities that have more than one valid Sector assignment are assigned Sector classification "Multisector aid" only.  3) Activities that do not have a Sector assignment or do not have a valid Sector assignment are assigned Sector classification "Sectors not specified".  4) The text value for the xml Sector element is stored in the content field of the activity table.	|
|	7	|	24	|	taxonomy_classifications	|	Data Model	|	Convert from materialized view back to view.	|
|	7	|	23	|	pmt_activity_listview	|	Additional Functionality	|	Complete redesign of logic and return object to better meet the needs of a pabable list of activities.	|
|	7	|	22	|	taxonomy_classifications	|	Data Model	|	Convert from view to materialized view with indexes.	|
|	7	|	21	|	pmt_org_inuse	|	Bug Fix	|	Inacurate selection of participating organizations.	|
|	7	|	20	|	pmt_activity_listview	|	Bug Fix	|	Remove duplicate activities caused by unaggregated join to organizations.	|
|	7	|	19	|	pmt_activity_details	|	Additional Functionality	|	Adding organization names to taxonomy return object where taxonomy is Organisation Role.	|
|	7	|	18	|	pmt_activity_listview	|	Additional Functionality	|	Adding date parameters.	|
|	7	|	18	|	pmt_activity_listview_ct	|	Additional Functionality	|	Adding date parameters.	|
|	7	|	17	|	pmt_stat_activity_by_district	|	Additional Functionality	|	Adding country parameter.	|
|	7	|	17	|	pmt_stat_orgs_by_district	|	Additional Functionality	|	Adding country parameter.	|
|	7	|	17	|	pmt_stat_pop_by_district	|	Additional Functionality	|	Adding country parameter.	|
|	7	|	16	|	bmgf_infobox_activity_stats	|	Additional Functionality	|	Adding location count and administrative boundary to return.	|
|	7	|	15	|	pmt_stat_pop_by_district	|	New Function	|	Function for population statistics by region/district.	|
|	7	|	14	|	gual2	|	Data Model	|	Adding new column pop_source to track population data source.	|
|	7	|	13	|	pmt_stat_orgs_by_activity	|	Bug Fix	|	Repairing organization filter logic.	|
|	7	|	12	|	pmt_filter_orgs	|	Additional Functionality	|	Remove g_id from returned values.	|
|	7	|	12	|	pmt_filter_locations	|	Additional Functionality	|	Remove g_id from returned values.	|
|	7	|	11	|	pmt_activity_listview	|	Bug Fix	|	Repairing organization filter logic.	|
|	7	|	10	|	refresh_taxonomy_lookup	|	Additional Functionality	|	Converting update functionality to refresh materialized views.	|
|	7	|	10	|	taxonomy_lookup	|	Data Model	|	Converting from table to materialized view.	|
|	7	|	10	|	organization_lookup	|	Data Model	|	Converting from table to materialized view.	|
|	7	|	10	|	location_lookup	|	Data Model	|	Converting from table to materialized view.	|
|	7	|	9	|	pmt_stat_activity_by_district	|	Additional Functionality	|	Adding data group filter.	|
|	7	|	9	|	pmt_stat_orgs_by_district	|	Additional Functionality	|	Adding data group filter.	|
|	7	|	8	|	map	|	Data Model	|	New column 'filters' as json datatype for storing filter data a json in the db	|
|	7	|	7	|	pmt_user_salt	|	New Function	|	Function for getting salt for a specific user	|
|	7	|	7	|	pmt_user_auth	|	New Function	|	Function for authenticating a user using a hash/salted password	|
|	7	|	6	|	pmt_stat_activity_by_district	|	New Function	|	Function for activities by taxonomy by district for a given region	|
|	7	|	6	|	pmt_stat_orgs_by_district	|	New Function	|	Function for organizations with activity counts by district for a given region	|
|	7	|	5	|	map	|	Data Model	|	New entity for storing saved map information.	|
|	7	|	4	|	pmt_infobox_activity_desc	|	New Function	|	Function for activity description	|
|	7	|	4	|	pmt_infobox_activity_contact	|	New Function	|	Function for activity contacts and partners	|
|	7	|	4	|	pmt_infobox_activity_stats	|	New Function	|	Function for general activity statistics	|
|	7	|	4	|	pmt_infobox_project_contact	|	New Function	|	Function for project contact and partners	|
|	7	|	4	|	pmt_infobox_project_desc	|	New Function	|	Function for project description	|
|	7	|	4	|	pmt_infobox_project_stats	|	New Function	|	Function for general project statistics	|
|	7	|	4	|	pmt_infobox_project_info	|	New Function	|	Function for project information	|
|	7	|	3	|	pmt_project_list	|	Function Rename	|	Rename pmt_project_list to bmgf_project_list	|
|	7	|	3	|	pmt_infobox_activity_desc	|	Function Rename	|	Rename pmt_infobox_activity_desc to bmgf_infobox_activity_desc	|
|	7	|	3	|	pmt_infobox_activity_contact	|	Function Rename	|	Rename pmt_infobox_activity_contact to bmgf_infobox_activity_contact	|
|	7	|	3	|	pmt_infobox_activity_stats	|	Function Rename	|	Rename pmt_infobox_activity_stats to bmgf_infobox_activity_stats	|
|	7	|	3	|	pmt_infobox_project_nutrition	|	Function Rename	|	Rename pmt_infobox_project_nutrition to bmgf_infobox_project_nutrition	|
|	7	|	3	|	pmt_infobox_project_contact	|	Function Rename	|	Rename pmt_infobox_project_contact to bmgf_infobox_project_contact	|
|	7	|	3	|	pmt_infobox_project_desc	|	Function Rename	|	Rename pmt_infobox_project_desc to bmgf_infobox_project_desc	|
|	7	|	3	|	pmt_infobox_project_stats	|	Function Rename	|	Rename pmt_infobox_project_stats to bmgf_infobox_project_stats	|
|	7	|	3	|	pmt_infobox_project_info	|	Function Rename	|	Rename pmt_infobox_project_info to bmgf_infobox_project_info	|
|	7	|	2	|	gaul2	|	Data Model	|	Four new fields for population data: pop_rural, pop_poverty, pop_poverty_rural, pop_total	|
|	7	|	1	|	pmt_auth_user	|	New Function	|	Function to authenticate a user, using username and password. Returns user information if authentication is successful.	|
|	7	|	1	|	pmt_validate_organizations	|	New Function	|	Function to validate multiple organization_ids. Returns array of valid organization_ids.	|
|	7	|	1	|	pmt_validate_organization	|	New Function	|	Function to validate a single organization_id. Returns boolean.	|
|	7	|	1	|	pmt_update_user	|	New Function	|	Function to update an existing user.	|
|	7	|	1	|	pmt_create_user	|	New Function	|	Function to create a new user.	|
|	7	|	1	|	pmt_users	|	New Function	|	Function returning all user and role information.	|
|	7	|	1	|	user_role	|	Data Model	|	New junction table for supporting relationships between user and role entites.	|
|	7	|	1	|	role	|	Data Model	|	New table for supporting role based permissions.	|
|	7	|	1	|	user	|	Data Model	|	Added new organization_id field. Updated email, password and username to NOT NULL.	|
|	6	|	41	|	pmt_filter_csv	|	New Function	|	Function to export data to csv.	|
|	6	|	40	|	pmt_filter_csv/bmgf_filter_csv	|	Function Rename	|	Rename pmt_filter_csv to bmgf_filter_csv	|
|	6	|	39	|	process_xml	|	Bug Fix	|	Wasn't picking up sector codes if the xml sector element did not have any text values.	|
|	6	|	38	|	pmt_filter_cvs	|	Additional Functionality	|	Added database instance name to file name for use by the server process in determining the appropriate email message content. 	|
|	6	|	37	|	pmt_filter_iati	|	Additional Functionality	|	Added database instance name to file name for use by the server process in determining the appropriate email message content. 	|
|	6	|	36	|	pmt_stat_orgs_by_activity	|	Bug Fix	|	Was not returning correct counts for activities by classification.	|
|	6	|	34	|	pmt_filter_projects	|	Performance Improvement	|	Using location_lookup over taxonomy_lookup.	|
|	6	|	33	|	pmt_filter_csv	|	Bug Fix	|	Activities were not being filtered within filtered projects and activities country column wasn't being populated.	|
|	6	|	32	|	pmt_stat_counts	|	Bug Fix	|	Failing on date ranges. 	|
|	6	|	31	|	refresh_taxonomy_lookup	|	Additional Functionality	|	Adding start and end dates to organization_lookup.	|
|	6	|	30	|	pmt_iati_import	|	New Function	|	Imports an IATI Activities formatted xml document, with the option to replace or append the data.	|
|	6	|	29	|	pmt_project_listview	|	Additional Functionality	|	Added date range parameters to filter.	|
|	6	|	29	|	pmt_project_listview_ct	|	Additional Functionality	|	Added date range parameters to filter.	|
|	6	|	28	|	pmt_purge_project	|	New Function	|	New function for purging all data associated to a single project.	|
|	6	|	28	|	pmt_purge_activity	|	New Function	|	New function for purging all data associated to a single activity.	|
|	6	|	27	|	pmt_activity_details	|	New Function	|	Provide full details for a single activity by activity_id.	|
|	6	|	26	|	active_project_activities	|	Additional Functionality	|	Limit data to active organizations, participation.	|
|	6	|	26	|	accountable_organizations	|	Additional Functionality	|	Limit data to active organizations, participation.	|
|	6	|	26	|	organization_participation	|	Additional Functionality	|	Limit data to active organizations, participation.	|
|	6	|	25	|	pmt_infobox_project_info	|	Additional Functionality	|	Adding lat, long, and list of c_ids by reporting taxonomy_id to return.	|
|	6	|	24	|	pmt_filter_cvs	|	Bug Fix	|	Added logic to gracefully return false if no records are found.	|
|	6	|	23	|	pmt_stat_orgs_by_activity	|	Additional Functionality	|	Changed organization role to be Accountable from Implementing.	|
|	6	|	22	|	pmt_infobox_project_contact	|	Additional Functionality	|	Change in partner logic to be ONLY Implementing Organisation Role. BMGF instance ONLY.	|
|	6	|	21	|	pmt_auto_complete	|	New Function	|	Function accepting columns for both project and activity and compiles a list of unique data from those fields for use in an autocomplete or type ahead function.	|
|	6	|	20	|	pmt_version	|	Additional Functionality	|	Return the most recent version data.	|
|	6	|	20	|	config	|	Data Model	|	Remove unused config columns due to moving the app model into the pmt model.	|
|	6	|	19	|	upd_boundary_features	|	Additional Functionality	|	Adding dynamic spatial intersection to find Country for location Country taxonomy.	|
|	6	|	19	|	upd_geometry_formats	|	Additional Functionality	|	Remove dynamic spatial intersection to find Country for location Country taxonomy.	|
|	6	|	18	|	bmgf_global_search	|	New Function	|	Text search function for activities and projects: title, description, opportunity_id, tag fields. BMGF instance only.	|
|	6	|	17	|	refresh_taxonomy_lookup	|	Additional Functionality	|	Adding update statements for location_lookup to maintain gaul#_name columns.	|
|	6	|	17	|	location_lookup	|	Data Model	|	Adding three new columns: gaul0_name, gaul1_name, gaul2_name	|
|	6	|	17	|	pmt_activity_listview	|	Additional Functionality	|	Adding gaul 0 & 1 names and financials.	|
|	6	|	16	|	pmt_infobox_activity_contact	|	Bug Fix	|	Bug fix.	|
|	6	|	15	|	gaul_lookup	|	Additional Functionality	|	Adding type field to specify: Country, Region or District	|
|	6	|	14	|	active_project_activities	|	Additional Functionality	|	Removing reporting_org organizations from the lookup tables, by removing from supporting view.	|
|	6	|	13	|	pmt_stat_orgs_by_activity	|	Performance Improvement	|	Added organization name, and updated to use new lookup tables.	|
|	6	|	13	|	pmt_stat_activity_by_tax	|	Performance Improvement	|	Updated to use new lookup tables.	|
|	6	|	13	|	pmt_stat_project_by_tax	|	Performance Improvement	|	Updated to use new lookup tables.	|
|	6	|	13	|	pmt_stat_counts	|	Performance Improvement	|	Updated to use new lookup tables.	|
|	6	|	12	|	pmt_stat_locations	|	New Function	|	Statistics function for location lat/long.	|
|	6	|	11	|	pmt_activity_listview	|	Performance Improvement	|	Updated to use new lookup tables.	|
|	6	|	11	|	pmt_filter_locations	|	Performance Improvement	|	Updated to use new lookup tables.	|
|	6	|	11	|	pmt_locations_by_org	|	Performance Improvement	|	Updated to use new lookup tables.	|
|	6	|	11	|	pmt_locations_by_tax	|	Performance Improvement	|	Updated to use new lookup tables.	|
|	6	|	10	|	refresh_taxonomy_lookup	|	Additional Functionality	|	Added functionality to update additional lookup tables.	|
|	6	|	10	|	organization_lookup	|	Data Model	|	New lookup table optimized for performance.	|
|	6	|	10	|	location_lookup	|	Data Model	|	New lookup table optimized for performance.	|
|	6	|	9	|	pmt_filter_iati	|	New Function	|	Creates IATI formated xml document of activities. Filterable. Accepts an email address.	|
|	6	|	8	|	pmt_countries	|	Bug Fix	|	cs 2.0.6.5 casued a error, fixed. Removed on demand dump of polygons, no longer needed since gual polygons were repaired.	|
|	6	|	-	|	user	|	Data Model	|	Moved the User table into the PMT data model.	|
|	6	|	7	|	pmt_project_listview	|	New Function	|	Filters project, activity, participation with reportable taxonomy and paging parameters. 	|
|	6	|	7	|	pmt_project_listview_ct	|	New Function	|	Record count for pmt_project_listview taking the same parameters.	|
|	6	|	6	|	pmt_stat_counts	|	New Function	|	Statistics function providing filterable counts for project, activity, implementing organizations and districts.	|
|	6	|	6	|	pmt_stat_project_by_tax	|	New Function	|	Statistics function providing filterable counts for project by taxonomy.	|
|	6	|	6	|	pmt_stat_activity_by_tax	|	New Function	|	Statistics function providing filterable counts for activity by taxonomy.	|
|	6	|	6	|	pmt_stat_orgs_by_activity	|	New Function	|	Statistics function providing filterable counts for TOP TEN implementing organizations by activity classified by taxonomy.	|
|	6	|	5	|	gaul tables	|	Performance Improvement	|	Updating the gaul geometry in each gaul table in order to discontinue the gaul0_dump table and its uses. Updating all locations in order for the boundary_features to be recollected, for use in the statistic functions.	|
|	6	|	4	|	pmt_tax_inuse	|	Bug Fix	|	Classification was returning with taxonomy category_id instead of its own.	|
|	6	|	3	|	pmt_filter_orgs	|	Additional Functionality	|	Complete redesign of inner logic to mirror logic of other filters, returning organization_ids by location_id.	|
|	6	|	3	|	pmt_org_inuse	|	New Function	|	Returns organization id and name in-use by filtered locations.	|
|	6	|	2	|	pmt_locations_by_org	|	Performance Improvement	|	Redesigned the executed query for performance.	|
|	6	|	2	|	pmt_locations_by_tax	|	Performance Improvement	|	Redesigned the executed query for performance.	|
|	6	|	1	|	pmt_activity_listview	|	New Function	|	Filters activity, organization and reportable taxonomy with paging parameters.	|
|	6	|	1	|	pmt_activity_listview_ct	|	New Function	|	Record count for pmt_activity_listview taking the same parameters.	|
|	6	|	0	|	taxonomy	|	New columns	|	Columns: category_id & is_category. To support category within taxonomy.	|
|	6	|	0	|	classification	|	New columns	|	Columns: category_id. To support category within taxonomy.	|
|	6	|	0	|	PMT Sector Category	|	New taxonomy	|	Added a category to Sector Category taxonomy to further reduce the number of categories in Sector.	|
|	6	|	0	|	process_xml	|	Additional Functionality	|	Updated to create Sector Category taxonomy from the Sector codelist and implement category logic. Updated to assign Sector Category to incoming IATI Activities.	|
|	6	|	0	|	pmt_category_root	|	New Function	|	Recieves a taxonomy and returns the base taxonomy when a category taxonomy is passed.	|
|	6	|	0	|	pmt_filter_locations	|	Additional Functionality	|	Adding category logic to function to handle reporting by a category.	|
|	6	|	0	|	pmt_locations_by_tax	|	Additional Functionality	|	Adding category logic to function to handle reporting by a category.	|
|	6	|	0	|	pmt_tax_inuse	|	Additional Functionality	|	Adding category attributes to output.	|
|	6	|	0	|	pmt_taxonomies	|	Additional Functionality	|	Adding category attributes to output.	|
|	6	|	0	|	pmt_filter_locations	|	Additional Functionality	|	Adding functionality to return locations that have no assignments to a given taxonomy.	|
|	6	|	0	|	pmt_filter_projects	|	Additional Functionality	|	Adding functionality to return projects associated to locations that have no assignments to a given taxonomy.	|
|	6	|	0	|	pmt_version	|	New Function	|	Returns the current database version.	|
|	6	|	0	|	pmt_activities_by_tax	|	New Function	|	Returns activity id, title and list of classification ids based on data group, country and reporting taxonomy id.	|
|	6	|	0	|	pmt_validate_activity	|	New Function	|	To validate a single activity_id. Returns boolean.	|
|	6	|	0	|	pmt_validate_activities	|	New Function	|	To validate string array of activity_ids. Returns integer array of only the valid passed activity_ids	|
|	5	|	7	|	pmt_taxonomies	|	New Function	|	Returns all or requested taxonomy/classification as nested json	|
|	5	|	6	|	pmt_filter_orgs	|	New Function	|	Filter organizations by the same parameters as other filter functions. Returning organization id and name.	|
|	5	|	4	|	pmt_tax_inuse	|	Additional Functionality	|	Adding parameter for filtering by country ids	|
|	5	|	3	|	pmt_filter_locations	|	Performance Improvement	|	Change return value from c_ids to r_ids	|
|	5	|	2	|	pmt_locations_by_org	|	Additional Functionality	|	Adding parameter for filtering by country ids	|
|	5	|	2	|	pmt_locations_by_tax	|	Additional Functionality	|	Adding parameter for filtering by country ids	|
|	5	|	1	|	pmt_validate_classifications	|	New Function	|	To validate string array of classification_ids. Returns integer array of only the valid passed classification_ids	|
|	5	|	1	|	pmt_validate_classification	|	New Function	|	To validate a single classification_id. Returns boolean.	|
|	5	|	1	|	pmt_validate_taxonomies	|	New Function	|	To validate string array of taxonomy_ids. Returns integer array of only the valid passed taxonomy_ids	|
|	5	|	1	|	pmt_validate_taxonomy	|	New Function	|	To validate a single taxonomy_id. Returns boolean.	|
|	5	|	1	|	pmt_tax_inuse	|	Additional Functionality	|	Order by most used.	|
|	5	|	1	|	pmt_locations_by_org	|	New Function	|	Locations ordered by georef and reporting organization. Accepts filter params: classification ids and data group id	|
|	5	|	1	|	pmt_locations_by_tax	|	Performance Improvement	|	Removed unused join to classification, change return value from c_ids to r_ids	|
