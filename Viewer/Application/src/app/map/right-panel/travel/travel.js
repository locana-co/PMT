/***************************************************************
 * Travel Time Analysis Tool
 * Supports the travel time analysis tool.
 ***************************************************************/
angular.module('PMTViewer').controller('MapTravelCtrl', function ($scope, $rootScope, $mdSelect, stateService, otpService, mapService, hcService, pmtMapService) {
    
    var tax1_id = $scope.page.tools.map.travel.taxonomy;
    var tax2_id = $scope.page.tools.map.travel.subtaxonomy;
    var boundary = $scope.page.tools.map.travel.countries;
    var intervals = [2, 4, 6, 8];
    var featureLayer = L.geoJson().addTo(mapService.map);
    var marker = {};
    var geometries = {};
    
    // walkspeed (km/hr)
    var walkspeed = 4;

    $scope.showInvestmentData = $scope.page.tools.map.travel.showInvestmentData;
    $scope.activeCategory = null;
    $scope.button = false;
    $scope.errorMessage = false;
    $scope.showSummary = false;
    $scope.loadingMessage = false;
    $scope.intervalTab = 0;
    $scope.boundaries = { country: 'Ethiopia', region: 'Addis Ababa', district: 'Addis Ababa' };
    $scope.travelModes = [{ label: 'Walking', param: 'WALK' }, { label: 'Donkey Cart', param: 'WALK' } /*, { label: 'Driving', param: 'WALK' }*/];
    $scope.selectedMode = { label: 'Walking', param: 'WALK' };
    $scope.summaryCategories = [{ title: 'investments', label: 'Investments' }, { title: 'agStats', label: 'Agricultural Statistics' }];
    
    // when the url is updated do this
    $scope.$on('route-update', function () {
        
        // if travel-panel is not a state param, disable travel tool
        if (!stateService.isParam('travel-panel')) {
            $scope.disable();
        }
    });

    //when the filter is updated, if enabled update activity list
    $scope.$on('pmt-filter-update', function() {
        if ($scope.button === true && geometries) {
            $scope.loadingMessage = true;
            summarizeData(geometries);
        }
    });

    //when the layer filter is updated, if enabled update activity list
    $scope.$on('pmt-layers-update', function() {
        if ($scope.button === true && geometries) {
            $scope.loadingMessage = true;
            summarizeData(geometries);
        }
    });
    
    // select mode of travel
    $scope.selectMode = function (mode) {
        $scope.selectedMode = mode;

    };
    
    // toggle button on and off
    $scope.toggleButton = function () {
        if ($scope.button === true) {
            
            // turn on cursor pin
            mapService.setCursor('pin');
        }
        else {
            $scope.disable();
        }
    };
    
    // disable travel tool
    $scope.disable = function () {

        if ($scope.button === true) {
            $scope.button = false;
        }

        // turn off cursor pin
        mapService.setCursor('default');
        
        // close dropdown menu
        $mdSelect.hide();

        $scope.errorMessage = false;
        $scope.showSummary = false;
        mapService.map.removeLayer(featureLayer);
        mapService.map.removeLayer(marker);
    };
    
    // calculate euclidean distance buffer
    function euclBuffer(coords) {
        var buffers = {
            type: 'FeatureCollection',
            features: []
        };
        
        // user's clicked location
        var pt = {
            "type": "Feature",
            "properties": {},
            "geometry": {
                "type": "Point",
                "coordinates": [coords[1], coords[0]]
            }
        };
        
        // draw on map in reverse order
        var reverseInt = [8, 6, 4, 2];
        
        // create buffer geojson with travel time property
        reverseInt.forEach(function (el) {
            var buffer = turf.buffer(pt, el * 4, 'kilometers');
            
            // convert buffer distance to travel time (sec)
            buffer.features[0].properties.time = el * 3600;
            
            buffers.features.push(buffer.features[0]);
        });
        
        // add polygons to map
        featureLayer = L.geoJson(buffers.features.reverse(), { style: otpService.getStyle }).addTo(mapService.map);
        
        // zoom to the polygons extent
        mapService.map.fitBounds(featureLayer.getBounds(), {
            paddingBottomRight: [500, 0]
        });
        
        // summarize data for each buffer
        geometries = buffers;
        summarizeData(buffers);
    }
    
    // translate abbrv. crop names and AEZ names
    function translate(result) {
        result.forEach(function (el) {
            el.name = hcService.getCropDictionary(el.name);
        });
    }
    
    // open dropdown when menu item is clicked
    $scope.selectMenuItem = function (cat) {
        
        $scope.summaryCategories.forEach(function (el) {
            if (el === cat) {
                $scope.activeCategory = cat;
            }
        });
        
        $scope.expandDropdown = true;
        return cat;
    };
    
    // summarize data within polygons
    function summarizeData(polygons) {
        
        $scope.summaryData = [];
        
        // collect summary data in one array
        for (var i = 0; i < 4; i++) {
            $scope.summaryData[i] = {
                'investments': {
                    'activityCount': 0,
                    'tax1ActivityCount': [],
                    'tax2ActivityCount': [],
                    'implPartnerActivityCount': [],
                    'donorActivityCount': []
                },
                'agStats': {
                    'aezs': [],
                    'farmSys': [],
                    'cropYield': [],
                    'cropProd': [],
                    'cropHarvArea': []
                }
            };
        }
        
        // get summary data for each polygon
        polygons.features.forEach(function (iso, index) {
            
            // convert geoJSON multipolygons to geoJSON single polygons
            var singlePolys = hcService.multiPolyToSingle(iso);
            
            //convert polygons to wkt
            var wkt = hcService.geojsonToWKT(singlePolys[0]);
            
            // get harvest choice AEZ data
            hcService.getAEZs(wkt)
                .then(function (result) {
                
                // translate abbrv. AEZ name
                result.forEach(function (el) {
                    hcService.aezDictionary.forEach(function (e) {
                        if (e.abbrv === el.AEZ8_CLAS) {
                            el.AEZ8_CLAS = e.label;
                        }
                    });
                });
                
                $scope.summaryData[index].agStats.aezs.push(result);
            });
            
            // get harvest choice crop yield (kg/ha) data
            hcService.getCropYield(wkt)
                .then(function (result) {
                var count = 0;
                
                // count results
                result.forEach(function (el) {
                    count += el.value;
                });
                
                if (count > 1) {
                    // translate abbrv. crop names
                    translate(result);
                    
                    $scope.summaryData[index].agStats.cropYield.push(result);
                }
            });
            
            // get harvest choice crop yield (mt) data
            hcService.getCropProd(wkt)
                .then(function (result) {
                var count = 0;
                
                // count results
                result.forEach(function (el) {
                    count += el.value;
                });
                
                if (count > 1) {
                    
                    // translate abbrv. crop names
                    translate(result);
                    
                    $scope.summaryData[index].agStats.cropProd.push(result);
                }
            });
            
            // get harvest choice harvested area (ha) data
            hcService.getHarvArea(wkt)
                .then(function (result) {
                var count = 0;
                
                // count results
                result.forEach(function (el) {
                    count += el.value;
                });
                
                if (count > 1) {
                    
                    // translate abbrv. crop names
                    translate(result);
                    
                    $scope.summaryData[index].agStats.cropHarvArea.push(result);
                }
            });
            
            // get activity_id's within wkt polygon
            pmtMapService.getActivitiesByPoly(wkt)
                .then(function (result) {
                
                if (result[0].response.activity_ids !== null) {
                    var activity_ids = result[0].response.activity_ids.toString();
                    
                    // count activities within wkt polygon
                    $scope.summaryData[index].investments.activityCount = result[0].response.activity_ids.length;
                    
                    // count activity_id's by taxonomy 1 (ex. initiative)
                    pmtMapService.getActivityCountByTax(tax1_id, activity_ids)
                            .then(function (result) {
                        
                        if (result.length !== 0) {
                            result.forEach(function (el) {
                                $scope.summaryData[index].investments.tax1ActivityCount.push(el.response);
                            });
                        }
                    });
                    
                    // count activity_id's by taxonomy 2 (ex. sub-initiative)
                    pmtMapService.getActivityCountByTax(tax2_id, activity_ids)
                            .then(function (result) {
                        
                        if (result.length !== 0) {
                            result.forEach(function (el) {
                                $scope.summaryData[index].investments.tax2ActivityCount.push(el.response);

                            });
                        }
                    });
                    
                    // count activity_id's by implementing partner
                    pmtMapService.getActivityCountByOrg(497, activity_ids)
                            .then(function (result) {
                        
                        if (result.length !== 0 && result[0].response.organizations !== null) {
                            $scope.summaryData[index].investments.implPartnerActivityCount.push(result[0].response);
                        }
                    });
                    
                    // count activity_id's by donor
                    pmtMapService.getActivityCountByOrg(496, activity_ids)
                            .then(function (result) {
                        
                        if (result.length !== 0 && result[0].response.organizations !== null) {
                            $scope.summaryData[index].investments.donorActivityCount.push(result[0].response);
                        }
                    });
                }
            });
        });
        $scope.loadingMessage = false;
        $scope.showSummary = true;
    }

    //when the filter is updated, if enabled update activity list
    $scope.$on('pmt-filter-update', function() {
        if ($scope.button === true && geometries) {
            $scope.loadingMessage = true;
            summarizeData(geometries);
        }
    });

    
    // when map is clicked, calculate polygons
    mapService.map.on('click', function (event) {
        
        if ($scope.button === true) {
            
            var clickedLocation = [event.latlng.lat, event.latlng.lng];
            var wktPoint = 'POINT (' + String(clickedLocation[1]) + ' ' + String(clickedLocation[0]) + ')';
            
            $scope.errorMessage = false;
            $scope.loadingMessage = true;
            $scope.showSummary = false;
            mapService.map.removeLayer(featureLayer);
            mapService.map.removeLayer(marker);
            
            // add marker to user's clicked location
            marker = L.marker(event.latlng).addTo(mapService.map);
            
            pmtMapService.getBoundariesByPoint(wktPoint)
            .then(function (result) {
                
                // get country name for user's clicked location
                result[0].response.forEach(function (el) {
                    if (el.boundary_name == boundary) {
                        $scope.boundaries.country = el.feature_name;
                    }
                });
            });
            
            // set speed of donkey cart
            if ($scope.selectedMode.label == 'Donkey Cart') {
                walkspeed = 5.6327;
            }
            
            // calculate isochrones and draw polygons on map
            otpService.getIsochrones($scope.boundaries.country, clickedLocation, $scope.selectedMode.param, walkspeed, intervals)
                .then(function (isochrones) {

                    geometries = isochrones;
                
                    // add polygons to map
                    featureLayer = L.geoJson(geometries.features.reverse(), { style: otpService.getStyle }).addTo(mapService.map);

                    // zoom to the polygons extent
                    mapService.map.fitBounds(featureLayer.getBounds(), {
                        paddingBottomRight: [500, 0]
                    });

                    summarizeData(geometries);

            }, function (error) {
                $scope.errorMessage = true;
                
                euclBuffer(clickedLocation);
            });
        }
    });
});