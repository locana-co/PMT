module.exports = angular.module('PMTViewer').controller('EditorOrgSelectorCtrl', function ($scope, $rootScope, $mdDialog, editorService) {

    // initialze module
    init();
    $scope.searchText = null;

    // update the selected organization
    $scope.updateOrg = function () {
        var org = _.find($scope.orgs, function (o) { return o.id == $scope.dialogSettings.selectedOrg; });
        // close modal
        $mdDialog.hide(org);
    };

    // update the selected organization
    $scope.loadAllOrgs = function () {
        $scope.loadingOrgs = true;
        $scope.orgs = editorService.getAllOrgs();
        // if the list is empty then it is the first call, lets populate it
        if ($scope.orgs.length <= 0) {
            editorService.getInUseOrgs(null, null, 'all').then(function (orgs) {
                $scope.orgs = _.sortBy(orgs, 'n');
                $scope.loadingOrgs = false;
            });
        }
    };

    // on selection of organization radio button, toggle feature selected
    // required because we are using dynamic HTML and cannot use md-radio ng-model
    $scope.selectedOrg = function (id) {
        $scope.dialogSettings.selectedOrg = id;
        var org;
        // find the feature location by id
        org = _.find($scope.orgs, function (o) { return o.id === id; });
        if (org) {
            // mark all inactive
            _.each($scope.orgs, function (o) { o.selected = false; });
            org.selected = true;
        }
        $("md-dialog").scrollTop(0);
    };

    // on click function for close buttons
    $scope.cancel = function () {
        $mdDialog.cancel();
    };

    // watch the search input for changes and set search
    $scope.$watch('searchText', setSearch);

    // regenerate the menu including only searched text
    function setSearch(searchText) {
        $scope.menuUI = generateMenu(searchText);
    }

    // intialize the modal
    function init() {
        // set loading true
        $scope.loadingOrgs = true;
        // collect the data groups
        var dataGroupIds = [];
        _.each($scope.settings.datagroups, function (dg) {
            dataGroupIds.push(dg.data_group_id);
        });
        // initialize the org list
        $scope.orgs = [];
        // get the list of orgs from the service
        switch ($scope.dialogSettings.orgType) {
            case 'funding':
                $scope.orgs = editorService.getFundingOrgs();
                break;
            case 'implmenting':
                $scope.orgs = editorService.getImplementingOrgs();
                break;
            case 'accountable':
                $scope.orgs = editorService.getAccountableOrgs();
                break;
            case 'inuse':
                $scope.orgs = editorService.getInUse();
                break;
            default:
                $scope.orgs = editorService.getAllOrgs();
                break;
        }

        // if the list is empty then it is the first call, lets populate it
        if ($scope.orgs.length <= 0) {
            editorService.getInUseOrgs(dataGroupIds.join(), $scope.dialogSettings.roleIds, $scope.dialogSettings.orgType).then(function (orgs) {
                $scope.orgs = _.sortBy(orgs, 'n');
                _.each($scope.orgs, function (org) { _.extend(org, { selected: false }); });
                $scope.menuUI = generateMenu(null);
                $scope.loadingOrgs = false;
            });
        }
        else {
            $scope.loadingOrgs = false;
            $scope.menuUI = generateMenu(null);
        }
    }

    // private function to dynamically generate the HTML for the
    // menu (listing of organizations) 
    // using this approach over ng-repeat because the or list is 
    // a very large object and ng-repeat causes extream performance issues
    function generateMenu(searchText) {
        // the HTML for the menu
        var menuHTML = '';
        _.each($scope.orgs, function (org) {
            if (searchText === null || org.n.toLowerCase().indexOf(searchText.toLowerCase()) >= 0) {
                menuHTML += '<div class="radio">';
                // menuHTML += '<md-checkbox ng-click="selectedOrg(' + org.id + ')">' + org.n + '</md-checkbox>';
                menuHTML += '<input type="radio"  ng-checked="' + Boolean($scope.dialogSettings.selectedOrg === org.id).toString() + '" name="orgs" value="' + org.id + '" id="' + org.id + '" ng-click="selectedOrg(' + org.id + ');"/>';
                menuHTML += '<label for="' + org.id + '" class="radio-label">' + org.n + '</label>';
                menuHTML += '</div>';
            }
        });
        return menuHTML;
    }

});