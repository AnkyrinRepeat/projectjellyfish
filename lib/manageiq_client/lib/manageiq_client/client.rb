module ManageIQClient
  class Client
    extend BasicRequest

    attr_reader :host, :base_path

    basic_request :discover, uri: ''
    basic_request :auth

    def initialize(options = {})
      @host = options[:host] || 'https://localhost'
      @base_path = options[:base_path] || ManageIQClient::BASE_PATH
      @headers = options[:headers] || ManageIQClient::HEADERS
      @authentication_method = options[:authentication_method] || :basic_auth # Also accept :token_auth
      if @authentication_method == :token_auth
        raise 'Missing token for authentication' if options[:token].nil?
        @token = options[:token]
      else
        # raise 'Missing credentials for authentication' if options[:username].nil? || options[:password].nil?
        @username = options[:username] || 'admin'
        @password = options[:password] || 'smartvm'
      end

      @connection_options = options[:connection_options] || {}

      discover_api
    end

    def reconnect
      @connection = nil
      discover_api
    end

    private

    attr_reader :collections

    def request(options)
      options[:uri] = [@base_path, options[:uri]].compact.join('/').sub(%r{/\z}, '')
      connection.request options
    end

    def connection
      @connection ||= Connection.new(host, connection_options)
    end

    def connection_options
      @connection_options.merge({}.tap do |o|
        if @authentication_method == :basic_auth
          o[:user] = @username
          o[:password] = @password
          o[:headers] = @headers
        else
          o[:headers] = @headers.merge 'X-Auth-Token' => @token
        end

        o[:base_path] = @base_path
        o[:read_timeout] = ManageIQClient::READ_TIMEOUT
        o[:write_timeout] = ManageIQClient::WRITE_TIMEOUT
      end)
    end

    def discover_api
      @collections = {}

      # TODO: call gets more than just collections
      discover['collections'].each do |data|
        name = data['name'].to_sym
        collection = Collection.new(connection, data)
        self.class.send :define_method, name do
          collections[name] ||= collection.discover_api
        end
      end
    end
  end
end
