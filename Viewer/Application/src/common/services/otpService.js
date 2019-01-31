/***************************************************************
 * Open Trip Planner (OTP) Service
 * Service to provide access to the open trip planner server. 
 * Supports the travel time analysis tool in the tools module.
* *************************************************************/   
angular.module('PMTViewer').service('otpService', function ($q, $http) {
    // the open trip planner service model
    var otpService = {};
    
    // get OTP isochrones
    otpService.getIsochrones = function (country, coordinates, mode, walkspeed, intervals) {
        var deferred = $q.defer();
        var walkspeed = walkspeed * 0.277778; // convert km/hr to m/sec
        var url = 'http://otp.investmentmapping.org/otp/routers/';
        url += country;
        url += '/isochrone?&fromPlace=' + coordinates;
        url += '&date=2016/04/09&time=12:00:00&mode=' + mode;
        url += '&walkSpeed=' + walkspeed;
        url += '&cutoffSec=' + (intervals[0] * 3600);
        url += '&cutoffSec=' + (intervals[1] * 3600);
        url += '&cutoffSec=' + (intervals[2] * 3600);
        url += '&cutoffSec=' + (intervals[3] * 3600);
        
        
        // request to OTP service for json isochrone polygons
        $http.get(url)
            .success(function (response) {
            deferred.resolve(response);
        })
            .error(function (response) {
            console.log(response);
            deferred.reject(response);
        });
        
        return deferred.promise;
    };
    
    // generate styling for isochrone polygons
    otpService.getStyle = function (feature) {
        var intervals = [2, 4, 6, 8];
        
        switch (feature.properties.time) {
            case 7200: return { color: '#FFFFFF', weight: 0, fillColor: "#6e016b", fillOpacity: 0.50 };
            case 14400: return { color: '#FFFFFF', weight: 0, fillColor: "#88419d", fillOpacity: 0.40 };
            case 21600: return { color: '#FFFFFF', weight: 0, fillColor: "#8c6bb1", fillOpacity: 0.20 };
            case 28800: return { color: '#FFFFFF', weight: 0, fillColor: "#8c96c6", fillOpacity: 0.20 };
        }
    };
    
    return otpService;
});