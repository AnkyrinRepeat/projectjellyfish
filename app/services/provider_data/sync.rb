class ProviderData < ApplicationRecord
  class Sync < ApplicationService
    include Sanitize
    include Model

    model Provider, :find

    sanitize do
      required(:provider_id, ApplicationRecord::Types::UUID).filled
      required(:last_synced_at, :string)
    end

    def perform
      return unless model.last_synced_at.to_s == params[:last_synced_at]

      # timeout_seconds as 0 so that it will try to lock once, if the job is running the block will be skipped
      ProviderData.with_advisory_lock("provider-data-sync-#{model.id}", timeout_seconds: 0) do
        model.sync_provider_data
      end
      # rescue
      # TODO: Handle failure; log it, reschedule it, ...
      # If it failed to sync don't try again.
    ensure
      # Update the providers timestamp regardless; avoids piling on failures into the queue
      model.update last_synced_at: DateTime.current
    end

    private

    def model_id
      params[:provider_id]
    end
  end
end
