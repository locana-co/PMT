/***************************************************************
 * Contextual Layer Menu Controller
 * Supports the contextual layers menu feature.
* *************************************************************/ 
angular.module('PMTViewer').controller('MapContextualCtrl', function ($scope, $state, $rootScope, $stateParams, $q, $http, $sce, stateService, pmtMapService, mapService, config) {
    $scope.stateService = stateService;
    //keeps track of active category
    $scope.activeCategory = null;
    //tooltip object
    $scope.catTooltip = {};
    //start by hiding tooltip
    $scope.catTooltip.show = false;
    
    // initialization      
    if ($scope.page) {
        // get the current state
        var state = stateService.getState();
        // get the list of layers from state
        var layers = state.layers.split(',');
        // activate options that are listed in state
        _.each(layers, function (alias) {
            _.each($scope.page.tools.map.contextual, function (category) {
                var option = _.find(category.layers, function (l) { return l.alias == alias; });
                if (option) {
                    option.active = true;
                    if (option.legend) {
                        if (option.legend.includes('legend?f=pjson')) {
                            pmtMapService.getAGSLegendJSON(option, $scope);
                        }
                        else {
                            var html = '<img src="' + option.legend + '" >';
                            option.legendHTML = $sce.trustAsHtml(html);
                        }
                    }
                }
                // add property of whether to show tooltip
                _.each(category, function(l) {
                    l.showTooltip = false;
                });
            });

        });
        // assign the contextual object
        $scope.categories = $scope.page.tools.map.contextual;
    }
    
    // when the url is updated do this
    $scope.$on('layers-update', function () {
        // get the current state
        var state = stateService.getState();
        // if the layer list has changed, update the map
        if (stateService.paramChanged('layers')) {
            try {
                // reset the contextual layers
                _.each($scope.categories, function (category) {
                    _.each(category.layers, function (layer) {
                        if (layer.active) {
                            layer.active = false;
                        }
                    });
                });
                // set the layers active where present in url
                var layers = state.layers.split(',');
                if (layers.length > 0) {
                    _.each(layers, function (alias) {
                        _.each($scope.categories, function (category) {
                            var contextual = _.find(category.layers, function (l) { return l.alias == alias; });
                            if (contextual) {
                                contextual.active = true;
                            }
                        });
                    });
                }
            }
            // error handler
            catch (ex) {
                // there was an error report it to the error handler
            }
        }
    });
    
    // when the url is updated do this
    $scope.$on('route-update', function () {
        if (stateService.isNotParam('left-panel')) { $scope.sideoutOpen = false; }
    });
    
    // a menu category has been selected, show the sub menu
    $scope.onMenuClick = function (alias) {
        $scope.activeCategory = alias;
        $scope.sideoutOpen = true;
        $scope.resizeLeftPanel();
    };
    
    // go back to the main menu
    $scope.closeSlideOut = function () {
        $scope.sideoutOpen = false;
    };
    
    // the options have changed
    $scope.optionChanged = function (option) {
        try {
            // toggle current option active flag
            option.active = !option.active;
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
                if (option.legend.includes('legend?f=pjson')) {
                    pmtMapService.getAGSLegendJSON(option, $scope);
                }
                else if (option.legend.includes('json')) {
                    pmtMapService.getPMTLegendJSON(option, $scope);
                }
                else {
                    var html = '<img class="legend-url" src="' + option.legend + '" >';
                    option.legendHTML = $sce.trustAsHtml(html);
                }
            // remove layer
            } else {
                // set the layer's opacity back to default settings
                option.opacity = 0.80;
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
    
    // only open category bin one at a time
    $scope.categoryEvent = function (category) {
        try {
            //check if the category bin is opened, if it is close it. If not open it.
            if (category.active) {
                category.active = false;
            } else {
                //reset category bins - close bins
                for (var cate in $scope.category) {
                    $scope.category[cate].active = false;
                }
                //clicked category to be true and open bin
                category.active = true;
            }
        }
        // error handler
        catch (ex) {
            // there was an error report it to the error handler
        }
    };

    $scope.showTooltip = function() {
        $scope.catTooltip.show = true;
        var option = _.find($scope.page.tools.map.contextual, function (c) { return c.alias == $scope.activeCategory; });
        //add elements to tooltip
        $scope.catTooltip.source = option.metadata.source;
        $scope.catTooltip.reference_period = option.metadata.reference_period;
        $scope.catTooltip.url = option.metadata.URL;

    };

    $scope.hideTooltip = function() {
        $scope.catTooltip.show = false;
    };

});

// all templates used by the left panel contextual layers
require('./selection/selection.js');