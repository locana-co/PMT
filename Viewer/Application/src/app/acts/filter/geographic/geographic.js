/***************************************************************
 * Geographic Controller
 * A filter controller. Supports the filtering activities by
 * a geographic feature. Usage is defined in the app.config in 
 * the activity page filter object.
* *************************************************************/
angular.module('PMTViewer').controller('ActFilterGeographicCtrl', function ($scope, $element, activityService, boundaryService) {
    var initialized = false;
    var dataGroupIds = null;
    $scope.loading = true;
    $scope.menuUI = null;

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
        validateActive();
    });

    // toggle filter menus open/closed
    $scope.onMenuClicked = function (b0, b1, b2, b3) {
        if (b0) {
            var boundary0;
            // get the requested level zero object
            boundary0 = _.find($scope.filter.options.boundaries, function (b) {
                return b.id == b0;
            });
            // level zero was clicked
            if (b1 === null && b2 === null && b3 === null && $scope.boundaryKeys.length > 1) {
                boundary0.active = !boundary0.active;
            }
            // level 1 or greater was clicked
            if (b1 && boundary0) {
                var boundary1;
                // get the requested level one object
                boundary1 = _.find(boundary0.b, function (b) {
                    return b.id == b1;
                });
                // level one was clicked
                if (b2 === null && b3 === null && $scope.boundaryKeys.length > 2) {
                    boundary1.active = !boundary1.active;
                }
                // level 2 or greater was clicked
                if (b2 && boundary0 && boundary1) {
                    var boundary2;
                    // get the requested level two object
                    boundary2 = _.find(boundary1.b, function (b) {
                        return b.id == b2;
                    });
                    // level two was clicked
                    if (b3 === null && $scope.boundaryKeys.length > 3) {
                        boundary2.active = !boundary2.active;
                    }
                    // level three was clicked (this is the deepest level supported)
                    if (b3 && boundary0 && boundary1 && boundary2) {
                        var boundary3;
                        boundary3 = _.find(boundary2.b, function (b) {
                            return b.id == b3;
                        });
                        boundary3.active = !boundary3.active;
                    }
                }
            }
            $scope.menuUI = updateMenu(0, b0, b1, b2, b3);
        }
    };

    // menu option selected/unselected
    $scope.onMenuSelected = function (b0, b1, b2, b3) {
        if (b0) {
            var boundary0;
            // get the requested level zero object
            boundary0 = _.find($scope.filter.options.boundaries, function (b) {
                return b.id == b0;
            });
            // level zero was clicked
            if (b1 === null && b2 === null && b3 === null) {
                boundary0.selected = !boundary0.selected;
                if (boundary0.b) {
                    // toggle all child boundaries true/false
                    _.each(boundary0.b, function (level1) {
                        level1.selected = boundary0.selected === true ? true : false;
                        if (level1.b) {
                            _.each(level1.b, function (level2) {
                                level2.selected = boundary0.selected === true ? true : false;
                                if (level2.b) {
                                    _.each(level2.b, function (level3) {
                                        level3.selected = boundary0.selected === true ? true : false;
                                    });
                                }
                            });
                        }
                    });
                }
            }
            // level 1 or greater was clicked
            if (b1 && boundary0) {
                var boundary1;
                // get the requested level one object
                boundary1 = _.find(boundary0.b, function (b) {
                    return b.id == b1;
                });
                // level one was clicked
                if (b2 === null && b3 === null) {
                    boundary1.selected = !boundary1.selected;
                    if (boundary1.b) {
                        // toggle all child boundaries true/false
                        _.each(boundary1.b, function (level2) {
                            level2.selected = boundary1.selected === true ? true : false;
                            if (level2.b) {
                                _.each(level2.b, function (level3) {
                                    level3.selected = boundary1.selected === true ? true : false;
                                });
                            }
                        });
                    }
                    if (!boundary1.selected) {
                        boundary0.selected = false;
                    }
                }
                // level 2 or greater was clicked
                if (b2 && boundary0 && boundary1) {
                    var boundary2;
                    // get the requested level two object
                    boundary2 = _.find(boundary1.b, function (b) {
                        return b.id == b2;
                    });
                    // level two was clicked
                    if (b3 === null) {
                        boundary2.selected = !boundary2.selected;
                        if (boundary2.b) {
                            // toggle all child boundaries true/false
                            _.each(boundary2.b, function (level3) {
                                level3.selected = boundary2.selected === true ? true : false;
                            });
                        }
                        if (!boundary2.selected) {
                            boundary0.selected = false;
                            boundary1.selected = false;
                        }
                    }
                    // level three was clicked (this is the deepest level supported)
                    if (b3 && boundary0 && boundary1 && boundary2) {
                        var boundary3;
                        boundary3 = _.find(boundary2.b, function (b) {
                            return b.id == b3;
                        });
                        if (!boundary3.selected) {
                            boundary0.selected = false;
                            boundary1.selected = false;
                            boundary2.selected = false;
                        }
                    }
                }
            }
            $scope.prepareFilter();
            $scope.menuUI = updateMenu(0, b0, b1, b2, b3);
        }
    };

    // prepare selected filters and update activityService    
    $scope.prepareFilter = function () {
        // filter must be in json format as array of objects
        // each object must contain "b" as boundary id and "ids" as an
        // array of feature ids
        // (i.e. [{"b":12,"ids":[2,3]},{"b":13,"ids":[73,85]}])
        var filter = [];
        _.each($scope.filter.options, function (value, key, list) {
            if (key !== 'boundaries') {
                var filterObject = {
                    "b": value,
                    "ids": []
                };
                filter.push(filterObject);
            }
        });
        _.each($scope.filter.options.boundaries, function (boundary0) {
            if (boundary0.selected) {
                filter[0].ids.push(boundary0.id);
            }
            if (boundary0.b) {
                _.each(boundary0.b, function (boundary1) {
                    if (boundary1.selected) {
                        filter[1].ids.push(boundary1.id);
                    }
                    if (boundary1.b) {
                        _.each(boundary1.b, function (boundary2) {
                            if (boundary2.selected) {
                                filter[2].ids.push(boundary2.id);
                            }
                            if (boundary2.b) {
                                _.each(boundary2.b, function (boundary3) {
                                    if (boundary3.selected) {
                                        filter[3].ids.push(boundary3.id);
                                    }
                                });
                            }
                        });
                    }
                });
            }
        });
        var boundaryFilters = _.filter(filter, function (f) { return f.ids.length > 0; });
        if (boundaryFilters.length > 0) {
            activityService.setBoundaryFilter(boundaryFilters);
        }
        else {
            activityService.removeBoundaryFilter();
        }
    };

    // validate active selections
    function validateActive() {
        if ($scope.filter.enable) {
            // get the active boundary filters
            var filters = activityService.getBoundaryFilters();
            // no filters are in place ensure all options are unselected
            if (filters === null && $scope.filter.options) {
                _.each($scope.filter.options.boundaries, function (boundary0) {
                    // set selected to false
                    boundary0.selected = false;
                    // loop through the next boundary level, unless its the last level
                    if (boundary0.b) {
                        _.each(boundary0.b, function (boundary1) {
                            // set selected to false
                            boundary1.selected = false;
                            // loop through the next boundary level, unless its the last level
                            if (boundary1.b) {
                                _.each(boundary1.b, function (boundary2) {
                                    // set selected to false
                                    boundary2.selected = false;
                                    // loop through the next boundary level, unless its the last level
                                    // supporting only up to 4 levels (0-3)
                                    if (boundary2.b) {
                                        _.each(boundary2.b, function (boundary3) {
                                            // set selected to false
                                            boundary3.selected = false;
                                        });
                                    }
                                });
                            }
                        });
                    }
                });
            }
        }
    }

    // private function to dynamically generate the HTML for
    // the menu (listing of boundary features)
    // using this approach over ng-repeat because the boundary heirachy is 
    // a very large object and ng-repeat causes extreme performance issues
    function updateMenu(level, sb0, sb1, sb2, sb3) {
        // the HTML for the menu
        var menuHTML = '';
        // loop through level 0 boundaries
        _.each($scope.filter.options.boundaries, function (b0) {
            // create level 0 menu
            menuHTML += '<div id="b0_menu_' + b0.id + '" class="menu-option">';
            menuHTML += '<md-checkbox class="menu-checkbox" ng-checked="' + b0.selected + '" aria-label="Select All" ng-click="onMenuSelected(' + b0.id + ',null,null,null)"></md-checkbox>';
            menuHTML += '<div class="boundary-name" ng-click="onMenuClicked(' + b0.id + ',null,null,null);">' + b0.n + '</div>';
            if (b0.b) {
                menuHTML += '<div id="b0_arrow' + b0.id + '" class="arrow" ng-click="onMenuClicked(' + b0.id + ',null,null,null);">';
                if (b0.active) {
                    menuHTML += '<i class="material-icons">keyboard_arrow_up</i></div>';
                }
                else {
                    menuHTML += '<i class="material-icons">keyboard_arrow_down</i></div>';
                }
            }
            // generate menu if selected feature is active
            if (b0.active) {
                // create level 1 menu
                menuHTML += '<div id="b0_opt_' + b0.id + '" class="menu-option level-1">';
                _.each(b0.b, function (b1) {
                    menuHTML += '<div><md-checkbox class="menu-checkbox" ng-checked="' + b1.selected + '" aria-label="Select All" ng-click="onMenuSelected(' + b0.id + ',' + b1.id + ',null,null)"></md-checkbox>';
                    menuHTML += '<div class="boundary-name" ng-click="onMenuClicked(' + b0.id + ',' + b1.id + ',null,null);">' + b1.n + '</div>';
                    if (b1.b) {
                        menuHTML += '<div id="b1_arrow' + b1.id + '" class="arrow" ng-click="onMenuClicked(' + b0.id + ',' + b1.id + ',null,null);">';
                        if (b1.active) {
                            menuHTML += '<i class="material-icons">keyboard_arrow_up</i></div>';
                        }
                        else {
                            menuHTML += '<i class="material-icons">keyboard_arrow_down</i></div>';
                        }
                    }
                    var selected1 = _.find(b0.b, function (b) { return b.id === sb1; });
                    // generate menu if selected feature is active
                    if (b1.active) {
                        // create level 2 menu
                        menuHTML += '<div id="b1_opt_' + b1.id + '" class="menu-option level-2">';
                        _.each(b1.b, function (b2) {
                            menuHTML += '<div><md-checkbox class="menu-checkbox" ng-checked="' + b2.selected + '" aria-label="Select All" ng-click="onMenuSelected(' + b0.id + ',' + b1.id + ',' + b2.id + ',null)"></md-checkbox>';
                            menuHTML += '<div class="boundary-name" ng-click="onMenuClicked(' + b1.id + ',' + b2.id + ',null,null);">' + b2.n + '</div>';
                            if (b2.b) {
                                menuHTML += '<div id="b1_arrow' + b2.id + '" class="arrow" ng-click="onMenuClicked(' + b1.id + ',' + b2.id + ',null,null);">';
                                if (b2.active) {
                                    menuHTML += '<i class="material-icons">keyboard_arrow_up</i></div>';
                                }
                                else {
                                    menuHTML += '<i class="material-icons">keyboard_arrow_down</i></div>';
                                }
                            }
                            menuHTML += '</div>';
                        });
                        menuHTML += '</div>'; // level 1 - options
                    }
                    menuHTML += '</div>'; // level 2
                });
                menuHTML += '</div>'; // level 0 - options
            }
            menuHTML += '</div>'; // level 0
        });
        return menuHTML;
    }

    // geographic filter initialization
    function init() {
        $scope.filter.options = activityService.boundaryMenu;
        if ($scope.filter.enable) {
            // initialize the filter if it has not been initialized
            if ($scope.filter && !$scope.filter.options) {
                $scope.filter.disabled = true;
                // get current data group ids, order by id
                var activeDataGroupIds = _.sortBy(activityService.getDataGroupFilters(), function (id) { return Math.sin(id); });
                // using the pmt map service, get all the classifications for the filter
                boundaryService.getBoundaryMenu($scope.filter.params.boundary_type,
                    $scope.filter.params.admin_levels, $scope.filter.params.filter_features, activeDataGroupIds.join(','))
                    .then(function (menu) {
                        // save the filter menu to the service
                        activityService.boundaryMenu = menu;
                        $scope.filter.options = activityService.boundaryMenu;
                        // get the boundary keys for the menu (b0,b1,b2,etc.)
                        $scope.boundaryKeys = _.keys($scope.filter.options);
                        $scope.boundaryKeys.pop();
                        // activate options that are listed in state
                        _.each($scope.filter.options.boundaries, function (boundary0) {
                            // set selected to false
                            boundary0.selected = false;
                            if ($scope.boundaryKeys.length > 1) {
                                // set active to false
                                boundary0.active = false;
                                // set active arrow
                                boundary0.arrow = boundary0.b === null ? null : "keyboard_arrow_down";
                            }
                            // loop through the next boundary level, unless its the last level
                            if (boundary0.b) {
                                _.each(boundary0.b, function (boundary1) {
                                    // set selected to false
                                    boundary1.selected = false;
                                    if ($scope.boundaryKeys.length > 2) {
                                        // set active to false
                                        boundary1.active = false;
                                        // set active arrow
                                        boundary1.arrow = boundary1.b === null ? null : "keyboard_arrow_down";
                                    }
                                    // loop through the next boundary level, unless its the last level
                                    if (boundary1.b) {
                                        _.each(boundary1.b, function (boundary2) {
                                            // set selected to false
                                            boundary2.selected = false;
                                            if ($scope.boundaryKeys.length > 3) {
                                                // set active to false
                                                boundary2.active = false;
                                                // set active arrow
                                                boundary2.arrow = boundary2.b === null ? null : "keyboard_arrow_down";
                                            }
                                            // loop through the next boundary level, unless its the last level
                                            // supporting only up to 4 levels (0-3)
                                            if (boundary2.b) {
                                                _.each(boundary2.b, function (boundary3) {
                                                    // set selected to false
                                                    boundary3.selected = false;
                                                });
                                            }
                                        });
                                    }
                                });
                            }
                        });
                        // set the filter size
                        $scope.filter.size = $scope.filter.options.boundaries.length;
                        $scope.loading = false;
                        $scope.filter.disabled = false;
                        $scope.menuUI = updateMenu(0, null, null, null, null);
                    });
            }
            else {
                // get the boundary keys for the menu (b0,b1,b2,etc.)
                $scope.boundaryKeys = _.keys($scope.filter.options);
                $scope.boundaryKeys.pop();
                $scope.menuUI = updateMenu(0, null, null, null, null);
                $scope.loading = false;

            }
        }
    }

    // initialize filter
    init();
});