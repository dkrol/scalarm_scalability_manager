module MonitoringHelper

  def hour_options
    hours = []

    0.upto(24) do |hour|
      hours << [ "#{hour}:00", "#{hour}:00:00"]
    end

    hours
  end

  def time_resolution_options
    [
        ["30 sec", "30"],
        ["1 min", "60"],
        ["30 min", "1800"],
        ["1 h", "3600"],
        ["5 min", "300"]
    ].reverse
  end

  def time_resolution_label(time_resolution)
    {
        '30' => '30 secs',
        '60' => '1 min',
        '1800' => '30 min',
        '3600' => '1 h',
        '300' => '5 min',
    }[time_resolution.to_s]
  end

  #def metric_label(metric_name)
  #  metric_fragments = metric_name.split('___')
  #
  #  if metric_fragments[0] == 'System' and metric_fragments[1] == 'NULL'
  #    metric_fragments[2]
  #  else
  #    metric_name
  #  end
  #
  #end

end
