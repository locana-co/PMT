/***************************************************************
 * Data Source Controller
 * A filter controller. Supports the data sources for PMT. These
 * are defined in the app.config in the explorer page filter object.
* *************************************************************/ 
angular.module('PMTViewer').controller('MapFilterDataSourceCtrl', function ($scope, $http, $rootScope, $state, $stateParams, stateService, config, global) {
    // $scope.page holds the tools page object defined in app.config
    if ($scope.page) {
        // get the current state
        var state = stateService.getState();
        // get the list of layers from state
        var layers = state.layers.split(',');
        // activate options that are listed in state
        _.each(layers, function (alias) {
            var option = _.find($scope.page.tools.map.layers, function (l) { return l.alias == alias; });
            if (option) { option.active = true; }
        });
        // assign the options for the view (list of PMT layers)
        $scope.options = $scope.page.tools.map.layers;
    }

    // the options have changed
    $scope.optionClicked = function (option) {
        // toggle current option active flag
        option.active = !option.active;
        try {
            // get the current state
            var state = stateService.getState();
            // set the layers active where present in url
            var layers = [];
            if ($stateParams.layers !== '') {
                layers = $stateParams.layers.split(',');
            }            
            // add layer
            if (option.active === true) {
                // is the layer already in the url?
                var param = _.find(layers, function (l) { return l == option.alias; });
                // add the param if it is not there
                if (!param) {
                    layers.push(option.alias);
                    $stateParams.layers = layers.join();
                }
            // remove layer
            } else {
                var params = _.filter(layers, function (l) { return l !== option.alias; });
                if (params.length != layers.length) {
                    $stateParams.layers = params.join() || '';
                }
            }            
            // update parameters        
            stateService.setState($state.current.name || 'home', $stateParams, false);
        }
        // error handler
        catch (ex) {
            // there was an error report it to the error handler
            console.log(ex);
        }
    };
    
    // when the url is updated do this
    $scope.$on('layers-update', function () {
        // get the current state
        var state = stateService.getState();
        // if the layer list has changed, update the map
        if (stateService.paramChanged('layers')) {
            try {
                // reset the layers
                _.each($scope.page.tools.map.layers, function (layer) {
                    if (layer.active) {
                        layer.active = false;
                    }
                });                
                // set the layers active where present in url
                var layers = state.layers.split(',');
                if (layers.length > 0) {
                    _.each(layers, function (alias) {
                        var layer = _.find($scope.page.tools.map.layers, function (l) { return l.alias == alias; });
                        if (layer) {
                            layer.active = true;
                        }
                    });
                }                
            }
            // error handler
            catch (ex) {
                // there was an error report it to the error handler
            }
        }                
    });    
});