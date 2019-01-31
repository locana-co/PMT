/***************************************************************
 * Locations Controller
 * Supports the location page.
 ***************************************************************/
angular.module('PMTViewer').controller('LocsCtrl', function LocsCtrl($scope, $state, $stateParams, config, locsService) {
    // get the location page object
    $scope.page = _.find(config.states, function (state) { return state.route == "locations"; });

    // terminology specification
    $scope.terminology = config.terminology;

    // initialze the locsService
    if ($state.current.name === 'locations') {
        // initialize the locations module
        locsService.init();
    }

});

// all templates used by the locations page:
require('./map/map.js');
require('./mid-bar/mid-bar.js');
require('./top-bar/top-bar.js');
require('./filter/filter.js');
require('./widget/widget.js');