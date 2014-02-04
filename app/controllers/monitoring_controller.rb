require 'json'

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

    @monitoring_period_start = Date.parse(@monitoring_period_start).to_time unless @monitoring_period_start.nil?
    @monitoring_period_end   = Date.parse(@monitoring_period_end).to_time unless @monitoring_period_end.nil?

    @metrics.each do |metric_name, host_list|
      @metrics[metric_name] = host_list.map do |host|
        metric = Metric.create_from_full_name("#{host}.#{metric_name}")
        Rails.logger.debug("Getting measurements for: #{metric.get_id}")

        measurements = @monitoring_db.get_measurements(metric, @monitoring_period_start, @monitoring_period_end).map do |x|
          [ x['date'].to_i + 3600, x['value'].to_f ]
        end

        { name: host_label(host), data: change_time_resolution_of(measurements) }
      end
    end
  end

  def monitoring_data
    @time_resolution = params[:time_resolution].to_i
    @start_time = Time.at(params[:start_time].to_i)
    @end_time = Time.at(params[:end_time].to_i)

    Rails.logger.debug("Start: #{@start_time} - End: #{@end_time}")

    metric_measurements = []

    params[:hosts].each do |host|
      full_metric_id = "#{host.gsub('.', '_')}.#{params[:metric]}"
      metric = Metric.create_from_full_name(full_metric_id)

      measurements = @monitoring_db.get_measurements(metric, @start_time, @end_time).map do |x|
        [ x['date'].to_i, x['value'].to_f ]
      end

      #db = @monitoring_db.db
      #measurements = db[full_metric_id].find({date: { '$gt' => @start_time }}).to_a.map{|doc|
      #  [ doc['date'].to_i, doc['value'].to_f ]
      #}

      Rails.logger.debug("Measurements: #{measurements}")
      metric_measurements << { name: host, data: measurements } unless measurements.empty?
    end

    Rails.logger.debug("Metric measurements: #{metric_measurements.inspect}")

    render json: metric_measurements
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
    return [] if measurements.empty?

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
