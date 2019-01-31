# PMT Database Function Documentation

The PMT Database contains a large number of functions that support various application &
database functionality. This documentation contains a description of the function, its 
parameters and examples for usage. Please report any errors to the issues page.

_Note: A small number of functions are deprecated in version 10, but are included so that
logic is not lost. If needed, these functions will need to be updated for v10._

## Function Listing

[pmt\_2x2](#pmt_2x2)

[pmt\_2x2\_regions](#pmt_2x2_regions)

[pmt\_activate\_activity](#pmt_activate_activity)

[pmt\_activities](#pmt_activities)

[pmt\_activities\_by\_polygon](#pmt_activities_by_polygon)

[pmt\_activity](#pmt_activity)

[pmt\_activity\_by\_invest](#pmt_activity_by_invest)

[pmt\_activity\_count](#pmt_activity_count)

[pmt\_activity\_count\_by\_participants](#pmt_activity_count_by_participants)

[pmt\_activity\_count\_by\_taxonomy](#pmt_activity_count_by_taxonomy)

[pmt\_activity\_detail](#pmt_activity_detail)

[pmt\_activity\_family\_titles](#pmt_activity_family_titles)

[pmt\_activity\_ids\_by\_boundary](#pmt_activity_ids_by_boundary)

[pmt\_activity\_titles](#pmt_activity_titles)

[pmt\_are\_data\_group](#pmt_are_data_group)

[pmt\_auto\_complete](#pmt_auto_complete)

[pmt\_boundaries\_by\_point](#pmt_boundaries_by_point)

[pmt\_boundary\_extents](#pmt_boundary_extents)

[pmt\_boundary\_feature](#pmt_boundary_feature)

[pmt\_boundary\_filter](#pmt_boundary_filter)

[pmt\_boundary\_hierarchy](#pmt_boundary_hierarchy)

[pmt\_boundary\_pivot](#pmt_boundary_pivot)

[pmt\_boundary\_search](#pmt_boundary_search)

[pmt\_bytea\_import](#pmt_bytea_import)

[pmt\_category\_root](#pmt_category_root) **Deprecated**

[pmt\_classification\_search](#pmt_classification_search)

[pmt\_classification\_count](#pmt_classification_count)

[pmt\_classifications](#pmt_classifications)

[pmt\_clone\_activity](#pmt_clone_activity) **Deprecated**

[pmt\_consolidate\_orgs](#pmt_consolidate_orgs)

[pmt\_contacts](#pmt_contacts)

[pmt\_data\_groups](#pmt_data_groups)

[pmt\_edit\_activity](#pmt_edit_activity)

[pmt\_edit\_activity\_contact](#pmt_edit_activity_contact) **Deprecated**

[pmt\_edit\_activity\_taxonomy](#pmt_edit_activity_taxonomy)

[pmt\_edit\_classification](#pmt_edit_classification)

[pmt\_edit\_contact](#pmt_edit_contact)

[pmt\_edit\_detail](#pmt_edit_detail)

[pmt\_edit\_detail\_taxonomy](#pmt_edit_detail_taxonomy)

[pmt\_edit\_financial](#pmt_edit_financial)

[pmt\_edit\_financial\_taxonomy](#pmt_edit_financial_taxonomy)

[pmt\_edit\_location](#pmt_edit_location)

[pmt\_edit\_location\_taxonomy](#pmt_edit_location_taxonomy) **Deprecated**

[pmt\_edit\_organization](#pmt_edit_organization) 

[pmt\_edit\_participation](#pmt_edit_participation)

[pmt\_edit\_participation\_taxonomy](#pmt_edit_participation_taxonomy) **Deprecated**

[pmt\_edit\_taxonomy](#pmt_edit_taxonomy)

[pmt\_edit\_user](#pmt_edit_user)

[pmt\_edit\_user\_activity](#pmt_edit_user_activity)

[pmt\_export](#pmt_export)

[pmt\_exists\_activity_contact](#pmt_exists_activity_contact)

[pmt\_filter](#pmt_filter)

[pmt\_filter\_iati](#pmt_filter_iati) **Deprecated**

[pmt\_filter\_string](#pmt_filter_string)

[pmt\_find\_users](#pmt_find_users)

[pmt\_get\_valid\_id](#pmt_get_valid_id)

[pmt\_global\_search](#pmt_global_search)

[pmt\_iati\_import](#pmt_iati_import)

[pmt\_is\_data\_group](#pmt_is_data_group)

[pmt\_is\_data\_groups](#pmt_is_data_groups)

[pmt\_isdate](#pmt_isdate)

[pmt\_isnumeric](#pmt_isnumeric)

[pmt\_locations](#pmt_locations)

[pmt\_locations\_for\_boundaries](#pmt_locations_for_boundaries)

[pmt\_org\_inuse](#pmt_org_inuse)

[pmt\_orgs](#pmt_orgs)

[pmt\_overview_stats](#pmt_overview_stats)

[pmt\_partner\_pivot](#pmt_partner_pivot)

[pmt\_partner\_sankey](#pmt_partner_sankey)

[pmt\_partner\_sankey\_activities](#pmt_partner_sankey_activities)

[pmt\_purge\_activities](#pmt_purge_activities)

[pmt\_purge\_activity](#pmt_purge_activity)

[pmt\_refresh\_views](#pmt_refresh_views)

[pmt\_roles](#pmt_roles)

[pmt\_stat\_activity\_by\_tax](#pmt_stat_activity_by_tax)

[pmt\_stat\_by\_org](#pmt_stat_by_org)

[pmt\_stat\_invest\_by\_funder](#pmt_stat_invest_by_funder)

[pmt\_statistic\_data](#pmt_statistic_data)

[pmt\_statistic\_indicators](#pmt_statistic_indicators)

[pmt\_taxonomies](#pmt_taxonomies)

[pmt\_taxonomy\_count](#pmt_taxonomy_count)

[pmt\_taxonomy\_search](#pmt_taxonomy_search)

[pmt\_update\_crosswalks](#pmt_update_crosswalks)

[pmt\_update\_location\_boundries](#pmt_update_location_boundries)

[pmt\_user\_auth](#pmt_user_auth)

[pmt\_user\_orgs](#pmt_user_orgs)

[pmt\_user\_salt](#pmt_user_salt)

[pmt\_users](#pmt_users)

[pmt\_validate\_activities](#pmt_validate_activities)

[pmt\_validate\_activity](#pmt_validate_activity)

[pmt\_validate\_boundary\_feature](#pmt_validate_boundary_feature)

[pmt\_validate\_classification](#pmt_validate_classification)

[pmt\_validate\_classifications](#pmt_validate_classifications)

[pmt\_validate\_contact](#pmt_validate_contact)

[pmt\_validate\_contacts](#pmt_validate_contacts)

[pmt\_validate\_detail](#pmt_validate_detail)

[pmt\_validate\_details](#pmt_validate_details)

[pmt\_validate\_financial](#pmt_validate_financial)

[pmt\_validate\_financials](#pmt_validate_financials)

[pmt\_validate\_location](#pmt_validate_location)

[pmt\_validate\_locations](#pmt_validate_locations)

[pmt\_validate\_organization](#pmt_validate_organization)

[pmt\_validate\_organizations](#pmt_validate_organizations) **Deprecated**

[pmt\_validate\_participation](#pmt_validate_participation)

[pmt\_validate\_participations](#pmt_validate_participations) **Deprecated**

[pmt\_validate\_role](#pmt_validate_role)

[pmt\_validate\_taxonomies](#pmt_validate_taxonomies)

[pmt\_validate\_taxonomy](#pmt_validate_taxonomy)

[pmt\_validate\_user](#pmt_validate_user)

[pmt\_validate\_user\_authority](#pmt_validate_user_authority)

[pmt\_validate\_username](#pmt_validate_username)

[pmt\_version](#pmt_version)

[test\_execute\_unit\_tests](#test_execute_unit_tests)

* * * * *

## pmt\_2x2

##### Description

Returns 2x2 data for a requested country & region.

##### Parameter(s)

1. country (character varying) - **Required** the country name.
2. region (character varying) - **Required** the region name within the country for the 2x2 data.

##### Result

Json with the following:

1.  country (character varying) – name of the country
2.  regions (character varying[]) - array of region names with in the country that have 2x2 data

##### Example(s)

-   Get all participating country & regions for the 2x2:

```
SELECT * FROM pmt_2x2_regions(); 
```

```
{
	"order":0,
	"category":"Low-Low",
	"districts":"Guji, Horo Guduru, Mirab Hararghe, Ilubabor, Jimma, Kelem Wellega, Bale, Mirab Shewa, Mirab Welega, Misraq Harerge, Misraq Wellega, North Shewa",
	"area":192455.44,
	"pop":22218885.238295598,
	"popden":115.4495047700163633,
	"povden":0.40458716053960334922
},
{
	"order":1,
	"category":"Low-Hi",
	"districts":"",
	"area":0,
	"pop":0,
	"popden":0,
	"povden":0
},
{
	"order":2,
	"category":"Hi-Low",
	"districts":"Debub Mirab Shewa, Arsi, Mirab Arsi, Borena",
	"area":83545.20,
	"pop":8065437.75257711,
	"popden":96.5398102174285297,
	"povden":0.38057243264723766297
}
{
	"order":3,
	"category":"Hi-Hi",
	"districts":"Misraq Shewa",
	"area":8370.9,
	"pop":1956499.81554151,
	"popden":233.7263395263962059,
	"povden":0.93239675542653717044
}
{
	"order":4,
	"category":"n/a",
	"districts":"",
	"area":0,
	"pop":0,
	"popden":0,
	"povden":0
}

```

[&larr;  Back to Function List](#function-listing)


## pmt\_2x2\_regions

##### Description

Returns participating country & regions for the 2x2 tool.

##### Parameter(s)

No parameters

##### Result

Json with the following:

1.  id (integer) – id of the gadm0 feature representing the country
2.  country (character varying) – name of the country
3.  extent (wkt) – polygon extent of the country
4.  regions (json[]) - array of json objects
    1. id (integer) – id of the gadm1 feature representing the region within the country
    2. _name (character varying) - name of the region

##### Example(s)

-   Get all participating country & regions for the 2x2:

```
SELECT * FROM pmt_2x2_regions(); 
```

```
"{"id":74,"_name":"Ethiopia","extent":"POLYGON((33.0015373229982 3.39882302284263,33.0015373229982 14.8454771041872,47.9582290649417 14.8454771041872,47.9582290649417 3.39882302284263,33.0015373229982 3.39882302284263))","regions":[{"id":15174,"_name":"Addi (...)"
{
	"id":74,
	"country":"Ethiopia",
	"extent":"POLYGON((33.0015373229982 3.39882302284263,33.0015373229982 14.8454771041872,47.9582290649417 14.8454771041872,47.9582290649417 3.39882302284263,33.0015373229982 3.39882302284263))"
	"regions":[
		{
			"id":889,
			"_name":"Addis Abeba"
		},
		{
			"id":890,
			"_name":"Afar"
		},
		...
		{
			"id":899,
			"_name":"Tigray"
		}
	]
},
{
	"id":227,
	"country":"Tanzania",
	"extent":"POLYGON((29.3271675109864 -11.7456951141355,29.3271675109864 -0.985787510871774,40.445137023926 -0.985787510871774,40.445137023926 -11.7456951141355,29.3271675109864 -11.7456951141355))"
	"regions":[
		{
			"id":2998,
			"_name":"Arusha"
		},
		{
			"id":2999,
			"_name":"Dar es Salaam"
		},
		{	
			"id":3000,
			"_name":"Dodoma"
		},
		...
		{	
			"id":3027,
			"_name":"Zanzibar West"
		}	
	]
}
...

```

[&larr;  Back to Function List](#function-listing)


## pmt\_activate\_activity

##### Description

Activate/deactivate an activity and its related records (locations, financial, participation, detail, result).

##### Parameter(s)

1.  instance\_id (integer) – **Required**. instance id in which the requesting edit originates.
2.  user\_id (integer) – **Required**. user id of user requesting edit.
3.  activity\_id (integer) – **Required**. activity id to activate/deactivate.
4.  activate (boolean) - **Default is TRUE**. True to activate, false to deactivate.

##### Result

Json with the following:

1.  id (integer) – activity id of the activity activated/deactivated.
2.  message(character varying) - Message containing either "Success" for a successful transaction 
or containing an error description regarding the unsuccessful transaction. Some possible error messages:
	- Must included instance\_id, user\_id and activity\_id data parameters
	- User does NOT have authority to change the active status of this activity and its assoicated records

##### Example(s)

-   Activate the activity\_id 15820 and its related records.

```select * from pmt_activate_activity(34, 15820, true);```

```{"id":15820,"message":"Success"}```

-  Deactivate the activity\_id 15820 and its related records.

```select * from pmt_activate_activity(34, 15820, false);```

```{"id":15820,"message":"Success"}```

[&larr;  Back to Function List](#function-listing)


## pmt\_activities


##### Description

Get a filterable list of activities.

##### Parameter(s)


1. data\_group\_ids (character varying) - comma seperated list of classification id(s) from the Data Group taxonomy
to restrict data. If no data group id is provided, all data groups are included.
2. classification\_ids (character varying) - comma seperated list of classification id(s) for any taxonomy (filter).
3. org\_ids (character varying) - comma seperated list of organization id(s) for organizations for all participation types (filter).
4. imp\_org\_ids (character varying) - comma seperated list of organization id(s) for implementing organizations (filter).
5. fund\_org\_ids (character varying) - comma seperated list of organization id(s) for funding organizations (filter).
6. start\_date (date) - start date for activities (filter).
7. end\_date (date) - end date for activities (filter).
8. unassigned\_taxonomy\_ids (character varying) - comma seperated list of taxonomy id(s) for any taxonomy, will return activities that _DO NOT_ have that taxonomy assigned (filter).
9. activity\_ids (character varying) - comma seperated list of activity id(s) to restrict data aggregation to.
10. boundary\_filter (json) - a json array of objects. Each object must contain "b" with a boundary id and "ids" with an array of feature ids (i.e. ```[{"b":12,"ids":[2,3]},{"b":13,"ids":[73,85]}]```)

##### Result

Json with the following:

1.  id (integer) – the activity id.
2.  pid (integer) – the activity id of the parent activity.
3.  dgid (integer) – the data group id for the activity.
4.  dg (character varying) – the name of the data group for the activity
5.  t (character varying) – title of activity.
6.  a (numeric) – total investment amount for the activity.
7.  sd (date) - the activity start date.
8.  ed (date) - the activity end date.
9.  f (character varying[]) - array of funding organizations for the activity.

##### Example(s)

- All activities for BMGF (data\_group\_id: 768) that have an Activity Status (taxonomy id: 18) of "Complete" (classification id: 797) or do 
not have an Activity Status (taxonomy id: 18) assigned between 1/1/2005 and 1/1/2020:

```select * from pmt_activities('768','797',null,null,null,'1/1/2005','1/1/2020','18',null);  ```

```
...
{
	"id":1841,
	"pid":23728,
	"dgid":768,
	"dg":"BMGF",
	"t":"Tanzania Tropical Pesticides Research Institute",
	"a":200000.00,
	"sd":"2008-02-01",
	"ed":"2013-01-31",
	"f":{
		"Bill & Melinda Gates Foundation (BMGF)"
	}
},
{
	"id":1842,
	"pid":23546,
	"dgid":768,
	"dg":"BMGF",
	"t":"Quarterly review meeting",
	"a":null
	"sd":"2011-11-01",
	"ed":"2016-11-30",
	"f":{null}
},
{
	"id":1843,
	"pid":23546,
	"dgid":768,
	"dg":"BMGF",
	"t":"Equip women farmers and collective members with life skills",
	"a":null,
	"sd":"2011-11-01",
	"ed":"2016-11-30",
	"f":{null}
}
...
```

[&larr;  Back to Function List](#function-listing)


## pmt\_activities\_by\_polygon

##### Description

Select activities within a given polygon.

##### Parameter(s)

1.  wktpolygon (text) – **Required**. Well-known text representation of a polygon.
2. data\_group\_ids (character varying) - comma seperated list of classification\_id(s) from the Data Group taxonomy
to restrict data aggregation to. If no data group id is provided, all data groups are included.
3. classification\_ids (character varying) - comma seperated list of classification\_id(s) for any taxonomy (filter).
4. org\_ids (character varying) - comma seperated list of organization\_id(s) for any organization regardless of role (filter).
5. imp\_org\_ids (character varying) - comma seperated list of organization\_id(s) for implementing organizations (filter).
6. fund\_org\_ids (character varying) - comma seperated list of organization\_id(s) for funding organizations (filter).
7. start\_date (date) - start date for activities (filter).
8. end\_date (date) - end date for activities (filter).
9. unassigned\_taxonomy\_ids (character varying) - comma seperated list of taxonomy id(s) for any taxonomy, will return activities that _DO NOT_ have that taxonomy assigned (filter).
10. activity\_ids (character varying) - comma seperated list of activity id(s) to restrict data aggregation to.
11. boundary\_filter (json) - a json array of objects. Each object must contain "b" with a boundary id and "ids" with an array of feature ids (i.e. ```[{"b":12,"ids":[2,3]},{"b":13,"ids":[73,85]}]```)


##### Result

Json with the following:

1.  activity\_ids (integer[]) – integer array of activity ids.

##### Example(s)

-   Get activities for BMGF & AGRA (data\_groups\_id: 768,769) between 2001 and 2021 within a given polygon:

```
select * from pmt_activities_by_polygon('POLYGON((-16.473 13.522,-16.469 13.186,-16.764 13.185,-16.797 13.491,-16.472 13.517,-16.473 13.522))','768,769',null,null,null,null,'01-01-2001','12-31-2021',null, null,null); 
```

```
{
	"activity_ids":[14893,14895]
}
```

[&larr;  Back to Function List](#function-listing)


## pmt\_activity


##### Description

All information for a single activity.

##### Parameter(s)

1. activity_id (integer) - **Required.** Activity id.

##### Result

Json with the following:

1.  id (integer) – activity id.
2.  data\_group\_id (integer) – the data group id.
3.  parent\_id (integer) – the activity's parent id (if null the activity is a parent).
4.  \_title (character varying) – title of activity.
5.  \_label (character varying) – short title for activity.
6.  \_description (character varying) – description of activity.
7.  \_objective (character varying) – the objective for activity.
8.  \_content (character varying) – various content for activity.
9.  \_url (character varying) – url for activity.
10.  \_start\_date (date) – start date of activity.
11.  \_planned\_start\_date (date) – planned start date of activity.
12.  \_planned\_end\_date (date) – end date of activity.
13.  \_end\_date (date) – planned end date of activity.
14.  \_tags (character varying) – tags or keywords of activity.
15.  \_iati\_identifier (integer) – iati identifier or primary key of activity.
16.  \_iati\_import\_id (integer) – iati import id for the corresponding import record (if null the data was manually loaded).
17.  \_updated\_by (character varying(50)) -  last user to update activity information.
18.  \_updated\_date (timestamp) -  last date and time activity information was updated.
19.  custom\_fields (various) - any custom fields in the activity table that are not in the Core PMT will be returned as well.
20.  data\_group (character varying) – the data group name.
21.  parent\_title (character varying) – the activity's parent activity title.
22.  ct (integer) - number of locations for activity.
23.  taxonomy(object) - An object containing all associated taxonomy for the activity
	1. taxonomy\_id (integer) - taxonomy id.
	2. taxonomy (character varying) - taxonomy name.
	3. classification\_id (integer) - classification id.
	4. classification (character varying) - classification name.
	5. code (character varying) - classification code.
24.  organizations(object) - An object containing all organizations participating in the activity
	1. organization (character varying) - organization name
	2. role (character varying) - the organization's role in the activity (Organisation Role taxonomy)
	3. type (charcter varyng) - the organization's type in the activity (Organisation Type taxonomy)
	4. prime (charcter varyng) - the organization's prime designation in the activity (Implementing Types taxonomy)
	5. url (character varying) - the url for the organization.
	6. address (character varying) - the organization's address.
	7. city (character varying) - the city of the organization.
	8. state\_providence (character varying) - the state or providence of the organization.
	9. zip (character varying) - the zip code for the providence.
	10. country (character varying) - the country of the organization.
25.  contacts (object) - An object containing all activity contacts.
	1. id (integer) - the contact id.
	2. \_first\_name (character varying) - contact's first name.
	3. \_last\_name (character varying) - contact's last name.
	4. \_email (character varying) - contact's email address.
	5. \_title (character varying) - contact's title.
	6. organization\_id (integer) - organization id.
	7. \_name (character varying) - organization name the contact is associated with.
26.  details (object) - An object containing all activity details.
	1. detail\_id (integer) - detail id.
	2. \_title (character varying) - the title of the detail.
	3. \_description (character varying) - description of the detail.
	4. \_amount (numeric (12,2)) - detail amount.
	5. taxonomy(object) - An object containing all associated taxonomy for the financial record
		1. taxonomy\_id (integer) - taxonomy id.
		2. taxonomy (character varying) - taxonomy name.
		3. classification\_id (integer) - classification id.
		4. classification (character varying) - classification name.
		5. code (character varying) - classification code.
27.  financials (object) - An object containing all activity financial data.
	1. id (integer) - financial id.
	2. \_amount (numeric (100,2)) - financial amount.	
	3. \_start\_date (date) – start date for financial amount.
	4. \_end\_date (date) – end date for financial amount.
	5. provider (character varying) - the name of the organization providing the financial amount.
	6. recipient (character varying) - the name of the organization receiving the financial amount.
	7. taxonomy(object) - An object containing all associated taxonomy for the financial record
		1. taxonomy\_id (integer) - taxonomy id.
		2. taxonomy (character varying) - taxonomy name.
		3. classification\_id (integer) - classification id.
		4. classification (character varying) - classification name.
		5. code (character varying) - classification code.
28.  location\_ids (int[]) - An array of location_ids associated to the activity.
29.  locations (object) - An object containing all activity location data.
	1. id (integer) - location id.
	2. \_admin1 (character varying) - the name of the administrative level 1 boundray for the location.	
	3. \_admin2 (character varying) - the name of the administrative level 2 boundray for the location.
	4. \_admin3 (character varying) - the name of the administrative level 3 boundray for the location.
	5. \_admin_level (integer) - the administrative boundary level in which the location is mapped to.
	6. taxonomy(object) - An object containing all associated taxonomy for the financial record
		1. taxonomy\_id (integer) - taxonomy id.
		2. taxonomy (character varying) - taxonomy name.
		3. classification\_id (integer) - classification id.
		4. classification (character varying) - classification name.
		5. code (character varying) - classification code.
	7. boundaries(object) - An object containing all intersected boundaries for the activity's locations
		1. boundary\_id (integer) - boundary id.
		2. feature\_id (integer) - feature id of boundary.
		3. \_feature\_name (character varying) - the name of the feature.
30.  children (object) - An object containing all activity's children activities.
	1. id (integer) - child activity id.
	2. \_title (character varying) - child activity title.

##### Example(s)

```select * from pmt_activity(3);```

```
{
	"activity_id":3
	,"title":"UN collaborative Program for Reducing Emissions from Deforestation and forest Degradation in developing 
			countries, Tanzania (UN-REDD)"
	,"label":null
	,"description":"The project aims at strengthening Tanzanias readiness for Reducing Emissions from Deforestation and 
			forest Degradation (REDD) as a component of the Governments evolving REDD Strategy, and integrate it 
			with other REDD activities in the country"
	,"content":null
	,"start_date":"2009-10-01"
	,"end_date":"2013-12-31"
	,"tags":null	
	,"updated_by":"IATI XML Import"
	,"updated_date":"2014-01-16 00:00:00"
	,"iati_identifier":null
	,"location_ct":1
	,"admin_bnds":"United Republic of Tanzania,Singida,Manyoni"
	,"taxonomy":[{
		 "taxonomy_id":5
		,"taxonomy":"Country"
		,"classification_id":244
		,"classification":"TANZANIA, UNITED REPUBLIC OF"
		,"code":"TZ"
		}
		,{
		 "taxonomy_id":14
		,"taxonomy":"Sector Category"
		,"classification_id":552
		,"classification":"Other multisector"
		,"code":"430"
		}
		,{
		 "taxonomy_id":15
		,"taxonomy":"Sector"
		,"classification_id":729
		,"classification":"Multisector aid"
		,"code":"43010"
		}
		,{
		 "taxonomy_id":17
		,"taxonomy":"Category"
		,"classification_id":779
		,"classification":"Training and Capacity Building"
		,"code":null
		}
		,{
		 "taxonomy_id":18
		,"taxonomy":"Sub-Category"
		,"classification_id":792
		,"classification":"Training and Capacity Building"
		,"code":null
		}]
	,"organizations":[{
		 "organization_id":1
		,"name":"FAO/ UNEP/ UNDP"
		,"url":null
		,"taxonomy":[{
			"taxonomy_id":10
			,"taxonomy":"Organisation Role"
			,"classification_id":496
			,"classification":"Funding"
			,"code":"Funding"
			}]
		}
		,{
		"organization_id":56
		,"name":"Tanzania Forestry Service (TFS)"
		,"url":null
		,"taxonomy":[{
			"taxonomy_id":10
			,"taxonomy":"Organisation Role"
			,"classification_id":497
			,"classification":"Implementing"
			,"code":"Implementing"
			}]
		}
		,{
		"organization_id":2
		,"name":"MNRT, TFS"
		,"taxonomy":[{
			"taxonomy_id":10
			,"taxonomy":"Organisation Role"
			,"classification_id":497
			,"classification":"Implementing"
			,"code":"Implementing"
			}]
		}]
	,"contacts":[{
		"contact_id":1
		,"first_name":"Almas"
		,"last_name":"Kashindye"
		,"email":"Almas.Kashindye@fao.org"
		,"organization_id":1
		,"name":"FAO/ UNEP/ UNDP"
		}]
	,"details": null
	,"financials":[{
		 "financial_id":13
		,"amount":814972.00
		,"taxonomy":[{
			"taxonomy_id":6
			,"taxonomy":"Currency"
			,"classification_id":422
			,"classification":"US Dollar"
			,"code":"USD"
			}]
		}]
	,"locations":[{3}]
}
```

[&larr;  Back to Function List](#function-listing)


## pmt\_activity\_by\_invest


##### Description

Returns the top x number of activities, ordered by greatest investment amount.

##### Parameter(s)

1. data\_group\_ids (character varying) - comma seperated list of classification id(s) from the Data Group taxonomy
to restrict data. If no data group id is provided, all data groups are included.
2. classification\_ids (character varying) - comma seperated list of classification id(s) for any taxonomy (filter).
3. start\_date (date) - start date for activities (filter).
4. end\_date (date) - end date for activities (filter).
6. boundary\_id (integer) - the boundary id referenced by the feature\_id (filter).
7. feature\_id (integer) - the featuer id to restrict activities to (filter).
8. limit\_records (integer) - number of records to return.
9. field\_list (character varying) - list of additional activity fields to return. Example: 'opportunity_id,_description'


##### Result

Json with the following:

1.  id (integer) – the activity id.
2.  title (character varying) – the activity title.
3.  amount (numeric) – the investment amount for the activity.
4.  fund (character varying) - comma seperated listing of funding organization names for the activity.
5.  imp (character varying) - comma seperated listing of implementing organization names for the activity.
6.  acct (character varying) - comma seperated listing of accountable organization names for the activity.
7.  additional requested fields listed in the "field\_list" option.

##### Example(s)

-   Top 5 activities by investment, including the opportunity_id field for BMGF data group (data\_group\_id:768)
in Ethiopia (feature\_id: 74) using GADM 0 boundary (boundary\_id: 15):

```SELECT * FROM pmt_activity_by_invest('768',null,null,null,15,74,5,'opportunity_id');```

```
{
	"id":24905,
	"_title":"AGRA Soil Health Program",
	"amount":148135881.00,
	"fund":"Bill & Melinda Gates Foundation (BMGF)",
	"imp":"Alliance for a Green Revolution in Africa (AGRA)",	
	"acct":null,
	"opportunity_id":"OPP48790"
},
...
{
	"id":25130,
	"_title":"Renewal: STRASA Phase 3 - Stress-Tolerant Rice for Africa and South Asia",
	"amount":32770000.00,
	"fund":"Bill & Melinda Gates Foundation (BMGF)",
	"imp":"International Rice Research Institute (IRRI)",
	"acct":null,
	"opportunity_id":"OPP10888"
}

```

[&larr;  Back to Function List](#function-listing)


## pmt\_activity\_count

##### Description

Returns count of parent activities for a filter.

##### Parameter(s)

1. data\_group\_ids (character varying) - comma seperated list of classification\_id(s) from the Data Group taxonomy
to restrict data aggregation to. If no data group id is provided, all data groups are included.
2. classification\_ids (character varying) - comma seperated list of classification\_id(s) for any taxonomy (filter).
3. org\_ids (character varying) - comma seperated list of organization\_id(s) for any organization regardless of role (filter).
4. imp\_org\_ids (character varying) - comma seperated list of organization\_id(s) for implementing organizations (filter).
5. fund\_org\_ids (character varying) - comma seperated list of organization\_id(s) for funding organizations (filter).
6. start\_date (date) - start date for activities (filter).
7. end\_date (date) - end date for activities (filter).
8. unassigned\_taxonomy\_ids (character varying) - comma seperated list of taxonomy id(s) for any taxonomy, will return activities that _DO NOT_ have that taxonomy assigned (filter).
9. activity\_ids (character varying) - comma seperated list of activity id(s) to restrict data aggregation to.
10. boundary\_filter (json) - a json array of objects. Each object must contain "b" with a boundary id and "ids" with an array of feature ids (i.e. ```[{"b":12,"ids":[2,3]},{"b":13,"ids":[73,85]}]```)

##### Result

Json with the following:

1.  ct(integer) – total number of activities for a given filter.

##### Example(s)
-   Number of activities for BMGF data (data\_group\_id: 768) where Activity Status is Complete (classification\_id: 797) 
and activities occur between 1/1/2012 and 12/31/2018:

```SELECT * FROM pmt_activity_count('768','797',null,null,'1/1/2012','12/31/2018',null); ```

```
{
	"ct":67
}
```

-   Number of activities for BMGF data (data\_group\_id: 768) where Activity Status is Complete (classification\_id: 797) 
and activities occur between 1/1/2012 and 12/31/2018:

```SELECT * FROM pmt_activity_count('768','797',null,null,null,'1/1/2012','12/31/2018',null,null,null); ```

```
{
	"ct":67
}
```

[&larr;  Back to Function List](#function-listing)


## pmt\_activity\_count\_by\_participants

##### Description

Returns count of activities by organization for a specific organization role.

##### Parameter(s)

1. classification\_id (integer) - **Required** classification id of the Organisation Role taxonomy.
2. activity\_ids (character varying) -  **Required** comma seperated list of activity id(s) to be counted per organization.

##### Result

Json with the following:

1.  organizations(object[]) – array of objects containing organizations with specified Organisation Role.
	1. name (character varying) - name of organization.
	2. activity\_ct (integer) - number of activities organization is participating in from provided list of activity ids.

##### Example(s)
- Number of activities each Implmenting (classification\_id: 497) organization is participating in.

```SELECT * FROM pmt_activity_count_by_participants(497, '1767,3188'); ```

```
{
	"organizations":[
		{
			"name":"Local Government",
			"activity_ct":1
		},
		{
			"name":"Ministry of Agriculture Food Security and Cooperatives (MAFC)",
			"activity_ct":1
		},
		{
			"name":"Private Sector Players",
			"activity_ct":1
		}
	]
}
```

[&larr;  Back to Function List](#function-listing)


## pmt\_activity\_count\_by\_taxonomy

##### Description

Returns count of activities within a list of activity ids for a specified taxonomy.

##### Parameter(s)

1. tax\_id (integer) - **Required** taxonomy id for count of activities that have a classification assignment.
2. activity\_ids (character varying) - **Required** comma seperated list of activity id(s) to be counted for association to specified taxonomy.

##### Result

Json with the following:

1. taxonomy (character varying) – the name of the requested taxonomy.
2. classification (character varying) – the name of the classification within the requested taxonomy.
2. activity\_ct (integer) - the number of activities that have the classification assignment within the provided list of activities.

##### Example(s)
- Number of activities in list that are assigned to the Initiative taxonomy (taxonomy\_id: 23).

```SELECT * FROM pmt_activity_count_by_taxonomy(23, '19030,14893,14895,24268');```

```
{
	"taxonomy":"Initiative",
	"classification":"Research & Development",
	"activity_ct":2
}
```

[&larr;  Back to Function List](#function-listing)


## pmt\_activity\_detail


##### Description

All information for a single activity, tailored specifically for an editing UI. THIS DOCUMENTATION IS OUT OF DATE,
CURRENTLY UNDER DEVELOPMENT.

##### Parameter(s)

1. activity_id (integer) - **Required.** Activity id.

##### Result

Json with the following:

1.  id (integer) – activity id.
2.  data\_group\_id (integer) – the data group id.
3.  parent\_id (integer) – the activity's parent id (if null the activity is a parent).
4.  \_title (character varying) – title of activity.
5.  \_label (character varying) – short title for activity.
6.  \_description (character varying) – description of activity.
7.  \_objective (character varying) – the objective for activity.
8.  \_content (character varying) – various content for activity.
9.  \_url (character varying) – url for activity.
10.  \_start\_date (date) – start date of activity.
11.  \_planned\_start\_date (date) – planned start date of activity.
12.  \_planned\_end\_date (date) – end date of activity.
13.  \_end\_date (date) – planned end date of activity.
14.  \_tags (character varying) – tags or keywords of activity.
15.  \_iati\_identifier (integer) – iati identifier or primary key of activity.
16.  \_iati\_import\_id (integer) – iati import id for the corresponding import record (if null the data was manually loaded).
17.  \_created\_by (character varying(50)) - user who created activity information.
18.  \_created\_date (timestamp) -  date and time activity information was created.
17.  \_updated\_by (character varying(50)) -  last user to update activity information.
18.  \_updated\_date (timestamp) -  last date and time activity information was updated.
19.  custom\_fields (various) - any custom fields in the activity table that are not in the Core PMT will be returned as well.
20.   data\_group (character varying) – the data group name.
21.   parent\_title (character varying) – the activity's parent activity title.
22.  ct (integer) - number of locations for activity.
23.  taxonomy(object) - An object containing all associated taxonomy for the activity
	1. taxonomy\_id (integer) - taxonomy id.
	2. taxonomy (character varying) - taxonomy name.
	3. classification\_id (integer) - classification id.
	4. classification (character varying) - classification name.
	5. code (character varying) - classification code.
24.  organizations(object) - An object containing all organizations participating in the activity
	1. p\_id (integer) - participation record id
	2. id (integer) - organization id	
	3. \_name (character varying) - organization name
	4. classification\_id (integer) - classification id of the Organization Role.
	5. classification (character varying) - classification name of the Organization Role.
25.  contacts (object) - An object containing all activity contacts.
	1. id (integer) - the contact id.
	2. \_first\_name (character varying) - contact's first name.
	3. \_last\_name (character varying) - contact's last name.
	4. \_title (character varying) - contact's title.
	5. \_email (character varying) - contact's email address.
	6. organization\_id (integer) - organization id.
	7. organization\_name (character varying) - organization name the contact is associated with.
	8. activities (integer[]) - list of activity ids the contact is related to.
27.  financials (object) - An object containing all activity financial data.
	1. id (integer) - financial id.
	2. \_amount (numeric (100,2)) - financial amount.	
	3. \_start\_date (date) – start date for financial amount.
	4. \_end\_date (date) – end date for financial amount.
	5. provider\_id (integer) - the id of the organization providing the financial amount.
	5. provider (character varying) - the name of the organization providing the financial amount.
	6. recipient\_id (integer) - the id of the organization receiving the financial amount.
	6. recipient (character varying) - the name of the organization receiving the financial amount.
	7. taxonomy(object) - An object containing all associated taxonomy for the financial record
		1. taxonomy\_id (integer) - taxonomy id.
		2. taxonomy (character varying) - taxonomy name.
		3. classification\_id (integer) - classification id.
		4. classification (character varying) - classification name.
		5. code (character varying) - classification code.
29.  locations (object) - An object containing all activity location data.
	1. id (integer) - location id.
	2. \_admin1 (character varying) - the name of the administrative level 1 boundray for the location.	
	3. \_admin2 (character varying) - the name of the administrative level 2 boundray for the location.
	4. \_admin3 (character varying) - the name of the administrative level 3 boundray for the location.
	5. \_admin_level (integer) - the administrative boundary level in which the location is mapped to.
	6. boundary\_id (integer) - boundary id.
	7. feature\_id (integer) - feature id of boundary.
30.  children (object) - An object containing all activity's children activities.
	1. id (integer) - child activity id.
	2. \_title (character varying) - child activity title.

##### Example(s)

```select * from pmt_activity_detail(3);```

```
{
	"activity_id":3
	,"title":"UN collaborative Program for Reducing Emissions from Deforestation and forest Degradation in developing 
			countries, Tanzania (UN-REDD)"
	,"label":null
	,"description":"The project aims at strengthening Tanzanias readiness for Reducing Emissions from Deforestation and 
			forest Degradation (REDD) as a component of the Governments evolving REDD Strategy, and integrate it 
			with other REDD activities in the country"
	,"content":null
	,"start_date":"2009-10-01"
	,"end_date":"2013-12-31"
	,"tags":null	
	,"updated_by":"IATI XML Import"
	,"updated_date":"2014-01-16 00:00:00"
	,"iati_identifier":null
	,"location_ct":1
	,"admin_bnds":"United Republic of Tanzania,Singida,Manyoni"
	,"taxonomy":[{
		 "taxonomy_id":5
		,"taxonomy":"Country"
		,"classification_id":244
		,"classification":"TANZANIA, UNITED REPUBLIC OF"
		,"code":"TZ"
		}
		,{
		 "taxonomy_id":14
		,"taxonomy":"Sector Category"
		,"classification_id":552
		,"classification":"Other multisector"
		,"code":"430"
		}
		,{
		 "taxonomy_id":15
		,"taxonomy":"Sector"
		,"classification_id":729
		,"classification":"Multisector aid"
		,"code":"43010"
		}
		,{
		 "taxonomy_id":17
		,"taxonomy":"Category"
		,"classification_id":779
		,"classification":"Training and Capacity Building"
		,"code":null
		}
		,{
		 "taxonomy_id":18
		,"taxonomy":"Sub-Category"
		,"classification_id":792
		,"classification":"Training and Capacity Building"
		,"code":null
		}]
	,"organizations":[{
		 "organization_id":1
		,"_name":"FAO/ UNEP/ UNDP"
		,"url":null
		,"classification_id":496
		,"classification":"Funding"
		}
		,{
		"organization_id":56
		,"name":"Tanzania Forestry Service (TFS)"
		,"url":null
		,"taxonomy":[{
			"taxonomy_id":10
			,"taxonomy":"Organisation Role"
			,"classification_id":497
			,"classification":"Implementing"
			,"code":"Implementing"
			}]
		}
		,{
		"organization_id":2
		,"name":"MNRT, TFS"
		,"taxonomy":[{
			"taxonomy_id":10
			,"taxonomy":"Organisation Role"
			,"classification_id":497
			,"classification":"Implementing"
			,"_code":"Implementing"
			}]
		}]
	,"contacts":[{
		"contact_id":1
		,"_first_name":"Almas"
		,"_last_name":"Kashindye"
		,"_title":"Project Manager"
		,"_email":"Almas.Kashindye@fao.org"
		,"organization_id":1
		,"organization_name":"FAO/ UNEP/ UNDP"
		}]
	,"details": null
	,"financials":[{
		 "financial_id":13
		,"_amount":814972.00
		,"taxonomy":[{
			"taxonomy_id":6
			,"taxonomy":"Currency"
			,"classification_id":422
			,"classification":"US Dollar"
			,"_code":"USD"
			}]
		}]
	,"locations":[{3}]
}
```

[&larr;  Back to Function List](#function-listing)


## pmt\_activity\_family\_titles

##### Description

Provides a listing of family structured activity titles (parent -> child). Filterable by data group.

##### Parameter(s)

1.  data\_group\_ids (character varying) – Optional. Comma seperated listing of data group ids to filter results to.
2.  classification\_ids (character varying) – Optional. Comma seperated listing of classification ids to return associations to. Returns all classification ids in provided list where each activity is associated.

##### Result

Json with the following:

1.  id (integer) – parent activity id.
2.  \_title (character varying) – title of parent activity.
3.  c (integer[]) - list of classification ids associated to from provided list.
4.  children (json[]) - array of child activity objects
	1.  id (integer) – child activity id.
	2.  \_title (character varying) – title of child activity.
	3.  c (integer[]) - list of classification ids associated to from provided list.

##### Example(s)

-   Family activity titles for the RED&FS data group (2237):

```SELECT * FROM pmt_activity_family_titles('2237',null);```

```
{
	"id":26269,
	"_title":"ATVET Project",
	"children":null,
	"c": null
},
...
{
	"id":29572,
	"_title":"Pastoralist Areas Resilience Improvement and Market Expansion (PRIME)",
	"c": null,
	"children":[
		{
			"id":29714,
			"_title":"Afar Region",
			"c": null
		},{
			"id":29713,
			"_title":"Oromia Region",
			"c": null
		},{
			"id":29712,
			"_title":"Amhara Region",
			"c": null
		},{
			"id":29711,
			"_title":"Somali Region",
			"c": null
		}
	[
},
{
	"id":29575,
	"_title":"Drought Resilience and Sustainable Livelihoods Programme (DRSLP)",
	"children":null,
	"c": null
}
...
```

-   Family activity titles for the RED&FS data group (2237) and return assoications to Maize (2268) :

```SELECT * FROM pmt_activity_family_titles('2237','2268');```

```
{
	"id":26269,
	"_title":"ATVET Project",
	"children":null,
	"c": null
},
...
{
	"id":29600,
	"_title":"Advanced Maize Seed Adoption Program (AMSAP)",
	"c": null,
	"children":[
		{
			"id":29740,
			"_title":"Oromia Region",
			"c":[2268]
		},{
			"id":29741,
			"_title":"Amhara Region",
			"c":[2268]
		},{
			"id":29739,
			"_title":"Tigray Region",
			"c":[2268]
		}
	]
},
{
	"id":29602,
	"_title":"SDR_IFTAR - Strengthening Drought Resilience: Transitional aid measure: Improving food security and disaster risk management to enhance resilience of livestock dependent pastoralists in Afar, Ethiopia",
	"children":null,
	"c": [2268]
}
...
```

[&larr;  Back to Function List](#function-listing)

## pmt\_activity\_ids\_by\_boundary

##### Description

Returns parent activity ids and titles for a given feature and boundary.

##### Parameter(s)

1. boundary\_id (integer) - **Required**. boundary id of the boundary layer that the feature belongs to.
2. feature\_id (integer) - **Required**. feature id of the feature in which to query activities for.
3. data\_group\_ids (character varying) - comma seperated list of classification\_id(s) from the Data Group taxonomy
to restrict data aggregation to. If no data group id is provided, all data groups are included.
4. classification\_ids (character varying) - comma seperated list of classification\_id(s) for any taxonomy (filter).
5. org\_ids (character varying) - comma seperated list of organization\_id(s) for any organization regardless of role (filter).
6. imp\_org\_ids (character varying) - comma seperated list of organization\_id(s) for implementing organizations (filter).
7. fund\_org\_ids (character varying) - comma seperated list of organization\_id(s) for funding organizations (filter).
8. start\_date (date) - start date for activities (filter).
9. end\_date (date) - end date for activities (filter).
10. unassigned\_taxonomy\_ids (character varying) - comma seperated list of taxonomy id(s) for any taxonomy, will return activities that _DO NOT_ have that taxonomy assigned (filter).
11. activity\_ids (character varying) - comma seperated list of activity id(s) to restrict data aggregation to.
12. boundary\_filter (json) - a json array of objects. Each object must contain "b" with a boundary id and "ids" with an array of feature ids (i.e. ```[{"b":12,"ids":[2,3]},{"b":13,"ids":[73,85]}]```)

##### Result

Json array with the following:

1. id (integer) – id of activity
2. \_title (character varying) - the activity title

##### Example(s)

-   Activity information for Africa (feature id: 4) in the continent boundary (boundary id: 8) for BMGF data (data\_group\_id: 768)
where Focus Crop is Maize or Cassava (classification ids: 816,819) OR the activity has **NO** Focus Crops (taxonomy id: 22)
and activities occur between 1/1/2012 and 12/31/2018:

```SELECT * FROM pmt_activity_ids_by_boundary(8, 4,'768','816,819','','','1/1/2012','12/31/2018','22',null); ```

```
...
{
	"id":15795,
	"_title":"OLAM"
},
{
	"id":15796,
	"_title":"Cocoa Research Institute of Ghana"
},
{	"id":15797,
	"_title":"Ministry of Food & AGRIC, Ghana"
}
...
```

-   Activity information for Gambela (feature\_id: 6) in the  to the UNOCHA administrative level 1 boundary (boundary\_id: 12) for RED&FS data (data\_group\_id: 2237)
where Program is "Stand Alone Project" (classification\_id: 2239) and activities occur between 1/1/2002 and 12/31/2020 within the Oromia region 
(boundary\_id: 12 feature\_id: 8) or in the Majang zone (boundary\_id: 13 feature\_id: 38) within the Gambela region :

```SELECT * FROM pmt_activity_ids_by_boundary(12, 6,'2237','2239',null,null,'1/1/2002','12/31/2020',null,'[{"b":12,"ids":[8]},{"b":13,"ids":[38]}]');```

```
{
	"id":26234,
	"_title":"UNICEF-Accelarating Progress MDGS on W&S Ethiopia"
},
{
	"id":26283,
	"_title":"Rural Capacity Building Project (RCBP)"
},
{
	"id":26301,
	"_title":"Disaster Risk Reduction and Early Recovery Project"
}
```

[&larr;  Back to Function List](#function-listing)


## pmt\_activity\_titles


##### Description

Provides a listing of activity titles for a given set of activity ids.

##### Parameter(s)

1.  activity\_ids (integer[]) – **Required**. Array of activity ids.

##### Result

Json with the following:

1.  id (integer) – activity id.
2.  \_title (character varying) – title of activity.

##### Example(s)

-   Activity titles for the following activity ids (26271,26283,26284,26286,26287):

```SELECT * FROM pmt_activity_titles(ARRAY[26271,26283,26284,26286,26287]);```

```
{
	"id":26325,
	"_title":"East Africa Agriculture Productivity Project"
},
{
	"id":26284,
	"_title":"Ethiopia Productive Safety Net APL III Project (P113220)"
},
{
	"id":26271,"_title":"African Stockpiles Project"
},
{
	"id":26283,
	"_title":"Rural Capacity Building Project (RCBP)"
},
{
	"id":26286,
	"_title":"Tana Beles Integrated Water Resources Development Project (TBIWRDP)"
},
{
	"id":26287,
	"_title":"Agricultural Growth"
}

```

[&larr;  Back to Function List](#function-listing)


## pmt\_are\_data\_group

##### Description

Validates an array of data group classification\_ids. Data group is a taxonomy that
is used to determine data source and provide user authentication.

##### Parameter(s)

1. ids (character varying) – comma seperated list of classification\_ids within the Data Group taxonomy.

##### Result

True or false.

##### Example(s)

```pmt_are_data_group(ARRAY[1068,999999]);```

FALSE

```SELECT SELECT * FROM pmt_are_data_group(ARRAY[1068,1069,2266,2267,768,769]);```

TRUE

[&larr;  Back to Function List](#function-listing)


## pmt\_auto\_complete


##### Description

Function accepting columns, of data type text or character varying, for the 
[activity table](DataDictionary.md#activity) and compiles a list of unique data from those 
fields for use in an autocomplete or type ahead function.

##### Parameter(s)

1.  filter\_fields (character varying) – **Required**. Comma separated string of activity table column names.

##### Result

A text array of distinct values from all provided columns. Each text element returned is restricted to 100 characters.

##### Example(s)

-   Tags and opportunity\_id (custom instance field) from the activity table:

```SELECT * FROM pmt_auto_complete('_tags,opportunity_id');```

```
{
  "autocomplete":
  [
	"4h",
	"accelerate country action",
	"access",
	"accountability",
	"adopt",
	"adoption",
	"advocacy",
	"advocacy and campaigns",
	"advocate for fctc measures",
	...
  ]
}
```

[&larr;  Back to Function List](#function-listing)


## pmt\_boundaries\_by\_point


##### Description

Accepts a well-known text point and returns all intersected boundary features.

##### Parameter(s)

1.  wktpoint (character varying) – **Required**. Well-known text representation of a point feature.

##### Result

An array of json objects containing all intersected boundary features:

1.  boundary\_id (integer) – id of the boundary intersected.
2.  boundary\_name (character varying) – the name of the boundary intersected.
1.  feature\_id (integer) – id of the feature of the boundary intersected.
2.  feature\_name (character varying) – the name of the feature of the boundary intersected.


##### Example(s)

-   Determine what boundries are under the point 'POINT(38.758578 8.942346)':

```SELECT * FROM pmt_boundaries_by_point('POINT(38.758578 8.942346)'); ```

```
[
	{
		"boundary_id":1,
		"boundary_name":"gaul0",
		"feature_id":86,
		"feature_name":"Ethiopia"
	},
	{
		"boundary_id":2,
		"boundary_name":"gaul1",
		"feature_id":951,
		"feature_name":"Addis Ababa"
	},
	{
		"boundary_id":3,
		"boundary_name":"gaul2",
		"feature_id":15117,
		"feature_name":"Addis Ababa Zone3"
	},
	...
	{
		"boundary_id":18,
		"boundary_name":"gadm3",
		"feature_id":33778,
		"feature_name":"Akaki - Kalit"
	}

```

[&larr;  Back to Function List](#function-listing)


## pmt\_boundary\_extents

##### Description

Get boundary extent of a boundary feature(s).

##### Parameter(s)

1. boundary\_table (character varying) - **Required** the name of the boundary table.
2. feature\_names (character varying) - **Required** comma delimited list of features to include in extent.

##### Result

Json with the following:

1.  extent (wkt polygon) – well-known text representation of a polygon as the extent of the requested features

##### Example(s)

-   Get extent of Ethiopia and Mali from the gamd0 (spatial table: gadm0) boundary:

```
SELECT * FROM pmt_boundary_extents('gadm0','Ethiopia,Mali'); ; 
```

```
{
	"extent":"POLYGON(
		(-12.2389116287231 3.39882302284263,
		-12.2389116287231 25.0000000000001,
		47.9582290649417 25.0000000000001,
		47.9582290649417 3.39882302284263,
		-12.2389116287231 3.39882302284263))"
}

```

[&larr;  Back to Function List](#function-listing)


## pmt\_boundary\_feature

##### Description

Returns all administrative level names for a give boundary feature.

##### Parameter(s)

1. boundary_id (integer) - **Required** the boundary id for the feature.
2. feature_id (integer) - **Required** the feature id for the feature to query.

##### Result

Json with the following:

1.  0_name (character varying) – the country level name (if exists)
2.  1_name (character varying) – the admin 1 level name (if exists)
3.  2_name (character varying) – the admin 2 level name (if exists)
4.  3_name (character varying) – the admin 3 level name (if exists)
5.  admin_level (character varying) – the number for the administrative level: 0 (country), 1 (admin 1), 2 (admin 2) or 3 (admin 3)

##### Example(s)

-   Get all administrative level names for Ethiopia (feature\_id: 74) in GADM 0 (boundary\_id: 15):

```
SELECT * FROM  pmt_boundary_feature(15, 74); 
```

```
{
	"0_name":"Ethiopia",
	"admin_level":"0"
}

```

-   Get all administrative level names for Addis Abeba(feature\_id: 15174) in GADM 2 (boundary\_id: 17):

```
SELECT * FROM  pmt_boundary_feature(17, 15174); 
```

```
{
	"0_name":"Ethiopia",
	"1_name":"Addis Abeba",
	"2_name":"Addis Abeba",
	"admin_level":"2"
}

```


[&larr;  Back to Function List](#function-listing)


## pmt\_boundary\_hierarchy

##### Description

Creates a nested boundary hierarchy (tree view structure) of boundary feature ids and names.

##### Parameter(s)

1. boundary\_type (character varying) - **Required** The boundary type for the created hierarchy. Options: gaul, gadm, unocha, nbs.
2. admin\_levels (character varying) - a comma delimited list of admin levels to include. Options: 0,1,2,3 
3. filter\_features (character varying) - a comma delimited list of names of features in the highest admin level to restrict data to.
4. data\_group\_ids (character varying) - a comma delimited list of data group ids to filter returned boundaries to. Only boundary features where data group(s) have location information will be returned.

##### Result

Json with the following:

1.  b0-b3 (integer) - the boundary id of each level of the hierarchy (number does not correlate to admin level).
2.  boundaries (object[]) - array of objects containing the boundary hierarchy
	1. id (integer) - the feature id (first boundary level of hierarchy)
	2. n (character varying) - the feature name  (first boundary level of hierarchy)
	3. b (object[]) - array of objects containing the next boundary level
		1. id (integer) - the feature id (second boundary level of hierarchy)
		2. n (character varying) - the feature name  (second boundary level of hierarchy)
		3. b (object[]) - array of objects containing the next boundary level
			1. pattern continued for each level of boundary hierarchy (based on requested number of admin levels)
		

##### Example(s)

-   Create a boundary hierarchy using GADM for admin levels 0-2 for Ethiopia:

```
SELECT * FROM pmt_boundary_hierarchy('gadm','0,1,2','Ethiopia'); 
```

```
{
	"b0":15,
	"b1":16,
	"b2":17,
	"boundaries":[
	{
		"id":74,
		"n":"Ethiopia",
		"b1":[
		{
			"id":896,
			"n":"Oromia",
			"b2":[
			{
				"id":15203,
				"n":"Debub Mirab Shewa"
			},
			{
				"id":15200,
				"n":"Arsi"
			},
			{
				"id":15204,
				"n":"Guji"
			},
			...
			{
				"id":15216,
				"n":"North Shewa"
			}]
		},
		...
		{
			"id":890,
			"n":"Afar",
			"b2":[
			{
				"id":15178,
				"n":"Afar Zone 4"
			},
			{
				"id":15179,
				"n":"Afar Zone 5"
			},
			...
			{
				"id":15177,
				"n":"Afar Zone 3"
			}]
		}]
	}]
}
		
```

[&larr;  Back to Function List](#function-listing)


## pmt\_boundary\_filter

##### Description

Filters boundary features.

##### Parameter(s)

1. boundary\_table (character varying) - **Required** the name of the boundary table to filter.
2. query\_field (character varying) - **Required** the name of the field in the boundary table to apply query to.
3. query (character varying) - **Required** comma delimited list of values in the query field to restrict features to.

##### Result

Json with the following:

1.  id (integer) – the feature id.
2.  _name (character varying) - the name of the feature

##### Example(s)

-   Get all gadm regions (spatial table: gadm1) in Ethiopia and Mali:

```
SELECT * FROM pmt_boundary_filter('gadm1','_gadm0_name','Ethiopia,Mali'); ; 
```

```
{
	"id":1768,
	"_name":"Gao"
},
{	
	"id":896,
	"_name":"Oromia"
},
{
	"id":891,
	"_name":"Amhara"
}
...
{
	"id":1773,
	"_name":"Ségou"
},
{
	"id":1774,
	"_name":"Sikasso"
}

```

[&larr;  Back to Function List](#function-listing)


## pmt\_boundary\_pivot

##### Description

Function to create a filterable pivot table showing organization represation within a single taxonomy and boundary (row and column) based on a single 
organization role.

##### Parameter(s)

1. pivot\_boundary\_id (integer) - **Required** boundary id for the boundary that will represent either rows  (y axis of pivot) or columns (x axis of pivot). The
boundary used to pivot **must** be of the same type as the boundary to filter (i.e both must be gadm). The pivot boundary cannot be the same level as the filter. For
example, if the filter is admin level 0 then the pivot must an admin level higher (1, 2, ect). 
2. pivot\_taxonomy\_id (integer) - **Required** taxonomy id for taxonomy that will represent either rows  (y axis of pivot) or columns (x axis of pivot).
3. boundary_as_row (boolean) - T/F will the boundary be represented as rows. Default is false, meaning the boundary is represented as a column and the taxonomy is the row.
4. org\_role\_id (integer) - **Required** classification id for the Organisation Role to be used to select participating organizations (table data).
5. data\_group\_ids (character varying) - comma seperated list of classification\_id(s) from the Data Group taxonomy
to restrict data. If no data group id is provided, all data groups are included (filter).
6. classification\_ids (character varying) - comma seperated list of classification\_id(s) for any taxonomy (filter).
7. start\_date (date) - start date for activities (filter).
8. end\_date (date) - end date for activities (filter).
9. boundary\_id (integer) - **Required** the boundary id referenced by the feature\_id (filter).
10. feature\_id (integer) - **Required** the featuer id to restrict activities to (filter).

##### Result

Json with the following:

1.  c# (character varying) - each object will contain a value for each column in a row numbered 1 - x
	1.  f1 (character varying) - organization label
	2.  f2 (integer) - organization id
	3.  f3 (character varying) organization name

##### Example(s)

-   Partner pivot table data to include only EthATA data (data\_group\_id: 2237) where Program is the row/y-axis (pivot\_taxonomy\_id: 68) and 
GADM Level 1 is the column/x-axis  (pivot\_boundary\_id: 16 & boundary\_as\_row: false) and the organizations represented are Funding (org\_role\_id: 496) for
all activities in Ethiopia (feature\_id: 74) using GADM Level 0 (boundary\_id: 15):

```SELECT * FROM pmt_boundary_pivot(16,68,false,496,'2237',null,null,null,15,74);```
```
{
	"c1":"",
	"c2":"Oromia",
	"c3":"Amhara",
	"c4":"Benshangul-Gumaz",
	"c5":"Dire Dawa",
	"c6":"Addis Abeba",
	"c7":"Gambela Peoples",
	"c8":"Harari People",
	"c9":"Somali",
	"c10":"Southern Nations, Nationalities and Peoples",
	"c11":"Tigray",
	"c12":"Afar"
}
{
	"c1":"Agricultural Growth Program",
	"c2":[
		{
			"f1":"CIDA",
			"f2":3135,
			"f3":"Canadian International Development Agency (CIDA)"
		}, 
 
		{
			"f1":"Global Agriculture and Food Security Program",
			"f2":2588,
			"f3":"Global Agriculture and Food Security Program"
		},
		... 
 
		{
			"f1":"GoE",
			"f2":3148,
			"f3":"Government of Ethiopia (GoE)"
		}
	],
	"c3":[
		{
			"f1":"CIDA",
			"f2":3135,
			"f3":"Canadian International Development Agency (CIDA)"
		}, 
 
		{
			"f1":"Global Agriculture and Food Security Program",
			"f2":2588,
			"f3":"Global Agriculture and Food Security Program"
		},
		... 
 
		{
			"f1":"GoE",
			"f2":3148,
			"f3":"Government of Ethiopia (GoE)"
		}
	],
	"c4":[null],
	"c5":[null],
	"c6":[null],
	"c7":[null],
	"c8":[null],
	"c9":[null],
	"c10":[
		{
			"f1":"CIDA",
			"f2":3135,
			"f3":"Canadian International Development Agency (CIDA)"
		}, 
 
		{
			"f1":"Global Agriculture and Food Security Program",
			"f2":2588,
			"f3":"Global Agriculture and Food Security Program"
		},
		... 
 
		{
			"f1":"GoE",
			"f2":3148,
			"f3":"Government of Ethiopia (GoE)"
		}
	],
	"c11":[
		{
			"f1":"CIDA",
			"f2":3135,
			"f3":"Canadian International Development Agency (CIDA)"
		}, 
 
		{
			"f1":"Global Agriculture and Food Security Program",
			"f2":2588,
			"f3":"Global Agriculture and Food Security Program"
		},
		... 
 
		{
			"f1":"GoE",
			"f2":3148,
			"f3":"Government of Ethiopia (GoE)"
		}
	],
	"c12":[null]
},
{
	"c1":"Concern Livlihoods Program",
	"c2":[null],
	"c3":[null],
	"c4":[null],
	"c5":[null],
	"c6":[null],
	"c7":[null],
	"c8":[null],
	"c9":[null],
	"c10":[null],
	"c11":[null],
	"c12":[
		{
			"f1":"Concern Ethiopia",
			"f2":3166,
			"f3":"Concern Ethiopia"
		}, 

		{
			"f1":"EU",
			"f2":1027,
			"f3":"European Union (EU)"
		}, 
 
		{
			"f1":"WRDA",
			"f2":3222,
			"f3":"Wonnta Rural Development Association (WRDA)"
		}
	]
},
{
	"c1":"Food Security Program",
	"c2":[null],
	"c3":[null],
	"c4":[null],
	"c5":[null],
	"c6":[null],
	"c7":[null],
	"c8":[null],
	"c9":[null],
	"c10":[null],
	"c11":[null],
	"c12":[
		{
			"f1":"CIDA",
			"f2":3135,
			"f3":"Canadian International Development Agency (CIDA)"
		}, 
 
		{
			"f1":"DEFID",
			"f2":3170,
			"f3":"DEFID"
		}, 
 
		{
			"f1":"Department of Foreign and International Affairs",
			"f2":3171,
			"f3":"Department of Foreign and International Affairs"
		}
	]
},
{
	"c1":"Stand Alone Project",
	"c2":[
		{
			"f1":"GDC",
			"f2":3149,
			"f3":"German Development Cooperation (GDC)"
		}
	],
	"c3":[
		{
			"f1":"ITAL",
			"f2":3100,
			"f3":"Italian Development Cooperation (ITAL)"
		}
	],
	"c4":[
		{
			"f1":"EU",
			"f2":1027,
			"f3":"European Union (EU)"
		},
		{
			"f1":"ITAL",
			"f2":3100,
			"f3":"Italian Development Cooperation (ITAL)"
		}, 
 
		{
			"f1":"UNDP",
			"f2":3093,
			"f3":"United Nations Development Program (UNDP)"
		}
	],
	"c5":[null],
	"c6":[null],
	"c7":[null],
	"c8":[null],
	"c9":[null],
	"c10":[null],
	"c11":[null],
	"c12":[
		{
			"f1":"ADA",
			"f2":3163,
			"f3":"Austrian Development Agency (ADA)"
		}
	]
```
Results can then be rendered as a table:

||Oromia|Amhara|Benshangul-Gumaz|Dire Dawa|Addis Abeba|Gambela Peoples|Harari People|Somali|Southern Nations, Nationalities and Peoples|Tigray|Afar|
|:----------|:----------|:----------|:----------|:----------|:----------|:----------|:----------|:----------|:----------|:----------|:----------|
|Agricultural Growth Program|CIDA,Global Agriculture and Food Security Program,GoE,Local,NETH,SPAN,USAID,WB,|CIDA,Global Agriculture and Food Security Program,GoE,Local,NETH,SPAN,USAID,WB,|||||||CIDA,Global Agriculture and Food Security Program,GoE,Local,NETH,SPAN,USAID,WB,|CIDA,Global Agriculture and Food Security Program,GoE,Local,NETH,SPAN,USAID,WB,||
|Concern Livlihoods Program||Concern Ethiopia,|||||||Concern Ethiopia,EU,WRDA,|||
|Food Security Program|CIDA,DEFID,Department of Foreign and International Affairs,EC,GoE,IREAID,NETH,SWED,USAID,WB,WFP,|CIDA,DEFID,Department of Foreign and International Affairs,EC,GoE,IREAID,NETH,SWED,USAID,WB,WFP,||Department of Foreign and International Affairs,GoE,IREAID,WB,|||Department of Foreign and International Affairs,GoE,IREAID,WB,|CIDA,DEFID,EC,IREAID,NETH,SWED,USAID,WB,WFP,|CIDA,DEFID,Department of Foreign and International Affairs,EC,GoE,IREAID,NETH,SWED,USAID,WB,WFP,|CIDA,DEFID,Department of Foreign and International Affairs,EC,GoE,IREAID,NETH,SWED,USAID,WB,WFP,||
|Stand Alone Project|African Development Bank,Belgium Cooperation,CIDA,Department of Foreign and International Affairs,EU,FIN,GDC,GIZ,GoE,IFAD,IREAID,ITAL,JICA,Korea,Local,NETH,Regional Government,Royal Norwegian Embassy,Russia,SPAN,UNDP,UNICEF,USAID,WB,WFP,|ADA,African Development Bank,CIDA,DANIDA,Department of Foreign and International Affairs,EU,FIN,GoE,IFAD,IREAID,ITAL,JICA,Korea,Local,MEDA,Regional Government,Russia,SIDA,SPAN,UNDP,UNICEF,USAID,WB,WFP,|CIDA,Department of Foreign and International Affairs,EU,FIN,GoE,WB,|EU,|CIDA,GoE,Local,MEDA,UNDP,USAID,|CIDA,EU,UNDP,WB,||CIDA,EU,GoE,IFAD,International Rescue Committee,IREAID,JICA,Korea,Local,Russia,SPAN,UNDP,USAID,WB,WFP,|African Development Bank,Christian Aid,CIDA,Department of Foreign and International Affairs,EU,GoE,IFAD,IREAID,JICA,Korea,Local,MEDA,Regional Government,Royal Norwegian Embassy,Russia,SPAN,UNDP,UNICEF,USAID,WB,WFP,|African Development Bank,CIDA,Department of Foreign and International Affairs,EU,GoE,IFAD,IREAID,ITAL,JICA,Korea,Regional Government,Royal Norwegian Embassy,Russia,SPAN,UNDP,UNICEF,USAID,WB,WFP,|CIDA,Department of Foreign and International Affairs,EU,GoE,IFAD,IIRR,Local,Norway Development Fund,OCHA,SPAN,UNDP,USAID,WB|
|Sustainable Land Management Program|CIDA,DED,EU,GIZ,IFAD,KFW,MASHAV,WB,|CIDA,DED,EU,FIN,GIZ,IFAD,KFW,MASHAV,WB,|CIDA,DED,EU,FIN,GIZ,IFAD,KFW,WB,||||||CIDA,DED,EU,GIZ,IFAD,KFW,MASHAV,WB,|CIDA,DED,EU,GIZ,IFAD,KFW,MASHAV,WB,||


[&larr;  Back to Function List](#function-listing)

## pmt\_boundary\_search
Searches all pmt boundary table feature names, within an given boundary type and returns matching features.

##### Parameter(s)
1.  boundary\_type (character varying) – admin boundry type. ['gadm','gaul','unocha','acc','nbs', ect]
2.  search\_string (character varying) - string to search for, not case sensative. Will match if search string is contained in any part of the feature name.

##### Result

Array of json objects with the following:
1. b0 (character varying) - the boundary level 0 name for feature matched.
2. b1 (character varying) - the boundary level 1 name for feature matched.
3. b2 (character varying) - the boundary level 2 name for feature matched.
4. b3 (character varying) - the boundary level 3 name for feature matched.


##### Example(s)

-   Search for "libolo" in GADM boundaries:

```select * from pmt_boundary_search( 'gadm','libolo' );```

```
{
	"b0":"Angola",
	"b1":"Cuanza Sul",
	"b2":"Libolo",
	"b3":""
},	
{
	"b0":"Angola",
	"b1":"Cuanza Sul",
	"b2":"Libolo",
	"b3":"Kabuta"
},
...
{
	"b0":"Angola",
	"b1":"Cuanza Sul",
	"b2":"Libolo",
	"b3":"Munenga"
}
```

[&larr;  Back to Function List](#function-listing)

## pmt\_bytea\_import

##### Description

Converts text into bytea. Used in combination with PostgreSQL
convert\_from() to import xml documents as an xml data type. (Jack
Douglas)[[1]](#bytea_ref)

##### Parameter(s)

1.  (text) – any text, or document.

##### Result

Text as bytea.

##### Example(s)

-   Convert utf-8 formatted xml file in the temp directory called
    file.xml into the xml data type:

```convert_from(pmt_bytea_import('/temp/file.xml'), 'utf-8')::xml```

[&larr;  Back to Function List](#function-listing)


## pmt\_category\_root

##### Description

A taxonomy can have a taxonomy category and a taxonomy category can have
a taxonomy category. This function returns the base or root taxonomy\_id
of any taxonomy.

##### Parameter(s)

1.  id (integer) – **Required**. The category taxonomy.
2.  data\_group (character varying) – Optional. Comma separated list of data group classification id(s).

##### Result

Integer of root taxonomy\_id.

##### Example(s)

-   Return the root taxonomy for the PMT Sector Category
    (taxonomy\_id:16) taxonomy category:

```SELECT pmt_category_root(16, null);```

15

[&larr;  Back to Function List](#function-listing)


## pmt\_classification\_count

##### Description

Count of classifications, filterable by search text and taxonomy id.

##### Parameter(s)

1.  taxonomy\_id (instance) – **Required**. Taxonomy id for classification listing.
2.  search\_text (text) – Optional. Search text to restrict classification by. Searches classification _name.

##### Result

Json with the following:

1.  count (integer) – number of classifications match criteria.

##### Example(s)

-   Get count of classifications for Fodder Crop Types (taxonomy\_id: 81):

```SELECT * FROM pmt_classification_count(81,null);```

```
{
	"count":20
}
```

[&larr;  Back to Function List](#function-listing)

## pmt\_classification\_search

##### Description

Listing of classifications, filterable by search text and taxonomy id.

##### Parameter(s)

1.  taxonomy\_id (instance) – **Required**. Taxonomy id for classification listing.
2.  search\_text (text) – Optional. Search text to restrict classification by. Searches classification _name (of both parent and child if the requested taxonomy is a category).
3.  offsetter (integer) - Optional. Number of records to offset return by.
4.  limiter (integer) - Optional. Number of records to limit return by.

##### Result

Json with the following:

1.  id (integer) – classification id.
2.  c (character varying(255)) – name of classification.
3. activities (json[]) - json array of activities using classification
	1. id (integer) - the parent activity id for activity using classification
	2. _title (character varying) - parent activity title
4. children (json[]) - object containing child classification records when taxonomy is a category:
	1. id (integer) – classification id.
	2.  c (character varying(255)) – name of classification.
	3. activities (json[]) - json array of activities using classification
		1. id (integer) - the parent activity id for activity using classification
		2. _title (character varying) - parent activity title


##### Example(s)

-   Get list of classifications for GTP2 Strategic Objective (taxonomy\_id: 77) that have "agr" in the classification:

```SELECT * FROM pmt_classification_search(77,'agr',null,null);```

```
{
	"id":2443,
	"c":"SO1: Increased market oriented crop production and improved crop productivity focusing on strategic crops","activities":[
		{
			"id":29659,
			"_title":"Fertilizer Blending Project"
		},{
			"id":29549,
			"_title":"Participatory Small Scale Irrigation Development Programme"
		},
		...
	],
	"children":[
		{
			"id":2447,
			"c":"Agricultural extension",
			"activities":[
				{
					"id":29549,
					"_title":"Participatory Small Scale Irrigation Development Programme"
				},{
					"id":29578,
					"_title":"SDR_TREE Project - Strengthening Drought Resilience: Trilateral Resilience Enhancement in Ethiop (...)"
				},
				...
			]
		},{
			"id":2449,
			"c":"Agricultural mechanization",
			"activities":[
				{
					"id":29856,
					"_title":"Bilateral Ethiopian-Netherlands Effort for Food,Income and Trade Partnership (BENEFIT)"
				},{
					"id":29573,
					"_title":"Agro-Business Induced Growth Porgramme in the Amhara National Regional State Phase Two (AgroBIG II)"},{"id":29597,"_title" (...)"
				},
				...
			]
		},
		...
	]
}
...
```

[&larr;  Back to Function List](#function-listing)

## pmt\_classifications


##### Description

Returns classifications for a single taxonomy with usage counts.

##### Parameter(s)

1. taxonomy\_id (integer) - **Required** taxonomy id for the requested taxonomy classifications. 
2. data\_group\_ids (character varying) - comma seperated list of classification\_id(s) from the Data Group taxonomy
to restrict data (filter). If no data group id is provided, all data groups are included. When data groups are specified
only in-use classifications for that data group are returned.
3. instance\_id (integer) - id of the instance to restrict data to (filter). If no instance id is provided, all data groups 
are included. When an instance is specified only in-use classifications for that instance's data group are returned. The 
instance\_id parameter overrides the data\_group\_ids parameter when both are provided.
4. locations\_only (boolean) - t/f in-use applies only to activities with locations.

##### Result

Json object array with the following:

1.  id (integer) - classification id
2.  c (character varying) - classification name
3.  ct (integer) - number of activities with classification assignment

##### Example(s)

-   Get classifications for the Activity Status taxonomy (taxonomy\_id: 18) that are in use for ASDP data (data\_group\_id: 1068) not restrictive to 
activities with locations:

```SELECT * FROM pmt_classifications(18, '1068', null, false);```
```
{
	"id":794,
	"c":"Active",
	"ct":96
},
{
	"id":797,
	"c":"Completed",
	"ct":15
},
{
	"id":798,
	"c":"Has not started",
	"ct":20
},
{
	"id":1239,
	"c":"Suspended",
	"ct":1
}
```

-   If classifications are from a taxonomy that has child record, those records will be returned as well. Get classifications for the Focus Crop Categories taxonomy (taxonomy\_id: 79) for the RED&FS data group (data\_group\_id: 2237), restricted to locations:

```select * from pmt_classifications(79, '2237', null, true);```

```
...
,{
	"id":2476,
	"c":"Oilseed",
	"ct":5,
	"children":[
		{
			"id":2271,
			"c":"Sesame",
			"ct":4
		},{
			"id":2495,
			"c":"Ground Nut",
			"ct":1
		},{
			"id":2496,
			"c":"Linseed",
			"ct":1}
		,{
			"id":2501,
			"c":"Sunflower",
			"ct":1
		}
	]
},
...
```


[&larr;  Back to Function List](#function-listing)


## pmt\_clone\_activity

##### Description

Clone an existing activity and all it's related records. The clone will replicate the following 
activity records:
	*  contacts
	*  taxonomies
	*  participation records (and associated taxonomies)
	*  financial records (and associated taxonomies)
	*  detail records (and associated taxonomies)
	*  result records (and associated taxonomies)

##### Parameter(s)

1.  user\_id (integer) – **Required**. User\_id of user requesting edits.
2.  activity\_id (integer) – **Required**. Activity\_id of activity to clone.
3.  project\_id (integer) – Optional. Project\_id of newly cloned activity.
4.  json (json) - Optional. Key/value pair as json of field/values to edit. Activity is cloned, then
columns submitted in json are updated. Column names are case sensitive. Enclose all values in 
double quotes, including null. **If your text values include a single quote, use two adjacent 
single quotes, e.g., 'Dianne''s dog'. This is because PostgreSQL uses the single quote to encase 
string constants.** You can include any existing field that exists for activity, even custom fields. 
The following fields cannot be edited evenif included: 
	- activity\_id
	- project_id
	- active
	- retired_by
	- created_by
	- created_date
	- updated_by
	- updated_date

	Json key/value format:
	```
	{"column_name": "value"}
	```

##### Result

Json with the following:

1.  id (integer) – activity\_id of then new activity.
2.  message(character varying) - Message containing either "Success" for a successful transaction 
or containing an error description regarding the unsuccessful transaction. Some possible error messages:
	- user_id and activity_id are required parameters for all operations
	- Invalid user_id
	- Invalid activity_id
	- User does NOT have authority to create new records on this project

##### Example(s)

-   User sparadee (user\_id: 34) to clone activity "Advancing through Sustainable Diets" (activity\_id: 45) 
changing the title and description. (_By not providing the project_id, the new activity will remain on the same project as
the activity it was cloned from_)

```
select * from pmt_clone_activity(34, 45, null,'{"title": "Advancing through Sustainable Diets: Phase II", 
"description":"Phase II of the activity."}');
```

```
{"id":863,"message":"Success"}
```

-  User sparadee (user\_id: 34) to clone activity "Rwanda Super Foods" (activity\_id: 661) for project 
"Improving Rwanda Food Supplies Phase II" (project\_id: 756):

```
select * from pmt_clone_activity(34, 661, 756 ,null);
```

```
{"id":967,"message":"Success"}
```

[&larr;  Back to Function List](#function-listing)

## pmt\_consolidate\_orgs

##### Description

Consolidate Organizations. Takes One organization ID to keep, and an array of organizations to consolidate into the Kept organization.
Tables affected: contact, instance, users, financial, organization, organization_taxonomy, participation, participation_taxonomy

##### Parameter(s)

1.  instance\_id (integer) – **Required**. Instance id of the instance where the request originates.
2.  user\_id (integer) – **Required**. User\_id of user requesting the consolidation.
3.  organization\_to\_keep\_id (integer) – **Required** organization id of organiztion to keep.
4.  organization\_ids\_to\_consolidate (integer[]) - **Required**. array of organization id's to consolidate into organization\_to\_keep\_id

##### Result

Json with the following:

1.  message(character varying) - Message containing either "Success" for a successful transaction 
or containing an error description regarding the unsuccessful transaction. Possible error messages:
	- User\_id is a required parameter for all operations. - Received when required parameter is not provided.
	- Organization_id_to_keep is a required parameter for all operations. - Received when required parameter is not provided.
	- An array of organization_ids is a required parameter for all operations. - Received when required parameter is not provided.
	- At least one Organization to consolidate must be passed to this function. - Received when the array of organizations to consolidate is empty.
	- The organization to keep must not be part of the list or organizations to consolidate. - Received when the organization to keep is included in the organiztions to consolidate array.
	
##### Example(s)

-   User sparadee (user\_id: 34) request to consolidate organizations 221,239,277 into 237 from EthAIM (instance\_id: 1):

```
SELECT * FROM pmt_consolidate_orgs (1, 34, 237, ARRAY[221,239,277]::integer[]);
```

```
{"id": 237, "message":"Success"}
```

[&larr;  Back to Function List](#function-listing)

## pmt\_contacts

##### Description

 Get all contacts.

##### Parameter(s)

No parameters.

##### Result

Ordered by last name then first name. Json with the following:

1.  id (integer) – contact id.
2.  \_first\_name (character varying(64)) – first name of contact.
3.  \_last\_name (character varying(128)) – last name of contact.
4.  \_title (character varying(75)) - title/position of contact.
5.  \_email (character varying(100)) - email of contact.
6.  organization\_id (integer) – organization\_id in which the contact belongs to.
7.  organization\_name (character varying(255)) - organization name of the organization in which the contact belongs to.
8.  activities (integer[]) - array of activity ids that the contact is associated with.

##### Example(s)

```SELECT * FROM pmt_contacts();```

```
...
{	
	"id":1588,
	"_first_name":"Assaye",
	"_last_name":"Legesse",
	"_title":null,
	"_email":"alegesse@worldbank.org",
	"organization_id":2739,
	"organization_name":"The World Bank",
	"activities":[26325]
}
...
```

[&larr;  Back to Function List](#function-listing)

## pmt\_data\_groups

##### Description

Returns all active data groups. Data group is a taxonomy that all data into group by source
or owner. Data group is use to determine user permissions to a record.

##### Parameter(s)

None.

##### Result

1.  c\_id (integer) – Classification\_id of the Data Group classification.
2.  name (character varying) – Name of the Data Group classification.

##### Example(s)

-   Get data groups:

```SELECT * FROM pmt_data_groups();```

| c\_id                                | Name                                 |
|--------------------------------------|--------------------------------------|
| 768                                  | "BMGF"                               |
| 769                                  | "AGRA"			              |
| 1068                                 | "AWG"                                |
| …                                    | …                                    |

[&larr;  Back to Function List](#function-listing)


## pmt\_edit\_activity

##### Description

Edit an activity.

##### Parameter(s)

1.  instance\_id (integer) – **Required**. Instance id of the instance where the edit request originates.
2.  user\_id (integer) – **Required**. User id of user requesting edits.
3.  activity\_id (integer) – **Required for delete and update operations**. Activity id of activity to update or delete.
4.  data\_group\_id (integer) – **Required for create operation**. Classification id of the Data Group taxonomy in which the activity belongs to.
5.  key\_value\_data (json) - **Required for create and update operations**. Key/value pair as json of field/values to edit. Column names are 
case sensitive. Enclose all values in double quotes, including null. **If your text values include
a single quote, use two adjacent single quotes, e.g., 'Dianne''s dog'. This is because PostgreSQL
uses the single quote to encase string constants.** You can include any existing
field that exists for activity, even custom fields. The following fields cannot be edited even
if included: 
	- id
	- _active
	- _retired_by
	- _created_by
	- _created_date
	- _updated_by
	- _updated_date

	Json key/value format:
	```
	{"column_name": "value"}
	```
6. delete\_record (boolean) - Optional, default is false. True to request the record be deleted.

##### Result

Json with the following:

1.  id (integer) – activity\_id of the activity created, updated or deleted.
2.  message(character varying) - Message containing either "Success" for a successful transaction 
or containing an error description regarding the unsuccessful transaction. Some possible error messages:
	- The json parameter is required for a create/update operation
	- activity_id is required for a delete operation - When delete\_record is true, an activity\_id is required.
	- user\_id is a required parameter for all operations
	- User does NOT have authority to create a new activity for project_id
	- User does NOT have authority to delete this activity
	- project_id is not valid - the provide project\_id is either not active or invalid
	- User does NOT have authority to update this activity

##### Example(s)

-   Update the title, description and start_date for activity id 14863 from the BMGF instance (instance\_id: 5) 
and set it's opportunity\_id to null. 

```
select * from pmt_edit_activity(5,34,14863,null,'{"title": "Project Objective 1", 
"description":"Market opportunities, Policies and Partnerships", "start_date":"9-2-2012", 
"opportunity_id": "null"}', false);
```

```
{"id":14863,"message":"Success"}
```

-  Create a new activity for the RED&FS data group (id: 2237) from the EthAIM instance (instance\_id: 1).

```
select * from pmt_edit_activity(1,34,null,2237,'{"title": "A New Activity", 
"description":"Doing some good work in Nepal", "start_date":"6-1-2014", "end_date":"5-31-2016"}', false);
```

```
{"id":15821,"message":"Success"}
```

-  Delete activity\_id 15821 from the TanAIM instance (instance\_id: 2).

```
select * from pmt_edit_activity(2, 34, 15821, null, null, true);
```

```
{"id":15821,"message":"Success"}
```

[&larr;  Back to Function List](#function-listing)


## pmt\_edit\_activity\_contact

##### Description

Edit the relationship between an activity and a contact.

##### Parameter(s)

1.  user\_id (integer) – **Required**. User\_id of user requesting edits.
2.  activity\_id (integer) – **Required**. Activity\_id of activity to edit.
2.  contact\_id (integer) – **Required**.  Contact\_id of contact to associate to activity\_id.
3.  edit\_action (enum) - Optional. 
	Options:
	1. add (default) - will add a relationship between provided activity\_id and contact\_id
	2. delete - will remove the relationship between the provided activity\_id and contact\_id
	3. replace - will replace all existing relationships to the provided activity\_id with any contact, with the contact 
of the provided contact\_id.

##### Result

Boolean. Sucessfull (true) or unsuccessful (false). Unsuccessful is usually due invalid parameters or 
user does not have authorization to edit. Use [pmt\_validate\_user\_authority](#validate_user_authority)
to determine authorization.

##### Example(s)

-   Add Don John (contact\_id:169) as a contact for activity\_id 14863 as user sparadee (user\_id:34):

```select * from pmt_edit_activity_contact(34,14863, 169, 'add');```

	TRUE

-   Replace all contacts with Edward Jones (contact\_id:145) for activity\_id 14863 as user sparadee (user\_id:34):

```select * from pmt_edit_activity_contact(34,14863, 145, 'replace');```

	TRUE

-   Delete Edward Jones (contact\_id:145) as contact for activity\_id 14863 as user sparadee (user\_id:34):

```select * from pmt_edit_activity_contact(34,14863, 145, 'delete');```

	TRUE

[&larr;  Back to Function List](#function-listing)

## pmt\_edit\_activity\_taxonomy

##### Description

Edit the relationship between activity(ies) and a taxonomy classification(s). 

##### Parameter(s)

1.  instance\_id (integer) – **Required**. Instance id of the instance where the edit request originates.
2.  user\_id (integer) – **Required**. User\_id of user requesting edits.
3.  activity\_ids (character varying) – **Required**. Comma separated list of activity_ids to edit.
4.  classification\_ids (character varying) – **Required/Optional**.  Comma separated list of  classification\_ids of taxonomy classifications in relationship to activity\_id(s). Not required if using the "delete" option for the edit\_activity parameter.
4.  taxonomy\_ids (character varying) – **Required/Optional**.  Comma separated list of  taxonomy\_ids to remove from relationships to activity\_id(s). Not required if not using the "delete" option for the edit\_activity parameter..
5.  edit\_activity (enum) - Optional. 
	Options:
	1. add (default) - will add a relationship between provided activity\_id(s) and classification\_id(s)
	2. delete - will remove the relationship between the provided activity\_id(s) and classification_id(s)/taxonomy\_id(s)
	3. replace - will replace all relationships between the provided activity\_ids(s) and taxonomy of the provided classification\_id(s), with
a relationship between the provided activity\_id(s) and classification\_id(s) per taxonomy.

##### Result

Json with the following:

1.  activity\_ids (integer) – activity\_id(s) of the activity updated.
2.  message(character varying) - Message containing either "Success" for a successful transaction 
or containing an error description regarding the unsuccessful transaction. Some possible error messages:
	- Error: instance_id is a required parameter for all operations.
	- Error: classification_ids or taxonomy_ids are a required parameter for delete operations.

##### Example(s)

-   User sparadee (user\Id: 34) to add a relationship to Crops 'Barley' & 'Rice' (classification\_id:2243,2250) and to Thematic Area 'Agricultural Growth (AG)' 
(classification\_id:2416) to activity\_ids 13264,13355,13361 from the EthAIM instance (instance\_id: 1):

```select * from pmt_edit_activity_taxonomy(1,34,'13264,13355,13361','2243,2250,2416', null, 'add');```

```{"activity_ids":"13264,13355,13361","message":"Success"}```

-   User sparadee (user\Id: 34) to replace all relationships to Crops with 'Coffee' (classification\_id:2245) and to Thematic Area with 'Agricultural Growth (AG)' 
(classification\_id:2416) for activity\_id 13264 from the EthAIM instance (instance\_id: 1). This will result in all other reltionships to Crops and Thematic Area
to be removed leaving **ONLY** the above classification assignments:

```select * from pmt_edit_activity_taxonomy(1,34,'13264','2245,2416', null, 'replace');```

```{"activity_ids":"13264,13355,13361","message":"Success"}```


-   User sparadee (user\Id: 34) to remoe all relationships to Crops (taxonomy\_id:69) for activity\_id 13264 from the EthAIM instance (instance\_id: 1). This will result in the activity
having no assignments to Crops:

```select * from pmt_edit_activity_taxonomy(1,34,'13264',null, 69, 'delete');```

```{"activity_ids":"13264,13355,13361","message":"Success"}```


[&larr;  Back to Function List](#function-listing)

## [pmt\_edit\_classification]

##### Description

Edit the classification table. 

##### Parameter(s)

1.  instance\_id (integer) – **Required**. Instance id of the instance where the edit request originates.
2.  user\_id (integer) – **Required**. User\_id of user requesting edits.
3.  classification\_id (integer) – **Required for update and delete operations**. Classification record to update.
4.  taxonomy\_id (integer) – **Required for create operations**. The taxonomy id to create new classification record for.
5.  key\_value\_data (json) - **Required for create and update operations**. Key/value pair as json of field/values to edit. Column names are 
case sensitive. Enclose all values in double quotes, including null. **If your text values include
a single quote, use two adjacent single quotes, e.g., 'Dianne''s dog'. This is because PostgreSQL
uses the single quote to encase string constants.** You can include any existing
field that exists for activity, even custom fields. The following fields cannot be edited even
if included: 
	- id
	- _active
	- _retired_by
	- _created_by
	- _created_date
	- _updated_by
	- _updated_date

	Json key/value format:
	```
	{"column_name": "value"}
	```
6. delete\_record (boolean) - Optional, default is false. True to request the record be deleted.
 
##### Result

Success or Fail message Json message

##### Example(s)

Add a new classification
``` 
select * from pmt_edit_classification(1, 272, '{2237}'::integer[], NULL, '{"_name":"Test Classfication","_description":"Test Classification - tester","taxonomy_id":71,"_code":null,"_iati_codelist":null,"parent_id":null}'::json, false);
```

Update a classification
``` 
select * from pmt_edit_classification(1, 272, '{2237}'::integer[], 2244, '{"_name":"New Name For Classfication","_description":"Test Classification - tester","taxonomy_id":71,"_code":null,"_iati_codelist":null,"parent_id":null}'::json, false);
```

Remove/Deactivate a  classification
``` 
select * from pmt_edit_classification(1, 272, '{2237}'::integer[], 2244, '{"_name":"New Name For Classfication","_description":"Test Classification - tester","taxonomy_id":71,"_code":null,"_iati_codelist":null,"parent_id":null}'::json, false);
```


[&larr;  Back to Function List](#function-listing)

## pmt\_edit\_contact

##### Description

Edit a contact.

##### Parameter(s)

1.  instance\_id (integer) – **Required**. Instance id of the instance where the edit request originates.
2.  user\_id (integer) – **Required**. User id of user requesting edits.
3.  activity\_id (integer) – **Required for delete and update operations**. Activity id of activity to update or delete.
4.  data\_group\_id – **Required for create operation**. Classification id of the Data Group taxonomy in which the activity belongs to.
5.  contact\_id (integer) – **Required for delete and update operations**. Contact id of contact to update or delete.
6.  key\_value\_data (json) - **Required for create and update operations**. Key/value pair as json of field/values to edit. Column names are 
case sensitive. Enclose all values in double quotes, including null. **If your text values include
a single quote, use two adjacent single quotes, e.g., 'Dianne''s dog'. This is because PostgreSQL
uses the single quote to encase string constants.** You can include any existing
field that exists for activity, even custom fields. The following fields cannot be edited even
if included: 
	- id
	- _active
	- _retired_by
	- _created_by
	- _created_date
	- _updated_by
	- _updated_date

	Json key/value format:
	```
	{"column_name": "value"}
	```
7. delete\_record (boolean) - Optional, default is false. True to request the record be deleted.

##### Result

Json with the following:

1.  id (integer) – contact\_id of the contact created or updated.
2.  message(character varying) - Message containing either "Success" for a successful transaction 
or containing an error description regarding the unsuccessful transaction. Possible error messages:
	- Must include user\_id and json data parameters - Received when both required parameters are not provided.
	- User does NOT have authority to create a new contact - Received when the user\_id provided does not have authority to create under current role.
	- User does NOT have authority to update an existing contact - Received when the user\_id provided does not have authority to update under current role.
	- Invalid contact\_id - Received when the contact\_id provided is invalid.

##### Example(s)

-   Update the first name, last name, email and title for John Hancock (contact\_id:148) as user sparadee (user\_id:34)

```
SELECT * FROM pmt_edit_contact(1,34,26225,2237,148,'{"id": 148,"_first_name": "John","_last_name": "Hanhock","_email": "jhanhock@mail.com","_title": "CEO"}', false)
```

```
{"id":148,"message":"Success"}
```

-   Add new contact for BMGF (organization\_id:13) as user sparadee (user\_id:34)

```
SELECT * FROM pmt_edit_contact(1,34,26225,2237,null,'{"_first_name": "John","_last_name": "Hanhock","_email": "jhanhock@mail.com","_title": "CEO","organization_id": 13}', false);
```

```
{"id":672,"message":"Success"}
```

-   Delete contact\_id 672 as user sparadee (user\_id:34)

```
SELECT * FROM pmt_edit_contact(1,34,26225,2237,672,null,true)
```

```
{"id":672,"message":"Success"}
```

[&larr;  Back to Function List](#function-listing)


## pmt\_edit\_detail

##### Description

Edit a detail.

##### Parameter(s)

1.  instance\_id (integer) – **Required**. Instance id of the instance where the edit request originates.
2.  user\_id (integer) – **Required**. User id of user requesting edits.
3.  activity\_id (integer) – **Required**. activity id of detail record to create.
4.  detail\_id (integer) – **Required for update and delete operations**. detail id of existing detail to update or delete, if left null then a new detail record will be created.
5.  key\_value\_data (json) - **Required for update and create operations**. Key/value pair as json of field/values to edit. Column names are 
case sensitive. Enclose all values in double quotes, including null. **If your text values include
a single quote, use two adjacent single quotes, e.g., 'Dianne''s dog'. This is because PostgreSQL
uses the single quote to encase string constants.** You can include any existing
field that exists for financial, even custom fields. The following fields cannot be edited even
if included: 
	- id
	- _active
	- _retired_by
	- _created_by
	- _created_date
	- _updated_by
	- _updated_date

	Json key/value format:
	```
	{"column_name": "value"}
	```
6. delete\_record (boolean) - Optional, default is false. True to request the record be deleted.

##### Result

Json with the following:

1.  id (integer) – detail\_id of the detail created or updated.
2.  message(character varying) - Message containing either "Success" for a successful transaction 
or containing an error description regarding the unsuccessful transaction. Possible error messages:
	- The json parameter is required for a create/update operation
	- Must include detail\_id when delete_record is true
	- Must include activity\_id parameter when detail\_id parameter is null
	- Must include user\_id parameter
	- Invalid activity\_id


##### Example(s)

-   Update title for detail\_id 136 on activity\_id 29345 as user sparadee (user\_id:34) on the EthAIM instance (instance\_id:1)

```
SELECT * FROM pmt_edit_detail(1, 34, 29345, 136,'{"title": "Description of Activities Related to Nutrition"}', false);
```

```
{"id":136,"message":"Success"}
```

-   Add new detail for activity\_id 493 as user sparadee (user\_id:34) on the AGRA instance (instance\_id:4)

```
SELECT * FROM pmt_edit_detail(4, 34, 493, null,'{"title": "Description of Activities Related to Nutrition"}', false);
```

```
{"id":672,"message":"Success"}
```

-   Delete detail\_id 673 for activity\_id 493 as user sparadee (user\_id:34) on the BMGF instance (instance\_id:5)

```
select * from pmt_edit_detail(5, 34, 493, 673,  null, true);
```

```
{"id":673,"message":"Success"}
```

[&larr;  Back to Function List](#function-listing)

## pmt\_edit\_detail\_taxonomy

##### Description

Edit the relationship between detail(s) and a taxonomy classification(s). 

##### Parameter(s)

1.  instance\_id (integer) – **Required**. Instance id of the instance where the edit request originates.
2.  user\_id (integer) – **Required**. User id of user requesting edits.
3.  detail\_ids (character varying) – **Required**. Comma separated list of detail ids to edit.
4.  classification\_ids (character varying) – **Required/Optional**.  Comma separated list of classification ids of taxonomy classifications in relationship to detail id(s). Not required if using taxonomy\_ids parameter with the delete action. Required for add/replace actions.
5.  taxonomy\_ids (character varying) – **Required/Optional**.  Comma separated list of taxonomy\_ids to remove from relationships to detail\_id(s). Only required if using the delete action.
6.  edit\_action (enum) - **Required** 
	Options:
	1. add (default) - will add a relationship between provided detail id(s) and classification id(s)
	2. delete - will remove the relationship between the provided detail id(s) and classification id(s)/taxonomy id(s)
	3. replace - will replace all relationships between the provided detail ids(s) and taxonomy of the provided classification id(s), with
a relationship between the provided detail id(s) and classification id(s) per taxonomy.

##### Result

Boolean. Sucessfull (true) or unsuccessful (false). Unsuccessful is usually due invalid parameters or permissions.

##### Example(s)

-   User sparadee (user\_id:34) to add a relationship to GTP2 Program Area 'Agricultural extension' (classification\_id:2447) to detail\_ids 1896,1889,1885 from
the EthAIM instance (instance\_id:1):

```select * from pmt_edit_detail_taxonomy(1,34,'1896,1889,1885','2447',null,'add');```

	TRUE

-   User sparadee (user\_id:34) to remove a relationship to GTP2 Program Area 'Agricultural extension' (classification\_id:2447) from detail\_ids 1896,1889,1885 in
the EthAIM instance (instance\_id:1):

```select * from pmt_edit_detail_taxonomy(1,34,'1896,1889,1885','2447',null,'delete');```

	TRUE

-   User sparadee (user\_id:34) to replace all relationships to the GTP2 Program Area taxonomy with a relationship to GTP2 Program Area 'Support to input supply' 
(classification\_id:2450) for detail\_ids 1896,1889,1885 from the EthAIM instance (instance\_id:1):

```select * from pmt_edit_detail_taxonomy(1, 34,'1896,1889,1885','2450',null,'replace');```

	TRUE

-   User sparadee (user\_id:34) to remove all the relationships within the GTP2 Program Area (taxonomy\_id:78) from 
detail\_ids 1896,1889,1885 from the TanAIM instance (instance\_id:1):

```select * from pmt_edit_detail_taxonomy(1,34,'1896,1889,1885',null,'78','delete');```

	TRUE

[&larr;  Back to Function List](#function-listing)

## pmt\_edit\_financial

##### Description

Edit a financial record.

##### Parameter(s)

1.  instance\_id (integer) – **Required**. Instance id of the instance where the edit request originates.
2.  user\_id (integer) – **Required**. User id of user requesting edits.
3.  activity\_id (integer) – **Required for create operations on activity financials**. activity id of financial record to create.
4.  financial\_id (integer) – **Required for update and delete operations**. financial id of existing financial to update or delete, if left null then a new financial record will be created.
5.  key\_value\_data (json) - **Required for update and create operations**. Key/value pair as json of field/values to edit. Column names are 
case sensitive. Enclose all values in double quotes, including null. **If your text values include
a single quote, use two adjacent single quotes, e.g., 'Dianne''s dog'. This is because PostgreSQL
uses the single quote to encase string constants.** You can include any existing
field that exists for financial, even custom fields. The following fields cannot be edited even
if included: 
	- id
	- _active
	- _retired_by
	- _created_by
	- _created_date
	- _updated_by
	- _updated_date

	Json key/value format:
	```
	{"column_name": "value"}
	```
6. delete\_record (boolean) - Optional, default is false. True to request the record be deleted.

##### Result

Json with the following:

1.  id (integer) – financial\_id of the financial created or updated.
2.  message(character varying) - Message containing either "Success" for a successful transaction 
or containing an error description regarding the unsuccessful transaction. Possible error messages:
	- The json parameter is required for a create/update operation
	- Must include financial\_id when delete_record is true
	- Must include activity\_id parameter when financial\_id parameter is null
	- Must include user\_id parameter
	- Invalid activity\_id

##### Example(s)

-   Update amount and start\_date for financial\_id 136 as user sparadee (user\_id:34) from the EthAIM instance (instance\_id:1):

```
select * from pmt_edit_financial(1,34,null,136,'{"_amount": 130900.00, "_start_date":"1-1-2014"}', false);
```

```
{"id":136,"message":"Success"}
```

-   Add new financial record for activity\_id 493 as user sparadee (user\_id:34) from the EthAIM instance (instance\_id:1):

```
select * from pmt_edit_financial(1,34,493,null,'{"_amount": "100500.00", "_start_date":"1-1-2014", 
"_end_date":"12-31-2016"}', false);
```

```
{"id":672,"message":"Success"}
```

-   Delete financial\_id 673 as user sparadee (user\_id:34) from the BMGF instance (instance\_id:4):

```
select * from pmt_edit_financial(4, 34, null, 673, null, true);
```

```
{"id":673,"message":"Success"}
```

[&larr;  Back to Function List](#function-listing)


## pmt\_edit\_financial\_taxonomy

##### Description

Edit the relationship between financial(s) and a taxonomy classification(s). 

##### Parameter(s)

1.  instance\_id (integer) – **Required**. Instance id of the instance where the edit request originates.
2.  user\_id (integer) – **Required**. User id of user requesting edits.
3.  financial\_ids (character varying) – **Required**. Comma separated list of financial ids to edit.
4.  classification\_ids (character varying) – **Required/Optional**.  Comma separated list of classification ids of taxonomy classifications in relationship to financial id(s). Not required if using taxonomy\_ids parameter with the delete action. Required for add/replace actions.
5.  taxonomy\_ids (character varying) – **Required/Optional**.  Comma separated list of taxonomy\_ids to remove from relationships to financial\_id(s). Only required if using the delete action.
6.  edit\_action (enum) - **Required** 
	Options:
	1. add (default) - will add a relationship between provided financial id(s) and classification id(s)
	2. delete - will remove the relationship between the provided financial id(s) and classification id(s)/taxonomy id(s)
	3. replace - will replace all relationships between the provided financial ids(s) and taxonomy of the provided classification id(s), with
a relationship between the provided financial id(s) and classification id(s) per taxonomy.

##### Result

Boolean. Sucessfull (true) or unsuccessful (false). Unsuccessful is usually due invalid parameters or permissions.

##### Example(s)

-   User sparadee (user\_id:34) to add a relationship to Currency 'Tanzanian Shilling' (classification\_id:419) to financial\_ids 8061,8062,8063 from
the TanAIM instance (instance\_id:3):

```select * from pmt_edit_financial_taxonomy(3,34,'8061,8062,8063','419',null,'add');```

	TRUE

-   User sparadee (user\_id:34) to remove the relationship to Currency 'Tanzanian Shilling' (classification\_id:419) from financial\_ids 8064,8065,8066,8067 from
the TanAIM instance (instance\_id:3):

```select * from pmt_edit_financial_taxonomy(3,34,'8064,8065,8066,8067','419',null,'delete');```

	TRUE

-   User sparadee (user\_id:34) to replace  all relationships to the Currency taxonomy 'Tanzanian Shilling' with the relationship to Currency 'Lebanese Pound' 
(classification\_id:356) for financial\_ids 8061,8062,8063 from the TanAIM instance (instance\_id:3):

```select * from pmt_edit_financial_taxonomy(3, 34,'8061,8062,8063','356',null,'replace');```

	TRUE

-   User sparadee (user\_id:34) to remove all the relationships within the Currency (taxonomy\_id:6) from 
financial\_ids 8061,8062,8063 from the TanAIM instance (instance\_id:3):

```select * from pmt_edit_financial_taxonomy(3,34,'8061,8062,8063',null,'6','delete');```

	TRUE

[&larr;  Back to Function List](#function-listing)


## pmt\_edit\_location

##### Description

Create/delete a location. Locations are currently not editable, to alter a location: delete and create.

##### Parameter(s)

1.  instance\_id (integer) – **Required**. Instance id of the instance where the edit request originates.
2.  user\_id (integer) – **Required**. User id of user requesting edits.
3.  activity\_id (integer) – **Required**. Activity id of the location.
4.  location\_id (integer) – **Required for delete operation**. Location id of location to update or delete.
5.  boundary\_id (integer) – **Required for create operation**. Boundary id of boundary the location features is within.
6.  feature\_id (integer) – **Required for create operation**. Featuere id within the boundary representing the location.
7.  admin\_level (integer) – **Required for create operation**. Administrative level (0,1,2,3) of the feature representing the location.
8.  key\_value\_data (json) - **Required for create operation**. Key/value pair as json of field/values to edit. Enclose 
all values in double quotes, including null. **If your text values include
a single quote, use two adjacent single quotes, e.g., 'Dianne''s dog'. This is because PostgreSQL
uses the single quote to encase string constants.** You can include any existing
field that exists for location, even custom fields. The following fields cannot be edited even
if included: 
	- id
	- activity\_id
	- _x
	- _y
	- _lat_dd
	- _long_dd
	- _latlong
	- _active
	- _retired_by
	- _created_by
	- _created_date
	- _updated_by
	- _updated_date

	Json key/value format:
	```
	{"column_name": "value"}
	```
9. delete\_record (boolean) - Optional, default is false. True to request the record be deleted.

##### Result

Json with the following:

1.  id (integer) – location\_id of the location created, updated or deleted.
2.  message(character varying) - Message containing either "Success" for a successful transaction 
or containing an error description regarding the unsuccessful transaction. Some possible error messages:
	- The json parameter is required for a create operation
	- activity\_id is a required parameter for all operations
	- instance\_id is a required parameter for all operations
	- user\_id is a required parameter for all operations
	- User does NOT have authority to create/delete a location record for activity id
	- Invalid boundary\_id & feature\_id
	- The boundary\_id, feature\_id & admin\_level parameters are required for a create operation

##### Example(s)

-  As user sparadee (user\_id:34) create a new location for activity id 23342 in Bole (feature\_id:1322) a woreda in Region 14, Addis Ababa within the 
UNOCHA Ethiopia Administrative Level 3 (boundary\_id:14) from the EthAIM instance (instance\_id:1):

```
select * from pmt_edit_location(1,34,23342,null,14,1322,3,'{"_admin0": "Ethiopia", "_admin1": "Addis Ababa", "_admin2": "Region 14", "_admin3": "Bole"}', false); 
```

```
{"id":15821,"message":"Success"}
```

-  As user sparadee (user\_id:34) delete location\_id 81116 for activity id 23342 from the EthAIM instance (instance\_id:1):

```
select * from pmt_edit_location(1,34,23342,81116,null,null,null,null,true); 
```

```
{"id":81116,"message":"Success"}
```

[&larr;  Back to Function List](#function-listing)


## pmt\_edit\_location\_taxonomy

##### Description

Edit the relationship between a location(s) and a taxonomy classification(s).

##### Parameter(s)

1.  user\_id (integer) – **Required**. User\_id of user requesting edits.
2.  location\_ids (character varying) – **Required**. Comma seperated list of location_ids to edit.
3.  classification\_ids (character varying) – **Required/Optional**.  Comma seperated list of  classification\_ids of taxonomy classifications in relationship to location\_id(s). Not required if using remove\_taxonomy\_ids parameter.
4.  remove\_taxonomy\_ids (charcter varying) - **Required/Optional**.  Comma seperated list of taxonomy\_ids to remove from relationships to location\_id(s). Not required if using classification\_ids parameter.
5.	edit\_location (enum) - Optional. 
	Options:
	1. add (default) - will add a relationship between provided location\_id(s) and classification_id(s)
	2. delete - will remove the relationship between the provided location\_id(s) and classification_id(s)
	3. replace - will replace all relationships between the provided location\_ids(s) and taxonomy of the provided classification\_id(s), with
a relationship between the provided location\_id(s) and classification\_id(s) per taxonomy.

##### Result

Boolean. Successful (true) or unsuccessful (false). Unsuccessful is usually due invalid parameters or insufficient permissions.

##### Example(s)

-   Add a relationship to Location Reach 'Intended Beneficiaries' (classification\_id:975), Location Class
'Populated Place' (classification\_id:971) and Location Class 'Ward (level-3)' (classification\_id:1196) 
to location\_ids 1470,1471,1472,1473:

```select * from pmt_edit_location_taxonomy(55,'1470,1471,1472,1473','975,971,1196',null,'add')```

	TRUE

-   Remove the relationship to Location Reach 'Partners' (classification\_id:976), Location Class
'River Basin' (classification\_id:973) and Location Class 'District (level-2)' (classification\_id:970) 
to location\_ids 1470,1471,1472,1473:


```select * from pmt_edit_location_taxonomy(55,'1470,1471,1472,1473','976,970,973',null,'delete');```

	TRUE

-   Replace  all relationships to the Location Reach taxonomy with the relationship to Location Reach 
'Action/intervention' (classification\_id:974) and all the relationships to Location Class with the
relationship to Location Class 'District (level-2)' (classification\_id:970) for location\_ids 
1470,1471,1472,1473:

```select * from pmt_edit_location_taxonomy(55,'1470,1471,1472,1473','974,970','replace');```

	TRUE

-   Remove the realtionships within the 'Country' taxonomy (taxonomy\_id:5) for location\_ids 1472,1473,1474,1475,1476,1477:

```select * from pmt_edit_location_taxonomy(55,'1472,1473,1474,1475,1476,1477',null,'5',null);```

	TRUE

[&larr;  Back to Function List](#function-listing)

## pmt\_edit\_organization

##### Description

Edit a organization.

##### Parameter(s)

1.  instnace\_id (integer) – **Required**. Instance id that the requesting user is editing from.
2.  user\_id (integer) – **Required**. User\_id of user requesting edits.
3.  organization\_id (integer) – **Required for update and delete operations**. organization\_id of existing organization to update or delete, if left null then a new organization record will be created.
4.  json (json) - **Required for create and update operations**. Key/value pair as json of field/values to edit. Column names are 
a single quote, use two adjacent single quotes, e.g., 'Dianne''s dog'. This is because PostgreSQL
uses the single quote to encase string constants.** You can include any existing
field that exists for organization, even custom fields. The following fields cannot be edited even
if included: 
	- id
	- iati\_import\_id
	- \_active
	- \_retired_by
	- \_created_by
	- \_created_date
	- \_updated_by
	- \_updated_date

	Json key/value format:
	```
	{"column_name": "value"}
	```
5. delete\_record (boolean) - Optional, default is false. True to request the record be deleted.

##### Result

Json with the following:

1.  id (integer) – organization\_id of the organization created or updated.
2.  message(character varying) - Message containing either "Success" for a successful transaction 
or containing an error description regarding the unsuccessful transaction. Possible error messages:
	- Must include user\_id and json data parameters - Received when both required parameters are not provided.
	- User does NOT have authority to create a new organization - Received when the user\_id provided does not have authority to create under current role.
	- User does NOT have authority to update an existing organization - Received when the user\_id provided does not have authority to update under current role.
	- Invalid organization\_id - Received when the organization\_id provided is invalid.

##### Example(s)

-   Update the email and url for CIAT (organization\_id:25) as user sparadee (user\_id:34) in the EthAIM instance (instance\_id:1)

```
select * from pmt_edit_organization(1,34,25,'{"email":"ciatk@mail.com", "url":"www.ciat.org"}', false);
```

```
{"id":25,"message":"Success"}
```

-   Add new organization as user sparadee (user\_id:34) in the EthAIM instance (instance\_id:1)

```
select * from pmt_edit_organization(4,34,null,'{"name":"SpatialDev", "url":"www.spatialdev.com", 
"email":"info@spatialdev.com"}', false);
```

```
{"id":672,"message":"Success"}
```

-   Delete organization\_id 672 as user sparadee (user\_id:34) from EthAIM instance (instance\_id:1)

```
select * from pmt_edit_organization(1, 34,672,null, true);
```

```
{"id":672,"message":"Success"}
```

[&larr;  Back to Function List](#function-listing)

## pmt\_edit\_participation

##### Description

Edit the relationship between activities and organizations.

##### Parameter(s)

1.  instance\_id (integer) – **Required**. Instance id of the instance where the edit request originates.
2.  user\_id (integer) – **Required**. User id of user requesting edits.
3.  activity\_id (integer) – **Required**. Activity id of activity that organization has participation in.
4.  organiation\_id (integer) – **Required**. Organiation id of organization that is participating in the activity.
5.  participation\_id (integer) – **Required for delete/replace operations**. participation id of participation record to edit.
6.  classification\_ids (character varying) – **Required for add/replace operations**.  Classification ids from Organisation Role taxonomy that represents the organizations participation role in the activity.
7.  edit\_action (enum) - **Required** 
	Options:
	1. add (default) - will add a participation record to activity.
	2. delete - will remove a participation record.
	3. replace - will replace all existing participation records with the new participation record for the activity **make sure you understand what this is doing before requesting this edit action**

##### Result

Json with the following:

1.  id (integer) – organization\_id of the organization created or updated.
2.  message(character varying) - Message containing either "Success" for a successful transaction 
or containing an error description regarding the unsuccessful transaction.

##### Example(s)

-   Add AECID (SPAN) (organization\_id:3075) as a Funding & Implementing (classification\_id:496 & 497) organization for activity 'African Stockpiles Project'
(activity\_id:26271) as user sparadee (user\_id:34) from the EthAIM instance (instance\_id:1):

```select * from pmt_edit_participation(1, 34, 26271, 3075, null, '496,497', 'add');```

```{"id":56667,"message":"Success"}```

-   Delete Government of Ethiopia (GoE) (paricipation\_id:10708) as a participating organization for activity 'African Stockpiles Project'
(activity\_id:26271) as user sparadee (user\_id:34) from the EthAIM instance (instance\_id:1):

```select * from pmt_edit_participation(1, 34, 26271, null, 10708, null, 'delete');```

```{"id":10708,"message":"Success"}```

-   Replace Government of Ethiopia (GoE) (paricipation\_id:10708) as a participating organization for activity 'African Stockpiles Project'
(activity\_id:26271) with AECID (SPAN) (organization\_id:3075) as a Funding & Implementing (classification\_id:496 & 497) organization as user 
sparadee (user\_id:34) from the EthAIM instance (instance\_id:1):

```select * from pmt_edit_participation(1, 34, 26271, 3075, 10708, '496,497', 'replace');```

```{"id":10708,"message":"Success"}```

[&larr;  Back to Function List](#function-listing)

## pmt\_edit\_participation\_taxonomy

##### Description

Edit the relationship between a participation and a taxonomy classification.

##### Parameter(s)

1.  user\_id (integer) – **Required**. User\_id of user requesting edits.
2.  participation\_id (integer) – **Required**. participation_id to edit.
3.  classification\_id (integer) – **Required**.  Classification\_id of taxonomy classification in relationship to the participation\_id.
4.  edit\_action (enum) - Optional. 
	Options:
	1. add (default) - will add a relationship between provided participation\_id and classification_id
	2. delete - will remove the relationship between the provided participation\_id and classification_id
	3. replace - will replace all relationships between the provided participation\_ids and taxonomy of the provided classification\_id, with
a single relationship between the provided participation\_id and classification\_id.

##### Result

Boolean. Sucessfull (true) or unsuccessful (false). Unsuccessful is usually due invalid parameters or insufficient permissions.

##### Example(s)

-   Add a relationship to Organisation Role 'Accountable' (classification\_id:494) and 'Funding'
(classification\_id:496) to participation\_ids 6003,6004:


```select * from pmt_edit_participation_taxonomy(55,'6003,6004','494,496','add');```

	TRUE

-   Remove a relationship to Organisation Role 'Accountable' (classification\_id:494) and 'Funding'
(classification\_id:496) for participation\_ids 6003,6004:

```select * from pmt_edit_participation_taxonomy(55,'6003,6004','494,496', 'delete');```

	TRUE

-   Replace  all relationships to the Organisation Role taxonomy with the relationship 
to Organisation Role 'Implementing' (classification\_id:497) to participation\_id 6003,6004:


```select * from pmt_edit_participation_taxonomy(55,'6003,6004', '497', 'replace');```

	TRUE

[&larr;  Back to Function List](#function-listing)

## [pmt\_edit\_taxonomy]

##### Description

Edit the taxonomy table. 

##### Parameter(s)

1.  instance\_id (integer) – **Required**. Instance id of the instance where the edit request originates.
2.  user\_id (integer) – **Required**. User\_id of user requesting edits.
3.  taxonomy\_id (integer) – **Required for update and delete operations**. Taxonomy id of record to update or delete.
4.  key\_value\_data (json) - **Required for create and update operations**. Key/value pair as json of field/values to edit. Column names are 
case sensitive. Enclose all values in double quotes, including null. **If your text values include
a single quote, use two adjacent single quotes, e.g., 'Dianne''s dog'. This is because PostgreSQL
uses the single quote to encase string constants.** You can include any existing
field that exists for activity, even custom fields. The following fields cannot be edited even
if included: 
	- id
	- _active
	- _retired_by
	- _created_by
	- _created_date
	- _updated_by
	- _updated_date
	- _core
	- data_group_ids (this are copied from the instance on create operations)

	Json key/value format:
	```
	{"column_name": "value"}
	```
5. delete\_record (boolean) - Optional, default is false. True to request the record be deleted.
 
##### Result

Success or Fail message Json message

##### Example(s)

Add a new taxonomy "Test Taxonomy" from EthAIM instance (instance\_id: 1) as user\_id 272:
``` 
select * from pmt_edit_taxonomy(1, 272, null, '{"_name":"Test Taxonomy","_description":"Test Taxonomy - tester"}', false);
```

Update the "Test Taxonomy" (taxonomy\_id: 85) from EthAIM instance (instance\_id: 1) as user\_id 272:
``` 
select * from pmt_edit_taxonomy(1, 272, 85, '{"_description":"Test Taxonomy - updating the description"}', false);
```

Delete the "Test Taxonomy" (taxonomy\_id: 85) from EthAIM instance (instance\_id: 1) as user\_id 272:
``` 
select * from pmt_edit_taxonomy(1, 272, 85, null, true);
```

[&larr;  Back to Function List](#function-listing)

## pmt\_edit\_user

##### Description

Edit a user.

##### Parameter(s)

1.  instnace\_id (integer) – **Required**. Instance id that the requesting user is editing from.
1.  request\_user\_id (integer) – **Required**. User id of user requesting edits.
2.  target\_user\_id (integer) – **Required for delete and update operations**. User id of user record to be updated or deleted.
3.  json (json) - **Required for create and update operations**. Key/value pair as json of field/values to edit. Column names are 
case sensitive. Enclose all values in double quotes, including null. **If your text values include
a single quote, use two adjacent single quotes, e.g., 'Dianne''s dog'. This is because PostgreSQL
uses the single quote to encase string constants.** You can include any existing
field that exists for user even custom fields. The following fields cannot be edited even
if included: 
	- id
	- _retired_by
	- _created_by
	- _created_date
	- _updated_by
	- _updated_date

	Json key/value format:
	```
	{"column_name": "value"}
	```
4. role\_id (integer) **Required for create and update operations**. The role id of the edited user record for the instance.
5. delete\_record (boolean) - Optional, default is false. True to request the record be deleted.

##### Result

Json with the following:

1.  id (integer) – user\_id of the user that was created, updated or deleted.
2.  message(character varying) - Message containing either "Success" for a successful transaction 
or containing an error description regarding the unsuccessful transaction. Some possible error messages:
	- Must include json parameter when delete_record is false.
	- User does NOT have authority to create a new user
	- User does NOT have authority to delete this user
	- User does NOT have authority to update this user
	- Invalid user_id.
	- Invalid organization_id;

##### Example(s)

-   User (user\_id: 34) updates their own email and password from the SpatialDev instance (instance\_id: 1) where they are have a
Administrator role (role\_id: 4). Users can change any 
element of their user record with the exception of their role\_id which determines thier instance level permissions.

```
select * from pmt_edit_user(1, 34, 34, '{"email": "mymail@email.com", "password":"Summ3r!"}', 4, false);
```

```
{"id":4,"message":"Success"}
```

-  Create a new user with Editor role (role\_id: 2) on the EthAIM instance (instance\_id: 3) as user (user\_id:34) with the an 
Administrator role (role\_id: 4). The following fields are required for a new user: \_first\_name, \_last\_name, \_email, \_username, 
\_password & organization\_id.

```
select * from pmt_edit_user(1, 34, null, '{"organization_id": 2672, "_username":"testuser", "_password":"testpassword","_email":"test@mail.com","_first_name":"Test","_last_name":"User"}', 2, false)
```

```
{"id":45,"message":"Success"}
```

-  Delete user\_id 45 as user (user\_id:34) with either the Administrator role on the TanAIM instance (instance\_id: 3).

```
select * from pmt_edit_user(3, 34, 45, null, null, true);

```

```
{"id":45,"message":"Success"}
```

[&larr;  Back to Function List](#function-listing)


## pmt\_edit\_user\_activity

##### Description

Edit a user's authorization to access activities for editing by activity id or classification id.

##### Parameter(s)

1.  instnace\_id (integer) – **Required**. Instance id that the requesting user is editing from.
1.  request\_user\_id (integer) – **Required**. User id of user requesting edits.
2.  target\_user\_id (integer) – **Required**. User id of user record to be authorized for access to activities.
3.  activity\_ids (integer[]) - Array of activity ids to authorize or remove access to. 
4.  classification\_ids (integer[]) - Array of classification ids to authorize or remove access to.
5.  delete\_record (boolean) - Optional, default is false. True to request removal of authorization to activities.

##### Result

Json with the following:

1.  id (integer) – user\_id of the user in which authorization was edited.
2.  message(character varying) - Message containing either "Success" for a successful transaction 
or containing an error description regarding the unsuccessful transaction. Some possible error messages:
	- The requesting user must have security rights on instance.
	- The target user must have edit rights on instance.
	- The target user must have access to instance.
	- A valid instance_id is a required.

##### Example(s)

-   Administrator user (user\_id: 227) removes access to activity ids 26197 & 26200 for an editor user (user\_id: 275)
on the EthAIM instance (instance\_id: 1). _Note: The user's permissions on these activities is dependent on their role on the instance._

```
select * from pmt_edit_user_activity(1, 277, 275, ARRAY[26197,26200], null, true);
```

```
{"id":275,"message":"Success"}
```

-   Administrator user (user\_id: 227) authorizes access to all activities for an editor user (user\_id: 275) that are associated to
the "Stand Alone Project" & "Agricultural Growth Program" (classification\id: 2239,2242) for the Category Taxonomy.
on the EthAIM instance (instance\_id: 1). _Note: The user's permissions on these activities is dependent on their role on the instance._

```
select * from pmt_edit_user_activity(1, 277, 275, null, ARRAY[2239,2242], false);
```

```
{"id":275,"message":"Success"}
```

[&larr;  Back to Function List](#function-listing)


## pmt\_export

##### Description

Create an export dataset based on filters. Intended to be exported at csv using application or json to csv conversion. This
function is intended to be the generic export function, but there may be custom export functions for specific data groups:
  - pmt\_export\_bmgf
  - pmt\_export\_tanaim
  - pmt\_export\_ethaim

##### Parameter(s)

1. data\_group\_ids (character varying) - comma seperated list of classification id(s) from the Data Group taxonomy
to restrict data. If no data group id is provided, all data groups are included.
2. classification\_ids (character varying) - comma seperated list of classification id(s) for any taxonomy (filter).
3. org\_ids (character varying) - comma seperated list of organization id(s) for organizations for all participation types (filter).
4. imp\_org\_ids (character varying) - comma seperated list of organization id(s) for implementing organizations (filter).
5. fund\_org\_ids (character varying) - comma seperated list of organization id(s) for funding organizations (filter).
6. start\_date (date) - start date for activities (filter).
7. end\_date (date) - end date for activities (filter).
8. unassigned\_taxonomy\_ids (character varying) - comma seperated list of taxonomy id(s) for any taxonomy, will return activities that _DO NOT_ have that taxonomy assigned (filter).

##### Result

A json object containing columns of data by row:

1. c1 (text) – first column of data
2. c2 (text) – second column of data
3. c3 (text) - third column of data
...
18. c18 (text) - the eighteenth column of data

##### Example(s)

-   Data export for all data for World Bank (data\_group\_id:2210):

```SELECT * FROM pmt_export('2210',null,null,null,null,null,null,null);```

```
...
{
	"c1":"Activity Data",
	"c2":"PMT ActivityID",
	"c3":"Activity Title",
	"c4":"Activity Description",
	"c5":"Sector - Name",
	"c6":"Sector - Code",
	"c7":"Latitude Longitude",
	"c8":"Country",
	"c9":"Funding Organization(s)",
	"c10":"Implementing Organization(s)",
	"c11":"Start Date",
	"c12":"End Date",
	"c13":"Total Budget",
	"c14":"Activity Status",
	"c15":null,
	"c16":null,
	"c17":null,
	"c18":null
}
{
	"c1":"",
	"c2":"24586",
	"c3":"BF-Compet &amp; Enterprise Dev (FY03)",
	"c4":"The Competitiveness and Enterprise Development Project for Burkina Faso will assist Burkina Faso to improve the competitiveness of its economy through privatization and utility reform (...)"
	"c5":"Agricultural development",
	"c6":"31120",
	"c7":"32.01524 -5.2584",
	"c8":"Tanzania",
	"c9":"World Bank",
	"c10":"Local NGOs",
	"c11":"2005-1-15",
	"c12":"2008-5-30",
	"c13":"1530250",
	"c14":"Complete",
	"c15":null,
	"c16":null,
	"c17":null,
	"c18":null
}
...
```

[&larr;  Back to Function List](#function-listing)

## pmt\_exists\_activity_contact

##### Description

Confirm if a contact is assigned to an activity.

##### Parameter(s)

1. activity\_id (integer) -  **Required**. activity_id to lookup.
1. contact\_id (integer) -  **Required**. contact_id to lookup.

##### Result

Boolean. True/False valid.

##### Example(s)

```SELECT * FROM pmt_exists_activity_contact(26225,2355);```

TRUE

[&larr;  Back to Function List](#function-listing)

## pmt\_filter

##### Description

Accepts a number of filter parameters and returns a list of activity ids that have requested attributes.

##### Parameter(s)

1. data\_group\_ids (character varying) - comma seperated list of classification id(s) from the Data Group taxonomy
to restrict data. If no data group id is provided, all data groups are included.
2. classification\_ids (character varying) - comma seperated list of classification id(s) for any taxonomy (filter).
3. org\_ids (character varying) - comma seperated list of organization id(s) for organizations for all participation types (filter).
4. imp\_org\_ids (character varying) - comma seperated list of organization id(s) for implementing organizations (filter).
5. fund\_org\_ids (character varying) - comma seperated list of organization id(s) for funding organizations (filter).
6. start\_date (date) - start date for activities (filter).
7. end\_date (date) - end date for activities (filter).
8. unassigned\_taxonomy\_ids (character varying) - comma seperated list of taxonomy id(s) for any taxonomy, will return activities that _DO NOT_ have that taxonomy assigned (filter).

##### Result

Integer array of filtered activity ids. Only active activity ids will be returned.


##### Example(s)

-   Filter activities to include only BMGF data (data\_group\_id: 768) where the Initative is Research & Development 
(classification\_id: 831) or there is **NO** Initiative (taxonomy\_id: 23) and Non-Governmental organizations (NGOs) 
(organization\_id:1681) are participating in activities occuring between 1/1/2012 and 12/31/2018:

```SELECT * FROM pmt_filter('768','831','1681','','','1/1/2012','12/31/2018','23');```

```
[2070,2071,2072,2073,2074,2077,2078,2094,2095,2108,12039]

```

[&larr;  Back to Function List](#function-listing)

## pmt\_filter\_iati

##### Description

Create and email a IATI formatted Activity xml file of data filtered by classification, organization and date range,
reporting associated organization(s).

##### Parameter(s)

1.  classification\_ids (character varying) – Optional. Restrict data to
    classification(s).
2.  organization\_ids (character varying) – Optional. Restrict data to
    organization(s)
3.  unassigned\_tax\_ids (character varying) – Optional. Include data
    without assignments to specified taxonomy(ies).
4.  start\_date (date) – Optional. Restrict data to a data range. Used
    with end\_date parameter.
5.  end\_date (date) – Optional. Restrict data to a data range. Used
    with start\_date parameter.
6.  email (text) - **Required**. Email address to send the created csv to.

##### Result

A xml document of in the IATI Activity Schema.

##### Example(s)

-   Data export for AGRA data group (classification\_id:769):

```SELECT * FROM pmt_filter_iati('769','','',null,null, 'sparadee@spatialdev.com');```

	TRUE

[&larr;  Back to Function List](#function-listing)


## pmt\_filter\_string

##### Description

Accepts the same parameters as [pmt\_filter](#pmt_filter) and returns a "pretty string" of selected filters.

##### Parameter(s)

1. data\_group\_ids (character varying) - comma seperated list of classification id(s) from the Data Group taxonomy
to restrict data. If no data group id is provided, all data groups are included.
2. classification\_ids (character varying) - comma seperated list of classification id(s) for any taxonomy (filter).
3. org\_ids (character varying) - comma seperated list of organization id(s) for organizations for all participation types (filter).
4. imp\_org\_ids (character varying) - comma seperated list of organization id(s) for implementing organizations (filter).
5. fund\_org\_ids (character varying) - comma seperated list of organization id(s) for funding organizations (filter).
6. start\_date (date) - start date for activities (filter).
7. end\_date (date) - end date for activities (filter).
8. unassigned\_taxonomy\_ids (character varying) - comma seperated list of taxonomy id(s) for any taxonomy, will return activities that _DO NOT_ have that taxonomy assigned (filter).

##### Result

A string.


##### Example(s)

-   Filter activities to include only BMGF data (data\_group\_id: 768) where the Initative is Research & Development 
(classification\_id: 831) or there is **NO** Initiative (taxonomy\_id: 23) and Non-Governmental organizations (NGOs) 
(organization\_id:1681) are participating in activities occuring between 1/1/2012 and 12/31/2018:

```SELECT * FROM pmt_filter_string('768','831','1681','','','1/1/2012','12/31/2018','23');```

```
"PMT 3.0, Database Version 3.0.10.34, Retrieval Date: 2016-06-22, Filters: Data Group: BMGF | Initiative: Research & Development | Unassigned taxonomies: Initiative | Organization: Non-Governmental organizations (NGOs) | DateRange: 2012-01-01 to 2018-12-31"

```

[&larr;  Back to Function List](#function-listing)


## pmt\_find\_users

##### Description

Returns all users with first name, last name or email equal or like passed parameters.  Useful for 
finding potential matching or existing users.

##### Parameter(s)

1. first\_name (character varying) - first name to search.
2. last\_name (character varying) - last name to search.
3. email (character varying) - email to search.

##### Result

Json with the following:

1.  id (integer) – user id.
2.  _first\_name (character varying) – first name of user.
3.  _last\_name (character varying) – last name of user.
4.  _username (character varying) – username of user.
5.  _email (character varying) – email address of user.
6.  \_phone (character varying) - phone number of user.
7.  organization\_id (integer) – organization id for organization of user.
8.  organization (character varying) – organization name for organization of user.
9.  instances (json[]) - object containing instance information user has access to
    a. instance\_id (integer) - the instance id.
	b. instance (character varying) - the theme name of the instance
    c. role\_id (integer) - the role id.
	d. role (character varying) - the name of the role.
10.  _access\_date (timestamp without time zone) - most recent user login timestamp.
11. _active (boolean) - t/f user account is active.

##### Example(s)

```SELECT * FROM pmt_find_users('Jane','Doe','jdoe@email.com');```

```
{
	"id":315,
	"_first_name":"Jane",
	"_last_name":"Doe",
	"_username":"myusername",
	"_email":"jane.doe@email.com",
	"_phone":"123-456-7890",
	"organization_id":13,
	"organization": "BMGF",
	"instances":[
		"instance_id": 2,
		"instance": "bmgf",
		"role_id": 2,
		"role": "Editor"
	],
	"_access_date": "2014-05-21T23:29:27.497825",
	"_active":true
}
```


[&larr;  Back to Function List](#function-listing)


## pmt\_full\_record


##### Description

All information for a single activity formatted specifically for editing.

##### Parameter(s)

1. activity_id (integer) - **Required.** Activity id.

##### Result

Json with the following:

1.  id (integer) – activity id.
2.  data\_group\_id (integer) – the data group id.
3.  parent\_id (integer) – the activity's parent id (if null the activity is a parent).
4.  \_title (character varying) – title of activity.
5.  \_label (character varying) – short title for activity.
6.  \_description (character varying) – description of activity.
7.  \_objective (character varying) – the objective for activity.
8.  \_content (character varying) – various content for activity.
9.  \_url (character varying) – url for activity.
10.  \_start\_date (date) – start date of activity.
11.  \_planned\_start\_date (date) – planned start date of activity.
12.  \_planned\_end\_date (date) – end date of activity.
13.  \_end\_date (date) – planned end date of activity.
14.  \_tags (character varying) – tags or keywords of activity.
15.  \_iati\_identifier (integer) – iati identifier or primary key of activity.
16.  \_iati\_import\_id (integer) – iati import id for the corresponding import record (if null the data was manually loaded).
17.  \_created\_by (character varying(50)) -  user to create activity information.
18.  \_created\_date (timestamp) -  date and time activity information was created.
17.  \_updated\_by (character varying(50)) -  last user to update activity information.
18.  \_updated\_date (timestamp) -  last date and time activity information was updated.
19.  custom\_fields (various) - any custom fields in the activity table that are not in the Core PMT will be returned as well.
20.   data\_group (character varying) – the data group name.
21.   parent\_title (character varying) – the activity's parent activity title.
22.  ct (integer) - number of locations for activity.
23.  taxonomy(object) - An object containing all associated taxonomy for the activity
	1. taxonomy\_id (integer) - taxonomy id.
	2. taxonomy (character varying) - taxonomy name.
	3. classification\_id (integer) - classification id.
	4. classification (character varying) - classification name.
	5. code (character varying) - classification code.
24.  organizations(object) - An object containing all organizations participating in the activity
	1. id (integer) - organization id
	2. _name (character varying) - the organization name.
	3. classification\_id (integer) - the classification id for the assigned organization role
	4. classification (character varying) - the organization's role in the activity (Implementing, Funding, Accountable, Extending).
25.  contacts (object) - An object containing all activity contacts.
	1. id (integer) - the contact id.
	2. \_first\_name (character varying) - contact's first name.
	3. \_last\_name (character varying) - contact's last name.
	4. \_email (character varying) - contact's email address.
	5. organization\_id (integer) - organization id.
	6. \_name (character varying) - organization name the contact is associated with.
27.  financials (object) - An object containing all activity financial data.
	1. id (integer) - financial id.
	2. \_amount (numeric (100,2)) - financial amount.	
	3. \_start\_date (date) – start date for financial amount.
	4. \_end\_date (date) – end date for financial amount.
	5. provider\_id (integer) - the organization id for the organization providing the financial amount.
	5. provider (character varying) - the name of the organization providing the financial amount.
	6. recipient\_id (integer) - the organization id of the organization receiving the financial amount.
	6. recipient (character varying) - the name of the organization receiving the financial amount.
	7. taxonomy(object) - An object containing all associated taxonomy for the financial record
		1. taxonomy\_id (integer) - taxonomy id.
		2. taxonomy (character varying) - taxonomy name.
		3. classification\_id (integer) - classification id.
		4. classification (character varying) - classification name.
		5. code (character varying) - classification code.
29.  locations (object) - An object containing all activity location data.
	1. id (integer) - location id.
	2. \_admin0 (character varying) - the name of the administrative level 0 boundray for the location.	
	2. \_admin1 (character varying) - the name of the administrative level 1 boundray for the location.	
	3. \_admin2 (character varying) - the name of the administrative level 2 boundray for the location.
	4. \_admin3 (character varying) - the name of the administrative level 3 boundray for the location.
	5. \_admin_level (integer) - the administrative boundary level in which the location is mapped to.
	6. boundary\_id (integer) - boundary id for associated feature.
	7. feature\_id (integer) - feature id of boundary.
30.  children (object) - An object containing all activity's children activities.
	1. id (integer) - child activity id.
	2. \_title (character varying) - child activity title.

##### Example(s)

```select * from pmt_activity(3);```

```
{
	"activity_id":3
	,"project_id":1
	,"title":"UN collaborative Program for Reducing Emissions from Deforestation and forest Degradation in developing 
			countries, Tanzania (UN-REDD)"
	,"label":null
	,"description":"The project aims at strengthening Tanzanias readiness for Reducing Emissions from Deforestation and 
			forest Degradation (REDD) as a component of the Governments evolving REDD Strategy, and integrate it 
			with other REDD activities in the country"
	,"content":null
	,"start_date":"2009-10-01"
	,"end_date":"2013-12-31"
	,"tags":null	
	,"created_by":"IATI XML Import"
	,"created_date":"2014-01-16 00:00:00"
	,"updated_by":"IATI XML Import"
	,"updated_date":"2014-01-16 00:00:00"
	,"iati_identifier":null
	,"location_ct":1
	,"admin_bnds":"United Republic of Tanzania,Singida,Manyoni"
	,"taxonomy":[{
		 "taxonomy_id":5
		,"taxonomy":"Country"
		,"classification_id":244
		,"classification":"TANZANIA, UNITED REPUBLIC OF"
		,"code":"TZ"
		}
		,{
		 "taxonomy_id":14
		,"taxonomy":"Sector Category"
		,"classification_id":552
		,"classification":"Other multisector"
		,"code":"430"
		}
		,{
		 "taxonomy_id":15
		,"taxonomy":"Sector"
		,"classification_id":729
		,"classification":"Multisector aid"
		,"code":"43010"
		}
		,{
		 "taxonomy_id":17
		,"taxonomy":"Category"
		,"classification_id":779
		,"classification":"Training and Capacity Building"
		,"code":null
		}
		,{
		 "taxonomy_id":18
		,"taxonomy":"Sub-Category"
		,"classification_id":792
		,"classification":"Training and Capacity Building"
		,"code":null
		}]
	,"organizations":[
		{
		 "id":1
		,"_name":"FAO/ UNEP/ UNDP"
		,"classification_id":496
		,"classification":"Funding"
		}
		,{
		"id":56
		,"_name":"Tanzania Forestry Service (TFS)"
		,"classification_id":497
		,"classification":"Implementing"
		}
		,{
		"id":2
		,"_name":"MNRT, TFS"
		,"classification_id":497
		,"classification":"Implementing"
		}
	]
	,"contacts":[{
		"contact_id":1
		,"first_name":"Almas"
		,"last_name":"Kashindye"
		,"email":"Almas.Kashindye@fao.org"
		,"organization_id":1
		,"name":"FAO/ UNEP/ UNDP"
		}]
	,"financials":[{
		 "financial_id":13
		,"amount":814972.00
		,"taxonomy":[{
			"taxonomy_id":6
			,"taxonomy":"Currency"
			,"classification_id":422
			,"classification":"US Dollar"
			,"code":"USD"
			}]
		}]
	,"locations":[{3}]
}
```

[&larr;  Back to Function List](#function-listing)


## pmt\_get_\_valid\_id


##### Description

Returns first valid parent activity id.

##### Parameter(s)

1.  data\_group\_ids (character varying) - comma delimited string of data group ids it restrict search to.

##### Result

Json with the following:

1.  id (integer) – first valid parent activity id.


##### Example(s)

-   Get the first valid parent activity id in the RED&FS data (data_group_id: 2237):

```SELECT * FROM pmt_get_valid_id('2237');```

```
{
	"ids":[26255,26257,26259]
}

```

[&larr;  Back to Function List](#function-listing)

## pmt\_global\_search


##### Description

Searches all text and character varying data type fields for the [activity table](DataDictionary.md#activity) for the search text.

##### Parameter(s)

1.  search\_text (text) – **Required**. Text string to search activity table.
2.  data\_group\_ids (character varying) - comma delimited string of data group ids it restrict search to.

##### Result

Json with the following:

1.  ids (integer[]) – array of activity ids.


##### Example(s)

-   Search for the term 'wheat' in the RED&FS data (data_group_id: 2237):

```SELECT * FROM pmt_global_search('wheat', '2237');```

```
{
	"ids":[26255,26257,26259]
}

```

[&larr;  Back to Function List](#function-listing)

## pmt\_iati\_import

##### Description

Imports an IATI Activities formatted xml document. 

##### Parameter(s)

1. user\_id (integer) **Required**. The user id of the user loading the xml document.
2. file\_path (text) – **Required**. Path to IATI Activities formatted xml document.
3. file\_encoding (text) – **Required**. The encoding of the xml document. The encoding should be 
an attribute on the xml element. Must use the [Postgres equivalent](http://www.postgresql.org/docs/9.1/static/functions-string.html#CONVERSION-NAMES) 
for the encoding.
4. data\_group\_name (character varying) - **Required**. Name of the data group. If data group does not exist it will be created.


##### Result

True (success) or false (unsuccessful).

##### Example(s)

```SELECT * FROM pmt_iati_import(34, '/usr/local/pmt_iati/BoliviaIATI.xml', 'utf-8', 'Bolivia');```

TRUE

[&larr;  Back to Function List](#function-listing)


## pmt\_is\_data\_group

##### Description

Validates a data group name or data group classification\_id. Data group is a taxonomy that
is used to determine data source and provide user authentication.

##### Parameter(s)

1. name (character varying) – any Data Group name to be tested as valid.
** OR **
1. classification\_id (integer) - any integer to be tested as a valid classification\_id in the Data Group taxonomy.

##### Result

True or false.

##### Example(s)

```SELECT * FROM pmt_is_data_group('Charlie Chocolate');```

FALSE

```SELECT SELECT * FROM pmt_is_data_group(768);```

TRUE

[&larr;  Back to Function List](#function-listing)

## pmt\_is\_data\_groups

##### Description

Validates data group classification\_ids. Data group is a taxonomy that
is used to determine data validity.

##### Parameter(s)

1. classification\_ids (integer[]) – Array of Data Group ID's to be tested as valid. If parameter is NULL then result will be TRUE.

##### Result

True or false.

##### Example(s)

```SELECT * FROM pmt_is_data_groups(ARRAY[768,1068,1069,2266,2267,769,2237,123456789]);```

FALSE

```SELECT * FROM pmt_is_data_groups(null);```

TRUE

[&larr;  Back to Function List](#function-listing)

## pmt\_isdate

##### Description

Validates a text value for date data type

##### Parameter(s)

1.  (text) – any text value to be tested.

##### Result

True or false.

##### Example(s)

```SELECT pmt_isdate('14-1-2012');```

FALSE

```SELECT pmt_isdate('2012-1-13');```

TRUE

[&larr;  Back to Function List](#function-listing)


## pmt\_isnumeric

##### Description

Validates a text value for numeric data type

##### Parameter(s)

1.  (text) – any text value to be tested.

##### Result

True or false.

##### Example(s)

```SELECT pmt_isnumeric('');```

FALSE

```SELECT pmt_isnumeric(null);```

TRUE

[&larr;  Back to Function List](#function-listing)


## pmt\_locations

##### Description

All information for one or more locations.

##### Parameter(s)

1. location\_ids (character varying) - **Required.** Comma delimited list of location_ids.

##### Result

Json with the following:

1.  id (integer) – location id.
2.  activity\_id (integer) – activity id of location.
3.  boundary\_id (integer) – boundary id of location's associated boundary layer.
4.  feature\_id (integer) – feature id of location's associated boundary feature.
5.  _title (character varying) – title of location.
6.  _description (character varying) – description of location.
7.  _x (numeric) – x coordinate.
8.  _y (numeric) – y coordinate.
9.  _lat_dd (numeric) – latitude decimal degrees.
10. _long_dd (numeric) – longitude decimal degrees.
11. _latlong (character varying) – latitude and longitude.
12. _georef (character varying) – geo-reference format.
13. _updated\_by (character varying(50)) -  last user to update activity information.
14. _updated\_date (timestamp) -  last date and time activity information was updated.
15. _custom\_fields (various) - any custom fields in the activity table that are not in the Core PMT will be returned as well.
16.  taxonomy(object) - An object containing all associated taxonomy for the activity
	1. taxonomy\_id (integer) - taxonomy id.
	2. taxonomy (character varying) - taxonomy name.
	3. classification\_id (integer) - classification id.
	4. classification (character varying) - classification name.
	5. _code (character varying) - classification code.
17.  point (object) - An object containing geoJson representation of the point feature
18.  polygon (object) - An object containing geoJson representation of the associated polygon feature


##### Example(s)

```select * from pmt_locations('79564,39489');```

```
{
	"id":79564
	,"activity_id":80
	,"_title":null
	,"_description":null
	,"_x":1496805
	,"_y":1833818
	,"_lat_dd":16.251080
	,"_long_dd":13.44603
	,"_latlong":"16°15'4\"N 13°26'46\"E"
	,"_georef":"NHPB26461504"
	,"_updated_by":"super"
	,"_updated_date":"2014-05-05 22:40:42.741879"
	,"boundary_id":3,
	,"feature_id":25675,
	,"taxonomy":[
		{
		"taxonomy_id":5
		,"taxonomy":"Country"
		,"classification_id":185
		,"classification":"NIGER"
		,"_code":"NE"
		},{
		"taxonomy_id":25
		,"taxonomy":"Location Class"
		,"classification_id":970
		,"classification":"Administrative Region"
		,"_code":"1"
		},{
		"taxonomy_id":26
		,"taxonomy":"Location Reach"
		,"classification_id":974
		,"classification":"Action/intervention"
		,"_code":"101"
		}]
	,"point":{
		"type":"Point"
		,"coordinates":[13.4460309287303,16.2510804045115]
		}
	,"polygon":{
		"type":"MultiPolygon"
		,"coordinates":[[[
			[15.5595092773437,18.0062866210938],[15.556884765625,17.9564819335938],
			[15.5551147460937,17.9263305664062],[15.5543212890625,17.9204711914062],
			[15.5535278320312,17.9146728515625],[15.5535278320312,17.8839111328125],
			[ (...)]]]"
		}
	
```
[&larr;  Back to Function List](#function-listing)



## pmt\_locations\_for\_boundaries

##### Description

Calculates and returns the counts for activities and locations for all features in a
requested boundary.

##### Parameter(s)

1. boundary\_id (integer) - **Required**. boundary_id of the boundary layer to aggregate location and activity counts to.
2. data\_group\_ids (character varying) - comma seperated list of classification\_id(s) from the Data Group taxonomy
to restrict data aggregation to. If no data group id is provided, all data groups are included.
3. classification\_ids (character varying) - comma seperated list of classification\_id(s) for any taxonomy (filter).
4. org\_ids (character varying) - comma seperated list of organization\_id(s) for any organization regardless of role (filter).
5. imp\_org\_ids (character varying) - comma seperated list of organization\_id(s) for implementing organizations (filter).
6. fund\_org\_ids (character varying) - comma seperated list of organization\_id(s) for funding organizations (filter).
7. start\_date (date) - start date for activities (filter).
8. end\_date (date) - end date for activities (filter).
9. unassigned\_taxonomy\_ids (character varying) - comma seperated list of taxonomy id(s) for any taxonomy, will return activities that _DO NOT_ have that taxonomy assigned (filter).
10. activity\_ids (character varying) - comma seperated list of activity id(s) to restrict data aggregation to.
11. boundary\_filter (json) - a json array of objects. Each object must contain "b" with a boundary id and "ids" with an array of feature ids (i.e. ```[{"b":12,"ids":[2,3]},{"b":13,"ids":[73,85]}]```)

##### Result

Json with the following:

1.  id (integer) – feature\_id of the feature within the requested boundary.
2.  p (integer) - total number of parent activities within feature.
3.  a (integer) – total number of activities within feature.
4.  l (integer) – total number of locations within feature.
5.  b (integer) – boundary\_id of the boundary feature is associated to.


##### Example(s)

-   Aggregate location/activity counts to the continent boundary (boundary\_id: 8) for BMGF data (data\_group\_id: 768)
where Activity Status is Complete (classification\_id: 797) and activities occur between 1/1/2012 and 12/31/2018:

```SELECT * FROM pmt_locations_for_boundaries(8,'768','797',null,null,'1/1/2012','12/31/2018',null,null);```

```
{
	"id":1,
	"p":1,
	"a":1,
	"l":1,
	"b":8
},{
	"id":4,
	"p":3,
	"a":66,
	"l":66,
	"b":8
}

```

-   Aggregate location/activity counts to the UNOCHA administrative level 1 boundary (boundary\_id: 12) for RED&FS data (data\_group\_id: 2237)
where Program is "Stand Alone Project" (classification\_id: 2239) and activities occur between 1/1/2002 and 12/31/2020 within the Oromia region 
(boundary\_id: 12 feature\_id: 8) or in the Majang zone (boundary\_id: 13 feature\_id: 38) within the Gambela region :

```SELECT * FROM pmt_locations_for_boundaries(12,'2237','2239',null,null,'1/1/2002','12/31/2020',null,'[{"b":12,"ids":[8]},{"b":13,"ids":[38]}]');```

```
{
	"id":1,
	"a":3,
	"l":3,
	"b":12
},
...
{
	"id":10,
	"a":15,
	"l":80,
	"b":12
},
{
	"id":11,
	"a":20,
	"l":49,
	"b":12
}

```

[&larr;  Back to Function List](#function-listing)

## pmt\_org\_inuse


##### Description

Organizations participating in activities.

##### Parameter(s)

1.  data\_group\_ids (character varying) – Optional. Classification\_id(s) from the Data
Group taxonomy. Restrict data to data groups(s).
2.  org\_role\_ids (character varying) – Optional. Classification\_id(s) from the Organisation
Role taxonomy. Restrict data to Organisation Role(s).

##### Result

Ordered by most used. Json with the following:

1.  id (integer) – organization id.
2.  n (character varying(255)) – name of organization.
3.  ct (integer) - number of activities organization participates in (can order by ct for most active organizations).
4.  o (character varying(1)) - the first letter of the organization name (can use o for an alphabetical lookup).

##### Example(s)

-   Implementing organizations (classification\_id: 497) participating in activities 
in the BMGF data group (classification\_id:768):

```SELECT * FROM pmt_org_inuse('768','497');```

```
{	"id":270,
	"n":"International Institute of Tropical Agriculture (IITA)",
	"ct":695,
	"o":"i"
}
{
	"id":5,
	"n":"TechnoServe",
	"ct":525,
	"o":"t"
}
{
	"id":22,
	"n":"Agricultural Cooperative Development International and Volunteers in Overseas Cooperative Assistance (ACDI/VOCA)",
	"ct":508,
	"o":"a"
}
...
```

[&larr;  Back to Function List](#function-listing)


## pmt\_orgs

##### Description

Get all organizations.

##### Parameter(s)

No parameters.

##### Result

Json with the following:

1.  id (integer) – id of organization.
2.  _name (character varying) – name of organization.
3.  _label (character varying) - label of organization.

##### Example(s)

```SELECT * FROM pmt_orgs();```

```
...
{
	"id":2071,
	"_name":"Ohio State University (OSU)",
	"_label":"OSU",
	"_url": null
}
...
```

[&larr;  Back to Function List](#function-listing)


## pmt\_overview\_stats


##### Description

Function to calculate overview statistics.

##### Parameter(s)

1. data\_group\_ids (character varying) - comma seperated list of classification\_id(s) from the Data Group taxonomy
to restrict data. If no data group id is provided, all data groups are included (filter).
2. classification\_ids (character varying) - comma seperated list of classification\_id(s) for any taxonomy (filter).
3. start\_date (date) - start date for activities (filter).
4. end\_date (date) - end date for activities (filter).
5. boundary\_id (integer) - the boundary id referenced by the feature\_id (filter).
6. feature\_ids (character varying) - comma seperated list of featuer ids for the boundary to restrict activities to (filter).

##### Result

Json with the following:

1.  activity\_count (integer) - total number of activities
2.  implmenting\_count (integer) - total number of implementing organizations
3.  total\_investment (integer) - total amount of invested money for activities
4.  country\_count (integer) - total number of countries where activities have locations

##### Example(s)

-   Overview statistics for BMGF data (data\_group\_id: 768) in Ethiopia (feature\_id: 74) and Tanzania (feature\_id: 227)
using the GADM boundary (boundary_id: 15):

```SELECT * FROM pmt_overview_stats('768',null,null,null,15,'74,227');```
```
{
	"activity_count":117,
	"implmenting_count":252,
	"total_investment":1576921373.00,
	"country_count":2
}
```

[&larr;  Back to Function List](#function-listing)


## pmt\_partner\_pivot


##### Description

Function to create a filterable pivot table showing organization represation within two taxonomies (row and column) based on a single 
organization role.

##### Parameter(s)

1. row\_taxonomy\_id (integer) - **Required** taxonomy id for taxonomy that will represent rows (y axis of pivot).
2. column\_taxonomy\_id (integer) - **Required** taxonomy id for taxonomy that will represent columns (x axis of pivot).
3. org\_role\_id (integer) - **Required** classification id for the Organisation Role to be used to select participating organizations (table data).
4. data\_group\_ids (character varying) - comma seperated list of classification\_id(s) from the Data Group taxonomy
to restrict data. If no data group id is provided, all data groups are included (filter).
5. classification\_ids (character varying) - comma seperated list of classification\_id(s) for any taxonomy (filter).
6. start\_date (date) - start date for activities (filter).
7. end\_date (date) - end date for activities (filter).
8. boundary\_id (integer) - the boundary id referenced by the feature\_id (filter).
9. feature\_id (integer) - the featuer id to restrict activities to (filter).

##### Result

Json with the following:

1.  c# (character varying) - each object will contain a value for each column in a row numbered 1 - x
2.  f1 (character varying) - organization label
3.  f2 (integer) - organization id
4.  f3 (character varying) organization name

##### Example(s)

-   Partner pivot table data to include only EthATA data (data\_group\_id: 2237) where Program is the row/y-axis (taxonomy id: 68) and 
Crops and Livestock is the column/x-axis  (taxonomy id: 69) and the organizations represented are Funding (classification id: 496) for
activities in the Oromia region (feature\_id: 869) of Ethiopia using GADM boundaries (boundary\_id: 16):

```SELECT * FROM pmt_partner_pivot(68,69,496,'2237',null,null,null,16,896);```
```
{
	"c1":"",
	"c2":"Barley",
	"c3":"Cactus",
	"c4":"Coffee",
	"c5":"Fruit",
	"c6":"Horticulture",
	"c7":"Livestock",
	"c8":"Potato",
	"c9":"Rice",
	"c10":"Sericulture",
	"c11":"Wheat",
	"c12":"Unspecified"
}
{
	"c1":"Agricultural Growth Program",
	"c2":[null],
	"c3":[null],
	"c4":[null],
	"c5":[null],
	"c6":[null],
	"c7":[null],
	"c8":[null],
	"c9":[null],
	"c10":[null],
	"c11":[null],
	"c12":[
		{
			"f1":"CIDA",
			"f2":3135,
			"f3":"Canadian International Development Agency (CIDA)"
		},
		{
			"f1":"Global Agriculture and Food Security Program",
			"f2":2588,
			"f3":"Global Agriculture and Food Security Program"
		}, 
 
		{
			"f1":"GoE",
			"f2":3148,
			"f3":"Government of Ethiopia (GoE)"
		}
	]
},
{
	"c1":"Concern Livlihoods Program",
	"c2":[null],
	"c3":[null],
	"c4":[null],
	"c5":[null],
	"c6":[null],
	"c7":[null],
	"c8":[null],
	"c9":[null],
	"c10":[null],
	"c11":[null],
	"c12":[
		{
			"f1":"Concern Ethiopia",
			"f2":3166,
			"f3":"Concern Ethiopia"
		}, 

		{
			"f1":"EU",
			"f2":1027,
			"f3":"European Union (EU)"
		}, 
 
		{
			"f1":"WRDA",
			"f2":3222,
			"f3":"Wonnta Rural Development Association (WRDA)"
		}
	]
},
{
	"c1":"Food Security Program",
	"c2":[null],
	"c3":[null],
	"c4":[null],
	"c5":[null],
	"c6":[null],
	"c7":[null],
	"c8":[null],
	"c9":[null],
	"c10":[null],
	"c11":[null],
	"c12":[
		{
			"f1":"CIDA",
			"f2":3135,
			"f3":"Canadian International Development Agency (CIDA)"
		}, 
 
		{
			"f1":"DEFID",
			"f2":3170,
			"f3":"DEFID"
		}, 
 
		{
			"f1":"Department of Foreign and International Affairs",
			"f2":3171,
			"f3":"Department of Foreign and International Affairs"
		}
	]
},
{
	"c1":"Stand Alone Project",
	"c2":[
		{
			"f1":"GDC",
			"f2":3149,
			"f3":"German Development Cooperation (GDC)"
		}
	],
	"c3":[
		{
			"f1":"ITAL",
			"f2":3100,
			"f3":"Italian Development Cooperation (ITAL)"
		}
	],
	"c4":[
		{
			"f1":"EU",
			"f2":1027,
			"f3":"European Union (EU)"
		},
		{
			"f1":"ITAL",
			"f2":3100,
			"f3":"Italian Development Cooperation (ITAL)"
		}, 
 
		{
			"f1":"UNDP",
			"f2":3093,
			"f3":"United Nations Development Program (UNDP)"
		}
	],
	"c5":[null],
	"c6":[null],
	"c7":[null],
	"c8":[null],
	"c9":[null],
	"c10":[null],
	"c11":[null],
	"c12":[
		{
			"f1":"ADA",
			"f2":3163,
			"f3":"Austrian Development Agency (ADA)"
		}
	]
```
Results can then be rendered as a table:

||Barley|Cactus|Coffee|Fruit|Horticulture|Livestock|Potato|Rice|Sericulture|Wheat|Unspecified|
|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|
|Agricultural Growth Program|||||||||||CIDA, Global Agriculture and Food Security Program, GoE, Local, NETH, SPAN, undetermined, USAID, WB|
|Food Security Program|||||||||||CIDA, DEFID, Department of Foreign and International Affairs, EC, GoE, IREAID, NETH, SWED, USAID, WB, WFP|
|Sustainable Land Management Program|||||||||||CIDA, DED, EU, FIN, GIZ, IFAD, KFW, MASHAV, WB|
|Stand Alone Project|GDC|ITAL|EU, ITAL, UNDP|ITAL|ITAL|EU, GoE, OCHA, USAID|USAID|CIDA|GoE|GDC, ITAL|ADA, African Development Bank, Belgium Cooperation, Christian Aid, CIDA, DANIDA, Department of Foreign and International Affairs, EU, FIN, GIZ, GoE, IFAD, IIRR, International Rescue Committee, IREAID, ITAL, JICA, Korea, Local, MEDA, NETH|
|Concern Livlihoods Program|||||||||||Concern Ethiopia, EU, WRDA|


[&larr;  Back to Function List](#function-listing)


## pmt\_partner\_sankey


##### Description

Function specifically for reporting data in the D3 Sankey data format using nodes and links 
for the partnerlink tool. Function accepts filtering parameters.

##### Parameter(s)

1. data\_group\_ids (character varying) - comma seperated list of classification\_id(s) from the Data Group taxonomy
to restrict data. If no data group id is provided, all data groups are included.
2. classification\_ids (character varying) - comma seperated list of classification\_id(s) for any taxonomy (filter).
3. org\_ids (character varying) - comma seperated list of organization\_id(s) for organizations for all participation types (filter).
4. start\_date (date) - start date for activities (filter).
5. end\_date (date) - end date for activities (filter).
6. unassigned\_taxonomy\_ids (character varying) - comma seperated list of taxonomy id(s) for any taxonomy, will return activities that _DO NOT_ have that taxonomy assigned (filter).

##### Result

Json with the following:

1.  nodes (object) – Json object.
	1. name (string) - name of organization (_node levels 0-2_) or activity title (_node level 3_).
	2. node (numeric) - unique identifier for node using a numeric pattern. Whole 
number represents the organization\_id and the decimal represents the node level (i.e. 
13.1 is organization\_id 13 at node level 1 (_Grantee_)).
	3. level (integer) - node level (0-3). Each node level represents a participation 
role or the activity: 
		1. 0-Funder (_Organisation Role Accountable_)
		2. 1-Grantee (_Organisation Role Funding_)
		3. 2-Partner (_Organisation Role Implementing_)
		4. 3-Activity
2.  links (object) – Json object.
	1. source (numeric) - the source node id.
	2. source_level (integer) - the source node level.
	3. target (numeric) - the target node id.
	4. target_level (integer) - the target node level.
	5. link (string) - a concatenated text representation of the source/target relationship (source 
node id + \_ + target node id).
	6. value (integer) - count of activities.

##### Example(s)

-   Partner Sankey data to include only BMGF data (data\_group\_id: 768) where the Initative is Research & Development 
(classification\_id: 831) and activities occure between 1/1/2012 and 12/31/2018:

```SELECT * FROM pmt_partner_sankey('768','831',null,'1/1/2012','12/31/2018',null);```
```
{
	"nodes": [{ 
		"name":"Partner Not Reported"
		,"node":3.2
		,"level":2
		},{
		"name":"Kickstart International"
		,"node":10.0
		,"level":0
		},{
		"name":"Kickstart International"
		,"node":10.2
		,"level":2
		},{
		"name":"Bill & Melinda Gates Foundation (BMGF)"
		,"node":13.1
		,"level":1
		},{
		...
		},{
		"name":"GAAP-Kickstart-Impact of Kickstart Treadle Pumps in East Africa"
		,"node":14968.3
		,"level":3
		}],
	"links":[{
		"source":495
		,"source_level":0
		,"target":13.1
		,"target_level":1
		,"link":"495_13.1"
		,"value":584
		},{
		"source":367	
		,"source_level":0
		,"target":13.1	
		,"target_level":1
		,"link":"367_13.1"
		,"value":207
		},{
		"source":1025
		,"source_level":0
		,"target":13.1
		,"target_level":1
		,"link":"1025_13.1"
		,"value":167
		},{
		...
		},{
		"source":1674.2
		,"source_level":2
		,"target":3173.3
		,"target_level":3
		,"link":"1674.2_3173.3"
		,"value":1
		}]
}
```

[&larr;  Back to Function List](#function-listing)



## pmt\_partner\_sankey\_activities


##### Description

Function specifically for requesting applicable activities for a given organization in the 
partnerlink.

##### Parameter(s)

1. data\_group\_ids (character varying) - **Required** comma seperated list of classification\_id(s) from the Data Group taxonomy
to restrict data.
2. organization (character varying) -  **Required** the organization name that is participating in the activities.
3. partnerlink\_level (integer) -  **Required** the partnerlink node level that the organization is in (options: 0,1,2).

##### Result

Json with the following:

1.  activity\_id (integer) – the activity id.
2.  title (character varying) – the activity title


##### Example(s)

-   Activities in the African Development Bank data (data\_group\_id: 2209) where the African Development Fund is in the first node (Funder):

```SELECT * FROM pmt_partner_sankey_activities('2209','African Development Fund',0);```
```
{
	"activity_id":23951,
	"title":"Projet d'appui Ñ la Bonne Gouvernance et Ñ la Decentralisation"
},
{
	"activity_id":23963,
	"title":"Appui Institutionnel  Ñ Quatres MinistÑres"
},
{
	"activity_id":24110,
	"title":"Anyianam-Kumasi Road Rehabilitation Project"
},
...
{
	"activity_id":24520,
	"title":"Strengthening of science and technical teacher of the school of education"
}

```

[&larr;  Back to Function List](#function-listing)


## pmt\_purge\_activities

##### Description

Deletes all records assoicated to an activity, including all **children** activities. **Warning!! 
This function permanently deletes ALL data associated to the given activity ids.** 
Use [pmt\_activate\_activity](#activate_activity) to deactivate if deletion is not desired. 

##### Parameter(s)

1.  a\_id (integer[]) – **Required**. Array of activity ids to be deleted.

##### Result
 
Boolean. True/False successful.

##### Example(s)

-   Remove activity id 101, 102, 103 & 104:

```SELECT * FROM pmt_purge_activities([101,102,103,104]);```

TRUE

[&larr;  Back to Function List](#function-listing)


## pmt\_purge\_activity

##### Description

Deletes all records assoicated to an activity, including all **children** activities. **Warning!! 
This function permanently deletes ALL data associated to the given activity id.** 
Use [pmt\_activate\_activity](#activate_activity) to deactivate if deletion is not desired. 

##### Parameter(s)

1.  id (integer) – **Required**. Id of the activity to be deleted.

##### Result
 
Boolean. True/False successful.

##### Example(s)

-   Remove activity id 101:

```SELECT * FROM pmt_purge_activity(101);```

TRUE

[&larr;  Back to Function List](#function-listing)


## pmt\_refresh\_views

##### Description

Refresh all the materialized views in the database. Materialized views must be refreshed to reflect any updates
to that the source data may have since the last update.

##### Parameter(s)

1. instance\_id (integer) - **Required**. instance id to validate user's authority for.
2. user\_id (integer) - **Required**. user id of user to validate authority for.

##### Result
 
Json with the following:

1. success (boolean) – t/f process was successful.
2. message (character varying) – message containing additional information about success/fail.

##### Example(s)

-   Request to refresh views as sparadee (user\_id: 34) from Ethaim (instance\_id: 1)

```SELECT * FROM pmt_refresh_views(1,34);```

```
{
	"success":true,
	"message":"Success"
}
```

[&larr;  Back to Function List](#function-listing)


## pmt\_roles

##### Description

List of roles

##### Parameter(s)

No parameters.

##### Result
 
Json with the following:

1. id (integer) – the role id.
2. \_name (character varying) – the role name
3. \_active (boolean) - t/f is an active role

##### Example(s)

-   Get all roles.

```SELECT * FROM pmt_roles();```

```
{
	"id":1,
	"_name":"Reader",
	"_active":true
},
{
	"id":2,
	"_name":"Editor",
	"_active":true
}
{
	"id":4,
	"_name":"Administrator",
	"_active":true
},
{
	"id":3,
	"_name":"Super",
	"_active":true
}
```

[&larr;  Back to Function List](#function-listing)


## pmt\_stat\_activity\_by\_tax

##### Description

Statistics function providing filterable investments and activity counts by a taxonomy.

##### Parameter(s)

1.  taxonomy\_id (integer) – **Required**. the taxonomy id to classify returned activity investments and counts.
2. data\_group\_ids (character varying) - comma seperated list of classification id(s) from the Data Group taxonomy
to restrict data. If no data group id is provided, all data groups are included.
3. classification\_ids (character varying) - comma seperated list of classification id(s) for any taxonomy (filter).
4. start\_date (date) - start date for activities (filter).
5. end\_date (date) - end date for activities (filter).
6. boundary\_id (integer) - the boundary id referenced by the feature\_id (filter).
7. feature\_id (integer) - the feature id to restrict activities to (filter).
8. record\_limit (integer) - the number of records to limit return to, remaining classifications will be aggregated into an "other" classification.
9. filter\_classification\_ids (character varying) - comma seperated list of classification ids for provided taxonomy id to restrict returned values to.

##### Result

Json with the following:

1.  id (integer) – the classification id for the given taxonomy.
2.  classification (character varying) - the classification name for the given taxonomy.
3.  count (integer) - the number of activities assigned to the classification.
4.  sum (numeric) - the investment for the assigned classification.

##### Example(s)

-   Activity investments and counts for all of BMGF (data\_group\_id:768) for the
    Initiative taxonomy (taxonomy\_id:23) in Ethiopia (feature\_id: 74) using GADM 
boundary (boundary\_id: 15):

```SELECT * FROM pmt_stat_activity_by_tax(23,'768',null,null,null,15,74,null);```

```
{
	"classification_id":831,
	"classification":"Research & Development",
	"count":57,
	"sum":100000.00
},
{
	"classification_id":null,
	"classification":"Unspecified",
	"count":2146,
	"sum":500000.00
},
{
	"classification_id":2213,
	"classification":"Country & Policy",
	"count":2,
	"sum":null
},
{
	"classification_id":2212,
	"classification":"Farmer Systems & Services",
	"count":389,
	"sum":null
},
{	
	"classification_id":829,
	"classification":"Other",
	"count":1,
	"sum":null
}

```

[&larr;  Back to Function List](#function-listing)


## pmt\_stat_by\_org


##### Description

Statistics function providing filterable activity counts by organization and role, ordered by greatest activity count.

##### Parameter(s)

1. data\_group\_ids (character varying) - comma seperated list of classification id(s) from the Data Group taxonomy
to restrict data. If no data group id is provided, all data groups are included.
2. classification\_ids (character varying) - comma seperated list of classification id(s) for any taxonomy (filter).
3. start\_date (date) - start date for activities (filter).
4. end\_date (date) - end date for activities (filter).
5. org\_role\_id (integer) - the organization role to filter data to (filter).
6. boundary\_id (integer) - the boundary id referenced by the feature\_id (filter).
7. feature\_id (integer) - the featuer id to restrict activities to (filter).
8. limit\_records (integer) - number of records to return.


##### Result

Json with the following:

1.  id (integer) – the organization id.
2.  name (character varying) – the organization name.
3.  label (character varying) – the organization name's abbreviation or shortened name.
4.  role (character varying) – the organization's role.
5.  activity\_count (integer) – the number of activities the organization is involved in.

##### Example(s)

-   Top 5 implmenting (org\_role\_id: 497) organizations for BMGF & AGRA data groups (data\_group\_id: 769,768)
in Ethiopia (feature\_id: 74) using GADM boundary (boundary\_id: 15):

```SELECT * FROM pmt_stat_by_org('769,768',null,null,null,497,15,74,5);```

```
{
	"id":9,
	"name":"United Nations Food and Agriculture Organization (FAO)",
	"label":"FAO",
	"role":"Implementing",
	"activity_count":16
},
{
	"id":12,
	"name":"U.S. Agency for International Development (USAID)",
	"label":"USAID",
	"role":"Implementing",
	"activity_count":1
},
{
	"id":22,
	"name":"Agricultural Cooperative Development International and Volunteers in Overseas Cooperative Assistance (ACDI/VOCA)",
	"label":"ACDI/VOCA",
	"role":"Implementing",
	"activity_count":6
},
{
	"id":221,
	"name":"Kenya Agricultural Research Institute (KARI)",
	"label":"KARI",
	"role":"Implementing",
	"activity_count":1
},
{
	"id":270,
	"name":"International Institute of Tropical Agriculture (IITA)",
	"label":"IITA",
	"role":"Implementing",
	"activity_count":1
}


```

[&larr;  Back to Function List](#function-listing)


## pmt\_stat\_invest\_by\_funder


##### Description

Statistics function providing filterable investments by funding organization, ordered by greatest investment amount.

##### Parameter(s)

1. data\_group\_ids (character varying) - comma seperated list of classification id(s) from the Data Group taxonomy
to restrict data. If no data group id is provided, all data groups are included.
2. classification\_ids (character varying) - comma seperated list of classification id(s) for any taxonomy (filter).
3. start\_date (date) - start date for activities (filter).
4. end\_date (date) - end date for activities (filter).
6. boundary\_id (integer) - the boundary id referenced by the feature\_id (filter).
7. feature\_id (integer) - the featuer id to restrict activities to (filter).
8. limit\_records (integer) - number of records to return.


##### Result

Json with the following:

1.  id (integer) – the funding organization id.
2.  name (character varying) – the funding organization name.
3.  label (character varying) – the funding organization name's abbreviation or shortened name.
4.  count (integer) – the number of activities funded by the organization.
5.  sum (numeric) – the total amount invested by the funding organization.
6.  a\_ids (integer[]) - a list of activity ids funded by organization.

##### Example(s)

-   Top 5 investments by funding organization for EthATA data group (data\_group\_id:2237)
in Ethiopia (feature\_id: 74) using GADM boundary (boundary\_id: 15):

```SELECT * FROM pmt_stat_invest_by_funder('2237',null,null,null,15,74,5);```

```
{
	"id":3112,
	"name":"World Bank (WB)",
	"label":"WB",
	"count":10,
	"sum":1030620000.00,
	"a_ids":[26271,26283,26284,26286,26287,26288,26322,26323,26324,26325]
},
{
	"id":3073,
	"name":"United States Agency for International Development (USAID)",
	"label":"USAID",
	"count":22,
	"sum":751774975.00,
	"a_ids":[26284,26285,26287,26303,26304,26305,26306,26307,26308,26309,26310,26311,26312,26313,26314,26315,26316,26317,26318,26319,26320,26321]
},
{
	"id":3175,
	"name":"European Commission (EC)",
	"label":"EC",
	"count":1,
	"sum":360000000.00,
	"a_ids":[26284]
},
{
	"id":3135,
	"name":"Canadian International Development Agency (CIDA)",
	"label":"CIDA",
	"count":20,
	"sum":309649285.00,
	"a_ids":[26200,26201,26202,26203,26204,26205,26206,26207,26208,26209,26210,26211,26212,26280,26283,26284,26285,26287,26326]
},
{
	"id":3170,
	"name":"DEFID",
	"label":"DEFID",
	"count":1,"sum":282300000.00,
	"a_ids":[26284]
}


```

[&larr;  Back to Function List](#function-listing)


## pmt\_statistic\_data


##### Description

Provides statistics for a given indicator.

##### Parameter(s)

1.  indicator\_id (integer) – **Required**. Id for the target indicator found in stats\_metadata.
2.  code (character varying) – Optional. Restrict data to a specific country (ISO 3 digit codes).

##### Result

Json with the following:

1. indicator (character varying) – the name of the requested indicator.
2. boundary (character varying) – the name of the boundary for which the statistics apply.
3. _2000 (numeric) - the statistic value for the year 2000.
4. _2001 (numeric) - the statistic value for the year 2001.
5. _2002 (numeric) - the statistic value for the year 2002.
6. _2003 (numeric) - the statistic value for the year 2003.
7. _2004 (numeric) - the statistic value for the year 2004.
8. _2005 (numeric) - the statistic value for the year 2005.
9. _2006 (numeric) - the statistic value for the year 2006.
10. _2007 (numeric) - the statistic value for the year 2007.
11. _2008 (numeric) - the statistic value for the year 2008.
12. _2009 (numeric) - the statistic value for the year 2009.
13. _2010 (numeric) - the statistic value for the year 2010.
14. _2011 (numeric) - the statistic value for the year 2011.
15. _2012 (numeric) - the statistic value for the year 2012.
16. _2013 (numeric) - the statistic value for the year 2013.
17. _2014 (numeric) - the statistic value for the year 2014.
18. _2015 (numeric) - the statistic value for the year 2015.
19. _2016 (numeric) - the statistic value for the year 2016.

##### Example(s)

-  Poverty gap at $1.90 a day (2011 PPP) (%) (indicator\_id:1733) for Tanzania (code: TZA):

```SELECT * FROM pmt_statistic_data(1733,'TZA');```

```
{
	"indicator":"Poverty gap at $1.90 a day (2011 PPP) (%)",
	"boundary":"Tanzania",
	"_2000":44.54,
	"_2001":null,
	"_2002":null,
	"_2003":null,
	"_2004":null,
	"_2005":null,
	"_2006":null,
	"_2007":18.95,
	"_2008":null,
	"_2009":null,
	"_2010":null,
	"_2011":14.35,
	"_2012":null,
	"_2013":null,
	"_2014":null,
	"_2015":null,
	"_2016":null
}
```

[&larr;  Back to Function List](#function-listing)


## pmt\_statistic\_indicators


##### Description

Lists available statistic indicators.

##### Parameter(s)

1.  code (character varying) – Optional. Restrict data to a specific country (ISO 3 digit codes).

##### Result

Json with the following:

1. _category (character varying) – the category for the indicator.
2. _sub_categories (json[]) – object array containing sub categories
	1. _sub_category (character varying) – name of the sub category
	2. indicators (json[]) – object array of indicators
		1. id (integer) - the indicator id
		2. _name (character varying) - the name of the indicator

##### Example(s)

-  Get all statistic indicators for Kenya (code: KEN):

```SELECT * pmt_statistic_indicators('KEN');```

```
{
	"_category":"Private Sector & Trade",
	"sub_categories":[
		{
			"_sub_category":"Tariffs",
			"indicators":[
				{
					"id":3028,
					"_name":"Share of tariff lines with international peaks, all products (%)"
				},
				{
					"id":3027,
					"_name":"Bound rate, simple mean, all products (%)"
				},
				...
				{
					"id":1641,
					"_name":"Share of tariff lines with international peaks, all products (%)"
				}
			]
		},
		...
		{
			"_sub_category":"Exports",
			"indicators":[
				{
					"id":3081,
					"_name":"Merchandise exports to developing economies in Europe & Central Asia (% of total merchandise exports)"
				},
				{
					"id":3071,
					"_name":"Fuel exports (% of merchandise exports)"
				}
				...
			]
		}
	]	
}
...
{
	"_category":"Poverty",
	"sub_categories":[
		{
			"_sub_category":"Conflict & fragility"
			,"indicators":[
				{
					"id":1717,
					"_name":"Combined polity score"
				}
				...
			]
		}
	]	
}
		
```

[&larr;  Back to Function List](#function-listing)


## pmt\_taxonomies

##### Description

Listing of taxonomies, filterable by instance and "core" taxonomies.

##### Parameter(s)

1.  instance\_id (instance) – Optional. Instance id of the instance to restrict return data to instance owned taxonomy(ies) (editable taxonomies for given instance).
2.  return\_core (boolean) - Optional. t/f return core taxonomies (not editable by any instance). Default is false.

##### Result

Json with the following:

1.  id (integer) – taxonomy id.
2.  _name (character varying(255)) – name of taxonomy.
3. _description (character varying) -  description for taxonomy.
4. _iati_codelist (character varying(100)) - the codelist name for IATI taxonomies.
5. parent_id (integer) - id of the parent taxonomy.
6. _is_category (boolean) - t/f the taxonomy is a parent or category taxonomy.
7. _core (boolean) - t/f the taxonomy is a "core" taxonomy to the PMT and cannot be edited by the application.
8. data_group_ids (integer[]) - data group ids that "own" the taxonomy, if NULL then taxonomy is not editable.

##### Example(s)

-   Get taxonomies for the EthAIM instance (instance\_id:1), excluding core taxonomies :

```SELECT * FROM pmt_taxonomies(1,false);```

```
...
{
	"id":77,
	"_name":"GTP2 Strategic Objective",
	"_description":null,
	"_iati_codelist":null,
	"parent_id":null,
	"_is_category":true,
	"_active":true,
	"_retired_by":null,
	"_created_by":"OMK & ONA Import 2017",
	"_created_date":"2018-06-18 00:00:00",
	"_updated_by":"ds_eth10.13",
	"_updated_date":"2018-06-18 00:00:00"
}
...
```

[&larr;  Back to Function List](#function-listing)


## pmt\_taxonomy\_count

##### Description

Count of taxonomies, filterable by search text and taxonomy id.

##### Parameter(s)

1.  instance\_id (instance) – **Required**. Instance id of the instance to restrict return data to instance owned taxonomy(ies) (editable taxonomies for given instance).
2.  search\_text (text) – Optional. Search text to restrict taxonomies by. Searches taxonony and classification _name.
3.  exclude\_ids (character varying) - Optional. Comma delimited listing of taxonomy ids to exclude from returned results.
4.  return\_core (boolean) - Optional. t/f return core taxonomies (not editable by any instance). Default is false.

##### Result

Json with the following:

1.  count (integer) – number of taxonomies that meet the critieria.

##### Example(s)

-   Get number of taxonomies for the EthAIM instance (instance\_id:1), excluding core taxonomies (not editable) where "org" is found in either the taxonomy or classification name:

```SELECT * FROM pmt_taxonomy_count(1,'org',null,false);```

```
{
	"count": 2
}
```

-   Get number of taxonomies for the EthAIM instance (instance\_id:1), including core taxonomies (not editable) except for the Country taxonomy (taxonomy\id: 5):

```SELECT * FROM pmt_taxonomy_count(1,null,'5',true);```

```
{
	"count": 38
}
```

[&larr;  Back to Function List](#function-listing)

## pmt\_taxonomy\_search

##### Description

Listing of taxonomies, filterable by search text and taxonomy id, excluding all child taxonomies (which are linked through the parent taxonomies).

##### Parameter(s)

1.  instance\_id (instance) – Optional. Instance id of the instance to restrict return data to instance owned taxonomy(ies) (editable taxonomies for given instance).
2.  search\_text (text) – Optional. Search text to restrict taxonomies by. Searches taxonony and classification _name.
3.  offsetter (integer) - Optional. Number of records to offset return by.
4.  limiter (integer) - Optional. Number of records to limit return by.
5.  return\_core (boolean) - Optional. t/f return core taxonomies (not editable by any instance). Default is false.

##### Result

Json with the following:

1.  id (integer) – taxonomy id.
2.  _name (character varying(255)) – name of taxonomy.
3. _description (character varying) -  description for taxonomy.
4. _iati_codelist (character varying(100)) - the codelist name for IATI taxonomies.
5. parent_id (integer) - id of the parent taxonomy.
6. _is_category (boolean) - t/f the taxonomy is a parent or category taxonomy.
7. _core (boolean) - t/f the taxonomy is a "core" taxonomy to the PMT and cannot be edited by the application.
8. data_group_ids (integer[]) - data group ids that "own" the taxonomy, if NULL then taxonomy is not editable.

##### Example(s)

-   Get taxonomies for the EthAIM instance (instance\_id:1), excluding core taxonomies (not editable) where "org" is found in either the taxonomy or classification name
and limit return to the first 10 records:

```SELECT * FROM pmt_taxonomy_search(1,'org',0,10,false);```

```
{
	"id":11,
	"_name":"Organisation Type",
	"_description":"IATI Standards. The IATI codelists ensure activity and organisation information is comparable between different publishers.",
	"_iati_codelist":"OrganisationType",
	"parent_id":null,
	"_is_category":false,
	"_active":true,
	"_retired_by":null,
	"_created_by":"OMK & ONA Import 2017",
	"_created_date":"2018-06-18 00:00:00",
	"_updated_by":"ds_eth10.13",
	"_updated_date":"2018-06-18 00:00:00",
	"child_id":null
},
{
	"id":69,
	"_name":"Focus Crop Categories",
	"_description":"Ethiopia ATA Taxonomy.",
	"_iati_codelist":null,
	"parent_id":80,
	"_is_category":false,
	"_active":true,
	"_retired_by":null,
	"_created_by":"ds_pmt10.5",
	"_created_date":"2016-01-21 00:00:00",
	"_updated_by":"OMK & ONA Import 2017",
	"_updated_date":"2018-06-18 00:00:00",
	"child_id": 79
}
```

-   Get taxonomies for the EthAIM instance (instance\_id:1), including core taxonomies (not editable) and limit return to the records 5-10:

```SELECT * FROM pmt_taxonomy_search(1,null,5,5,true);```

```
...
{
	"id":13,
	"_name":"Result Type",
	"_description":"IATI Standards. The IATI codelists ensure activity and organisation information is comparable between different publishers.",
	"_iati_codelist":"ResultType",
	"parent_id":null,
	"_is_category":false,
	"_active":true,
	"_created_by":"IATI XML Import",
	"_created_date":"2014-01-28 00:00:00",
	"_updated_by":"IATI XML Import",
	"_updated_date":"2018-08-08 00:00:00",
	"child_id":null
}
...
```

[&larr;  Back to Function List](#function-listing)

## pmt\_update\_crosswalks

##### Description

Remove and recreate activity taxonomy crosswalk data for a data group.

##### Parameter(s)

1.  data\_group\_id (integer) - **Required**. Classification id from the Data Group taxonomy.

##### Result

Success boolean (True/False).

##### Example(s)

- Update the crosswalk data for the BMGF data group (data\_group\_id: 768).

```SELECT * FROM pmt_update_crosswalks(768);```

```
TRUE
```

[&larr;  Back to Function List](#function-listing)


## pmt\_update\_location\_boundaries

##### Description

Recalculates the intersected boundaries for location(s) when no record field changes are needed. This functionality is typically performed
by the trigger on the location table when a location record is update, however when a boundary or a boundary feature changes the locations
intersected need to be recalculted. This function provides that mechanism outside the trigger.

##### Parameter(s)

1.  l\_ids (integer[]) – **Required**. Array of location ids to recalculate.

##### Result
 
Boolean. True/False successful.

##### Example(s)

-   Recalcuate boundary intersections for the following locations: 23412,33453,98730

```SELECT * FROM pmt_update_location_boundries([23412,33453,98730]);```

TRUE

[&larr;  Back to Function List](#function-listing)


## pmt\_user\_auth

##### Description

Authenticate user.

##### Parameter(s)

1.  username (character varying) - **Required**. User's username.
2.  password (character varying) - **Required**. User's password.
3.  instance\_id (integer) - **Required**. The instance user is requesting access to.

##### Result

Json with the following:

1.  user\_id (integer) – user id.
2.  first\_name (character varying) – first name of user.
3.  last\_name (character varying) – last name of user.
4.  username (character varying) – username of user.
5.  email (character varying) – email address of user.
6.  organization\_id (integer) – organization id for organization of user.
7.  organization (character varying) – organization name for organization of user.
8.  role\_id (integer) – database role id user is assigned to.
9.  role (character varying) – name of database role user is assigned to.
7.  authorizations (integer[]) – array of activity\_ids user is authorized for. If user has the "Super" or "Administrator" role, all activities for the instances data group are authorized.

##### Example(s)

- Authenticate johndoe for the SpatialDev instance (instance\_id: 1).

```SELECT * FROM pmt_user_auth('johndoe', 'password',1);```

```
{
	"id":1,
	"_first_name":"John",
	"_last_name":"Doe",
	"_username":"johndoe",
	"_email":"test@email.com",
	"organization_id":3,
	"organization":"Spatial Development International, LLC (SpatialDev)",
	"role_id":2,
	"role":"Editor",
	"role_auth":
	{
		"_read":true,
		"_create":true,
		"_update":true,
		"_delete":false,
		"_super":true,
		"_security":false
	},
	"authorizations":[23345,23367,23388,23389]
}
```
- Authenticate Reader test user passing its username and an invalid password.

```SELECT * FROM pmt_user_auth('reader', 'bad password', 1);```

```
{
	"message":"Invalid username or password."
}
```

[&larr;  Back to Function List](#function-listing)


## pmt\_user\_orgs

##### Description

Get all organizations for a given instance. Returns only organizations that are in use by the instance users or Accountable organizations
for the instance's data group(s).

##### Parameter(s)

1. instance\_id (integer) - **Required**. id of instance to filter organizations to.

##### Result

Json with the following:

1.  id (integer) – organization id.
2.  \_name (character varying) – organization name.

##### Example(s)

- Request all organizations for the users and data groups for the EthAIM instance (instance\_id: 2):

```SELECT * FROM pmt_user_orgs(2);```

```
{
	"id":3263,
	"_name":"Aarhus University (AU)"
},
{
	"id":2121,
	"_name":"Abt Associates, Inc."
}
...
{
	"id":3112,
	"_name":"World Bank (WB)"
}
```

[&larr;  Back to Function List](#function-listing)


## pmt\_user\_salt

##### Description

Get the salt for a specific user.

##### Parameter(s)

1.  username (text)– **Required**. Username for requested salt value.

##### Result

Salt value as text. 

##### Example(s)

-   Salt value for test user Reader(johndoe):

```select * from pmt_user_salt('johndoe');```

```
$2a$10$.V0ETMIAW6O9z2wekwMG1.
```

[&larr;  Back to Function List](#function-listing)


## pmt\_users

##### Description

Get all user and role information for the entire database OR a single instance. This is an overloaded method.

##### Parameter(s)

No parameters.

OR 

1. instance\_id (integer) - **Required**. id of instance to filter users to. Only users with access to instance will be returned. 

##### Results

Json with the following with **NO PARAMETERS**:

1.  id (integer) – user id.
2.  \_first\_name (character varying) – first name of user.
3.  \_last\_name (character varying) – last name of user.
4.  \_username (character varying) – username of user.
5.  \_email (character varying) – email address of user.
6.  \_phone (character varying) - phone number of user.
7.  organization\_id (integer) – organization id for organization of user.
8.  organization (character varying) – organization name for organization of user.
9.  instances (json[]) - object containing instance information user has access to
    a. instance\_id (integer) - the instance id.
	b. instance (character varying) - the theme name of the instance
    c. role\_id (integer) - the role id.
	d. role (character varying) - the name of the role.
10.  \_access\_date (timestamp without time zone) - most recent user login timestamp.
12. \_active (boolean) - t/f user account is active.

Json with the following **WITH PARAMETERS**:

1.  id (integer) – user id.
2.  \_first\_name (character varying) – first name of user.
3.  \_last\_name (character varying) – last name of user.
4.  \_username (character varying) – username of user.
5.  \_email (character varying) – email address of user.
6.  \_phone (character varying) - phone number of user.
7.  organization\_id (integer) – organization id for organization of user.
8.  organization (character varying) – organization name for organization of user.
9.  role\_id (integer) - the role id.
10.  role (character varying) - the name of the role.
11. authorizations (json) - object containing the user's authorization for the instance. _Note: Only editors require authorizations. Administrators and Super roles automatically are granted access to all activities on a given instance, and Readers do not have any access_
	a. activity\_ids (integer[]) - array of activity ids user has access to edit
	b. classification\_ids (integer[]) - array of classification ids. Activities assigned to these ids are editable by user.
12. classifications (json[]) - array of taxonomy information for the user's authorization by taxonomy.
    a. t (character varying) - the taxonomy name for authorized classifications
	b. t_id (integer) - the taxonomy id for authorized classifications
	c. c (json[]) - array of classification information for each classification user is authorized for
		i. c (character varying) - the classification name
		ii. c_id (integer) - the classification id
13. \_access\_date (timestamp without time zone) - most recent user login timestamp.
14. \_active (boolean) - t/f user account is active.

##### Example(s)

- Get all users:

```SELECT * FROM pmt_users();```

```
...
{
	"id":315,
	"_first_name":"Jane",
	"_last_name":"Doe",
	"_username":"myusername",
	"_email":"jane.doe@email.com",
	"_phone":"123-456-7890",
	"organization_id":13,
	"organization": "BMGF",
	"instances":[
		"instance_id": 2,
		"instance": "bmgf",
		"role_id": 2,
		"role": "Editor"
	],
	"_access_date": "2014-05-21T23:29:27.497825",
	"_active":true
}
...
```

- Get all users in the EthAIM instance (instance\_id: 2):

```SELECT * FROM pmt_users(2);```

```
...
{
	"id":315,
	"_first_name":"Jane",
	"_last_name":"Doe",
	"_username":"myusername",
	"_email":"jane.doe@email.com",
	"_phone":"123-456-7890",
	"organization_id":13,
	"organization": "BMGF",
	"role_id": 2,
	"role": "Editor",
	"authorizations":
		{
			"activity_ids":[27252,27252,22610,27631,25502,25461,25514],
			"classification_ids":[1081,1076]
		},
	"classifications":[
		{
			"t":"Program"
			"t_id":68,
			"c":[
				{
					"c":"Food Security Program",
					"c_id": 2240
				},
				{
					"c":"Agricultural Growth Program",
					"c_id": 2241
				}
			]
		}
	]
	"_access_date": "2014-05-21T23:29:27.497825",
	"_active":true
}
...
```

[&larr;  Back to Function List](#function-listing)


## pmt\_validate\_activities

##### Description

Validate list of activity ids.

##### Parameter(s)

1. activity\_ids (character varying) - **Required**. comma separated list of activity ids to validate.

##### Result

Integer array of valid ACTIVE activity ids.

##### Example(s)

```SELECT * FROM pmt_validate_activities('11879,15432,15725,122');```

| integer[]   |
|-------------|
| {11879,15432,15725}|

[&larr;  Back to Function List](#function-listing)


## pmt\_validate\_activity

##### Description

Validate an activity id.

##### Parameter(s)

1. id (integer) - **Required**. activity id to validate.

##### Result

Boolean. True/False valid.

##### Example(s)

```SELECT * FROM pmt_validate_activity(11879);```

TRUE

[&larr;  Back to Function List](#function-listing)


## pmt\_validate\_boundary\_feature

##### Description

Validate an boundary\_id and feature\_id combination.

##### Parameter(s)

1. boundary\_id (integer) - **Required**. boundary\_id to validate.
1. feature\_id (integer) - **Required**. feature\_id to validate.

##### Result

Boolean. True/False valid.

##### Example(s)

```SELECT * FROM pmt_validate_boundary_feature(1, 23);```

TRUE

[&larr;  Back to Function List](#function-listing)


## pmt\_validate\_classification


##### Description

Validate a classification id.

##### Parameter(s)

1. classification\_id (integer) - **Required**. classification id to validate.

##### Result

Boolean. True/False valid.

##### Example(s)

```SELECT * FROM pmt_validate_classification(768);```

TRUE

[&larr;  Back to Function List](#function-listing)


## pmt\_validate\_classifications


##### Description

Validate list of classification ids.

##### Parameter(s)

1. classification\_ids (character varying) - **Required**. comma separated list of classification ids to validate.

##### Result

Integer array of valid ACTIVE classification ids in ascending order.

##### Example(s)

```SELECT * FROM pmt_validate_classifications('50,9999,720');```

| integer[]   |
|-------------|
| {50,720}|

[&larr;  Back to Function List](#function-listing)


## pmt\_validate\_contact

##### Description

Validate a contact\_id.

##### Parameter(s)

1. contact\_id (integer) -  **Required**. contact_id to validate.

##### Result

Boolean. True/False valid.

##### Example(s)

```SELECT * FROM pmt_validate_contact(169);```

TRUE

[&larr;  Back to Function List](#function-listing)


## pmt\_validate\_contacts

##### Description

Validate list of contact\_ids.

##### Parameter(s)

1. contact\_ids (character varying) - **Required**. comma separated list of contact_ids to validate.

##### Result

Integer array of valid ACTIVE contact_ids.

##### Example(s)

```SELECT * FROM pmt_validate_contacts('169,145,9999');```

| integer[]   |
|-------------|
| {145,169}|

[&larr;  Back to Function List](#function-listing)


## pmt\_validate\_detail

##### Description

Validate a detail\_id.

##### Parameter(s)

1. detail\_id (integer) -  **Required**. detail_id to validate.

##### Result

Boolean. True/False valid.

##### Example(s)

```SELECT * FROM pmt_validate_detail(169);```

TRUE

[&larr;  Back to Function List](#function-listing)


## pmt\_validate\_details

##### Description

Validate an array of detail ids.

##### Parameter(s)

1. detail\_ids (character varying) -  **Required**. comma delimited list of detail ids to validate.

##### Result

Array of valid ACTIVE detail ids.

##### Example(s)

```SELECT * FROM pmt_validate_details('156,169,171,26373');```

| integer[]   |
|-------------|
| {156,169,171}	  |

[&larr;  Back to Function List](#function-listing)


## pmt\_validate\_financial

##### Description

Validate a financial id.

##### Parameter(s)

1. id (integer) -  **Required**. financial id to validate.

##### Result

Boolean. True/False valid.

##### Example(s)

```SELECT * FROM pmt_validate_financial(19);```

TRUE

[&larr;  Back to Function List](#function-listing)


## pmt\_validate\_financials

##### Description

Validate an array of financial ids.

##### Parameter(s)

1. financial\_ids (character varying) -  **Required**. comma delimited list of financial ids to validate.

##### Result

Array of valid ACTIVE financial ids.

##### Example(s)

```SELECT * FROM pmt_validate_financials('9999999,26371,26372,26373,26374');```

| integer[]   |
|-------------|
| {26371,26372,26373,26374}	  |

[&larr;  Back to Function List](#function-listing)


## pmt\_validate\_location

##### Description

Validate a location\_id.

##### Parameter(s)

1. location\_id (integer) -  **Required**. location_id to validate.

##### Result

Boolean. True/False valid.

##### Example(s)

```SELECT * FROM pmt_validate_location(19);```

TRUE

[&larr;  Back to Function List](#function-listing)

## pmt\_validate\_locations

##### Description

Validate list of location\_ids.

##### Parameter(s)

1. location\_ids (character varying) - **Required**  Comma separated list of location_ids to validate.

##### Result

Integer array of valid ACTIVE location_ids.

##### Example(s)

```SELECT * FROM pmt_validate_locations('9,12,15');```

| integer[]   |
|-------------|
| {9,12,15}|

[&larr;  Back to Function List](#function-listing)


## pmt\_validate\_organization

##### Description

Validate a organization id.

##### Parameter(s)

1. organization\_id (integer) - **Required**. organization id to validate.

##### Result

Boolean. True/False valid.

##### Example(s)

```SELECT * FROM pmt_validate_organization(13);```

TRUE

[&larr;  Back to Function List](#function-listing)


## pmt\_validate\_organizations

##### Description

Validate list of organization\_ids.

##### Parameter(s)

1. organization\_ids (character varying) - **Required**  Comma separated list of organization_ids to validate.

##### Result

Integer array of valid ACTIVE organization_ids.

##### Example(s)

```SELECT * FROM pmt_validate_organizations('13,27,2');```

| integer[]   |
|-------------|
| {13,27}|

[&larr;  Back to Function List](#function-listing)


## pmt\_validate\_participation

##### Description

Validate a participation id.

##### Parameter(s)

1. id (integer) - **Required**. participation id to validate.

##### Result

Boolean. True/False valid.

##### Example(s)

```SELECT * FROM pmt_validate_participation(57789);```

TRUE

[&larr;  Back to Function List](#function-listing)


## pmt\_validate\_participations

##### Description

Validate list of participation\_ids.

##### Parameter(s)

1. participation\_ids (character varying) - **Required**. comma separated list of participation_ids to validate.

##### Result

Integer array of valid ACTIVE participation_ids.

##### Example(s)

```SELECT * FROM pmt_validate_participations('18416,57789,34331,2');```

| integer[]   |
|-------------|
| {2,57789}   |

[&larr;  Back to Function List](#function-listing)


## pmt\_validate\_role

##### Description

Validate an role\_id.

##### Parameter(s)

1. role\_id (integer) - **Required**. role_id to validate.

##### Result

Boolean. True/False valid.

##### Example(s)

```SELECT * FROM pmt_validate_role(1);```

TRUE

[&larr;  Back to Function List](#function-listing)


## pmt\_validate\_taxonomies

##### Description

Validate list of taxonomy ids.

##### Parameter(s)

1. ids (character varying) - **Required**. comma separated list of taxonomy ids to validate.

##### Result

Integer array of valid ACTIVE taxonomy ids.

##### Example(s)

```SELECT * FROM pmt_validate_taxonomies('5,10,99');```

| integer[]   |
|-------------|
| {5,10}	  |

[&larr;  Back to Function List](#function-listing)


## pmt\_validate\_taxonomy

##### Description

Validate a taxonomy id.

##### Parameter(s)

1. id (integer) - **Required**. taxonomy id to validate.

##### Result

Boolean. True/False valid.

##### Example(s)

```SELECT * FROM pmt_validate_taxonomy(1);```

TRUE

[&larr;  Back to Function List](#function-listing)

## [pmt\_taxonomy]
##### Description

Return a list of taxonomies

##### Parameter(s)

1. instance\_id (integer) - **Required**. instance id in which the requesting edit originates.                     
2. core (boolean) - optional, defaults to false. Inclused core taxonomies or not.

##### Result

Json with all the columns in the Taxomomy table that match the Instance Id :
[{
    "response": {
        "id": 47,
        "_name": "Category",
        "_description": "Tan-AIM taxonomy.",
        "_iati_codelist": null,
        "parent_id": null,
        "_is_category": false,
        "_active": true,
        "_retired_by": null,
        "_created_by": "Tan-AIM Data Load",
        "_created_date": "2013-12-17 00:00:00",
        "_updated_by": "Tan-AIM Data Load",
        "_updated_date": "2018-06-18 00:00:00",
        "_core": false,
        "data_group_ids": [1068,1069,2266,2267]
    }
}]    

##### Example(s)

```SELECT * FROM pmt_validate_user(2,false);```

```
{
    "id": 47,
    "_name": "Category",
    "_description": "Tan-AIM taxonomy.",
    "_iati_codelist": null,
    "parent_id": null,
    "_is_category": false,
    "_active": true,
    "_retired_by": null,
    "_created_by": "Tan-AIM Data Load",
    "_created_date": "2013-12-17 00:00:00",
    "_updated_by": "Tan-AIM Data Load",
    "_updated_date": "2018-06-18 00:00:00",
    "_core": false,
    "data_group_ids": [1068,1069,2266,2267]
}
```

[&larr;  Back to Function List](#function-listing)

## pmt\_validate\_user

##### Description

Validate an user\_id.

##### Parameter(s)

1. user\_id (integer) - **Required**. user_id to validate.

##### Result

Boolean. True/False valid.

##### Example(s)

```SELECT * FROM pmt_validate_user(1);```

TRUE

[&larr;  Back to Function List](#function-listing)


## pmt\_validate\_user\_authority

##### Description

Validate a user's authority on an activity and the level of authority (CRUD).

##### Parameter(s)

1. instance\_id (integer) - **Required**. instance id to validate user's authority for.
2. user\_id (integer) - **Required**. user id of user to validate authority for.
3. activity\_id (integer) - **Required for auth types: read, update, delete**. activity id to validate authority for user to edit.
4. data\_group\_id (integer) - **Required for auth types: create**. data group id to validate authority for user to create activity in.
5. auth\_type (enum) - **Required**. authority type.
	Options:
	1. create - user has ability to create new records.
	2. read - user has ability to read records.
	3. update - user has ability to update existing records.
	4. delete - user has ability to delete records.

##### Result

Boolean. True/False user has authority on activity with authority type.

##### Example(s)

- User sparadee (user\_id: 34) has authority to update activity id 34 on EthAIM instance (instance\_id: 1):

```select * from pmt_validate_user_authority(1, 34, 422, null, 'update');```

TRUE

- User sparadee (user\_id: 34) has authority to create a new activity in the RED&FS data group (data\_group\_id: 2237) 
in EthAIM instance (instance\_id: 1):

```select * from pmt_validate_user_authority(1, 34, null, 2237, 'create');```

TRUE

- User sparadee (user\_id: 34) has authority to delete activity 5674 in EthAIM instance (instance\_id: 1):

```select * from pmt_validate_user_authority(1, 34, 5674, null, 'delete');```

TRUE

[&larr;  Back to Function List](#function-listing)


## pmt\_validate\_username

##### Description

Validate a username is available for use.

##### Parameter(s)

1. username (character varying) - **Required**. username to validate as available.

##### Result

Boolean. True/False username is available.

##### Example(s)

```select * from pmt_validate_username('sparadee');```

FALSE

```select * from pmt_validate_username('junebug');```

TRUE

[&larr;  Back to Function List](#function-listing)


## pmt\_version


##### Description

Provides the current version, iteration, changeset, instance creation date and last changeset update date.

##### Parameter(s)

No parameters.

##### Result
Json with the following:

1.  pmt\_version (text) – the version, iteration, changeset.
2.  last\_update (date) – the date of last changeset.
3.  created (date) – the date instance was created.

##### Example(s)

```SELECT * FROM pmt_version();```

```
{
	"pmt_version":"3.0.10.16",
	"last_update":"2016-03-31",
	"created":"2014-02-05"
}
```


## test\_execute\_unit\_tests

##### Description

Execute all unit tests.

##### Parameter(s)

No parameters.

##### Result

Text. Results message.

##### Example(s)

- Execute tests:

```SELECT * FROM test_execute_unit_tests();```

Unit testing complete: pass (32) fail (0) execution_failures(0) total(32)

- View testing results:

```SELECT * FROM unit_test;```

[&larr;  Back to Function List](#function-listing)


* * * * *

<a name="bytea_ref"/>
[[1]](#bytea_reftext) Douglas, Jack. "SQL to read XML from file into
PostgreSQL database." StackExchange Database Administrators Nov 2011.
Web. 02 Aug 2013
 http://dba.stackexchange.com/questions/8172/sql-to-read-xml-from-file-into-postgresql-database
