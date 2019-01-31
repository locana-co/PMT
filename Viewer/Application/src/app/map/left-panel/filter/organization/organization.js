/***************************************************************
 * Organization Filter Controller
 * A filter controller. Supports the filtering of PMT layers by 
 * organizations. Usage is defined in the app.config in the map 
 * page filter object.
* *************************************************************/
angular.module('PMTViewer').controller('MapFilterOrganizationCtrl', function ($scope, $rootScope, $element, stateService, config, pmtMapService, mapService) {

    var initialized = false;
    var dataGroupIds = null;

    // when the selected pmt map filter changes do this
    $scope.$on('pmt-filter-update', function () {
        validateActive();
    });

    // when the selected filter changes do this
    $scope.$on('filter-menu-selected', function () {
        // scroll back to the top
        $('div.sub-menu').scrollTop(0);
        // intitalize the template
        init();
    });

    // organization index clicked
    $scope.indexClicked = function (i) {
        // scroll back to the top
        $('div.sub-menu').scrollTop(0);
        // find position of first organization that starts with selected letter (i)
        var org = $(".sub-menu-option-container.active .index_" + i).first().offset().top;
        var heightToContainer;
        // nav (45) + global tabs (50) + filter tabs (50) + header (50) + height of first org '-' 35 and potentially org selection bar (30)
        if ($scope.selectedOrgs) {
            heightToContainer = ($scope.selectedOrgs.length > 0) ? 260 : 230;
        } else {
            heightToContainer = 230;
        }
        // animate the scroll to organization position
        $('div.sub-menu').animate({
            scrollTop: org - heightToContainer
        }, 1000);
    };

    // organization name checked
    $scope.orgClicked = function (org) {
        // toggle current org active flag
        org.active = !org.active;
        $scope.selectedOrgs = [];
        // get all the selected organizations
        _.each($scope.filter.options, function (o) {
            if (o.active === true) {
                $scope.selectedOrgs.push(o.id);
            }
        });
        // set the filter in the pmtMapService based on type
        switch ($scope.filter.params.type) {
            case 'implementing':
                pmtMapService.setImpOrgFilter($scope.selectedOrgs);
                break;
            case 'funding':
                pmtMapService.setFundOrgFilter($scope.selectedOrgs);
                break;
            default:
                pmtMapService.setOrgFilter($scope.selectedOrgs);
                break;
        }
    };

    // organization filter initialization
    function init() {
        var activeDataGroupIds = pmtMapService.getDataGroupIds();
        // if the selected data groups have changed update or if the filter hasn't been
        // initialized then update the organization list
        if (!_.isEqual(dataGroupIds, activeDataGroupIds) || !initialized) {
            // get the data groups currently in use (on the map)
            dataGroupIds = pmtMapService.getDataGroupIds();
            // get the id of the div (which is the filter id value from the config)
            var filterId = $($element[0]).parent().attr("id");
            // get the filter by id from the config
            $scope.filter = _.find($scope.page.tools.map.filters, function (filter) { return filter.id == filterId; });
            // if the filter is valid
            if ($scope.filter) {
                // using the pmt map service, get all the organizations for the filter
                pmtMapService.getOrgsInUse($scope.filter.params.org_role_ids, $scope.filter.params.type).then(function (orgs) {
                    // get the distinct list of first letters from all the orgs
                    var idx = _.union(_.pluck(orgs, 'o'));
                    // remove the bad chars from our index
                    idx = _.difference(idx, ['-', '"']);
                    // sort the organizations by name
                    orgs = _.sortBy(orgs, 'n');
                    // convert all to title case
                    _.each(orgs, function (o) {
                        var regExp = /\(([^)]+)\)/;
                        o.n = toTitleCase(o.n);
                        var match = regExp.exec(o.n);
                        if (match) {
                            var replacement = match[1].toUpperCase();
                            o.n = o.n.replace(/\(.*?\)/, "(" + replacement + ")");
                        }
                    });
                    // assign the prepared variables to scope
                    $scope.filter.options = orgs;
                    // set the filter size
                    $scope.filter.size = $scope.filter.options.length;
                    $scope.index = idx;
                    // set init flag true
                    initialized = true;
                });
            }
        }
    }

    // validate active organizations via filter
    function validateActive() {
        if ($scope.filter) {
            // selected filters (organizations)
            var filters = [];
            // set the filter in the pmtMapService based on type
            switch ($scope.filter.params.type) {
                case 'implementing':
                    filters = pmtMapService.getImpOrgFilters();
                    break;
                case 'funding':
                    filters = pmtMapService.getFundOrgFilters();
                    break;
                default:
                    filters = pmtMapService.getOrgFilters();
                    break;
            }
            // set the active organizations
            _.each($scope.filter.options, function (o) {
                o.active = false;
                if (filters.indexOf(o.id) > -1) {
                    o.active = true;
                }
            });
        }
    }

    // convert any string to title case
    function toTitleCase(str) {
        return str.replace(/\w\S*/g, function (txt) { return txt.charAt(0).toUpperCase() + txt.substr(1).toLowerCase(); });
    }

    // initialize the filter
    init();

});