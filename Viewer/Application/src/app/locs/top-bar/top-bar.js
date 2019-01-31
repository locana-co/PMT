/***************************************************************
 * Locations Top Bar Controller
 * Supports the top bar for the locations page. 
 ***************************************************************/ 
angular.module('PMTViewer').controller('LocsTopBarCtrl', function ($scope, $rootScope, $stateParams, locsService) {
    // set defaults
    $scope.title = 'Investment Summary';
    $scope.menu = _.pluck($scope.page.tools.map.countries, "_name");
    //if only one county, init there, otherwise start at world
    if ($scope.menu.length <= 1) {
        $scope.selectedOption = $scope.menu[0];
        $scope.area = 'National';
    }
    else {
        $scope.selectedOption = 'World';
        $scope.area = 'World';
    }

    //display title for summary charts
    var areaHash = {
        'world' : 'World',
        'national': 'National',
        'regional': 'Regional'
    };

    // when the selection is updated, do this
    $scope.$on('selection-update', function () {
        if ($stateParams.area == 'world') {
            $scope.selectedOption = 'World';
        }
        else {
            if (locsService.selectedNationalFeature) {
                $scope.selectedOption = _.find($scope.menu, function (m) { return m == locsService.selectedNationalFeature._name; });
            }
        }
        //update title
        $scope.area = areaHash[$stateParams.area];
    });
    
    // menu option selected
    $scope.menuOptionSelected = function (option) {
        if (option == 'World') {
            // call the locations module service to set map back to world
            locsService.setAreaToWorld();
        }
        else {
            // call the locations module service to select country
            locsService.selectCountry(null, option);
        }
    };

});