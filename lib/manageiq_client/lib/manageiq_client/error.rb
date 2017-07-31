module ManageIQClient
  class Error < StandardError
    attr_reader :status_code, :error_kind, :response_data

    def self.parse(error)
      data = nil
      message = nil
      status_code = nil
      error_kind = nil

      if error.respond_to? :response
        status_code = error.response.status
        unless error.response.body.empty?
          begin
            data = JSON(error.response.body)
            message = data['error']['message']
            error_kind = data['error']['kind']
          rescue
            message = error.response.body
            data = error.response.body
          end
        end
      elsif error.is_a? Excon::Error::Socket
        status_code = 503
        message = data = error.message
        error_kind = 'Server Unreachable'
      else
        status_code = 500
        message = data = error.message
        error_kind = 'Unexpected Client Error'
      end

      new_error(message, data, status_code, error_kind)
    end

    def self.new_error(message, data, status_code, error_kind)
      new_error = new(message)
      new_error.instance_variable_set(:@response_data, data)
      new_error.instance_variable_set(:@status_code, status_code)
      new_error.instance_variable_set(:@error_kind, error_kind)
      new_error
    end
  end
end
