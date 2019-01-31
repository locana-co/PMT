/***************************************************************
 * Taxonomy Summary Widget Controller
 * Supports the taxonomy summary pie chart widget.
 ***************************************************************/
angular.module('PMTViewer').controller('LocsWidgetTaxSummaryCtrl', function ($scope, $rootScope, $stateParams, analysisService, locsService) {
    $scope.chartData = [];
    $scope.loading = false;
    $scope.noData = false;

    // when the selection is updated, do this
    $scope.$on('selection-update', function () {
        if ($scope.widget.area == $stateParams.area) {
            processChartData();
        }
    });

    // when the filter is updated, update widget
    $scope.$on('locs-filter-update', function () {
        if ($scope.widget.area == $stateParams.area) {
            processChartData();
        }
    });

    // collect and process the chart data
    function processChartData() {
        var featureId;
        var boundaryId;
        // if a data group is selected process the chart data
        if (locsService.getDataGroupFilters().length > 0) {
            switch ($stateParams.area) {
                case 'national':
                    featureId = parseInt(locsService.selectedNationalFeature.id, 10);
                    boundaryId = locsService.nationalLayer.boundary_id;
                    processData(featureId, boundaryId);
                    break;
                case 'regional':
                    featureId = locsService.selectedRegionalFeature.id;
                    boundaryId = locsService.regionalLayer.boundary_id;
                    processData(featureId, boundaryId);
                    break;
                default:
                    $scope.chartData = [];
                    $scope.loading = false;
                    $scope.noData = true;
                    break;
            }
        }
        // otherwise inform the widget there is no data
        else {
            $scope.chartData = [];
            $scope.loading = false;
            $scope.noData = true;
        }
    }

    // initialization function
    function init() {
        processChartData();
    }

    // call analysis service for data and processs
    function processData(featureId, boundaryId) {
        $scope.noData = false;
        $scope.loading = true;
        analysisService.getStatsActivityByTaxonomy(
            $scope.widget.params.taxonomy_id,
            locsService.getDataGroupFilters().join(','),
            locsService.getClassificationFilters().join(','),
            locsService.getStartDateFilter(),
            locsService.getEndDateFilter(),
            boundaryId,
            featureId,
            $scope.widget.params.top
        ).then(function (data) {
            // clear the chart data
            $scope.chartData = [];
            // set no data flag if array is empty
            if (data.length === 1) {
                if (data[0].classification === 'Other' && data[0].count === 0) {
                    $scope.noData = true;
                }
            }
            if (!$scope.noData) {
                // show the other column
                if ($scope.widget.params.show_other) {
                    // update the aggregated "other" classifications label
                    if ($scope.widget.params.other_label) {
                        _.each(data, function (f) {
                            if (f.classification_id === null) {
                                f.classification = $scope.widget.params.other_label;
                            }
                        });
                    }
                }
                // don't show other column
                else {
                    // remove the aggregated "other" classifications information
                    data = _.filter(data, function (f) { return f.classification_id !== null; });
                }
                // assign the chart data
                _.each(data, function (d) {
                    var pieData;
                    if ($stateParams.area === 'national') {
                        pieData = {
                            "tooltip": "<div class='title'>" + d.classification.capitalizeFirstLetter() +
                            "</div><span>" + $scope.terminology.activity_terminology.plural + ":</span> " + d.count +
                            "</br><span>Investment:</span> " + locsService.abbreviateMoney(d.sum),
                            "label": d.classification.capitalizeFirstLetter(),
                            "value": d.sum,
                            "a_ids": d.a_ids,
                            "classification_id": d.classification_id
                        };
                    }
                    else {
                        pieData = {
                            "tooltip": "<div class='title'>" + d.classification.capitalizeFirstLetter() +
                            "</div><span>" + $scope.terminology.activity_terminology.plural + ":</span> " + d.count,
                            "label": d.classification.capitalizeFirstLetter(),
                            "value": d.count,
                            "a_ids": d.a_ids,
                            "classification_id": d.classification_id
                        };
                    }
                    $scope.chartData.push(pieData);
                });
                // assign color ramp colors
                _.each($scope.chartData, function (d, index) {
                    if ($scope.widget.params.show_other && d.classification_id === null) {
                        d.color = "#727273";
                    }
                    else {
                        d.color = $scope.widget.colors[index];
                    }
                });
            }
            $scope.loading = false;
        });
    }

    // initialize the widget
    init();
});
