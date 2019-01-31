/***************************************************************
 * Activities Top Bar Controller
 * Supports the top bar for the activities page.
 ***************************************************************/
angular.module('PMTViewer').controller('ActsTopBarCtrl', function ($scope, stateService, activityService, $rootScope, config) {

    $scope.stateService = stateService;
    // get number of activities
    $scope.activityCount = activityService.activityCount;
    // get activity
    $scope.activity = activityService.getSelectedActivity();
    // get activity title
    $scope.activityTitle = activityService.getSelectedActivity().title;
    // determine if editor is enabled
    $scope.hasEditor = hasEditor();

    // when the activity list is updated do this
    $scope.$on('act-list-updated', function () {
        $scope.activityCount = activityService.activityCount;
        if ($scope.activityTitle) {
            $scope.titleLength = $scope.activityTitle.length;
        }
    });

    //on activity id change, update activity name
    $scope.$on('acts-title-update', function () {
        $scope.activityTitle = activityService.getSelectedActivity().title;
        if ($scope.activityTitle) {
            $scope.titleLength = $scope.activityTitle.length;
        }
        $scope.activity = activityService.getSelectedActivity();

    });

    //on url update, update activity name
    $scope.$on('route-update', function () {
        $scope.activityTitle = activityService.getSelectedActivity().title;
        if ($scope.activityTitle) {
            $scope.titleLength = $scope.activityTitle.length;
        }
        $scope.activity = activityService.getSelectedActivity();
    });

    // function to return to list of activities
    $scope.returnToActivityList = function() {
        stateService.setParamWithVal('activity_id','');
    };

    // show parent activity
    $scope.showParentActivity = function (activity_id) {
        stateService.setParamWithVal('activity_id', activity_id);
    };
    
    // navigate to edit page to edit activity
    $scope.editActivity = function (activity_id) {
        var params = { "editor_activity_id": activity_id };
        stateService.setState("editor", params, true);
    };

    // determine if instances has the editor enabled
    function hasEditor(){
        var enabled;
        _.each(config.states, function(state){
            if(state.route === 'editor'){
                enabled =  state.enable;
            }
        });
        return enabled;
    }
});