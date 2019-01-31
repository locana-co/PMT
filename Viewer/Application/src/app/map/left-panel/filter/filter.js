/***************************************************************
 * Map Page Filter Controller
 * Supports the filter controller. The filter controller houses
 * all the individual filters configured to be used by the 
 * app.config. Each filter is a seperate feature and the filter
 * contoller provides a tab for each filter in use and clearing
 * all filters button. All developed filter features must have
 * a filter clearing function.
* *************************************************************/
angular.module('PMTViewer').controller('MapFilterCtrl', function ($scope, $rootScope, stateService, pmtMapService) {

    $scope.stateService = stateService;
    $scope.filterCount = 0;

    // initialization
    init();

    // when the pmt map filter changes do this
    $scope.$on('pmt-filter-update', function () {
        init();
    });

    // when the url is updated do this
    $scope.$on('route-update', function () {
        if (stateService.isNotParam('left-panel')) { $scope.sideoutOpen = false; }
    });

    // menu option clicked
    $scope.onMenuClicked = function (id) {
        // get the active filter by id
        $scope.activeFilter = _.find($scope.page.tools.map.filters, function (filter) {
            return filter.id == id;
        });
        $scope.sideoutOpen = true;
        $scope.resizeLeftPanel();
        // broadcast that a filter menu has been selected
        $rootScope.$broadcast('filter-menu-selected', id);
    };

    // close the sub menu
    $scope.closeSlideOut = function () {
        $scope.sideoutOpen = false;
    };

    // remove filter when removed from UI selection panel
    $scope.removeFilter = function (filter) {
        // call the appropriate function based on the filter type
        switch (filter.type) {
            // remove a funding organization filter
            case "fund":
                pmtMapService.removeFundOrgFilter(filter.id);
                break;
            // remove a implementing organization filter
            case "imp":
                pmtMapService.removeImpOrgFilter(filter.id);
                break;
            // remove an organization filter
            case "org":
                pmtMapService.removeOrgFilter(filter.id);
                break;
            // remove an unassigned taxonomy filter
            case "unassigned":
                pmtMapService.removeUnassignedTaxonomyFilter(filter.id);
                break;
            // remove all boundary filters
            case "boundary":
                pmtMapService.removeBoundaryFilter();
                break;
            // remove the keyword filter
            case "keyword":
                pmtMapService.removeKeywordFilter();
                $scope.keyword = null;
                break;
            // remove a classification filter (taxonomy)
            default:
                pmtMapService.removeClassificationFilter(filter.id);
                break;
        }
    };

    // function to clear all filters
    $scope.removeAllFilters = function () {
        var selectedFilters = pmtMapService.getSelectedFilters();
        // filter count is 0
        $scope.filterCount = 0;
        // remove each filter
        _.each(selectedFilters, function (filter) {
            $scope.removeFilter(filter);
        });
    };

    // update the activity service with a keyword string to filter activities
    $scope.filterByKeyword = function (keyword) {
        pmtMapService.setKeywordFilter(keyword);
    };

    // clear the keyword filter
    $scope.clearKeywordFilter = function () {
        if ($scope.keyword.length === 0) {
            pmtMapService.removeKeywordFilter();
        }
    };

    // initialization function for filters
    function init() {
        // loop through filters and get defaults (taxonomy only)
        _.each($scope.page.tools.map.filters, function (filter) {
            if (_.contains(_.keys(filter.params), 'defaults') && !_.contains(_.keys(filter), 'initialized')) {
                // determine from config if classifications for filter should be in-use only
                var inuse = filter.params.inuse || false;
                // get the data groups currently in use (on the map)
                var dataGroupIds = pmtMapService.getDataGroupIds();
                // using the pmt map service, get all the classifications for the filter
                pmtMapService.getTaxonomy(filter.params.taxonomy_id, inuse)
                    .then(function (classifications) {
                        // apply filter to taxonomy classifications if filter exists
                        if (filter.params.filter) {
                            if (filter.params.filter.length > 0) {
                                classifications = _.filter(classifications, function (c) {
                                    return _.contains(filter.params.filter, c.id);
                                });
                            }
                        }
                        // sort the classifications by name
                        classifications = _.sortBy(classifications, 'c');
                        // capital case the classification
                        classifications = _.each(classifications, function (c) {
                            c.c = c.c.toLowerCase();
                            c.c = c.c.capitalizeFirstLetter();
                        });
                        // if there are default settings in the config
                        // loop through the classifications and set them to active
                        if (filter.params.defaults.length > 0) {
                            _.each(classifications, function (cls) {
                                if (_.contains(filter.params.defaults, cls.id)) {
                                   cls.active = true;
                                }
                            });
                        }
                        // assign the prepared variables to scope
                        filter.options = classifications;
                        // set the filter size
                        filter.size = filter.options.length;
                        // set default filter
                        pmtMapService.setClassificationFilter(filter.params.taxonomy_id, filter.params.defaults);
                    });
            }
            filter = _.extend(filter, { "initialized": true });
        });
        // reset selected filters
        $scope.selectedFilters = pmtMapService.getSelectedFilters();
        $scope.filterCount = Object.keys($scope.selectedFilters).length;
        $scope.resizeLeftPanel();
    }

});
// all templates used by the left panel filter
require('./geographic/geographic.js');
require('./datasource/datasource.js');
require('./organization/organization.js');
require('./taxonomy/taxonomy.js');