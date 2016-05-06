require 'spec_helper'
require_relative '../lib/cache_store'

describe LocalCacheStore do

  describe '#set' do

    it "should add an item to the cache store that doesn't expire when no [expires_in] is specified." do

      key = 'key123'
      value = 'value123'
      subject.set(key, value)

      expect(subject.store[0][:key]).to eq(key)
      expect(subject.store[0][:value]).to eq(value)
      expect(subject.store[0][:expires]).to eq(nil)

    end

    it "should add an item to the cache store an set the expiry when specified." do

      key = 'key123'
      value = 'value123'
      expires_in = 10

      now = Time.now.utc

      subject.set(key, value, expires_in)

      expect(subject.store[0][:key]).to eq(key)
      expect(subject.store[0][:value]).to eq(value)
      expect(subject.store[0][:expires]).to be > now

    end

  end

  describe '#get' do

    it 'should return a value from the cache store for the specified key when a value is found.' do

      key = 'key123'
      value  = 'value123'

      subject.store.push({ key: key, value: value, expires: nil })

      expect(subject.get(key)).to eq(value)

    end

    it 'should return nil from the cache store for the specified key when no value is found and no hydration block is specified.' do

      expect(subject.get('key123')).to eq(nil)

    end

    it 'should hydrate the cache store with a value for the specified key when no value is found and a hydration block is provided.' do

      key = 'key123'
      value = 'value123'
      expires_in = 10

      now = Time.now.utc

      result = subject.get(key, expires_in) do
        value
      end

      expect(result).to eq(value)
      expect(subject.store.length).to eq(1)
      expect(subject.store[0][:expires]).to be > now

    end

    it 'should hydrate the cache store with a value for the specified key when the value has expired and a hydration block is provided.' do

      key = 'key123'
      value = 'value123'

      subject.store.push({ key: key, value: 'old_value', expires: Time.now.utc })

      result = subject.get(key) do
        value
      end

      expect(result).to eq(value)
      expect(subject.store.length).to eq(1)

    end

    it 'should return nil from the cache store for the specified key when a value is expired.' do

      key = 'key123'
      value  = 'value123'

      subject.store.push({ key: key, value: value, expires: Time.now.utc })

      expect(subject.get(key)).to eq(nil)
      expect(subject.store.length).to eq(0)

    end

  end

  describe '#remove' do

    it "should remove a value by it's specified key" do

      key = 'key123'
      value = 'value123'

      subject.store.push({ key: key, value: value })

      subject.remove(key)
      expect(subject.store.length).to eq(0)

    end

  end

  describe '#exist?' do

    it 'should return true when a value exists for a specified key' do

      key = 'key123'
      value = 'value123'

      subject.store.push({ key: key, value: value })

      expect(subject.exist?(key)).to eq(true)

    end

    it 'should return false when a value does not exist for a specified key' do

      key = 'key123'

      expect(subject.exist?(key)).to eq(false)

    end

  end

  describe 'with namespace specified' do

     subject { LocalCacheStore.new('test') }

    it 'should set a value and append the namespace to the key' do

      key = 'key123'

      subject.set(key, 'value123')

      expect(subject.store[0][:key]).to eq('test:key123')

    end

    it 'should get a value when a namespace has been specified' do

      key = 'key123'
      value = 'value123'

      subject.store.push({key: 'test:' + key, value: value })

      result = subject.get(key)

      expect(result).to eq(value)

    end

    it 'should remove a value when a namespace has been specified' do

      key = 'key123'
      value = 'value123'

      subject.store.push({key: 'test:' + key, value: value })

      subject.remove(key)

      expect(subject.store.length).to eq(0)

    end

     it 'should return true when check if a key exists when a namespace has been specified' do

       key = 'key123'
       value = 'value123'

       subject.store.push({key: 'test:' + key, value: value })

       expect(subject.exist?(key)).to eq(true)

     end

  end

end