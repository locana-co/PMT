# PMT Database Data Dictionary
Comprehensive documentation of all the tables, fields & triggers within the PMT database. 

## Notable Information
* All fields in the database prefixed with an underscore (\_) are _core_ data fields,
which are present in all PMT database instances.
* All views in the database prefixed with an underscore (\_) are _core_ views,
which are present in all PMT database instances.
* Primary and foreign keys are not prefixed with an underscore (\_).
* All primary keys are named id.
* All foreign keys are named after their representative table (i.e. foreign key to activity table would be named activity\_id).

## Table Listing

[activity](#activity)

[activity\_contact](#activity_contact)

[activity\_taxonomy](#activity_taxonomy)

[boundary](#boundary)

[boundary\_taxonomy](#boundary_taxonomy)

[classification](#classification)

[config](#config)

[contact](#contact)

[contact\_taxonomy](#contact_taxonomy)

[detail](#detail)

[detail\_taxonomy](#detail_taxonomy)

[feature\_taxonomy](#feature_taxonomy)

[financial](#financial)

[financial\_taxonomy](#financial_taxonomy)

[iati\_import](#iati_import)

[location](#location)

[location\_boundary](#location_boundary)

[location\_taxonomy](#location_taxonomy)

map (**deprecating in iteration 10**)

[organization](#organization)

[organization\_taxonomy](#organization_taxonomy)

[participation](#participation)

[participation\_taxonomy](#participation_taxonomy)

[result](#result)

[result\_taxonomy](#result_taxonomy)

[role](#role)

[stats\_data](#stats_data)

[stats\_metadata](#stats_metadata)

[taxonomy](#taxonomy)

[taxonomy\_xwalk](#taxonomy_xwalk)

[user\_activity\_role](#user_activity_role)

[user\_log](#user_log)

[users](#users)

[version](#version)

* * * * *

## activity

#### Description

The main table in the data model, representing the highest level in the hierarchy of
data elements. The activity table houses all activity related data.

#### Field List

All **bold** fields are required.

| Field		   		| Data Type   		| Default Value	| Constraint			| Description													|
| ----------------------------- | --------------------- |:-------------:|:-----------------------------:| ------------------------------------------------------------------------------------------------------------- |
| **id**      			| serial		|  automated	| PK				| Primary key for the table.										|
| **data\_group\_id**		| integer		|  		| FK - classification.id	| Foreign key to the classification table for the **Data Group** taxonomy. 					|
| parent\_id			| integer		|  		| FK - activity.id		| Self referencing foreign key to the activity table. Allows activities to be related to one another in an unlimited hierarchy.	|
| \_title			| character varying	|  		| 				| Title of the activity.	|
| \_label			| character varying	|  		| 				| Label of the activity. This field is used instead of _\_title_, when space is limited for display.	|
| \_description			| character varying	|  		| 				| Description of the activity.	|
| \_objective			| character varying	|  		| 				| Specific objectives of the activity.	|
| \_content			| character varying	|  		| 				| Additional field for any related information about the activity, that is not represented in any other field.	|
| \_url				| character varying	|  		| 				| URL for the activity.	|
| \_start\_date			| date			|  		| 				| Actual start date for the activity.	|
| \_plan\_start\_date		| date			|  		| 				| Planned start date for the activity.	|
| \_end\_date			| date			|  		| 				| Actual end date for the activity.	|
| \_plan\_end\_date		| date			|  		| 				| Planned end date for the activity.	|
| \_tags			| character varying	|  		| 				| Comma separated list of keywords or terms that describe the activity. This metadata is used for browsing or searching.	|
| \_iati\_identifier		| character varying(150)|  		| 				| External primary key for the activity. For data originating in a system outside of the PMT, this field is used to store that systems primary key.	|
| iati\_import\_id		| integer		|  		| FK - iati\_import.id		| Foreign key to the iati\_import table. When populated the record has been imported from the associated IATI activity document.	|
| **\_active**			| boolean		| true		| 				| T/F the record is active. Inactive records are not accessible through any of the PMT read-only interfaces. Essentially treated as _"deleted"_.	|
| \_retired\_by			| integer		| 		| 				| Activity id (primary key) of the activity that has replaced/retired this activity.	|
| **\_created\_by**		| character varying(150)| 		| 				| Username of user or script name of data script that has created the record in the PMT Database.	|
| **\_created\_date**		| timestamp without time| current date	| 				| Date the record was created in the PMT Database.	|
| **\_updated\_by**		| character varying(150)| 		| 				| Username of user or script name of data script that has last updated the record in the PMT Database.	|
| **\_updated\_date**		| timestamp without time| current date	| 				| Date the record was last edited in the PMT Database.	|

[&larrhk; Back to Table List](#table-listing)


## activity\_contact

#### Description

A junction table to link activities to contacts. An activity can have zero to many contacts.

#### Field List

All **bold** fields are required.

| Field		   		| Data Type   		| Default Value	| Constraint			| Description													|
| ----------------------------- | --------------------- |:-------------:|:-----------------------------:| ------------------------------------------------------------------------------------------------------------- |
| **activity\_id** 		| integer		|  		| FK - activity.id		| Foreign key to the activity table.										|
| **contact\_id**		| integer		|  		| FK - contact.id		| Foreign key to the contact table. 					|

[&larrhk; Back to Table List](#table-listing)


## activity\_taxonomy

#### Description

A junction table to link activities to taxonomy classifications. An activity can have zero to many taxonomy classifications.

#### Field List

All **bold** fields are required.

| Field		   		| Data Type   		| Default Value	| Constraint			| Description													|
| ----------------------------- | --------------------- |:-------------:|:-----------------------------:| ------------------------------------------------------------------------------------------------------------- |
| **activity\_id** 		| integer		|  		| FK - activity.id		| Foreign key to the activity table.										|
| **classification\_id**	| integer		|  		| FK - classification.id	| Foreign key to the classification table. 					|
| **\_field**			| character varying(50)	|  		| 				| Name of the activity table field in which the taxonomy classification is associated. If id, then the taxonomy is assumed to be associated to the entire record. 	|

[&larrhk; Back to Table List](#table-listing)


## boundary

#### Description

The boundary table keeps track of all the available boundary data loaded into the PMT Database. A boundary is a polygon representation
of an administrative boundary. Any boundary layer added to the database must have a record in the boundary table in order for that 
boundary layer to participate in PMT features (see: [location\_boundary](#location_boundary)). 

#### Field List

All **bold** fields are required.

| Field		   		| Data Type   		| Default Value	| Constraint			| Description													|
| ----------------------------- | --------------------- |:-------------:|:-----------------------------:| ------------------------------------------------------------------------------------------------------------- |
| **id**      			| serial		|  automated	| PK				| Primary key for the table.										|
| \_name			| character varying(250)|  		| 				| Name or title of the boundary layer.	|
| \_description			| character varying	|  		| 				| Description of the boundary layer.	|
| \_spatial\_table		| character varying(50)	|  		| 				| Table name of the boundary layer loaded in the PMT Database.	|
| \_version			| character varying(50)	|  		| 				| Version of the boundary layer. Most commonly this is the year the boundary layer was developed.	|
| \_source			| character varying(150)|  		| 				| Source of the boundary layer. Use a URL to source where possible.	|
| **\_active**			| boolean		| true		| 				| T/F the record is active. Inactive records are not accessible through any of the PMT read-only interfaces. Essentially treated as _"deleted"_.	|
| \_retired\_by			| integer		| 		| 				| Boundary id (primary key) of the boundary that has replaced/retired this boundary.	|
| **\_created\_by**		| character varying(150)| 		| 				| Username of user or script name of data script that has created the record in the PMT Database.	|
| **\_created\_date**		| timestamp without time| current date	| 				| Date the record was created in the PMT Database.	|
| **\_updated\_by**		| character varying(150)| 		| 				| Username of user or script name of data script that has last updated the record in the PMT Database.	|
| **\_updated\_date**		| timestamp without time| current date	| 				| Date the record was last edited in the PMT Database.	|

[&larrhk; Back to Table List](#table-listing)


## boundary\_taxonomy

#### Description

A junction table to link boundaries to taxonomy classifications. A boundary can have zero to many taxonomy classifications.

#### Field List

All **bold** fields are required.

| Field		   		| Data Type   		| Default Value	| Constraint			| Description													|
| ----------------------------- | --------------------- |:-------------:|:-----------------------------:| ------------------------------------------------------------------------------------------------------------- |
| **boundary\_id** 		| integer		|  		| FK - boundary.id		| Foreign key to the boundary table.										|
| **classification\_id**	| integer		|  		| FK - classification.id	| Foreign key to the classification table. 					|
| **\_field**			| character varying(50)	|  		| 				| Name of the boundary table field in which the taxonomy classification is associated. If id, then the taxonomy is assumed to be associated to the entire record. 	|

[&larrhk; Back to Table List](#table-listing)


## classification

#### Description

The classification table houses all the classifications for each taxonomy. A taxonomy has one to many classifications. 
Taxonomies are a central core data model concept to the PMT. For more information on taxonomies, see the [_"Understanding the 
Data Model"_](Understanding the Data Model.pdf) document.

#### Field List

All **bold** fields are required.

| Field		   		| Data Type   		| Default Value	| Constraint			| Description													|
| ----------------------------- | --------------------- |:-------------:|:-----------------------------:| ------------------------------------------------------------------------------------------------------------- |
| **id**      			| serial		|  automated	| PK				| Primary key for the table.										|
| **taxonomy\_id**		| integer		|   		| FK - taxonomy.id		| Foreign key to the taxonomy table.										|
| \_code			| character varying(25)	|  		| 				| Code associated to a classification. Example CA is a code for the state of California.	|
| \_name			| character varying(255)|  		| 				| Name or title of a classification. This field will appear in the application in most instances.	|
| \_description			| character varying	|  		| 				| Description of a classification.	|
| \_iati\_code			| character varying(25)	|  		| 				| Code associated to a classification used by IATI (either as export or imported data).	|
| \_iati\_name			| character varying(255)|  		| 				| Name or title of a classification used by IATI (either as export or imported data).	|
| \_iati\_description		| character varying	|  		| 				| Description of a classification used by IATI (either as export or imported data).	|
| parent_id			| integer		|  		| FK - classification.id	| A self referencing foreign key to the classification table. Allows classifications to be related to one another in an unlimited hierarchy.	|
| **\_active**			| boolean		| true		| 				| T/F the record is active. Inactive records are not accessible through any of the PMT read-only interfaces. Essentially treated as _"deleted"_.	|
| \_retired\_by			| integer		| 		| 				| Classification id (primary key) of the classification that has replaced/retired this classification.	|
| **\_created\_by**		| character varying(150)| 		| 				| Username of user or script name of data script that has created the record in the PMT Database.	|
| **\_created\_date**		| timestamp without time| current date	| 				| Date the record was created in the PMT Database.	|
| **\_updated\_by**		| character varying(150)| 		| 				| Username of user or script name of data script that has last updated the record in the PMT Database.	|
| **\_updated\_date**		| timestamp without time| current date	| 				| Date the record was last edited in the PMT Database.	|

[&larrhk; Back to Table List](#table-listing)


## config

#### Description

The config table contains information regarding the PMT Database instance. This is a system table for system related
information and does not contain portfolio data.

#### Field List

All **bold** fields are required.

| Field		   		| Data Type   		| Default Value	| Constraint			| Description													|
| ----------------------------- | --------------------- |:-------------:|:-----------------------------:| ------------------------------------------------------------------------------------------------------------- |
| **id**      			| serial		|  automated	| PK				| Primary key for the table.										|
| \_version			| numeric(2,1)		|  		| 				| Current version of the database.	|
| \_download\_dir		| text			|  		| 				| Postgres data directory.	|
| **\_created\_date**		| timestamp without time| current date	| 				| Date the database was created.	|
| **\_updated\_date**		| timestamp without time| current date	| 				| Date the database was last updated.	|

[&larrhk; Back to Table List](#table-listing)


## contact

#### Description

The contact table contains information about people that can be considered as a point of contact for an activity or 
organization.

#### Field List

All **bold** fields are required.

| Field		   		| Data Type   		| Default Value	| Constraint			| Description													|
| ----------------------------- | --------------------- |:-------------:|:-----------------------------:| ------------------------------------------------------------------------------------------------------------- |
| **id**      			| serial		|  automated	| PK				| Primary key for the table.										|
| organization\_id		| integer		|   		| FK - organization.id		| Foreign key to the organization table, representing the contact's organization affiliation.		|
| \_salutation			| character varying(16)	|  		| 				| Name salutation. Examples: Dr. Mr. Mrs. Ms.	|
| \_first\_name			| character varying     |  		| 				| First name.	|
| \_initial			| character varying(1)	|  		| 				| Middle initial.	|
| \_last\_name			| character varying(128)|  		| 				| Last name.	|
| \_title			| character varying(75)	|  		| 				| Professional or working title.	|
| \_address1			| character varying(150)|  		| 				| Address.	|
| \_address2			| character varying(150)|  		| 				| Additional address field.	|
| \_city			| character varying(30)	|  		| 				| City.	|
| \_state\_providence		| character varying(50)	|  		| 				| State or providence.	|
| \_postal\_code		| character varying(32)	|  		| 				| Postal code .	|
| \_country			| character varying(50)	|  		| 				| Country.	|
| \_direct\_phone		| character varying(21)	|  		| 				| Phone number.	|
| \_mobile\_phone		| character varying(21)	|  		| 				| Mobile number.	|
| \_fax				| character varying(21)	|  		| 				| Fax number.	|
| \_email			| character varying(100)|  		| 				| Email address.	|
| \_url				| character varying(100)|  		| 				| Company website or other professional website related to the contact.	|
| iati\_import\_id		| integer		|  		| FK - iati\_import.id		| Foreign key to the iati\_import table. When populated the record has been imported from the associated IATI activity document.	|
| **\_active**			| boolean		| true		| 				| T/F the record is active. Inactive records are not accessible through any of the PMT read-only interfaces. Essentially treated as _"deleted"_.	|
| \_retired\_by			| integer		| 		| 				| Contact id (primary key) of the contact that has replaced/retired this contact.	|
| **\_created\_by**		| character varying(150)| 		| 				| Username of user or script name of data script that has created the record in the PMT Database.	|
| **\_created\_date**		| timestamp without time| current date	| 				| Date the record was created in the PMT Database.	|
| **\_updated\_by**		| character varying(150)| 		| 				| Username of user or script name of data script that has last updated the record in the PMT Database.	|
| **\_updated\_date**		| timestamp without time| current date	| 				| Date the record was last edited in the PMT Database.	|

[&larrhk; Back to Table List](#table-listing)


## contact\_taxonomy

#### Description

A junction table to link contacts to taxonomy classifications. A contact can have zero to many taxonomy classifications.

#### Field List

All **bold** fields are required.

| Field		   		| Data Type   		| Default Value	| Constraint			| Description													|
| ----------------------------- | --------------------- |:-------------:|:-----------------------------:| ------------------------------------------------------------------------------------------------------------- |
| **contact\_id** 		| integer		|  		| FK - contact.id		| Foreign key to the contact table.										|
| **classification\_id**	| integer		|  		| FK - classification.id	| Foreign key to the classification table. 					|
| **\_field**			| character varying(50)	|  		| 				| Name of the contact table field in which the taxonomy classification is associated. If id, then the taxonomy is assumed to be associated to the entire record. 	|

[&larrhk; Back to Table List](#table-listing)


## detail

#### Description

The detail table contains additional activity details. An activity can have zero to many details.

#### Field List

All **bold** fields are required.

| Field		   		| Data Type   		| Default Value	| Constraint			| Description													|
| ----------------------------- | --------------------- |:-------------:|:-----------------------------:| ------------------------------------------------------------------------------------------------------------- |
| **id**      			| serial		|  automated	| PK				| Primary key for the table.										|
| **activity\_id**		| integer		|   		| FK - activity.id		| Foreign key to the activity table.										|
| \_title			| character varying	|  		| 				| Title of the detail.	|
| \_description			| character varying	|  		| 				| Description of the detail.	|
| \_amount			| numeric(12,2)		|  		| 				| Numerical amount associated to the detail.	|
| **\_active**			| boolean		| true		| 				| T/F the record is active. Inactive records are not accessible through any of the PMT read-only interfaces. Essentially treated as _"deleted"_.	|
| \_retired\_by			| integer		| 		| 				| Detail id (primary key) of the detail that has replaced/retired this detail.	|
| **\_created\_by**		| character varying(150)| 		| 				| Username of user or script name of data script that has created the record in the PMT Database.	|
| **\_created\_date**		| timestamp without time| current date	| 				| Date the record was created in the PMT Database.	|
| **\_updated\_by**		| character varying(150)| 		| 				| Username of user or script name of data script that has last updated the record in the PMT Database.	|
| **\_updated\_date**		| timestamp without time| current date	| 				| Date the record was last edited in the PMT Database.	|

[&larrhk; Back to Table List](#table-listing)


## detail\_taxonomy

#### Description

A junction table to link details to taxonomy classifications. A detail can have zero to many taxonomy classifications.

#### Field List

All **bold** fields are required.

| Field		   		| Data Type   		| Default Value	| Constraint			| Description													|
| ----------------------------- | --------------------- |:-------------:|:-----------------------------:| ------------------------------------------------------------------------------------------------------------- |
| **detail\_id** 		| integer		|  		| FK - detail.id		| Foreign key to the detail table.										|
| **classification\_id**	| integer		|  		| FK - classification.id	| Foreign key to the classification table. 					|
| **\_field**			| character varying(50)	|  		| 				| Name of the detail table field in which the taxonomy classification is associated. If id, then the taxonomy is assumed to be associated to the entire record. 	|

[&larrhk; Back to Table List](#table-listing)



## feature\_taxonomy

#### Description

A junction table to link boundary features to taxonomy classifications. A boundary feature can have zero
to many taxonomy classifications.

#### Field List

All **bold** fields are required.

| Field		   		| Data Type   		| Default Value	| Constraint			| Description													|
| ----------------------------- | --------------------- |:-------------:|:-----------------------------:| ------------------------------------------------------------------------------------------------------------- |
| **feature\_id** 		| integer		|  		| Check constraint		| Check enforced foreign key to the spatial boundary table specified by the boundary\_id.										|
| **boundary\_id**		| integer		|  		| FK - boundary.id		| Foreign key to the boundary table. 					|
| **classification\_id**	| integer		|  		| FK - classification.id	| Foreign key to the classification table. 					|
| **\_field**			| character varying(50)	|  		| 				| Name of the boundary table field (as specified in the boundary\_id) in which the taxonomy classification is associated. If id, then the taxonomy is assumed to be associated to the entire record. 	|

[&larrhk; Back to Table List](#table-listing)


## financial

#### Description

The financial table contains additional activity details. An activity can have zero to many details.

#### Field List

All **bold** fields are required.

| Field		   		| Data Type   		| Default Value	| Constraint			| Description													|
| ----------------------------- | --------------------- |:-------------:|:-----------------------------:| ------------------------------------------------------------------------------------------------------------- |
| **id**      			| serial		|  automated	| PK				| Primary key for the table.										|
| **activity\_id**		| integer		|   		| FK - activity.id		| Foreign key to the activity table.										|
| provider\_id  		| integer		|  		| FK - organization.id		| Foreign key to the organization table. The organization the providing the financial amount.	|
| recipient\_id  		| integer		|  		| FK - organization.id		| Foreign key to the organization table. The organization the receiving the financial amount.	|
| \_amount			| numeric(100,2)	|  		| 				| Monetary value.	|
| \_start\_date			| date			| 		| 				| Start date associated to the monetary value.	|
| \_end\_date			| date			| 		| 				| End date associated to the monetary value.	|
| **\_active**			| boolean		| true		| 				| T/F the record is active. Inactive records are not accessible through any of the PMT read-only interfaces. Essentially treated as _"deleted"_.	|
| \_retired\_by			| integer		| 		| 				| Financial id (primary key) of the financial record that has replaced/retired this financial record.	|
| **\_created\_by**		| character varying(150)| 		| 				| Username of user or script name of data script that has created the record in the PMT Database.	|
| **\_created\_date**		| timestamp without time| current date	| 				| Date the record was created in the PMT Database.	|
| **\_updated\_by**		| character varying(150)| 		| 				| Username of user or script name of data script that has last updated the record in the PMT Database.	|
| **\_updated\_date**		| timestamp without time| current date	| 				| Date the record was last edited in the PMT Database.	|

[&larrhk; Back to Table List](#table-listing)


## financial\_taxonomy

#### Description

A junction table to link financial records to taxonomy classifications. A financial record can have zero to many taxonomy classifications.

#### Field List

All **bold** fields are required.

| Field		   		| Data Type   		| Default Value	| Constraint			| Description													|
| ----------------------------- | --------------------- |:-------------:|:-----------------------------:| ------------------------------------------------------------------------------------------------------------- |
| **financial\_id** 		| integer		|  		| FK - financial.id		| Foreign key to the financial table.										|
| **classification\_id**	| integer		|  		| FK - classification.id	| Foreign key to the classification table. 					|
| **\_field**			| character varying(50)	|  		| 				| Name of the financial table field in which the taxonomy classification is associated. If id, then the taxonomy is assumed to be associated to the entire record. 	|

[&larrhk; Back to Table List](#table-listing)


## iati\_import

#### Description

The iati\_import table loads IATI formatted xml data into the PMT database.  Using the function
[pmt_iati_import](Functions/pmt_iati_import) xml data is copied into the iati\_import table,
which fires the pmt\_process\_iati trigger that loades the IATI formatted xml data into the PMT database.
Currently the import process supports IATI [codelists](http://iatistandard.org/201/codelists/) 
and [activity](http://iatistandard.org/201/activity-standard/) xml documents.

#### Field List

All **bold** fields are required.

| Field		   		| Data Type   		| Default Value	| Constraint			| Description													|
| ----------------------------- | --------------------- |:-------------:|:-----------------------------:| ------------------------------------------------------------------------------------------------------------- |
| **id**      			| serial		|  automated	| PK				| Primary key for the table.										|
| **\_action**			| character varying(25)	|  insert	| 				| Action to perform on the imported xml. Options: insert.	|
| \_type			| character varying(50)	|  		| 				| Type of imported xml. Options: code list or iati-activity. The trigger on this table updates this field on INSERT based on xml document type.	|
| \_codelist			| character varying(100)|  		| 				| Codelist name of imported xml document of type _codelist_. The trigger on this table updates this field on INSERT of a _codelist_ document type.	|
| \_data\_group			| character varying(100)|  		| 				| Data group name for imported xml document of type _iati-activity_. The trigger on this table will create a new classification in the Data Group taxonomy if the provided value does not exist.	|
| \_version			| numeric		|  		| 				| The IATI version of the imported xml document of type _iati-activity_. The trigger on this table updates this field on INSERT base on the attribute value for version.	|
| \_error			| character varying	|  		| 				| Error description. The trigger on this table will write an error description if the trigger fails to import the xml data.	|
| **\_xml**			| xml			|  		| 				| Xml document to be loaded into the PMT database.	|
| **\_created\_by**		| character varying(150)| 		| 				| Username of user or script name of data script that has created the record in the PMT Database.	|
| **\_created\_date**		| timestamp without time| current date	| 				| Date the record was created in the PMT Database.	|

#### Triggers 

* **pmt\_iati\_preprocess** (BEFORE INSERT) - pre-process the IATI xml documents to collect important information 
needed for processing, this information is then recorded in the iati_import table. Currently supports IATI 
[codelists](http://iatistandard.org/201/codelists/) and [activity](http://iatistandard.org/201/activity-standard/) 
xml documents. 
* **pmt\_iati\_evaluate** (AFTER INSERT) - evaluate the IATI xml documents attributes recorded by the _pmt\_iati\_preprocess_
trigger to determine which ETL function to perfrom to load the data into the PMT.

[&larrhk; Back to Table List](#table-listing)


## location

#### Description

The location table contains a spatial location associated to an activity. An activity can have zero to one locations. A location can be a point
or a polygon from an associated boundary feature.

#### Field List

All **bold** fields are required.

| Field		   		| Data Type   		| Default Value	| Constraint			| Description													|
| ----------------------------- | --------------------- |:-------------:|:-----------------------------:| ------------------------------------------------------------------------------------------------------------- |
| **id**      			| serial		|  automated	| PK				| Primary key for the table.										|
| **activity\_id**		| integer		|   		| FK - activity.id		| Foreign key to the activity table. 										|
| **boundary\_id**		| integer		|   		| FK - boundary.id		| Foreign key to the boundary table. The boundary table containing the feature represented by the feature\_id.										|
| **feature\_id**		| integer		|   		| Check constraint		| Check enforced foreign key to the spatial boundary table specified by the boundary\_id.		|
| \_title			| character varying	|  		| 				| Title of the location.	|
| \_description			| character varying	|  		| 				| Description of the location.	|
| \_geographic\_id		| character varying	|  		| 				| A code from the gazetteer or administrative boundary repository specified by the associated Geographic Vocabulary taxonomy classification. |
| \_geographic\_level		| character varying	|  		| 				| A number defining a subdivision within a hierarchical system of administrative areas. The precise system for defining the particular meaning of each level value is determined by the associated Geographic Vocabulary taxonomy classification. |
| \_x				| integer		|  		| 				| x coordinate as integer, calculated from point on INSERT or UPDATE.	|
| \_y				| integer		|  		| 				| y coordinate as integer, calculated from point on INSERT or UPDATE.	|
| \_lat\_dd			| numeric		|  		| 				| Latitude in decimal degrees format (DDD.dddd), calculated from point on INSERT or UPDATE.	|
| \_long\_dd			| numeric		|  		| 				| Longitude in decimal degrees format (DDD.dddd), calculated from point on INSERT or UPDATE.	|
| \_latlong			| character varying(100)|  		| 				| Latitude & longitude in compass direction format (DDD MM SS + compass direction), calculated from point on INSERT or UPDATE.	|
| \_georef			| character varying(20)	|  		| 				| Latitude & longitude in [GeoRef](http://en.wikipedia.org/wiki/Georef) format, calculated from point on INSERT or UPDATE.	|
| \_admin1			| character varying	|  		| 				| Administrative boundary level 1, for boundary geocoded locations.	|
| \_admin2			| character varying	|  		| 				| Administrative boundary level 2, for boundary geocoded locations.	|
| \_admin3			| character varying	|  		| 				| Administrative boundary level 3, for boundary geocoded locations.	|
| \_admin4			| character varying	|  		| 				| Administrative boundary level 4, for boundary geocoded locations.	|
| \_point			| geometry		|  		| 				| Spatial point.	|
| **\_active**			| boolean		| true		| 				| T/F the record is active. Inactive records are not accessible through any of the PMT read-only interfaces. Essentially treated as _"deleted"_.	|
| \_retired\_by			| integer		| 		| 				| Location id (primary key) of the location that has replaced/retired this location.	|
| **\_created\_by**		| character varying(150)| 		| 				| Username of user or script name of data script that has created the record in the PMT Database.	|
| **\_created\_date**		| timestamp without time| current date	| 				| Date the record was created in the PMT Database.	|
| **\_updated\_by**		| character varying(150)| 		| 				| Username of user or script name of data script that has last updated the record in the PMT Database.	|
| **\_updated\_date**		| timestamp without time| current date	| 				| Date the record was last edited in the PMT Database.	|

#### Triggers 

* **pmt_upd_geometry_formats** (INSERT, UPDATE) - calculates and updates all the location formats (\_x, \_y, \_lat\_dd, \_long\_dd, 
\_latlong, \_georef) in the location table based on inserted or updated point. 
* **pmt_upd_boundary_features** (INSERT, UPDATE) - locates all the boundary features intersected by the inserted or updated point and creates 
relationships to the point within the [location\_boundary](#location_boundary) table.
* **pmt_dlt_boundary_features** (DELETE) - removes all the boundary features relationships to the point within the 
[location\_boundary](#location_boundary) table before the location is deleted.

[&larrhk; Back to Table List](#table-listing)


## location\_boundary

#### Description

A junction table to link locations and boundaries. Represents the diverse relationship between locations and the available 
boundaries within the PMT. Available boundaries are listed in the [boundary](#boundary) table. When a point it inserted or updated
in the [location](#location) table a trigger locates all the boundary features intersected by that point and records the relationship
in the location\_boundary table.

#### Field List

All **bold** fields are required.

| Field		   		| Data Type   		| Default Value	| Constraint			| Description													|
| ----------------------------- | --------------------- |:-------------:|:-----------------------------:| ------------------------------------------------------------------------------------------------------------- |
| **location\_id** 		| integer		|  		| FK - location.id		| Foreign key to the location table.										|
| **boundary\_id** 		| integer		|  		| FK - boundary.id		| Foreign key to the boundary table.										|
| **feature\_id** 		| integer		|  		| Check constraint		| Check enforced foreign key to the spatial boundary table specified by the boundary\_id.		|
| \_feature\_area		| double		|  		| 				| The area of the associate feature polygon. 					|
| \_feature\_name		| character varying	|  		| 				| Name of the feature associated. 	|

[&larrhk; Back to Table List](#table-listing)


## location\_taxonomy

#### Description

A junction table to link locations to taxonomy classifications. A location can have zero to many taxonomy classifications.

#### Field List

All **bold** fields are required.

| Field		   		| Data Type   		| Default Value	| Constraint			| Description													|
| ----------------------------- | --------------------- |:-------------:|:-----------------------------:| ------------------------------------------------------------------------------------------------------------- |
| **location\_id** 		| integer		|  		| FK - location.id		| Foreign key to the location table.										|
| **classification\_id**	| integer		|  		| FK - classification.id	| Foreign key to the classification table. 					|
| **\_field**			| character varying(50)	|  		| 				| Name of the location table field in which the taxonomy classification is associated. If id, then the taxonomy is assumed to be associated to the entire record. 	|

[&larrhk; Back to Table List](#table-listing)


## organization

#### Description

The organization table contains information about organizations that participate in activities in one of the 
four capacities outline in the [IATI Standard for Organization Roles](http://iatistandard.org/201/codelists/OrganisationRole/).

#### Field List

All **bold** fields are required.

| Field		   		| Data Type   		| Default Value	| Constraint			| Description													|
| ----------------------------- | --------------------- |:-------------:|:-----------------------------:| ------------------------------------------------------------------------------------------------------------- |
| **id**      			| serial		|  automated	| PK				| Primary key for the table.										|
| \_name			| character varying	|  		| 				| Name of the organization.	|
| \_label			| character varying	|  		| 				| Organization name's abbreviation or shorten version.|
| \_address1			| character varying(150)|  		| 				| Address.	|
| \_address2			| character varying(150)|  		| 				| Additional address field.	|
| \_city			| character varying(30)	|  		| 				| City.	|
| \_state\_providence		| character varying(50)	|  		| 				| State or providence.	|
| \_postal\_code		| character varying(32)	|  		| 				| Postal code .	|
| \_country			| character varying(50)	|  		| 				| Country.	|
| \_direct\_phone		| character varying(21)	|  		| 				| Phone number.	|
| \_mobile\_phone		| character varying(21)	|  		| 				| Mobile number.	|
| \_fax				| character varying(21)	|  		| 				| Fax number.	|
| \_url				| character varying(150)|  		| 				| Company website or other professional website related to the organization.	|
| iati\_import\_id		| integer		|  		| FK - iati\_import.id		| Foreign key to the iati\_import table. When populated the record has been imported from the associated IATI activity document.	|
| **\_active**			| boolean		| true		| 				| T/F the record is active. Inactive records are not accessible through any of the PMT read-only interfaces. Essentially treated as _"deleted"_.	|
| \_retired\_by			| integer		| 		| 				| Organization id (primary key) of the organization that has replaced/retired this organization.	|
| **\_created\_by**		| character varying(150)| 		| 				| Username of user or script name of data script that has created the record in the PMT Database.	|
| **\_created\_date**		| timestamp without time| current date	| 				| Date the record was created in the PMT Database.	|
| **\_updated\_by**		| character varying(150)| 		| 				| Username of user or script name of data script that has last updated the record in the PMT Database.	|
| **\_updated\_date**		| timestamp without time| current date	| 				| Date the record was last edited in the PMT Database.	|

[&larrhk; Back to Table List](#table-listing)


## organization\_taxonomy

#### Description

A junction table to link organizations to taxonomy classifications. A organization can have zero to many taxonomy classifications.

#### Field List

All **bold** fields are required.

| Field		   		| Data Type   		| Default Value	| Constraint			| Description													|
| ----------------------------- | --------------------- |:-------------:|:-----------------------------:| ------------------------------------------------------------------------------------------------------------- |
| **organization\_id** 		| integer		|  		| FK - organization.id		| Foreign key to the organization table.					|
| **classification\_id**	| integer		|  		| FK - classification.id	| Foreign key to the classification table. 					|
| **\_field**			| character varying(50)	|  		| 				| Name of the organization table field in which the taxonomy classification is associated. If id, then the taxonomy is assumed to be associated to the entire record. 	|

[&larrhk; Back to Table List](#table-listing)


## participation

#### Description

A junction table to link activities and organization. Represents the diverse relationship between
activities and organizations. Organizations can participate in zero to many activities. Activities
can have zero to many organization participants.

#### Field List

All **bold** fields are required.

| Field		   		| Data Type   		| Default Value	| Constraint			| Description													|
| ----------------------------- | --------------------- |:-------------:|:-----------------------------:| ------------------------------------------------------------------------------------------------------------- |
| **id**      			| serial		|  automated	| PK				| Primary key for the table.										|
| **activity\_id** 		| integer		|  		| FK - activity.id		| Foreign key to the activity table.										|
| **organization\_id** 		| integer		|  		| FK - organization.id		| Foreign key to the organization table.					|
| **\_active**			| boolean		| true		| 				| T/F the record is active. Inactive records are not accessible through any of the PMT read-only interfaces. Essentially treated as _"deleted"_.	|
| \_retired\_by			| integer		| 		| 				| Participation id (primary key) of the participation that has replaced/retired this participation.	|
| **\_created\_by**		| character varying(150)| 		| 				| Username of user or script name of data script that has created the record in the PMT Database.	|
| **\_created\_date**		| timestamp without time| current date	| 				| Date the record was created in the PMT Database.	|
| **\_updated\_by**		| character varying(150)| 		| 				| Username of user or script name of data script that has last updated the record in the PMT Database.	|
| **\_updated\_date**		| timestamp without time| current date	| 				| Date the record was last edited in the PMT Database.	|

[&larrhk; Back to Table List](#table-listing)


## participation\_taxonomy

#### Description

A junction table to link participation records to taxonomy classifications. A participation record can have zero to many taxonomy classifications. The
primary taxonomy used on participation records is the Organisation Role.

#### Field List

All **bold** fields are required.

| Field		   		| Data Type   		| Default Value	| Constraint			| Description													|
| ----------------------------- | --------------------- |:-------------:|:-----------------------------:| ------------------------------------------------------------------------------------------------------------- |
| **participation\_id**		| integer		|  		| FK - participation.id		| Foreign key to the participation table.										|
| **classification\_id**	| integer		|  		| FK - classification.id	| Foreign key to the classification table. 					|
| **\_field**			| character varying(50)	|  		| 				| Name of the participation table field in which the taxonomy classification is associated. If id, then the taxonomy is assumed to be associated to the entire record. 	|

[&larrhk; Back to Table List](#table-listing)


## result

#### Description

The result table contains information related to activities that describe an outcome of the related
activity. Activities can have zero to many results.

#### Field List

All **bold** fields are required.

| Field		   		| Data Type   		| Default Value	| Constraint			| Description													|
| ----------------------------- | --------------------- |:-------------:|:-----------------------------:| ------------------------------------------------------------------------------------------------------------- |
| **id**      			| serial		|  automated	| PK				| Primary key for the table.										|
| **activity\_id**		| integer		|  		| FK - activity.id		| Foreign key to the activity table. 					|
| \_title			| character varying	|  		| 				| Title of the result.	|
| \_description			| character varying	|  		| 				| Description of the result.	|
| **\_active**			| boolean		| true		| 				| T/F the record is active. Inactive records are not accessible through any of the PMT read-only interfaces. Essentially treated as _"deleted"_.	|
| \_retired\_by			| integer		| 		| 				| Result id (primary key) of the result that has replaced/retired this result.	|
| **\_created\_by**		| character varying(150)| 		| 				| Username of user or script name of data script that has created the record in the PMT Database.	|
| **\_created\_date**		| timestamp without time| current date	| 				| Date the record was created in the PMT Database.	|
| **\_updated\_by**		| character varying(150)| 		| 				| Username of user or script name of data script that has last updated the record in the PMT Database.	|
| **\_updated\_date**		| timestamp without time| current date	| 				| Date the record was last edited in the PMT Database.	|

[&larrhk; Back to Table List](#table-listing)


## result\_taxonomy

#### Description

A junction table to link results to taxonomy classifications. A result can have zero to many taxonomy classifications.

#### Field List

All **bold** fields are required.

| Field		   		| Data Type   		| Default Value	| Constraint			| Description													|
| ----------------------------- | --------------------- |:-------------:|:-----------------------------:| ------------------------------------------------------------------------------------------------------------- |
| **result\_id** 		| integer		|  		| FK - result.id		| Foreign key to the result table.										|
| **classification\_id**	| integer		|  		| FK - classification.id	| Foreign key to the classification table. 					|
| **\_field**			| character varying(50)	|  		| 				| Name of the result table field in which the taxonomy classification is associated. If id, then the taxonomy is assumed to be associated to the entire record. 	|

[&larrhk; Back to Table List](#table-listing)


## role

#### Description

The role table contains the roles users can be assign to. Roles determine permissions.

#### Field List

All **bold** fields are required.

| Field		   		| Data Type   		| Default Value	| Constraint			| Description													|
| ----------------------------- | --------------------- |:-------------:|:-----------------------------:| ------------------------------------------------------------------------------------------------------------- |
| **id**      			| serial		|  automated	| PK				| Primary key for the table.										|
| \_name			| character varying	|  		| 				| Name of the role.	|
| \_description			| character varying	|  		| 				| Description of the role.	|
| **\_read**			| boolean		| false		| 				| T/F role has read permissions.	|
| **\_create**			| boolean		| false		| 				| T/F role has create permissions.	|
| **\_update**			| boolean		| false		| 				| T/F role has update permissions.	|
| **\_delete**			| boolean		| false		| 				| T/F role has delete permissions.	|
| **\_super**			| boolean		| false		| 				| T/F role has all crud permissions: read, create, update, delete. Overrides any settings for individual CRUD settings.	|
| **\_security**		| boolean		| false		| 				| T/F role has ability to grant permissions.	|
| **\_active**			| boolean		| true		| 				| T/F the record is active. Inactive records are not accessible through any of the PMT read-only interfaces. Essentially treated as _"deleted"_.	|
| \_retired\_by			| integer		| 		| 				| Role id (primary key) of the role that has replaced/retired this role.	|
| **\_created\_by**		| character varying(150)| 		| 				| Username of user or script name of data script that has created the record in the PMT Database.	|
| **\_created\_date**		| timestamp without time| current date	| 				| Date the record was created in the PMT Database.	|
| **\_updated\_by**		| character varying(150)| 		| 				| Username of user or script name of data script that has last updated the record in the PMT Database.	|
| **\_updated\_date**		| timestamp without time| current date	| 				| Date the record was last edited in the PMT Database.	|

[&larrhk; Back to Table List](#table-listing)


## stats\_data

#### Description

The stats\_data table contains statistical information for a specified boundary and indicator. Available
indicators can be found in the [stats\_metadata](#stats_metadata) table.

#### Field List

All **bold** fields are required.

| Field		   		| Data Type   		| Default Value	| Constraint			| Description													|
| ----------------------------- | --------------------- |:-------------:|:-----------------------------:| ------------------------------------------------------------------------------------------------------------- |
| **id**      			| serial		|  automated	| PK				| Primary key for the table.										|
| stats\_metadata\_id		| integer|  		| 		| FK - stats\_metadata.id	| Foreign key to the stats\_metadata table.										|
| \_code			| character varying	|  		| 				| Code for referenced boundary the statistic applies to (i.e. 3 digit ISO code for countries).	|
| \_name			| character varying	|  		| 				| Full name of the referenced boundary the statistic applies to.	|
| \_boundary\_level		| integer		|  		| 				| Level of referenced administrative boundary. Example: 0 - country.	|
| \_data\_type			| character varying	| 		| 				| Statistic data type: continuous or classification.	|
| \_data			| character varying	| 		| 				| The default data value for the statistic.	|
| \_2000			| character varying	| 		| 				| The data value for the statistic for the year 2000.	|
| \_2001			| character varying	| 		| 				| The data value for the statistic for the year 2001.	|
| \_2002			| character varying	| 		| 				| The data value for the statistic for the year 2002.	|
| \_2003			| character varying	| 		| 				| The data value for the statistic for the year 2003.	|
| \_2004			| character varying	| 		| 				| The data value for the statistic for the year 2004.	|
| \_2005			| character varying	| 		| 				| The data value for the statistic for the year 2005.	|
| \_2006			| character varying	| 		| 				| The data value for the statistic for the year 2006.	|
| \_2007			| character varying	| 		| 				| The data value for the statistic for the year 2007.	|
| \_2008			| character varying	| 		| 				| The data value for the statistic for the year 2008.	|
| \_2009			| character varying	| 		| 				| The data value for the statistic for the year 2009.	|
| \_2010			| character varying	| 		| 				| The data value for the statistic for the year 2010.	|
| \_2011			| character varying	| 		| 				| The data value for the statistic for the year 2011.	|
| \_2012			| character varying	| 		| 				| The data value for the statistic for the year 2012.	|
| \_2013			| character varying	| 		| 				| The data value for the statistic for the year 2013.	|
| \_2014			| character varying	| 		| 				| The data value for the statistic for the year 2014.	|
| \_2015			| character varying	| 		| 				| The data value for the statistic for the year 2015.	|
| \_2016			| character varying	| 		| 				| The data value for the statistic for the year 2016.	|
| **\_active**			| boolean		| true		| 				| T/F the record is active. Inactive records are not accessible through any of the PMT read-only interfaces. Essentially treated as _"deleted"_.	|
| \_retired\_by			| integer		| 		| 				| stats\_data id (primary key) of the stats\_data record that has replaced/retired this stats\_data record.	|
| **\_created\_by**		| character varying(150)| 		| 				| Username of user or script name of data script that has created the record in the PMT Database.	|
| **\_created\_date**		| timestamp without time| current date	| 				| Date the record was created in the PMT Database.	|
| **\_updated\_by**		| character varying(150)| 		| 				| Username of user or script name of data script that has last updated the record in the PMT Database.	|
| **\_updated\_date**		| timestamp without time| current date	| 				| Date the record was last edited in the PMT Database.	|

[&larrhk; Back to Table List](#table-listing)


## stats\_metadata

#### Description

The stats\_metadata table contains statistical metadata for available indicators. Data for the indicators
can be found in the [stats\_data](#stats_data) table.

#### Field List

All **bold** fields are required.

| Field		   		| Data Type   		| Default Value	| Constraint			| Description													|
| ----------------------------- | --------------------- |:-------------:|:-----------------------------:| ------------------------------------------------------------------------------------------------------------- |
| **id**      			| serial		|  automated	| PK				| Primary key for the table.										|
| \_code			| character varying	|  		| 				| Code for the indicator.	|
| \_name			| character varying	|  		| 				| Full name of the indicator.	|
| \_description			| character varying	|  		| 				| Description of the indicator.	|
| \_source			| character varying	| 		| 				| Source of indicator data.	|
| \_category			| character varying	| 		| 				| Category the indicator is grouped under.	|
| \_sub\_category		| character varying	| 		| 				| Sub-category the indicator is grouped under.	|
| \_periodicity			| character varying	| 		| 				| The frequency in which the data is updated.	|
| \_aggregation			| character varying	| 		| 				| The formula or information about how the data was aggregated.	|
| \_exceptions			| character varying	| 		| 				| Exemptions or limitations of the data.	|
| \_comments			| character varying	| 		| 				| Comments about the data or the collection process.	|
| \_dataset			| character varying	| 		| 				| The name of the dataset in which the indicator belongs to.	|
| \_data\_origin		| character varying	| 		| 				| The url or origin of where the data was obtained or downloaded.	|
| **\_active**			| boolean		| true		| 				| T/F the record is active. Inactive records are not accessible through any of the PMT read-only interfaces. Essentially treated as _"deleted"_.	|
| \_retired\_by			| integer		| 		| 				| stats\_data id (primary key) of the stats\_data record that has replaced/retired this stats\_data record.	|
| **\_created\_by**		| character varying(150)| 		| 				| Username of user or script name of data script that has created the record in the PMT Database.	|
| **\_created\_date**		| timestamp without time| current date	| 				| Date the record was created in the PMT Database.	|
| **\_updated\_by**		| character varying(150)| 		| 				| Username of user or script name of data script that has last updated the record in the PMT Database.	|
| **\_updated\_date**		| timestamp without time| current date	| 				| Date the record was last edited in the PMT Database.	|

[&larrhk; Back to Table List](#table-listing)


## taxonomy

#### Description

The taxonomy table contains the information for taxonomies. Taxonomies are a central core data model concept to the PMT. For more information on taxonomies, see the [_"Understanding the 
Data Model"_](Understanding the Data Model.pdf) document.

#### Field List

All **bold** fields are required.

| Field		   		| Data Type   		| Default Value	| Constraint			| Description													|
| ----------------------------- | --------------------- |:-------------:|:-----------------------------:| ------------------------------------------------------------------------------------------------------------- |
| **id**      			| serial		|  automated	| PK				| Primary key for the table.										|
| \_name			| character varying(255)|  		| 				| Name of the taxonomy.	|
| \_description			| character varying	|  		| 				| Description of the taxonomy.	|
| \_iati\_codelist		| character varying(100)|  		| 				| Name of the IATI codelist, only applies to loaded [IATI taxonomies](http://iatistandard.org/201/codelists/).	|
| parent\_id			| integer		|  		| FK - taxonomy.id		| Self referencing foreign key to the taxonomy table. Allows taxonomies to be related to one another in an unlimited hierarchy.	|
| \_is\_category		| boolean		| false		| 				| T/F the taxonomy is a category for another taxonomy.	|
| **\_active**			| boolean		| true		| 				| T/F the record is active. Inactive records are not accessible through any of the PMT read-only interfaces. Essentially treated as _"deleted"_.	|
| \_retired\_by			| integer		| 		| 				| taxonomy id (primary key) of the taxonomy that has replaced/retired this taxonomy.	|
| **\_created\_by**		| character varying(150)| 		| 				| Username of user or script name of data script that has created the record in the PMT Database.	|
| **\_created\_date**		| timestamp without time| current date	| 				| Date the record was created in the PMT Database.	|
| **\_updated\_by**		| character varying(150)| 		| 				| Username of user or script name of data script that has last updated the record in the PMT Database.	|
| **\_updated\_date**		| timestamp without time| current date	| 				| Date the record was last edited in the PMT Database.	|

[&larrhk; Back to Table List](#table-listing)


## taxonomy\_xwalk

#### Description

The taxonomy crosswalk table is used to connect to taxonomies together to allow data to be 
interchangeably described by either taxonomy regardless of the data's origin taxonomy.

#### Field List

All **bold** fields are required.

| Field		   		| Data Type   		| Default Value	| Constraint			| Description													|
| ----------------------------- | --------------------- |:-------------:|:-----------------------------:| ------------------------------------------------------------------------------------------------------------- |
| **id**      			| serial		|  automated	| PK				| Primary key for the table.										|
| **origin\_taxonomy\_id**	| integer		|  		| FK - taxonomy.id		| Foreign key to the taxonomy table. Origin or source taxonomy that will be linked to another taxonomy.	|
| **linked\_taxonomy\_id**	| integer		|  		| FK - taxonomy.id		| Foreign key to the taxonomy table. Linked taxonomy that will be linked to the origin taxonomy.	|
| **origin\_classification\_id**| integer		|  		| FK - classification.id	| Foreign key to the classification table. Origin or source classification that will be linked to another classification.	|
| **linked\_classification\_id**| integer		|  		| FK - classification.id	| Foreign key to the classification table. Linked classification that will be linked to the origin classification.	|
| **\_direction**		| character varying(5)	| ONE		| 				| Direction of crosswalk. ONE - one way: origin to link. BOTH - both ways: origin to link and link to origin.	|
| **\_active**			| boolean		| true		| 				| T/F the record is active. Inactive records are not accessible through any of the PMT read-only interfaces. Essentially treated as _"deleted"_.	|
| \_retired\_by			| integer		| 		| 				| Taxonomy_xwalk id (primary key) of the taxonomy\_xwalk record that has replaced/retired this taxonomy\_xwalk record.	|
| **\_created\_by**		| character varying(150)| 		| 				| Username of user or script name of data script that has created the record in the PMT Database.	|
| **\_created\_date**		| timestamp without time| current date	| 				| Date the record was created in the PMT Database.	|
| **\_updated\_by**		| character varying(150)| 		| 				| Username of user or script name of data script that has last updated the record in the PMT Database.	|
| **\_updated\_date**		| timestamp without time| current date	| 				| Date the record was last edited in the PMT Database.	|

[&larrhk; Back to Table List](#table-listing)


## user\_activity\_role

#### Description

The user activity role table provides users permissions via roles to activities. Assignments of permissions for a user
to activities can be done per activity or by a taxonomy classification.

#### Field List

All **bold** fields are required.

| Field		   		| Data Type   		| Default Value	| Constraint			| Description													|
| ----------------------------- | --------------------- |:-------------:|:-----------------------------:| ------------------------------------------------------------------------------------------------------------- |
| **id**      			| serial		|  automated	| PK				| Primary key for the table.										|
| **user\_id**			| integer		|  		| FK - user.id			| Foreign key to the user table. The user being granted a role on an activity.	|
| **role\_id**			| integer		|  		| FK - role.id			| Foreign key to the role table. The role the user is assigned for an activity.	|
| activity\_id			| integer		|  		| FK - activity.id		| Foreign key to the activity table. The activity the users has permissions on. Activity\_id **OR** classification\_id must not be null. When activity\_id is used then user is provided permissions to the single activity. 	|
| classification\_id		| integer		|  		| FK - classification.id	| Foreign key to the classification table. The user is granted permission to all activities having the specified classification. Activity\_id **OR** classification\_id must not be null. |
| **\_direction**		| character varying(5)	| ONE		| 				| Direction of crosswalk. ONE - one way: origin to link. BOTH - both ways: origin to link and link to origin.	|
| **\_active**			| boolean		| true		| 				| T/F the record is active. Inactive records are not accessible through any of the PMT read-only interfaces. Essentially treated as _"deleted"_.	|
| \_retired\_by			| integer		| 		| 				| User\_activity\_role id (primary key) of the User\_activity\_role record that has replaced/retired this User\_activity\_role record.	|
| **\_created\_by**		| character varying(150)| 		| 				| Username of user or script name of data script that has created the record in the PMT Database.	|
| **\_created\_date**		| timestamp without time| current date	| 				| Date the record was created in the PMT Database.	|
| **\_updated\_by**		| character varying(150)| 		| 				| Username of user or script name of data script that has last updated the record in the PMT Database.	|
| **\_updated\_date**		| timestamp without time| current date	| 				| Date the record was last edited in the PMT Database.	|

[&larrhk; Back to Table List](#table-listing)


## user\_log

#### Description

The user log table contains information about users accessing the PMT database.

#### Field List

All **bold** fields are required.

| Field		   		| Data Type   		| Default Value	| Constraint			| Description													|
| ----------------------------- | --------------------- |:-------------:|:-----------------------------:| ------------------------------------------------------------------------------------------------------------- |
| **id**      			| serial		|  automated	| PK				| Primary key for the table.										|
| user\_id			| integer		|  		| FK - user.id			| Foreign key to the user table. The user_id of the username.	|
| **\_username**		| character varying(255)| 		| 				| The username of the user accessing the PMT.	|
| **\_access\_date**		| timestamp without time| current date	| 				| The date the user accessed the PMT.	|
| **\_status**			| character varying(50)	| 		| 				| The status of the user's access to the PMT. Options: success or fail.	|

[&larrhk; Back to Table List](#table-listing)


## users

#### Description

The users table contains all the PMT users.

#### Field List

All **bold** fields are required.

| Field		   		| Data Type   		| Default Value	| Constraint			| Description													|
| ----------------------------- | --------------------- |:-------------:|:-----------------------------:| ------------------------------------------------------------------------------------------------------------- |
| **id**      			| serial		|  automated	| PK				| Primary key for the table.										|
| **organization\_id**		| integer		|  		| FK - organization.id		| Foreign key to the organization table. The organization the user belongs to.	|
| **role\_id**			| integer		| 1 		| FK - role.id			| Foreign key to the role table. The role the user is assigned for database level permissions.	|
| \_first\_name			| character varying(150)|  		| 				| First name.	|
| \_last\_name			| character varying(150)|  		| 				| Last name.	|
| **\_username**		| character varying(255)|  		| 				| Username.	|
| **\_email**			| character varying(255)|  		| 				| Email.	|
| **\_password**		| character varying(255)|  		| 				| Password.	|
| **\_active**			| boolean		| true		| 				| T/F the record is active. Inactive records are not accessible through any of the PMT read-only interfaces. Essentially treated as _"deleted"_.	|
| \_retired\_by			| integer		| 		| 				| User id (primary key) of the user record that has replaced/retired this user record.	|
| **\_created\_by**		| character varying(150)| 		| 				| Username of user or script name of data script that has created the record in the PMT Database.	|
| **\_created\_date**		| timestamp without time| current date	| 				| Date the record was created in the PMT Database.	|
| **\_updated\_by**		| character varying(150)| 		| 				| Username of user or script name of data script that has last updated the record in the PMT Database.	|
| **\_updated\_date**		| timestamp without time| current date	| 				| Date the record was last edited in the PMT Database.	|

[&larrhk; Back to Table List](#table-listing)


## version

#### Description

The version table contains all the change information for a PMT instance.

#### Field List

All **bold** fields are required.

| Field		   		| Data Type   		| Default Value	| Constraint			| Description													|
| ----------------------------- | --------------------- |:-------------:|:-----------------------------:| ------------------------------------------------------------------------------------------------------------- |
| **id**      			| serial		|  automated	| PK				| Primary key for the table.										|
| \_version			| numeric(2,1)		|  		| 				| The current version if the PMT database the change set is targeting.	|
| \_iteration			| integer		|  		| 				| The iteration of change for the current version of the PMT database the change set is targeting.	|
| \_changeset			| integer		|  		| 				| The change set number of the iteration and version of the PMT database.	|
| **\_created\_date**		| timestamp without time| current date	| 				| Date the record was created in the PMT Database.	|
| **\_updated\_date**		| timestamp without time| current date	| 				| Date the record was last edited in the PMT Database.	|

#### Triggers 

* **pmt_upd_version** (INSERT) - determines if this change script has been executed before, 
and only records first time executions. Updates the updated_date for additional executions. 

[&larrhk; Back to Table List](#table-listing)
