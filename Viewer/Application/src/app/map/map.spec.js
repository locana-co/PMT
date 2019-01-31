describe('Controller: MapCtrl', function () {
    beforeEach(module('PMTViewer'));

    var $controller;

    beforeEach(inject(function (_$controller_) {
        $controller = _$controller_;
    }));

    describe('$scope.page', function () {
        it('should have a defined page configuration for route', function () {
            var $scope = {};
            var controller = $controller('MapCtrl', { $scope: $scope });
            expect($scope.page.route).toBeDefined();
        });
        it('should have a defined page configuration for stateParamDefaults', function () {
            var $scope = {};
            var controller = $controller('MapCtrl', { $scope: $scope });
            expect($scope.page.stateParamDefaults).toBeDefined();
        });
        it('should have a defined page configuration for stateParamDefaults lat & lng & layers & zoom', function () {
            var $scope = {};
            var controller = $controller('MapCtrl', { $scope: $scope });
            expect($scope.page.stateParamDefaults.lat).toBeDefined();
            expect($scope.page.stateParamDefaults.lng).toBeDefined();
            expect($scope.page.stateParamDefaults.zoom).toBeDefined();
            expect($scope.page.stateParamDefaults.layers).toBeDefined();

        });
        it('should have a defined page configuration for tools', function () {
            var $scope = {};
            var controller = $controller('MapCtrl', { $scope: $scope });
            expect($scope.page.tools).toBeDefined();
            expect($scope.page.tools.map).toBeDefined();
            expect($scope.page.tools.geocoderKey.key).toBeDefined();

        //    tests for tools
            describe('$scope.page.tools.map', function () {
                it('should have map settings including minZoom, maxZoom and layers', function () {
                    var $scope = {};
                    var controller = $controller('MapCtrl', { $scope: $scope });
                    expect($scope.page.tools.map.minZoom).toBeDefined();
                    expect($scope.page.tools.map.maxZoom).toBeDefined();
                    expect($scope.page.tools.map.layers).toBeDefined();
                    expect($scope.page.tools.map.supplemental).toBeDefined();
                });
                it('should check that the $scope.page.tools.map.layers contains all the correct properties - alias, label, datagroupids, boundaryPoints, export', function() {
                    var $scope = {};
                    var controller = $controller('MapCtrl', { $scope: $scope });
                    var array = $scope.page.tools.map.layers;
                    _.each(array, function (layer) {
                        expect(layer.alias).toBeDefined();
                        expect(layer.label).toBeDefined();
                        expect(layer.dataGroupIds).toBeDefined();
                        expect(layer.boundaryPoints).toBeDefined();
                        expect(layer.export).toBeDefined();
                    });
                });
                it('should check that the $scope.page.tools.map.contextual layers contains all the correct properties - alias, label, url, legend, layers, format, opacity, type, active, requiresToken', function() {
                    var $scope = {};
                    var controller = $controller('MapCtrl', { $scope: $scope });
                    var array = $scope.page.tools.map.contextual;
                    _.each(array, function (layer) {
                        expect(layer.alias).toBeDefined();
                        expect(layer.label).toBeDefined();
                        // expect(layer.url).toBeDefined();
                        // expect(layer.legend).toBeDefined();
                        expect(layer.layers).toBeDefined();
                        //expect(layer.format).toBeDefined();
                        // expect(layer.opacity).toBeDefined();
                        // expect(layer.type).toBeDefined();
                        expect(layer.active).toBeDefined();
                        // expect(layer.requiresToken).toBeDefined();
                    });
                });
                it('should check that the $scope.page.tools.map.supportingLayers layers contains all the correct properties - alias, label, url, legend, opacity, type, active', function() {
                    var $scope = {};
                    var controller = $controller('MapCtrl', { $scope: $scope });
                    var array = $scope.page.tools.map.supportingLayers;
                    _.each(array, function (layer) {
                        expect(layer.alias).toBeDefined();
                        expect(layer.label).toBeDefined();
                        expect(layer.url).toBeDefined();
                        expect(layer.legend).toBeDefined();
                        expect(layer.opacity).toBeDefined();
                        expect(layer.type).toBeDefined();
                        expect(layer.active).toBeDefined();
                    });
                });
                it('should have a defined page configuration for regions - type, geometry, properties', function () {
                    var $scope = {};
                    var controller = $controller('MapCtrl', { $scope: $scope });

                    //if regions are defined, check for properties
                    if ($scope.page.tools.map.regions) {
                        var array = $scope.page.tools.map.regions.features;
                        _.each(array, function (layer) {
                            expect(layer.type).toBeDefined();
                            expect(layer.geometry).toBeDefined();
                            expect(layer.properties).toBeDefined();

                        });
                    }
               });
                it('should have a defined page configuration for filters - id, tpl, label', function () {
                    var $scope = {};
                    var controller = $controller('MapCtrl', { $scope: $scope });
                    expect($scope.page.tools.map.filters).toBeDefined();

                    var array = $scope.page.tools.map.filters;
                    _.each(array, function (filter) {
                        expect(filter.id).toBeDefined();
                        expect(filter.label).toBeDefined();
                        expect(filter.tpl).toBeDefined();

                    });
                });
                it('should have a defined page configuration for timeslider defaultStart, defaultEnd, floor, ceiling', function () {
                    var $scope = {};
                    var controller = $controller('MapCtrl', { $scope: $scope });
                    expect($scope.page.tools.map.timeslider.defaultStart).toBeDefined();
                    expect($scope.page.tools.map.timeslider.defaultEnd).toBeDefined();
                    expect($scope.page.tools.map.timeslider.floor).toBeDefined();
                    expect($scope.page.tools.map.timeslider.ceiling).toBeDefined();
                });
                it('should have a defined page configuration for targetAnalysis active,countries,supportingLayer', function () {
                    var $scope = {};
                    var controller = $controller('MapCtrl', { $scope: $scope });
                    expect($scope.page.tools.map.targetAnalysis.active).toBeDefined();
                    expect($scope.page.tools.map.targetAnalysis.countries).toBeDefined();
                    expect($scope.page.tools.map.targetAnalysis.supportingLayer).toBeDefined();
                });
                it('should have a defined page configuration for travel taxonomy, subtaxonomy, countries, regions, district,showInvestmentData', function () {
                    var $scope = {};
                    var controller = $controller('MapCtrl', { $scope: $scope });
                    expect($scope.page.tools.map.travel.taxonomy).toBeDefined();
                    expect($scope.page.tools.map.travel.subtaxonomy).toBeDefined();
                    expect($scope.page.tools.map.travel.countries).toBeDefined();
                    expect($scope.page.tools.map.travel.regions).toBeDefined();
                    expect($scope.page.tools.map.travel.districts).toBeDefined();
                    expect($scope.page.tools.map.travel.showInvestmentData).toBeDefined();
                });
            });
        });
    });

    describe('$scope.terminology', function () {
        it('should have a defined terminology', function () {
            var $scope = {};
            var controller = $controller('MapCtrl', {$scope: $scope});
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


