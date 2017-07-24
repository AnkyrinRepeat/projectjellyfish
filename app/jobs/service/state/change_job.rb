class Service < ApplicationRecord
  module State
    class ChangeJob < ApplicationJob
      MAX_TRIES = 5

      rescue_from StandardError do |error|
        if retries_count < MAX_TRIES
          retry_job wait: WAIT**retries_count
        else
          raise error
        end
      end

      def perform(service_id, action)
        Service::State::Change.run(context: nil, params: { id: service_id, action: action })
      end
    end
  end
end
