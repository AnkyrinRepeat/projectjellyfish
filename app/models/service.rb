class Service < ApplicationRecord
  belongs_to :user
  belongs_to :provider
  belongs_to :product
  belongs_to :project
  belongs_to :service_request
  belongs_to :service_order

  state_machine :state, initial: :pending do
    event :provision do
      transition pending: :provisioning
    end

    event :done do
      # Required: Define service transitions in your service to standardize the completion of any work.
    end

    event :errored do
      transition all - :error => :error
    end
    after_transition to: :error, do: :alert_email

    after_transition do |service, transition|
      service.monitor_frequency = service.monitor_frequency_for(transition.to)
      service.billable = service.billable_for(transition.to)
      service.last_changed_at = DateTime.current
      # Caching the actions makes them available to ServiceDetails results
      service.actions = (service.state_events - service.ignored_actions).join ','
    end

    after_transition to: :provisioning, do: :start_provisioning

    state :provisioned
    state :error
  end

  # Optional: Implement and call `+ super` in each service to exclude actions from being serialized
  def ignored_actions
    %i(errored done)
  end

  # Optional: Implement in each service to define default details
  def self.default_details
    {}
  end

  # Optional: Implement in each service to process settings as desired
  def self.combine_settings(product_settings, user_settings)
    {
      product: product_settings,
      user: user_settings
    }
  end

  # Optional: Implement in each service to process the service provisioning
  def start_provisioning
    done!
  end

  # Optional: Implement in each service to keep monitor_frequency at optimal rates
  def monitor_frequency_for(_state)
    0
  end

  # Optional: Implement in each service to keep billable updated
  def billable_for(_state)
    false
  end

  # Optional: Implement in each service to check the status of
  def check_status
    check_method = "check_#{state}_status".to_sym
    __send__ check_method if respond_to? check_method
  rescue => error
    errored!
    self.status_message = error.message
  ensure
    save if changed?
  end

  # TODO: unused?
  def connected?
    provider.connected? or (self.status_message = 'Actions cannot be taken while the service provider is disconnected' and false)
  end

  # All Services use the same serializer unless overridden
  def serializer_class_name
    'ServiceSerializer'
  end

  def alert_email
    ServiceMailer.error_alert(self).deliver_later
  end
end
