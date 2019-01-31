/***************************************************************
 * Detail Controller
 * Supports the details feature. Users can click on pmt layer
 * points on the map and view details for the activities
 * associated to the feature.
 * *************************************************************/
angular.module('PMTViewer').controller('MapDetailCtrl', function ($scope, $rootScope, stateService, mapService, activityService, pmtMapService, config) {
    $scope.stateService = stateService;
    // details object for active detail
    $scope.activeDetail = {};
    // index of the current displayed detail
    $scope.activeDetailIdx = 0;
    // total number of details
    $scope.numDetails = 0;
    // the list of selected details (activities)
    $scope.selectedDetails = {};
    // loading flag
    $scope.loading = false;
    //track whether list of activities or a single activity is displayed in panel
    $scope.displayDetailsList = true;
    // determine if editor is enabled
    $scope.hasEditor = hasEditor();
    // locations on map toggle
    $scope.locationsOn = false;
    // tab config
    $scope.tabConfig = $scope.page.tools.map.tabs.financials;

    // when pmtMapService boadcasts the pmt feature details 
    // are loading do this
    $scope.$on('pmt-feature-details-loading', function () {
        // open the details panel
        stateService.openParam('detail-panel');
        // activate the loader
        $scope.loading = true;
        mapService.clearGeojson();
        stateService.closeParam('activity-locations');
    });

    // when pmtMapService broadcasts that a pmt map feature 
    // details are loaded do this
    $scope.$on('pmt-feature-details-loaded', function () {
        try {
            // loading flag
            $scope.loading = false;
            // reset the number of details
            $scope.numDetails = pmtMapService.selectedDetails.length || 0;
            //get the selected details (activities)
            $scope.selectedDetails = pmtMapService.selectedDetails;
            // reset the active detail
            $scope.activeDetailIdx = 0;
            // clear the details object
            $scope.activeDetail = {};
            // if there are details show the active detail
            if ($scope.numDetails > 0) {
                $scope.showDetail($scope.activeDetailIdx, true);
                // default the details panel to the list of activities
                if ($scope.numDetails > 1) {
                    $scope.displayDetailsList = true;
                }
                // go directly to details list
                else {
                    $scope.displayDetailsList = false;
                }
            }
            if ($scope.numDetails > 1) {
                //default the details panel to the list of activities
                $scope.displayDetailsList = true;
            }
            else {
                // go directly to details list
                $scope.displayDetailsList = false;
            }
        }
        catch (e) {
        }
    });

    // when pmtMapService broadcasts that a pmt map feature has
    // been unselected do this
    $scope.$on('unselect-pmt-map-feature', function () {
        try {
            // reset the number of details
            // pmtMapService.selectedDetails = [];
            //$scope.numDetails = 0;
            // reset the active detail
            //$scope.activeDetailIdx = 0;
            // clear the details object
            //$scope.activeDetail = {};
        }
        catch (e) {
        }
    });

    // when the url is updated do this
    $scope.$on('route-update', function () {
        if (stateService.isNotParam('detail-panel') && stateService.isState('map')) {
            mapService.clearGeojson();
            stateService.closeParam('activity-locations');
        }
        if (stateService.isParam('activity-locations')) {
            showLocations();
        }
        else {
            mapService.clearGeojson();
        }
        $scope.repositionMapControls();
    });

    // show a single activity detail
    $scope.showDetail = function (idx, parent) {
        // locations on map toggle
        $scope.locationsOn = false;
        //detail to info tab
        $scope.selectedTab = 0;
        // clear any previously selected locations
        mapService.clearGeojson();
        //set activity id
        var activity_id = null;
        // the requested index is the active detail index and is a parent activity
        if (typeof idx === 'number' && parent) {
            $scope.activeDetailIdx = idx;
            activity_id = pmtMapService.selectedDetails[idx].id;
        }
        else {
            //else if child activity
            activity_id = idx;

        }

        // get detail                     
        pmtMapService.getDetail(activity_id).then(function (d) {
            $scope.activeDetail = d[0].response;

            // process data for each UI activity details tabs
            $scope.activeDetail.overviewDetails = processOverview($scope.activeDetail);
            $scope.activeDetail.taxonomyDetails = processTaxonomies($scope.activeDetail.taxonomy);
            $scope.activeDetail.financialsDetails = processFinancials($scope.activeDetail.financials);
            $scope.activeDetail.locationDetails = processLocations($scope.activeDetail.locations);
            $scope.activeDetail.organizationDetails = processOrganizations($scope.activeDetail.organizations);


            if ($scope.page.mergeRelatedActivities) {
                //create counts to know when all children have been received
                $scope.activeDetail.childrenLoadedMax = $scope.activeDetail.children ? $scope.activeDetail.children.length : null;
                $scope.activeDetail.childrenCount = 0;
                $scope.activeDetail.childrenMappedMax = $scope.activeDetail.children ? $scope.activeDetail.children.length : null;
                $scope.activeDetail.childrenMappedCount = 0;
                //if project has children, get each child's data
                _($scope.activeDetail.children).each(function (child) {
                    getChildActivity(child.id);
                });
            }

            // check details
            if($scope.activeDetail.details){
                var financial_details = [];
                _.each($scope.activeDetail.details, function(detail){
                    if(detail._amount){
                        try{
                            detail.total = $scope.activeDetail.overviewDetails.total_amount * (detail._amount/100);
                        } 
                        catch(ex){
                            detail.total = 0;
                        }
                        financial_details.push(detail);
                    }
                });
                if(financial_details.length>0){
                    $scope.activeDetail.detailsFinancial = financial_details;
                }
            }

        });
    };

    // called when next detail icon is clicked
    $scope.nextDetail = function () {
        try {
            var len = pmtMapService.selectedDetails.length;
            if (++$scope.activeDetailIdx >= len) {
                $scope.activeDetailIdx = 0;
            }
            $scope.showDetail($scope.activeDetailIdx, true);
        }
        catch (ex) {
            // there was an error report it to the error handler
        }
    };

    // called when previous detail icon is clicked
    $scope.prevDetail = function () {
        try {
            var len = pmtMapService.selectedDetails.length;
            if (--$scope.activeDetailIdx < 0) {
                $scope.activeDetailIdx = len - 1;
            }
            $scope.showDetail($scope.activeDetailIdx, true);
        }
        catch (ex) {
            // there was an error report it to the error handler
        }
    };

    // toggle locations on/off map
    $scope.toggleParam = function () {
        stateService.toggleParam('activity-locations');
    };

    // toggle display list
    $scope.toggleDisplayList = function () {
        mapService.clearGeojson();
        $scope.displayDetailsList = !$scope.displayDetailsList;
    };

    // function to link activity list to activity module
    $scope.goToActivity = function (activity_id) {
        var params = { "activity_id": activity_id };
        stateService.setState("activities", params, true);
    };

    // navigate to edit page to edit activity
    $scope.editActivity = function (activity_id) {
        var params = { "editor_activity_id": activity_id };
        stateService.setState("editor", params, true);
    };

    // toggle whether seeing child activity details on the list
    $scope.toggleActive = function (act) {
        act.active = !act.active;
        act.arrow = (act.active) ? "keyboard_arrow_up" : "keyboard_arrow_down";
    };

    function getChildActivity(id) {
        //check to see if sub activity data has been requested
        $scope.loading = true;
        // get detail details
        activityService.getDetail(id).then(function (d) {

            var child = _($scope.activeDetail.children).find({ id: id });
            //if valid activity
            if (d.length > 0) {
                child.activeDetail = d[0].response;

                // process data for each UI activity details tabs
                child.activeDetail.overviewDetails = activityService.processOverview(child.activeDetail);
                child.activeDetail.taxonomyDetails = activityService.processTaxonomies(child.activeDetail.taxonomy);
                child.activeDetail.financialsDetails = activityService.processFinancials(child.activeDetail.financials);
                child.activeDetail.locationDetails = activityService.processLocations(child.activeDetail.locations);
                child.activeDetail.organizationDetails = activityService.processOrganizations(child.activeDetail.organizations);
            }

            $scope.activeDetail.childrenCount += 1;
            if ($scope.activeDetail.childrenCount === $scope.activeDetail.childrenLoadedMax) {
                //deactivate the loader once all requests are complete
                $scope.loading = false;
                $scope.activeDetail.childrenLoaded = true;
                $scope.activeDetail.childLocationDetails = _.chain($scope.activeDetail.children).pluck('activeDetail').pluck('locationDetails').flatten().value();
            }


        });

    }

    // show an activity's locations on map
    function showLocations() {
        var location_ids = [];
        // collect parent location ids
        if ($scope.activeDetail.location_ids) {
            location_ids = $scope.activeDetail.location_ids.join(',');
        }
        // collect child locations ids
        if($scope.activeDetail.children){
            location_ids = _.chain($scope.activeDetail.children).pluck("activeDetail").pluck("location_ids").union(location_ids).compact().value().join(',');
        }
        // add locations to map if there are any to show   
        if(location_ids.length > 1){
            mapService.clearGeojson();
            pmtMapService.getLocations(location_ids).then(function (locations) {
                _.each(locations, function (location) {
                    //check if location is a polygon
                    if (location.response.polygon !== null) {
                        // check admin level and assign appropriate admin class
                        switch (location.response._admin_level) {
                            case 1:
                                mapService.addGeojson(JSON.parse(location.response.polygon), "admin1");
                                break;
                            case 2:
                                mapService.addGeojson(JSON.parse(location.response.polygon), "admin2");
                                break;
                            case 3:
                                mapService.addGeojson(JSON.parse(location.response.polygon), "admin3");
                                break;
                            default:
                                //todo error there shouldn't be geometry without amin1/2/3
                                break;
                        }
                    }
                    else {
                        if (location.response.point !== null) {
                            mapService.addGeojson(JSON.parse(location.response.point));
                        }
                    }
                });
                //zoon to geojson
                //mapService.map.fitBounds(mapService.geojson.getBounds());

            });
        }                    
    }

    // function to process overview data for UI activity panel
    function processOverview(activityData) {
        //taxonomy object
        var overviewDetails = {};
        //data group
        _.each($scope.page.tools.map.layers, function (filter) {
            var dgs = filter.dataGroupIds.split(',');
            if (_.contains(dgs, activityData.data_group_id.toString())) {
                activityData.data_group = filter.label;
            }
        });
        overviewDetails.data_group = activityData.data_group;
        //objective
        overviewDetails.objective = activityData._objective;
        //content
        overviewDetails.content = activityData._content;
        //start_date
        overviewDetails.start_date = activityData._start_date;
        //end_date
        overviewDetails.end_date = activityData._end_date;
        //planned start_date
        overviewDetails.plan_start_date = activityData._plan_start_date;
        //planned end_date
        overviewDetails.plan_end_date = activityData._plan_end_date;
        //tags
        overviewDetails.tags = activityData._tags;

        // get the beneficiaries configuration
        $scope.beneficiaryConfig = _.chain(config.states).where({ route: 'editor' }).pluck("tools").pluck("editor").pluck("activity").pluck("beneficiary").first().value();
        if ($scope.beneficiaryConfig) {
            //beneficiaries
            overviewDetails.beneficiary_type = _.chain($scope.beneficiaryConfig.beneficiary_type.values).where({ value: activityData.beneficiary_type }).pluck("label").first().value();
            overviewDetails.beneficiary_unit = _.chain($scope.beneficiaryConfig.beneficiary_unit.values).where({ value: activityData.beneficiary_unit }).pluck("label").first().value();
            overviewDetails.direct_beneficiaries = activityData.direct_beneficiaries;
            overviewDetails.indirect_beneficiaries = activityData.indirect_beneficiaries;
            overviewDetails.female_individual_direct = activityData.female_individual_direct;
            overviewDetails.female_individual_indirect = activityData.female_individual_indirect;
            overviewDetails.female_hhds_direct = activityData.female_hhds_direct;
            overviewDetails.female_hhds_indirect = activityData.female_hhds_indirect;
            overviewDetails.male_individual_direct = activityData.male_individual_direct;
            overviewDetails.male_individual_indirect = activityData.male_individual_indirect;
            overviewDetails.male_hhds_direct = activityData.male_hhds_direct;
            overviewDetails.male_hhds_indirect = activityData.male_hhds_indirect;
            overviewDetails.institutes_direct = activityData.institutes_direct;
            overviewDetails.institutes_indirect = activityData.institutes_indirect;
        }

        //taxonomy sector category array
        overviewDetails.sector_category = [];
        //taxonomy sector array
        overviewDetails.sector = [];
        //taxonomy activity status array
        overviewDetails.activity_status = [];

        //loop through all taxonomies
        _.each(activityData.taxonomy, function (taxonomy) {
            //sector category
            if (taxonomy.taxonomy == 'Sector Category') {
                overviewDetails.sector_category.push(taxonomy.classification);
            }
            //sector
            else if (taxonomy.taxonomy == 'Sector') {
                overviewDetails.sector.push(taxonomy.classification);
            }
            //activity status
            else if (taxonomy.taxonomy == 'Activity Status') {
                overviewDetails.activity_status.push(taxonomy.classification);
            }
            //version
            else if (taxonomy.taxonomy == 'Version') {
                overviewDetails.version = taxonomy.classification;
            }
        });

        //turn arrays into string lists for UI
        overviewDetails.sector_category = overviewDetails.sector_category.join(', ');
        overviewDetails.sector = overviewDetails.sector.join(', ');
        overviewDetails.activity_status = overviewDetails.activity_status.join(', ');

        //financial amount
        overviewDetails.total_amount = _.reduce((_.pluck(activityData.financials, '_amount')), function (amount, num) {
            return amount + num;
        }, 0);

        //country
        //loop through taxonomy data
        _.each(activityData.taxonomy, function (taxonomy) {
            //country
            if (taxonomy.taxonomy == 'Country') {
                overviewDetails.country = taxonomy.classification;
            }
        });
        //array for additional resources
        overviewDetails.additionalResources = [];
        //if there are supplemental resources, add them
        if ($scope.page.tools.map.supplemental.length > 0) {
            _.each($scope.page.tools.map.supplemental, function (s) {
                var foundMatch = false;

                //get all classifications for activity
                var allClass = [];
                _.each(activityData.taxonomy, function (t) {
                    allClass.push(t.classification_id);
                });
                //check if any classifications match
                _.each(allClass, function (c) {
                    if (_.contains(s.classification_ids, c) && foundMatch === false) {
                        overviewDetails.additionalResources.push(s);
                        foundMatch = true;
                    }
                });
                //check keyword match
                if (foundMatch === false) {
                    //grab fields to query text from
                    _.each(s.keywords.fields, function (f) {
                        var searchArray = activityData[f].toLowerCase();
                        //loop through keywords to see if in array of keyword field
                        _.each(s.keywords.keywords, function (k) {
                            if (searchArray.includes(k.toLowerCase()) && foundMatch === false) {
                                overviewDetails.additionalResources.push(s);
                                return;
                            }
                        });
                    });
                }
            });
        }
        return overviewDetails;
    }

    // function to process taxonomies for UI activity panel
    function processTaxonomies(activityTaxonomies) {
        //taxonomy object
        var taxonomyDetails = {};
        //taxonomy sector category array
        taxonomyDetails.sector_category = [];
        //taxonomy sector array
        taxonomyDetails.sector = [];
        //taxonomy activity status array
        taxonomyDetails.activity_status = [];
        //taxonomy activity scope array
        taxonomyDetails.activity_scope = [];
        //taxonomy custom fields object
        taxonomyDetails.custom = {};

        //loop through all taxonomies
        _.each(activityTaxonomies, function (taxonomy) {
            //sector category
            if (taxonomy.taxonomy == 'Sector Category') {
                taxonomyDetails.sector_category.push(taxonomy.classification);
            }
            //sector
            else if (taxonomy.taxonomy == 'Sector') {
                taxonomyDetails.sector.push(taxonomy.classification);
            }
            //activity status
            else if (taxonomy.taxonomy == 'Activity Status') {
                taxonomyDetails.activity_status.push(taxonomy.classification);
            }
            //activity scope
            else if (taxonomy.taxonomy == 'Activity Scope') {
                taxonomyDetails.activity_scope.push(taxonomy.classification);
            }
            //custom
            else {
                taxonomyDetails.custom[taxonomy.taxonomy] = (typeof taxonomyDetails.custom[taxonomy.taxonomy] != 'undefined' && taxonomyDetails.custom[taxonomy.taxonomy] instanceof Array) ? taxonomyDetails.custom[taxonomy.taxonomy] : [];
                taxonomyDetails.custom[taxonomy.taxonomy].push(taxonomy.classification);
            }
        });

        //turn arrays into string lists for UI
        taxonomyDetails.sector_category = taxonomyDetails.sector_category.join(', ');
        taxonomyDetails.sector = taxonomyDetails.sector.join(', ');
        taxonomyDetails.activity_status = taxonomyDetails.activity_status.join(', ');
        taxonomyDetails.activity_scope = taxonomyDetails.activity_scope.join(', ');
        taxonomyDetails.custom_taxonomy = {};
        _.reduce(taxonomyDetails.custom, function (tax, value, key) {
            taxonomyDetails.custom_taxonomy[key] = value.join(', ');
            return tax;
        }, {});

        return taxonomyDetails;
    }

    // function to process financial data for UI activity panel
    function processFinancials(activityFinancials) {
        //financials array
        var financialDetails = [];

        // loop through all financials
        _.each(activityFinancials, function (financial) {
            //create new financial object
            var financialElement = {};

            //provider
            financialElement.provider = financial.provider;
            //recipient
            financialElement.recipient = financial.recipient;
            // amount
            financialElement.amount = financial._amount;

            //loop through taxonomy data
            _.each(financial.taxonomy, function (taxonomy) {
                //financial type category
                if (taxonomy.taxonomy == 'Finance Type (category)') {
                    financialElement.finance_category = taxonomy.classification;
                }
                //financial type
                if (taxonomy.taxonomy == 'Finance Type') {
                    financialElement.finance_type = taxonomy.classification;
                }
                //transaction type
                if (taxonomy.taxonomy == 'Transaction Type') {
                    financialElement.transaction_type = taxonomy.classification;
                }
                //currency
                if (taxonomy.taxonomy == 'Currency') {
                    financialElement.currency = taxonomy._code;
                    if (!_.has($scope.activeDetail.overviewDetails, 'currency')) {
                        $scope.activeDetail.overviewDetails.currency = taxonomy._code;
                    }
                }
            });
            // add element to array of financials
            financialDetails.push(financialElement);
        });
        return financialDetails;
    }

    // function to process location data for UI activity panel
    function processLocations(activityLocations) {
        //array of locations
        var locationDetails = [];

        _.each(activityLocations, function (location) {
            //create new location object
            var locationElement = {};
            //admin 1
            locationElement.admin1 = location._admin1;
            //admin 2
            locationElement.admin2 = location._admin2;
            // admin 3
            locationElement.admin3 = location._admin3;

            //loop through taxonomy data
            _.each(location.taxonomy, function (taxonomy) {
                //country
                if (taxonomy.taxonomy == 'Country') {
                    locationElement.country = taxonomy.classification;
                }
                //location type
                if (taxonomy.taxonomy == 'Location Type') {
                    locationElement.location_type = taxonomy.classification;
                }
                //transaction type
                if (taxonomy.taxonomy == 'Location Flag') {
                    locationElement.location_flag = taxonomy.classification;
                }
                //national/local
                if (taxonomy.taxonomy == 'National/Local') {
                    locationElement.national_local = taxonomy.classification;
                }
            });
            // add element to array of financials
            locationDetails.push(locationElement);
        });
        return locationDetails;
    }

    //f unction to process organization data for UI activity detail
    function processOrganizations(activityOrganizations) {
        var organizationDetails = {};
        organizationDetails.implementingOrgs = [];
        organizationDetails.fundingOrgs = [];
        organizationDetails.accountableOrgs = [];
        organizationDetails.organizationCount = 0;

        // group organizations by role
        _.each(activityOrganizations, function (org) {
            if (org.role == 'Implementing') {
                organizationDetails.implementingOrgs.push(org);
                organizationDetails.organizationCount = organizationDetails.organizationCount + 1;
            }
            else if (org.role == 'Funding') {
                organizationDetails.fundingOrgs.push(org);
                organizationDetails.organizationCount = organizationDetails.organizationCount + 1;
            }
            else if (org.role == 'Accountable') {
                organizationDetails.accountableOrgs.push(org);
                organizationDetails.organizationCount = organizationDetails.organizationCount + 1;
            }
        });

        return organizationDetails;
    }

    // determine if instances has the editor enabled
    function hasEditor() {
        var enabled;
        _.each(config.states, function (state) {
            if (state.route === 'editor') {
                enabled = state.enable;
            }
        });
        return enabled;
    }

});

require('../children/details/details.js');
require('../children/organization/organization.js');
require('../children/taxonomy/taxonomy.js');
require('../children/location/location.js');