require "cache_store/version"
require 'date'
require 'pry'
#This class is used to define the contract that CacheStore implementations must adhere to.
class CacheStoreContract

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

  def initialize
    @store = Array.new
  end

  #This method is called to set a value within this cache store by it's key.
  #
  # @param [String] This is the unique key to reference the value being set within this cache store.
  # @param [Object] This is the value to set within this cache store.
  # @param [Integer] This is the number of seconds from the current time that this value should expire.
  def set(key, value, expires_in = 0)
    remove(key)
    expires = nil
    if expires_in > 0
      now = DateTime.now
      expires = DateTime.new(now.year, now.month, now.day, 0, 0, expires_in)
    end
    @store.push({ key: key, value: value, expires: expires})
  end

  #This method is called to get a value from this cache store by it's unique key.
  #
  # @param [String] This is the unique key to reference the value to fetch from within this cache store.
  # @param [Integer] This is the number of seconds from the current time that this value should expire. (This is used in conjunction with the block to hydrate the cache key if it is empty.)
  # @param [Block] This block is provided to hydrate this cache store with the value for the request key when it is not found.
  def get(key, expires_in = 0, &block)

    #look for the cache item in the store
    items = @store.select { |i| i[:key] == key }
    item = if !items.empty? then items[0] else nil end
    #check if a valid item was found in the store
    if item == nil || (item[:expires] != nil && item[:expires] <= DateTime.now)
      #a valid item wasn't found so check if a hydration block was specified.
      if block_given?
        #create the item from the block
        value = yield
        #put the item in the store
        set(key, value, expires_in)
        return value
      else
        #no hydration block was specified

        #check if an expired item was found
        if item != nil
          #remove the expired item from the store
          remove(key)
        end
        return nil
      end
    end

    #return the item
    return item[:value]
  end

  # This method is called to remove a value from this cache store by it's unique key.
  #
  # @param [String] This is the unique key to reference the value to remove from this cache store.
  def remove(key)
    @store.delete_if { |i| i[:key] == key }
  end

  # This method is called to check if a value exists within this cache store for a specific key.
  #
  # @param [String] This is the unique key to reference the value to check for within this cache store.
  def exist?(key)
    !@store.select { |i| i[:key] == key }.empty?
  end
end