/***************************************************************
 * Organization Controller
 * A filter controller.
 * *************************************************************/
angular.module('PMTViewer').controller('PLFilterOrganizationCtrl', function ($scope, $rootScope, partnerLinkService) {
    $scope.loadingOrgs = true;
    
    // when the partnerlink sankey is updating, do this
    $scope.$on('partnerlink-sankey-updating', function (event, data) {
        $scope.loadingOrgs = true;
    });
    
    // when the partnerlink sankey is updated, do this
    $scope.$on('partnerlink-sankey-updated', function (event, data) {
        // get the organizations from the partnerlink service
        $scope.options = partnerLinkService.organizations;
        // add size property (num of items) to parent scope
        _.extend($scope.filter, { size: $scope.options.length });
        // turn off loading
        $scope.loadingOrgs = false;
    });

    // the orgs have changed
    $scope.optionClicked = function (option) {
        try {
            if (option.active) {
                partnerLinkService.setOrgId(option.id);
            } else {
                partnerLinkService.removeOrgId(option.id);
            }
        }
        // error handler
        catch (ex) {
            // there was an error report it to the error handler
            console.log(ex);
        }
    };
 
});
