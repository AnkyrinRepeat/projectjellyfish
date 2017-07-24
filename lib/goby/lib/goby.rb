require 'goby/version'
require 'active_support/concern'
require 'dry-validation'
require 'dry-types'

require 'goby/config'
require 'goby/error'
require 'goby/exceptions'

module Goby
  class << self
    attr_writer :config
  end

  def self.config
    @config ||= Config.new
  end

  def self.configure
    yield config
  end
end

require 'goby/service'
require 'goby/service/model'
require 'goby/service/policy'
require 'goby/service/sanitize'
require 'goby/service/validation'

require 'goby/request_parser'
require 'goby/response_extras'
# require 'goby/resource_links'
require 'goby/serializer'
require 'goby/controller'
require 'goby/railtie' if defined?(Rails)
