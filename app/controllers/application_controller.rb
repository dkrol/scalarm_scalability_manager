class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  prepend_before_filter :set_auth_token

  before_filter :load_information_manager

  protected

  def set_auth_token
    unless params.include? :authenticity_token
      params[:authenticity_token] = cookies['XSRF-TOKEN']
    end
  end

  def load_information_manager
    @config = YAML.load_file(File.join(Rails.root, 'config', 'scalarm.yml'))
    @information_service = InformationService.new(@config)
  end

end
