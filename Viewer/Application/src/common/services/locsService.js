/***************************************************************
 * Locations Module Service
 * Service to support the locations module functionality.
* *************************************************************/

angular.module('PMTViewer').service('locsService', function ($q, $http, $state, $rootScope, $stateParams, pmt, config, stateService, boundaryService, mapService, partnerLinkService) {

    var locsService = {
        nationalLayer: {},  // the national level layer (admin level 0)
        nationalFeatures: [], // list of names to filter the national level layer to
        regionalLayer: {},  // the regional level layer (admin level 1)
        regionalFeatures: [],  // the list of names to filter the regional level layer to
        regionalSelectLayer: {},  // the regional level selection layer (admin level 1), we use a custom selection process
        selectedNationalFeature: {}, // the current selected national feature (of the national layer)
        selectedRegionalFeature: {}, // the current selected regional feature (of the regional layer)
        dataGroups: [], //stores list of data groups for module
        taxonomies: [] // holds the taxonomies for filters
    };

    // private variable
    // filter contains current filter settings for all requested data
    var filter = {
        data_group_ids: [], // list of data group ids
        classification_ids: [], // list of classification_ids (excluding data group)
        start_date: null, // activity start date
        end_date: null,  // activity end date
        unassigned_taxonomy_ids: []  // unassigned taxonomy  ids (filter parameter for including activities that are NOT assigned to a given taxonomy)
    };

    // get the state configuration for the locations state
    var stateConfig = _.find(config.states, function (states) { return states.route == 'locations'; });

    // get the national layer
    locsService.getNationalLayer = function () {
        return locsService.nationalLayer;
    };

    // get the regional layer
    locsService.getRegionalLayer = function () {
        return locsService.regionalLayer;
    };

    // get the name of the national feature name for a given id
    locsService.getNationalFeatureName = function (id) {
        var feature = _.find(locsService.nationalFeatures, function (f) { return f.id == id; });
        if (feature) {
            return feature._name;
        }
        else {
            return null;
        }
    };

    // get the name of the regional feature name for a given id
    locsService.getRegionalFeatureName = function (id) {
        var feature = _.find(locsService.regionalFeatures, function (f) { return f.id == id; });
        return feature._name;
    };

    // update the regional features for a selected country
    locsService.setRegionalFeatures = function (country, callback) {
        // call the boundary services filter boundary features to get only the regions
        // for the selected country
        boundaryService.filterBoundaryFeatures(
            // boundary spatial table name
            locsService.regionalLayer.spatialTable,
            // field to query (based on PMT naming convention is derived from table name)
            '_' + locsService.nationalLayer.spatialTable + '_name',
            // query values
            country).then(function (data) {
                locsService.regionalFeatures = data;
                // get a list of ids from the regional features
                var regionIds = _.pluck(locsService.regionalFeatures, "id");
                // set the regional layer's filter
                locsService.regionalLayer.filter = regionIds;
                // set the regional select layer's target filter parameter
                if (_.has(locsService.regionalLayer, 'fields')) {
                    locsService.regionalLayer.filterParam = locsService.regionalLayer.fields.id;
                }
                else {
                    locsService.regionalLayer.filterParam = 'id';
                }
                // add the layer to state (which will add it to the map)
                $stateParams.layers = locsService.regionalLayer.alias;
                // update parameters        
                stateService.setState($state.current.name, $stateParams, false);
                // force the map to redraw
                mapService.forceRedraw();
                callback();
            });
    };

    // set the selected national feature
    locsService.setNationalFeature = function (id) {
        locsService.selectedNationalFeature = _.find(locsService.nationalFeatures, function (f) { return f.id == id; });
    };

    // set the selected regional feature
    locsService.setRegionalFeature = function (id, name) {
        locsService.selectedRegionalFeature = _.find(locsService.regionalFeatures, function (f) { return f.id == id; });
        // update the regional layer's filter to remove the selected feature
        locsService.updateRegionalFilter(id);
        var filter = [];
        filter.push(id);
        // set the regional select layer's filter
        locsService.regionalSelectLayer.filter = filter;
        // set the regional select layer's target filter parameter
        if (_.has(locsService.regionalSelectLayer, 'fields')) {
            locsService.regionalSelectLayer.filterParam = locsService.regionalSelectLayer.fields.id;
        }
        else {
            locsService.regionalSelectLayer.filterParam = 'id';
        }
        var layers = [];
        layers.push(locsService.regionalLayer.alias);
        layers.push(locsService.regionalSelectLayer.alias);
        // add the layer to state (which will add it to the map)
        $stateParams.layers = layers.join();
        // update parameters        
        stateService.setState($state.current.name, $stateParams, false);      
    };

    // get the classification ids for the selected national feature
    locsService.getSelectedNationalFeatureFilter = function () {
        if (locsService.selectedNationalFeature) {
            var country = _.find(stateConfig.tools.map.countries, function (c) { return c.country === locsService.selectedNationalFeature._name; });
            if (country) { return country.classification_ids; }
            else { return null; }
        }
        else { return null; }
    };

    // update the regional features filter
    locsService.updateRegionalFilter = function (selected) {
        // get a list of names from the regional features
        var regionIds = _.pluck(locsService.regionalFeatures, "id");
        // remove the selected features from the list of regions
        regionIds = _.filter(regionIds, function (r) { return r !== selected; });
        // update the region layers filter
        locsService.regionalLayer.filter = regionIds;
        // force the map to redraw
        mapService.forceRedraw();
    };

    // set the service to the world view
    locsService.setAreaToWorld = function () {
        // set the area to national level
        $stateParams.area = 'world';
        // set the selection feature
        $stateParams.selection = null;
        // clear selections
        locsService.selectedNationalFeature = {};
        locsService.selectedRegionalFeature = {};
        // add the layer to state (which will add it to the map)
        $stateParams.layers = locsService.nationalLayer.alias;
        // set the map to defaults
        mapService.setMapCenter(stateConfig.stateParamDefaults.lat, stateConfig.stateParamDefaults.lng, stateConfig.stateParamDefaults.zoom);
        // update parameters        
        stateService.setState($state.current.name, $stateParams, false);
    };

    // select a country (user clicks on feature)
    locsService.selectCountry = function (id, name) {
        if (name !== 'World') {
            var feature;
            // get the feature by id            
            if (id) {
                feature = _.find(locsService.nationalFeatures, function (f) { return f.id == id; });
            }
            // get the feature by name
            else {
                feature = _.find(locsService.nationalFeatures, function (f) { return f._name == name; });
            }
            if (feature) {
                // set the selected national feature
                locsService.setNationalFeature(feature.id);
                // set the area to national level
                $stateParams.area = 'national';
                // set the selection feature
                $stateParams.selection = String(feature.id);
                // set & show the available regional features by selected country
                locsService.setRegionalFeatures(feature._name, function () { });
                // zoom to selected country
                boundaryService.getBoundaryExtent(locsService.nationalLayer.spatialTable, feature._name).then(function (data) {
                    var extent = JSON.parse(data[0].extent);
                    mapService.zoomToExtent(extent.coordinates[0]);
                });
                // update state parameters        
                stateService.setState($state.current.name, $stateParams, false);
            }
        }
    };

    // select a region (user clicks on feature)
    locsService.regionSelected = function (id, name) {
        var feature;
        // get the feature by id            
        if (id) {
            feature = _.find(locsService.regionalFeatures, function (f) { return f.id == id; });
        }
        // get the feature by name
        else {
            feature = _.find(locsService.regionalFeatures, function (f) { return f._name == name; });
        }
        if (feature) {
            // set the area to regional level
            $stateParams.area = 'regional';
            // set the selection feature
            $stateParams.selection = String(feature.id);
            // set the selected regional feature
            locsService.setRegionalFeature(feature.id, feature._name);
            // update state parameters        
            stateService.setState($state.current.name, $stateParams, false);
        }

    };

    // update the boundaries used
    locsService.updateBoundaries = function () {
        // re-initialize the location service data
        locsService.init();
        // if the selection is set and area is national process for default at national level
        if (_.has(stateConfig.stateParamDefaults, 'selection') && stateConfig.stateParamDefaults.selection !== null
            && stateConfig.stateParamDefaults.area === 'national') {
            $stateParams.area = stateConfig.stateParamDefaults.area || $stateParams.area;
            // set the selected national feature
            locsService.setNationalFeature(stateConfig.stateParamDefaults.selection);
            // update the state
            stateService.setState($state.current.name, $stateParams, false);
            // call the boundary services filter boundary features to get only the regions
            // for the selected country
            boundaryService.filterBoundaryFeatures(
                // boundary spatial table name
                locsService.regionalLayer.spatialTable,
                // field to query (based on PMT naming convention is derived from table name)
                '_' + locsService.nationalLayer.spatialTable + '_name',
                // query values
                stateConfig.tools.map.countries[0]._name).then(function (data) {
                    locsService.regionalFeatures = data;
                    // get a list of names from the regional features
                    var regionIds = _.pluck(locsService.regionalFeatures, "id");
                    // set the regional layer's filter
                    locsService.regionalLayer.filter = regionIds;
                    // set the regional select layer's target filter parameter
                    if (_.has(locsService.regionalLayer, 'fields')) {
                        locsService.regionalLayer.filterParam = locsService.regionalLayer.fields.id;
                    }
                    else {
                        locsService.regionalLayer.filterParam = 'id';
                    }
                    // set the stateParams selection value to default country
                    $stateParams.selection = String(stateConfig.stateParamDefaults.selection);
                    mapService.clearLayers();
                    $stateParams.basemap = stateConfig.stateParamDefaults.basemap;
                    // set layers
                    var boundaryGroup = _.find(stateConfig.tools.map.toggleBoundaries, function (t) { return t.boundaryGroup == stateConfig.tools.map.boundaryGroup; })
                    $stateParams.layers = boundaryGroup.layer;
                    // update the state
                    stateService.setState($state.current.name, $stateParams, false);
                    // force map to redraw
                    mapService.forceRedraw();
                });
        }
    };

    // gets and returns list of classifications for a taxonomy
    locsService.getTaxonomy = function (taxonomy_id, inuse) {
        var deferred = $q.defer();
        var data_group_ids = null;
        if (inuse) {
            data_group_ids = filter.data_group_ids.join(',');
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
        $http.post(pmt.api[pmt.env] + 'pmt_classifications', options, header, { cache: true })
            .success(function (data, status, headers, config) {
                var classifications = [];
                // add the active parameter to our object
                _.each(data, function (o) {
                    var classification = o.response;
                    _.extend(classification, { active: false });
                    classifications.push(classification);
                });
                // remove taxonomy from the service
                locsService.taxonomies = _.reject(locsService.taxonomies, function (t) { return t.taxonomy_id === taxonomy_id; });
                // add updated taxonomy to the service
                var t = {
                    taxonomy_id: taxonomy_id,
                    classification_ids: classifications
                };
                locsService.taxonomies.push(t);
                deferred.resolve(classifications);
            })
            .error(function (data, status, headers, c) {
                // there was an error report it to the error handler
                console.log("error on api call to: pmt_classifications");
                deferred.reject(status);
            });
        return deferred.promise;
    };

    // sets the data group ids filter
    locsService.setDataGroupFilter = function (id) {
        if (!_.contains(filter.data_group_ids, id)) {
            filter.data_group_ids.push(id);
            // the filter has been updated
            filterUpdated();
        }
    };

    // sets the classification ids filter
    locsService.setClassificationFilter = function (taxonomy_id, ids) {
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

    // set the start date filter
    locsService.setStartDateFilter = function (date) {
        if (date != filter.start_date) {
            filter.start_date = date;
            // the filter has been updated
            filterUpdated();
        }
    };

    // sets the end date filter
    locsService.setEndDateFilter = function (date) {
        if (date != filter.end_date) {
            filter.end_date = date;
            // the filter has been updated
            filterUpdated();
        }
    };

    // sets the unassigned taxonomy ids filter
    locsService.setUnassignedTaxonomyFilter = function (id) {
        if (!_.contains(filter.unassigned_taxonomy_ids, id)) {
            filter.unassigned_taxonomy_ids.push(id);
            // the filter has been updated
            filterUpdated();
        }
    };

    // set a group of filters at once
    locsService.setFilters = function (data_group_ids, taxonomy_filter, start_date, end_date, unassigned_taxonomy_ids) {
        var filterChanged = false;
        // set data group filter
        // expecting array of integers
        if (data_group_ids) {
            _.each(data_group_ids, function (id) {
                if (!_.contains(filter.data_group_ids, id)) {
                    filter.data_group_ids.push(id);
                    filterChanged = true;
                }
            });
        }
        // set classification filter
        // expecting array of objects [{"taxonomy_id": 15, "classification_ids":[]}]
        if (taxonomy_filter) {
            _.each(taxonomy_filter, function (taxonomy) {
                // get the taxonomy filter if it already exists
                var taxClassifications = _.find(filter.classification_ids, function (c) { return c.taxonomy_id === taxonomy.taxonomy_id });
                // update the classification ids for the taxonomy filter
                if (taxClassifications) {
                    if (taxClassifications.classification_ids != taxonomy.classification_ids) {
                        taxClassifications.classification_ids = taxonomy.classification_ids;
                        filterChanged = true;
                    }
                }
                // taxonomy filter doesn't exists to create it
                else {
                    var obj = {
                        taxonomy_id: taxonomy.taxonomy_id,
                        classification_ids: taxonomy.classification_ids
                    };
                    filter.classification_ids.push(obj);
                    filterChanged = true;
                }
            });
        }
        // set start date filter
        // expecting date string
        if (start_date) {
            if (start_date != filter.start_date) {
                filter.start_date = start_date;
                filterChanged = true;
            }
        }
        // set end date filter
        // expecting date string
        if (end_date) {
            if (end_date != filter.end_date) {
                filter.end_date = end_date;
                filterChanged = true;
            }
        }
        // set unassigned taxonomy filter
        // expecting array of integers
        if (unassigned_taxonomy_ids) {
            if (unassigned_taxonomy_ids != filter.unassigned_taxonomy_ids) {
                filter.unassigned_taxonomy_ids = unassigned_taxonomy_ids;
                filterChanged = true;
            }
        }
        // call the filter update function if a filter
        // was updated
        if (filterChanged) { filterUpdated(); }
    };

    // remove a data group id from filter
    locsService.removeDataGroupFilter = function (id) {
        if (id) {
            filter.data_group_ids = _.without(filter.data_group_ids, id);
            // the filter has been updated
            filterUpdated();
        }
    };

    // remove a taxonomy id from filter
    locsService.removeClassificationFilter = function (id) {
        if (id) {
            // loop through each taxonomy filter
            _.each(filter.classification_ids, function (taxonomy_filter) {
                taxonomy_filter.classification_ids = _.without(taxonomy_filter.classification_ids, id);
            });
            // the filter has been updated
            filterUpdated();
        }
    };

    // remove the start date filter
    locsService.removeStartDateFilter = function () {
        filter.start_date = null;
        // the filter has been updated
        filterUpdated();
    };

    // remove the end date filter
    locsService.removeEndDateFilter = function () {
        filter.end_date = null;
        // the filter has been updated
        filterUpdated();
    };

    // remove a taxonomy id from filter
    locsService.removeUnassignedTaxonomyFilter = function (id) {
        if (id) {
            filter.unassigned_taxonomy_ids = _.without(filter.unassigned_taxonomy_ids, id);
            // the filter has been updated
            filterUpdated();
        }
    };

    // clear all filters
    locsService.clearFilters = function () {
        // clear all filters
        filter.classification_ids = [];
        filter.start_date = null;
        filter.end_date = null;
        filter.unassigned_taxonomy_ids = [];
        // the filter has been updated
        filterUpdated();
    };

    // t/f there are applied filters
    locsService.hasFilters = function () {
        if (filter.unassigned_taxonomy_ids.length > 0) {
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
        else if (filter.start_date != null || filter.end_date != null) {
            return true;
        }
        else {
            return false;
        }
    };

    // gets the filters and creates a model specific to the selection panel
    // example returned filter object:
    // f = [{id: 342, label: "Yams", type: "c"},{id: 13, label: "BMGF", type: "fund"}]
    locsService.getSelectedFilters = function () {
        var filters = [];
        // get a comma seperated list of selected classification ids
        var idList = getClassificationIds();
        if (idList) {
            var ids = idList.split(',');
            if (ids.length > 0) {
                // loop through the selected classification ids
                _.each(ids, function (id) {
                    // look up the classification
                    _.each(locsService.taxonomies, function (t) {
                        var cls = _.find(t.classification_ids, function (c) { return c.id == id; });
                        if (cls) {
                            // add the classification to the selected features
                            filters.push({ id: cls.id, label: cls.c, type: "c" });
                        }
                    });
                });
            }
        }
        // loop through the selected unassigned taxonomy ids
        _.each(filter.unassigned_taxonomy_ids, function (id) {
            var tax = _.find(locsService.taxonomies, function (t) { return t.taxonomy_id == id; });
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
        // start date
        if (filter.start_date) {
            var sDate = (filter.start_date.getMonth() + 1) + '/' + filter.start_date.getDate() + '/' + filter.start_date.getFullYear();
            filters.push({ id: null, label: 'Start Date: ' + sDate, type: "startDate" });
        }
        // end date
        if (filter.end_date) {
            var eDate = (filter.end_date.getMonth() + 1) + '/' + filter.end_date.getDate() + '/' + filter.end_date.getFullYear();
            filters.push({ id: null, label: 'End Date: ' + eDate, type: "endDate" });
        }

        return filters;
    };

    // gets the data group filters
    locsService.getDataGroupFilters = function () { return filter.data_group_ids; };

    // gets the classification filters
    locsService.getClassificationFilters = function () {
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

    // gets start date filter
    locsService.getStartDateFilter = function () {
        return filter.start_date;
    };

    // gets end date filter
    locsService.getEndDateFilter = function () { return filter.end_date; };

    // gets the unassigned taxonomy filters
    locsService.getUnassignedTaxonomyFilters = function () { return filter.unassigned_taxonomy_ids; };

    // export utility for the pivot table
    locsService.exportPivotasCSV = function (chartData, headers, label1, label2, orgName, widgetData) {
        var deferred = $q.defer();
        var params = widgetData.params;
        var header = {
            '0': 'Title: ' + widgetData.title + orgName,
            '1': 'Area: ' + widgetData.area,
            '2': 'Column Taxonomy:' + label2
        };
        // file header
        var fileName = widgetData.title + orgName;

        //store data to download
        var data = [];
        //add header to data
        data.push(header);
        //add an empty row for formatting
        data.push({});

        //format data to download
        //start with headers
        var column_headers = {};
        _.each(headers, function (h, i) {
            //first header should be pivot column name
            if (i === 0) {
                column_headers[i] = label1;
            }
            else {
                column_headers[i] = h.key;
            }
        });
        data.push(column_headers);

        //each row
        _.each(chartData, function (d) {
            var row = {};

            //loop through each column
            _.each(d, function (c, index) {
                //store column value
                var c_value = '';

                //header
                if (index == 0) {
                    //if unspecified column, update header
                    if (d[0][0].f1 == null) {
                        row[0] = params.unspecified_label;
                    }
                    else {
                        row[0] = d[0][0].f1;
                    }
                }
                //if column is null, add it
                else if (c == null) {
                    row[index] = '';
                }
                //if there is only one column value
                else if (c.length == 1) {
                    //if there is an overflow, concat all of the values
                    if (c[0].overflow != null && c[0].overflow.length > 0) {
                        _.each(c[0].overflow, function (value) {
                            c_value = c_value + value.f3 + '; ';
                        });
                        row[index] = c_value;
                    }
                    //if there is no overflow
                    else {
                        row[index] = c[0].f3;
                    }
                }
                //if there are multiple column values
                else if (c.length > 1) {
                    //loop through all of the orgs, with the last one potentially having overflow
                    for (var i = 0; i < c.length; i++) {
                        //if i is the last element
                        if (i == c.length - 1) {
                            //if there is an overflow, concat all of the values
                            if (c[i].overflow != null && c[i].overflow.length > 0) {

                                _.each(c[i].overflow, function (value) {
                                    c_value = c_value + value.f3 + '; ';
                                });

                            }
                            //if there is no overflow
                            else {
                                c_value = c_value + c[i].f3 + '; ';
                            }
                        }
                        else {
                            c_value = c_value + c[i].f3 + '; ';
                        }
                    }
                    row[index] = c_value;
                }
                else {
                    console.log('error');
                }
            });
            data.push(row);
        });

        // download csv
        partnerLinkService.JSONToCSVConvertor(data, fileName, false, function () {
            deferred.resolve(data);
        });
    }

    // utility function to format and abbreviate money
    locsService.abbreviateMoney = function (x) {
        // less than a million
        if (x > 0 && x < 999999) {
            x = Math.round(x);
            return "$ " + x.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ",");
        }
        // a least a million, but less than a billion
        if (x > 999999 && x < 999999999) {
            x = x / 1000000;
            x = x.toFixed(2);
            return "$ " + x.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ",") + " M";
        }
        // a least a billion, but less than a trillion
        if (x > 999999999 && x < 999999999999) {
            x = x / 1000000000;
            x = x.toFixed(2);
            return "$ " + x.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ",") + " B";
        }
        // a least a trillion
        if (x > 999999999999) {
            x = x / 1000000000000;
            x = x.toFixed(2);
            return "$ " + x.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ",") + " T";
        }
    };

    // private function to convert the filter.classification_ids
    // object into a comma delimited list of ids
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

    // the location service filter has been updated
    function filterUpdated() {
        $rootScope.$broadcast('locs-filter-update');
    }

    // initialize the location service
    locsService.init = function () {
        var deferred = $q.defer();
        var setState = false;
        // get the national layer
        locsService.nationalLayer = _.find(stateConfig.tools.map.supportingLayers, function (l) { return l.area == 'national' && l.boundaryGroup == stateConfig.tools.map.boundaryGroup; });
        // get the regional layer
        locsService.regionalLayer = _.find(stateConfig.tools.map.supportingLayers, function (l) { return l.area == 'regional' && l.boundaryGroup == stateConfig.tools.map.boundaryGroup; });
        // get the regional select layer
        locsService.regionalSelectLayer = _.find(stateConfig.tools.map.supportingLayers, function (l) { return l.area == 'select' && l.boundaryGroup == stateConfig.tools.map.boundaryGroup; });
        // get the configurations list of countries for the national area
        var countries = _.pluck(stateConfig.tools.map.countries, "_name");
        // if the default area is world, add world to the list of countries
        if (stateConfig.stateParamDefaults.area === 'world') {
            if (!_.contains(countries, "World")) {
                stateConfig.tools.map.countries.unshift({ "_name": "World", "id": null });
            }
        }
        // set the national layer's filter for the participating countries
        locsService.nationalLayer.filter = countries;
        // set the national layer's target filter parameter
        locsService.nationalLayer.filterParam = '_name';
        // set the national layers mutext toggle (only one feature selected at a time)
        locsService.nationalLayer.mutexToggle = true;
        // set the national layers on click function
        locsService.nationalLayer.onClick = function (evt) {
            //if clicked on map
            if (evt.feature) {
                locsService.selectCountry(evt.feature.properties.id, evt.feature.properties._name);
            }
        };
        // assign the features to the national list of features
        locsService.nationalFeatures = stateConfig.tools.map.countries;
        // set the regional layers mutext toggle (only one feature selected at a time)
        locsService.regionalLayer.mutexToggle = true;
        // set the regional layers on click function
        locsService.regionalLayer.onClick = function (evt) {
            //if clicked on map
            if (evt.feature) {
                if (_.has(locsService.regionalLayer, 'fields')) {
                    locsService.regionSelected(evt.feature.properties[locsService.regionalLayer.fields.id], evt.feature.properties[locsService.regionalLayer.fields.name]);
                }
                else {
                    locsService.regionSelected(evt.feature.properties.id, evt.feature.properties._name);
                }
            }
        };
        // set the regional layers select style to the base style
        locsService.regionalLayer.style.selected = locsService.regionalLayer.style;
        // if the region layer has a filter by parameter copy it into the filter
        locsService.regionalLayer.filter = [];
        locsService.regionalLayer.filter = angular.copy(locsService.regionalLayer.filterBy);
        // set the stateParams not related to the map (those are managed by the mapService)
        // update state parameters if empty
        if ($stateParams.area == '') {
            $stateParams.area = $stateParams.area || stateConfig.stateParamDefaults.area;
            setState = true;
        }
        // if the selection is set and area is national process for default at national level
        if (_.has(stateConfig.stateParamDefaults, 'selection') && stateConfig.stateParamDefaults.selection !== null
            && stateConfig.stateParamDefaults.area === 'national' && $stateParams.selection == '') {
            // set the selected national feature
            locsService.setNationalFeature(stateConfig.stateParamDefaults.selection);
            // update the state
            stateService.setState($state.current.name, $stateParams, false);
            // call the boundary services filter boundary features to get only the regions
            // for the selected country
            boundaryService.filterBoundaryFeatures(
                // boundary spatial table name
                locsService.regionalLayer.spatialTable,
                // field to query (based on PMT naming convention is derived from table name)
                '_' + locsService.nationalLayer.spatialTable + '_name',
                // query values
                stateConfig.tools.map.countries[0]._name).then(function (data) {
                    locsService.regionalFeatures = data;
                    // get a list of names from the regional features
                    var regionIds = _.pluck(locsService.regionalFeatures, "id");
                    // set the regional layer's filter
                    locsService.regionalLayer.filter = regionIds;
                    // set the regional select layer's target filter parameter
                    if (_.has(locsService.regionalLayer, 'fields')) {
                        locsService.regionalLayer.filterParam = locsService.regionalLayer.fields.id;
                    }
                    else {
                        locsService.regionalLayer.filterParam = 'id';
                    }
                    // set the stateParams selection value to default country
                    $stateParams.selection = String(stateConfig.stateParamDefaults.selection);
                    // update the state
                    stateService.setState($state.current.name, $stateParams, false);
                });
        }
        else {
            // setState if it was altered
            if (setState) { stateService.setState($state.current.name, $stateParams, false); }
        }
        // add data groups to locsService
        locsService.dataGroups = stateConfig.tools.map.dataSources;
        // look through data sources and grab ones that are active
        _.each(locsService.dataGroups, function (source) {
            if (source.active) {
                //add data groups of active data sources
                var dg = source.dataGroupIds.split(",");
                _.each(dg, function (id) {
                    filter.data_group_ids.push(id);
                });
            }
        });

        deferred.resolve();
        return deferred.promise;
    };

    return locsService;
});