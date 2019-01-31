/***************************************************************
 * Partnerlink Filter Controller
 * Supports the partnerlink filter.
 * *************************************************************/
angular.module('PMTViewer').controller('PLFilterCtrl', function ($scope) {
    // get the filters from the config
    $scope.filters = $scope.page.tools.filters;
    
    // filter menu option clicked
    $scope.onMenuClicked = function (filter) {
        // toggle current filter open/closed
        filter.open = !filter.open; 
    };
});

// all templates used by the partnerlink filter:
require('./datasource/datasource.js');
require('./organization/organization.js');