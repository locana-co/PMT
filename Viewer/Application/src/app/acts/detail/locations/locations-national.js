
/***************************************************************
 * Activity Detail Locations Template Controller
 * Supports the activity details location template for national
 * locations.
 * *************************************************************/
angular.module('PMTViewer').controller('ActsDetailLocationNationalCtrl', function ($scope) {

    // do this when the activity detail is updated
    $scope.$on('activity-detail-updated', function () {
        if ($scope.selectedActivity.locationDetails.length > 0 && $scope.selectedActivity.locationDetails[0].admin0) {
            $scope.flag = 'https://s3.amazonaws.com/v10.investmentmapping.org/themes/flags/' +
                $scope.selectedActivity.locationDetails[0].admin0.toLowerCase() + '.jpg';
        }
    });
});