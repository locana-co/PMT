
describe('Contoller: AppCtrl', function () {
    var $rootScope, $scope, $controller;
    
    beforeEach(module('PMTViewer'));
    
    beforeEach(inject(function (_$rootScope_, _$controller_) {
        $rootScope = _$rootScope_;
        $scope = $rootScope.$new();
        $controller = _$controller_;
        
        $controller('AppCtrl', { '$rootScope' : $rootScope, '$scope': $scope });
    }));
    
});
