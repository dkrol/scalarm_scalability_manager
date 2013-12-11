class ExperimentManager

  def initialize(repo_url, service_folder)
    @service_repo = repo_url
    @service_folder = service_folder
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
               "bind 'tcp://0.0.0.0:3001'"
             else
               "bind 'unix:///tmp/scalarm_experiment_manager.sock'"
            end
  end
end