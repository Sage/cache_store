require 'cache_store_redis/version'
require 'redis'
require 'securerandom'
require 'connection_pool'

#This class is used to implement a redis cache store.
#This class is used for interacting with a redis based cache store.
class RedisCacheStore

  def self.pool(config)
    @pool ||= ConnectionPool.new(size: pool_size, timeout: pool_timeout) do
      if config == nil
        Redis.new
      else
        Redis.new(config)
      end
    end
  end

  def self.pool_size
    @pool_size ||= Integer(ENV['CACHE_STORE_POOL_SIZE'] || 20)
  end

  def self.pool_timeout
    @pool_size ||= Integer(ENV['CACHE_STORE_POOL_TIMEOUT'] || 1)
  end

  def initialize(namespace = nil, config = nil)

    if RUBY_PLATFORM != 'java'
      require 'oj'
    end

    @namespace = namespace
    @config = config
  end

  def with_client
    self.class.pool(@config).with do |client|
      yield client
    end
  end

  #This method is called to configure the connection to the cache store.
  def configure(host = 'localhost', port = 6379, db = 'default', password = nil, driver: nil, url: nil)
    if url != nil
      @config = {}
      @config[:url] = url
      @config[:db] = db
    else
      @config = { :host => host, :port => port, :db => db }
    end
    if password != nil
      @config[:password] = password
    end
    if driver != nil
      @config[:driver] = driver
    end
  end

  #This method is called to set a value within this cache store by it's key.
  #
  # @param key [String] This is the unique key to reference the value being set within this cache store.
  # @param value [Object] This is the value to set within this cache store.
  # @param expires_in [Integer] This is the number of seconds from the current time that this value should expire.
  def set(key, value, expires_in = 0)
    v = nil
    k = build_key(key)

    if value != nil
      v = serialize(value)
    end

    with_client do |client|
      client.multi do
        client.set(k, v)

        if expires_in > 0
          client.expire(k, expires_in)
        end
      end
    end

  end

  #This method is called to get a value from this cache store by it's unique key.
  #
  # @param key [String] This is the unique key to reference the value to fetch from within this cache store.
  # @param expires_in [Integer] This is the number of seconds from the current time that this value should expire. (This is used in conjunction with the block to hydrate the cache key if it is empty.)
  # @param &block [Block] This block is provided to hydrate this cache store with the value for the request key when it is not found.
  # @return [Object] The value for the specified unique key within the cache store.
  def get(key, expires_in = 0, &block)

    k = build_key(key)

    value = with_client do |client|
      client.get(k)
    end

    value = deserialize(value) unless value == nil

    if value.nil? && block_given?
      value = yield
      set(k, value, expires_in)
    end

    return value
  end

  # This method is called to remove a value from this cache store by it's unique key.
  #
  # @param key [String] This is the unique key to reference the value to remove from this cache store.
  def remove(key)
    with_client do |client|
      client.del(build_key(key))
    end
  end

  # This method is called to check if a value exists within this cache store for a specific key.
  #
  # @param key [String] This is the unique key to reference the value to check for within this cache store.
  # @return [Boolean] True or False to specify if the key exists in the cache store.
  def exist?(key)
    with_client do |client|
      client.exists(build_key(key))
    end
  end

  # Ping the cache store.
  #
  # @return [String] `PONG`
  def ping
    with_client do |client|
      client.ping
    end
  end


  private

  def serialize(object)
    if RUBY_PLATFORM == 'java'
      Marshal::dump(object)
    else
      Oj.dump(object)
    end
  end

  def deserialize(object)
    if RUBY_PLATFORM == 'java'
      Marshal::load(object)
    else
      Oj.load(object)
    end
  end

  def build_key(key)
    k = ''
    if @namespace != nil
      k = @namespace + ':' + key.to_s
    elsif
      k = key.to_s
    end
    k
  end

end
