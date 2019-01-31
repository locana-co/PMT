/***************************************************************
 * Boundary Service
 * Service to support boundary data.
* *************************************************************/        

angular.module('PMTViewer').service('boundaryService', function ($q, $http, $rootScope, pmt) {

    var boundaryService = { };
        
    // get filtered boundary features
    boundaryService.filterBoundaryFeatures = function (boundary_table, query_field, query) {
        var deferred = $q.defer();
        var options = {
            boundary_table: boundary_table, // Required. the name of the boundary spatial table to filter.
            query_field: query_field, // the name of the field within the boundary table to apply filter to.
            query: query, // comma seperated list values to filter by.           
            pmtId: pmt.id[pmt.env]
        };
        var header = {
            headers: { Authorization : 'Bearer ' + $rootScope.currentUser.token }
        };
        
        $http.post(pmt.api[pmt.env] + 'pmt_boundary_filter', options, header, { cache: true })
            .success(function (data, status, headers, config) {
            // remove unneccessary response object from api
            var response = _.pluck(data, 'response');
            // console.log('pmt_boundary_filter:', response);
            deferred.resolve(response);
        })
            .error(function (data, status, headers, c) {
            // there was an error report it to the error handler
            console.log("error on api call to: pmt_boundary_filter");
            deferred.reject(status);
        });
        return deferred.promise;
    };       
    
    // get boundary features extent
    boundaryService.getBoundaryExtent = function (boundary_table, feature_names) {
        var deferred = $q.defer();
        var options = {
            boundary_table: boundary_table, // Required. the name of the boundary spatial table.
            feature_names: feature_names, // the name(s) of the features to include in the extent.
            pmtId: pmt.id[pmt.env]
        };
        var header = {
            headers: { Authorization : 'Bearer ' + $rootScope.currentUser.token }
        };
        
        $http.post(pmt.api[pmt.env] + 'pmt_boundary_extents', options, header, { cache: true })
            .success(function (data, status, headers, config) {
            // remove unneccessary response object from api
            var response = _.pluck(data, 'response');
            // console.log('pmt_boundary_extents:', response);
            deferred.resolve(response);
        })
            .error(function (data, status, headers, c) {
            // there was an error report it to the error handler
            console.log("error on api call to: pmt_boundary_extents");
            deferred.reject(status);
        });
        return deferred.promise;
    };

    // get boundary menu (hierarchy)
    boundaryService.getBoundaryMenu = function (boundary_type, admin_levels, filter_features, data_group_ids) {
        var deferred = $q.defer();
        var options = {
            boundary_type: boundary_type, // Required. the boundary type for the created hierarchy. Options: gaul, gadm, unocha, nbs.
            admin_levels: admin_levels, // a comma delimited list of admin levels to include. Options: 0,1,2,3 
            filter_features : filter_features, //a comma delimited list of names of features in the highest admin level to restrict data to.
            data_group_ids: data_group_ids, // a comma delimited list of data groups to filter features to, only features with a data group's locaiton will be included
            pmtId: pmt.id[pmt.env]
        };
        var header = {
            headers: { Authorization : 'Bearer ' + $rootScope.currentUser.token }
        };
        
        $http.post(pmt.api[pmt.env] + 'pmt_boundary_hierarchy', options, header, { cache: true })
            .success(function (data, status, headers, config) {
            // remove unneccessary response object from api
            var response = _.pluck(data, 'response');
            //console.log('pmt_boundary_hierarchy:', response[0]);
            deferred.resolve(response[0]);
        })
            .error(function (data, status, headers, c) {
            // there was an error report it to the error handler
            console.log("error on api call to: pmt_boundary_hierarchy");
            deferred.reject(status);
        });
        return deferred.promise;
    };

    // search PMT boundaries by name
    boundaryService.getBoundaryByText = function (boundary_type, search_text) {
        var deferred = $q.defer();
        var options = {
            boundary_type: boundary_type, // Required. the boundary type for the created hierarchy. Options: gaul, gadm, unocha, nbs.
            search_text: search_text, // Text to search _name's for
            pmtId: pmt.id[pmt.env]
        };
        var header = {
            headers: { Authorization : 'Bearer ' + $rootScope.currentUser.token }
        };
        
        $http.post(pmt.api[pmt.env] + 'pmt_boundary_search', options, header, { cache: true })
            .success(function (data, status, headers, config) {

            // convert response to same format as address search
            var rsp = {
                // map return resutls to expected client format
                features: data.map(function(feature,idx) {
                    // get the extent of this feature
                    var boundsArr = feature.response.bounds.replace('BOX(','').replace(')','').split(',');
                    var swCords = boundsArr[0].split(' ');
                    var nwCords = boundsArr[1].split(' ');

                    // created the formatted display string
                    var formatted = 
                        ((feature.response.b3)?feature.response.b3.trim():'');
                    formatted = formatted +
                        (((formatted.length>0)&&(formatted.trim().slice(-1)!=','))?', ':'')+
                        ((feature.response.b2)?feature.response.b2.trim():'');
                    formatted = formatted +
                        (((formatted.length>0)&&(formatted.trim().slice(-1)!=','))?', ':'')+
                        ((feature.response.b1)?feature.response.b1.trim():'');
                    formatted = formatted +
                        (((formatted.length>0)&&(formatted.trim().slice(-1)!=','))?', ':'')+
                        ((feature.response.b0)?feature.response.b0.trim():'');

                    // map results
                    return {
                        id: feature.response.id,
                        boundary_table_name: feature.response.table_name,
                        type: 'Feature',
                        properties : {
                            formatted: formatted,
                            bounds: {
                                southwest: {
                                    lng: swCords[0],
                                    lat: swCords[1]
                                },
                                northeast: {
                                    lng: nwCords[0],
                                    lat: nwCords[1]
                                }
                            },
                            components: {
                                city: feature.response.b3,
                                county: feature.response.b2,
                                state: feature.response.b1,
                                country: feature.response.b0                
                            }
                        }
                    }
                }) // map rows to obj
            }; // reponse obj
            

            deferred.resolve(rsp);
        })
            .error(function (data, status, headers, c) {
            // there was an error report it to the error handler
            console.log("error on api call to: pmt_boundary_search");
            deferred.reject(status);
        });
        return deferred.promise;
    };
        

    return boundaryService;
   
});