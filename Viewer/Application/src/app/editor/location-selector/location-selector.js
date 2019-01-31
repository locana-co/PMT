module.exports = angular.module('PMTViewer').controller('EditorLocationSelectorCtrl', function ($scope, $rootScope, $q, $sce, $mdDialog, editorService, blockUI) {

    // initialze module
    init();

    // set admin filters to null
    $scope.admin1Selection = null;
    $scope.admin2Selection = null;

    // collect selected feature locations and return them
    // to the requesting page for processing
    $scope.saveLocations = function () {
        var locations = null;
        switch ($scope.dialogSettings.admin_level) {
            case 1:
                locations = _.filter($scope.menu.boundaries, function (l) { return l.selected; });
                break;
            case 2:
                locations = [];
                _.each($scope.menu.boundaries, function (admin1) {
                    var selections = _.filter(admin1.b, function (l) { return l.selected; });
                    _.each(selections, function (s) {
                        _.extend(s, { n1: admin1.n });
                        locations.push(s);
                    });
                });
                break;
            case 3:
                locations = [];
                _.each($scope.menu.boundaries, function (admin1) {
                    _.each(admin1.b, function (admin2) {
                        var selections = _.filter(admin2.b, function (l) { return l.selected; });
                        _.each(selections, function (s) {
                            _.extend(s, { n1: admin1.n, n2: admin2.n });
                            locations.push(s);
                        });
                    });
                });
                break;
            default:
                break;
        }
        // close modal
        $mdDialog.hide(locations);
    };

    // on click function for close buttons
    $scope.cancel = function () {
        $mdDialog.cancel();
    };

    // on click function for admin 1 filter
    $scope.admin1Filter = function () {
        // filter on menu expects an integer
        $scope.admin1Selection = parseInt($scope.admin1Selection, 10);
        $scope.admin2Selection = null;
    };

    // on click function for admin 2 filter
    $scope.admin2Filter = function () {
        // filter on menu expects an integer
        $scope.admin2Selection = parseInt($scope.admin2Selection, 10);
    };

    // on selection of location checkbox, toggle feature selected
    // required because we are using dynamic HTML and cannot use md-checkboxes ng-model
    $scope.selectedLocation = function (id) {
        var location;
        // toggle feature based on admin level
        switch ($scope.dialogSettings.admin_level) {
            case 1:
                // find the feature location by id
                location = _.find($scope.menu.boundaries, function (b) { return b.id === id; });
                if (location) {
                    location.selected = !location.selected;
                }
                break;
            case 2:
                _.each($scope.menu.boundaries, function (admin1) {
                    // find the feature location by id
                    location = _.find(admin1.b, function (b) { return b.id === id; });
                    if (location) {
                        location.selected = !location.selected;
                    }
                });
                break;
            case 3:
                _.each($scope.menu.boundaries, function (admin1) {
                    _.each(admin1.b, function (admin2) {
                        // find the feature location by id
                        location = _.find(admin2.b, function (b) { return b.id === id; });
                        if (location) {
                            location.selected = !location.selected;
                        }
                    });
                });
                break;
        }
    };

    // private function to initialize module
    function init() {
        // set loading true
        $scope.loadingLocations = true;
        // initialize the menu
        $scope.menu = editorService.getBoundaryMenu();
        // if the list is empty then it is the first call, lets populated it
        if (_.isNull($scope.menu)) {
            //  get the options from the service        
            editorService.getBoundaryHierarchy($scope.settings.location.boundary_type, $scope.settings.location.admin_levels, null, null).then(function (menu) {
                $scope.menu = menu;
                prepareMenu().then(function () {
                    $scope.loadingLocations = false;
                    var html = generateMenu();
                    $scope.menuUI = html;
                    blockUI.stop();
                });
            });
        }
        else {
            prepareMenu().then(function () {
                $scope.loadingLocations = false;
                var html = generateMenu();
                $scope.menuUI = html;
                blockUI.stop();
            });
        }
    }

    // private function to loop through boundary heirachy to 
    // set active/selected settings for each feature
    function prepareMenu() {
        var deferred = $q.defer();
        // loop through admin 1 level boundaries
        _.each($scope.menu.boundaries, function (admin1) {
            // get a list of the admin 1 locations already assigned to activity
            var admin1Ids = _.pluck(_.filter($scope.dialogSettings.activity.locations.admin1, function (a) { return a.delete === false; }), 'feature_id');
            // set features active/selected settings appropriately
            if (_.contains(admin1Ids, admin1.id)) {
                admin1.active = false;
                admin1.selected = false;
            }
            else {
                admin1.active = true;
                admin1.selected = false;
            }
            // if the hierachy contains a admin 2 boundary, process
            if (admin1.b) {
                // loop through admin 2 level boundaries
                _.each(admin1.b, function (admin2) {
                    // get a list of the admin 2 locations already assigned to activity
                    var admin2Ids = _.pluck(_.filter($scope.dialogSettings.activity.locations.admin2, function (a) { return a.delete === false; }), 'feature_id');
                    // set features active/selected settings appropriately
                    if (_.contains(admin2Ids, admin2.id)) {
                        admin2.active = false;
                        admin2.selected = false;
                    }
                    else {
                        admin2.active = true;
                        admin2.selected = false;
                    }
                    // if the hierachy contains a admin 3 boundary, process
                    if (admin2.b) {
                        // loop through admin 3 level boundaries
                        _.each(admin2.b, function (admin3) {
                            // get a list of the admin 3 locations already assigned to activity
                            var admin3Ids = _.pluck(_.filter($scope.dialogSettings.activity.locations.admin3, function (a) { return a.delete === false; }), 'feature_id');
                            // set features active/selected settings appropriately
                            if (_.contains(admin3Ids, admin3.id)) {
                                admin3.active = false;
                                admin3.selected = false;
                            }
                            else {
                                admin3.active = true;
                                admin3.selected = false;
                            }
                        });
                        deferred.resolve();
                    }
                    else {
                        deferred.resolve();
                    }
                });
            }
            else {
                deferred.resolve();
            }
        });
        return deferred.promise;
    }

    // private function to dynamically generate the HTML for
    // the menu (listing of boundary features)
    // using this approach over ng-repeat because the boundary heirachy is 
    // a very large object and ng-repeat causes extream performance issues
    function generateMenu() {
        // the HTML for the menu
        var menuHTML = '';
        // build menu for the requested admin level
        switch ($scope.dialogSettings.admin_level) {
            // admin 1
            case 1:
                _.each($scope.menu.boundaries, function (admin1) {
                    if (admin1.active) {
                        menuHTML += '<md-checkbox ng-click="selectedLocation(' + admin1.id + ')">' + admin1.n + '</md-checkbox>';
                    }
                });
                break;
            // admin 2
            case 2:
                _.each($scope.menu.boundaries, function (admin1) {
                    var hasAdmin2 = _.filter(admin1.b, function (b) { return b.active; });
                    if (hasAdmin2.length > 0) {
                        menuHTML += '<md-subheader class="md-no-sticky">' + admin1.n + '</md-subheader><md-divider></md-divider> <div layout="column" layout-wrap flex class="checkbox-section">';
                        _.each(admin1.b, function (admin2) {
                            if (admin2.active) {
                                menuHTML += '<md-checkbox ng-click="selectedLocation(' + admin2.id + ')">' + admin2.n + '</md-checkbox>';
                            }
                        });
                        menuHTML += '</div>';
                    }
                });
                break;
            // admin 3
            case 3:
                // admin 3 has two dropdown filters for admin 1 & 2
                $scope.admin1List = [];
                $scope.admin2List = [];
                _.each($scope.menu.boundaries, function (admin1) {
                    $scope.admin1List.push({ id: admin1.id, n: admin1.n });
                    menuHTML += '<md-subheader class="md-no-sticky" ng-show="admin1Selection===null || admin1Selection===' + admin1.id + '">' + admin1.n + '</md-subheader ng-show="admin1Selection===null || admin1Selection===' + admin1.id + '"><md-divider ng-show="admin1Selection===null || admin1Selection===' + admin1.id + '"></md-divider><div class="sub-section" ng-show="admin1Selection===null || admin1Selection===' + admin1.id + '">';
                    _.each(admin1.b, function (admin2) {
                        var hasAdmin3 = _.filter(admin2.b, function (b) { return b.active; });
                        if (hasAdmin3.length > 0) {
                            $scope.admin2List.push({ id: admin2.id, n: admin2.n, p: admin1.id });
                            menuHTML += '<md-subheader class="md-no-sticky" ng-show="admin2Selection===null || admin2Selection===' + admin2.id + '" ng-hide="' + admin2.empty + '">' + admin2.n + '</md-subheader ng-show="admin2Selection===null || admin2Selection===' + admin2.id + '"><md-divider ng-show="admin2Selection===null || admin2Selection===' + admin2.id + '"></md-divider> <div layout="column" layout-wrap flex class="checkbox-section" ng-show="admin2Selection===null || admin2Selection===' + admin2.id + '">';
                            _.each(admin2.b, function (admin3) {
                                if (admin3.active) {
                                    menuHTML += '<md-checkbox ng-click="selectedLocation(' + admin3.id + ')">' + admin3.n + '</md-checkbox>';
                                }
                            });
                            menuHTML += '</div>';
                        }
                    });
                    menuHTML += '</div>';
                });
                break;
        }
        return menuHTML;
    }
});