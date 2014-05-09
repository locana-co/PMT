PMT Database Function Reference
===============================


##### Contents

[pmt\_activate\_activity](#activate_activity)

[pmt\_activate\_project](#activate_project)

[pmt\_activities\_by\_tax](#activities_by_tax)

[pmt\_activities](#activities)

[pmt\_activity](#activity)

[pmt\_activity\_details](#activity_details)

[pmt\_activity\_listview](#activity_listview)

[pmt\_activity\_listview\_ct](#activity_listview_ct)

[pmt\_auth\_user](#auth_user)   **SCHEDULED TO BE DEPRECATED IN DATABASE ITERATION 9 (see [pmt\_user\_auth](#user_auth))**

[pmt\_auto\_complete](#auto_complete)

[pmt\_bytea\_import](#bytea_import)

[pmt\_category\_root](#category_root)

[pmt\_contacts](#contacts)

[pmt\_countries](#countries)

[pmt\_create\_user](#create_user)

[pmt\_data\_groups](#data_groups)

[pmt\_edit\_activity](#edit_activity)

[pmt\_edit\_activity\_contact](#edit_activity_contact)

[pmt\_edit\_activity\_taxonomy](#edit_activity_taxonomy)

[pmt\_edit\_contact](#edit_contact)

[pmt\_edit\_detail](#edit_detail)

[pmt\_edit\_financial](#edit_financial)

[pmt\_edit\_location](#edit_location)

[pmt\_edit\_location\_taxonomy](#edit_location_taxonomy)

[pmt\_edit\_organization](#edit_organization)

[pmt\_edit\_participation](#edit_participation)

[pmt\_edit\_project](#edit_project)

[pmt\_edit\_project\_contact](#edit_project_contact)

[pmt\_edit\_project\_taxonomy](#edit_project_taxonomy)

[pmt\_filter\_csv](#filter_csv)

[pmt\_filter\_iati](#filter_iati)

[pmt\_filter\_locations](#filter_locations)

[pmt\_filter\_orgs](#filter_orgs)

[pmt\_filter\_projects](#filter_projects)

[pmt\_global\_search](#global_search)

[pmt\_iati\_import](#iati_import)

[pmt\_infobox\_activity](#infobox_activity)   **SCHEDULED TO BE DEPRECATED IN DATABASE ITERATION 9 (see [pmt\_activity](#activity))**

[pmt\_infobox\_activity\_contact](#infobox_activity_contact)   **SCHEDULED TO BE DEPRECATED IN DATABASE ITERATION 9 (see [pmt\_activity](#activity))**

[pmt\_infobox\_activity\_desc](#infobox_activity_desc)   **SCHEDULED TO BE DEPRECATED IN DATABASE ITERATION 9 (see [pmt\_activity](#activity))**

[pmt\_infobox\_activity\_stats](#infobox_activity_stats)   **SCHEDULED TO BE DEPRECATED IN DATABASE ITERATION 9 (see [pmt\_activity](#activity))**

[pmt\_infobox\_project\_contact](#infobox_project_contact)

[pmt\_infobox\_project\_desc](#infobox_project_desc)

[pmt\_infobox\_project\_info](#infobox_project_info)

[pmt\_infobox\_project\_stats](#infobox_project_stats)

[pmt\_isdate](#isdate)

[pmt\_isnumeric](#isnumeric)

[pmt\_locations](#locations)

[pmt\_locations\_by\_org](#locations_by_org)

[pmt\_locations\_by\_polygon](#locations_by_polygon)

[pmt\_locations\_by\_tax](#locations_by_tax)

[pmt\_org\_inuse](#org_inuse)

[pmt\_orgs](#orgs)

[pmt\_project](#project)

[pmt\_project\_listview](#project_listview)

[pmt\_project\_listview\_ct](#project_listview_ct)

[pmt\_projects](#projects)

[pmt\_purge\_activity](#purge_activity)

[pmt\_purge\_project](#purge_project)

[pmt\_sector\_compare](#sector_compare)

[pmt\_stat\_activity\_by\_district](#stat_activity_by_district)

[pmt\_stat\_activity\_by\_tax](#stat_activity_by_tax)

[pmt\_stat\_counts](#stat_counts)

[pmt\_stat\_orgs\_by\_activity](#stat_orgs_by_activity)

[pmt\_stat\_orgs\_by\_district](#stat_orgs_by_district)

[pmt\_stat\_partner\_network](#stat_partner_network)

[pmt\_stat\_pop\_by\_district](#stat_pop_by_district)

[pmt\_stat\_project\_by\_tax](#stat_project_by_tax)

[pmt\_tax\_inuse](#tax_inuse)

[pmt\_taxonomies](#taxonomies)

[pmt\_update\_user](#update_user)

[pmt\_user\_auth](#user_auth)

[pmt\_user\_salt](#user_salt)

[pmt\_users](#users)

[pmt\_validate\_activities](#validate_activities)

[pmt\_validate\_activity](#validate_activity)

[pmt\_validate\_boundary\_feature](#validate_boundary_feature)

[pmt\_validate\_classification](#validate_classification)

[pmt\_validate\_classifications](#validate_classifications)

[pmt\_validate\_contact](#validate_contact)

[pmt\_validate\_contacts](#validate_contacts)

[pmt\_validate\_detail](#validate_detail)

[pmt\_validate\_financial](#validate_financial)

[pmt\_validate\_location](#validate_location)

[pmt\_validate\_organization](#validate_organization)

[pmt\_validate\_organizations](#validate_organizations)

[pmt\_validate\_project](#validate_project)

[pmt\_validate\_projects](#validate_projects)

[pmt\_validate\_taxonomies](#validate_taxonomies)

[pmt\_validate\_taxonomy](#validate_taxonomy)

[pmt\_validate\_user\_authority](#validate_user_authority)

[pmt\_version](#version)

* * * * *

<a name="activate_activity"/>
pmt\_activate\_activity
=======================

##### Description

Activate/deactivate an activity and its related records (locations, financial, participation, detail, result).

##### Parameter(s)

1.  user\_id (integer) – **Required**. user\_id of user requesting edit.
2.  activity\_id (integer) – **Required**. activity\_id to activate/deactivate.
3.  activate (boolean) - **Default is TRUE**. True to activate, false to deactivate.

##### Result

Json with the following:

1.  id (integer) – activity\_id of the activity activated/deactivated.
2.  message(character varying) - Message containing either "Success" for a successful transaction 
or containing an error description regarding the unsuccessful transaction. Some possible error messages:
	- Must included user_id and activity_id data parameters
	- User does NOT have authority to change the active status of this activity and its assoicated records.

##### Example(s)

-   Activate the activity\_id 15820 and its related records.

```select * from pmt_activate_activity(34, 15820, true);```

```{"id":15820,"message":"Success"}```

-  Deactivate the activity\_id 15820 and its related records.

```select * from pmt_activate_activity(34, 15820, false);```

```{"id":15820,"message":"Success"}```


<a name="activate_project"/>
pmt\_activate\_project
=======================

##### Description

Activate/deactivate a project and its related records (activity, locations, financial, participation, detail, result).

##### Parameter(s)

1.  user\_id (integer) – **Required**. user\_id of user requesting edit.
2.  project\_id (integer) – **Required**. project\_id to activate/deactivate.
3.  activate (boolean) - **Default is TRUE**. True to activate, false to deactivate.

##### Result

Json with the following:

1.  id (integer) – project\_id of the project activated/deactivated.
2.  message(character varying) - Message containing either "Success" for a successful transaction 
or containing an error description regarding the unsuccessful transaction. Some possible error messages:
	- Must included user_id and project_id data parameters
	- User does NOT have authority to change the active status of this project and its assoicated records.

##### Example(s)

-   Activate the project\_id 402 and its related records.

```select * from pmt_activate_project(34, 402, true);```

```{"id":402,"message":"Success"}```

-  Deactivate the project\_id 402 and its related records.

```select * from pmt_activate_project(34, 402, false);```

```{"id":402,"message":"Success"}```

<a name="activities_by_tax"/>
pmt\_activities\_by\_tax
========================

##### Description

Filter activities by classification reporting by a specified taxonomy.

##### Parameter(s)

1.  tax\_id (integer) – **Required**. Taxonomy\_id to classify returned
    activities.
2.  data\_group (integer) -  Optional. Restrict data to a single data
    group.
3.  country\_ids (character varying) – Optional. Restrict data to
    country(ies).

##### Result

1.  a\_id (integer) – activity\_id.
2.  title (character varying) – title of activity.
3.  c\_ids (text) – comma separated list of classification\_ids
    associated to activity from taxonomy specified by tax\_id.

##### Example(s)

-   Activities by Sector (taxonomy\_id:15) from World Bank data group
    (classification\_id:772):

```SELECT * FROM pmt_activities_by_tax(15, 772, '');```


| a\_id                   | Title                   | c\_ids                  |
|-------------------------|-------------------------|-------------------------|
| 32757                   | "SA Trade &amp; Trans Facilitation Project"  | "575,623,624"           |
| 32759                   | "3A-Southern Afr Power Mrkt APL 1 (FY04)" | "637,717"               |
| 32765                   | "3A-CEMAC Regional Institutions Support"      | "651,652,653"           |
|...|...|...|


<a name="activities"/>
pmt\_activities
=============================

##### Description

All activities: activity\_id, title and list of location\_ids.

##### Parameter(s)

None.

##### Result

Json with the following:

1.  activity\_id (integer) – activity id.
2.  title (character varying) – title of activity.
3.  location\_ids (int[]) – array of location\_ids related to activity.


##### Example(s)

```select * from pmt_activities();```

```
...
{
	"activity_id":66
	,"title":""
	,"location_ids":[72880,72879,72878,72877,72876]
},{
	"activity_id":10
	,"title":"Rwanda Super Foods"
	,"location_ids":[39489,39488,39487]
},{
	"activity_id":31
	,"title":"Strengthening and evaluating HKIs homestead food production program in Burkina Faso"
	,"location_ids":[39492]
}
...
```

<a name="activity"/>
pmt\_activity
=============================

##### Description

All information for a single activity.

##### Parameter(s)

1. activity_id (integer) - **Required.** Activity id.

##### Result

Json with the following:

1.  activity\_id (integer) – activity id.
2.  project\_id (integer) – project id of activity.
3.  title (character varying) – title of activity.
4.  label (character varying) – short title for activity.
5.  description (character varying) – description of activity.
6.  content (character varying) – various content for activity.
7.  start\_date (date) – start date of activity.
8.  end\_date (date) – end date of activity.
9.  tags (character varying) – tags or keywords of activity.
10.  updated\_by (character varying(50)) -  last user to update activity information.
11.  updated\_date (timestamp) -  last date and time activity information was updated.
12.  iati\_identifier (integer) – iati idenifier or primary key of activity.
13.  custom\_fields (various) - any custom fields in the activity table that are not in the Core PMT will be returned as well.
14.  location\_ct (integer) - number of locations for activity.
15.  admin\_bnds (character varying) - list of GAUL administrative boundaries for all locations (format gaul_2, gaul_1, gaul_0). Multiple
locations are seperated by a semi-colon (;).
16.  taxonomy(object) - An object containing all associated taxonomy for the activity
	1. taxonomy\_id (integer) - taxonomy id.
	2. taxonomy (character varying) - taxonomy name.
	3. classification\_id (integer) - classification id.
	4. classification (character varying) - classification name.
	5. code (character varying) - classification code.
17.  organizations(object) - An object containing all organizations participating in the activity
	1. participation\_id (integer) - participation id for the organization participating in the activity
	2. organization\_id (integer) - organization id.
	3. name (character varying) - organization name.
	4. url (character varying) - url for organization.
	5. taxonomy(object) - An object containing all associated taxonomy for the organization
		1. taxonomy\_id (integer) - taxonomy id.
		2. taxonomy (character varying) - taxonomy name.
		3. classification\_id (integer) - classification id.
		4. classification (character varying) - classification name.
		5. code (character varying) - classification code.
18.  contacts (object) - An object containing all activity contacts.
	1. contact\_id (integer) - contact id.
	2. first\_name (character varying) - contact's first name.
	3. last\_name (character varying) - contact's last name.
	4. email (character varying) - contact's email address.
	5. organization\_id (integer) - organization id.
	6. name (character varying) - organization name the contact is associated with.
19.  details (object) - An object containing all activity details.
	1. detail\_id (integer) - detail id.
	2. title (character varying) - the title of the detail.
	3. description (character varying) - description of the detail.
	4. amount (numeric (12,2)) - detail amount.
20.  financials (object) - An object containing all activity financial data.
	1. financial\_id (integer) - financial id.
	2. amount (numeric (100,2)) - financial amount.	
	3. taxonomy(object) - An object containing all associated taxonomy for the financial record
		1. taxonomy\_id (integer) - taxonomy id.
		2. taxonomy (character varying) - taxonomy name.
		3. classification\_id (integer) - classification id.
		4. classification (character varying) - classification name.
		5. code (character varying) - classification code.
21.  locations (int[]) - An array of location_ids associated to the activity.

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

<a name="activity_details"/>
pmt\_activity\_details
=======================

##### Description

Activity details for a single activity.

##### Parameter(s)

1.  a\_id (integer) – **Required**. activity\_id.

##### Result

Json with the following:

1.  a\_id (integer) – activity\_id.
2.  title (character varying) – title of activity.
3.  desc (character varying) – description of activity.
4.  start\_date (date) – start date of activity.
4.  end\_date (date) – end date of activity.
5.  tags (character varying) – tags of activity.
6.  amount (integer) - total amount of activity.
7.  taxonomy (object) – object containing taxonomy/classification for all related taxonomies
	1. taxonomy (character varying) – name of taxonomy
	2. classification (character varying) – name of classifcation
	3. org (character varying) – name of organization (provided only where taxonomy is *Organisation Role*)
7.  locations (object) – object containing all related locations.
	1. location_id (integer) - location_id of location
	2. gaul0\_name (character varying) - name of GAUL 0 administrative boundary
	3. gaul1\_name (character varying) - name of GAUL 1 administrative boundary
	3. gaul2\_name (character varying) - name of GAUL 2 administrative boundary
	3. lat (decimal degrees) - latitude of location
	3. long (decimal degrees) - longitude of location
##### Example(s)

-   Activity_id 2039:

```SELECT * FROM  pmt_activity_details(2039);```

```
{	"a_id":2039
	,"title":"ASDP"
	,"desc":"repair of hides and skin banda"
	,"start_date":"2011-01-01"
	,"end_date":"2012-12-31"
	,"tags":null
	,"amount":3500000.00
	,"taxonomy":
		[{	"taxonomy":"Country"
			,"classification":"TANZANIA, UNITED REPUBLIC OF"
			,"org":null
		  }
 		 ,{	"taxonomy":"Data Group"
			,"classification":"ASDP"
			,"org":null
		  }
		 ,{	"taxonomy":"Category"
			,"classification":"Post Harvest"
			,"org":null
		  }
		 ,{	"taxonomy":"Organisation Role"
			,"classification":"Implementing"
			,"org":"LGAs"
		  }
		 ,{	"taxonomy":"Organisation Role"
			,"classification":"Funding"
			,"org":"DLDF (District Local Development Fund)"
		  }
		 ,{	"taxonomy":"Sector"
			,"classification":"Plant and post-harvest protection and pest control"
			,"org":null
		  }
		 ,{	"taxonomy":"Sector Category"
			,"classification":"AGRICULTURE"
			,"org":null
		  }
	 	 ,{	"taxonomy":"Sub-Category"
			,"classification":"Commodity Value Chain"
			,"org":null
		  }]
	,"locations":
		  [{	"location_id":2039
			,"gaul0_name":"United Republic of Tanzania"
			,"gaul1_name":"Shinyanga"
			,"gaul2_name":"Kahama"
			,"lat":-3.950000
			,"long":32.03333
		  }]
}
```

<a name="activity_listview"/>
pmt\_activity\_listview
=======================

##### Description

Filter activity and organization by classification, organization and
date range, reporting a specified taxonomy(ies) with pagination.

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
6.  report\_taxonomy\_ids (character varying) – Optional. Report activities by one or 
    more taxonomies.
7.  orderby (text) – Optional. Order by result columns (a\_id, a\_name, f\_orgs, i\_orgs, tax1, tax2, etc.).
8.  limit\_rec (integer) – Optional. Maximum number of returned records.
9.  offset\_rec (integer) – Optional. Number of records to offset the
    return records by.

##### Result

Json with the following:

1.  a\_id (integer) – activity\_id.
2.  a\_name (character varying) – title of activity.
3.  f\_orgs (character varying) - comma seperated list of funding organizations.
4.  i\_orgs (character varying) - comma seperated list of implementing organizations.
5.  tax (character varying) - comma seperated list of classifications based on requested 
    reporting taxonomy(ies). **Note:** report\_taxonomy\_ids accepts multiple taxonomy ids. The ids
    are sorted by ascending order and returned as tax1, tax2, tax3, etc.

##### Example(s)

-   Activities for Bolivia (classification\_id:769) between the dates of 1-1-1990 and 12-31-2014. Report
    activities by Sector (taxonomy\_id:15) and include activities that do NOT have an assignement to Sector (taxonomy\_id:15).  
    Order the data by activity title (a\_name). Limit the number of rows returned to 10 with an offset of
    100:

```select * from  pmt_activity_listview('769', '', '15', null,null, '15', 'a_name', 10, 100);```

```
...
{
	"a_id":5089
	,"a_name":"AMPL. MEJ. SIST. AGUA POTABLE ANTOFAGASTA  (SAN CARLOS)"
	,"f_orgs":"Donaciones - HIPC II"
	,"i_orgs":"Fondo Nacional de InversiСn Productiva y Social"
	,"tax1":"Water supply and sanitation - large systems"
}
...
```

-   Activities for ASDP (classification\_id:769). Report activities by Sector (taxonomy\_id:15) and by Country (taxonomy\_id:5) 
    and include activities that do NOT have an assignement to Sector (taxonomy\_id:15).  
    Order the data by Sector (tax2). Limit the number of rows returned to 10 no offset:  
    **Note:** Sector is first in the parameter list, but is returned as tax2. This is because they are returned in numerical order 
    and Country (taxonomy\_id 5) is before Sector (taxonomy\_id 15):

```select * from  pmt_activity_listview('769', '', '15', null,null, '15,5', 'tax2', 10, null);;```

```
...
{
	"a_id":970
	,"a_name":"ASDP"
	,"f_orgs":"ACBG (Agriculture Capacity Building Grant)"
	,"i_orgs":"LGAs"
	,"tax1":"TANZANIA, UNITED REPUBLIC OF"
	,"tax2":"Agricultural co-operatives"
}
...
```

<a name="activity_listview_ct"/>
pmt\_activity\_listview\_ct
===========================

##### Description

Total record count for pmt\_activity\_listview. Sending the same filter
parameters as pmt\_activity\_listview will provide the total record
count. Used to assist with pagination.

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

##### Result

Integer of number of records.

##### Example(s)

-   Number of Activity & Organization records in Nepal
    (classification\_id:771) and organization participant is Funding
    (classification\_id:496) between the dates of 1-1-1990 and 12-31-2014:

```select * from  pmt_activity_listview_ct('771,496', '', '', '1-1-1990','12-31-2014');```

1613

<a name="auth_user"/>
pmt\_auth\_user
=============================
**SCHEDULED TO BE DEPRECATED IN DATABASE ITERATION 9**
##### Description

Authenticate user using a plain text password.

##### Parameter(s)

1.  username (character varying) - **Required**. User's username.
2.  password (character varying) - **Required**. User's password.

##### Result

Json with the following:

1.  user\_id (integer) – user id.
2.  first\_name (character varying) – first name of user.
3.  last\_name (character varying) – last name of user.
4.  username (character varying) – username of user.
5.  email (character varying) – email address of user.
6.  organization\_id (integer) – organization id for organization of user.
7.  roles (json object):
	1.  role\_id (integer) – role id user is assigned to.
	2.  name (character varying) – name of role user is assigned to.

##### Example(s)

- Authenticate Jane Doe passing her username and password.

```SELECT * FROM pmt_auth_user('janedoe', 'supersecret');```

```
{
	"user_id":315,
	"first_name":"Jane",
	"last_name":"Doe",
	"username":"myusername",
	"email":"jane.doe@email.com",
	"organization_id":13,
	"organization": "BMGF",
	"data_group_id":768,
	"data_group": "BMGF",
	"roles":[
		{
			"role_id":2,
			"name":"Editor"
		}
		]
}
```
- Authenticate Jane Doe passing her username and an invalid password.

```SELECT * FROM pmt_auth_user('janedoe', 'superduper');```

```
{
	"message":"Invalid username or password."
}
```

<a name="auto_complete"/>
pmt\_auto\_complete
===========================

##### Description

Function accepting columns for both project and activity and compiles a 
list of unique data from those fields for use in an autocomplete or type 
ahead function.

##### Parameter(s)

1.  project\_fields (character varying) – Optional. Comma seperated string of project column names.
2.  activity\_fields (character varying) – Optional. Comma seperated string of activity column names.

##### Result

A text array of distinct values from all provided columns. Each text element returned is restricted to 100 characters.

##### Example(s)

-   Title from both project and activity tables:

```SELECT * FROM pmt_auto_complete('title', 'title');```

```
{
  "autocomplete":
    [
      "(1)  PEAK PRODUCTS LTD",
      "(10) AMIDAL INVESTMENT LTD",
      "(11) IDAEWOR FARMS LTD",
      "(12) IMO STATE POLYTECHNIC ULTRA MODERN CASSAVA PROCESSING PLANT",
       ...
    ]
}
```
<a name="bytea_import"/>
pmt\_bytea\_import
==================

##### Description

<a name="bytea_reftext"/>
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

<a name="category_root"/>
pmt\_category\_root
===================

##### Description

A taxonomy can have a taxonomy category and a taxonomy category can have
a taxonomy category. This function returns the base or root taxonomy\_id
of any taxonomy.

##### Parameter(s)

1.  id (integer) – **Required**. The category taxonomy.
2.  data\_group (integer) – Optional. The data group classification id.

##### Result

Integer of root taxonomy\_id.

##### Example(s)

-   Return the root taxonomy for the PMT Sector Category
    (taxonomy\_id:16) taxonomy category:

```SELECT pmt_category_root(16, null);```

15

<a name="contacts"/>
pmt\_contacts
==============

##### Description

 Get all contacts.

##### Parameter(s)

No parameters.

##### Result

Ordered by last name then first name. Json with the following:

1.  c\_id (integer) – contact\_id.
2.  first_name (character varying(64)) – first name of contact.
3.  last_name (character varying(128)) – last name of contact.
4.  email (character varying(100)) - email of contact.
4.  o\_id (integer) – organization\_id in which the contact belongs to.
5.  org (character varying(255)) - organization name of the organization in which the contact belongs to.

##### Example(s)

```SELECT * FROM pmt_contacts();```

```
...
{
	"c_id":4,
	"first_name":"John",
	"last_name":"Doe",
	"email":"john.doe@mymail.com",
	"o_id":13,
	"org":"FAO"
}
...
```

<a name="countries"/>
pmt\_countries
==============

##### Description

 Filter countries by classifications.

##### Parameter(s)

1.  classification\_ids (character varying) – Optional. Restrict data to
    classification(s).

##### Result

Json with the following:

1.  c\_id (integer) – classification\_id.
2.  name (character varying(255)) – name of country.
3.  bounds (json object) – bounding box of country.

##### Example(s)

-   Country for Afghanistan:

```SELECT * FROM pmt_countries('24');```

```
{        
    "c_id":24,
    "name":"afghanistan",
    "bounds":"{
    	\"type\":\"Polygon\",
        \"coordinates\":[[[60.4758911132812,29.3773193359375],[60.4758911132812,38.49072265625],[74.889892578125,38.49072265625],[74.889892578125,29.3773193359375],[60.4758911132812,29.3773193359375]]]
    }                
}
```

<a name="create_user"/>
pmt\_create\_user
================

##### Description

Create new user.

##### Parameter(s)

1.  organization\_id (integer) – **Required**. Organization id user will be assigned to.
2.  data\_group\_id (integer) - **Required**. Data group id user will be assigned to.
3.  role\_id (integer) – **Required**. Role id user will be assigned to.
4.  username (character varying(255)) - **Required**. User username.
5.  password (character varying(255)) - **Required**. User password.
6.  email (character varying(255)) - **Required**. User email address.
7.  first\_name (character varying(150)) - Optional. User first name.
8.  last\_name (character varying(150)) - Optional. User last name.

##### Result

Boolean. Successful (true). Unsuccessful (false).

##### Example(s)

-   Create new user for Jane Doe as a Reader (role_id:1) for BMGF organization (organization_id:13) in  data group BMGF(classification_id:768):

```SELECT * FROM pmt_create_user(13, 768, 1, 'janedoe', 'secretpassword', 'jane.doe@email.com', 'Jane', 'Doe');```

```
TRUE
```

<a name="data_groups"/>
pmt\_data\_groups
=================

##### Description

Returns data groups.

##### Parameter(s)

None.

##### Result

1.  a\_id (integer) – Activity\_id.
2.  title (character varying) – Title of activity.
3.  c\_ids (text) – Comma separated list of classification\_ids
    associated to activity from taxonomy specified by tax\_id.

##### Example(s)

-   Get data groups:

```SELECT * from pmt_data_groups();```

| c\_id                                | Name                                 |
|--------------------------------------|--------------------------------------|
| 768                                  | "AFDB"                               |
| 769                                  | "Bolivia"                            |
| 770                                  | "Malawi"                             |
| …                                    | …                                    |


<a name="edit_activity"/>
pmt\_edit\_activity
===================

##### Description

Edit an activity.

##### Parameter(s)

1.  user\_id (integer) – **Required**. User\_id of user requesting edits.
2.  activity\_id (integer) – **Required for delete and update operations**. Activity\_id of activity to update or delete.
3.  project\_id (integer) – **Required for create operation**. Project\_id of activity to create.
4.  json (json) - **Required for create and update operations**. Key/value pair as json of field/values to edit. Column names are 
case sensitive. Enclose all values in double quotes, including null. **If your text values include
a single quote, use two adjacent single quotes, e.g., 'Dianne''s dog'. This is because PostgreSQL
uses the single quote to encase string constants.** You can include any existing
field that exists for activity, even custom fields. The following fields cannot be edited even
if included: 
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
5. delete\_record (boolean) - Optional, default is false. True to request the record be deleted.

##### Result

Json with the following:

1.  id (integer) – activity\_id of the activity created, updated or deleted.
2.  message(character varying) - Message containing either "Success" for a successful transaction 
or containing an error description regarding the unsuccessful transaction. Some possible error messages:
	- The json parameter is required for a create/update operation
	- project\_id is required for a create operation - When activity\_id is null a create operation is assumed an project\_id is required.
	- activity_id is required for a delete operation - When delete\_record is true, an activity\_id is required.
	- user\_id is a required parameter for all operations
	- User does NOT have authority to create a new activity for project_id
	- User does NOT have authority to delete this activity
	- project_id is not valid - the provide project\_id is either not active or invalid
	- User does NOT have authority to update this activity

##### Example(s)

-   Update the title, description and start_date for activity\_id 14863 and set it's opportunity\_id 
 to null. 

```
select * from pmt_edit_activity(34,14863, null,'{"title": "Project Objective 1", 
"description":"Market opportunities, Policies and Partnerships", "start_date":"9-2-2012", 
"opportunity_id": "null"}', false);
```

```
{"id":14863,"message":"Success"}
```

-  Create a new activity for project\_id 749.

```
select * from pmt_edit_activity(34, null, 749,'{"title": "A New Activity", 
"description":"Doing some good work in Nepal", "start_date":"6-1-2014", "end_date":"5-31-2016"}', false);
```

```
{"id":15821,"message":"Success"}
```

-  Delete activity\_id 15821.

```
select * from pmt_edit_activity(34, 15821, null, null, true);
```

```
{"id":15821,"message":"Success"}
```

<a name="edit_activity_contact"/>
pmt\_edit\_activity\_contact
=============================

##### Description

Edit the relationship between an activity and a contact.

##### Parameter(s)

1.  user\_id (integer) – **Required**. User\_id of user requesting edits.
2.  activity\_id (integer) – **Required**. Activity\_id of activity to edit.
2.  contact\_id (integer) – **Required**.  Contact\_id of contact to associate to activity\_id.
3.  edit\_activity (enum) - Optional. 
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

<a name="edit_activity_taxonomy"/>
pmt\_edit\_activity\_taxonomy
=============================

##### Description

Edit the relationship between activity(ies) and a taxonomy classification. **Important Note: This function DOES NOT 
call the refresh\_taxonomy\_lookup() function, which updates the materialized views that support a majority of the functions
in the database. Be sure to call this function when editing is complete.**

##### Parameter(s)

1.  activity\_ids (character varying) – **Required**. Comma seperated list of activity_ids to edit.
2.  classification\_id (integer) – **Required**.  Classification\_id of taxonomy classification in relationship to activity\_id(s).
3.  edit\_activity (enum) - Optional. 
	Options:
	1. add (default) - will add a relationship between provided activity\_id(s) and classification_id
	2. delete - will remove the relationship between the provided activity\_id(s) and classification_id
	3. replace - will replace all relationships between the provided activity\_ids(s) and taxonomy of the provided classification\_id, with
a single relationship between the provided activity\_id(s) and classification\_id.

##### Result

Boolean. Sucessfull (true) or unsuccessful (false). Unsuccessful is usually due invalid parameters.

##### Example(s)

-   Add a relationship to Sector 'Educational research' (classification\_id:567) to activity\_ids 2336,2335,5526:

```select * from pmt_edit_activity_taxonomy('5526,2335,2336', 567, 'add');```

	TRUE

-   Remove the relationship to Sector 'Sectors not specified' (classification\_id:756) from activity\_ids 2336,2335,5526:

```select * from pmt_edit_activity_taxonomy('5526,2335,2336', 756, 'delete');```

	TRUE

-   Replace  all relationships to the Sector taxonomy with the relationship to Sector 'Educational research' 
(classification\_id:567) for activity\_ids 2336,2335,5526:

```select * from pmt_edit_activity_taxonomy('5526,2335,2336', 756, 'replace');```

	TRUE

<a name="edit_contact"/>
pmt\_edit\_contact
===================

##### Description

Edit a contact.

##### Parameter(s)

1.  user\_id (integer) – **Required**. User\_id of user requesting edits.
2.  contact\_id (integer) – **Required for update and delete operations**. Contact\_id of existing contact to update or delete, if left null then a new contact record will be created.
3.  json (json) - **Required**. Key/value pair as json of field/values to edit. Column names are 
case sensitive. Enclose all values in double quotes, including null. **If your text values include
a single quote, use two adjacent single quotes, e.g., 'Dianne''s dog'. This is because PostgreSQL
uses the single quote to encase string constants.** You can include any existing
field that exists for contact, even custom fields. The following fields cannot be edited even
if included: 
	- contact\_id
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
4. delete\_record (boolean) - Optional, default is false. True to request the record be deleted.

##### Result

Json with the following:

1.  id (integer) – contact\_id of the contact created or updated.
2.  message(character varying) - Message containing either "Success" for a successful transaction 
or containing an error description regarding the unsuccessful transaction. Possible error messages:
	- Must included user\_id and json data parameters - Received when both required parameters are not provided.
	- User does NOT have authority to create a new contact - Received when the user\_id provided does not have authority to create under current role.
	- User does NOT have authority to update an existing contact - Received when the user\_id provided does not have authority to update under current role.
	- Invalid contact\_id - Received when the contact\_id provided is invalid.

##### Example(s)

-   Update the email and title for Jonh Hancock (contact\_id:148) as user sparadee (user\_id:34)

```select * from pmt_edit_contact(34,148,'{"email":"jhanhock@mail.com", "title":"CEO"}', false);```

```
{"id":148,"message":"Success"}
```

-   Add new contact for BMGF (organization\_id:13) as user sparadee (user\_id:34)

```
select * from pmt_edit_contact(34,null,'{"first_name":"John", "last_name":"Hanhock", "email":"jhanhock@mail.com", 
"title":"CEO", "organization_id": 13}', false);
```

```
{"id":672,"message":"Success"}
```

-   Delete contact\_id 672 as user sparadee (user\_id:34)

```
select * from pmt_edit_contact(34,672,null, true);
```

```
{"id":672,"message":"Success"}
```

<a name="edit_detail"/>
pmt\_edit\_detail
===================

##### Description

Edit a detail.

##### Parameter(s)

1.  user\_id (integer) – **Required**. User\_id of user requesting edits.
2.  detail\_id (integer) – **Required for update and delete operations**. detail\_id of existing detail to update or delete, if left null then a new detail record will be created.
2.  project\_id (integer) – **Required for create operations on project details**. project\_id of detail to create.
2.  activity\_id (integer) – **Required for create operations on activity details**. activity\_id of detail to create.
3.  json (json) - **Required for update and create operations**. Key/value pair as json of field/values to edit. Column names are 
case sensitive. Enclose all values in double quotes, including null. **If your text values include
a single quote, use two adjacent single quotes, e.g., 'Dianne''s dog'. This is because PostgreSQL
uses the single quote to encase string constants.** You can include any existing
field that exists for detail, even custom fields. The following fields cannot be edited even
if included: 
	- detail\_id
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
6. delete\_record (boolean) - Optional, default is false. True to request the record be deleted.

##### Result

Json with the following:

1.  id (integer) – detail\_id of the detail created or updated.
2.  message(character varying) - Message containing either "Success" for a successful transaction 
or containing an error description regarding the unsuccessful transaction. Possible error messages:
	- Must included json parameter when delete_record is false
	- Must included detail_id when delete_record is true
	- Must included project_id or activity_id parameter when detail_id parameter is null
	- Must included user_id parameter
	- Invalid project_id

##### Example(s)

-   Update title for detail\_id 136 as user sparadee (user\_id:34)

```
select * from pmt_edit_detail(34,136,null,null,'{"title": "Description of Activities Related to Nutrition"}', 
false);
```

```
{"id":136,"message":"Success"}
```

-   Add new detail for activity\_id 493 as user sparadee (user\_id:34)

```
select * from pmt_edit_detail(34,null, null, 493,'{"title": "Test Title", "description":"a description", 
"amount":3}', false);
```

```
{"id":672,"message":"Success"}
```

-   Add new detail for project\_id 13 as user sparadee (user\_id:34)

```
select * from pmt_edit_detail(34, null, 13, null, '{"title": "Test Title", "description":"a description", 
"amount":3}', false);
```

```
{"id":673,"message":"Success"}
```

-   Delete detail\_id 673 as user sparadee (user\_id:34)

```
select * from pmt_edit_detail(34, 673, null, null, null, true);
```

```
{"id":673,"message":"Success"}
```

<a name="edit_financial"/>
pmt\_edit\_financial
===================

##### Description

Edit a financial record.

##### Parameter(s)

1.  user\_id (integer) – **Required**. User\_id of user requesting edits.
2.  financial\_id (integer) – **Required for update and delete operations**. financial\_id of existing financial to update or delete, if left null then a new financial record will be created.
2.  project\_id (integer) – **Required for create operations on project financials**. project\_id of financial record to create.
2.  activity\_id (integer) – **Required for create operations on activity financials**. activity\_id of financial record to create.
3.  json (json) - **Required for update and create operations**. Key/value pair as json of field/values to edit. Column names are 
case sensitive. Enclose all values in double quotes, including null. **If your text values include
a single quote, use two adjacent single quotes, e.g., 'Dianne''s dog'. This is because PostgreSQL
uses the single quote to encase string constants.** You can include any existing
field that exists for financial, even custom fields. The following fields cannot be edited even
if included: 
	- financial\_id
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
6. delete\_record (boolean) - Optional, default is false. True to request the record be deleted.

##### Result

Json with the following:

1.  id (integer) – financial\_id of the financial created or updated.
2.  message(character varying) - Message containing either "Success" for a successful transaction 
or containing an error description regarding the unsuccessful transaction. Possible error messages:
	- Must included json parameter when delete_record is false
	- Must included financial_id when delete_record is true
	- Must included project_id or activity_id parameter when financial_id parameter is null
	- Must included user_id parameter
	- Invalid project_id

##### Example(s)

-   Update amount and start\_date for financial\_id 136 as user sparadee (user\_id:34)

```
select * from pmt_edit_financial(34,136,null,null,'{"amount": 130900.00, "start_date":"1-1-2014"}', false);
```

```
{"id":136,"message":"Success"}
```

-   Add new financial record for activity\_id 493 as user sparadee (user\_id:34)

```
select * from pmt_edit_financial(34,null, null, 493,'{"amount": "100500.00", "start_date":"1-1-2014", 
"end_date":"12-31-2016"}', false);
```

```
{"id":672,"message":"Success"}
```

-   Add new financial for project\_id 13 as user sparadee (user\_id:34)

```
select * from pmt_edit_financial(34, null, 13, null, '{"amount": "1000000.00", 
"start_date":"1-1-2014", "end_date":"12-31-2016"}', false);
```

```
{"id":673,"message":"Success"}
```

-   Delete financial\_id 673 as user sparadee (user\_id:34)

```
select * from pmt_edit_financial(34, 673, null, null, null, true);
```

```
{"id":673,"message":"Success"}
```

<a name="edit_location"/>
pmt\_edit\_location
===================

##### Description

Edit a location.

##### Parameter(s)

1.  user\_id (integer) – **Required**. User\_id of user requesting edits.
2.  location\_id (integer) – **Required for delete and update operations**. Location\_id of location to update or delete.
3.  activity\_id (integer) – **Required for create operation**. Activity\_id of the location to create.
4.  json (json) - **Required for create and update operations**. Key/value pair as json of field/values to edit. Enclose 
all values in double quotes, including null. **If your text values include
a single quote, use two adjacent single quotes, e.g., 'Dianne''s dog'. This is because PostgreSQL
uses the single quote to encase string constants.** You can include any existing
field that exists for location, even custom fields. The following fields cannot be edited even
if included: 
	- location\_id
	- project_id
	- activity\_id
	- x
	- y
	- lat_dd
	- long_dd
	- latlong
	- georef
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
5. delete\_record (boolean) - Optional, default is false. True to request the record be deleted.

##### Result

Json with the following:

1.  id (integer) – location\_id of the location created, updated or deleted.
2.  message(character varying) - Message containing either "Success" for a successful transaction 
or containing an error description regarding the unsuccessful transaction. Some possible error messages:
	- The json parameter is required for a create/update operation
	- activity\_id is required for a create operation - (When location\_id is null a create operation is assumed an activity\_id is required.)
	- location_id is required for a delete operation - (When delete\_record is true, an location\_id is required.)
	- user\_id is a required parameter for all operations
	- User does NOT have authority to create a new location for activity_id
	- User does NOT have authority to delete this location
	- activity_id is not valid - (the provided activity\_id is either not active or invalid)
	- User does NOT have authority to update this location

##### Example(s)

-   Update the point geometry for location\_id 81118.

```
select * from pmt_edit_location(3, 81118, null, '{"point":"POINT(4.921875 27.308333052145453)"}', false);
```

```
{"id":81118,"message":"Success"}
```

-   Update an existing location to a boundary feature polygon (__Note: Since this is an existing point location, this
will replace the current point with the centroid of the given boundary feature. If a location record has a boundary_id
and feature_id the point is ALWAYS the centroid of the associated feature__). 

```
select * from pmt_edit_location(3, 79564, null, '{"boundary_id":3,"feature_id":25675}', false); 
```

```
{"id":79564,"message":"Success"}
```

-  Create a new location with title for activity\_id 6.

```
select * from pmt_edit_location(3, null, 6, '{"title": "A village in Nepal", "point":"POINT(39.0234375 6.9427857850946015)"}', false); 
```

```
{"id":15821,"message":"Success"}
```

-  Create a new location as a boundary feature polygon for activity\_id 6 (__Note: You do not have to provide a 
point value as it is automatically created as the centroid of the provided polygon__).

```
select * from pmt_edit_location(3, null, 6, '{"boundary_id":3,"feature_id":25675}', false); 
```

```
{"id":15821,"message":"Success"}
```

-  Delete location\_id 81116.

```
select * from pmt_edit_location(3, 81116, null, null, true);
```

```
{"id":81116,"message":"Success"}
```

<a name="edit_location_taxonomy"/>
pmt\_edit\_location\_taxonomy
=============================

##### Description

Edit the relationship between a location and a taxonomy classification. **Important Note: This function DOES NOT 
call the refresh\_taxonomy\_lookup() function, which updates the materialized views that support a majority of the functions
in the database. Be sure to call this function when editing is complete.**

##### Parameter(s)

1.  location\_ids (integer) – **Required**. location_id to edit.
2.  classification\_id (integer) – **Required**.  Classification\_id of taxonomy classification in relationship to the location\_id.
3.  edit\_action (enum) - Optional. 
	Options:
	1. add (default) - will add a relationship between provided location\_id and classification_id
	2. delete - will remove the relationship between the provided location\_id and classification_id
	3. replace - will replace all relationships between the provided location\_ids and taxonomy of the provided classification\_id, with
a single relationship between the provided location\_id and classification\_id.

##### Result

Boolean. Sucessfull (true) or unsuccessful (false). Unsuccessful is usually due invalid parameters or insufficient permissions.

##### Example(s)

-   Add a relationship to Location Reach 'Potential beneficiaries' (classification\_id:975) to location\_id 722:

```select * from pmt_edit_location_taxonomy(3, 722, 975, 'add');```

	TRUE

-   Remove the relationship to Location Reach 'Experimental farm or nursery' (classification\_id:977) to location\_id 722:

```select * from pmt_edit_location_taxonomy(3, 722, 977, 'delete');```

	TRUE

-   Replace  all relationships to the Location Reach taxonomy with the single relationship to Location Reach 'Action/intervention' 
(classification\_id:974) to location\_id 722:

```select * from pmt_edit_location_taxonomy(3, 722, 974, 'replace');```

	TRUE

<a name="edit_organization"/>
pmt\_edit\_organization
===================

##### Description

Edit a organization.

##### Parameter(s)

1.  user\_id (integer) – **Required**. User\_id of user requesting edits.
2.  organization\_id (integer) – **Required for update and delete operations**. organization\_id of existing organization to update or delete, if left null then a new organization record will be created.
3.  json (json) - **Required**. Key/value pair as json of field/values to edit. Column names are 
case sensitive. Enclose all values in double quotes, including null. **If your text values include
a single quote, use two adjacent single quotes, e.g., 'Dianne''s dog'. This is because PostgreSQL
uses the single quote to encase string constants.** You can include any existing
field that exists for organization, even custom fields. The following fields cannot be edited even
if included: 
	- organization\_id
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
4. delete\_record (boolean) - Optional, default is false. True to request the record be deleted.

##### Result

Json with the following:

1.  id (integer) – organization\_id of the organization created or updated.
2.  message(character varying) - Message containing either "Success" for a successful transaction 
or containing an error description regarding the unsuccessful transaction. Possible error messages:
	- Must included user\_id and json data parameters - Received when both required parameters are not provided.
	- User does NOT have authority to create a new organization - Received when the user\_id provided does not have authority to create under current role.
	- User does NOT have authority to update an existing organization - Received when the user\_id provided does not have authority to update under current role.
	- Invalid organization\_id - Received when the organization\_id provided is invalid.

##### Example(s)

-   Update the email and url for CIAT (organization\_id:25) as user sparadee (user\_id:34)

```
select * from pmt_edit_organization(34,25,'{"email":"ciatk@mail.com", "url":"www.ciat.org"}', false);
```

```
{"id":25,"message":"Success"}
```

-   Add new organization as user sparadee (user\_id:34)

```
select * from pmt_edit_organization(34,null,'{"name":"SpatialDev", "url":"www.spatialdev.com", 
"email":"info@spatialdev.com"}', false);
```

```
{"id":672,"message":"Success"}
```

-   Delete organization\_id 672 as user sparadee (user\_id:34)

```
select * from pmt_edit_organization(34,672,null, true);
```

```
{"id":672,"message":"Success"}
```

<a name="edit_participation"/>
pmt\_edit\_participation
=============================

##### Description

Edit the relationship between projects, activities and organizations.

##### Parameter(s)

1.  user\_id (integer) – **Required**. User\_id of user requesting edits.
2.  participation\_id (integer) – **Required when edit\_activity option is delete**. participation\_id of participation record to edit.
3.  project\_id (integer) – **Required for project participation when edit\_activity option is add/replace**. Project\_id of project that organization has participation in.
4.  activity\_id (integer) – **Required for activity participation when edit\_activity option is add/replace**. Activity\_id of activity that organization has participation in.
5.  organiation\_id (integer) – **Required when edit\_activity option is add/replace***.  Organiation\_id of organization that is participating in the project/activity.
6.  classification\_id (integer) – **Required when edit\_activity option is add/replace***.  Classification\_id from Organisation Role taxonomy that represents the organization's
participation role in the project/activity.
7.  edit\_activity (enum) - Optional. 
	Options:
	1. add (default) - will add a participation record to project/activity.
	2. delete - will remove  a participation record.
	3. replace - will replace all existing all existing participation records with the new participation record for the project/activity **make sure you understand what this is doing before requesting this edit action***

##### Result

Json with the following:

1.  id (integer) – organization\_id of the organization created or updated.
2.  message(character varying) - Message containing either "Success" for a successful transaction 
or containing an error description regarding the unsuccessful transaction.

##### Example(s)

-   Add IFPRI (organization\_id:519) as an Implementing (classification\_id:497) organization for 'STAPLE CROPS PROGRAMME' project 
(project\_id:463) activity 'P008-09-P1-08-008-Integrated Striga Management For Improved Sorghum Productivity In East And Central Africa'
(activity\_id:1653) as user sparadee (user\_id:34):

```select * from pmt_edit_participation(34, null, 463, 1653, 519, 497, 'add');```

```{"id":618,"message":"Success"}```

-   Delete IFPRI as an Implementing organization for 'STAPLE CROPS PROGRAMME' project activity 'P008-09-P1-08-008-Integrated Striga Management 
For Improved Sorghum Productivity In East And Central Africa'(participation\_id:10708) as user sparadee (user\_id:34):

```select * from pmt_edit_participation(34, 10708, null, null, null, null, 'delete');```

```{"id":10708,"message":"Success"}```

-   Replace **ALL** participation records for 'STAPLE CROPS PROGRAMME' project (project\_id:463) activity 
'P008-09-P1-08-008-Integrated Striga Management For Improved Sorghum Productivity In East And Central Africa'
(activity\_id:1653) with IFPRI as an Implementing organization as user sparadee (user\_id:34). 

```select * from pmt_edit_participation(34, null, 463, 1653, 519, 497, 'replace');```

```{"id":1058,"message":"Success"}```

<a name="edit_project"/>
pmt\_edit\_project
===================

##### Description

Edit a project.

##### Parameter(s)

1.  user\_id (integer) – **Required**. User\_id of user requesting edits.
2.  project\_id (integer) – **Required for delete and update operations**. project\_id of project to update or delete.
4.  json (json) - **Required for create and update operations**. Key/value pair as json of field/values to edit. Column names are 
case sensitive. Enclose all values in double quotes, including null. **If your text values include
a single quote, use two adjacent single quotes, e.g., 'Dianne''s dog'. This is because PostgreSQL
uses the single quote to encase string constants.** You can include any existing
field that exists for project, even custom fields. The following fields cannot be edited even
if included: 
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
5. delete\_record (boolean) - Optional, default is false. True to request the record be deleted.

##### Result

Json with the following:

1.  id (integer) – project\_id of the project created, updated or deleted.
2.  message(character varying) - Message containing either "Success" for a successful transaction 
or containing an error description regarding the unsuccessful transaction. Some possible error messages:
	- Must included json parameter when delete_record is false.
	- User does NOT have authority to create a new project.
	- User does NOT have authority to delete this project.
	- User does NOT have authority to update this project.
	- Invalid project_id.

##### Example(s)

-   Update the title, description and start_date for project\_id 14 and set the url to null. 

```
select * from pmt_edit_project(34,14, '{"title": "Project Objective 1", 
"description":"Market opportunities, Policies and Partnerships", "start_date":"9-2-2012", "url": "null"}', 
false);
```

```
{"id":14,"message":"Success"}
```

-  Create a new project.

```
select * from pmt_edit_project(34, null, '{"title": "A New project", "description":"Doing some good work in 
Nepal", "start_date":"6-1-2014", "end_date":"5-31-2016"}', false);
```

```
{"id":45,"message":"Success"}
```

-  Delete project\_id 45.

```
select * from pmt_edit_project(34, 45, null, true);

```

```
{"id":45,"message":"Success"}
```

<a name="edit_project_contact"/>
pmt\_edit\_project\_contact
=============================

##### Description

Edit the relationship between an project and a contact.

##### Parameter(s)

1.  user\_id (integer) – **Required**. User\_id of user requesting edits.
2.  project\_id (integer) – **Required**. Project\_id of project to edit.
2.  contact\_id (integer) – **Required**.  Contact\_id of contact to associate to project\_id.
3.  edit\_action (enum) - Optional. 
	Options:
	1. add (default) - will add a relationship between provided project\_id and contact\_id
	2. delete - will remove the relationship between the provided project\_id and contact\_id
	3. replace - will replace all existing relationships to the provided project\_id with any contact, with the contact 
of the provided contact\_id.

##### Result

Boolean. Sucessfull (true) or unsuccessful (false). Unsuccessful is usually due invalid parameters or 
user does not have authorization to edit. Use [pmt\_validate\_user\_authority](#validate_user_authority)
to determine authorization.

##### Example(s)

-   Add Don John (contact\_id:169) as a contact for project\_id 14 as user sparadee (user\_id:34):

```select * from pmt_edit_project_contact(34,14, 169, 'add');```

	TRUE

-   Replace all contacts with Edward Jones (contact\_id:145) for project\_id 14 as user sparadee (user\_id:34):

```select * from pmt_edit_project_contact(34,14, 145, 'replace');```

	TRUE

-   Delete Edward Jones (contact\_id:145) as contact for project\_id 14 as user sparadee (user\_id:34):

```select * from pmt_edit_project_contact(34,14, 145, 'delete');```

	TRUE

<a name="edit_project_taxonomy"/>
pmt\_edit\_project\_taxonomy
=============================

##### Description

Edit the relationship between a project and a taxonomy classification. **Important Note: This function DOES NOT 
call the refresh\_taxonomy\_lookup() function, which updates the materialized views that support a majority of the functions
in the database. Be sure to call this function when editing is complete.**

##### Parameter(s)

1.  project\_ids (integer) – **Required**. Project_id to edit.
2.  classification\_id (integer) – **Required**.  Classification\_id of taxonomy classification in relationship to the project\_id.
3.  edit\_action (enum) - Optional. 
	Options:
	1. add (default) - will add a relationship between provided project\_id and classification_id
	2. delete - will remove the relationship between the provided project\_id and classification_id
	3. replace - will replace all relationships between the provided project\_ids and taxonomy of the provided classification\_id, with
a single relationship between the provided project\_id and classification\_id.

##### Result

Boolean. Sucessfull (true) or unsuccessful (false). Unsuccessful is usually due invalid parameters or insufficient permissions.

##### Example(s)

-   Add a relationship to Data Group 'CRP' (classification\_id:978) to project\_id 15:

```select * from pmt_edit_project_taxonomy(3, 15, 978, 'add');```

	TRUE

-   Remove the relationship to Data Group 'CRP' (classification\_id:978) to project\_id 15:

```select * from pmt_edit_project_taxonomy(3, 15, 978, 'delete');```

	TRUE

-   Replace  all relationships to the Data Group taxonomy with the relationship to Data Group 'CRP' 
(classification\_id:978) to project\_id 15:

```select * from pmt_edit_project_taxonomy(3, 15, 978, 'replace');```

	TRUE

<a name="filter_csv"/>
pmt\_filter\_csv
=================

##### Description

Create and email a csv of data filtered by classification, organization and date range,
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

Boolean. Sucessfull (true) or unsuccessful (false). Unsuccessful is usually due to the filter
resulting in no data. A csv document of filtered data is created and emailed to the email
address passed.

##### Example(s)

-   Data export for Nepal data group (classification\_id:771) activities for Sector - Education
Policy and Administrative Management (classificatoin\_id:564):

```SELECT * FROM pmt_filter_csv('771,564','','',null,null, 'sparadee@spatialdev.com');```

	TRUE


<a name="filter_iati"/>
pmt\_filter\_iati
=================

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

<a name="filter_locations"/>
pmt\_filter\_locations
======================

##### Description

Filter locations by classification, organization and date range,
reporting a specified taxonomy.

##### Parameter(s)

1.  tax\_id (integer) – **Required**. Taxonomy\_id to classify returned
    locations.
2.  classification\_ids (character varying) – Optional. Restrict data to
    classification(s).
3.  organization\_ids (character varying) – Optional. Restrict data to
    organization(s)
4.  unassigned\_tax\_ids (character varying) – Optional. Include data
    without assignments to specified taxonomy(ies).
5.  start\_date (date) – Optional. Restrict data to a data range. Used
    with end\_date parameter.
6.  end\_date (date) – Optional. Restrict data to a data range. Used
    with start\_date parameter.

##### Result

Ordered  by georef.

1.  l\_id (integer) – Location\_id.
2.  r\_ids (text) – comma separated list of classification\_ids
    associated to location from taxonomy specified by tax\_id.

##### Example(s)

-   Locations by Focus Crop taxonomy (taxonomy\_id:22) where there are
    Legumes (classification\_id:816) or no Focus Crop and BMGF
    (organization\_id:13 )is a participant:

```SELECT * FROM pmt_filter_locations(22, '816', '13', '22', null, null);```

| l\_id                   | r\_ids                  |
|-------------------------|-------------------------|
| 2690                    |"816,818,819,820,822,841"|
| 2710                    |"816,818,819,820,822,841"|
| 4674                    |"816,818,819,820,822,841"|
| …                       | …                       |

<a name="filter_orgs"/>
pmt\_filter\_orgs
=================

##### Description

Filter locations by classification, organization and date range,
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

##### Result

Ordered  by georef.

1.  l\_id (integer) – Location\_id.
2.  r\_ids (text) – comma separated list of organization\_ids related to
    location.

##### Example(s)

-   Locations by organization for World Bank data group
    (classification\_id:722) in the country of Bolivia
    (classification\_id:50):

```SELECT * FROM pmt_filter_orgs('772,50', '', '', null, null);```

| l\_id                   | r\_ids                  |
|-------------------------|-------------------------|
| 35814                   | "365,443,939"           |
| 35919                   | "365,443,941"           |
| 35539                   | "365,443,933"           |
| …                       | …                       |

<a name="filter_projects"/>
pmt\_filter\_projects
=====================

##### Description

Filter projects by classification, organization and date range.

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

##### Result

Ordered  by project\_id.

1.  p\_id (integer) – project\_id.
2.  a\_ids (text) – comma separated list of filtered activity\_ids
    associated to the project.

##### Example(s)

-   Projects for AGRA data group (classification\_id:769) where AGRA
    (organization\_id:27) is a participant with activities between Jan
    1, 2010 to Jan 1, 2012:

```SELECT * FROM pmt_filter_projects( '769', '27', '', '1-1-2010', '1-1-2012');```

| p\_id                                | a\_ids                               |
|--------------------------------------|--------------------------------------|
| 661                                  | "13053,13195,13238,13261"            |
| 662                                  | "13034,13209"                        |
| 663                                  | "13147,13151"                        |
| …                                    | …                                    |

<a name="global_search"/>
pmt\_global\_search
=====================

##### Description

Searches title, description and tag columns of both activity and project tables for the search text.

##### Parameter(s)

1.  search\_text (text) – **Required**. Text string to search in activity and project tables.

##### Result

Json with the following:

1.  type (text) – (p) for project record  and (a) for activity record.
2.  id (integer) – project id or activity id, dependent on type.
3.  title (character varying) – title of project or activity, dependent on type.
4.  description (character varying) – description of project or activity, dependent on type.
5.  tags (character varying) – tags of project or activity,  dependent on type.
6.  p_ids (integer[]) - array of project ids related to record.
7.  a_ids (integer[]) - array of activity ids related to record.
8.  dg_id (integer[]) - array of data group ids related to record.


##### Example(s)

-   Search for the term 'rice':

```SELECT * FROM pmt_global_search('rice');```

```
...
{
	"type":"a",
	"id":1152,
	"title":"ASDP",
	"desc":"To install Rice processing plant at Mwamapuli village by June 2012",
	"tags":null,
	"p_ids":[2],
	"a_ids":[1152],
	"dg_id":[768]
}
...
{
	"type":"a",
	"id":701,
	"title":"ASDP",
	"desc":"To excavate and line 2600 m of the main canal of Iyendwe irrigation scheme by June 2012",
	"tags":"Rice",	
	"p_ids":[2],
	"a_ids":[701],
	"dg_id":[768]
}
...

```
<a name="iati_import"/>
pmt\_iati\_import
=================

##### Description

Imports an IATI Activities formatted xml document, with the option to replace or append. 

* **Depending on the size of the document
and the size of the database this function could take several minutes to run!!**

##### Parameter(s)

1. file_path (text) – **Required**. Path to IATI Activities formated xml document.
2. data_group_name (character varying) - **Required**. Name of the data group. If data group does not exist it will be created.
3. replace_all (boolean) **Required**. **True - delete all data in the data group and replace with imported file data.** False - just add the imported data to the data group.


##### Result

True (success) or false (unsuccessful).

##### Example(s)

```SELECT * FROM pmt_iati_import('/usr/local/pmt_iati/BoliviaIATI.xml', 'Bolivia', true);```

TRUE

<a name="infobox_activity"/>
pmt\_infobox\_activity
=============================

##### Description

All information for a single activity.

##### Parameter(s)

1. activity_id (integer) - **Required.** Activity id.

##### Result

Json with the following:

1.  activity\_id (integer) – activity id.
2.  project\_id (integer) – project id of activity.
3.  title (character varying) – title of activity.
4.  label (character varying) – short title for activity.
5.  description (character varying) – description of activity.
6.  content (character varying) – various content for activity.
7.  start\_date (date) – start date of activity.
8.  end\_date (date) – end date of activity.
9.  tags (character varying) – tags or keywords of activity.
10.  iati\_identifier (integer) – iati idenifier or primary key of activity.
11.  updated\_by (character varying(50)) -  last user to update activity information.
12.  updated\_date (timestamp) -  last date and time activity information was updated.
13.  custom\_fields (various) - any custom fields in the activity table that are not in the Core PMT will be returned as well.
14.  location\_ct (integer) - number of locations for activity.
15.  admin\_bnds (character varying) - list of GAUL administrative boundaries for all locations (format gaul_2, gaul_1, gaul_0). Multiple
locations are seperated by a semi-colon (;).
16.  taxonomy(object) - An object containing all associated taxonomy for the activity
	1. taxonomy\_id (integer) - taxonomy id.
	2. taxonomy (character varying) - taxonomy name.
	3. classification\_id (integer) - classification id.
	4. classification (character varying) - classification name.
17.  partners(object) - An object containing all activity parners (Organizations having a Implementing or Funding Role in a activity)
	1. organization\_id (integer) - organization id.
	2. name (character varying) - organization name.
	3. taxonomy\_id (integer) - taxonomy id.
	4. taxonomy (character varying) - taxonomy name.
	5. classification\_id (integer) - classification id.
	6. classification (character varying) - classification name.
18.  contacts (character varying) - An object containing all activity contacts.
	1. contact\_id (integer) - contact id.
	2. first\_name (character varying) - contact's first name.
	3. last\_name (character varying) - contact's last name.
	4. organization\_id (integer) - organization id.
	5. name (character varying) - organization name the contact is associated with.

##### Example(s)

```select * from pmt_infobox_activity(14941);```

```
{
	"activity_id":14941
	,"project_id":764
	,"title":"National coordination"
	,"label":null
	,"description":"National coordination"
	,"content":null
	,"start_date":"2011-03-19"
	,"end_date":"2014-02-28"
	,"tags":null
	,"updated_by":"BMGF Data Scrub"
	,"updated_date":"2014-01-28"
	,"location_ct":1
	,"admin_bnds":"Uganda,Kampala,Central Kampala"
	,"taxonomy":[{
		"taxonomy_id":17
		,"taxonomy":"Sub-Initiative"
		,"classification_id":774
		,"classification":"Data & Priority Setting Platforms"
		}]
	,"partners":[{
		"organization_id":1547
		,"name":"Kickstart"
		,"taxonomy_id":10
		,"taxonomy":"Organisation Role"
		,"classification_id":497
		,"classification":"Implementing"
		}]
	,"contacts":null
}
```

<a name="infobox_activity_contact"/>
pmt\_infobox\_activity\_contact
=============================
**SCHEDULED TO BE DEPRECATED IN DATABASE ITERATION 9**
##### Description

Contacts and partners for a given activity.

##### Parameter(s)

1. activity_id (integer) - **Required.** Activity id.

##### Result

Json with the following:

1.  activity\_id (integer) – activity\_id.
2.  partners(character varying) - List of activity parners (Organizations having a Implementing or Funding Role in a activity)
3.  contacts (character varying) - List of activity contacts.


##### Example(s)

```select * from pmt_infobox_activity_contact(1);```

```
{
	"activity_id":1
	,"partners":"FAO/ UNEP/ UNDP,MNRT, TFS,Tanzania Forestry Service (TFS)"
	,"contacts":"Almas Kashindye"
}
```

<a name="infobox_activity_desc"/>
pmt\_infobox\_activity\_desc
=============================
**SCHEDULED TO BE DEPRECATED IN DATABASE ITERATION 9**
##### Description

Description for a given activity.

##### Parameter(s)

1. activity_id (integer) - **Required.** Activity id.

##### Result

Json with the following:

1.  activity\_id (integer) – activity\_id.
2.  description (character varying) - description of activity


##### Example(s)

```select * from pmt_infobox_activity_desc(1);```

```
{
	"activity_id":1
	,"description":"The project aims at strengthening Tanzanias readiness for Reducing Emissions 
			from Deforestation and forest Degradation (REDD) as a component of the Governments 
			evolving REDD Strategy, and integrate it with other REDD activities in the country"
}
```

<a name="infobox_activity_stats"/>
pmt\_infobox\_activity\_stats
=============================
**SCHEDULED TO BE DEPRECATED IN DATABASE ITERATION 9**
##### Description

Quick stats for a given activity.

##### Parameter(s)

1. activity_id (integer) - **Required.** Activity id.

##### Result

Json with the following:

1.  activity\_id (integer) – activity\_id.
2.  start\_date (date) - start date of activity.
3.  end\_date (date) - end date of activity.
4.  sector (character varying) - Sector taxonomy assignement.
5.  status (character varying) - Activity Status taxonomy assignment.
6.  location (character varying) - List of GAUL administrative boundaries for all locations (format gaul_2, gaul_1, gaul_0)
7.  keywords (character varying) - List of keywords assigned to activity.


##### Example(s)

```select * from pmt_infobox_activity_stats(1);```

```
{
	"activity_id":1
	,"start_date":"2009-10-01"
	,"end_date":"2013-12-31"
	,"sector":"Environmental policy and administrative management"
	,"status":"No Data Entered"
	,"location":"Manyoni, Singida, United Republic of Tanzania"
	,"keywords":"No Data Entered"
}
```

<a name="infobox_project_contact"/>
pmt\_infobox\_project\_contact
=============================

##### Description

Contacts and partners for a given project.

##### Parameter(s)

1. project_id (integer) - **Required.** Project id.

##### Result

Json with the following:

1.  project\_id (integer) – project\_id.
2.  partners(character varying) - List of project parners (Organizations having a Implementing or Funding Role in a activity)
3.  contacts (character varying) - List of project contacts.


##### Example(s)

```select * from pmt_infobox_project_contact(1);```

```
{
	"project_id":1
	,"partners":"No Data Entered"
	,"contacts":"No Data Entered"
}
```

<a name="infobox_project_desc"/>
pmt\_infobox\_project\_desc
=============================

##### Description

Description for a given project.

##### Parameter(s)

1. project_id (integer) - **Required.** Project id.

##### Result

Json with the following:

1.  project\_id (integer) – project\_id.
2.  title (character varying) - title of project
2.  description (character varying) - description of project

##### Example(s)

```select * from pmt_infobox_project_desc(1);```

```
{
	"project_id":1
	,"title":"IATI Activities XML Import"
	,"description":"No Data Entered"
}
```

<a name="infobox_project_info"/>
pmt\_infobox\_project\_info
=============================

##### Description

Information for a given project.

##### Parameter(s)

1. project_id (integer) - **Required.** Project id.
2. taxonomy_id (integer) - Optional. Default is Data Group. Taxonomy used to report locations by.

##### Result

Json with the following:

1.  project\_id (integer) – project\_id.
2.  title (character varying) - Project title.
3.  org_name (character varying) - Organization name participating in project.
4.  org_url (character varying) - Organization url of organization participating in project.
5.  sector (character varying) - Sector taxonomy assignement
5.  keywords (character varying) - List of keywords assigned to project
5.  project_url (character varying) - Project url
5.  l_ids (object) - json object of locations
	1. lat (decimal) - latitude
	2. long (decimal) - longitude
	3. c_id (integer) - classification_ids assigned from taxonomy id provided or default (Data Group)


##### Example(s)

```select * from pmt_infobox_project_info(2, 15);```

```
{
	"project_id":2
	,"title":"IATI Activities XML Import"
	,"org_name":"LGAs"
	,"org_url":""
	,"sector":"No Data Entered"
	,"keywords":"No Data Entered"
	,"project_url":"No Data Entered"
	,"l_ids":
		[
			...
			{
			"lat":-11.316670
			,"long":34.83333
			,"c_id":"624,658,661,662,663,665,669,672"	
			}
			...
		]
}
```

<a name="infobox_project_stats"/>
pmt\_infobox\_project\_stats
=============================

##### Description

Quick stats for a given project.

##### Parameter(s)

1. project_id (integer) - **Required.** Project id.

##### Result

Json with the following:

1.  project\_id (integer) – project\_id.
2.  start\_date (date) - start date of project
3.  end\_date (date) - end date of project
4.  sector (character varying) - Sector taxonomy assignement.
5.  grant (decimal) - total amount of money associated to activity.


##### Example(s)

```select * from pmt_infobox_project_stats(1);```

```
{
	"project_id":1
	,"start_date":null
	,"end_date":null
	,"sector":"No Data Entered"
	,"grant":null
}
```

<a name="isdate"/>
pmt\_isdate
===========

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

<a name="isnumeric"/>
pmt\_isnumeric
==============

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

<a name="locations"/>
pmt\_locations
=============================

##### Description

All information for one or more locations.

##### Parameter(s)

1. location\_ids (character varying) - **Required.** Comma delimited list of location_ids.

##### Result

Json with the following:

1.  location\_id (integer) – location id.
2.  activity\_id (integer) – activity id of location.
3.  project\_id (integer) – project id of location.
4.  boundary\_id (integer) – boundary id of location's associated boundary layer.
5.  feature\_id (integer) – feature id of location's associated boundary feature.
6.  title (character varying) – title of location.
7.  description (character varying) – description of location.
8.  x (numeric) – x coordinate.
9.  y (numeric) – y coordinate.
10.  lat_dd (numeric) – latitude decimal degrees.
11.  long_dd (numeric) – longitude decimal degrees.
12.  latlong (character varying) – latitude and longitude.
13.  georef (character varying) – geo-reference format.
14.  updated\_by (character varying(50)) -  last user to update activity information.
15.  updated\_date (timestamp) -  last date and time activity information was updated.
16.  custom\_fields (various) - any custom fields in the activity table that are not in the Core PMT will be returned as well.
17.  taxonomy(object) - An object containing all associated taxonomy for the activity
	1. taxonomy\_id (integer) - taxonomy id.
	2. taxonomy (character varying) - taxonomy name.
	3. classification\_id (integer) - classification id.
	4. classification (character varying) - classification name.
	5. code (character varying) - classification code.
18.  point (object) - An object containing geoJson representation of the point feature
19.  polygon (object) - An object containing geoJson representation of the associated polygon feature


##### Example(s)

```select * from pmt_locations('79564,39489');```

```
{
	"location_id":79564
	,"project_id":15
	,"activity_id":80
	,"title":null
	,"description":null
	,"x":1496805
	,"y":1833818
	,"lat_dd":16.251080
	,"long_dd":13.44603
	,"latlong":"16°15'4\"N 13°26'46\"E"
	,"georef":"NHPB26461504"
	,"updated_by":"super"
	,"updated_date":"2014-05-05 22:40:42.741879"
	,"boundary_id":3,
	,"feature_id":25675,
	,"taxonomy":[
		{
		"taxonomy_id":5
		,"taxonomy":"Country"
		,"classification_id":185
		,"classification":"NIGER"
		,"code":"NE"
		},{
		"taxonomy_id":25
		,"taxonomy":"Location Class"
		,"classification_id":970
		,"classification":"Administrative Region"
		,"code":"1"
		},{
		"taxonomy_id":26
		,"taxonomy":"Location Reach"
		,"classification_id":974
		,"classification":"Action/intervention"
		,"code":"101"
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

<a name="locations_by_org"/>
pmt\_locations\_by\_org
=======================

##### Description

Filter locations by classification, organization and date range,
reporting associated organization(s).

##### Parameter(s)

1.  class\_id (integer) – Optional. classification\_id to restrict
    organizations by.
2.  data\_group (integer) – Optional. Restrict data to a single data
    group.
3.  country\_ids (character varying) – Optional. Restrict data to
    country(ies).

##### Result

Ordered  by georef.

1.  l\_id (integer) – Location\_id.
2.  x (integer) – x coordinate.
3.  y (integer) – y coordinate.
4.  r\_ids (text) – comma separated list of organization\_ids associated
    to location.

##### Example(s)

-   Locations by organization for World Bank data group
    (classification\_id:772) in the country of Bolivia
    (classification\_id:50):

```SELECT * FROM pmt_locations_by_org (null, 772, '50');```

| l\_id              | x                  | y                  | r\_ids             |
|--------------------|--------------------|--------------------|--------------------|
| 35814              | -7718151           | -1946061           | "365,443,939"      |
| 35919              | -7699599           | -1806653           | "365,443,941"      |
| 35539              | -7690321           | -1822100           | "365,443,933"      |
| …                  | …                  | …                  | …                  |

<a name="locations_by_polygon"/>
pmt\_locations\_by\_polygon
=======================

##### Description

Select locations within a given polygon by activity with a calculated distance from polygon centroid.

##### Parameter(s)

1.  wktPolygon (text) – **Required**. Well-known text representation of a polygon. 

##### Result

Json with the following:

1.  title (character varying) – title of activity
2.  location_ct (inteter) – number of locations found intersecting given polygon for this activity
3.  avg_km (integer) - average distance from the polygon's centroid to the locations found intersecting given polygon for this activity
3.  locations (json object):
	1.  location\_id (integer) – location\_id of location
	2.  lat\_dd (decimal) – latitude of location in decimal degrees
	3.  long\_dd (decimal) – longitude of location in decimal degrees
	4.  taxonomy (object) - listing of taxonomies associated to the location, activity or project
		1. taxonomy\_id (integer) - taxonomy id.
		2. taxonomy (character varying) - the taxonomy name.
		3. classification\_id (integer) - classification id.
		4. classification (character varying) - the classification id.
	4.  organizations (object) - listing of participation organizations in the activity or project
		1. organization\_id (integer) - organization id.
		2. name (character varying) - the organization name.
		1. taxonomy\_id (integer) - taxonomy id.
		2. taxonomy (character varying) - the taxonomy name.
		3. classification\_id (integer) - classification id.
		4. classification (character varying) - the classification id.

##### Example(s)

-   Polygon in the Banjul, Gambia region:

```
select * from pmt_locations_by_polygon('POLYGON((-16.473 13.522,-16.469 13.186,-16.764 13.185,-16.797 
13.491,-16.472 13.517,-16.473 13.522))'); 
```

```
{
	"title":"National coordination"
	,"location_ct":1
	,"avg_km":9
	,"locations":[{
		 	"location_id":7630
			,"lat_dd":13.269500
			,"long_dd":-16.64700
			,"taxonomy":[{
				"taxonomy_id":5
				,"taxonomy":"Country"
				,"classification_id":104
				,"classification":"GAMBIA"
				}
				,{
				"taxonomy_id":17
				,"taxonomy":"Sub-Initiative"
				,"classification_id":774
				,"classification":"Data & Priority Setting Platforms"
				}
				,{
				"taxonomy_id":22
				,"taxonomy":"Focus Crop"
				,"classification_id":820	
				,"classification":"Rice"
				}
				,{
				"taxonomy_id":1
				,"taxonomy":"Data Group"
				,"classification_id":768	
				,"classification":"BMGF"
				}
				,{
				"taxonomy_id":23
				,"taxonomy":"Initiative"
				,"classification_id":831	
				,"classification":"Research & Development"
				}
			}]
			,"organizations":[{
				"organization_id":987
				,"name":"International Rice Research Institute (IRRI)"	
				,"taxonomy_id":10
				,"taxonomy":"Organisation Role"
				,"classification_id":494
				,"classification":"Accountable"
				}
				,{
				"organization_id":13
				,"name":"BMGF"	
				,"taxonomy_id":10
				,"taxonomy":"Organisation Role"
				,"classification_id":496
				,"classification":"Funding"
				}
			}]
		}]
}
...
```

<a name="locations_by_tax"/>
pmt\_locations\_by\_tax
=======================

##### Description

Filter locations by classification, organization and date range,
reporting a specified taxonomy.

##### Parameter(s)

1.  tax\_id (integer) – **Required**. Taxonomy\_id to classify returned
    locations.
2.  data\_group (integer) -  Optional. Restrict data to a single data
    group.
3.  country\_ids (character varying) – Optional. Restrict data to
    country(ies).

##### Result

Ordered  by georef.

1.  l\_id (integer) – Location\_id.
2.  x (integer) – x coordinate.
3.  y (integer) – y coordinate.
4.  r\_ids (text) – comma separated list of classification\_ids
    associated to location from taxonomy specified by tax\_id.

##### Example(s)

-   Locations by Sector taxonomy (taxonomy\_id:10) for World Bank data
    group (classification\_id:772) in the country of Bolivia
    (classification\_id:50):

```SELECT * FROM pmt_locations_by_tax (10, 772, '50');```

| l\_id              | x                  | y                  | r\_ids             |
|--------------------|--------------------|--------------------|--------------------|
| 35814              | -7718151           | -1946061           | "495,496,497"      |
| 35919              | -7699599           | -1806653           | "495,496,497"      |
| 35539              | -7690321           | -1822100           | "495,496,497"      |
| …                  | …                  | …                  | …                  |

<a name="org_inuse"/>
pmt\_org\_inuse
===============

##### Description

Organizations participating in projects or/and activities.

##### Parameter(s)

1.  classification\_ids (character varying) – Optional. Restrict data to
    classification(s).

##### Result

Ordered by most used. Json with the following:

1.  o\_id (integer) – organization\_id.
2.  name (character varying(255)) – name of organization.

##### Example(s)

-   Organizations participating in activities in the AFDB data group
    (classification\_id:768) in Cameroon (classification\_id:62):

```SELECT * FROM pmt_org_inuse('768,62');```

```
{
    "o_id":1,    
    "name":"AfDB"   
}
```

<a name="orgs"/>
pmt\_orgs
=========

##### Description

Get all organizations.

##### Parameter(s)

No parameters.

##### Result

Ordered by organization name. Json with the following:

1.  o\_id (integer) – organization\_id.
2.  name (character varying(255)) – name of organization.

##### Example(s)

```SELECT * FROM pmt_orgs();```

```
...
{
	"o_id":32,
	"name":"CARE International"  
}
...
```

<a name="project"/>
pmt\_project
============

##### Description

All information for a single  project.

##### Parameter(s)

1.  project\_id (integer) – **Required**

##### Result

Json with the following:

1.  project\_id (integer) – project\_id.
2.  title (character varying) – title of project.
3.  label (character varying) – label of project.
4.  description (character varying) – descripton of project.
5.  url (character varying) – url of project.
6.  start\_date (date) – start date of project.
7.  end\_date (date) – end date of project.
8.  tags (character varying) – tags or keywords of project.
9.  updated\_by (character varying(50)) -  last user to update project information.
10.  updated\_date (timestamp) -  last date and time project information was updated.
11.  custom\_fields (various) - any custom fields in the project table that are not in the Core PMT will 
be returned as well.
13.  taxonomy(object) - An object containing all associated taxonomy for the project (does not include 
taxonomy associated to activities)
	1. taxonomy\_id (integer) - taxonomy id.
	2. taxonomy (character varying) - taxonomy name.
	3. classification\_id (integer) - classification id.
	4. classification (character varying) - classification name.
	5. code (character varying) - classification code.
14.  organizations(object) - An object containing all organizations participating in the project (does not include organizations participating in activities)
	1. participation\_id (integer) - participation id for the organization participating in the project
	2. organization\_id (integer) - organization id.
	3. name (character varying) - organization name.
	4. url (character varying) - url for organization.
	5. taxonomy(object) - An object containing all associated taxonomy for the organization
		1. taxonomy\_id (integer) - taxonomy id.
		2. taxonomy (character varying) - taxonomy name.
		3. classification\_id (integer) - classification id.
		4. classification (character varying) - classification name.
		5. code (character varying) - classification code.
15.  contacts (object) - An object containing all project contacts (does not include project activity contacts).
	1. contact\_id (integer) - contact id.
	2. first\_name (character varying) - contact's first name.
	3. last\_name (character varying) - contact's last name.
	4. email (character varying) - contact's email address.
	5. organization\_id (integer) - organization id.
	6. name (character varying) - organization name the contact is associated with.
16.  details (object) - An object containing all project details.
	1. detail\_id (integer) - detail id.
	2. title (character varying) - the title of the detail.
	3. description (character varying) - the description of the detail.
	4. amount (character varying) - the amount of the detail.
20.  financials (object) - An object containing all activity financial data.
	1. financial\_id (integer) - financial id.
	2. amount (numeric (100,2)) - financial amount.	
	3. taxonomy(object) - An object containing all associated taxonomy for the financial record
		1. taxonomy\_id (integer) - taxonomy id.
		2. taxonomy (character varying) - taxonomy name.
		3. classification\_id (integer) - classification id.
		4. classification (character varying) - classification name.
		5. code (character varying) - classification code.
17.  activity_ids (integer[]) - an array of associated activity_ids.
18.  location_ids (integer[]) - an array of associated location_ids.

##### Example(s)

-   Information for project\_id 753 from the BMGF PMT instance:

```SELECT * FROM  pmt_project(753);```

```
{
    	"project_id":753
    	,"title":"CCRP: Collaborative Crop Research Program"
	,"label":"CCRP: Collaborative Crop Research Program"
	,"description":"CCRP: Collaborative Crop Research Program: To identify, 
		support and facilitate the success of sets of crop research projects designed 
		to overcome constraints to food and nutritional security in sub-Saharan Africa."
	,"url":null
	,"start_date":"2008-10-01"
	,"end_date":"2013-12-31"
	,"tags":null
	,"updated_by":"BMGF Data Scrub"
	,"updated_date":"2014-01-28 00:00:00"
	,"impact":null
	,"people_affected":null
	,"fte":null
	,"opportunity_id":"OPP50336"
	,"taxonomy":[{
		 "taxonomy_id":23
		,"taxonomy":"Initiative"
		,"classification_id":831
		,"classification":"Research & Development"
		,"code":null
		}
		,{
		 "taxonomy_id":1
		,"taxonomy":"Data Group"
		,"classification_id":768
		,"classification":"BMGF"
		,"code":null		
		}
		,{
		 "taxonomy_id":24
		,"taxonomy":"Nutrient Focus"
		,"classification_id":837
		,"classification":"Zinc"
		,"code":null
		}
		...

		]
	,"organizations":"[{
		"organization_id":87
		,"name":"The McKnight Foundation"
		,"url":"mcknight.org"
		,"taxonomy":[{
			"taxonomy_id":10
			,"taxonomy":"Organisation Role"
			,"classification_id":494
			,"classification":"Accountable"
			,"code":"Accountable"
			}]
		},{
		"organization_id":13
		,"name":"BMGF"
		,"url":"www.gatesfoundation.org"
		,"taxonomy":[{
			"taxonomy_id":10
			,"taxonomy":"Organisation Role"
			,"classification_id":496
			,"classification":"Funding"
			,"code":"Funding"
			}]
		}]
	,"contacts":null
	,"details":"[{
		"detail_id":132
		,"title":"Description of Activities Related to Nutrition"
		,"description":"Bean, soybean, and cowpea breeding studies (Report 1.1 8); improved stress tolerance 
			in sorghum (2011 RSA, 2); improved varieties of sorghum, millet, tef (2011 RSA 2) - Cowpea 
			utilization study to improve diets (Report 1.1, 8); Common bean diffusion survey (...)"
		,"amount":null
		},{
		"detail_id":100
		,"title":"Summary of Activities Related to Nutrition"
		,"description":"Developing new crop varieties - Data collection - Creating institutional partnerships 
			- Nutritional Extension - Agricultural extension - Supporting marketing - Strengthening crop 
			delivery"
		,"amount":null
		}
		...
		}]
	,"financials":[{
		"financial_id":1355
		,"amount":260069310.00
		,"taxonomy":null
		}]
	,"activities":"{14697,14695,14694,14693,14692,14691,14690,14689,14688,14687,14686,14685,14684,14683,14682,
			14681,14680,14679,14696,14678,14677,14676,14675,14674,14673,14672,14657,14656,14655,14654,
			14653,14652,14651,14650,14649,14648,14647,14646,14645,14644,14643,14642,146 (...)"}
	,"locations":"{7715,7714,7713,7712,7711,7710,7709,7708,7707,7706,7705,7704,7703,7702,7701,7700,7699,7698,
			7697,7696,7695,7694,7693,7692,7691,7553,7676,7675,7674,7673,7672,7671,7670,7669,7668,7667,
			7666,7665,7664,7663,7662,7661,7660,7659,7658,7657,7656,7655,7654,7653,7652, (...)"}
}
```

<a name="project_listview"/>
pmt\_project\_listview
======================

##### Description

Filter project, activity and organization participation by
classification, organization and date range, reporting a specified
taxonomy with pagination.

##### Parameter(s)

1.  tax\_id (integer) – **Required**. Taxonomy\_id to classify returned
    projects.
2.  classification\_ids (character varying) – Optional. Restrict data to
    classification(s).
3.  organization\_ids (character varying) – Optional. Restrict data to
    organization(s)
4.  unassigned\_tax\_ids (character varying) – Optional. Include data
    without assignments to specified taxonomy(ies).
5.  start\_date (date) – Optional. Restrict data to a data range. Used
    with end\_date parameter.
6.  end\_date (date) – Optional. Restrict data to a data range. Used
    with start\_date parameter.
7.  orderby (text) – Optional. Order by result columns.
8.  limit\_rec (integer) – Optional. Maximum number of returned records.
9.  offset\_rec (integer) – Optional. Number of records to offset the
    return records by.

##### Result

Json with the following:

1.  p\_id (integer) – project\_id.
2.  title (character varying) – title of project.
3.  a\_ids (integer array) – list of activity\_ids for project.
4.  org (character varying) – accountable organization name.
5.  f\_orgs (character varying) – funding organization name(s).
6.  c\_name (character varying) – classification name of classification
    related to  project from the taxonomy specified in tax\_id.

##### Example(s)

-   BMGF data group (classification\_id:768) projects by Initiative
    (taxonomy\_id:23).  Order the data by project title (title). Limit
    the number of rows returned to 10 with an offset of 20 records:

```SELECT * FROM  pmt_project_listview(23, '768', '', '', '1-1-1990','12-31-2014', 'title', 10, 20);```

```
...
{
    	"p_id":615,
    	"title":"Community knowledge workers for Ugandan agriculture",
	"a_ids":[11946,11947,11948,11949,11950,11951,11952,11953,11954,11955,11956,11957,11958,11959,11960,
		11961,11962,11963,11964,11965,11966,11967,11968,11969,11970,11971],
	"org":"Grameen Foundation USA",
	"f_orgs":"BMGF",
	"c_name":"Access & Markets"        

}
...
```

<a name="project_listview_ct"/>
pmt\_project\_listview\_ct
==========================

##### Description

Total record count for pmt\_project\_listview. Sending the same filter
parameters as pmt\_project\_listview will provide the total record
count. Used to assist with pagination.

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

##### Result

Integer of number of records.

##### Example(s)

-   Number of Project records for BMGF data group
    (classification\_id:768):

```SELECT * FROM pmt_project_listview_ct('768', '', '', '1-1-1990','12-31-2014');```

56

<a name="projects"/>
pmt\_projects
=============

##### Description

All projects: project\_id, title and list of activity\_ids.

##### Parameter(s)

None.

##### Result

Json with the following:

1.  project\_id (integer) – project id.
2.  title (character varying) – title of project.
3.  activity\_ids (int[]) – array of activity\_ids related to project.


##### Example(s)

```select * from pmt_projects();```

```
...
},{
	"project_id":15
	,"title":"CGIAR - Policies, Institutions, and Markets"
	,"activity_ids":[121,122,104,105,106,107,108,109,110,119,111,112,113]
},{

	"project_id":16
	,"title":"CGIAR - Agriculture for Nutrition and Health"
	,"activity_ids":[6,28,40,1,2,3,4,5,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23]
},{
	"project_id":13
	,"title":"CGIAR - Aquatic Agricultural Systems"
	,"activity_ids":null
},{
...
```

<a name="purge_activity"/>
pmt\_purge\_activity
==========================

##### Description

Deletes all records assoicated to an activity. **Warning!! This function 
permanently deletes ALL data associated to the given activity id.** Use [pmt\_activate\_activity](#activate_activity)
to deactivate if deletion is not desired. 

*On large PMT instances (i.e. OAM) this function can take 2-3 minutes. This will
recieve an huge performance improvement when editing functions are added to 
the model.*

##### Parameter(s)

1.  a\_id (integer) – **Required**. Activity_id of activity to be deleted.

##### Result
 
Boolean. True/False successful.

##### Example(s)

-   Remove activity_id 101:

```SELECT * FROM pmt_purge_activity(101);```

TRUE

<a name="purge_project"/>
pmt\_purge\_project
==========================

##### Description

Deletes all records assoicated to a project. **Warning!! This function 
permanently deletes ALL data associated to the given project id.** Use [pmt\_activate\_project](#activate_project)
to deactivate if deletion is not desired. 

*On large PMT instances (i.e. OAM) this function can take 2-3 minutes. This will
recieve an huge performance improvement when editing functions are added to 
the model.*

##### Parameter(s)

1.  p\_id (integer) – **Required**. Project_id of project to be deleted.

##### Result
 
Boolean. True/False successful.

##### Example(s)

-   Remove project_id 1:

```SELECT * FROM pmt_purge_project(1);```

TRUE

<a name="sector_compare"/>
pmt\_sector\_compare
====================

##### Description

Allows a comparision of assigned Sector taxonomy and the text value from the IATI Activities Sector xml element from the imported 
document.

##### Parameter(s)

1.  classification\_ids (character varying) – Optional. Comma seperated list of classification_ids to restrict results to.
2.  order\_by (character varying) – Optional. Name of return result field to order results by (see Result section).

##### Result

Json with the following:

1.  a\_id (integer) – activity_id of activity.
2.  c\_id (integer) - classification_id of Sector classification currently assigned to activity.
3.  sector (character varying) - classification name of Sector classification currently assigned to activity.
3.  import (character varying) - text value of the IATI Activities Sector element from the source document used to import the activity data.

##### Example(s)

-   Compare the text value of the XML IATI Activities Sector element from the source document used to import 
the activity data for the Bolivia data group (classification\_id:769) where the Sector 
'Sectors not specified' (classification\_id:756) was assigned and sort by the text value of the IATI Activities 
Sector xml element (result field: 'import'):

```select * from pmt_sector_compare('769,756', 'import');```

```
...
,{
	"a_id":5526,
	"c_id":756,
	"sector":"Sectors not specified",
	"import":"MULTISECTORIAL"
}
,{
	"a_id":7461,
	"c_id":756,
	"sector":"Sectors not specified",
	"import":"RECURSOS HIDRICOS"
}
...
```

<a name="stat_activity_by_district"/>
pmt\_stat\_activity\_by\_district
=============================

##### Description

Statistics function providing activity counts by taxonomy per district for a region.

##### Parameter(s)

1.  data\_group\_id (integer) – Optional. Classification_id of data group to restrict results to.
2.  country (character varying) – **Required**. Name of country (GAUL 0 Administrive Name)
3.  region (character varying) – **Required**. Name of region (GAUL 1 Administrive Name)
4.  activity\_taxonomy\_id (integer) – **Required**. Taxonomy_id of taxonomy to group activity counts by per district.

##### Result

Json with the following:

1.  region (character varying) – name of the region.
2.  district (character varying) – name of the district within region.
3.  activities (json object):
	1.  c\_id (integer) – classification_id of classification within provided activity taxonomy_id.
	2.  name (character varying) – name of classification within provided activity taxonomy_id.
	3.  a\_ct (integer) - number of activities assigned classification within district.

##### Example(s)

-   AGRA data (classification\_id:769) activity counts by Initiative (taxonomy\_id:23) per district for the Morogoro Region:

```select * from pmt_stat_activity_by_district(769, 'United Republic of Tanzania', 'Morogoro', 23);```

```
...
,{
	"region":"Morogoro"
	,"district":"Morogoro Rural"
	,"activities":
		[{
			"c_id":823
			,"name":"Access & Markets"
			,"a_ct":4
		},
		{
			"c_id":831
			,"name":"Research & Development"
			,"a_ct":3
		}]
}
...
```

<a name="stat_activity_by_tax"/>
pmt\_stat\_activity\_by\_tax
============================

##### Description

Statistics function providing filterable counts for activity by
taxonomy.

##### Parameter(s)

1.  tax\_id (integer) – **Required**. Taxonomy\_id to classify returned
    activity counts.
2.  classification\_ids (character varying) – Optional. Restrict data to
    classification(s).
3.  organization\_ids (character varying) – Optional. Restrict data to
    organization(s)
4.  unassigned\_tax\_ids (character varying) – Optional. Include data
    without assignments to specified taxonomy(ies).
5.  start\_date (date) – Optional. Restrict data to a data range. Used
    with end\_date parameter.
6.  end\_date (date) – Optional. Restrict data to a data range. Used
    with start\_date parameter.

##### Result

Json with the following:

1.  c\_id (integer) – classification\_id.
2.  a\_ct (integer) – activity count.

##### Example(s)

-   Activity counts for BMGF data group (classification\_id:768) by
    Sub-Initiative taxonomy (taxonomy\_id:17):

```SELECT * FROM pmt_stat_activity_by_tax(17, '768', '', '17', null, null);```

```
{
    {"c_id":771,"a_ct":220}
    {"c_id":773,"a_ct":297}
    {"c_id":774,"a_ct":155}
    {"c_id":778,"a_ct":18}
    {"c_id":779,"a_ct":16}
    {"c_id":780,"a_ct":1060}
    {"c_id":783,"a_ct":378}
    {"c_id":784,"a_ct":432}
    {"c_id":786,"a_ct":378}
    {"c_id":788,"a_ct":2337}
    {"c_id":791,"a_ct":20}
    {"c_id":null,"a_ct":345}
}
```

<a name="stat_counts"/>
pmt\_stat\_counts
=================

##### Description

Statistics function providing filterable counts for project, activity,
implementing organizations and districts.

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

##### Result

Json with the following:

1.  p\_ct (integer) – project count.
2.  a\_ct (integer) – activity count.
3.  o\_ct (integer) – implementing organization count.
4.  d\_ct (integer) – district count.

##### Example(s)

-   Statistic counts for BMGF data group (classification\_id:768):

```SELECT * FROM pmt_stat_counts('768', '', '', null, null);```

```
{

    "p_ct":80,
    "a_ct":6112,
    "o_ct":602,
    "d_ct":1405
}
```
<a name="stat_orgs_by_activity"/>
pmt\_stat\_orgs\_by\_activity
=============================

##### Description

Statistics function providing filterable counts for TOP TEN implementing
organizations by activity classified by taxonomy.

##### Parameter(s)

1.  tax\_id (integer) – **Required**. Taxonomy\_id to classify returned
    activity counts.
2.  classification\_ids (character varying) – Optional. Restrict data to
    classification(s).
3.  organization\_ids (character varying) – Optional. Restrict data to
    organization(s)
4.  unassigned\_tax\_ids (character varying) – Optional. Include data
    without assignments to specified taxonomy(ies).
5.  start\_date (date) – Optional. Restrict data to a data range. Used
    with end\_date parameter.
6.  end\_date (date) – Optional. Restrict data to a data range. Used
    with start\_date parameter.

##### Result

Json with the following:

1.  o\_id (integer) – organization\_id.
2.  a\_ct (integer) – activity count.
3.  a\_by\_tax (json object):
	1.  c\_id (integer) – classification id.
	2.  a\_ct (integer) – number of activities with classification id in
    a\_ct above.

##### Example(s)

-   Top ten implementing organizations by activity counts for BMGF data
    group (classification\_id:768) by Initiative taxonomy
    (taxonomy\_id:23):

```SELECT * FROM pmt_stat_orgs_by_activity(23, '768', '', '', null, null);```

```
{
    "o_id":334,
    "a_ct":646,
    "a_by_tax":[
		{
			"c_id":823,
			"a_ct":625
		},       
		{
			"c_id":831,
			"a_ct":21
		}
	]
}
...
```

<a name="stat_orgs_by_district"/>
pmt\_stat\_orgs\_by\_district
=============================

##### Description

Statistics function providing organizations with activity counts by district for a region.

##### Parameter(s)

1.  data\_group\_id (integer) – Optional. Classification_id of data group to restrict results to.
2.  country (character varying) – **Required**. Name of country (GAUL 0 Administrive Name)
3.  region (character varying) – **Required**. Name of region (GAUL 1 Administrive Name)
4.  org\_role\_id (integer) – Optional. Classification_id for taxonomy 'Organisation Role'. Default is 'Accountable'. 
5.  top\_limit (integer) – Optional. Limits the number of returned organizations per district to number requested ordered by number of activities. Default is 3. 

##### Result

Json with the following:

1.  region (character varying) – name of the region.
2.  district (character varying) – name of the district within region.
3.  orgs (json object):
	1.  o\_id (integer) – organization id.
	2.  name (character varying) – name of organization.
	3.  a\_ct (integer) - number of activities the organization participates within the 'Organisation Role' classification.

##### Example(s)

-   Top three accountable (classification\_id:494) organizations for AGRA (classification\_id:769) per district 
    for the Morogoro Region:

```select * from pmt_stat_orgs_by_district(769, 'United Republic of Tanzania', 'Morogoro', 494, 3);```

```
...
,{
	"region":"Morogoro"
	,"district":"Morogoro Urban"
	,"orgs":
		[{
			"o_id":27
			,"name":"Alliance for a Green Revolution in Africa (AGRA)"
			,"a_ct":6
		}
		,{
			"o_id":10
			,"name":"Kickstart International"
			,"a_ct":3
		}
		,{
			"o_id":269
			,"name":"Board of Regents of the University of Nebraska"
			,"a_ct":2
		}]
}
...
```

<a name="stat_partner_network"/>
pmt\_stat\_partner\_network
=============================

##### Description

Statistics function providing nested accountable and implementing organizations and activities by funding organization.

##### Parameter(s)

1.  country\_ids (character varying) – Optional. Restrict data to country(ies).

##### Result

Json with the following:

1. name(character varying) – name funding organization.
2. o\_id (integer) - funding organization's id.
	1. children (array) - object array of accountable organizations for the funding organizations activities
		1. name (character varying) - name of accountable organization
		2. children (array) - object array of implementing organizations for the accountable organizations activities
			1. name (character varying) - name of implementing organization
			2. children (array) - object array of activites implemented by the implementing organization
				1. name (character varying) - title of activity

##### Example(s)

-   Partner network for activities in Nigeria (classification\_id:244):

```SELECT * FROM pmt_stat_partner_network('244');```

```
...
[
  {
	"name":"BMGF"
	"o_id":13
	,"children":[
		{
		   "name":"International Institute of Tropical Agriculture (IITA)"
		  ,"children":[
			{
			    "name":"Doreo Partners"
			    ,"children":[
				{
				    "name":"Aflatoxin prevalence study in farmers' fields in Nigeria"
				},
				{
				    "name":"Aflatoxin prevalence study in farmers' fields in Nigeria"
				},
				{
				    "name":"Aflatoxin prevalence study in farmers' fields in Nigeria"
				},
				...
		   	     ]
			}
			...
		   ]
		}
		...
	]
  }
  ...
]
...
```

<a name="stat_pop_by_district"/>
pmt\_stat\_pop\_by\_district
=============================

##### Description

Statistics function providing population data by district for a region.

##### Parameter(s)

1.  country (character varying) – **Required**. Name of country (GAUL 0 Administrive Name)
2.  region (character varying) – **Required**. Name of region (GAUL 1 Administrive Name)

##### Result

Json with the following:

1.  region (character varying) – name of the region.
2.  district (character varying) – name of the district within region.
3.  pop_total (numeric(500,2)): total population of the district.
4.  pop_poverty (numeric(500,2)): poverty population of the district.
5.  pop_rural (numeric(500,2)): rural population of the district.
6.  pop_poverty_rural (numeric(500,2)): rural poverty population of the district.
7.  pop_source (text): source of population data for the district.

##### Example(s)

-   Population data per district for the Morogoro Region:

```select * from pmt_stat_pop_by_district('United Republic of Tanzania', 'morogoro');```

```
...
,{
	"region":"Morogoro",
	"district":"Morogoro Urban",
	"pop_total":307356.00,
	"pop_poverty":50573.40,
	"pop_rural":124967.00,
	"pop_poverty_rural":50573.40,
	"pop_source":"WorldPop"
}
...
```

<a name="stat_project_by_tax"/>
pmt\_stat\_project\_by\_tax
===========================

##### Description

Statistics function providing filterable counts for project by taxonomy

##### Parameter(s)

1.  tax\_id (integer) – **Required**. Taxonomy\_id to classify returned
    project counts.
2.  classification\_ids (character varying) – Optional. Restrict data to
    classification(s).
3.  organization\_ids (character varying) – Optional. Restrict data to
    organization(s)
4.  unassigned\_tax\_ids (character varying) – Optional. Include data
    without assignments to specified taxonomy(ies).
5.  start\_date (date) – Optional. Restrict data to a data range. Used
    with end\_date parameter.
6.  end\_date (date) – Optional. Restrict data to a data range. Used
    with start\_date parameter.

##### Result

Json with the following:

1.  c\_id (integer) – classification\_id.
2.  p\_ct (integer) – project count.

##### Example(s)

-   Project counts for BMGF data group (classification\_id:768) by
    Initiative taxonomy (taxonomy\_id:23):

```SELECT * FROM pmt_stat_project_by_tax(23, '768', '', '', null, null);```

```
{
    {"c_id":823,"p_ct":34}
    {"c_id":824,"p_ct":13}
    {"c_id":829,"p_ct":2}
    {"c_id":831,"p_ct":23}
    {"c_id":839,"p_ct":8}
}
```

<a name="tax_inuse"/>
pmt\_tax\_inuse
===============

##### Description

Taxonomy and associated classifications that are in use by any project,
activity or location.

##### Parameter(s)

1.  data\_group\_id (integer) – Optional. Restrict data to data group.
2.  taxonomy\_ids (character varying) – Optional. Restrict data to
    taxonomy(ies).
3.  country\_ids (character varying) – Optional. Restrict data to
    country(ies).

##### Result

Ordered by most used. Json with the following:

1.  t\_id (integer) – taxonomy\_id.
2.  name (character varying(255)) – name of taxonomy.
3.  Is\_cat (boolean) – is/not a taxonomy category.
4.  cat\_id (integer) – taxonomy\_id of the taxonomy category for this
    taxonomy.
5.  classifications (object) – classifications in use for this taxonomy.
	1.  c\_id (integer) – classification\_id.
	2.  cat\_id (integer) – classification\_id for the category
    classification.
	3.  name (character varying(255)) – the name of the classification.

##### Example(s)

-   Taxonomy/classifications for the World Bank data group
    (classification\_id:772) in Bolivia (classification\_id:50):

```SELECT * FROM pmt_tax_inuse(772, '', '50');```

```
...
{
    "t_id":15,
    "name":"Sector",
    "is_cat":false,
    "cat_id":14,
    "classifications":
        [
            {
                "c_id":731,
                "cat_id":552,
                "name":"Desarrollo rural"
            },
            {
                "c_id":636,
                "cat_id":540,
                "name":"Power generation/renewable sources"
            },
            ...
        ]
},
{
    "t_id":14,
    "name":"Sector Category",
    "is_cat":true,
    "cat_id":16,
    "classifications":
        [
            {
                "c_id":552,
                "cat_id":765,
                "name":"Other multisector"
            },
            ...
            {
                "c_id":540,
                "cat_id":764,
                "name":"ENERGY GENERATION AND SUPPLY"},
            ...
        ]
}
```

<a name="taxonomies"/>
pmt\_taxonomies
===============

##### Description

Taxonomy and associated classifications.

##### Parameter(s)

1.  taxonomy\_ids (character varying) – Optional. Restrict data to taxonomy(ies).

##### Result

Ordered by most used. Json with the following:

1.  t\_id (integer) – taxonomy\_id.
2.  name (character varying(255)) – name of taxonomy.
3.  Is\_cat (boolean) – is/not a taxonomy category.
4.  cat\_id (integer) – taxonomy\_id of the taxonomy category for this
    taxonomy.
5.  classifications (object) – classifications in use for this taxonomy.
	1.  c\_id (integer) – classification\_id.
	2.  cat\_id (integer) – classification\_id for the category
    classification.
	3.  name (character varying(255)) – the name of the classification.

##### Example(s)

-   Taxonomy/classifications for the Sector taxonomy (taxonomy\_id:15):

```select * from pmt_taxonomies('15');```

```
...
{
    "t_id":15,
    "name":"Sector",
    "is_cat":false,
    "cat_id":14,
    "classifications":
        [
	    {
		"c_id":636,
		"cat_id":540,
		"name":"Power generation/renewable sources"
	    },
  	    {
		"c_id":657,
		"cat_id":542,
		"name":"Privatisation"
	    }            
            ...
        ]
}
```

<a name="update_user"/>
pmt\_update\_user
================

##### Description

Update existing user information and/or role.

##### Parameter(s)

1.  user\_id (integer) – **Required**. User id for user being updated.
2.  organization\_id (integer) – Optional. Organization id user will be assigned to.
3.  data\_group\_id (integer) - Optional. Data group id user will be assigned to.
4.  role\_id (integer) – Optional. Role id user will be assigned to.
5.  username (character varying(255)) - Optional. User username.
6.  password (character varying(255)) - Optional. User password.
7.  email (character varying(255)) - Optional. User email address.
8.  first\_name (character varying(150)) - Optional. User first name.
9.  last\_name (character varying(150)) - Optional. User last name.

##### Result

Boolean. Successful (true). Unsuccessful (false).

##### Example(s)

-   Update email for user Jane Doe(user_id:315):

```SELECT * FROM pmt_update_user(315, null, null, null, null, null, 'jane.doe1234@email.com',  null, null);```

```
TRUE
```

<a name="user_auth"/>
pmt\_user\_auth
=============================

##### Description

Authenticate user using a salted and hashed password.

##### Parameter(s)

1.  username (character varying) - **Required**. User's username.
2.  password (character varying) - **Required**. User's password salted and hashed.

##### Result

Json with the following:

1.  user\_id (integer) – user id.
2.  first\_name (character varying) – first name of user.
3.  last\_name (character varying) – last name of user.
4.  username (character varying) – username of user.
5.  email (character varying) – email address of user.
6.  organization\_id (integer) – organization id for organization of user.
7.  authorized\_project\_ids - list of project_ids user has authority to edit.
7.  roles (json object):
	1.  role\_id (integer) – role id user is assigned to.
	2.  name (character varying) – name of role user is assigned to.

##### Example(s)

- Authenticate Reader test user passing its username and hashed and salted password.

```SELECT * FROM pmt_user_auth('johndoe', '$2a$10$.V0ETMIAW6O9z2wekwMG1.PuaYpuJmZTO1W3GCwOOF3UyfjoXKiea');```

```
{
	"user_id":1,
	"first_name":"John",
	"last_name":"Doe",
	"username":"johndoe",
	"email":"test@email.com",
	"organization_id":3,
	"organization":"spatial dev",
	"data_group_id":769,
	"data_group":"ASDP",
	"authorized_project_ids": "661,621,733,443"
	"roles":
		[{
			"role_id":2,
			"name":"Editor"
		}]
}
```
- Authenticate Reader test user passing its username and an invalid hashed and salted password.

```SELECT * FROM pmt_user_auth('reader', '$2a$10$.V0ETMIAW6O9z2wekwMG1.PuaYpuJmZTO1W3GCwOOF3Uyfj3343e');```

```
{
	"message":"Invalid username or password."
}
```
<a name="user_salt"/>
pmt\_user\_salt
================

##### Description

Get the salt for a specific user.

##### Parameter(s)

1.  user\_id (integer) – **Required**. User id for requested salt value.

##### Result

Salt value as text. 

##### Example(s)

-   Salt value for test user Reader(user_id:1):

```select * from pmt_user_salt(1);```

```
$2a$10$.V0ETMIAW6O9z2wekwMG1.
```

<a name="users"/>
pmt\_users
=============================

##### Description

Get all user and role information.

##### Parameter(s)

No parameters.

##### Result

Json with the following:

1.  user\_id (integer) – user id.
2.  first\_name (character varying) – first name of user.
3.  last\_name (character varying) – last name of user.
4.  username (character varying) – username of user.
5.  email (character varying) – email address of user.
6.  organization\_id (integer) – organization id for organization of user.
7.  roles (json object):
	1.  role\_id (integer) – role id user is assigned to.
	2.  name (character varying) – name of role user is assigned to.

##### Example(s)

```SELECT * FROM pmt_users();```

```
...
{
	"user_id":315,
	"first_name":"Jane",
	"last_name":"Doe",
	"username":"myusername",
	"email":"jane.doe@email.com",
	"organization_id":13,
	"organization": "BMGF",
	"data_group_id":768,
	"data_group": "BMGF",
	"roles":[{
			"role_id":2,
			"name":"Editor"
		}]
}
...
```

<a name="validate_activities"/>
pmt\_validate\_activities
===========================

##### Description

Validate list of activity\_ids.

##### Parameter(s)

1. activity\_ids (character varying) - **Required**. comma seperated list of activity_ids to validate.

##### Result

Integer array of valid ACTIVE activity_ids.

##### Example(s)

```SELECT * FROM pmt_validate_activities('11879,15432,15725,122');```

| integer[]   |
|-------------|
| {11879,15432,15725}|

<a name="validate_activity"/>
pmt\_validate\_activity
===========================

##### Description

Validate an activity\_id.

##### Parameter(s)

1. activity\_id (integer) - **Required**. activity_id to validate.

##### Result

Boolean. True/False valid.

##### Example(s)

```SELECT * FROM pmt_validate_activity(11879);```

TRUE

<a name="validate_boundary_feature"/>
pmt\_validate\_boundary\_feature
===========================

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

<a name="validate_classification"/>
pmt\_validate\_classification
===========================

##### Description

Validate a classification\_id.

##### Parameter(s)

1. classification\_id (integer) - **Required**. classification_id to validate.

##### Result

Boolean. True/False valid.

##### Example(s)

```SELECT * FROM pmt_validate_classification(768);```

TRUE

<a name="validate_classifications"/>
pmt\_validate\_classifications
==============================

##### Description

Validate list of classification\_ids.

##### Parameter(s)

1. classification\_ids (character varying) - **Required**. comma seperated list of classification_ids to validate.

##### Result

Integer array of valid ACTIVE classification_ids.

##### Example(s)

```SELECT * FROM pmt_validate_classifications('50,9999,720');```

| integer[]   |
|-------------|
| {50,720}|

<a name="validate_contact"/>
pmt\_validate\_contact
===========================

##### Description

Validate a contact\_id.

##### Parameter(s)

1. contact\_id (integer) -  **Required**. contact_id to validate.

##### Result

Boolean. True/False valid.

##### Example(s)

```SELECT * FROM pmt_validate_contact(169);```

TRUE

<a name="validate_contacts"/>
pmt\_validate\_contacts
==============================

##### Description

Validate list of contact\_ids.

##### Parameter(s)

1. contact\_ids (character varying) - **Required**. comma seperated list of contact_ids to validate.

##### Result

Integer array of valid ACTIVE contact_ids.

##### Example(s)

```SELECT * FROM pmt_validate_contacts('169,145,9999');```

| integer[]   |
|-------------|
| {145,169}|

<a name="validate_detail"/>
pmt\_validate\_detail
===========================

##### Description

Validate a detail\_id.

##### Parameter(s)

1. detail\_id (integer) -  **Required**. detail_id to validate.

##### Result

Boolean. True/False valid.

##### Example(s)

```SELECT * FROM pmt_validate_detail(169);```

TRUE

<a name="validate_financial"/>
pmt\_validate\_financial
===========================

##### Description

Validate a financial\_id.

##### Parameter(s)

1. financial\_id (integer) -  **Required**. financial_id to validate.

##### Result

Boolean. True/False valid.

##### Example(s)

```SELECT * FROM pmt_validate_financial(19);```

TRUE

<a name="validate_location"/>
pmt\_validate\_location
===========================

##### Description

Validate a location\_id.

##### Parameter(s)

1. location\_id (integer) -  **Required**. location_id to validate.

##### Result

Boolean. True/False valid.

##### Example(s)

```SELECT * FROM pmt_validate_location(19);```

TRUE

<a name="validate_organization"/>
pmt\_validate\_organization
===========================

##### Description

Validate a organization\_id.

##### Parameter(s)

1. organization\_id (integer) - **Required**. organization_id to validate.

##### Result

Boolean. True/False valid.

##### Example(s)

```SELECT * FROM pmt_validate_organization(13);```

TRUE

<a name="validate_organizations"/>
pmt\_validate\_organizations
==============================

##### Description

Validate list of organization\_ids.

##### Parameter(s)

1. organization\_ids (character varying) - **Required**. comma seperated list of organization_ids to validate.

##### Result

Integer array of valid ACTIVE organization_ids.

##### Example(s)

```SELECT * FROM pmt_validate_organizations('13,27,2');```

| integer[]   |
|-------------|
| {13,27}|

<a name="validate_project"/>
pmt\_validate\_project
===========================

##### Description

Validate a project\_id.

##### Parameter(s)

1. project\_id (integer) - **Required**. project_id to validate.

##### Result

Boolean. True/False valid.

##### Example(s)

```SELECT * FROM pmt_validate_project(13);```

TRUE

<a name="validate_projects"/>
pmt\_validate\_projects
==============================

##### Description

Validate list of project\_ids.

##### Parameter(s)

1. project\_ids (character varying) - **Required**. comma seperated list of project_ids to validate.

##### Result

Integer array of valid ACTIVE project_ids.

##### Example(s)

```SELECT * FROM pmt_validate_projects('12,1,4,6,15,89');```

| integer[]   |
|-------------|
| {1,4,6,12,15}|

<a name="validate_taxonomies"/>
pmt\_validate\_taxonomies
===========================

##### Description

Validate list of taxonomy\_ids.

##### Parameter(s)

1. taxonomy\_ids (character varying) - **Required**. comma seperated list of taxonomy_ids to validate.

##### Result

Integer array of valid ACTIVE taxonomy_ids.

##### Example(s)

```SELECT * FROM pmt_validate_taxonomies('5,10,99');```

| integer[]   |
|-------------|
| {5,10}|

<a name="validate_taxonomy"/>
pmt\_validate\_taxonomy
===========================

##### Description

Validate an taxonomy\_id.

##### Parameter(s)

1. taxonomy\_id (integer) - **Required**. taxonomy_id to validate.

##### Result

Boolean. True/False valid.

##### Example(s)

```SELECT * FROM pmt_validate_taxonomy(1);```

TRUE

<a name="validate_user_authority"/>
pmt\_validate\_user\_authority
==============================

##### Description

Validate a user's authority to edit a project id and the level of authority (CRUD).

##### Parameter(s)

1. user\_id (integer) - **Required**. user_id of user to validate authority for.
2. project\_id (integer) - project_id to validate authority for user to edit.
3. auth\_type (enum) - **Required**. authority type.
	Options:
	1. create - user has ability to create new records.
	2. read - user has ability to read records.
	3. update - user has ability to update existing records.
	4. delete - user has ability to delete records.

##### Result

Boolean. True/False user has authority to edit project with authority type.

##### Example(s)

```select * from pmt_validate_user_authority(23, 420, 'update');```

TRUE

<a name="version"/>
pmt\_version
============

##### Description

Provides the current version, iteration, changeset, instance creation date and last changeset update date.

##### Parameter(s)

No parameters.

##### Result

1.  version (text) – the version, iteration, changeset.
2.  last\_update (date) – the date of last changeset.
3.  created (date) – the date instance was created.

##### Example(s)

```SELECT * FROM pmt_version();```

| version     | last\_update     | created       |
|-------------|------------------|---------------|
| 2.0.6.23    | 2013-11-21       | 2013-11-2     |


* * * * *

<a name="bytea_ref"/>
[[1]](#bytea_reftext) Douglas, Jack. "SQL to read XML from file into
PostgreSQL database." StackExchange Database Administrators Nov 2011.
Web. 02 Aug 2013
 http://dba.stackexchange.com/questions/8172/sql-to-read-xml-from-file-into-postgresql-database
