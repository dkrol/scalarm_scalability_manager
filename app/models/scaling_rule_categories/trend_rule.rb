class TrendRule

  def get_measurements(rule, db)
    collection_name = rule.get_metric.get_id

    time_window_length = rule.time_window.length
    if rule.time_window.length_unit == 'm'
      time_window_length *= 60
    elsif rule.time_window.length_unit == 'h'
      time_window_length *= 3600
    end

    time_window_start = Time.now - time_window_length.seconds

    db[collection_name].find({ date: { '$gt' => time_window_start } }).to_a
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