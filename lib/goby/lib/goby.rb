require 'goby/version'
require 'active_support/concern'
require 'dry-validation'
require 'dry-types'

require 'goby/config'
require 'goby/error'
require 'goby/exceptions'

module Goby
  class << self
    attr_reader :config
  end

  def self.configure(message_paths, default_page_size, max_page_size, related_links, include_backtraces)
    @config = Config.new(message_paths, default_page_size, max_page_size, related_links, include_backtraces)
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
