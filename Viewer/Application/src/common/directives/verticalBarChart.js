/***************************************************************
 * Vertical Bar Chart Directive
 * Manages creation of a d3 vertical bar chart.
 * *************************************************************/
angular.module('PMTViewer').directive('verticalBarChart', function ($parse, $mdDialog, stateService, analysisService) {

    var verticalBarChart = {
        restrict: 'E',
        replace: false,
        scope: {
            data: '=chartData',
            terminology: '=terminology',
            barColors: '=colors',
            hasOther: '=other',
            showpopup: '=showpopup',
            popupurl: '=popupurl'
        },
        link: function (scope, element, attrs) {
            // get the parent element of the chart
            var parent = $(element[0]).parent();

            // get the parent container dimensions
            scope.getParentDimensions = function () {
                return { 'h': parent.height(), 'w': parent.width() };
            };

            // function to create chart
            scope.renderChart = function () {
                // empty the chart div
                $(element[0]).empty();

                var margin = { top: 30, right: 10, bottom: 30, left: 40 },
                    width = scope.getParentDimensions().w - margin.left - margin.right,
                    height = 200 - margin.top - margin.bottom;

                var barWidth = width / scope.data.length;

                var x = d3.scale.ordinal()
                    .rangeRoundBands([0, width], .1);

                var y = d3.scale.linear()
                    .range([height, 0]);


                var xAxis = d3.svg.axis()
                    .scale(x)
                    .ticks(0)
                    .orient("bottom");

                var yAxis = d3.svg.axis()
                    .scale(y)
                    .orient("left")
                    .ticks(5);

                var tooltip = d3.select(element[0]).append("div")
                    .attr("class", "vertical-chart-tooltip")
                    .style("display", 'none');

                var svg = d3.select(element[0]).append("svg")
                    .attr("class", "chart")
                    .attr("width", width + margin.left + margin.right)
                    .attr("height", height + margin.top + margin.bottom)
                    .append("g")
                    .attr("transform", "translate(" + margin.left + "," + margin.top + ")");

                y.domain([0, d3.max(scope.data, function (d) { return d.count; })]);

                svg.append("g")
                    .attr("class", "x axis")
                    .attr("transform", "translate(0," + height + ")")
                    .call(xAxis);

                var axis_text = scope.terminology.activity_terminology.singular + " count";

                svg.append("g")
                    .attr("class", "y axis")
                    .call(yAxis)
                    .append("text")
                    .attr("transform", "rotate(-90)")
                    .attr("text-transform", "capitalize")
                    .attr("y", 6)
                    .attr("dy", ".71em")
                    .style("text-anchor", "end")
                    .text(axis_text);

                svg.selectAll(".bar")
                    .data(scope.data)
                    .enter().append("rect")
                    .attr("class", "bar")
                    .style("fill", function (d) {
                        // if has "Other" is true and at the last element, color grey                        
                        if (scope.hasOther && scope.data.classification_id===null) { 
                            return '#727273';
                        }
                        else {
                            return scope.barColors[scope.data.indexOf(d)];
                        }
                    })
                    .attr("width", barWidth / 2)
                    .attr("y", function (d) { return y(d.count); })
                    .attr("height", function (d) { return height - y(d.count); })
                    .attr("transform", function (d, i) { return "translate(" + (i * barWidth + barWidth / 4) + ",0)"; })
                    .on("mouseover", function (d) {
                        //max count value
                        var maxValue = _.max(scope.data, function (d) { return d.count }).count;
                        //location top and left
                        //calculate top of bar
                        var top = height - (d.count / maxValue * height);
                        var left = d3.event.layerX - 62;
                        d.classification= d.classification.toLowerCase();
                        d.classification = d.classification.capitalizeFirstLetter();
                        // show tooltip
                        tooltip.html("<div class='tooltip-title'>" + d.classification + "</div><br><div class='tooltip-data'><span class='sub-title'>" + scope.terminology.activity_terminology.singular + " Count : </span>" + d.count + "<div>")
                            .style("left", left + "px")
                            .style("top", top + "px")
                            .style("display", 'block');
                    })
                    .on("mouseout", function (d) {
                        // hide tooltip
                        tooltip
                            //  .transition().duration(500)
                            .style("display", 'none');
                    })
                    .on("click", function (d) {
                        // show popup on click if showpop if true
                        if (scope.showpopup) {
                            //save modal data
                            scope.modaldata = d;
                            //show dialog box
                            showAllProjects();
                        }
                    });

            };

            // create the chart
            scope.renderChart();

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
                    locals: { modalData: scope.modaldata, popupURL: scope.popupurl, stateService: stateService, analysisService: analysisService, terminology: scope.terminology },
                    controller: VerticalModalController,
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
    function VerticalModalController($scope, modalData, stateService, analysisService, terminology) {

        $scope.modalData = modalData;
        $scope.loading = true;
        $scope.activities = [];
        $scope.terminology = terminology;


        //get activity titles from list of activity ids from an org in horizontal chart
        analysisService.getActivityTitles(modalData.a_ids)
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

    return verticalBarChart;
});
