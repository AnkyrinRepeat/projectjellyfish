class ProductType < ApplicationRecord
  # Helpful defaults for ProductTypes which are servers/vms/computes
  class Vm < ::ProductType
    def properties
      [
        { name: 'CPUs', value: '' },
        { name: 'Memory', value: '' },
        { name: 'Storage', value: '' },
        { name: 'OS', value: '' }
      ]
    end

    def tag_list
      %w(server virtual-machine)
    end
  end
end
