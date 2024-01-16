class ApplicationController < ActionController::Base
  before_action :authenticate_user!

  def after_sign_in_path_for(resource)
    images_path
  end

  def after_sign_out_path_for(resource)
    new_user_session_path
  end

  def not_found
    new_user_session_path
  end
end
