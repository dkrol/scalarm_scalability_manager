# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

@PlatformCtrl = ($scope) ->
  $scope.worker_nodes = JSON.parse($('#worker-nodes').html())
  $scope.managers = JSON.parse($('#managers').html())

  console.log $scope.worker_nodes
  console.log $scope.managers
