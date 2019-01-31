/**
 * This file/module contains all configuration for the themes.
 */
module.exports = {
    /**
     * The `build_dir` folder is where our projects are compiled during
     * development and the `compile_dir` folder is where our app resides once it's
     * completely built.
     */
    ngconstant: {
        // Options for all themes
        "options": {
            // name of the angular.module
            "name": "config",
            // path & file name of generated file on build
            "dest": "src/app/config.js",
            // all objects will be applicable to ALL PMT themes (global settings)
            "constants": {
                "global": {
                    // the application's github repo
                    "gitrepo": "https://github.com/spatialdev/PMT-Viewer",
                    // the applications's woofoo feedback form
                    "woofoo": "https://investmentmapping.wufoo.com/forms/z1jg22qn1wq79x3/",
                    // the applications's user guide
                    "userGuide": "http://v10.investmentmapping.org/userguide/user-guide.html",
                    // version history page
                    "versionHistory": "http://v10.investmentmapping.org/version_history.html",
                    // current version
                    "version": "3.10.9",
                    // fonts used by all PMT themes
                    "fonts": [
                        "assets/font-awesome.min.css",
                        "http://fonts.googleapis.com/css?family=Raleway",
                        "https://fonts.googleapis.com/icon?family=Material+Icons"
                    ],
                    // list of all available basemaps
                    "basemaps": [
                        {
                            "url": "http://{s}.tile.osm.org/{z}/{x}/{y}.png",
                            "name": "Standard OpenStreetMap",
                            "alias": "standardopenstreetmap",
                            "attribution": "&copy; <a href='http://osm.org/copyright'>OpenStreetMap contributors</a>"
                        },
                        {
                            "url": "http://{s}.tile2.opencyclemap.org/transport/{z}/{x}/{y}.png",
                            "name": "Transport OpenStreetMap",
                            "alias": "transportopenstreetmap",
                            "attribution": "Maps &copy; <a href='http://www.thunderforest.com/'>Thunderforest</a>, Data &copy; <a href='http://osm.org/copyright'>OpenStreetMap contributors</a>"
                        },
                        {
                            "url": "https://{s}.tiles.mapbox.com/v4/spatialdev.map-hozgh18d/{z}/{x}/{y}.png?access_token=pk.eyJ1Ijoic3BhdGlhbGRldiIsImEiOiJKRGYyYUlRIn0.PuYcbpuC38WO6D1r7xdMdA#3/0.00/0.00",
                            "name": "Satellite Basemap",
                            "alias": "satellite",
                            "attribution": "<a href='https://www.mapbox.com/about/maps/' target='_blank'>&copy; Mapbox</a> <a href='http://www.openstreetmap.org/about/' target='_blank'>&copy; OpenStreetMap</a> <a href='https://www.digitalglobe.com/' target='_blank'>&copy; DigitalGlobe</a>"
                        },
                        {
                            "url": "http://services.arcgisonline.com/ArcGIS/rest/services/NatGeo_World_Map/MapServer/tile/{z}/{y}/{x}",
                            "name": "National Geographic",
                            "alias": "nationalgeographic",
                            "attribution": "Tiles &copy; Esri &mdash; National Geographic, Esri, DeLorme, NAVTEQ, UNEP-WCMC, USGS, NASA, ESA, METI, NRCAN, GEBCO, NOAA, iPC"
                        },
                        {
                            "url": "http://services.arcgisonline.com/ArcGIS/rest/services/Ocean/World_Ocean_Base/MapServer/tile/{z}/{y}/{x}",
                            "name": "Ocean Bathymetric",
                            "alias": "oceanbathymetric",
                            "attribution": "Tiles &copy; Esri &mdash; Sources: GEBCO, NOAA, CHS, OSU, UNH, CSUMB, National Geographic, DeLorme, NAVTEQ, and Esri"
                        },
                        {
                            "url": "http://services.arcgisonline.com/ArcGIS/rest/services/World_Topo_Map/MapServer/tile/{z}/{y}/{x}",
                            "name": "Esri Topographic",
                            "alias": "esritopographic",
                            "attribution": "Tiles &copy; Esri &mdash; Esri, DeLorme, NAVTEQ, TomTom, Intermap, iPC, USGS, FAO, NPS, NRCAN, GeoBase, Kadaster NL, Ordnance Survey, Esri Japan, METI, Esri China (Hong Kong), and the GIS User Community"
                        },
                        {
                            "url": "http://server.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Light_Gray_Base/MapServer/tile/{z}/{y}/{x}",
                            "name": "Esri Light Gray",
                            "alias": "lightgray",
                            "attribution": "Tiles &copy; Esri &mdash; Esri, DeLorme, NAVTEQ"
                        }
                    ],
                    // mapbox gl styles
                    "styles": [
                        {
                            "url": "mapbox://styles/spatialdev/ciksn1d1w00509flxk5rvbs8h",
                            "name": "Me Custom Main",
                            "alias": "memain"
                        },
                        {
                            "url": "mapbox://styles/mapbox/basic-v8",
                            "name": "Basic",
                            "alias": "basic"
                        },
                        {
                            "url": "mapbox://styles/mapbox/bright-v8",
                            "name": "Bright",
                            "alias": "bright"
                        },
                        {
                            "url": "mapbox://styles/mapbox/light-v8",
                            "name": "Light",
                            "alias": "light"
                        },
                        {
                            "url": "mapbox://styles/mapbox/streets-v8",
                            "name": "Streets",
                            "alias": "streets"
                        },
                        {

                            "url": "mapbox://styles/mapbox/dark-v8",
                            "name": "Dark",
                            "alias": "dark"
                        }
                    ],
                    "mapbox-gl-accessToken": "pk.eyJ1Ijoic3BhdGlhbGRldiIsImEiOiJKRGYyYUlRIn0.PuYcbpuC38WO6D1r7xdMdA"
                }
            }
        },
        // theme: spatialdev
        "spatialdev": {
            "constants": {
                // source pmt database
                "pmt": {
                    // Environment setting for the API
                    "env": "stage",
                    // API PMT Resource ID
                    // Must be assigned by the API
                    "id": {
                        "production": 1,
                        "stage": 2,
                        "demo": 3,
                        "local": 4,
                        "local1": 5
                    },
                    // PMT Instance ID (must match database)
                    "instance": 3,
                    // API urls for each environment setting
                    "api": {
                        "production": "http://api.v10.investmentmapping.org:8080/api/",
                        "stage": "http://api.v10.investmentmapping.org:8082/pmt-api-stage/",
                        "demo": "http://api.v10.investmentmapping.org:8083/pmt-api-demo/",
                        "local": "http://localhost:8087/api/",
                        "local1": "http://localhost:8087/api/"
                    },
                    //search autocomplete results
                    "autocompleteText": {
                        "file": "assets/pmt_autocomplete_results.json"
                    },
                    // boundary points are used to cluster PMT locations
                    // each theme must specify boundaryPoints usage for each PMT layer
                    "boundaryPoints": {
                        "gadm": [
                            {
                                "alias": "continent",
                                "file": "assets/continent.geojson",
                                "zoomMin": 0,
                                "zoomMax": 3,
                                "boundaryId": 8,
                                "active": false
                            },
                            {
                                "alias": "gadm0",
                                "file": "assets/gadm0.geojson",
                                "zoomMin": 4,
                                "zoomMax": 6,
                                "boundaryId": 15,
                                "active": false,
                                // optionally boundary points may have a boundary layer associated
                                // when present the boundary layer will be show at the same zoom levels
                                // as specified by the point layer
                                "boundary": {
                                    "alias": "boundary0",
                                    "label": "GADM Level 0",
                                    "url": "https://s3.amazonaws.com/v10.investmentmapping.org/vector-tiles/gadm0/{z}/{x}/{y}.pbf",
                                    "legend": "",
                                    "opacity": .80,
                                    "type": "vectortile",
                                    "active": false,
                                    "style": {
                                        "color": "rgba(0,128,0,0)",
                                        "outline": {
                                            "color": "rgb(0,128,0)",
                                            "size": 2
                                        }
                                    }
                                },
                                // when a boundary layer is present a select layer should also be present to allow
                                // highlighing when point clusters are selected within the bounadary layer feature
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
                                    // if filter is specified so must filterParam be specified
                                    // listing of values to show, only the listed values will be displayed
                                    "filter": [],
                                    // the field the filter is targeting on the layer
                                    "filterParam": "id"
                                }
                            },
                            {
                                "alias": "gadm1",
                                "file": "assets/gadm1.geojson",
                                "zoomMin": 7,
                                "zoomMax": 8,
                                "boundaryId": 16,
                                "active": false,
                                // optionally boundary points may have a boundary layer associated
                                // when present the boundary layer will be show at the same zoom levels
                                // as specified by the point layer
                                "boundary": {
                                    "alias": "boundary1",
                                    "label": "GADM Level 1",
                                    "url": "https://s3.amazonaws.com/v10.investmentmapping.org/vector-tiles/gadm1/{z}/{x}/{y}.pbf",
                                    "legend": "",
                                    "opacity": .80,
                                    "type": "vectortile",
                                    "active": false,
                                    "style": {
                                        "color": "rgba(208,77,56,0)",
                                        "outline": {
                                            "color": "rgb(208,77,56)",
                                            "size": 2
                                        }
                                    }
                                },
                                // when a boundary layer is present a select layer should also be present to allow
                                // highlighing when point clusters are selected within the bounadary layer feature
                                "select": {
                                    "alias": "select1",
                                    "label": "GADM Level 1",
                                    "url": "https://s3.amazonaws.com/v10.investmentmapping.org/vector-tiles/gadm1/{z}/{x}/{y}.pbf",
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
                                    // if filter is specified so must filterParam be specified
                                    // listing of values to show, only the listed values will be displayed
                                    "filter": [],
                                    // the field the filter is targeting on the layer
                                    "filterParam": "id"
                                }
                            },
                            {
                                "alias": "gadm2",
                                "file": "assets/gadm2.geojson",
                                "zoomMin": 9,
                                "zoomMax": 50,
                                "boundaryId": 17,
                                "active": false,
                                // optionally boundary points may have a boundary layer associated
                                // when present the boundary layer will be show at the same zoom levels
                                // as specified by the point layer
                                "boundary": {
                                    "alias": "boundary2",
                                    "label": "GADM Level 2",
                                    "url": "https://s3.amazonaws.com/v10.investmentmapping.org/vector-tiles/gadm2/{z}/{x}/{y}.pbf",
                                    "legend": "",
                                    "opacity": .80,
                                    "type": "vectortile",
                                    "active": false,
                                    "style": {
                                        "color": "rgba(51,122,183,0)",
                                        "outline": {
                                            "color": "rgb(51,122,183)",
                                            "size": 2
                                        }
                                    }
                                },
                                // when a boundary layer is present a select layer should also be present to allow
                                // highlighing when point clusters are selected within the bounadary layer feature
                                "select": {
                                    "alias": "select2",
                                    "label": "GADM Level 2",
                                    "url": "https://s3.amazonaws.com/v10.investmentmapping.org/vector-tiles/gadm2/{z}/{x}/{y}.pbf",
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
                                    // if filter is specified so must filterParam be specified
                                    // listing of values to show, only the listed values will be displayed
                                    "filter": [],
                                    // the field the filter is targeting on the layer
                                    "filterParam": "id"
                                }
                            }
                        ]
                    }
                },
                // font libraries
                "fonts": [
                    "https://fonts.googleapis.com/css?family=Oswald"
                ],
                // application configuration settings
                "config": {
                    // application instance URL
                    "url": "http://v10.investmentmapping.org/spatialdev",
                    "theme": {
                        "alias": "spatialdev",
                        "name": "Portfolio Mapping Tool (PMT)",
                        "url": "http://www.spatialdev.com",
                        // height must be 45px and width must be 210px
                        "topbanner": "assets/topbanner.svg",
                        // height must be 35px and width must be 185px
                        "bottombanner": "https://s3.amazonaws.com/v10.investmentmapping.org/themes/spatialdev/bottombanner.png"
                    },
                    "links": {
                        "socialmedia": {
                            "linkedin": "http://linkedin.com/spatial-development-international",
                            "github": "http://github.com/spatialdev",
                            "twitter": "http://www.twitter.com/spatialdev",
                            "facebook": "https://www.facebook.com/spatialdev"
                        }
                    },
                    "meta": {
                        "title": "PMT Viewer",
                        "author": "SpatialDev",
                        "description": "The PMT Viewer is a web application for viewing information supported by the IATI (International Aid Transparency Initiative) Standards. The PMT Viewer provides tools for visualizing and comparing aid data, stored within the PMT Database.",
                        "url": "http://spatialdev.github.io/PMT-Viewer",
                        "image": "https://s3.amazonaws.com/v10.investmentmapping.org/themes/spatialdev/spatialdev_logo.png",
                        "twitterHandle": "@spatialdev"
                    },
                    "login": {
                        "public": true,
                        "username": "public",
                        "password": "R3ad0nlyAcc3ss!",
                        // wiil provide a login when public is true
                        "allowLogin": true
                    },
                    "states": [
                        // home page
                        {
                            "route": "home",
                            "authorization": "000000",
                            "enable": false,
                            "order": 0,
                            "navLabel": "Home",
                            "navIcon": "fa fa-home",
                            "title": "The Home Section",
                            "subtitle": "The home section is the application landing page."
                        },
                        // locations page
                        {
                            "route": "locations",
                            "authorization": "000000",
                            "enable": true,
                            "order": 1,
                            "navLabel": "Summaries",
                            "navIcon": "fas fa-chart-bar",
                            "navURL": null,
                            "title": "The Location Section",
                            "subtitle": "The location section is for exploring data from a location first perspective.",
                            "mapSummary": false,
                            "stateParamDefaults": {
                                "lat": 15.5,
                                "lng": 30.5,
                                "zoom": 3,
                                "area": "world",
                                "basemap": "lightgray",
                                "layers": "gadm0"
                            },
                            // tool settings
                            "tools": {
                                // interactive map settings
                                "map": {
                                    "minZoom": 2,
                                    "maxZoom": 19,
                                    // pmt layers
                                    "layers": [],
                                    // contextual layers
                                    "contextual": [],
                                    // supporting layers
                                    "supportingLayers": [
                                        {
                                            "alias": "gadm0",
                                            "label": "GADM Level 0",
                                            "url": "https://s3.amazonaws.com/v10.investmentmapping.org/vector-tiles/gadm0/{z}/{x}/{y}.pbf",
                                            "legend": "",
                                            "opacity": .80,
                                            "type": "vectortile",
                                            "active": false,
                                            // inform the tool which area (options: world, country, region, select) this layer supports
                                            "area": "national",
                                            // the name of the boundary spatial table the tiles where derived from in PMT
                                            "spatialTable": "gadm0",
                                            // the boundary group name (allows boundaries to be grouped for toggling)
                                            "boundaryGroup": "gadm",
                                            // the id of the boundary record in PMT for this boundary
                                            "boundary_id": 15,
                                            // layer style
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
                                        },
                                        {
                                            "alias": "gadm1",
                                            "label": "GADM Level 1",
                                            "url": "https://s3.amazonaws.com/v10.investmentmapping.org/vector-tiles/gadm1/{z}/{x}/{y}.pbf",
                                            "legend": "",
                                            "opacity": .80,
                                            "type": "vectortile",
                                            "active": false,
                                            // inform the tool which area (options: world, national, regional, select) this layer supports
                                            "area": "regional",
                                            // the name of the boundary spatial table the tiles where derived from in PMT
                                            "spatialTable": "gadm1",
                                            // the boundary group name (allows boundaries to be grouped for toggling)
                                            "boundaryGroup": "gadm",
                                            // the id of the boundary record in PMT for this boundary
                                            "boundary_id": 16,
                                            // layer style
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
                                        },
                                        {
                                            "alias": "gadm1select",
                                            "label": "GADM Level 1",
                                            "url": "https://s3.amazonaws.com/v10.investmentmapping.org/vector-tiles/gadm1/{z}/{x}/{y}.pbf",
                                            "legend": "",
                                            "opacity": .80,
                                            "type": "vectortile",
                                            "active": false,
                                            // inform the tool which area (options: world, national, regional, select) this layer supports
                                            "area": "select",
                                            // the name of the boundary spatial table the tiles where derived from in PMT
                                            "spatialTable": "gadm1",
                                            // the boundary group name (allows boundaries to be grouped for toggling)
                                            "boundaryGroup": "gadm",
                                            // the id of the boundary record in PMT for this boundary
                                            "boundary_id": 16,
                                            // layer style
                                            "style": {
                                                "color": "rgba(93,191,228,0.3)",
                                                "outline": {
                                                    "color": "rgba(93,191,228,1)",
                                                    "size": 1
                                                },
                                                "selected": {
                                                    "color": "rgba(93,191,228,0.3)",
                                                    "outline": {
                                                        "color": "rgba(93,191,228,1)",
                                                        "size": 1
                                                    }
                                                }
                                            }
                                        }
                                    ],
                                    // the filter settings
                                    "filters": [
                                        // data sources
                                        {
                                            "id": "locsfilter1",
                                            "label": "Data Sources",
                                            "tpl": "locs/filter/datasource/datasource.tpl.html",
                                            // filter is enabled/visable (t/f)
                                            "enable": true,
                                            // filter is active (open by default: t/f)
                                            "active": true,
                                            // filter type
                                            // options: datasource, date, taxonomy
                                            "type": "datasource",
                                            "params": {
                                                "dataSources": [
                                                    {
                                                        // label for application
                                                        "label": "African Development Bank",
                                                        // data group id(s)
                                                        "dataGroupIds": "2209",
                                                        // default active (t/f)
                                                        "active": true
                                                    },
                                                    {
                                                        // label for application
                                                        "label": "World Bank",
                                                        // data group id(s)
                                                        "dataGroupIds": "2210",
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
                                                // limit the filter to only in-use classifications (overrides filter parameter)
                                                "inuse": true,
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
                                            // filter is active (open by default: t/f)
                                            "active": false,
                                            // filter type
                                            // options: datasource, date, taxonomy
                                            "type": "date",
                                            "params": {}
                                        }
                                    ],
                                    // countries supported
                                    // country: name must match supporting layer properties exactly
                                    // ids: id must match the supporting layer properites exactly
                                    "countries": [
                                        {
                                            "_name": "Burkina Faso",
                                            "id": "38"
                                        },
                                        {
                                            "_name": "Mali",
                                            "id": "138"
                                        },
                                        {
                                            "_name": "Ghana",
                                            "id": "87"
                                        },
                                        {
                                            "_name": "Nigeria",
                                            "id": "163"
                                        },
                                        {
                                            "_name": "Tanzania",
                                            "id": "227"
                                        },
                                        {
                                            "_name": "Uganda",
                                            "id": "239"
                                        },
                                        {
                                            "_name": "Ethiopia",
                                            "id": "74"
                                        },
                                        {
                                            "_name": "India",
                                            "id": "105"
                                        }
                                    ],
                                    // default boundary group
                                    "boundaryGroup": "gadm",
                                    // widgets are displyed in the area configured in the order in which they appear
                                    // in the widgets array
                                    "widgets": [
                                        // overview widget - world
                                        {
                                            "id": "widget0",
                                            "title": "At a glance",
                                            "tpl": "locs/widget/overview/overview.tpl.html",
                                            // widget display area (options: world, national, regional)
                                            "area": "world",
                                            // row number widget is placed in
                                            "row": 0,
                                            // column span (1-12)
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
                                                                "description": "Number of countries where activities are taking place"
                                                            },
                                                            {
                                                                "statistic": "activity_count",
                                                                "title": "Total Activities",
                                                                "description": "Number of activities world wide"
                                                            },
                                                            {
                                                                "statistic": "total_investment",
                                                                "title": "Global Investment",
                                                                "description": "Global investments in USD"
                                                            },
                                                            {
                                                                "statistic": "implmenting_count",
                                                                "title": "Implmenting Partners",
                                                                "description": "Total number of organizations implementing activities world wide"
                                                            }
                                                        ]
                                                    }
                                                ]
                                            }
                                        },
                                        // summarization widget for investments
                                        // by top (x) funders - national
                                        {
                                            "id": "widget1",
                                            "title": "Top Funding Partners by Investment Amount",
                                            "subtitle": "Top 5 Funding Partners",
                                            "footnote": "Active Projects as of 1/1/2016",
                                            "tpl": "locs/widget/top-dollar/top-dollar.tpl.html",
                                            // widget display area (options: world, national, regional)
                                            "area": "national",
                                            // row number widget is placed in
                                            "row": 0,
                                            // column span (1-12)
                                            "colspan": 8,
                                            //info passed to download widget
                                            "exports": [
                                                { widget_id: "widget1", title: 'Top Funding Partners by Investment Amount Graph (Image)' }
                                            ],
                                            "params": {
                                                // number of top organizations to show
                                                "top": 5,
                                                // organization role id
                                                "org_role_id": 496,
                                                // restrict data by a date range
                                                "date": {
                                                    "start": null,
                                                    "end": null
                                                },
                                                // display full list option/link
                                                "full_list": false
                                            }
                                        },
                                        // summarization widget for total activities
                                        // by a taxonomy - national
                                        {
                                            "id": "widget2",
                                            "title": "Share of Top Initiatives by Investment Amount",
                                            "tpl": "locs/widget/tax-summary/tax-summary.tpl.html",
                                            // widget display area (options: world, national, regional)
                                            "area": "national",
                                            // row number widget is placed in
                                            "row": 0,
                                            // column span (1-12)
                                            "colspan": 4,
                                            // pie pieces color range, ensure there are enough colors in the range
                                            // to account for all possible pieces
                                            "colors": ["#C13838", "#D35731", "#B0693D", "#586D5B", "#458080", "#75A4AE", "#98AFAA", "#AEA176", "#BDA151", "#C7B03B,#CA4835", "#DC672E", "#846B4C", "#2D6F6A", "#5D9297", "#8DB6C5", "#A3A890", "#B99A5C", "#C2A946", "#CCB830"],
                                            //info passed to download widget
                                            "exports": [
                                                { widget_id: "widget2", title: 'Share of Top Initiatives by Investment Amount Graph (Image)' }
                                            ],
                                            "params": {
                                                // the taxonomy to summarize by
                                                "taxonomy_id": 23
                                            }
                                        },
                                        // partner pivot widget - national
                                        {
                                            "id": "widget3",
                                            "title": "Matrix of Agriculture Investments by",
                                            "tpl": "locs/widget/pivot/pivot.tpl.html",
                                            // widget display area (options: world, national, regional)
                                            "area": "national",
                                            // row number widget is placed in
                                            "row": 1,
                                            // column span (1-12)
                                            "colspan": 12,
                                            "params": {
                                                // taxonomy id for row/y-axis of pivot
                                                "row_taxonomy_id": 22,
                                                // taxonomy id for column/x-axis of pivot
                                                "column_taxonomy_id": 23,
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
                                                        //whether or not to pivot on locations
                                                        "pivot_on_locations": false,
                                                        // taxonomy id for row/y-axis of pivot
                                                        "row_taxonomy_id": 22,
                                                        "label": "Investment Initiative"
                                                    },
                                                    {
                                                        //whether or not to pivot on locations
                                                        "pivot_on_locations": false,
                                                        // taxonomy id for row/y-axis of pivot
                                                        "row_taxonomy_id": 23,
                                                        "label": "Commodities"
                                                    }
                                                ],
                                                "unspecified_label": "Cross Cutting",
                                                "show_empty_columns": false,
                                                "show_empty_rows": false
                                            }
                                        },
                                        // summarization widget for total activities
                                        // by a taxonomy (sector) - national
                                        {
                                            "id": "widget4",
                                            "title": "Activity Count by Sector (2014)",
                                            "subtitle": "",
                                            "footnote": "",
                                            "tpl": "locs/widget/top-taxonomy/top-taxonomy.tpl.html",
                                            // widget display area (options: world, national, regional)
                                            "area": "national",
                                            // row number widget is placed in
                                            "row": 2,
                                            // column span (1-12)
                                            "colspan": 6,
                                            // color range, ensure there are enough colors in the range
                                            // to account for all possible pieces, last color should be grey for 'Other'
                                            "colors": ["#8ca3d3", "#b8995f", "#2e6e6b", "#cf6e34", "#ad2542", "#727273"],
                                            //info passed to download widget
                                            "exports": [
                                                { widget_id: "widget4", title: 'Activity Count by Sector (2014)' }
                                            ],
                                            "params": {
                                                // the taxonomy to summarize by
                                                "taxonomy_id": 15,
                                                // number of top classifications to show
                                                "top": 5,
                                                // whether to show "Other" category
                                                "show_other": true,
                                                // label for "Other" category
                                                "other_label": "Other"
                                            }
                                        },
                                        // summarization widget for total activities
                                        // by a taxonomy (crop) - national
                                        {
                                            "id": "widget5",
                                            "title": "Activity Count by Crop (2014)",
                                            "subtitle": "",
                                            "footnote": "",
                                            "tpl": "locs/widget/top-taxonomy/top-taxonomy.tpl.html",
                                            // widget display area (options: world, national, regional)
                                            "area": "national",
                                            // row number widget is placed in
                                            "row": 2,
                                            // column span (1-12)
                                            "colspan": 6,
                                            // color range, ensure there are enough colors in the range
                                            // to account for all possible pieces, last color should be grey for "Other"
                                            "colors": ["#8ca3d3", "#b8995f", "#2e6e6b", "#cf6e34", "#ad2542", "#727273"],
                                            //info passed to download widget
                                            "exports": [
                                                { widget_id: "widget5", title: 'Activity Count by Crop (2014)' }
                                            ],
                                            "params": {
                                                // the taxonomy to summarize by
                                                "taxonomy_id": 69,
                                                // number of top classifications to show
                                                "top": 5,
                                                //whether to show "Other" category
                                                "show_other": true,
                                                //label for "Other" category
                                                "other_label": "Other"
                                            }
                                        },
                                        // summarization widget for investments
                                        // by top (x) funders - regional
                                        {
                                            "id": "widget101",
                                            "title": "Activity Count by Implementing Partner",
                                            "subtitle": "Top Implementing Partners",
                                            "footnote": "",
                                            "tpl": "locs/widget/top-dollar/top-dollar.tpl.html",
                                            // widget display area (options: world, national, regional)
                                            "area": "regional",
                                            // row number widget is placed in
                                            "row": 0,
                                            // column span (1-12)
                                            "colspan": 8,
                                            //info passed to download widget
                                            "exports": [
                                                { widget_id: "widget101", title: 'Activity Count by Implementing Partner' }
                                            ],
                                            "params": {
                                                // number of top organizations to show
                                                "top": 5,
                                                // organization role id
                                                "org_role_id": 497,
                                                // restrict data by a date range
                                                "date": {
                                                    "start": null,
                                                    "end": null
                                                },
                                                // display full list option/link
                                                "full_list": false
                                            }
                                        },
                                        // summarization widget for total activities
                                        // by a taxonomy - regional
                                        {
                                            "id": "widget102",
                                            "title": "Share of Total Current Activity Count by Initiative",
                                            "tpl": "locs/widget/tax-summary/tax-summary.tpl.html",
                                            // widget display area (options: world, national, regional)
                                            "area": "regional",
                                            // row number widget is placed in
                                            "row": 0,
                                            // column span (1-12)
                                            "colspan": 4,
                                            // pie pieces color range, ensure there are enough colors in the range
                                            // to account for all possible pieces
                                            "colors": ["#C13838", "#D35731", "#B0693D", "#586D5B", "#458080", "#75A4AE", "#98AFAA", "#AEA176", "#BDA151", "#C7B03B,#CA4835", "#DC672E", "#846B4C", "#2D6F6A", "#5D9297", "#8DB6C5", "#A3A890", "#B99A5C", "#C2A946", "#CCB830"],
                                            //info passed to download widget
                                            "exports": [
                                                { widget_id: "widget102", title: 'Share of Total Current Activity Count by Initiative' }
                                            ],
                                            "params": {
                                                // the taxonomy to summarize by
                                                "taxonomy_id": 23
                                            }
                                        },
                                        // partner pivot widget - regional
                                        {
                                            "id": "widget103",
                                            "title": "Matrix of Agriculture Activities by Implementing Partner",
                                            "tpl": "locs/widget/pivot/pivot.tpl.html",
                                            // widget display area (options: world, national, regional)
                                            "area": "regional",
                                            // row number widget is placed in
                                            "row": 1,
                                            // column span (1-12)
                                            "colspan": 12,
                                            //info passed to download widget
                                            "exports": [
                                                { widget_id: "widget103", title: 'Matrix of Agriculture Activities by Implementing Partner' }
                                            ],
                                            "params": {
                                                // the organization role for organizations (cells of pivot)
                                                "org_role_id": 497,
                                                "partner_filters": [],
                                                "axis_options": [
                                                    {
                                                        //whether or not to pivot on locations
                                                        "pivot_on_locations": false,
                                                        // taxonomy id for row/y-axis of pivot
                                                        "row_taxonomy_id": 22,
                                                        "label": "Investment Initiative"
                                                    },
                                                    {
                                                        //whether or not to pivot on locations
                                                        "pivot_on_locations": false,
                                                        // taxonomy id for row/y-axis of pivot
                                                        "row_taxonomy_id": 23,
                                                        "label": "Commodities"
                                                    }
                                                ],
                                                "unspecified_label": "Cross Cutting",
                                                "show_empty_columns": true,
                                                "show_empty_rows": true
                                            }
                                        },
                                        // summarization widget for total activities
                                        // by a taxonomy (sector) - national
                                        {
                                            "id": "widget104",
                                            "title": "Activity Count by Sector (2014)",
                                            "subtitle": "",
                                            "footnote": "",
                                            "tpl": "locs/widget/top-taxonomy/top-taxonomy.tpl.html",
                                            // widget display area (options: world, national, regional)
                                            "area": "regional",
                                            // row number widget is placed in
                                            "row": 2,
                                            // column span (1-12)
                                            "colspan": 6,
                                            // color range, ensure there are enough colors in the range
                                            // to account for all possible pieces, last color should be grey for "Other"
                                            "colors": ["#8ca3d3", "#b8995f", "#2e6e6b", "#cf6e34", "#ad2542", "#727273"],
                                            //info passed to download widget
                                            "exports": [
                                                { widget_id: "widget104", title: 'Activity Count by Sector (2014)' }
                                            ],
                                            "params": {
                                                // the taxonomy to summarize by
                                                "taxonomy_id": 15,
                                                // number of top classifications to show
                                                "top": 5,
                                                //whether to show "Other" category
                                                "show_other": true,
                                                //label for "Other" category
                                                "other_label": "Other"
                                            }
                                        },
                                        // summarization widget for total activities
                                        // by a taxonomy (crop) - national
                                        {
                                            "id": "widget105",
                                            "title": "Activity Count by Crop (2014)",
                                            "subtitle": "",
                                            "footnote": "",
                                            "tpl": "locs/widget/top-taxonomy/top-taxonomy.tpl.html",
                                            // widget display area (options: world, national, regional)
                                            "area": "regional",
                                            // row number widget is placed in
                                            "row": 2,
                                            // column span (1-12)
                                            "colspan": 6,
                                            // color range, ensure there are enough colors in the range
                                            // to account for all possible pieces, last color should be grey for "Other"
                                            "colors": ["#8ca3d3", "#b8995f", "#2e6e6b", "#cf6e34", "#ad2542", "#727273"],
                                            //info passed to download widget
                                            "exports": [
                                                { widget_id: "widget105", title: 'Activity Count by Crop (2014)' }
                                            ],
                                            "params": {
                                                // the taxonomy to summarize by
                                                "taxonomy_id": 69,
                                                // number of top classifications to show
                                                "top": 5,
                                                //whether to show "Other" category
                                                "show_other": true,
                                                //label for "Other" category
                                                "other_label": "Other"
                                            }
                                        }
                                    ],
                                    "params": {
                                        //investment data
                                        "investment_label": "Total Active Agricultural Investment",
                                        "start_date": "1970",
                                        "end_date": "2024"
                                    }
                                }
                            }
                        },
                        // activities page
                        {
                            "route": "activities",
                            "authorization": "000000",
                            "enable": true,
                            "order": 2,
                            "navLabel": "Activities",
                            "navIcon": "fa fa-list-ul",
                            "navURL": null,
                            "title": "The Activity Section",
                            "subtitle": "The activity section is for exploring data from a activity first perspective.",
                            "stateParamDefaults": {
                                "lat": 35.068359,
                                "lng": -6.031311,
                                "zoom": 5,
                                "basemap": "standardopenstreetmap",
                                "layers": ""
                            },
                            // tool settings
                            "tools": {
                                // interactive map settings
                                "map": {
                                    "minZoom": 2,
                                    "maxZoom": 19,
                                    "layers": [],
                                    // contextual layers
                                    "contextual": [],
                                    // supporting layers
                                    "supportingLayers": [],
                                    // the filter settings
                                    "filters": [
                                        // data sources
                                        {
                                            "id": "actsfilter1",
                                            "label": "Data Sources",
                                            "tpl": "acts/filter/datasource/datasource.tpl.html",
                                            // filter is enabled/visable (t/f)
                                            "enable": true,
                                            // filter is active (open by default: t/f)
                                            "active": true,
                                            // filter type
                                            // options: datasource, organization, taxonomy, geographic
                                            "type": "datasource",
                                            "params": {
                                                "dataSources": [
                                                    {
                                                        // label for application
                                                        "label": "African Development Bank",
                                                        // data group id(s)
                                                        "dataGroupIds": "2209",
                                                        // default active (t/f)
                                                        "active": false
                                                    },
                                                    {
                                                        // label for application
                                                        "label": "World Bank",
                                                        // data group id(s)
                                                        "dataGroupIds": "2210",
                                                        // default active (t/f)
                                                        "active": true
                                                    }
                                                ]
                                            },
                                            //optional is a child taxonomy
                                            "isChild": false
                                        },
                                        // funding organizations
                                        {
                                            "id": "actsfilter2",
                                            "label": "Funders",
                                            "tpl": "acts/filter/organization/organization.tpl.html",
                                            // filter is active (open by default: t/f)
                                            "active": false,
                                            // filter type
                                            // options: datasource, organization, taxonomy, geographic
                                            "type": "organization",
                                            "params": {
                                                // the filter for organization role to restrict data to
                                                "org_role_ids": "496",
                                                // filter type (options: implementing, funding, all)
                                                "type": "funding"
                                            },
                                            //optional is a child taxonomy
                                            "isChild": false
                                        },
                                        // implementing organizations
                                        {
                                            "id": "actsfilter3",
                                            "label": "Implementers",
                                            "tpl": "acts/filter/organization/organization.tpl.html",
                                            // filter is active (open by default: t/f)
                                            "active": false,
                                            // filter type
                                            // options: datasource, organization, taxonomy, geographic
                                            "type": "organization",
                                            "params": {
                                                // the filter for organization role to restrict data to
                                                "org_role_ids": "497",
                                                // filter type (options: implementing, funding, all)
                                                "type": "implementing"
                                            },
                                            //optional is a child taxonomy
                                            "isChild": false
                                        },
                                        // taxonomy (Sector)
                                        {
                                            "id": "actsfilter5",
                                            "label": "Sector",
                                            "tpl": "acts/filter/taxonomy/taxonomy.tpl.html",
                                            // filter is active (open by default: t/f)
                                            "active": false,
                                            // filter type
                                            // options: datasource, organization, taxonomy, geographic
                                            "type": "taxonomy",
                                            "params": {
                                                "taxonomy_id": 15,
                                                // limit the filter options to only the listed
                                                "filter": [],
                                                // limit the filter to only in-use classifications (overrides filter parameter)
                                                "inuse": true,
                                                // show unassigned taxonomy option (t/f)
                                                "unassigned": true,
                                                // options (classifications) to set to active by default
                                                "defaults": []
                                            },
                                            //optional is a child taxonomy
                                            "isChild": false
                                        },
                                        // taxonomy (Activity Status)
                                        {
                                            "id": "actsfilter6",
                                            "label": "Activity Status",
                                            "tpl": "acts/filter/taxonomy/taxonomy.tpl.html",
                                            // filter is active (open by default: t/f)
                                            "active": false,
                                            // filter type
                                            // options: datasource, organization, taxonomy, geographic
                                            "type": "taxonomy",
                                            "params": {
                                                "taxonomy_id": 18,
                                                // limit the filter options to only the listed
                                                "filter": [],
                                                // limit the filter to only in-use classifications (overrides filter parameter)
                                                "inuse": true,
                                                // show unassigned taxonomy option (t/f)
                                                "unassigned": true,
                                                // options (classifications) to set to active by default
                                                "defaults": []
                                            },
                                            //optional is a child taxonomy
                                            "isChild": false
                                        }
                                    ],
                                    // allow data download
                                    "downloadAuthorization": "000000",
                                    //external additional resources
                                    "supplemental": [],
                                    //detail page parameters
                                    "params": {
                                        //whether or not to show country or default to showing funding partner on header
                                        "showCountry": true,
                                        //whether to show admin 2 or stop at admin 1
                                        "showAdmin3": true,
                                        // columns to show on activity list
                                        // options: data_group, start_date, end_date, funding
                                        "activityListColumns": ["data_group", "start_date", "end_date", "funding"],
                                        // show data group (true/false)
                                        "showDataGroup": true,
                                        // tab settings
                                        "tabs": {
                                            "financials": {
                                                // columns to show on the financial tab
                                                // options: provider, recipient, finance_category, finance_type, transaction_type, amount
                                                "columns": ["provider", "recipient", "finance_category", "finance_type", "transaction_type", "amount"],
                                                // include detail records for activity that have an "_amount"
                                                "details": false
                                            }
                                        }
                                    }
                                }
                            }
                        },
                        // interactive map page
                        {
                            "route": "map",
                            "authorization": "000000",
                            "enable": true,
                            "order": 3,
                            "navLabel": "Map",
                            "navIcon": "fa fa-globe",
                            "navURL": "assets/icon_globe.svg",
                            "title": "The Interactive Map Section",
                            "subtitle": "The interactive map section is for exploring the spatial data.",
                            "stateParamDefaults": {
                                "lat": 20.30,
                                "lng": 8.26,
                                "zoom": 3,
                                "basemap": "esritopographic",
                                "layers": "afdb,wb"
                            },
                            // tool settings
                            "tools": {
                                // interactive map settings
                                "map": {
                                    "minZoom": 2,
                                    "maxZoom": 19,
                                    // pmt layers
                                    "layers": [
                                        {
                                            // unique application variable
                                            // (must be unique with contextual as well)
                                            "alias": "afdb",
                                            // lable for application
                                            "label": "African Development Bank",
                                            // data group id(s)
                                            "dataGroupIds": "2209",
                                            // the boundaryPoints to cluster to
                                            // (see: global.boundaryPoints)
                                            "boundaryPoints": "gadm",
                                            // export function
                                            "export": "pmt_export"
                                        },
                                        {
                                            // unique application variable
                                            // (must be unique with contextual as well)
                                            "alias": "wb",
                                            // lable for application
                                            "label": "World Bank",
                                            // data group id(s)
                                            "dataGroupIds": "2210",
                                            // the boundaryPoints to cluster to
                                            // (see: global.boundaryPoints)
                                            "boundaryPoints": "gadm",
                                            // export function
                                            "export": "pmt_export"
                                        }
                                    ],
                                    // contextual layers
                                    "contextual": [
                                        // Base Layers
                                        {
                                            // application variable (must be unique)
                                            "alias": "baselayers",
                                            // label presented in the UI menu
                                            "label": "Base Layers",
                                            // turn layer on by default
                                            "active": false,
                                            // listing of layers for this category (all alias values must be unique for
                                            // ALL layers in the app (both contextual and layers (pmt))
                                            // order of appearance is based on listed order below
                                            "layers": [
                                                {
                                                    "alias": "ele250msrtm",
                                                    "label": "Elevation, 250-meter (SRTM)",
                                                    "url": "http://gis1.servirglobal.net/arcgis/rest/services/Global/Global_Elevation_250m/MapServer",
                                                    "legend": "http://gis1.servirglobal.net/arcgis/rest/services/Global/Global_Elevation_250m/MapServer/legend?f=pjson",
                                                    "layers": [0],
                                                    "format": "image/png",
                                                    "opacity": .80,
                                                    "type": "wms",
                                                    "active": false,
                                                    "requiresToken": false
                                                },
                                                {
                                                    "alias": "ele90msrtm",
                                                    "label": "Elevation, 90-meter (SRTM)",
                                                    "url": "http://gis1.servirglobal.net/arcgis/rest/services/Global/Global_Elevation_90m/MapServer",
                                                    "legend": "http://gis1.servirglobal.net/arcgis/rest/services/Global/Global_Elevation_90m/MapServer/legend?f=pjson",
                                                    "layers": [0],
                                                    "format": "image/png",
                                                    "opacity": .80,
                                                    "type": "wms",
                                                    "active": false,
                                                    "requiresToken": false
                                                },
                                                {
                                                    "alias": "popdensity2000ciesin",
                                                    "label": "Population Density: 2000 (CIESIN)",
                                                    "url": "http://sedac.ciesin.columbia.edu/geoserver/ows",
                                                    "legend": "http://sedac.ciesin.columbia.edu/geoserver/ows?service=WMS&request=GetLegendGraphic&format=image%2Fpng&layer=gpw-v3-population-density_2000",
                                                    "legend_size": { "height": 163, "width": 213 },
                                                    "layers": ["gpw-v3-population-density_2000"],
                                                    "format": "image/png",
                                                    "opacity": .80,
                                                    "type": "tilelayer",
                                                    "crs": "L.CRS.EPSG4326",
                                                    "active": false,
                                                    "requiresToken": false
                                                },
                                                {
                                                    "alias": "popdensity1995ciesin",
                                                    "label": "Population Density: 1995 (CIESIN)",
                                                    "url": "http://sedac.ciesin.columbia.edu/geoserver/ows",
                                                    "legend": "http://sedac.ciesin.columbia.edu/geoserver/ows?service=WMS&request=GetLegendGraphic&format=image%2Fpng&layer=gpw-v3-population-density_1995",
                                                    "legend_size": { "height": 163, "width": 213 },
                                                    "layers": ["gpw-v3-population-density_1995"],
                                                    "format": "image/png",
                                                    "opacity": .80,
                                                    "type": "tilelayer",
                                                    "crs": "L.CRS.EPSG4326",
                                                    "active": false,
                                                    "requiresToken": false
                                                },
                                                {
                                                    "alias": "popdensity1990ciesin",
                                                    "label": "Population Density: 1990 (CIESIN)",
                                                    "url": "http://sedac.ciesin.columbia.edu/geoserver/ows",
                                                    "legend": "http://sedac.ciesin.columbia.edu/geoserver/ows?service=WMS&request=GetLegendGraphic&format=image%2Fpng&layer=gpw-v3-population-density_1990",
                                                    "legend_size": { "height": 163, "width": 213 },
                                                    "layers": ["gpw-v3-population-density_1990"],
                                                    "format": "image/png",
                                                    "opacity": .80,
                                                    "type": "tilelayer",
                                                    "crs": "L.CRS.EPSG4326",
                                                    "active": false,
                                                    "requiresToken": false
                                                },
                                                {
                                                    "alias": "popfutureest2015ciesin",
                                                    "label": "Population Future Estimates: 2015 (CIESIN)",
                                                    "url": "http://sedac.ciesin.columbia.edu/geoserver/ows",
                                                    "legend": "http://sedac.ciesin.columbia.edu/geoserver/ows?service=WMS&request=GetLegendGraphic&format=image%2Fpng&layer=gpw-v3-population-density-future-estimates_2015",
                                                    "legend_size": { "height": 163, "width": 213 },
                                                    "layers": ["gpw-v3-population-density-future-estimates_2015"],
                                                    "format": "image/png",
                                                    "opacity": .80,
                                                    "type": "tilelayer",
                                                    "crs": "L.CRS.EPSG4326",
                                                    "active": false,
                                                    "requiresToken": false
                                                },
                                                {
                                                    "alias": "popfutureest2010ciesin",
                                                    "label": "Population Future Estimates: 2010 (CIESIN)",
                                                    "url": "http://sedac.ciesin.columbia.edu/geoserver/ows",
                                                    "legend": "http://sedac.ciesin.columbia.edu/geoserver/ows?service=WMS&request=GetLegendGraphic&format=image%2Fpng&layer=gpw-v3-population-density-future-estimates_2010",
                                                    "legend_size": { "height": 163, "width": 213 },
                                                    "layers": ["gpw-v3-population-density-future-estimates_2010"],
                                                    "format": "image/png",
                                                    "opacity": .80,
                                                    "type": "tilelayer",
                                                    "crs": "L.CRS.EPSG4326",
                                                    "active": false,
                                                    "requiresToken": false
                                                },
                                                {
                                                    "alias": "popfutureest2005ciesin",
                                                    "label": "Population Future Estimates: 2005 (CIESIN)",
                                                    "url": "http://sedac.ciesin.columbia.edu/geoserver/ows",
                                                    "legend": "http://sedac.ciesin.columbia.edu/geoserver/ows?service=WMS&request=GetLegendGraphic&format=image%2Fpng&layer=gpw-v3-population-density-future-estimates_2005",
                                                    "legend_size": { "height": 163, "width": 213 },
                                                    "layers": ["gpw-v3-population-density-future-estimates_2005"],
                                                    "format": "image/png",
                                                    "opacity": .80,
                                                    "type": "tilelayer",
                                                    "crs": "L.CRS.EPSG4326",
                                                    "active": false,
                                                    "requiresToken": false
                                                },
                                                {
                                                    "alias": "popsettlementpointsciesin",
                                                    "label": "Population, Settlement Points (CIESIN)",
                                                    "url": "http://sedac.ciesin.columbia.edu/geoserver/ows",
                                                    "legend": "http://sedac.ciesin.columbia.edu/geoserver/ows?service=WMS&request=GetLegendGraphic&format=image%2Fpng&layer=grump-v1-settlement-points",
                                                    "legend_size": { "height": 20, "width": 20 },
                                                    "layers": ["grump-v1-settlement-points"],
                                                    "format": "image/png",
                                                    "opacity": .80,
                                                    "type": "tilelayer",
                                                    "crs": "L.CRS.EPSG4326",
                                                    "active": false,
                                                    "requiresToken": false
                                                },
                                                {
                                                    "alias": "popurbanextentsciesin",
                                                    "label": "Population, Urban Extents (CIESIN)",
                                                    "url": "http://sedac.ciesin.columbia.edu/geoserver/ows",
                                                    "legend": "http://sedac.ciesin.columbia.edu/geoserver/ows?service=WMS&request=GetLegendGraphic&format=image%2Fpng&layer=grump-v1-urban-extents",
                                                    "legend_size": { "height": 20, "width": 20 },
                                                    "layers": ["grump-v1-urban-extents"],
                                                    "format": "image/png",
                                                    "opacity": .80,
                                                    "type": "tilelayer",
                                                    "crs": "L.CRS.EPSG4326",
                                                    "active": false,
                                                    "requiresToken": false
                                                },
                                                {
                                                    "alias": "soiltypeshwsd",
                                                    "label": "Soil Types (HWSD)",
                                                    "url": "http://gis1.servirglobal.net/arcgis/rest/services/Global/Global_Soils/MapServer",
                                                    "legend": "http://gis1.servirglobal.net/arcgis/rest/services/Global/Global_Soils/MapServer/legend?f=pjson",
                                                    "layers": [0],
                                                    "format": "image/png",
                                                    "opacity": .80,
                                                    "type": "wms",
                                                    "active": false,
                                                    "requiresToken": false
                                                },
                                                {
                                                    "alias": "acc",
                                                    "label": "Agricultural Commercialization Clusters",
                                                    "url": "http://spatialserver.spatialdev.com/services/tiles/ethaim_acc_2016116/{z}/{x}/{y}.png",
                                                    "legend": "https://s3.amazonaws.com/v10.investmentmapping.org/vector-tiles/legends/mapLegend_acc_boundary.png",
                                                    "format": "image/png",
                                                    "opacity": .80,
                                                    "type": "mbtile",
                                                    "active": false,
                                                    "requiresToken": false
                                                }
                                            ],
                                            "metadata": {
                                                "source": "Humanitarian Response",
                                                "reference_period": "2011",
                                                "URL": "https://www.humanitarianresponse.info/"
                                            }
                                        },
                                        // Ecosystems
                                        {
                                            // application variable (must be unique)
                                            "alias": "ecobio",
                                            // label presented in the UI menu
                                            "label": "Ecosystems",
                                            // turn layer on by default
                                            "active": false,
                                            // listing of layers for this category (all alias values must be unique for
                                            // ALL layers in the app (both contextual and layers (pmt))
                                            // order of appearance is based on listed order below
                                            "layers": [
                                                {
                                                    "alias": "modislandcover01",
                                                    "label": "MODIS Landcover 2001",
                                                    "url": "http://gis1.servirglobal.net/arcgis/rest/services/Global/MODIS_Landcover_Type1_2001/MapServer",
                                                    "legend": "http://gis1.servirglobal.net/arcgis/rest/services/Global/MODIS_Landcover_Type1_2001/MapServer/legend?f=pjson",
                                                    "layers": [0],
                                                    "format": "image/png",
                                                    "opacity": .80,
                                                    "type": "wms",
                                                    "active": false,
                                                    "requiresToken": false
                                                },
                                                {
                                                    "alias": "modislandcover02",
                                                    "label": "MODIS Landcover 2002",
                                                    "url": "http://gis1.servirglobal.net/arcgis/rest/services/Global/MODIS_Landcover_Type1_2002/MapServer",
                                                    "legend": "http://gis1.servirglobal.net/arcgis/rest/services/Global/MODIS_Landcover_Type1_2002/MapServer/legend?f=pjson",
                                                    "layers": [0],
                                                    "format": "image/png",
                                                    "opacity": .80,
                                                    "type": "wms",
                                                    "active": false,
                                                    "requiresToken": false
                                                },
                                                {
                                                    "alias": "modislandcover03",
                                                    "label": "MODIS Landcover 2003",
                                                    "url": "http://gis1.servirglobal.net/arcgis/rest/services/Global/MODIS_Landcover_Type1_2003/MapServer",
                                                    "legend": "http://gis1.servirglobal.net/arcgis/rest/services/Global/MODIS_Landcover_Type1_2003/MapServer/legend?f=pjson",
                                                    "layers": [0],
                                                    "format": "image/png",
                                                    "opacity": .80,
                                                    "type": "wms",
                                                    "active": false,
                                                    "requiresToken": false
                                                },
                                                {
                                                    "alias": "modislandcover04",
                                                    "label": "MODIS Landcover 2004",
                                                    "url": "http://gis1.servirglobal.net/arcgis/rest/services/Global/MODIS_Landcover_Type1_2004/MapServer",
                                                    "legend": "http://gis1.servirglobal.net/arcgis/rest/services/Global/MODIS_Landcover_Type1_2004/MapServer/legend?f=pjson",
                                                    "layers": [0],
                                                    "format": "image/png",
                                                    "opacity": .80,
                                                    "type": "wms",
                                                    "active": false,
                                                    "requiresToken": false
                                                },
                                                {
                                                    "alias": "modislandcover05",
                                                    "label": "MODIS Landcover 2005",
                                                    "url": "http://gis1.servirglobal.net/arcgis/rest/services/Global/MODIS_Landcover_Type1_2005/MapServer",
                                                    "legend": "http://gis1.servirglobal.net/arcgis/rest/services/Global/MODIS_Landcover_Type1_2005/MapServer/legend?f=pjson",
                                                    "layers": [0],
                                                    "format": "image/png",
                                                    "opacity": .80,
                                                    "type": "wms",
                                                    "active": false,
                                                    "requiresToken": false
                                                },
                                                {
                                                    "alias": "modislandcover06",
                                                    "label": "MODIS Landcover 2006",
                                                    "url": "http://gis1.servirglobal.net/arcgis/rest/services/Global/MODIS_Landcover_Type1_2006/MapServer",
                                                    "legend": "http://gis1.servirglobal.net/arcgis/rest/services/Global/MODIS_Landcover_Type1_2006/MapServer/legend?f=pjson",
                                                    "layers": [0],
                                                    "format": "image/png",
                                                    "opacity": .80,
                                                    "type": "wms",
                                                    "active": false,
                                                    "requiresToken": false
                                                },
                                                {
                                                    "alias": "modislandcover07",
                                                    "label": "MODIS Landcover 2007",
                                                    "url": "http://gis1.servirglobal.net/arcgis/rest/services/Global/MODIS_Landcover_Type1_2007/MapServer",
                                                    "legend": "http://gis1.servirglobal.net/arcgis/rest/services/Global/MODIS_Landcover_Type1_2007/MapServer/legend?f=pjson",
                                                    "layers": [0],
                                                    "format": "image/png",
                                                    "opacity": .80,
                                                    "type": "wms",
                                                    "active": false,
                                                    "requiresToken": false
                                                },
                                                {
                                                    "alias": "modislandcover08",
                                                    "label": "MODIS Landcover 2008",
                                                    "url": "http://gis1.servirglobal.net/arcgis/rest/services/Global/MODIS_Landcover_Type1_2008/MapServer",
                                                    "legend": "http://gis1.servirglobal.net/arcgis/rest/services/Global/MODIS_Landcover_Type1_2008/MapServer/legend?f=pjson",
                                                    "layers": [0],
                                                    "format": "image/png",
                                                    "opacity": .80,
                                                    "type": "wms",
                                                    "active": false,
                                                    "requiresToken": false
                                                },
                                                {
                                                    "alias": "modislandcover09",
                                                    "label": "MODIS Landcover 2009",
                                                    "url": "http://gis1.servirglobal.net/arcgis/rest/services/Global/MODIS_Landcover_Type1_2009/MapServer",
                                                    "legend": "http://gis1.servirglobal.net/arcgis/rest/services/Global/MODIS_Landcover_Type1_2009/MapServer/legend?f=pjson",
                                                    "layers": [0],
                                                    "format": "image/png",
                                                    "opacity": .80,
                                                    "type": "wms",
                                                    "active": false,
                                                    "requiresToken": false
                                                },
                                                {
                                                    "alias": "modislandcover10",
                                                    "label": "MODIS Landcover 2010",
                                                    "url": "http://gis1.servirglobal.net/arcgis/rest/services/Global/MODIS_Landcover_Type1_2010/MapServer",
                                                    "legend": "http://gis1.servirglobal.net/arcgis/rest/services/Global/MODIS_Landcover_Type1_2010/MapServer/legend?f=pjson",
                                                    "layers": [0],
                                                    "format": "image/png",
                                                    "opacity": .80,
                                                    "type": "wms",
                                                    "active": false,
                                                    "requiresToken": false
                                                },
                                                {
                                                    "alias": "modislandcover11",
                                                    "label": "MODIS Landcover 2011",
                                                    "url": "http://gis1.servirglobal.net/arcgis/rest/services/Global/MODIS_Landcover_Type1_2011/MapServer",
                                                    "legend": "http://gis1.servirglobal.net/arcgis/rest/services/Global/MODIS_Landcover_Type1_2011/MapServer/legend?f=pjson",
                                                    "layers": [0],
                                                    "format": "image/png",
                                                    "opacity": .80,
                                                    "type": "wms",
                                                    "active": false,
                                                    "requiresToken": false
                                                },
                                                {
                                                    "alias": "modisleafindex1m",
                                                    "label": "Leaf Area Index: 1 Month (MODIS)",
                                                    "url": "http://neowms.sci.gsfc.nasa.gov/wms/wms",
                                                    "legend": "http://neo.sci.gsfc.nasa.gov/palettes/modis_lai.png",
                                                    "legend_size": { "height": 35, "width": 200 },
                                                    "layers": ["MOD15A2_M_LAI"],
                                                    "format": "image/png",
                                                    "opacity": .80,
                                                    "type": "tilelayer",
                                                    //"crs": "L.CRS.EPSG4326",
                                                    "active": false,
                                                    "requiresToken": false
                                                },
                                                {
                                                    "alias": "vegetationindex1mmodis",
                                                    "label": "Vegetation Index: 1 Month (MODIS)",
                                                    "url": "http://neowms.sci.gsfc.nasa.gov/wms/wms",
                                                    "legend": "http://neo.sci.gsfc.nasa.gov/palettes/modis_ndvi.png",
                                                    "legend_size": { "height": 35, "width": 200 },
                                                    "layers": ["MOD13A2_M_NDVI"],
                                                    "format": "image/png",
                                                    "opacity": .80,
                                                    "type": "tilelayer",
                                                    "crs": "L.CRS.EPSG4326",
                                                    "active": false,
                                                    "requiresToken": false
                                                }
                                            ],
                                            "metadata": {
                                                "source": "Servir Global",
                                                "reference_period": "2001-2011",
                                                "URL": "http://gis1.servirglobal.net/arcgis/rest/services/Global/"
                                            }
                                        },
                                        // Water
                                        {
                                            // application variable (must be unique)
                                            "alias": "water",
                                            // label presented in the UI menu
                                            "label": "Water",
                                            // turn layer on by default
                                            "active": false,
                                            // listing of layers for this category (all alias values must be unique for
                                            // ALL layers in the app (both contextual and layers (pmt))
                                            // order of appearance is based on listed order below
                                            "layers": [
                                                {
                                                    "alias": "chlorophyllconc1mmodis",
                                                    "label": "Chlorophyll Concentration: 1 Month (MODIS)",
                                                    "url": "http://neowms.sci.gsfc.nasa.gov/wms/wms",
                                                    "legend": "http://neo.sci.gsfc.nasa.gov/palettes/modis_chlor.png",
                                                    "legend_size": { "height": 35, "width": 200 },
                                                    "layers": ["MY1DMM_CHLORA"],
                                                    "format": "image/png",
                                                    "opacity": .80,
                                                    "type": "tilelayer",
                                                    "crs": "L.CRS.EPSG4326",
                                                    "active": false,
                                                    "requiresToken": false
                                                },
                                                {
                                                    "alias": "seasurfacetempanml1mmodis",
                                                    "label": "Sea Surface Temp Anomaly: 1 Month (MODIS)",
                                                    "url": "http://neowms.sci.gsfc.nasa.gov/wms/wms",
                                                    "legend": "http://neo.sci.gsfc.nasa.gov/palettes/modis_sst_45.png",
                                                    "legend_size": { "height": 35, "width": 200 },
                                                    "layers": ["AMSRE_SSTAn_M"],
                                                    "format": "image/png",
                                                    "opacity": .80,
                                                    "type": "tilelayer",
                                                    "crs": "L.CRS.EPSG4326",
                                                    "active": false,
                                                    "requiresToken": false
                                                }
                                            ],
                                            "metadata": {
                                                "source": "NASA MODIS",
                                                "reference_period": "NA",
                                                "URL": "http://neowms.sci.gsfc.nasa.gov/wms/wms"
                                            }
                                        },
                                        // Weather
                                        {
                                            // application variable (must be unique)
                                            "alias": "weather",
                                            // label presented in the UI menu
                                            "label": "Weather",
                                            // turn layer on by default
                                            "active": false,
                                            // listing of layers for this category (all alias values must be unique for
                                            // ALL layers in the app (both contextual and layers (pmt))
                                            // order of appearance is based on listed order below
                                            "layers": [
                                                {
                                                    "alias": "nasa7drain",
                                                    "label": "NASA 7 Day Rainfall",
                                                    "url": "http://gis1.servirglobal.net/arcgis/rest/services/Global/IMERG_Accumulations/MapServer",
                                                    "legend": "http://gis1.servirglobal.net/arcgis/rest/services/Global/IMERG_Accumulations/MapServer/legend?f=pjson",
                                                    "layers": [1],
                                                    "format": "image/png",
                                                    "opacity": .80,
                                                    "type": "wms",
                                                    "active": false,
                                                    "requiresToken": false
                                                }
                                            ],
                                            "metadata": {
                                                "source": "Servir Global",
                                                "reference_period": "current",
                                                "URL": "http://gis1.servirglobal.net/arcgis/rest/services/Global/"
                                            }
                                        }
                                    ],
                                    // supporting layers
                                    "supportingLayers": [
                                        {
                                            "alias": "gadm0",
                                            "label": "GADM Level o",
                                            "url": "https://s3.amazonaws.com/v10.investmentmapping.org/vector-tiles/gadm0/{z}/{x}/{y}.pbf",
                                            "legend": "",
                                            "opacity": .80,
                                            "type": "vectortile",
                                            "active": false
                                        },
                                        {
                                            "alias": "gadm1",
                                            "label": "GADM Level 1",
                                            "url": "https://s3.amazonaws.com/v10.investmentmapping.org/vector-tiles/gadm1/{z}/{x}/{y}.pbf",
                                            "legend": "",
                                            "opacity": .80,
                                            "type": "vectortile",
                                            "active": false
                                        },
                                        {
                                            "alias": "gadm2",
                                            "label": "GADM Level 2",
                                            "url": "https://s3.amazonaws.com/v10.investmentmapping.org/vector-tiles/gadm2/{z}/{x}/{y}.pbf",
                                            "legend": "",
                                            "opacity": .80,
                                            "type": "vectortile",
                                            "active": false
                                        }
                                    ],
                                    // regions feature collection
                                    "regions": {
                                        "type": "FeatureCollection",
                                        "features": [
                                            // Global
                                            {
                                                "type": "Feature",
                                                "geometry": {
                                                    "type": "Polygon",
                                                    "coordinates": [
                                                        [137.109375, 59.3163747103164],
                                                        [137.109375, -49.2032427441791],
                                                        [-104.765625, -49.2032427441791],
                                                        [-104.765625, 59.3163747103164],
                                                        [137.109375, 59.3163747103164]
                                                    ]
                                                },
                                                "properties": {
                                                    "alias": "global",
                                                    "name": "Global",
                                                    "classification_ids": [],
                                                    "sort_order": 0
                                                }
                                            },
                                            // SpatialDev Headquarters
                                            {
                                                "type": "Feature",
                                                "geometry": {
                                                    "type": "Polygon",
                                                    "coordinates": [
                                                        [-122.45635986328125, 47.705509208064115],
                                                        [-122.17964172363281, 47.705509208064115],
                                                        [-122.17964172363281, 47.527307784805366],
                                                        [-122.45635986328125, 47.527307784805366],
                                                        [-122.45635986328125, 47.705509208064115]
                                                    ]
                                                },
                                                "properties": {
                                                    "alias": "spatialdevhq",
                                                    "name": "SpatialDev HQ",
                                                    "classification_ids": [],
                                                    "sort_order": 1
                                                }
                                            }
                                        ]
                                    },
                                    // filter settings
                                    "filters": [
                                        // data sources
                                        {
                                            // available data sources for the filter are defined by the layers
                                            // defined in tools.map.layers
                                            "id": "mapfilter1",
                                            "label": "Data Sources",
                                            "tpl": "map/left-panel/filter/datasource/datasource.tpl.html",
                                            // show filter (t/f)
                                            "enable": true,
                                            //optional is a child taxonomy
                                            "isChild": false
                                        },
                                        // funding organizations
                                        {
                                            "id": "mapfilter2",
                                            "label": "Funders",
                                            "tpl": "map/left-panel/filter/organization/organization.tpl.html",
                                            "params": {
                                                // the filter for organization role to restrict data to
                                                "org_role_ids": "496",
                                                // filter type (options: implementing, funding, all)
                                                "type": "funding"
                                            },
                                            //optional is a child taxonomy
                                            "isChild": false
                                        },
                                        // implementing organizations
                                        {
                                            "id": "mapfilter3",
                                            "label": "Implementers",
                                            "tpl": "map/left-panel/filter/organization/organization.tpl.html",
                                            "params": {
                                                // the filter for organization role to restrict data to
                                                "org_role_ids": "497",
                                                // filter type (options: implementing, funding, all)
                                                "type": "implementing"
                                            },
                                            //optional is a child taxonomy
                                            "isChild": false
                                        },
                                        // taxonomy (Sector)
                                        {
                                            "id": "mapfilter5",
                                            "label": "Sector",
                                            "tpl": "map/left-panel/filter/taxonomy/taxonomy.tpl.html",
                                            "params": {
                                                // id of taxonomy for filter options
                                                "taxonomy_id": 15,
                                                // limit the filter options to only the listed
                                                "filter": [],
                                                // limit the filter to only in-use classifications (overrides filter parameter)
                                                "inuse": true,
                                                // show unassigned taxonomy option (t/f)
                                                "unassigned": true
                                            },
                                            //optional is a child taxonomy
                                            "isChild": false
                                        },
                                        // taxonomy (Activity Status)
                                        {
                                            "id": "mapfilter6",
                                            "label": "Activity Status",
                                            "tpl": "map/left-panel/filter/taxonomy/taxonomy.tpl.html",
                                            "params": {
                                                // id of taxonomy for filter options
                                                "taxonomy_id": 18,
                                                // limit the filter options to only the listed
                                                "filter": [],
                                                // limit the filter to only in-use classifications (overrides filter parameter)
                                                "inuse": true,
                                                // show unassigned taxonomy option (t/f)
                                                "unassigned": true
                                            },
                                            //optional is a child taxonomy
                                            "isChild": false
                                        }
                                    ],
                                    // allow data export
                                    "exportAuthorization": "000000",
                                    // the timeslider settings
                                    "timeslider": {
                                        // the timeslider is initially on/off
                                        "defaultEnabled": true,
                                        // the default start year on initialization
                                        "defaultStart": 1970,
                                        // the default end year on initialization
                                        "defaultEnd": 2024,
                                        // the timesliders minimum year
                                        "floor": 1970,
                                        // the timesliders maximum year
                                        "ceiling": 2024
                                    },
                                    // target analysis settings
                                    "targetAnalysis": {
                                        "active": false,
                                        "countries": ["Ethiopia", "Tanzania"],
                                        "supportingLayer": "gadm1"
                                    },
                                    // travel tool settings
                                    "travel": {
                                        "active": true,
                                        // taxonomy id (ex. initiative)
                                        "taxonomy": 14,
                                        // sub-taxonomy id (ex. sub-initiative)
                                        "subtaxonomy": 15,
                                        // preferred country boundaries
                                        "countries": "gadm0",
                                        // preferred region boundaries
                                        "regions": "gadm1",
                                        // preferred district boundaries
                                        "districts": "gadm2",
                                        "showInvestmentData": true
                                    },
                                    //external additional resources
                                    "supplemental": [],
                                    // zoom to search settings
                                    "zoomTo": {
                                        // boundary type for boundary search
                                        "boundaryType": "gadm",
                                        // country list to restricct search to (list all country name variations)
                                        "countries": []
                                    },
                                    // show data group (true/false)
                                    "showDataGroup": true,
                                    // tab settings
                                    "tabs": {
                                        "financials": {
                                            // columns to show on the financial tab
                                            // options: provider, recipient, finance_category, finance_type, transaction_type, amount
                                            "columns": ["provider", "recipient", "finance_category", "finance_type", "transaction_type", "amount"],
                                            // include detail records for activity that have an "_amount"
                                            "details": false
                                        }
                                    },
                                    // template
                                    "tpl": "map/map/map.tpl.html"
                                },
                                //geocoder key for location search, interactive map
                                "geocoderKey": {
                                    "key": "7ec03ba5eb2a8d457af76416a35a5728"
                                }
                            }
                        },
                        // partnerlink page
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
                            "stateParamDefaults": {
                            },
                            // tool settings
                            "tools": {
                                // filter settings
                                "filters": [
                                    // data sources
                                    {
                                        // available data sources for the filter are defined by the layers
                                        // defined in tools.map.layers
                                        "id": "plfilter1",
                                        "label": "Data Sources",
                                        "tpl": "pl/filter/datasource/datasource.tpl.html",
                                        "params": {
                                            // data group(s) available for visualization in the partnerlink
                                            "data_groups": [
                                                {
                                                    "label": "World Bank",
                                                    "data_group_ids": "2210",
                                                    "active": true
                                                },
                                                {
                                                    "label": "African Development Bank",
                                                    "data_group_ids": "2209",
                                                    "active": true
                                                }
                                            ]
                                        },
                                        // default setting for filter
                                        "open": true
                                    },
                                    // implementing organizations
                                    {
                                        "id": "plfilter2",
                                        "label": "Organization",
                                        "tpl": "pl/filter/organization/organization.tpl.html",
                                        // default setting for filter
                                        "open": false
                                    }
                                ],
                                "color_range": ["#3E7F98", "#3E7F98"],
                                "grantee_not_reported_label": "",
                                "partner_not_reported_label": "Other Partners",
                                "funder_not_reported_label": "",
                                "aggregator": "activity_count"
                            }
                        },
                        // monitoring & evaluation (me) page
                        {
                            "route": "me",
                            "authorization": "000000",
                            "enable": false,
                            "order": 5,
                            "navLabel": "M&E",
                            "navIcon": "fa fa-line-chart",
                            "navURL": "assets/icon_analysis.svg",
                            "title": "Monitoring & Evaluation",
                            "subtitle": "The Monitoring & Evaluation section is for exploring results and tracking data related to project and program indicators and goals."
                        },
                        // editor page
                        {
                            "route": "editor",
                            "authorization": "000111",
                            "enable": false,
                            "order": 6,
                            "navLabel": "Editor",
                            "navIcon": "fa fa-pencil-alt",
                            "navURL": null,
                            "title": "The Editor Section",
                            "subtitle": "The editor section is the application editing page."
                        },
                        // organization editor page
                        {
                            "route": "orgs",
                            "authorization": "100000",
                            "enable": true,
                            "order": 7,
                            "navLabel": "Orgs",
                            "navIcon": "fa fa-key",
                            "navURL": "assets/icon_orgs.svg",
                            "title": "Organization Editor",
                            "subtitle": "Organization Management",
                            // tool settings
                            "tools": {
                                // editor tools
                            }
                        },
                        // taxonomy editor page
                        {
                            "route": "tax",
                            "authorization": "100000",
                            "enable": false,
                            "order": 8,
                            "navLabel": "Taxonomy",
                            "navIcon": "fa fa-gavel",
                            "navURL": null,
                            "title": "Taxonomy Editor",
                            "subtitle": "Taxonomy Management",
                            // tool settings
                            "tools": {
                                // editor tools
                            }
                        },
                        // admin page
                        {
                            "route": "admin",
                            "authorization": "100000",
                            "enable": true,
                            "order": 8,
                            "navLabel": "Admin",
                            "navIcon": "fa fa-key",
                            "navURL": "assets/icon_key.svg",
                            "title": "Administrative Console",
                            "subtitle": "User Management",
                            // tool settings
                            "tools": {
                                // user administration tools
                                "users": {
                                    // list of taxonomies for granting user access to activities  
                                    "taxonomies": [
                                        {
                                            "taxonomy_id": 15,
                                            // limit the options to only the listed
                                            "filter": [],
                                            // limit the options to only in-use classifications (overrides filter parameter)
                                            "inuse": true,
                                            // taxonomy label
                                            "label": "Sector"
                                        }
                                    ]
                                }
                            }
                        },
                        // video button
                        {
                            "route": null,
                            "authorization": "000000",
                            "enable": false,
                            "order": 9,
                            "navLabel": "Video",
                            "navIcon": "fa fa-home",
                            "title": "The Intro Video",
                            "subtitle": "Explanation of how to use PMT.",
                            "template": "video/video.tpl.html",
                            "videoURL": ""
                        },
                        // ARGA integration page
                        {
                            "route": "agra",
                            "authorization": "100000",
                            "enable": false,
                            "order": 6,
                            "mergeRelatedActivities": false, //if true, will take related activities and display within the details page, rather than linking to sub-details page
                            "navLabel": "Integration",
                            "navIcon": "fas fa-server",
                            "navURL": null,
                            "title": "AGRA AMIS/PMT Integration Tool",
                            "subtitle": "The integration is resource intensive and should only be executed outside of peak usage times for the application.",
                            "stateParamDefaults": {

                            },
                            "tools": {
                                //tool params
                                "schedule": null,
                                "recipients": null,
                            }
                        }
                    ],
                    //specific terminology to be used in this instance
                    "terminology": {
                        "activity_terminology": {
                            "singular": "activity",
                            "plural": "activities"
                        },
                        "boundary_terminology": {
                            "singular": {
                                "admin1": "region",
                                "admin2": "zone",
                                "admin3": "area"
                            },
                            "plural": {
                                "admin1": "regions",
                                "admin2": "zones",
                                "admin3": "areas"
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
                    // the default state (after login),
                    "defaultState": "locations",
                    // email subject and message for new users and updated passwords
                    "email": {
                        "newUser": {
                            "subject": "New PMT account",
                            "body": "A new account has been created. See details below:"
                        },
                        "newPassword": {
                            "subject": "Updated PMT Account Password",
                            "body": "A new password has been created. See details below:"
                        }

                    },
                    // user guide (the user guide has been configured for this theme)
                    "userguide": false
                }
            }
        }
    }
};
