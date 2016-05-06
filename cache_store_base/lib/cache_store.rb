require "cache_store/version"
require 'date'
require 'time'
#This class is used to define the contract that CacheStore implementations must adhere to.
class CacheStoreContract

  def initialize(namespace = '')
    @namespace = namespace
  end

  #This method is called to set a value within this cache store by it's key.
  #
  # @param [String] This is the unique key to reference the value being set within this cache store.
  # @param [Object] This is the value to set within this cache store.
  # @param [Integer] This is the number of seconds from the current time that this value should expire.
  def set(key, value, expires_in = 0)

  end

  #This method is called to get a value from this cache store by it's unique key.
  #
  # @param [String] This is the unique key to reference the value to fetch from within this cache store.
  # @param [Integer] This is the number of seconds from the current time that this value should expire. (This is used in conjunction with the block to hydrate the cache key if it is empty.)
  # @param [Block] This block is provided to hydrate this cache store with the value for the request key when it is not found.
  def get(key, expires_in = 0, &block)

  end

  # This method is called to remove a value from this cache store by it's unique key.
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

#This class is used to implement a local in memory cache store.
class LocalCacheStore

  attr_accessor :store

  def initialize(namespace = nil)
    @store = Array.new
    @namespace = namespace
  end

  #This method is called to set a value within this cache store by it's key.
  #
  # @param key [String] This is the unique key to reference the value being set within this cache store.
  # @param value [Object] This is the value to set within this cache store.
  # @param expires_in [Integer] This is the number of seconds from the current time that this value should expire.
  def set(key, value, expires_in = 0)
    remove(build_key(key))
    expires = nil
    if expires_in > 0
      #now = DateTime.now
      #expires = DateTime.new(now.year, now.month, now.day, 0, 0, expires_in)
      expires = Time.now.utc + expires_in
    end
    @store.push({ key: build_key(key), value: value, expires: expires})
  end

  #This method is called to get a value from this cache store by it's unique key.
  #
  # @param key [String] This is the unique key to reference the value to fetch from within this cache store.
  # @param expires_in [Integer] This is the number of seconds from the current time that this value should expire. (This is used in conjunction with the block to hydrate the cache key if it is empty.)
  # @param &block [Block] This block is provided to hydrate this cache store with the value for the request key when it is not found.
  # @return [Object] The value for the specified unique key within the cache store.
  def get(key, expires_in = 0, &block)

    #look for the cache item in the store
    items = @store.select { |i| i[:key] == build_key(key) }
    item = if !items.empty? then items[0] else nil end
    #check if a valid item was found in the store
    if item == nil || (item[:expires] != nil && item[:expires] <= Time.now.utc)
      #a valid item wasn't found so check if a hydration block was specified.
      if block_given?
        #create the item from the block
        value = yield
        #put the item in the store
        set(build_key(key), value, expires_in)
        return value
      else
        #no hydration block was specified

        #check if an expired item was found
        if item != nil
          #remove the expired item from the store
          remove(build_key(key))
        end
        return nil
      end
    end

    #return the item
    return item[:value]
  end

  # This method is called to remove a value from this cache store by it's unique key.
  #
  # @param key [String] This is the unique key to reference the value to remove from this cache store.
  def remove(key)
    @store.delete_if { |i| i[:key] == build_key(key) }
  end

  # This method is called to check if a value exists within this cache store for a specific key.
  #
  # @param key [String] This is the unique key to reference the value to check for within this cache store.
  # @return [Boolean] True or False to specify if the key exists in the cache store.
  def exist?(key)
    !@store.select { |i| i[:key] == build_key(key) }.empty?
  end

  private

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