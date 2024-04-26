Rails.application.routes.draw do
  # Skipping built-in Devise controllers for sessions and registrations
  devise_for :amigos, skip: [:sessions, :registrations]

  # API routes
  namespace :api do
    namespace :v1, defaults: { format: :json } do
      # Custom routes for sessions and registrations using specific controllers
      devise_scope :amigo do
        post 'login', to: 'amigos/sessions#create', as: :amigo_login
        delete 'logout', to: 'amigos/sessions#destroy', as: :amigo_logout
        post 'signup', to: 'amigos/registrations#create', as: :amigo_signup
      end

      resources :amigos, except: [:new, :edit] do
        resources :amigo_locations, except: [:new, :edit]
        resource :amigo_details, except: [:new, :edit]
      end
      # Route for listing all locations across all amigos
      resources :amigo_locations, only: [:index]
      # Route for listing all details
      resources :amigo_details, only: [:index] 

      resources :events, except: [:new, :edit] do
        resources :event_amigo_connectors, except: [:new, :edit]
        resources :event_location_connectors, only: [:create]
        # Routes for managing location connectors
        resources :event_location_connectors, only: [:index, :show, :create, :update, :destroy] do
          member do
            post 'add_location'    # Adds an existing location to an event
            delete 'remove_location'  # Removes a location from an event
          end
        end
        # Routes to directly add or remove a location to/from an event without needing to manage the connector directly
        post 'add_location', to: 'event_location_connectors#add_location'
        delete 'remove_location/:id', to: 'event_location_connectors#remove_location'
      end
      # Separate resource for locations to manage them outside of events
      resources :event_locations, except: [:new, :edit]
    end
  end
end