/***************************************************************
 * Editor Top Bar Controller
 * Supports the top bar for the editor page.
 ***************************************************************/
angular.module('PMTViewer').controller('EditorTopBarCtrl', function ($scope, $mdDialog, stateService, editorService, $rootScope, blockUI) {

    $scope.stateService = stateService;
    // get the activity list count
    $scope.activityCt = 0;

    // when the editor activity id parameter is updated do this
    $scope.$on('editor-activity-loaded', function () {
        $scope.activityTitle = editorService.getCurrentActivity()._title;
    });

    // when the editable activity list is updated do this
    $scope.$on('editor-list-updated', function () {
        if (Array.isArray(editorService.getAllActivities())) {
            $scope.activityCt = editorService.getAllActivities().length;
        }
    });

    // when the route changes do this
    $scope.$on('route-update', function () {
        if (Array.isArray(editorService.getAllActivities())) {
            $scope.activityCt = editorService.getAllActivities().length;
        }
    });

    // show parent activity
    $scope.returnToParent = function (e, id) {
        e.preventDefault();
        if (editorService.isDirty()) {
            var confirm = $mdDialog.confirm()
                .title('Are you sure you want to navigate way from this record before saving?')
                .ariaLabel('leaving record confirmation')
                .ok('Yes, Go to Parent')
                .cancel('No, Cancel');
            $mdDialog.show(confirm).then(function () {
                var params = {
                    editor_activity_id: id,
                    editor_parent_id: null,
                    editor_parent_title: null
                };
                stateService.setState("editor", params, true);
            }, function () { });
        } else {
            var params = {
                editor_activity_id: id,
                editor_parent_id: null,
                editor_parent_title: null
            };
            stateService.setState("editor", params, true);
        }


    };

    // on click of back button in top bar
    $scope.returnToActivityList = function (e) {
        if (!$(e.currentTarget).is("[disabled='disabled']")) {
            if (editorService.isDirty()) {
                var confirm = $mdDialog.confirm()
                    .title('Are you sure you want to navigate way from this record before saving?')
                    .ariaLabel('leaving record confirmation')
                    .ok('Yes, Go to List')
                    .cancel('No, Cancel');
                $mdDialog.show(confirm).then(function () {
                    stateService.setParamWithVal('editor_activity_id', '');
                    stateService.setParamWithVal('layers', '');
                    stateService.setParamWithVal('editor_parent_id', '');
                    stateService.setParamWithVal('editor_parent_title', '');
                }, function () { });
            } else {
                stateService.setParamWithVal('editor_activity_id', '');
                stateService.setParamWithVal('layers', '');
                stateService.setParamWithVal('editor_parent_id', '');
                stateService.setParamWithVal('editor_parent_title', '');
            }
        }
    };

    // save activity record 
    $scope.saveActivity = function (event) {
        if (editorService.validateForms()) {
            blockUI.message('Saving ...');
            editorService.saveActivity().then(function (activity) {
                // broadcast refresh of the activity
                $rootScope.$broadcast('refresh-editor-activity');
                // broadcast refresh of the list
                $rootScope.$broadcast('refresh-editor-list');
                if (activity.errors.length > 0) {
                    var html = '<p>Your changes have been saved, but there were some errors reported:</p>';
                    html += '<p><ul>';
                    _.each(activity.errors, function (error) {
                        html += '<li>' + error.record.capitalizeFirstLetter() + ' (ID ' + error.id + '): ' +
                            error.message + '</li>';
                    });
                    html += '</ul></p>';
                    blockUI.done(function () {
                        // inform user the record was saved, but there were some errors
                        $mdDialog.show(
                            $mdDialog.alert()
                                .parent(angular.element(document.querySelector('#editor-detail')))
                                .clickOutsideToClose(true)
                                .title('Saved with Errors')
                                .htmlContent(html)
                                .ariaLabel('Activity Save')
                                .ok('Ok')
                                .targetEvent(event)
                        );
                    });
                }
                else {
                    blockUI.done(function () {
                        // inform user the record was saved successfully
                        $mdDialog.show(
                            $mdDialog.alert()
                                .parent(angular.element(document.querySelector('#editor-detail')))
                                .clickOutsideToClose(true)
                                .title('Save Successful')
                                .textContent('Your changes have been successfully saved!')
                                .ariaLabel('Activity Save')
                                .ok('Ok')
                                .targetEvent(event)
                        );
                    });
                }
            }, function (error) {
                blockUI.done(function () {
                    // inform the user there was an error during the saving of the record
                    $mdDialog.show(
                        $mdDialog.alert()
                            .parent(angular.element(document.querySelector('#editor-detail')))
                            .clickOutsideToClose(true)
                            .title('Error Message')
                            .textContent(error)
                            .ariaLabel('Validation Error Alert')
                            .ok('Ok')
                            .targetEvent(event)
                    );
                });
            });
        }
        else {
            // inform the user there is missing, required information 
            $mdDialog.show(
                $mdDialog.alert()
                    .parent(angular.element(document.querySelector('#editor-detail')))
                    .clickOutsideToClose(true)
                    .title('Data Validation Check')
                    .textContent('It appears that you may have forgotten to provide some information. Please review and ensure all required fields are filled out.')
                    .ariaLabel('Validation Error Alert')
                    .ok('Ok')
                    .targetEvent(event)
            );
        }
    };

    // cancel activity record
    $scope.cancelActivity = function (event) {
        if (editorService.isDirty()) {
            // appending dialog to document.body to cover sidenav in docs app
            var confirm = $mdDialog.confirm()
                .title('Are you sure you want to cancel? All changes to this record will be lost!')
                .ariaLabel('cancel confirmation')
                .targetEvent(event)
                .ok('Yes, Cancel Changes')
                .cancel('No, Keep Changes');
            $mdDialog.show(confirm).then(function () {
                if ($scope.activityTitle) {
                    // broadcast refresh of the activity
                    $rootScope.$broadcast('refresh-editor-activity');
                } else {
                    //go back to list
                    stateService.setParamWithVal('editor_activity_id', '');
                    stateService.setParamWithVal('layers', '');
                }

            }, function () { });
        }else{
            if ($scope.activityTitle) {
                // broadcast refresh of the activity
                $rootScope.$broadcast('refresh-editor-activity');
            } else {
                //go back to list
                stateService.setParamWithVal('editor_activity_id', '');
                stateService.setParamWithVal('layers', '');
            }
        }
    };

    // delete activity record
    $scope.deleteActivity = function (event) {
        // appending dialog to document.body to cover sidenav in docs app
        var confirm = $mdDialog.confirm()
            .title('Are you sure you want to delete this record? This will permanently remove this record from the database!')
            .ariaLabel('delete confirmation')
            .targetEvent(event)
            .ok('Yes, Delete ' + $scope.terminology.activity_terminology.singular.capitalizeFirstLetter())
            .cancel('No, Cancel');
        $mdDialog.show(confirm).then(function () {
            if (editorService.getActivityId) {
                editorService.deleteActivity().then(function () {
                    stateService.setParamWithVal('editor_activity_id', '');
                    stateService.setParamWithVal('layers', '');
                    // broadcast refresh of the list
                    $rootScope.$broadcast('refresh-editor-list');
                });
            }
        }, function () { });
    };

    // create new activity record
    $scope.createActivity = function (event) {
        var message, cancel = null;
        if ($scope.stateService.isParam('editor_activity_id')) {
            message = "Are you sure you want to continue with a new record? All changes to this record will be lost!";
            cancel = "No, Keep Changes";
        }
        else {
            message = "Are you sure you want to create a new record?";
            cancel = "No, Cancel";
        }
        // appending dialog to document.body to cover sidenav in docs app
        var confirm = $mdDialog.confirm()
            .title(message)
            .ariaLabel('new confirmation')
            .targetEvent(event)
            .ok('Yes, Create New ' + $scope.terminology.activity_terminology.singular.capitalizeFirstLetter())
            .cancel(cancel);
        $mdDialog.show(confirm).then(function () {
            // -1 signifies a new record
            var params = { "editor_activity_id": -1 };
            stateService.setState("editor", params, true);
        }, function () { });
    };

});

// custom filter for adding elipses to long strings
angular.module('PMTViewer').filter('cut', function () {
    return function (value, wordwise, max, tail) {
        if (!value) { return ''; }

        max = parseInt(max, 10);
        if (!max) { return value; }
        if (value.length <= max) { return value; }

        value = value.substr(0, max);
        if (wordwise) {
            var lastspace = value.lastIndexOf(' ');
            if (lastspace != -1) {
                //Also remove . and , so its gives a cleaner result.
                if (value.charAt(lastspace - 1) == '.' || value.charAt(lastspace - 1) == ',') {
                    lastspace = lastspace - 1;
                }
                value = value.substr(0, lastspace);
            }
        }
        return value + (tail || ' …');
    };
});