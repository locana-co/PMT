/***************************************************************
 * Pivot Table Widget Controller
 * Supports the pivot table widget. The pivot table supports 
 * pivoting organization information by taxonomies and boundaries.
 ***************************************************************/
angular.module('PMTViewer').controller('LocsWidgetPivotCtrl', function ($scope, $rootScope, $stateParams, analysisService, locsService, $mdDialog) {
    // max character limit per cell
    var cellCharacterLimit = 35;
    //loader
    $scope.loading = false;
    //stores the selected cell for list of partners
    $scope.selectedCell = {};
    // no data flag
    $scope.noData = false;

    // index of axis option for row and col options (drop downs)
    // axis options in widget.params.axis_options
    // by default the first option will be set as column option and
    // second option will be set as row option
    $scope.col_option_index = 1;
    $scope.row_option_index = 0;
    // assign colun and row options based on above index
    $scope.col_options = _.find($scope.widget.params.axis_options, function(a){ return a.row_taxonomy_id === $scope.widget.params.column_taxonomy_id; }) || $scope.widget.params.axis_options[$scope.col_option_index];
    $scope.row_options = _.find($scope.widget.params.axis_options, function(a){ return a.row_taxonomy_id === $scope.widget.params.row_taxonomy_id; }) || $scope.widget.params.axis_options[$scope.row_option_index];

    // when the selection is updated, do this
    $scope.$on('selection-update', function () {
        if ($scope.widget.area == $stateParams.area) {
            $scope.processPartnerPivotData();
        }
    });

    // when the filter is updated, update widget
    $scope.$on('locs-filter-update', function () {
        if ($scope.widget.area == $stateParams.area) {
            $scope.processPartnerPivotData();
        }
    });

    // when user clicks in table cell, updates the current selected cell
    $scope.setSelectedCell = function (cell) {
        var partners = [];
        _.each(cell, function (element) {
            // if overflow element
            if (element.overflow) {
                _.each(element.overflow, function (p) {
                    partners.push(p);
                });
            }
            // otherwise just add partner obj to list
            else {
                partners.push(element);
            }
        });
        $scope.selectedCell = cell;
        $scope.selectedCell.partners = partners;
    };

    // update the selected column option with user selection
    $scope.updateColumnOption = function () {
        $scope.col_options = $scope.widget.params.axis_options[$scope.col_option_index];
        $scope.processPartnerPivotData();
    };

    // update the selected row option with user selection
    $scope.updateRowOption = function (index) {
        $scope.row_options = $scope.widget.params.axis_options[$scope.row_option_index];
        $scope.processPartnerPivotData();
    };

    // load and process the pivot data as a chart
    $scope.processPartnerPivotData = function () {
        // if a data group is selected process the chart data
        if (locsService.getDataGroupFilters().length > 0) {
            switch ($stateParams.area) {
                case 'national':
                case 'regional':
                    // turn on loading symbol
                    $scope.loading = true;
                    // turn of no data
                    $scope.noData = false;
                    // get the current selected feature id
                    var featureId = ($scope.widget.area == 'national' ? parseInt(locsService.selectedNationalFeature.id, 10) : parseInt(locsService.selectedRegionalFeature.id, 10));
                    // get the current selected boundary id
                    var boundaryId = ($scope.widget.area == 'national' ? locsService.nationalLayer.boundary_id : locsService.regionalLayer.boundary_id);
                    //if boundaries selected for both row and column, return no data
                    if ($scope.col_options.pivot_on_locations && $scope.row_options.pivot_on_locations) {
                        $scope.chartData = [];
                        $scope.loading = false;
                        $scope.noData = true;
                    }
                    // column option is a boundary, call partner boundary pivot
                    else if ($scope.col_options.pivot_on_locations) {
                        partnerBoundaryPivot($scope.col_options.pivot_boundary_id, $scope.row_options.row_taxonomy_id, false, boundaryId, featureId);
                    }
                    // row option is a boundary, call partner boundary pivot
                    else if ($scope.row_options.pivot_on_locations) {
                        partnerBoundaryPivot($scope.row_options.pivot_boundary_id, $scope.col_options.row_taxonomy_id, true, boundaryId, featureId);
                    }
                    // row & column options are taxonomies, call partner pivot
                    else {
                        partnerPivot(boundaryId, featureId);
                    }
                    break;
                default:
                    $scope.chartData = [];
                    $scope.loading = false;
                    $scope.noData = true;
                    break;
            }
        }
        // otherwise inform the widget there is no data
        else {
            $scope.chartData = [];
            $scope.loading = false;
            $scope.noData = true;
        }
    };

    // popup dialog with list of all partners within a table cell
    $scope.showAllPartners = function (d) {
        // if there is an overflow
        if ($scope.selectedCell[$scope.selectedCell.length - 1].overflow) {
            // open dialog
            $mdDialog.show({
                locals: { data: $scope.selectedCell },
                controller: PivotModalController,
                templateUrl: 'locs/widget/pivot/pivot-modal.tpl.html',
                targetEvent: d,
                clickOutsideToClose: true,
                scope: $scope,
                preserveScope: true
            });
        }
    };

    // export pivot table as CSV
    $scope.exportPivotasCSV = function () {
        var orgName = _.find($scope.widget.params.partner_filters, function (f) {
            return f.org_role_id = $scope.widget.params.org_role_id;
        });
        // call to export pivot table as CSV
        locsService.exportPivotasCSV($scope.chartData, $scope.headers, $scope.col_options.label, $scope.row_options.label, orgName.name, $scope.widget);
    };

    // modal popup for exporting widget data (options: as png or csv)
    $scope.exportPopup = function () {
        $mdDialog.show({
            locals: {},
            controller: DownloadController,
            templateUrl: 'locs/widget/pivot/widget-print-modal.tpl.html',
            parent: angular.element(document.body),
            clickOutsideToClose: true,
            scope: $scope,
            preserveScope: true
        });
    };

    // call for and process partner boundary pivot data (one taxonomy, one boundary)
    function partnerBoundaryPivot(pivot_boundary_id, taxonomy_id, boundary_as_row, boundary_id, feature_id) {
        analysisService.getBoundaryPivot(
            pivot_boundary_id,
            taxonomy_id,
            boundary_as_row,
            parseInt($scope.widget.params.org_role_id, 10),
            locsService.getDataGroupFilters().join(','),
            locsService.getClassificationFilters().join(','),
            locsService.getStartDateFilter(),
            locsService.getEndDateFilter(),
            boundary_id,
            feature_id
        ).then(function (data) {
            // if a data group is selected process the chart data
            if (locsService.getDataGroupFilters().length > 0) {
                // if only data is headers
                if (data.length <= 1) {
                    $scope.chartData = [];
                    $scope.loading = false;
                    $scope.noData = true;
                }
                // collect the header data
                $scope.headers = [];
                _.each(data[0], function (k, v) {
                    $scope.headers.push({
                        "key": k,
                        "value": v,
                        "active": false
                    });
                });
                // the first row is the header
                data.shift();
                // clear the chart data
                $scope.chartData = [];
                // loop through the data and process
                _.each(data, function (row) {
                    var dataRow = [];
                    dataRow.push([{ "f1": row.c1, "f2": null, "f3": null }]);
                    delete row.c1;
                    _.each(row, function (cell) {
                        if (cell[0] === null) {
                            dataRow.push(null);
                        }
                        else {
                            var items = [];
                            var overflow = [];
                            var characterCount = 0;
                            // filter the data to remove empty cells
                            var cells = _.filter(cell, function (c) { return c !== null; });
                            cells = _.filter(cells, function (c) { return c.f1 !== null; });
                            _.each(cells, function (item, index) {
                                if (_.has(item, 'f1')) {
                                    if (item.f1 !== null) {
                                        characterCount = characterCount + item.f1.length;
                                        if (characterCount < cellCharacterLimit) {
                                            items.push(item);
                                        }
                                        else {
                                            overflow.push(item);
                                            if (index == cells.length - 1) {
                                                items.push({ "f1": overflow.length + " more", "f2": null, "f3": "Click to see full list", "overflow": overflow });
                                            }
                                        }
                                    }
                                }
                            });
                            dataRow.push(items);
                        }
                    });
                    $scope.chartData.push(dataRow);
                });
                // grab number of columns
                var numColumns = $scope.chartData[0].length;
                // set header column active
                $scope.headers[0].active = true;
                // loop through rows and set active status of columns
                _.each($scope.chartData, function (row) {
                    // check all columns not including header
                    for (var i = 1; i < numColumns; i++) {
                        // if there is data in a column, update the active status for that column
                        if ((row[i] !== null) && (row[i].length > 0)) {
                            $scope.headers[i].active = true;
                        }
                    }
                });
                // turn off loading symbol
                $scope.loading = false;
            }
            // otherwise inform the widget there is no data
            else {
                $scope.chartData = [];
                $scope.loading = false;
                $scope.noData = true;
            }
        });
    }

    // call for and process partner pivot data (two taxonomies)
    function partnerPivot(boundary_id, feature_id) {
        analysisService.getPartnerPivot(
            $scope.col_options.row_taxonomy_id,
            $scope.row_options.row_taxonomy_id,
            parseInt($scope.widget.params.org_role_id, 10),
            locsService.getDataGroupFilters().join(','),
            locsService.getClassificationFilters().join(','),
            locsService.getStartDateFilter(),
            locsService.getEndDateFilter(),
            boundary_id,
            feature_id
        ).then(function (data) {
            // if a data group is selected process the chart data
            if (locsService.getDataGroupFilters().length > 0) {
                // if only data is headers
                if (data.length <= 1) {
                    $scope.noData = true;
                }
                // collect the header data
                $scope.headers = [];
                _.each(data[0], function (k, v) {
                    $scope.headers.push({
                        "key": k,
                        "value": v,
                        "active": false
                    });
                });
                // the first row is the header
                data.shift();
                // clear the chart data
                $scope.chartData = [];
                // loop through the data and process
                _.each(data, function (row) {
                    var dataRow = [];
                    dataRow.push([{ "f1": row.c1, "f2": null, "f3": null }]);
                    delete row.c1;
                    _.each(row, function (cell) {
                        if (cell[0] === null) {
                            dataRow.push(null);
                        }
                        else {
                            var items = [];
                            var overflow = [];
                            var characterCount = 0;
                            // filter the data to remove empty cells
                            var cells = _.filter(cell, function (c) {
                                return c !== null;
                            });
                            cells = _.filter(cells, function (c) {
                                return c.f1 !== null;
                            });
                            _.each(cells, function (item, index) {
                                if (_.has(item, 'f1')) {
                                    if (item.f1 !== null) {
                                        characterCount = characterCount + item.f1.length;
                                        if (characterCount < cellCharacterLimit) {
                                            items.push(item);
                                        }
                                        else {
                                            overflow.push(item);
                                            if (index == cells.length - 1) {
                                                items.push({
                                                    "f1": overflow.length + " more",
                                                    "f2": null,
                                                    "f3": "Click to see full list",
                                                    "overflow": overflow
                                                });
                                            }
                                        }
                                    }
                                }
                            });
                            dataRow.push(items);
                        }
                    });
                    $scope.chartData.push(dataRow);
                });
                //grab number of columns
                var numColumns = $scope.chartData[0].length;
                //set header column active
                $scope.headers[0].active = true;
                //loop through rows and set active status of columns
                _.each($scope.chartData, function (row) {
                    //check all columns not including header
                    for (var i = 1; i < numColumns; i++) {
                        //if there is data in a column, update the active status for that column
                        if ((row[i] !== null) && (row[i].length > 0)) {
                            $scope.headers[i].active = true;
                        }
                    }
                });
                // if configuration is set to remove empty columns, remove
                if (!$scope.widget.params.show_empty_columns) {
                    var idxBump = 0;
                    _.each($scope.headers, function (h, idx) {
                        if (!h.active) {
                            _.each($scope.chartData, function (d) {
                                return d.splice(idx - idxBump, 1);
                            });
                            idxBump++;
                        }
                    });
                    $scope.headers = _.reject($scope.headers, function (h) {
                        return !h.active;
                    });
                    var test = $scope.chartData;
                }
                // if configuration is set to remove empty rows, remove
                if (!$scope.widget.params.show_empty_rows) {
                    var idxCt = 0;
                    var emptyRowIndexes = [];
                    _.each($scope.chartData, function (d, idx) {
                        var empty = true;
                        _.each(d, function (cell, i) {
                            if (cell && i !== 0) {
                                if (cell.length > 0) {
                                    empty = false;
                                }
                            }
                        });
                        if (empty) {
                            emptyRowIndexes.push(idx);
                        }
                    });
                    _.each($scope.chartData, function (d, idx) {
                        if (_.contains(emptyRowIndexes, idx)) {
                            $scope.chartData.splice(idx - idxCt, 1);
                            idxCt++;
                        }
                    });
                }
                // turn off the loading symbol
                $scope.loading = false;
            }
            // otherwise inform the widget there is no data
            else {
                $scope.chartData = [];
                $scope.loading = false;
                $scope.noData = true;
            }
        });
    }

    // pop-up model on download click
    function DownloadController($scope) {
        // on click function for close buttons
        $scope.closeDialog = function () {
            $mdDialog.cancel();
        };
    }

    // modal controller for showing all organizations
    function PivotModalController($scope, data) {
        $scope.data = data;
        // on click function for close buttons
        $scope.closeDialog = function () {
            $mdDialog.cancel();
        };
    }

    // intialization function
    function init() {
        // process partner pivot data
        $scope.processPartnerPivotData();
    }

    // initialize the widget
    init();
});
