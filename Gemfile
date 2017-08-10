source 'https://rubygems.org'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '~> 5.0.0', '>= 5.0.0.1'
# Use postgresql as the database for Active Record
gem 'pg', '~> 0.18'
gem 'pg_search', '~> 1.0.0' # Postgres Fulltext searching
gem 'scenic', '~> 1.3.0' # Postgres view management
gem 'with_advisory_lock', '~> 3.1.0' # Allow application level locks
# Use Puma as the app server
gem 'puma', '~> 3.0'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
# gem 'jbuilder', '~> 2.5'
# Use Redis adapter to run Action Cable in production
gem 'redis', '~> 3.0'
# Use ActiveModel has_secure_password
gem 'bcrypt', '~> 3.1.7'

# Simple ENV variables
gem 'dotenv-rails'

# Service parameter validation and schema verification
gem 'dry-validation'
gem 'goby', path: './lib/goby'
gem 'kaminari'

# Authentication (HTTP Token)
gem 'jwt'

# Cache & Job backend
gem 'redis-store'

# Jobs & Workers
gem 'rufus-scheduler'
gem 'sidekiq'

# Model additions
gem 'acts-as-taggable-on', '~> 4.0.0'
gem 'paranoia', '~> 2.2.0'
gem 'state_machines'
gem 'state_machines-activerecord', '~> 0.4.0'

# Used by provider clients
gem 'manageiq-client', path: './lib/manageiq_client'

# Use Rack CORS for handling Cross-Origin Resource Sharing (CORS), making cross-origin AJAX possible
gem 'rack-cors'

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug', platform: :mri
end

group :development do
  gem 'listen', '~> 3.0.5'
  gem 'pry-rails'
  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring'
  gem 'spring-commands-testunit'
  gem 'spring-watcher-listen', '~> 2.0.0'
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: %i[mingw mswin x64_mingw jruby]

group :test do
  gem 'minitest'
  gem 'minitest-rails'
  gem 'minitest-reporters'
  gem 'simplecov', require: false
  gem 'webmock'
end

#
# Client Gem includes; All of the following can be removed if the Server is no longer also serving the Client
#

# Also remove the following client additions
# - config/initializers/assets.rb
# - app/controllers/client_controller.rb
# - app/views/layouts/client.html.erb
# - app/views/client
# - app/assets
# - Client Routes from config/routes.rb

# Using assets; Serving the client as well as serving the API
gem 'mini_racer'
gem 'sprockets-rails'
# HTML
gem 'angular-rails-templates'
gem 'haml'
# CSS
# gem 'bootstrap-sass'
gem 'autoprefixer-rails'
gem 'font-awesome-rails'
gem 'sassc-rails'
# JavaScript
gem 'ngannotate-rails'
gem 'uglifier'
# UX dependencies
source 'https://rails-assets.org' do
  angular_version = '~> 1.5.0'

  gem 'rails-assets-angular', angular_version
  gem 'rails-assets-angular-animate', angular_version
  gem 'rails-assets-angular-aria', angular_version
  gem 'rails-assets-angular-chart.js', '~> 1.1.0'
  gem 'rails-assets-angular-loading-bar', '~> 0.9.0'
  gem 'rails-assets-angular-messages', angular_version
  gem 'rails-assets-angular-moment', '~> 1.0.0'
  gem 'rails-assets-angular-sanitize', angular_version
  gem 'rails-assets-angular-toastr', '~> 2.1.0'
  gem 'rails-assets-bulma', '~> 0.3.0'
  gem 'rails-assets-chart.js', '~> 2.4.0'
  gem 'rails-assets-moment', '~> 2.15.0'
  gem 'rails-assets-ng-dialog', '~> 0.6.0'
  gem 'rails-assets-ng-tags-input', '~> 3.1.0'
  gem 'rails-assets-satellizer', '~> 0.15.0'
end
