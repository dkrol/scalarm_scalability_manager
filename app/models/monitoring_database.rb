require 'mongo'

class MonitoringDatabase
  MONITORING_TABLE_PATTERN = /.*_.*_.*\..*___.*___.*/
  attr_reader :db

  def initialize
    @config = YAML.load_file(File.join(Rails.root, 'config', 'scalarm.yml'))['monitoring']
    @db_name = @config['db_name']
    @db = Mongo::Connection.new('localhost').db(@db_name)
  end

  def monitored_hosts
    collections = @db.collection_names.select do |collection_name|
      collection_name =~ MONITORING_TABLE_PATTERN
    end

    collections
  end

  def measurements(metric_name, date_constraints)
    field_filter = { :fields => { _id: 0, date: 1, value: 1 } }

    metric_values = @db[metric_name].find(date_filter(date_constraints), field_filter).to_a.sort_by{|a| a['date']}.map do |doc|
      [ doc['date'].to_i, doc['value'].to_f ]
    end

    metric_values
  end

  def get_measurements(metric, after_date = nil, before_date = nil, find_one = false)
    query_constraints = { "date" => {} }
    query_constraints["date"]["$gt"] = after_date unless after_date.nil?
    query_constraints["date"]["$lt"] = before_date unless before_date.nil?

    result_constraints = { sort: ['_id', :asc] }
    result_constraints['limit'] = 1 if find_one
    Rails.logger.debug("Query constraints: #{query_constraints.inspect}")
    Rails.logger.debug("Result constraints: #{result_constraints.inspect}")

    @db[metric.get_id].find(query_constraints, result_constraints).to_a
  end

  # somehow the hour in JS is one hour ahead
  def string_to_time(string_date)
    DateTime.strptime(string_date, "%Y-%m-%d %H:%M:%S").to_time
  end

  def date_filter(date_constraints)
    date_filter = {}

    date_filter['$gt'] = date_constraints['monitoring_period_start'] if date_constraints.include?('monitoring_period_start')
    date_filter['$lte'] = date_constraints['monitoring_period_end'] if date_constraints.include?('monitoring_period_end')

    { 'date' => date_filter }
  end

  def get_metrics
    metrics = []

    @db.collection_names.each do |collection_name|
      if collection_name =~ MONITORING_TABLE_PATTERN
        metric = Metric.new
        host, attribute = collection_name.split('.')
        metric.host = host
        metric.attribute = attribute

        metrics << metric
      end
    end

    metrics
  end

end