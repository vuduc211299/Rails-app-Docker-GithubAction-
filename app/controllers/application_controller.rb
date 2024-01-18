# frozen_string_literal: true

# application.rb
class ApplicationController < ActionController::Base
  def not_found
    redirect_to new_user_session_path
  end
end
