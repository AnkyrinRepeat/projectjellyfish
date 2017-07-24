class ServiceRequest < ApplicationRecord
  class BuildServiceJob < ApplicationJob
    def perform(service_request_id)
      result = ServiceRequest::BuildService.run(context: nil, params: { id: service_request_id })

      if result.valid?
        # Do something
      end
    end
  end
end
