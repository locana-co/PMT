/***************************************************************
 * Organization Top Bar Controller
 * Supports the top bar for the organization page.
 ***************************************************************/
angular.module('PMTViewer').controller('TaxTopBarCtrl', function ($scope, $mdDialog, taxonomyService, $rootScope, blockUI, stateService) {
    $scope.stateService = stateService;
    // get the organization list count
    $scope.taxonomyCount = 0;
    // when the editable organization list is updated do this
    $scope.$on('tax-list-updated', function () {
       setCount();
    });

    $scope.$on('tax-title-update', function (e, tax) {
        $scope._name = tax._name;
    });

    $scope.cancelTaxonomy = function () {
        $rootScope.$broadcast('refresh-tax-list');
    };

    $scope.createTaxonomy = function () {
        $rootScope.$broadcast('add-taxonomy');
    };

    $scope.saveTaxonomy = function () {
        if (stateService.isParam('tax_id')) {
            // detail page
            $rootScope.$broadcast('save-taxonomy-activities');
        } else {
            // taxonomy page
            $rootScope.$broadcast('save-taxonomy');
        }
    };

    // on click of back button in top bar
    $scope.returnToTaxonomyList = function (e) {
        if (!$(e.currentTarget).is("[disabled='disabled']")) {
            // if (editorService.isDirty()) {
            //     var confirm = $mdDialog.confirm()
            //         .title('Are you sure you want to navigate way from this record before saving?')
            //         .ariaLabel('leaving record confirmation')
            //         .ok('Yes, Go to List')
            //         .cancel('No, Cancel');
            //     $mdDialog.show(confirm).then(function () {
            //         stateService.setParamWithVal('editor_activity_id', '');
            //         stateService.setParamWithVal('layers', '');
            //         stateService.setParamWithVal('editor_parent_id', '');
            //         stateService.setParamWithVal('editor_parent_title', '');
            //     }, function () { });
            // } else {
            $rootScope.$broadcast('tax-list-pristine');
            stateService.setParamWithVal('tax_id', '');
            // }
        }
    };

    function setCount(){
        $scope.taxonomyCount = taxonomyService.getTaxonomiesCount();
    }

    setCount();
});