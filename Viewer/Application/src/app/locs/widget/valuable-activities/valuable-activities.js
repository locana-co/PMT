/***************************************************************
 * Top Valuable Activities Widget Controller
 * Supports the top most valuable activities widget.
 ***************************************************************/
angular.module('PMTViewer').controller('LocsWidgetValuableActivityCtrl', function ($scope, $rootScope, $stateParams, analysisService, utilService, locsService, $mdDialog, stateService) {

    var cellCharacterLimit = 35;
    // set the loading flag
    $scope.loading = false;
    //stores the selected cell for list of partners
    $scope.selectedCell = {};
    // set the no data flag
    $scope.noData = false;

    // when the selection is updated, do this
    $rootScope.$on('selection-update', function () {
        if ($scope.widget.area == $stateParams.area) {
            $scope.processTableData();
        }
    });

    // when the filter is updated, update widget
    $scope.$on('locs-filter-update', function () {
        if ($scope.widget.area == $stateParams.area) {
            $scope.processTableData();
        }
    });

    //updates the selected cell
    $scope.setSelectedCell = function (cell) {
        var partners = [];
        _.each(cell, function (element) {
            //if overflow element
            if (element.overflow) {
                _.each(element.overflow, function (p) {
                    partners.push(p);
                });
            }
            //otherwise just add partner obj to list
            else {
                partners.push(element);
            }
        });
        $scope.selectedCell = cell;
        $scope.selectedCell.partners = partners;
    };

    // load and process the table data
    $scope.processTableData = function () {
        // if a data group is selected process the chart data
        if (locsService.getDataGroupFilters().length > 0) {
            switch ($stateParams.area) {
                case 'national':
                case 'regional':
                    // turn on loading
                    $scope.loading = true;
                    // set no data flag
                    $scope.noData = false;
                    // get the selected feature
                    var featureId = ($scope.widget.area == 'national' ? parseInt(locsService.selectedNationalFeature.id, 10) : parseInt(locsService.selectedRegionalFeature.id, 10));
                    // get the current boundary
                    var boundaryId = ($scope.widget.area == 'national' ? locsService.nationalLayer.boundary_id : locsService.regionalLayer.boundary_id);
                    // call the analysis service for table data
                    analysisService.getActivityByInvestment(
                        locsService.getDataGroupFilters().join(','),
                        locsService.getClassificationFilters().join(','),
                        locsService.getStartDateFilter(),
                        locsService.getEndDateFilter(),
                        boundaryId,
                        featureId,
                        $scope.widget.params.top,
                        $scope.widget.params.fields
                    ).then(function (data) {
                        // assign chart data
                        $scope.chartData = [];
                        var tableData = [];
                        // loop through the chart data and attach it to the table parameter 
                        // in the configuration
                        _.each($scope.widget.params.table, function (table) {
                            table.values = [];
                            _.each(data, function (d) {
                                if (_.has(d, table.column_field)) {
                                    if (table.column_field == 'amount') {
                                        table.values.push(utilService.formatMoney(d[table.column_field]));
                                    }
                                    else {
                                        table.values.push(d[table.column_field]);
                                    }
                                }
                            });
                            tableData.push(table.values);
                        });
                        tableData.push(_.pluck(data, 'id'));
                        // zip the collected data together
                        $scope.chartData = _.zip.apply(_, tableData);
                        // set the no data flag if there is no returned activities
                        if (data.length <= 0) {
                            $scope.noData = true;
                        }
                        // turn off loading
                        $scope.loading = false;
                    });

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
    };

    $scope.goToActivity = function (activity_id) {
        var params = { "activity_id": activity_id };
        stateService.setState("activities", params, true);
    };


    // initialization function
    function init() {
        // process partner pivot data
        $scope.processTableData();
    }

    // initialize the widget
    init();
});
