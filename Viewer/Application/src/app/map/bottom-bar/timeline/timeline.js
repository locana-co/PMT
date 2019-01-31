/***************************************************************
 * Timeline Controller
 * Supports the timeline feature. Users can use a timeline
 * slider to define the range for data to be displayed on
 * the map.
 * *************************************************************/
angular.module('PMTViewer').controller('MapTimelineCtrl', function ($scope, $rootScope, stateService, mapService, pmtMapService) {
    var defaultStart = $scope.page.tools.map.timeslider.defaultStart;
    var defaultEnd = $scope.page.tools.map.timeslider.defaultEnd;

    $scope.timelineDisabled = false;

    //timeline defaults
    $scope.slider = {
        minValue: defaultStart,
        maxValue: defaultEnd,
        options: {
            disabled: !$scope.page.tools.map.timeslider.defaultEnabled,
            floor: $scope.page.tools.map.timeslider.floor,
            ceil: $scope.page.tools.map.timeslider.ceiling,
            showTicks: true,
            showTicksValues: false
        }
    };

    // when user finished sliding a handle update date filter
    $scope.$on("slideEnded", function () {
        setDateFilters(false);
    });

    // toggle the timeline disable feature
    $scope.toggleDisableTimeline = function () {
        $scope.slider.options.disabled = !$scope.timelineDisabled;
        if (!$scope.timelineDisabled) {
            // clear date filters
            setDateFilters(true);
        }
        else {
            // set the date filters
            setDateFilters(false);
        }
    };

    // initialize the timeslider
    function init() {
        // set timeline checkbox element
        $scope.timelineDisabled = !$scope.page.tools.map.timeslider.defaultEnabled;
        // default for timeslider is enabled, set filters
        if ($scope.page.tools.map.timeslider.defaultEnabled) {
            // set timeline filters with default parameters
            var min_date = new Date('1-1-' + defaultStart);
            var max_date = new Date('12-31-' + defaultEnd);
            pmtMapService.setDateFilters(min_date, max_date);
        }
        // default for timeslider is disabled, clear filters
        else {
            setDateFilters(true);
           // $scope.slider.options.disabled = true;
        }
    }

    // set the date filters (when clear is true null filters)
    function setDateFilters(clear) {
        if (clear) {
            pmtMapService.setDateFilters(null, null);
        }
        else {
            var min_date = new Date('1-1-' + $scope.slider.minValue);
            var max_date = new Date('12-31-' + $scope.slider.maxValue);
            pmtMapService.setDateFilters(min_date, max_date);
        }
    }

    // initialize the timeslider
    init();

});