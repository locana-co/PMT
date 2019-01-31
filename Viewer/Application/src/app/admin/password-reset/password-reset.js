module.exports = angular.module('PMTViewer').controller('AdminPasswordResetCtrl', function ($scope, $mdDialog, userService) {

    $scope.Loading = false;

    // model validation behavior on form inputs
    $scope.newPassword = {focused:false,touched:false};
    $scope.verifyNewPassword = {focused:false,touched:false};

    // get bound data from mdDialog
    if (this.locals) {
        $scope.activeUser = this.locals.activeUser;
        $scope.activeUser._password = null;
        $scope.activeUser.verify_password = null;
    }

    // keep track of when input is focused
    $scope.setFocused = function(input) {
        $scope[input].focused = true;

        // if user has already touched input, remove touched
        if($scope[input].touched===true) {
            $scope[input].touched = false;
        }

        // if verify-password input is focused, remove validity check
        if(input==='verifyNewPassword') {
            $scope.updatePassword.verify_password.$setValidity('required',true);
        }
    };

    // keep track of when input is blurred
    $scope.setBlurred = function(input) {
        // if input has been both focused and blurred, it has been "touched" by the user
        if ($scope[input].focused === true) {
            $scope[input].touched = true;
            $scope[input].focused = false;

            // if verify-password input is blurred, set validity check
            $scope.updatePassword.verify_password.$setValidity('required',$scope.activeUser.verify_password===$scope.activeUser['_password']);
        }
    };

    // reset user password
    $scope.resetPassword = function () {
        // check for unmatched passwords
        $scope.passwordError = ($scope.activeUser._password !== $scope.activeUser.verify_password);
        // move on if passwords match
        if (!$scope.passwordError) {
            $scope.Loading = true;
            userService.resetUserPassword($scope.activeUser).then(function (res) {
                // set parent variable to true
                $scope.$parent.UpdatePasswordSuccess = true;
                $scope.Loading = false; // remove loading animation
                $mdDialog.cancel(); // close modal
            }).catch(function (msg) {
                $scope.Loading = false; // remove loading animation
                $scope.errorMessage = msg; // display error message
            });
        }
    };

    // on click function for close buttons
    $scope.cancel = function () {
        $mdDialog.cancel();
    };

});