Rails.application.routes.draw do
  # Define routes for Devise authentication
  devise_for :mucho_amigos, controllers: {
    sessions: 'amigos/sessions',
    registrations: 'amigos/registrations'
  }

  # API routes
  namespace :api do
    namespace :v1 do
      resources :amigos, only: [:index, :show, :update] do
        resources :amigo_locations, only: [:index, :show, :create, :update, :destroy]
      end
    end
  end
end
