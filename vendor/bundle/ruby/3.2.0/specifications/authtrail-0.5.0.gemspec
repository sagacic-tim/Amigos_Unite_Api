# -*- encoding: utf-8 -*-
# stub: authtrail 0.5.0 ruby lib

Gem::Specification.new do |s|
  s.name = "authtrail".freeze
  s.version = "0.5.0".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Andrew Kane".freeze]
  s.date = "2023-07-02"
  s.email = "andrew@ankane.org".freeze
  s.homepage = "https://github.com/ankane/authtrail".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 3".freeze)
  s.rubygems_version = "3.4.10".freeze
  s.summary = "Track Devise login activity".freeze

  s.installed_by_version = "3.7.2".freeze

  s.specification_version = 4

  s.add_runtime_dependency(%q<railties>.freeze, [">= 6.1".freeze])
  s.add_runtime_dependency(%q<warden>.freeze, [">= 0".freeze])
end
