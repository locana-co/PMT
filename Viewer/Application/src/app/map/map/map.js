/***************************************************************
 * Map Controller
 * Supports the interactive map tool.
 ***************************************************************/
angular.module('PMTViewer').controller('MapMapCtrl', function ($scope, mapService, stateService, $stateParams) {

    initializeMap();

    // get a full list of contextual and data group layers for instance
    // get data groups
    var instanceLayers = _.pluck($scope.page.tools.map.layers, 'alias');
    // add contextual layers
    _.each($scope.page.tools.map.contextual, function (layerGroup) {
        _.each(layerGroup.layers, function (layer) {
            instanceLayers.push(layer.alias);
        });
    });

    // when toggle is updated cluster points by boundary
    $scope.toggleBoundary = function () {
        try {
            // go through each layer and update boundaryPoints
            _.each($scope.page.tools.map.layers, function (layer) {
                // update the boundary group of each layer
                layer.boundaryPoints = $scope.groupBy.boundaryPoints;

            });
            // get a list of state param layers
            var layers = $stateParams.layers.split(',');
            // if layer if not in list of instance layers (ie is a boundary layer) remove it
            _.each(layers, function (l) {
                if (!_.contains(instanceLayers, l)) {
                    layers = _.without(layers, l);
                }
            });
            // update state layers
            $stateParams.layers = layers.join(',');
            stateService.setState('map', $stateParams, false);
            // redraw map
            mapService.forceRedraw();
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
            var map = L.map('interactive-map', {
                zoomControl: false,
                scrollWheelZoom: false
            });
            // call the map services to initialize the map
            mapService.init(map);
            // be default the left-panel should be open
            stateService.openParam('left-panel');

            // if group by does not match boundaries of layers, toggle Boundary/use other boundary
            if (_.has($scope.page.tools.map, 'toggleBoundaries')) {
                if ($scope.page.tools.map.toggleBoundaries[0].boundaryPoints == $scope.page.tools.map.layers[0].boundaryPoints) {
                    $scope.groupBy = $scope.page.tools.map.toggleBoundaries[0];
                }
                else {
                    $scope.groupBy = $scope.page.tools.map.toggleBoundaries[1];
                }
            }
        }
        // error handler
        catch (ex) {
            // there was an error report it to the error handler
            console.log("There was an error in the tools controller: " + ex);
        }
    }

});