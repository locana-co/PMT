/***************************************************************
 * Horizontal Bar Chart Directive
 * Manages creation of a d3 horizontal bar chart.
* *************************************************************/
angular.module('PMTViewer').directive('horizontalBarChart', function ($parse, $mdDialog, stateService, analysisService) {

    var horizontalBarChart = {
        restrict: 'E',
        replace: false,
        scope: {
            data: '=chartData',
            showpopup : '=showpopup',
            popupurl : '=popupurl',
            terminology : '=terminology'
        },
        link: function (scope, element, attrs) {
            // get the parent element of the chart
            var parent = $(element[0]).parent();
            // function to create chart
            scope.renderChart = function () {
                // empty the chart div
                $(element[0]).empty();
                // get the chart directive element
                var chart = d3.select(element[0]);
                // get an array of the values
                var values = _.pluck(scope.data, "value");
                // sum all the values
                var maxValues = _.max(values);
                // create a chart-bar container for each data element
                var bars = chart.append("table").attr("class", "chart")
                    .selectAll('table').data(scope.data).enter()
                    .append("tr").attr("class", "chart-bar");
                // loop through the chart-bar containers and fill them with content
                bars.each(function (d, i) {
                    if (i === 0) {
                        // create left label
                        d3.select(this).append("td").attr("class", "chart-bar-lt-label")
                            .text(function (d) { return d.label_left; })
                            .append("div").html("<div class='tooltip-title'>" + d.full_label + "</div>")
                            .attr("class", "horizontal-chart-tooltip")
                            .style("display", "block")
                            .style("visibility", "hidden")
                            .style("position","absolute");
                    }
                    else {
                        // create left label
                        d3.select(this).append("td").attr("class", "chart-bar-lt-label")
                            .text(function (d) { return d.label_left; })
                            .append("div").html("<div class='tooltip-title'>" + d.full_label + "</div>")
                            .attr("class", "horizontal-chart-tooltip")
                            .style("display", "block")
                            .style("visibility", "hidden")
                            .style("position","relative");
                    }

                    // show tooltip on hover
                    d3.selectAll("td.chart-bar-lt-label")
                        .on("mouseover", function (d) {
                            d3.select(this.children[0]).style("visibility", 'visible');
                        })
                        .on("mouseout", function (d) {
                            d3.select(this.children[0]).style("visibility", 'hidden');
                        });


                    // create data bar
                    d3.select(this).append("td").attr("class", "chart-bar")
                        .append("div").attr("class", "bar-background")
                        .style("width", "100%")
                        .style("float", "left")
                        .append("div").attr("class", "bar")
                        .style("float", "left")
                        .transition().ease("elastic")
                        .style("width", function (d) { return Math.round((d.value / maxValues) * 100) + "%"; });


                    // show popup on click if showpop if true
                    if (scope.showpopup) {
                        d3.selectAll("td.chart-bar")
                            .on("click", function (d) {
                                //save modal data
                                scope.modaldata = d;
                                //show dialog box
                                showAllProjects();
                            });
                    }
                    // create right label
                    d3.select(this).append("td").attr("class", "chart-bar-rt-label")
                        .text(function (d) { return d.label_right; });
                });
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
                    controller: HorizontalModalController,
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
    function HorizontalModalController($scope, modalData, stateService, analysisService, terminology) {

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

    return horizontalBarChart;
});


