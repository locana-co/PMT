module.exports = angular.module('PMTViewer').controller('IntegrationDetailCtrl', function EditorDetailCtrl($scope, $rootScope, $mdDialog, $timeout, stateService, editorService, utilService, integrationService, mapService, partnerLinkService, blockUI, config, pmt) {
    // initialized flag for map
    var initialize = false;
    // add state service to scope
    $scope.stateService = stateService;
    // editor settings
    $scope.settings = $scope.page.tools;


    // loader
    $scope.loading = false;
    // loader
    $scope.warnedOnce = false;
    // loading error
    $scope.error = false;
    // selected tab index
    $scope.tabIndex = 0;
    // initialize activity
    setIntegration();
    // when the editor activity needs refreshing do this
    $scope.$on('refresh-integration', function () {
        setIntegration();
    });

    // user clicked "Add Recipient" button
    $scope.addRecipient = function () {
        //var newRecord = newParticipationRecord();
        // $scope.edited_activity.organizations.push(newRecord);
    };

    // user clicked "Delete Record"
    $scope.deleteSchedule = function () {
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

    // user clicked "Run integration now"
    $scope.runIntegration = function () {
        var confirm = $mdDialog.confirm()
            .title('Are you sure you want to run the integration now?')
            .ariaLabel('run integration')
            .targetEvent(event)
            .ok('Yes, run')
            .cancel('No, Cancel');
        $mdDialog.show(confirm).then(function () {
            // run integration task now 

        }, function () { });
    };

    // user clicked "Add Contact Record" button
    $scope.addRecipientRecord = function () {
        //check to see if any records have been marked for deletion and remove from array.
        _.chain($scope.model._recipients).where({ deleted: true }).each(function (o) {
            $scope.model._recipients = _($scope.model._recipients).without(o);
        });

        var question = $mdDialog.confirm()
            .title('How would you like to add?')
            .ariaLabel('confirm add')
            .targetEvent(event)
            .ok('New Recipient')
            .cancel('Lookup Recipient');
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
            if (!Array.isArray($scope.model._recipients)) { $scope.model._recipients = []; }
            //add blank record
            $scope.model._recipients.push(newRecord);
        }, function () {
            //open a popup with exiting user to choose from 
            $scope.openContactSelector();
        });
    };

    // open the contact-selector modal
    // user chooses option after add contact record is clicked 
    $scope.openContactSelector = function () {
        $scope.dialogSettings = {
            idsToExclude: _($scope.model._recipients).pluck("id") || [],
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
            if (!Array.isArray($scope.model._recipients)) { $scope.model._recipients = []; }
            //add blank record
            $scope.model._recipients.push($scope.dialogSettings.selectedContact);
        });
    };

    // private function to grab activity from url and set page to details
    function setIntegration() {
        if (stateService.isState('integration')) {
            //temp model
            $scope.model = {
                _recurrence: null,
                _recipients: [],
                _day: {},
                _week: {},
                _month: {
                    one: {},
                    many: {}
                },
                _year: {
                    one: {},
                    many: {}
                }
            };


            $scope.forms = integrationService.getForms();
            //and store the dom reference for lookup purposes
            _($scope.forms).each(function (f, key) {
                f.form = $("[name='" + key + "']");
            });
        }
    }

    // user changed an input being tracked for potential duplicates
    $scope.changeRecipient = function (event, record) {
        //make sure this is a new record
        // if ((!record.id || record.id > -1) && (record._email !== "")) {
        //     $scope.contacts = editorService.getAllContacts();

        //     if ($scope.contacts.length <= 0) {
        //         editorService.getContacts().then(function (contacts) {
        //             $scope.contacts = contacts;
        //             contactsReady($scope, $scope.contacts, record);
        //         });
        //     } else {
        //         contactsReady($scope, $scope.contacts, record);
        //     }
        // }
    };

    //private function used to lookup user entry against existing contacts
    // function contactsReady(scope, contacts, record) {
    //     var finding = _.chain(contacts).filter(function (o) {
    //         return o.id !== record.id && o._first_name === record._first_name && o._last_name === record._last_name && o._email === record._email;
    //     }).first().value();

    //     if (finding) {
    //         //if user already in list, warn user
    //         if (_(scope.edited_activity.contacts).findIndex({ id: finding.id }) >= 0) {
    //             $mdDialog.alert({
    //                 title: '',
    //                 textContent: '',
    //                 ok: 'Close'
    //             });

    //             var alert = $mdDialog.alert()
    //                 .title('Duplicate Record!')
    //                 .ariaLabel('Duplicate Record')
    //                 .textContent('The contact already exists in your list. Please delete this record or enter different contact information.')
    //                 .targetEvent(event)
    //                 .ok('Ok');
    //             $mdDialog.show(alert).then(function () { }, function () { });

    //             return;
    //         }
    //         //get ready to load contact 
    //         $scope.loading = true;
    //         //let user know the user exists and that they should select the existing user or change their entry 
    //         var question = $mdDialog.confirm()
    //             .title('Existing contact found, would you like to import?')
    //             .ariaLabel('confirm import')
    //             .targetEvent(event)
    //             .ok('Import Contact')
    //             .cancel('Cancel');
    //         $mdDialog.show(question).then(function (result) {
    //             //update model with found contact
    //             record.id = finding.id;
    //             record._title = finding._title;
    //             record.activities = finding.activities;
    //             record.organization_id = finding.organization_id;
    //             record.organization_name = finding.organization_name;

    //             $scope.loading = false;
    //         }, function () {
    //             $scope.loading = false;
    //         });
    //     }
    // }

    // private function to create new activity
    function createActivity() {
        // activate loader
        $scope.loading = true;
        // get detail details
        editorService.createActivity().then(function (activity) {
            // remove all features from the map
            editorService.removeFeatures();
            // deactivate the loader with a 2 second delay
            $timeout(function () {
                $scope.loading = false;
            }, 2000);
            // get the form information (validation)
            $scope.forms = editorService.getForms();
            // set the activity
            $scope.edited_activity = editorService.getCurrentActivity();
            // get the taxonomies
            $scope.taxonomies = editorService.getTaxonomies();
            if ($scope.taxonomies.sort) { $scope.taxonomies = $scope.taxonomies.sort(utilService.dynamicSort("order")); }
        }, function (message) {
            // deactivate the loader
            $scope.loading = false;
            // notify of error
            $scope.error = true;
        });
        // loop through the listing of taxonomies and load
        _.each($scope.settings.taxonomies, function (taxonomy) {
            var loadedTaxonomy = _.find(editorService.taxonomies, function (t) { return t.taxonomy_id == taxonomy.taxonomy_id; });
            if (!loadedTaxonomy) {
                editorService.getTaxonomy(taxonomy).then(function (t) {
                    $scope.taxonomies = editorService.getTaxonomies();
                    if ($scope.taxonomies.sort) { $scope.taxonomies = $scope.taxonomies.sort(utilService.dynamicSort("order")); }
                });
            }
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

});