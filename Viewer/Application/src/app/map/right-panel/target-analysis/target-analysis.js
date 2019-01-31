/***************************************************************
 * Target Analysis Controller
 * Supports the target analysis feature.
 * *************************************************************/
angular.module('PMTViewer').controller('MapTargetAnalysisCtrl', function ($scope, $rootScope, $state, $stateParams, stateService, analysisService) {
    $scope.stateService = stateService;
    $scope.targetAnalysisActive = false;
    $scope.analysis2x2 = []; // contains the 2x2 data
    $scope.country = null; // contains the name of the target country
    $scope.region = null; // contains the name of the target region
    $scope.supportingLayerOn = false;
    var countries = []; // contains array of country objects for participating country/regions
    
    analysisService.get2x2Regions().then(function (data) {
        var filterCountries = $scope.page.tools.map.targetAnalysis.countries;
        countries = data;
        countries = _.filter(countries, function (c) { return _.contains(filterCountries, c._name); });
    });
    
    // when the url is updated do this
    $scope.$on('route-update', function () {
        if (!stateService.isParam('target-analysis-panel') && $scope.supportingLayerOn) {
            // remove the supporting layer
            manageSupportingLayer(false);
            // clear the table
            $scope.analysis2x2 = [];
            // set the right panel wide off
            $scope.$parent.$parent.rightPanelWide = false;
            // set tool active flag
            $scope.targetAnalysisActive = false;
        }
        // reposition the map controls
        $scope.repositionMapControls();
    });
    
    // toggle on/off target analysis map (selectable features)
    $scope.toggleMap = function () {       
        // the tool is active
        if ($scope.targetAnalysisActive) {
            // add the supporting layer
            manageSupportingLayer(true);
        }
        // the tool is inactive
        else {
            // remove the supporting layer
            manageSupportingLayer(false);
            // clear the table
            $scope.analysis2x2 = [];
            // set the right panel wide off
            $scope.$parent.$parent.rightPanelWide = false;
            // reposition the map controls
            $scope.repositionMapControls();      
        }
    };
    
    // private function for processing 2x2 when region is selected
    function regionSelected(region) {
        $scope.country = null;
        $scope.region = region;
        _.each(countries, function (c) {
            var found = _.find(c.regions, function (r) { return r._name == region; });
            if (found) {
                $scope.country = c._name;
            }
        });
        if ($scope.country !== null) {
            analysisService.get2x2($scope.country, $scope.region).then(function (data) {
                $scope.analysis2x2 = data;
                $scope.$parent.$parent.rightPanelWide = true;
                $scope.repositionMapControls();
            });
        }
    }

    // private function for managing the support layer on the map
    function manageSupportingLayer(add) {
        // get the current state
        var state = stateService.getState();
        // to hold updated layer list
        var layers = [];
        // collect the current layers from the state
        if ($stateParams.layers !== '') {
            layers = $stateParams.layers.split(',');
        }  
        // get the tools supporting layer's alias
        var layerAlias = $scope.page.tools.map.targetAnalysis.supportingLayer;
        // get the supporting layer from the config
        var supportingLayer = _.find($scope.page.tools.map.supportingLayers, function (l) { return l.alias == layerAlias; });
         
        // add the supporting layer to the map
        if (add) {
            try {
                // continue if there is a valid supporting layer
                if (supportingLayer) {
                    // collect array of region ids to show on the map
                    var regionIds = [];
                    _.each(countries, function (country) {
                        var ids = _.pluck(country.regions, 'id');
                        regionIds = _.union(regionIds, ids);
                    });
                    // set the supporting layer's filter for the participating regions
                    supportingLayer.filter = regionIds;
                    supportingLayer.mutexToggle = true;
                    supportingLayer.onClick = function (evt) {
                        regionSelected(evt.feature.properties._name);
                    };                    
                    // add the supporting layer to the map
                    layers.push(layerAlias);
                    // update the supporting layer flag
                    $scope.supportingLayerOn = true;
                }
            }
            // error handler
            catch (ex) {
                // there was an error report it to the error handler
                console.log(ex);
            }
        }
        // remove the supporting layer from the map
        else {
            // remove the layer from the list of layers
            layers = _.filter(layers, function (l) { return l !== layerAlias; });
            // update supporting layer flag
            $scope.supportingLayerOn = false;
        }

        // upate the state
        $stateParams.layers = layers.join() || '';
        // update parameters        
        stateService.setState($state.current.name || 'home', $stateParams, false);
    }
});
