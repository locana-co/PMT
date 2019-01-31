/***************************************************************
 * Interactive Map Controller
 * Supports the interactive map page.
 ***************************************************************/ 
angular.module('PMTViewer').controller('MapCtrl', function ($scope, config, stateService) {
    // get the explorer page object
    $scope.page = _.find(config.states, function (state) { return state.route == "map"; });

    //terminology specification
    $scope.terminology = config.terminology;

});

// all templates used by the interactive map page:
require('./map/map.js');
require('./zoomTo/zoomTo.js');
require('./top-bar/top-bar.js');
require('./bottom-bar/bottom-bar.js');
require('./left-panel/left-panel.js');
require('./right-panel/right-panel.js');
require('./basemap/basemap.js');