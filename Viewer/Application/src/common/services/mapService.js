/***************************************************************
 * Map Service
 * 
* *************************************************************/

angular.module('PMTViewer').service('mapService', function ($state, $rootScope, $stateParams, stateService, basemapService, pmtMapService, config, global, pmt) {

    // the map service model
    var mapService = {
        map: {},
        basemap: {},
        layers: {},
        contextual: {},
        geojson: {},
        hasGeojson: false
    };

    // geojson style
    //style function to set geojson by attribute
    function style(feature) {
        if (feature.geometry.level == 'admin3') {
            return {
                weight: 3,
                opacity: 1,
                color: "rgb(205,68,255)",
                fillOpacity: 0.3,
                fillColor: "rgb(205,68,255)"
            };
        }
        if (feature.geometry.level == 'admin2') {
            return {
                weight: 3,
                opacity: 1,
                color: "rgb(51,122,183)",
                fillOpacity: 0.3,
                fillColor: "rgb(51,122,183)"
            };
        }
        if (feature.geometry.level == 'admin1') {
            return {
                weight: 3,
                opacity: 1,
                color: "rgb(208,77,56)",
                fillOpacity: 0.3,
                fillColor: "rgb(208,77,56)"
            };
        }
        else {
            return {
                weight: 1,
                opacity: 1,
                color: "#2E85CB",
                fillOpacity: 0.5,
                fillColor: "#2E85CB"
            };
        }
    }

    var stateConfig = _.find(config.states, function (states) { return states.route == $state.current.name; });

    // intialize the map service
    mapService.init = function (map) {
        // get the current state
        stateConfig = _.find(config.states, function (states) { return states.route == $state.current.name; });
        var setState = false;
        // clear the service instance
        clearInstance();
        // assign the instantiated map to our map variable
        mapService.map = map;
        // instantiate geojson layer
        mapService.geojson = L.geoJson().addTo(mapService.map);
        // add the zoom controls to the bottom right of the map
        new L.Control.Zoom({ position: 'bottomright' }).addTo(mapService.map);
        //set state params if empty
        if ($stateParams.lat == '' || $stateParams.lng == '' || $stateParams.zoom == '' || $stateParams.basemap == '') {
            $stateParams.lat = $stateParams.lat || stateConfig.stateParamDefaults.lat.toString();
            $stateParams.lng = $stateParams.lng || stateConfig.stateParamDefaults.lng.toString();
            $stateParams.zoom = $stateParams.zoom || stateConfig.stateParamDefaults.zoom.toString();
            $stateParams.basemap = $stateParams.basemap || stateConfig.stateParamDefaults.basemap;
            setState = true;
        }

        // set the map center
        mapService.map.setView([parseInt($stateParams.lat, 10), parseInt($stateParams.lng, 10)], parseInt($stateParams.zoom, 10));
        // get the basemap alias from state or default if empty 
        // call the basemap service to get the basemap layer
        var basemapLayer = basemapService.getBasemap($stateParams.basemap);
        mapService.basemap = basemapLayer;
        // add the basemap layer to the map
        mapService.basemap.addTo(mapService.map);

        // update the url if it was empty of lat,lng,zoom or basemap params
        if ($stateParams.lat == '' || $stateParams.lng == '' || $stateParams.zoom == '' || $stateParams.basemap == '') {
            stateService.setState($state.current.name, $stateParams, false);
        }

        // add default layers if url is empty
        if ($stateParams.layers) {
            // call the redraw function to redraw all layers listed in the url
            redraw(true);
        }
        else {
            $stateParams.layers = stateConfig.stateParamDefaults.layers;
            stateService.setState($state.current.name, $stateParams, false);
            setState = false; // set to false so state is not set twice below
        }

        // setState if it was altered
        if (setState) { stateService.setState($state.current.name, $stateParams, false); }

        // when the map stops moving do this
        mapService.map.on('moveend', function () {
            var c = mapService.map.getCenter();
            var lat = c.lat.toFixed(6);
            var lng = c.lng.toFixed(6);
            var zoom = mapService.map.getZoom().toString();

            // if the zoom level or lat/log changes then
            // update the states zoom and lat/long parameters
            if ($stateParams.lat !== lat.toString() || $stateParams.lng !== lng.toString() || $stateParams.zoom !== zoom.toString()) {
                $stateParams.lat = lat.toString();
                $stateParams.lng = lng.toString();
                $stateParams.zoom = zoom.toString();
                // delay the map function check for container size change
                setTimeout(function () { map.invalidateSize() }, 400);
                mapMoveEnd = true;
                stateService.setState($state.current.name, $stateParams, false);
            }
        });
    };

    // add geojson to the map
    mapService.addGeojson = function (feature, level) {
        //update feature to have level property
        feature.level = level;
        mapService.geojson.addData(feature);
        mapService.geojson.setStyle(style);
        mapService.hasGeojson = true;
    };

    // clear all geojson features
    mapService.clearGeojson = function () {
        mapService.map.removeLayer(mapService.geojson);
        mapService.geojson = L.geoJson().addTo(mapService.map);
        mapService.hasGeojson = false;
    };

    // zoom to an extent
    mapService.zoomToExtent = function (extent) {
        mapService.map.fitBounds([
            [extent[0][1], extent[0][0]],
            [extent[2][1], extent[2][0]]
        ]);
    };

    // set the map center
    mapService.setMapCenter = function (lat, lng, zoom) {
        // set the map center
        mapService.map.setView([lat, lng], zoom);
    };

    // tell the map service to redraw
    mapService.forceRedraw = function () { redraw(true); };

    // update the cursor for the map
    mapService.setCursor = function (type) {
        switch (type) {
            case 'pin':
                $('.leaflet-container').css('cursor', 'url("./assets/icon_pin.png"), auto');
                break;
            case 'pointer':
                $('.leaflet-container').css('cursor', 'pointer');
                break;
            case 'default':
                $('.leaflet-container').css('cursor', 'default');
                break;
            default:
                $('.leaflet-container').css('cursor', '');
                break;
        }
    };

    // clear all layers from the map
    mapService.clearLayers = function () {
        mapService.map.eachLayer(function (layer) {
            if (!layer.isBasemap) {
                mapService.map.removeLayer(layer);
            }
        });
    };

    // when the url is updated do this
    $rootScope.$on('layers-update', function () {
        redraw(false);
    });

    // when the basemap parameter is updated do this
    $rootScope.$on('basemap-update', function () {
        // if the basemap has changed, update the map
        if (stateService.paramChanged('basemap')) {
            // remove layer
            mapService.map.removeLayer(mapService.basemap);
            mapService.basemap = {};
            // get the current state
            var state = stateService.getState();
            // get the basemap alias from state or default if empty 
            // call the basemap service to get the basemap layer
            var basemapLayer = basemapService.getBasemap(state.basemap || stateConfig.stateParamDefaults.basemap);
            // add the basemap layer to the map
            mapService.basemap = basemapLayer;
            basemapLayer.addTo(mapService.map);
        }
    });

    // when the zoom parameter is updated do this
    $rootScope.$on('zoom-update', function () {
        redraw(true);
    });

    // when the filter is updated do this
    $rootScope.$on('pmt-filter-update', function () {
        redraw(true);
    });

    // loop through the list of layers in state
    // and draw them on the map
    function redraw(force_redraw) {
        stateConfig = _.find(config.states, function (states) { return states.route == $state.current.name; });
        // init pmt map service
        pmtMapService.init(mapService.map);
        // get the current state
        var state = stateService.getState();
        // get a list of the boundaries from the pmt boundary points
        var boundaries = [];
        // get all the boundary layers in the boundary points
        _.each(pmt.boundaryPoints, function (boundarySet) {
            // get all the boundary aliases
            boundaries = boundaries.concat(_.pluck(_.filter(boundarySet, function (l) { return _.has(l, 'boundary'); }), 'boundary'));
            boundaries = boundaries.concat(_.pluck(_.filter(boundarySet, function (l) { return _.has(l, 'select'); }), 'select'));
        });
        // if the layer list has changed, update the map
        if (stateService.paramChanged('layers') || stateService.paramChanged('zoom') || force_redraw) {
            var layers = state.layers.split(',');
            var layerAliases = _.pluck(stateConfig.tools.map.layers, 'alias');
            var layersOnMap = _.intersection(_.pluck(stateConfig.tools.map.layers, 'alias'), layers);
            // loop through the pmt layers
            _.each(stateConfig.tools.map.layers, function (layer) {
                // layer is IN state: put it/keep it on the map
                if (_.contains(layers, layer.alias)) {
                    // layer is on the map
                    if (mapService.layers[layer.alias]) {
                        // only remove and redraw if required
                        if (pmtMapService.redraw(layer.alias,
                            mapService.layers[layer.alias].options.boundaryLayer)) {
                            // remove layer
                            mapService.map.removeLayer(mapService.layers[layer.alias]);
                            delete mapService.layers[layer.alias];
                            pmtMapService.removeLayer(layer.alias);
                            // add layer                     
                            pmtMapService.getLayer(layer.alias).then(function (l) {
                                l.alias = layer.alias;
                                mapService.layers[layer.alias] = l;
                                l.addTo(mapService.map);
                            });
                            // redraw pmt clusters
                            // there is a pmt cluster on the map
                            if (mapService.layers.pmtCluster) {
                                // remove layer
                                mapService.map.removeLayer(mapService.layers.pmtCluster);
                                delete mapService.layers.pmtCluster;
                                pmtMapService.removeLayer("pmtCluster");
                                // add layer                     
                                pmtMapService.getLayers(layersOnMap).then(function (l) {
                                    l.alias = "pmtCluster";
                                    mapService.layers.pmtCluster = l;
                                    l.addTo(mapService.map);
                                });
                            }
                            else {
                                // add layer                     
                                pmtMapService.getLayers(layersOnMap).then(function (l) {
                                    l.alias = "pmtCluster";
                                    mapService.layers.pmtCluster = l;
                                    l.addTo(mapService.map);
                                });
                            }
                        }
                    }
                    else {
                        // add layer                     
                        pmtMapService.getLayer(layer.alias).then(function (l) {
                            // ensure the layer is not on the map already
                            // need a secondary check to ensure async calls are not causing
                            // layer duplication                            
                            if (!mapService.layers[layer.alias]) {
                                l.alias = layer.alias;
                                mapService.layers[layer.alias] = l;
                                l.addTo(mapService.map);
                                // redraw pmt clusters
                                // there is a pmt cluster on the map
                                if (mapService.layers.pmtCluster) {
                                    // remove layer
                                    mapService.map.removeLayer(mapService.layers.pmtCluster);
                                    delete mapService.layers.pmtCluster;
                                    pmtMapService.removeLayer("pmtCluster");
                                    // add layer                     
                                    pmtMapService.getLayers(layersOnMap).then(function (l) {
                                        l.alias = "pmtCluster";
                                        mapService.layers.pmtCluster = l;
                                        l.addTo(mapService.map);
                                    });
                                }
                                else {
                                    // add layer                     
                                    pmtMapService.getLayers(layersOnMap).then(function (l) {
                                        l.alias = "pmtCluster";
                                        mapService.layers.pmtCluster = l;
                                        l.addTo(mapService.map);
                                    });
                                }
                            }
                        });
                    }
                }
                // layer is NOT in state: remove it from the map
                else {
                    if (mapService.layers[layer.alias]) {
                        // remove layer
                        mapService.map.removeLayer(mapService.layers[layer.alias]);
                        delete mapService.layers[layer.alias];
                        pmtMapService.removeLayer(layer.alias);
                        // redraw pmt clusters
                        // there is a pmt cluster on the map
                        if (mapService.layers.pmtCluster) {
                            // remove layer
                            mapService.map.removeLayer(mapService.layers.pmtCluster);
                            delete mapService.layers.pmtCluster;
                            pmtMapService.removeLayer("pmtCluster");
                            // add layer back if there are layers to cluster
                            if (layersOnMap.length > 0) {
                                pmtMapService.getLayers(layersOnMap).then(function (l) {
                                    l.alias = "pmtCluster";
                                    mapService.layers.pmtCluster = l;
                                    l.addTo(mapService.map);
                                });
                            }
                        }
                        else {
                            // add layer back if there are layers to cluster
                            if (layersOnMap.length > 0) {
                                pmtMapService.getLayers(layersOnMap).then(function (l) {
                                    l.alias = "pmtCluster";
                                    mapService.layers.pmtCluster = l;
                                    l.addTo(mapService.map);
                                });
                            }
                        }
                    }
                }
            });
            // loop through the contextual layers
            _.each(stateConfig.tools.map.contextual, function (category) {
                _.each(category.layers, function (layer) {
                    // layer is IN state: put it/keep it on the map
                    if (_.contains(layers, layer.alias)) {
                        // layer is NOT on the map
                        if (!mapService.layers[layer.alias]) {
                            drawLayer(layer);
                        }
                        // layer IS on the map
                        else {
                            // only redraw the layer if requested
                            if (force_redraw) {
                                // remove layer
                                mapService.map.removeLayer(mapService.layers[layer.alias]);
                                delete mapService.layers[layer.alias];
                                // add layer back
                                drawLayer(layer);
                            }
                        }
                    }
                    // layer is NOT in state: remove it from the map
                    else {
                        if (mapService.layers[layer.alias]) {
                            // remove layer
                            mapService.map.removeLayer(mapService.layers[layer.alias]);
                            delete mapService.layers[layer.alias];
                        }
                    }
                });
            });
            // loop through the supporting layers
            _.each(stateConfig.tools.map.supportingLayers, function (layer) {
                // layer is IN state: put it/keep it on the map
                if (_.contains(layers, layer.alias)) {
                    // layer is NOT on the map
                    if (!mapService.layers[layer.alias]) {
                        // console.log("mapService: adding " + layer.alias + " to the map");
                        drawLayer(layer);
                    }
                    // layer IS on the map
                    else {
                        // only redraw the layer if requested
                        if (force_redraw) {
                            // console.log("mapService: redrawing " + layer.alias + " on the map");
                            // remove layer
                            mapService.map.removeLayer(mapService.layers[layer.alias]);
                            delete mapService.layers[layer.alias];
                            // add layer back
                            drawLayer(layer);
                        }
                    }
                }
                // layer is NOT in state: remove it from the map
                else {
                    if (mapService.layers[layer.alias]) {
                        // console.log("mapService: removing " + layer.alias + " from the map");
                        // remove layer
                        mapService.map.removeLayer(mapService.layers[layer.alias]);
                        delete mapService.layers[layer.alias];
                    }
                }
            });
            // loop through the pmt boundary layers
            _.each(boundaries, function (layer) {
                // layer is IN state: put it/keep it on the map
                if (_.contains(layers, layer.alias)) {
                    // layer is NOT on the map
                    if (!mapService.layers[layer.alias]) {
                        // console.log("mapService: adding " + layer.alias + " to the map");
                        drawLayer(layer);
                    }
                    // layer IS on the map
                    else {
                        // only redraw the layer if requested
                        if (force_redraw) {
                            // console.log("mapService: redrawing " + layer.alias + " on the map");
                            // remove layer
                            mapService.map.removeLayer(mapService.layers[layer.alias]);
                            delete mapService.layers[layer.alias];
                            // add layer back
                            drawLayer(layer);
                        }
                    }
                }
                // layer is NOT in state: remove it from the map
                else {
                    if (mapService.layers[layer.alias]) {
                        // console.log("mapService: removing " + layer.alias + " from the map");
                        // remove layer
                        mapService.map.removeLayer(mapService.layers[layer.alias]);
                        delete mapService.layers[layer.alias];
                    }
                }
            });
        }
    }

    // draw a layer on the map
    function drawLayer(layer) {
        try {
            var mapLayer = {};
            var url = (layer.requiresToken) ? (layer.url + "?token=" + $rootScope.currentUser.user["ata-token"]) : layer.url;
            switch (layer.type) {
                case "vectortile":
                    var config = {
                        url: url,
                        clickable: [layer.alias]
                    };
                    // if the layer does not have a style parameter, set the defaults
                    if (!_.has(layer, 'style')) {
                        config.style = function (feature) {
                            var style = {};
                            var type = feature.type;
                            switch (type) {
                                case 1://'Point'
                                    style.color = 'rgba(49,79,79,0.5)';
                                    style.radius = scaleDependentPointRadius;
                                    style.lineWidth = 1;
                                    style.strokeStyle = {
                                        "color": "rgb(0,0,0)"
                                    };
                                    style.selected = {
                                        color: 'rgba(49,79,79,0.5)',
                                        radius: scaleDependentPointRadius
                                    };
                                    break;
                                case 2://'LineString'
                                    style.color = 'rgba(161,217,155,0.8)';
                                    style.size = 3;
                                    style.selected = {
                                        color: 'rgba(255,25,0,0.5)',
                                        size: 4
                                    };
                                    break;
                                case 3://'Polygon'
                                    style.color = 'rgba(149,139,255,0.4)';
                                    style.outline = {
                                        color: 'rgb(20,20,20)',
                                        size: 1
                                    };
                                    style.selected = {
                                        color: 'rgba(255,140,0,0.3)',
                                        outline: {
                                            color: 'rgba(255,140,0,1)',
                                            size: 2
                                        }
                                    };
                                    break;
                            }

                            return style;
                        };
                    }
                    else {
                        config.style = function (feature) {
                            var style = {};
                            var type = feature.type;
                            switch (type) {
                                case 1://'Point'
                                    style.color = layer.style.color;
                                    style.radius = scaleDependentPointRadius;
                                    style.lineWidth = layer.style.lineWidth;
                                    style.strokeStyle = layer.style.strokeStyle;
                                    style.selected = layer.style.selected;
                                    break;
                                case 2://'LineString'
                                    style.color = layer.style.color;
                                    style.size = layer.style.size;
                                    style.selected = layer.style.selected;
                                    break;
                                case 3://'Polygon'
                                    style.color = layer.style.color;
                                    style.outline = layer.style.outline;
                                    style.selected = layer.style.selected;
                                    break;
                            }

                            return style;
                        };
                    }
                    // if the layer has a filter parameter add the query
                    if (_.has(layer, 'filter')) {
                        // get the filter's target parameter or set id to the default (id)
                        var filterParam = layer.filterParam || 'id';
                        if (Array.isArray(layer.filter)) {
                            if (layer.filter.length > 0) {
                                config.filter = function (feature, context) {
                                    if (_.contains(layer.filter, feature.properties[filterParam])) {
                                        return true;
                                    }
                                    return false;
                                };
                            }
                        }
                    }
                    // if the layer has a mutexToggle parameter add the setting
                    if (_.has(layer, 'mutexToggle')) {
                        config.mutexToggle = layer.mutexToggle;
                    }
                    // if the layer has a onClick parameter add the setting
                    if (_.has(layer, 'onClick')) {
                        config.onClick = layer.onClick;
                    } else {
                        config.onClick = function (evt) {
                        };
                    }

                    mapLayer = new L.TileLayer.MVTSource(config);

                    mapLayer.on('mousemove', function (e) {
                        //console.log('mouseover:' + e);
                    });

                    break;
                case "mbtile":
                    mapLayer = L.tileLayer(url, {
                        opacity: layer.opacity || 100
                    });
                    break;
                case "tilelayer":
                    mapLayer = L.tileLayer.wms(url, {
                        format: layer.format || 'image/png',
                        transparent: true,
                        opacity: layer.opacity || .80,
                        layers: layer.layers[0]
                    });

                    if (layer.crs != null) {
                        mapLayer.options.crs = L.CRS.EPSG4326;
                    }

                    break;
                default:
                    var url = (layer.requiresToken) ? (layer.url + "?token=" + $rootScope.currentUser.user["ata-token"]) : layer.url;
                    mapLayer = L.esri.dynamicMapLayer(url, {
                        layers: layer.layers || [0],
                        opacity: layer.opacity || 100,
                        format: layer.format || 'image/png'
                    });

                    if (layer.crs != null) {
                        mapLayer.crs = L.CRS.EPSG4326;
                    }

                    if (layer.query != null) {
                        var querydef = {};
                        // query definitions will only apply to first layer
                        querydef[layersArray[0]] = layer.query;
                        mapLayer.setLayerDefs(querydef);
                    }
                    break;

            }
            if (typeof mapService.layers != "undefined") {
                mapService.layers[layer.alias] = mapLayer;
                mapLayer.addTo(mapService.map);
            }
        }
        catch (e) {
            console.log(e);
        }
    }

    // clear the map instance
    function clearInstance() {
        mapService.map = {};
        mapService.basemap = {};
        mapService.layers = {};
        mapService.contextual = {};
        mapService.geojson = {};
    }

    // Adjust the point radius for the zoom level
    var scaleDependentPointRadius = function () {

        //Set point radius based on zoom
        var pointRadius = 1;
        var zoom = parseInt($stateParams.zoom);

        if (zoom >= 2 && zoom <= 3) {
            pointRadius = 2;
        }
        else if (zoom > 3 && zoom <= 5) {
            pointRadius = 3;
        }
        else if (zoom === 6) {
            pointRadius = 5;
        }
        else if (zoom === 7) {
            pointRadius = 7;
        }
        else if (zoom > 7 && zoom <= 8) {
            pointRadius = 9;
        }
        else if (zoom > 8 && zoom <= 9) {
            pointRadius = 11;
        }
        else if (zoom > 9) {
            pointRadius = 14;
        }

        return pointRadius;
    };

    return mapService;

});