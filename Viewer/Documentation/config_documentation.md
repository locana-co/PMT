# PMT Viewer Configuration Documentation

Many aspects of the PMT are configurable. This document serves to be a comprehensive
documentation of those configurable elements.

## List of Elements

* [theme](#theme)
  * [pmt](#theme-pmt)
    * [boundaryPoints](#theme-pmt-boundarypoints)
      * [boundary](#theme-pmt-boundarypoints-boundary)
      * [select](#theme-pmt-boundarypoints-select)
  * [fonts](#theme-fonts)
  * [config](#theme-config)
    * [states](#theme-config-states)
      * [home](#theme-config-states-home)
      * [locations](#theme-config-states-locations)
        * [stateParamDefaults](#theme-config-states-locations-stateparamdefaults)
        * tools
          * [map](#theme-config-states-locations-tools-map)
            * [supportingLayers](#theme-config-states-locations-tools-map-supporting-layers)
            * [filters](#theme-config-states-locations-tools-map-filters)
            * [widgets](#theme-config-states-locations-tools-map-widgets)
      * [activities](#theme-config-states-activities)
        * [stateParamDefaults](#theme-config-states-activities-stateparamdefaults)
        * tools
          * [map](#theme-config-states-activities-tools-map)
            * [filters](#theme-config-states-activities-tools-map-filters)
            * [supplemental](#theme-config-states-activities-tools-map-supplemental)
      * [map](#theme-config-states-map)
        * [stateParamDefaults](#theme-config-states-activities-stateparamdefaults)
        * tools
          * [map](#theme-config-states-map-tools-map)
            * [layers](#theme-config-states-map-tools-map-layers)
            * [contextual](#theme-config-states-map-tools-map-contextual)
            * [supportingLayers](#theme-config-states-map-tools-map-supportinglayers)
            * [regions](#theme-config-states-map-tools-map-regions)
            * [filters](#theme-config-states-map-tools-map-filters)
            * [supplemental](#theme-config-states-map-tools-map-supplemental)
      * [partnerlink](#theme-config-states-partnerlink)
        * tools
          * [filters](#theme-config-states-partnerlink-tools-filters)
      * [me](#theme-config-states-me)
      * [admin](#theme-config-states-admin)



* * * * *

## theme

#### Description

A theme is an individual instance of PMT. A theme has a single parameter called "constants" which,
holds the angaularjs constants variables for the instances. All instances
have the same constants variables.

[&larrhk; Back to Element List](#list-of-elements)


## theme pmt

#### Description

The pmt parameter contains all the information to connect to the PMT database,
through the PMT API. blah. blah. blah TODO

##### Parameter(s)

* env (string) - **Required** the environment setting for the target environment. References both the id and api parameter values.
* id (object) - **Required** PMT API resource ids for each available environment. Ids are assigned by the API.
* api (object) - **Required** PMT API urls for each available environment.
* autocompleteText (path) - internal appliation path to auto complete text (not currently in use we should remove.).
* boundaryPoints (object) - **Required** see [boundaryPoints](#theme-pmt-boundarypoints) for details.

##### Example(s)
```
"pmt": {
    "env": "stage",
    "id": {
        "production":1,
        "stage":2,
        "demo": 3,
        "local": 4
    },
    "api": {
        "production":"http://api.v10.investmentmapping.org:8080/api/",
        "stage":"http://api.v10.investmentmapping.org:8082/pmt-api-stage/",
        "demo": "http://api.v10.investmentmapping.org:8083/pmt-api-demo/",
        "local":  "http://localhost:8080/api/"
    },
    "autocompleteText": {
        "file": "assets/pmt_autocomplete_results.json"
    },
    "boundaryPoints": {
        ...
    }
}

```

[&larrhk; Back to Elememt List](#list-of-elements)



## theme pmt boundaryPoints

#### Description

An array of boundary objects containing information for each administrative level,
in which PMT locations are associated to for presentation on the map.

##### Parameter(s)

Array of objects containing the following parameters:

* alias (string) - **Required** unqiue name for the administrative boundary layer.
* file (path) - **Required** internal appliation path to geojson file containing centroid points of boundary layer.
* zoomMin (integer) - **Required** minimum leaflet zoom level to present layer. zoomMin and zoomMax levels should not overlap for a single boundary type (i.e. gaul).
* zoomMax (integer) - **Required** maximum leaflet zoom level to present layer. zoomMin and zoomMax levels should not overlap for a single boundary type (i.e. gaul).
* boundaryId - **Required** unique database id for the boundary
* active - boolean whether or not the layer should be visible on load
* boundary - see [boundary](#theme-pmt-boundarypoints-boundary) for details.
* select - see [select](#theme-pmt-boundarypoints-select) for details.

##### Example(s)
```
"boundaryPoints": {
    "eth": [
        {
            "alias": "gamd0",
            "file": "assets/gadm0.geojson",
            "zoomMin": 4,
            "zoomMax": 5,
            "boundaryId": 15,
            "active": false,
            // optionally boundary points may have a boundary layer associated
            // when present the boundary layer will be show at the same zoom levels
            // as specified by the point layer
            "boundary": {
                ...
            },
            "select": {
                ...
            }
        }
    ]
}
```

[&larrhk; Back to Elememt List](#list-of-elements)


## theme pmt boundaryPoints boundary

#### Description

Boundary points may have an optional boundary layer associated when present the boundary layer will be show at the same zoom levels as specified by the point layer

##### Parameter(s)

Array of objects containing the following parameters:

* alias (string) - **Required** unqiue name for the administrative boundary.
* label (string) - **Required** Human readable label name for the layer.
* url (string) - **Required** URL location of boundary tiles.
* legend (string) - URL location of boundary legend.
* opacity (number) - Opacity of rendered tile layer.
* type (string) - **Required** Tile classification.
* active (boolean) - Whether or not boundary should be active.
* style (object) - Style object for displaying layer.
* filter (array) - Listing of values to show, only the listed values will be displayed.
* filterParam (string) - If filter is specified, filterParam is required. Represents the field the filter is targeting on the layer

##### Example(s)
```
"boundary": {
    "alias": "boundary0",
    "label": "GADM Level 0",
    "url": "https://s3.amazonaws.com/v10.investmentmapping.org/vector-tiles/gadm0/{z}/{x}/{y}.pbf",
    "legend": "",
    "opacity": .80,
    "type": "vectortile",
    "active": false,
    "style": {
        "color": "rgba(0,128,0, 0)",
        "outline": {
            "color": "rgb(0,128,0)",
            "size": 2
        }
    },
    "filter": ["Ethiopia"],
    "filterParam": "_name"
}
```

[&larrhk; Back to Elememt List](#list-of-elements)


## theme pmt boundaryPoints select

#### Description

When a boundary layer is present a select layer should also be present to allow highlighting when point clusters are selected within the boundary layer feature

##### Parameter(s)

Array of objects containing the following parameters:

* alias (string) - **Required** unqiue name for the administrative boundary.
* label (string) - **Required** Human readable label name for the layer.
* url (string) - **Required** URL location of boundary tiles.
* legend (string) - URL location of boundary legend.
* opacity (number) - Opacity of rendered tile layer.
* type (string) - **Required** Tile classification.
* active (boolean) - Whether or not boundary should be active.
* style (object) - Style object for displaying layer.
* filter (array) - Listing of values to show, only the listed values will be displayed.
* filterParam (string) - If filter is specified, filterParam is required. Represents the field the filter is targeting on the layer

##### Example(s)
```
 "select": {
    "alias": "select0",
    "label": "GADM Level 0",
    "url": "https://s3.amazonaws.com/v10.investmentmapping.org/vector-tiles/gadm0/{z}/{x}/{y}.pbf",
    "legend": "",
    "opacity": .80,
    "type": "vectortile",
    "active": false,
    "style": {
        "color": "rgba(235,194,32, 0.2)",
        "outline": {
            "color": "rgb(235,194,32)",
            "size": 2
        }
    },
    "filter": [],
    "filterParam": ""
}
```

[&larrhk; Back to Elememt List](#list-of-elements)



## theme fonts

#### Description

Fonts is an array of external font libraries to include in the application.

##### Example(s)
```
"fonts": [
   "https://fonts.googleapis.com/css?family=Open+Sans:400,700,300,600"
 ]
```

[&larrhk; Back to Element List](#list-of-elements)



## theme config

#### Description

Application configuration settings.


##### Parameter(s)

* url (string) - **Required** the url for the application instance.
* theme (object) - **Required** instance-specific details regarding alias, name, and images.
* links (object) -  **Required** list of external social media links that are associated with the instance.
* meta (object) - **Required** instance metadata.
* login (object) - **Required** whether or not the application requires a login, and if not the user/password that should be the default.
* states (array) - **Required** see [states](#theme-config-states).
* terminology (object) - **Required** object defining the terminology to be used for the words "activity", "boundary", "funder" and "implementor".
  * activity_terminology (object) - **Required** site-wide terminology for word "activity"
    * singular (string) - **Required** singular word for "activity"
    * plural (string) - **Required** plural word for "activity"
  * boundary_terminology (object) - **Required** site-wide terminology for boundary concepts
    * singular (object) - **Required** site-wide terminology for singular concept of boundary
      * admin1 (string) - **Required** singular word for "admin1"
      * admin2 (string) - **Required** singular word for "admin2"
      * admin3 (string) - **Required** singular word for "admin3"
    * plural (object) - **Required** site-wide terminology for plural concept of boundary
      * admin1 (string) - **Required** plural word for "admin1"
      * admin2 (string) - **Required** plural word for "admin2"
      * admin3 (string) - **Required** plural word for "admin3"
  * funder_terminology (object) - **Required** site-wide terminology for word "funder"
    * singular (string) - **Required** singular word for "funder"
    * plural (string) - **Required** plural word for "funder"
  * implementor_terminology (object) - **Required** site-wide terminology for word "implementor"
    * singular (string) - **Required** singular word for "implementor"
    * plural (string) - **Required** plural word for "implementor"
* defaultState (string) - Name of default module for application


##### Example(s)
```
"config": {
   // application instance URL
   "url": "http://v10.investmentmapping.org/ethaim",
   "theme": {
       "alias": "ethaim",
           "name": "ATA",
           "url": "http://www.ata.gov.et/",
           // height must be 45px and width must be 210px
           "topbanner": "example.png",
           // height must be 35px and width must be 185px
           "bottombanner": null
   },
   "links": {
       "socialmedia": {
           "linkedin": null,
           "github": null,
           "twitter": null,
           "facebook": null
       }
   },
   "meta": {
       "title": "Ethiopia Agriculture Investment Mapping (EthAIM) Portfolio Mapping Tool (PMT)",
           "author": "SpatialDev",
           "description": "The PMT is a web application for viewing information supported by the IATI (International Aid Transparency Initiative) Standards. The PMT Viewer provides tools for visualizing and comparing aid data, stored within the PMT Database.",
           "url": "http://spatialdev.github.io/PMT-Viewer",
           "image": "https://s3.amazonaws.com/v10.investmentmapping.org/themes/bmgf/bmgf_logo.gif",
           "twitterHandle": "@gatesfoundation"
   },
   "login": {
       "public": false,
           "username": "",
           "password": ""
   },
   "states": [
        ...
   ],
   "terminology": {
       "activity_terminology": {
           "singular": "project",
               "plural": "projects"
       },
       "boundary_terminology": {
           "singular": {
               "admin1": "region",
                   "admin2": "zone",
                   "admin3": "woreda"
           },
           "plural": {
               "admin1": "regions",
                   "admin2": "zones",
                   "admin3": "woredas"
           }
       },
       "funder_terminology": {
           "singular": "donor",
               "plural": "donors"
       },
       "implementor_terminology": {
           "singular": "implementing partner",
               "plural": "implementing partners"
       }
   },
   "defaultState": "locations"
}
```

[&larrhk; Back to Element List](#list-of-elements)



## theme config states

#### Description

Array of instance modules.  Each module has its own parameters. Potential modules include:

* home (object) - see [home](#theme-config-states-home).
* locations (object) - see [locations](#theme-config-states-locations).
* activities (object) - see [activities](#theme-config-states-activities).
* interactive map (object) see [map](#theme-config-states-map).
* partnerlink (object) see [partnerlink](#theme-config-states-partnerlink).
* measurement and evaluation (object) see [me](#theme-config-states-me).

##### Example(s)
```
"fonts": [
   "https://fonts.googleapis.com/css?family=Open+Sans:400,700,300,600"
 ]
```

[&larrhk; Back to Element List](#list-of-elements)


## theme config states home

#### Description

The home section is the application landing page module.

##### Parameter(s)

* route (string) - **Required** route of "home" module.
* authorization (string) - .  TODO not clear what this is.
* enable (boolean) - **Required** whether or not module is active.
* order (integer) - **Required** ordering for the left nav panel.
* navLabel (string) - **Required** label for the button on the nav panel.
* navIcon (string) - **Required** name of icon to be used on left nav panel.
* title (string) - **Required** title of module.
* subtitle (string) - **Required** subtitle of module.


##### Example(s)
```
{
    "route": "home",
    "authorization": "000000",
    "enable": false,
    "order": 0,
    "navLabel": "Home",
    "navIcon": "fa fa-home",
    "title": "The Home Section",
    "subtitle": "The home section is the application landing page."
}
```
[&larrhk; Back to Element List](#list-of-elements)



## theme config states locations

#### Description

The location section contains all of the summary widgets.  The location module can be customized to contain widgets at the global, national and regional scales.  This section contains both a navigatable map as well as customizable widgets.

##### Parameter(s)

* route (string) - **Required** route of "locations" module.
* authorization (string) - .  TODO not clear what this is.
* enable (boolean) - **Required** whether or not module is active.
* order (integer) - **Required** ordering for the left nav panel.
* navLabel (string) - **Required** label for the button on the nav panel.
* navIcon (string) - **Required** name of icon to be used on left nav panel.
* title (string) - **Required** title of module.
* subtitle (string) - **Required** subtitle of module.
* mapSummary (boolean) - **Required** whether or not the module starts at country or global level. TODO
* stateParamDefaults (object) - **Required** see [stateParamDefaults](#theme-config-states-locations-stateparamdefaults).
* tools (object) - **Required** has one parameter, map, see [stateParamDefaults](#theme-config-states-locations-tools-map).


##### Example(s)
```
{
    "route": "locations",
    "authorization": "000000",
    "enable": true,
    "order": 1,
    "navLabel": "Summaries",
    "navIcon": "fa fa-bar-chart",
    "navURL": null,
    "title": "The Location Section",
    "subtitle": "The location section is for exploring data from a location first perspective.",
    "mapSummary": false,
    "stateParamDefaults": {
       ...
    },
    "tools": {
        "map" : {
           ...
        }
    }
}

```
[&larrhk; Back to Element List](#list-of-elements)




## theme config states locations stateParamDefaults

#### Description

stateParamDefaults define the defaults for the location module.

##### Parameter(s)

* lat (number) - **Required** starting latitude of the map.
* lng (number) - **Required**  starting longitude of the map.
* zoom (integer) - **Required** starting zoom level of the map.
* area (string) - **Required** starting level for widgets : national or regional.
* selection (integer) - **Required** starting selected feature id.
* basemap (string) - **Required** starting selected basemap.
* layers (string) - **Required** starting selected layers on the locations map.


##### Example(s)
```
"stateParamDefaults": {
   "lat": 9.168244,
   "lng": 40.479883,
   "zoom": 5,
   "area": "national",
   "selection": 74, //represents the gadm boundary of Ethiopia
   "basemap": "lightgray",
   "layers": "gadm1"
}

```
[&larrhk; Back to Element List](#list-of-elements)



## theme config states locations tools map

#### Description

map defines the settings for the location modules including which regions are supported, widgets and filters.

##### Parameter(s)

* minZoom (number) - **Required** min zoom for the map.
* maxZoom (number) - **Required**  max zoom for the map.
* layers (array) - **Required** array of layers to be added to the map.  Default empty. TODO
* contextual (array) - **Required** array of contextual layers to be added to the map. Default empty. TODO
* supportingLayers (array) - **Required** see [supportingLayers](#theme-config-states-locations-tools-map-supporting-layers).
* countries (array) - **Required** list of countries supported in the locations module. "_name" and "id" properties must match supporting layer properties exactly.
* filters (object) - **Required** see [filters](#theme-config-states-locations-tools-map-filters).
* widgets (object) - **Required** see [widgets](#theme-config-states-locations-tools-map-widgets).
* params (object) - **Required** additional parameters.  Currently, only parameter is a label for investment data.


##### Example(s)
```
"map": {
    "minZoom": 2,
        "maxZoom": 19,
        "layers": [],
        "contextual": [],
        "supportingLayers": [
            ...
        ],
        "countries": [
            {
                "_name": "Ethiopia",
                "id": "74"
            }
        ],
        "filters": [
            ...
        ],
        "widgets": [
            ...
        ],
        "params": {
            "investment_label": "Total Agricultural Investment"
        }
}

```
[&larrhk; Back to Element List](#list-of-elements)


## theme config states locations tools map supportingLayers

#### Description

array of supporting map layers used for showing locations of summary data and for allowing the user to navigate to location summaries through a map interface.

##### Parameter(s)

* alias (string) - **Required** unique name for the administrative boundary.
* label (string) - **Required** UI label name for the layer.
* url (string) - **Required** URL location of boundary tiles.
* legend (string) - URL location of boundary legend.
* opacity (number) - Opacity of rendered tile layer.
* type (string) - **Required** Tile classification.
* active (boolean) - Whether or not boundary should be active.
* style (object) - Style object for displaying layer.
* filter (array) - Listing of values to show, only the listed values will be displayed.
* filterParam (string) - If filter is specified, filterParam is required. Represents the field the filter is targeting on the layer


##### Example(s)
```
"supportingLayers": [
    {
        "alias": "gadm0",
        "label": "GADM Level 0",
        "url": "https://s3.amazonaws.com/v10.investmentmapping.org/vector-tiles/gadm0/{z}/{x}/{y}.pbf",
        "legend": "https://s3.amazonaws.com/v10.investmentmapping.org/vector-tiles/legends/mapLegend_country.png",
        "opacity": .80,
        "type": "vectortile",
        "active": false,
        "area": "national",
        "spatialTable": "gadm0",
        "boundary_id": 15, //gadm0
        "style": {
            "color": "rgba(62,127,152,0.7)",
            "outline": {
                "color": "rgb(255,255,255)",
                "size": 1
            },
            "selected": {
                "color": "rgba(90,176,209,0.3)",
                "outline": {
                    "color": "rgba(212,239,250,1)",
                    "size": 1
                }
            }
        }
]

```
[&larrhk; Back to Element List](#list-of-elements)



## theme config states locations tools map filters

#### Description

array of filters for locations data.

##### Parameter(s)

* id (string) - **Required** unique id for the filter.
* label (string) - **Required** UI label name for the filter.
* tpl (string) - **Required** Location of html template for filter.
* enable (boolean) - Filter is enabled/visible (t/f).
* active (boolean) - Filter is active (open by default: t/f).
* type (string) - **Required** Filters can be of type "datasource", "taxonomy" or "date".
* params (object) - **Required** Listing of parameters for each filter.  Each filter type has its own parameters.
    data source
    * dataSources - Array of data sources.
        * label (string) - **Required** label for the data group.
        * dataGroupIds (string) - **Required** comma seperated list of data group ids.
        * active (boolean) - **Required** default active (t/f).
    taxonomy
    * taxonomy_id (integer) - **Required** database id for particular taxonomy.
    * filter (arrray) - **Required** limit the filter options to only the listed ids.
    * unassigned (boolean) - **Required** show unassigned taxonomy option (t/f).
    * defaults (array) - **Required** id defaults for the taxonomy.
    date - No extra parameters needed.


##### Example(s)
```
"filters": [
    // data sources
    {
        // available data sources for the filter are defined by the layers
        // defined in tools.map.layers
        "id": "locsfilter1",
        "label": "Data Sources",
        "tpl": "locs/filter/datasource/datasource.tpl.html",
        "enable": false,
        "active": false,
        // filter type
        "type": "datasource",
        "params": {
            "dataSources": [
                {
                    // label for application
                    "label": "RED&FS",
                    // data group id(s)
                    "dataGroupIds": "2237",
                    // default active (t/f)
                    "active": true
                }
            ]
        }
    },
    // taxonomy (Activity Status)
    {
        "id": "locsfilter2",
        "label": "Activity Status",
        "tpl": "locs/filter/taxonomy/taxonomy.tpl.html",
        // filter is active (open by default: t/f)
        "active": false,
        // filter type
        // options: datasource, date, taxonomy
        "type": "taxonomy",
        "params": {
            "taxonomy_id": 18,
            // limit the filter options to only the listed
            "filter": [],
            // show unassigned taxonomy option (t/f)
            "unassigned": true,
            // options (classifications) to set to active by default
            "defaults": []
        }
    },
     // date
    {
        "id": "locsfilter3",
        "label": "Date",
        "tpl": "locs/filter/date/date.tpl.html",
        "active": false,
        "type": "date",
        "params": {}
    }
],

```
[&larrhk; Back to Element List](#list-of-elements)




## theme config states locations tools map widgets

#### Description

array of widgets for locations data.  All widgets are not required and can be customized based on geographic level and instance-specific data.

##### Parameter(s)
overview widget
* id (string) - **Required** unique id for the widget.
* title (string) - **Required** UI title for the widget.
* tpl (string) - **Required** Location of html template for widget.
* area (string) - **Required** widget display area (options: world, national, regional).
* row (integer) - **Required** row number widget is placed in.
* colspan (integer) - **Required** column span (1-12).
* params (object) - **Required** Listing of parameters for widget.
    * overview (array) - List of overview widgets.
        * mapFilter (boolean) - **Required** whether the map should filter the data.
        * stats (array) - **Required** list of statistics to be included in overview widget.
            * statistic (string) - **Required** name of statistic from the database.
            * title (string) - **Required** statistic title to show up in UI.
            * description (string) - **Required** statistic description to show up in UI.

success stories widget
* id (string) - **Required** unique id for the widget.
* title (string) - **Required** UI title for the widget.
* subtitle (string) - UI subtitle for the widget.
* footnote (string) - UI footnote for the widget.
* tpl (string) - **Required** Location of html template for widget.
* area (string) - **Required** widget display area (options: world, national, regional).
* row (integer) - **Required** row number widget is placed in.
* colspan (integer) - **Required** column span (1-12).
* params (object) - **Required** Listing of parameters for widget.
    * stories (object) - Story object contains a parameter for each country that has story data.
        * Ethiopia (array) - List of country stories.
            * title (string) - title to show up in UI.
            * subTitle (string) - subTitle to show up in UI.
            * story (object) - an individual story for an individual country.
                * text (string) - story text.
                * italic (array) - array of phrases which should be italicized.
            * details (string) - TODO.
            * quote (object) - display quote for a story.
                * text (string) - quote text.
            * image (object) - image for a story.
                * source (string) - url location of image.
                * caption (string) - image caption.

external link widget
* id (string) - **Required** unique id for the widget.
* title (string) - **Required** UI title for the widget.
* subtitle (string) - UI subtitle for the widget.
* footnote (string) - UI footnote for the widget.
* tpl (string) - **Required** Location of html template for widget.
* area (string) - **Required** widget display area (options: world, national, regional).
* row (integer) - **Required** row number widget is placed in.
* colspan (integer) - **Required** column span (1-12).
* params (object) - **Required** Listing of parameters for widget.
    * url (string) - **Required**  url of external link.

summary widget top widget by top (x) funders
* id (string) - **Required** unique id for the widget.
* title (string) - **Required** UI title for the widget.
* subtitle (string) - UI subtitle for the widget.
* footnote (string) - UI footnote for the widget.
* tpl (string) - **Required** Location of html template for widget.
* area (string) - **Required** widget display area (options: world, national, regional).
* row (integer) - **Required** row number widget is placed in.
* colspan (integer) - **Required** column span (1-12).
* params (object) - **Required** Listing of parameters for widget.
    * top (integer) - **Required**  number of top organizations to show.
    * org_role_id (integer) - **Required**  organization role id.

summary widget top activities by taxonomy
* id (string) - **Required** unique id for the widget.
* title (string) - **Required** UI title for the widget.
* tpl (string) - **Required** Location of html template for widget.
* area (string) - **Required** widget display area (options: world, national, regional).
* row (integer) - **Required** row number widget is placed in.
* colspan (integer) - **Required** column span (1-12).
* colors (array) - **Required** pie pieces color range, ensure there are enough colors in the range.
* params (object) - **Required** Listing of parameters for widget.
    * taxonomy_id (integer) - **Required**  the taxonomy to summarize by.

summary widget partner(organization) pivot
* id (string) - **Required** unique id for the widget.
* title (string) - **Required** UI title for the widget.
* tpl (string) - **Required** Location of html template for widget.
* area (string) - **Required** widget display area (options: world, national, regional).
* row (integer) - **Required** row number widget is placed in.
* colspan (integer) - **Required** column span (1-12).
* params (object) - **Required** Listing of parameters for each widget.
    * org_role_id (integer) - **Required**  the default organization role for organizations (cells of pivot).
    * partner_filters (array) - **Required** list of org_role options for widget dropdown.
        * name (string) - **Required**  name for dropdown label.
        * org_role_id (integer) - **Required**  the organization role for organizations (cells of pivot).
    * axis_options (array) - **Required** dropdown options for pivot table.  If more than 2 options are given, dropdowns are generated in the UI.
        * pivot_on_locations (boolean) - **Required**  whether or not option represents a boundary.
        * label (string) - **Required**  axis label.

        If pivoting on location
         * pivot_boundary_id (integer) - **Required**  boundary id to pivot on.

        If NOT pivoting on location
        * taxonomy_id (integer) - if option is a taxonomy, taxonomy id should be provided.


summary widget activities by taxonomy (vertical bar chart)
* id (string) - **Required** unique id for the widget.
* title (string) - **Required** UI title for the widget.
* subtitle (string) - UI subtitle for the widget.
* footnote (string) - UI footnote for the widget.
* tpl (string) - **Required** Location of html template for widget.
* area (string) - **Required** widget display area (options: world, national, regional).
* row (integer) - **Required** row number widget is placed in.
* colspan (integer) - **Required** column span (1-12).
* colors (array) - **Required** pie pieces color range, ensure there are enough colors in the range.
* params (object) - **Required** Listing of parameters for widget.
    * taxonomy_id (integer) - **Required**  the taxonomy to summarize by.
    * top (integer) - **Required**  number of taxonomies to show.
    * show_other (boolean) - **Required**  whether to show "Other" category.
    * other_label (string) - **Required**  label for "Other" category.


##### Example(s)
```
// interactive map settings
"widgets": [
    // overview widget
    {
        "id": "widget0",
        "title": "At a glance",
        "tpl": "locs/widget/overview/overview.tpl.html",
        "area": "world",
        "row": 0,
        "colspan": 12,
        "params": {
            // title & description text for stats
            "overview": [
                {
                    "mapFilter": false,
                    "stats": [
                        {
                            "statistic": "country_count",
                            "title": "Total Countries",
                            "description": "Number of countries where AGRA has agriculatural development efforts"
                        },
                        {
                            "statistic": "activity_count",
                            "title": "Total Grants",
                            "description": "Number of AGRA agricultural grants world wide"
                        }
                    ]
                }
            ]
        }
    },
    //success stories
    {
        "id": "widget1",
        "title": "Stories",
        "subtitle": "",
        "footnote": "",
        "tpl": "locs/widget/stories/stories.tpl.html",
        "area": "national",
        "row": 0,
        // column span (1-12)
        "colspan": 6,
        "params": {
            // success stories
            "stories": {
                "Ethiopia": [{
                    "title": "Ethiopian farmers adopt hybrid seeds",
                    "subTitle": "In the Southern Nations, Nationalities, and Peoples%% Region (SNNP), one of the nine ethnic divisions (kililoch) of Ethiopia, Wulchafo Surage, is busy constructing a granary for the first time in his compound in anticipation of a bumper harvest.",
                    "story": {
                        "text": "The 44-year-old father of 5 is one of a few smallholder farmers in Ethiopia who have boosted their maize yields by planting high-quality hybrid seeds, and using the recommended amount of fertilizers. @@ According to official records, hybrid seed uptake in Ethiopia stands at only 10%, particularly among smallholder farmers. This compares poorly with a country like Kenya, whose uptake of hybrid maize seed is about 60% nationally. @@ A recent report by the International Food Policy Research Institute (IFPRI), titled %%Seed System Potential in Ethiopia%%, points out that the shortage of hybrid maize seed in the country is a national concern because farmers are unable to access seed in the quantities they need. @@As a result, the average yield of maize in Ethiopia stands at 2 t/ha, which is far lower than the potential average of 6 t/ha, depending on the hybrid variety planted, prevailing weather conditions, and the quality of field management. @@To bridge this gap, Alemayehu Makonnen, a large-scale farmer in the SNNP region, is now dedicated to producing hybrid seed (with support from AGRA) as a way of boosting food productivity in the country – and farmers are already taking it up. @@&&I tried out hybrid maize seed for the first time in 2011, after attending a farmer field day at Makonnen%%s farm,&& said Surage, a farmer in the region. @@After realizing that the yield from a half-hectare piece of land planted to hybrid maize was higher than that from two and a half hectares planted to non-hybrid seed, he decided to plant the recommended hybrid maize variety and apply fertilizer on his entire 3-hectare piece of land in 2012. @@This gave him a yield of 18 tons of maize from three hectares, six times more than he had been harvesting before. He has continued with this practice, with similar results in 2013 and 2014. @@&&Many other farmers who have seen my crop have turned to hybrid seeds,&& said Surage, who is a member of the Adjo Farmer Association. @@And Makonnen now reports that he expects to sell the hybrid seed to over 20,000 farmers for the next planting season, as farmers continue adopting the hybrid technology. @@ Up to 80% of smallholder farmers in the region who planted hybrid seed and used improved management practices over the past three years have realized an average yield of 4 t/ha, with the highest recording 6 t/ha, according to Makonnen. @@&&From my observation, many people do not use high quality seed and farm inputs simply because they do not know where to find them, and sometimes because they lack the working capital. Experience has shown that a little capacity building can change the situation within a very short period,&& he said. @@ In 2011, when he expanded the production of hybrid maize seed using a grant from AGRA, 1,000 farmers from the region purchased it. Their yields were quite impressive, attracting an additional 5,000 farmers in 2012. And in 2013 (the latest available data), 16,000 farmers bought the seed – a clear indication that adoption is growing rapidly. This number is expected to have increased yet again in 2014. @@The impact is evident from farmers%% testimonies. &&Last year I harvested 20 bags (90 kg each) of maize, which is the highest I have ever achieved in my life as a farmer,&& said Hilda Alem, a smallholder farmer from the region. &&This hybrid seed is changing my life!&&",
                        "italic": ["Seed System Potential in Ethiopia"]
                    },
                    "details": null,
                    "quote": {
                        "text": "Last year I harvested 20 bags of maize, which is the highest I have ever achieved in my life as a farmer...This hybrid seed is changing my life!"
                    },
                    "image": {
                        "source": "https://s3.amazonaws.com/v10.investmentmapping.org/themes/agra/success_stories/example.jpg",
                        "caption": "The yield from a half-hectare piece of land planted to hybrid maize was higher than that from two and a half hectares planted planted to non-hybrid varieties."
                    }

                }],
            }
        }
    },
    // external link
    {
        "id": "widget2",
        "title": "Watch the AGRA story",
        "subtitle": "The March Towards a Green Revolution in Africa",
        "footnote": "",
        "tpl": "locs/widget/external-link/external-link.tpl.html",
        "area": "national",
        "row": 0,
        "colspan": 6,
        "params": {
            "url": "https://www.youtube.com/watch?v=CM_2FWzc3QU"
        }
    },
    // summarization widget for investments
    // by top (x) funders - national
    {
        "id": "widget3",
        "title": "Top Funding Partners by Investment Amount",
        "subtitle": "Top Funding Partners",
        "footnote": "",
        "tpl": "locs/widget/top-dollar/top-dollar.tpl.html",
        "area": "national",
        "row": 1,
        "colspan": 6,
        "params": {
            "top": 5,
            "org_role_id": 496
        }
    },
    //summarization widget for total activities
    //by a taxonomy - national
    {
        "id": "widget4",
        "title": "Top Programs by Investment Amount",
        "tpl": "locs/widget/tax-summary/tax-summary.tpl.html",
        "area": "national",
        "row": 1,
        "colspan": 6,
        "colors": ["#C13838", "#D35731", "#B0693D", "#586D5B", "#458080", "#75A4AE", "#98AFAA", "#AEA176", "#BDA151", "#C7B03B,#CA4835", "#DC672E", "#846B4C", "#2D6F6A", "#5D9297", "#8DB6C5", "#A3A890", "#B99A5C", "#C2A946", "#CCB830"],
        "params": {
            "taxonomy_id": 70
        }
    },
    // partner pivot widget - national
    {
        "id": "widget5",
        "title": "Matrix of Agriculture Investments by",
        "tpl": "locs/widget/pivot/pivot.tpl.html",
        // widget display area (options: world, national, regional)
        "area": "national",
        // row number widget is placed in
        "row": 2,
        // column span (1-12)
        "colspan": 12,
        "params": {
            // the organization role for organizations (cells of pivot)
            "org_role_id": 497,
            "partner_filters": [
                {
                    "name": "Implementing Partners",
                    "org_role_id": 497
                },
                {
                    "name": "Funding Partners",
                    "org_role_id": 496
                }
            ],
            "axis_options": [
                {
                    "pivot_on_locations": false,
                    "row_taxonomy_id": 72,
                    "label": "Investment Programs"
                },
                {
                    "pivot_on_locations": true,
                    "label": "Region",
                    "pivot_boundary_id": 16
                }
            ],
            "unspecified_label": "Cross Cutting",
            "show_empty_columns": false
        }
    },
    //summarization widget for total activities
    //by a taxonomy (sector) - regional
    {
        "id": "widget6",
        "title": "Top Sub-Programs by Grant Count",
        "subtitle": "",
        "footnote": "",
        "tpl": "locs/widget/top-taxonomy/top-taxonomy.tpl.html",
        "area": "regional",
        "row": 3,
        "colspan": 6,
        "colors": ["#8ca3d3", "#b8995f", "#2e6e6b", "#cf6e34", "#ad2542", "#727273"],
        "params": {
            "taxonomy_id": 71,
            "top": 5,
            "show_other": true,
            "other_label": "Other"
        }
    },
]
```
[&larrhk; Back to Element List](#list-of-elements)


## theme config states activities

#### Description

The home section is the application landing page module.

##### Parameter(s)

* route (string) - **Required** route of "activities" module.
* authorization (string) - .  TODO not clear what this is.
* enable (boolean) - **Required** whether or not module is active.
* order (integer) - **Required** ordering for the left nav panel.
* navLabel (string) - **Required** label for the button on the nav panel.
* navIcon (string) - **Required** name of icon to be used on left nav panel.
* title (string) - **Required** title of module.
* subtitle (string) - **Required** subtitle of module.
* stateParamDefaults (object) - **Required** see [stateParamDefaults](#theme-config-states-activities-stateparamdefaults).
* tools (object) - **Required** has one parameter, map, see [stateParamDefaults](#theme-config-states-activities-tools-map).


##### Example(s)
```
{
    "route": "activities",
    "authorization": "000000",
    "enable": true,
    "order": 2,
    "navLabel": "Projects",
    "navIcon": "fa fa-list-ul",
    "navURL": null,
    "title": "The Activity Section",
    "subtitle": "The activity section is for exploring data from a activity first perspective.",
    "stateParamDefaults": {
        ...
    },
    // tool settings
    "tools": {
        ...
    }
}
```
[&larrhk; Back to Element List](#list-of-elements)


## theme config states locations stateParamDefaults

#### Description

stateParamDefaults define the defaults for the location module.

##### Parameter(s)

* lat (number) - **Required** starting latitude of the map.
* lng (number) - **Required**  starting longitude of the map.
* zoom (integer) - **Required** starting zoom level of the map.
* basemap (string) - **Required** starting selected basemap.
* layers (string) - **Required** starting selected layers on the activity map.


##### Example(s)
```
"stateParamDefaults": {
    "lat": 35.068359,
    "lng": -6.031311,
    "zoom": 5,
    "basemap": "standardopenstreetmap",
    "layers": ""
}
```
[&larrhk; Back to Element List](#list-of-elements)



## theme config states activities tools map

#### Description

map defines the settings for the activities module including which regions are supported, widgets and filters.

##### Parameter(s)

* minZoom (number) - **Required** min zoom for the map.
* maxZoom (number) - **Required**  max zoom for the map.
* layers (array) - **Required** array of layers to be added to the map.  Default empty. TODO
* contextual (array) - **Required** array of contextual layers to be added to the map. Default empty. TODO
* supportingLayers (array) - **Required** array of supporting layers to be added to the map. Default empty. TODO
* filters (array) - **Required** see [filters](#theme-config-states-activities-tools-map-filters).
* supplemental (array) - **Required** see [filters](#theme-config-states-activities-tools-map-supplemental).
* params (object) - **Required** additional parameters.
  * showCountry (boolean) - whether or not to show country or default to showing funding partner on activity detail header.
  * showAdmin3 (boolean) - whether to show admin 3 or stop at admin 2.
  * activityListColumns (array) - columns to show on activity list.  Options: data_group, start_date, end_date, funding



##### Example(s)
```
"map": {
    "minZoom": 2,
    "maxZoom": 19,
    "layers": [],
    "contextual": [],
    "supportingLayers": [],
    "filters": [],
    // external additional resources
    "supplemental": [],
    "params": {
        "showCountry": false,
        "showAdmin3": true,
        "activityListColumns": ["start_date", "end_date", "funding"]
    }
}

```
[&larrhk; Back to Element List](#list-of-elements)


## theme config states activities tools map filters

#### Description

array of filters for locations data.

##### Parameter(s)

* id (string) - **Required** unique id for the filter.
* label (string) - **Required** UI label name for the filter.
* tpl (string) - **Required** Location of html template for filter.
* enable (boolean) - Filter is enabled/visible (t/f).
* active (boolean) - Filter is active (open by default: t/f).
* type (string) - **Required** Filters can be of type "datasource", "organization", "taxonomy", "geographic".
* params (object) - **Required** Listing of parameters for each filter.  Each filter type has its own parameters.
    data source
    * dataSources - Array of data sources.
        * label (string) - **Required** label for the data group.
        * dataGroupIds (string) - **Required** comma seperated list of data group ids.
        * active (boolean) - **Required** default active (t/f).
    organization
    * org_role_ids (string) - **Required** the filter for organization role to restrict data to. Comma separated list of ids.
    * type (string) - **Required**  organization type (options: implementing, funding, all).
    taxonomy
    * taxonomy_id (integer) - **Required** database id for particular taxonomy.
    * filter (array) - **Required** limit the filter options to only the listed ids.
    * unassigned (boolean) - **Required** show unassigned taxonomy option (t/f).
    * defaults (array) - **Required** id defaults for the taxonomy.

##### Example(s)
```
"filters": [
    // data sources
    {
        "id": "actsfilter1",
        "label": "Data Sources",
        "tpl": "acts/filter/datasource/datasource.tpl.html",
        "enable": false,
        "active": false,
        "type": "datasource",
        "params": {
            "dataSources": [
                {
                    "label": "RED&FS",
                    "dataGroupIds": "2237",
                    "active": true
                }
            ]
        }
    },
    // funding organizations
    {
        "id": "actsfilter2",
        "label": "Donors",
        "tpl": "acts/filter/organization/organization.tpl.html",
        "active": false,
        "type": "organization",
        "params": {
            "org_role_ids": "496",
            "type": "funding"
        }
    },
    // taxonomy (Sector Category)
    {
        "id": "mapfilter5",
        "label": "Sector Category",
        "tpl": "acts/filter/taxonomy/taxonomy.tpl.html",
        // filter is active (open by default: t/f)
        "active": false,
        // filter type
        // options: datasource, organization, taxonomy, geographic
        "type": "taxonomy",
        "params": {
            "taxonomy_id": 14,
            "filter": [ 532, 534, 535, 540, 543, 544, 545, 546, 549, 551, 552, 553, 554, 559, 563 ],
            "unassigned": true,
            "defaults": []
        }
    }
],

```
[&larrhk; Back to Element List](#list-of-elements)



## theme config states activities tools map supplemental

#### Description

external additional resources that should be attached to a given activity.

##### Parameter(s)

* title (string) - **Required** name/title of the link.
* url (string) - **Required**  url to be linked.
* type (string) - **Required** name should be of material design icon
* classification_ids (array) - **Required** supplemental information links will be associated to activities with the following classification ids assigned
* keywords (object) - **Required** supplemental information will be associated to activities where any of the keywords appear in any of the listed fields
  * fields (array) - fields to search for keywords in.
  * keywords (array) - list of keywords.

##### Example(s)
```
 "supplemental": [
    {
        "title": "Seize the Moment",
        "url": "https://www.youtube.com/watch?v=eMgophNDQe8",
        "type": "videocam",
        "classification_ids": [2289, 2308, 2309, 2310, 2311, 2312, 2313, 2314, 2304, 2288, 2296, 2315, 2301, 2306, 2307],
        "keywords": {
            "fields": ["_title", "_description"],
            "keywords": ["policy", "seed", "seeds", "soil", "soils", "market", "markets", "finance", "storage", "capacity building"]
        }
    }
 ]

```
[&larrhk; Back to Element List](#list-of-elements)


## theme config states map

#### Description

The map section houses the interactive map module.  This section allows users to visualize project/activity data spatially.  Data can be filtered, and visualized with contextual layers.  This module also contains the walkshed tool and a detail panel for users to see high-level details about a specific project.

##### Parameter(s)

* route (string) - **Required** route of "map" module.
* authorization (string) - .  TODO not clear what this is.
* enable (boolean) - **Required** whether or not module is active.
* order (integer) - **Required** ordering for the left nav panel.
* navLabel (string) - **Required** label for the button on the nav panel.
* navIcon (string) - **Required** name of icon to be used on left nav panel.
* title (string) - **Required** title of module.
* subtitle (string) - **Required** subtitle of module.
* stateParamDefaults (object) - **Required** see [stateParamDefaults](#theme-config-states-map-stateparamdefaults).
* tools (object) - **Required** contains additional parameters for interactive map module.
  * map (object) - **Required** see [stateParamDefaults](#theme-config-states-map-tools-map).
  * geocoderKey (string) - **Required** geocoder key for location search, interactive map.


##### Example(s)
```
{
    "route": "map",
    "authorization": "000000",
    "enable": true,
    "order": 2,
    "navLabel": "Map",
    "navIcon": "fa fa-globe",
    "navURL": "assets/icon_globe.svg",
    "title": "The Interactive Map Section",
    "subtitle": "The interactive map section is for exploring the spatial data.",
    "stateParamDefaults": {
       ...
    },
    "tools": {
        "map" : {
           ...
        },
        "geocoderKey": {
            "key": "7ec03ba5eb2a8d457af76416a35a5728"
        }
    }
}
```
[&larrhk; Back to Element List](#list-of-elements)


## theme config states map stateParamDefaults

#### Description

stateParamDefaults define the defaults for the map module.

##### Parameter(s)

* lat (number) - **Required** starting latitude of the map.
* lng (number) - **Required**  starting longitude of the map.
* zoom (integer) - **Required** starting zoom level of the map.
* basemap (string) - **Required** starting selected basemap.
* layers (string) - **Required** starting selected layers on the map.


##### Example(s)
```
"stateParamDefaults": {
    "lat": 8.8919,
    "lng": 38.7220,
    "zoom": 6,
    "basemap": "standardopenstreetmap",
    "layers": "ethaim"
}

```
[&larrhk; Back to Element List](#list-of-elements)


## theme config states map tools map

#### Description

map defines the settings for the map module including which tools, contextual layers and filters are available to the user.

##### Parameter(s)

* minZoom (number) - **Required** min zoom for the map.
* maxZoom (number) - **Required**  max zoom for the map.
* layers (array) - **Required** see [layers](#theme-config-states-map-tools-map-layers).
* contextual (array) - **Required** see [contextual](#theme-config-states-map-tools-map-contextual).
* supportingLayers (array) - **Required** see [supportingLayers](#theme-config-states-map-tools-map-supportinglayers).
* activityClusterLegend (string) - legend location for activity clusters
* regions (object) - **Required** see [regions](#theme-config-states-activities-tools-map-regions).
* filters (array) - **Required** see [filters](#theme-config-states-activities-tools-map-filters).
* timeslider (object) - **Required** settings for the timeslider
  * defaultStart (integer) - the default start year on initialization
  * defaultEnd (integer) - the default end year on initialization
  * floor (integer) - the timeslider's minimum year
  * ceiling (integer) - tthe timeslider's maximum year
* targetAnalysis (object) - **Required** settings for the target analysis tool
  * active (boolean) - whether or not the tool is active
  * countries (array) - list of countries that the tool supports
  * supportingLayer (string) - layer that is used to summarize target analysis results
* travel (object) - **Required** settings for the walkshed/travel tool
  * active (boolean) - whether or not the tool is active
  * taxonomy (integer) - id of taxonomy to be summarized by travel tool
  * subtaxonomy (integer) - id of sub taxonomy to be summarized by travel tool
  * countries (string) - name of preferred country boundary layer
  * regions (string) - name of preferred region boundary layer
  * districts (string) - name of preferred district boundary layer
  * showInvestmentData (boolean) - whether or not to show investment data
* supplemental (array) - see [filters](#theme-config-states-map-tools-map-supplemental).
* tpl (string) - **Required** Location of html template for filter.

##### Example(s)
```
"map": {
    "minZoom": 2,
    "maxZoom": 19,
    "layers": [
        ...
    ],
    "contextual": [
        ...
    ],
    "supportingLayers": [
        ...
    ],
    "activityClusterLegend" : "https://s3.amazonaws.com/v10.investmentmapping.org/vector-tiles/legends/mapLegend_project_cluster.png",
    "regions" : {
        ...
    },
    "filters": [
        ...
    ],
    "timeslider": {
        "defaultStart": 2002,
        "defaultEnd": 2020,
        "floor": 2000,
        "ceiling": 2025
    },
    "targetAnalysis": {
        "active": false,
        "countries": ["Ethiopia"],
        "supportingLayer": "gadm1"
    },
    "travel": {
        "active": true,
        "taxonomy": 68,
        "subtaxonomy": 69,
        "countries": "gadm0",
        "regions": "eth_1",
        "districts": "eth_2",
        "showInvestmentData": false
    },
    "supplemental": [
        ...
    ],
    "tpl": "map/map/map.tpl.html"
}
```
[&larrhk; Back to Element List](#list-of-elements)



## theme config states locations tools map layers

#### Description

Array of map layers (data sources) to be included on the interactive map

##### Parameter(s)

* alias (string) - **Required** unique name for the data source. (must be unique with contextual layers as well).
* label (string) - **Required** UI label name for the layer.
* dataGroupIds (string) - **Required** comma separated list of data group ids to be included in the layer.
* boundaryPoints (string) - the boundaryPoints to cluster to (see: [boundaryPoints](#theme-pmt-boundarypoints) )
* export (string) - export function for the layer.


##### Example(s)
```
"layers": [
    {
        "alias": "bmgf",
        "label": "BMGF",
        "dataGroupIds": "768",
        "boundaryPoints": "gadm",
        "export": "pmt_export_bmgf"
    }
]
```
[&larrhk; Back to Element List](#list-of-elements)


## theme config states locations tools map contextual

#### Description

Array of map contextual layers to be included on the interactive map

##### Parameter(s)

* alias (string) - **Required** unique name for group of contextual layers.
* label (string) - **Required** UI label name for the layers group.
* layers (array) - **Required** list of layers to be included in layer group.
  * alias (string) - **Required** unique name for map layer.
  * label (string) - **Required** UI label name for the layer.
  * url (string) - **Required** location of map layer.
  * legend (string) - **Required** location of map layer legend.
  * opacity (number) - opacity of layer on initialization.
  * type (string) - **Required** layer type.
  * active (boolean) - whether or not layer is active on initialization.
  * style (object) - style object for layer.
    * color (string) - style color for layer.
* metadata (object) - metadata object for layer.
  * source (string) - layer source.
  * reference_period (string) - layer reference period.
  * URL (string) - layer URL.

##### Example(s)
```
{
    "alias": "baselayers",
    "label": "Base Layers",
    "active": false,
    "layers": [
        {
            "alias": "boundary0_contextual",
            "label": "Country",
            "url": "https://s3.amazonaws.com/v10.investmentmapping.org/vector-tiles/gadm0/{z}/{x}/{y}.pbf",
            "legend" : "https://s3.amazonaws.com/v10.investmentmapping.org/vector-tiles/legends/mapLegend_country.png",
            "opacity": .80,
            "type": "vectortile",
            "active": false,
            "style": {
                "color": "rgba(0,128,0,0)"
            }
        }
    ],
    "metadata": {
        "source": "GADM",
        "reference_period": "NA",
        "URL": "NA"
     }
},
```
[&larrhk; Back to Element List](#list-of-elements)



## theme config states locations tools map supportingLayers

#### Description

Array of map supporting layers to be included on the interactive map for visualizing the boundaries of map clusers

##### Parameter(s)

* alias (string) - **Required** unique name for map layer.
* label (string) - **Required** UI label name for the layer.
* url (string) - **Required** location of map layer.
* legend (string) - **Required** location of map layer legend.
* opacity (number) - opacity of layer on initialization.
* type (string) - **Required** layer type.
* active (boolean) - whether or not layer is active on initialization.



##### Example(s)
```
"supportingLayers": [
    {
        "alias": "gadm0",
        "label": "GADM Level 0",
        "url": "https://s3.amazonaws.com/v10.investmentmapping.org/vector-tiles/gadm0/{z}/{x}/{y}.pbf",
        "legend": "",
        "opacity": .80,
        "type": "vectortile",
        "active": false
    }
]
```
[&larrhk; Back to Element List](#list-of-elements)


## theme config states map tools map regions

#### Description

regions feature collection TODO

##### Parameter(s)

* type (string) - **Required** "FeatureCollection".
* features (array) - **Required**  list of feature objects.
  * type (string) - "Feature".
  * geometry (object) - geometry object for a single feature.
    * type (string) - "Feature".
    * coordinates (array) - List of feature coordinate.
  * properties (object) - feature properties.
    * alias (string) - alias for feature.
    * name (string) - name of feature.
    * classification_ids (string) - feature classification ids.  TODO
    * sort_order (string) - feature sort order.

##### Example(s)
```
 "regions": {
     "type": "FeatureCollection",
         "features": [
         // example: Ethiopia
         {
             "type": "Feature",
             "geometry": {
                 "type": "Polygon",
                 "coordinates": [
                     [30.9814453125, 17.55173587948925],
                     [50.1416015625, 17.55173587948925],
                     [50.1416015625, -1.2832331602903575],
                     [30.9814453125, -1.2832331602903575],
                     [30.9814453125, 17.55173587948925]
                 ]
             },
             "properties": {
                 "alias": "ethiopia",
                 "name": "Ethiopia",
                 "classification_ids": [94],
                 "sort_order": 2
             }
         },
     ]
 },
 ]

```
[&larrhk; Back to Element List](#list-of-elements)


## theme config states map tools map filters

#### Description

array of filters for interactive map module.  Filters can be used to filter instance data in the UI.

##### Parameter(s)

* id (string) - **Required** unique id for the filter.
* label (string) - **Required** UI label name for the filter.
* tpl (string) - **Required** Location of html template for filter.
* enable (boolean) - Filter is enabled/visible (t/f).
* params (object) - Listing of parameters for each filter.  Each filter type has its own parameters.
    data source - no additional params. available data sources for the filter are defined by the layers defined in tools.map.layers
    organization
    * org_role_ids (string) - **Required** the filter for organization role to restrict data to. Comma separated list of ids.
    * type (string) - **Required**  organization type (options: implementing, funding, all).
    taxonomy
    * taxonomy_id (integer) - **Required** database id for particular taxonomy.
    * filter (array) - **Required** limit the filter options to only the listed ids.
    * unassigned (boolean) - **Required** show unassigned taxonomy option (t/f).
    * defaults (array) - **Required** id defaults for the taxonomy.


##### Example(s)
```
"filters": [
    // data sources
    {
        "id": "mapfilter1",
        "label": "Data Sources",
        "tpl": "map/left-panel/filter/datasource/datasource.tpl.html",
        "enable": false
    },
    // implementing organizations
    {
        "id": "mapfilter",
        "label": "Implementers",
        "tpl": "map/left-panel/filter/organization/organization.tpl.html",
        "params": {
            "org_role_ids": "497",
            "type": "implementing"
        }
    },
    // taxonomy (Activity Status)
    {
        "id": "mapfilter8",
        "label": "Activity Status",
        "tpl": "map/left-panel/filter/taxonomy/taxonomy.tpl.html",
        "params": {
            "taxonomy_id": 18,
            "filter": [],
            "unassigned": true,
            "defaults": [794]
        }
    }
],

```
[&larrhk; Back to Element List](#list-of-elements)



## theme config states map tools map supplemental

#### Description

external additional resources that should be attached to a given activity.

##### Parameter(s)

* title (string) - **Required** name/title of the link.
* url (string) - **Required**  url to be linked.
* type (string) - **Required** name should be of material design icon
* classification_ids (array) - **Required** supplemental information links will be associated to activities with the following classification ids assigned
* keywords (object) - **Required** supplemental information will be associated to activities where any of the keywords appear in any of the listed fields
  * fields (array) - fields to search for keywords in.
  * keywords (array) - list of keywords.

##### Example(s)
```
 "supplemental": [
    {
        "title": "Seize the Moment",
        "url": "https://www.youtube.com/watch?v=eMgophNDQe8",
        "type": "videocam",
        "classification_ids": [2289, 2308, 2309, 2310, 2311, 2312, 2313, 2314, 2304, 2288, 2296, 2315, 2301, 2306, 2307],
        "keywords": {
            "fields": ["_title", "_description"],
            "keywords": ["policy", "seed", "seeds", "soil", "soils", "market", "markets", "finance", "storage", "capacity building"]
        }
    }
 ]

```
[&larrhk; Back to Element List](#list-of-elements)



## theme config states partnerlink

#### Description

The partnerlink section allows users to understand the connections between organizations working together and on related projects.

##### Parameter(s)

* route (string) - **Required** route of "partnerlink" module.
* authorization (string) - .  TODO not clear what this is.
* enable (boolean) - **Required** whether or not module is active.
* order (integer) - **Required** ordering for the left nav panel.
* navLabel (string) - **Required** label for the button on the nav panel.
* navIcon (string) - **Required** name of icon to be used on left nav panel.
* title (string) - **Required** title of module.
* subtitle (string) - **Required** subtitle of module.
* stateParamDefaults (object) - **Required** empty object to hold future params for the partnerlink module.
* tools (object) - **Required** defines the settings for the partnerlink modules including which filters, labels and colors are supported.
    * filters (array) - **Required** - see [filters](#theme-config-states-partnerlink-tools-filters).
    * grantee_not_reported_label (string) - label for partnerlink (sankey) elements in which the grantee is not reported.
    * partner_not_reported_label (string) - label for partnerlink (sankey) elements in which the partner is not reported.
    * funder_not_reported_label (string) - label for partnerlink (sankey) elements in which the funder is not reported.
    * aggregator (string) - **Required** label for partnerlink (sankey) elements in which the grantee is not reported.


##### Example(s)
```
{
    "route": "partnerlink",
    "authorization": "000000",
    "enable": true,
    "order": 4,
    "navLabel": "Partnerlink",
    "navIcon": "fa fa-retweet",
    "navURL": "assets/icon_handshake.svg",
    "title": "The Partnerlink Section",
    "subtitle": "The parternlink section is for exploring relationships between organizations.",
    "stateParamDefaults": {},
    "tools": {
        "filters": [],
            "color_range": ["#abbb3b", "#abbb3b"],
            "grantee_not_reported_label": "",
            "partner_not_reported_label": "Other Partners",
            "funder_not_reported_label": "",
            "aggregator": "a"
    }
}
```
[&larrhk; Back to Element List](#list-of-elements)



## theme config states partnerlink tools filters

#### Description

array of filters for partnerlink module.  Filters can be used to filter instance data in the UI.

##### Parameter(s)

* id (string) - **Required** unique id for the filter.
* label (string) - **Required** UI label name for the filter.
* tpl (string) - **Required** Location of html template for filter.
* open (boolean) - Whether or not the filter menu is open.
* params (object) - Listing of parameters for each filter.  Each filter type has its own parameters.
    data source
    * data_groups - Array of data sources.
        * label (string) - **Required** label for the data group.
        * dataGroupIds (string) - **Required** comma seperated list of data group ids.
        * active (boolean) - **Required** default active (t/f).
    organization - no additional parameters are required


##### Example(s)
```
"filters": [
    // data sources
    {
        "id": "plfilter1",
        "label": "Data Sources",
        "tpl": "pl/filter/datasource/datasource.tpl.html",
        "open": true,
        "params": {
            "data_groups": [
                {
                    "label": "RED&FS",
                    "data_group_ids": "2237",
                    "active": true
                }
            ]
        }
    },
    //organizations
    {
        "id": "plfilter2",
        "label": "Organization",
        "tpl": "pl/filter/organization/organization.tpl.html",
        "open": false
    }
],

```
[&larrhk; Back to Element List](#list-of-elements)



## theme config states me

#### Description

The me section is the application is the measurement and evaluation section of the application.

##### Parameter(s)

* route (string) - **Required** route of "me" module.
* authorization (string) - .  TODO not clear what this is.
* enable (boolean) - **Required** whether or not module is active.
* order (integer) - **Required** ordering for the left nav panel.
* navLabel (string) - **Required** label for the button on the nav panel.
* navIcon (string) - **Required** name of icon to be used on left nav panel.
* title (string) - **Required** title of module.
* subtitle (string) - **Required** subtitle of module.


##### Example(s)
```
{
    "route": "me",
    "authorization": "000000",
    "enable": false,
    "order": 2,
    "navLabel": "M&E",
    "navIcon": "fa fa-line-chart",
    "navURL": "assets/icon_analysis.svg",
    "title": "Monitoring & Evaluation",
    "subtitle": "The Monitoring & Evaluation section is for exploring results and tracking data related to project and program indicators and goals."
}
```
[&larrhk; Back to Element List](#list-of-elements)


## theme config states admin

#### Description

The admin section is the application stores the user list.

##### Parameter(s)

* route (string) - **Required** route of "admin" module.
* authorization (string) - .  TODO not clear what this is.
* enable (boolean) - **Required** whether or not module is active.
* order (integer) - **Required** ordering for the left nav panel.
* navLabel (string) - **Required** label for the button on the nav panel.
* navIcon (string) - **Required** name of icon to be used on left nav panel.
* title (string) - **Required** title of module.
* subtitle (string) - **Required** subtitle of module.


##### Example(s)
```
{
    "route": "admin",
    "authorization": "100000",
    "enable": true,
    "order": 6,
    "navLabel": "Admin",
    "navIcon": "fa fa-key",
    "navURL": "assets/icon_key.svg",
    "title": "Admin",
    "subtitle": "User List"
}
```
[&larrhk; Back to Element List](#list-of-elements)
