# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'cache_store/version'

Gem::Specification.new do |spec|
  spec.name          = "cache_store"
  spec.version       = CacheStore::VERSION
  spec.authors       = ["vaughanbrittonsage"]
  spec.email         = ["vaughan.britton@sage.com"]

  spec.summary       = 'This is the base for a cache framework that includes a basic in memory cache store, along with a dependency contract for additional provider implementations plugins.'
  spec.description   = 'This is the base for a cache framework that includes a basic in memory cache store, along with a dependency contract for additional provider implementations plugins.'
  spec.homepage      = "https://github.com/vaughanbrittonsage/cache_store"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.11"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  
end
