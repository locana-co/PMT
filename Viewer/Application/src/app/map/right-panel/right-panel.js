/***************************************************************
 * Right Panel Controller
 * Supports the right side slide out panels (feature containers).
* *************************************************************/        
module.exports = angular.module('PMTViewer').controller('MapRightPanelCtrl', function ($scope, $rootScope, stateService) {
    $scope.stateService = stateService;
    $scope.rightPanelWide = false; // boolean for toggling the right panel to a wide state
    
    // function to determine if any child panels are open
    $scope.isPanelOpen = function () {
        var open = false;
        if (stateService.isParam('detail-panel') || stateService.isParam('travel-panel') || stateService.isParam('target-analysis-panel')) {
            $scope.title = 'Details';
            open = true;
            $scope.resizeRightPanel();
        }
        
        return open;
    };
    
    //resize function
    $scope.resizeRightPanel = function () {
        try {
            // right panel
            var outsideHeight = $("#map-right-panel").height();
            var detailHeader = $("#map-right-panel .activity-detail .header").height();
            var detailTabs = $("#map-right-panel .detail-tabs").height();
            var bottomBar = $("#map-bottom-bar").height();
            var footer = $("#footer").height();
            var travelTabs = $("#map-travel .nav.nav-tabs").height();
            var travelTitle = $("#map-travel .summary-title").height();
            var travelLink = $("#map-travel .back-link").height();
            $("#map-right-panel .activity-menu").height(outsideHeight - footer - 20);
            $("#map-right-panel .detail-tab-resizing").height(outsideHeight - footer - bottomBar - detailHeader - 47);
            $("#map-right-panel .detail-tab-resizing.activity").height(outsideHeight - footer - bottomBar - detailHeader - 187);
            $("#map-travel .menu-content").height(outsideHeight - footer - bottomBar - travelTabs - 95);
        }
        catch (e) { }
    };
    
    //reposition map controls based on whether ride panel is open
    $scope.repositionMapControls = function () {
        //reposition map controls when right panel is open
        if (stateService.isParam('detail-panel') || stateService.isParam('travel-panel') || stateService.isParam('target-analysis-panel')) {
            if ($scope.rightPanelWide) {
                $('#map-basemap').css({
                    right: 681,
                    WebkitTransition : 'all .5s ease .3s',
                    MozTransition    : 'all .5s ease .3s',
                    MsTransition     : 'all .5s ease .3s',
                    OTransition      : 'all .5s ease .3s',
                    transition       : 'all .5s ease .3s'
                });
                $('#interactive-map .leaflet-bottom.leaflet-right').css({
                    right: 672,
                    WebkitTransition : 'all .5s ease .3s',
                    MozTransition    : 'all .5s ease .3s',
                    MsTransition     : 'all .5s ease .3s',
                    OTransition      : 'all .5s ease .3s',
                    transition       : 'all .5s ease .3s'
                });
            }
            else {
                $('#map-zoomTo').css({
                    right: 419,
                    WebkitTransition : 'all .5s ease .3s',
                    MozTransition    : 'all .5s ease .3s',
                    MsTransition     : 'all .5s ease .3s',
                    OTransition      : 'all .5s ease .3s',
                    transition       : 'all .5s ease .3s'
                });

                $('#map-map .group-by').css({
                    right: 455,
                    WebkitTransition : 'all .5s ease .3s',
                    MozTransition    : 'all .5s ease .3s',
                    MsTransition     : 'all .5s ease .3s',
                    OTransition      : 'all .5s ease .3s',
                    transition       : 'all .5s ease .3s'
                });

                $('#map-basemap').css({
                    right: 420,
                    WebkitTransition : 'all .5s ease .3s',
                    MozTransition    : 'all .5s ease .3s',
                    MsTransition     : 'all .5s ease .3s',
                    OTransition      : 'all .5s ease .3s',
                    transition       : 'all .5s ease .3s'
                });
                $('#interactive-map .leaflet-bottom.leaflet-right').css({
                    right: 410,
                    WebkitTransition : 'all .5s ease .3s',
                    MozTransition    : 'all .5s ease .3s',
                    MsTransition     : 'all .5s ease .3s',
                    OTransition      : 'all .5s ease .3s',
                    transition       : 'all .5s ease .3s'
                });
            }
        }
        else {
            $('#map-zoomTo').css({
                right: 10,
                WebkitTransition : 'all .5s ease .3s',
                MozTransition    : 'all .5s ease .3s',
                MsTransition     : 'all .5s ease .3s',
                OTransition      : 'all .5s ease .3s',
                transition       : 'all .5s ease .3s'
            });
            $('#map-map .group-by').css({
                right: 52,
                WebkitTransition : 'all .5s ease .3s',
                MozTransition    : 'all .5s ease .3s',
                MsTransition     : 'all .5s ease .3s',
                OTransition      : 'all .5s ease .3s',
                transition       : 'all .5s ease .3s'
            });
            $('#map-basemap').css({
                right: 9,
                WebkitTransition : 'all .5s ease .3s',
                MozTransition    : 'all .5s ease .3s',
                MsTransition     : 'all .5s ease .3s',
                OTransition      : 'all .5s ease .3s',
                transition       : 'all .5s ease .3s'
            });
            $('#interactive-map .leaflet-bottom.leaflet-right').css({
                right: 0,
                WebkitTransition : 'all .5s ease .3s',
                MozTransition    : 'all .5s ease .3s',
                MsTransition     : 'all .5s ease .3s',
                OTransition      : 'all .5s ease .3s',
                transition       : 'all .5s ease .3s'
            });
        }
    };
    
    // connect to the window resize event
    $(window).resize(function () {
        $scope.resizeRightPanel();
    });
    
    // initialization
    $(document).ready(function () {
        $scope.resizeRightPanel();
    });

});

// all templates used by the right panel
require('./detail/detail.js');
require('./travel/travel.js');
require('./target-analysis/target-analysis.js');
