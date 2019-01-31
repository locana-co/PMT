module.exports = angular.module('PMTViewer').controller('HomeCtrl', function HomeCtrl($scope, $rootScope, config, global) {
    // get the about page object
    $scope.page = _.find(config.states, function (state) { return state.route == "home"; });
});