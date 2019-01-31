/***************************************************************
 * Organization Page List Controller
 * Supports the organization page's list feature.
 * *************************************************************/
angular.module('PMTViewer').controller('OrgsListCtrl', function ($scope, $rootScope, orgService, $mdDialog) {
    // loader
    $scope.loading = false;
    // user error message
    $scope.error = false;
    // organization list
    $scope.organizationsList = null;
    /// consolidate mode
    $scope.consolidate = false;
    // selected org to keep for consolidation
    $scope.consolidateSelectedIdToKeep = null;
    // all selected orgs to consolidate
    $scope.orgsToBeConsolidated = null;

    // initialize page
    init(false);

    // when the organization list needs refreshing do this
    $scope.$on('refresh-org-list', function (event, isConsolidate) {
        $scope.consolidate = isConsolidate;
        $rootScope.$broadcast('enable-consolidate-submit', false);
        $scope.consolidateSelectedIdToKeep = null;
        $scope.orgsToBeConsolidated = null;
        init(true);
    });

    // when submit selected orgs to consolidate is clicked do this
    $scope.$on('submit-consolidate-list', function () {
        // when none is selected
        if ($scope.orgsToBeConsolidated == null || $scope.orgsToBeConsolidated.length < 1) {
            showConfirmationDialog('Consolidate Error', 'Please select organization(s) to consolidate.');
        }
        // when at least one is selected
        else {
            var length = $scope.orgsToBeConsolidated.length;
            var message = '';
            if (length > 1) {
                message = 'Are you sure you want to consolidate the selected organizations?';
            } else {
                message = 'Are you sure you want to consolidate the selected organization?';
            }
            var confirm = askConfirmationDialog(message, 'confirm consolidation');
            // confirm consolidation
            $mdDialog.show(confirm).then(function () {
                orgService.consolidate($scope.consolidateSelectedIdToKeep, $scope.orgsToBeConsolidated).then(function (res) {
                    // success, refresh org list
                    $rootScope.$broadcast('refresh-org-list', true);
                    // success dialog
                    showConfirmationDialog('Success', 'Organization has been consolidated.');
                }).catch(function (msg) {
                    // error dialog
                    showConfirmationDialog('Error', 'unable to consolidate organization: ' + msg);
                });
            });
        }
    });

    // open editor module - cancel, delete, save
    $scope.openEditOrg = function (org_id) {
        var selectedOrg = _.findWhere($scope.organizationsList, { id: org_id });
        var filterSelectedOrg = {
            name: selectedOrg.name,
            id: selectedOrg.id,
            url: selectedOrg.url,
            label: selectedOrg.label
        };
        $scope.org = filterSelectedOrg;
        $mdDialog.show({
            controller: 'UserEditOrgCtrl',
            templateUrl: 'orgs/edit-org/edit-org.tpl.html',
            parent: angular.element(document.body),
            clickOutsideToClose: true,
            bindToController: true,
            scope: $scope, // pass scope to UserEditOrgCtrl
            preserveScope: true
        });
    };

    // when keep button is clicked do this to save the org_id of kept organization 
    $scope.consolidateSelectedOrgToKeep = function (org_id) {
        // unselect org to be kept
        if ($scope.consolidateSelectedIdToKeep !== null) {
            var message = 'Are you sure you want to unselect this organization to keep?';
            var confirm = askConfirmationDialog(message, 'confirm reselection');
            $mdDialog.show(confirm).then(function () {
                $scope.consolidateSelectedIdToKeep = null;
                $scope.orgsToBeConsolidated = null;
                _.each($scope.organizationsList, function (org) {
                    var idToKeep = "#keep_" + org.id;
                    var idToCons = "#cons_" + org.id;
                    if (org.id == org_id) {
                        // change keep button to normal color
                        $(idToKeep).removeClass("keep");
                        $(idToKeep).addClass("normal-button");
                    }
                    else {
                        // disable all consolidate buttons and enable keep button
                        $(idToKeep).prop('disabled', false);
                        $(idToCons).prop('disabled', true);
                        // change consolidate button to normal color
                        $(idToCons).removeClass("selected");
                        $(idToCons).addClass("normal-button");
                    }
                });
                // disable submit button
                $rootScope.$broadcast('enable-consolidate-submit', false);
            });
        }
        // select org to be kept
        else {
            $scope.consolidateSelectedIdToKeep = org_id;
            _.each($scope.organizationsList, function (org) {
                var idToKeep = "#keep_" + org.id;
                var idToCons = "#cons_" + org.id;
                if (org.id == org_id) {
                    // change keep button to be selected
                    $(idToKeep).removeClass("normal-button");
                    $(idToKeep).addClass("keep");
                }
                else {
                    // disable all keep button and enable consolidate button
                    $(idToKeep).prop('disabled', true);
                    $(idToCons).prop('disabled', false);
                }
            });
            // enable submit button
            $rootScope.$broadcast('enable-consolidate-submit', true);
        }
    };

    // when consolidate button is clicked do this to save the org_id of all consolidate organizations
    $scope.selectToConsolidate = function (org_id) {
        var id = "#cons_" + org_id;
        // initialize array of selected orgs to be consolidated
        if ($scope.orgsToBeConsolidated == null) {
            $scope.orgsToBeConsolidated = [];
        }
        var index = $scope.orgsToBeConsolidated.indexOf(org_id);
        // user unselects: delete from array if org id already exists
        if (index > -1) {
            $scope.orgsToBeConsolidated.splice(index, 1);
            // change color to be normal
            $(id).removeClass("selected");
            $(id).addClass("normal-button");
        }
        // user selects: add to array if org id doesn't exists
        else {
            $scope.orgsToBeConsolidated.push(org_id);
            // change color to indicate selection
            $(id).removeClass("normal-button");
            $(id).addClass("selected");
        }
    };

    function init(reload) {
        $scope.loading = true;
        // get the saved organization list from the service
        $scope.organizationsList = orgService.getAllOrgs();

        if ($scope.error) {
            $scope.loading = false;
            $scope.organizationsList = null;
        }
        else {
            // list is not initialized
            if ($scope.organizationsList === null || reload) {
                // call service to get organization list
                orgService.getOrgs().then(function (orgs) {
                    $scope.organizationsList = orgs;
                    $scope.htmlList = processOrganizations();
                    $scope.loading = false;
                    $rootScope.$broadcast('org-list-updated');
                });
            }
            else {
                $scope.htmlList = processOrganizations();
                $scope.loading = false;
                $rootScope.$broadcast('org-list-updated');
            }
        }
    }

    // ask for confirmation dialog
    function askConfirmationDialog(title, label) {
        var confirm = $mdDialog.confirm()
            .title(title)
            .ariaLabel(label)
            .ok('Yes')
            .cancel('Cancel');
        return confirm;
    }

    // message dialog
    function showConfirmationDialog(title, content) {
        $mdDialog.show(
            $mdDialog.alert()
                .clickOutsideToClose(true)
                .title(title)
                .textContent(content)
                .ariaLabel('Consolidate Organization Message')
                .ok('OK')
        );
    }

    // process organization list and dynamically generate the HTML for the list
    // using this approach over ng-repeat because the list is 
    // a very large object and ng-repeat causes extreme performance issues
    function processOrganizations() {
        var htmlList = '';
        htmlList += '<br><br>';
        // consolidate directions
        if ($scope.consolidate) {
            htmlList += '<div class="message">';
            htmlList += 'Please select one organization to KEEP. Then select organization(s) you want to CONSOLIDATE. ';
            htmlList += 'All selected CONSOLIDATE organizations will be permanently deleted and replaced with the KEEP organization after clicking the <i class="material-icons ng-scope">done</i> submit button.';
            htmlList += '</div>';
        }
        // default 3 columns
        var colSpan = 3;
        if ($scope.consolidate) {
            colSpan = 4;
        }
        // search bar
        htmlList += '<md-input-container md-no-float class="search md-block">';
        htmlList += '<input id="orgListInput" onkeyup="searchOrgList()" placeholder="Search">';
        htmlList += '</md-input-container>';
        // organization table
        htmlList += '<table id="orgListTable">';
        htmlList += '<thead><tr><th colspan="' + colSpan + '">Organizations</th></tr></thead>';
        htmlList += '<tbody>';
        _.each($scope.organizationsList, function (org) {
            htmlList += '<tr id="' + org.id + '">';
            // label
            htmlList += '<td>';
            htmlList += '<div >' + org.orderedBy + '</div>';
            htmlList += '</td>';
            // name
            htmlList += '<td>';
            htmlList += '<div >' + org.name + '</div>';
            htmlList += '</td>';
            // edit mode shows edit button
            if (!$scope.consolidate) {
                htmlList += '<td>';
                htmlList += '<div class="tools">';
                htmlList += '<md-button class="md-mini md-fab icon-button normal-button" ';
                htmlList += 'ng-click="openEditOrg(' + org.id + ')">';
                htmlList += '<md-tooltip md-direction="bottom">Edit Organization</md-tooltip>';
                htmlList += '<i class="material-icons">mode_edit</i>';
                htmlList += '</md-button>';
                htmlList += '</div>';
                htmlList += '</td>';
            }
            // consolidate mode shows consolidate button
            else {
                htmlList += '<td>';
                htmlList += '<div class="tools">';
                // keep button
                htmlList += '<md-button class="md-raised icon-button normal-button" id="keep_' + org.id + '" ng-click="consolidateSelectedOrgToKeep(' + org.id + ')">Keep</md-button>';
                htmlList += '</div></td>';
                htmlList += '<td><div class="tools">';
                // consolidate button
                // enable or disable consolidate button 
                htmlList += '<md-button class="md-raised icon-button normal-button" id="cons_' + org.id + '" ng-click="selectToConsolidate(' + org.id + ')" disabled >Consolidate</md-button>';
                htmlList += '</div></td>';
            }
            htmlList += '</tr>';
        });
        return htmlList + '</tbody></table>' + jScript();
    }

    // filter list by search
    function jScript() {
        var script = '<script>';
        script += 'function searchOrgList() {';
        script += 'var input, filter, table, tr, td, i, j, pass, isMatch;';
        script += 'input = document.getElementById("orgListInput");';
        script += 'filter = input.value.toLowerCase();';
        script += 'table = document.getElementById("orgListTable");';
        script += 'tr = table.getElementsByTagName("tr");';
        // loop through all table rows, and hide those who don't match the search query
        script += 'for (i = 1; i < tr.length; i++) {';
        script += 'pass = [];';
        // loop through all columns in the row
        script += 'for (j = 0; j < 2; j++) {';
        script += 'td = tr[i].getElementsByTagName("td")[j];';
        script += 'if (td) {';
        script += 'pass.push( (td.innerHTML.toLowerCase().indexOf(filter) > -1) );';
        script += '}';
        script += '}';
        // check if table row is a match
        script += 'isMatch = false;';
        script += 'for (j = 0; j < pass.length; j++) {';
        script += 'if (pass[j] == true) {';
        script += 'isMatch = true;';
        script += '}';
        script += '}';
        // display or hide the row
        script += 'if (isMatch) {';
        script += 'tr[i].style.display = "";';
        script += '} else {';
        script += 'tr[i].style.display= "none";';
        script += '}';
        script += '}';
        script += '}';
        script += '</script >';
        return script;
    }
});

require('../edit-org/edit-org.js');
