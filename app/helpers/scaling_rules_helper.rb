module ScalingRulesHelper
  def measurement_type_options
    [["Simple", "simple"], ["Time window", "time_window"]]
  end

  def action_options
    ScalingAction.get_actions.reduce([]) do |options, action|
      options << [ action.to_s, action.get_id ]
    end
  end

  def metric_options
    @metrics.reduce([]) do |options, metric|
      options << [ metric_label(metric), metric.get_id ]
    end
  end

  def time_window_length_units_options
    [["Seconds", "s"], ["Minutes", "m"], ["Hours", "h"]]
  end
end
