/***************************************************************
 * Editor Service
 * Service to support editor module.
* *************************************************************/

angular.module('PMTViewer').service('integrationService', function ($q, $http, $rootScope, $state, $stateParams, config, pmt, utilService, mapService, stateService) {

    // the editor service model
    var integrationService = {};
    // internal editor service attributes
    var service = {
        integration: {}, // integration in edit mode
        schedules: null, // all integration
        contacts: [], // all contacts
        taxonomies: {}, // taxonomy options
        forms: {
            scheduleForm: {
                error: false,
                validated: false,
                message: null
            },
            recipientForm: {
                error: false,
                validated: false
            }
        }, // forms used to edit elements of the activity record
        lastEdit: null // timestamp of last saved edit
    };

    // get the state configuration for the locations state
    var stateConfig = _.find(config.states, function (states) { return states.route == 'editor'; });

    // getters
    integrationService.getCurrentIntegration = function () { return service.integration; };
    integrationService.getAllSchedules = function () { return service.schedules; };
    integrationService.getScheduleId = function () { return service.integration.schedule.id; };
    integrationService.getTaxonomies = function (isChild) {
        if (!isChild) {
            return service.taxonomies;
        } else {
            return _(service.taxonomies).where({ childEditing: true });
        }
    };
    integrationService.getForms = function () { return service.forms; };
    integrationService.getLastEdit = function () { return service.lastEdit; };

    // gets and returns all integrations
    integrationService.getIntegrations = function (data_group_ids, activity_ids) {
        var deferred = $q.defer();
        // var ids = activity_ids !== null ? activity_ids.join(",") : null;
        // var options = {
        //     data_group_ids: data_group_ids.join(","),
        //     classification_ids: null,
        //     imp_org_ids: null,
        //     fund_org_ids: null,
        //     org_ids: null,
        //     start_date: null,
        //     end_date: null,
        //     unassigned_taxonomy_ids: null,
        //     activity_ids: ids,
        //     boundary_filter: null,
        //     pmtId: pmt.id[pmt.env]
        // };
        // var header = {
        //     headers: { Authorization: 'Bearer ' + $rootScope.currentUser.token }
        // };
        // // call the api to get the pmt data
        // $http.post(pmt.api[pmt.env] + 'pmt_activities', options, header).success(function (data, status, headers, config) {
        //     var activities = [];
        //     // loop through data and remove the response object
        //     _.each(data, function (a) {
        //         activities.push(a.response);
        //     });
        //     service.activities = _.sortBy(activities, 't');;
        //     // broadcast that editable activity list is updated
        //     $rootScope.$broadcast('editor-list-updated');
        //     deferred.resolve(service.activities);
        // }).error(function (data, status, headers, c) {
        //     // there was an error report it to the error handler
        //     console.log("error on api call to: pmt_activity");
        //     deferred.reject(status);
        // });

        deferred.resolve([]);
        return deferred.promise;
    };

    // gets and returns integration details
    integrationService.getIntegration = function (id) {
        var deferred = $q.defer();
        // var options = {
        //     id: id,
        //     pmtId: pmt.id[pmt.env]
        // };
        // var header = {
        //     headers: { Authorization: 'Bearer ' + $rootScope.currentUser.token }
        // };
        // // call the api to get the pmt data by boundary points
        // $http.post(pmt.api[pmt.env] + 'pmt_activity_detail', options, header).success(function (data, status, headers, config) {
        //     if (data.length > 0) {
        //         // remove response object
        //         var activity = data[0].response;
        //         service.activity = activity;
        //         clearTaxonomies();
        //         setBoundries().then(function () {
        //             processActivity();
        //             setTaxonomies();
        //             setFinancialTaxonomies();
        //             setLocations();
        //             $rootScope.$broadcast('editor-activity-loaded');
        //             deferred.resolve(service.activity);
        //         }, function () {
        //             deferred.reject("Boundaries did not load and are required for the activity.");
        //         });
        //     }
        //     else {
        //         deferred.reject("Activity does not exist");
        //     }
        // }).error(function (data, status, headers, c) {
        //     // there was an error report it to the error handler
        //     console.log("error on api call to: pmt_activity_detail");
        //     deferred.reject(status);
        // });
        deferred.resolve({});
        return deferred.promise;
    };

    // save integration
    integrationService.saveIntegration = function () {
        var deferred = $q.defer();
        if (integrationService.formsValid()) {
            // add/reset errors for activity
            service.activity.errors = [];
            // call function to save activity and related records
            saveActivity().then(function (id) {
                // new activity
                if (service.activity.id === null) {
                    service.activity.id = id;
                    stateService.setParamWithVal('editor_activity_id', service.activity.id);
                    $rootScope.currentUser.user.authorizations.push(id);
                }
                // chain all the saving promises
                var saveAll = $q.all([
                    saveSchedule(),
                    saveRecipients()
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
            if (!integrationService.validateForms()) {
                deferred.reject("It appears that you may have forgotten to provide some information or there's an error on your form. Please review and ensure everything is correct.");
            }
        }
        return deferred.promise;

    };

    // cancel integration
    integrationService.cancelIntegration = function () {
        var deferred = $q.defer();

        deferred.resolve(service.schedule);

        return deferred.promise;
    };

    // delete integration
    integrationService.deleteIntegration = function () {
        var deferred = $q.defer();
        // var options = {
        //     instance_id: pmt.instance,
        //     user_id: $rootScope.currentUser.user.id,
        //     activity_id: service.activity.id,
        //     data_group_id: null,
        //     key_value_data: null,
        //     delete_record: true,
        //     pmtId: pmt.id[pmt.env]
        // };
        // var header = {
        //     headers: { Authorization: 'Bearer ' + $rootScope.currentUser.token }
        // };
        // // call the api
        // $http.post(pmt.api[pmt.env] + 'pmt_edit_activity', options, header).success(function (data, status, headers, config) {
        //     deferred.resolve(data[0].response);
        //     //console.log('activity deleted:', data);
        // }).error(function (data, status, headers, c) {
        //     // there was an error report it to the error handler
        //     console.log("error on api call to: ", data);
        //     deferred.reject(status);
        // });
        deferred.resolve({});
        return deferred.promise;
    };

    // gets and returns list of classifications for a taxonomy
    integrationService.getTaxonomy = function (taxonomy) {
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
    integrationService.getInUseOrgs = function (data_group_ids, org_role_ids, type) {
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
    integrationService.getContacts = function () {
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
    integrationService.getBoundaryHierarchy = function (boundary_type, admin_levels, filter_features, data_group_ids) {
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
    integrationService.getFinancialTaxonomy = function (taxonomy) {
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
    integrationService.validateAuthorization = function (activity_id, data_group_id, auth_type) {
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

    // validate forms used to edit the activity record
    integrationService.validateForms = function () {
        var isValid = true;
        // validate activity form
        if (!validateScheduleForm()) { isValid = false; }
        // validate taxonomy form
        if (!validateRecipientForm()) { isValid = false; }
        return isValid;
    };

    // t/f are all forms validated without errors
    integrationService.formsValid = function () {
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
    integrationService.clearForms = function () {
        _.each(service.forms, function (form) {
            form.validated = false;
            form.error = false;
            if (_.has(form, 'message')) {
                form.message = null;
            }
        });
    };

    
    // check all forms to see if any have edits
    integrationService.isDirty = function() {
        // activate loader
        var dirty = false;
        _(this.getForms()).each(function (f) {
            if (f.form.length > 0) {
                if (f.form && f.form.length > 0 && !f.form.hasClass('ng-pristine')) { dirty = true; }
            }
        });

        return dirty;
    }

    // private function to save activity record information
    function saveSchedule() {
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

    // private function to save activity's financial information
    function saveRecipients() {
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
    function saveRecipient(financial_id, key_value_data, delete_record) {
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

    // private function to delete a activity location
    function deleteRecipient(id) {
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

    // private function to save a single financial record
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
                    key_value_data.id = response.id;
                } else {
                    //if the record was deleted, mark it for removal from array
                    service.activity.details = _(service.activity.details).difference(_(service.activity.details).where({id:response.id}));
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

    // private function to validate activity form
    function validateActivityForm() {
        var isValid = true, fields = stateConfig.tools.editor.activity.fields;
        // validate activity form
        service.forms.activityForm.error = false;

        //if this is a child activity - only validate on child fields
        if (stateService.isParam('editor_parent_id') && stateService.getState().editor_parent_id) {
            fields = _(fields).pick(function(field) { return field.childEditing; });
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
        // if validated with no errors mark form as valid
        if (isValid) {
            service.forms.financialForm.validated = true;
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
                var orgs = _.filter(service.activity.organizations, function (o) { return !o.delete && o.classification_id === role.classification_id; });
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
                    || org.classification_id === null || org.classification_id === '' || typeof org.classification_id === 'undefined') {
                    service.forms.orgForm.error = true;
                    service.forms.orgForm.message = "Please check the organization records for missing information.";
                    isValid = false;
                }
            }
        });
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

        // if validated with no errors mark form as valid
        if (isValid) {
            service.forms.contactForm.validated = true;
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

        // if validated with no errors mark form as valid
        if (isValid) {
            service.forms.detailForm.validated = true;
        }
        return isValid;
    }

    return integrationService;

});