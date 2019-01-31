/***************************************************************
 * Top Bar Controller
 * Supports the top bar feature.
* *************************************************************/ 
module.exports = angular.module('PMTViewer').controller('MapTopBarCtrl', function ($scope, $rootScope, config, mapService, pmtMapService, $mdDialog, stateService) {
    $scope.regions = null;
    $scope.selectedRegion = null;
    $scope.showSearchInputBox = false;
    $scope.stateService = stateService;
    $scope.activityCountUpdating = false;
    $scope.loading = true;
    // whether or not to show clusters
    $scope.showClusters = true;
    
    if ($scope.page.tools.map.regions) {
        // get the region feature collection from the configuration
        $scope.regions = $scope.page.tools.map.regions;
        // set the first feature as the current selected region
        $scope.selectedRegion = $scope.regions.features[0];
    }
    
    $scope.activityCount = pmtMapService.activityCount;
    
    // when the activity count is updating do this
    $scope.$on('activity-count-updating', function () {
        $scope.activityCountUpdating = true;
    });
    
    // when the activity count is updated do this
    $scope.$on('activity-count-update', function () {
        $scope.activityCount = pmtMapService.activityCount;
        $scope.activityCountUpdating = false;
    });

    // open the export modal
    $scope.openExportModal = function (event) {
        $mdDialog.show({
            controller: 'MapExportCtrl',
            templateUrl: 'map/top-bar/export/export.tpl.html',
            parent: angular.element(document.body),
            clickOutsideToClose: true,
            targetEvent: event,
            bindToController: true
        });
    };

    // toggle the activity clusters on/off the map
    $scope.togglePointClusters = function() {
        pmtMapService.togglePointClusters(!$scope.showClusters);
    };

});

// all templates used by the top bar page:
require('./export/export.js');
