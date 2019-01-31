/***************************************************************
 * Widget Controller
 * Supports the widgets container and logic for placing all
 * configured widgets on the UI.
 ***************************************************************/ 
angular.module('PMTViewer').controller('LocsWidgetCtrl', function LocsCtrl($rootScope, $scope, $stateParams, config, $mdDialog) {
    
    // get the widgets for the current area (world, national or regional)
    $scope.widgets = _.groupBy(_.filter($scope.page.tools.map.widgets, function (f) { return f.area === $stateParams.area; }), 'row');

    // when the area is updated, do this
    $scope.$on('area-update', function () {
        // get the widgets for the area
        $scope.widgets = _.groupBy(_.filter($scope.page.tools.map.widgets, function (f) { return f.area === $stateParams.area; }), 'row');
    });

    // modal popup for printing widgets
    $scope.printWidget = function(options) {
        $mdDialog.show({
            locals: {options: options},
            controller: DownloadController,
            templateUrl: 'locs/widget/widget-modal.tpl.html',
            parent: angular.element(document.body),
            clickOutsideToClose: true,
            scope: $scope,
            preserveScope: true
        });
    };

    // pop-up model on download click
    function DownloadController(options, $scope) {

        $scope.options = options;

        // on click function for close buttons
        $scope.closeDialog = function () {
            $mdDialog.cancel();
        };
    }
});

// all templates used by the widgets:
require('./overview/overview.js');
require('./tax-summary/tax-summary.js');
require('./top-dollar/top-dollar.js');
require('./top-taxonomy/top-taxonomy.js');
require('./stories/stories.js');
require('./valuable-activities/valuable-activities.js');
require('./pivot/pivot.js');
require('./external-link/external-link.js');