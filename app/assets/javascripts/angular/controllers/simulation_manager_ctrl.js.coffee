@SimulationManagerCtrl = ($scope, $http, $timeout) ->
  $scope.managers = []
  $scope.worker_nodes = []
  $scope.loading_simulation_manger = false
  # messages
  $scope.has_message = false
  $scope.message = ''
  $scope.has_error_message = false
  $scope.error_message = ''

  $http.get('/scalarm_managers/worker_nodes').
    success((data, status, headers, config) -> $scope.worker_nodes = data).
    error((data, status, headers, config) ->
      $scope.flash_message("error", "Status: #{status}, Message: #{data}")
    )

  $http.get('/scalarm_managers/simulation_managers').
    success((data, status, headers, config) -> $scope.managers = data).
    error((data, status, headers, config) ->
      $scope.flash_message("error", "Status: #{status}, Message: #{data}")
    )

  $scope.deploy = () =>
    console.log "Node to deploy Simulation Manager:"
    console.log $scope.destination_node
#
    if $scope.destination_node == undefined
      $scope.flash_message('error', "You have to select node in order to deploy")
      return

    $scope.loading_simulation_manger = true
    parameters = {
      worker_node_id: $scope.destination_node.id,
      experiment_id: $scope.experiment_id,
      login: $scope.login,
      password: $scope.password
    }

    $http({
      url: '/platform/deploy_simulation_manager',
      method: "POST",
      data: parameters
    }).success((data, status, headers, config) =>
      $scope.flash_message("message", "New Simulation Manager added")

      $scope.managers.push(data)
      $scope.loading_simulation_manger = false
    ).error((data, status, headers, config) =>
      $scope.flash_message("error", "Status: #{status}, Message: #{data}")
      $scope.loading_simulation_manger = false
    )

  $scope.destroy = (manager) =>
    console.log "Destroying manager:"
    console.log manager

    $scope.loading_simulation_manger = true

    $http({
      url: "/scalarm_managers/#{manager.id}",
      method: "DELETE"
    }).success((data, status, headers, config) =>
      $scope.loading_simulation_manger = false
      $scope.flash_message("message", "Simulation Manager deleted")

      for i in [0..$scope.managers.length] by 1
        if($scope.managers[i].id == manager.id)
          $scope.managers.splice(i, 1)
          break
    ).error((data, status, headers, config) =>
      $scope.loading_simulation_manger = false
      $scope.flash_message("error", "Status: #{status}, Message: #{data}")
    )

  $scope.flash_message = (type, message) =>
    if type == "message"
      $scope.message = message
      $scope.has_message = true

    else if type == "error"
      $scope.error_message = message
      $scope.has_error_message = true

    $timeout =>
      $scope.has_message = false
      $scope.has_error_message = false
    , 10000