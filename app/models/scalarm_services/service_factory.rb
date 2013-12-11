require_relative 'experiment_manager'

class ScalarmServiceFactory

  def self.create_service(type)
    if type == 'experiments'
      ExperimentManager.new(service_repos[type], service_repos[type].split('/').last)
    else
      nil
    end
  end


  def self.service_repos
    {
        'experiments' => 'https://github.com/Scalarm/scalarm_experiment_manager'
    }
  end
end