/***************************************************************
 * Locations Mid Bar Controller
 * Supports the middle bar for the locations page. 
 ***************************************************************/
angular.module('PMTViewer').controller('LocsMidBarCtrl', function ($scope, $rootScope, $stateParams, locsService, analysisService) {
    // set defaults
    $scope.stateParams = $stateParams;
    $scope.investmentLabel = $scope.page.tools.map.params.investment_label;

    // only get investment if national
    if ($stateParams.area == 'national') {
        getInvestment();
    }

    // when the area is updated, do this
    $scope.$on('area-update', function () {
        updateTitles();
    });

    // when the selection is updated, do this
    $scope.$on('selection-update', function () {
        updateTitles();
        //only get investment if national
        if ($stateParams.area == 'national') {
            getInvestment();
        }
        // update the sub title
        updateSubTitle();
    });

    // when the filter is updated, update financials
    $scope.$on('locs-filter-update', function () {
        //only get investment if national
        if ($stateParams.area == 'national') {
            getInvestment();
        }
        // update the sub title
        updateSubTitle();
    });

    // when the filter options are updated, do this
    $scope.$on('locs-filter-options-update', function () {
        // update the sub title
        updateSubTitle();
    });

    // private function to update titles based on area and selection
    function updateTitles() {
        switch ($stateParams.area) {
            case 'world':
                $scope.title = '';
                break;
            case 'national':
                $scope.title = 'National Investment Summaries';
                break;
            case 'regional':
                $scope.title = 'Region Profile for ' + locsService.selectedRegionalFeature._name;
                break;
            default:
                break;
        }
    }

    // private function to update subtitle based on filters
    function updateSubTitle() {
        //classifications
        var classFilters = [];
        //start date
        var sdate = $scope.page.tools.map.params.start_date;
        //enddate
        var edate = $scope.page.tools.map.params.end_date;
        //get filters
        var activityFilters = locsService.getSelectedFilters();
        //grab names from filter and create a list
        _.each(activityFilters, function (f) {
            //add to list of classification
            if (f.type == 'c') {
                classFilters.push(f.label);
            }
            else if (f.type == "startDate") {
                sdate = f.label.replace("Start Date: ", '');
            }
            else if (f.type == "endDate") {
                edate = f.label.replace("End Date: ", '');
            }
        });
        var classificationText = classFilters.length > 0 ? ' with filters : ' + classFilters.join(' / ') : ' with no additional filters';
        // subtitle
        $scope.subtitle = '* Includes data from ' + sdate + ' to ' + edate + classificationText;
    }

    // private function to get investment amount
    function getInvestment() {
        // if a data group is selected process the data
        if (locsService.getDataGroupFilters().length > 0) {
            $scope.investmentLoading = true;
            //get data groups
            var dataGroups = locsService.getDataGroupFilters().join(',');
            //get classification filters
            var classificationIds = locsService.getClassificationFilters().join(',');
            //start date
            var startDate = locsService.getStartDateFilter();
            //endDate
            var endDate = locsService.getEndDateFilter();
            //get id from layer lookup
            var boundary_id = _.filter($scope.page.tools.map.supportingLayers, function (layer) { return layer.alias == 'gadm0'; })[0].boundary_id;
            // get feature id from current selection
            var feature_ids = [];
            feature_ids.push(parseInt($stateParams.selection, 10));
            //get total investment
            analysisService.getOverviewStats(dataGroups, classificationIds, startDate, endDate, boundary_id, feature_ids.join(',')).then(function (data) {
                // check to ensure there is still data groups selected
                if (locsService.getDataGroupFilters().length > 0 && data.length > 0) {
                    var result = data[0].total_investment;
                    $scope.investment = locsService.abbreviateMoney(result);
                    $scope.investmentLoading = false;
                }
                // otherwise inform the widget there is no data
                else {
                    $scope.chartData = [];
                    $scope.loading = false;
                    $scope.noData = true;
                }
            });
        }
        // otherwise inform the widget there is no data
        else {
            $scope.investmentLoading = true;
            $scope.investment = '$0';
            $scope.investmentLoading = false;
        }
    }

});