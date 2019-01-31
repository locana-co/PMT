/***************************************************************
 * Locations Leaflet Controller
 * Supports the location page's map feature
 ***************************************************************/
angular.module('PMTViewer').controller('LocsMapCtrl', function ($stateParams, $scope, locsService, mapService, config) {

    initializeMap();

    // when the area is updated, do this
    $scope.$on('selection-update', function () {
        // get country name
        var country = locsService.selectedNationalFeature;
        if ($scope.page.tools.map.params["summary-widget"]) {
            $scope.details = $scope.page.tools.map.params["summary-widget"][country._name];
            $scope.mapShrink = ($scope.page.mapSummary && $stateParams.area !== "world" && typeof $scope.details !== "undefined" && $scope.details !== null);
        }
    });

    // when toggle is updated cluster points by boundary
    $scope.toggleBoundary = function () {
        try {
            // update the boundary group for map
            $scope.page.tools.map.boundaryGroup = $scope.activeBoundaryGroup.boundaryGroup;
            // tell the locsService to toggle boundary
            locsService.updateBoundaries();
        }
        // error handler
        catch (ex) {
            // there was an error report it to the error handler
            console.log(ex);
        }
    };

    // function for all initialization processes
    function initializeMap() {
        try {

            // create the map control
            var map = L.map('locs-map', {
                zoomControl: false
            });

            // disable drag and zoom handlers
            map.dragging.disable();
            map.touchZoom.disable();
            map.doubleClickZoom.disable();
            map.scrollWheelZoom.disable();
            map.keyboard.disable();

            // call the map services to initialize the map
            mapService.init(map);

            // set the default boundary if the toggle boundary feature is configured
            if (_.has($scope.page.tools.map, 'toggleBoundaries')) {
                $scope.activeBoundaryGroup = _.find($scope.page.tools.map.toggleBoundaries, function (b) { return b.boundaryGroup == $scope.page.tools.map.boundaryGroup; });
            }
        }
        // error handler
        catch (ex) {
            // there was an error report it to the error handler
            console.log("There was an error in the map controller: " + ex);
        }
    }

});

// all templates used by the map:
require('./map-bar/map-bar.js');
require('./map-summary/map-summary.js');