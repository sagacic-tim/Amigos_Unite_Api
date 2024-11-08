# config/routes.rb
Rails.application.routes.draw do
  devise_for :amigos, skip: [:sessions, :registrations]

  # Handle CORS preflight OPTIONS requests
  match '*path', via: [:options], to: 'application#options_request'

  namespace :api do
    namespace :v1, defaults: { format: :json } do
      # Devise custom routes for authentication
      devise_scope :amigo do
        post 'refresh_token', to: 'sessions#refresh', as: 'refresh_token'
        get 'test', to: 'test#index'
        post 'login', to: 'sessions#create'
        delete 'logout', to: 'sessions#destroy'
        post 'signup', to: 'registrations#create'
        get 'verify_token', to: 'sessions#verify_token'
      end

      # Amigo routes with standard RESTful actions
      resources :amigos, only: [:index, :show, :create, :update, :destroy] do
        # Nested routes for amigo's detail and locations
        resource :amigo_detail, only: [:show, :create, :update, :destroy]
        resources :amigo_locations, only: [:index, :create, :show, :update, :destroy]
      end

      # Events and related connectors
      resources :events, except: [:new, :edit] do
        resources :event_amigo_connectors, except: [:new, :edit]
        resources :event_location_connectors, only: [:index, :show, :create, :update, :destroy] do
          member do
            post 'add_location'
            delete 'remove_location'
          end
        end
      end

      # Event locations
      resources :event_locations, except: [:new, :edit]
    end
  end

  # Active Storage routes are loaded automatically; no need to define them explicitly
end