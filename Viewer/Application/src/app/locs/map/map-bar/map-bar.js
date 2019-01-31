/***************************************************************
 * Locations Map Bar Controller
 * Supports the map bar for the map on the locations page. 
 ***************************************************************/
angular.module('PMTViewer').controller('LocsMapBarCtrl', function ($scope, $rootScope, $stateParams, locsService, config) {
    $scope.breadcrumbs = [];
    $scope.menu = [];
    $scope.selectedOption = "";
    $scope.stateParams = $stateParams;

    // get the location page object
    $scope.countryCount = $scope.page.tools.map.countries.length;

    // when the selection is updated, do this
    $scope.$on('selection-update', function () {
        updateMapBar();
    });

    // when the layers are updated, do this
    $scope.$on('layers-update', function () {
        updateMapBar();
    });

    // clicked world in breadcrumb list
    $scope.setAreaToWorld = function () {
        locsService.setAreaToWorld();
    };

    // clicked a breadcrumb, which currently can only be a national feature
    $scope.clickedBreadcrumb = function (featureName) {
        // call the locations module service to select country
        locsService.selectCountry(null, featureName);
    };

    // menu option selected
    $scope.menuOptionSelected = function (option) {
        // call the locations module service to select region
        locsService.regionSelected(null, option);
    };

    // update the breadcrumbs and drop-down menu
    function updateMapBar() {
        // get a list of names from the regional features
        var regionNames = _.pluck(locsService.regionalFeatures, "_name");
        switch ($stateParams.area) {
            case 'national':
                var national = locsService.getNationalFeatureName($stateParams.selection);
                locsService.setRegionalFeatures(national, function () {
                    regionNames = _.pluck(locsService.regionalFeatures, "_name");
                    $scope.menu = regionNames;
                });
                $scope.breadcrumbs = [];
                $scope.breadcrumbs.push(national);
                $scope.selectedOption = "";
                break;
            case 'regional':
                var regional = locsService.getRegionalFeatureName($stateParams.selection);
                // if breadcrumbs has a regional name, replace
                if ($scope.breadcrumbs.length === 2) {
                    $scope.breadcrumbs.pop();
                }
                $scope.breadcrumbs.push(regional);
                $scope.menu = regionNames;
                $scope.selectedOption = _.find($scope.menu, function (m) { return m == locsService.selectedRegionalFeature._name; });
                break;
            default:
                $scope.breadcrumbs = [];
                $scope.menu = [];
                $scope.selectedOption = "";
                break;
        }
    }

});

//custom filter for adding elipses to long strings
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