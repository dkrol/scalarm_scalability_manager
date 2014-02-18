require 'scaling_rule_categories/simple_rule'
require 'scaling_rule_categories/window_rule'
require 'scaling_rule_categories/trend_rule'

class ScalingRule < ActiveRecord::Base
  has_one :time_window, dependent: :destroy
  attr_accessor :db

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
    get_rule_specifics.get_measurements(self, @db || MonitoringDatabase.new)
  end

  def fulfilled?(measurements)
    get_rule_specifics.fulfilled?(measurements, self, @db ||  MonitoringDatabase.new)
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
    cooldown_period_length = YAML::load_file(File.join(Rails.root, 'config', 'scalarm.yml'))['cooldown_period_length'].to_i

    while true
      Rails.logger.debug("[#{Time.now}][#{get_id}] scaling rule monitoring")

      if CooldownPeriod.in_cooldown_period(Time.now)
        Rails.logger.debug("[#{Time.now}][#{get_id}] There is an ongoing cooldown period")
      else
        measurements = get_measurements
        is_fulfilled = fulfilled?(measurements)

        Rails.logger.debug("[#{Time.now}][#{get_id}] is fulfilled - #{is_fulfilled}")

        if is_fulfilled
          Rails.logger.debug("[#{Time.now}][#{get_id}] executing scaling action - #{action}")

          manager = ScalingAction.create_from_id(action).execute(get_metric)

          if manager.nil?
            Rails.logger.error("Failed to scale")
          else
            cooldown_period = CooldownPeriod.new(start_at: Time.now, end_at: Time.now + cooldown_period_length.minutes)
            cooldown_period.save

            Rails.logger.debug("Deployed manager: #{manager}")
          end
        end
      end

      sleep(30)
    end
  end

  def get_id
    "#{metric}-#{rule_category}-#{condition}-#{threshold}-#{action}".gsub('|', '-')
  end

  def start_monitoring_process
    pid_file_path = File.join(Rails.root, 'tmp', "#{get_id}.pid")

    if File.exist?(pid_file_path)
      Rails.logger.debug("[#{Time.now}][#{get_id}] a pid file already exists - hence we will not monitor this rule")
    else
      reader, writer = IO.pipe()

      pid = fork do
        writer.close

        scaling_rule_id = reader.gets.to_i
        rule = ScalingRule.find(scaling_rule_id)

        rule.monitor
      end

      reader.close
      writer.puts self.id

      IO.write(pid_file_path, pid)

      Process.detach(pid)

      Rails.logger.debug("[#{Time.now}][#{get_id}] scaling rule monitoring process started")
    end

  end

  def stop_monitoring_process
    pid_file_path = File.join(Rails.root, 'tmp', "#{get_id}.pid")

    if File.exist?(pid_file_path)
      pid = IO.read(pid_file_path).to_i
      begin
        Process.kill('TERM', pid)
      rescue Exception => e
        Rails.logger.warn("Could not kill the process with pid #{pid} -> #{e}")
      end

      File.delete(pid_file_path)
      Rails.logger.debug("[#{Time.now}][#{get_id}] scaling rule monitoring process stopped")
    else
      Rails.logger.debug("[#{Time.now}][#{get_id}] there is no file with the monitoring pid process")
    end

  end

  def self.global_monitoring_start
    ScalingRule.all.each do |rule|
      rule.start_monitoring_process
    end
  end

  def self.global_monitoring_stop
    ScalingRule.all.each do |rule|
      rule.stop_monitoring_process
    end
  end

end
