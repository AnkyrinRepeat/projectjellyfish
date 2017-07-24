class ServiceRequest < ApplicationRecord
  class UnstickJob < ApplicationJob
    def perform(service_request_id)
      result = ServiceRequest::Unstick.run(context: nil, params: { id: service_request_id })

      if result.valid?
        # Do something
      end
    end
  end
end
