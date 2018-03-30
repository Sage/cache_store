class RedisConnection
  attr_accessor :created
  attr_accessor :client

  def initialize(config)
    self.client = Redis.new(config)
    self.created = Time.now
  end

  # This method is called to determine if this connection has been open for longer than the keep alive timeout or not.
  def expired?
    return false if self.created.nil?
    Time.now >= (self.created + keep_alive_timeout)
  end

  def open
    self.created = Time.now if self.created.nil?
  end

  def close
    self.client.close
    self.created = nil
  end

  # This method is called to get the keep alive timeout value to use for this connection.
  def keep_alive_timeout
    Float(ENV['REDIS_KEEP_ALIVE_TIMEOUT'] ||  30)
  end
end
