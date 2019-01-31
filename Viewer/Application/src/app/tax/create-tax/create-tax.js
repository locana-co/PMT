/***************************************************************
 * Create a New Organization Controller
 * Supports the organization page's add new org feature.
 * *************************************************************/
module.exports = angular.module('PMTViewer').controller('TaxCreateTaxonomyCtrl', function CreateOrgCtrl($scope, $rootScope, $mdDialog, taxonomyService, config) {

    $scope.settings = _.chain(config.states).where({ route: "tax" }).pluck("tools").first().value();
    $scope.model = this.locals.model;

    // on click function for creating new taxonomy
    $scope.createNewTax = function () {
        $scope.loading = true;
        var isValid = isTaxonomyUnique($scope.model._name);
        $scope.newTaxForm._name.$setValidity('unique', isValid);
        $scope.newTaxForm.$invalid = !isValid;
        if (isValid) {
            // ensure required fields are not empty
            //add record to database then reload 
            taxonomyService.saveTaxonoimes([$scope.model]).then(function (response) {
                var parent_taxonomy_id = response[0].id;
                // if a child tax was provided, create that next
                if ($scope.model._is_category && response.length > 0 && response[0].message === "Success") {
                    $scope.model.parent_id = response[0].id;
                    taxonomyService.saveTaxonoimes([$scope.model], true).then(function (res) {
                        //if a child tax was provided, create that next
                        $scope.loading = false;
                        //then refresh list 
                        $rootScope.$broadcast('refresh-taxonomy', { "id": parent_taxonomy_id });
                        //close dialog
                        $mdDialog.hide(true);
                    }).catch(function (msg) {
                        // error dialog
                        $scope.errorMessage = msg;
                    });
                } else {
                    $scope.loading = false;
                    //then refresh list 
                    $rootScope.$broadcast('refresh-taxonomy', { "id": parent_taxonomy_id });
                    //close dialog
                    $mdDialog.hide(true);
                }


            }).catch(function (msg) {
                // error dialog
                $scope.errorMessage = msg;
            });
        } else {
            $scope.loading = false;
        }
    };

    // on click function for close and cancel buttons
    $scope.cancel = function () {
        var cope = $scope;
        $mdDialog.cancel();
    };

    $scope.isValid = function () {
        var isValid = isTaxonomyUnique($scope.model._name);
        $scope.newTaxForm._name.$setValidity('unique', isValid);
        $scope.newTaxForm.$invalid = !isValid;
    };

    // validate the new organization name is unique
    function isTaxonomyUnique(name) {
        var taxes = taxonomyService.getTaxonomies();
        return _(taxes).where({ _name: name }).length <= 0;
    }

});