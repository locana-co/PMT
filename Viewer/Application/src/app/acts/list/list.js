/***************************************************************
 * Activity Page List Controller
 * Supports the activity page's activity list feature.
 * *************************************************************/
angular.module('PMTViewer').controller('ActsListCtrl', function ($scope, $rootScope, stateService, config, activityService, editorService, $mdDialog) {

    $scope.stateService = stateService;
    //loader
    $scope.loading = true;
    //defaults for pagination
    $scope.query = {
        order: 'response.t',
        limit: 50,
        page: 1
    };
    // list of additional columns to show for activity list
    $scope.columnList = $scope.page.tools.map.params.activityListColumns;
    // determine the column span for child activities
    $scope.childColSpan = $scope.page.tools.map.params.activityListColumns.length + 2;
    //initialize parent count at 0
    $scope.parentActivityCount = 0;

    // when the activity list is updated do this
    $scope.$on('act-list-updated', function () {
        $scope.filteredActivities = activityService.allActivities;
        $scope.parentActivityCount = activityService.activityCount;
        $scope.loading = false;
    });

    // when the activity list is updating do this
    $scope.$on('act-list-updating', function () {
        $scope.loading = true;
    });

    // show activity
    $scope.showActivityDetail = function (activity) {
        stateService.setParamWithVal('activity_id', activity.id.toString());
        //create an activity object to store in activity service
        var a = {
            id: activity.id,
            pid: activity.pid,
            title: activity.t
        };
        activityService.setSelectedActivity(a);
    };

    // toggle whether seeing child activity details on the list
    $scope.toggleActive = function (act) {
        act.active = !act.active;
        act.arrow = (act.active) ? "keyboard_arrow_up" : "keyboard_arrow_down";
    };

    // export activity list
    $scope.exportActivityList = function () {

        var activities = [];

        //add header to activity print
        var header = {
            '0': 'PMT Id',
            '1': $scope.terminology.activity_terminology.singular.capitalizeFirstLetter() + ' Name',
            '3': 'Data Group',
            '4': 'Budget',
            '5': 'Currency',
            '6': 'Start Date',
            '7': 'End Date',
            '8': $scope.terminology.funder_terminology.plural.capitalizeFirstLetter()
        };
        activities.push(header);

        _.each($scope.filteredActivities, function (a) {
            //create an activity structure to print
            var act = {
                '0': a.response.id,
                '1': a.response.t,
                '3': a.response.dg,
                '4': a.response.a,
                '5': a.response.currency,
                '6': a.response.sd,
                '7': a.response.ed,
                '8': a.response.f.join(' ; ')
            };
            activities.push(act);
        });

        activityService.exportActivityList(activities);
    };

    // modal popup for printing widgets
    $scope.exportPopup = function () {
        $mdDialog.show({
            locals: {},
            controller: DownloadController,
            templateUrl: 'acts/list/acts-print-modal.tpl.html',
            parent: angular.element(document.body),
            clickOutsideToClose: true,
            scope: $scope,
            preserveScope: true
        });
    };

    // navigate to edit page to edit activity
    $scope.editActivity = function (activity_id) {
        var params = { "editor_activity_id": activity_id };
        stateService.setState("editor", params, true);
    };

    // initialize list
    function init() {
        var lastEdit = editorService.getLastEdit();
        var listUpdated = activityService.getLastListUpdate();
        if (editorService.getLastEdit() !== null && activityService.getLastListUpdate() < editorService.getLastEdit()) {
            console.log("activity list is out of date, re-fetch and load");
            $scope.loading = true;
            activityService.getActivities().then(function (activities) {
                $scope.filteredActivities = activityService.allActivities;
                $scope.parentActivityCount = activityService.activityCount;
                $scope.loading = false;
            });
        }
        else {
            if (activityService.allActivities.length > 0) {
                $scope.filteredActivities = activityService.allActivities;
                $scope.parentActivityCount = activityService.activityCount;
                $scope.loading = false;
            }
        }
    }

    // pop-up model on download click
    function DownloadController($scope) {

        // on click function for close buttons
        $scope.closeDialog = function () {
            $mdDialog.cancel();
        };
    }

    init();
});

angular.module('PMTViewer').filter('filterListOrgs', function () {
    return function (value) {
        if (!value) { return '--'; }
        //identify number of funders
        var funderCount = value.length;

        if (funderCount > 1) {
            return 'Multiple Funders';
        }
        else if (funderCount === 0) {
            return '--';
        }
        else {
            return value[0];
        }
    };
});