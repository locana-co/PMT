/***************************************************************
 * Basemap Service
 * Manages all the basemap layers.
* *************************************************************/        

angular.module('PMTViewer').service('basemapService', function ($http, $q, $stateParams, global) {

    var basemapService = {};

    // create basemap layer by alias
    basemapService.getBasemap = function (alias) {
        var basemap = _.find(global.basemaps, function (basemap) { return basemap.alias == alias });
        var basemapLyr = L.tileLayer(basemap.url, {
            attribution: basemap.attribution
        });
        basemapLyr.overlayName = basemap.alias;
        basemapLyr.isBasemap = true;
        // ensure the basemap stays in the back
        basemapLyr.on('load', function () {
            try {
                //Move to back
                basemapLyr.bringToBack();
            }
            catch (e) { }
        });
        return basemapLyr;
    };

    // create style layer by alias
    basemapService.getStyle = function (alias) {
        var basemap = _.find(global.styles, function (basemap) { return basemap.alias == alias; });
        basemapLyr.attribution = basemap.attribution;
        basemap.overlayName = basemap.alias;
        basemap.isBasemap = true;

        return basemap;
    };
        
    return basemapService;
});