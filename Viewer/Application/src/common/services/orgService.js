/***************************************************************
 * Organization Service
 * Service to support organization module.
* *************************************************************/
angular.module('PMTViewer').service('orgService', function ($q, $http, $rootScope, $state, $stateParams, config, pmt, stateService) {
    // the organization service model
    var orgsService = {};
    // internal organization service attributes
    var service = {
        organizations: null
    };

    // getters
    orgsService.getAllOrgs = function () { return service.organizations; };

    // get all organizations
    orgsService.getOrgs = function () {
        var deferred = $q.defer();
        var options = {
            pmtId: pmt.id[pmt.env]
        };
        var header = {
            headers: { Authorization: 'Bearer ' + $rootScope.currentUser.token }
        };
        // use existing data if saved in scope
        if (pmt.orgs) {
            deferred.resolve(pmt.orgs);
            return deferred.promise;
        } else {
            // call the api
            $http.post(pmt.api[pmt.env] + 'pmt_orgs', options, header, { cache: true }).success(function (data, status, headers, config) {
                // remove unneccessary response object from api
                var orgs = _.pluck(data, 'response');
                orgs = _.each(orgs, function (inst) {
                    inst.name = inst._name.replace(/\s*\(.*?\)\s*/g, '');
                    inst.compareName = inst.name.toLowerCase();
                    inst.label = inst._label;
                    inst.url = inst._url;
                    inst.orderedBy = inst._label ? inst._label : inst.name;
                });
                orgs = _.sortBy(orgs, 'orderedBy');
                $rootScope.$broadcast('org-list-updated');
                service.organizations = orgs;
                deferred.resolve(orgs);
            }).error(function (data, status, headers, c) {
                // there was an error report it to the error handler
                console.log("error on api call to: pmt_orgs");
                deferred.reject(status);
            });
            return deferred.promise;
        }
    };

    // create a new organization
    orgsService.createOrg = function (org) {
        var orgJsonObj = getOrgJsonObject(org);
        var options = {
            pmtId: pmt.id[pmt.env],
            instance_id: pmt.instance,
            user_id: $rootScope.currentUser.user.id,
            delete_record: false,
            key_value_data: orgJsonObj
        };

        return editOrgInstance(options);
    };

    // delete organization record
    orgsService.deleteOrg = function (org) {
        var options = {
            pmtId: pmt.id[pmt.env],
            instance_id: pmt.instance,
            user_id: $rootScope.currentUser.user.id,
            delete_record: true,
            organization_id: org.id,
        };

        return editOrgInstance(options);
    };

    // make changes to exisiting organization
    orgsService.changeOrg = function (org) {
        var orgJsonObj = getOrgJsonObject(org);
        var options = {
            pmtId: pmt.id[pmt.env],
            instance_id: pmt.instance,
            user_id: $rootScope.currentUser.user.id,
            delete_record: false,
            organization_id: org.id,
            key_value_data: orgJsonObj
        };

        return editOrgInstance(options)
    };

    // Consolidate Organization
    // Takes One organization ID to keep, and an array of organizations to consolidate into the kept organization.
    orgsService.consolidate = function (orgId, orgs) {
        var deferred = $q.defer();

        var header = {
            headers: { Authorization: 'Bearer ' + $rootScope.currentUser.token }
        };

        var options = {
            pmtId: pmt.id[pmt.env],
            instance_id: pmt.instance,
            user_id: $rootScope.currentUser.user.id,
            organization_to_keep_id: orgId,
            organization_ids_to_consolidate: orgs
        };

        $http.post(pmt.api[pmt.env] + 'pmt_consolidate_orgs', options, header)
            .success(function (data, status, headers, config) {
                deferred.resolve(data);
            }).error(function (data, status, headers, c) {
                // there was an error report it to the error handler
                console.log("error on the api call to (post) pmt_consolidate_orgs");
                deferred.reject(data.message);
            });

        return deferred.promise;
    }

    // edit organization - create, delete, or change
    function editOrgInstance(options) {
        var deferred = $q.defer();

        var header = {
            headers: { Authorization: 'Bearer ' + $rootScope.currentUser.token }
        };

        // call the api
        $http.post(pmt.api[pmt.env] + 'pmt_edit_organization', options, header)
            .success(function (data, status, headers, config) {
                deferred.resolve(data);
            }).error(function (data, status, headers, c) {
                // there was an error report it to the error handler
                console.log("error on api call to: (post) pmt_edit_organizations");
                deferred.reject(data.message);
            });

        return deferred.promise;
    };

    // create an organization json object
    function getOrgJsonObject(org) {
        var orgJsonObject = {};
        var name = org.name;
        if (org.label === undefined || org.label === null || org.label === '') {
            orgJsonObject._label = null;
        } else {
            orgJsonObject._label = org.label;
            name = org.name + ' (' + org.label + ')';
        }
        orgJsonObject._name = name;
        if (org.url === undefined || org.url === null || org.url === '') {
            orgJsonObject._url = null;
        } else {
            orgJsonObject._url = org.url;
        }
        return orgJsonObject;
    }

    return orgsService;
});
