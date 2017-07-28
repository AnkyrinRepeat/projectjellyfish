module ManageIQClient
  class Client
    extend BasicRequest

    attr_reader :host, :base_path

    basic_request :discover, uri: ''
    basic_request :auth

    def initialize(options = {})
      @host = options[:host]
      @base_path = options[:base_path]
      @headers = options[:headers]
      @authentication_method = options[:authentication_method]
      if @authentication_method == :token_auth
        raise 'Missing token for authentication' if options[:token].nil?
        @token = options[:token]
      else
        # raise 'Missing credentials for authentication' if options[:username].nil? || options[:password].nil?
        @username = options[:username] || 'admin'
        @password = options[:password] || 'smartvm'
      end

      @connection_options = options[:connection_options]

      initialize_default
      discover_api
    end

    def initialize_default
      @host ||= 'https://localhost'
      @base_path ||= ManageIQClient::BASE_PATH
      @headers ||= ManageIQClient::HEADERS
      @authentication_method ||= :basic_auth # Also accept :token_auth
      @connection_options ||= {}
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
      @connection_options.merge({}.tap do |option|
        if @authentication_method == :basic_auth
          option[:user] = @username
          option[:password] = @password
          option[:headers] = @headers
        else
          option[:headers] = @headers.merge 'X-Auth-Token' => @token
        end

        option[:base_path] = @base_path
        option[:read_timeout] = ManageIQClient::READ_TIMEOUT
        option[:write_timeout] = ManageIQClient::WRITE_TIMEOUT
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
