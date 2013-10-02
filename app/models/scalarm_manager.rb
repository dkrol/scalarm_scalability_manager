class ScalarmManager < ActiveRecord::Base
  belongs_to :worker_node

  include ExperimentManager


  def self.remote_installation(worker_node, manager_type, em_lb_config)
    begin
      Net::SSH.start(worker_node.url, worker_node.user, password: worker_node.password) do |ssh|
        # deployment procedure
        # 1. upload and start the code of the selected manager type at the specified worker node
        Rails.logger.debug(ssh.exec!(remote_installation_commands(worker_node, label_to_name(manager_type), em_lb_config)))
      end

      # 2. update and restart load balancer of the selected manager type
      Net::SSH.start(em_lb_config['url'], em_lb_config['user']) do |ssh|
        lb_config = ssh.exec!("cat #{em_lb_config['config_file']}")
        if worker_node.url != em_lb_config['url']
          unless lb_config.include?('/tmp/scalarm_experiment_manager.sock')
            em_address = <<-EOD
  upstream scalarm_experiment_manager {
      server unix:/tmp/scalarm_experiment_manager.sock;
            EOD
            lb_config.gsub!('upstream scalarm_experiment_manager {', em_address)
          end
        else
          unless lb_config.include?("#{worker_node.url}:3001")
            em_address = <<-EOD
  upstream scalarm_experiment_manager {
      server #{worker_node.url}:3001;
            EOD
            lb_config.gsub!('upstream scalarm_experiment_manager {', em_address)
          end
        end

        Rails.logger.debug(lb_config)
        ssh.exec!("echo \"#{lb_config}\" > #{em_lb_config['config_file']}")
        ssh.exec!("service nginx restart")
      end

      # 3. create new manager instance locally unless error in previous step
      manager_url = if worker_node.url != em_lb_config['url']
                      "#{worker_node.url}:3001"
                    else
                      "#{worker_node.url}:/tmp/scalarm_experiment_manager.sock"
                    end
      manager = ScalarmManager.new(url: manager_url, service_type: manager_type)
      manager.worker_node = worker_node
      manager.save

      # 4. return the local manager instance as json object
      manager
    rescue Exception => e
      Rails.logger.error("An Exception occured during manager deployment: #{e}")
      nil
    end

  end

  def self.remote_installation_commands(worker_node, manager_type, em_lb_config)
    [
      "source .rvm/environments/default",
      "ruby --version",
      "rm -rf #{manager_type}",
      "git clone https://github.com/dkrol/#{manager_type}",
      "cd #{manager_type}",
      'rm config/scalarm.yml',
      "echo \"#{scalarm_config_file(manager_type)}\" >> config/scalarm.yml",
      'rm config/thin.yml',
      "echo \"#{thin_config_file(worker_node, manager_type, em_lb_config)}\" >> config/thin.yml",
      "bundle install",
      "RAILS_ENV=production rake assets:precompile",
      "bundle exec rake service:start"
    ].join(';')
  end

  def self.label_to_name(manager_label)
    manager_label_map = {
        'Experiment Manager' => 'scalarm_experiment_manager'
    }

    manager_label_map[manager_label]
  end

  def self.scalarm_config_file(manager_type)
    case manager_type
      when 'scalarm_experiment_manager'
        <<-END
# at which port the service should listen
information_service_url: localhost:11300
# mongo_activerecord config
db_name: 'scalarm_db'
        END
    end
  end

  def self.thin_config_file(worker_node, manager_type, em_lb_config)
    case manager_type
      when 'scalarm_experiment_manager'
        config = <<-END
pid: tmp/pids/thin.pid
log: log/thin.log
environment: production
#servers: 6

        END
        config + if worker_node.url != em_lb_config['url']
                    'socket: /tmp/scalarm_experiment_manager.sock'
                  else
                    'port: 3001'
                  end
    end
  end

end
