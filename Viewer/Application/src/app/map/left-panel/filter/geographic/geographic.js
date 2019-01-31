/***************************************************************
 * Geographic Controller
 * A filter controller. Supports the filter of PMT layers by 
 * geographic features. Usage is defined in the app.config
 * in the map page filter object.
* *************************************************************/
angular.module('PMTViewer').controller('MapFilterGeographicCtrl', function ($scope, $element, pmtMapService, boundaryService) {

    var initialized = false;
    var dataGroupIds = null;
    $scope.loading = true;

    // when the selected filter changes do this
    $scope.$on('pmt-filter-update', function () {
        validateActive();
    });

    // when the selected filter changes do this
    $scope.$on('filter-menu-selected', function () {
        // intitalize the template
        init();
    });

    // menu option selected/unselected
    $scope.onMenuSelected = function (b0, b1, b2, b3) {
        if (b0) {
            var boundary0;
            // get the requested level zero object
            boundary0 = _.find($scope.geographies.boundaries, function (b) {
                return b.id == b0;
            });
            // level zero was clicked
            if (b1 === null && b2 === null && b3 === null) {
                if (boundary0.b) {
                    // toggle all child boundaries true/false
                    _.each(boundary0.b, function (level1) {
                        level1.selected = boundary0.selected === true ? false : true;
                        if (level1.b) {
                            _.each(level1.b, function (level2) {
                                level2.selected = boundary0.selected === true ? false : true;
                                if (level2.b) {
                                    _.each(level2.b, function (level3) {
                                        level3.selected = boundary0.selected === true ? false : true;
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
                    if (boundary1.b) {
                        // toggle all child boundaries true/false
                        _.each(boundary1.b, function (level2) {
                            level2.selected = boundary1.selected === true ? false : true;
                            if (level2.b) {
                                _.each(level2.b, function (level3) {
                                    level3.selected = boundary1.selected === true ? false : true;
                                });
                            }
                        });
                    }
                    if (boundary1.selected) {
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
                        if (boundary2.b) {
                            // toggle all child boundaries true/false
                            _.each(boundary2.b, function (level3) {
                                level3.selected = boundary2.selected === true ? false : true;
                            });
                        }
                        if (boundary2.selected) {
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
                        if (boundary3.selected) {
                            boundary0.selected = false;
                            boundary1.selected = false;
                            boundary2.selected = false;
                        }
                    }
                }
            }
        }
    };

    // toggle filter menus open/closed
    $scope.onMenuClicked = function (b0, b1, b2, b3) {
        if (b0) {
            var boundary0;
            // get the requested level zero object
            boundary0 = _.find($scope.geographies.boundaries, function (b) {
                return b.id == b0;
            });
            // level zero was clicked
            if (b1 === null && b2 === null && b3 === null && $scope.boundaryKeys.length > 1) {
                boundary0.active = !boundary0.active;
                if (boundary0.b != null) {
                    boundary0.arrow = (boundary0.active) ? "keyboard_arrow_up" : "keyboard_arrow_down";
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
                if (b2 === null && b3 === null && $scope.boundaryKeys.length > 2) {
                    boundary1.active = !boundary1.active;
                    if (boundary1.b != null) {
                        boundary1.arrow = (boundary1.active) ? "keyboard_arrow_up" : "keyboard_arrow_down";
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
                    if (b3 === null && $scope.boundaryKeys.length > 3) {
                        boundary2.active = !boundary2.active;
                        if (boundary2.b != null) {
                            boundary2.arrow = (boundary2.active) ? "keyboard_arrow_up" : "keyboard_arrow_down";
                        }
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
        }
    };

    // prepare selected filters and update pmtMapService    
    $scope.prepareFilter = function () {
        // filter must be in json format as array of objects
        // each object must contain "b" as boundary id and "ids" as an
        // array of feature ids
        // (i.e. [{"b":12,"ids":[2,3]},{"b":13,"ids":[73,85]}])
        var filter = [];
        _.each($scope.geographies, function (value, key, list) {
            if (key !== 'boundaries') {
                var filterObject = {
                    "b": value,
                    "ids": []
                };
                filter.push(filterObject);
            }
        });
        _.each($scope.geographies.boundaries, function (boundary0) {
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
            pmtMapService.setBoundaryFilter(boundaryFilters);
        }
        else {
            pmtMapService.removeBoundaryFilter();
        }
    };

    // validate active selections
    function validateActive() {
        if ($scope.geographies) {
            // get the active boundary filters
            var filters = pmtMapService.getBoundaryFilters();
            // no filters are in place ensure all options are unselected
            if (filters === null) {
                _.each($scope.geographies.boundaries, function (boundary0) {
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

    // geographic filter initialization
    function init() {
        var activeDataGroupIds = pmtMapService.getDataGroupIds();
        // if the selected data groups have changed update or if the filter hasn't been
        // initialized then update the organization list
        if (!_.isEqual(dataGroupIds, activeDataGroupIds) || !initialized) {
            $scope.loading = true;
            // get the data groups currently in use (on the map)
            dataGroupIds = pmtMapService.getDataGroupIds();
            // get the id of the div (which is the filter id value from the config)
            var filterId = $($element[0]).parent().attr("id");
            // get the filter by id from the config
            $scope.filter = _.find($scope.page.tools.map.filters, function (filter) { return filter.id == filterId; });
            // if the filter is valid
            if ($scope.filter) {
                // using the pmt map service, get all the classifications for the filter
                boundaryService.getBoundaryMenu($scope.filter.params.boundary_type,
                    $scope.filter.params.admin_levels, $scope.filter.params.filter_features, dataGroupIds.join(','))
                    .then(function (menu) {
                        $scope.geographies = menu;
                        // get the boundary keys for the menu (b0,b1,b2,etc.)
                        $scope.boundaryKeys = _.keys($scope.geographies);
                        $scope.boundaryKeys.pop();
                        // activate options that are listed in state
                        _.each($scope.geographies.boundaries, function (boundary0) {
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
                        $scope.loading = false;
                        // set init flag true
                        initialized = true;
                    });
            }
        }
    }

    // initialize filter
    init();

});