# config/initializers/active_storage.rb
Rails.application.config.active_storage.content_types_to_serve_as_binary.delete('image/svg+xml')

if defined?(ActiveStorage::Engine)
  puts "Active Storage Initialized"
end