module CloudForms
  class Provider < ::Provider
    belongs_to :provider_type

    credential :host
    credential :username
    credential :password, encrypted: true

    def self.credentials_schema(mode = :create)
      Dry::Validation.Schema(build: false) do
        required(:host, ApplicationRecord::Types::HOST).filled(format?: ApplicationRecord::Types::HOST_REGEXP)
        required(:username).filled(:str?)
        if mode == :create
          required(:password).filled(:str?)
        else
          optional(:password).value(:str?)
        end
      end
    end

    def sync_provider_data
      # Things we care about
      # 1. Providers (those without a parent_id), name, description, guid, id
      # 2. Templates, name, description, id, ems_id, deprecated
      # 3. Flavors, name, description, id, ems_id, deprecated

      # Going to store ALL of the records we find into this and use `.assoc` to match against existing rows
      @data = []

      # Get and loop over each provider; We only care about collecting data for active providers
      provider_query = '?expand=resources&attributes=id,name,provider_region,description,type,guid,last_refresh_date&filter[]=parent_ems_id=null'
      client.providers.paginate provider_query do |provider_result|
        provider_type = provider_types[provider_result[:type]]

        # Only sync supported provider types
        next unless provider_type

        # TODO: Use last_refresh_date to skip syncing a provider that doesn't need refreshing

        # Decorate AWS as govcloud when the region contains /gov/
        if provider_type == 'aws' && provider_result[:provider_region][/gov/]
          provider_type = 'awsgov'
        end

        @data << [[:provider, provider_result[:id].to_s], {
          name: provider_result[:name],
          description: provider_result[:description],
          properties: { guid: provider_result[:guid], type: provider_type }
        }]

        fetch_templates
        fetch_flavor
        start_transaction

        true
      end
    end

    def fetch_templates
      # Get the templates for the provider
      template_query = "?expand=resources&attributes=id,name,description,guid,deprecated,connection_state&filter[]=ems_id=#{provider_result[:id]}"
      client.templates.paginate template_query do |template_result|
        record_data = {
          name: template_result[:name],
          description: template_result[:description],
          ext_group_id: provider_result[:id],
          properties: { guid: template_result[:guid] }
        }

        # determine deprecation status
        record_data[:deprecated] = case provider_type
                                   when 'google'
                                     template_result[:deprecated]
                                   when 'vmware'
                                     template_result[:connection_state] != 'connected'
                                   else
                                     template_result.fetch(:deprecated, false)
                                   end

        @data << [[:template, template_result[:id].to_s], record_data]
      end
    end

    def fetch_flavor
      # Get the flavors for the provider
      flavor_query = "?expand=resources&attributes=id,name,description,enabled&filter[]=ems_id=#{provider_result[:id]}"
      client.flavors.paginate flavor_query do |flavor_result|
        @data << [[:flavor, flavor_result[:id].to_s], {
          name: flavor_result[:name],
          description: flavor_result[:description],
          ext_group_id: provider_result[:id],
          deprecated: !flavor_result[:enabled]
        }]
      end
    end

    def start_transaction
      # Start our transaction to isolate flubs
      Provider.transaction do
        provider_data_defaults = { available: true, deprecated: false, properties: {} }

        # Get our providers data in chunks; We've got an unknown amount of data in memory already
        ProviderData.where(provider_id: id).find_each(batch_size: 100) do |provider_data|
          # Locate our new or updated data using `.assoc`
          row_data = data.assoc([provider_data.data_type.to_sym, provider_data.ext_id])

          # Disable any rows we don't have data for
          unless row_data
            provider_data.update available: false
            next
          end

          provider_data.update provider_data_defaults.merge(row_data[1])

          # Mark the row so later when we create the new rows it'll be skipped
          row_data[0] = false
        end

        # Add on the provider.id to the defaults hash
        provider_data_defaults[:provider_id] = id

        # Find and create any rows we haven't already used in an update
        @data.each do |(type_id, row_data)|
          # Skip updated rows
          next unless type_id
          ProviderData.create provider_data_defaults.merge(row_data.merge(data_type: type_id[0].to_s, ext_id: type_id[1]))
        end
      end
    end

    def valid_credentials?
      client.reconnect
    end

    def client
      @client ||= ManageIQClient::Client.new host: host, username: username, password: password, connection_options: { ssl_verify_peer: false }
    end

    # Basic type mapping; PJ will support creating VMs on the following types
    def provider_types
      {
        'ManageIQ::Providers::Google::CloudManager' => 'google',
        'ManageIQ::Providers::Amazon::CloudManager' => 'aws',
        'ManageIQ::Providers::Azure::CloudManager' => 'azure',
        'ManageIQ::Providers::Vmware::InfraManager' => 'vmware'
      }
    end
  end
end
