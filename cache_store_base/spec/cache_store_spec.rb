require 'spec_helper'
require_relative '../lib/cache_store'

describe LocalCacheStore do
  describe '#set' do
    let(:key       ) { 'key123'     }
    let(:value     ) { 'value123'   }
    let(:expires_in) { 10           }
    let(:now       ) { Time.now.utc }

    it "should add an item to the cache store that doesn't expire when no [expires_in] is specified." do
      subject.set(key, value)

      expect(subject.store[0][:key    ]).to eq(key  )
      expect(subject.store[0][:value  ]).to eq(value)
      expect(subject.store[0][:expires]).to eq(nil  )
    end

    it "should add an item to the cache store and set the expiry when specified." do
      subject.set(key, value, expires_in)

      expect(subject.store[0][:key    ]).to eq(key)
      expect(subject.store[0][:value  ]).to eq(value)
      expect(subject.store[0][:expires]).to be > now
    end

    context "when item already exists" do
      let(:new_value) { 'abc123' }

      before { subject.set(key, value) }

      it "updates item with new value" do
        expect(subject.get(key)).to eq(value)

        subject.set(key, new_value)

        expect(subject.get(key)).to eq(new_value)
      end
    end
  end

  describe '#get' do
    let(:key       ) { 'key123'     }
    let(:value     ) { 'value123'   }
    let(:expires_in) { 10           }
    let(:now       ) { Time.now.utc }

    it 'should return a value from the cache store for the specified key when a value is found.' do
      subject.store.push({ key: key, value: value, expires: nil })

      expect(subject.get(key)).to eq(value)
    end

    it 'should return nil from the cache store for the specified key when no value is found and no hydration block is specified.' do
      expect(subject.get(key)).to eq(nil)
    end

    it 'should hydrate the cache store with a value for the specified key when no value is found and a hydration block is provided.' do

      result = subject.get(key, expires_in) do
        value
      end

      expect(result).to eq(value)
      expect(subject.store.length).to eq(1)
      expect(subject.store[0][:expires]).to be > now
    end

    it 'should hydrate the cache store with a value for the specified key when the value has expired and a hydration block is provided.' do
      subject.store.push({ key: key, value: 'old_value', expires: Time.now.utc })

      result = subject.get(key) do
        value
      end

      expect(result).to eq(value)
      expect(subject.store.length).to eq(1)

    end

    it 'should return nil from the cache store for the specified key when a value is expired.' do
      subject.store.push({ key: key, value: value, expires: Time.now.utc })

      expect(subject.get(key)).to eq(nil)
      expect(subject.store.length).to eq(0)
    end
  end

  describe '#remove' do
    let(:key  ) { 'key123'   }
    let(:value) { 'value123' }

    it "should remove a value by it's specified key" do
      subject.store.push({ key: key, value: value })

      subject.remove(key)
      expect(subject.store.length).to eq(0)
    end
  end

  describe '#exist?' do
    let(:key) { 'key123' }
    let(:value) { 'value123' }

    context 'when a value exists for a specified key' do
      before { subject.store.push({ key: key, value: value}) }

      it 'should return true' do
        expect(subject.exist?(key)).to eq(true)
      end
    end

    context 'when a value does not exist for a specified key' do
      it 'should return false ' do
        expect(subject.exist?(key)).to eq(false)
      end
    end
  end

  context 'with namespace specified' do
    let(:key      ) { 'key123'   }
    let(:value    ) { 'value123' }
    let(:new_value) { 'abc123'   }

    subject { LocalCacheStore.new('test') }

    it 'should set a value and append the namespace to the key' do
      subject.set(key, value)

      expect(subject.store[0][:key]).to eq('test:key123')
    end

    context 'when a namespace has been specified' do
      before { subject.store.push({key: 'test:' + key, value: value }) }

      it 'should get a value' do
        result = subject.get(key)

        expect(result).to eq(value)
      end

      it 'should remove a value' do
        subject.remove(key)

        expect(subject.store.length).to eq(0)
      end

      it 'should return true when check if a key exists' do
        expect(subject.exist?(key)).to eq(true)
      end

      it "updates item with new value" do
        expect(subject.get(key)).to eq(value)

        subject.set(key, new_value)

        expect(subject.get(key)).to eq(new_value)
      end
    end
  end
end
