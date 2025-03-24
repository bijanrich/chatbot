require 'sidekiq/web'

Rails.application.routes.draw do
  # Mount Sidekiq web UI
  mount Sidekiq::Web => '/sidekiq' if Rails.env.development?

  # Telegram webhook - make it accessible outside the API namespace
  post '/telegram/webhook', to: 'telegram_webhook#create'

  # API routes
  namespace :api do
    resources :chats, only: [:create, :index, :show] do
      post :message, on: :collection
      get :history, on: :member
    end
    
    resources :memories, only: [:index, :create]
  end

  # Health check
  get "up" => "rails/health#show", as: :rails_health_check
end
