Rails.application.routes.draw do
  if Rails.env.development?
    require 'sidekiq/web'
    mount Sidekiq::Web => '/sidekiq'
    # get '/rails/mailers' => 'rails/mailers#index'
    # get '/rails/mailers/*path' => 'rails/mailers#preview'
  end

  resource :health_check, only: [:show]

  # API Routes
  scope :api, format: false, defaults: { format: :jsonapi } do
    resource :app_settings, only: %i[show update]

    resource :registrations, only: [:create]
    resource :sessions, only: %i[create destroy]
    resource :passwords, only: %i[create update]

    resources :users, only: %i[index show create update destroy] do
      resource :password, only: [:update], module: :users
      resource :action, only: [:create], module: :users
    end

    resource :account_info, only: [:show]

    resources :provider_types, only: %i[index show]
    resources :provider_data, only: %i[index show]
    resources :providers do
      resource :connection, only: [:update], module: :providers
      resource :sync, only: [:create], module: :providers
    end
    namespace :providers do
      resource :credentials, only: [:create]
    end

    resources :product_categories

    resources :product_types, only: %i[index show]
    resources :products

    resources :service_requests do
      resource :approval, only: [:create], module: :service_requests
    end
    resources :service_orders
    resources :services do
      resource :action, only: [:create], module: :services
    end
    resources :service_details, only: %i[index show]

    resources :project_requests do
      resource :approval, only: [:create], module: :project_requests
    end
    resources :projects

    resources :project_questions

    resources :memberships
    resources :members, only: %i[index show]

    resources :filters
  end

  # NOTICE: If the Client is extracted from the API remove the following routes.
  # Client Handling
  root 'client#index'
  resource :remote_auth_sessions, only: [:create], path: :remote_login
  match '*path' => 'client#index', via: :all
end
