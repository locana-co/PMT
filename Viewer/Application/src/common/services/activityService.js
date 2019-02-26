/***************************************************************
 * Activity Service
 * Service to interact with Activity Data.
 * *************************************************************/

angular.module('PMTViewer').service('activityService', function ($q, $http, config, stateService, pmt, $state, $rootScope, partnerLinkService, pmtMapService) {
    // the activity service model
    var activityService = {
        activityCount: 0, // holds activity count
        taxonomies: [], // holds the taxonomies for filters
        orgsInUse: [], // holds list of all orgs in use
        allActivities: [], // holds list of all activities
        selectedActivity: {}, //stores selectedActivity
        boundaryMenu: null // contains the boundary menu
    };

    // private variable
    // filter contains current filter settings for all requested data
    var filter = {
        data_group_ids: [], // list of data group ids
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

    // track the last time the activity list was fetched
    var lastListUpdate = null;

    // get the state configuration for the locations state
    var stateConfig = _.find(config.states, function (states) { return states.route == 'activities'; });

    // gets and returns activity details
    activityService.getActivities = function () {
        var deferred = $q.defer();
        // broadcast that activity list is updating
        $rootScope.$broadcast('act-list-updating');
        // if there is no data group ids then the list should be empty
        if (filter.data_group_ids.length <= 0) {
            activityService.allActivities = [];
            activityService.activityCount = activityService.allActivities.length;
            // update the timestamp for when list was last updated
            lastListUpdate = + new Date();
            // broadcast that activity list is updated
            $rootScope.$broadcast('act-list-updated');
            deferred.resolve(activityService.allActivities);
        }
        //if there is a keyword and no activity ids, list should be empty
        else if (filter.keyword_filter.keyword && filter.keyword_filter.activity_ids.length == 0) {
            activityService.allActivities = [];
            activityService.activityCount = activityService.allActivities.length;
            // update the timestamp for when list was last updated
            lastListUpdate = + new Date();
            // broadcast that activity list is updated
            $rootScope.$broadcast('act-list-updated');
            deferred.resolve(activityService.allActivities);
        }
        // update activities
        else {
            var options = {
                data_group_ids: filter.data_group_ids.join(","),
                classification_ids: getClassificationIds(),
                imp_org_ids: filter.imp_org_ids.join(","),
                fund_org_ids: filter.fund_org_ids.join(","),
                org_ids: filter.org_ids.join(","),
                start_date: filter.start_date,
                end_date: filter.end_date,
                unassigned_taxonomy_ids: filter.unassigned_taxonomy_ids.join(","),
                activity_ids: filter.keyword_filter.activity_ids.join(),
                boundary_filter: filter.boundary_filter,
                pmtId: pmt.id[pmt.env]
            };
            var header = {
                headers: { Authorization: 'Bearer ' + $rootScope.currentUser.token }
            };
            // call the api to get the pmt data
            $http.post(pmt.api[pmt.env] + 'pmt_activities', options, header).success(function (data, status, headers, config) {
                activityService.allActivities = data;
                processActivities();
                // console.log("pmt_activities (after processing): ", activityService.allActivities);
                // update the timestamp for when list was last updated
                lastListUpdate = + new Date();
                // broadcast that activity list is updated
                $rootScope.$broadcast('act-list-updated');
                deferred.resolve(activityService.allActivities);
            }).error(function (data, status, headers, c) {
                // there was an error report it to the error handler
                console.log("error on api call to: pmt_activity");
                $rootScope.$broadcast('act-list-updated');
                deferred.reject(status);
            });
        }

        return deferred.promise;
    };

    // gets and returns activities for a specific project (didn't want to affect main activities page)
    activityService.getProjectActivities = function (data_group) {
        var deferred = $q.defer();
        var options = {
            data_group_ids: data_group.join(","),
            classification_ids: "",
            imp_org_ids: "",
            fund_org_ids: "",
            org_ids: "",
            start_date: null,
            end_date: null,
            unassigned_taxonomy_ids: "",
            activity_ids: "",
            boundary_filter: null,
            pmtId: pmt.id[pmt.env]
        };
        var header = {
            headers: { Authorization: 'Bearer ' + $rootScope.currentUser.token }
        };
        // call the api to get the pmt data
        $http.post(pmt.api[pmt.env] + 'pmt_activities', options, header).success(function (data, status, headers, config) {
            var activities = processActivities(data);
            deferred.resolve(activities);
        }).error(function (data, status, headers, c) {
            // there was an error report it to the error handler
            console.log("error on api call to: pmt_activity");
            deferred.reject([]);
        });

        return deferred.promise;
    };

    // gets and returns activity details
    activityService.getDetail = function (activity_id) {
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

     // gets and returns activity details
     activityService.getActivityDetails = function (activity_id) {
        var deferred = $q.defer();
        var options = {
            id: activity_id,
            pmtId: pmt.id[pmt.env]
        };
        var header = {
            headers: { Authorization: 'Bearer ' + $rootScope.currentUser.token }
        };
        // call the api to get the pmt data by boundary points
        $http.post(pmt.api[pmt.env] + 'pmt_activity_detail', options, header)
            .success(function (data, status, headers, config) {
                deferred.resolve(data);
                // console.log('pmt_activity:',data);
            })
            .error(function (data, status, headers, c) {
                // there was an error report it to the error handler
                console.log("error on api call to: pmt_activity_detail");
                deferred.reject(status);
            });
        return deferred.promise;
    };

    // saves assignment changes
    activityService.saveActivityClassifications = function (activity_ids, classification_ids, taxonomy_ids, edit_action) {
        var deferred = $q.defer();
        var options = {
            pmtId: pmt.id[pmt.env],
            instance_id: pmt.instance,
            user_id: $rootScope.currentUser.user.id,
            activity_ids: activity_ids.join(','),
            classification_ids: classification_ids.join(','),
            taxonomy_ids: taxonomy_ids.join(','),
            edit_action: edit_action
        };
        var header = {
            headers: { Authorization: 'Bearer ' + $rootScope.currentUser.token }
        };
        // call the api to get the pmt data by boundary points
        $http.post(pmt.api[pmt.env] + 'pmt_edit_activity_taxonomy', options, header)
            .success(function (data, status, headers, config) {
                deferred.resolve(data);
            })
            .error(function (data, status, headers, c) {
                // there was an error report it to the error handler
                console.log("error on api call to: pmt_activity");
                deferred.reject(status);
            });
        return deferred.promise;
    };

    // returns all activities and associations to classifications based of a list of classifications
    activityService.getFamilyTree = function (classification_ids) {
        var deferred = $q.defer();
        var options = {
            pmtId: pmt.id[pmt.env],
            data_group_ids: stateConfig.datagroups[0].data_group_id.toString(),
            classification_ids: classification_ids.join(',')
        };
        var header = {
            headers: { Authorization: 'Bearer ' + $rootScope.currentUser.token }
        };
        // call the api to get the pmt data by boundary points
        $http.post(pmt.api[pmt.env] + 'pmt_activity_family_titles', options, header)
            .success(function (data, status, headers, config) {
                deferred.resolve(data);
            })
            .error(function (data, status, headers, c) {
                // there was an error report it to the error handler
                console.log("error on api call to: pmt_activity");
                deferred.reject(status);
            });
        return deferred.promise;
    };

    // gets and returns list of organizations in use
    activityService.getOrgsInUse = function (org_role_ids, type) {
        var deferred = $q.defer();
        var dataGroupIds = activityService.getDataGroupFilters();
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
            // cache the data in the service
            var o = {
                org_role_ids: org_role_ids,
                data_group_ids: dataGroupIds.join(','),
                organizations: orgs
            };
            // clear and refill the orgs
            activityService.orgsInUse[type] = [];
            activityService.orgsInUse[type] = orgs;
            // return the orgs
            deferred.resolve(orgs);
        }).error(function (data, status, headers, c) {
            // there was an error report it to the error handler
            console.log("error on api call to: pmt_org_inuse");
            deferred.reject(status);
        });
        return deferred.promise;
    };

    // gets and returns list of classifications for a taxonomy
    activityService.getTaxonomy = function (taxonomy_id, inuse) {
        var deferred = $q.defer();
        var data_group_ids = null;
        if (inuse) {
            data_group_ids = filter.data_group_ids.join(',');
        }
        var options = {
            taxonomy_id: taxonomy_id, // taxonomy id
            data_group_ids: data_group_ids, // return in-use classifications for data groups listed, otherwise all classifications
            locations_only: false, // return in-use classifications for activities with locations only
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
                activityService.taxonomies = _.reject(activityService.taxonomies, function (t) { return t.taxonomy_id === taxonomy_id; });
                // add updated taxonomy to the service
                var t = {
                    taxonomy_id: taxonomy_id,
                    classification_ids: classifications
                };
                activityService.taxonomies.push(t);
                deferred.resolve(classifications);
            })
            .error(function (data, status, headers, c) {
                // there was an error report it to the error handler
                console.log("error on api call to: pmt_classifications");
                deferred.reject(status);
            });
        return deferred.promise;
    };

    // gets selected activity
    activityService.getSelectedActivity = function () {
        return activityService.selectedActivity;
    };

    // sets the data group ids filter
    activityService.setDataGroupFilter = function (id) {
        if (!_.contains(filter.data_group_ids, id)) {
            filter.data_group_ids.push(id);
            // the filter has been updated
            filterUpdated();
        }
    };

    // sets the classification ids filter
    activityService.setClassificationFilter = function (taxonomy_id, ids) {
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
    activityService.setImpOrgFilter = function (ids) {
        if (ids != filter.imp_org_ids) {
            filter.imp_org_ids = ids;
            // the filter has been updated
            filterUpdated();
        }
    };

    // sets the funding org ids filter
    activityService.setFundOrgFilter = function (ids) {
        if (ids != filter.fund_org_ids) {
            filter.fund_org_ids = ids;
            // the filter has been updated
            filterUpdated();
        }
    };

    // sets the org ids filter 
    activityService.setOrgFilter = function (ids) {
        if (ids != filter.org_ids) {
            filter.org_ids = ids;
            // the filter has been updated
            filterUpdated();
        }
    };

    // sets the start date filter
    activityService.setStartDateFilter = function (date) {
        if (date != filter.start_date) {
            filter.start_date = date;
            // the filter has been updated
            filterUpdated();
        }
    };

    // sets the end date filter
    activityService.setEndDateFilter = function (date) {
        if (date != filter.end_date) {
            filter.end_date = date;
            // the filter has been updated
            filterUpdated();
        }
    };

    // sets the start & end date filters
    // use when setting both start and end date in a single transaction
    activityService.setDateFilters = function (startDate, endDate) {
        if (startDate != filter.start_date || endDate != filter.end_date) {
            filter.start_date = startDate;
            filter.end_date = endDate;
            // the filter has been updated
            filterUpdated();
        }
    };

    // sets the unassigned taxonomy ids filter
    activityService.setUnassignedTaxonomyFilter = function (id) {
        if (!_.contains(filter.unassigned_taxonomy_ids, id)) {
            filter.unassigned_taxonomy_ids.push(id);
            // the filter has been updated
            filterUpdated();
        }
    };

    // sets the boundary filter
    activityService.setBoundaryFilter = function (boundary_object) {
        filter.boundary_filter = boundary_object;
        // the filter has been updated
        filterUpdated();
    };

    // set the keyword filter
    activityService.setKeywordFilter = function (keyword) {
        // check if keyword has changed
        if (keyword != filter.keyword_filter.keyword) {
            filter.keyword_filter.keyword = keyword;
            // data group ids
            var data_group_ids = [];
            var dataGroupFilter = _.find(stateConfig.tools.map.filters, function (f) { return f.type === 'datasource'; });
            _.each(dataGroupFilter.params.dataSources, function (filter) {
                var dgs = filter.dataGroupIds.split(',');
                _.each(dgs, function(dg){
                    data_group_ids.push(dg);
                });
            });
            // call the api to get a list of activities ids matching the keyword
            pmtMapService.globalSearchText(keyword, data_group_ids).then(function (data) {
                // update filter activity_ids list
                if (data[0].response.ids) { filter.keyword_filter.activity_ids = data[0].response.ids; }
                else { filter.keyword_filter.activity_ids = []; }
                // the filter has been updated
                filterUpdated();
            });
        }
    }

    // gets selected activity
    activityService.setSelectedActivity = function (activity) {
        activityService.selectedActivity = activity;
        $rootScope.$broadcast('acts-title-update');
    };

    // set a group of filters at once
    activityService.setFilters = function (data_group_ids, taxonomy_filter, imp_org_ids, fund_org_ids,
        org_ids, start_date, end_date, unassigned_taxonomy_ids) {
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
        // set implementing org filter
        // expecting array of integers
        if (imp_org_ids) {
            if (imp_org_ids != filter.imp_org_ids) {
                filter.imp_org_ids = imp_org_ids;
                filterChanged = true;
            }
        }
        // set funding org filter
        // expecting array of integers
        if (fund_org_ids) {
            if (fund_org_ids != filter.fund_org_ids) {
                filter.fund_org_ids = fund_org_ids;
                filterChanged = true;
            }
        }
        // set all org filter
        // expecting array of integers
        if (org_ids) {
            if (org_ids != filter.org_ids) {
                filter.org_ids = org_ids;
                filterChanged = true;
            }
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
    activityService.removeDataGroupFilter = function (id) {
        if (id) {
            filter.data_group_ids = _.without(filter.data_group_ids, id);
            // the filter has been updated
            filterUpdated();
        }
    };

    // remove a classification id from filter
    activityService.removeClassificationFilter = function (id) {
        if (id) {
            // loop through each taxonomy filter
            _.each(filter.classification_ids, function (taxonomy_filter) {
                taxonomy_filter.classification_ids = _.without(taxonomy_filter.classification_ids, id);
                //if this was a parent class, also remove all children
                var parent = _.chain(activityService.taxonomies).pluck("classification_ids").flatten().compact().find({ id: id }).value();
                if (parent && parent.children) {
                    taxonomy_filter.classification_ids = _.difference(taxonomy_filter.classification_ids, _(parent.children).pluck("id"));
                }

            });
            // the filter has been updated
            filterUpdated();
        }
    };

    // remove a implmenting org id from filter
    activityService.removeImpOrgFilter = function (id) {
        if (id) {
            filter.imp_org_ids = _.without(filter.imp_org_ids, id);
            var org = _.find(activityService.orgsInUse);
            // the filter has been updated
            filterUpdated();
        }
    };

    // remove a funding org id from filter
    activityService.removeFundOrgFilter = function (id) {
        if (id) {
            filter.fund_org_ids = _.without(filter.fund_org_ids, id);
            // the filter has been updated
            filterUpdated();
        }
    };

    // remove a org id from filter
    activityService.removeOrgFilter = function (id) {
        if (id) {
            filter.org_ids = _.without(filter.org_ids, id);
            // the filter has been updated
            filterUpdated();
        }
    };

    // remove the start date from filter
    activityService.removeStartDateFilter = function () {
        filter.start_date = null;
        // the filter has been updated
        filterUpdated();
    };

    // remove the end date from filter
    activityService.removeEndDateFilter = function () {
        filter.end_date = null;
        // the filter has been updated
        filterUpdated();
    };

    // remove a taxonomy id from filter
    activityService.removeUnassignedTaxonomyFilter = function (id) {
        if (id) {
            filter.unassigned_taxonomy_ids = _.without(filter.unassigned_taxonomy_ids, id);
            // the filter has been updated
            filterUpdated();
        }
    };

    // remove the boundary filter
    activityService.removeBoundaryFilter = function () {
        filter.boundary_filter = null;
        // the filter has been updated
        filterUpdated();
    };

    //remove keyword filter
    activityService.removeKeywordFilter = function () {
        filter.keyword_filter.keyword = null;
        filter.keyword_filter.activity_ids = [];
        // the filter has been updated
        filterUpdated();
    };

    // clear all filters
    activityService.clearFilters = function () {
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
    activityService.hasFilters = function () {
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
    activityService.getSelectedFilters = function () {
        var filters = [];
        // get a comma seperated list of selected classification ids
        var idList = getClassificationIds();
        if (idList) {
            var ids = idList.split(',');
            if (ids.length > 0) {
                // loop through the selected classification ids
                _.each(ids, function (id) {
                    // look up the classification
                    _.each(activityService.taxonomies, function (t) {
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
            _.each(activityService.orgsInUse['implementing'], function (imp_org) {
                if (imp_org.id === i) {
                    // add the organization to the selected features
                    filters.push({ id: imp_org.id, label: imp_org.n, type: "imp" });
                }
            });
        });
        // loop through the selected funding org ids
        _.each(filter.fund_org_ids, function (f) {
            // look up the organzation
            _.each(activityService.orgsInUse['funding'], function (fund_org) {
                if (fund_org.id === f) {
                    filters.push({ id: fund_org.id, label: fund_org.n, type: "fund" });
                }
            });
        });
        // loop through the selected org ids
        _.each(filter.org_ids, function (o) {
            // look up the organzation
            _.each(activityService.orgsInUse['all'], function (org) {
                if (org.id === o) {
                    filters.push({ id: org.id, label: org.n, type: "org" });
                }
            });
        });
        // loop through the selected unassigned taxonomy ids
        _.each(filter.unassigned_taxonomy_ids, function (id) {
            var tax = _.find(activityService.taxonomies, function (t) { return t.taxonomy_id == id; });
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

    // gets the data group filters
    activityService.getDataGroupFilters = function () { return filter.data_group_ids; };

    // gets the classification filters
    activityService.getClassificationFilters = function () {
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
    activityService.getImpOrgFilters = function () { return filter.imp_org_ids; };

    // gets the funding org filters
    activityService.getFundOrgFilters = function () { return filter.fund_org_ids; };

    // gets the org filters
    activityService.getOrgFilters = function () { return filter.org_ids; };

    // gets the start date filter
    activityService.getStartDateFilters = function () { return filter.start_date; };

    // gets the end date filter
    activityService.getEndDateFilters = function () { return filter.end_date; };

    // gets the unassigned taxonomy filters
    activityService.getUnassignedTaxonomyFilters = function () { return filter.unassigned_taxonomy_ids; };

    // gets the boundary filters
    activityService.getBoundaryFilters = function () { return filter.boundary_filter; };

    // gets the keyword filter
    activityService.getKeywordFilters = function () { return filter.keyword_filter; };

    // gets the timestap for the last time the activity list was updated
    activityService.getLastListUpdate = function () { return lastListUpdate; };

    //function to process overview data for UI activity detail
    activityService.processOverview = function (activityData) {
        //taxonomy object
        var overviewDetails = {};
        //data group
        var dataGroupFilter = _.find(stateConfig.tools.map.filters, function (f) { return f.type === 'datasource'; });
        _.each(dataGroupFilter.params.dataSources, function (filter) {
            var dgs = filter.dataGroupIds.split(',');
            if (_.contains(dgs, activityData.data_group_id.toString())) {
                activityData.data_group = filter.label;
            }
        });
        overviewDetails.data_group = activityData.data_group;
        //objective
        overviewDetails.objective = activityData._objective;
        //content
        overviewDetails.content = activityData._content;
        //start_date
        overviewDetails.start_date = activityData._start_date;
        //end_date
        overviewDetails.end_date = activityData._end_date;
        //planned start_date
        overviewDetails.plan_start_date = activityData._plan_start_date;
        //planned end_date
        overviewDetails.plan_end_date = activityData._plan_end_date;
        //tags
        overviewDetails.tags = activityData._tags;

        // get the beneficiaries configuration
        var beneConfig = _.find(config.states, function (states) { return states.route == 'editor'; });
        if (beneConfig && beneConfig.tools && beneConfig.tools.editor.activity.beneficiary) {
            //beneficiaries
            overviewDetails.beneficiary_type = _.chain(beneConfig.tools.editor.activity.beneficiary.beneficiary_type.values).where({ value: activityData.beneficiary_type }).pluck("label").first().value();
            overviewDetails.beneficiary_unit = _.chain(beneConfig.tools.editor.activity.beneficiary.beneficiary_unit.values).where({ value: activityData.beneficiary_unit }).pluck("label").first().value();
            overviewDetails.direct_beneficiaries = activityData.direct_beneficiaries;
            overviewDetails.indirect_beneficiaries = activityData.indirect_beneficiaries;
            overviewDetails.female_individual_direct = activityData.female_individual_direct;
            overviewDetails.female_individual_indirect = activityData.female_individual_indirect;
            overviewDetails.female_hhds_direct = activityData.female_hhds_direct;
            overviewDetails.female_hhds_indirect = activityData.female_hhds_indirect;
            overviewDetails.male_individual_direct = activityData.male_individual_direct;
            overviewDetails.male_individual_indirect = activityData.male_individual_indirect;
            overviewDetails.male_hhds_direct = activityData.male_hhds_direct;
            overviewDetails.male_hhds_indirect = activityData.male_hhds_indirect;
            overviewDetails.institutes_direct = activityData.institutes_direct;
            overviewDetails.institutes_indirect = activityData.institutes_indirect;
        }


        //taxonomy sector category array
        overviewDetails.sector_category = [];
        //taxonomy sector array
        overviewDetails.sector = [];
        //taxonomy activity status array
        overviewDetails.activity_status = [];

        //loop through all taxonomies
        _.each(activityData.taxonomy, function (taxonomy) {
            //sector category
            if (taxonomy.taxonomy == 'Sector Category') {
                overviewDetails.sector_category.push(taxonomy.classification);
            }
            //sector
            else if (taxonomy.taxonomy == 'Sector') {
                overviewDetails.sector.push(taxonomy.classification);
            }
            //activity status
            else if (taxonomy.taxonomy == 'Activity Status') {
                overviewDetails.activity_status.push(taxonomy.classification);
            }
            //version
            else if (taxonomy.taxonomy == 'Version') {
                overviewDetails.version = taxonomy.classification;
            }
        });

        //turn arrays into string lists for UI
        overviewDetails.sector_category = overviewDetails.sector_category.join(', ');
        overviewDetails.sector = overviewDetails.sector.join(', ');
        overviewDetails.activity_status = overviewDetails.activity_status.join(', ');

        //financial amount
        overviewDetails.total_amount = _.reduce((_.pluck(activityData.financials, '_amount')), function (amount, num) { return amount + num; }, 0);

        //currency
        var currencies = [];
        _.each(activityData.financials, function (financial) {
            //loop through taxonomy data
            _.each(financial.taxonomy, function (taxonomy) {

                //currency
                if (taxonomy.taxonomy == 'Currency') {
                    currencies.push(taxonomy._code);
                }
            });
        });
        //if there is a currency, use it
        if (currencies.length > 0) {
            overviewDetails.currency = currencies[0];
        }
        //otherwise default to USD
        else {
            overviewDetails.currency = 'USD';
        }



        //country
        //loop through taxonomy data
        _.each(activityData.taxonomy, function (taxonomy) {
            //country
            if (taxonomy.taxonomy == 'Country') {
                overviewDetails.country = taxonomy.classification;
            }
        });

        //array for additional resources
        overviewDetails.additionalResources = [];
        //if there are supplemental resources, add them
        if (stateConfig.tools.map.supplemental && stateConfig.tools.map.supplemental.length > 0) {
            _.each(stateConfig.tools.map.supplemental, function (s) {
                var foundMatch = false;
                // get all classifications ids for activity
                var classificationIds = [];
                _.each(activityData.taxonomy, function (t) {
                    classificationIds.push(t.classification_id);
                });
                // check if any classifications match
                _.each(classificationIds, function (c) {
                    if (_.contains(s.classification_ids, c)) {
                        foundMatch = true;
                    }
                });
                // check keyword match
                if (foundMatch == false) {
                    //grab fields to query text from
                    _.each(s.keywords.fields, function (f) {
                        var searchArray = activityData[f].toLowerCase();
                        //loop through keywords to see if in array of keyword field
                        _.each(s.keywords.keywords, function (k) {
                            if (searchArray.includes(k.toLowerCase())) {
                                foundMatch = true;
                            }
                        });
                    });
                }
                if (foundMatch) {
                    overviewDetails.additionalResources.push(s);
                }
            });
        }
        return overviewDetails;
    };

    //function to process taxonomies for UI activity detail
    activityService.processTaxonomies = function (activityTaxonomies) {
        //taxonomy object
        var taxonomyDetails = {};
        //taxonomy sector category array
        taxonomyDetails.sector_category = [];
        //taxonomy sector array
        taxonomyDetails.sector = [];
        //taxonomy activity status array
        taxonomyDetails.activity_status = [];
        //taxonomy activity scope array
        taxonomyDetails.activity_scope = [];
        //taxonomy custom fields object
        taxonomyDetails.custom = {};
        //taxonomy count
        taxonomyDetails.taxonomyCount = 0;

        //loop through all taxonomies
        _.each(activityTaxonomies, function (taxonomy) {
            //sector category
            if (taxonomy.taxonomy == 'Sector Category') {
                taxonomyDetails.sector_category.push(taxonomy.classification);
                taxonomyDetails.taxonomyCount += 1;
            }
            //sector
            else if (taxonomy.taxonomy == 'Sector') {
                taxonomyDetails.sector.push(taxonomy.classification);
                taxonomyDetails.taxonomyCount += 1;
            }
            //activity status
            else if (taxonomy.taxonomy == 'Activity Status') {
                taxonomyDetails.activity_status.push(taxonomy.classification);
                taxonomyDetails.taxonomyCount += 1;
            }
            //activity scope
            else if (taxonomy.taxonomy == 'Activity Scope') {
                taxonomyDetails.activity_scope.push(taxonomy.classification);
                taxonomyDetails.taxonomyCount += 1;
            }
            //custom
            else {
                taxonomyDetails.custom[taxonomy.taxonomy] = (typeof taxonomyDetails.custom[taxonomy.taxonomy] != 'undefined' && taxonomyDetails.custom[taxonomy.taxonomy] instanceof Array) ? taxonomyDetails.custom[taxonomy.taxonomy] : [];
                taxonomyDetails.custom[taxonomy.taxonomy].push(taxonomy.classification);
                taxonomyDetails.taxonomyCount += 1;
            }
        });

        //turn arrays into string lists for UI
        taxonomyDetails.sector_category = taxonomyDetails.sector_category.join(', ');
        taxonomyDetails.sector = taxonomyDetails.sector.join(', ');
        taxonomyDetails.activity_status = taxonomyDetails.activity_status.join(', ');
        taxonomyDetails.activity_scope = taxonomyDetails.activity_scope.join(', ');
        taxonomyDetails.custom_taxonomy = {};
        _.reduce(taxonomyDetails.custom, function (tax, value, key) {
            taxonomyDetails.custom_taxonomy[key] = value.join(', ');
            return tax;
        }, {});

        return taxonomyDetails;
    };

    // function to process financial data for UI activity detail
    activityService.processFinancials = function (activityFinancials) {
        //financials array
        var financialDetails = [];

        // loop through all financials
        _.each(activityFinancials, function (financial) {
            //create new financial object
            var financialElement = {};

            //provider
            financialElement.provider = financial.provider;
            //recipient
            financialElement.recipient = financial.recipient;
            //start_date
            financialElement.start_date = financial._start_date;
            //end_date
            financialElement.end_date = financial._end_date;
            // amount
            financialElement.amount = financial._amount;
            //currency defaulted to USD
            financialElement.currency = 'USD';

            //loop through taxonomy data
            _.each(financial.taxonomy, function (taxonomy) {
                //financial type category
                if (taxonomy.taxonomy == 'Finance Type (category)') {
                    financialElement.finance_category = taxonomy.classification;
                }
                //financial type
                if (taxonomy.taxonomy == 'Finance Type') {
                    financialElement.finance_type = taxonomy.classification;
                }
                //transaction type
                if (taxonomy.taxonomy == 'Transaction Type') {
                    financialElement.transaction_type = taxonomy.classification;
                }
                //currency
                if (taxonomy.taxonomy == 'Currency') {
                    financialElement.currency = taxonomy._code;
                }
            });
            // add element to array of financials
            financialDetails.push(financialElement);
        });
        return financialDetails;
    };

    // function to process location data for UI activity detail
    activityService.processLocations = function (activityLocations) {
        //array of locations
        var locationDetails = [];

        _.each(activityLocations, function (location) {
            //create new location object
            var locationElement = {};
            //admin 0
            locationElement.admin0 = location._admin0;
            //admin 1
            locationElement.admin1 = location._admin1;
            //admin 2
            locationElement.admin2 = location._admin2;
            // admin 3
            locationElement.admin3 = location._admin3;

            //loop through taxonomy data
            _.each(location.taxonomy, function (taxonomy) {
                //country
                if (taxonomy.taxonomy == 'Country') {
                    locationElement.country = taxonomy.classification;
                }
                //location type
                if (taxonomy.taxonomy == 'Location Type') {
                    locationElement.location_type = taxonomy.classification;
                }
                //transaction type
                if (taxonomy.taxonomy == 'Location Flag') {
                    locationElement.location_flag = taxonomy.classification;
                }
                //national/local
                if (taxonomy.taxonomy == 'National/Local') {
                    locationElement.national_local = taxonomy.classification;
                }
            });
            // add element to array of financials
            locationDetails.push(locationElement);
        });
        //console.log("processed locations for activity details: ", locationDetails);
        return locationDetails;
    };

    //function to process organization data for UI activity detail
    activityService.processOrganizations = function (activityOrganizations) {
        var organizationDetails = {};
        organizationDetails.implementingOrgs = [];
        organizationDetails.fundingOrgs = [];
        organizationDetails.accountableOrgs = [];
        organizationDetails.organizationCount = 0;
        organizationDetails.fundingPartners = 'no information';

        // group organizations by role
        _.each(activityOrganizations, function (org) {
            if (org.role == 'Implementing') {
                organizationDetails.implementingOrgs.push(org);
                organizationDetails.organizationCount += 1;
            }
            else if (org.role == 'Funding') {
                organizationDetails.fundingOrgs.push(org);
                organizationDetails.organizationCount += 1;
            }
            else if (org.role == 'Accountable') {
                organizationDetails.accountableOrgs.push(org);
                organizationDetails.organizationCount += 1;
            }
        });

        //funding partner string to be used in overview stats
        if (organizationDetails.fundingOrgs.length > 0) {
            organizationDetails.fundingPartners = '';
            _.each(organizationDetails.fundingOrgs, function (org) {
                organizationDetails.fundingPartners = organizationDetails.fundingPartners + ' ' + org.organization;
            })
        }

        return organizationDetails;
    }

    //export activity list
    activityService.exportActivityList = function (data) {
        var deferred = $q.defer();

        // download csv
        partnerLinkService.JSONToCSVConvertor(data, 'activity_list', false, function () {
            deferred.resolve(data);
        });
    }

    // the activity service filter has been updated
    function filterUpdated() {
        // broadcast that the filter has changed
        $rootScope.$broadcast('activity-filter-update');
        activityService.getActivities();
    }

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

    // private function to process activities in a parent/child structure
    function processActivities(activities) {
        var setAllActivities = !activities;
        activities = activities || activityService.allActivities;
        var activityList = activities.slice(0, activities.length);
        var parentActivities = {};
        var childActivities = activities.slice(0, activities.length);

        _.each(activityList, function (activity, index) {
            // grab all of the parent ids
            if (!activity.response.pid) {
                var dataGroupFilter = _.find(stateConfig.tools.map.filters, function (f) { return f.type === 'datasource'; });
                _.each(dataGroupFilter.params.dataSources, function (filter) {
                    var dgs = filter.dataGroupIds.split(',');
                    if (_.contains(dgs, activity.response.dgid.toString())) {
                        activity.response.dg = filter.label;
                    }
                });
                // add active filter and set to false
                activity.active = false;
                // add arrow property
                activity.arrow = (activity.active) ? "keyboard_arrow_up" : "keyboard_arrow_down";
                parentActivities[activity.response.id] = activity;
                // remove activity from activityList
                childActivities.splice(childActivities.indexOf(activity), 1);
                // add default USD
                activity.response.currency = 'USD';
            }
        });
        //add all of the children ids to the parent ids
        _.each(childActivities, function (activity) {
            //check if there is a parent activity that hasn't been filtered
            if (parentActivities[activity.response.pid]) {
                if (!(parentActivities[activity.response.pid].response.childActivities)) {
                    //add array if doesn't exist
                    parentActivities[activity.response.pid].response.childActivities = [];
                }
                // add child activity to array
                parentActivities[activity.response.pid].response.childActivities.push(activity);
            }
        });
        var fA = [];
        _(parentActivities).each(function (value, elm) { fA.push(value); });
        if(setAllActivities){
            activityService.allActivities = fA;
            activityService.activityCount = activityService.allActivities.length;
        }

        return fA;
    }

    return activityService;


});