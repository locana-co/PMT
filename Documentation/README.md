PMT Reference
========================


##### Contents

[bmgf\_filter\_csv](#bmgf_filter_csv)

[pmt\_activities\_by\_tax](#activities_by_tax)

[pmt\_activity\_details](#activity_details)

[pmt\_activity\_listview](#activity_listview)

[pmt\_activity\_listview\_ct](#activity_listview_ct)

[pmt\_auth\_user](#auth_user)

[pmt\_auto\_complete](#auto_complete)

[pmt\_bytea\_import](#bytea_import)

[pmt\_category\_root](#category_root)

[pmt\_countries](#countries)

[pmt\_create\_user](#create_user)

[pmt\_data\_groups](#data_groups)

[pmt\_filter\_csv](#filter_csv)

[pmt\_filter\_iati](#filter_iati)

[pmt\_filter\_locations](#filter_locations)

[pmt\_filter\_orgs](#filter_orgs)

[pmt\_filter\_projects](#filter_projects)

[pmt\_iati\_import](#iati_import)

[pmt\_infobox\_activity\_stats](#infobox_activity_stats)

[pmt\_infobox\_activity\_desc](#infobox_activity_desc)

[pmt\_infobox\_activity\_contact](#infobox_activity_contact)

[pmt\_infobox\_project\_info](#infobox_project_info)

[pmt\_infobox\_project\_stats](#infobox_project_stats)

[pmt\_infobox\_project\_desc](#infobox_project_desc)

[pmt\_infobox\_project\_contact](#infobox_project_contact)

[pmt\_isdate](#isdate)

[pmt\_isnumeric](#isnumeric)

[pmt\_locations\_by\_org](#locations_by_org)

[pmt\_locations\_by\_tax](#locations_by_tax)

[pmt\_org\_inuse](#org_inuse)

[pmt\_project\_listview](#project_listview)

[pmt\_project\_listview\_ct](#project_listview_ct)

[pmt\_purge\_activity](#purge_activity)

[pmt\_purge\_project](#purge_project)

[pmt\_tax\_inuse](#tax_inuse)

[pmt\_stat\_counts](#stat_counts)

[pmt\_stat\_project\_by\_tax](#stat_project_by_tax)

[pmt\_stat\_activity\_by\_tax](#stat_activity_by_tax)

[pmt\_stat\_orgs\_by\_activity](#stat_orgs_by_activity)

[pmt\_update\_user](#update_user)

[pmt\_users](#users)

[pmt\_version](#version)

* * * * *

<a name="bmgf_filter_csv"/>
bmgf\_filter\_csv
=================

##### Description

**In BMGF PMT Only!** Create and email a csv of data filtered by classification, organization and date range,
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

-   Data export for AGRA data group (classification\_id:769):

```SELECT * FROM bmgf_filter_csv('769','','',null,null, 'sparadee@spatialdev.com');```

	TRUE


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


<a name="activity_listview"/>
pmt\_activity\_listview
=======================

##### Description

Filter activity and organization by classification, organization and
date range, reporting a specified taxonomy with pagination.

##### Parameter(s)

1.  tax\_id (integer) – **Required**. Taxonomy\_id to classify returned
    activities.
2.  classification\_ids (character varying) – Optional. Restrict data to
    classification(s).
3.  organization\_ids (character varying) – Optional. Restrict data to
    organization(s)
4.  unassigned\_tax\_ids (character varying) – Optional. Include data
    without assignments to specified taxonomy(ies).
5.  orderby (text) – Optional. Order by result columns.
6.  limit\_rec (integer) – Optional. Maximum number of returned records.
7.  offset\_rec (integer) – Optional. Number of records to offset the
    return records by.

##### Result

Json with the following:

1.  a\_id (integer) – activity\_id.
2.  a\_name (character varying) – title of activity.
3.  a\_desc (character varying) – description of activity.
4.  a\_date1 (date) – start date of activity.
5.  o\_id (integer) – organization\_id.
6.  o\_name (character varying) – name of organization.
7.  r\_name (character varying) – classification name of classification
    related to activity from the taxonomy specified in tax\_id.

##### Example(s)

-   Activity & Organization by Sector (taxonomy\_id:15) in Nepal
    (classification\_id:771) and organization participant is Funding
    (classification\_id:496).  Order the data by activity title
    (a\_name). Limit the number of rows returned to 10 with an offset of
    100:

```SELECT * FROM  pmt_activity_listview(15, '771,496', '', '','a_name', 10, 100);```

```
{        

    "a_id":16664,

    "a_name":"Action for Social Inclusion of Children Affected by Armed Conflict in Nepal (ASIC)",

    "a_desc":"Children and families affected by Armed conflict got support",

    "a_date1":"2010-01-01",

    "o_id":389,

    "o_name":"European Union",

    "r_name":"Servicios sociales o de bienestar"

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
7.  taxonomy (object) – object containing taxonomy/classification for all related taxonomies.
7.  locations (object) – object containing all related locations.

##### Example(s)

-   Activity_id 1234:

```SELECT * FROM  pmt_activity_details(1234);```

```
{
	"a_id":1234,
	"title":"SUPPLEMENTARY LOAN TO MONTEPUEZ - LICHINGA ROAD PROJECT",
	"desc":null,
	"start_date":"2010-05-30",
	"end_date":"2014-12-31",
	"tags":null,
	"amount":57810000.00,
	,"taxonomy":
		[
		{"taxonomy":"Data Group","classification":"AFDB"}
		,{"taxonomy":"Sector","classification":"Transporte por carretera"}
		,{"taxonomy":"Sector Category","classification":"TRANSPORT AND STORAGE"}
		,{"taxonomy":"Organisation Role","classification":"Financiamiento"}
		,{"taxonomy":"Country","classification":"MOZAMBIQUE"}
		]
	,"locations":
		[
		{"location_id":1234
		,"gaul0_name":"Mozambique"	
		,"gaul1_name":"Niassa"
		,"gaul2_name":"Cidade de Lichinga"
		,"lat":-13.312778
		,"long":35.24055
		}]
}
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

##### Result

Integer of number of records.

##### Example(s)

-   Number of Activity & Organization records in Nepal
    (classification\_id:771) and organization participant is Funding
    (classification\_id:496):

```SELECT * FROM  pmt_activity_listview_ct('771,496', '', '');```

888

<a name="auth_user"/>
pmt\_auth\_user
=============================

##### Description

Authenticate user.

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

1.  a\_id (integer) – activity\_id.
2.  title (character varying) – title of activity.
3.  c\_ids (text) – comma separated list of classification\_ids
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
2.  g\_id (character varying(20)) – geo-reference format of the
    location.
3.  r\_ids (text) – comma separated list of classification\_ids
    associated to location from taxonomy specified by tax\_id.

##### Example(s)

-   Locations by Focus Crop taxonomy (taxonomy\_id:22) where there are
    Legumes (classification\_id:816) or no Focus Crop and BMGF
    (organization\_id:13 )is a participant:

```SELECT * FROM pmt_filter_locations(22, '816', '13', '22', null, null);```

| l\_id                   | g\_id                   | r\_ids                  |
|-------------------------|-------------------------|-------------------------|
| 2690                    | "HDKM37051601"          | "816,818,819,820,822,841"|
| 2710                    | "HDLM27305730"          | "816,818,819,820,822,841"|
| 4674                    | "HDLM27305730"          | "816,818,819,820,822,841"|
| …                       | …                       | …                       |

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
2.  g\_id (character varying(20)) – geo-reference format of the
    location.
3.  r\_ids (text) – comma separated list of organization\_ids related to
    location.

##### Example(s)

-   Locations by organization for World Bank data group
    (classification\_id:722) in the country of Bolivia
    (classification\_id:50):

```SELECT * FROM pmt_filter_orgs('772,50', '', '', null, null);```

| l\_id                   | g\_id                   | r\_ids                  |
|-------------------------|-------------------------|-------------------------|
| 35814                   | "HEFN40004660"          | "365,443,939"           |
| 35919                   | "HEFP49605860"          | "365,443,941"           |
| 35539                   | "HEFP55005100"          | "365,443,933"           |
| …                       | …                       | …                       |

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

<a name="infobox_activity_stats"/>
pmt\_infobox\_activity\_stats
=============================

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

<a name="infobox_activity_desc"/>
pmt\_infobox\_activity\_desc
=============================

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

<a name="infobox_activity_contact"/>
pmt\_infobox\_activity\_contact
=============================

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

    "a_ids":[11946,11947,11948,11949,11950,11951,11952,11953,11954,11955,11956,11957,11958,11959,11960,11961,11962,11963,11964,11965,11966,11967,11968,11969,11970,11971],

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

<a name="purge_activity"/>
pmt\_purge\_activity
==========================

##### Description

Deletes all records assoicated to an activity. **Warning!! This function 
permanently deletes ALL data associated to the given activity id**

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
permanently deletes ALL data associated to the given project id**

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

```SELECT * FROM pmt_update_user(315, null, null, null, null, 'jane.doe1234@email.com',  null, null);```

```
TRUE
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
	"roles":[
		{
			"role_id":2,
			"name":"Editor"
		}
		]
}
...
```

<a name="version"/>
pmt\_version
=============================

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
