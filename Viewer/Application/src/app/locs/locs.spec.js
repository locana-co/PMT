describe('Controller: LocsCtrl', function () {
    beforeEach(module('PMTViewer'));
    
    var $controller;
    
    beforeEach(inject(function (_$controller_) {
        $controller = _$controller_;
    }));
    
    describe('$scope.page', function () {
        it('should have a defined page configuration for route', function () {
            var $scope = {};
            var controller = $controller('LocsCtrl', { $scope: $scope });
            expect($scope.page.route).toBeDefined();
        });
        it('should have a defined page configuration for stateParamDefaults', function () {
            var $scope = {};
            var controller = $controller('LocsCtrl', { $scope: $scope });
            expect($scope.page.stateParamDefaults).toBeDefined();
        });
        it('should have a defined page configuration for stateParamDefaults lat & lng', function () {
            var $scope = {};
            var controller = $controller('LocsCtrl', { $scope: $scope });
            expect($scope.page.stateParamDefaults.lat).toBeDefined();
            expect($scope.page.stateParamDefaults.lng).toBeDefined();

        });
         it('should have a defined page configuration for stateParamDefaults.area', function () {
            var $scope = {};
            var controller = $controller('LocsCtrl', { $scope: $scope });
            var options = ["world","national","regional"];
            expect(options).toContain($scope.page.stateParamDefaults.area);
            expect($scope.page.stateParamDefaults.area).toBeDefined();

        });
    });
});
