/***************************************************************
 * Create a New Organization Controller
 * Supports the organization page's add new org feature.
 * *************************************************************/
module.exports = angular.module('PMTViewer').controller('TaxCreateClassificationCtrl', function CreateOrgCtrl($scope, $rootScope, $mdDialog, taxonomyService, config) {
    $scope.settings = _.chain(config.states).where({ route: "tax" }).pluck("tools").first().value();
    $scope.parent = this.locals.parent;
    $scope.model = this.locals.model;

    // on click function for creating new classification
    $scope.createNewClassification = function () {
        $scope.loading = true;
        var isValid = isClassificationUnique($scope.model.c);
        $scope.newClassForm.c.$setValidity('unique', isValid);
        $scope.newClassForm.$invalid = !isValid;
        if (isValid) {
            // ensure required fields are not empty
            //add record to database then reload 
            taxonomyService.saveClassifications([$scope.model]).then(function (res) {
                $scope.loading = false;
                //then refresh list 
                $rootScope.$broadcast('refresh-classification', $scope.model.taxonomy_id);
                //close dialog
                $mdDialog.hide(true);
            }).catch(function (msg) {
                // error dialog
                $scope.errorMessage = msg;
            });
        }else{
            $scope.loading = false;
        }
    };

    // on click function for close and cancel buttons
    $scope.cancel = function () {
        var cope = $scope;
        $mdDialog.cancel();
    };

    $scope.isValid = function () {
        var isValid = isClassificationUnique($scope.model.c);
        $scope.newClassForm.c.$setValidity('unique', isValid);
        $scope.newClassForm.$invalid = !isValid;
    };

    // validate the new organization name is unique
    function isClassificationUnique(name) {
        return _.chain(taxonomyService.getTaxonomies()).where({id:$scope.parent}).pluck("classifications").pluck("loadedPages").flatten().where({ c: name }).value().length <= 0;
    }

});