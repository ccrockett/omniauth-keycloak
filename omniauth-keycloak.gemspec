require File.expand_path("../lib/keycloak/version", __FILE__)
Gem::Specification.new do |spec|
  spec.name          = "omniauth-keycloak"
  spec.version       = Omniauth::Keycloak::VERSION
  spec.authors       = ["Cameron Crockett"]
  spec.email         = ["cameron.crockett@ccrockett.com"]
  
  spec.description   = %q{"Omniauth strategy for Keycloak"}
  spec.summary       = spec.description
  spec.homepage      = "https://github.com/ccrockett/omniauth-keycloak"
  spec.license       = "MIT"
  spec.required_rubygems_version = '>= 1.3.5'
  spec.required_ruby_version = '>= 2.2'

  spec.require_paths = ["lib"]
  gem.executables   = `git ls-files -- bin/*`.split("\n").collect { |f| File.basename(f) }
  gem.files         = `git ls-files`.split("\n")
  gem.test_files = `git ls-files -- {test,spec,features}/*`.split("\n")
  
  spec.add_dependency "omniauth", "~> 1.8.1"
  spec.add_dependency "omniauth-oauth2", "~> 1.5.0"
  spec.add_dependency "json-jwt", "~> 1.9.4"
  spec.add_development_dependency "bundler", "~> 1.16"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency 'simplecov', '~> 0.16.1'
  spec.add_development_dependency 'webmock', '~> 3.4.2'
end
