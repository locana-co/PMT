module.exports = angular.module('PMTViewer').controller('EditorCtrl', function EditorCtrl($scope, $rootScope, config, global) {
    // get the page object
    $scope.page = _.find(config.states, function (state) { return state.route == "editor"; });
    
    // terminology specification
    $scope.terminology = config.terminology;
});

// all templates used by the editor page:
require('./detail/detail.js');
require('./list/list.js');
require('./top-bar/top-bar.js');
require('./org-selector/org-selector.js');
require('./location-selector/location-selector.js');
require('./contact-selector/contact-selector.js');
require('./file-selector/file-selector.js');