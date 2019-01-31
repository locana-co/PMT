module.exports = angular.module('PMTViewer').controller('EditPermissionsCtrl', function ($scope, $rootScope, $mdDialog, userService, config, utilService) {
    // loader
    $scope.loading = false;
    // activity list
    $scope.activities = null;
    // taxonomy list
    $scope.taxonomies = [];

    if (typeof $rootScope.currentUser != 'undefined' && $rootScope.currentUser != null) {
        fetchActivities();
        fetchTaxonomies();
    }

    // on click function for close and cancel buttons
    $scope.cancelPermissions = function () {
        $mdDialog.cancel();
    };

    // update permissions for each activity & classification
    $scope.setPermissions = function () {
        $scope.loading = true;

        // authorize all active activities and classifications
        userService.editUserActivities($scope.activeUser, filterActivities(true), filterClassifications(true), false);

        // deauthorize all inactive activities and classifications
        userService.editUserActivities($scope.activeUser, filterActivities(false), filterClassifications(false), true).then(function (res) {
            // reload user list on admin page
            $scope.loading = false;
            $mdDialog.hide(true);
        }).catch(function (msg) {
            $scope.loading = false;
            $scope.errorMessage = msg;
        });
    };

    // on selection of activity checkbox, toggle feature selected
    // required because we are using dynamic HTML and cannot use md-checkbox ng-model
    $scope.selectedActivity = function (id) {
        var activity;
        // find the activity by id
        activity = _.find($scope.activities, function (a) { return a.id === id; });
        if (activity) {
            activity.active = !activity.active;
        }
    };

    // on selection of classification checkbox, toggle feature selected
    // required because we are using dynamic HTML and cannot use md-checkbox ng-model
    $scope.selectedClassification = function (id) {
        var classification;
        _.each($scope.taxonomies, function (t) {
            // find the classification by id
            classification = _.find(t.classifications, function (c) { return c.id === id; });
            if (classification) {
                classification.active = !classification.active;
            }
        });
    };

    // get all activities for the current instance
    function fetchActivities() {
        // loader
        $scope.loading = true;
        // get the list of activities from the service
        $scope.activities = userService.getAllActivities();
        // list is not initialized
        if ($scope.activities === null) {
            // collect the data groups
            var dataGroupIds = [];
            _.each($scope.page.tools.admin.datagroups, function (dg) {
                dataGroupIds.push(dg.data_group_id);
            });
            // get the filtered activities
            userService.getActivities(dataGroupIds).then(function (activities) {
                $scope.activities = activities;
                if ($scope.activeUser.authorizations && $scope.activeUser.authorizations.activity_ids) {
                    _.each($scope.activities, function (a) {
                        // check if the user is authorized for the activity
                        if ($scope.activeUser.authorizations.activity_ids.indexOf(a.id) > -1) {
                            a.active = true;
                        }
                        else {
                            a.active = false;
                        }
                    });
                }
                $scope.activityUI = processActivities();
                $scope.loading = false;
            });
        }
        else {
            if ($scope.activeUser.authorizations && $scope.activeUser.authorizations.activity_ids) {
                _.each($scope.activities, function (a) {
                    // check if the user is authorized for the activity
                    if ($scope.activeUser.authorizations.activity_ids.indexOf(a.id) > -1) {
                        a.active = true;
                    }
                    else {
                        a.active = false;
                    }
                });
            }
            $scope.activityUI = processActivities();
            $scope.loading = false;
        }
    }

    // get all taxonomies filtered to the current instance
    function fetchTaxonomies() {
        // get the list of taxonomies from the service
        $scope.taxonomies = userService.getAllTaxonomies();
        _.each($scope.page.tools.admin.taxonomies, function (taxonomy) {
            var existingTaxonomy = _.find($scope.taxonomies, function (t) { return t.taxonomy_id === taxonomy.taxonomy_id; });
            if (existingTaxonomy) {
                // add the active parameter to our object (for checkboxes)
                _.each(existingTaxonomy.classifications, function (c) {
                    // if the user is authorized for the classification, set the classification to active
                    if ($scope.activeUser.authorizations && $scope.activeUser.authorizations.classification_ids) {
                        if ($scope.activeUser.authorizations.classification_ids.indexOf(c.id) > -1) {
                            c.active = true;
                        }
                        else {
                            c.active = false;
                        }
                    }
                });
                // if last taxonomy in the list process for menu UI
                if (_.last($scope.page.tools.admin.taxonomies).taxonomy_id === taxonomy.taxonomy_id) {
                    $scope.taxonomyUI = processTaxonomies();
                }
            }
            else {
                // the each taxonomy's classifications
                userService.getTaxonomy(taxonomy, $scope.activeUser.authorizations).then(function (taxonomies) {
                    $scope.taxonomies = taxonomies;
                    // if last taxonomy in the list process for menu UI
                    if (_.last($scope.page.tools.admin.taxonomies).taxonomy_id === taxonomy.taxonomy_id) {
                        $scope.taxonomyUI = processTaxonomies();
                    }
                });
            }
        });
    }

    // filter active/inactive activities from list
    function filterActivities(isActive) {
        var filter = [];
        // collect collect all active/inactive activities
        _.each($scope.activities, function (a) {
            if (a.active === isActive) {
                filter.push(a.id);
            }
        });
        return filter;
    }

    // filter active/inactive classifications from list
    function filterClassifications(isActive) {
        var classifications = [];
        var filter = [];
        // union classifications into one group
        _.each($scope.taxonomies, function (t) {
            classifications = _.union(t.classifications, classifications);
        });
        // collect collect all active/inactive classifications
        _.each(classifications, function (c) {
            if (c.active === isActive) {
                filter.push(c.id);
            }
        });
        return filter;
    }

    // process activity list and dynamically generate the HTML for the list
    // using this approach over ng-repeat because the or list is 
    // a very large object and ng-repeat causes extream performance issues
    function processActivities() {
        // the HTML for the menu
        var menuHTML = '';
        _.each($scope.activities, function (activity) {
            // if (searchText === null || activity.t.toLowerCase().indexOf(searchText.toLowerCase()) >= 0) {                
            menuHTML += '<div class="checkbox">';
            if (activity.active) {
                menuHTML += '<input type="checkbox" ng-click="selectedActivity(' + activity.id + ');" checked="true" id="' + activity.id + '" value="' + activity.id + '" name="activity">';
            }
            else {
                menuHTML += '<input type="checkbox" ng-click="selectedActivity(' + activity.id + ');" id="' + activity.id + '" value="' + activity.id + '" name="activity">';
            }
            menuHTML += '<label for="' + activity.id + '" class="checkbox-label">' + activity.t + '</label></div>';
            // }
        });
        return menuHTML;
    }

    // process taxonomies list and dynamically generate the HTML for the list
    // using this approach over ng-repeat because the or list is 
    // a very large object and ng-repeat causes extream performance issues
    function processTaxonomies() {
        // the HTML for the menu
        var menuHTML = '';
        _.each($scope.taxonomies, function (taxonomy) {
            menuHTML += '<label class="taxonomy-label">' + taxonomy.label + '</label>';
            _.each(taxonomy.classifications, function (classification) {
                menuHTML += '<div class="checkbox">';
                if (classification.active) {
                    menuHTML += '<input type="checkbox" ng-click="selectedClassification(' + classification.id + ');" checked="true" id="' + classification.id + '" value="' + classification.id + '" name="classification">';
                }
                else {
                    menuHTML += '<input type="checkbox" ng-click="selectedClassification(' + classification.id + ');" id="' + classification.id + '" value="' + classification.id + '" name="classification">';
                }
                menuHTML += '<label for="' + classification.id + '" class="checkbox-label">' + classification.c + '</label></div>';
            });
        });
        return menuHTML;
    }
});