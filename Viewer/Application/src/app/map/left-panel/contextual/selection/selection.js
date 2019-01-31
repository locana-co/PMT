/***************************************************************
 * Contextual Selected Layers Controller
 * Supports the contextual selection layers and tools feature.
* *************************************************************/ 
angular.module('PMTViewer').controller('MapContextualSelectionCtrl', function ($scope, $state, $rootScope, $stateParams, stateService, pmtMapService, mapService) {
    // keeps track of selected overlays
    $scope.selectedOverlays = [];
    // keeps track of whether there are any active overlays
    $scope.activeOverlays = false;
    // boolean to track a forced redraw of the map due to a resort
    var forceRedraw = false;
    
    // when the url is updated do this
    $scope.$on('layers-update', function () {
        //update the list of overlays on layer change
        setSelectedOverlays();
        if (forceRedraw) {
            mapService.forceRedraw();
            forceRedraw = false;
        }
        setTimeout(function () { $scope.resizeLeftPanel(); }, 500);
    });
    
    // a selected layer's opacity has been changed
    $scope.opacityChanged = function (layer) {
        mapService.forceRedraw();
    };

    //catches the case when layer opacity is changed to zero and mouse leaves scale div
    $scope.opacityChangedToZero = function(layer) {
        if (layer.opacity <= 0.01) {
            mapService.forceRedraw();
        }
    };
    
    // the layer's sort order has been changed
    $scope.sortChanged = function () {
        try {
            var sortedListLayer = [];
            // get the current layer list from the url
            var currentLayerList = $stateParams.layers.split(',');
            // get the new sort order of selected layers
            var selectedLayers = _.pluck($scope.selectedOverlays, 'alias');
            // get all the pmt layers on the map
            var pmtLayers = pmtMapService.layersPlusClass;
            if (pmtLayers) {
                var aliases = _.keys(pmtLayers);
                _.each(currentLayerList, function (l) {
                    if (_.contains(aliases, l)) {
                        // add the pmt layer to the new sorted layer list if its on the map
                        sortedListLayer.push(l);
                    }
                });
            }
            // put the newly re-ordered list of layers in the map's draw order
            for (var idx in selectedLayers.reverse()) {
                sortedListLayer.push(selectedLayers[idx]);
            }
            // update the layer parameter which will cause a map redraw in the
            // order requested
            $stateParams.layers = sortedListLayer.join();
            // put the order back
            selectedLayers.reverse();
            // set the force redraw boolean to true, so on layer change in the 
            // url the map will be forced to redraw           
            forceRedraw = true;
            // update parameters        
            stateService.setState($state.current.name || 'home', $stateParams, false);
        }
            // error handler
            catch (ex) {
            // there was an error report it to the error handler
            console.log('There was an error in the redraw:', ex);
        }
    };
    
    //function to remove all selected overlays
    $scope.removeAllOverlays = function () {
        $scope.selectedOverlays = [];
        // get the layers present in url
        var layers = [];
        if ($stateParams.layers !== '') {
            layers = $stateParams.layers.split(',');
        }
        // loop through the contextual layers 
        $scope.categories.forEach(function (c) {
            c.layers.forEach(function (l) {
                // remove active layers
                if (l.active === true) {
                    layers = _.filter(layers, function (a) { return a !== l.alias; });
                    l.active = false;
                }
            });
        });
        // add remaining layers to the state parameters
        $stateParams.layers = layers.join() || '';
        // update parameters        
        stateService.setState($state.current.name || 'home', $stateParams, false);
        $scope.activeOverlays = false;
        setTimeout(function () { $scope.resizeLeftPanel(); }, 500);
    };
    
    //private function to set the list of selected overlays
    function setSelectedOverlays() {
        // clear the selected overlays object
        $scope.selectedOverlays = [];
        // get the current layer list from the url
        var currentLayerList = $stateParams.layers.split(',');
        _.each(currentLayerList, function (alias) {
            $scope.categories.forEach(function (c) {
                c.layers.forEach(function (l) {
                    if (l.alias == alias) {
                        $scope.selectedOverlays.push(l);
                    }
                });
            });
        });
        // if there are any active overlays, update activeOverlays
        if ($scope.selectedOverlays.length > 0) {
            // reverse the order to simulate draw order
            $scope.selectedOverlays.reverse();
            $scope.activeOverlays = true;
        }
        else {
            $scope.activeOverlays = false;
        }
    }
});