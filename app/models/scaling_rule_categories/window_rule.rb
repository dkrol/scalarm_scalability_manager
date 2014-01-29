class WindowRule

  def get_measurements(rule, db)
    time_window_start = Time.now - rule.time_window.get_length.seconds

    db.get_measurements(rule.get_metric, time_window_start)
  end

  def fulfilled?(measurements, rule, db)
    return false if measurements.blank?

    avg_metric_value = measurements.reduce(0.0) do |acc, measurement|
      acc + measurement['value'].to_f
    end

    avg_metric_value /= measurements.size

    condition = rule.condition

    avg_metric_value.send(condition, rule.threshold.to_f)
  end

end