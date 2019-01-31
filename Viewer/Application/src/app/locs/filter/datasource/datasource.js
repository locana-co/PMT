/***************************************************************
 * Data Source Controller
 * A filter controller. Supports the data sources for PMT. These
 * are defined in the app.config in the location page filter object.
 * *************************************************************/
angular.module('PMTViewer').controller('LocsFilterDataSourceCtrl', function ($scope, locsService) {

    // set the filter size
    $scope.filter.size = $scope.filter.params.dataSources.length;

    // the options have changed
    $scope.optionClicked = function (option) {
        // split dataGroupIds string into array
        var dataGroupIds = option.dataGroupIds.split(",");
        try {
            if (option.active) {
                // add ids to filter
                _.each(dataGroupIds, function (id) {
                    //update the activity filter
                    locsService.setDataGroupFilter(id);
                });
            } else {
                // remove ids from filter
                _.each(dataGroupIds, function (id) {
                    //update the activity filter
                    locsService.removeDataGroupFilter(id);
                });
            }
        }
        // error handler
        catch (ex) {
            // there was an error report it to the error handler
            console.log(ex);
        }
    };

    
});