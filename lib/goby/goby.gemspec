# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'goby/version'

Gem::Specification.new do |spec|
  spec.name          = 'goby'
  spec.version       = Goby::VERSION
  spec.authors       = ['Michael Stack']
  spec.email         = ['michael.stack@gmail.com']

  spec.summary       = 'Goby, a service object based JSON-API implementation for Rails'
  spec.description   = 'Goby are cleaner fish, and like a cleaner fish this gem helps to clean up your models and controller of complicated business logic.'
  spec.homepage      = 'https://github.com/boozallen/goby'

  # # Prevent pushing this gem to RubyGems.org by setting 'allowed_push_host', or
  # # delete this section to allow pushing this gem to any host.
  # if spec.respond_to?(:metadata)
  #   spec.metadata['allowed_push_host'] = "TODO: Set to 'http://mygemserver.com'"
  # else
  #   raise "RubyGems 2.0 or newer is required to protect against public gem pushes."
  # end

  spec.files         = Dir['lib/**/*.rb']
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'kaminari', '~> 0.17.0'
  spec.add_dependency 'activesupport', '~> 5.0'
  spec.add_dependency 'dry-validation', '~> 0.10'
  spec.add_dependency 'dry-types', '~> 0.9'

  spec.add_development_dependency 'bundler', '~> 1.11'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'minitest', '~> 5.0'
  spec.add_development_dependency 'pry'
end
