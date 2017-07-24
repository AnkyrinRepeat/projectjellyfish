class ServiceOrder < ApplicationRecord
  class RecountJob < ApplicationJob
    def perform(service_order_id)
      result = ServiceOrder::Recount.run(context: nil, params: { id: service_order_id })

      if result.valid?
        # Do something
      end
    end
  end
end
