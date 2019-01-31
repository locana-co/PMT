module.exports = angular.module('PMTViewer').controller('AdminCreateUserCtrl', function CreateUserCtrl($scope, $rootScope, $mdDialog, userService) {
    
    $scope.user = {};
    // email pattern
    var pattern = new RegExp(".+@.+\\..+");

    // model validation behavior on form inputs
    $scope.firstName = {focused:false,touched:false};
    $scope.lastName = {focused:false,touched:false};
    $scope.email = {focused:false,touched:false};
    $scope.username = {focused:false,touched:false};
    $scope.password = {focused:false,touched:false};
    $scope.verifyPassword = {focused:false,touched:false};
    $scope.phone = {focused:false,touched:false};


    // keep track of when input is focused
    $scope.setFocused = function(input) {
        $scope[input].focused = true;

        // if user has already touched input, remove touched
        if($scope[input].touched===true) {
            $scope[input].touched = false;
        }

        // if email input is focused, remove validity check
        if(input==='email') {
            $scope.newUser.email.$setValidity('pattern',true);
        }
        // if verify-password input is focused, remove validity check
        if(input==='verifyPassword') {
            $scope.newUser.verifyPassword.$setValidity('required',true);
        }

        // if verify-password input is focused, remove validity check
        if(input==='username') {
            $scope.newUser.username.$setValidity('unique',true);
        }
    };

    // keep track of when input is blurred
    $scope.setBlurred = function(input) {
        // if input has been both focused and blurred, it has been "touched" by the user
        if ($scope[input].focused === true) {
            $scope[input].touched = true;
            $scope[input].focused = false;

            // if email input is blurred, set validity check
            if(input==='email') {
                $scope.newUser.email.$setValidity('pattern',pattern.test($scope.user['_email']));
            }
            // if verify-password input is blurred, set validity check
            if(input==='password' || input==='verifyPassword') {
                $scope.newUser.verifyPassword.$setValidity('required',$scope.user.verify_password===$scope.user['_password']);
            }

            // if username input is blurred, set validity check
            if(input==='username' && $scope.newUser.username.$dirty) {
                userService.validateUsername($scope.user['_username'])
                    .then(function(res) {
                        $scope.newUser.username.$setValidity('unique',res);
                    })
                    .catch(function(msg) {
                        $scope.errorMessage = msg;
                    });
            }
        }
    };

    if (typeof $rootScope.currentUser != 'undefined' && $rootScope.currentUser != null) {
        // call the user service to get a list of common orgs
        userService.getOrgs().then(function (orgs) {
            $scope.orgs = _.chain(orgs).uniq('id').sortBy('_name').value();
        });
        // call the user service to get a list of all the roles
        userService.getRoles().then(function (roles) {
            $scope.roles = roles;
        });
    }
    
    // on click function for create new user button
    $scope.createNewUser = function() {
        // convert organization and role id to integers
        $scope.user.organization_id = parseInt($scope.user.organization_id,10);
        $scope.user.role_id = parseInt($scope.user.role_id,10);
        // check for unmatched passwords
        $scope.passwordError = ($scope.user._password !== $scope.user.verify_password);
        // ensure required fields are not empty
        $scope.requiredFieldsError = ($scope.user._first_name === undefined || $scope.user._last_name === undefined || $scope.user._username === undefined || $scope.user.role_id === undefined || $scope.user._email === undefined || $scope.passwordError);
        // if required fields are missing, add validation messages
        if($scope.requiredFieldsError) {
            $scope.newUser.firstName.$setValidity('required',$scope.newUser.firstName.$dirty);
            $scope.newUser.lastName.$setValidity('required',$scope.newUser.lastName.$dirty);
            $scope.newUser.email.$setValidity('required',$scope.newUser.email.$dirty);
            $scope.newUser.username.$setValidity('required',$scope.newUser.username.$dirty);
            $scope.newUser.password.$setValidity('required',$scope.newUser.password.$dirty);
        }
        // only move on if all required fields are filled out
        else {
            $scope.Loading = true;
            userService.createUser($scope.user)
                .then(function (res) {
                    // reload user list on admin page
                    $scope.Loading = false;
                    $mdDialog.hide(true);
                })
                .catch(function(msg){
                    $scope.Loading = false;
                    $scope.errorMessage = msg;
                });
        }
    };

    // validate the new user is unique
    function validateNewUser(username) {
        userService.validateUsername(username)
            .then(function(res) {
                return res;
            })
            .catch(function(msg) {
                $scope.errorMessage = msg;
            });
    }

     // update users assigned database role
    $scope.updateRole = function (user, role) {
        user.role_id = role.id;
        user.role = role._name;
    };

    // on click function for close and cancel buttons
    $scope.cancel = function () {
        $mdDialog.cancel();
    };

});