class ServiceOrder < ApplicationRecord
  class Recount < ApplicationService
    include Model

    model ServiceOrder, :find

    def perform
      groups = model.service_requests.group_by(&:state)

      model.approved_count = groups['approved'].length if groups.key? 'approved'
      model.denied_count = groups['denied'].length if groups.key? 'denied'

      if model.approved_count + model.denied_count == model.ordered_count
        model.complete!
      end

      model.save
    end
  end
end
