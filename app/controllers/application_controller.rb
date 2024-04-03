# frozen_string_literal: true

# application.rb
class ApplicationController < ActionController::Base
  protect_from_forgery

  def not_found
    redirect_to new_user_session_path
  end

  rescue_from CanCan::AccessDenied do |exception|
    redirect_to root_url, alert: exception.message
  end
end
