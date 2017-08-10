# Be sure to restart your server when you modify this file.

if Rails.env.production?
  Rails.application.config.assets.js_compressor = :uglifier
  Rails.application.config.assets.css_compressor = :sass
end

# Version of your assets, change this if you want to expire all your assets.
Rails.application.config.assets.version = (ENV['ASSETS_VERSION'] || '1.0')

# Precompile additional assets.
# application.js, application.css, and all non-JS/CSS in app/assets folder are already added.
Rails.application.config.assets.precompile.shift
Rails.application.config.assets.precompile += %w(libraries.js libraries.css)
Rails.application.config.assets.precompile.unshift(proc do |path, filename|
  filename.start_with?(Rails.root.join('app', 'assets').to_s) && !%w(.js .css .html .svg).include?(File.extname(path))
end)

Rails.application.config.assets.precompile += %w(.svg .png .jpg .gif)

# Angular Templates
Rails.application.config.angular_templates.ignore_prefix = %w(app/)
# Angular ng-strict-di happiness
Rails.application.config.ng_annotate.process = true
Rails.application.config.ng_annotate.ignore_paths = %w(/ruby/gems/ libraries.js)
