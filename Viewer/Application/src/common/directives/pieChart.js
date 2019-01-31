/***************************************************************
 * Pie Chart Directive
 * Manages creation of a d3 pie chart.
* *************************************************************/   
angular.module('PMTViewer').directive('pieChart', function ($parse, $window, $mdDialog, stateService, analysisService) {
    
    var pieChart = {
        restrict: 'E',
        replace: false,
        scope: { data: '=chartData',
            colorRange: '=colorRange',
            hasOther: '=other',
            showpopup : '=showpopup',
            popupurl : '=popupurl',
            terminology: '=terminology',
        },
        link: function (scope, element, attrs) {
            // get the parent element of the chart
            var parent = $(element[0]).parent();
            // function to create the chart
            scope.renderChart = function () {
                // get the width of parent div to size chart by
                var width = parent.width();
                var height = parent.height();
                // size default
                var size = 200;
                // if heigth is greater than zero, calculate chart size
                if (height > 0) {
                    size = Math.round(height * .60);
                    // ensure the width will accomidate the chart as well
                    if (size > width) {
                        size = Math.round(width * .70);
                    }
                }
                // empty the chart div
                $(element[0]).empty();
                // flag for tracking active tooltip
                var tooltipOn = false;
                // set radius based on height and width
                var radius = Math.min(size, size) / 2;
                // assign the color range
                var color = d3.scale.ordinal().range(scope.colorRange);
                // create arc
                var arc = d3.svg.arc().outerRadius(radius - 10).innerRadius(0);
                // create arc on hover
                var hoverArc = d3.svg.arc().outerRadius(radius + 2);
                // create arc label
                var labelArc = d3.svg.arc().outerRadius(radius - 20).innerRadius(radius - 150);
                // generate pie           
                var pie = d3.layout.pie().sort(null).value(function (d) { return d.value; });
                // create svg element for chart
                var svg = d3.select(element[0]).append("svg")
                .attr("width", size)
                .attr("height", size)
                .append("g")
                .attr("transform", "translate(" + size / 2 + "," + size / 2 + ")");
                // create the tooltip div
                var tooltip = d3.select(element[0]).append("div")
                .attr("class", "pie-chart-tooltip")
                .style("opacity", 0);
                // generate pie pieces
                var g = svg.selectAll(".arc")
                .data(pie(scope.data))
                .enter().append("g")
                .attr("class", "arc")
                .on("mouseover", function (d) {
                    // tooltip is active
                    tooltipOn = true;
                    var coordinates = [0, 0];
                    coordinates = d3.mouse(this);
                    var x = coordinates[0];
                    var y = coordinates[1];
                    // show tooltip
                    tooltip.html(d.data.tooltip)
                    .style("left", x + 100 + "px")
                    .style("top", y + "px")
                    .style("opacity", 1)
                    .transition().duration(200);
                    // highlight pie piece
                    d3.select(this).select("path")
                    .attr("stroke", "white")
                    .transition().duration(500)
                    .attr("d", hoverArc)
                    .attr("stroke-width", 2);
                })
                .on("mouseout", function (d) {
                    // tooltip is not active
                    tooltipOn = false;
                    // hide tooltip
                    tooltip.transition().duration(500)
                    .style("opacity", 0)
                    .style("left", 0)
                    .style("top", 0);
                    // remove highlight from pie piece
                    d3.select(this).select("path")
                    .transition().duration(200)
                    .attr("d", arc)
                    .attr("stroke-width", 1);
                })
                .on("click", function(d) {
                    // show popup on click if showpop if true
                    if (scope.showpopup) {
                        //save modal data
                        scope.modaldata = d;
                        //show dialog box
                        showAllProjects();
                    }
                });
                // color pie pieces
                g.append("path")
                .attr("d", arc)
                .style("fill", function (d) {
                        // if has "Other" is true and at the last element, color grey                        
                        if (scope.hasOther && d.data.classification_id===null) { 
                            return '#727273';
                        }
                        else {
                            return color(d.data.label);
                        }
                    });
                // add labels
                //g.append("text")
                //    .attr("transform", function (d) { return "translate(" + labelArc.centroid(d) + ")"; })
                //    .attr("dy", ".35em")
                //    .text(function (d) { return d.data.label; });
            };
            // create the chart
            scope.renderChart();
            // get the parent container dimensions
            scope.getParentDimensions = function () {
                return { 'h': parent.height(), 'w': parent.width() };
            };
            // watch the get parent dimensions function when executed
            scope.$watch(scope.getParentDimensions, function (newValue, oldValue) {
                if (newValue !== oldValue) {
                    // if the parent containers dimensions have changed recreate the chart
                    scope.renderChart();
                }
            }, true);
            // call directive if parent is resized
            parent.bind('resize', function () {
                scope.$apply();
            });
            // watch for chartData updates
            scope.$watch('data', function (newValue, oldValue) {
                if (newValue !== oldValue)
                    // if the data has changed redraw the chart
                    scope.renderChart();
            }, true);

            // popup dialog with list of all partners within a table cell
            var showAllProjects = function (ev) {
                // open dialog
                $mdDialog.show({
                    locals: { modalData: scope.modaldata, popupURL : scope.popupurl, stateService : stateService, analysisService : analysisService, terminology:scope.terminology},
                    controller: PieModalController,
                    templateUrl: scope.popupurl,
                    targetEvent: ev,
                    clickOutsideToClose: true,
                    //scope: $scope,
                    preserveScope: true
                });
            }
        }
    };

    // modal controller for showing all organizations
    function PieModalController($scope, modalData, stateService, analysisService, terminology) {

        $scope.modalData = modalData;
        $scope.loading = true;
        $scope.activities = [];
        $scope.terminology = terminology;


        //get activity titles from list of activity ids from an org in horizontal chart
        analysisService.getActivityTitles(modalData.data.a_ids)
            .then(function (data) {
                $scope.activities = data;
                $scope.loading = false;
            });

        //when click on activity from bar chart popup modal, go to activity page
        $scope.goToActivity = function (activity_id) {
            var params = { "activity_id": activity_id };
            stateService.setState("activities", params, true);
            $scope.closeDialog();
        };

        // on click function for close buttons
        $scope.closeDialog = function () {
            $mdDialog.cancel();
        };
    }


    return pieChart;
});