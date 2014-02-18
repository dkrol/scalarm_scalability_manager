class Metric
  attr_accessor :host, :attribute

  def get_id
    "#{host}.#{attribute}"
  end

  def get_host_ip
    host.gsub('_', '.')
  end

  def self.create_from_full_name(full_name)
    host, attribute = full_name.split('.')

    metric = Metric.new
    metric.host = host
    metric.attribute = attribute

    metric
  end
end