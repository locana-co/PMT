/***************************************************************
 * Date Controller
 * A filter controller. Supports the filtering activities by
 * a taxonomy. Usage is defined in the app.config in the activity
 * page filter object.
* *************************************************************/
angular.module('PMTViewer').controller('LocsFilterDateCtrl', function ($scope, $element, stateService, config, locsService) {
    // $scope.page holds the activity page object defined in app.config
    if ($scope.page) {
        // store whether filter should be disabled or not
        $scope.disableFilter = false;
        // remove filters from UI
        $scope.startDate = null;
        $scope.endDate = null;

        // add size property (num of items) to parent scope
        _.each($scope.filters, function (f) {
            if (f.label == "Date") {
                _.extend(f, { size: 2 });
            }
        });

        // when the filter is updated, update the date in the UI
        $scope.$on('locs-filter-update', function () {
            updateDates();
        });

        // the options have changed
        $scope.updateStartDate = function (date) {
            var timestamp = Date.parse(date);
            // if valid date
            if (!isNaN(timestamp)) {
                locsService.setStartDateFilter(date);
            }
        };

        // the options have changed
        $scope.updateEndDate = function (date) {
            var timestamp = Date.parse(date);

            //if valid date
            if (!isNaN(timestamp)) {
                locsService.setEndDateFilter(date);
            }
        };

        $scope.removeDateFilter = function () {
            //remove filters from service
            locsService.removeStartDateFilter();
            locsService.removeEndDateFilter();
            //remove filters from UI
            $scope.startDate = null;
            $scope.endDate = null;
        };

        // update dates
        updateDates();
    }

    function updateDates() {
        $scope.startDate = locsService.getStartDateFilter() !== null ? new Date(locsService.getStartDateFilter()) : null;
        $scope.endDate = locsService.getEndDateFilter() !== null ? new Date(locsService.getEndDateFilter()) : null;
    }

});