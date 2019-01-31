module.exports = angular.module('PMTViewer').controller('AdminCtrl', function ($scope, $rootScope, $mdDialog, userService, config, blockUI) {
    // get the admin page object
    $scope.page = _.find(config.states, function (state) { return state.route == "admin"; });
    // terminology specification
    $scope.terminology = config.terminology;
    // loading animation
    $scope.LoadingUsers = true;
    // user search
    $scope.searchQuery = '';
    // determine if editor is enabled
    $scope.hasEditor = hasEditor();

    if (typeof $rootScope.currentUser != 'undefined' && $rootScope.currentUser != null) {
        blockUI.start();
        // call the user service to get the list of users
        userService.getInstanceUsers().then(function (users) {
            $scope.users = users;
            // create a readable sentance for classification permissions
            _.each($scope.users, function (user) {
                if (user.classifications) {
                    user.classification_permissions = '';
                    _.each(user.classifications, function (taxonomy) {
                        var classificiations = _.pluck(taxonomy.c, 'c');
                        user.classification_permissions += taxonomy.t + '(' + classificiations.join(', ') + ') ';
                    });
                }
                blockUI.stop();
            });
            $scope.LoadingUsers = false;
        });
        // call the user service to get a list of all the roles
        userService.getRoles().then(function (roles) {
            $scope.roles = roles;
        });
    }

    // toggle edit session for a user
    $scope.edit = function (user) {
        user.active = true;
    };

    // cancel changes to user record
    $scope.cancel = function (user) {
        // loading animation
        $scope.LoadingUsers = true;
        userService.getInstanceUsers().then(function (users) {
            $scope.users = users;
            $scope.LoadingUsers = false;
        });
        user.active = false;
    };

    // update users assigned database role
    $scope.updateRole = function (user, role) {
        user.role_id = role.id;
        user.role = role._name;
        user.authorizations = {
            activity_ids: [],
            classification_ids: []
        };
    };

    // save edits to a user
    $scope.save = function (user) {
        // convert role id to number
        user.role_id = parseInt(user.role_id, 10);
        // assign user role to correct role name
        $scope.roles.map(function (a) {
            if (a.id === user.role_id) {
                user.role = a._name;
            }
        });

        userService.editUser(user, false).then(function (res) {
            // deactivate edit session for user
            user.active = false;
            // success dialog
            showConfirmationDialog('Success', 'User has been updated');
        }).catch(function (msg) {
            // error dialog
            showConfirmationDialog('Error', 'Unable to update user:' + msg);
        });
    };

    // delete/deactivate user
    $scope.deleteUser = function (event, user) {
        user.delete = true;

        // confirm delete user dialog
        var confirm = $mdDialog.confirm()
            .title('Are you sure you want to delete this user?')
            //.textContent('Are you sure you want to delete this user?')
            .ariaLabel('confirm delete')
            .targetEvent(event)
            .ok('Yes')
            .cancel('Cancel');

        // if confirmed yes, delete user
        $mdDialog.show(confirm).then(function () {
            // deactivate user
            userService.editUser(user, true).then(function (res) {
                // call the user service to get the updated list of users
                $scope.LoadingUsers = true;
                userService.getInstanceUsers().then(function (users) {
                    $scope.users = users;
                    $scope.LoadingUsers = false;
                });
                // success dialog
                showConfirmationDialog('Success', 'User has been deleted successfully.');
            }).catch(function (msg) {
                // error dialog
                showConfirmationDialog('Error', 'Unable to delete user:' + msg);
            });
        }, function () {
            user.delete = false;
        });


    };

    // open the org-selector modal
    $scope.openOrgSelector = function (event, user) {
        $scope.activeUser = user;
        $mdDialog.show({
            controller: 'AdminOrgSelectorCtrl',
            templateUrl: 'admin/org-selector/org-selector.tpl.html',
            parent: angular.element(document.body),
            targetEvent: event,
            clickOutsideToClose: true,
            bindToController: true,
            preserveScope: true, // keep scope when dialog is closed
            locals: { activeUser: $scope.activeUser } // bind activeUser to scope
        });
    };

    // open the create-user modal
    $scope.createUser = function (event) {
        $mdDialog.show({
            controller: 'AdminCreateUserCtrl',
            templateUrl: 'admin/create-user/create-user.tpl.html',
            parent: angular.element(document.body),
            targetEvent: event,
            clickOutsideToClose: true,
            bindToController: true,
            scope: $scope, // pass scope to AdminCreateUserCtrl
            preserveScope: true
        }).then(function (success) {
            // get new users
            if (success) {
                // loading animation
                $scope.LoadingUsers = true;
                userService.getInstanceUsers().then(function (users) {
                    $scope.users = users;
                    $scope.LoadingUsers = false;
                    // show success modal
                    showConfirmationDialog('Success', 'Your new user has been created');
                });
            }
        });
    };

    // open the add-exist-user modal
    $scope.addExistingUser = function (event) {
        $mdDialog.show({
            controller: 'AdminAddExistingUserCtrl',
            templateUrl: 'admin/add-existing-user/add-existing-user.tpl.html',
            parent: angular.element(document.body),
            targetEvent: event,
            clickOutsideToClose: true,
            bindToController: true,
            scope: $scope, // pass scope to AdminAddExistingUserCtrl
            preserveScope: true
        }).then(function (success) {
            // get new users
            if (success) {
                // loading animation
                $scope.LoadingUsers = true;
                userService.getInstanceUsers().then(function (users) {
                    $scope.users = users;
                    $scope.LoadingUsers = false;
                    // show success modal
                    showConfirmationDialog('Success', 'Your new user has been added');
                });
            }
        });
    };

    // user clicked refresh views button
    $scope.refreshViews = function (event) {
        var confirm = $mdDialog.confirm()
            .title('Refresh Database Views')
            .textContent('Refreshing the database views can take up to 25 minutes and may cause application errors during execution. Are you sure you want to begin the refresh?')
            .ariaLabel('refresh confirmation')
            .targetEvent(event)
            .ok('Yes, Refresh')
            .cancel('No, Cancel');
        $mdDialog.show(confirm).then(function () {
            userService.refreshViews();
        }, function () { });
    };

    // open the edit-permissions modal
    $scope.editPermissions = function (event, user) {
        if (user.active) {
            $scope.activeUser = user;
            $mdDialog.show({
                controller: 'EditPermissionsCtrl',
                templateUrl: 'admin/edit-permissions/edit-permissions.tpl.html',
                parent: angular.element(document.body),
                targetEvent: event,
                clickOutsideToClose: true,
                bindToController: true,
                scope: $scope, // pass scope to EditPermissionsCtrl
                preserveScope: true,
                locals: { activeUser: $scope.activeUser }
            }).then(function (success) {
                if (success) {
                    // loading animation
                    $scope.LoadingUsers = true;
                    // convert role id to number
                    user.role_id = parseInt(user.role_id, 10);
                    // assign user role to correct role name
                    $scope.roles.map(function (a) {
                        if (a.id === user.role_id) {
                            user.role = a._name;
                        }
                    });
                    // save user information
                    userService.editUser(user, false).then(function (res) {
                        // reload users
                        userService.getInstanceUsers().then(function (users) {
                            $scope.users = users;
                            $scope.LoadingUsers = false;
                            // show success modal
                            showConfirmationDialog('Success', 'Your permission changes have been saved');
                        });
                    }).catch(function (msg) {
                        // error dialog
                        showConfirmationDialog('Error', 'Unable to update user:' + msg);
                    });

                }
            });
        }
    };

    // open the password-reset modal
    $scope.openPasswordReset = function (event, user) {
        $scope.activeUser = user;
        $mdDialog.show({
            controller: 'AdminPasswordResetCtrl',
            templateUrl: 'admin/password-reset/password-reset.tpl.html',
            parent: angular.element(document.body),
            targetEvent: event,
            clickOutsideToClose: true,
            bindToController: true,
            scope: $scope, // pass scope to AdminPasswordResetCtrl
            preserveScope: true, // keep scope when dialog is closed
            locals: { activeUser: $scope.activeUser }, // bind activeUser to scope
            onRemoving: function () {
                // check for successful password update
                if ($scope.UpdatePasswordSuccess) {
                    // show success modal
                    showConfirmationDialog('Success', 'Password rest & new credentials have been emailed to user');
                    // reset successful user creation
                    $scope.UpdatePasswordSuccess = false;
                    // close edit user
                    user.active = false;
                }
            }
        });
    };

    // message dialog
    function showConfirmationDialog(title, content) {
        $mdDialog.show(
            $mdDialog.alert()
                .clickOutsideToClose(true)
                .title(title)
                .textContent(content)
                .ariaLabel('Create Account Success Message')
                .ok('OK')
        );
    }

    // determine if instances has the editor enabled
    function hasEditor() {
        var enabled;
        _.each(config.states, function (state) {
            if (state.route === 'editor') {
                enabled = state.enable;
            }
        });
        return enabled;
    }
});

// custom angular filter for user list
// filter all property values by search text unless user is being edited
module.exports = angular.module('PMTViewer').filter('filterUsers', function () {
    return function (input, val) {
        var output = _.filter(input, function (o) {
            var pass = [];
            // loop through all users
            _.each(Object.keys(o), function (p) {
                // only check non null properties
                if (o[p] !== null && typeof o[p] != "undefined") {
                    // check if value is contained in string
                    pass.push((o[p].toString().toLowerCase().indexOf(val.toString().toLowerCase()) !== -1));
                }
                pass.push(o.active); // add active property
            });
            // if pass has one true value, return user
            return _.contains(pass, true);
        });
        return output;
    };
});

// all templates used by the admin page:
require('./org-selector/org-selector.js');
require('./create-user/create-user.js');
require('./password-reset/password-reset.js');
require('./add-existing-user/add-existing-user.js');
require('./edit-permissions/edit-permissions.js');

