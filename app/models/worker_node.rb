class WorkerNode < ActiveRecord::Base
  has_many :scalarm_managers

  def password
    if self.password_hashed
      Base64.decode64(self.password_hashed).decrypt
    else
      nil
    end
  end

  def password=(new_password)
    self.password_hashed = Base64.encode64(new_password.encrypt)
  end

  def self.find_node_without(service_name)
    service_name = 'experiments' if service_name == 'experiment'
    service_name = 'db_instances' if service_name == 'storage'

    wn = nil

    WorkerNode.all.each do |node|
      next if node.ignored.to_s == 'true'

      hosted_services = node.scalarm_managers.map(&:service_type)
      Rails.logger.debug("Hosted services at #{node.url} - #{hosted_services}")

      unless hosted_services.include?(service_name)
        wn = node
        break
      end
    end

    wn
  end

end
