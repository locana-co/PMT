/***************************************************************
 * Organization Controller
 * A controller. Supports the marged activites view for PMT. These
 * are defined in the app.config in the children object.
 * *************************************************************/
angular.module('PMTViewer').controller('ActsOrganizationDetailsCtrl', function ($scope, config, activityService) {
$scope.terminoloy = config.terminoloy;

});