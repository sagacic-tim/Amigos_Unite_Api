# config/routes.rb
Rails.application.routes.draw do
  devise_for :amigos, skip: [:sessions, :registrations]

  namespace :api do
    namespace :v1, defaults: { format: :json } do
      devise_scope :amigo do
        post 'login', to: 'amigos/sessions#create', as: :amigo_login
        delete 'logout', to: 'amigos/sessions#destroy', as: :amigo_logout
        post 'signup', to: 'amigos/registrations#create', as: :amigo_signup
      end

      resources :amigos, except: [:new, :edit] do
        resource :amigo_detail, only: [:show, :create, :update, :destroy]
        resources :amigo_locations, only: [:index, :show, :create, :update, :destroy]
      end

      resources :amigo_locations, only: [:index]
      resources :amigo_details, only: [:index]

      resources :events, except: [:new, :edit] do
        resources :event_amigo_connectors, except: [:new, :edit]
        resources :event_location_connectors, only: [:create]
        resources :event_location_connectors, only: [:index, :show, :create, :update, :destroy] do
          member do
            post 'add_location'
            delete 'remove_location'
          end
        end
        post 'add_location', to: 'event_location_connectors#add_location'
        delete 'remove_location/:id', to: 'event_location_connectors#remove_location'
      end

      resources :event_locations, except: [:new, :edit]
    end
  end

  # Active Storage routes
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
    get '/rails/active_storage/representations/proxy/:signed_blob_id/:variation_key/*filename' => 'active_storage/representations#proxy', as: :rails_blob_representation_proxy
    get '/rails/active_storage/representations/:signed_blob_id/:variation_key/*filename' => 'active_storage/representations#show', as: :rails_blob_representation
    get '/rails/active_storage/disk/:encoded_key/*filename' => 'active_storage/disk#show', as: :rails_disk_service
    put '/rails/active_storage/disk/:encoded_token' => 'active_storage/disk#update', as: :update_rails_disk_service
    post '/rails/active_storage/direct_uploads' => 'active_storage/direct_uploads#create', as: :rails_direct_uploads
  end
end