require_relative 'experiment_manager'
require_relative 'db_instance_manager'

class ScalarmServiceFactory

  def self.create_service(type)
    if type == 'experiments'
      ExperimentManager.new(service_repos[type], service_repos[type].split('/').last)
    elsif type == 'db_instances'
      DbInstanceManager.new(service_repos[type], service_repos[type].split('/').last)
    else
      nil
    end
  end


  def self.service_repos
    {
        'experiments' => 'https://github.com/Scalarm/scalarm_experiment_manager',
        'db_instances' => 'https://github.com/Scalarm/scalarm_storage_manager'
    }
  end
end