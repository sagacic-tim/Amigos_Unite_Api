Amigos Unite API

Rails 7 API for community event coordination

Overview

Amigos Unite API is a Ruby on Rails API-only backend that powers the Amigos Unite platform.

It supports user authentication, community event creation, location management, and role-based participation.

The API is designed to be consumed by multiple clients (web, mobile, future integrations) and follows a stateless, JWT-based authentication model suitable for distributed systems.

Core Features

Amigo accounts

Secure signup, login, logout

JWT authentication (Devise + JWT)

Event management

Create, update, and manage community events

Event statuses (planning, active, completed, canceled)

Role-based participation

Lead coordinators, assistant coordinators, participants

Location support

Event locations with structured address data

Google Places integration for location search and images

Security

CSRF protection

Rate limiting via Rack::Attack

Token refresh flow

Tech Stack

Language: Ruby 3.2.2

Framework: Rails 7.x (API-only)

Database: PostgreSQL (15+ recommended)

Authentication: Devise + JWT

Background jobs: Sidekiq

Image processing: libvips

External APIs: Google Places API

Deployment: Docker + GHCR + VPS

System Requirements

Ruby 3.2.2

PostgreSQL 15+

libvips

Redis (for Sidekiq)

Docker (recommended for production)

Configuration
Credentials

Secrets are stored using Rails encrypted credentials:

config/credentials/development.yml.enc
config/credentials/test.yml.enc
config/credentials/production.yml.enc


Required keys include:

google_maps:
  api_key: <GOOGLE_PLACES_API_KEY>

devise:
  jwt_secret_key: <JWT_SECRET>
  pepper: <DEVISE_PEPPER>


The corresponding master.key (or environment-provided key) must be present for each environment.

Database Setup
bin/rails db:create
bin/rails db:migrate


PostgreSQL extensions such as PostGIS may be enabled depending on deployment configuration.

Running the Test Suite
bundle exec rspec


The test environment uses an isolated PostgreSQL database and validates:

Authentication flows

Event and location APIs

Role-based permissions

API Architecture Notes

API responses are JSON-only

Stateless JWT authentication (no server sessions)

Designed for same-origin and cross-origin SPA clients

Google Places lookups are proxied through the API to protect API keys

Deployment

Built and published as a Docker image via GitHub Container Registry (GHCR)

Automated CI/CD using GitHub Actions:

Test → Build → Push → Deploy

Production runs behind Nginx with TLS termination

Project Goals

This API demonstrates:

Clean domain modeling

Secure authentication patterns

External API integration

Production-grade deployment practices
