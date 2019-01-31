describe('Controller: PLCtrl', function () {
    beforeEach(module('PMTViewer'));

    var $controller;

    beforeEach(inject(function (_$controller_) {
        $controller = _$controller_;
    }));

    describe('$scope.page', function () {
        it('should have a defined page configuration for route', function () {
            var $scope = {};
            var controller = $controller('PLCtrl', { $scope: $scope });
            expect($scope.page.route).toBeDefined();
        });
        it('should have a defined page configuration for tools - filters, color_range, grantee_not_reported_label, parter_not_reported_label, funder_not_reported_label', function () {
            var $scope = {};
            var controller = $controller('PLCtrl', { $scope: $scope });
            expect($scope.page.tools).toBeDefined();
            expect($scope.page.tools.filters).toBeDefined();
            expect($scope.page.tools.color_range).toBeDefined();
            expect($scope.page.tools.grantee_not_reported_label).toBeDefined();
            expect($scope.page.tools.partner_not_reported_label).toBeDefined();
            expect($scope.page.tools.funder_not_reported_label).toBeDefined();
            expect($scope.page.tools.aggregator).toBeDefined();

            //    tests for tools.amp
            describe('$scope.page.tools.filters', function () {

                it('should have specific properties - id, label, tpl, params, open', function () {
                    var array = $scope.page.tools.filters;
                    _.each(array, function (filter) {
                        expect(filter.id).toBeDefined();
                        expect(filter.label).toBeDefined();
                        expect(filter.tpl).toBeDefined();
                        expect(filter.open).toBeDefined();
                    });
                });
            });
        });
    });

    describe('$scope.terminology', function () {
        it('should have a defined terminology', function () {
            var $scope = {};
            var controller = $controller('PLCtrl', {$scope: $scope});
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


