# coding: utf-8

lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'manageiq_client/version'

Gem::Specification.new do |spec|
  spec.name          = 'manageiq-client'
  spec.version       = ManageIQClient::VERSION
  spec.authors       = ['Michael Stack']
  spec.email         = ['stack_michael@bah.com']

  spec.summary       = 'ManageIQ API Client'
  spec.description   = 'ManageIQ API Client built using Excon.'
  spec.homepage      = 'https://github.com/boozallen/manageiq-client'

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = ''
  else
    raise 'RubyGems 2.0 or newer is required to protect against public gem pushes.'
  end

  spec.files         = Dir['lib/**/*.rb'] + Dir['bin/*']
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'excon', '~> 0.53.0'

  spec.add_development_dependency 'bundler', '~> 1.13'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'minitest', '~> 5.0'
end
