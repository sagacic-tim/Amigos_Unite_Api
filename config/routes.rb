# config/routes.rb
Rails.application.routes.draw do
  # CORS preflight
  match '*path', via: :options, to: 'application#options_request'

  require 'sidekiq/web'
  if Rails.env.development?
    mount Sidekiq::Web => '/sidekiq'
  end

  scope '/api/v1', module: 'api/v1', defaults: { format: :json } do
    # CSRF handshake
    get    'csrf',        to: 'auth/csrf#show'

    get  'confirmations', to: 'confirmations#show'   # /api/v1/confirmations?token=...
    post 'confirmations', to: 'confirmations#create' # resend

    devise_for :amigos,
      path: '',
      skip: [:sessions, :registrations],
      path_names: { sign_up: 'signup' },
      controllers: {
        registrations: 'auth/registrations',
        confirmations: 'auth/confirmations',
        passwords:     'auth/passwords',
        unlocks:       'auth/unlocks'
      }

    devise_scope :amigo do
      post   'login',         to: 'auth/sessions#create'
      delete 'logout',        to: 'auth/sessions#destroy'
      post   'signup',        to: 'auth/registrations#create'
      post   'refresh_token', to: 'auth/sessions#refresh'
      get    'verify_token',  to: 'auth/sessions#verify_token'
    end

    # Google Places proxy
    get 'places/search',     to: 'places#search'
    get 'places/:id/photos', to: 'places#photos'

    # Your application resources
    get    'me',            to: 'amigos#me'
    resources :amigos,      only: %i[index show create update destroy] do
      resource  :amigo_detail,    only: %i[show create update destroy]
      resources :amigo_locations, only: %i[index create show update destroy]
    end

    # TOP-LEVEL INDEX: /api/v1/event_amigo_connectors
    resources :event_amigo_connectors, only: [:index]

    resources :events, except: %i[new edit] do
      # NEW: /api/v1/events/my_events → Api::V1::EventsController#my_events
      collection do
        get :my_events
      end

      # NESTED: /api/v1/events/:event_id/event_amigo_connectors
      resources :event_amigo_connectors,    except: %i[new edit]
      resources :event_location_connectors, only: %i[index show create update destroy]
    end

    resources :event_locations,  except: %i[new edit]
    resources :contact_messages, only: :create
  end
end
