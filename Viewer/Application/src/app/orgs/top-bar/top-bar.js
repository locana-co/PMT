/***************************************************************
 * Organization Top Bar Controller
 * Supports the top bar for the organization page.
 ***************************************************************/
angular.module('PMTViewer').controller('OrgsTopBarCtrl', function ($scope, $mdDialog, orgService, $rootScope) {
    // get the organization list count
    $scope.organizationCount = 0;
    // consolidate submit button
    $scope.submitConsolidate = false;
    // consolidate or edit mode to display
    $scope.isConsolidate = false;
    // consolidate or edit mode message
    $scope.message = 'edit mode';

    // when the editable organization list is updated do this
    $scope.$on('org-list-updated', function () {
        if (Array.isArray(orgService.getAllOrgs())) {
            $scope.organizationCount = orgService.getAllOrgs().length;
        }
    });

    // when display mode is updated do this
    $scope.$on('enable-consolidate-submit', function (event, enable) {
        $scope.submitConsolidate = enable;
    });

    // on change function for switch to go between two different modes
    $scope.onModeChange = function () {
        if ($scope.submitConsolidate) {
            var confirm = askConfirmationDialog('Are you sure you want to discard your changes?', 'undo changes');
            $mdDialog.show(confirm).then(function () {
                changeMode();
            }, function() {
                $scope.isConsolidate = true;
            });
        } else {
            changeMode();
        }
    };

    // on click function for submitting consolidation list
    $scope.submit = function () {
        $rootScope.$broadcast('submit-consolidate-list');
    };

    // ask for user for confirmation
    function askConfirmationDialog(title, label) {
        var confirm = $mdDialog.confirm()
            .title(title)
            .ariaLabel(label)
            .ok('Yes')
            .cancel('Cancel');
        return confirm;
    }

    // change mode message on switch toggle and show org list based on mode
    function changeMode() {
        $scope.message = $scope.isConsolidate ? 'consolidate mode' : 'edit mode';
        $rootScope.$broadcast('refresh-org-list', $scope.isConsolidate);
    }
});