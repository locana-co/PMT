/***************************************************************
 * Editor Service
 * Service to support editor module.
* *************************************************************/

angular.module('PMTViewer').service('editorService', function ($q, $http, $rootScope, $state, $stateParams, config, pmt, utilService, mapService, stateService) {

    // the editor service model
    var editorService = {};


    // internal editor service attributes
    var service = {
        activity: {
            errors: []
        }, // activity in edit mode
        activities: null, // all activities
        contacts: [], // all contacts
        taxonomies: {}, // taxonomy options
        activityModelId: null, //used to create a new activity
        financialTaxonomies: {}, // taxonomy options for financial records
        statusTaxonomy: [], // activity status taxonomy
        orgLists: {
            funding: [],
            implementing: [],
            accountable: [],
            inuse: [],
            all: []
        }, // list of organizations
        boundaries: {
            admin0: {
                edit: null,
                highlight: null,
                select: null
            },
            admin1: {
                edit: null,
                highlight: null,
                select: null
            },
            admin2: {
                edit: null,
                highlight: null,
                select: null
            },
            admin3: {
                edit: null,
                highlight: null,
                select: null
            },
            aliases: {
                edit: [],
                highlight: [],
                select: []
            },
            menu: null
        }, // list of location boundaries
        forms: {
            activityForm: {
                error: false,
                validated: false,
                message: null
            },
            taxonomyForm: {
                error: false,
                validated: false
            },
            financialForm: {
                error: false,
                validated: false,
                message: null
            },
            subFinancialForm: {
                error: false,
                validated: false,
                message: null
            },
            orgForm: {
                error: false,
                validated: false,
                message: null
            },
            contactForm: {
                error: false,
                validated: false,
                message: null
            },
            locationForm: {
                error: false,
                validated: false,
                message: null
            },
            detailForm: {
                error: false,
                validated: false,
                message: null
            },
            childForm: {
                error: false,
                validated: false,
                message: null
            }
        }, // forms used to edit elements of the activity record
        lastEdit: null // timestamp of last saved edit
    };

    // get the state configuration for the locations state
    var stateConfig = _.find(config.states, function (states) { return states.route == 'editor'; });

    // getters
    editorService.getCurrentActivity = function () { return service.activity; };
    editorService.getAllActivities = function () { return service.activities; };
    editorService.getActivityId = function () { return service.activity.id; };
    editorService.getTaxonomies = function (isChild) {
        if (!isChild) {
            return service.taxonomies;
        } else {
            return _(service.taxonomies).where({ childEditing: true });
        }
    };
    editorService.getFinancialTaxonomies = function () { return service.financialTaxonomies; };
    editorService.getStatusTaxonomy = function () { return service.statusTaxonomy; };
    editorService.getFundingOrgs = function () { return service.orgLists.funding; };
    editorService.getImplementingOrgs = function () { return service.orgLists.implementing; };
    editorService.getAccountableOrgs = function () { return service.orgLists.accountable; };
    editorService.getInUse = function () { return service.orgLists.inuse; };
    editorService.getAllOrgs = function () { return service.orgLists.all; };
    editorService.getAllContacts = function () { return service.contacts; };
    editorService.getBoundaryMenu = function () { return service.boundaries.menu; };
    editorService.getForms = function () { return service.forms; };
    editorService.getLastEdit = function () { return service.lastEdit; };

    // get a single id of a record to use as our model when creating new projects 
    editorService.getModelActivityId = function () {
        var deferred = $q.defer();
        var options = {
            data_group_ids: stateConfig.tools.editor.datagroups[0].data_group_id.toString(),
            pmtId: pmt.id[pmt.env]
        };
        var header = {
            headers: { Authorization: 'Bearer ' + $rootScope.currentUser.token }
        };
        // call the api to get single id to be used as example when creating a new project
        $http.post(pmt.api[pmt.env] + 'pmt_get_valid_id', options, header).success(function (data, status, headers, config) {
            var response = data[0].response;

            if (response.id) {
                // the record was found successfully
                service.activityModelId = response.id;
                deferred.resolve();
            }
            else {
                // there was an error getting the id
                service.activity.errors.push({ "record": "activity", "id": null, "message": "error in retrieving valid activity id" });
                deferred.reject();
            }
        }).error(function (data, status, headers, c) {
            service.activity.errors.push({ "record": "activity", "id": financial_id, "message": status });
            deferred.reject(status);
        });
        return deferred.promise;
    };

    // gets and returns all activities
    editorService.getActivities = function (data_group_ids, activity_ids) {
        var deferred = $q.defer();
        var ids = activity_ids !== null ? activity_ids.join(",") : null;
        var options = {
            data_group_ids: data_group_ids.join(","),
            only_active: false,
            pmtId: pmt.id[pmt.env]
        };
        var header = {
            headers: { Authorization: 'Bearer ' + $rootScope.currentUser.token }
        };
        // call the api to get the pmt data
        $http.post(pmt.api[pmt.env] + 'pmt_activities_all', options, header).success(function (data, status, headers, config) {
            var activities = [];
            // loop through data and remove the response object
            _.each(data, function (a) {
                activities.push(a.response);
            });
            service.activities = _.sortBy(activities, 't');;
            // broadcast that editable activity list is updated
            $rootScope.$broadcast('editor-list-updated');
            deferred.resolve(service.activities);
        }).error(function (data, status, headers, c) {
            // there was an error report it to the error handler
            console.log("error on api call to: pmt_activity");
            deferred.reject(status);
        });

        return deferred.promise;
    };

    // gets and returns activity details
    editorService.getActivity = function (id) {
        var deferred = $q.defer();
        var options = {
            id: id,
            pmtId: pmt.id[pmt.env]
        };
        var header = {
            headers: { Authorization: 'Bearer ' + $rootScope.currentUser.token }
        };
        // call the api to get the pmt data by boundary points
        $http.post(pmt.api[pmt.env] + 'pmt_activity_detail', options, header).success(function (data, status, headers, config) {
            if (data.length > 0) {
                // remove response object
                var activity = data[0].response;
                service.activity = activity;
                clearTaxonomies();
                setBoundries().then(function () {
                    processActivity();
                    setTaxonomies();
                    setFinancialTaxonomies();
                    setLocations();
                    $rootScope.$broadcast('editor-activity-loaded');
                    deferred.resolve(service.activity);
                }, function () {
                    deferred.reject("Boundaries did not load and are required for the activity.");
                });
            }
            else {
                deferred.reject("Activity does not exist");
            }
        }).error(function (data, status, headers, c) {
            // there was an error report it to the error handler
            console.log("error on api call to: pmt_activity_detail");
            deferred.reject(status);
        });
        return deferred.promise;
    };

    // creates a new activity detail record
    editorService.createActivity = function () {
        var deferred = $q.defer();
        //use stored model id
        editorService.getActivity(service.activityModelId).then(function (activity) {
            if (activity) {
                // clear activity object of data
                _.each(_.keys(activity), function (key) {
                    activity[key] = null;
                });
                clearTaxonomies();
                setBoundries().then(function () {
                    processActivity();
                    setTaxonomies();
                    setFinancialTaxonomies();
                    setLocations();
                    $rootScope.$broadcast('editor-activity-loaded');
                    deferred.resolve(service.activity);
                }, function () {
                    deferred.reject("Boundaries did not load and are required for the activity.");
                });
            }
            //console.log("Activity to clear:", activity);
            deferred.resolve(activity.id);
        });

        return deferred.promise;
    };

    // save activity
    editorService.saveActivity = function () {
        var deferred = $q.defer();
        if (editorService.formsValid()) {
            // add/reset errors for activity
            service.activity.errors = [];
            // call function to save activity and related records
            saveActivity().then(function (id) {
                // new activity
                if (service.activity.id === null) {
                    service.activity.id = id;
                    stateService.setParamWithVal('editor_activity_id', service.activity.id);
                    if ($rootScope.currentUser.user.authorizations) { $rootScope.currentUser.user.authorizations.push(id); }
                }
                // chain all the saving promises
                var saveAll = $q.all([
                    saveTaxonomies(),
                    saveFinancials(),
                    saveParticipation(),
                    saveContacts(),
                    saveLocations(),
                    saveChildren(),
                    saveDetails()
                ]);
                saveAll.then(function (values) {
                    // record the date/time of last edit
                    service.lastEdit = + new Date();
                    deferred.resolve(service.activity);
                }).catch(function (ex) {
                    deferred.resolve(service.activity);
                });
            }, function (message) {
                deferred.reject("Whoops! There was an error while saving the record. Please contact the administrator with this " + message.replace(/Error/, 'message'));
            });
        }
        else {
            if (!editorService.validateForms()) {
                deferred.reject("It appears that you may have forgotten to provide some information or there's an error on your form. Please review and ensure everything is correct.");
            }
        }
        return deferred.promise;

    };

    // cancel activity
    editorService.cancelActivity = function () {
        var deferred = $q.defer();

        deferred.resolve(service.activity);

        return deferred.promise;
    };

    // delete activity
    editorService.deleteActivity = function () {
        var deferred = $q.defer();
        var options = {
            instance_id: pmt.instance,
            user_id: $rootScope.currentUser.user.id,
            activity_id: service.activity.id,
            data_group_id: null,
            key_value_data: null,
            delete_record: true,
            pmtId: pmt.id[pmt.env]
        };
        var header = {
            headers: { Authorization: 'Bearer ' + $rootScope.currentUser.token }
        };
        // call the api
        $http.post(pmt.api[pmt.env] + 'pmt_edit_activity', options, header).success(function (data, status, headers, config) {
            deferred.resolve(data[0].response);
            //console.log('activity deleted:', data);
        }).error(function (data, status, headers, c) {
            // there was an error report it to the error handler
            console.log("error on api call to: ", data);
            deferred.reject(status);
        });
        return deferred.promise;
    };

    // gets and returns list of classifications for a taxonomy
    editorService.getTaxonomy = function (taxonomy) {
        var deferred = $q.defer();
        var options = {
            taxonomy_id: taxonomy.taxonomy_id, // taxonomy id
            data_group_ids: null, // return in-use classifications for data groups listed, otherwise all classifications
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
                    if (taxonomy.filter.length > 0) {
                        if (_.contains(taxonomy.filter, classification.id)) {
                            _.extend(classification, { active: false });
                            classifications.push(classification);
                        }
                    }
                    else {
                        _.extend(classification, { active: false });
                        classifications.push(classification);
                    }
                });
                classifications = classifications.sort(utilService.dynamicSort("c"));
                // remove taxonomy from the service
                service.taxonomies = _.reject(service.taxonomies, function (t) { return t.taxonomy_id === taxonomy.taxonomy_id; });
                // add updated taxonomy to the service
                taxonomy.classifications = classifications;
                service.taxonomies.push(taxonomy);
                setTaxonomies();
                deferred.resolve(taxonomy);
            })
            .error(function (data, status, headers, c) {
                // there was an error report it to the error handler
                console.log("error on api call to: pmt_classifications");
                deferred.reject(status);
            });
        return deferred.promise;
    };

    // gets and returns a list of in-use organizations
    // type: funding, implementing, accountable, inuse or all
    editorService.getInUseOrgs = function (data_group_ids, org_role_ids, type) {
        var deferred = $q.defer();
        var options = {
            data_group_ids: data_group_ids,
            org_role_ids: org_role_ids || null,
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
            service.orgLists[type] = [];
            service.orgLists[type] = orgs;
            // return the orgs
            deferred.resolve(orgs);
        }).error(function (data, status, headers, c) {
            // there was an error report it to the error handler
            console.log("error on api call to: pmt_org_inuse");
            deferred.reject(status);
        });
        return deferred.promise;
    };

    // gets and returns a list of contacts
    // all available for the current activity 
    editorService.getContacts = function () {
        var deferred = $q.defer();
        var options = {
            data_group_ids: null,
            pmtId: pmt.id[pmt.env]
        };
        var header = {
            headers: { Authorization: 'Bearer ' + $rootScope.currentUser.token }
        };
        // call the api to get the organizations
        $http.post(pmt.api[pmt.env] + 'pmt_contacts', options, header, { cache: true }).success(function (data, status, headers, config) {
            // remove unneccessary response object from api
            var contacts = _.pluck(data, 'response');
            //transform data to match the contact data model.

            service.contacts = contacts;
            // return the orgs
            deferred.resolve(contacts);
        }).error(function (data, status, headers, c) {
            // there was an error report it to the error handler
            console.log("error on api call to: pmt_contacts");
            deferred.reject(status);
        });
        return deferred.promise;
    };

    // get boundary menu (hierarchy)
    editorService.getBoundaryHierarchy = function (boundary_type, admin_levels, filter_features, data_group_ids) {
        var deferred = $q.defer();
        var options = {
            boundary_type: boundary_type, // Required. the boundary type for the created hierarchy. Options: gaul, gadm, unocha, nbs.
            admin_levels: admin_levels, // a comma delimited list of admin levels to include. Options: 0,1,2,3 
            filter_features: filter_features, //a comma delimited list of names of features in the highest admin level to restrict data to.
            data_group_ids: data_group_ids, // a comma delimited list of data groups to filter features to, only features with a data group's locaiton will be included
            pmtId: pmt.id[pmt.env]
        };
        var header = {
            headers: { Authorization: 'Bearer ' + $rootScope.currentUser.token }
        };

        $http.post(pmt.api[pmt.env] + 'pmt_boundary_hierarchy', options, header, { cache: true })
            .success(function (data, status, headers, config) {
                // remove unneccessary response object from api
                var response = _.pluck(data, 'response');
                _.each(response[0].boundaries, function (admin1) {
                    _.extend(admin1, { active: true, selected: false });
                    if (admin1.b) {
                        _.each(admin1.b, function (admin2) {
                            _.extend(admin2, { active: true, selected: false });
                            if (admin2.b) {
                                _.each(admin2.b, function (admin3) {
                                    _.extend(admin3, { active: true, selected: false });
                                });
                            }
                        });
                    }
                });
                service.boundaries.menu = response[0];
                // console.log('pmt_boundary_hierarchy:', response[0]);
                deferred.resolve(response[0]);
            })
            .error(function (data, status, headers, c) {
                // there was an error report it to the error handler
                console.log("error on api call to: pmt_boundary_hierarchy");
                deferred.reject(status);
            });
        return deferred.promise;
    };

    // gets and returns list of classifications for a taxonomy
    editorService.getFinancialTaxonomy = function (taxonomy) {
        var deferred = $q.defer();
        var options = {
            taxonomy_id: taxonomy.taxonomy_id, // taxonomy id
            data_group_ids: null, // return in-use classifications for data groups listed, otherwise all classifications
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
                    if (taxonomy.filter.length > 0) {
                        if (_.contains(taxonomy.filter, classification.id)) {
                            _.extend(classification, { active: false });
                            classifications.push(classification);
                        }
                    }
                    else {
                        _.extend(classification, { active: false });
                        classifications.push(classification);
                    }
                });
                classifications = classifications.sort(utilService.dynamicSort("c"));
                // remove taxonomy from the service
                service.financialTaxonomies = _.reject(service.financialTaxonomies, function (t) { return t.taxonomy_id === taxonomy.taxonomy_id; });
                // add updated taxonomy to the service
                taxonomy.classifications = classifications;
                service.financialTaxonomies.push(taxonomy);
                setFinancialTaxonomies();
                deferred.resolve(taxonomy);
            })
            .error(function (data, status, headers, c) {
                // there was an error report it to the error handler
                console.log("error on api call to: pmt_classifications");
                deferred.reject(status);
            });
        return deferred.promise;
    };

    // validate users authority to edit activity
    editorService.validateAuthorization = function (activity_id, data_group_id, auth_type) {
        var deferred = $q.defer();
        var options = {
            instance_id: pmt.instance,
            user_id: $rootScope.currentUser.user.id,
            activity_id: activity_id,
            data_group_id: data_group_id,
            auth_type: auth_type,
            pmtId: pmt.id[pmt.env]
        };
        var header = {
            headers: { Authorization: 'Bearer ' + $rootScope.currentUser.token }
        };
        // call the api to get the pmt data by boundary points
        $http.post(pmt.api[pmt.env] + 'pmt_validate_user_authority', options, header)
            .success(function (data, status, headers, config) {
                deferred.resolve(data);
                // console.log('pmt_validate_user_authority:', data);
            })
            .error(function (data, status, headers, c) {
                // there was an error report it to the error handler
                console.log("error on api call to: pmt_activity");
                deferred.reject(status);
            });
        return deferred.promise;
    };

    // add selection feature
    editorService.selectFeature = function (admin_level) {
        var layers = [];
        var param = null;
        var filters = [];
        if ($stateParams.layers !== '') {
            layers = $stateParams.layers.split(',');
        }
        layers.push(service.boundaries[admin_level].select.alias);
        $stateParams.layers = layers.join();
        // update parameters        
        stateService.setState($state.current.name || 'home', $stateParams, false);
    };

    // toggle highlight on boundary feature
    editorService.toggleHighlight = function (location) {
        var layers = [];
        var filters = [];
        if ($stateParams.layers !== '') {
            layers = $stateParams.layers.split(',');
        }
        switch (location._admin_level) {
            case 1:
                // feature is highlighted, remove
                if (_.contains(service.boundaries.admin1.highlight.filter, location.feature_id)) {
                    service.boundaries.admin1.highlight.filter = _.without(service.boundaries.admin1.highlight.filter, location.feature_id);
                    if (service.boundaries.admin1.highlight.filter.length === 0) {
                        layers = _.without(layers, service.boundaries.admin1.highlight.alias);
                    }
                    else {
                        // force the map to redraw
                        mapService.forceRedraw();
                    }
                }
                // feature is not hightlighted, add
                else {
                    service.boundaries.admin1.highlight.filter.push(location.feature_id);
                    // add the layer to the map if it is not there
                    if (!_.contains(layers, service.boundaries.admin1.highlight.alias)) {
                        layers.push(service.boundaries.admin1.highlight.alias);
                    }
                    else {
                        // force the map to redraw
                        mapService.forceRedraw();
                    }
                }
                filters = service.boundaries.admin1.highlight.filter;
                break;
            case 2:
                // feature is highlighted, remove
                if (_.contains(service.boundaries.admin2.highlight.filter, location.feature_id)) {
                    service.boundaries.admin2.highlight.filter = _.without(service.boundaries.admin2.highlight.filter, location.feature_id);
                    if (service.boundaries.admin2.highlight.filter.length === 0) {
                        layers = _.without(layers, service.boundaries.admin2.highlight.alias);
                    }
                    else {
                        // force the map to redraw
                        mapService.forceRedraw();
                    }
                }
                // feature is not hightlighted, add
                else {
                    service.boundaries.admin2.highlight.filter.push(location.feature_id);
                    // add the layer to the map if it is not there
                    if (!_.contains(layers, service.boundaries.admin2.highlight.alias)) {
                        layers.push(service.boundaries.admin2.highlight.alias);
                    }
                    else {
                        // force the map to redraw
                        mapService.forceRedraw();
                    }
                }
                filters = service.boundaries.admin2.highlight.filter;
                break;
            case 3:
                // feature is highlighted, remove
                if (_.contains(service.boundaries.admin3.highlight.filter, location.feature_id)) {
                    service.boundaries.admin3.highlight.filter = _.without(service.boundaries.admin3.highlight.filter, location.feature_id);
                    if (service.boundaries.admin3.highlight.filter.length === 0) {
                        layers = _.without(layers, service.boundaries.admin3.highlight.alias);
                    }
                    else {
                        // force the map to redraw
                        mapService.forceRedraw();
                    }
                }
                // feature is not hightlighted, add
                else {
                    service.boundaries.admin3.highlight.filter.push(location.feature_id);
                    // add the layer to the map if it is not there
                    if (!_.contains(layers, service.boundaries.admin3.highlight.alias)) {
                        layers.push(service.boundaries.admin3.highlight.alias);
                    }
                    else {
                        // force the map to redraw
                        mapService.forceRedraw();
                    }
                }
                filters = service.boundaries.admin3.highlight.filter;
                break;
        }
        $stateParams.layers = layers.join();
        // update parameters        
        stateService.setState($state.current.name || 'home', $stateParams, false);
        return filters;
    };

    // remove a feature from a boundary
    editorService.removeFeature = function (location) {
        var layers = [];
        var filters = [];
        var forceRedraw = false;
        if ($stateParams.layers !== '') {
            layers = $stateParams.layers.split(',');
        }
        switch (location._admin_level) {
            case 0:
                layers = _.without(layers, service.boundaries.admin0.edit.alias);
                break;
            case 1:
                // edit feature exits, remove
                if (_.contains(service.boundaries.admin1.edit.filter, location.feature_id)) {
                    service.boundaries.admin1.edit.filter = _.without(service.boundaries.admin1.edit.filter, location.feature_id);
                    // remove the boundary if it is empty
                    if (service.boundaries.admin1.edit.filter.length === 0) {
                        layers = _.without(layers, service.boundaries.admin1.edit.alias);
                    }
                    else {
                        forceRedraw = true;
                    }
                }
                // highlight feature exits, remove
                if (_.contains(service.boundaries.admin1.highlight.filter, location.feature_id)) {
                    service.boundaries.admin1.highlight.filter = _.without(service.boundaries.admin1.highlight.filter, location.feature_id);
                    // remove the boundary if it is empty
                    if (service.boundaries.admin1.highlight.filter.length === 0) {
                        layers = _.without(layers, service.boundaries.admin1.highlight.alias);
                    }
                    else {
                        forceRedraw = true;
                    }
                }
                break;
            case 2:
                // edit feature exits, remove
                if (_.contains(service.boundaries.admin2.edit.filter, location.feature_id)) {
                    service.boundaries.admin2.edit.filter = _.without(service.boundaries.admin2.edit.filter, location.feature_id);
                    // remove the boundary if it is empty
                    if (service.boundaries.admin2.edit.filter.length === 0) {
                        layers = _.without(layers, service.boundaries.admin2.edit.alias);
                    }
                    else {
                        forceRedraw = true;
                    }
                }
                // highlight feature exits, remove
                if (_.contains(service.boundaries.admin2.highlight.filter, location.feature_id)) {
                    service.boundaries.admin2.highlight.filter = _.without(service.boundaries.admin2.highlight.filter, location.feature_id);
                    // remove the boundary if it is empty
                    if (service.boundaries.admin2.highlight.filter.length === 0) {
                        layers = _.without(layers, service.boundaries.admin2.highlight.alias);
                    }
                    else {
                        forceRedraw = true;
                    }
                }
                break;
            case 3:
                // edit feature exits, remove
                if (_.contains(service.boundaries.admin3.edit.filter, location.feature_id)) {
                    service.boundaries.admin3.edit.filter = _.without(service.boundaries.admin3.edit.filter, location.feature_id);
                    // remove the boundary if it is empty
                    if (service.boundaries.admin3.edit.filter.length === 0) {
                        layers = _.without(layers, service.boundaries.admin3.edit.alias);
                    }
                    else {
                        forceRedraw = true;
                    }
                }
                // highlight feature exits, remove
                if (_.contains(service.boundaries.admin3.highlight.filter, location.feature_id)) {
                    service.boundaries.admin3.highlight.filter = _.without(service.boundaries.admin3.highlight.filter, location.feature_id);
                    // remove the boundary if it is empty
                    if (service.boundaries.admin3.highlight.filter.length === 0) {
                        layers = _.without(layers, service.boundaries.admin3.highlight.alias);
                    }
                    else {
                        forceRedraw = true;
                    }
                }
                break;
        }
        $stateParams.layers = layers.join();
        // update parameters        
        stateService.setState($state.current.name || 'home', $stateParams, false);
        if (forceRedraw) {
            // force the map to redraw
            mapService.forceRedraw();
        }
    };

    // remove all features from all boundaries
    editorService.removeFeatures = function () {
        var layers = [];
        if ($stateParams.layers !== '') {
            layers = $stateParams.layers.split(',');
        }
        // remove all admin edit layers levels 1-3
        service.boundaries.admin1.edit.filter = [];
        service.boundaries.admin2.edit.filter = [];
        service.boundaries.admin3.edit.filter = [];
        layers = _.without(layers, service.boundaries.admin1.edit.alias);
        layers = _.without(layers, service.boundaries.admin2.edit.alias);
        layers = _.without(layers, service.boundaries.admin3.edit.alias);
        // remove all admin highlight layers levels 1-3
        service.boundaries.admin1.highlight.filter = [];
        service.boundaries.admin2.highlight.filter = [];
        service.boundaries.admin3.highlight.filter = [];
        layers = _.without(layers, service.boundaries.admin1.highlight.alias);
        layers = _.without(layers, service.boundaries.admin2.highlight.alias);
        layers = _.without(layers, service.boundaries.admin3.highlight.alias);
        // update parameters 
        $stateParams.layers = layers.join();
        stateService.setState($state.current.name || 'home', $stateParams, false);
    };

    // add a feature to a boundary
    editorService.addFeatures = function (locations, admin_level) {
        // get the current list of layers on the map
        var layers = [];
        if ($stateParams.layers !== '') {
            layers = $stateParams.layers.split(',');
        }
        var locationIds = _.pluck(locations, 'feature_id');
        var filter = [];
        switch (admin_level) {
            case 0:
                // the boundary is not on the map
                if (!_.contains(layers, service.boundaries.admin0.edit.alias)) {
                    layers.push(service.boundaries.admin0.edit.alias);
                }
                break;
            case 1:
                // get the new list of features for the boundary
                filter = _.union(service.boundaries.admin1.edit.filter, locationIds);
                // the boundary is not on the map
                if (!_.contains(layers, service.boundaries.admin1.edit.alias)) {
                    // there are features to display
                    if (filter.length > 0) {
                        service.boundaries.admin1.edit.filter = filter;
                        layers.push(service.boundaries.admin1.edit.alias);
                    }
                }
                // boundary is already on the map
                else {
                    // there are features to display
                    if (filter.length > 0) {
                        service.boundaries.admin1.edit.filter = filter;
                        // force the map to redraw
                        mapService.forceRedraw();
                    }
                    else {
                        layers = _.without(layers, service.boundaries.admin1.edit.alias);
                    }
                }
                break;
            case 2:
                // get the new list of features for the boundary
                filter = _.union(service.boundaries.admin2.edit.filter, locationIds);
                // the boundary is not on the map
                if (!_.contains(layers, service.boundaries.admin2.edit.alias)) {
                    // there are features to display
                    if (filter.length > 0) {
                        service.boundaries.admin2.edit.filter = filter;
                        layers.push(service.boundaries.admin2.edit.alias);
                    }
                }
                // boundary is already on the map
                else {
                    // there are features to display
                    if (filter.length > 0) {
                        service.boundaries.admin2.edit.filter = filter;
                        // force the map to redraw
                        mapService.forceRedraw();
                    }
                    else {
                        layers = _.without(layers, service.boundaries.admin2.edit.alias);
                    }
                }
                break;
            case 3:
                // get the new list of features for the boundary
                filter = _.union(service.boundaries.admin3.edit.filter, locationIds);
                // the boundary is not on the map
                if (!_.contains(layers, service.boundaries.admin3.edit.alias)) {
                    // there are features to display
                    if (filter.length > 0) {
                        service.boundaries.admin3.edit.filter = filter;
                        layers.push(service.boundaries.admin3.edit.alias);
                    }
                }
                // boundary is already on the map
                else {
                    // there are features to display
                    if (filter.length > 0) {
                        service.boundaries.admin3.edit.filter = filter;
                        // force the map to redraw
                        mapService.forceRedraw();
                    }
                    else {
                        layers = _.without(layers, service.boundaries.admin3.edit.alias);
                    }
                }
                break;
        }
        $stateParams.layers = layers.join();
        // update parameters        
        stateService.setState($state.current.name || 'home', $stateParams, false);
    };

    // clear & remove the highlight layers from the map
    editorService.clearHighlights = function () {
        // remove the layers from the map
        var layers = [];
        if ($stateParams.layers !== '') {
            layers = $stateParams.layers.split(',');
        }
        layers = _.difference(layers, service.boundaries.aliases.highlight);
        // clear each boundaries highlight layer
        _.each(service.boundaries, function (boundary) {
            if (_.has(boundary, 'highlight')) {
                if (_.has(boundary.highlight, 'filter')) {
                    boundary.highlight.filter = [];
                }
            }
        });
        // update the url minus the highlight layers
        $stateParams.layers = layers.join();
        // update parameters        
        stateService.setState($state.current.name || 'home', $stateParams, false);
    };

    // clear & remove the edit layers from the map
    editorService.clearEdits = function () {
        // remove the layers from the map
        var layers = [];
        if ($stateParams.layers !== '') {
            layers = $stateParams.layers.split(',');
        }
        layers = _.difference(layers, service.boundaries.aliases.edit);
        // clear each boundaries edit layer
        _.each(_.omit(service.boundaries, 'admin0'), function (boundary) {
            if (_.has(boundary, 'edit')) {
                if (_.has(boundary.edit, 'filter')) {
                    boundary.edit.filter = [];
                }
            }
        });
        // update the url minus the edit layers
        $stateParams.layers = layers.join();
        // update parameters        
        stateService.setState($state.current.name || 'home', $stateParams, false);
    };

    // validate forms used to edit the activity record
    editorService.validateForms = function () {
        var isValid = true;
        // validate activity form
        if (!validateActivityForm()) { isValid = false; }
        // validate taxonomy form
        if (!validateTaxonomyForm()) { isValid = false; }
        // validate financial form - ignore on child activity
        if ((!stateService.isParam('editor_parent_id') || !stateService.getState().editor_parent_id) && !validateFinancialForm()) { isValid = false; }
        // validate organization form
        if (!validateOrgForm()) { isValid = false; }
        // validate contact form - ignore on child activity
        if ((!stateService.isParam('editor_parent_id') || !stateService.getState().editor_parent_id) && !validateContactForm()) { isValid = false; }
        // validate child form - ignore on child activity
        if ((!stateService.isParam('editor_parent_id') || !stateService.getState().editor_parent_id) && !validateChildForm()) { isValid = false; }
        // validate location form
        if (!validateLocationForm()) { isValid = false; }
        // validate details form - only on child activity
        if ((stateService.isParam('editor_parent_id') && stateService.getState().editor_parent_id) && !validateDetailsForm()) { isValid = false; }

        return isValid;
    };

    // t/f are all forms validated without errors
    editorService.formsValid = function () {
        // loop through the forms and check if they have been checked (validated)
        // and if they have any errors
        _.each(service.forms, function (form) {
            if (!form.validated || form.error) {
                return false;
            }
        });
        return true;
    };

    // clear forms
    editorService.clearForms = function () {
        _.each(service.forms, function (form) {
            form.validated = false;
            form.error = false;
            if (_.has(form, 'message')) {
                form.message = null;
            }
        });
    };


    // check all forms to see if any have edits
    editorService.isDirty = function () {
        // activate loader
        var dirty = false;
        _(this.getForms()).each(function (f) {
            if (f.form && f.form.length > 0 && !f.form.hasClass('ng-pristine')) { dirty = true; }
        });

        return dirty;
    }

    // private function to set boundary layers for locations
    function setBoundries() {
        var deferred = $q.defer();
        _.each(stateConfig.tools.map.supportingLayers, function (b) {
            if (b.admin_level || b.admin_level === 0) {
                switch (b.admin_level) {
                    case 0:
                        service.boundaries.admin0[b.function] = b;
                        break;
                    case 1:
                        service.boundaries.admin1[b.function] = b;
                        break;
                    case 2:
                        service.boundaries.admin2[b.function] = b;
                        break;
                    case 3:
                        service.boundaries.admin3[b.function] = b;
                        break;
                }
                service.boundaries.aliases[b.function].push(b.alias);
            }
        });
        deferred.resolve();
        return deferred.promise;
    }

    // private function to process activity for editing
    function processActivity() {
        // convert strings to dates
        service.activity._start_date = service.activity._start_date ? utilService.parseDateString(service.activity._start_date) : null;
        service.activity._end_date = service.activity._end_date ? utilService.parseDateString(service.activity._end_date) : null;
        // loop through financial records
        _.each(service.activity.financials, function (f) {
            // convert strings to dates
            f._end_date = f._end_date ? utilService.parseDateString(f._end_date) : null;
            f._start_date = f._start_date ? utilService.parseDateString(f._start_date) : null;
            // sort taxonomies
            f.taxonomy = _.sortBy(f.taxonomy, 'taxonomy_id');
            // add delete parameter to each record
            _.extend(f, { delete: false });
        });
        // loop through detail records
        _.each(service.activity.details, function (d) {
            // sort taxonomies
            d.details = _.sortBy(d.details, '_title');
            // add delete parameter to each record
            _.extend(d, { delete: false });
        });
        service.activity.contacts = service.activity.contacts || [];
        // loop through contact records
        _.each(service.activity.contacts, function (c) {
            // add delete parameter to each record
            _.extend(c, { delete: false });
        });

        // add delete parameter to each record
        service.activity.children = _(service.activity.children).map(function (c) {
            c.delete = false;
            return c;
        });
        // group locations
        var locations = {
            national: [],
            admin1: [],
            admin2: [],
            admin3: []
        };
        // loop through location records
        _.each(service.activity.locations, function (l) {
            // add delete & highlight parameter to each record
            _.extend(l, { delete: false, highlight: false });
            switch (l._admin_level) {
                case 0:
                    locations.national.push(l);
                    break;
                case 1:
                    locations.admin1.push(l);
                    break;
                case 2:
                    locations.admin2.push(l);
                    break;
                case 3:
                    locations.admin3.push(l);
                    break;
                default:
                    break;
            }
        });
        service.activity.locations = locations;
        // loop through participation records
        _.each(service.activity.organizations, function (o) {
            // add delete parameter to each record
            _.extend(o, { delete: false });
            if (o.imp_type_id) {
                o.isPrimary = true;
            }
        });
        // order the organizations
        service.activity.organizations = _.sortBy(service.activity.organizations, 'classification');
        // set status from Activity Status taxonomy
        var status = _.find(service.activity.taxonomy, function (t) { return t.taxonomy == 'Activity Status' });
        service.activity.status = status ? status.classification_id.toString() : null;
        // format dates
        service.activity._updated_date = utilService.formatShortDate(service.activity._updated_date);
        service.activity._created_date = utilService.formatShortDate(service.activity._created_date);
    }

    // private function to set taxonomies
    function setTaxonomies() {
        if (service.activity.id) {
            // loop through the serivce taxonomies
            _.each(service.taxonomies, function (taxonomy) {
                // get the activity's assignments for the taxonomy
                var assignments = _.filter(service.activity.taxonomy, function (t) { return t.taxonomy_id === taxonomy.taxonomy_id || t.taxonomy_id == taxonomy.childTaxonomy; });
                // loop through the taxonomy's classifications
                _.each(taxonomy.classifications, function (classification) {
                    var assignment = _.find(assignments, function (a) { return a.classification_id == classification.id; });
                    if (assignment) {
                        classification.active = true;
                        if (taxonomy.single) {
                            taxonomy.selected = classification.id;
                        }
                    }
                    //check to see if the taxonomy has children associated with it, if so, check against our model to select. 
                    if (classification.children) {
                        _.each(classification.children, function (child) {
                            var child_assignment = _.find(assignments, function (a) { return a.classification_id == child.id; });
                            if (child_assignment) {
                                child.active = true;
                                classification.showNest = true; //auto expand parent to show active child.
                                if (taxonomy.single) {
                                    taxonomy.selected = child.id;
                                }
                            } else if (_(classification.children).where({ active: true }).length === 0) {
                                classification.showNest = false; //already the default, but should account for user unchecking all children from a parent.
                            }
                        });
                    }
                });
            });
        }
    }

    // private function to set taxonomies
    function setFinancialTaxonomies() {
        if (service.activity.id) {
            // loop through the financial taxonomies
            _.each(service.financialTaxonomies, function (taxonomy) {
                _.each(service.activity.financials, function (financial) {
                    var financialTaxonomy = _.find(financial.taxonomy, function (t) { return t.taxonomy_id == taxonomy.taxonomy_id; });
                    // has the taxonomy, mark active classification
                    if (financialTaxonomy) {
                        // assign classifications to financial record
                        financialTaxonomy.classifications = jQuery.extend(true, {}, taxonomy.classifications);
                        financialTaxonomy.label = taxonomy.label;
                        // mark active classification
                        _.each(financialTaxonomy.classifications, function (c) {
                            if (c.id == financialTaxonomy.classification_id) {
                                c.active = true;
                            }
                        });
                    }
                    // add taxonomy to financial object for activity
                    else {
                        var t = {
                            classification: null,
                            classification_id: null,
                            classifications: jQuery.extend(true, {}, taxonomy.classifications),
                            label: taxonomy.label,
                            taxonomy_id: taxonomy.taxonomy_id
                        };
                        if (!financial.taxonomy) {
                            financial.taxonomy = [];
                        }
                        financial.taxonomy.push(t);
                    }
                });
            });
        }
    }

    // private function to set locations on boundaries
    function setLocations() {
        var ids = [];
        // set the layers active where present in url
        var layers = [];
        if ($stateParams.layers && $stateParams.layers !== '') {
            layers = $stateParams.layers.split(',');
        }
        var param = null;
        if (service.activity.locations.admin3.length > 0) {
            ids = _.pluck(service.activity.locations.admin3, 'feature_id');
            service.boundaries.admin3.edit.filter = ids;
            // is the layer already in the url?
            param = _.find(layers, function (l) { return l == service.boundaries.admin3.edit.alias; });
            // add the param if it is not there
            if (!param) {
                layers.push(service.boundaries.admin3.edit.alias);
            }
        }
        if (service.activity.locations.admin2.length > 0) {
            ids = _.pluck(service.activity.locations.admin2, 'feature_id');
            service.boundaries.admin2.edit.filter = ids;
            // is the layer already in the url?
            param = _.find(layers, function (l) { return l == service.boundaries.admin2.edit.alias; });
            // add the param if it is not there
            if (!param) {
                layers.push(service.boundaries.admin2.edit.alias);
            }
        }
        if (service.activity.locations.admin1.length > 0) {
            ids = _.pluck(service.activity.locations.admin1, 'feature_id');
            service.boundaries.admin1.edit.filter = ids;
            // is the layer already in the url?
            param = _.find(layers, function (l) { return l == service.boundaries.admin1.edit.alias; });
            // add the param if it is not there
            if (!param) {
                layers.push(service.boundaries.admin1.edit.alias);
            }
        }
        if (service.activity.locations.national.length > 0) {
            // is the layer already in the url?
            param = _.find(layers, function (l) { return l == service.boundaries.admin0.edit.alias; });
            // add the param if it is not there
            if (!param) {
                layers.push(service.boundaries.admin0.edit.alias);
            }
        }
        $stateParams.layers = layers.join();
        // update parameters        
        stateService.setState($state.current.name || 'home', $stateParams, false);
    }

    // private function to clear taxonomy selections
    function clearTaxonomies() {
        // loop through the serivce taxonomies
        _.each(service.taxonomies, function (taxonomy) {
            // loop through the taxonomy's classifications
            _.each(taxonomy.classifications, function (classification) {
                classification.active = false;
                if (taxonomy.single) {
                    taxonomy.selected = null;
                }
                if (classification.children) {
                    _.each(classification.children, function (child) {
                        child.active = false;
                    });
                }
                if (_.contains(_.keys(classification), 'showNest')) {
                    classification.showNest = false;
                }
            });
        });
    }

    // private function to save activity record information
    function saveActivity() {
        var deferred = $q.defer();
        // create activity json object
        var activity = {};
        _.each(stateConfig.tools.editor.activity.fields, function (field, key) {
            switch (field.datatype) {
                case "string":
                    activity[key] = service.activity[key];
                    break;
                case "date":
                    activity[key] = utilService.formatShortDate(service.activity[key]);
                    break;
                default:
                    activity[key] = service.activity[key];
                    break;
            }
        });
        //loop through beneficiary fields
        _.each(stateConfig.tools.editor.activity.beneficiary, function (field, key) {
            switch (field.datatype) {
                case "string":
                    activity[key] = service.activity[key];
                    break;
                case "number":
                    activity[key] = service.activity[key] ? Number(service.activity[key]) : service.activity[key];
                    break;
                case "date":
                    activity[key] = utilService.formatShortDate(service.activity[key]);
                    break;
                default:
                    activity[key] = service.activity[key];
                    break;
            }

            //also make sure the field should have data based on the type/unit selected
            if ((field.types || field.unit) && (field.types.indexOf(service.activity.beneficiary_type) < 0 || (field.unit && field.unit !== service.activity.beneficiary_unit))) {
                activity[key] = 'null'; //reset value
            }
        });

        //swap date values if a revised date is entered
        if (activity._revised_start_date) {
            activity._plan_start_date = moment(activity._start_date).format("MM/DD/YYYY");
            activity._start_date = moment(activity._revised_start_date).format("MM/DD/YYYY");
        }
        //swap date values if a revised date is entered
        if (activity._revised_end_date) {
            activity._plan_end_date = moment(activity._end_date).format("MM/DD/YYYY");
            activity._end_date = moment(activity._revised_end_date).format("MM/DD/YYYY");
        }

        // get data group id for new record
        var data_group_id = null;
        if (service.activity.id === null) {
            // TO DO: assumes only one data group, expand to include multiple data groups
            data_group_id = stateConfig.tools.editor.datagroups[0].data_group_id;
        }
        var options = {
            instance_id: pmt.instance,
            user_id: $rootScope.currentUser.user.id,
            activity_id: service.activity.id,
            data_group_id: data_group_id,
            key_value_data: activity,
            delete_record: false,
            pmtId: pmt.id[pmt.env]
        };
        var header = {
            headers: { Authorization: 'Bearer ' + $rootScope.currentUser.token }
        };
        // call the api
        $http.post(pmt.api[pmt.env] + 'pmt_edit_activity', options, header).success(function (data, status, headers, config) {
            var response = data[0].response;
            // if an id & message of success returned, resolve
            if (response.message === 'Success') {
                deferred.resolve(response.id);
            }
            // error occurred on database side, reject with database message
            else {
                service.activity.errors.push({ "record": "activity", "id": response.id, "message": response.message });
                deferred.reject(response.message);
            }
        }).error(function (data, status, headers, c) {
            service.activity.errors.push({ "record": "activity", "id": service.activity.id, "message": status });
            deferred.reject(status);
        });
        return deferred.promise;
    }

    // private function to save activity's taxonomy information
    function saveTaxonomies() {
        var deferred = $q.defer();
        // collect the list of promises
        var promiseList = [];
        // initialize data for api
        var taxonomies = {
            replace: {
                classification_ids: service.activity.status ? [parseInt(service.activity.status, 10)] : [] // status from activity form
            },
            delete: {
                taxonomy_ids: []
            }
        }
        // loop through the taxonomy form information
        _.each(service.taxonomies, function (taxonomy) {
            // taxonomy is a radio UI
            if (taxonomy.single && taxonomy.selected) {
                taxonomies.replace.classification_ids.push(taxonomy.selected);
            }
            // taxonomy is checkbox UI
            else {
                var isEmpty = true;
                _.each(taxonomy.classifications, function (classification) {
                    if (classification.active) {
                        taxonomies.replace.classification_ids.push(classification.id);
                        isEmpty = false;
                    }

                    //look for children
                    _.each(classification.children, function (child) {
                        if (child.active) {
                            taxonomies.replace.classification_ids.push(child.id);
                            isEmpty = false;
                        }
                    });
                });
                if (isEmpty) {
                    taxonomies.delete.taxonomy_ids.push(taxonomy.taxonomy_id);
                }
            }
        });
        if (taxonomies.replace.classification_ids.length > 0) {
            promiseList.push(replaceTaxonomies(taxonomies.replace));
        }
        if (taxonomies.delete.taxonomy_ids.length > 0) {
            promiseList.push(deleteTaxonomies(taxonomies.delete));
        }
        // chain all the saving promises
        var doAll = $q.all(promiseList);
        doAll.then(function () {
            deferred.resolve();
        }).catch(function (ex) {
            deferred.resolve();
        });
        return deferred.promise;
    }

    // private function to save activity's financial information
    function saveFinancials() {
        var deferred = $q.defer();
        // collect the list of promises
        var promiseList = [];
        // loop through all the financial information and save
        _.each(service.activity.financials, function (f, idx) {
            // delete record
            if (f.delete) {
                if (f.id) {
                    promiseList.push(saveFinancial(f.id, null, true));
                }
            }
            // save record
            else {
                // update
                if (f.id) {
                    promiseList.push(saveFinancial(f.id, f, false));
                }
                // create
                else {
                    promiseList.push(saveFinancial(null, f, false));
                }
            }
        });
        // chain all the saving promises
        var doAll = $q.all(promiseList);
        doAll.then(function () {
            deferred.resolve();
        }).catch(function (ex) {
            deferred.resolve();
        });
        return deferred.promise;
    }

    // private function to save a single financial record
    function saveFinancial(financial_id, key_value_data, delete_record) {
        var deferred = $q.defer();
        // collect the list of promises
        var promiseList = [];
        // prepare the options for the api call
        var options = {
            instance_id: pmt.instance,
            user_id: $rootScope.currentUser.user.id,
            activity_id: service.activity.id,
            financial_id: financial_id,
            key_value_data: key_value_data,
            delete_record: delete_record,
            pmtId: pmt.id[pmt.env]
        };
        var header = {
            headers: { Authorization: 'Bearer ' + $rootScope.currentUser.token }
        };
        // call the api to save financial record
        $http.post(pmt.api[pmt.env] + 'pmt_edit_financial', options, header).success(function (data, status, headers, config) {
            var response = data[0].response;
            // the financial record was saved successfully
            if (response.message === 'Success') {
                if (!options.delete_record) {
                    // object to store ids for delete/replacement of taxonomies
                    var taxonomies = {
                        replace: {
                            classification_ids: []
                        },
                        delete: {
                            taxonomy_ids: []
                        }
                    }
                    // loop through the taxonomy form information & collect ids
                    _.each(key_value_data.taxonomy, function (taxonomy) {
                        // taxonomy is assigned
                        if (taxonomy.classification_id && taxonomy.classification_id !== 'None') {
                            taxonomies.replace.classification_ids.push(taxonomy.classification_id);
                        }
                        // taxonomy is unassigned
                        else {
                            taxonomies.delete.taxonomy_ids.push(taxonomy.taxonomy_id);
                        }
                    });
                    // call the replace taxonomy functions if needed
                    if (taxonomies.replace.classification_ids.length > 0) {
                        promiseList.push(replaceFinancialTaxonomies(response.id.toString(), taxonomies.replace));
                    }
                    // call the delete taxonomy functions if needed
                    if (taxonomies.delete.taxonomy_ids.length > 0) {
                        promiseList.push(deleteFinancialTaxonomies(response.id.toString(), taxonomies.delete));
                    }
                }
            }
            // there was an error saving the financial record
            else {
                service.activity.errors.push({ "record": "financial", "id": response.id, "message": response.message });
            }
            // // if this is the last record return 
            // if (service.activity.financials.length === idx + 1) {
            //     deferred.resolve(service.activity.financials);
            // }
        }).error(function (data, status, headers, c) {
            service.activity.errors.push({ "record": "financial", "id": financial_id, "message": status });
            // if this is the last record return 
            //if (service.activity.financials.length === idx + 1) {
            //    deferred.resolve(service.activity.financials);
            //}
            deferred.reject(status);
        });
        // chain all the saving promises
        var doAll = $q.all(promiseList);
        doAll.then(function () {
            deferred.resolve();
        }).catch(function (ex) {
            deferred.resolve();
        });
        return deferred.promise;
    }

    // private function to save activity's participation information
    function saveParticipation() {
        var deferred = $q.defer();
        // collect organization information to save
        var organizations = [];
        // filter organizations for existing records
        _.each(service.activity.organizations, function (organization) {
            // ignore empty records
            if (organization.role_id !== null && organization.id !== null) {
                var existing = _.find(organizations, function (o) { return o.id === organization.id });
                // the organization is already collected
                if (existing) {
                    // update participation id if avialable 
                    if (existing.p_id === null && organization.p_id !== null) {
                        existing.p_id = organization.p_id;
                    }
                    // organization is NOT marked for removal
                    if (!organization.delete) {
                        existing.role_ids.push(organization.role_id.toString());
                        existing.role_ids = _.uniq(existing.role_ids);
                        existing.delete = false;
                    }
                }
                // the organization hasn't been collected
                else {
                    // organization is marked for removal
                    if (organization.delete) {
                        // if the p_id is null, ignore because its not in the database to delete
                        if (organization.p_id !== null) {
                            // add the role_ids parameter as an empty array, effectively removing classification
                            _.extend(organization, { role_ids: [] });
                        }
                    }
                    else {
                        // add the role_ids parameter and populate with classification id
                        _.extend(organization, { role_ids: [organization.role_id.toString()] });
                    }
                    organizations.push(organization);
                }
            }
        });
        _.each(organizations, function (org, idx) {
            var classification_ids = [];
            if (org.type_id) {
                classification_ids.push(org.type_id.toString());
            }
            if (org.imp_type_id) {
                classification_ids.push(org.imp_type_id.toString());
            }
            classification_ids = _.compact(_.union(classification_ids, org.role_ids)).join(',');
            var options = {
                instance_id: pmt.instance,
                user_id: $rootScope.currentUser.user.id,
                activity_id: service.activity.id,
                organization_id: org.id,
                participation_id: org.p_id,
                type_id: org.type_id,
                implementation_id: org.imp_type_id,
                role_ids: org.role_ids.toString() || null,
                edit_action: "replace",
                classification_ids: classification_ids,
                pmtId: pmt.id[pmt.env]
            };
            var header = {
                headers: { Authorization: 'Bearer ' + $rootScope.currentUser.token }
            };
            // delete record
            if (org.delete && org.role_ids.length === 0) {
                options.edit_action = "delete";
            }
            // save record
            else {
                // new record
                if (!org.p_id) {
                    options.edit_action = "add";
                }
            }
            // call the api
            $http.post(pmt.api[pmt.env] + 'pmt_edit_participation', options, header).success(function (data, status, headers, config) {
                var response = data[0].response;
                // the participation record was not saved successfully
                if (response.message !== 'Success') {
                    service.activity.errors.push({ "record": "organization", "id": response.id, "message": response.message });
                }
                // if this is the last record return 
                if (organizations.length === idx + 1) {
                    deferred.resolve(organizations);
                }
            }).error(function (data, status, headers, c) {
                // if this is the last record return 
                if (organizations.length === idx + 1) {
                    deferred.resolve(organizations);
                }
            });
        });
        return deferred.promise;
    }

    // private function to process activity's location information for saving
    function saveLocations() {
        var deferred = $q.defer();
        // collect the list of promises
        var promiseList = [];
        // process national locations
        if (service.activity.locations.national) {
            // assuming single national location
            _.each(service.activity.locations.national, function (l) {
                // delete record
                if (l.delete && l.id) {
                    promiseList.push(deleteLocation(l.id));
                }
                // create record
                if (!l.id && !l.delete) {
                    promiseList.push(saveLocation(l, { _admin0: l._admin0 }));
                }
            });
        }
        // process admin1 locations
        if (service.activity.locations.admin1) {
            _.each(service.activity.locations.admin1, function (l) {
                // delete record
                if (l.delete && l.id) {
                    promiseList.push(deleteLocation(l.id));
                }
                // create record
                if (!l.id && !l.delete) {
                    promiseList.push(saveLocation(l, { _admin0: l._admin0, _admin1: l._admin1 }));
                }
            });
        }
        // process admin2 locations
        if (service.activity.locations.admin2) {
            _.each(service.activity.locations.admin2, function (l) {
                // delete record
                if (l.delete && l.id) {
                    promiseList.push(deleteLocation(l.id));
                }
                // create record
                if (!l.id && !l.delete) {
                    promiseList.push(saveLocation(l, { _admin0: l._admin0, _admin1: l._admin1, _admin2: l._admin2 }));
                }
            });
        }
        // process admin3 locations
        if (service.activity.locations.admin3) {
            _.each(service.activity.locations.admin3, function (l) {
                // delete record
                if (l.delete && l.id) {
                    promiseList.push(deleteLocation(l.id));
                }
                // create record
                if (!l.id && !l.delete) {
                    promiseList.push(saveLocation(l, { _admin0: l._admin0, _admin1: l._admin1, _admin2: l._admin2, _admin3: l._admin3 }));
                }
            });
        }
        // chain all the saving promises
        var doAll = $q.all(promiseList);
        doAll.then(function () {
            deferred.resolve();
        }).catch(function (ex) {
            deferred.resolve();
        });
        return deferred.promise;
    }

    // private function to save a activity location
    function saveLocation(location, key_value) {
        var deferred = $q.defer();
        var options = {
            instance_id: pmt.instance,
            user_id: $rootScope.currentUser.user.id,
            activity_id: service.activity.id,
            location_id: null,
            boundary_id: location.boundary_id,
            feature_id: location.feature_id,
            admin_level: location._admin_level,
            key_value_data: key_value,
            delete_record: false,
            pmtId: pmt.id[pmt.env]
        };
        var header = {
            headers: { Authorization: 'Bearer ' + $rootScope.currentUser.token }
        };
        // call the api
        $http.post(pmt.api[pmt.env] + 'pmt_edit_location', options, header).success(function (data, status, headers, config) {
            deferred.resolve(data);
            //console.log('activity locations saved:', data);
        }).error(function (data, status, headers, c) {
            // there was an error report it to the error handler
            console.log("error on api call to: ", data);
            deferred.reject(status);
        });
        return deferred.promise;
    }

    // private function to delete a activity location
    function deleteLocation(id) {
        var deferred = $q.defer();
        var options = {
            instance_id: pmt.instance,
            user_id: $rootScope.currentUser.user.id,
            activity_id: service.activity.id,
            location_id: id,
            boundary_id: null,
            feature_id: null,
            admin_level: null,
            key_value_data: null,
            delete_record: true,
            pmtId: pmt.id[pmt.env]
        };
        var header = {
            headers: { Authorization: 'Bearer ' + $rootScope.currentUser.token }
        };
        // call the api
        $http.post(pmt.api[pmt.env] + 'pmt_edit_location', options, header).success(function (data, status, headers, config) {
            deferred.resolve(data);
            //console.log('activity locations deleted:', data);
        }).error(function (data, status, headers, c) {
            // there was an error report it to the error handler
            console.log("error on api call to: ", data);
            deferred.reject(status);
        });
        return deferred.promise;
    }

    // private function to replace requested taxonomies
    // classifications will replace all other classifications for a given taxonomy
    function replaceTaxonomies(taxonomies) {
        var deferred = $q.defer();
        var options = {
            instance_id: pmt.instance,
            user_id: $rootScope.currentUser.user.id,
            activity_ids: service.activity.id.toString(),
            classification_ids: taxonomies.classification_ids.join(),
            taxonomy_ids: null,
            edit_action: "replace",
            pmtId: pmt.id[pmt.env]
        };
        var header = {
            headers: { Authorization: 'Bearer ' + $rootScope.currentUser.token }
        };
        // call the api
        $http.post(pmt.api[pmt.env] + 'pmt_edit_activity_taxonomy', options, header).success(function (data, status, headers, config) {
            deferred.resolve(data);
            //console.log('activity taxonomies replaced:', data);
        }).error(function (data, status, headers, c) {
            // there was an error report it to the error handler
            console.log("error on api call to: ", data);
            deferred.reject(status);
        });
        return deferred.promise;
    }

    // private function to delete requested taxonomies
    // removes all classifications from a given taxonomy
    function deleteTaxonomies(taxonomies) {
        var deferred = $q.defer();
        var options = {
            instance_id: pmt.instance,
            user_id: $rootScope.currentUser.user.id,
            activity_ids: service.activity.id.toString(),
            classification_ids: null,
            taxonomy_ids: taxonomies.taxonomy_ids.join(),
            edit_action: "delete",
            pmtId: pmt.id[pmt.env]
        };
        var header = {
            headers: { Authorization: 'Bearer ' + $rootScope.currentUser.token }
        };
        // call the api
        $http.post(pmt.api[pmt.env] + 'pmt_edit_activity_taxonomy', options, header).success(function (data, status, headers, config) {
            deferred.resolve(data);
            //console.log('activity taxonomies deleted:', data);
        }).error(function (data, status, headers, c) {
            // there was an error report it to the error handler
            console.log("error on api call to: ", data);
            deferred.reject(status);
        });
        return deferred.promise;
    }

    // private function to replace requested financial taxonomies
    // classifications will replace all other classifications for a given taxonomy
    function replaceFinancialTaxonomies(ids, taxonomies) {
        var deferred = $q.defer();
        var options = {
            instance_id: pmt.instance,
            user_id: $rootScope.currentUser.user.id,
            financial_ids: ids,
            classification_ids: taxonomies.classification_ids.join(),
            taxonomy_ids: null,
            edit_action: "replace",
            pmtId: pmt.id[pmt.env]
        };
        var header = {
            headers: { Authorization: 'Bearer ' + $rootScope.currentUser.token }
        };
        // call the api
        $http.post(pmt.api[pmt.env] + 'pmt_edit_financial_taxonomy', options, header).success(function (data, status, headers, config) {
            deferred.resolve(data);
            //console.log('financial taxonomies replaced:', data);
        }).error(function (data, status, headers, c) {
            // there was an error report it to the error handler
            console.log("error on api call to: ", data);
            deferred.reject(status);
        });
        return deferred.promise;
    }

    // private function to delete requested financial taxonomies
    // removes all classifications from a given taxonomy
    function deleteFinancialTaxonomies(ids, taxonomies) {
        var deferred = $q.defer();
        var options = {
            instance_id: pmt.instance,
            user_id: $rootScope.currentUser.user.id,
            financial_ids: ids,
            classification_ids: null,
            taxonomy_ids: taxonomies.taxonomy_ids.join(),
            edit_action: "delete",
            pmtId: pmt.id[pmt.env]
        };
        var header = {
            headers: { Authorization: 'Bearer ' + $rootScope.currentUser.token }
        };
        // call the api
        $http.post(pmt.api[pmt.env] + 'pmt_edit_financial_taxonomy', options, header).success(function (data, status, headers, config) {
            deferred.resolve(data);
            //console.log('financial taxonomies deleted:', data);
        }).error(function (data, status, headers, c) {
            // there was an error report it to the error handler
            console.log("error on api call to: ", data);
            deferred.reject(status);
        });
        return deferred.promise;
    }

    // private function to save contact records
    function saveContacts() {
        var deferred = $q.defer();
        // collect the list of promises
        var promiseList = [];
        service.activity.contacts = service.activity.contacts || [];
        // loop through all the contact information and save one by one
        _.each(service.activity.contacts, function (c, idx) {
            promiseList.push(saveContact(c.id, c, c.delete));
        });
        // chain all the saving promises
        var doAll = $q.all(promiseList);
        doAll.then(function () {
            deferred.resolve();
        }).catch(function (ex) {
            deferred.resolve();
        });
        return deferred.promise;
    }

    // private function to save a single contact record
    function saveContact(contact_id, key_value_data, delete_record) {
        var deferred = $q.defer();
        // collect the list of promises
        // prepare the options for the api call
        var options = {
            instance_id: pmt.instance,
            user_id: $rootScope.currentUser.user.id,
            data_group_id: stateConfig.tools.editor.datagroups[0].data_group_id,
            pmtId: pmt.id[pmt.env],
            activity_id: service.activity.id,
            contact_id: contact_id,
            key_value_data: delete_record ? null : key_value_data,
            delete_record: delete_record
        };
        var header = {
            headers: { Authorization: 'Bearer ' + $rootScope.currentUser.token }
        };
        // call the api to save financial record
        $http.post(pmt.api[pmt.env] + 'pmt_edit_contact', options, header).success(function (data, status, headers, config) {
            var response = data[0].response;
            // the financial record was saved successfully
            if (response.message === 'Success') {
                if (!options.delete_record) {
                    // object to store ids for delete/replacement of taxonomies

                    //if a created or activity is missing add it in
                    if (!key_value_data.id || !key_value_data.activities || key_value_data.activities.length === 0) key_value_data.activities = [service.activity.id];
                    else if (key_value_data.activities.indexOf(service.activity.id) < 0) key_value_data.activities.push(service.activity.id);
                    //add or confirm id
                    key_value_data.id = response.id;

                    //clear global list of contacts to force a get on next request
                    this.contacts = [];
                } else {
                    //if the record was deleted, mark it for removal from array
                    key_value_data.deleted = true;
                }

                deferred.resolve(data);
            } else {
                // there was an error saving the financial record
                service.activity.errors.push({ "record": "contact", "id": response.id, "message": response.message });
                deferred.reject(status);
            }
        }).error(function (data, status, headers, c) {
            service.activity.errors.push({ "record": "contact", "id": key_value_data.id, "message": status });
            deferred.reject(status);
        });

        return deferred.promise;
    }

    // private function to save any child records (create or delete)
    function saveChildren() {
        var deferred = $q.defer();
        // collect the list of promises
        var promiseList = [];
        service.activity.children = service.activity.children || [];
        // loop through all the children and save one by one
        _.each(service.activity.children, function (c, idx) {
            promiseList.push(saveChild(c.id, c, c.delete));
        });
        // chain all the saving promises
        var doAll = $q.all(promiseList);
        doAll.then(function () {
            deferred.resolve();
        }).catch(function (ex) {
            deferred.resolve();
        });
        return deferred.promise;
    }

    // private function to save a single child record
    function saveChild(child_id, key_value_data, delete_record) {
        var deferred = $q.defer();
        //skip if no change (either null id and not for delete, or deleteing a record that already exists)
        if ((!child_id && !delete_record) || (child_id && delete_record)) {

            // prepare the options for the api call
            var options = {
                instance_id: pmt.instance,
                user_id: $rootScope.currentUser.user.id,
                activity_id: child_id,
                data_group_id: stateConfig.tools.editor.datagroups[0].data_group_id,
                key_value_data: key_value_data,
                delete_record: delete_record,
                pmtId: pmt.id[pmt.env]
            };
            var header = {
                headers: { Authorization: 'Bearer ' + $rootScope.currentUser.token }
            };
            // call the api
            $http.post(pmt.api[pmt.env] + 'pmt_edit_activity', options, header).success(function (data, status, headers, config) {
                var response = data[0].response;
                // if an id & message of success returned, resolve
                if (response.message === 'Success') {
                    if (!$rootScope.currentUser.user.role_auth._super || !$rootScope.currentUser.user.role_auth._security) {
                        if ($rootScope.currentUser.user.authorizations) {
                            $rootScope.currentUser.user.authorizations.push(response.id);
                        }
                    }
                    deferred.resolve(response.id);
                }
                // error occurred on database side, reject with database message
                else {
                    service.activity.errors.push({ "record": "activity", "id": response.id, "message": response.message });
                    deferred.reject(response.message);
                }
            }).error(function (data, status, headers, c) {
                service.activity.errors.push({ "record": "activity", "id": service.activity.id, "message": status });
                deferred.reject(status);
            });
        } else {
            deferred.resolve();
        }

        return deferred.promise;
    }

    // private function to save detail/activity records
    function saveDetails() {
        var deferred = $q.defer();
        // collect the list of promises
        var promiseList = [];
        service.activity.details = service.activity.details || [];
        // loop through all the details and save one by one
        _.each(service.activity.details, function (d, idx) {
            promiseList.push(saveDetail(d.id, d, d.delete));
        });
        // chain all the saving promises
        var doAll = $q.all(promiseList);
        doAll.then(function () {
            deferred.resolve();
        }).catch(function (ex) {
            deferred.resolve();
        });
        return deferred.promise;
    }

    // private function to save a single detail/activity record
    function saveDetail(detail_id, key_value_data, delete_record) {
        var deferred = $q.defer();
        // collect the list of promises
        // prepare the options for the api call
        var options = {
            instance_id: pmt.instance,
            user_id: $rootScope.currentUser.user.id,
            data_group_id: stateConfig.tools.editor.datagroups[0].data_group_id,
            pmtId: pmt.id[pmt.env],
            activity_id: service.activity.id,
            detail_id: detail_id,
            key_value_data: delete_record ? null : key_value_data,
            delete_record: delete_record
        };
        var header = {
            headers: { Authorization: 'Bearer ' + $rootScope.currentUser.token }
        };
        // call the api to save detail record
        $http.post(pmt.api[pmt.env] + 'pmt_edit_detail', options, header).success(function (data, status, headers, config) {
            var response = data[0].response;
            // the financial record was saved successfully
            if (response.message === 'Success') {
                if (!options.delete_record) {
                    //add or confirm id
                    var edit_action = delete_record ? 'delete' : key_value_data.id ? 'replace' : 'add';
                    //update record with id
                    key_value_data.id = response.id;

                    //take new value and add the correct taxonomy to it if record needs it
                    if (key_value_data.taxonomy) {
                        editorService.saveFinancialDetail(pmt.instance, $rootScope.currentUser.user.id, response.id, key_value_data.taxonomy[0].classification_id, key_value_data.taxonomy[0].taxonomy_id, edit_action);
                    }

                } else {
                    //if the record was deleted, mark it for removal from array
                    service.activity.details = _(service.activity.details).difference(_(service.activity.details).where({ id: response.id }));

                    //take new value and add the correct taxonomy to it if record needs it
                    if (key_value_data.taxonomy) {
                        editorService.saveFinancialDetail(response.id, detail_id, key_value_data, delete_record);
                    }
                }

                deferred.resolve(data);
            } else {
                // there was an error saving the financial record
                service.activity.errors.push({ "record": "detail", "id": response.id, "message": response.message });
                deferred.reject(status);
            }
        }).error(function (data, status, headers, c) {
            service.activity.errors.push({ "record": "detail", "id": key_value_data.id, "message": status });
            deferred.reject(status);
        });

        return deferred.promise;
    }

    // private function to save a single detail/activity record
    editorService.saveFinancialDetail = function (instance_id, user_id, detail_ids, classification_ids, taxonomy_ids, edit_action) {
        var deferred = $q.defer();
        // collect the list of promises
        // prepare the options for the api call
        var options = {
            instance_id: instance_id,
            user_id: $rootScope.currentUser.user.id,
            data_group_id: stateConfig.tools.editor.datagroups[0].data_group_id,
            pmtId: pmt.id[pmt.env],
            detail_ids: detail_ids.toString(),
            classification_ids: classification_ids.toString(),
            taxonomy_ids: taxonomy_ids.toString(),
            edit_action: edit_action
        };
        var header = {
            headers: { Authorization: 'Bearer ' + $rootScope.currentUser.token }
        };
        // call the api to save detail record
        $http.post(pmt.api[pmt.env] + 'pmt_edit_detail_taxonomy', options, header).success(function (data, status, headers, config) {
            var response = data[0].response;
            // the financial record was saved successfully
            if (response.message === 'Success') {
                deferred.resolve(data);
            } else {
                // there was an error saving the financial record
                service.activity.errors.push({ "record": "detail", "id": response.id, "message": response.message });
                deferred.reject(status);
            }
        }).error(function (data, status, headers, c) {
            deferred.reject(status);
        });

        return deferred.promise;
    }

    // private function to validate activity form
    function validateActivityForm() {
        var isValid = true, fields = stateConfig.tools.editor.activity.fields;
        // validate activity form
        service.forms.activityForm.error = false;

        //if this is a child activity - only validate on child fields
        if (stateService.isParam('editor_parent_id') && stateService.getState().editor_parent_id) {
            fields = _(fields).pick(function (field) { return field.childEditing; });
        }

        //make sure name is unique
        var dup = _(editorService.getAllActivities()).find({ t: service.activity._title });
        if (dup && dup.id !== service.activity.id) {
            service.forms.activityForm.error = true;
            isValid = false;
            service.forms.activityForm.message = "Project title already in use.";
        }
        // loop through the configurations fields and validate required fields
        _.each(fields, function (field, key) {
            if (field.required) {
                // if required field is empty, invalidate form
                if (service.activity[key] === '' || service.activity[key] === null || typeof service.activity[key] === 'undefined') {
                    service.forms.activityForm.error = true;
                    isValid = false;
                }
            }
        });
        //loop through extra fields (if not a child activity)
        if (!stateService.isParam('editor_parent_id') || !stateService.getState().editor_parent_id) {
            _.each(stateConfig.tools.editor.activity.beneficiary, function (field, key) {
                if (field.required) {
                    // if required field is empty, invalidate form
                    if (service.activity[key] === '' || service.activity[key] === null || typeof service.activity[key] === 'undefined') {
                        //make sure this doesn't have a type or unit or that the correct type and unit are selected
                        if ((!field.types && !field.unit) || (field.types.indexOf(service.activity.beneficiary_type) > -1 && field.unit === service.activity.beneficiary_unit)) {
                            service.forms.activityForm.error = true;
                            isValid = false;
                        }
                    }
                }
            });
        }


         //make sure end date is before today if Project Status is completed
         var status = _.chain(stateConfig.tools.editor.activity.status.values).where({label: "Completed"}).pluck("value").first().value();
         if (status && status == service.activity.status && (moment().isBefore(service.activity._end_date) || moment().isBefore(service.activity._revised_end_date))) {
             service.forms.activityForm.error = true;
             isValid = false;
             service.forms.activityForm.message = "Future projects cannot be completed.";
         }

        // if status is required ensure value is assigned
        if (stateConfig.tools.editor.activity.status.required && (!stateService.isParam('editor_parent_id') || !stateService.getState().editor_parent_id)) {
            // if required & empty, invalidate form
            if (service.activity.status === '' || service.activity.status === null || typeof service.activity.status === 'undefined') {
                service.forms.activityForm.error = true;
                service.forms.activityForm.message = "Please check for missing, required information.";
                isValid = false;
            }
        }
        // ensure validate date ranges
        if (service.activity._start_date !== null && service.activity._end_date !== null && (!stateService.isParam('editor_parent_id') || !stateService.getState().editor_parent_id)) {
            if (service.activity._start_date > service.activity._end_date) {
                service.forms.activityForm.error = true;
                service.forms.activityForm.message = "The date range is invalid, cannot have a start date later than an end date.";
                isValid = false;
            }
        }
        // ensure validate dates
        if (service.activity._start_date !== null && (!stateService.isParam('editor_parent_id') || !stateService.getState().editor_parent_id)) {
            if (!utilService.validDate(service.activity._start_date.toString())) {
                service.forms.activityForm.error = true;
                service.forms.activityForm.message = "The start date is not a valid date.";
                isValid = false;
            }
        }
        if (service.activity._end_date !== null && (!stateService.isParam('editor_parent_id') || !stateService.getState().editor_parent_id)) {
            if (!utilService.validDate(service.activity._end_date.toString())) {
                service.forms.activityForm.error = true;
                service.forms.activityForm.message = "The end date is not a valid date.";
                isValid = false;
            }
        }
        // if validated with no errors mark form as valid
        if (isValid) {
            service.forms.activityForm.validated = true;
        }
        return isValid;
    }

    // private function to validate taxonomy form
    function validateTaxonomyForm() {
        var isValid = true, fields = stateConfig.tools.editor.taxonomies;
        // validate taxonomy form
        service.forms.taxonomyForm.error = false;

        //if this is a child activity - only validate on child fields
        if (stateService.isParam('editor_parent_id') && stateService.getState().editor_parent_id) {
            fields = _(fields).where({ childEditing: true });
        }

        // loop through the configurations taxonomies and validate required taxonomies
        _.each(fields, function (taxonomy) {
            // if a required taxonomy is missing, invalidate form
            if (taxonomy.required && taxonomy.selected === null) {
                service.forms.taxonomyForm.error = true;
                isValid = false;
            }
        });
        // if validated with no errors mark form as valid
        if (isValid) {
            service.forms.taxonomyForm.validated = true;
        }
        return isValid;
    }

    // private function to validate financial form
    function validateFinancialForm() {
        var isValid = true;
        // validate financial form
        service.forms.financialForm.error = false;
        // validate financial records if required
        if (stateConfig.tools.editor.financial.required) {
            var financials = _.filter(service.activity.financials, function (f) { return !f.delete; });
            // must contain at least one record
            if (financials.length < 1) {
                service.forms.financialForm.error = true;
                service.forms.financialForm.message = "Must have at least one financial record.";
                isValid = false;
            }
            // validate record fields
            _.each(financials, function (financial) {
                // all records must contain an amount
                if (financial._amount < 100 || financial._amount === null || typeof financial._amount === 'undefined') {
                    service.forms.financialForm.error = true;
                    service.forms.financialForm.message = "Please check the financial records for missing information.";
                    isValid = false;
                }
                // ensure validate date ranges
                if (financial._start_date !== null && financial._end_date !== null) {
                    if (financial._start_date > financial._end_date) {
                        service.forms.financialForm.error = true;
                        service.forms.financialForm.message = "Please check the financial records for invalid date ranges, cannot have a start date later than an end date.";
                        isValid = false;
                    }
                }
                // ensure validate dates
                if (financial._start_date !== null) {
                    if (!utilService.validDate(financial._start_date.toString())) {
                        service.forms.financialForm.error = true;
                        service.forms.financialForm.message = "The start date is not a valid date.";
                        isValid = false;
                    }
                }
                if (financial._end_date !== null) {
                    if (!utilService.validDate(financial._end_date.toString())) {
                        service.forms.financialForm.error = true;
                        service.forms.financialForm.message = "The end date is not a valid date.";
                        isValid = false;
                    }
                }
            });
        }
        //check to see if this record has any financial details, if so, make sure the amount in not greater than 100
        service.forms.subFinancialForm.error = false;
        if (service.activity.details) {
            var total = _.chain(service.activity.details).where({ _title: null }).where({ delete: false }).reduce(function (a, b) { return a + b._amount; }, 0).value();
            if (total > 100) {
                service.forms.subFinancialForm.error = true;
                service.forms.subFinancialForm.message = "Total percentage of financial records cannot exceed 100.";
                isValid = false;
            }
        }

        // if validated with no errors mark form as valid
        if (isValid) {
            service.forms.financialForm.validated = true;
            service.forms.subFinancialForm.validated = true;
        }
        return isValid;
    }

    // private function to validate organization form
    function validateOrgForm() {
        var isValid = true;
        // validate organization form
        service.forms.orgForm.error = false;
        service.forms.orgForm.message = null;
        // loop through the configurations roles and validate required organization roles
        _.each(stateConfig.tools.editor.organization.roles, function (role, key) {
            if (role.required && (
                (!stateService.isParam('editor_parent_id') && !stateService.getState().editor_parent_id)
                || (stateService.isParam('editor_parent_id') && stateService.getState().editor_parent_id && role.childRequired))) {
                var orgs = _.filter(service.activity.organizations, function (o) { return !o.delete && o.role_id === role.role_id; });
                // must contain at least one record
                if (orgs.length < 1) {
                    service.forms.orgForm.error = true;
                    service.forms.orgForm.message = "Must have at lease one " + role.label + " organization.";
                    isValid = false;
                }
            }
        });
        // loop through all the organizations to ensure name and role are provided
        _.each(service.activity.organizations, function (org) {
            if (!org.delete) {
                if (org._name === null || org._name === '' || typeof org._name === 'undefined'
                    || org.role_id === null || org.role_id === '' || typeof org.role_id === 'undefined') {
                    service.forms.orgForm.error = true;
                    service.forms.orgForm.message = "Please check the organization records for missing information.";
                    isValid = false;
                }

            }
        });
        // make sure only 1 organization is primary
        var primaryCt = _.filter(service.activity.organizations, function (o) {
            if (o._name !== null && _.contains(_.keys(o), 'imp_type_id') && o.imp_type_id !== null) {
                return o;
            }
            //return null;
        });
        if (primaryCt > 1) {
            service.forms.orgForm.error = true;
            service.forms.orgForm.message = "Please select only 1 primary implementing organization.";
            isValid = false;
        }

        // if validated with no errors mark form as valid
        if (isValid) {
            service.forms.orgForm.validated = true;
        }
        return isValid;
    }

    // private function to validate contacts form
    function validateContactForm() {
        var isValid = true;
        // validate contact form
        service.forms.contactForm.message = ""; //reset message
        service.forms.contactForm.error = false;

        // if (service.forms.contactForm.form.is(".ng-invalid")) {
        //     service.forms.contactForm.error = true;
        //     service.forms.contactForm.message = "Please check the contact records for errors.";
        //     isValid = false;
        // }

        if (isValid) {
            //loop through each contact to check for validity
            service.activity.contacts = service.activity.contacts || [];
            _.each(service.activity.contacts, function(contact) {
                // loop through the configurations fields and validate required fields
                _.each(stateConfig.tools.editor.contacts.fields, function (field, key) {
                    if (field.required) {
                        // if required field is empty, invalidate form
                        if (contact[key] === '' || contact[key] === null || typeof contact[key] === 'undefined') {
                            service.forms.contactForm.error = true;
                            service.forms.contactForm.message = "Please check the contact records for missing information.";
                            isValid = false;
                        }

                    }
                });

                //make sure record is unique amongst other records
                var finding = _(service.activity.contacts).filter(function (o) {
                    //id is not null and is the same OR first, last, and email match.
                    return (o.id && o.id === contact.id) || (o._first_name === contact._first_name && o._last_name === contact._last_name && o._email === contact._email);
                });

                if (finding.length > 1) {
                    service.forms.contactForm.error = true;
                    service.forms.contactForm.message = "Please check the contact records for duplicate contacts.";
                    isValid = false;
                }
            });
        }

        // if validated with no errors mark form as valid
        if (isValid) {
            service.forms.contactForm.validated = true;
        }
        return isValid;
    }

    //make sure title is in place for all children
    function validateChildForm() {
        var isValid = true;
        // validate child form
        service.forms.childForm.message = ""; //reset message
        service.forms.childForm.error = false;

        //loop through each child to check for validity
        service.activity.children = service.activity.children || [];
        _.each(service.activity.children, function(child) {
            // loop through the configurations fields and validate required fields
            _.each(stateConfig.tools.editor.children.fields, function (field, key) {
                if (field.required) {
                    // if required field is empty, invalidate form
                    if ((child[key] === '' || child[key] === null || typeof child[key] === 'undefined') && !child.delete) {
                        service.forms.childForm.error = true;
                        service.forms.childForm.message = "Please check the child records for missing information.";
                        isValid = false;
                    }
                }
            });
        });

        // if validated with no errors mark form as valid
        if (isValid) {
            service.forms.childForm.validated = true;
        }
        return isValid;
    }

    // private function to validate location form
    function validateLocationForm() {
        var isValid = true;
        // validate validate form
        service.forms.locationForm.error = false;
        var national = _.filter(service.activity.locations.national, function (l) { return !l.delete; });
        var admin1 = _.filter(service.activity.locations.admin1, function (l) { return !l.delete; });
        var admin2 = _.filter(service.activity.locations.admin2, function (l) { return !l.delete; });
        var admin3 = _.filter(service.activity.locations.admin3, function (l) { return !l.delete; });
        // ensure there is at least one location
        if (national.length === 0 & admin1.length === 0 & admin2.length === 0 & admin3.length === 0) {
            service.forms.locationForm.error = true;
            isValid = false;
        }
        // if validated with no errors mark form as valid
        if (isValid) {
            service.forms.activityForm.validated = true;
        }
        return isValid;
    }

    // private - validatation on child details list form
    function validateDetailsForm() {
        var isValid = true;
        // validate organization form
        service.forms.detailForm.error = false;
        service.forms.detailForm.message = null;
        // loop through the configurations roles and validate required organization roles
        if (service.activity.details) {
            _.each(service.activity.details, function(detail) {
                // loop through the configurations fields and validate required fields
                _.each(stateConfig.tools.editor.activityList, function (field, key) {
                    if (field.required) {
                        // if required field is empty, invalidate form
                        if (detail[key] === '' || detail[key] === null || typeof detail[key] === 'undefined') {
                            service.forms.detailForm.error = true;
                            service.forms.detailForm.message = "Please check the activity list records for missing information.";
                            isValid = false;
                        }

                    }
                });
            });
        }

        // if validated with no errors mark form as valid
        if (isValid) {
            service.forms.detailForm.validated = true;
        }
        return isValid;
    }

    //get 1 id to use in creating a new record 
    editorService.modelId = editorService.getModelActivityId();

    return editorService;

});