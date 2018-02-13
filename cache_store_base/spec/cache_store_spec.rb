require 'spec_helper'
require 'cache_store'

describe LocalCacheStore do
  describe '#set' do
    let(:key       ) { 'key123'     }
    let(:value     ) { 'value123'   }
    let(:expires_in) { 10           }
    let(:now       ) { Time.now.utc }

    it "should add an item to the cache store that doesn't expire when no [expires_in] is specified." do
      subject.set(key, value)
      expect(subject.get(key)).to eq(value)
    end

    it "should add an item to the cache store and set the expiry when specified." do
      subject.set(key, value, 0.001)

      sleep 0.002
      expect(subject.get(key)).to be_nil
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
      subject.set key, value

      expect(subject.get(key)).to eq(value)
    end

    it 'should return nil from the cache store for the specified key when no value is found and no block is specified.' do
      expect(subject.get(key)).to eq(nil)
    end

    it 'should populate the cache store with a value for the specified key when no value is found and a block is provided.' do
      result = subject.get(key, expires_in) do
        value
      end

      expect(result).to eq(value)
    end

    it 'should populate cache store with a value for the specified key when the value has expired and a block is provided.' do
      subject.set(key, 'old_value', 0.001)
      sleep 0.002

      result = subject.get(key) do
        value
      end

      expect(result).to eq(value)
    end

    it 'should return nil from the cache store for the specified key when a value is expired' do
      subject.set(key, value, 0.001)
      sleep(0.001)

      expect(subject.get(key)).to eq(nil)
    end
  end

  describe '#remove' do
    let(:key  ) { 'key123'   }
    let(:value) { 'value123' }

    it "should remove a value by its specified key" do
      subject.set key, value

      subject.remove(key)
      expect(subject.get(key)).to be_nil
    end
  end

  describe '#exist?' do
    let(:key) { 'key123' }
    let(:value) { 'value123' }

    context 'when a value exists for a specified key' do
      before { subject.set key, value }

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

    it 'accepts the namespace in the initializer' do
      store = LocalCacheStore.new('test')
      store.set key, value
      expect(store.get(key)).to eq(value)
    end
  end
end
