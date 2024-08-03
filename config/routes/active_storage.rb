# config/routes/active_storage.rb

Rails.application.routes.draw do
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