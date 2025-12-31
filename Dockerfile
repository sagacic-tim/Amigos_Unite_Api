
# amigos_unite_api/Dockerfile
FROM ruby:3.2.2-slim AS base

ENV RAILS_ENV=production \
    RACK_ENV=production \
    BUNDLE_WITHOUT="development:test"

# System deps
RUN apt-get update -qq && \
    apt-get install -y --no-install-recommends \
      build-essential \
      libpq-dev \
      postgresql-client \
      nodejs \
      curl \
      git && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Install gems first (cache layer)
COPY Gemfile Gemfile.lock ./
RUN bundle config set deployment 'true' && \
    bundle config set without 'development test' && \
    bundle install --jobs 4 --retry 3

# Copy the rest of the app
COPY . .

# If you ever add assets, uncomment:
# RUN bundle exec rails assets:precompile

EXPOSE 3001

# Expect DATABASE_URL, RAILS_MASTER_KEY, etc. from environment
CMD ["bundle", "exec", "puma", "-C", "config/puma.rb"]
