/***************************************************************
 * Export Controller
 * Supports the export modal
 * Allows multiple export options, print pdf & download csv
 * *************************************************************/
angular.module('PMTViewer').controller('MapExportCtrl', function ($scope, $rootScope, $mdDialog, stateService, mapService, pmtMapService, config) {

    // disable download if no activities on map
    $scope.activeDownload = _.keys(pmtMapService.layersPlusClass).length > 0;

    // disable download if no activities on map
    $scope.activeDownload = _.keys(pmtMapService.layersPlusClass).length > 0;

    $scope.downloadCSV = function () {
        $scope.Loading = true;
        var promise = pmtMapService.export();

        promise.then(function(){
                $scope.Loading = false;
            }).catch(function(error){
                $scope.Loading = false;
                $scope.error = error;
            });
    };

    // on click function for close buttons
    $scope.cancel = function () {
        $mdDialog.cancel();
    };

});
