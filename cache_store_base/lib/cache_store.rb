require "cache_store/version"
require 'date'
require 'time'
#This class is used to define the contract that CacheStore implementations must adhere to.
class CacheStoreContract

  def initialize(namespace = '')
    @namespace = namespace
  end

  # This method is called to set a value within this cache store by its key.
  #
  # @param [String] This is the unique key to reference the value being set within this cache store.
  # @param [Object] This is the value to set within this cache store.
  # @param [Integer] This is the number of seconds from the current time that this value should expire.
  def set(key, value, expires_in = 0)

  end

  # This method is called to get a value from this cache store by its unique key.
  #
  # @param [String] This is the unique key to reference the value to fetch from within this cache store.
  # @param [Integer] This is the number of seconds from the current time that this value should expire. (This is used in conjunction with the block to hydrate the cache key if it is empty.)
  # @param [Block] This block is provided to hydrate this cache store with the value for the request key when it is not found.
  def get(key, expires_in = 0, &block)

  end

  # This method is called to remove a value from this cache store by its unique key.
  #
  # @param [String] This is the unique key to reference the value to remove from this cache store.
  def remove(key)

  end

  # This method is called to check if a value exists within this cache store for a specific key.
  #
  # @param [String] This is the unique key to reference the value to check for within this cache store.
  def exist?(key)

  end
end

# This class implements a local in-memory cache store.
class LocalCacheStore
  def initialize(_namespace = nil)
    @store = {}
  end

  # Store a value in this cache store by its key.
  #
  # @param key [String] The unique key to reference the value being set.
  # @param value [Object] The value to store.
  # @param expires_in [Integer] The number of seconds from the current time that this value should expire.
  def set(key, value, expires_in = 0)
    if expires_in > 0
      expires = Time.now + expires_in
    end
    @store.store(key, {value: value, expires: expires})
  end

  # This method is called to get a value from this cache store by its unique key.
  #
  # @param key [String] Unique key to reference the value to fetch from within this cache store.
  # @param &block [Block] This block is provided to populate this cache store with the value for the request key when it is not found.
  # @return [Object] The value for the specified unique key within the cache store.
  def get(key, expires_in = 0)
    item = @store[key]
    if item
      if item[:expires] && item[:expires] < Time.now # An expired entry has been found
        if block_given?
          value = yield
          set(key, value, expires_in)
          return value
        else
          remove(key)
          return nil
        end
      else # An item was found which has not expired
        return item[:value]
      end
    elsif block_given?
      value = yield
      set(key, value, expires_in)
      return value
    end
  end

  # This method is called to remove a value from this cache store by its unique key.
  #
  # @param key [String] The unique key to remove from this cache store.
  def remove(key)
    @store.delete key
  end

  # This method is called to check if a value exists within this cache store for a specific key.
  #
  # @param key [String] The unique key to reference the value to check for within this cache store.
  # @return [Boolean] True or False to specify if the key exists in the cache store.
  def exist?(key)
    @store.key? key
  end
end
