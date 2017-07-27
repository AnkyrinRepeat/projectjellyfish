class SessionsController < ApplicationController
  skip_before_action :authenticate, only: [:create]

  # service_class User

  def create
    handle Session::Create do |success|
      @current_user = success.model
      response.headers['Authorization'] = success.model.session.token
      render_results success.model
    end
  end

  def destroy
    handle Session::Destroy do
      # noop
    end
  end

  private

  # def model_class
  #   User
  # end

  def create_params
    params.to_unsafe_hash.merge user_agent: request.user_agent, remote_ip: request.remote_ip
  end
end
