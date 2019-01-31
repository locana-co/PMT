/***************************************************************
 * Edit Existing Organization Controller
 * Supports the organization page's edit organization feature.
 * *************************************************************/
module.exports = angular.module('PMTViewer').controller('UserEditOrgCtrl', function EditOrgCtrl($scope, $rootScope, $mdDialog, orgService) {
    // url pattern
    var pattern = new RegExp(/^(https?:\/\/)?([\da-z\.-]+)\.([a-z\.]{2,6})([\/\w \.-]*)*\/?$/);

    $scope.name = { focused: false, touched: false };
    $scope.label = { focused: false, touched: false };
    $scope.url = { focused: false, touched: false };

    // keep track of when input is focused
    $scope.setFocused = function (input) {
        $scope[input].focused = true;
        // if user has already touched input, remove touched
        if ($scope[input].touched === true) {
            $scope[input].touched = false;
        }
        // if name input is focused, remove validity check
        if (input == 'name') {
            $scope.editOrgForm.name.$setValidity('required', true);
            $scope.editOrgForm.name.$setValidity('unique', true);
        }
        // if url input is focused, remove validity check
        if (input == 'url') {
            $scope.editOrgForm.url.$setValidity('pattern', true);
        }
    };

    // keep track of when input is blurred
    $scope.setBlurred = function (input) {
        // if input has been both focused and blurred, it has been "touched" by the user
        if ($scope[input].focused === true) {
            $scope[input].touched = true;
            $scope[input].focused = false;
            // if url input is blurred, set validity check
            if (input == 'url') {
                var url = $scope.editOrgForm.url.$modelValue;
                if (url !== null && url !== undefined && url !== '') {
                    $scope.editOrgForm.url.$setValidity('pattern', pattern.test($scope.org['url']));
                }
            }
            // if name input is blurred, set validity check
            if (input === 'name' && $scope.editOrgForm.name.$dirty) {
                var isOrgUnique = isOrganizationUnique($scope.editOrgForm.name.$modelValue);
                $scope.editOrgForm.name.$setValidity('unique', isOrgUnique);
            }
        }
    };

    $scope.delete = function (event, org) {
        // confirm delete organization dialog
        var confirm = $mdDialog.confirm()
            .title('Are you sure you want to delete this organization?')
            .ariaLabel('confirm delete')
            .targetEvent(event)
            .ok('Yes')
            .cancel('Cancel');
        $mdDialog.show(confirm).then(function () {
            orgService.deleteOrg(org).then(function (res) {
                // refresh org list
                $rootScope.$broadcast('refresh-org-list', false);
                // success dialog
                showConfirmationDialog('Success', 'Organization has been deleted successfully.');
            }).catch(function (msg) {
                // error dialog
                showConfirmationDialog('Error', 'Unable to delete organization:' + msg);
            });
        });
    };

    // on click function for save button to save current changes
    $scope.save = function (org) {
        // ensure required fields are not empty
        $scope.requiredFieldsError = (org === undefined || org.name === undefined);
        // if required fields are missing, add validation messages
        if ($scope.requiredFieldsError) {
            $scope.editOrgForm.name.$setValidity('required', $scope.editOrgForm.name.$dirty);
        }
        // only move on if all required fields are filled out
        else {
            // ensure url is valid
            var urlValid = isUrlValid(org.url);
            if (urlValid) {
                orgService.changeOrg(org).then(function (res) {
                    // refresh org list 
                    $rootScope.$broadcast('refresh-org-list', false);
                    // success dialog
                    showConfirmationDialog('Success', 'Organization has been updated.');
                }).catch(function (msg) {
                    // error dialog
                    showConfirmationDialog('Error', 'unable to update organization: ' + msg);
                });
            }
        }
    };

    // on click function for close and cancel buttons
    $scope.cancel = function () {
        $mdDialog.cancel();
        clearFields();
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

    // check if url is valid
    function isUrlValid(url) {
        var regExp = /^(https?:\/\/)?([\da-z\.-]+)\.([a-z\.]{2,6})([\/\w \.-]*)*\/?$/;
        if (url !== null && url !== '') {
            var urlMatch = regExp.test(url);
            if (!urlMatch) {
                showConfirmationDialog('Error', 'Please enter a valid url.');
                return false;
            }
        }
        return true;
    }

    // validate the new organization name is unique
    function isOrganizationUnique(name) {
        var orgs = orgService.getAllOrgs();
        orgs = _.pluck(orgs, 'compareName');
        return !_.contains(orgs, name.toLowerCase());
    }

    // clear organization form fields
    function clearFields() {
        var emptyOrgInst = { name: '', label: '', url: '' };
        $scope.org = angular.copy(emptyOrgInst);
        $scope.editOrgForm.$setPristine();
    }
});