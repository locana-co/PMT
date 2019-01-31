/***************************************************************
 * Data Source Controller
 * A filter controller. Supports the data sources for PMT. These
 * are defined in the app.config in the explorer page filter object.
 * *************************************************************/
angular.module('PMTViewer').controller('PLFilterDataSourceCtrl', function ($scope, $rootScope, partnerLinkService) {
            
    // $scope.page holds the tools page object defined in app.config
    if ($scope.page && $scope.filter) {
        // get the data group ids for filter from parameters
        $scope.options = $scope.filter.params.data_groups;               
        // add size property (num of items) to parent scope
        _.extend($scope.filter, { size: $scope.options.length });
        // loop through the data groups and get those that are active
        var data_group_ids = [];
        _.each($scope.options, function (o) {
            if (o.active === true) {
                data_group_ids = _.union(data_group_ids, o.data_group_ids.split());
            }
        });
        partnerLinkService.init(data_group_ids);
    }
    
    // the options have changed
    $scope.optionClicked = function (option) {
        try {
            if (option.active) {
                partnerLinkService.setDataGroupIds(option.data_group_ids);
            } else {
                partnerLinkService.removeDataGroupIds(option.data_group_ids);
            }
        }
        // error handler
        catch (ex) {
            // there was an error report it to the error handler
            console.log(ex);
        }
    };

});