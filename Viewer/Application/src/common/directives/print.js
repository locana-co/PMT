/***************************************************************
 * Pie Chart Directive
 * Manages creation of a d3 pie chart.
* *************************************************************/
angular.module('PMTViewer').directive('print', function ($timeout, analysisService, locsService, partnerLinkService) {

    var print = {
        restrict: 'A',
        replace: false,
        link: function (scope, element, attrs) {
            var targetElement = null;
            attrs.$observe('print', function () {
                // console.log(' print:', attrs.print);
                targetElement = attrs.print;
            });
            element.bind('click', onClick);
            function onClick() {
                if (targetElement && targetElement === "funding") {
                    //special case

                    var featureId = parseInt(locsService.selectedNationalFeature.id, 10);
                    var boundaryId = locsService.nationalLayer.boundary_id;

                    analysisService.getStatsInvestmentsByFunder(
                        locsService.getDataGroupFilters().join(','),
                        locsService.getClassificationFilters().join(','),
                        locsService.getStartDateFilter(),
                        locsService.getEndDateFilter(),
                        boundaryId,
                        featureId,
                        0 // all records
                    ).then(function (data) {
                        // process returned data (remove extra fields we don't want to show)
                        var allOrgs = _.map(data, function (item, idx) {
                            var org = {
                                Organization: item.label,
                                Amount: item.sum
                            };
                            return org;
                        });

                        partnerLinkService.JSONToCSVConvertor(allOrgs, "All Funding Organization List", true, null);
                    });

                } else {
                    //use a canvas print
                    var targete = $(targetElement);
                    html2canvas($('#' + targetElement), {
                        onrendered: function (canvas) {
                            var c = canvas;
                            Canvas2Image.saveAsPNG(canvas);
                            $("#print-download").empty();
                            $("#print-download").append(canvas);
                        }
                    });
                }

            }
        }
    };

    return print;
});