@ScalingRulesCtrl = ($scope) ->
  $scope.show_simple_rule_form = false
  $scope.show_time_window_rule_form = false
  $scope.show_trend_rule_form = false

  $scope.rule_category_listener = () =>
    console.log "Rule category: #{$scope.rule_category}"
    if $scope.rule_category == 'simple'
      $scope.show_time_window_rule_form = $scope.show_trend_rule_form = false
      $scope.show_simple_rule_form = true
    else if $scope.rule_category == 'trend'
      $scope.show_time_window_rule_form = $scope.show_simple_rule_form = false
      $scope.show_trend_rule_form = true
    else if $scope.rule_category == 'time_window'
      $scope.show_trend_rule_form = $scope.show_simple_rule_form = false
      $scope.show_time_window_rule_form = true
    else
      $scope.show_time_window_rule_form = $scope.show_simple_rule_form = $scope.show_trend_rule_form = false
