/***************************************************************
 * Locations Page Filter Controller
 * Supports the filter controller. The filter controller houses
 * all the individual filters configured to be used by the 
 * app.config. Each filter is a seperate feature and the filter.
 * *************************************************************/
angular.module('PMTViewer').controller('LocsFilterCtrl', function ($scope, $rootScope, stateService, config, locsService) {

    $scope.stateService = stateService;
    $scope.filterCount = 0;

    // initialization
    init();

    // when the location service filter is updated, to this
    $scope.$on('locs-filter-update', function () {
        refresh();
    });

    // when the location options are updated is updated, to this
    $scope.$on('locs-filter-options-update', function () {
        refresh();
    });

    // menu option clicked (toggle filter menus)
    $scope.onMenuClicked = function (id) {
        // get the active filter by id
        var activeFilter = _.find($scope.page.tools.map.filters, function (filter) {
            return filter.id == id;
        });
        // if filter active, make it inactive
        if (activeFilter.active) {
            activeFilter.active = false;
            activeFilter.arrow = "keyboard_arrow_down";
        }
        // otherwise make all filters inactive except for selected one
        else {
            // make all filters inactive so only one is active at a time
            _.each($scope.page.tools.map.filters, function (filter) {
                filter.active = false;
                filter.arrow = "keyboard_arrow_down";
            });
            // make filter active
            activeFilter.active = true;
            activeFilter.arrow = "keyboard_arrow_up";
        }
    };

    // when clicking on filter from selection area, remove it
    $scope.removeFilter = function (filter) {
        // call the appropriate function based on the filter type
        switch (filter.type) {
            // remove an unassigned taxonomy filter
            case "unassigned":
                locsService.removeUnassignedTaxonomyFilter(filter.id);
                break;
            // remove a start date
            case "startDate":
                locsService.removeStartDateFilter();
                break;
            // remove a start date
            case "endDate":
                locsService.removeEndDateFilter();
                break;
            // remove a classification filter (taxonomy)
            default:
                locsService.removeClassificationFilter(filter.id);
                break;
        }
    };

    //function to clear all filters
    $scope.removeAllFilters = function () {
        var selectedFilters = locsService.getSelectedFilters();
        //filter count is 0
        $scope.filterCount = 0;
        //remove each filter
        _.each(selectedFilters, function (filter) {
            if (filter.type != 'dataGroup') {
                $scope.removeFilter(filter);
            }
        });
    };

    // refresh filters function
    function refresh() {
        // reset selected filters
        $scope.selectedFilters = locsService.getSelectedFilters();
        $scope.filterCount = Object.keys($scope.selectedFilters).length;
    }

    // initialization function for filters
    function init() {
        var filters = {
            data_group_ids: null,
            taxonomy_filter: null,
            start_date: null
        };
        // loop through the filters and set any default values
        _.each($scope.page.tools.map.filters, function (filter) {
            // set the arrow based on default active params
            filter.arrow = filter.active ? "keyboard_arrow_up" : "keyboard_arrow_down";
            // collect default settings for each filter type
            switch (filter.type) {
                case 'datasource':
                    // loop through all the data sources and add all active data sources
                    _.each(filter.params.dataSources, function (dataSource) {
                        if (dataSource.active) {
                            // split dataGroupIds string into array
                            var dataGroupIds = dataSource.dataGroupIds.split(",");
                            // add the data groups to our filters
                            filters.data_group_ids = _.union(filters.data_group_ids, dataGroupIds);
                        }
                    });
                    break;
                case 'taxonomy':
                    if (filter.params.defaults.length > 0) {
                        var taxonomy_filter = {
                            taxonomy_id: filter.params.taxonomy_id,
                            classification_ids: filter.params.defaults
                        };
                        // add the taxonomy filter to our filters
                        if (filters.taxonomy_filter === null) {
                            filters.taxonomy_filter = [];
                            filters.taxonomy_filter.push(taxonomy_filter);
                        }
                        else {
                            filters.taxonomy_filter.push(taxonomy_filter);
                        }
                    }
                    break;
                case 'date':
                    if (_.has(filter.params, "start_date")) {
                        if (new Date(filter.params.start_date).toString() !== "Invalid Date") {
                            filters.start_date = new Date(filter.params.start_date);
                        }
                    }
                    break;
                default:
                    break;
            }
        });
        // send the collected filters to the location service
        locsService.setFilters(filters.data_group_ids, filters.taxonomy_filter, filters.start_date, null, null);
    }

});

// all templates used by the filter:
require('./datasource/datasource.js');
require('./date/date.js');
require('./taxonomy/taxonomy.js');