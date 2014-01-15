module ApplicationHelper

  def metric_name_label(metric_name)
    metric_fragments = metric_name.split('___')

    if metric_fragments[0] == 'System' and metric_fragments[1] == 'NULL'
      metric_fragments[2]
    else
      metric_name
    end

  end

  def host_label(host)
    host.gsub('_', '.')
  end

  def metric_label(metric)
    "Parameter '#{metric_name_label(metric.attribute)}' for '#{host_label(metric.host)}'"
  end

end
