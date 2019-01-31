/***************************************************************
 * Partnerlink Service
 * Service to the partnerlink tool and data access.
 * *************************************************************/
angular.module('PMTViewer').service('partnerLinkService', function ($q, $http, $rootScope, pmt) {
    
    // the partner link data service model
    var partnerLinkService = {
        filter: {
            data_group_ids: [],
            org_ids: []
        },
        organizations: []
    };
    
    // intialize the partnerlink
    partnerLinkService.init = function (data_group_ids) {
        $rootScope.$broadcast('partnerlink-sankey-updating');
        // set the data group ids to initialize with
        partnerLinkService.filter.data_group_ids = data_group_ids;
        // get the organizations that are associated to the data groups
        partnerLinkService.getOrganizations().then(function (orgs) {
            // get the sankey data
            partnerLinkService.getSankeyData().then(function (data) {
                // broadcast that the sankey data has changed
                $rootScope.$broadcast('partnerlink-sankey-updated', {
                    sankey: data
                });
            });
        });
    };

    // set a data group filter
    partnerLinkService.setDataGroupIds = function (ids) {
        var dataGroupIds = ids.split();
        _.each(dataGroupIds, function (id) {
            if (!_.contains(partnerLinkService.filter.data_group_ids, id)) {
                partnerLinkService.filter.data_group_ids.push(id);
                dataGroupUpdated();
            }
        });
    };
    
    // remove a data group filter
    partnerLinkService.removeDataGroupIds = function (ids) {
        var dataGroupIds = ids.split();
        _.each(dataGroupIds, function (id) {
            if (_.contains(partnerLinkService.filter.data_group_ids, id)) {
                partnerLinkService.filter.data_group_ids = _.reject(partnerLinkService.filter.data_group_ids, function (dg) { return dg == id; });
                dataGroupUpdated();
            }
        });
    };
    
    // set an organization filter
    partnerLinkService.setOrgId = function (id) {
        if (id) {
            if (!_.contains(partnerLinkService.filter.org_ids, id)) {
                partnerLinkService.filter.org_ids.push(id);
                filtersUpdated();
            }
        }
    };
    
    // remove an organization filter
    partnerLinkService.removeOrgId = function (id) {
        if (id) {
            if (_.contains(partnerLinkService.filter.org_ids, id)) {
                partnerLinkService.filter.org_ids = _.reject(partnerLinkService.filter.org_ids, function (o) { return o == id; });
                filtersUpdated();
            }
        }
    };
    
    // call the api to get data in the d3 sankey format (filterable)
    partnerLinkService.getSankeyData = function () {
        var deferred = $q.defer();
        var options = {
            data_group_ids: partnerLinkService.filter.data_group_ids.join(),
            classification_ids: null,
            org_ids: partnerLinkService.filter.org_ids.join(),
            start_date: null,
            end_date: null,
            pmtId: pmt.id[pmt.env]
        };
        var header = {
            headers: { Authorization: 'Bearer ' + $rootScope.currentUser.token }
        };
        // call the api to get the pmt partner link d3 sankey formatted data
        $http.post(pmt.api[pmt.env] + 'pmt_partner_sankey', options, header)
            .success(function (data, status, headers, config) {
            // console.log('pmt_partner_sankey:', data[0]);
            deferred.resolve(data[0]);
        })
            .error(function (data, status, headers, c) {
            // there was an error report it to the error handler
            console.log("error on api call to: pmt_partner_sankey");
            deferred.reject(status);
        });
        
        return deferred.promise;
    };
    
    // convert json data to csv format
    partnerLinkService.JSONToCSVConvertor = function (JSONData, ReportTitle, ShowLabel, callback) {
        // If JSONData is not an object then JSON.parse will parse the JSON string in an object
        var arrData = typeof JSONData != 'object' ? JSON.parse(JSONData) : JSONData;
        var CSV = '';
        
        // generate the label/header (t/f)
        if (ShowLabel) {
            var row = "";
            // this loop will extract the label from 1st index of on array
            for (var index in arrData[0]) {
                // now convert each value to string and comma-seprated
                row += index + ',';
            }
            row = row.slice(0, -1);
            // append Label row with line break
            CSV += row + '\r\n';
        }
        
        // 1st loop is to extract each row
        for (var i = 0; i < arrData.length; i++) {
            var row = "";
            // 2nd loop will extract each column and convert it in string comma-seprated
            for (var index in arrData[i]) {
                row += '"' + arrData[i][index] + '",';
            }
            row.slice(0, row.length - 1);
            //add a line break after each row
            CSV += row + '\r\n';
        }
        
        if (CSV == '') {
            return;
        }
        
        // generate a file name
        var fileName = "PMT_";
        // this will remove the blank-spaces from the title and replace it with an underscore
        fileName += ReportTitle.replace(/ /g, "_");
        
        // initialize file format you want csv or xls
        var uri = 'data:text/csv;charset=utf-8,' + escape(CSV);
        
        // now the little tricky part you can use either>> window.open(uri);
        // but this will not work in some browsers or you will not get the correct file extension
        
        //this trick will generate a temp <a /> tag
        var link = document.createElement("a");
        link.href = uri;
        
        //set the visibility hidden so it will not effect on your web-layout
        link.style = "visibility:hidden";
        //html5 download attribute
        link.download = fileName + ".csv";
        
        //this part will append the anchor tag and remove it after automatic click
        document.body.appendChild(link);
        link.click();
        document.body.removeChild(link);
        
        if (callback) {
            callback();
        }
    };
    
    // format the sankey data from the API
    partnerLinkService.quickParse = function (data) {
        var slimNodes = JSON.parse(JSON.stringify(_.filter(data.nodes, function (node) {
            return (node.level === 0 || node.level === 1);
        })));
        
        //&& link.source !== 2.1 && link.target !== 2.1 && link.source !== 3.2 && link.target !== 3.2 && (link.source !== 1 && link.target !== 1)
        var slimLinks = JSON.parse(JSON.stringify(_.filter(data.links, function (link) {
            return (link.source_level === 0 && link.target_level === 1);
        })));
        
        _.each(slimNodes, function (node, idx) {
            node.id = node.node;
            node.node = idx;
        });
        
        _.each(slimLinks, function (link) {
            var sourceMatch = _.find(slimNodes, function (node) {
                return node.id === link.source;
            });
            link.source = sourceMatch.node;
            var targetMatch = _.find(slimNodes, function (node) {
                return node.id === link.target;
            });
            link.target = targetMatch.node;
        });
        
        var slimmedData = JSON.parse(JSON.stringify({ nodes: slimNodes, links: slimLinks }));
        
        return slimmedData;
    };
    
    // get related sankey data information from a clicked node
    partnerLinkService.getRelatedData = function (maindata, sourceNode) {
        var deferred = $q.defer();
        
        var levels = [0, 1, 2];
        var startNode = sourceNode.id;
        
        var leveledNodes = _.filter(maindata.nodes, function (node) {
            return (_.indexOf(levels, node.level) > -1);
        });
        leveledNodes = JSON.parse(JSON.stringify(leveledNodes));
        
        var leveledLinks = _.filter(maindata.links, function (link) {
            return ((_.indexOf(levels, link.source_level)) > -1 && (_.indexOf(levels, link.target_level)) > -1);
        });
        leveledLinks = JSON.parse(JSON.stringify(leveledLinks));
        
        _.each(leveledNodes, function (node, idx) {
            node.id = node.node;
            node.node = idx;
        });
        
        var selectDownLinks = JSON.parse(JSON.stringify(_.filter(leveledLinks, function (link) {
            return link.source === startNode;
        })));
        
        var originalDownSources = _.uniq(_.pluck(selectDownLinks, "source"));
        
        var selectBackUpLinks = [];
        var excludeIds = [];
        _.each(selectDownLinks, function (downLink) {
            var thisTargetNode = _.findWhere(leveledNodes, { id: downLink.target });
            if (thisTargetNode.name == "Partner Not Reported") {
                excludeIds.push(thisTargetNode.id);
            }
        });
        
        // go through and filter out all faux partner links
        _.each(selectDownLinks, function (downLink) {
            var targetLinks = _.uniq(_.pluck(selectDownLinks, "target"));
            var eachUpLinks = _.filter(leveledLinks, function (link) {
                return (_.indexOf(targetLinks, link.target) > -1 && _.indexOf(excludeIds, link.target) == -1
);
            });
            selectBackUpLinks = _.union(selectBackUpLinks, eachUpLinks);
        });
        
        // go back through and add in the faux partners that are linked to the selected node
        _.each(selectDownLinks, function (downLink) {
            var eachUpLinks = _.filter(leveledLinks, function (link) {
                return (_.indexOf(excludeIds, link.target) > -1 && _.indexOf(originalDownSources, link.source) > -1);
            });
            selectBackUpLinks = _.union(selectBackUpLinks, eachUpLinks);
        });
        
        selectBackUpLinks = JSON.parse(JSON.stringify(selectBackUpLinks));
        
        var allBackUpLinks = [];
        
        _.each(selectBackUpLinks, function (upLink) {
            var sourceLinks = _.uniq(_.pluck(selectBackUpLinks, "source"));
            var eachUpLinks = _.filter(leveledLinks, function (link) {
                return (_.indexOf(sourceLinks, link.target) >= 0);
            });
            allBackUpLinks = _.union(selectBackUpLinks, eachUpLinks);
        });
        
        var allLinks = _.union(selectBackUpLinks, allBackUpLinks);
        
        var allNodes = JSON.parse(JSON.stringify(_.filter(leveledNodes, function (node) {
            var validNodes = _.union(_.pluck(allLinks, "source"), _.pluck(allLinks, "target"));
            return _.indexOf(validNodes, node.id) >= 0;
        })));
        
        _.each(allNodes, function (node, idx) {
            node.node = idx;
        });
        
        _.each(allLinks, function (link) {
            var sourceMatch = _.find(allNodes, function (node) {
                return node.id === link.source;
            });
            link.source = sourceMatch.node;
            
            var targetMatch = _.find(allNodes, function (node) {
                return node.id === link.target;
            });
            link.target = targetMatch.node;
        });
        
        var newChartData = JSON.parse(JSON.stringify({ nodes: allNodes, links: allLinks }));
        
        deferred.resolve(newChartData);
        
        return deferred.promise;
    };
    
    // get activity participation information by an organization name
    partnerLinkService.getActivities = function (organization, partnerlink_level) {
        var deferred = $q.defer();
        var options = {
            data_group_ids: partnerLinkService.filter.data_group_ids.join(),
            organization: organization,
            partnerlink_level: partnerlink_level,
            pmtId: pmt.id[pmt.env]
        };
        var header = {
            headers: { Authorization: 'Bearer ' + $rootScope.currentUser.token }
        };
        // call the api to get the activity participant information for a organization
        $http.post(pmt.api[pmt.env] + 'pmt_partner_sankey_activities', options, header)
            .success(function (data, status, headers, config) {
            // remove unneccessary response object from api
            var activities = _.pluck(data, 'response');
            deferred.resolve(activities);
        })
            .error(function (data, status, headers, c) {
            // there was an error report it to the error handler
            console.log("error on api call to: pmt_activity_participants_by_org");
            deferred.reject(status);
        });
        return deferred.promise;
    };
    
    // update the organization list based on data group filters
    partnerLinkService.getOrganizations = function () {
        var deferred = $q.defer();
        var options = {
            data_group_ids: partnerLinkService.filter.data_group_ids.join(),
            org_role_ids: null,
            pmtId: pmt.id[pmt.env]
        };
        var header = {
            headers: { Authorization : 'Bearer ' + $rootScope.currentUser.token }
        };
        $http.post(pmt.api[pmt.env] + 'pmt_org_inuse', options, header, { cache: true })
            .success(function (data, status, headers, config) {
            // remove unneccessary response object from api
            var orgs = _.pluck(data, 'response');
            // add the active parameter to our object
            _.each(orgs, function (o) {
                if (_.contains(partnerLinkService.filter.org_ids, o.id)) {
                    _.extend(o, { active: true });
                }
                else {
                    _.extend(o, { active: false });
                }                
                o.n = o.n.replace(/\r?\n|\r/g, '');
            });
            partnerLinkService.organizations = orgs;
            // return the orgs
            deferred.resolve(orgs);
        })
            .error(function (data, status, headers, c) {
            // there was an error report it to the error handler
            console.log("error on api call to: pmt_org_inuse");
            deferred.reject(status);
        });
        
        return deferred.promise;
    };
    
    // private function to handle sankey and organization updates when
    // data groups change
    function dataGroupUpdated() {
        $rootScope.$broadcast('partnerlink-sankey-updating');
        // check to see if all filters are empty
        if (partnerLinkService.filter.data_group_ids.length === 0) {
            // broadcast that the sankey data has changed
            $rootScope.$broadcast('partnerlink-sankey-updated', {
                data: null
            });
        }
        else {
            // get the organizations that are associated to the data groups
            partnerLinkService.getOrganizations().then(function (orgs) {
                //if org from org filter not in list of updated orgs, remove it from the filter
                _.each(partnerLinkService.filter.org_ids, function(o) {
                    if (!_.contains(orgs, o)) {
                        partnerLinkService.removeOrgId(o);
                    }
                });
                // get the sankey data
                partnerLinkService.getSankeyData().then(function (data) {
                    // broadcast that the sankey data has changed
                    $rootScope.$broadcast('partnerlink-sankey-updated', {
                        sankey: data
                    });
                });
            });  
        }
    }
    
    // private function to handle sankey updates when filters change
    function filtersUpdated() {
        $rootScope.$broadcast('partnerlink-sankey-updating');
        // get the sankey data
        partnerLinkService.getSankeyData().then(function (data) {
            // broadcast that the sankey data has changed
            $rootScope.$broadcast('partnerlink-sankey-updated', {
                sankey: data
            });
        });
    }
    
    return partnerLinkService;
});
