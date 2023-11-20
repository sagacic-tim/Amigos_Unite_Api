Rails.application.routes.draw do
  # Define routes for Devise authentication
  devise_for :amigos, path: '', path_names: {
    sign_in: 'login',
    sign_out: 'logout',
    registration: 'signup'
  },
  controllers: {
    sessions: 'api/v1/amigos/sessions',
    registrations: 'api/v1/amigos/registrations'
  }

  # API routes
  namespace :api do
    namespace :v1 do
      resources :amigos, only: [:index, :show, :create, :update, :destroy] do
        resources :amigo_locations, only: [:index, :show, :create, :update, :destroy]
        resource :amigo_details, only: [:show, :create, :update, :destroy] # Singular resource
      end
    end
  end
end
  