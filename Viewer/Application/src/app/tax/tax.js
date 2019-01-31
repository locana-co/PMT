/***************************************************************
 * Organization Editor Controller
 * Supports the organizational editor module.
 ***************************************************************/
module.exports = angular.module('PMTViewer').controller('TaxCtrl', function ($scope, $rootScope, $mdDialog, config, taxonomyService, blockUI) {
    // get the page object
    $scope.page = _.find(config.states, function (state) { return state.route == "tax"; });
    // terminology specification
    $scope.terminology = config.terminology;
    
    blockUI.stop();
});

// all templates used by the org page:
require('./detail/detail.js');
require('./list/list.js');
require('./top-bar/top-bar.js');
require('./create-tax/create-tax.js');
require('./create-class/create-class.js');