class ScalingRule < ActiveRecord::Base
  has_one :time_window, dependent: :destroy

  #def as_string
  #  string_form = "if #{self.metric_name.split(".").last} on #{self.metric_name.split(".").first}" +
  #  " is #{self.condition} #{self.threshold}"
  #
  #  if self.measurement_type == "time_window"
  #    string_form += " in last #{self.time_window_length} #{time_window_length_unit}"
  #  end
  #
  #  string_form += " than '#{self.action}'"
  #
  #  string_form
  #end
  #
  #def time_window_length_in_secs
  #  if time_window_length_unit == "s"
  #    time_window_length
  #  elsif time_window_length_unit == "m"
  #    time_window_length*60
  #  elsif time_window_length_unit == "h"
  #    time_window_length*3600
  #  end
  #end

  def get_metric
    Metric.create_from_full_name(metric)
  end

  def self.conditions
    %w(> < = <= >=)
  end

  def condition_label
    case condition
      when '>'
        'greater than'
      when '<'
        'less then'
      when '='
        'equal to'
      when '<='
        'less then or equal to'
      when '>='
        'greater then or equal to'
    end
  end


end
