require 'logger'

# This class is used to define a redis cache store that logs failures as warnings but does not raise errors for
# cache connections
class OptionalRedisCacheStore
  def initialize(namespace: nil, config: nil, logger: nil)
    @cache_store = RedisCacheStore.new(namespace, config)
    @logger = logger || Logger.new(STDOUT)
  end
  
  def redis_store
    @cache_store
  end

  # This method is called to configure the connection to the cache store.
  def configure(
    host = 'localhost',
    port = 6379,
    db = 'default',
    password = nil,
    driver: nil,
    url: nil,
    connect_timeout: 0.5,
    read_timeout: 1,
    write_timeout: 0.5)
    redis_store.configure(
      host,
      port,
      db,
      password,
      driver: driver,
      url: url,
      connect_timeout: connect_timeout,
      read_timeout: read_timeout,
      write_timeout: write_timeout
    )
  end

  def optional_get(key, expires_in = 0)
    redis_store.get(key, expires_in)
  rescue => e
    @logger.error(
      "[#{self.class}] - An error occurred requesting data from the cache. " \
"Key: #{key} | Error: #{e.message} | Backtrace: #{e.backtrace}"
    )
    nil
  end

  def get(key, expires_in = 0, &block)
    value = optional_get(key, expires_in)

    if value.nil? && block_given?
      value = yield
      set(key, value, expires_in)
    end

    value
  end

  def set(key, value, expires_in = 0)
    redis_store.set(key, value, expires_in)
  rescue => e
    @logger.error(
      "[#{self.class}] - An error occurred storing data in the cache. " \
"Key: #{key} | Error: #{e.message} | Backtrace: #{e.backtrace}"
    )
  end

  def remove(key)
    redis_store.remove(key)
  rescue => e
    @logger.error(
      "[#{self.class}] - An error occurred removing data from the cache. " \
"Key: #{key} | Error: #{e.message} | Backtrace: #{e.backtrace}"
    )
  end

  def exist?(key)
    redis_store.exist?(key)
  rescue => e
    @logger.error(
      "[#{self.class}] - An error occurred checking if a key exists in the cache. " \
"Key: #{key} | Error: #{e.message} | Backtrace: #{e.backtrace}"
    )
    false
  end

  def ping
    redis_store.ping
  rescue => e
    @logger.error(
      "[#{self.class}] - An error occurred checking pinging the cache. " \
"Error: #{e.message} | Backtrace: #{e.backtrace}"
    )
    false
  end
end
