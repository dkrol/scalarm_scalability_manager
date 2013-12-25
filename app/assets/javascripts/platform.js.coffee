# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

@PlatformCtrl = ($scope, $http) ->
  $scope.worker_nodes = []
  $scope.managers = {}
  $scope.manager_labels = {}
  $scope.count = 0
  $scope.errorMap = new Array()

  $http.get('/scalarm_managers/worker_nodes').
    success((data, status, headers, config) -> $scope.worker_nodes = data).
    error((data, status, headers, config) ->
#     TODO show error in communication message
    )

  $http.get('/scalarm_managers/managers').
    success((data, status, headers, config) -> $scope.managers = data).
    error((data, status, headers, config) ->
#     TODO show error in communication message
    )

  $http.get('/scalarm_managers/manager_labels').
    success((data, status, headers, config) -> $scope.manager_labels = data).
    error((data, status, headers, config) ->
#     TODO show error in communication message
    )

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
    console.log "Manager type: #{managerType} --- Node to deploy at:"
    console.log nodeToDeployAt

    if nodeToDeployAt == undefined
      $scope.showError("deploy_#{managerType}", "You have to select node in order to deploy")
      return

    $scope['loading_' + managerType] = true

    $http({
      url: '/platform/deployManager',
      method: "POST",
      data: { 'worker_node_id': nodeToDeployAt.id, 'manager_type': managerType}
    }).success((data, status, headers, config) =>
      $scope.managers[managerType].push(data)

      $scope['loading_' + managerType] = false

    ).error((data, status, headers, config) =>
      $scope.showError("deploy_#{managerType}", "Status: #{status}, Reason: #{data}")
      $scope['loading_' + managerType] = false
    )

  $scope.destroyManager = (manager) =>
    console.log "Destroying manager:"
    console.log manager

    $scope['loading_' + manager.service_type] = true

    $http({
      url: "/scalarm_managers/#{manager.id}",
      method: "DELETE"
    }).success((data, status, headers, config) =>
      $scope['loading_' + manager.service_type] = false
#      $scope.worker_nodes = data.worker_nodes
      for i in [0..$scope.managers[manager.service_type].length] by 1
        if($scope.managers[manager.service_type][i].id == manager.id)
          $scope.managers[manager.service_type].splice(i, 1)
          break
    ).error((data, status, headers, config) =>
      $scope['loading_' + manager.service_type] = false
      console.log "Error"
      console.log status
      console.log data
    )

  $scope.showError = (key, message) =>
    $scope.errorMap[key] = message
    setTimeout (=> console.log "Deleting element from array";  $scope.errorMap[key] = ""; console.log $scope.errorMap[key]), 10000

  $scope.hasError = (key) =>
    $scope.errorMap[key]