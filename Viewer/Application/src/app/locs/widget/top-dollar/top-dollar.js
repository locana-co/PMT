/***************************************************************
 * Top Dollar Widget Controller
 * Supports the top dollar summary widget.
 ***************************************************************/
angular.module('PMTViewer').controller('LocsWidgetTopDollarCtrl', function ($scope, $rootScope, $stateParams, $mdDialog, analysisService, locsService) {
    $scope.chartData = [];    // holds data for bar chart
    $scope.allOrganizations = []; // holds listing of all organizations
    $scope.loading = false;
    $scope.noData = false;
    $scope.funder_terminology = $scope.terminology.funder_terminology.plural.toTitleCase();

    // var length of label to trim
    var nameLength = 30;

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

    // show all click event handler
    $scope.showAll = function () {
        showAllOrganizations();   
    };

    // show modal window with all contribuitors or activites
    function showAllOrganizations() {
        var featureId = parseInt(locsService.selectedNationalFeature.id, 10);
        var boundaryId = locsService.nationalLayer.boundary_id;

        analysisService.getStatsInvestmentsByFunder(
            locsService.getDataGroupFilters().join(','),
            locsService.getClassificationFilters().join(','),
            locsService.getStartDateFilter(),
            locsService.getEndDateFilter(),
            boundaryId,
            featureId,
            0 // all records
        ).then(function (data) {
            // process returned data
            $scope.allOrganizations = _.map(data, function(item,idx) {
                 // convert amounts in to user friendly string ie 1.5B
                item.sumStr = locsService.abbreviateMoney(item.sum); 
                return item;  
            });
            
            $mdDialog.show({
                scope: $scope,
                preserveScope: true,
                controller: showAllController,
                bindToController: true,
                templateUrl: 'locs/widget/top-dollar/top-dollar-show-all-modal.tpl.html',
                controllerAs: 'ctrl',
                parent: angular.element(document.body),
                clickOutsideToClose: true,
                targetEvent: event
            });
        });        
    }

    // controller for the show-all modal
    function showAllController($scope, $mdDialog){
        $scope.closeDialog = function () {
            $mdDialog.hide();
            return;
        };
    }

    // collect and process the chart data
    function processChartData() {
        // if a data group is selected process the chart data
        if (locsService.getDataGroupFilters().length > 0) {
            switch ($stateParams.area) {
                case 'national':
                    $scope.loading = true;
                    $scope.noData = false;
                    var count = 0;

                    var featureId = parseInt(locsService.selectedNationalFeature.id, 10);
                    var boundaryId = locsService.nationalLayer.boundary_id;

                    analysisService.getStatsInvestmentsByFunder(
                        locsService.getDataGroupFilters().join(','),
                        locsService.getClassificationFilters().join(','),
                        locsService.getStartDateFilter(),
                        locsService.getEndDateFilter(),
                        boundaryId,
                        featureId,
                        $scope.widget.params.top
                    ).then(function (data) {

                        //if empty array is returned
                        if (data.length < 1) {
                            $scope.noData = true;
                        }

                        $scope.chartData = [];
                        _.each(data, function (d) {
                            if (count < $scope.widget.params.top) {
                                if (d.label != null && d.sum != null) {
                                    var value = Math.round(d.sum / 1000000);
                                    var label;
                                    if (d.label.length > nameLength) {
                                        label = d.label.substring(0, nameLength) + '...';
                                    }
                                    else {
                                        label = d.label;
                                    }
                                    var chart = {
                                        "label_left": label,
                                        "full_label": d.name,
                                        "label_right": locsService.abbreviateMoney(d.sum),
                                        "value": value,
                                        "a_ids" : d.a_ids
                                    };
                                    $scope.chartData.push(chart);
                                    count++;
                                }
                            }
                        });
                        $scope.loading = false;
                    });
                    break;
                case 'regional':
                    $scope.loading = true;
                    $scope.noData = false;
                    var countR = 0;

                    var regionalFeatureId = locsService.selectedRegionalFeature.id;
                    var regionalBoundaryId = locsService.regionalLayer.boundary_id;

                    analysisService.getStatsByOrg(
                        locsService.getDataGroupFilters().join(','),
                        locsService.getClassificationFilters().join(','),
                        locsService.getStartDateFilter(),
                        locsService.getEndDateFilter(),
                        $scope.widget.params.org_role_id,
                        regionalBoundaryId,
                        regionalFeatureId,
                        $scope.widget.params.top
                    ).then(function (data) {

                        //if only data is headers
                        if (data.length < 1) {
                            $scope.noData = true;
                        }

                        $scope.chartData = [];
                        _.each(data, function (d) {
                            if (countR < $scope.widget.params.top) {
                                if (d.label != null && d.activity_count != null) {
                                    var label;
                                    if (d.label.length > nameLength) {
                                        label = d.label.substring(0, nameLength) + '...';
                                    }
                                    else {
                                        label = d.label;
                                    }
                                    //plural or singular label
                                    var label_right = (d.activity_count > 1 ? $scope.terminology.activity_terminology.plural : $scope.terminology.activity_terminology.singular);

                                    var chart = {
                                        "label_left": label,
                                        "full_label": d.name,
                                        "label_right": d.activity_count + " " + label_right,
                                        "value": d.activity_count,
                                        "a_ids" : d.a_ids
                                    };
                                    $scope.chartData.push(chart);
                                    countR++;
                                }
                            }
                        });
                        // sort the data by value in desc order (largest to smallest)
                        $scope.chartData = _.sortBy($scope.chartData, 'value').reverse();
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

    }
    
    // initialization function
    function init() {
        processChartData();
    }

    // initialize the widget
    init();
});
