require 'spec_helper'
require_relative '../lib/cache_store_redis'

class TestObject
  attr_accessor :text
  attr_accessor :numeric
end

describe RedisCacheStore do

  before do
    @cache_store = RedisCacheStore.new
    @cache_store.configure
  end

  it 'should add a string to the cache store and retrieve it' do

    key = SecureRandom.uuid
    value = 'value123'
    @cache_store.set(key, value)

    v = @cache_store.get(key)

    expect(v).to eq(value)

  end

  it 'should add an object to the cache store and retrieve it' do

    key = SecureRandom.uuid
    value = TestObject.new
    value.text = 'abc123'
    value.numeric = 123

    @cache_store.set(key, value)

    v = @cache_store.get(key)

    expect(v.class).to eq(TestObject)
    expect(v.text).to eq(value.text)
    expect(v.numeric).to eq(value.numeric)

  end

  it 'should run the hydration block when the requested key does not exist in the cache' do

    key = SecureRandom.uuid

    v = @cache_store.get(key) do
      value = TestObject.new
      value.text = 'abc123'
      value.numeric = 123
      value
    end

    expect(v.class).to eq(TestObject)
    expect(v.text).to eq('abc123')
    expect(v.numeric).to eq(123)

  end

  it 'should not retrieve an expired value' do

    key = SecureRandom.uuid
    value = '123'

    @cache_store.set(key, value, 1)

    sleep(1.2)

    v = @cache_store.get(key)

    expect(v).to be_nil

  end

  context '#exists?' do

    it 'should return false when a key does not exist' do

      key = SecureRandom.uuid

      exists = @cache_store.exist?(key)

      expect(exists).to eq(false)

    end

    it 'should return true when a key exists' do

      key = SecureRandom.uuid

      @cache_store.set(key, '123')

      exists = @cache_store.exist?(key)

      expect(exists).to eq(true)

    end

  end

  context '#remove' do

    it 'should remove a value when it exists' do

      key = SecureRandom.uuid

      @cache_store.set(key, '123')

      exists = @cache_store.exist?(key)

      expect(exists).to eq(true)

      @cache_store.remove(key)

      exists = @cache_store.exist?(key)

      expect(exists).to eq(false)

    end

    it 'should not fail when trying to remove a value that does not exists' do

      key = SecureRandom.uuid

      @cache_store.remove(key)

    end

  end

end