/***************************************************************
 * Data Source Controller
 * A filter controller. Supports the data sources for PMT. These
 * are defined in the app.config in the activity page filter object.
 * *************************************************************/
angular.module('PMTViewer').controller('ActsFilterDataSourceCtrl', function ($scope, activityService) {

    // set the filter size
    $scope.filter.size = $scope.filter.params.dataSources.length;

    // when the activity list is updating do this
    $scope.$on('act-list-updating', function () {
        // disable the filter when list is updating
        $scope.filter.disabled = true;
    });

    // when the activity list has updated do this
    $scope.$on('act-list-updated', function () {
        // enable the filter when list has finished updating
        $scope.filter.disabled = false;
    });

    // the options have changed
    $scope.optionClicked = function (option) {
        // split dataGroupIds string into array
        var dataGroupIds = option.dataGroupIds.split(",");
        try {
            if (option.active) {
                // add ids to filter
                _.each(dataGroupIds, function (id) {
                    //update the activity filter
                    activityService.setDataGroupFilter(id);
                });
            } else {
                // remove ids from filter
                _.each(dataGroupIds, function (id) {
                    //update the activity filter
                    activityService.removeDataGroupFilter(id);
                });
            }
        }
        // error handler
        catch (ex) {
            // there was an error report it to the error handler
            console.log(ex);
        }
    };

    // initialize the filter
    function init() {
        // initialize the filter if it has not been initialized
        if ($scope.filter && !_.has($scope.filter, 'disabled')) {
            $scope.filter.disabled = true;
        }
    }

    init();
});