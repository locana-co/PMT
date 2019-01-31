/***************************************************************
 * Basemap Menu Controller
 * Supports the basemap menu feature.
* *************************************************************/ 
angular.module('PMTViewer').controller('MapBasemapCtrl', function ($scope, $state, $stateParams, stateService, global) {
    $scope.stateService = stateService;
    $scope.basemaps = global.basemaps;
    
    $scope.onOptionSelected = function (alias) {
        try {
            if ($stateParams.basemap !== '') {
                if ($stateParams.basemap != alias) {
                    $stateParams.basemap = alias;
                }
            }            
            // update parameters        
            stateService.setState($state.current.name || 'home', $stateParams, false);
            // close menu
            stateService.closeParam('basemap-menu');
        }
        // error handler
        catch (ex) {
            // there was an error report it to the error handler
            console.log(ex);
        }
    };
});