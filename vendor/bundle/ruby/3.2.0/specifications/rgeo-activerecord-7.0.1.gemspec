# -*- encoding: utf-8 -*-
# stub: rgeo-activerecord 7.0.1 ruby lib

Gem::Specification.new do |s|
  s.name = "rgeo-activerecord".freeze
  s.version = "7.0.1".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Daniel Azuma".freeze, "Tee Parham".freeze]
  s.date = "2021-02-23"
  s.description = "RGeo is a geospatial data library for Ruby. RGeo::ActiveRecord is an optional RGeo module providing some spatial extensions to ActiveRecord, as well as common tools used by RGeo-based spatial adapters.".freeze
  s.email = ["dazuma@gmail.com".freeze, "parhameter@gmail.com".freeze, "kfdoggett@gmail.com".freeze]
  s.homepage = "https://github.com/rgeo/rgeo-activerecord".freeze
  s.licenses = ["BSD-3-Clause".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.5.0".freeze)
  s.rubygems_version = "3.0.8".freeze
  s.summary = "An RGeo module providing spatial extensions to ActiveRecord.".freeze

  s.installed_by_version = "3.7.2".freeze

  s.specification_version = 4

  s.add_runtime_dependency(%q<activerecord>.freeze, [">= 5.0".freeze])
  s.add_runtime_dependency(%q<rgeo>.freeze, [">= 1.0.0".freeze])
  s.add_development_dependency(%q<appraisal>.freeze, ["~> 2.1".freeze])
  s.add_development_dependency(%q<ffi-geos>.freeze, ["~> 1.2".freeze])
  s.add_development_dependency(%q<minitest>.freeze, ["~> 5.8".freeze])
  s.add_development_dependency(%q<mocha>.freeze, ["~> 1.1".freeze])
  s.add_development_dependency(%q<rake>.freeze, ["~> 12.0".freeze])
  s.add_development_dependency(%q<rgeo-geojson>.freeze, [">= 1.0.0".freeze])
  s.add_development_dependency(%q<simplecov>.freeze, [">= 0.20.0".freeze])
end
