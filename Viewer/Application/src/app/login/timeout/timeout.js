module.exports = angular.module('PMTViewer').controller('LoginTimeout', function ($rootScope, $scope, $mdDialog, $interval) {

    // convert idle time from seconds to minutes
    $scope.idle = Math.round($rootScope.loginIdle / 60);
    $scope.idle = $scope.idle || 0;
    $rootScope.loginIdle = $rootScope.loginIdle || 0;

    $scope.message = "This page will be refreshed";

    if($rootScope.currentUser.user._username !== 'public'){
        $scope.message = "You'll be logged out";
    }
    
    // on click function for close buttons
    $scope.cancel = function () {
        $mdDialog.cancel();
    };

});