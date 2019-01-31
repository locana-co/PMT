/***************************************************************
 * ZoomTo Controller
 * Supports the interactive map tool.
 ***************************************************************/
angular.module('PMTViewer').controller('MapZoomToCtrl', function ($scope, mapService, stateService, pmtMapService, boundaryService) {
    $scope.showSearchInputBox = false;
    $scope.searchText = null;
    $scope.showResponse = false;

    // get the boundary_type
    $scope.boundary_type = $scope.page.tools.map.zoomTo.boundaryType;
     
    // if no search text, opposite of what it started as
    $scope.toggleSearchInputBox = function() {
        if (!$scope.searchText) {
            $scope.showSearchInputBox = !$scope.showSearchInputBox;
        }
    };

    //geocoder
    $scope.getOpenCageSearchData = function () {

        if ($scope.searchText) {

            $scope.loading = true;
            $scope.searchResponse = null;

            $scope.searchDisplayText = $scope.searchText;

            pmtMapService.geocode($scope.searchText)
                .then(function (res) {
                    $scope.searchResponse = res;
                })
                .then(function(resFromGeoCode) {
                    boundaryService.getBoundaryByText( $scope.boundary_type , $scope.searchText.toLowerCase())
                        .then(function(repFromGetBoundaryByText, err){
                            $scope.loading = false;
                            $scope.showResponse = true;
                            if (err){
                                throw err;
                            }else{
                                // filter geocoder responses to instance's country list
                                $scope.searchResponse.features = _.filter($scope.searchResponse.features, function(feature){
                                    var countries = [];
                                    _.each($scope.page.tools.map.zoomTo.countries, function(c) {
                                        countries.push(c.toLowerCase());
                                    });
                                    return _.contains(countries, feature.properties.components.country.toLowerCase());
                                });
                                // add pmt responses
                                $scope.searchResponse.features = $scope.searchResponse.features.concat(repFromGetBoundaryByText.features);
                            }
                    }); // getBoundaryByText
                } // then GetBoundaryByText
            ); // call GeoCode then GetCoundaryByText
        } // if we have search text
    }; // getOpenCageSearchData

    
    // update map extent for bounds
    $scope.fitBounds = function (bounds, lookUpRec) {
        // if we don't have bounds, look it up
        if (bounds===undefined){
            // [sparadee]: add logic
        } else {
            // we have bounds, so center map there
            var b = L.latLngBounds(bounds.southwest, bounds.northeast);
            mapService.map.fitBounds(b);
        }
    };

    // update map extent for bounds
    $scope.fitBounds = function (bounds) {
        var b = L.latLngBounds(bounds.southwest, bounds.northeast);
        mapService.map.fitBounds(b);
    };

    //close search results
    $scope.closeSearchResults = function () {
        $scope.showResponse = false;
        $scope.searchText = null;
        $scope.toggleSearchInputBox();
    };
});