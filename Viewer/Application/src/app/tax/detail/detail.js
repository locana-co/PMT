/***************************************************************
 * Activity Detail Controller
 * Supports the activity controller and displays data for a single activity.
 * *************************************************************/
angular.module('PMTViewer').controller('TaxDetailCtrl', function ($scope, $q, $element, $rootScope, $mdDialog, stateService, activityService, taxonomyService, config, utilService) {
    $scope.utilService = utilService;
    $scope.stateService = stateService;
    //loader
    $scope.loading = false;
    // details object for active detail
    $scope.tree = null;
    $scope.selectedClassifications = [];
    //initialize variables 
    $scope.tree = null;
    $scope.treeCount = null;
    $scope.classifications = [];
    //settings 
    $scope.settings = $scope.page.tools;

    //defaults for pagination
    $scope.query = {
        order: '_title',
        limit: 50,
        page: 1,
        checks: {} //object holding model for 
    };

    //update row count on search change
    $scope.$watch('gridSearchText', function (newValue, oldValue) {
        $scope.treeCount = _($scope.tree).filter(function (b) {
            if (b._title.toLowerCase().indexOf(newValue.toLowerCase()) > -1) { return true; }
        }).length;
    });

    // when the url is updated run this
    $scope.$on('route-update', function () {
        if (stateService.isParam('tax_id') && stateService.getState().tax_id) {
            //reset
            $scope.tree = null;
            $scope.treeCount = null;
            $scope.classifications = null;
            $scope.selectedClassifications = [];
            //get select options
            var id = parseInt(stateService.getState().tax_id, 0);
            taxonomyService.getTaxonomyClassifications(id).then(function (classifications) {
                $scope.classifications = classifications;
            });
        }
    });

    //save any changes to the assigned activities for this taxonomy
    //will perform and add and/or delete for each classification across all activities
    $scope.$on('save-taxonomy-activities', function () {
        $scope.loading = true;
        //pare down grid data based on dirty rows
        var changedPanrent = _($scope.tree).where({ isDirty: true });
        var changedChild = _.chain($scope.tree).pluck("children").flatten().where({ isDirty: true }).value();
        var changed = _.union(changedPanrent, changedChild);

        var adding = [], deleting = [];
        //loop through each classification and look for adds/deletes in data
        _.chain($scope.selectedClassifications).where({ fetched: true }).each(function (column) {
            var addtivities = [], adds = [], deletivities = [], deletes = [];
            _(changed).each(function (change) {


                //check for add
                if (change[column.id] && (!change.c || change.c.length === 0 || change.c.indexOf(column.id) === -1)) {
                    addtivities.push(change.id);
                } else if (change[column.id] && change.c.indexOf(column.id) > -1) {
                    deletivities.push(change.id);
                }

            });
            //store for next loop that will call the service
            if (addtivities.length > 0) {
                adding.push({ activities: _(addtivities).uniq(), classification: column.id });
            }
            if (deletivities.length > 0) {
                deleting.push({ activities: _(deletivities).uniq(), classification: column.id });
            }
        });
        //save each one
        var count = 0, max = adding.length + deleting.length;
        //save adds
        _(adding).each(function (a) {
            activityService.saveActivityClassifications(a.activities, [a.classification], [parseInt(stateService.getState().tax_id, 0)], "add").then(function (result) {
                if (result.length > 0) {
                    //if success then increment count, otherwise log error
                    if (result[0].response.message === "Success") { count += 1; }
                    else {
                        $scope.loading = false;
                        console.log(result[0].response.message);
                    }

                    if (count === max) {
                        //go back to tax home page
                        $scope.loading = false;
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
                        stateService.setParamWithVal('tax_id', '');
                    }
                }
            });
        });
        //save deletes
        _(deleting).each(function (d) {
            activityService.saveActivityClassifications(d.activities, [d.classification], [parseInt(stateService.getState().tax_id, 0)], "add").then(function (result) {
                if (result.length > 0) {
                    //if success then increment count, otherwise log error
                    if (result[0].response.message === "Success") { count += 1; }
                    else {
                        $scope.loading = false;
                        console.log(result[0].response.message);
                    }

                    if (count === max) {
                        //go back to tax home page
                        $scope.loading = false;
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
                        stateService.setParamWithVal('tax_id', '');
                    }
                }
            });
        });
    });

    // take all selected classifications and build a project table based off of it 
    $scope.buildTable = function () {
        var ids = _($scope.selectedClassifications).pluck("id");
        // whichever options aren't selected are set to not fetched
        _($scope.classifications).each(function (c) {
            if (ids.indexOf(c.id) < 0) { c.fetched = false; }
        });
        if (ids.length > 0) {
            if ($scope.tree && $scope.taxActivityForm.$dirty) {
                var confirm = $mdDialog.confirm()
                    .title('Are you sure you want to update the table? All current edits will be lost.')
                    .ariaLabel('create confirmation')
                    .targetEvent(event)
                    .ok('Yes, Continue')
                    .cancel('No, Cancel');
                $mdDialog.show(confirm).then(function () {
                    getFamilyTree(ids);

                }, function () { });
            } else {
                getFamilyTree(ids);

            }
        } else {
            $mdDialog.show(
                $mdDialog.alert()
                    .parent(angular.element(document.querySelector('#tax')))
                    .clickOutsideToClose(true)
                    .title('No classifications detected')
                    .textContent('Please select at least 1 classification to edit an ' + $scope.terminology.activity_terminology.singluar)
                    .ariaLabel(' No Changes')
                    .ok('Ok')
                    .targetEvent(event)
            );
        }
    };

    // get getFamilyTree
    function getFamilyTree(ids) {
        activityService.getFamilyTree(ids).then(function (data) {
            $scope.taxActivityForm.$setPristine(true); //reset form activity
            // update pager total records
            $scope.treeCount = data.length;
            // translate date to a table
            $scope.tree = _.chain(data).pluck("response").map(function (p) {
                // add in checkbox value for each classification
                _($scope.selectedClassifications).each(function (column) {
                    column.fetched = true;
                    p[column.id] = p.c && p.c.length > 0 ? p.c.indexOf(column.id) > -1 : false;
                });
                // in case a search was made
                p.inFilter = !$scope.gridSearchText || $scope.gridSearchText === "" || p._title.indexOf(gridSearchText) > -1;

                // same setup on children
                if (p.children) {
                    p.arrow = "keyboard_arrow_up";
                    p.active = false; // default to not display
                    _(p.children).each(function (child) {
                        _($scope.selectedClassifications).each(function (column) {
                            child[column.id] = child.c && child.c.length > 0 ? child.c.indexOf(column.id) > -1 : false;
                        });
                    });
                }
                return p;
            }).sortBy("_title").value();
        });
    }

    //select all records
    $scope.selectAll = function (list, data) {
        $scope[list] = [];
        _($scope[data]).each(function (d) {
            $scope[list].push(d);
        });
    };

    //deselect all records
    $scope.deSelectAll = function (list) {
        $scope[list] = [];
    };

    //clear search
    $scope.clearClassificationSearchTerm = function () {
        $scope.classificationSearchTerm = null;
    };

    //clear search
    $scope.clearActivitySearchTerm = function () {
        $scope.activitySearchTerm = null;
    };

    //search filter for grid
    $scope.searchTaxList = function () {

    };

    //column header checked/unchecked
    $scope.columnChecked = function (id) {
        _($scope.tree).each(function (b) {
            //make sure to only update valid values based on the search input
            if (!$scope.gridSearchText || $scope.gridSearchText === "" || b._title.toLowerCase().indexOf($scope.gridSearchText.toLowerCase()) > -1) {
                b.isDirty = true; //track for saving
                b[id] = $scope.query.checks[id];
                _(b.children).each(function (c) {
                    c.isDirty = true; //track for saving
                    c[id] = $scope.query.checks[id];
                });
            }
        });
    };

    //parent header checked/unchecked
    $scope.updateChildren = function (branch, id) {
        _(branch.children).each(function (c) {
            c.isDirty = true;
            c[id] = branch[id];
        });
    };

    //make activity row dirty so we know to update it on save
    $scope.makeDirty = function (record) {
        record.isDirty = true;
    };

    // toggle whether seeing child activity details displays in the list
    $scope.toggleActive = function (b) {
        b.active = !b.active;
        b.arrow = b.active ? "keyboard_arrow_down" : "keyboard_arrow_up";
    };

    // The md-select directive eats keydown events for some quick select
    // logic. Since we have a search input here, we don't need that logic.
    $element.find('input').on('keydown', function (ev) {
        ev.stopPropagation();
    });


});