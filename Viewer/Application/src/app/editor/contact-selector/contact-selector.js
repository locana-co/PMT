module.exports = angular.module('PMTViewer').controller('EditorContactSelectorCtrl', function ($scope, $rootScope, $mdDialog, editorService) {

    // initialze module
    init();
    $scope.searchText = null;

    // update the selected contact
    $scope.updateContact = function () {
        var contact = _.find($scope.contacts, function (o) { return o.id == $scope.dialogSettings.selectedOrg; });
        //clear search for next time contact list is opened. 
        this.searchConText = "";
        // close modal
        $mdDialog.hide(contact);
    };

    // update the selected contact
    $scope.loadContacts = function () {
        $scope.loadingContacts = true;
        $scope.contacts = _.chain(editorService.getAllContacts()).filter(function(o){ return $scope.dialogSettings.idsToExclude.indexOf(o.id) < 0;}).sortBy('_last_name').value();
        
        //see if we need to request data
        getContacts();
    };

    // on selection of contact radio button, toggle feature selected
    // required because we are using dynamic HTML and cannot use md-radio ng-model
    $scope.selectedContact = function (id) {
        // find the feature location by id
        $scope.dialogSettings.selectedContact = _.find($scope.contacts, function (o) { return o.id === id; });
        if ($scope.dialogSettings.selectedContact) {
            // mark all inactive
            _($scope.contacts).each(function (o) { 
                o.selected = false; 
                o.delete = false;
            });
            //set current to active 
            $scope.dialogSettings.selectedContact.selected = true;
        }
        $("md-dialog").scrollTop(0);
    };

    // on click function for close buttons
    $scope.cancel = function () {
        $mdDialog.cancel();
    };

    // watch the search input for changes and set search
    $scope.$watch('searchConText', setSearch);

    // regenerate the menu including only searched text
    function setSearch(searchText) {
        $scope.menuUI = generateMenu(!searchText ? null : searchText);
    }

    // intialize the modal
    function init() {
        // set loading true
        $scope.loadingContacts = true;
        // collect the data groups
        var dataGroupIds = [];
        _.each($scope.settings.datagroups, function (dg) {
            dataGroupIds.push(dg.data_group_id);
        });
        $scope.loadingContacts = true;
        // initialize the contact list
        $scope.contacts = _(editorService.getAllContacts()).filter(function(o){ return $scope.dialogSettings.idsToExclude.indexOf(o.id) < 0;});

        getContacts();
    }

    // private function to prepare contacts for display
    // ends by regenerating the menu
    function getContacts() {
       // if the list is empty then it is the first call, lets populate it
       if ($scope.contacts.length <= 0) {
            editorService.getContacts().then(function (contacts) {
                $scope.contacts = _.chain(contacts).filter(function(o){ 
                    return $scope.dialogSettings.idsToExclude.indexOf(o.id) < 0;
                }).sortBy('_last_name').map(function(c){
                    c.selected = false;
                    c.delete = false;
                    c.organization_id = c.o_id;
                    c.organization_name = c.org;
                    delete c.o_id;
                    delete c.org;
                    return c;
                }).value();
                
                $scope.menuUI = generateMenu(null);
                $scope.loadingContacts = false;
            });
        }
        else {
            $scope.loadingContacts = false;
            $scope.menuUI = generateMenu(null);
        }
    }

    // private function to dynamically generate the HTML for the
    // menu (listing of contacts) 
    // using this approach over ng-repeat in case of an overly large collection
    // where ng-repeat causes extreme performance issues
    function generateMenu(searchText) {
        // the HTML for the menu
        var menuHTML = '';
        _.each($scope.contacts, function (contact) {
            if (searchText === null || 
                (contact._last_name && contact._last_name.toLowerCase().indexOf(searchText.toLowerCase()) >= 0) || 
                (contact._first_name && contact._first_name.toLowerCase().indexOf(searchText.toLowerCase()) >= 0)) {
                menuHTML += '<div class="radio">';
                menuHTML += '<input type="radio" ng-checked="' + Boolean($scope.dialogSettings.selectedContact && $scope.dialogSettings.selectedContact.id===contact.id).toString() + '" name="contacts" value="' + contact.id + '" id="' + contact.id + '" ng-click="selectedContact(' + contact.id + ');"/>';
                menuHTML += '<label for="' + contact.id + '" class="radio-label">' + contact._last_name + ", " + contact._first_name + '</label>';
                menuHTML += '</div>';
            }
        });
        return menuHTML;
    }

});