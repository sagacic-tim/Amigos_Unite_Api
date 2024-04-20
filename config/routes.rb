Rails.application.routes.draw do
  # Devise routes for authentication
  devise_for :amigos, path: '', path_names: {
    sign_in: 'login',
    sign_out: 'logout',
    registration: 'signup'
  }, controllers: {
    sessions: 'api/v1/amigos/sessions',
    registrations: 'api/v1/amigos/registrations'
  }

  namespace :api do
    namespace :v1, defaults: { format: :json } do
      resources :amigos, except: [:new, :edit] do
        resources :amigo_locations, except: [:new, :edit]
        resource :amigo_details, except: [:new, :edit]
      end

      resources :events, except: [:new, :edit] do
        resources :event_amigo_connectors, except: [:new, :edit]
        resources :event_location_connectors, only: [:create]
        resources :event_locations, only: [:index]  # Ensure this line exists
      end

      resources :event_locations, except: [:new, :edit]
    end
  end
end