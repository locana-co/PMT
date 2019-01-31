/***************************************************************
 * Left Panel Controller
 * Supports the left side slide out panels (feature containers).
* *************************************************************/ 
module.exports = angular.module('PMTViewer').controller('MapLeftPanelCtrl', function ($scope, $rootScope, stateService, pmtMapService) {
    $scope.stateService = stateService;
    $scope.navTab = 'filter'; // set the filter panel active by default
    $scope.chevronDirection = stateService.isParam('left-panel') ? 'left' : 'right';
    $rootScope.sideoutOpen = false;
        
    // when url is updated, change arrow direction
    $scope.$on('route-update', function () {
        $scope.chevronDirection = stateService.isParam('left-panel') ? 'left' : 'right';
    });
    
    // toggle left panel and update chevron direction
    $scope.toggleParam = function () {
        stateService.toggleParam('left-panel');
    };
    
    //resize function
    $scope.resizeLeftPanel = function () {
        try {
            // left panel
            var fullHeight = $("#map-left-panel").height();
            var header = $("#header").height();
            var insideHeight = $("#map .tool-tabs").height();
            var footer = $("#footer").height();
            var filterCount = pmtMapService.getSelectedFilters().length;
            var mapFilterTitle = $("#map-filter .title").height();
            // filter selection box - if there are filters add padding for new filter, otherwise height should be zero
            var selectionHeight = (filterCount > 0) ? (24*filterCount + 27 ) : -5;
            selectionHeight = selectionHeight > 121 ? 121 : selectionHeight;
            // contextual layers selectionHeight box
            var toolsHeight = $(".layers-tool.active").height() || 0;
            //resize
            $("#map-filter .sub-menu.scrollable").height(fullHeight - insideHeight - header - footer - selectionHeight  - mapFilterTitle - 74);
            $("#map-contextual .sub-menu.scrollable").height(fullHeight - insideHeight - toolsHeight - header - footer - 74);
            $("#map-filter .org-index").height(fullHeight - insideHeight - header - footer - selectionHeight - 65);
        }
        catch (e) { }
    };
    
    $scope.toggleNavTab = function (tab) {
        $scope.navTab = tab;
    };
    
    // connect to the window resize event
    $(window).resize(function () {
        $scope.resizeLeftPanel();
    });
    
    // initialization
    $(document).ready(function () {
        $scope.resizeLeftPanel();
    });

});

// all templates used by the left panel
require('./filter/filter.js');
require('./contextual/contextual.js');
