# This script provisions a VMWare VM and
# gets an IP address for it

require 'rbvmomi'
require 'net/http'
require 'uri/http'
require 'json'

def send_order_status(status, order_id, information, message = '')
  host = 'jellyfish-core-dev.dpi.bah.com'
  path = "/order_items/#{order_id}/provision_update"
  url = "http://#{host}#{path}"
  uri = URI.parse(url)

  information = information.merge('provision_status' => status.downcase)
  $evm.log('info', "send_order_status: Information: #{information}")
  json = {
    status: "#{status}",
    message: "#{message}",
    info: information
  }
  $evm.log('info', "send_order_status: Information #{json}")
  begin
    http = Net::HTTP.new(uri.host, uri.port)
    request = Net::HTTP::Put.new(uri.path)
    request.content_type = 'application/json'
    request.body = json.to_json
    response = http.request(request)
    $evm.log('info', "send_order_status: HTTP Response code: #{response.code}")
    $evm.log('info', "send_order_status: HTTP Response message: #{response.message}")
  rescue HTTPExceptions => e
    $evm.log('error', "send_order_status: HTTP Exception caught while sending response back to core: #{e.message}")
  rescue StandardError => e
    $evm.log('error', "send_order_status: Exception caught while sending response back to core: #{e.message}")
  end
end # End of function

# Retrieve all information set from the marketplace
product_details = $evm.root['dialog_product_details']
$evm.log('info', "CreateVMWareVM: Product Details: #{product_details}")
product_hash = JSON.parse(product_details.gsub("'", '"').gsub('=>', ':'))
datacenter = product_hash['datacenter']
host = product_hash['host']
port = Integer(product_hash['port']) unless product_hash['port'].nil || product_hash[port] == ''
user = product_hash['user']
password = product_hash['password']
template = product_hash['template']
spec_name = product_hash['spec_name']
uuid = product_hash['uuid']
order_id = product_hash['id']
instance_name = product_hash['instance_name']
info = {
  'id' => order_id,
  'uuid' => uuid
}

begin
  $evm.log('info', 'CreateVMWareVM: Begin')
  vim = RbVmomi::VIM.connect host: host, port: port, user: user, password: password, insecure: false
  dc = vim.serviceInstance.find_datacenter(datacenter)
  $evm.log('info', 'CreateVMWareVM: Found datacenter #{datacenter}')
  clone_vm = dc.find_vm(template)
  if clone_vm.nil?
    send_order_status('CRITICAL', order_id,  info, 'Could not find VM')
    exit
  end
  configuration = RbVmomi::VIM.VirtualMachineConfigSpec(annotation: 'Creation time:  ' + Time.now.strftime('%Y-%m-%d %H:%M') + "\n\n")
  hosts = dc.hostFolder.children
  pool = hosts.first.resourcePool
  relocation_spec = RbVmomi::VIM.VirtualMachineRelocateSpec(pool: pool)
  custom_spec = vim.serviceContent.customizationSpecManager.GetCustomizationSpec(name: spec_name).spec
  if custom_spec.nil?
    send_order_status('CRITICAL', order_id,  info, 'Could not find specified spec file')
    exit
  end
  clone_spec =  RbVmomi::VIM.VirtualMachineCloneSpec(
    location: relocation_spec,
    config: configuration,
    customization: custom_spec,
    powerOn: true,
    template: false
  )
  task = clone_vm.CloneVM_Task(folder: clone_vm.parent, name: instance_name, spec: clone_spec)
  task.wait_for_completion
  created_vm = dc.find_vm(instance_name)
  # Get information about the VM to pass back
  ip_address = created_vm.guest.ipAddress
  guest_family = created_vm.guest.guestFamily
  info = {
    'id' => order_id,
    'uuid' => uuid,
    'ip_address' => ip_address,
    'guest_family' => guest_family
  }
  send_order_status('OK', order_id,  info, '')
rescue StandardError => e
  $evm.log('error', "CloneVM: General exception caught: #{e.message}")
  send_order_status('CRITICAL', order_id,  info, "Exception caught while creating VM: #{e.message}")
  exit
end
