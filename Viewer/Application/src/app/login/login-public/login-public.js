module.exports = angular.module('PMTViewer').controller('LoginPublicCtrl', function ($scope, $state, $rootScope, $mdDialog, config, userService) {

    // on click function for close button
    $scope.cancelLogin = function () {
        $mdDialog.cancel();
    };

    // on click function for login button
    $scope.userLogin = function (user) {
        // remove all previously place errors
        $(".login div.error").remove();
        // if there is no user data at all place errors for username & password
        if (typeof user === "undefined" || user === null) {
            $("#user").after("<div class='error'>Please enter your username.</div>");
            $("#password").after("<div class='error'>Please enter your password.</div>");
        }
        else {
            // if there is no username entered place error for username
            if (typeof user.username === "undefined") {
                $("#user").after("<div class='error'>Please enter your username.</div>");
            }
            // if there is no password entered place error for password
            else if (typeof user.password === "undefined") {
                $("#password").after("<div class='error'>Please enter your password.</div>");
            }
            // validate username and password if entered
            else {
                // call the user service to attempted login
                userService.logIn(user.username, user.password).then(function (u) {
                    if ($rootScope.currentUser != null) {
                        config.login.loginSuccess = true;
                        $mdDialog.hide(true);
                    }
                    else {
                        // set flag for login success when public access allowed
                        config.login.loginSuccess = false;
                        // place user authentication error
                        $("#password").after("<div class='error'>Username or password is incorrect.</div>");
                    }
                },
                    function (msg) {
                        // set flag for login success when public access allowed
                        config.login.loginSuccess = false;
                        // place user authentication error
                        $("#password").after("<div class='error'>" + msg + "</div>");
                    });
            }
        }
    };


});