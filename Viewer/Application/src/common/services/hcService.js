/***************************************************************
 * Harvest Choice (HC) Data Service
 * Service to support access to the Harvest Choice Data API.
 * *************************************************************/

angular.module('PMTViewer').service('hcService', function ($q, $http) {
    // the harvest choice data service model
    var hcService = {};
    
    // dictionary for abbreviated crop names
    hcService.cropDictionary = {
        'bapl': 'Banana & Plantain',
        'bean': 'Bean',
        'cass': 'Cassava',
        'chic': 'Chickpea',
        'cowp': 'Cowpea',
        'grou': 'Groundnut',
        'maiz': 'Maize',
        'pmil': 'Pearl millet',
        'rice': 'Rice',
        'sorg': 'Sorghum',
        'swpo': 'Sweet potato',
        'whea': 'Wheat',
        'yams': 'Yam',
    };
    
    // dictionary for abbreviated aez climate names
    hcService.aezDictionary = [
        { 'label': 'Arid', 'abbrv': 'Arid' },
        { 'label': 'Humid', 'abbrv': 'Humid' },
        { 'label': 'Sub-Humid', 'abbrv': 'Sub-Humid' },
        { 'label': 'Semi-Arid', 'abbrv': 'Semi-Arid' },
        { 'label': 'SubTropic - warm/arid', 'abbrv': 'Trp. Hld. Arid' },
        { 'label': 'Tropic - cool / semiarid', 'abbrv': 'Trp. Hld. Semi-Arid' },
        { 'label': 'Tropic - cool / subhumid', 'abbrv': 'Trp. Hld. Sub-Humid' },
        { 'label': 'Tropic - cool / humid', 'abbrv': 'Trp. Hld. Humid' }
    ];
    
    // convert multipolygon geoJSON to single polygon geoJSON
    hcService.multiPolyToSingle = function (poly) {
        var result = [];
        
        if (poly.geometry.type == 'MultiPolygon') {
            poly.geometry.coordinates[0].forEach(function (coords) {
                var newPoly = {};
                newPoly.type = 'Feature';
                newPoly.properties = poly.properties;
                newPoly.geometry = {};
                newPoly.geometry.type = 'Polygon';
                newPoly.geometry.coordinates = [];
                newPoly.geometry.coordinates[0] = coords;
                
                result.push(newPoly);
            });
        }
        else {
            result.push(poly);
        }
        
        return result;
    };
    
    // convert geoJSON to WKT
    // code adapted from: https://github.com/mapbox/wellknown
    hcService.geojsonToWKT = function (gj) {
        
        // convert each geometry
        if (gj.type === 'Feature') {
            gj = gj.geometry;
        }
        
        // structure coordinates
        function pairWKT(c) {
            if (c.length === 2) {
                return c[0] + ' ' + c[1];
            } else if (c.length === 3) {
                return c[0] + ' ' + c[1] + ' ' + c[2];
            }
        }
        
        // collect vertices
        function ringWKT(r) {
            return r.map(pairWKT).join(', ');
        }
        
        function ringsWKT(r) {
            return r.map(ringWKT).map(wrapParens).join(', ');
        }
        
        function multiRingsWKT(r) {
            return r.map(ringsWKT).map(wrapParens).join(', ');
        }
        
        function wrapParens(s) {
            return '(' + s + ')';
        }
        
        // add wkt text and coordinates
        switch (gj.type) {
            case 'Polygon':
                return 'POLYGON (' + ringsWKT(gj.coordinates) + ')';
            case 'MultiPolygon':
                return 'MULTIPOLYGON (' + multiRingsWKT(gj.coordinates) + ')';
            case 'GeometryCollection':
                return 'GEOMETRYCOLLECTION (' + gj.geometries.map(stringify).join(', ') + ')';
            default:
                throw new Error('Not a valid geojson feature');
        }
    };
    
    // sort by greatest to fewest, and get top 3
    hcService.getTop3 = function (response) {
        var properties = Object.getOwnPropertyNames(response[0]);
        var dataset = [];
        
        // collect numeric data from result
        properties.forEach(function (element) {
            if (typeof response[0][element] === 'number') {
                var data = {};
                
                data.name = element;
                data.value = response[0][element];
                dataset.push(data);
            }
        });
        
        // sort numeric data by crop yield
        dataset = dataset.sort(function (a, b) { return a.value - b.value });
        
        // order by greatest to fewest
        dataset = dataset.reverse();
        
        // use only top 3 crops
        return dataset.splice(0, 3);
    };
    
    // get agro-ecological zones by wkt polygon (top 3 ranked by area if more than one)
    hcService.getAEZs = function (wkt) {
        var deferred = $q.defer();
        var url = 'http://hcapi.harvestchoice.org/ocpu/library/hcapi3/R/hcapi/json';
        var params = {
            var: 'AEZ8_CLAS',
            wkt: wkt
        };
        
        // get data from harvest choice api
        $http.post(url, params)
            .success(function (response) {
            //console.log(response);
            deferred.resolve(response);
        })
            .error(function () {
            deferred.reject(response);
        });
        return deferred.promise;
    };
    
    // get farming system by wkt polygon (ranked by area if more than one)
    hcService.getFarmSys = function (wkt) {
        var deferred = $q.defer();
        var url = 'http://hcapi.harvestchoice.org/ocpu/library/hcapi3/R/hcapi/json';
        var params = {
            var: 'FS_2012',
            wkt: wkt
        };
        
        // get data from harvest choice api
        $http.post(url, params)
            .success(function (response) {
            //console.log(response);
            deferred.resolve(response);
        })
            .error(function () {
            deferred.reject(response);
        });
        return deferred.promise;
    };
    
    // get crop yield (kg/ha) focus crops by wkt polygon
    hcService.getCropYield = function (wkt) {
        var deferred = $q.defer();
        var url = 'http://hcapi.harvestchoice.org/ocpu/library/hcapi3/R/hcapi/json';
        var params = {
            var: ['bapl_y', 'bean_y', 'cass_y', 'chic_y', 'cowp_y', 'grou_y', 'maiz_y', 'pmil_y', 'rice_y', 'sorg_y', 'swpo_y', 'whea_y', 'yams_y'], //'vp_crop_ar'
            wkt: wkt
        };
        
        // get data from harvest choice api
        $http.post(url, params)
            .success(function (response) {
            deferred.resolve(hcService.getTop3(response));
        })
            .error(function () {
            deferred.reject(response);
        });
        return deferred.promise;
    };
    
    // get crop yield (mt) focus crops by wkt polygon
    hcService.getCropProd = function (wkt) {
        var deferred = $q.defer();
        var url = 'http://hcapi.harvestchoice.org/ocpu/library/hcapi3/R/hcapi/json';
        var params = {
            var: ['bapl_p', 'bean_p', 'cass_p', 'chic_p', 'cowp_p', 'grou_p', 'maiz_p', 'pmil_p', 'rice_p', 'sorg_p', 'swpo_p', 'whea_p', 'yams_p'], // 'vp_crop'
            wkt: wkt
        };
        
        // get data from harvest choice api
        $http.post(url, params)
            .success(function (response) {
            deferred.resolve(hcService.getTop3(response));
        })
            .error(function () {
            deferred.reject(response);
        });
        return deferred.promise;
    };
    
    // get harvested area (ha) focus crops by wkt polygon
    hcService.getHarvArea = function (wkt) {
        var deferred = $q.defer();
        var url = 'http://hcapi.harvestchoice.org/ocpu/library/hcapi3/R/hcapi/json';
        var params = {
            var: ['bapl_h', 'bean_h', 'cass_h', 'chic_h', 'cowp_h', 'grou_h', 'maiz_h', 'pmil_h', 'rice_h', 'sorg_h', 'swpo_h', 'whea_h', 'yams_h'],
            wkt: wkt
        };
        
        // get data from harvest choice api
        $http.post(url, params)
            .success(function (response) {
            deferred.resolve(hcService.getTop3(response));
        })
            .error(function () {
            deferred.reject(response);
        });
        return deferred.promise;
    };
    
    // translate abbreviated crop names
    hcService.getCropDictionary = function (abbrv) {
        return hcService.cropDictionary[abbrv.slice(0, abbrv.length - 2)];
    };
    
    return hcService;

});