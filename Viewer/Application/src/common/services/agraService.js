/***************************************************************
 * MIS Grant Import Service
 * Service to support import module.
* *************************************************************/
angular.module('PMTViewer').service('agraService', function ($q, $http, $rootScope, config, pmt, utilService) { 
    // the organization service model
    var agraService = {
        data: {
        }, //container for all data
        taxonomies: [],
        orgs: []
    };

    var stateConfig = _.find(config.states, function (states) { return states.route == 'agra'; });

    //function to perform on load
    agraService.init = function () {

    };

    // start the AGRA MIS integration
    agraService.startIntegration = function () {
        var deferred = $q.defer();
        var options = {
            instance_id: pmt.instance,
            user_id: $rootScope.currentUser.user.id,
            pmtId: pmt.id[pmt.env]
        };
        var header = {
            headers: { Authorization: 'Bearer ' + $rootScope.currentUser.token }
        };
        // call the api
        $http.post(pmt.api[pmt.env] + 'agra_mis_integration', options, header)
            .success(function (data, status, headers, config) {
                deferred.resolve(data);
                console.log('agra_mis_integration:',data);
            })
            .error(function (data, status, headers, c) {
                // there was an error report it to the error handler
                console.log("error on api call to: agra_mis_integration");
                deferred.reject(status);
            });
        return deferred.promise;
    };

     // check status of a AGRA MIS integration
     agraService.integrationStatus = function () {
        var deferred = $q.defer();
        var options = {
            pmtId: pmt.id[pmt.env]
        };
        var header = {
            headers: { Authorization: 'Bearer ' + $rootScope.currentUser.token }
        };
        // call the api
        $http.post(pmt.api[pmt.env] + 'agra_mis_integration_status', options, header)
            .success(function (data, status, headers, config) {
                deferred.resolve(data);
                console.log('agra_mis_integration_status:',data);
            })
            .error(function (data, status, headers, c) {
                // there was an error report it to the error handler
                console.log("error on api call to: agra_mis_integration_status");
                deferred.reject(status);
            });
        return deferred.promise;
    };

    // start service
    agraService.init();

    return agraService;
});
