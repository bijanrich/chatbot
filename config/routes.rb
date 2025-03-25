require 'sidekiq/web'

Rails.application.routes.draw do
  # Set the root path to the home index page
  root 'home#index'
  
  get 'home/index'
  devise_for :users
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

    namespace :v1 do
      post 'onlyfans/generate_response', to: 'onlyfans_messages#generate_response'
    end
  end

  # Health check
  get "up" => "rails/health#show", as: :rails_health_check
end
