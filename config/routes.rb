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

      resources :events, except: [:new, :edit] do
        resources :event_amigo_connectors, except: [:new, :edit]
        resources :event_location_connectors, only: [:create]
      end

      resources :event_locations, except: [:new, :edit]
    end
  end
end