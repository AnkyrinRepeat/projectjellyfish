module CloudForms
  module Vm
    class Service < ::Service
      state_machine :state do
        event :done do
          transition provisioning: :powered_on, if: :vm_on?
          transition provisioning: :powered_off
          transition powering_on: :powered_on
          transition powering_off: :powered_off
          transition rebooting: :powered_on, if: :vm_on?
          transition rebooting: :powered_off
          transition deprovisioning: :deprovisioned
        end

        event :deprovision do
          transition to: :deprovisioning
        end

        event :power_on do
          transition [:provisioned, :powered_off] => :powering_on, unless: :vm_on?
          transition [:provisioned, :powered_off] => :powered_on
        end

        event :power_off do
          transition [:provisioned, :powered_on] => :powering_off, unless: :vm_off?
          transition [:provisioned, :powered_on] => :powered_off
        end

        event :reboot do
          transition [:provisioned, :powered_on] => :rebooting
        end

        after_transition to: :powering_on, do: :start_powering_on
        after_transition to: :powering_off, do: :start_powering_off
        after_transition to: :rebooting, do: :start_rebooting
        after_transition to: :deprovisioning, do: :start_deprovisioning

        state :powered_on
        state :powered_off
      end

      def monitor_frequency_for(state)
        case state.to_sym
        when :powered_on, :powered_off
          60
        when :provisioning, :deprovisioning, :powering_on, :powering_off, :rebooting
          10
        else
          super
        end
      end

      def billable_for(state)
        case state.to_sym
        when :pending
          super
        when :deprovisioned
          false
        else
          true
        end
      end

      def self.combine_settings(product_settings, user_settings)
        product_settings.merge(user_settings)
      end

      def build_provision_request
        inputs = settings

        vm_fields = case ext_provider_type
                    when :google
                      {
                        instance_type: inputs['flavor_ext_id'].to_i,
                        boot_disk_size: inputs['disk_size_gb']
                      }
                    when :aws, :azure, :awsgov
                      {
                        instance_type: inputs['flavor_ext_id'].to_i
                      }
                    else
                      {}
                    end

        vm_fields[:vm_name] = generate_vm_name ext_provider_type

        {
          body: {
            resource: {
              version: '1.1',
              template_fields: {
                guid: ext_template.properties['guid']
              },
              vm_fields: vm_fields,
              requester: {
                owner_first_name: 'Project',
                owner_last_name: 'Jellyfish',
                owner_email: user.email
              },
              tags: {},
              ems_custom_attributes: {},
              miq_custom_attributes: {}
            }
          }
        }
      end

      def start_provisioning
        response = provider.client.provision_requests.create build_provision_request
        results = response['results'].first
        self.status_message = results['message']
        details['provision_request_id'] = results['id']
      rescue => error
        errored!
        self.status_message = error.message
      ensure
        save if changed?
      end

      def check_provisioning_status
        # TODO: Should consider some kind of timeout
        while provisioning?
          sleep 5 # TODO: sleeping? maybe a block taking method with yield with options might be better
          results = provider.client.provision_requests.find "#{details['provision_request_id']}?expand=tasks"
          update_attributes status_message: results['message']
          raise results['message'] if results['status'].casecmp('error').zero?

          next unless results.key? 'tasks'

          task = results['tasks'].last
          raise task['message'] if task['status'].casecmp('error').zero?

          # downcase to avoid '[fF]inished'
          next unless results['request_state'].casecmp('finished').zero?
          details['instance_id'] = task['destination_id']
          update_status
          done!
        end
      rescue => error
        errored!
        self.status_message = error.message
      ensure
        save if changed?
      end

      def start_deprovisioning
        # Already retired? We're done.
        if details['retired']
          done!
          return
        end

        terminate_results = case ext_provider_type
                            when :vmware, :awsgov
                              provider.client.vms.retire details['instance_id']
                            else
                              provider.client.instances.terminate details['instance_id']
                            end

        self.status_message = terminate_results['message']

        details['terminate_task_id'] = terminate_results['task_id']
      rescue => error
        errored!
        self.status_message = error.message
      ensure
        save if changed?
      end

      def check_deprovisioning_status
        # TODO: Should consider some kind of timeout
        while deprovisioning?
          sleep 5 # TODO: needs DRYing

          if details['terminate_task_id']
            task = provider.client.tasks.find details['terminate_task_id']

            # task['status'] could be 'Error'; Needs handling
            if task['state'].casecmp('finished').zero?
              update_status
              self.status_message = task['message']
            end
          elsif [:vmware, :awsgov].include? ext_provider_type
            # TODO: Find out what methods are available to follow the retirement for vms
            update_status
          end
        end
      rescue => error
        errored!
        self.status_message = error.message
      ensure
        save if changed?
      end

      def check_powered_on_status
        update_status
      end

      alias check_powered_off_status check_powered_on_status

      def start_powering_on
        if vm_on?
          done!
          return
        end

        task_results = case ext_provider_type
                       when :vmware, :awsgov
                         provider.client.vms.start details['instance_id']
                       else
                         provider.client.instances.start details['instance_id']
                       end
        self.status_message = task_results['message']
        details['power_on_task_id'] = task_results['task_id']
      rescue => error
        errored!
        self.status_message = error.message
      ensure
        save if changed?
      end

      def check_powering_on_status
        while powering_on?
          sleep 5

          update_status

          done! if vm_on?
        end
      end

      def start_powering_off
        if vm_off?
          done!
          return
        end

        task_results = case ext_provider_type
                       when :vmware, :awsgov
                         provider.client.vms.stop details['instance_id']
                       else
                         provider.client.instances.stop details['instance_id']
                       end

        self.status_message = task_results['message']

        details['power_off_task_id'] = task_results['task_id']
      end

      def check_powering_off_status
        while powering_off?
          sleep 5

          update_status

          done! if vm_off?
        end
      end

      def do_reboot
      end

      def check_rebooting_status
      end

      def vm_on?
        details['power_state'] == 'on'
      end

      def vm_off?
        details['power_state'] == 'off'
      end

      private

      def update_status
        attributes = 'disks,provisioned_storage,ipaddresses,mem_cpu,num_cpu,cpu_total_cores,cpu_cores_per_socket,retirement_status'
        instance_details = case ext_provider_type
                           when :vmware, :awsgov
                             provider.client.vms.find "#{details['instance_id']}?attributes=#{attributes}"
                           else
                             provider.client.instances.find "#{details['instance_id']}?attributes=#{attributes}"
                           end

        details['name'] = instance_details['name']
        details['vendor'] = instance_details['vendor']
        details['power_state'] = instance_details['power_state'].downcase
        ips = partition_ips instance_details['ipaddresses']
        details['public_ips'] = ips[1].sort
        details['private_ips'] = ips[0].sort
        details['disk_size'] = instance_details['provisioned_storage'].to_i / 1024 / 1024 # Returns in B, reduce to in MB
        details['memory'] = instance_details['mem_cpu']
        details['cpu_count'] = instance_details['num_cpu']
        details['core_count'] = instance_details['cpu_total_cores']
        details['retired'] = instance_details.fetch('retired', false) || instance_details['raw_power_state'].casecmp('deleted').zero? || instance_details.fetch('retirement_status', 'active')[/retir/]

        details_will_change!

        case details['power_state']
        when 'on'
          power_on
        when 'off'
          power_off
        when 'unknown'
          details['retired'] = true
          power_off
        end

        if details['retired']
          deprovision
        end

        save
      end

      def generate_vm_name(provider_type)
        case provider_type
        when :azure
          # AFAICT Azure has the most restrictive server name rules. 15 alphanumeric and -_, must start and end with alpha
          ('pj-' + SecureRandom.base58(11) + ('a'..'z').to_a.sample)
        else
          ('pj-' + SecureRandom.hex(8))
        end
      end

      def partition_ips(ips)
        ips.partition do |ip|
          octets = ip.split('.').map(&:to_i)

          (octets[0] == 10) ||
            ((octets[0] == 172) && (octets[1] >= 16) && (octets[1] <= 31)) ||
            ((octets[0] == 192) && (octets[1] == 168))
        end
      end

      # Some helper methods that make determining what actions or external calls to make easier.

      def ext_provider
        @_ext_provider ||= ProviderData.find_by(provider_id: provider_id, ext_id: settings['provider_ext_id'], data_type: 'provider')
      end

      def ext_provider_type
        @_ext_provider_type ||= ext_provider.properties['type'].to_sym
      end

      def ext_template
        @_ext_template ||= ProviderData.find_by(provider_id: provider_id, ext_id: settings['template_ext_id'], data_type: 'template')
      end
    end
  end
end
