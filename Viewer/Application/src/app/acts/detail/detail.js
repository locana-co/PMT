/***************************************************************
 * Activity Detail Controller
 * Supports the activity controller and displays data for a single activity.
 * *************************************************************/
angular.module('PMTViewer').controller('ActsDetailCtrl', function ($scope, $q, $rootScope, stateService, activityService, config, mapService, pmtMapService) {

    $scope.stateService = stateService;
    //loader
    $scope.loading = false;
    //map loader
    $scope.mapLoading = false;
    // details object for active detail
    $scope.selectedActivity = {};
    //setup config for display beneficiary info (if activity has it)
    $scope.beneficiaryConfig = _.chain(config.states).where({ route: 'editor' }).pluck("tools").pluck("editor").pluck("activity").pluck("beneficiary").first().value();
    //has map been initialized
    var initialized = false;
    // tab config
    $scope.tabConfig = $scope.page.tools.map.params.tabs.financials;

    //initialize map for details
    initializeMap();

    //set activity
    setActivity();

    // when the url is updated do this
    $scope.$on('activity_id-update', function () {
        if (initialized) {
            setActivity();
        } else {
            initializeMap().then(function () { setActivity(); });
        }
    });

    //show child activity
    $scope.showChildActivity = function (activity, parent_id) {
        stateService.setParamWithVal('activity_id', activity.id.toString());

        //update activity stored in activity Service
        var a = {
            id: activity.id,
            pid: parent_id,
            title: activity._title
        };
        activityService.setSelectedActivity(a);

    };

    //start the map (make sure the DOM is ready by allowing this request multiple times with a promise)
    function initializeMap() {
        var deferred = $q.defer();

        try {
            // create the map control
            var map = L.map('acts-map', {
                zoomControl: false,
                maxZoom: 8
            });

            // disable drag and zoom handlers
            map.dragging.disable();
            map.touchZoom.disable();
            map.doubleClickZoom.disable();
            map.scrollWheelZoom.disable();
            map.keyboard.disable();

            // call the map services to initialize the map
            mapService.init(map);
            mapService.setCursor('default');

            initialized = true;
            deferred.resolve();
        } catch (ex) {  // error handler
            // there was an error report it to the error handler
            deferred.reject();
            console.log("There was an error in the detail controller: " + ex);
        }

        return deferred.promise;


    }

    //private function to grab activity from url and set page to details
    function setActivity() {
        if (stateService.isParam('activity_id')) {

            //activity id
            if (!isNaN(parseInt(stateService.states.activities.activity_id, 10))) {
                var act_id = parseInt(stateService.states.activities.activity_id, 10);
                //loader
                $scope.loading = true;
                //map loader
                $scope.mapLoading = true;
                // set flag inactive
                $scope.showNationalFlag = false;
                // set sub-national flag
                $scope.subNationallocationData = false;

                // get detail details
                activityService.getDetail(act_id).then(function (d) {
                    //if valid activity
                    if (d.length > 0) {
                        $scope.selectedActivity = d[0].response;
                        $scope.selectedActivity.childrenMapped = false; //help with when to load map
                        $scope.selectedActivity.childLocations = []; //used to show the location names in the location tab

                        //update activity stored in activity Service
                        var a = {
                            id: $scope.selectedActivity.id,
                            pid: $scope.selectedActivity.parent_id,
                            title: $scope.selectedActivity._title
                        };
                        activityService.setSelectedActivity(a);

                        //only perform extra child logic if active for project
                        if ($scope.page.mergeRelatedActivities) {
                            //create counts to know when all children have been received
                            $scope.selectedActivity.childrenLoadedMax = $scope.selectedActivity.children ? $scope.selectedActivity.children.length : null;
                            $scope.selectedActivity.childrenCount = 0;
                            $scope.selectedActivity.childrenMappedMax = $scope.selectedActivity.children ? $scope.selectedActivity.children.length : null;
                            $scope.selectedActivity.childrenMappedCount = 0;
                            $scope.selectedActivity.childrenTaxonomyCount = 0;
                            $scope.selectedActivity.childrenOrganizationCount = 0;
                            //if project has children, get each child's data
                            _($scope.selectedActivity.children).each(function (child) {
                                getChildActivity(child.id);
                            });
                        }

                        // process data for each UI activity details tabs
                        $scope.selectedActivity.overviewDetails = activityService.processOverview($scope.selectedActivity);
                        $scope.selectedActivity.taxonomyDetails = activityService.processTaxonomies($scope.selectedActivity.taxonomy);
                        $scope.selectedActivity.financialsDetails = activityService.processFinancials($scope.selectedActivity.financials);
                        $scope.selectedActivity.locationDetails = activityService.processLocations($scope.selectedActivity.locations);
                        $scope.selectedActivity.organizationDetails = activityService.processOrganizations($scope.selectedActivity.organizations);

                        // check to see if at least one location has sub national data
                        _.each($scope.selectedActivity.locationDetails, function (l) {
                            if (l.admin1 || l.admin2 || l.admin3) {
                                $scope.subNationallocationData = true;
                            }
                            // if the activity contains a country level location it is a national project
                            if(l.admin1 == null && l.admin2 == null  && l.admin3 == null ){
                                $scope.showNationalFlag = true;
                            }
                        });

                        // add locations to map
                        if ($scope.selectedActivity.location_ids) {
                            var location_ids = $scope.selectedActivity.location_ids.join(',');
                            mapService.clearGeojson();
                            pmtMapService.getLocations(location_ids).then(function (locations) {
                                _.each(locations, function (location) {
                                    //get the admin level
                                    var adminLevel = location.response._admin_level ? 'admin' + location.response._admin_level : null;


                                    if (location.response.polygon !== null) {
                                        mapService.addGeojson(JSON.parse(location.response.polygon), adminLevel);
                                    }
                                    else {
                                        if (location.response.point !== null) {
                                            mapService.addGeojson(JSON.parse(location.response.point));
                                        }
                                    }
                                });
                                //wait for UI to be ready for bounds
                                _.defer(function () {
                                    var bounds = mapService.geojson.getBounds();
                                    if (bounds) {
                                        mapService.map.fitBounds(bounds);
                                    }
                                });
                                $scope.mapLoading = false;
                            });
                        }
                        else {
                            mapService.clearGeojson();
                            //set mapview to world
                            mapService.map.fitWorld();
                            //end loader
                            $scope.mapLoading = false;
                        }

                        // check details
                        if($scope.selectedActivity.details){
                            var financial_details = [];
                            _.each($scope.selectedActivity.details, function(detail){
                                if(detail._amount){
                                    try{
                                        detail.total = $scope.selectedActivity.overviewDetails.total_amount * (detail._amount/100);
                                    } 
                                    catch(ex){
                                        detail.total = 0;
                                    }
                                    financial_details.push(detail);
                                }
                            });
                            if(financial_details.length>0){
                                $scope.selectedActivity.detailsFinancial = financial_details;
                            }
                        }
                    }
                    else {
                        //update page title
                        activityService.setActivityTitle('No activity found');
                        mapService.clearGeojson();
                        //set mapview to world
                        mapService.map.fitWorld();
                    }
                    // notify listeners that the activity detail is updated
                    $rootScope.$broadcast('activity-detail-updated');
                    //deactivate the loader
                    $scope.loading = false;
                });
            }
        }
    }

    function getChildActivity(id) {
        //check to see if sub activity data has been requested
        $scope.loading = true;
        // get detail details
        activityService.getDetail(id).then(function (d) {

            var child = _($scope.selectedActivity.children).find({ id: id });
            //if valid activity
            if (d.length > 0) {
                child.selectedActivity = d[0].response;

                // process data for each UI activity details tabs
                child.selectedActivity.overviewDetails = activityService.processOverview(child.selectedActivity);
                child.selectedActivity.taxonomyDetails = activityService.processTaxonomies(child.selectedActivity.taxonomy);
                child.selectedActivity.financialsDetails = activityService.processFinancials(child.selectedActivity.financials);
                child.selectedActivity.locationDetails = activityService.processLocations(child.selectedActivity.locations);
                child.selectedActivity.organizationDetails = activityService.processOrganizations(child.selectedActivity.organizations);

                //check to see if at least one location has sub national data
                _.each(child.selectedActivity.locationDetails, function (l) {
                    if (l.admin1 || l.admin2 || l.admin3) {
                        $scope.subNationallocationData = true;
                    }
                });

                // add locations to map
                if (child.selectedActivity.location_ids) {
                    $scope.mapLoading = true;
                    var location_ids = child.selectedActivity.location_ids.join(',');

                    pmtMapService.getLocations(location_ids).then(function (locations) {
                        _.each(locations, function (location) {
                            //get the admin level
                            var adminLevel = location.response._admin_level ? 'admin' + location.response._admin_level : null;

                            if (location.response.polygon !== null) {
                                mapService.addGeojson(JSON.parse(location.response.polygon), adminLevel);
                            }
                            else {
                                if (location.response.point !== null) {
                                    mapService.addGeojson(JSON.parse(location.response.point));
                                }
                            }
                        });
                        $scope.selectedActivity.childrenMappedCount += 1;
                        if ($scope.selectedActivity.childrenMappedMax === $scope.selectedActivity.childrenMappedCount) {
                            //wait for map to paint before trying to set bounds
                            _.defer(function () {
                                var bounds = mapService.geojson.getBounds();
                                if (bounds) {
                                    mapService.map.fitBounds(bounds);
                                }
                            });
                            $scope.mapLoading = false;
                            $scope.selectedActivity.childLocations = _.chain($scope.selectedActivity.children).pluck('selectedActivity').pluck('locationDetails').flatten().value();
                            $scope.selectedActivity.childrenMapped = true;
                        }
                    });
                }
                else {
                    mapService.clearGeojson();
                    //set mapview to world
                    mapService.map.fitWorld();
                    //end loader
                    $scope.mapLoading = false;
                }
            }
            $scope.selectedActivity.childrenOrganizationCount += child.selectedActivity.organizationDetails.organizationCount;
            $scope.selectedActivity.childrenTaxonomyCount += child.selectedActivity.taxonomyDetails.taxonomyCount;
            $scope.selectedActivity.childrenCount += 1;
            if ($scope.selectedActivity.childrenLoadedMax === $scope.selectedActivity.childrenCount) {
                //deactivate the loader once all requests are complete
                $scope.loading = false;
                $scope.selectedActivity.childrenLoaded = true;
            }
        });

    }

});

// custom filter for adding elipses to long strings
angular.module('PMTViewer').filter('cut', function () {
    return function (value, wordwise, max, tail) {
        if (!value) { return ''; }

        max = parseInt(max, 10);
        if (!max) { return value; }
        if (value.length <= max) { return value; }

        value = value.substr(0, max);
        if (wordwise) {
            var lastspace = value.lastIndexOf(' ');
            if (lastspace != -1) {
                //Also remove . and , so its gives a cleaner result.
                if (value.charAt(lastspace - 1) == '.' || value.charAt(lastspace - 1) == ',') {
                    lastspace = lastspace - 1;
                }
                value = value.substr(0, lastspace);
            }
        }
        return value + (tail || ' …');
    };
});


// custom filter for adding elipses to long strings
angular.module('PMTViewer').filter('filterDetailOrgs', function () {
    return function (value) {
        if (!value) { return '--'; }
        //identify number of funders
        var funderCount = value.length;

        if (funderCount > 1) {
            return 'Multiple Funders';
        }
        else if (funderCount === 0) {
            return 'No Information';
        }
        else {
            return value[0].organization;
        }
    };
});

// all templates used by the details:
require('./locations/locations-national.js');
require('../children/details/details.js');
require('../children/organization/organization.js');
require('../children/taxonomy/taxonomy.js');