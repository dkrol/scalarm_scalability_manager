class SimpleRule

  def get_measurements(rule, db)
    collection_name = rule.get_metric.get_id

    db[collection_name].find({}, { sort: ['_id', :desc], limit: 1 }).to_a
  end

  def fulfilled?(measurements, rule, db)
    measurement = measurements.first['value'].to_f
    condition = rule.condition

    measurement.send(condition, rule.threshold.to_f)
  end

end