module Goby
  class Config
    attr_reader :message_paths, :default_page_size, :max_page_size, :related_links, :include_backtraces

    def initialize(message_paths, default_page_size, max_page_size, related_links, include_backtraces)
      @message_paths = message_paths || []
      @default_page_size = default_page_size || nil
      @max_page_size = max_page_size || nil
      @related_links = related_links || true
      @include_backtraces = include_backtraces || false
    end
  end
end
