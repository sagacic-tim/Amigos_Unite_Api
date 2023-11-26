Rails.application.routes.draw do
  # Define routes for Devise authentication
  devise_for :amigos, path: '', path_names: {
    sign_in: 'login',
    sign_out: 'logout',
    registration: 'signup'
  }, controllers: {
    sessions: 'api/v1/amigos/sessions',
    registrations: 'api/v1/amigos/registrations'
  }

  # API routes
  namespace :api do
    namespace :v1 do
      resources :amigos, except: [:new, :edit] do
        resources :amigo_locations, except: [:new, :edit]
        resource :amigo_details, except: [:new, :edit]
      end

      resources :events, except: [:new, :edit] do
        resources :event_locations, except: [:new, :edit]
        resources :event_participants, except: [:new, :edit]
        resources :event_coordinators, except: [:new, :edit] do
          member do
            get 'locations_of_host'
          end
        end
      end
    end
  end
end