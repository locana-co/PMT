/***************************************************************
 * Analysis Service
 * Provides access to analysis functions and data.
* *************************************************************/        
angular.module('PMTViewer').service('analysisService', function ($rootScope, $http, $q, pmt) {
    
    var analysisService = {};
    
    // get all the participating regions for the 2x2 tool
    analysisService.get2x2Regions = function () {
        var deferred = $q.defer();
        var options = {
            pmtId: pmt.id[pmt.env]
        };
        var header = {
            headers: { Authorization : 'Bearer ' + $rootScope.currentUser.token }
        };
        // call the api to get the country and region information
        $http.post(pmt.api[pmt.env] + 'pmt_2x2_regions', options, header, { cache: true })
            .success(function (data, status, headers, config) {
            // remove unneccessary response object from api
            var regions = _.pluck(data, 'response');
            // console.log('pmt_2x2_regions:', regions);
            deferred.resolve(regions);
        })
            .error(function (data, status, headers, c) {
            // there was an error report it to the error handler
            console.log("error on api call to: pmt_2x2_regions");
            deferred.reject(status);
        });
        return deferred.promise;
    };
    
    // get 2x2 data for a given country name & region name
    analysisService.get2x2 = function (country, region) {
        var deferred = $q.defer();
        var options = {
            country: country, //  name of the country (gadm0)
            region: region, // name of the region within country (gadm1)
            pmtId: pmt.id[pmt.env]
        };
        var header = {
            headers: { Authorization : 'Bearer ' + $rootScope.currentUser.token }
        };
        // call the api to get a 2x2 data set for a country and region
        $http.post(pmt.api[pmt.env] + 'pmt_2x2', options, header, { cache: true })
            .success(function (data, status, headers, config) {
            // remove unneccessary response object from api
            var table = _.pluck(data, 'response');
            // console.log('pmt_2x2:', table);
            deferred.resolve(table);
        })
            .error(function (data, status, headers, c) {
            // there was an error report it to the error handler
            console.log("error on api call to: pmt_2x2");
            deferred.reject(status);
        });
        return deferred.promise;
    };
    
    // get activity counts and investment totals by taxonomy
    analysisService.getStatsActivityByTaxonomy = function (taxonomy_id, data_group_ids, classification_ids, start_date, end_date, boundary_id, feature_id, record_limit, filter_classification_ids) {
        var deferred = $q.defer();
        var options = {
            taxonomy_id: taxonomy_id, // Required. the taxonomy id to classify returned activity investments and counts.
            data_group_ids: data_group_ids, //comma seperated list of classification id(s) from the Data Group taxonomy to restrict data. If no data group id is provided, all data groups are included.
            classification_ids: classification_ids, //comma seperated list of classification id(s) for any taxonomy (filter).
            start_date: start_date, // start date for activities (filter).
            end_date: end_date, // end date for activities (filter).
            boundary_id: boundary_id, //id of boundary layer
            feature_id: feature_id, // id of location geometry
            record_limit: record_limit, // max number of classifications to return
            filter_classification_ids: filter_classification_ids, // list of classifications within provided taxonomy_id to filter return to
            pmtId: pmt.id[pmt.env]
        };
        var header = {
            headers: { Authorization : 'Bearer ' + $rootScope.currentUser.token }
        };

        $http.post(pmt.api[pmt.env] + 'pmt_stat_activity_by_tax', options, header, { cache: true })
            .success(function (data, status, headers, config) {
            // remove unneccessary response object from api
            var stats = _.pluck(data, 'response');
            // console.log('pmt_stat_activity_by_tax:', stats);
            deferred.resolve(stats);
        })
            .error(function (data, status, headers, c) {
            // there was an error report it to the error handler
            console.log("error on api call to: pmt_stat_activity_by_tax");
            deferred.reject(status);
        });
        return deferred.promise;
    };
        
    // get investment totals by funder
    analysisService.getStatsInvestmentsByFunder = function (data_group_ids, classification_ids, start_date, end_date, boundary_id, feature_id, limit_records) {
        var deferred = $q.defer();
        var options = {
            data_group_ids: data_group_ids, //comma seperated list of classification id(s) from the Data Group taxonomy to restrict data. If no data group id is provided, all data groups are included.
            classification_ids: classification_ids, //comma seperated list of classification id(s) for any taxonomy (filter).
            start_date: start_date, // start date for activities (filter).
            end_date: end_date, // end date for activities (filter).
            boundary_id: boundary_id, //id of boundary layer
            feature_id: feature_id, // id of location geometry,
            limit_records: limit_records,
            pmtId: pmt.id[pmt.env]
        };
        var header = {
            headers: { Authorization : 'Bearer ' + $rootScope.currentUser.token }
        };
        
        $http.post(pmt.api[pmt.env] + 'pmt_stat_invest_by_funder', options, header, { cache: true })
            .success(function (data, status, headers, config) {
            // remove unneccessary response object from api
            var stats = _.pluck(data, 'response');
            // console.log('pmt_stat_invest_by_funder:', stats);
            deferred.resolve(stats);
        })
            .error(function (data, status, headers, c) {
            // there was an error report it to the error handler
            console.log("error on api call to: pmt_stat_invest_by_funder");
            deferred.reject(status);
        });
        return deferred.promise;
    };

    // get activity count totals by org
    analysisService.getStatsByOrg = function (data_group_ids, classification_ids, start_date, end_date, org_role_id, boundary_id, feature_id, limit_records) {
        var deferred = $q.defer();
        var options = {
            data_group_ids: data_group_ids, //comma seperated list of classification id(s) from the Data Group taxonomy to restrict data. If no data group id is provided, all data groups are included.
            classification_ids: classification_ids, //comma seperated list of classification id(s) for any taxonomy (filter).
            start_date: start_date, // start date for activities (filter).
            end_date: end_date, // end date for activities (filter).
            org_role_id: org_role_id, // required: the organization role id for organizations to include in data
            boundary_id: boundary_id, //id of boundary layer
            feature_id: feature_id, // id of location geometry
            limit_records: limit_records,
            pmtId: pmt.id[pmt.env]
        };
        var header = {
            headers: { Authorization : 'Bearer ' + $rootScope.currentUser.token }
        };

        $http.post(pmt.api[pmt.env] + 'pmt_stat_by_org', options, header, { cache: true })
            .success(function (data, status, headers, config) {
                // remove unneccessary response object from api
                var stats = _.pluck(data, 'response');
                // console.log('pmt_stat_by_org:', stats);
                deferred.resolve(stats);
            })
            .error(function (data, status, headers, c) {
                // there was an error report it to the error handler
                console.log("error on api call to: pmt_stat_by_org");
                deferred.reject(status);
            });
        return deferred.promise;
    };
    
    // get partner pivot table
    analysisService.getPartnerPivot = function (column_taxonomy_id, row_taxonomy_id, org_role_id, data_group_ids, classification_ids, start_date, end_date, boundary_id, feature_id) {
        var deferred = $q.defer();
        var options = {
            row_taxonomy_id: row_taxonomy_id, // required: taxonomy for row/y-axis of pivot
            column_taxonomy_id: column_taxonomy_id, // required: taxonomy for column/x-axis of pivot
            org_role_id: org_role_id, // required: the organization role id for organizations to include in data
            data_group_ids: data_group_ids, //comma seperated list of classification id(s) from the Data Group taxonomy to restrict data. If no data group id is provided, all data groups are included.
            classification_ids: classification_ids, //comma seperated list of classification id(s) for any taxonomy (filter).
            start_date: start_date, // start date for activities (filter).
            end_date: end_date, // end date for activities (filter).
            boundary_id: boundary_id, //id of boundary layer
            feature_id: feature_id, // id of location geometry
            pmtId: pmt.id[pmt.env]
        };
        var header = {
            headers: { Authorization : 'Bearer ' + $rootScope.currentUser.token }
        };
        
        $http.post(pmt.api[pmt.env] + 'pmt_partner_pivot', options, header, { cache: true })
            .success(function (data, status, headers, config) {
            // remove unneccessary response object from api
            var stats = _.pluck(data, 'response');
            // console.log('pmt_partner_pivot:', stats);
            deferred.resolve(stats);
        })
            .error(function (data, status, headers, c) {
            // there was an error report it to the error handler
            console.log("error on api call to: pmt_partner_pivot");
            deferred.reject(status);
        });
        return deferred.promise;
    };

    // get boundary pivot table
    analysisService.getBoundaryPivot = function (pivot_boundary_id, pivot_taxonomy_id, boundary_as_row, org_role_id, data_group_ids, classification_ids, start_date, end_date, boundary_id, feature_id) {
        var deferred = $q.defer();
        var options = {
            pivot_boundary_id: pivot_boundary_id, // required: boundary for row/y-axis or column/x-axis of pivot
            pivot_taxonomy_id: pivot_taxonomy_id, // required: taxonomy for row/y-axis or column/x-axis of pivot
            boundary_as_row: boundary_as_row, // default is false, when true boundary is row/y-axis, when false is column/x-axis
            org_role_id: org_role_id, // required: the organization role id for organizations to include in data
            data_group_ids: data_group_ids, //comma seperated list of classification id(s) from the Data Group taxonomy to restrict data. If no data group id is provided, all data groups are included.
            classification_ids: classification_ids, //comma seperated list of classification id(s) for any taxonomy (filter).
            start_date: start_date, // start date for activities (filter).
            end_date: end_date, // end date for activities (filter).
            boundary_id: boundary_id, //id of boundary layer
            feature_id: feature_id, // id of location geometry
            pmtId: pmt.id[pmt.env]
        };
        var header = {
            headers: { Authorization : 'Bearer ' + $rootScope.currentUser.token }
        };
        
        $http.post(pmt.api[pmt.env] + 'pmt_boundary_pivot', options, header, { cache: true })
            .success(function (data, status, headers, config) {
            // remove unneccessary response object from api
            var stats = _.pluck(data, 'response');
            // console.log('pmt_boundary_pivot:', stats);
            deferred.resolve(stats);
        })
            .error(function (data, status, headers, c) {
            // there was an error report it to the error handler
            console.log("error on api call to: pmt_boundary_pivot");
            deferred.reject(status);
        });
        return deferred.promise;
    };

    // get activities by investment
    analysisService.getActivityByInvestment = function (data_group_ids, classification_ids, start_date, end_date, boundary_id, feature_id, limit_records, field_list) {
        var deferred = $q.defer();
        var options = {
            data_group_ids: data_group_ids, //comma seperated list of classification id(s) from the Data Group taxonomy to restrict data. If no data group id is provided, all data groups are included.
            classification_ids: classification_ids, //comma seperated list of classification id(s) for any taxonomy (filter).
            start_date: start_date, // start date for activities (filter).
            end_date: end_date, // end date for activities (filter).
            boundary_id: boundary_id, //id of boundary layer
            feature_id: feature_id, // id of location geometry
            limit_records: limit_records, // number of records to return
            field_list: field_list, // list of columns from activity table to add to the return
            pmtId: pmt.id[pmt.env]
        };
        var header = {
            headers: { Authorization : 'Bearer ' + $rootScope.currentUser.token }
        };

        $http.post(pmt.api[pmt.env] + 'pmt_activity_by_invest', options, header, { cache: true })
            .success(function (data, status, headers, config) {
                // remove unneccessary response object from api
                var stats = _.pluck(data, 'response');
                // console.log('pmt_activity_by_invest:', stats);
                deferred.resolve(stats);
            })
            .error(function (data, status, headers, c) {
                // there was an error report it to the error handler
                console.log("error on api call to: pmt_activity_by_invest");
                deferred.reject(status);
            });
        return deferred.promise;
    };
        
    // get overview statistics
    analysisService.getOverviewStats = function (data_group_ids, classification_ids, start_date, end_date, boundary_id, feature_ids) {
        var deferred = $q.defer();
        var options = {
            data_group_ids: data_group_ids, //comma seperated list of data groups from the Data Group taxonomy to restrict data. If no data group id is provided, all data groups are included.
            classification_ids: classification_ids, //comma seperated list of classification id(s) for any taxonomy (filter).
            start_date: start_date, // start date for activities (filter).
            end_date: end_date, // end date for activities (filter).
            boundary_id: boundary_id,
            feature_ids: feature_ids,
            pmtId: pmt.id[pmt.env]
        };
        var header = {
            headers: { Authorization : 'Bearer ' + $rootScope.currentUser.token }
        };
        
        $http.post(pmt.api[pmt.env] + 'pmt_overview_stats', options, header, { cache: true })
            .success(function (data, status, headers, config) {
            // remove unneccessary response object from api
            var stats = _.pluck(data, 'response');
            // console.log('pmt_overview_stats:', stats);
            deferred.resolve(stats);
        })
            .error(function (data, status, headers, c) {
            // there was an error report it to the error handler
            console.log("error on api call to: pmt_overview_stats");
            deferred.reject(status);
        });
        return deferred.promise;
    };
    
    // get activity titles by ids
    analysisService.getActivityTitles = function (activity_ids) {
        var deferred = $q.defer();
        var options = {
            activity_ids: activity_ids, // integer array of activity ids
            pmtId: pmt.id[pmt.env]
        };
        var header = {
            headers: { Authorization : 'Bearer ' + $rootScope.currentUser.token }
        };

        $http.post(pmt.api[pmt.env] + 'pmt_activity_titles', options, header)
            .success(function (data, status, headers, config) {
                // remove unneccessary response object from api
                var stats = _.pluck(data, 'response');
                // console.log('pmt_activity_titles:', stats);
                deferred.resolve(stats);
            })
            .error(function (data, status, headers, c) {
                // there was an error report it to the error handler
                console.log("error on api call to: pmt_activity_titles");
                deferred.reject(status);
            });
        return deferred.promise;
    };

    return analysisService;
});