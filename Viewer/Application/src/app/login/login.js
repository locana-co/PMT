module.exports = angular.module('PMTViewer').controller('LoginCtrl', function LoginCtrl($scope, $state, $rootScope, $mdDialog, config, userService, blockUI) {
    // t/f is the application publich accessable without login
    $scope.public = config.login.public;
    // holds the optional customizations for the login page
    $scope.customizations = null;
    // loading flag
    $scope.loading = true;

    // if public, grab username and password from config
    if ($scope.public) {
        publicLogin();
    }

    // log in method
    $scope.logIn = function (user) {
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
                        // after successful login set state to home page
                        config.login.loginSuccess = true;
                        $state.go(config.defaultState || 'tools');
                    }
                    else {
                        // place user authentication error
                        $("#password").after("<div class='error'>Username or password is incorrect.</div>");
                    }
                },
                    function (msg) {
                        // place user authentication error
                        $("#password").after("<div class='error'>" + msg + "</div>");
                    });
            }
        }
    };

    // log out method, needs to be accessable outside of 
    $rootScope.logOut = function () {
        // set flag for login success when public access allowed
        config.login.loginSuccess = false;
        if ($scope.public) {
            publicLogin();
        }
        else {
            $rootScope.currentUser = null;
            $state.go('login');
        }
    };

    // log in method, needs to be accessable outside of 
    $rootScope.logIn = function () {
        blockUI.stop();
        $mdDialog.show({
            controller: 'LoginPublicCtrl',
            templateUrl: 'login/login-public/login-public.tpl.html',
            parent: angular.element(document.body)
        });
    };

    // does the instance have log in page customizations
    if (_.has(config.login, 'customizations')) {
        $scope.customizations = config.login.customizations;
    }

    function publicLogin() {
        var username = config.login.username;
        var password = config.login.password;
        blockUI.stop();
        // call the user service to attempted login
        userService.logIn(username, password).then(function (u) {
            blockUI.stop();
            $scope.loading = false;
            if ($rootScope.currentUser != null) {
                // after successful login set state to home page
                $state.go(config.defaultState || 'tools');
            }
            else {
                // place user authentication error
                $("#login-error").after("<div class='error'>There was an error logging in.</div>");
            }
        }, function (msg) {
            $scope.loading = false;
            // place user authentication error
            $("#login-error").after("<div class='error'>There was an error logging in.</div>");
        });
    }

});

// all templates used by the login page:
require('./login-public/login-public.js');
require('./timeout/timeout.js');