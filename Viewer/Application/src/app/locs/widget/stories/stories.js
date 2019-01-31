/***************************************************************
 * Stories Widget Controller
 * Supports the stories widget.
 ***************************************************************/ 
angular.module('PMTViewer').controller('LocsWidgetStoriesCtrl', function ($scope, $sce, locsService, $stateParams, $mdDialog) {

 var country_name = locsService.getNationalFeatureName($stateParams.selection);
 var country_stories = $scope.widget.params.stories[country_name];

 processStories(country_stories);

 // when the selection is updated, do this
 $scope.$on('selection-update', function () {
  if ($scope.widget.area == $stateParams.area) {
   var country_name = locsService.getNationalFeatureName($stateParams.selection);
   var country_stories = $scope.widget.params.stories[country_name];

   processStories(country_stories);
  }
 });

 $scope.showSuccessStory = function(s) {
  $scope.story = s;
  //open modal
  $mdDialog.show({
   locals: {},
   controller: StoriesModalCtrl,
   templateUrl: 'locs/widget/stories/stories-modal.tpl.html',
   parent: angular.element(document.body),
   //targetEvent: d,
   clickOutsideToClose: true,
   scope: $scope,
   preserveScope: true
  // onComplete: enableClick
  });
 };


 //function to process story text for displaying
 function processStories(country_stories) {
  _.each(country_stories, function(story) {

   //add double quotes to title
   story.title = story.title.replace(/&&/g, '"' );

   //add double quotes to title
   story.subTitle = story.title.replace(/%%/g, "'" );

   //add double quotes to subtitle
   story.subTitle = story.subTitle.replace(/&&/g, '"' );

   //add double quotes to subtitle
   story.subTitle = story.subTitle.replace(/%%/g, "'" );

   //add italic in main body
   _.each(story.story.italic, function(i) {
    story.story.text = story.story.text.replace(i, ' <i>' + i + '</i> ' );
   });

   //add paragraph breaks
   story.story.text = story.story.text.replace(/@@/g, ' <br>' );

   //add double quotes
   story.story.text = story.story.text.replace(/&&/g, '"' );

   //add single quotes
   story.story.text = story.story.text.replace(/%%/g, "'" );

   story.story.updatedText = $sce.trustAsHtml(story.story.text);

   //if there are details
   if (story.details) {
    //each detail element in a story
    _.each(story.details.elements, function (e) {

     //add emphasis to key words
     _.each(e.emphasis, function (em) {
      e.text = e.text.replace(em, ' <span class="emphasis">' + em + '</span> ');
     });

     e.updatedText = $sce.trustAsHtml(e.text);

    });
   }
  });
  $scope.stories = country_stories;
 }

 // pop-up model on node click
 function StoriesModalCtrl($scope) {
  // on click function for close buttons
  $scope.closeDialog = function () {
   $mdDialog.cancel();
  };


 }

});
