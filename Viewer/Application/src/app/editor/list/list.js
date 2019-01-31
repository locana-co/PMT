/***************************************************************
 * Editor Page List Controller
 * Supports the editor page's activity list feature.
 * *************************************************************/
angular.module('PMTViewer').controller('EditorListCtrl', function ($scope, $rootScope, stateService, config, editorService, utilService, $mdDialog) {

    $scope.stateService = stateService;
    // editor settings
    $scope.settings = $scope.page.tools.editor;
    //loader
    $scope.loading = true;
    //defaults for pagination
    $scope.query = {
        order: 't',
        limit: 50,
        page: 1
    };
    // user error message
    $scope.error = false;
    // activity list
    $scope.activitiesList = [];
    // initialize page
    init(false);

    // function to link activity list to activity detail page
    $scope.goToActivity = function (activity_id) {
        var params = { "editor_activity_id": activity_id };
        stateService.setState("editor", params, true);
    };

    // when the editor activity list needs refreshing do this
    $scope.$on('refresh-editor-list', function () {
        init(true);
    });

    // initialize list
    function init(reload) {
        //only build out list if not viewing a detail record.
        //if ($scope.stateService.isState("editor") && $scope.stateService.isNotParam('editor_activity_id')) {
        $scope.loading = true;
        // get the saved activity list from the service
        $scope.activitiesList = editorService.getAllActivities();
        // activity ids
        var actvityIds = $rootScope.currentUser.user.authorizations;
        // user message (role Editor with NO authorizations)
        if (actvityIds === null && $rootScope.currentUser.user.role === 'Editor') {
            $scope.error = true;
        }
        // collect the data groups
        var dataGroupIds = [];
        _.each($scope.settings.datagroups, function (dg) {
            dataGroupIds.push(dg.data_group_id);
        });
        if ($scope.error) {
            $scope.loading = false;
            $scope.activitiesList = null;
        }
        else {
            // list is not initialized
            if ($scope.activitiesList === null || reload) {
                // call service to get activity list
                editorService.getActivities(dataGroupIds, actvityIds).then(function (activities) {
                    $scope.loading = false;
                    $scope.activitiesList = activities;
                    _.each($scope.activitiesList, function (activity) {
                        var version = { "v": null, "c": null };
                        version.v = activity.x ? (activity.v === null || activity.v.length === 0 ? "Incomplete" : version.v = activity.v[0]) : "Incomplete";
                        version.c = version.v.toLowerCase();
                        activity = _.extend(activity, { "version": version });
                    });
                    $scope.htmlList = processActivities();
                });
            }
            else {
                // get all the activity ids from saved list
                var listIds = _.pluck($scope.activitiesList, 'id');
                // if the user doesn't have access to all the activities in the saved list
                // re-fetch, the user has likely changed
                if (_.difference(listIds, actvityIds).length > 0 || _.difference(actvityIds, listIds).length > 0) {
                    // call service to get activity list
                    editorService.getActivities(dataGroupIds, actvityIds).then(function (activities) {
                        $scope.loading = false;
                        $scope.activitiesList = activities;
                        _.each($scope.activitiesList, function (activity) {
                            var version = { "v": null, "c": null };
                            version.v = activity.x ? (activity.v === null || activity.v.length === 0 ? "Incomplete" : version.v = activity.v[0]) : "Incomplete";
                            version.c = version.v.toLowerCase();
                            activity = _.extend(activity, { "version": version });
                        });
                        $scope.htmlList = processActivities();
                    });
                }
                else {
                    $scope.htmlList = processActivities();
                    $scope.loading = false;
                }
            }
        }
    }

    // process activity list and dynamically generate the HTML for the list
    // using this approach over ng-repeat because the or list is 
    // a very large object and ng-repeat causes extream performance issues
    function processActivities() {
        var htmlList = '<table md-table class="highlight bordered"><thead md-head><tr md-row>';
        htmlList += '<th md-column md-order-by="t">' + $scope.terminology.activity_terminology.singular + ' Name</th>';
        htmlList += '<th md-column md-order-by="activity.a">Version</th>';
        htmlList += '<th>budget</th><th class="start-date-column">start date</th><th>end date</th>';
        htmlList += '<th>' + $scope.terminology.funder_terminology.singular + '</th><tbody>';
        _.each($scope.activitiesList, function (activity) {
            htmlList += '<tr md-row>';
            htmlList += '<td ng-click="goToActivity(' + activity.id + ')">' + activity.t + '</td>';
            htmlList += '<td>' + activity.x + '</td>';
            htmlList += '<td>USD ' + utilService.formatMoney(activity.a) + '</td>';
            htmlList += '<td>' + utilService.formatShortDate(activity.sd) + '</td>';
            htmlList += '<td>' + utilService.formatShortDate(activity.ed) + '</td>';
            if (Array.isArray(activity.f)) {
                if (activity.f.length > 1) {
                    htmlList += '<td>Multiple Funders</td>';
                }
                else {
                    htmlList += '<td>' + activity.f + '</td>';
                }
            }
            else {
                htmlList += '<td>---</td>';
            }
            htmlList += '</tr>';
        });
        return htmlList + '</tbody></table>';
    }
});

angular.module('PMTViewer').filter('determineVersion', function () {
    return function (active, version) {
        // activity is active
        if (active) {
            if (version === null) {
                return "incomplete";
            }
            else if (version.length === 0) {
                return "incomplete";
            }
            else {
                return version[0].toLowerCase();
            }
        }
        // activity is inactive
        else {
            return "incomplete";
        }
    };
});