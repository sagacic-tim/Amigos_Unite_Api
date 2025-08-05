# config/routes.rb
Rails.application.routes.draw do
  # CORS preflight
  match '*path', via: :options, to: 'application#options_request'

  if Rails.env.development?
    mount LetterOpenerWeb::Engine, at: '/letter_opener'
  end

  scope '/api/v1', module: 'api/v1', defaults: { format: :json } do
    # CSRF handshake
    get    'csrf',          to: 'auth/csrf#show'

    # Signup still comes from Devise registrations
    devise_for :amigos,
      path: '',
      skip: [:sessions],                          # ⇣— don’t generate Devise’s own /login & /logout
      path_names: { sign_up: 'signup' },
      controllers: {
        registrations: 'auth/registrations',
        confirmations: 'auth/confirmations',
        passwords:     'auth/passwords',
        unlocks:       'auth/unlocks'
      }

    # Now manually re-declare all of the “session” routes you want:
      devise_scope :amigo do
        post   'login',         to: 'auth/sessions#create'
        delete 'logout',        to: 'auth/sessions#destroy'
        post   'refresh_token', to: 'auth/sessions#refresh'
        get    'verify_token',  to: 'auth/sessions#verify_token'
      end

    # Your application resources
    get    'me',            to: 'amigos#me'
    resources :amigos,      only: %i[index show create update destroy] do
      resource  :amigo_detail,    only: %i[show create update destroy]
      resources :amigo_locations, only: %i[index create show update destroy]
    end

    resources :events, except: %i[new edit] do
      resources :event_amigo_connectors, except: %i[new edit]
      resources :event_location_connectors, only: %i[index show create update destroy]
    end

    resources :event_locations, except: %i[new edit]
  end
end
