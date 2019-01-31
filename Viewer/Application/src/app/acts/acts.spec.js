describe('Controller: ActsCtrl', function () {
    beforeEach(module('PMTViewer'));

    var $controller;

    beforeEach(inject(function (_$controller_) {
        $controller = _$controller_;
    }));

    describe('$scope.page', function () {
        it('should have a defined page configuration for route', function () {
            var $scope = {};
            var controller = $controller('ActsCtrl', { $scope: $scope });
            expect($scope.page.route).toBeDefined();
        });
        it('should have a defined page configuration for stateParamDefaults', function () {
            var $scope = {};
            var controller = $controller('ActsCtrl', { $scope: $scope });
            expect($scope.page.stateParamDefaults).toBeDefined();
        });
        it('should have a defined page configuration for stateParamDefaults lat & lng & zoom', function () {
            var $scope = {};
            var controller = $controller('ActsCtrl', { $scope: $scope });
            expect($scope.page.stateParamDefaults.lat).toBeDefined();
            expect($scope.page.stateParamDefaults.lng).toBeDefined();
            expect($scope.page.stateParamDefaults.zoom).toBeDefined();

        });
        it('should have a defined page configuration for tools', function () {
            var $scope = {};
            var controller = $controller('ActsCtrl', { $scope: $scope });
            expect($scope.page.tools).toBeDefined();
            expect($scope.page.tools.map).toBeDefined();

            //    tests for tools.amp
            describe('$scope.page.tools.map', function () {
                it('should have map settings including minZoom, maxZoom, layers, contextual, supportingLayers, filters', function () {
                    var $scope = {};
                    var controller = $controller('ActsCtrl', { $scope: $scope });
                    expect($scope.page.tools.map.minZoom).toBeDefined();
                    expect($scope.page.tools.map.maxZoom).toBeDefined();
                    expect($scope.page.tools.map.layers).toBeDefined();
                    expect($scope.page.tools.map.contextual).toBeDefined();
                    expect($scope.page.tools.map.supportingLayers).toBeDefined();
                    expect($scope.page.tools.map.filters).toBeDefined();
                    expect($scope.page.tools.map.supplemental).toBeDefined();
                    expect($scope.page.tools.map.params).toBeDefined();
                });
                it('should check that the $scope.page.tools.map.filters contains all the correct properties:id, label, tpl, params', function() {
                    var $scope = {};
                    var controller = $controller('ActsCtrl', { $scope: $scope });
                    var array = $scope.page.tools.map.filters;

                    _.each(array, function (filters) {
                        expect(filters.id).toBeDefined();
                        expect(filters.label).toBeDefined();
                        expect(filters.tpl).toBeDefined();
                    });
                });
                it('should check that the $scope.page.tools.map.params has a showCountry property', function() {
                    var $scope = {};
                    var controller = $controller('ActsCtrl', { $scope: $scope });
                    var detailPageParams = $scope.page.tools.map.params;

                    expect(detailPageParams.showCountry).toBeDefined();
                });
            });
        });
    });

    describe('$scope.terminology', function () {
        it('should have a defined terminology', function () {
            var $scope = {};
            var controller = $controller('ActsCtrl', {$scope: $scope});
            expect($scope.terminology).toBeDefined();
            expect($scope.terminology.activity_terminology).toBeDefined();
            expect($scope.terminology.activity_terminology.singular).toBeDefined();
            expect($scope.terminology.activity_terminology.plural).toBeDefined();

            expect($scope.terminology.boundary_terminology.singular).toBeDefined();
            expect($scope.terminology.boundary_terminology.singular.admin1).toBeDefined();
            expect($scope.terminology.boundary_terminology.singular.admin2).toBeDefined();
            expect($scope.terminology.boundary_terminology.singular.admin3).toBeDefined();
            expect($scope.terminology.boundary_terminology.plural).toBeDefined();
            expect($scope.terminology.boundary_terminology.plural.admin1).toBeDefined();
            expect($scope.terminology.boundary_terminology.plural.admin2).toBeDefined();
            expect($scope.terminology.boundary_terminology.plural.admin3).toBeDefined();

            expect($scope.terminology.funder_terminology).toBeDefined();
            expect($scope.terminology.funder_terminology.singular).toBeDefined();
            expect($scope.terminology.funder_terminology.plural).toBeDefined();

            expect($scope.terminology.implementor_terminology).toBeDefined();
            expect($scope.terminology.implementor_terminology.singular).toBeDefined();
            expect($scope.terminology.implementor_terminology.plural).toBeDefined();
        });
    });
});


