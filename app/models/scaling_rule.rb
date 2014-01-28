require 'scaling_rule_categories/simple_rule'
require 'scaling_rule_categories/window_rule'
require 'scaling_rule_categories/trend_rule'

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
    %w(> < == <= >=)
  end

  def condition_label
    case condition
      when '>'
        'greater than'
      when '<'
        'less then'
      when '=='
        'equal to'
      when '<='
        'less then or equal to'
      when '>='
        'greater then or equal to'
    end
  end

  def get_measurements
    get_rule_specifics.get_measurements(self, MonitoringDatabase.new().db)
  end

  def fulfilled?(measurements)
    get_rule_specifics.fulfilled?(measurements, self, MonitoringDatabase.new().db)
  end

  def get_rule_specifics
    if rule_category == 'simple'
      SimpleRule.new
    elsif rule_category == 'time_window'
      WindowRule.new
    elsif rule_category == 'trend'
      TrendRule.new
    else
      nil
    end
  end

  def monitor
    while true
      puts "[#{Time.now}][#{get_id}] scaling rule monitoring"
      #TODO do not monitor if this is a cool down period

      measurements = get_measurements
      is_fulfilled = fulfilled?(measurements)

      puts "[#{Time.now}][#{get_id}] is fulfilled - #{is_fulfilled}"

      if is_fulfilled
        puts "[#{Time.now}][#{get_id}] executing scaling action - #{action}"
        # TODO perform the scaling action
        # TODO create a cool down period
      end

      sleep(30)
    end
  end

  def get_id
    "#{metric}-#{measurement_type}-#{condition}-#{threshold}-#{action}".gsub('|', '-')
  end

end
