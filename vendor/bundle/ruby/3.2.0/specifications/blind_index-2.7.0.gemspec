# -*- encoding: utf-8 -*-
# stub: blind_index 2.7.0 ruby lib

Gem::Specification.new do |s|
  s.name = "blind_index".freeze
  s.version = "2.7.0".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Andrew Kane".freeze]
  s.date = "1980-01-02"
  s.email = "andrew@ankane.org".freeze
  s.homepage = "https://github.com/ankane/blind_index".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 3.2".freeze)
  s.rubygems_version = "3.6.7".freeze
  s.summary = "Securely search encrypted database fields".freeze

  s.installed_by_version = "3.7.2".freeze

  s.specification_version = 4

  s.add_runtime_dependency(%q<activesupport>.freeze, [">= 7.1".freeze])
  s.add_runtime_dependency(%q<argon2-kdf>.freeze, [">= 0.2".freeze])
end
