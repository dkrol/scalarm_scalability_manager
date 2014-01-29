class SimpleRule

  def get_measurements(rule, db)
    db.get_measurements(rule.get_metric, nil, nil, true)
  end

  def fulfilled?(measurements, rule, db)
    measurement = measurements.first['value'].to_f
    condition = rule.condition

    measurement.send(condition, rule.threshold.to_f)
  end

end