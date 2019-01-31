/***************************************************************
 * Locations Map Bar Controller
 * Supports the map bar for the map on the locations page. 
 ***************************************************************/
angular.module('PMTViewer').controller('LocsMapSummaryCtrl', function ($scope, $rootScope, $sce, $stateParams, analysisService, locsService, config) {
    // get the location page object
    //$scope.page = _.find(config.states, function (state) { return state.route == "locations"; });
    // get country name
    $scope.country = locsService.selectedNationalFeature;
    // if there is a summary widget, grab title
    if ($scope.page.tools.map.params["summary-widget"]) {
        $scope.title = $scope.page.tools.map.params["summary-widget"].title;
    }

    // when country is updated, do this
    $scope.$on('selection-update', function () {
        if ($stateParams.area==='national'){
            // get country name
            $scope.country = locsService.selectedNationalFeature;
            // if there is a summary widget
            if ($scope.page.tools.map.params["summary-widget"]) {
                $scope.details = $scope.page.tools.map.params["summary-widget"][$scope.country._name];
                $scope.details.stats.num_activities = "-";
                $scope.details.stats.activity_value = "-";
                getOverviewStats();
            }
            else {
                $scope.details = null;
            }
        }
        $scope.show = ($scope.page.mapSummary && $stateParams.area !== "world" && $scope.details !== null);
        if ($scope.details !== null && typeof $scope.details !== "undefined") {
            if ($scope.details.hasOwnProperty("stats")) {
                addEmphasis($scope.details.stats);
            }
        }
    });

    // replace emphasized text with HTML
    function addEmphasis(stats) {
        if (stats.length > 0) {
            _.each(stats, function (s) {
                _.each(s.emphasis, function (e) {
                    s.text = s.text.replace(e, '<span class="bold">' + e + '</span>');
                    s.sanitizedText = $sce.trustAsHtml(s.text);
                });
            });
        }
    }

    // private function to get overview stats
    function getOverviewStats() {
        // get data groups
        var dataGroups = locsService.getDataGroupFilters().join(',');
        // get id from layer lookup
        var boundary_id = _.filter($scope.page.tools.map.supportingLayers, function (layer) { return layer.alias == 'gadm0'; })[0].boundary_id;
        // get feature id from current selection
        var feature_ids = [];
        feature_ids.push(parseInt($stateParams.selection, 10));
        // get total investment
        analysisService.getOverviewStats(dataGroups, null, null, null, boundary_id, feature_ids.join(',')).then(function (data) {
            $scope.details.stats.num_activities = data[0].activity_count;
            $scope.details.stats.activity_value = locsService.abbreviateMoney(data[0].total_investment);
        });
    }


});