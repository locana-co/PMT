/***************************************************************
 * Legend Controller
 * Supports the legend feature. Users can the legend
 * to understand map layers.
 * *************************************************************/
angular.module('PMTViewer').controller('MapLegendCtrl', function ($scope, $rootScope, pmtMapService, stateService, $stateParams) {
    $scope.stateService = stateService;
    $scope.legendOpen = false;
    // assign the contextual object
    $scope.categories = $scope.page.tools.map.contextual;
    //grab boundary legend from config
    $scope.boundaryLegend = $scope.page.tools.map.activityClusterLegend;

    //check whether layers are selected when controller loads
    checkContextLayersSelected();

    // when the selected context layer changes, update legend
    $scope.$on('layers-update', function () {
        checkContextLayersSelected();
    });
                 
    //function to toggle opening/closing of legend
    $scope.toggleLengend = function () {
        $scope.legendOpen = !$scope.legendOpen;
    };
    
    // function to check whether any context layers are selected
    function checkContextLayersSelected() {
        $scope.contextLayersSelected = false;
        //check if any layers are active
        $scope.categories.forEach(function (category) {
            category.layers.forEach(function (layer) {
                if (layer.active === true) {
                    return ($scope.contextLayersSelected = true);
                }
            });
        });

        //find all data groups on the map
        var dataGroupLayers = Object.keys(pmtMapService.layers);
        //grab all layers in state params
        var stateParamLayers = $stateParams.layers.split(',');
        //remove data group from state params
        $scope.showActivityClusters = false;
        _.each(dataGroupLayers, function(l) {
           if (_.contains(stateParamLayers, l)) {
               $scope.showActivityClusters = true;
           }
        });
    }
     
});