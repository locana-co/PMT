/***************************************************************
 * Organization Page List Controller
 * Supports the taxonomy page's list feature.
 * *************************************************************/
angular.module('PMTViewer').controller('TaxListCtrl', function ($scope, $rootScope, stateService, config, taxonomyService, $mdDialog) {
    $scope.stateService = stateService;
    // loader
    $scope.loading = false;
    // user error message
    $scope.error = false;
    // taxonomy list
    $scope.taxonomyList = null;
    // taxonomy list
    $scope.searchText = "";
    // settings for page rendering 
    $scope.settings = $scope.page.tools;
    // hold active class for displaying 
    $scope.activeClassifications = [];
    var timeout = null;

    // when the taxonomy list needs refreshing do this
    $scope.$on('refresh-tax-list', function () {
        init(true);
    });

    // whenever we need to refresh the list
    $scope.$on('refresh-taxonomy', function (event, data) {
        $scope.taxonomyList = $scope.taxonomyList || [];

        // $scope.taxonomyList.fetchNumItems_(true); //get the new count of items and reget the first page
        $scope.taxonomyForm.$setPristine(true); //form set back to clean
        init(true, data.id);
    });

    // whenever we need to refresh just 1 taxonomy in the list
    $scope.$on('refresh-classification', function (context, id) {
        taxonomyService.getTaxes(null, null, id).then(function (data) {
            $scope.taxonomyList = data;
        });
    });

    // whenever we need save edits to the list
    $scope.$on('save-taxonomy', function () {
        $scope.errorMessage = "";
        // make sure all taxonomies have classifications, else don't let the user save. 
        validateForm();
        // if validation fails stop the save from completing
        if ($scope.errorOnForm) {
            return;
        }

        // get changed taxonomies
        var changedTaxonomies = _($scope.taxonomyList).filter(function (t) { if (t.isDirty || t.delete) { return true; } });
        // setup counter
        var count = 0, max = changedTaxonomies.length > 0 ? 1 : 0;
        //validate changed taxonomies
        _(changedTaxonomies).each(function (t) {
            checkForDupes("Taxonomy", t.Name, _($scope.taxonomyList).pluck("Name"));
        });
        // loop through classificaiton data and determine which have changes
        // get all loaded classifications
        var allClassifications = _.chain($scope.taxonomyList).pluck("classifications").pluck("loadedPages").flatten().compact().value();
        // determine which classifications have edits
        var parentClassifications = _(allClassifications).filter(function (c) { if (c.isDirty || c.delete) { return true; } });
        var childClassifications = _.chain(allClassifications).pluck("children").flatten().compact().filter(function (c) { if (c.isDirty || c.delete) { return true; } }).value();
        var changedClassifications = _.union(parentClassifications, childClassifications);
        max += changedClassifications.length > 0 ? 1 : 0;
        //validate parent classes (can only check for classifications that have been loaded. Will also have to check for duplicates on database side)
        _(parentClassifications).each(function (p) {
            checkForDupes("Classification", p.c, _.chain(allClassifications).where({ taxonomy_id: p.taxonomy_id }).pluck("c").value());
        });
        //validate child classes
        _(childClassifications).each(function (c) {
            checkForDupes("Child Classification", c.c, _.chain(allClassifications).where({ taxonomy_id: c.taxonomy_id }).where({id: c.parent_id}).pluck("children").first().pluck("c").value());
        });

        if ($scope.errorOnForm) {
            //remove trailing separator
            if($scope.errorMessage.indexOf("  |  " > -1)){
                $scope.errorMessage = $scope.errorMessage.substring(0,$scope.errorMessage.length-4);
            }

            $mdDialog.show(
                $mdDialog.alert()
                    .parent(angular.element(document.querySelector('#tax')))
                    .clickOutsideToClose(true)
                    .title('Errors detected on form')
                    .textContent('Please correct all errors and try again')
                    .ariaLabel('Errors')
                    .ok('Ok')
                    .targetEvent(event)
            );
            return;
        }
        // check for no changes
        if (changedTaxonomies.length === 0 && changedClassifications.length === 0) {
            $mdDialog.show(
                $mdDialog.alert()
                    .parent(angular.element(document.querySelector('#tax')))
                    .clickOutsideToClose(true)
                    .title('No changes detected')
                    .textContent('Please make a change before saving')
                    .ariaLabel('No Changes')
                    .ok('Ok')
                    .targetEvent(event)
            );
        } else {
            if (changedTaxonomies.length > 0) {
                // save changes
                taxonomyService.saveTaxonoimes(changedTaxonomies).then(function (response) {
                    count += 1;
                    // if not an error and all requested completed.
                    if (count === max) {
                        saveComplete();
                        $scope.taxonomyForm.$setPristine(true); //form set back to clean
                        init();
                    }

                });
            }

            if (changedClassifications.length > 0) {
                // save changes
                taxonomyService.saveClassifications(changedClassifications).then(function (response) {
                    count += 1;
                    // if not an error and all requested completed.
                    if (count === max) {
                        saveComplete();
                        $scope.taxonomyForm.$setPristine(true); //form set back to clean
                        init();
                    }
                });
            }
        }
    });

    // losing the forms pristine state during data load, resetting back from time to time
    $scope.$on('tax-list-pristine', function () {
        $scope.taxonomyForm.$setPristine(true);
    });

    // when add button is clicked
    $scope.$on('add-taxonomy', function () {
        if ($scope.taxonomyForm.$dirty) {
            var confirm = $mdDialog.confirm()
                .title('Are you sure you want to create a taxonomy? All unsaved edits will be lost.')
                .ariaLabel('create confirmation')
                .targetEvent(event)
                .ok('Yes, Create')
                .cancel('No, Cancel');
            $mdDialog.show(confirm).then(function () {
                $mdDialog.show({
                    controller: 'TaxCreateTaxonomyCtrl',
                    templateUrl: 'tax/create-tax/create-tax.tpl.html',
                    parent: angular.element(document.body),
                    // targetEvent: event,
                    clickOutsideToClose: true,
                    bindToController: true,
                    // scope: $scope,
                    preserveScope: false,
                    locals: {
                        model: {
                            id: null,
                            parent_id: null,
                            _is_category: false, // does not support nested classifications by default
                            _description: null,
                            _name: null
                        }
                    }
                }).then(function () {
                    // $rootScope.$broadcast('refresh-taxonomy');
                });
            }, function () { });
        } else {
            $mdDialog.show({
                controller: 'TaxCreateTaxonomyCtrl',
                templateUrl: 'tax/create-tax/create-tax.tpl.html',
                parent: angular.element(document.body),
                // targetEvent: event,
                clickOutsideToClose: true,
                bindToController: true,
                // scope: $scope,
                preserveScope: false,
                locals: {
                    model: {
                        id: null,
                        classifications: {},
                        inFilter: true,
                        delete: false,
                        _description: null,
                        _iati_codelist: null,
                        _name: null
                    }
                }
            }).then(function () {
                // $rootScope.$broadcast('refresh-taxonomy');
            });
        }
    });

    // when popup button is clicked
    $scope.viewDetail = function (classification, e) {
        $scope.popupClass = classification;
        $mdDialog.show({
            scope: $scope,
            preserveScope: true,
            controller: showAllController,
            bindToController: true,
            templateUrl: 'tax/list/show-all-activities-modal.tpl.html',
            controllerAs: 'ctrl',
            parent: angular.element(document.body),
            clickOutsideToClose: true,
            targetEvent: event
        });
    };

    // when assignment button is clicked
    $scope.editDetail = function (tax, e) {
        if ($scope.taxonomyForm.$dirty) {
            var confirm = $mdDialog.confirm()
                .title('Are you sure you want to change assignments for this taxonomy? All unsaved edits will be lost.')
                .ariaLabel('create confirmation')
                .targetEvent(event)
                .ok('Yes, Continue')
                .cancel('No, Cancel');
            $mdDialog.show(confirm).then(function () {
                stateService.setParamWithVal('tax_id', tax.id.toString());
                //create an activity object to store in activity service
                var t = {
                    id: tax.id,
                    _name: tax._name
                };
                taxonomyService.setSelectedTaxonomy(t);
            }, function () { });
        } else {

            stateService.setParamWithVal('tax_id', tax.id.toString());
            //create an activity object to store in activity service

            var t = {
                id: tax.id,
                _name: tax._name
            };
            taxonomyService.setSelectedTaxonomy(t);
        }
    };

    // react to arrow being clicked by user on taxonomy group
    $scope.onArrowClicked = function (classification, taxId, e) {
        //set children to an emptry array if it's null
        classification.children = classification.children || [];
        //update the displayed child classs
        $scope.activeClassifications[taxId] = classification;
        $scope.activeClassifications[taxId].showNest = true; //!$scope.activeClassifications[taxId]!=classification; //toggle group
    };

    // apply search to form (performed on db)
    $scope.searchTaxList = function (e) {
        //need to give the user a chance to finish typing. 
        //Start a timeout and clear it if user types again before that time is up
        if (timeout) { timeout = clearTimeout(timeout); }

        //if the user has pressed enter, then bypass the timeout
        if (e.keyCode !== 13) {
            timeout = setTimeout(function () {
                taxonomyService.searchText = $scope.searchText;
                taxonomyService.getTaxes(null, null, null).then(function (data) {
                    $scope.taxonomyList = data;
                });
            }, 1000); //1 second
        } else {
            //search right away
            taxonomyService.searchText = $scope.searchText;
            taxonomyService.getTaxes(null, null, null).then(function (data) {
                $scope.taxonomyList = data;
            });
        }

    };

    // delete entire taxonomy
    $scope.deleteTax = function (tax) {
        var confirm = $mdDialog.confirm()
            .title('Are you sure you want to delete this taxonomy and all of its classifications?')
            .ariaLabel('delete confirmation')
            .targetEvent(event)
            .ok('Yes, Delete')
            .cancel('No, Cancel');
        $mdDialog.show(confirm).then(function () {
            //$scope.taxonomyList.numItems -= 1;
            //mark as deleted
            tax.delete = true;
            // notify form of change
            $scope.taxonomyForm.$setDirty();
            //update count on page
            $rootScope.$broadcast('tax-list-updated');
        }, function () { });
    };

    // create new classifcation for a given taxonomy
    // too much trouble to add locally to list, will have to add directly to the db. 
    // will warn user that a save here will save all other edits to this taxonomy
    $scope.addClassificationRecord = function (tax) {
        tax.classifications = tax.classifications || [];
        if ($scope.taxonomyForm.$dirty) {
            var confirm = $mdDialog.confirm()
                .title('Are you sure you want to create a classification? All unsaved edits for this taxonomy will be lost.')
                .ariaLabel('create confirmation')
                .targetEvent(event)
                .ok('Yes, Create')
                .cancel('No, Cancel');
            $mdDialog.show(confirm).then(function () {
                $mdDialog.show({
                    controller: 'TaxCreateClassificationCtrl',
                    templateUrl: 'tax/create-class/create-class.tpl.html',
                    parent: angular.element(document.body),
                    //targetEvent: event,
                    clickOutsideToClose: true,
                    bindToController: true,
                    //scope: $scope,
                    preserveScope: false,
                    locals: {
                        parent: tax.id,
                        model: {
                            id: null,
                            c: "",
                            taxonomy_id: tax.id,
                            children: null,
                            delete: false,
                            showNest: false
                        }
                    }
                }).then(function (classifcation) {

                });
            }, function () { });
        } else {
            $mdDialog.show({
                controller: 'TaxCreateClassificationCtrl',
                templateUrl: 'tax/create-class/create-class.tpl.html',
                parent: angular.element(document.body),
                //targetEvent: event,
                clickOutsideToClose: true,
                bindToController: true,
                //scope: $scope,
                preserveScope: false,
                locals: {
                    parent: tax.id,
                    model: {
                        id: null,
                        c: "",
                        taxonomy_id: tax.id,
                        children: null,
                        delete: false,
                        showNest: false
                    }
                }
            }).then(function (classifcation) {

            });
        }
    };

    // delete classifcation for a given taxonomy
    $scope.deleteClassificationRecord = function (tax, classification) {
        var confirm = $mdDialog.confirm()
            .title('Are you sure you want to delete this classification?')
            .ariaLabel('delete confirmation')
            .targetEvent(event)
            .ok('Yes, Delete')
            .cancel('No, Cancel');
        $mdDialog.show(confirm).then(function () {
            //tax.classifications = tax.classifications || {};
            //tax.classifications.numItems -= 1; //remove from count
            classification.delete = true;
            //notify form of change
            $scope.taxonomyForm.$setDirty();
        }, function () { });
    };

    // create new child for a given classification
    $scope.addChildRecord = function (classification, taxonomy_id) {
        //classification.isDirty = true; //note the edit
        classification.children.unshift({
            id: null,
            c: "",
            parent_id: classification.id,
            taxonomy_id: taxonomy_id, //include to make saving easier
            delete: false,
            showNest: false
        });
    };

    // delete child for a given taxonomy
    $scope.deleteChildRecord = function (child) {
        var confirm = $mdDialog.confirm()
            .title('Are you sure you want to delete this child?')
            .ariaLabel('delete confirmation')
            .targetEvent(event)
            .ok('Yes, Delete')
            .cancel('No, Cancel');
        $mdDialog.show(confirm).then(function () {
            child.delete = true;
        }, function () { });
    };

    // make activity row dirty so we know to update it on save
    $scope.makeDirty = function (record) {
        record.isDirty = true;
    };

    function init(reload, id) {
        // reset search 
        taxonomyService.searchText = $scope.searchText = null;
        $scope.loading = true; // show loader

        if ($scope.error) {
            $scope.loading = false;
            $scope.taxonomyList = null;
        }
        else {
            // list is not initialized
            if ($scope.taxonomyList === null || reload) {
                //if asking to reload, clear the service's list
                if (reload) {
                    //clear all stored data
                    taxonomyService.taxonomies = null;
                    $scope.taxonomyList = [];
                }
                taxonomyService.getTaxes(null, null, null).then(function (data) {
                    if (id) {
                        var newTaxonomy = _.find(data, function (taxonomy) { return taxonomy.id === id; });
                        $scope.taxonomyList = moveObjectInArray(newTaxonomy, data);
                    }
                    else {
                        $scope.taxonomyList = data;
                    }
                    $scope.taxonomyForm.$setPristine(true); // form set back to clean
                    // console.log("$scope.taxonomyList", $scope.taxonomyList);
                });
                $scope.loading = false;
            }
            else {
                $scope.loading = false;
                $rootScope.$broadcast('tax-list-updated');
            }
        }
    }

    function moveObjectInArray(foo, arr) {
        for (var i = 0; i < arr.length; i++) {
            if (arr[i].id === foo.id) {
                var a = arr.splice(i, 1);   // removes the item
                arr.unshift(a[0]);         // adds it back to the beginning
                break;
            }
        }
        return arr;
    }

    //check for duplcate names
    function checkForDupes(type, name, list) {
        var finds = 0;
        //see if the name is found in any of the existing list of values
        _(list).each(function (item) {
            if (item === name) { finds += 1; }
        });

        //if found, add to error message
        if (finds > 1) {
            $scope.errorOnForm = true;
            $scope.errorMessage += "Duplicate " + type + " '" + name + "' found.  |  ";
        }

    }

    // controller for the show-all modal
    function saveComplete() {
        $mdDialog.show(
            $mdDialog.alert()
                .parent(angular.element(document.querySelector('#tax')))
                .clickOutsideToClose(true)
                .title('Save Successful')
                .textContent('Your changes have been successfully saved!')
                .ariaLabel('Taxonomy Save')
                .ok('Ok')
                .targetEvent(event)
        );
    }

    // controller for the show-all modal
    function showAllController($scope, $mdDialog) {
        $scope.closeDialog = function () {
            $mdDialog.hide();
            return;
        };
    }

    // internal function to check validity of form
    function validateForm() {
        $scope.errorOnForm = false;
        _($scope.taxonomyList).each(function (t) {
            if (_.chain(t.classifications.loadedPages).flatten().compact().value().length === 0) {
                $scope.errorOnForm = true;
                $scope.errorMessage = "All taxonomies must have as least 1 defined classification.";
            }

            _.chain(t.classifications.loadedPages).flatten().compact().each(function (c) {
                if (!c.c && c.c === "") {
                    $scope.errorOnForm = true;
                    $scope.errorMessage = "Name is required on all classifications.";
                }

                if (c.children && c.children.length > 0) {
                    if (_(t.children).filter(function (a) { if (!a.c || a.c === "") { return true; } }).length > 0) {
                        $scope.errorOnForm = true;
                        $scope.errorMessage = "Name is required on all child classifications.";
                    }
                }
            });
        });
    }

    // initialize view
    init(false);
});