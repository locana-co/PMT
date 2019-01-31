/***************************************************************
 * Overview Widget Controller
 * Supports the overview summary widget.
 ***************************************************************/
angular.module('PMTViewer').controller('LocsWidgetOverviewCtrl', function($scope, analysisService, locsService, $stateParams) {

    // initialization function for overview widget
    function init() {
        $scope.loading = true;
        //get id from layer lookup
        var boundary_id = _.filter($scope.page.tools.map.supportingLayers, function(layer) { return layer.alias == 'gadm0'; })[0].boundary_id;
        // get feature id from current selection
        var feature_ids = [];
        // loop through the countries in the map and collect the ids
        _.each($scope.page.tools.map.countries, function(country) {
            if (country.id) {
                feature_ids.push(country.id);
            }
        });
        // loop through the overview statuses
        _.each($scope.widget.params.overview, function(overview) {
            // if using the map filter then apply the summary page map's 
            // country list to the filter
            if (overview.mapFilter) {
                // call the analysis service to get the overview statistics
                analysisService.getOverviewStats(
                    locsService.getDataGroupFilters().join(','),
                    locsService.getClassificationFilters().join(','),
                    locsService.getStartDateFilter(),
                    locsService.getEndDateFilter(),
                    boundary_id,
                    feature_ids.join(',')
                ).then(function(data) {
                    // loop through the overview's stats and apply values
                    _.each(overview.stats, function(stat) {
                        var result = _.first(_.pluck(data, stat.statistic));
                        switch (stat.statistic) {
                            case 'total_investment':
                                // format the investment result
                                _.extend(stat, { "count": locsService.abbreviateMoney(result) });
                                break;
                            default:
                                _.extend(stat, { "count": result });
                                break;
                        }
                    });
                    $scope.loading = false;
                });
            }
            // if NOT using the map filter then do not pass any boundary filters
            else {
                // call the analysis service to get the overview statistics
                analysisService.getOverviewStats(
                    locsService.getDataGroupFilters().join(','),
                    locsService.getClassificationFilters().join(','),
                    locsService.getStartDateFilter(),
                    locsService.getEndDateFilter(),
                    null,
                    null
                ).then(function(data) {
                    // loop through the overview's stats and apply values
                    _.each(overview.stats, function(stat) {
                        var result = _.first(_.pluck(data, stat.statistic));
                        switch (stat.statistic) {
                            case 'total_investment':
                                // format the investment result
                                _.extend(stat, { "count": locsService.abbreviateMoney(result) });
                                break;
                            default:
                                _.extend(stat, { "count": result });
                                break;
                        }
                    });
                    $scope.loading = false;
                });
            }
        });
    }

    init();

    // when the filter is updated, update widget
    $scope.$on('locs-filter-update', function() {
        if ($scope.widget.area == $stateParams.area) {
            init();
        }
    });

});
