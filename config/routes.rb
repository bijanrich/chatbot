require 'sidekiq/web'

Rails.application.routes.draw do
  get 'subscriptions/index'
  get 'subscriptions/new'
  get 'subscriptions/checkout'
  get 'subscriptions/success'
  # Authenticated routes
  authenticated :user do
    root 'dashboard#index', as: :authenticated_root
    get 'dashboard', to: 'dashboard#index', as: :dashboard
  end
  
  # Set the root path to the home index page for non-authenticated users
  root 'home#index'
  
  get 'home/index'
  
  # Use custom controllers for Devise
  devise_for :users, controllers: {
    registrations: 'users/registrations',
    confirmations: 'users/confirmations'
  }
  
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
