module.exports = angular.module('PMTViewer').controller('AdminOrgSelectorCtrl', function ($scope, $rootScope, $mdDialog, userService) {
    
    $scope.LoadingOrgs = true;
    $scope.moreOrgs = false;

    // get bound data from mdDialog
    if (this.locals) {
        $scope.activeUser = this.locals.activeUser;
        $scope.originalOrg_id = this.locals.activeUser.organization_id;
    }

    if (typeof $rootScope.currentUser != 'undefined' && $rootScope.currentUser != null) {
        // call the user service to get a list of all the orgs
        userService.getCommonOrgs().then(function (orgs) {
            $scope.commonOrgs = _.sortBy(orgs, '_name');
            $scope.LoadingOrgs = false;
        });
    }

    // load all organizations
    $scope.getOrgs = function() {
        $scope.LoadingOrgs = true;
        $scope.moreOrgs = true;

        // get an array of common org ids
        var commonOrgIds = _.map($scope.commonOrgs, function(val) {
            return val.id;
        });

        userService.getOrgs().then(function (orgs) {
            $scope.orgs = _.chain(orgs)
                // sort alphabetically
                .sortBy(function(el) {
                    return el._name;
                })
                // remove common orgs
                .filter(function(el){
                    return !_.contains(commonOrgIds,el.id);
                })
                .value();

            $scope.LoadingOrgs = false;

        });
    };

    // update org name on admin list
    $scope.updateActiveUser = function(){
        var selectedOrg;
        // get org name by ng model radio button id
        if ($scope.orgs) {
            selectedOrg = _.find($scope.orgs, function(org){
                return org.id == $scope.activeUser.organization_id;
            });
        // if all orgs have not been loaded, find selected id in common orgs
        } else {
            selectedOrg = _.find($scope.commonOrgs, function(org){
                return org.id == $scope.activeUser.organization_id;
            });
        }

        // set org name
        $scope.activeUser.organization = selectedOrg._name;
        // close modal
        $mdDialog.cancel();
    };

    // on click function for close buttons
    $scope.cancel = function () {
        // set ng-model org_id back to original
        $scope.activeUser.organization_id = $scope.originalOrg_id;
        $mdDialog.cancel();
     };

});