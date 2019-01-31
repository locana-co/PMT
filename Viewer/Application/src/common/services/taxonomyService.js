/***************************************************************
 * Organization Service
 * Service to support organization module.
* *************************************************************/
angular.module('PMTViewer').service('taxonomyService', function ($timeout, $q, $http, $rootScope, $state, $stateParams, config, pmt, stateService, activityService) {
    // the organization service model
    var taxonomyService = {
        searchText: "",
        taxonomies: [],
        activities: [],
        selectAll: false,
        deSelectAll: false,
        selectedTaxonomy: {}, //stores selectedTaxonomy
    };
    // internal organization service attributes
    var taxonomies = null, taxonomiesCount = 0;

    // getters
    taxonomyService.getAllTaxonomies = function () {
        //get taxomomies or return stored copy
        return taxonomies;
    };

    // gets selected Taxonomy
    taxonomyService.setSelectedTaxonomy = function (tax) {
        taxonomyService.selectedTaxonomy = tax;
        $rootScope.$broadcast('tax-title-update', tax);
    };

    taxonomyService.getTaxonomies = function () {
        return taxonomyService.taxonomies;

    };

    taxonomyService.getTaxonomiesCount = function () {
        return _(taxonomyService.taxonomies).filter(function (t) {
            if (t.inFilter && !t.delete) return true;
        }).length;
    };

    //clear out taxonomies
    taxonomyService.clearVirtualData = function (list) {
        list.loadedPages = [];
    };

    // get all 
    taxonomyService.getTaxes = function (offset, limit, taxUpdated) {
        var deferred = $q.defer();

        if (taxUpdated && taxonomyService.taxonomies) {
            // performing a classification parent record add. 
            taxonomyService.getVirtualClassifications(taxUpdated);
        } else {
            // performing a load or search
            var options = {
                pmtId: pmt.id[pmt.env],
                instance_id: pmt.instance,
                return_core: false,
                search_text: taxonomyService.searchText,
                offset: offset,
                limit: limit
            };

            var header = {
                headers: { Authorization: 'Bearer ' + $rootScope.currentUser.token }
            };

            // call the api
            $http.post(pmt.api[pmt.env] + 'pmt_taxonomy_search', options, header, { cache: true }).success(function (data, status, headers, config) {
                // remove unneccessary response object from api

                if (!taxonomyService.taxonomies || taxonomyService.taxonomies.length === 0) {
                    var taxes = _.chain(data).pluck('response').map(function (t) {
                        t._name = t._name.replace(/\s*\(.*?\)\s*/g, '');
                        t.delete = false;
                        t.inFilter = true;

                        return t;
                    }).sortBy('_name').value();
                    taxonomyService.taxonomies = taxes;
                    _(taxonomyService.taxonomies).each(function (t) {
                        if (!t.classifications) {
                            taxonomyService.getVirtualClassifications(t.id);
                        }
                    });
                    deferred.resolve(taxes);
                } else {
                    // performing a search, only need to update the inFilter value
                    var ids = _.chain(data).pluck('response').pluck("id").value();
                    _(taxonomyService.taxonomies).each(function (t) {
                        t.inFilter = ids.indexOf(t.id) > -1;
                    });
                    deferred.resolve(taxonomyService.taxonomies);
                }

                $rootScope.$broadcast('tax-list-updated');
            }).error(function (data, status, headers, c) {
                // there was an error report it to the error handler
                console.log("error on api call to: pmt_tax");
                deferred.reject(status);
            });
        }

        return deferred.promise;

    };


    // process save for each taxonomy
    taxonomyService.saveTaxonoimes = function (taxonomies, isChild) {
        var deferred = $q.defer();
        // collect the list of promises
        var promiseList = [];
        // process deletes
        _.chain(taxonomies).where({ delete: true }).each(function (t) { promiseList.push(deleteTaxonomy(t.id)); });
        // process edits

        _.chain(taxonomies).filter(function (t) { if (!t.delete) { return true; } }).each(function (t) {
            var data = { _name: t._name, _description: t._description, _is_category: t._is_category };
            if (isChild) {
                //override settings to create a child taxonomy
                data.parent_id = t.parent_id;
                data._name = t._child_name;
                data._description = t._child_description;
                data._is_category = false;
            }
            promiseList.push(saveTaxonomy(t.id, data));
        });

        // chain all the saving promises
        var doAll = $q.all(promiseList);
        doAll.then(function (r) {
            deferred.resolve(r);
        }).catch(function (ex) {
            deferred.reject(ex);
        });
        return deferred.promise;
    }

    // private function to save a Taxonomy
    function saveTaxonomy(id, key_value_data) {
        var deferred = $q.defer();
        var options = {
            pmtId: pmt.id[pmt.env],
            instance_id: pmt.instance,
            user_id: $rootScope.currentUser.user.id,
            taxonomy_id: id,
            key_value_data: key_value_data,
            delete_record: false
        };
        var header = {
            headers: { Authorization: 'Bearer ' + $rootScope.currentUser.token }
        };
        // call the api
        $http.post(pmt.api[pmt.env] + 'pmt_edit_taxonomy', options, header).success(function (data, status, headers, config) {
            deferred.resolve(data[0].response);
        }).error(function (data, status, headers, c) {
            // there was an error report it to the error handler
            console.log("error on api call to: ", data);
            deferred.reject(status);
        });
        return deferred.promise;
    }

    // private function to delete a Taxonomy
    function deleteTaxonomy(id) {
        var deferred = $q.defer();
        var options = {
            pmtId: pmt.id[pmt.env],
            instance_id: pmt.instance,
            user_id: $rootScope.currentUser.user.id,
            taxonomy_id: id,
            key_value_data: null,
            delete_record: true

        };
        var header = {
            headers: { Authorization: 'Bearer ' + $rootScope.currentUser.token }
        };
        // call the api
        $http.post(pmt.api[pmt.env] + 'pmt_edit_taxonomy', options, header).success(function (data, status, headers, config) {
            deferred.resolve(data[0].response);
        }).error(function (data, status, headers, c) {
            // there was an error report it to the error handler
            console.log("error on api call to: ", data);
            deferred.reject(status);
        });
        return deferred.promise;
    }

    // process save for each Classification
    taxonomyService.saveClassifications = function (classifications) {
        var deferred = $q.defer();
        // collect the list of promises
        var promiseList = [];
        // process deletes
        _.chain(classifications).where({ delete: true }).each(function (c) { promiseList.push(deleteClassification(c.id)); });
        // process edits
        _.chain(classifications).filter(function (t) { if (!t.delete) { return true; } }).each(function (c) { promiseList.push(saveClassification(c.id, c.taxonomy_id, { _name: c.c, parent_id: c.parent_id })); });

        // chain all the saving promises
        var doAll = $q.all(promiseList);
        doAll.then(function (r) {
            deferred.resolve(r);
        }).catch(function (ex) {
            deferred.reject(ex);
        });
        return deferred.promise;
    }

    // private function to save a Classification
    function saveClassification(id, taxonomy_id, key_value_data) {
        var deferred = $q.defer();
        var options = {
            pmtId: pmt.id[pmt.env],
            instance_id: pmt.instance,
            user_id: $rootScope.currentUser.user.id,
            classification_id: id,
            taxonomy_id: taxonomy_id,
            key_value_data: key_value_data,
            delete_record: false
        };
        var header = {
            headers: { Authorization: 'Bearer ' + $rootScope.currentUser.token }
        };
        // call the api
        $http.post(pmt.api[pmt.env] + 'pmt_edit_classification', options, header).success(function (data, status, headers, config) {
            deferred.resolve(data[0].response);
        }).error(function (data, status, headers, c) {
            // there was an error report it to the error handler
            console.log("error on api call to: ", data);
            deferred.reject(data.message);
        });
        return deferred.promise;
    }

    // private function to delete a Classification
    function deleteClassification(id) {
        var deferred = $q.defer();
        var options = {
            pmtId: pmt.id[pmt.env],
            instance_id: pmt.instance,
            user_id: $rootScope.currentUser.user.id,
            classification_id: id,
            taxonomy_id: null,
            key_value_data: null,
            delete_record: true

        };
        var header = {
            headers: { Authorization: 'Bearer ' + $rootScope.currentUser.token }
        };
        // call the api
        $http.post(pmt.api[pmt.env] + 'pmt_edit_classification', options, header).success(function (data, status, headers, config) {
            deferred.resolve(data[0].response);
        }).error(function (data, status, headers, c) {
            // there was an error report it to the error handler
            console.log("error on api call to: ", data);
            deferred.reject(data.message);
        });
        return deferred.promise;
    }

    //returns a class that can display virtual data - this is the child/classification data for the taxonomy editor page
    taxonomyService.getVirtualClassifications = function (taxonomy_id, inuse) {
        // In this example, we set up our model using a class.
        // Using a plain object works too. All that matters
        // is that we implement getItemAtIndex and getLength.
        var DynamicItems = function () {
            /**
             * @type {!Object<?Array>} Data pages, keyed by page number (0-index).
             */
            this.loadedPages = [];

            /** @type {number} Total number of items. */
            this.numItems = 0;

            /** @const {number} Number of items to fetch per request. */
            this.PAGE_SIZE = 20;

            this.fetchNumItems_();
        };

        // Required.
        DynamicItems.prototype.getItemAtIndex = function (index) {
            var pageNumber = Math.floor(index / this.PAGE_SIZE);
            var page = this.loadedPages[pageNumber];

            if (page) {
                return page[index % this.PAGE_SIZE];
            } else if (page !== null) {
                this.fetchPage_(pageNumber);
            }
        };

        // Required.
        DynamicItems.prototype.getLength = function () {
            return this.numItems;
        };

        DynamicItems.prototype.fetchPage_ = function (pageNumber) {
            // Set the page to null so we know it is already being fetched.
            this.loadedPages[pageNumber] = null;
            //get all classifcations for the taxonomy
            taxonomyService.getTaxonomyClassifications(taxonomy_id, inuse, pageNumber * this.PAGE_SIZE, this.PAGE_SIZE).then(angular.bind(this, function (classifications) {
                this.loadedPages[pageNumber] = [];
                for (var i = 0; i < this.PAGE_SIZE; i++) {
                    this.loadedPages[pageNumber].push(classifications[i] || null);
                }
            }));
        };

        DynamicItems.prototype.fetchNumItems_ = function (doFetch) {
            //get total number of classification records per taxonomy
            taxonomyService.getTaxonomyClassificationsCount(taxonomy_id).then(angular.bind(this, function (count) {
                this.numItems = count;
                if (doFetch) this.fetchPage_(0);
            }));
        };

        if (taxonomyService.taxonomies) {
            var tax = _.chain(taxonomyService.taxonomies).compact().flatten().find({ id: taxonomy_id }).value();
            if (tax) {
                tax.classifications = new DynamicItems();
            }
        }

    }

    // gets and returns list of classifications for a taxonomy
    taxonomyService.getTaxonomyClassifications = function (taxonomy_id, inuse, offset, limit) {
        var deferred = $q.defer();
        var data_group_ids = null;
        if (inuse) {
            data_group_ids = filter.data_group_ids.join(',');
        }
        var options = {
            taxonomy_id: taxonomy_id, // taxonomy id
            data_group_ids: data_group_ids, // return in-use classifications for data groups listed, otherwise all classifications
            locations_only: false, // return in-use classifications for activities with locations only
            pmtId: pmt.id[pmt.env],
            instance_id: pmt.instance,
            return_core: false,
            offsetter: offset,
            limiter: limit
        };
        var header = {
            headers: { Authorization: 'Bearer ' + $rootScope.currentUser.token }
        };
        // call the api to get the classifications for a given taxonomy
        $http.post(pmt.api[pmt.env] + 'pmt_classification_search', options, header, { cache: true })
            .success(function (data, status, headers, config) {
                //new classification will have a delete of false
                var classifications = _.chain(data).pluck('response').map(function (c) {
                    c.delete = false;
                    c.showNest = false;
                    c.taxonomy_id = taxonomy_id; //include to make saving easier
                    return c;
                }).value();

                //add tax id to child classes to make saving simpler
                _(classifications).each(function(classification){
                    _.chain(classification.children).flatten().compact().each(function (c) {
                        c.parent_id = classification.id;
                        c.delete = false; // make sure it displays unless user selects to delete it 
                        c.taxonomy_id = taxonomy_id; //include to make saving easier
                    });
                });

                deferred.resolve(classifications);
            })
            .error(function (data, status, headers, c) {
                // there was an error report it to the error handler
                console.log("error on api call to: pmt_classifications");
                deferred.reject(status);
            });
        return deferred.promise;
    };

    // gets and returns list of classifications for a taxonomy
    taxonomyService.getTaxonomyClassificationsCount = function (taxonomy_id, inuse) {
        var deferred = $q.defer();
        var data_group_ids = null;
        if (inuse) {
            data_group_ids = filter.data_group_ids.join(',');
        }
        var options = {
            taxonomy_id: taxonomy_id, // taxonomy id
            data_group_ids: data_group_ids, // return in-use classifications for data groups listed, otherwise all classifications
            locations_only: false, // return in-use classifications for activities with locations only
            pmtId: pmt.id[pmt.env],
            instance_id: pmt.instance,
            return_core: false
        };
        var header = {
            headers: { Authorization: 'Bearer ' + $rootScope.currentUser.token }
        };
        // call the api to get the classifications for a given taxonomy
        $http.post(pmt.api[pmt.env] + 'pmt_classification_count', options, header, { cache: true })
            .success(function (data, status, headers, config) {
                //new classification will have a delete of false
                var count = _.chain(data).pluck('response').map(function (c) {
                    return c.count;
                }).first().value();

                deferred.resolve(count);
            })
            .error(function (data, status, headers, c) {
                // there was an error report it to the error handler
                console.log("error on api call to: pmt_classifications");
                deferred.reject(status);
            });
        return deferred.promise;
    };

    return taxonomyService;
});
