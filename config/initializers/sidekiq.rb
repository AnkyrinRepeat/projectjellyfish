url = if ENV.key? 'REDIS_URL'
        ENV['REDIS_URL']
      elsif ENV.key? 'REDIS_HOST'
        "redis://#{ENV['REDIS_HOST']}:#{ENV.fetch('REDIS_PORT', 6379)}"
      else
        'redis://127.0.0.1:6379'
      end

redis_config = { url: url }
# Namespace the queues for app and environment
queues = %W(api_#{Rails.env}_default api_#{Rails.env}_mailers)

Sidekiq.configure_server do |config|
  config.redis = redis_config
  config.options[:queues] = queues
end

Sidekiq.configure_client do |config|
  config.redis = redis_config
  config.options[:queues] = queues
end
