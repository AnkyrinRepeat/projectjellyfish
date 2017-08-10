require 'excon'

module ManageIQClient
  class Connection
    def initialize(host, options)
      @host = host
      @options = options
    end

    def request(uri:, headers: {}, expects: [200], method: 'GET', body: '', parse: true)
      # Convert the uri to a URI if it's a string.
      if uri.is_a?(String)
        uri = URI.parse(@host + uri)
      end

      # Include default headers
      headers = @options[:headers].merge headers

      # Make the request
      options = {
        expects: expects,
        method: method,
        path: uri.path + ("?#{uri.query}" if uri.query).to_s,
        headers: headers
      }

      if body.present?
        options[:body] = body
      end

      begin
        response = connection.request(options)
      rescue Excon::Errors::Error => error
        raise Error.parse error
      end

      return JSON(response.body) if parse

      response
    end

    def connection
      @connection ||= Excon.new(@host, @options)
    end
  end
end
