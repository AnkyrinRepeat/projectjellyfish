#
# Cache is disabled by default in development
#
# To enable MemoryStore caching create the file 'caching-dev.txt' under tmp
# `touch tmp/caching-dev.txt`
#
# You may need to stop spring if it does not appear to be using the cache store
# `spring stop`
#
# Memory cache exists only as long as the process is running; stopping and restarting
# the application will wipe the cache

#
# YOU'VE BEEN WARNED : DO NOT ENABLE REDIS CACHE IN DEVELOPMENT
#

redis_config = {}
redis_config[:namespace] = 'api:cache'
redis_config[:expires_in] = 1.week

redis_config[:url] = if ENV.key? 'REDIS_URL'
                       ENV['REDIS_URL']
                     elsif ENV.key? 'REDIS_HOST'
                       "redis://#{ENV['REDIS_HOST']}:#{ENV.fetch('REDIS_PORT', 6379)}"
                     else
                       'redis://127.0.0.1:6379'
                     end

Server::Application.config.cache_store = :redis_store, redis_config
