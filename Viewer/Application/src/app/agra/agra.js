module.exports = angular.module('PMTViewer').controller('AgraCtrl', function AgraCtrl($scope, $rootScope, stateService, config, global) {
    // get the page object
    $scope.page = _.find(config.states, function (state) { return state.route == "agra"; });
    stateService.setState("agra", {}, true);
    // terminology specification
    $scope.terminology = config.terminology;
});

// all templates used by the page:
require('./detail/detail.js');
require('./integrator/integrator.js');
require('./top-bar/top-bar.js');