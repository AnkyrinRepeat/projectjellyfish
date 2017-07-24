require 'rufus-scheduler'

scheduler = Rufus::Scheduler.new

# Limit scheduler to web processes only
if File.split($PROGRAM_NAME).last == 'puma'
  # # Provider connection checks
  # #
  # # 1. Find only connected providers
  # scheduler.every '10m', overlap: false do
  #   Provider.where(connected: true).pluck(:id).each do |provider_id|
  #     Provider::CheckCredentialsJob.perform_later provider_id
  #   end
  # end
  #
  # # Provider data sync
  # #
  # # 1. Find only connected providers
  # scheduler.every '20m', overlap: false do
  #   Provider.where(connected: true).pluck(:id, :last_synced_at).each do |provider_id, last_synced_at|
  #     ProviderData::SyncJob.perform_later provider_id, last_synced_at.to_s
  #   end
  # end

  scheduler.every '10s', overlap: false do
    # Provider connection checks, Provider data sync
    #
    # 1. Find only connected providers
    ten_minutes_ago = DateTime.current - 10.minutes
    twenty_minutes_ago = DateTime.current - 20.minutes
    Provider.where(connected: true).each do |provider|
      if provider.credentials_validated_at.nil? || provider.credentials_validated_at < ten_minutes_ago
        Provider::CheckCredentialsJob.perform_later(provider.id)
      end

      if provider.last_synced_at.nil? || provider.last_synced_at < twenty_minutes_ago
        ProviderData::SyncJob.perform_later(provider.id, provider.last_synced_at.to_s)
      end
    end

    # Monitor services
    #
    # 1. Find only services with connected providers
    # 2. That want to be monitored
    # 3. Have not been checked since `monitor_frequency` seconds ago
    # 4. And we've finished checking the service
    Service
      .select(:id, :updated_at)
      .joins(:provider)
      .merge(Provider.where(connected: true))
      .where('monitor_frequency != 0')
      .where("last_checked_at <= current_timestamp - monitor_frequency * INTERVAL '1 seconds' AND last_checked_at >= services.updated_at")
      .pluck(:id, :updated_at)
      .each do |service_id, updated_at|
      Service::State::CheckJob.perform_later service_id, updated_at.to_s
    end

    # Check for any delayed requests that can now be provisioned
    #
    # 1. Find service requests that are :delayed
    # 2. That belong to providers which are connected
    ServiceRequest
      .select(:id)
      .joins(:provider)
      .merge(Provider.where(connected: true))
      .with_state(:delayed)
      .each do |service_request|
      ServiceRequest::UnstickJob.perform_later(service_request.id)
    end
  end
end
