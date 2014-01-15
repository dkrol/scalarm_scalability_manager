class MonitoringController < ApplicationController

  before_filter :load_monitoring_db

  def index
    @monitored_hosts = {}
    @monitoring_db.monitored_hosts.each do |metric_full_name|
      host, metric_name = metric_full_name.split('.')

      @monitored_hosts[host] = [] unless @monitored_hosts.include?(host)

      @monitored_hosts[host] << metric_name
    end
  end

  def show
    parse_monitoring_options

    date_constraints = {}
    date_constraints['monitoring_period_start'] = @monitoring_period_start unless @monitoring_period_start.nil?
    date_constraints['monitoring_period_end'] = @monitoring_period_end unless @monitoring_period_end.nil?

    Rails.logger.debug("Date find conditions: #{date_constraints}")

    @metrics.each do |metric_name, host_list|
      @metrics[metric_name] = host_list.map do |host|
        Rails.logger.debug("Getting measurements for: #{host}.#{metric_name}")
        measurements = @monitoring_db.measurements("#{host}.#{metric_name}", date_constraints)

        { name: host_label(host), data: change_time_resolution_of(measurements) }
      end
    end

    #Rails.logger.debug("Metrics and measurements: #{@metrics}")
  end


  private

  def load_monitoring_db
    @monitoring_db = MonitoringDatabase.new
  end
  
  def parse_monitoring_options
    @time_resolution = params[:time_resolution].to_i

    #monitoring period params
    @monitoring_period_start = params[:monitoring_period_start]
    @monitoring_period_start = nil if @monitoring_period_start.blank?
    @monitoring_period_start = "#{@monitoring_period_start} #{params[:monitoring_period_start_time]}"

    @monitoring_period_end = params[:monitoring_period_end]
    @monitoring_period_end = nil if @monitoring_period_end.blank?
    @monitoring_period_end = "#{@monitoring_period_end} #{params[:monitoring_period_end_time]}"

    Rails.logger.debug("Monitoring time period: #{@monitoring_period_start} - #{@monitoring_period_end}")

    @metrics = { }
    params.keys.each do |param_name|
      if param_name.start_with?('metric_')
        metric_full_name = param_name.split('metric_')[1]
        host, metric_name = metric_full_name.split('.')

        @metrics[metric_name] = [] unless @metrics.include?(metric_name)

        @metrics[metric_name] << host
      end
    end
    #Rails.logger.debug("Metrics: #{@metrics}")
  end

  def host_label(host)
    host.gsub('_', '.')
  end

  def change_time_resolution_of(measurements)
    grouped_values, measurements_from_time_period = [], []

    last_measurement_date = measurements[0][0]
    measurements[1..-1].each do |measurements|
      measurement_date = measurements[0]

      if measurement_date - last_measurement_date < @time_resolution
        measurements_from_time_period << measurements[1]
        next
      end

      measurements_from_time_period << measurements[1]
      grouped_values << calculate_avg_from(last_measurement_date, measurements_from_time_period)
      grouped_values << calculate_avg_from(measurements[0], measurements_from_time_period)
      last_measurement_date = measurements[0]
      measurements_from_time_period = []
    end

    if not measurements_from_time_period.empty?
      grouped_values << calculate_avg_from(measurements[-1][0], measurements_from_time_period)
    end

    grouped_values
  end

  def calculate_avg_from(timestamp, measurements_from_time_period)
    metric_value_sum = measurements_from_time_period.reduce(0, :+)
    metric_value_avg = metric_value_sum / measurements_from_time_period.size

    # logger.info("Sum = #{metric_value_sum} --- Size: #{measurements_from_time_period.size} --- Avg: #{metric_value_avg}")
    [ (timestamp - 3600)*1000 , metric_value_avg ]
  end

end
