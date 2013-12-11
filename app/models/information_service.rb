require 'openssl'
require 'net/https'
require 'json'

class InformationService
  def initialize(config)
    @service_url = config['information_service']['url']
  end

  def scalarm_services
    {
        'experiments' => 'Experiment Manager',
        'storage' => 'Storage Manager - Log Bank',
        'db_instances' => 'Storage Manager - DB Instance',
        'db_config_services' => 'Storage Manager - DB Config Service',
        'db_routers' => 'Storage Manager - DB Router'
    }
  end

  def get_list_of(service)
    send_request("#{service}/list") or []
  end

  def send_request(request, data = nil)
    host, port = @service_url.split(':')
    Rails.logger.debug("#{Time.now} --- sending #{request} request to the Information Manager at '#{host}:#{port}'")

    req = if data.nil?
            Net::HTTP::Get.new('/' + request)
          else
            Net::HTTP::Post.new('/' + request)
          end

    unless data.nil?
      req.basic_auth(@username, @password)
      req.set_form_data(data) unless data.nil?
    end

    ssl_options = { use_ssl: true, ssl_version: :SSLv3, verify_mode: OpenSSL::SSL::VERIFY_NONE }

    begin
      response = Net::HTTP.start(host, port, ssl_options) { |http| http.request(req) }
      Rails.logger.debug("#{Time.now} --- response from the Information Manager is #{response.body}")

      return JSON.parse(response.body)
    rescue Exception => e
      Rails.logger.debug("Exception occurred but nothing terrible :) - #{e.message}")
    end

    nil
  end

end