/***************************************************************
 * Create a New Organization Controller
 * Supports the organization page's add new org feature.
 * *************************************************************/
module.exports = angular.module('PMTViewer').controller('UserCreateOrgCtrl', function CreateOrgCtrl($scope, $rootScope, $mdDialog, orgService) {
    // url pattern
    var pattern = new RegExp(/^(https?:\/\/)?([\da-z\.-]+)\.([a-z\.]{2,6})([\/\w \.-]*)*\/?$/);

    $scope.name = { focused: false, touched: false };
    $scope.label = { focused: false, touched: false };
    $scope.url = { focused: false, touched: false };

    if (typeof $rootScope.currentUser != 'undefined' && $rootScope.currentUser != null) {
        // call the org service to get a list of common orgs
        orgService.getOrgs().then(function (orgs) {
            $scope.orgs = orgs;
        });
    }

    // keep track of when input is focused
    $scope.setFocused = function (input) {
        $scope[input].focused = true;
        // if user has already touched input, remove touched
        if ($scope[input].touched === true) {
            $scope[input].touched = false;
        }
        // if name input is focused, remove validity check
        if (input == 'name') {
            $scope.newOrgForm.name.$setValidity('required', true);
            $scope.newOrgForm.name.$setValidity('unique', true);
        }
        // if url input is focused, remove validity check
        if (input == 'url') {
            $scope.newOrgForm.url.$setValidity('pattern', true);
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
                var url = $scope.newOrgForm.url.$modelValue;
                if (url !== null && url !== undefined && url !== '') {
                    $scope.newOrgForm.url.$setValidity('pattern', pattern.test($scope.org['url']));
                }
            }
            // if name input is blurred, set validity check
            if (input === 'name' && $scope.newOrgForm.name.$dirty) {
                var isOrgUnique = isOrganizationUnique($scope.newOrgForm.name.$modelValue);
                $scope.newOrgForm.name.$setValidity('unique', isOrgUnique);
            }
        }
    };

    // on click function for create new org button
    $scope.createNewOrg = function () {
        // ensure required fields are not empty
        $scope.requiredFieldsError = ($scope.org === undefined || $scope.org.name === '');
        // if required fields are missing, add validation messages
        if ($scope.requiredFieldsError) {
            $scope.newOrgForm.name.$setValidity('required', $scope.newOrgForm.name.$dirty);
        }
        // only move on if all required fields are filled out
        else {
            orgService.createOrg($scope.org).then(function (res) {
                // refresh org list 
                $rootScope.$broadcast('refresh-org-list', false);
                $mdDialog.hide(true);
                clearFields();
                // success dialog
                showConfirmationDialog('Success', 'Organization has been added successfully.');
            }).catch(function (msg) {
                // error dialog
                $scope.errorMessage = msg;
                showConfirmationDialog('Error', 'Unable to create organization ' + msg);
            });
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
                .ariaLabel('Create Organization Message')
                .ok('OK')
        );
    }

    // validate the new organization name is unique
    function isOrganizationUnique(name) {
        var orgs = $scope.orgs;
        orgs = _.pluck(orgs, 'compareName');
        return !_.contains(orgs, name.toLowerCase());
    }

    // clear organization form fields
    function clearFields() {
        var emptyOrgInst = { name: '', label: '', url: '' };
        $scope.org = angular.copy(emptyOrgInst);
        $scope.newOrgForm.$setPristine();
    }
});