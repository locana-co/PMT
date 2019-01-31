# 3.0.10

The 3.0 version is a significant change to the data model and requires the update of all
dependencies. Below is the current status of those updates:

- [Function Updates](#function_updates)

- [View Updates](#view_updates)

## Function Updates

The following is a listing of existing functions in the PMT. This list is intended to be used to track the evaluation and 
completion of function updates for existing functions. Removal of the project entity from the data model requires all functions 
be re-evaluated and tested.

|**Name**			|**Type**|**Remove/Update**|**Complete** |**Documented**|**Unit Test**			     		 |**Notes**					|
|------------------------------	|:------:|:---------------:|:-----------:|:------------:|------------------------------------------------|----------------------------------------------|
|bmgf_filter_csv		|Function|Updated	   |&check;	 |&check;	|						 |Rename pmt_export_bmgf. 			|
|bmgf_global_search		|Function|Remove	   |		 |		|						 |						|
|bmgf_infobox_project_info	|Function|Remove	   |		 |		|						 |						|
|bmgf_locations_by_tax		|Function|Remove	   |		 |		|						 |						|
|bmgf_project_list		|Function|Remove	   |		 |		|						 |						|
|pmt_activate_activity		|Function|		   |		 |		|						 |						|
|pmt_activate_project		|Function|Remove	   |		 |		|						 |						|
|pmt_activities			|Function|		   |		 |		|						 |						|
|pmt_activities_by_tax		|Function|		   |		 |		|						 |						|
|pmt_activity			|Function|Update	   |In-progress	 |		|						 |						|
|pmt_activity_count		|Function|New	   	   |&check;	 |&check;	|						 |Returns count of activities for a filter|
|pmt_activity_count_by_participants|Function|New	   |&check;	 |&check;	|						 |Returns count of activities by organization for a specific organization role, supports walkshed & target analysis|
|pmt_activity_count_by_taxonomy |Function|New		   |&check;	 |&check;	|						 |Returns count of provided activity ids that are assigned to a specified taxonomy, supports walkshed & target analysis|
|pmt_activity_ids_by_boundary	|Function|New		   |&check;	 |&check;	|						 |Returns activity_ids for a given boundary feature|
|pmt_activity_listview		|Function|		   |		 |		|						 |						|
|pmt_activity_listview_ct	|Function|		   |		 |		|						 |						|
|pmt_auto_complete		|Function|Updated	   |&check;	 |&check;	|						 |						|
|pmt_boundary_search    |Function|New          |&check;	 |&check;	|						 |						| Returns boundary recs where the name matches search text
|pmt_bytea_import		|Function|		   |		 |		|						 |						|
|pmt_category_root		|Function|		   |		 |		|						 |						|
|pmt_category_root		|Function|		   |		 |		|						 |						|
|pmt_clone_activity		|Function|		   |		 |		|						 |						|
|pmt_contacts			|Function|		   |		 |		|						 |						|
|pmt_countries			|Function|		   |		 |		|						 |						|
|pmt_data_groups		|Function|Update	   |&check;	 |&check;	|						 |update for new naming convention changes      |
|pmt_edit_activity		|Function|		   |		 |		|						 |						|
|pmt_edit_activity_contact	|Function|		   |		 |		|						 |						|
|pmt_edit_activity_taxonomy	|Function|		   |		 |		|						 |						|
|pmt_edit_contact		|Function|		   |		 |		|						 |						|
|pmt_edit_detail		|Function|		   |		 |		|						 |						|
|pmt_edit_financial		|Function|		   |		 |		|						 |						|
|pmt_edit_financial_taxonomy	|Function|		   |		 |		|						 |						|
|pmt_edit_location		|Function|		   |		 |		|						 |						|
|pmt_edit_location_taxonomy	|Function|		   |		 |		|						 |						|
|pmt_edit_organization		|Function|		   |		 |		|						 |						|
|pmt_edit_participation		|Function|		   |		 |		|						 |						|
|pmt_edit_participation_taxonomy|Function|		   |		 |		|						 |						|
|pmt_edit_project		|Function|Remove	   |		 |		|						 |						|
|pmt_edit_project_contact	|Function|Remove	   |		 |		|						 |						|
|pmt_edit_project_taxonomy	|Function|Remove	   |		 |		|						 |						|
|pmt_edit_user			|Function|Update	   |&check;      |&check;	|						 |update for new naming convention changes      |
|pmt_edit_user_project_role	|Function|Remove	   |		 |		|						 |						|
|pmt_export_tanaim		|Function|New		   |&check;	 |&check;	|						 |New custom export function for tanaim		|
|pmt_filter			|Function|New		   |&check;      |&check;	|						 |New function to centralize filter logic	|
|pmt_filter_csv			|Function|Updated	   |&check;	 |&check;	|						 |Rename pmt_export				|
|pmt_filter_iati		|Function|		   |		 |		|						 |						|
|pmt_filter_locations		|Function|Remove	   |		 |		|						 |						|
|pmt_filter_orgs		|Function|Remove	   |		 |		|						 |						|
|pmt_filter_projects		|Function|Remove	   |		 |		|						 |						|
|pmt_global_search		|Function|Updated	   |&check;	 |&check;	|						 |						|
|pmt_iati_import		|Function|Update	   |&check;	 |&check;	|						 |Remove project references and replace option	|
|pmt_etl_iati_codelist		|Function|New   	   |&check;	 |       	|						 |New function to isolate the codelist ETL logic	|
|pmt_etl_iati_activities_v201	|Function|New   	   |&check;	 |       	|						 |New function to isolate the activity ETL logic for version 2.01 of the IATI schema.	|
|pmt_etl_iati_activities_v104	|Function|New   	   |&check;	 |       	|						 |New function to isolate the activity ETL logic for version 1.04 of the IATI schema.|
|pmt_infobox_activity		|Function|Remove	   |		 |		|						 |						|
|pmt_infobox_menu		|Function|Remove	   |		 |		|						 |						|
|pmt_infobox_project_info	|Function|Remove	   |		 |		|						 |						|
|pmt_is_data_group		|Function|New		   |&check;	 |&check;	|						 |Returns boolean if data group id or name exists (overloaded method)|
|pmt_isdate			|Function|		   |		 |		|						 |						|
|pmt_isnumeric			|Function|		   |		 |		|						 |						|
|pmt_locations			|Function|		   |		 |		|						 |						|
|pmt_locations_by_org		|Function|		   |		 |		|						 |						|
|pmt_locations_by_polygon	|Function|Update	   |&check;	 |&check;	|						 |Renamed pmt_activities_by_polygon		|
|pmt_locations_by_polygon	|Function|Remove	   |		 |		|						 |Removed overloaded function accepting wkt and excluded activity ids|
|pmt_locations_by_tax		|Function|		   |		 |		|						 |						|
|pmt_locations_by_tax		|Function|		   |		 |		|						 |						|
|pmt_locations_for_boundaries	|Function|New		   |&check;	 |&check;	|						 |Calculates and returns the counts for activities and locations for all features in a requested boundary.|
|pmt_org_inuse			|Function|Updated	   |&check;	 |&check;	|						 |						|
|pmt_orgs			|Function|Updated	   |&check;	 |&check;	|						 |						|
|pmt_partner_sankey		|Function|Updated	   |&check;	 |&check;	|						 |						|
|pmt_project			|Function|Remove	   |		 |		|						 |						|
|pmt_project_listview		|Function|Remove	   |		 |		|						 |						|
|pmt_project_listview_ct	|Function|Remove	   |		 |		|						 |						|
|pmt_project_users		|Function|Remove	   |		 |		|						 |						|
|pmt_projects			|Function|Remove	   |		 |		|						 |						|
|pmt_purge_activity		|Function|Updated	   |&check;	 |&check;	|						 |						|
|pmt_purge_project		|Function|Remove	   |&check;	 |&check;	|						 |						|
|pmt_sector_compare		|Function|		   |		 |		|						 |						|
|pmt_stat_activity_by_district	|Function|		   |		 |		|						 |						|
|pmt_stat_activity_by_tax	|Function|		   |		 |		|						 |						|
|pmt_stat_counts		|Function|		   |		 |		|						 |						|
|pmt_stat_locations		|Function|		   |		 |		|						 |						|
|pmt_stat_orgs_by_activity	|Function|		   |		 |		|						 |						|
|pmt_stat_orgs_by_district	|Function|		   |		 |		|						 |						|
|pmt_stat_partner_network	|Function|		   |		 |		|						 |						|
|pmt_stat_pop_by_district	|Function|		   |		 |		|						 |						|
|pmt_stat_project_by_tax	|Function|Remove	   |		 |		|						 |						|
|pmt_statistic_data		|Function|New		   |&check;	 |&check;	|						 |Returns statistics for a given indicator	|
|pmt_statistic_indicators	|Function|New		   |&check;	 |&check;	|						 |Returns all available statistic indicators    |
|pmt_tax_inuse			|Function|		   |		 |		|						 |						|
|pmt_taxonomies			|Function|		   |		 |		|						 |						|
|pmt_user			|Function|		   |		 |		|						 |						|
|pmt_user_auth			|Function|Updated	   |&check;	 |&check;	|						 |						|
|pmt_user_salt			|Function|Updated	   |&check;	 |&check;	|						 |						|
|pmt_users			|Function|Updated	   |&check;	 |&check;	|						 |						|
|pmt_validate_activities	|Function|Updated	   |&check;	 |&check;	|						 |						|
|pmt_validate_activity		|Function|		   |		 |		|						 |						|
|pmt_validate_boundary_feature	|Function|Updated	   |&check;	 |&check;	|						 |Remove project dependency			|
|pmt_validate_classification	|Function|Updated	   |&check;	 |&check;	|						 |						|
|pmt_validate_classifications	|Function|Updated	   |&check;	 |&check;	|						 |						|
|pmt_validate_contact		|Function|		   |		 |		|						 |						|
|pmt_validate_contacts		|Function|		   |		 |		|						 |						|
|pmt_validate_detail		|Function|		   |		 |		|						 |						|
|pmt_validate_financial		|Function|		   |		 |		|						 |						|
|pmt_validate_financials	|Function|		   |		 |		|						 |						|
|pmt_validate_location		|Function|Updated	   |&check;	 |&check;	|						 |						|
|pmt_validate_locations		|Function|Updated	   |&check;	 |&check;	|						 |						|
|pmt_validate_organization	|Function|Updated	   |&check;	 |&check;	|						 |						|
|pmt_validate_organizations	|Function|		   |		 |		|						 |						|
|pmt_validate_participation	|Function|		   |		 |		|						 |						|
|pmt_validate_participations	|Function|		   |		 |		|						 |						|
|pmt_validate_project		|Function|Remove	   |		 |		|						 |						|
|pmt_validate_projects		|Function|Remove	   |		 |		|						 |						|
|pmt_validate_role		|Function|		   |		 |		|						 |						|
|pmt_validate_taxonomies	|Function|		   |		 |		|						 |						|
|pmt_validate_taxonomy		|Function|Updated	   |&check;	 |&check;	|						 |						|
|pmt_validate_user		|Function|Updated	   |&check;	 |&check;	|						 |update for new naming convention changes	|
|pmt_validate_user_authority	|Function|Updated	   |&check;	 |&check;	|						 |Changed authority to activity			|
|pmt_version			|Function|	           |		 |		|						 |                               		|
|process_xml			|Trigger |Updated	   |  		 |		|						 |Changed name to pmt_process_iati		|
|refresh_partnerlink_sankey	|Function|		   |		 |		|						 |						|
|refresh_taxonomy_lookup	|Function|		   |		 |		|						 |						|
|tanaim_activity		|Function|		   |		 |		|						 |						|
|tanaim_filter_csv		|Function|Updated	   |&check;	 |&check;	|						 |Rename pmt_export_taniam 			|
|**upd_boundary_features**	|Trigger |Updated	   |&check;	 |&check;	|						 |						|
|**upd_geometry_formats**	|Trigger |Updated	   |&check;	 |&check;	|test_upd_geometry_formats			 |Changed name to pmt_upd_geometry_formats	|
|pmt_orgs			|Function|Updated          |&check;      |&check;       |             			     		 |added _label to output


## View Updates

The following is a listing of existing views in the PMT. This list is intended to be used to track the evaluation and 
completion of view updates for existing views. Removal of the project entity from the data model requires all views 
be re-evaluated and tested.

All core views will be rename and prefixed with an underscore (_), per new naming convention as outlined in the PMT 
Database documentation ([see documentation](https://github.com/spatialdev/PMT-Database/blob/master/Documentation/DataDictionary.md#pmt-database-data-dictionary) for more information on the naming convention).


|**Name**				|**Type**|**Remove/Update**|**Complete**|**Notes**				|
|---------------------------------------|:------:|:---------------:|:----------:|---------------------------------------|
|accountable\_organizations		|V	 |Update	   |&check;	|Removed classification\_id and added activity count|
|accountable\_project\_participants	|V	 |Removed	   |&check;	|                                       |
|active\_project\_activities		|V	 |Update	   |&check;	|Rename to _active\_activities_		|
|activity\_contacts			|V	 |Update	   |&check;	|					|
|activity\_participants			|V	 |Update	   |&check;	|Rename to _partnerlink\_participants_  |
|activity\_participants			|V	 |New		   |&check;	|Create un-pivoted version		|
|activity\_taxonomies			|V	 |Updated	   |&check;	|Added data group			|
|activity\_taxonomy\_xwalks		|V	 |Updated	   |&check;	|Re-wrote to be non-instance specific	|
|data\_change\_report			|V	 |Updated	   |&check;	|					|
|data\_loading\_report			|V	 |Updated	   |&check;	|					|
|data\_validation\_report		|V	 |Updated	   |&check;	|					|
|entity\_taxonomy			|V	 |Updated	   |&check;	|					|
|gaul\_lookup				|V	 |Updated	   |&check;	|					|
|location\_boundary\_features		|V	 |Updated	   |&check;	|Re-wrote to be non-instance specific	|
|location\_lookup			|MV	 |Updated	   |&check;	|No longer a materialized view		|
|organization\_lookup			|MV	 |Updated	   |&check;	|No longer a materialized view		|
|organization\_participation		|V	 |Updated	   |&check;	|Removed unused/under-used columns	|
|partnerlink\_sankey\_links		|MV	 |Updated	   |&check;	|					|
|partnerlink\_sankey\_nodes		|MV	 |Updated	   |&check;	|					|
|project\_activity\_points		|V	 |Updated	   |&check;	|Renamed _activity\_points_		|
|project\_contacts			|V	 |Removed	   |&check;	|					|
|project\_taxonomies			|V	 |Removed	   |&check;	|					|
|project\_taxonomy\_xwalks		|V	 |Removed	   |&check;	|					|
|tags					|V	 |Updated	   |&check;	|					|
|tanaim\_aaz				|V	 |Updated	   |&check;	|Instance specific view			|
|tanaim\_nbs				|V	 |Updated	   |&check;	|Instance specific view			|
|taxonomy\_classifications		|V	 |Updated	   |&check;	|					|
|taxonomy\_lookup			|MV	 |Updated	   |&check;	|No longer a materialized view		|
|taxonomy\_xwalks			|V	 |Updated	   |&check;	|					|