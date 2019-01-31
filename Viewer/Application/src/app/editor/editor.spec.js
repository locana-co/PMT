
describe('Controller: EditorCtrl', function () {
    var $rootScope, $scope, $controller;

  beforeEach( module( 'PMTViewer' ) );
    
    beforeEach(inject(function (_$rootScope_, _$controller_) {
        $rootScope = _$rootScope_;
        $scope = $rootScope.$new();
        $controller = _$controller_;
        
        $controller('EditorCtrl', { '$rootScope' : $rootScope, '$scope': $scope });
    }));
    
    it('should have a defined title', function () {
        expect($scope.page.title).toBeDefined();
    });

    it('should have a defined sub-title', function () {
        expect($scope.page.subtitle).toBeDefined();
    });

});

