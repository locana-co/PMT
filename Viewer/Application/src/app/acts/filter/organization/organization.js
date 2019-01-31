/***************************************************************
 * Organization Filter Controller
 * A filter controller. Supports the filtering of activities by 
 * organizations. Usage is defined in the app.config in the 
 * activity page filter object.
 * *************************************************************/
angular.module('PMTViewer').controller('ActsFilterOrganizationCtrl', function ($scope, $http, $rootScope, $state, $stateParams, stateService, config, global, activityService) {

    var dataGroupIds = null;
    $scope.loadingOrgs = false;

    // when the activity list is updating, do this
    $scope.$on('act-list-updating', function () {
        $scope.filter.disabled = true;
    });

    // when the activity list has updated, do this
    $scope.$on('act-list-updated', function () {
        $scope.filter.disabled = false;
    });

    // when the filters have been updated, do this
    $scope.$on('activity-filter-update', function () {
        validateOrganizations();
    });

    // organization name clicked
    $scope.optionClicked = function (org) {
        try {
            $scope.selectedOrgs = [];
            // get all the selected organizations
            _.each($scope.filter.options, function (o) {
                if (o.active === true) {
                    $scope.selectedOrgs.push(o.id);
                }
            });
            // set the filter in the activityService based on type
            switch ($scope.filter.params.type) {
                case 'implementing':
                    activityService.setImpOrgFilter($scope.selectedOrgs);
                    break;
                case 'funding':
                    activityService.setFundOrgFilter($scope.selectedOrgs);
                    break;
                default:
                    activityService.setOrgFilter($scope.selectedOrgs);
                    break;
            }
        }
        // error handler
        catch (ex) {
            // there was an error report it to the error handler
            console.log(ex);
        }
    };

    // validate the organization list
    function validateOrganizations() {
        // get current data group ids, order by id
        var activeDataGroupIds = _.sortBy(activityService.getDataGroupFilters(), function (id) { return Math.sin(id); });
        // if the data groups have changed up date the organization list
        if (!_.isEqual(dataGroupIds, activeDataGroupIds.toString())) {
            // update the data groups
            dataGroupIds = activeDataGroupIds.toString();
            // turn loader on
            $scope.loadingOrgs = true;
            if (activeDataGroupIds.length === 0) {
                processOrganizations(null);
                // stop spinner
                $scope.loadingOrgs = false;
            }
            else {
                // using the activity service, get all the organizations for the filter
                activityService.getOrgsInUse($scope.filter.params.org_role_ids, $scope.filter.params.type).then(function (orgs) {
                    processOrganizations(orgs);
                    validateActive();
                    // stop spinner
                    $scope.loadingOrgs = false;
                });
            }
        }
        else {
            validateActive();
        }
    }

    // validate active organizations via filter
    function validateActive() {
        // selected filters (organizations)
        var filters = [];
        // set the filter in the activityService based on type
        switch ($scope.filter.params.type) {
            case 'implementing':
                filters = activityService.getImpOrgFilters();
                break;
            case 'funding':
                filters = activityService.getFundOrgFilters();
                break;
            default:
                filters = activityService.getOrgFilters();
                break;
        }
        // set the active organizations
        _.each($scope.filter.options, function (o) {
            o.active = false;
            if (_.contains(filters, o.id)) {
                o.active = true;
            }
        });
    }

    // convert any string to title case
    function toTitleCase(str) {
        return str.replace(/\w\S*/g, function (txt) { return txt.charAt(0).toUpperCase() + txt.substr(1).toLowerCase(); });
    }

    // organization filter initialization
    function init() {
        // initialize the filter if it has not been initialized
        if ($scope.filter && !_.has($scope.filter, 'options')) {
            $scope.filter.disabled = true;
            // turn loader on
            $scope.loadingOrgs = true;
            // set the current data group ids, order by id
            dataGroupIds = _.sortBy(activityService.getDataGroupFilters(), function (id) { return Math.sin(id); }).toString();
            // using the activity service, get all the organizations for the filter
            activityService.getOrgsInUse($scope.filter.params.org_role_ids, $scope.filter.params.type).then(function (orgs) {
                processOrganizations(orgs);
                // stop spinner
                $scope.loadingOrgs = false;
            });
        }
    }

    // process organizations for filter usage
    function processOrganizations(orgs) {
        if (orgs) {
            // sort the organizations by name
            orgs = _.sortBy(orgs, 'n');
            // convert all to title case
            // _.each(orgs, function (o) {
            //     var regExp = /\(([^)]+)\)/;
            //     o.n = toTitleCase(o.n);
            //     var match = regExp.exec(o.n);
            //     if (match) {
            //         var replacement = match[1].toUpperCase();
            //         o.n = o.n.replace(/\(.*?\)/, "(" + replacement + ")");
            //     }
            // });
        }
        else {
            orgs = [];
        }
        // assign the prepared variables to scope
        $scope.filter.options = orgs;
        // set the filter size
        $scope.filter.size = $scope.filter.options.length;
    }

    // initialize the filter
    init();

});