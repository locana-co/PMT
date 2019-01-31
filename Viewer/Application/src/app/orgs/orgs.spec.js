describe('Controller: OrgsCtrl', function () {
    beforeEach(module('PMTViewer'));
    
    var $controller;
    
    beforeEach(inject(function (_$controller_) {
        $controller = _$controller_;
    }));
    
    describe('$scope.page', function () {
        it('should have a defined page configuration for route', function () {
            var $scope = {};
            var controller = $controller('OrgsCtrl', { $scope: $scope });
            expect($scope.page.route).toBeDefined();
        });
    });
});

