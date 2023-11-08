source "https://rubygems.org" 
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby "3.2.2"

# Rails is a web-application framework that includes everything
# needed to create database-backed web applications according
# to the Model-View-Controller (MVC) pattern.
gem "rails", "~> 7.0.7"

# Database
# Pg is the Ruby interface to the PostgreSQL RDBMS. It works
# with PostgreSQL 9.3 and later.
gem 'pg', '~> 1.5', '>= 1.5.4'

# Puma
gem 'puma', '~> 6.3'

# Systrem gems
  # Shim to load environment variables from .env into ENV in
  # development.
gem 'dotenv', '~> 2.8', '>= 2.8.1', groups: [:development, :test]
  # Rack::Cors provides support for Cross-Origin Resource
  # Sharing (CORS)for Rack compatible web applications.
  # The CORS spec allows web applications to make cross domain
  # AJAX calls without using workarounds such as JSONP.
gem 'rack-cors', '~> 2.0', '>= 2.0.1'
  # A set of responders modules to dry up your Rails 4.2+ app.
gem 'responders', '~> 3.0', '>= 3.0.1'
  # Modern encryption for Ruby and Rails — Works with database fields,
  # files, and strings — Maximizes compatibility with existing code
  # and libraries — Makes migrating existing data and key rotation easy —
  # Has zero dependencies and many integrations
gem 'lockbox', '~> 1.3'

  # To summarize, we compute a keyed hash of the sensitive data and
  # store it in a column. To query, we apply the keyed hash function
  # to the value we’re searching and then perform a database search.
  # This results in performant queries for exact matches. Efficient
  # LIKE queries are not possible, but you can index expressions.
gem 'blind_index', '~> 2.4'

  # Reduces boot times through caching; required in config/boot.rb
gem "bootsnap", require: false

# Faker, a port of Data::Faker from Perl, is used to easily
# generate fake data: names, addresses, phone numbers, etc.

gem 'faker', '~> 3.2', '>= 3.2.2'

# Devise and related authentication gems
  # Devise is a flexible authentication solution for Rails
  # based on Warden. It:
  # 1. Is Rack based;
  # 2. Is a complete MVC solution based on Rails engines;
  # 3. Allows you to have multiple models signed in at the
  #    same time;
  # 4. Is based on a modularity concept: use only what you
  #    really need.
gem 'devise', '~> 4.8'
  # devise-jwt is a Devise extension which uses JWT tokens
  # for user authentication. It follows secure by default principle.
gem 'devise-jwt', '~> 0.11.0'
  # using jwt with devise-jwt in a Rails API-only app provides
  # a secure, scalable, and stateless authentication mechanism
  # that leverages Devise's ease of use while also being flexible
  # enough to accommodate various frontend technologies and
  # architectures.
gem 'jwt', '~> 2.2', '>= 2.2.1'
  # OmniAuth is a library that standardizes multi-provider
  # authentication for web applications.
gem 'omniauth', '~> 2.1', '>= 2.1.1'
  # This is the official OmniAuth strategy for authenticating
  # with these services
gem 'omniauth-google-oauth2', '~> 1.1', '>= 1.1.1'
gem 'omniauth-facebook', '~> 9.0'
gem 'omniauth-github'
gem 'omniauth-linkedin-oauth2', '~> 1.0', '>= 1.0.1'
  # This gem provides a mitigation against CVE-2015-9284 by
  # implementing a CSRF token verifier that directly uses
  # ActionController::RequestForgeryProtection code from Rails.
gem 'omniauth-rails_csrf_protection'
  # A LoginActivity record is created every time a user tries
  # to login. You can then use this information to detect
  # suspicious behavior. 
gem 'authtrail', '~> 0.5.0'

# Serialization and JSON DSL
  # Jbuilder gives you a simple DSL for declaring JSON
  # structures that beats manipulating giant hash structures.
gem 'jbuilder', '~> 2.11'
  # A fast JSON:API serializer for Ruby Objects.
gem 'jsonapi-serializer', '~> 2.2'

# Address Validation
gem 'smartystreets_ruby_sdk'
#The activerecord-postgis-adapter provides access to features
# of the PostGIS geospatial database from ActiveRecord. It
# extends the standard postgresql adapter to provide support
# for the spatial data types and features added by the PostGIS
# extension. It uses the RGeo library to represent spatial
# data in Ruby.
gem 'activerecord-postgis-adapter'

# Email and Phone Validation
gem 'phonelib', '~> 0.7.0'

# Additional Gems for Country and State Data
gem 'countries', '~> 5.6', require: 'countries/global'
gem 'bigdecimal', require: true

# Sanitize is an allowlist-based HTML and CSS sanitizer. It
# removes all HTML and/or CSS from a string except the
# elements, attributes, and properties you choose to allow.
gem 'sanitize', '~> 6.1'

group :development, :test do
  # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
  gem "debug", platforms: %i[ mri mingw x64_mingw ]
end

group :development do
  # Speed up commands on slow machines / big apps [https://github.com/rails/spring]
  # gem "spring"
  #
  # Preview email in the default browser instead of sending it.
  # This means you do not need to set up email delivery in your
  # development environment, and you no longer need to worry about
  # accidentally sending a test email to someone else's address.
  gem 'letter_opener', '~> 1.8', '>= 1.8.1'
end

