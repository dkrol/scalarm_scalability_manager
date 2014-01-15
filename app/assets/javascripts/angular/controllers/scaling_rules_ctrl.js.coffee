@ScalingRulesCtrl = ($scope) ->
  $scope.show_time_window_specs = false

  $scope.measurement_type_listener = () =>
    console.log "Measurement type: #{$scope.measurement_type}"
    $scope.show_time_window_specs = ($scope.measurement_type == 'time_window')
