class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  prepend_before_filter :set_auth_token

  protected

  def set_auth_token
    unless params.include? :authenticity_token
      params[:authenticity_token] = cookies['XSRF-TOKEN']
    end
  end
end
