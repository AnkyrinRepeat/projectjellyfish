class Service < ApplicationRecord
  module State
    class Check < ApplicationService
      include Model
      include Sanitize

      model Service, :find

      sanitize do
        required(:updated_at, :string).filled(:str?)
      end

      def perform
        # TODO: Remove the next three lines after testing
        logger.info params[:updated_at]
        logger.info model.updated_at
        logger.info model.updated_at.to_s == params[:updated_at]

        # Only continue if the check isn't for an earlier version
        return unless model.updated_at.to_s == params[:updated_at]

        model.save
        model.check_status

        model.update last_checked_at: DateTime.current
      end
    end
  end
end
