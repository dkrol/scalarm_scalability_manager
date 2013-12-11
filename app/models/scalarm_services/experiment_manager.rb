class ExperimentManager
  attr_reader :service_port, :service_socket

  def initialize(repo_url, service_folder)
    @service_repo = repo_url
    @service_folder = service_folder
    @service_port = 3001
    @service_socket = '/tmp/scalarm_experiment_manager.sock'
  end

  def remote_installation_commands(worker_node)
    [
      "source .rvm/environments/default",
      "ruby --version",
      "rm -rf #{@service_folder}",
      "git clone #{@service_repo}",
      "cd #{@service_folder}",
      "echo \"#{scalarm_config_file}\" > config/scalarm.yml",
      "echo \"#{puma_config_file(worker_node)}\" > config/puma.rb",
      "bundle install",
      "bundle exec rake db_router:start service:non_digested",
      "bundle exec rake service:start",
    ].join(';')
  end

  def scalarm_config_file
    scalarm_config = Rails.configuration.scalarm

    <<-END
# at which port the service should listen
information_service_url: #{scalarm_config['information_service']['url']}
information_service_user: #{scalarm_config['information_service']['user']}
information_service_pass: #{scalarm_config['information_service']['pass']}
# mongo_activerecord config
db_name: 'scalarm_db'
    END
  end

  def puma_config_file(worker_node)
    scalarm_config = Rails.configuration.scalarm

    config = <<-END
environment 'production'
daemonize
stdout_redirect 'log/puma.log', 'log/puma.log.err', true
pidfile 'puma.pid'
threads 1,16

    END

    Rails.logger.debug("Worker node url: #{worker_node.url} --- #{scalarm_config['experiment_manager_lb']['url']}")

    config + if worker_node.url != scalarm_config['experiment_manager_lb']['url']
               "bind 'tcp://0.0.0.0:#{@service_port}'"
             else
               "bind 'unix://#{@service_socket}'"
            end
  end

  def stop_service
    [
        'source .rvm/environments/default',
        'ruby --version',
        "cd #{@service_folder}",
        'bundle exec rake db_router:stop',
        'bundle exec rake service:stop'
    ].join(';')
  end

  def update_load_balancer_config(worker_node, load_balancer_host_address, load_balancer_config)
    if worker_node.url == load_balancer_host_address
      unless load_balancer_config.include?('/tmp/scalarm_experiment_manager.sock')
        em_address = <<-EOD
      upstream scalarm_experiment_manager {
            server unix:/tmp/scalarm_experiment_manager.sock;
        EOD
        load_balancer_config.gsub!('upstream scalarm_experiment_manager {', em_address)
      end

    else
      unless load_balancer_config.include?("#{worker_node.url}:3001")
        em_address = <<-EOD
      upstream scalarm_experiment_manager {
            server #{worker_node.url}:3001;
        EOD
        load_balancer_config.gsub!('upstream scalarm_experiment_manager {', em_address)
      end
    end

    load_balancer_config
  end

end