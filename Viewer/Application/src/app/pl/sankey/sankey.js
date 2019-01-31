/***************************************************************
 * Partnerlink Sankey Diagram Controller
 * Supports the partnerlink sankey diagram.
 ***************************************************************/
angular.module('PMTViewer').controller('PLSankeyCtrl', function ($scope, $rootScope, $mdDialog, pmtMapService, partnerLinkService, utilService, stateService) {
    var apiData; // raw sankey data from the api unformatted
    $scope.tabs = { selectedTab: 0, detailTabLabel: "" };
    $scope.LoadingCharts = false;    // loading symbol

    // when the partnerlink sankey is updating, do this
    $scope.$on('partnerlink-sankey-updating', function (event, data) {
        // turn on loading
        $scope.LoadingCharts = true;
        // set empty to false
        $scope.sankeyEmpty = false;
        // clear the sankey visualizations
        clearSankey();
        clearSankeyDetail();
        // set the selected tab to the partnerlink
        $scope.tabs.selectedTab = 0;
        // clear detail tab label
        $scope.tabs.detailTabLabel = "";
    });

    // when the partnerlink sankey is updated, do this
    $scope.$on('partnerlink-sankey-updated', function (event, data) {
        // turn off loading
        $scope.LoadingCharts = false;
        if (data.sankey) {
            //sankey not empty
            $scope.sankeyEmpty = false;
            // create sankey
            apiData = data.sankey.response;
            var sankeyData = partnerLinkService.quickParse(apiData);
            goSankey(sankeyData, "#pl-sankey-chart");
        } else {
            // sankey is empty
            $scope.sankeyEmpty = true;
        }
        $scope.resizeSankey();
    });

    //resize function
    $scope.resizeSankey = function () {
        try {
            var fullHeight = $("#pl-sankey").height();
            var tabHeight = $("#pl-sankey md-tabs-wrapper").height();
            var calHeight = (fullHeight - tabHeight - 30);
            var height = (calHeight > 50) ? calHeight : 150;
            $(".sankey-tab").height(height);
        }
        catch (e) { }
    };

    // clear the sankey diagram
    function clearSankey() {
        $("#pl-sankey-chart").empty();
    }

    // clear the sankey diagram
    function clearSankeyDetail() {
        $("#pl-sankey-chart-detail").empty();
        $("#pl-sankey-chart-detail").html('<div class="modal-body container"><div id="pl-sankey-chart-detail-popup"></div></div>');
    }

    // build the sankey diagram
    function goSankey(data, mainEl) {
        clearSankey();

        var formatNumber = d3.format(",.0f"),
            format = function (d) { return formatNumber(d); };

        // build the sankey diagram
        function buildSankey(sankeydata, el, focalNode) {
            var valueTotal = 0;
            var totalLevelZero = 0;
            var totalLevelOne = 0;
            var totalLevelTwo = 0;
            //if nodes less than 10, make magic number bigger
            var magicNumber = (sankeydata.nodes.length > 10) ? 0.02 : 10;
            var maxValue = _.max(sankeydata.links, function(link){
                return link.value;
            });
            var colorRange = $scope.page.tools.color_range;
            var scale = d3.scale.linear().domain([0,maxValue.value]).range(colorRange);
            var granteeNotReportedLabel = $scope.page.tools.grantee_not_reported_label;
            var partnerNotReportedLabel = $scope.page.tools.partner_not_reported_label;
            var funderNotReportedLabel = $scope.page.tools.funder_not_reported_label;
            // loop over all the links
            _.each(sankeydata.links, function (d) {
                valueTotal += d.value;
            });
            // loop through all the nodes
            _.each(sankeydata.nodes, function (d) {
                totalLevelZero = (d.level === 0) ? totalLevelZero + 1 : totalLevelZero;
                totalLevelOne = (d.level === 1) ? totalLevelOne + 1 : totalLevelOne;
                totalLevelTwo = (d.level === 2) ? totalLevelTwo + 1 : totalLevelTwo;
            });

            var totalMax = Math.max(totalLevelOne, totalLevelZero);
            var padding = 15;
            var height = (valueTotal * magicNumber) + (totalMax * padding);

            if (focalNode) {
                totalMax = Math.max(totalLevelZero, totalLevelOne, totalLevelTwo);
                height = (valueTotal * magicNumber) + (totalMax * padding);
                height = Math.max(height, 425);
            }

            var width = $(el).width();
            var chartWidths = (focalNode ? width - 30 : width);
            var headerheight = 20;
            var targetEl;

            if (focalNode) {
                var targetModal = d3.select(el);
                targetModal.style('display', 'block');
                targetEl = el + ' .modal-body';
            } else {
                targetEl = el;
            }

            var headers = d3.select(targetEl).append("div")
                .classed("headers", true)
                .classed("detail-modal-header", function () { return (focalNode ? true : false); });

            var sankeyHeaders = headers.append("div")
                .style("width", chartWidths + "px")
                .style("height", headerheight + "px")
                .classed("sankey-headers", true);

            sankeyHeaders.append("span")
                .text("FUNDER")
                .style("float", "left");
            sankeyHeaders.append("span")
                .text((focalNode ? "PARTNER" : "GRANTEE"))
                .style("float", "right");
            if (focalNode) {
                sankeyHeaders.append("span")
                    .text(("GRANTEE"))
                    .style("position", "absolute")
                    .style("right", (chartWidths / 2 - 31) + 'px');
            }

            var svg = d3.select(targetEl).append("svg")
                .attr("width", chartWidths)
                .attr("height", height)
                .style("padding", padding.toString() + "px");

            var sankey = d3.sankey()
                .nodeWidth(12)
                .nodePadding(10)
                .size([chartWidths - padding * 2, height - padding * 2]);

            var path = sankey.link();

            sankey.nodes(sankeydata.nodes)
                .links(sankeydata.links)
                .layout(32);

            var link = svg.append("g").selectAll(".link")
                .data(sankeydata.links);

            var newlinks = link.enter().append("path")
                .classed("link", true)
                .attr("class", function (d) {
                    return d3.select(this).attr("class") + " sourcenode_" + d.source.node;
                })
                .attr("d", path)
                .style("stroke-width", function (d) {
                    return Math.max(1, d.dy);
                }).sort(function (a, b) { return b.dy - a.dy; });

            newlinks.filter(function (d) { return (d.source.id === focalNode || d.target.id === focalNode); })
                .classed("focal_stream", true);

            newlinks.append("title")
                .text(function (d) {
                    return d.source.name + " -> " + d.target.name + "\n" + format(d.value);
                });

            var node = svg.append("g").selectAll(".node").data(sankeydata.nodes);

            var newNodes = node.enter().append("g")
                .classed("node", true)
                .classed("node_highlight", function (d) {
                    return d.level === 0;
                })
                .classed("node_0", function (d) {
                    return d.level === 0;
                })
                .classed("node_click", function (d) {
                    return d.level === 1;
                })
                .classed("node_1", function (d) {
                    return d.level === 1;
                })
                .classed("node_2", function (d) {
                    return d.level === 2;
                })
                .attr("transform", function (d) {
                    return "translate(" + d.x + "," + d.y + ")";
                });

            if (focalNode) {
                newNodes.classed("node_highlight", function (d) {
                    return d.level < 2;
                });
            } else {
                newNodes.classed("node_highlight", function (d) {
                    return d.level === 0;
                }).classed("node_click", function (d) {
                    return d.level === 1;
                });
            }

            // invisible rectangle for increased selection sensitivity
            newNodes.append("rect")
                .attr("height", function (d) {
                    return Math.abs(d.dy);
                }).attr("width", sankey.nodeWidth())
                .style("fill", 'rgba(0,0,0,0)')
                .style("stroke", 'rgba(0,0,0,0)')
                .style("stroke-width", '5px');

            // standard colored rectangle
            newNodes.append("rect").attr("height", function (d) {
                return Math.abs(d.dy);
            }).attr("width", sankey.nodeWidth())
                .style("fill", function (d) { return d.color = scale(d.value); })
                .style("stroke", function (d) { return d3.rgb(d.color).darker(2); });

            newNodes.append("title").text(function (d) {
                return d.name + "\n" + format(d.value);
            });

            var nodeText = newNodes.append("text")
                .attr("x", -6)
                .attr("y", function (d) { return d.dy / 2; })
                .attr("dy", ".35em")
                .attr("text-anchor", "end")
                .attr("transform", null)
                .text(function (d) {
                    if (d.name == 'Grantee Not Reported' ) { return granteeNotReportedLabel; }
                    else if (d.name == 'Funder Not Reported' ) { return funderNotReportedLabel; }
                    else if (d.name == 'Partner Not Reported' ) { return partnerNotReportedLabel; }
                    else { return d.name; }
                });

            nodeText.filter(function (d) { return d.x < width / 2 - 50; })
                .attr("x", 6 + sankey.nodeWidth())
                .attr("text-anchor", "start");

            nodeText.filter(function (d) { return (d.x > width / 2 - 50 && d.x < width / 2 + 50); })
                .attr("x", function (d) { return d.dx / 2; })
                .attr("text-anchor", "middle");

            nodeText.filter(function (d) { return (d.x > width / 2 - 50 && d.x < width / 2 + 50) && d.dy < 10; })
                .attr("y", function (d) { return d.dy / 2 + 3; });

            if (focalNode) {
                svg.selectAll(".node").on("click", function (d) {
                    //if a node has already been selected dont do anything, otherwise get activities
                    if (!$scope.LoadingMiniCharts) {
                        var orgName = d.name;
                        var nodeLevel = d.level;
                        $scope.LoadingMiniCharts = true;
                        //disable additional clicks
                        $("#pl-sankey").children().bind('click', function () {
                            return false;
                        });
                        // get the activities for the partner clicked
                        partnerLinkService.getActivities(orgName, d.level).then(function (activityData) {

                            d3.selectAll('.popover').remove();

                            var puWidth = width / 2.5;
                            var puHeight = height * 0.8;
                            var xOffset = d.x + d.dx + padding + 2;
                            var yOffset = d.y + headerheight + padding;


                            $mdDialog.show({
                                locals: {data: activityData, orgName: orgName},
                                controller: SankeyModalController,
                                templateUrl: 'pl/sankey/sankey-modal.tpl.html',
                                parent: angular.element(document.body),
                                targetEvent: d,
                                clickOutsideToClose: true,
                                scope: $scope,
                                preserveScope: true,
                                onComplete: enableClick
                            });

                        });
                    }
                });
                $scope.LoadingMiniCharts = false;
            } else {
                d3.selectAll(".node_highlight")
                    .on("click", function (d) {
                        //on click remove all highlights
                        d3.selectAll('.link').classed('selected', false);

                        d3.selectAll(".sourcenode_" + d.node)
                            .classed("selected", function () {
                                return (this.className.baseVal.indexOf("selected") <= 0);
                            });
                    });
                $scope.LoadingCharts = false;
            }
        }

        // call the build function
        buildSankey(data, mainEl);

        // on any click of the grantee nodes
        d3.selectAll(".node_click").on("click", function (d) {
            var focal_node_id = d.id;
            $scope.LoadingMiniCharts = true;
            clearSankeyDetail();
            $scope.tabs.detailTabLabel = "Relationships for: " + d.name;
            $scope.tabs.selectedTab = 1;
            partnerLinkService.getRelatedData(apiData, d).then(function (response) {
                var newSankey = response;
                buildSankey(newSankey, '#pl-sankey-chart-detail', focal_node_id);
            });
        });
    }

    // pop-up model on node click
    function SankeyModalController($scope, data, orgName) {
        $scope.data = data;
        $scope.orgName = orgName;
        // on click function for close buttons
        $scope.closeDialog = function () {
            $mdDialog.cancel();
        };

        $scope.goToActivity = function(activity_id) {
            var params = {"activity_id" : activity_id};
            stateService.setState("activities", params, true);
        };

        $scope.clickedActivity = function (activity) {
            activity.active = (activity.active === true) ? false : true;
            if (activity.active && !_.has(activity, "data")) {
                activity.loading = true;
                // get activity details
                pmtMapService.getDetail(activity.activity_id).then(function (data) {
                    activity.data = data[0].response;
                    var investments = _.pluck(activity.data.financials, '_amount');
                    activity.investment = 0;
                    _.each(investments, function (i) { activity.investment = activity.investment + i;});
                    activity.investment = utilService.formatMoney(Math.round(activity.investment * 100) / 100);
                    _.each(activity.data.financials, function (f) {
                        _.each(f.taxonomy, function (t) {
                            if (t.taxonomy == 'Currency') {
                                activity.currency = t._code;
                                f.currency = t._code;
                            }
                        });
                    });
                    _.each(activity.data.organizations, function (o) {
                        switch (o.role) {
                            case 'Funding':
                                o.role = 'Funder';
                                break;
                            case 'Accountable':
                                o.role = 'Grantee';
                                break;
                            case 'Implementing':
                                o.role = 'Partner';
                                break;
                            default:
                                break;
                        }
                    });
                    activity.data.organizations = _.sortBy(activity.data.organizations, 'role');
                    activity.loading = false;
                });
            }
        };

        $scope.showFinancials = function (activity) {
            activity.showFinancials = (activity.showFinancials === true) ? false : true;
        };
    }

    function enableClick() {
        $("#pl-sankey").children().unbind('click');
        $scope.LoadingMiniCharts = false;
    }

    // connect to the window resize event
    $(window).resize(function () {
        $scope.resizeSankey();
    });

    // initialization
    $(document).ready(function () {
        $scope.resizeSankey();
    });

});