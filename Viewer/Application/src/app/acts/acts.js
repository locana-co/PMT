/***************************************************************
 * Activities Controller
 * Supports the activity page.
 ***************************************************************/
angular.module('PMTViewer').controller('ActsCtrl', function ActsCtrl($scope, config) {
    // get the activity page object
    $scope.page = _.find(config.states, function (state) { return state.route == "activities"; });

    // terminology specification
    $scope.terminology = config.terminology;
});

// all templates used by the activities page:
require('./filter/filter.js');
require('./list/list.js');
require('./top-bar/top-bar.js');
require('./detail/detail.js');