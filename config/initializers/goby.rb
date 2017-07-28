Goby.configure(
  [Rails.root.join('app', 'services', 'errors.yml')],
  20,
  100,
  false,
  false
)

Goby::Service.logger = Rails.logger
