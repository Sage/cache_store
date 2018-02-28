# This class is used to implement a redis cache store.
class RedisCacheStore
  def initialize(namespace = nil, config = nil)
    unless RUBY_PLATFORM == 'java'
      require 'oj'
    end

    @namespace = namespace
    @config = config
    @queue = Queue.new

    @connections_created = 0
    @connections_in_use = 0
    @mutex = Mutex.new
    @enable_stats = false
  end

  def enable_stats=(value)
    @enable_stats = value
  end

  def increment_created_stat
    @mutex.synchronize do
      @connections_created += 1
    end
  end

  def increment_using_stat
    @mutex.synchronize do
      @connections_in_use += 1
    end
  end

  def decrement_using_stat
    @mutex.synchronize do
      @connections_in_use -= 1
    end
  end

  # This method is called to configure the connection to the cache store.
  def configure(host = 'localhost',
                port = 6379,
                db = 'default',
                password = nil,
                driver: nil,
                url: nil,
                connect_timeout: 0.5,
                read_timeout: 1,
                write_timeout: 0.5)
    if !url.nil?
      @config = {}
      @config[:url] = url
      @config[:db] = db
    else
      @config = { host: host, port: port, db: db }
    end

    @config[:password] = password unless password.nil?
    @config[:driver] = driver unless driver.nil?

    @config[:connect_timeout] = connect_timeout
    @config[:read_timeout] = read_timeout
    @config[:write_timeout] = write_timeout
  end

  def fetch_client
    begin
      @queue.pop(true)
    rescue
      increment_created_stat
      Redis.new(@config)
    end
  end

  def clean
    while @queue.length.positive?
      client = @queue.pop(true)
      client.close
    end
  end

  def log_stats
    return unless @enable_stats == true
    S1Logging.logger.debug do
      "[#{self.class}] - REDIS Connection Stats. Process: #{Process.pid} | " \
"Created: #{@connections_created} | Pending: #{@queue.length} | In use: #{@connections_in_use}"
    end
  end

  def with_client
    log_stats
    begin
      client = fetch_client
      increment_using_stat
      log_stats
      yield client
    ensure
      @queue.push(client)
      decrement_using_stat
      log_stats
    end
  end

  # This method is called to set a value within this cache store by it's key.
  #
  # @param key [String] This is the unique key to reference the value being set within this cache store.
  # @param value [Object] This is the value to set within this cache store.
  # @param expires_in [Integer] This is the number of seconds from the current time that this value should expire.
  def set(key, value, expires_in = 0)
    k = build_key(key)

    v = if value.nil? || (value.is_a?(String) && value.strip.empty?)
      nil
    else
      serialize(value)
    end

    with_client do |client|
      client.multi do
        client.set(k, v)

        client.expire(k, expires_in) if expires_in.positive?
      end
    end
  end

  # This method is called to get a value from this cache store by it's unique key.
  #
  # @param key [String] This is the unique key to reference the value to fetch from within this cache store.
  # @param expires_in [Integer] This is the number of seconds from the current time that this value should expire.
  # (This is used in conjunction with the block to hydrate the cache key if it is empty.)
  # @param &block [Block] This block is provided to hydrate this cache store with the value for the request key
  # when it is not found.
  # @return [Object] The value for the specified unique key within the cache store.
  def get(key, expires_in = 0, &block)
    k = build_key(key)

    value = with_client do |client|
      client.get(k)
    end

    if !value.nil? && value.strip.empty?
      value = nil
    else
      value = deserialize(value) unless value.nil?
    end

    if value.nil? && block_given?
      value = yield
      set(key, value, expires_in)
    end

    value
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
    if !@namespace.nil?
      @namespace + ':' + key.to_s
    else
      key.to_s
    end
  end
end
