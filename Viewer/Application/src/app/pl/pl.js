/***************************************************************
 * Partnerlink Controller
 * Supports the partnerlink page.
 ***************************************************************/ 
angular.module('PMTViewer').controller('PLCtrl', function ($scope, config, stateService) {
    // get the explorer page object
    $scope.page = _.find(config.states, function (state) { return state.route == "partnerlink"; });

    //terminology specification
    $scope.terminology = config.terminology;
});

// all templates used by the partnerlink page:
require('./sankey/sankey.js');
require('./filter/filter.js');