module.exports = angular.module('PMTViewer').controller('AdminAddExistingUserCtrl', function AddExistingUserCtrl($scope, $rootScope, $mdDialog, userService, pmt) {

    $scope.Loading = true;
    $scope.userSearchQuery = '';
    var instanceUserIds = _.pluck($scope.users, 'id');

    if (typeof $rootScope.currentUser != 'undefined' && $rootScope.currentUser != null) {
        // call the user service to get a list of all users
        userService.getAllUsers().then(function (users) {
            var sortedUsers = _.sortBy(users, '_last_name');

            // filter users who are not part of the current instance
            $scope.nonInstanceUsers = _.filter(sortedUsers, function(user) {
                return !_.contains(instanceUserIds, user.id) && (user._username !== 'public');
            });
            $scope.Loading = false;
            // set the default checked user
            $scope.selectedUser = null;
            $scope.selectedRole = null;
        });
    }

    // update users assigned database role
    $scope.updateRole = function (user, role) {
        user.role_id = role.id;
        user.role = role._name;
        $scope.selectedRole = role.id;
    };

    $scope.resetRole = function(user) {
        // if the clicked user is different from the previous user
        if (user.id !== $scope.selectedUser) {
            $scope.selectedRole = null;

            // remove role properties from each user in the list
            $scope.nonInstanceUsers.forEach(function(el) {
                delete el.role_id;
                delete el.role;
            });
        }
    };

    // on click function for add existing user button
    $scope.addUser = function() {
        $scope.Loading = true;

        // find the selected user
        $scope.nonInstanceUsers.forEach(function(el) {
            if (el.id===$scope.selectedUser) {
                // add the selected role id
                el.role_id = $scope.selectedRole;
                // add the checked user to the current instance
                userService.editUser(el, false)
                    .then(function (res) {
                        // reload user list on admin page
                        $scope.Loading = false;
                        $mdDialog.hide(true);
                    })
                    .catch(function (msg) {
                        $scope.Loading = false;
                        $scope.errorMessage = msg;
                    });
            }
        });
    };

    // on click function for close buttons
    $scope.cancel = function () {
        $mdDialog.cancel();
    };
});