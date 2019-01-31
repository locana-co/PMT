module.exports = angular.module('PMTViewer').controller('VideoCtrl', function VideoCtrl($scope, $rootScope, config, global, $mdDialog, $sce) {

    // get the video page object
    $scope.page = _.find(config.states, function (state) { return state.navLabel == "Video"; });

    // show video tutorial
    $scope.showVideo = function (d) {

        // open dialog
        $mdDialog.show({
            locals: { videoURL : $scope.page.videoURL },
            controller: PivotModalController,
            templateUrl: 'video/video-modal.tpl.html',
            targetEvent: d,
            clickOutsideToClose: true,
            scope: $scope,
            preserveScope: true
        });
    };


    // modal controller for showing tutorial video
    function PivotModalController($scope, videoURL) {
        $scope.videoURL = $sce.trustAsResourceUrl(videoURL);

        // on click function for close buttons
        $scope.closeDialog = function () {
            $mdDialog.cancel();
        };
    }
});