# PMT Viewer Configuration Documentation

Many aspects of the PMT are configurable. This document serves to be a comprehensive
documentation of those configurable elements. 

## List of Elements

* [theme](#theme)

  * [pmt](#themepmt)

    * [boundaryPoints](#themepmtboundaryPoints)
      
      * [examlpe](#themepmtboundaryPoints)
        
        * [examlpe](#themepmtboundaryPoints)
          
          * [examlpe](#themepmtboundaryPoints)
            
            * [examlpe](#themepmtboundaryPoints)

              * [examlpe](#themepmtboundaryPoints)


* * * * *

## theme

#### Description

A theme is.... A theme has a single parameter called "constants" which,
holds the angaularjs constants variables for the instances. All instances
have the same constants variables.

[&larrhk; Back to Elememt List](#list-of-elements)

## theme.pmt

#### Description

The pmt parameter contains all the information to connect to the PMT database,
through the PMT API. blah. blah. blah

##### Parameter(s) 

* env (string) - **Required** the environment setting for the target environment. References both the id and api parameter values.
* id (object) - **Required** PMT API resource ids for each available environment. Ids are assigned by the API.
* api (object) - **Required** PMT API urls for each available environment.
* autocompleteText (path) - internal appliation path to auto complete text (not currently in use we should remove.).
* boundaryPoints (object) - **Required** see [boundaryPoints](#theme.pmt.boundaryPoints) for details.

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


## theme.pmt.boundaryPoints

#### Description

An array of boundary objects containing information for each administrative level,
in which PMT locations are associated to for presentation on the map.

##### Parameter(s) 

Array of objects containing the following parameters:

* alias (string) - **Required** unqiue name for the administrative boundary layer.
* file (path) - **Required** internal appliation path to geojson file containing centroid points of boundary layer.
* zoomMin (integer) - **Required** minimum leaflet zoom level to present layer. zoomMin and zoomMax levels should not overlap for a single boundary type (i.e. gaul).
* zoomMax (integer) - **Required** maximum leaflet zoom level to present layer. zoomMin and zoomMax levels should not overlap for a single boundary type (i.e. gaul).
...

[&larrhk; Back to Elememt List](#list-of-elements)

