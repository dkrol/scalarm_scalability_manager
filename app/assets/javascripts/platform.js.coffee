# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

@PlatformCtrl = ($scope, $http) ->
  $scope.worker_nodes = JSON.parse($('#worker-nodes').html())
  $scope.managers = JSON.parse($('#managers').html())
  $scope.count = 0

  $scope.addWorkerNode = () =>
    $http({
      url: '/platform/addWorkerNode',
      method: "POST",
      data: {
        'url': $scope.newNodeUrl,
        'user': $scope.newNodeUser,
        'password': $scope.newNodePassword
      }
    }).success((data, status, headers, config) =>
      $scope.worker_nodes.push(data)

    ).error((data, status, headers, config) =>
      console.log "Error"
      console.log status
      console.log data
    )

  $scope.removeWorkerNode = (worker_node_id) ->
    @element_index = -1

    for i in [0..$scope.worker_nodes.length] by 1
      if($scope.worker_nodes[i].id == worker_node_id)
        @element_index = i
        break

    $http({
      url: '/platform/removeWorkerNode',
      method: "POST",
      data: {
        'worker_node_id': worker_node_id
      }
    }).success((data, status, headers, config) =>
      $scope.worker_nodes.splice(@element_index, 1)

    ).error((data, status, headers, config) =>
      console.log "Error"
      console.log status
      console.log data
    )

  $scope.synchronize = () =>
    $http({
      url: '/platform/synchronize',
      method: "POST",
    }).success((data, status, headers, config) =>
      $scope.worker_nodes = data.worker_nodes
      $scope.managers = data.managers
    ).error((data, status, headers, config) =>
      console.log "Error"
      console.log status
      console.log data
    )

  $scope.deployManager = (managerType, nodeToDeployAt) =>
    console.log "Manager type: #{managerType} --- Node to deploy at: #{nodeToDeployAt}"

    $http({
      url: '/platform/deployManager',
      method: "POST",
      data: { 'worker_node_id': nodeToDeployAt.id, 'managerType': managerType}
    }).success((data, status, headers, config) =>
      $scope.worker_nodes = data.worker_nodes
      $scope.managers = data.managers
    ).error((data, status, headers, config) =>
      console.log "Error"
      console.log status
      console.log data
    )