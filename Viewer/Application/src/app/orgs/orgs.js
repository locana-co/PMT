/***************************************************************
 * Organization Editor Controller
 * Supports the organizational editor module.
 ***************************************************************/
module.exports = angular.module('PMTViewer').controller('OrgsCtrl', function ($scope, $rootScope, $mdDialog, config, orgService) {
    // get the page object
    $scope.page = _.find(config.states, function (state) { return state.route == "orgs"; });
    // terminology specification
    $scope.terminology = config.terminology;
    if (typeof $rootScope.currentUser != 'undefined' && $rootScope.currentUser != null) {
        // call the organization service to get the list of organizations
        $scope.orgs = orgService.getAllOrgs();
    }

    // open the create-org modal
    $scope.createOrg = function (event) {
        $mdDialog.show({
            controller: 'UserCreateOrgCtrl',
            templateUrl: 'orgs/create-org/create-org.tpl.html', 
            parent: angular.element(document.body),
            targetEvent: event,
            clickOutsideToClose: true,
            bindToController: true,
            scope: $scope, // pass scope to UserCreateOrgCtrl
            preserveScope: true
        });
    };
});

// all templates used by the org page:
require('./create-org/create-org.js');
require('./list/list.js');
require('./top-bar/top-bar.js');
require('./edit-org/edit-org.js');
