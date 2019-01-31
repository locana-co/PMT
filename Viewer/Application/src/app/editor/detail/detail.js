module.exports = angular.module('PMTViewer').controller('EditorDetailCtrl', function EditorDetailCtrl($scope, $rootScope, $mdDialog, $timeout, stateService, utilService, editorService, mapService, partnerLinkService, blockUI, config, pmt) {
    // initialized flag for map
    var initialize = false;
    // add state service to scope
    $scope.stateService = stateService;
    // editor settings
    $scope.settings = $scope.page.tools.editor;
    // toggle settings
    $scope.select = { admin1: false, admin2: false, admin3: false };
    // loader
    $scope.loading = false;
    // loader
    $scope.warnedOnce = false;
    // loading error
    $scope.error = false;
    // selected tab index
    $scope.tabIndex = 0;
    //org types for picker
    $scope.organizationTypes = [];
    // default flag
    $scope.flag = 'https://s3.amazonaws.com/v10.investmentmapping.org/themes/flags/default_flag.jpg';
    //determine if user can change activity version
    $scope.isAdmin = $rootScope.currentUser.user.role_auth._security;
    $scope.version = null;
    $scope.versionMessage = "";
    //list used to add sub financial details
    $scope.subFinancialList = [];
    // initialize map
    initializeMap();
    // initialize activity
    setActivity();
    //initalizae locations
    setLocations();

    // when the editor activity needs refreshing do this
    $scope.$on('refresh-editor-activity', function () {
        setActivity();
    });

    // open the org-selector modal
    // org_type: funding, implementing, accountable or all
    // record_type: provider, recipient, participant
    $scope.openOrgSelector = function (event, org_type, org_id, record_type, record) {
        $scope.selectedRecord = record;
        $scope.dialogSettings = {
            orgType: org_type,
            selectedOrg: org_id,
            roleIds: $scope.settings.organization[org_type]
        };
        $mdDialog.show({
            controller: 'EditorOrgSelectorCtrl',
            templateUrl: 'editor/org-selector/org-selector.tpl.html',
            parent: angular.element(document.body),
            targetEvent: event,
            clickOutsideToClose: true,
            bindToController: true,
            scope: $scope,
            preserveScope: true, // keep scope when dialog is closed
            locals: { dialogSettings: $scope.dialogSettings }
        }).then(function (selectedOrg) {
            switch (record_type) {
                case 'provider':
                    $scope.selectedRecord.provider_id = selectedOrg.id;
                    $scope.selectedRecord.provider = selectedOrg.n;
                    break;
                case 'recipient':
                    $scope.selectedRecord.recipient_id = selectedOrg.id;
                    $scope.selectedRecord.recipient = selectedOrg.n;
                    break;
                case 'participant':
                    $scope.selectedRecord.id = selectedOrg.id;
                    $scope.selectedRecord._name = selectedOrg.n;
                    break;
                case 'contact':
                    $scope.selectedRecord.organization_id = selectedOrg.id;
                    $scope.selectedRecord.organization_name = selectedOrg.n;
                    break;
                default:
                    break;
            }
        });
    };

    // user clicked "plus" sign next to location admin level
    // opens the location selection modal
    $scope.openLocationSelector = function (event, admin_level) {
        $scope.dialogSettings = {
            admin_level: admin_level,
            activity: $scope.edited_activity
        };
        blockUI.start();
        $mdDialog.show({
            controller: 'EditorLocationSelectorCtrl',
            templateUrl: 'editor/location-selector/location-selector.tpl.html',
            parent: angular.element(document.body),
            targetEvent: event,
            clickOutsideToClose: true,
            bindToController: true,
            scope: $scope,
            preserveScope: true, // keep scope when dialog is closed
            locals: { dialogSettings: $scope.dialogSettings }
        }).then(function (selectedLocations) {
            var newLocations = [];
            switch (admin_level) {
                case 1:
                    _.each(selectedLocations, function (l) {
                        var location = _.find($scope.edited_activity.locations.admin1, function (a) { return a.feature_id === l.id; });
                        // location exists
                        if (location) {
                            location.delete = false;
                            newLocations.push(location);
                        }
                        else {
                            var newLocation = {
                                _admin1: l.n,
                                _admin2: null,
                                _admin3: null,
                                _admin_level: 1,
                                boundary_id: $scope.settings.location.boundaries.admin1,
                                delete: false,
                                feature_id: l.id,
                                highlight: false,
                                id: null
                            };
                            $scope.edited_activity.locations.admin1.push(newLocation);
                            newLocations.push(newLocation);
                        }
                    });
                    editorService.addFeatures(newLocations, 1);
                    break;
                case 2:
                    _.each(selectedLocations, function (l) {
                        var location = _.find($scope.edited_activity.locations.admin2, function (a) { return a.feature_id === l.id; });
                        // location exists
                        if (location) {
                            location.delete = false;
                            newLocations.push(location);
                        }
                        else {
                            var newLocation = {
                                _admin1: l.n1,
                                _admin2: l.n,
                                _admin3: null,
                                _admin_level: 2,
                                boundary_id: $scope.settings.location.boundaries.admin2,
                                delete: false,
                                feature_id: l.id,
                                highlight: false,
                                id: null
                            };
                            $scope.edited_activity.locations.admin2.push(newLocation);
                            newLocations.push(newLocation);
                        }
                    });
                    editorService.addFeatures(newLocations, 2);
                    break;
                case 3:
                    _.each(selectedLocations, function (l) {
                        var location = _.find($scope.edited_activity.locations.admin3, function (a) { return a.feature_id === l.id; });
                        // location exists
                        if (location) {
                            location.delete = false;
                            newLocations.push(location);
                        }
                        else {
                            var newLocation = {
                                _admin1: l.n1,
                                _admin2: l.n2,
                                _admin3: l.n,
                                _admin_level: 3,
                                boundary_id: $scope.settings.location.boundaries.admin3,
                                delete: false,
                                feature_id: l.id,
                                highlight: false,
                                id: null
                            };
                            $scope.edited_activity.locations.admin3.push(newLocation);
                            newLocations.push(newLocation);
                        }
                    });
                    editorService.addFeatures(newLocations, 3);
                    break;
            }
        });
    };

    // open the contact-selector modal
    // user chooses option after add contact record is clicked 
    $scope.openContactSelector = function () {
        $scope.dialogSettings = {
            idsToExclude: _($scope.edited_activity.contacts).pluck("id") || [],
            selectedContact: null
        };
        $mdDialog.show({
            controller: 'EditorContactSelectorCtrl',
            templateUrl: 'editor/contact-selector/contact-selector.tpl.html',
            parent: angular.element(document.body),
            //targetEvent: event,
            clickOutsideToClose: true,
            bindToController: true,
            scope: $scope,
            preserveScope: true, // keep scope when dialog is closed
            locals: { dialogSettings: $scope.dialogSettings }
        }).then(function (record) {
            //make sure contacts array has been initialized
            if (!Array.isArray($scope.edited_activity.contacts)) { $scope.edited_activity.contacts = []; }
            //add blank record
            $scope.edited_activity.contacts.push($scope.dialogSettings.selectedContact);
        });
    };

    // user changed an input being tracked for potential duplicates
    $scope.changeContact = function (event, record) {
        //make sure this is a new record
        if ((!record.id || record.id > -1) && (record._first_name && record._last_name && record._email && record._first_name !== "" && record._last_name !== "" && record._email !== "")) {
            $scope.contacts = editorService.getAllContacts();

            if ($scope.contacts.length <= 0) {
                editorService.getContacts().then(function (contacts) {
                    $scope.contacts = contacts;
                    contactsReady($scope, $scope.contacts, record);
                });
            } else {
                contactsReady($scope, $scope.contacts, record);
            }
        }
    };

    //edit child activity
    $scope.editChildActivity = function (child_activity, parent_id, parent_title) {
        var params = {
            editor_activity_id: child_activity.id.toString(),
            editor_parent_id: parent_id.toString(),
            editor_parent_title: parent_title.toString()
        };

        if (editorService.isDirty()) {
            // appending dialog to document.body to cover sidenav in docs app
            var confirm = $mdDialog.confirm()
                .title('Are you sure you want to go to the related activity? All changes to this record will be lost!')
                .ariaLabel('change confirmation')
                .targetEvent(event)
                .ok('Yes, Go to Activity')
                .cancel('No, Stay');
            $mdDialog.show(confirm).then(function () {
                stateService.setState("editor", params, true);
            }, function () { });
        } else {
            //go to child
            stateService.setState("editor", params, true);
        }

    };

    // user clicked "Add Financial Record" button
    $scope.addFinancialRecord = function () {
        var newRecord = newFinancialRecord();
        if (Array.isArray($scope.edited_activity.financials)) {
            $scope.edited_activity.financials.push(newRecord);
        }
        else {
            $scope.edited_activity.financials = [];
            $scope.edited_activity.financials.push(newRecord);
        }
    };

    //add simple detail record
    $scope.addDetailRecord = function () {
        $scope.edited_activity.details = $scope.edited_activity.details || []; //*figure where this should be defined 
        $scope.edited_activity.details.push({
            _title: null,
            id: null,
            activity_id: $scope.edited_activity.id,
            delete: false,
            _updated_date: utilService.formatShortDate(new Date()),
            _created_date: utilService.formatShortDate(new Date())
        });
    };

    //add new child record
    $scope.addChildRecord = function () {
        $scope.edited_activity.children = $scope.edited_activity.children || []; //*figure where this should be defined 
        $scope.edited_activity.children.push({
            _title: null,
            id: null,
            parent_id: $scope.edited_activity.id,
            delete: false
        });
    };

    // user clicked "Add Contact Record" button
    $scope.addContactRecord = function () {
        //check to see if any records have been marked for deletion and remove from array.
        _.chain($scope.edited_activity.contacts).where({ deleted: true }).each(function (o) {
            $scope.edited_activity.contacts = _($scope.edited_activity.contacts).without(o);
        });

        var question = $mdDialog.confirm()
            .title('How would you like to add?')
            .ariaLabel('confirm add type')
            .targetEvent(event)
            .ok('New Contact')
            .cancel('Lookup Contact');
        $mdDialog.show(question).then(function (result) {
            //create new record by hand
            var newRecord = {
                id: null,
                _first_name: null,
                _last_name: null,
                _name: null,
                _email: null,
                _title: null,
                organization_id: null,
                organization_name: null,
                delete: false
            };
            //make sure contacts array has been initialized
            if (!Array.isArray($scope.edited_activity.contacts)) { $scope.edited_activity.contacts = []; }
            //add blank record
            $scope.edited_activity.contacts.push(newRecord);
        }, function () {
            //open a popup with exiting user to choose from 
            $scope.openContactSelector();
        });
    };

    // user clicked "Add Organization Record" button
    $scope.addParticipationRecord = function () {
        var newRecord = newParticipationRecord();
        $scope.edited_activity.organizations.push(newRecord);
    };

    // user clicked "Delete Record"
    $scope.deleteRecord = function (event, record) {
        // determine if record is empty
        var notEmpty = false;
        _.each(_.pairs(record), function (field) {
            if (!_.contains(["delete"], field[0]) && field[1] != null) {
                notEmpty = true;
            }
        });
        // if record is not empty, request confirmation before delete
        if (notEmpty) {
            var that = this;
            var confirm = $mdDialog.confirm()
                .title('Are you sure you want to delete this record?')
                .ariaLabel('delete confirmation')
                .targetEvent(event)
                .ok('Yes, Delete')
                .cancel('No, Cancel');
            $mdDialog.show(confirm).then(function () {
                // mark as deleted
                record.delete = true;
                // location record
                if (_.has(record, '_admin_level')) {
                    record.highlight = false;
                    editorService.removeFeature(record);
                }

                //contact record
                if (record.id === null && $(event.currentTarget).attr("type") === "contact") {
                    //go ahead and remove from collection
                    that.edited_activity.contacts = _(that.edited_activity.contacts).without(record);
                }
            }, function () { });
        }
        // mark as deleted
        else {
            record.delete = true;
            //contact record
            if ($(event.currentTarget).attr("type") === "contact") {
                //go ahead and remove from collection
                this.edited_activity.contacts = _(this.edited_activity.contacts).without(record);
            }
        }
    };

    // calculate financial total
    $scope.calculateFinancialTotal = function () {
        var total = 0;
        if ($scope.edited_activity) {
            _.each($scope.edited_activity.financials, function (f) {
                if (!f.delete) {
                    total += f._amount;
                }
            });
        }
        return utilService.formatMoney(total.toFixed(2));
    };

    // calculate financial total
    $scope.calculatePercentFinancialTotal = function (percent) {
        var total = 0;
        if ($scope.edited_activity) {
            _.each($scope.edited_activity.financials, function (f) {
                if (!f.delete) {
                    total += f._amount;
                }
            });
        }
        return utilService.formatMoney(((percent / 100) * total).toFixed(2));
    };

    // highlight feature
    $scope.toggleHighlight = function (location) {
        var filters = editorService.toggleHighlight(location);
        if (_.contains(filters, location.feature_id)) {
            location.highlight = true;
        }
        else {
            location.highlight = false;
        }
    };

    // clear all highlight features
    $scope.clearHighlight = function () {
        editorService.clearHighlights();
        _.each($scope.edited_activity.locations, function (location) {
            if (Array.isArray(location)) {
                _.each(location, function (l) {
                    l.highlight = false;
                });
            }
        });
    };

    // set activity as national
    $scope.setNational = function () {
        // NOTE: logic all assumes that only one country is allowed at the national level
        // if there are sub-national locations notify user and alert that they will be
        // deleted
        if ($scope.getLocationCt($scope.edited_activity.locations.admin1) > 0 ||
            $scope.getLocationCt($scope.edited_activity.locations.admin2) > 0 ||
            $scope.getLocationCt($scope.edited_activity.locations.admin3) > 0) {
            // appending dialog to document.body to cover sidenav in docs app
            var confirm = $mdDialog.confirm()
                .title('Are you sure you want to set this as national ' + $scope.terminology.activity_terminology.singular + '? This will delete all locations at sub-national levels!')
                .ariaLabel('delete confirmation')
                .targetEvent(event)
                .ok('Yes, Set as National')
                .cancel('No, Cancel');
            $mdDialog.show(confirm).then(function () {
                // confirmed deletion of sub-national locations
                _.each($scope.edited_activity.locations.admin1, function (record) {
                    record.delete = true;
                });
                _.each($scope.edited_activity.locations.admin2, function (record) {
                    record.delete = true;
                });
                _.each($scope.edited_activity.locations.admin3, function (record) {
                    record.delete = true;
                });
                // remove all sub-national locations from the map
                editorService.removeFeatures();
                // create national and add to map
                createNational();
                // cancel, do nothing    
            }, function () { });
        }
        // no sub-national location exists, create national location
        else {
            // create national and add to map
            createNational();
        }
    };

    // get filtered location count
    $scope.getLocationCt = function (locations) {
        return _.filter(locations, function (l) { return l.delete === false; }).length;
    };

    // export location template
    $scope.exportLocation = function (e) {
        //
        var locations = [];
        //add header to activity print
        var header = {
            '0': utilService.toTitleCase($scope.terminology.boundary_terminology.singular.admin1) + " Locations",
            '1': utilService.toTitleCase($scope.terminology.boundary_terminology.singular.admin2) + " Locations",
            '2': utilService.toTitleCase($scope.terminology.boundary_terminology.singular.admin3) + " Locations"
        };
        locations.push(header);

        _.each($scope.locations.boundaries, function (admin1) {
            //create first tier location structure to output
            locations.push({
                '0': admin1.n,
                '1': "",
                '2': ""
            });

            _.each(admin1.b, function (admin2) {
                //create second tier location structure to output
                locations.push({
                    '0': admin1.n,
                    '1': admin2.n,
                    '2': ""
                });

                _.each(admin2.b, function (admin3) {
                    //create second tier location structure to output
                    locations.push({
                        '0': admin1.n,
                        '1': admin2.n,
                        '2': admin3.n
                    });
                });
            });
        });

        // download csv
        partnerLinkService.JSONToCSVConvertor(locations, utilService.toTitleCase($scope.terminology.activity_terminology.singular) + "LocationsTemplate", false, null);
    };

    // import location's based off template
    $scope.importLocation = function (e) {
        //
        $scope.fileSettings = {
            invalidRecords: [],
            duplicateRecords: [],
            newRecords: [],
            undeleteRecords: [],
            doReplace: null
        };
        $mdDialog.show({
            controller: 'FileSelectorCtrl',
            templateUrl: 'editor/file-selector/file-selector.tpl.html',
            parent: angular.element(document.body),
            //targetEvent: event,
            clickOutsideToClose: false,
            bindToController: true,
            scope: $scope,
            preserveScope: true // keep scope when dialog is closed
        }).then(function (file) {
            //make sure data came back before attempting to parse
            //if(file) editorService.parseLocationsFromCSV(file);
        });
    };

    // determine if any features are highlighted
    $scope.hasHighlights = function () {
        var highlights = false;
        if ($scope.edited_activity) {
            _.each($scope.edited_activity.locations, function (l) {
                if (Array.isArray(l)) {
                    if (_.contains(_.pluck(l, 'highlight'), true)) {
                        highlights = true;
                    }
                }
            });
        }
        return highlights;
    };

    // determine if an implementing org has been made primary
    $scope.changeOrgPrimary = function (e, org, type) {
        if (org.isPrimary) {
            //checked and should apply to this org
            org.imp_type_id = type.id;
        } else {
            //clear out
            org.imp_type_id = null;
        }
    };

    // react to arrow being clicked by user on taxonomy group
    $scope.onArrowClicked = function (classification, e) {
        classification.showNest = !classification.showNest; //toggle group
    };

    // react to checkbox being clicked by user child taxonomy (select parent)
    $scope.onCheckClicked = function (classification, e) {
        if (!classification.active) {
            classification.active = true;
        }
    };

    // warn user once that if they have values entered they could lose them on save
    $scope.beneficiaryChange = function (oldType, oldUnit) {
        if (!$scope.warnedOnce) {
            var hasData = false;
            _.each($scope.settings.activity.beneficiary, function (field, key) {
                //also make sure the field should have data based on the type/unit selected
                if ((field.types && field.unit) && (field.types.indexOf($scope.edited_activity.beneficiary_type) < 0 || field.unit !== $scope.edited_activity.beneficiary_unit) && $scope.edited_activity[key] !== null) {
                    hasData = true;
                }
            });

            //if the record has data that could be lost, let the user know and give them a chance to cancel 
            if (hasData) {
                $scope.warnedOnce = true; // make sure only 1 time per edit session does this warning display 
                //let user know the user know this change will result in lost data on save
                var confirm = $mdDialog.confirm()
                    .title('Changes Found!')
                    .textContent('Clicking Continue will confirm your change and may result in previous inputs being cleared on save. Click Cancel to undo your change. ')
                    .ariaLabel('confirm change')
                    .targetEvent(event)
                    .ok('Continue')
                    .cancel('Cancel');
                $mdDialog.show(confirm).then(function () {
                    //continue on
                }, function () {
                    $scope.edited_activity.beneficiary_type = oldType;
                    $scope.edited_activity.beneficiary_unit = oldUnit;
                });
            }
        }
    };

    //private function used to lookup user entry against existing contacts
    function contactsReady(scope, contacts, record) {
        var finding = _.chain(contacts).filter(function (o) {
            return o.id !== record.id && o._first_name === record._first_name && o._last_name === record._last_name && o._email === record._email;
        }).first().value();

        if (finding) {
            //if user already in list, warn user
            if (_(scope.edited_activity.contacts).findIndex({ id: finding.id }) >= 0) {
                $mdDialog.alert({
                    title: '',
                    textContent: '',
                    ok: 'Close'
                });

                var alert = $mdDialog.alert()
                    .title('Duplicate Record!')
                    .ariaLabel('Duplicate Record')
                    .textContent('The contact already exists in your list. Please delete this record or enter different contact information.')
                    .targetEvent(event)
                    .ok('Ok');
                $mdDialog.show(alert).then(function () { }, function () { });

                return;
            }
            //get ready to load contact 
            $scope.loading = true;
            blockUI.start();
            //let user know the user exists and that they should select the existing user or change their entry 
            var question = $mdDialog.confirm()
                .title('Existing contact found, would you like to import?')
                .ariaLabel('confirm import')
                .targetEvent(event)
                .ok('Import Contact')
                .cancel('Cancel');
            $mdDialog.show(question).then(function (result) {
                //update model with found contact
                record.id = finding.id;
                record._title = finding._title;
                record.activities = finding.activities;
                record.organization_id = finding.organization_id;
                record.organization_name = finding.organization_name;

                $scope.loading = false;
                blockUI.stop();
            }, function () {
                $scope.loading = false;
                blockUI.stop();
            });
        }
    }

    //private function to store all locations
    function setLocations() {
        $scope.locations = editorService.getBoundaryMenu();
        // if the list is empty then it is the first call, lets populated it
        if (_.isNull($scope.locations)) {
            //  get the options from the service        
            editorService.getBoundaryHierarchy($scope.settings.location.boundary_type, $scope.settings.location.admin_levels, null, null).then(function (menu) {
                $scope.locations = menu;
            });
        }
    }

    // private function to grab activity from url and set page to details
    function setActivity() {
        if (stateService.isParam('editor_activity_id')) {
            // activity id
            if (!isNaN(parseInt(stateService.states.editor.editor_activity_id, 10))) {
                var id = parseInt(stateService.states.editor.editor_activity_id, 10);
                // clear forms & layers
                editorService.clearForms();
                editorService.clearEdits();
                editorService.clearHighlights();
                // new record
                if (id === -1) {
                    createActivity();
                }
                else {
                    // check for user authorization
                    if (_.contains($rootScope.currentUser.user.authorizations, id) ||
                        _.contains(['Super', 'Administrator'], $rootScope.currentUser.user.role)) {
                        // activate loader
                        $scope.loading = true;
                        blockUI.start();
                        // get detail details
                        editorService.getActivity(id).then(function (activity) {
                            // deactivate the loader with a 2 second delay
                            $timeout(function () {
                                $scope.loading = false;
                                blockUI.stop();
                            }, 1000);
                            // get the form information (validation)
                            $scope.forms = editorService.getForms();
                            // and store the dom reference for lookup purposes
                            _($scope.forms).each(function (f, key) {
                                f.form = $("[name='" + key + "']");
                            });
                            // set the activity
                            $scope.edited_activity = editorService.getCurrentActivity();
                            // ensure taxonomies are loaded
                            loadTaxonomies();

                            // set flag if there is a national location
                            if ($scope.edited_activity.locations.national.length > 0) {
                                $scope.flag = 'https://s3.amazonaws.com/v10.investmentmapping.org/themes/flags/' +
                                    $scope.edited_activity.locations.national[0]._admin0.toLowerCase() + '.jpg';
                            }
                        }, function (message) {
                            // deactivate the loader
                            $scope.loading = false;
                            blockUI.stop();
                            // notify of error
                            $scope.error = true;
                        });

                        // loop through the listing of financial taxonomies and load
                        _.each($scope.settings.financial.taxonomies, function (taxonomy) {
                            var loadedTaxonomy = _.find(editorService.financialTaxonomies, function (t) { return t.taxonomy_id == taxonomy.taxonomy_id; });
                            if (!loadedTaxonomy) {
                                editorService.getFinancialTaxonomy(taxonomy).then(function (t) {
                                    $scope.financialTaxonomies = editorService.getFinancialTaxonomies();
                                });
                            }
                        });
                    }
                    // user is not authorized
                    else {
                        // deactivate the loader
                        $scope.loading = false;
                        blockUI.stop();
                        // notify of error
                        $scope.error = true;
                    }
                }
            }
        }
    }

    // private function to create new financial record
    function newFinancialRecord() {
        var newRecord = {
            _amount: null,
            _start_date: null,
            _end_date: null,
            provider: null,
            provider_id: null,
            recipient: null,
            recipient_id: null,
            delete: false,
            taxonomy: []
        };
        // loop through the financial taxonomies and add them to the new record
        _.each($scope.financialTaxonomies, function (taxonomy) {
            var t = {
                classification: null,
                classification_id: null,
                classifications: jQuery.extend(true, {}, taxonomy.classifications),
                label: taxonomy.label,
                taxonomy_id: taxonomy.taxonomy_id
            };
            newRecord.taxonomy.push(t);
        });
        return newRecord;
    }

    //setup list for subfinancial records
    function setSubFinanceList() {
        var existingValues = _.chain($scope.edited_activity.details).where({ _title: null }).where({ delete: false }).pluck("taxonomy").flatten().pluck("classification_id").value();

        return _.chain($scope.taxonomies).where({ childTaxonomy: $scope.settings.financial.childFinancialTaxonomyId }).pluck("classifications")
            .first()
            .map(function (c) { return c.children; })
            .flatten()
            .filter(function (d) { return existingValues.indexOf(d.id) < 0 && !d.delete; })
            .sortBy("c")
            .value();
    }

    //add to list for subfinancial records
    $scope.addSubFinancialListItem = function (id) {
        var item = _($scope.subFinancialList).find({ id: id });
        if (item) {
            //if already in the list marked for delete
            var existingRecord = _.chain($scope.edited_activity.details).where({ _title: null })
                .filter(function (e) {
                    return e.taxonomy && e.taxonomy[0].classification_id == item.id;
                }).first().value();
            if (existingRecord) {
                //updat existing record
                existingRecord.delete = false;
            } else {
                $scope.edited_activity.details = $scope.edited_activity.details || [];
                //add to details list
                $scope.edited_activity.details.push({
                    "id": null, "_title": null, "_description": null, "_amount": 0,
                    "taxonomy": [{
                        "taxonomy_id": $scope.settings.financial.childFinancialTaxonomyId,
                        "taxonomy": $scope.settings.financial.childFinancialTaxonomyTitle,
                        "classification_id": item.id,
                        "classification": item.c,
                        "_code": null
                    }], "details": [], "delete": false, "$$hashKey": ""
                });
            }

            //remove entry from dropdown list
            $scope.subFinancialList = setSubFinanceList();
        }
    };

    //remove from list for subfinancial records
    $scope.deleteSubFinanceRecord = function (e, detail) {
        //remove to details list
        detail.delete = true;

        //add entry from dropdown list
        $scope.subFinancialList = setSubFinanceList();
    };

    // private function to create new participation record
    function newParticipationRecord() {
        var classification = null, classification_id = null;
        //if a child, then default the role to implementing
        if (stateService.isParam('editor_parent_id') && stateService.getState().editor_parent_id && $scope.settings.organization.roles.implementing) {
            classification = $scope.settings.organization.roles.implementing.label;
            classification_id = $scope.settings.organization.roles.implementing.classification_id;
        }
        var newRecord = {
            p_id: null,
            _name: null,
            classification: classification,
            classification_id: classification_id,
            delete: false
        };
        return newRecord;
    }

    // private function to create a national activity
    function createNational() {
        // national location exists, reverse delete flag
        if ($scope.edited_activity.locations.national.length > 0) {
            $scope.edited_activity.locations.national[0].delete = false;
        }
        // create national location
        else {
            var national = _.clone($scope.settings.location.national);
            // add required parameters to each record
            _.extend(national, {
                id: null, delete: false, highlight: false,
                _admin1: null, _admin2: null, _admin3: null
            });
            $scope.edited_activity.locations.national = [national];
            // set flag
            $scope.flag = 'https://s3.amazonaws.com/v10.investmentmapping.org/themes/flags/' +
                $scope.edited_activity.locations.national[0]._admin0.toLowerCase() + '.jpg';
            // clear highlight flags
            _.each($scope.edited_activity.locations, function (location) {
                if (Array.isArray(location)) {
                    _.each(location, function (l) {
                        l.highlight = false;
                    });
                }
            });
        }
        // add national feature to map
        editorService.addFeatures($scope.edited_activity.locations.national, 0);
    }

    // private function to initialize the map
    function initializeMap() {
        try {
            // create the map control
            var map = L.map('editor-map', {
                zoomControl: false,
                scrollWheelZoom: false
            });

            // call the map services to initialize the map
            mapService.init(map);
            mapService.setCursor('default');
            // set map as initialize
            initialized = true;
        }
        // error handler
        catch (ex) {
            // there was an error report it to the error handler
            console.log("There was an error in the detail controller: " + ex);
        }
    }

    // private function to create new activity
    function createActivity() {
        // activate loader
        $scope.loading = true;
        blockUI.start();
        // get detail details
        editorService.createActivity().then(function (activity) {
            // remove all features from the map
            editorService.removeFeatures();
            // deactivate the loader with a 2 second delay
            $timeout(function () {
                $scope.loading = false;
                blockUI.stop();
            }, 2000);
            // get the form information (validation)
            $scope.forms = editorService.getForms();
            // set the activity
            $scope.edited_activity = editorService.getCurrentActivity();
            // ensure taxonomies are loaded
            loadTaxonomies();
        }, function (message) {
            // deactivate the loader
            $scope.loading = false;
            blockUI.stop();
            // notify of error
            $scope.error = true;
        });

        // loop through the listing of financial taxonomies and load
        _.each($scope.settings.financial.taxonomies, function (taxonomy) {
            var loadedTaxonomy = _.find(editorService.financialTaxonomies, function (t) { return t.taxonomy_id == taxonomy.taxonomy_id; });
            if (!loadedTaxonomy) {
                editorService.getFinancialTaxonomy(taxonomy).then(function (t) {
                    $scope.financialTaxonomies = editorService.getFinancialTaxonomies();
                });
            }
        });
    }

    // on version change, update the stored taxonomy version. 
    $scope.changeVersion = function () {
        if ($scope.versions && $scope.versions.length > 1) {
            ///set the message
            $scope.versionMessage = $scope.version ? $scope.versions[0].c : $scope.versions[1].c;
            //then update our taxonomy setting to be updated on save
            var tax = _($scope.edited_activity.taxonomy).find({ taxonomy_id: $scope.settings.activity.versionTaxononmyId });
            if (tax) {
                tax.classification_id = $scope.version ? $scope.versions[0].id : $scope.versions[1].id;
                _.chain($scope.taxonomies).where({ taxonomy_id: $scope.settings.activity.versionTaxononmyId }).pluck("classifications").first().each(function (c) {
                    //update taxonomy list for correct saving
                    c.active = c.id === tax.classification_id;
                });
            }
        }
    };

    //fire event on title change
    // $scope.titleChanged = function () {
    //     //confirm entered title is not already taken.
    //     var dup = _(editorService.getAllActivities()).find({ t: $scope.edited_activity._title });
    //     var titleError = dup && dup.id !== $scope.edited_activity.id;
    //     activityForm['_title'].setCustomValidity('titleError',titleError);
    //     activityForm['_title'].$error = $scope.titleError || !$scope.edited_activity._title || $scope.edited_activity._title !== "";
    // };

    // load taxonomies for the editor
    function loadTaxonomies(setDraft) {
        // get the taxonomies
        $scope.taxonomies = editorService.getTaxonomies();
        if (stateService.isParam('editor_parent_id') && stateService.getState().editor_parent_id) { $scope.taxonomies = _($scope.taxonomies).where({ childEditing: true }); }
        //$scope.nestedTaxonomies = _(editorService.getTaxonomies()).where({ isNested: true });
        if (!$scope.taxonomies || !$scope.taxonomies.sort || $scope.taxonomies.length === 0) {
            var taxes = _($scope.settings.taxonomies).filter(function (t) { return !t.isNested; });
            if (stateService.isParam('editor_parent_id') && stateService.getState().editor_parent_id) { taxes = _(taxes).where({ childEditing: true }); }
            _.each(taxes, function (taxonomy) {
                var loadedTaxonomy = _.find(editorService.taxonomies, function (t) { return t.taxonomy_id == taxonomy.taxonomy_id; });
                if (!loadedTaxonomy) {
                    editorService.getTaxonomy(taxonomy).then(function (t) {
                        $scope.taxonomies = _(editorService.getTaxonomies()).filter(function (t) { return !t.isNested; });
                        //$scope.nestedTaxonomies = _(editorService.getTaxonomies()).where({ isNested: true });
                        if ($scope.taxonomies.sort) { $scope.taxonomies = $scope.taxonomies.sort(utilService.dynamicSort("order")); }
                        //if ($scope.nestedTaxonomies.sort) { $scope.nestedTaxonomies = $scope.nestedTaxonomies.sort(utilService.dynamicSort("order")); }

                        //store separately for org type picker and primary checkbox
                        $scope.organizationTypes = _.chain($scope.taxonomies).where({ taxonomy_id: $scope.settings.organization.orgTypeTaxononmyId }).pluck("classifications").first().value();
                        $scope.implementingTypes = _.chain($scope.taxonomies).where({ taxonomy_id: $scope.settings.organization.implementingTypeTaxononmyId }).pluck("classifications").first().value();
                        $scope.versions = _.chain($scope.taxonomies).where({ taxonomy_id: $scope.settings.activity.versionTaxononmyId }).pluck("classifications").first().value();
                        $scope.subFinancialList = setSubFinanceList();
                        setVersion();
                        console.log("$scope.taxonomies", $scope.taxonomies);
                    });
                }
            });
        } else {
            if ($scope.taxonomies.sort) { $scope.taxonomies = $scope.taxonomies.sort(utilService.dynamicSort("order")); }
            // store separately for org type picker and primary checkbox
            $scope.organizationTypes = _.chain($scope.taxonomies).where({ taxonomy_id: $scope.settings.organization.orgTypeTaxononmyId }).pluck("classifications").first().value();
            $scope.implementingTypes = _.chain($scope.taxonomies).where({ taxonomy_id: $scope.settings.organization.implementingTypeTaxononmyId }).pluck("classifications").first().value();
            $scope.versions = _.chain($scope.taxonomies).where({ taxonomy_id: $scope.settings.activity.versionTaxononmyId }).pluck("classifications").first().value();
            $scope.subFinancialList = setSubFinanceList();
            setVersion();
            console.log("$scope.taxonomies", $scope.taxonomies);
        }
    }

    // on load, review taxonomy data to determine the initial display of the version toggle
    function setVersion() {
        //wait until we have all of the necessary data
        if ($scope.versions && $scope.versions.length > 0) {
            var val = _.chain($scope.edited_activity.taxonomy).where({ taxonomy_id: $scope.settings.activity.versionTaxononmyId }).pluck("classification_id").first().value();
            if (val) {
                var v = _($scope.versions).find({ id: val });
                $scope.version = _($scope.versions).findIndex({ id: val }) === 0;
                $scope.versionMessage = v.c;
            }
            else {
                var versionClass = _($scope.versions).find({ c: "Draft" });
                // if found, set draft to true by default
                if (versionClass) {
                    versionClass.active = true;
                    $scope.version = false;
                    $scope.versionMessage = versionClass.c;
                }
            }
        }
    }

    //set parent to md-input-focus to provide a way to show a formatted number when not editing a value
    $scope.formattedFinancialClicked = function(e) {
        $(e.currentTarget).parents('md-input-container').addClass('md-input-focused');
    };

});