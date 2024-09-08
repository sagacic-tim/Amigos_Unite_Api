# config/routes.rb
Rails.application.routes.draw do
  devise_for :amigos, skip: [:sessions, :registrations]

  namespace :api do
    namespace :v1, defaults: { format: :json } do
      # Devise custom routes for authentication
      devise_scope :amigo do
        post 'refresh_token', to: 'sessions#refresh'
        post 'login', to: 'sessions#create', as: :amigo_login
        delete 'logout', to: 'sessions#destroy', as: :amigo_logout
        post 'signup', to: 'registrations#create', as: :amigo_signup
        get 'verify_token', to: 'sessions#verify_token'  # Add the verify_token route here
      end

      # Amigo routes with standard RESTful actions
      resources :amigos, only: [:index, :show, :create, :update, :destroy] do
        # Nested route for amigo's detail
        resource :amigo_detail, only: [:show, :create, :update, :destroy]
        # Nested route for amigo's locations
        resources :amigo_locations, only: [:index, :create, :show, :update, :destroy]
      end

      # Separate route for listing all amigo locations across all amigos
      resources :amigo_locations, only: [:index]

      # Events and related connectors
      resources :events, except: [:new, :edit] do
        resources :event_amigo_connectors, except: [:new, :edit]
        resources :event_location_connectors, only: [:index, :show, :create, :update, :destroy] do
          member do
            post 'add_location'
            delete 'remove_location'
          end
        end
        post 'add_location', to: 'event_location_connectors#add_location'
        delete 'remove_location/:id', to: 'event_location_connectors#remove_location'
      end

      # Event locations
      resources :event_locations, except: [:new, :edit]
    end
  end

  # Active Storage routes (these are fine as-is)
  if defined?(ActiveStorage::Engine)
    ActiveStorage::Engine.routes.draw do
      get '/rails/active_storage/blobs/:signed_id/*filename', to: 'active_storage/blobs#show', as: :rails_blob
      get '/rails/active_storage/representations/:signed_blob_id/:variation_key/*filename', to: 'active_storage/representations#show', as: :rails_representation
      get '/rails/active_storage/disk/:encoded_key/*filename', to: 'active_storage/disk#show', as: :rails_disk
      put '/rails/active_storage/disk/:encoded_token', to: 'active_storage/disk#update', as: :update_rails_disk
      post '/rails/active_storage/direct_uploads', to: 'active_storage/direct_uploads#create', as: :rails_direct_uploads
    end
  else
    get '/rails/active_storage/blobs/redirect/:signed_id/*filename' => 'active_storage/blobs#redirect', as: :rails_service_blob
    get '/rails/active_storage/blobs/proxy/:signed_id/*filename' => 'active_storage/blobs#proxy', as: :rails_service_blob_proxy
    get '/rails/active_storage/blobs/:signed_id/*filename' => 'active_storage/blobs#show', as: :rails_blob_representation
    get '/rails/active_storage/representations/redirect/:signed_blob_id/:variation_key/*filename' => 'active_storage/representations#redirect', as: :rails_blob_representation_redirect
    get '/rails/active_storage/representations/proxy/:signed_blob_id/*filename' => 'active_storage/representations#proxy', as: :rails_blob_representation_proxy
    get '/rails/active_storage/representations/:signed_blob_id/*filename' => 'active_storage/representations#show', as: :rails_blob_representation
    get '/rails/active_storage/disk/:encoded_key/*filename' => 'active_storage/disk#show', as: :rails_disk_service
    put '/rails/active_storage/disk/:encoded_token' => 'update_rails_disk_service'
    post '/rails/active_storage/direct_uploads' => 'rails_direct_uploads'
  end
end