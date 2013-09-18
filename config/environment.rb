# Load the Rails application.
require File.expand_path('../application', __FILE__)

# Initialize the Rails application.
ScalarmScalabilityManager::Application.initialize!


Encryptor.default_options.merge!(:key => Digest::SHA256.hexdigest('QjqjFK}7|DDMUP-&82'))
