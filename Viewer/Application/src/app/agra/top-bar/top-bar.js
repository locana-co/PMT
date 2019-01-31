/***************************************************************
 * Agra Top Bar Controller
 * Supports the top bar for the integration page.
 ***************************************************************/
angular.module('PMTViewer').controller('AgraTopBarCtrl', function ($scope, $mdDialog, stateService, integrationService, $rootScope, blockUI) {

    $scope.stateService = stateService;
    // get the integration list count
    $scope.integrationCt = 0;

    // when the route changes do this
    $scope.$on('route-update', function () {
        if (Array.isArray(integrationService.getAllSchedules())) {
            $scope.integrationCt = integrationService.getAllSchedules().length;
        }
    });

   
    // save integration record 
    $scope.saveIntegration = function (event) {
        if (integrationService.validateForms()) {
            blockUI.message('Saving ...');
            integrationService.saveIntegration().then(function (integration) {
                // broadcast refresh of the integration
                $rootScope.$broadcast('refresh-editor-integration');
                // broadcast refresh of the list
                $rootScope.$broadcast('refresh-editor-list');
                if (integration.errors.length > 0) {
                    var html = '<p>Your changes have been saved, but there were some errors reported:</p>';
                    html += '<p><ul>';
                    _.each(integration.errors, function (error) {
                        html += '<li>' + error.record.capitalizeFirstLetter() + ' (ID ' + error.id + '): ' +
                            error.message + '</li>';
                    });
                    html += '</ul></p>';
                    blockUI.done(function () {
                        // inform user the record was saved, but there were some errors
                        $mdDialog.show(
                            $mdDialog.alert()
                                .parent(angular.element(document.querySelector('#editor-detail')))
                                .clickOutsideToClose(true)
                                .title('Saved with Errors')
                                .htmlContent(html)
                                .ariaLabel('Integration Save')
                                .ok('Ok')
                                .targetEvent(event)
                        );
                    });
                }
                else {
                    blockUI.done(function () {
                        // inform user the record was saved successfully
                        $mdDialog.show(
                            $mdDialog.alert()
                                .parent(angular.element(document.querySelector('#editor-detail')))
                                .clickOutsideToClose(true)
                                .title('Save Successful')
                                .textContent('Your changes have been successfully saved!')
                                .ariaLabel('Integration Save')
                                .ok('Ok')
                                .targetEvent(event)
                        );
                    });
                }
            }, function (error) {
                blockUI.done(function () {
                    // inform the user there was an error during the saving of the record
                    $mdDialog.show(
                        $mdDialog.alert()
                            .parent(angular.element(document.querySelector('#editor-detail')))
                            .clickOutsideToClose(true)
                            .title('Error Message')
                            .textContent(error)
                            .ariaLabel('Validation Error Alert')
                            .ok('Ok')
                            .targetEvent(event)
                    );
                });
            });
        }
        else {
            // inform the user there is missing, required information 
            $mdDialog.show(
                $mdDialog.alert()
                    .parent(angular.element(document.querySelector('#editor-detail')))
                    .clickOutsideToClose(true)
                    .title('Data Validation Check')
                    .textContent('It appears that you may have forgotten to provide some information. Please review and ensure all required fields are filled out.')
                    .ariaLabel('Validation Error Alert')
                    .ok('Ok')
                    .targetEvent(event)
            );
        }
    };

    // cancel integration record
    $scope.cancelIntegration = function () {
        if (integrationService.isDirty()) {
            // appending dialog to document.body to cover sidenav in docs app
            var confirm = $mdDialog.confirm()
                .title('Are you sure you want to cancel? All changes to this record will be lost!')
                .ariaLabel('cancel confirmation')
                .targetEvent(event)
                .ok('Yes, Cancel Changes')
                .cancel('No, Keep Changes');
            $mdDialog.show(confirm).then(function () {
                $rootScope.$broadcast('refresh-integration');

            }, function () { });
        }else{
            $rootScope.$broadcast('refresh-integration');
        }
    };

});