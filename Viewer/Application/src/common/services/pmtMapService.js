/***************************************************************
 * PMT Map Service
 * Service to interact with PMT Map Data. The locations in PMT 
 * are treated very uniquely.
* *************************************************************/

angular.module('PMTViewer').service('pmtMapService', function ($q, $http, $rootScope, $state, $stateParams, config, pmt, stateService, $sce, partnerLinkService, $mdDialog) {
    // the pmt map service model
    var pmtMapService = {
        map: {},
        layers: {}, // contains the PMT layers
        layersPlusClass: {},
        plusClasses: ['plus0', 'plus1', 'plus2', 'plus3', 'plus4', 'plus5', 'plus6'],
        orgsInUse: [], // holds the in use orgs for reference
        allOrgs: [], // holds the list of all active orgs for reference
        taxonomies: [], // holds the taxonomies for filters
        selectedDetails: [], // holds the selected activity details (id, title)
        activityCount: 0
    };

    // private variable
    // filter contains current filter settings for all PMT layers
    var filter = {
        classification_ids: [], // list of classification_ids (excluding data group)
        imp_org_ids: [], // implementing organization ids
        fund_org_ids: [],  // funding organization ids
        org_ids: [], // organization ids (does not factor in organization role)
        start_date: null, // activity start date
        end_date: null,  // activity end date
        unassigned_taxonomy_ids: [],  // unassigned taxonomy  ids (filter parameter for including activities that are NOT assigned to a given taxonomy)
        boundary_filter: null, // json object containing boundary filters (i.e. [{"b":12,"ids":[2,3]},{"b":13,"ids":[73,85]}])
        keyword_filter: { //json object containing keyword filter
            keyword: null, // keyword value
            activity_ids: [] // a list of activity ids to filter to
        }
    };

    // when the url is updated do this
    $rootScope.$on('boundary-update-required', function (event, args) {
        updateBoundariesforLayers(args.boundaryLayer, args.boundaryLayers);
    });

    // initialize the pmt map service
    pmtMapService.init = function (map) {
        pmtMapService.map = map;
    };

    // creates and returns pmt layer by alias
    pmtMapService.getLayer = function (alias) {
        // create promise
        var deferred = $q.defer();
        // get the current state's config
        var stateConfig = _.find(config.states, function (states) { return states.route == $state.current.name; });
        // get the requested layer information from the config by alias
        var layer = _.find(stateConfig.tools.map.layers, function (l) { return l.alias == alias });
        // get the marker options from the layer
        var markerOptions = layer.marker;
        // get the boundary point files for this layer from global 
        var boundaryLayers = pmt.boundaryPoints[layer.boundaryPoints];
        // get the current state
        var state = stateService.getState();
        // check to see if this is a new pmt layer for the map, not just a redraw
        // then broadcast the update after the layer is on the map
        var broadcast = false;
        if (stateService.paramChanged('layers')) {
            broadcast = true;
        }
        // get the boundary points layer according the the current zoom level
        for (var x = 0; x < boundaryLayers.length; x++) {
            // find the first layer that satisfies the current zoom
            if (parseInt(state.zoom) <= boundaryLayers[x].zoomMax &&
                parseInt(state.zoom) >= boundaryLayers[x].zoomMin) {
                // current boundary layer appropriate for the zoom level
                var boundaryLayer = boundaryLayers[x];
                $http.get(boundaryLayer.file, { cache: true })
                    .success(function (data) {
                        try {
                            // call the private function to get the location data
                            getLocationData(boundaryLayer.boundaryId, layer.dataGroupIds)
                                .then(function (locations) {
                                    // remove layer if it already exsists
                                    if (pmtMapService.layers[alias]) {
                                        // clear selections
                                        clearSelections();
                                        // remove layer if it already exists
                                        pmtMapService.removeLayer(alias);
                                    }
                                    pmtMapService.layers[alias] = {};
                                    pmtMapService.layers[alias].locations = locations;
                                    pmtMapService.layers[alias].filterApplied = true;
                                    // create an invisible marker
                                    var noMarker = {
                                        radius: 0,
                                        fillColor: null,
                                        outlineColor: null,
                                        weight: 0,
                                        opacity: 0,
                                        fillOpacity: 0
                                    };
                                    $rootScope.currentAlias = alias;
                                    // data summarized by point feature
                                    pmtMapService.layers[alias] = L.geoJson(data, {
                                        boundaryLayer: boundaryLayer,
                                        pointToLayer: function (feature, latlng) {
                                            return L.circleMarker(latlng, noMarker);
                                        },
                                        // onEachFeature: onEachLayerPoint,
                                        data: {
                                            locations: locations,
                                            layer: layer
                                        },
                                        alias: alias
                                    });
                                    if (broadcast) {
                                        getActivityCount();
                                        // broadcast a pmt layer has been updated only if its
                                        // been added to the map, not a redraw for a new boundary/scale
                                        $rootScope.$broadcast('pmt-layers-update');
                                        clearHighlights();
                                    }

                                    // broadcast that the boundary needs to be updated
                                    $rootScope.$broadcast('boundary-update-required', { boundaryLayer: boundaryLayer, boundaryLayers: boundaryLayers });
                                    deferred.resolve(pmtMapService.layers[alias]);
                                });
                        }
                        catch (ex) {
                            deferred.rejected();
                        }
                    })
                    .error(function (data, status, headers, config, statusText) {
                        // there was an error report it to the error handler
                        //ErrorReporter.sendErrorReport(1, 'GetConfig.js', 'service', status, statusText);
                        deferred.reject(status);
                    });
            }
        }

        return deferred.promise;
    };

    // creates and returns clustered pmt layers by aliases
    pmtMapService.getLayers = function (aliases) {
        // create promise
        var deferred = $q.defer();
        // if there are layer aliases get layers
        if (aliases) {
            // get the current state's config
            var stateConfig = _.find(config.states, function (states) { return states.route == $state.current.name; });
            // collect all the data group ids from aliases
            var dataGroupIds = [];
            _.each(stateConfig.tools.map.layers, function (layer) {
                if (_.contains(aliases, layer.alias)) {
                    dataGroupIds = dataGroupIds.concat(layer.dataGroupIds.split(','));
                }
            });
            var layer = _.find(stateConfig.tools.map.layers, function (l) { return l.alias == aliases[0] });
            // get the marker options from the layer
            var markerOptions = layer.marker;
            // get the boundary point files for this layer from global 
            var boundaryLayers = pmt.boundaryPoints[layer.boundaryPoints];
            // get the current state
            var state = stateService.getState();
            // check to see if this is a new pmt layer for the map, not just a redraw
            // then broadcast the update after the layer is on the map
            var broadcast = false;
            if (stateService.paramChanged('layers')) {
                broadcast = true;
            }
            // get the boundary points layer according the the current zoom level
            for (var x = 0; x < boundaryLayers.length; x++) {
                // find the first layer that satisfies the current zoom
                if (parseInt(state.zoom) <= boundaryLayers[x].zoomMax &&
                    parseInt(state.zoom) >= boundaryLayers[x].zoomMin) {
                    // current boundary layer appropriate for the zoom level
                    var boundaryLayer = boundaryLayers[x];
                    $http.get(boundaryLayer.file, { cache: true })
                        .success(function (data) {
                            try {
                                // call the private function to get the location data
                                getLocationData(boundaryLayer.boundaryId, dataGroupIds.join(','))
                                    .then(function (locations) {
                                        // remove layer if it already exsists
                                        if (pmtMapService.layers.pmtCluster) {
                                            // clear selections
                                            clearSelections();
                                            // remove layer if it already exists
                                            pmtMapService.removeLayer("pmtCluster");
                                        }
                                        pmtMapService.layers.pmtCluster = {
                                            filterApplied: true,
                                            boundaryLayer: boundaryLayer,
                                            locations: locations,
                                            alias: "pmtCluster",
                                            aliases: aliases,
                                            dataGroupIds: dataGroupIds
                                        };
                                        // create an invisible marker
                                        var noMarker = {
                                            radius: 0,
                                            fillColor: null,
                                            outlineColor: null,
                                            weight: 0,
                                            opacity: 0,
                                            fillOpacity: 0
                                        };
                                        $rootScope.currentAlias = "pmtCluster";
                                        // data summarized by point feature
                                        pmtMapService.layers.pmtCluster = L.geoJson(data, {
                                            boundaryLayer: boundaryLayer,
                                            pointToLayer: function (feature, latlng) {
                                                return L.circleMarker(latlng, noMarker);
                                            },
                                            onEachFeature: onEachLocationPoint,
                                            data: {
                                                locations: locations
                                            },
                                            alias: "pmtCluster",
                                            aliases: aliases,
                                            dataGroupIds: dataGroupIds
                                        });
                                        if (broadcast) {
                                            getActivityCount();
                                            // broadcast a pmt layer has been updated only if its
                                            // been added to the map, not a redraw for a new boundary/scale
                                            $rootScope.$broadcast('pmt-layers-update');
                                            clearHighlights();
                                        }

                                        // broadcast that the boundary needs to be updated
                                        $rootScope.$broadcast('boundary-update-required', { boundaryLayer: boundaryLayer, boundaryLayers: boundaryLayers });
                                        deferred.resolve(pmtMapService.layers.pmtCluster);
                                    });
                            }
                            catch (ex) {
                                deferred.rejected();
                            }
                        })
                        .error(function (data, status, headers, config, statusText) {
                            // there was an error report it to the error handler
                            //ErrorReporter.sendErrorReport(1, 'GetConfig.js', 'service', status, statusText);
                            deferred.reject(status);
                        });
                }
            }
        }
        else {
            deferred.resolve(null);
        }
        return deferred.promise;
    };

    // removes a layers markers
    pmtMapService.removeLayer = function (alias) {
        if (typeof pmtMapService.layersPlusClass !== 'undefined' && labelClass !== null) {
            var labelClass = pmtMapService.layersPlusClass[alias];
            if (typeof labelClass !== 'undefined' && labelClass !== null) {
                delete pmtMapService.layersPlusClass[alias];
            }
        }

        // each layer's markers use a class named after the alias
        $('.leaflet-marker-icon.' + alias).remove();
        if (stateService.paramChanged('layers')) {
            getActivityCount();
            // broadcast a pmt layer has been updated only if its
            // been added to the map, not a redraw for a new boundary/scale
            $rootScope.$broadcast('pmt-layers-update');
        }
    };

    // determines if layer requires redraw
    pmtMapService.redraw = function (alias, currentLayer) {
        var redraw = false;
        // if the filter has not been applied then redraw
        if (pmtMapService.layers[alias].filterApplied === false) {
            redraw = true;
        }
        // otherwise determine if the layer needs redrawing due to zoom change
        else {
            // get the current state's config
            var stateConfig = _.find(config.states, function (states) { return states.route == $state.current.name; });
            // get the requested layer information from the config by alias
            var layer = _.find(stateConfig.tools.map.layers, function (l) { return l.alias == alias });
            // get the boundary point files for this layer from pmt 
            var boundaryLayers = pmt.boundaryPoints[layer.boundaryPoints];
            // get the boundary points layer according the the current zoom level
            for (var x = 0; x < boundaryLayers.length; x++) {
                // find the first layer that satisfies the current zoom
                if (parseInt($stateParams.zoom) <= boundaryLayers[x].zoomMax &&
                    parseInt($stateParams.zoom) >= boundaryLayers[x].zoomMin) {
                    // current boundary layer appropriate for the zoom level
                    var boundaryLayer = boundaryLayers[x];
                    if (boundaryLayer.alias !== currentLayer.alias) {
                        redraw = true;
                    }
                }
            }
        }
        return redraw;
    };

    // get an array of data group ids for layers currently on the map
    pmtMapService.getDataGroupIds = function () {
        var dataGroupIds = [];
        var aliases = _.keys(pmtMapService.layers);
        // get the current state's config
        var stateConfig = _.find(config.states, function (states) { return states.route == $state.current.name; });
        // get the layers present in url (on the map)
        var layers = [];
        if ($stateParams.layers !== '') {
            layers = $stateParams.layers.split(',');
        }
        _.each(aliases, function (alias) {
            // if the pmt map layer is on return the data group ids for it
            if (_.contains(layers, alias)) {
                // get the requested layer information from the config by alias
                var layer = _.find(stateConfig.tools.map.layers, function (l) { return l.alias == alias });
                dataGroupIds = dataGroupIds.concat(layer.dataGroupIds.split(','));
            }
        });
        return dataGroupIds;
    };

    // gets and returns activity details
    pmtMapService.getDetail = function (activity_id) {
        var deferred = $q.defer();
        var options = {
            id: activity_id,
            pmtId: pmt.id[pmt.env]
        };
        var header = {
            headers: { Authorization: 'Bearer ' + $rootScope.currentUser.token }
        };
        // call the api to get the pmt data by boundary points
        $http.post(pmt.api[pmt.env] + 'pmt_activity', options, header)
            .success(function (data, status, headers, config) {
                deferred.resolve(data);
                // console.log('pmt_activity:',data);
            })
            .error(function (data, status, headers, c) {
                // there was an error report it to the error handler
                console.log("error on api call to: pmt_activity");
                deferred.reject(status);
            });
        return deferred.promise;
    };

    // gets and returns location details
    pmtMapService.getLocations = function (location_ids) {
        var deferred = $q.defer();
        var options = {
            location_ids: location_ids,
            pmtId: pmt.id[pmt.env]
        };
        var header = {
            headers: { Authorization: 'Bearer ' + $rootScope.currentUser.token }
        };
        // call the api to get the pmt data by boundary points
        $http.post(pmt.api[pmt.env] + 'pmt_locations', options, header)
            .success(function (data, status, headers, config) {
                deferred.resolve(data);
            })
            .error(function (data, status, headers, c) {
                // there was an error report it to the error handler
                console.log("error on api call to: pmt_locations");
                deferred.reject(status);
            });
        return deferred.promise;
    };

    // gets and returns total number of activities on map
    pmtMapService.getActivityCount = function () {
        return pmtMapService.activityCount;
    };

    // gets and returns list of organizations in use
    pmtMapService.getOrgsInUse = function (org_role_ids, type) {
        var deferred = $q.defer();
        var dataGroupIds = pmtMapService.getDataGroupIds();
        var options = {
            data_group_ids: dataGroupIds.join(','),
            org_role_ids: org_role_ids,
            pmtId: pmt.id[pmt.env]
        };
        var header = {
            headers: { Authorization: 'Bearer ' + $rootScope.currentUser.token }
        };
        // call the api to get the organizations
        $http.post(pmt.api[pmt.env] + 'pmt_org_inuse', options, header, { cache: true }).success(function (data, status, headers, config) {
            // remove unneccessary response object from api
            var orgs = _.pluck(data, 'response');
            // add the active parameter to our object
            _.each(orgs, function (o) {
                _.extend(o, { active: false });
                o.n = o.n.replace(/\r?\n|\r/g, '');
            });
            // clear and refill the orgs
            pmtMapService.orgsInUse[type] = [];
            pmtMapService.orgsInUse[type] = orgs;
            // return the orgs
            deferred.resolve(orgs);
        }).error(function (data, status, headers, c) {
            // there was an error report it to the error handler
            console.log("error on api call to: pmt_org_inuse");
            deferred.reject(status);
        });
        return deferred.promise;
    };

    // gets and returns list of all active organizations
    pmtMapService.getOrgs = function () {
        var deferred = $q.defer();
        var options = {
            pmtId: pmt.id[pmt.env]
        };
        var header = {
            headers: { Authorization: 'Bearer ' + $rootScope.currentUser.token }
        };
        // return the cached organizations, if available
        if (pmtMapService.allOrgs.length > 0) {
            deferred.resolve(pmtMapService.allOrgs);
        }
        // call the api to get the organizations, if cache is empty
        else {
            $http.post(pmt.api[pmt.env] + 'pmt_orgs', options, header, { cache: true })
                .success(function (data, status, headers, config) {
                    // remove unneccessary response object from api
                    var orgs = _.pluck(data, 'response');
                    // cache the data in the service
                    pmtMapService.allOrgs = orgs;
                    // return the orgs
                    deferred.resolve(orgs);
                })
                .error(function (data, status, headers, c) {
                    // there was an error report it to the error handler
                    console.log("error on api call to: pmt_org_inuse");
                    deferred.reject(status);
                });
        }
        return deferred.promise;
    };

    // gets and returns list of classifications for a taxonomy
    pmtMapService.getTaxonomy = function (taxonomy_id, inuse) {
        var deferred = $q.defer();
        var data_group_ids = null;
        if (inuse) {
            var dataGroupIds = pmtMapService.getDataGroupIds();
            data_group_ids = dataGroupIds.join(',');
        }
        var options = {
            taxonomy_id: taxonomy_id, // taxonomy id
            data_group_ids: data_group_ids, // return in-use classifications for data groups listed, otherwise all classifications
            locations_only: true, // return in-use classifications for activities with locations only
            pmtId: pmt.id[pmt.env]
        };
        var header = {
            headers: { Authorization: 'Bearer ' + $rootScope.currentUser.token }
        };
        // call the api to get the classifications for a given taxonomy
        $http.post(pmt.api[pmt.env] + 'pmt_classifications', options, header, { cache: true }).success(function (data, status, headers, config) {
            var classifications = [];
            // add the active parameter to our object
            _.each(data, function (o) {
                var classification = o.response;
                _.extend(classification, { active: false });
                classifications.push(classification);
            });
            // remove taxonomy from the service
            pmtMapService.taxonomies = _.reject(pmtMapService.taxonomies, function (t) { return t.taxonomy_id === taxonomy_id; });
            // add updated taxonomy to the service
            var t = {
                taxonomy_id: taxonomy_id,
                classification_ids: classifications
            };
            pmtMapService.taxonomies.push(t);
            deferred.resolve(classifications);
        }).error(function (data, status, headers, c) {
            // there was an error report it to the error handler
            console.log("error on api call to: pmt_classifications");
            deferred.reject(status);
        });
        return deferred.promise;
    };

    // sets the classification ids filter
    pmtMapService.setClassificationFilter = function (taxonomy_id, ids) {
        // get the taxonomy filter if it already exists
        var taxClassifications = _.find(filter.classification_ids, function (c) { return c.taxonomy_id === taxonomy_id });
        // update the classification ids for the taxonomy filter
        if (taxClassifications) {
            if (taxClassifications.classification_ids != ids) {
                taxClassifications.classification_ids = ids;
            }
        }
        // taxonomy filter doesn't exists to create it
        else {
            var obj = {
                taxonomy_id: taxonomy_id,
                classification_ids: ids
            };
            filter.classification_ids.push(obj);
        }
        // the filter has been updated
        filterUpdated();
    };

    // sets the implementing org ids filter
    pmtMapService.setImpOrgFilter = function (ids) {
        if (ids != filter.imp_org_ids) {
            filter.imp_org_ids = ids;
            // the filter has been updated
            filterUpdated();
        }
    };

    // sets the funding org ids filter
    pmtMapService.setFundOrgFilter = function (ids) {
        if (ids != filter.fund_org_ids) {
            filter.fund_org_ids = ids;
            // the filter has been updated
            filterUpdated();
        }
    };

    // sets the org ids filter 
    pmtMapService.setOrgFilter = function (ids) {
        if (ids != filter.org_ids) {
            filter.org_ids = ids;
            // the filter has been updated
            filterUpdated();
        }
    };

    // sets the start date filter
    pmtMapService.setStartDateFilter = function (date) {
        if (date != filter.start_date) {
            filter.start_date = date;
            // the filter has been updated
            filterUpdated();
        }
    };

    // sets the end date filter
    pmtMapService.setEndDateFilter = function (date) {
        if (date != filter.end_date) {
            filter.end_date = date;
            // the filter has been updated
            filterUpdated();
        }
    };

    // sets the start & end date filters
    // use when setting both start and end date in a single transaction
    pmtMapService.setDateFilters = function (startDate, endDate) {
        if (startDate != filter.start_date || endDate != filter.end_date) {
            filter.start_date = startDate;
            filter.end_date = endDate;
            // the filter has been updated
            filterUpdated();
        }
    };

    // sets the unassigned taxonomy ids filter
    pmtMapService.setUnassignedTaxonomyFilter = function (id) {
        if (!_.contains(filter.unassigned_taxonomy_ids, id)) {
            filter.unassigned_taxonomy_ids.push(id);
            // the filter has been updated
            filterUpdated();
        }
    };

    // sets the boundary filter
    pmtMapService.setBoundaryFilter = function (boundary_object) {
        filter.boundary_filter = boundary_object;
        // the filter has been updated
        filterUpdated();
    };

    // set the keyword filter
    pmtMapService.setKeywordFilter = function (keyword) {
        // check if keyword has changed
        if (keyword != filter.keyword_filter.keyword) {
            filter.keyword_filter.keyword = keyword;
            // call the api to get a list of activities ids matching the keyword
            pmtMapService.globalSearchText(keyword).then(function (data) {
                // update filter activity_ids list
                if (data[0].response.ids) { filter.keyword_filter.activity_ids = data[0].response.ids; }
                else { filter.keyword_filter.activity_ids = ['test']; }
                // the filter has been updated
                filterUpdated();
            });
        }
    }

    // remove a classification id from filter
    pmtMapService.removeClassificationFilter = function (id) {
        if (id) {
            // loop through each taxonomy filter
            _.each(filter.classification_ids, function (taxonomy_filter) {
                taxonomy_filter.classification_ids = _.without(taxonomy_filter.classification_ids, id);
                //if this was a parent class, also remove all children
                var parent = _.chain(pmtMapService.taxonomies).pluck("classification_ids").flatten().compact().find({id: id}).value();
                if(parent && parent.children){
                    taxonomy_filter.classification_ids = _.difference(taxonomy_filter.classification_ids, _(parent.children).pluck("id"));
                }
            });
            // the filter has been updated
            filterUpdated();
        }
    };

    // remove a implmenting org id from filter
    pmtMapService.removeImpOrgFilter = function (id) {
        if (id) {
            filter.imp_org_ids = _.without(filter.imp_org_ids, id);
            // the filter has been updated
            filterUpdated();
        }
    };

    // remove a funding org id from filter
    pmtMapService.removeFundOrgFilter = function (id) {
        if (id) {
            filter.fund_org_ids = _.without(filter.fund_org_ids, id);
            // the filter has been updated
            filterUpdated();
        }
    };

    // remove a org id from filter
    pmtMapService.removeOrgFilter = function (id) {
        if (id) {
            filter.org_ids = _.without(filter.org_ids, id);
            // the filter has been updated
            filterUpdated();
        }
    };

    // remove the start date from filter
    pmtMapService.removeStartDateFilter = function () {
        filter.start_date = null;
        // the filter has been updated
        filterUpdated();
    };

    // remove the end date from filter
    pmtMapService.removeEndDateFilter = function () {
        filter.end_date = null;
        // the filter has been updated
        filterUpdated();
    };

    // remove a taxonomy id from filter
    pmtMapService.removeUnassignedTaxonomyFilter = function (id) {
        if (id) {
            filter.unassigned_taxonomy_ids = _.without(filter.unassigned_taxonomy_ids, id);
            // the filter has been updated
            filterUpdated();
        }
    };

    // remove the boundary filter
    pmtMapService.removeBoundaryFilter = function () {
        filter.boundary_filter = null;
        // the filter has been updated
        filterUpdated();
    };

    // remove keyword filter
    pmtMapService.removeKeywordFilter = function () {
        filter.keyword_filter.keyword = null;
        filter.keyword_filter.activity_ids = [];
        // the filter has been updated
        filterUpdated();
    };

    // clear all filters
    pmtMapService.clearFilters = function () {
        // clear all filters
        filter.classification_ids = [];
        filter.imp_org_ids = [];
        filter.fund_org_ids = [];
        filter.org_ids = [];
        filter.start_date = null;
        filter.end_date = null;
        filter.unassigned_taxonomy_ids = [];
        filter.boundary_filter = null;
        filter.keyword_filter.keyword = null;
        filter.keyword_filter.activity_ids = [];
        // the filter has been updated
        filterUpdated();
    };

    // t/f there are applied filters
    pmtMapService.hasFilters = function () {
        if (filter.imp_org_ids.length > 0 || filter.fund_org_ids.length > 0 || filter.org_ids.length > 0
            || filter.unassigned_taxonomy_ids.length > 0 || filter.keyword_filter.activity_ids.length > 0) {
            return true;
        }
        else if (filter.classification_ids.length > 0) {
            var found = false;
            _.each(filter.classification_ids, function (c) {
                if (c.classification_ids.length > 0) {
                    found = true;
                }
            });
            return found;
        }
        else if (filter.start_date != null || filter.end_date != null || filter.boundary_filter != null) {
            return true;
        }
        else {
            return false;
        }
    };

    // gets the selected filters and creates a model
    // example returned filter object:
    // f = [{id: 342, label: "Yams", type: "c"},{id: 13, label: "BMGF", type: "fund"}]
    pmtMapService.getSelectedFilters = function () {
        var filters = [];
        // get a comma seperated list of selected classification ids
        var idList = getClassificationIds();
        if (idList) {
            var ids = idList.split(',');
            if (ids.length > 0) {
                // loop through the selected classification ids
                _.each(ids, function (id) {
                    // look up the classification
                    _.each(pmtMapService.taxonomies, function (t) {
                        var cls = _.find(t.classification_ids, function (c) { return c.id == id; });
                        if (cls) {
                            // add the classification to the selected features
                            filters.push({ id: cls.id, label: cls.c, type: "c", children: [] });
                        }
                        //also check if tax has children
                        _(t.classification_ids).each(function (parent) {
                            //see if classification has children
                            var childCls = _(parent.children).find({ id: parseInt(id) });
                            if (childCls) {
                                //if parent is also selected then nest
                                if (ids.indexOf(parent.id.toString()) > -1) {
                                    var parentCls = _(filters).find({ id: parent.id });
                                    if (parentCls) {
                                        // add the classification to the selected feature
                                        parentCls.children.push({ id: childCls.id, label: childCls.c, type: "c" });
                                    }

                                } else {    //else list flat
                                    // add the classification to the selected feature
                                    filters.push({ id: childCls.id, label: childCls.c, type: "c" });
                                }
                            }
                        })
                    });
                });
            }
        }
        // loop through the selected implementing org ids
        _.each(filter.imp_org_ids, function (i) {
            // look up the organization 
            _.each(pmtMapService.orgsInUse['implementing'], function (imp_org) {
                if (imp_org.id === i) {
                    // add the organization to the selected features
                    filters.push({ id: imp_org.id, label: imp_org.n, type: "imp" });
                }
            });
        });
        // loop through the selected funding org ids
        _.each(filter.fund_org_ids, function (f) {
            // look up the organzation
            _.each(pmtMapService.orgsInUse['funding'], function (fund_org) {
                if (fund_org.id === f) {
                    filters.push({ id: fund_org.id, label: fund_org.n, type: "fund" });
                }
            });
        });
        // loop through the selected org ids
        _.each(filter.org_ids, function (o) {
            // look up the organzation
            _.each(pmtMapService.orgsInUse['all'], function (org) {
                if (org.id === o) {
                    filters.push({ id: org.id, label: org.n, type: "org" });
                }
            });
        });
        // loop through the selected unassigned taxonomy ids
        _.each(filter.unassigned_taxonomy_ids, function (id) {
            var tax = _.find(pmtMapService.taxonomies, function (t) { return t.taxonomy_id == id; });
            if (tax) {
                var stateConfig = _.find(config.states, function (states) { return states.route == $state.current.name; });
                // if this state has a tools.map.filters object continue
                if (stateConfig.tools.map.filters) {
                    var filter = _.find(stateConfig.tools.map.filters, function (filter) {
                        if (_.has(filter, 'params')) {
                            if (_.has(filter.params, 'taxonomy_id')) {
                                return filter.params.taxonomy_id == tax.taxonomy_id;
                            }
                        }
                    });
                    if (filter) {
                        // add the unassigned taxonomy filter to the selected features
                        filters.push({ id: tax.taxonomy_id, label: 'None/Unspecified ' + filter.label, type: "unassigned" });
                    }
                }
            }
        });
        // check if there is a keyword if
        if (filter.keyword_filter.keyword) {
            // add keyword to the selected features
            filters.push({ id: filter.keyword_filter.keyword, label: '"' + filter.keyword_filter.keyword + '"', type: "keyword" });
        }
        // determine if there is a boundary filter active
        if (filter.boundary_filter !== null) {
            // add the boundary to the selected features
            filters.push({ id: null, label: "Geographic Filter", type: "boundary" });
        }
        return filters;
    };

    // gets the classification filters
    pmtMapService.getClassificationFilters = function () {
        var cls = [];
        var list = getClassificationIds();
        if (list) {
            cls = list.split(',');
            for (c in cls) {
                cls[c] = parseInt(cls[c], 10);
            }
        }
        return cls;
    };

    // gets the implmenting org filters
    pmtMapService.getImpOrgFilters = function () { return filter.imp_org_ids; };

    // gets the funding org filters
    pmtMapService.getFundOrgFilters = function () { return filter.fund_org_ids; };

    // gets the org filters
    pmtMapService.getOrgFilters = function () { return filter.org_ids; };

    // gets the start date filter
    pmtMapService.getStartDateFilters = function () { return filter.start_date; };

    // gets the end date filter
    pmtMapService.getEndDateFilters = function () { return filter.end_date; };

    // gets the unassigned taxonomy filters
    pmtMapService.getUnassignedTaxonomyFilters = function () { return filter.unassigned_taxonomy_ids; };

    // gets the boundary filters
    pmtMapService.getBoundaryFilters = function () { return filter.boundary_filter; };

    // gets the keyword filter
    pmtMapService.getKeywordFilters = function () { return filter.keyword_filter; };

    //construct html legend snippet from the AGS legend json object
    pmtMapService.getAGSLegendJSON = function (option, that) {
        var deferred = $q.defer();
        var json;
        that.showLoading = true;
        var storageParam = option.alias + '_legend';
        var cachedLegend = localStorage.getItem(storageParam);
        // fetch the json from the map service
        $http.jsonp(option.legend + '&callback=JSON_CALLBACK', { cache: true })
            .success(function (data) {
                json = data;
                deferred.resolve(data);
            })
            .error(function (data, status, headers, config) {
                that.showLoading = false;
                that.showMessage = true;
                that.showLegend = false;
                that.showJsonLegend = false;
                deferred.reject();
            })
            .then(function () {
                try {
                    // the html legend
                    var html = '';
                    // the layers listed in the json object
                    var jsonLayers = _.pluck(json['layers'], 'layerId');
                    jsonLayers = $.map(jsonLayers, function (value) {
                        return value;
                    });

                    // check to see if all the layers are available in the json legend object
                    if (_.intersection(option.layers, jsonLayers).length == option.layers.length) {
                        // all the layers are available in the json
                        // build just the layers we are using
                        for (var i = 0; i < json['layers'].length; i++) {
                            if (_.contains(option.layers, json['layers'][i]['layerId'])) {
                                var layerName = json['layers'][i]['layerName'];
                                var legend = json['layers'][i]['legend'];
                                // html += '<div class="legend-layer">' + layerName + '</div>';
                                for (var u = 0; u < legend.length; u++) {
                                    html += '<img class="legend-json" src="data:' + legend[u]['contentType'] + ';base64,' + legend[u]['imageData'] + '" />' + legend[u]['label'] + '<br/>';
                                }
                            }
                        }
                    }
                    else {
                        // some or none of the layers are available in the json
                        // then just build the entire legend as provided
                        for (var x = 0; x < json['layers'].length; x++) {
                            var name = json['layers'][x]['layerName'];
                            var legends = json['layers'][x]['legend'];
                            html += '<div class="legend-layer">' + name + '</div>';
                            for (var y = 0; y < legends.length; y++) {
                                html += '<img class="legend-json" src="data:' + legends[y]['contentType'] + ';base64,' + legends[y]['imageData'] + '" /><span class="legend-label" >' + legends[y]['label'] + '</span><br/>';
                            }
                        }
                    }
                    // add the created legend to local storage for caching
                    localStorage.setItem(storageParam, html);
                    // load the html into the activeDetail object
                    option.legendHTML = $sce.trustAsHtml(html);
                    that.showLoading = false;
                }
                catch (ex) {
                    that.showLoading = false;
                    that.showMessage = true;
                    that.showLegend = false;
                    that.showJsonLegend = false;
                    // there was an error report it to the error handler
                }
            });

        return deferred.promise;
    };

    //construct html legend snippet from pmt json file
    pmtMapService.getPMTLegendJSON = function (option, that) {
        var deferred = $q.defer();

        var url = option.legend;

        //get legend data from amazon
        $http.get(url, { cache: true })
            .then(function (response) {

                //find the legend data that matches from the json based on name
                var lData = _.find(response.data, function (l) { return l.name == option.label });

                option.legendObject = lData;

                deferred.resolve();

            }, function (err) {
                deferred.reject(err);
            });

        return deferred.promise;
    };

    // service to do a global search
    // gets and returns activity details
    pmtMapService.globalSearchText = function (search_text, data_group_ids) {
        var deferred = $q.defer();
        var dataGroupIds = pmtMapService.getDataGroupIds();
        var options = {
            search_text: search_text, // text value to search activity information for (will search all text fields in activity table)
            data_group_ids: data_group_ids || dataGroupIds.join(','), // comma delimited list of data group ids to restrict search to
            pmtId: pmt.id[pmt.env]
        };
        var header = {
            headers: { Authorization: 'Bearer ' + $rootScope.currentUser.token }
        };
        // call the api to get the pmt data by boundary points
        $http.post(pmt.api[pmt.env] + 'pmt_global_search', options, header)
            .success(function (data, status, headers, config) {
                deferred.resolve(data);
                //console.log('pmt_activity:',data);
            })
            .error(function (data, status, headers, c) {
                // there was an error report it to the error handler
                console.log("error on api call to: pmt_global_search");
                deferred.reject(status);
            });
        return deferred.promise;
    };

    // service to get a list of activities for autocomplete
    // gets and returns activity details
    pmtMapService.autoComplete = function (filter_fields) {
        var deferred = $q.defer();

        var url = pmt.autocompleteText.file;

        $http.get(url, { cache: true })
            .then(function (response) {

                if (response.data && response.data.error) {
                    deferred.reject(response.data.error);
                }

                deferred.resolve(response.data);

            }, function (err) {
                deferred.reject(err);
            });
        return deferred.promise;
    };

    // geocoder service
    pmtMapService.geocode = function (locationName) {
        var deferred = $q.defer();
        // get the current state's config
        var stateConfig = _.find(config.states, function (states) { return states.route == $state.current.name; });
        // if this state has tools
        if (typeof stateConfig.tools != "undefined") {
            // if this states tools have a geocoder key
            if (typeof stateConfig.tools.geocoderKey != "undefined") {
                // get the key from the config
                var key = stateConfig.tools.geocoderKey.key;
                // set up the url
                var url = 'https://api.opencagedata.com/geocode/v1/geojson?q=' + locationName + '&key=' + key + '&pretty=1';
                $http.get(url, { cache: true }).then(function (response) {
                    if (response.data && response.data.error) {
                        deferred.reject(response.data.error);
                    }
                    deferred.resolve(response.data);

                }, function (err) {
                    deferred.reject(err);
                });
            }
            else { deferred.reject('configuration does not contain a geocoder key.'); }
        }
        else { deferred.reject('configuration does not contain any tools.'); }

        return deferred.promise;
    }

    // run pmt_export function and download results
    pmtMapService.export = function () {
        var deferred = $q.defer();
        var exports = getDataGroupExportFunctions();
        var completedDownloads = 0;
        var chromeThreshold = 2500; // max number of rows chrome will download

        var header = {
            headers: { Authorization: 'Bearer ' + $rootScope.currentUser.token }
        };

        // loop through each fucntion in dictionary, fetch & download
        _.each(_.keys(exports), function (e, i) {
            var options = {
                data_group_ids: exports[e].dataGroupIds,
                classification_ids: getClassificationIds(),
                imp_org_ids: filter.imp_org_ids.join(","),
                fund_org_ids: filter.fund_org_ids.join(","),
                unassigned_taxonomy_ids: filter.unassigned_taxonomy_ids.join(""),
                start_date: filter.start_date,
                end_date: filter.end_date,
                pmtId: pmt.id[pmt.env],
                export: e // export function name
            };

            // call the api to get the activity id for this boundary feature
            $http.post(pmt.api[pmt.env] + 'pmt_export', options, header)
                .success(function (data, status, headers, config) {
                    // get header rows
                    var header = data.splice(0, 3); // file header
                    var numFiles = Math.ceil(data.length / chromeThreshold);

                    // split files > chromeThreshold
                    for (var i = 0; i <= numFiles - 1; i++) {
                        var splicedData = data.splice(0, chromeThreshold);
                        var fileName = (numFiles > 1) ? e + '_' + i : e;
                        // download csv
                        partnerLinkService.JSONToCSVConvertor(header.concat(splicedData), fileName, false, function () {
                            if (numFiles > 0) {
                                // all split files are complete, so increment completed downloads
                                if (i == numFiles - 1) {
                                    completedDownloads += 1;
                                }
                            } else {
                                // no need to split, so increment
                                completedDownloads += 1;
                            }

                            // all files are complete
                            if (completedDownloads == _.keys(exports).length) {
                                deferred.resolve(data);
                            }
                        });
                    }
                })
                .error(function (data, status, headers, c) {
                    // there was an error report it to the error handler
                    console.log("error on api call to: pmt_export");
                    deferred.reject(data);
                });
        });

        return deferred.promise;
    };

    // get activities in wkt polygon
    pmtMapService.getActivitiesByPoly = function (wkt) {
        var deferred = $q.defer();
        var dataGroupIds = pmtMapService.getDataGroupIds();
        var options = {
            wkt: wkt,
            data_group_ids: dataGroupIds.join(','),
            classification_ids: getClassificationIds(),
            org_ids: filter.org_ids.join(),
            imp_org_ids: filter.imp_org_ids.join(','),
            fund_org_ids: filter.fund_org_ids.join(','),
            start_date: filter.start_date,
            end_date: filter.end_date,
            unassigned_taxonomy_ids: filter.unassigned_taxonomy_ids.join(','),
            activity_ids: filter.keyword_filter.activity_ids.join(),
            boundary_filter: filter.boundary_filter,
            pmtId: pmt.id[pmt.env]
        };

        // if no data groups selected, return 0
        if (dataGroupIds.length === 0) {
            var result = [];
            result[0] = {};
            result[0].response = {};
            result[0].response.activity_ids = null;
            deferred.resolve(result);
        }

        var header = {
            headers: { Authorization: 'Bearer ' + $rootScope.currentUser.token }
        };

        $http.post(pmt.api[pmt.env] + 'pmt_activities_by_polygon', options, header, { cache: true }).success(function (result) {
            deferred.resolve(result);
        }).error(function (result) {
            deferred.reject(result);
        });
        return deferred.promise;
    };

    // get activity count by classifications in a given taxonomy
    pmtMapService.getActivityCountByTax = function (taxonomy_id, activity_ids) {
        var deferred = $q.defer();
        var options = {
            taxonomy_id: taxonomy_id,
            activity_ids: activity_ids,
            pmtId: pmt.id[pmt.env]
        };
        var header = {
            headers: { Authorization: 'Bearer ' + $rootScope.currentUser.token }
        };

        $http.post(pmt.api[pmt.env] + 'pmt_activity_count_by_taxonomy', options, header, { cache: true })
            .success(function (result) {

                deferred.resolve(result);
            })
            .error(function (result) {
                deferred.reject(result);
            });
        return deferred.promise;
    };

    // get activity count by participating organization
    pmtMapService.getActivityCountByOrg = function (classification_id, activity_ids) {
        var deferred = $q.defer();
        var options = {
            classification_id: classification_id,
            activity_ids: activity_ids,
            pmtId: pmt.id[pmt.env]
        };
        var header = {
            headers: { Authorization: 'Bearer ' + $rootScope.currentUser.token }
        };

        $http.post(pmt.api[pmt.env] + 'pmt_activity_count_by_participants', options, header, { cache: true })
            .success(function (result) {

                deferred.resolve(result);
            })
            .error(function (result) {
                deferred.reject(result);
            });
        return deferred.promise;
    };

    // get admin boundaries for a given point
    pmtMapService.getBoundariesByPoint = function (wktPoint) {
        var deferred = $q.defer();
        var options = {
            wktPoint: wktPoint,
            pmtId: pmt.id[pmt.env]
        };
        var header = {
            headers: { Authorization: 'Bearer ' + $rootScope.currentUser.token }
        };

        $http.post(pmt.api[pmt.env] + 'pmt_boundaries_by_point', options, header, { cache: true })
            .success(function (result) {

                deferred.resolve(result);
            })
            .error(function (result) {

                deferred.reject(result);
            });
        return deferred.promise;
    };

    // toggle clusters on the map
    pmtMapService.togglePointClusters = function (removeClusters) {
        // remove the clusters
        if (removeClusters) {
            // find all data groups on the map
            var dataGroupLayers = Object.keys(pmtMapService.layers);
            // remove pmtCluster
            dataGroupLayers = _.filter(dataGroupLayers, function (layer) { return layer !== 'pmtCluster'; });
            // grab all layers in state params
            var stateParamLayers = $stateParams.layers.split(',');
            // remove data group from state params
            var newLayers = _.difference(stateParamLayers, dataGroupLayers);;
            _.each(dataGroupLayers, function (l) {
                // remove boundaryLayer if exists
                if (pmtMapService.layers[l].options.boundaryLayer) {
                    newLayers = _.without(newLayers, pmtMapService.layers[l].options.boundaryLayer.boundary.alias);
                    // remove select layer
                    newLayers = _.without(newLayers, pmtMapService.layers[l].options.boundaryLayer.select.alias);
                }
            });
            $stateParams.layers = newLayers.join(',');
            // update the state
            stateService.setState('map', $stateParams, false);
        }
        else {
            // find all data groups on the map
            var dataGroupLayers = Object.keys(pmtMapService.layers);
            // remove pmtCluster
            dataGroupLayers = _.filter(dataGroupLayers, function (layer) { return layer !== 'pmtCluster'; });
            // grab all layers in state params
            var stateParamLayers = $stateParams.layers !== '' ? $stateParams.layers.split(',') : null;
            // add data group from state params
            var unionLayers = _.union(dataGroupLayers, stateParamLayers);
            // update the state params
            $stateParams.layers = unionLayers.join(',');
            // update the state
            stateService.setState('map', $stateParams, false);
        }
    };

    // private function to call pmt api
    // api calls pmt_locations_for_boundaries function 
    function getLocationData(boundary_id, data_group_ids) {
        var deferred = $q.defer();
        var dataGroupIds = pmtMapService.getDataGroupIds();
        var options = {
            boundary_id: boundary_id,
            data_group_ids: data_group_ids,
            classification_ids: getClassificationIds(),
            org_ids: filter.org_ids.join(),
            imp_org_ids: filter.imp_org_ids.join(),
            fund_org_ids: filter.fund_org_ids.join(),
            start_date: filter.start_date,
            end_date: filter.end_date,
            unassigned_taxonomy_ids: filter.unassigned_taxonomy_ids.join(),
            activity_ids: filter.keyword_filter.activity_ids.join(),
            boundary_filter: filter.boundary_filter,
            pmtId: pmt.id[pmt.env]
        };
        var header = {
            headers: { Authorization: 'Bearer ' + $rootScope.currentUser.token }
        };
        // call the api to get the pmt data by boundary points
        $http.post(pmt.api[pmt.env] + 'pmt_locations_for_boundaries', options, header)
            .success(function (data, status, headers, config) {
                // console.log('pmt_locations_for_boundaries: ', data);
                deferred.resolve(data);
            })
            .error(function (data, status, headers, c) {
                // there was an error report it to the error handler
                // console.log("error on api call to: locations_by_data_group");
                deferred.reject(status);
            });
        return deferred.promise;
    }

    // private function to call on each point location feature
    // function processes each point for use in the map
    function onEachLocationPoint(feature, layer) {
        // get the point feature if there is data for it
        var pointFeature = _.find(pmtMapService.layers[$rootScope.currentAlias].locations,
            function (item) {
                return item.response.id == feature.properties.id;
            });

        // each point should have its alias as a class (map-theme.less)
        // this provides the color for the marker
        var classes = 'pmtMarker ' + $rootScope.currentAlias;
        // check what boundary layer is on the map and add that as a class
        if (pmtMapService.layers[$rootScope.currentAlias].boundaryLayer.boundary) {
            var boundaryClass = pmtMapService.layers[$rootScope.currentAlias].boundaryLayer.boundary.alias;
            // add boundaryclass to class list
            classes = classes + ' ' + boundaryClass;
        }
        if (pmtMapService.layers[$rootScope.currentAlias].locations.length > 0) {
            // determine which plus class to use (i.e. plus0, plus1, ..., plus5)
            // this allows clustering of centroids on boundaries
            var plusClass = '';
            // if the layer has not been assigned a plus class, then get the next available
            if (typeof pmtMapService.layersPlusClass[$rootScope.currentAlias] === 'undefined') {
                // loop through the available plusClasses starting with 0,
                // to ensure we always place points according to priority of order
                for (var i = 0; i < pmtMapService.plusClasses.length; i++) {
                    var classInUse = false;
                    // see if this class is in use
                    var found = _.find(pmtMapService.layersPlusClass, function (c) { return c === pmtMapService.plusClasses[i] });
                    if (found) { classInUse = true; }

                    // assign class if it is not in use
                    if (!classInUse) {
                        pmtMapService.layersPlusClass[$rootScope.currentAlias] = pmtMapService.plusClasses[i];
                        plusClass = pmtMapService.plusClasses[i];
                        break;
                    }
                }
            }
            // otherwise use the pre-assigned class
            else {
                plusClass = pmtMapService.layersPlusClass[$rootScope.currentAlias];
            }

            // add the alias to the plusClass
            classes += ' ' + plusClass;
        }
        // if this feature has data give it a marker
        if (pointFeature) {
            var popup = '';
            var label = L.marker(layer._latlng, {
                icon: L.divIcon({
                    className: classes, // assign the classes
                    //html: pmtMapService.pmtLayer.p // p = parent activity count, a = activity count, l = location count
                    html: pointFeature.response.p // p = parent activity count, a = activity count, l = location count
                }),
                locations: pointFeature,
                alias: $rootScope.currentAlias,
                layer: pmtMapService.layers[$rootScope.currentAlias]
            }).addTo(pmtMapService.map)
                .bindPopup(popup);
            //bind click
            label.on({
                click: onClickLocationPoint,
                mouseover: onMouseoverLocationPoint,
                mouseout: onMouseoutLocationPoint
            });
        }
    }

    // private function to call pmt api
    // on click api calls pmt_activity_ids_by_boundary to get
    // all the activity ids for a clicked point
    function onClickLocationPoint(e, force) {

        if (!force && ($stateParams['travel-panel'] == 'open' || $stateParams['target-analysis-panel'] == 'open')) {
            confirmSwitchToActivityPanel(e);
            return;
        }
        else {
            var deferred = $q.defer();
            // broadcast that a feature details are loading
            $rootScope.$broadcast('pmt-feature-details-loading');
            // get the location information from the clicked label
            var location = e.target.options.locations.response;
            // highlight the boundary feature in which the point is within
            highlightBoundary(location.id, location.b);
            // clear all selections
            clearSelections();
            // set highlight
            e.target._icon.className = e.target._icon.className + ' pmt-selected';
            // get the current state's config
            var stateConfig = _.find(config.states, function (states) { return states.route == $state.current.name; });
            var options = {
                boundary_id: location.b,
                feature_id: location.id,
                data_group_ids: e.target.options.layer.dataGroupIds.join(),
                classification_ids: getClassificationIds(),
                org_ids: filter.org_ids.join(),
                imp_org_ids: filter.imp_org_ids.join(),
                fund_org_ids: filter.fund_org_ids.join(),
                start_date: filter.start_date,
                end_date: filter.end_date,
                unassigned_taxonomy_ids: filter.unassigned_taxonomy_ids.join(),
                activity_ids: filter.keyword_filter.activity_ids.join(),
                boundary_filter: filter.boundary_filter,
                pmtId: pmt.id[pmt.env]
            };
            var header = {
                headers: { Authorization: 'Bearer ' + $rootScope.currentUser.token }
            };
            // call the api to get the activity id for this boundary feature
            $http.post(pmt.api[pmt.env] + 'pmt_activity_ids_by_boundary', options, header).success(function (data, status, headers, config) {
                // assign select detail ids
                pmtMapService.selectedDetails = _.pluck(data, 'response');
                // broadcast that a feature details are loaded
                $rootScope.$broadcast('pmt-feature-details-loaded');
                deferred.resolve(data);
            }).error(function (data, status, headers, c) {
                // there was an error report it to the error handler
                console.log("error on api call to: pmt_activity_ids_by_boundary");
                deferred.reject(status);
            });
            return deferred.promise;
        }
    }

    // private function to call pmt api
    // on mouse over a point cluster calls pmt_boundary_feature
    // to get boundary information to place in popup
    function onMouseoverLocationPoint(e, force) {
        if (e.target._popup._content == '') {
            // get the current state
            var state = stateService.getState();
            // get all the layers on the map
            var mapLayers = state.layers.split(',');
            // get the locations from point on mouseover
            var location = e.target.options.locations.response;
            // get all the aliases for all the pmt layers
            var layerAliases = Object.keys(pmtMapService.layers);
            // filter out all the boundary aliases
            var boundaryAliases = [];
            _.each(layerAliases, function (l) {
                if (pmtMapService.layers[l].options.boundaryLayer.alias) {
                    boundaryAliases.push(pmtMapService.layers[l].options.boundaryLayer.alias);
                }
            });
            var options = {
                boundary_id: location.b,
                feature_id: location.id,
                pmtId: pmt.id[pmt.env]
            };
            var header = {
                headers: { Authorization: 'Bearer ' + $rootScope.currentUser.token }
            };
            // call the api to get the activity id for this boundary feature
            $http.post(pmt.api[pmt.env] + 'pmt_boundary_feature', options, header).success(function (data, status, headers) {
                var feature = _.pluck(data, 'response')[0];
                var popup = '';
                if (_.has(feature, '0_name')) {
                    popup += '<strong>Country: </strong>' + feature['0_name'] + '<br>';
                }
                if (_.has(feature, '1_name')) {
                    popup += '<strong>' + config.terminology.boundary_terminology.singular.admin1.capitalizeFirstLetter() +
                        ': </strong>' + feature['1_name'] + '<br>';
                }
                if (_.has(feature, '2_name')) {
                    // THIS IS A TEMPORARY HACK TO ADDRESS ACC boundaries SPECIAL popup
                    // This should be handled properly in terminology and connected to pmt.boundaries in config
                    if (_.contains(boundaryAliases, 'ethaccdissolved')) {
                        popup += '<strong>ACC: </strong>' + feature['2_name'] + '<br>';
                    }
                    else {
                        popup += '<strong>' + config.terminology.boundary_terminology.singular.admin2.capitalizeFirstLetter() +
                            ': </strong>' + feature['2_name'] + '<br>';
                    }
                }
                if (_.has(feature, '3_name')) {
                    // THIS IS A TEMPORARY HACK TO ADDRESS ACC boundaries SPECIAL popup
                    // This should be handled properly in terminology and connected to pmt.boundaries in config
                    if (_.contains(boundaryAliases, 'ethacc')) {
                        popup += '<strong>ACC: </strong>' + feature['3_name'] + '<br>';
                    }
                    else {
                        popup += '<strong>' + config.terminology.boundary_terminology.singular.admin3.capitalizeFirstLetter() +
                            ': </strong>' + feature['3_name'] + '<br>';
                    }
                }
                popup += '<strong>' + config.terminology.activity_terminology.plural.capitalizeFirstLetter() + ': </strong>' +
                    location.p;
                // get the current state's config
                var stateConfig = _.find(config.states, function (states) { return states.route == $state.current.name; });
                // if there is more than one pmt layer listed in config then add data group counts
                if (stateConfig.tools.map.layers.length > 1) {
                    popup += '<p>';
                    // loop through the pmt layers and collect individual data group information
                    _.each(pmtMapService.layers, function (layer) {
                        if (_.has(layer, "options")) {
                            // if the layer is not the clusters and is on the map add data group counts to pop-up
                            if (layer.options.alias != 'pmtCluster' && _.contains(mapLayers, layer.options.alias)) {
                                // get the point feature if there is data for it
                                var pointFeature = _.find(layer.options.data.locations,
                                    function (item) {
                                        return item.response.id == e.target.options.locations.response.id;
                                    });
                                if (pointFeature) {
                                    popup += '<strong>' + layer.options.data.layer.label + ' ' +
                                        config.terminology.activity_terminology.plural.capitalizeFirstLetter() + ': </strong>' +
                                        pointFeature.response.p + '<br>';
                                }
                            }
                        }
                    });
                    popup += '</p>';
                }
                // get popup information
                e.target._popup.setContent(popup);
                e.target.openPopup();
            }).error(function (data, status, headers, c) {
                // there was an error report it to the error handler
                console.log("error on api call to: pmt_boundary_feature");
            });
        }
        else {
            e.target.openPopup();
        }
    }

    // private function to remove popup from a point cluster
    // on mouse out
    function onMouseoutLocationPoint(e, force) {
        e.target.closePopup();
    }

    // private function to update current supporting layer boundary
    // layer boundaries are defined in pmt.boundaryPoints.<boundary-type>.boundary
    // the boundaries follow the zoom level definitions along with pmt points
    function updateBoundariesforLayers(boundaryLayer, boundaryLayers) {
        // get the current layers on the map
        var layers = $stateParams.layers.split(',');
        // get all the boundary aliases
        var boundaryAliases = _.pluck(_.pluck(_.filter(boundaryLayers, function (l) { return _.has(l, 'boundary'); }), 'boundary'), 'alias');
        // if the current boundary layer has a boundary to show 
        // then show it, otherwise remove all boundaries
        if (_.has(boundaryLayer, 'boundary')) {
            // remove the current boundary of the list of boundary alias
            boundaryAliases = _.without(boundaryAliases, boundaryLayer.boundary.alias);
            // remove any boundarys from the layer list remaining in the boudnary alias list
            layers = _.difference(layers, boundaryAliases);
            // add the current boundary if not in the list
            if (!_.contains(layers, boundaryLayer.boundary.alias)) { layers.push(boundaryLayer.boundary.alias); }
        }
        else {
            // remove any boundarys from the layer list in the boudnary alias list
            layers = _.difference(layers, boundaryAliases);
        }
        if (layers.join() !== $stateParams.layers) {
            // update state parameters
            $stateParams.layers = layers.join();
            stateService.setState($state.current.name, $stateParams, false);
        }
    }

    // private function to highlight current supporting layer boundary feature by id
    // layer boundaries are defined in pmtboundaryPoints.<boundary-type>.boundary
    // the boundaries follow the zoom level definitions along with pmt points
    function highlightBoundary(featureId, boundaryId) {
        clearHighlights();
        // get the current layers on the map
        var layers = $stateParams.layers.split(',');
        _.mapObject(pmt.boundaryPoints, function (boundary, alias) {
            _.each(boundary, function (b) {
                if (b.boundaryId == boundaryId) {
                    if (b.select) {
                        b.select.filter = [featureId];
                        layers.push(b.select.alias);
                    }
                }
            })
        });

        if (layers.join() !== $stateParams.layers) {
            // update state parameters
            $stateParams.layers = layers.join();
            stateService.setState($state.current.name, $stateParams, false);
        }
    }

    // private function to convert the filter.classification_ids 
    // object into a comma dilimeted list of ids
    function getClassificationIds() {
        var classificationIds = [];
        _.each(filter.classification_ids, function (c) {
            if (c.classification_ids.length > 0) {
                if (classificationIds.length > 0) {
                    classificationIds = classificationIds.concat(c.classification_ids);
                }
                else {
                    classificationIds = c.classification_ids;
                }
            }
        });
        classificationIds = _.unique(classificationIds);

        if (classificationIds.length > 0) { return classificationIds.join(); }
        else { return null; }
    }

    // private function to handle required processes 
    // when the filter is changed
    function filterUpdated() {
        // update activity count
        getActivityCount();
        // set all current layer filter applied boolean to false
        // so redraw is required
        _.each(pmtMapService.layers, function (l) { l.filterApplied = false; });
        // broadcast that the filter as changed
        $rootScope.$broadcast('pmt-filter-update');
        // update the global boolean for applied filters
        $rootScope.appliedFilters = filtersApplied();
    }

    // clear all selected features
    function clearSelections() {
        $('.leaflet-marker-icon').removeClass('pmt-selected');
        // broadcast the url has been updated
        $rootScope.$broadcast('unselect-pmt-map-feature');
    }

    // clear all highlighted boundary features
    function clearHighlights() {
        // get a list of all selection boundary alias
        var selections = [];
        _.each(pmt.boundaryPoints, function (boundarySet) {
            selections = selections.concat(_.pluck(_.pluck(_.filter(boundarySet, function (l) { return _.has(l, 'select'); }), 'select'), 'alias'));
        });
        // get the layer list
        var layers = $stateParams.layers.split(',');
        // get the selection aliases on the map
        var aliases = _.intersection(selections, layers);
        if (aliases.length > 0) {
            // update state parameters
            $stateParams.layers = _.difference(layers, aliases).join();
            stateService.setState($state.current.name, $stateParams, false);
        }
    }

    // private function which returns whether filters have been applied
    // date filters are not included as to not affect the top and prevent other
    // elements from shifting when a date filter is applied
    function filtersApplied() {
        if (filter.imp_org_ids.length > 0 || filter.fund_org_ids.length > 0
            || filter.unassigned_taxonomy_ids.length > 0) {
            return true;
        }
        else if (filter.classification_ids.length > 0) {
            var found = false;
            _.each(filter.classification_ids, function (c) {
                if (c.classification_ids.length > 0) {
                    found = true;
                }
            });
            return found;
        }
        else {
            return false;
        }
    }

    // private function to get an dictionary of export function names and associated dataGroupIds
    // for layers currently on the map
    function getDataGroupExportFunctions() {
        // get the layers present in url
        var aliases = [];
        if ($stateParams.layers !== '') {
            aliases = $stateParams.layers.split(',');
        }
        var exports = {};
        // get the current state's config
        var stateConfig = _.find(config.states, function (states) { return states.route == $state.current.name; });
        // create dictionary of function and dataGroupIds
        _.each(aliases, function (alias) {
            var layer = _.find(stateConfig.tools.map.layers, function (l) { return l.alias == alias });
            if (layer) {
                if (!exports[layer.export]) {
                    exports[layer.export] = {};
                    exports[layer.export].dataGroupIds = [];
                    exports[layer.export].dataGroupIds.push(layer.dataGroupIds);
                } else {
                    exports[layer.export].dataGroupIds.push(layer.dataGroupIds);
                }
            }
        });
        // convert array of dataGroupIds into string
        _.each(_.keys(exports), function (e) {
            exports[e].dataGroupIds = exports[e].dataGroupIds.join(",");
        });

        return exports;
    }

    // get total number of activities on the map
    function getActivityCount() {
        var deferred = $q.defer();
        var dataGroupIds = pmtMapService.getDataGroupIds();
        var options = {
            data_group_ids: dataGroupIds.join(','),
            classification_ids: getClassificationIds(),
            org_ids: filter.org_ids.join(),
            imp_org_ids: filter.imp_org_ids.join(','),
            fund_org_ids: filter.fund_org_ids.join(','),
            start_date: filter.start_date,
            end_date: filter.end_date,
            unassigned_taxonomy_ids: filter.unassigned_taxonomy_ids.join(','),
            activity_ids: filter.keyword_filter.activity_ids.join(','),
            boundary_filter: filter.boundary_filter,
            pmtId: pmt.id[pmt.env]
        };
        var header = {
            headers: { Authorization: 'Bearer ' + $rootScope.currentUser.token }
        };
        // broadcast the count is updating
        $rootScope.$broadcast('activity-count-updating');
        // if there is data group ids then request the current count
        if (dataGroupIds.length > 0) {
            // call the api to get the pmt data by boundary points
            $http.post(pmt.api[pmt.env] + 'pmt_activity_count', options, header)
                .success(function (data, status, headers, config) {
                    // remove unneccessary response object from api
                    var ct = _.pluck(data, 'response');
                    if (ct[0]) {
                        pmtMapService.activityCount = ct[0].ct;
                    }
                    else {
                        pmtMapService.activityCount = 0;
                    }
                    // broadcast the count has been updated
                    $rootScope.$broadcast('activity-count-update');
                    deferred.resolve(pmtMapService.activityCount);
                })
                .error(function (data, status, headers, c) {
                    // there was an error report it to the error handler
                    console.log("error on api call to: pmt_activity_count");
                    deferred.reject(status);
                });
        }
        // if there is no data group ids then the count is zero
        else {
            pmtMapService.activityCount = 0;
            // broadcast the count has been updated
            $rootScope.$broadcast('activity-count-update');
            deferred.resolve(pmtMapService.activityCount);
        }

        return deferred.promise;
    }


    ///private function to prompt the user about whether they want to switch to the activity panel
    function confirmSwitchToActivityPanel(e) {
        var currentTool = 'your current tool';
        //if currently on walkshed tool, update copy
        if (stateService.isParam('travel-panel')) {
            currentTool = 'the Walkshed Tool';
        }


        var confirm = $mdDialog.confirm()
            .title('You are about to leave ' + currentTool + ' to view Activity Details.')
            .textContent('Click VIEW DETAILS to open the activity info panel. Click CANCEL to stay in' + currentTool + '. ')
            .parent(angular.element(document.body))
            .hasBackdrop(true)
            .clickOutsideToClose(true)
            .ok('View Details')
            .cancel('Cancel');

        $mdDialog.show(confirm).then(function (result) {
            onClickLocationPoint(e, true);
        });
    }

    return pmtMapService;

});
