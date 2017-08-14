module CloudForms
  module Automation
    class ProductType < ::ProductType
      def default_settings
        {
          miq_namespace: '',
          miq_class: '',
          miq_instance: ''
        }
      end

      def tag_list
        %w(automation script)
      end
    end
  end
end
