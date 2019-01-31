module.exports = angular.module('PMTViewer').controller('AgraIntegratorCtrl', function AgraIntegratorCtrl($scope, $rootScope, stateService, config, global, agraService) {

    var interval = null;
    $scope.status = null;
    $scope.progress = 0;
    $scope.finished = false;
    $scope.allDone = false;

    $scope.startIntegration = function () {
        agraService.startIntegration();
        checkStatus(); //calling first b/c executing to fast right now
        // every 5 seconds 
        interval = setInterval(checkStatus, 5000);
    };

    function checkStatus() {
        agraService.integrationStatus().then(function (status) {
            if(status.running && status.step !== 0){
                $scope.status = processMISStats(_.extend(status));
                try {
                    $scope.progress = Math.floor(status.step * 100 / status.steps);
                } catch (ex) {
                   // $scope.progress = 0;
                }
                if ($scope.allDone || $scope.status.api.location.fail > 1 ) {
                    $scope.progress = 0;
                    $scope.status.step = 10;
                    $scope.finished = true;
                    clearInterval(interval);
                }
            }          
        }, function (reason) {
            $scope.progress = 0;
            $scope.status.step = 10;
            $scope.status.running = false;
            $scope.finished = true;
            clearInterval(interval);
        });

    }

    function processMISStats(status) {
        var isFinished = false;
        var api = {
            activity: {
                label: "Grants",
                started: false,
                finished: false
            },
            organization: {
                label: "Organizations",
                started: false,
                finished: false
            },
            contact: {
                label: "Contacts",
                started: false,
                finished: false
            },
            location: {
                label: "Locations",
                started: false,
                finished: false
            }
        };
        _.each(status.pmt.api, function (table) {
            var element = api[table.table];
            if (table.calls !== 0) {
                table.started = true;
                if ((table.pass + table.fail) === table.calls) {
                    table.finished = true;
                }
            }
            if(element){
                element = _.extend(element, table);
            }
        });
        status = _.extend(status, {api: api});

        $scope.allDone = false;
        _.each(status.api, function (t) { 
            if((t.calls > 0 && t.finished) || (t.calls === 0 && status.api.location.calls > 0 && status.stats.matched > 0)){
                t.done = true;
            }
        });

        var allFinished = _.filter(status.api, function (t) { return t.finished; }).length;
        var allStarted = _.filter(status.api, function (t) { return t.started; }).length;
        var allDoneCt = _.filter(status.api, function (t) { return t.done; }).length;
        if(allDoneCt===4){
            $scope.allDone  = true;
        }
        if ($scope.allDone ) { status.running = false; }

        return status;
    }
});