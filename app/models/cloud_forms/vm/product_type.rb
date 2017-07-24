module CloudForms
  module Vm
    class ProductType < ::ProductType::Vm
      def default_settings
        super.merge(
          provider_ext_id: '',
          template_ext_id: '',
          flavor_ext_id: '',
          disk_size_gb: '',

                      # # TODO: old fields, remove
                      # guid: '',
                      # vm_fields: [],
                      # service_fields: [],
                      # tags: [],
                      # ems_attrs: [],
                      # miq_attrs: []
                    )
      end
    end
  end
end
