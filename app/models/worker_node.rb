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
end
