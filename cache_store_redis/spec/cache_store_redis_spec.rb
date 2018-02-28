describe RedisCacheStore do
  before do
    @cache_store = RedisCacheStore.new('test')
    @cache_store.configure(url: 'redis://redis:6379')
  end

  after :each do
    @cache_store.with_client &:flushdb
  end

  describe "#set" do
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

      v2 = @cache_store.get(key)
      expect(v2.class).to eq(TestObject)
      expect(v2.text).to eq('abc123')
      expect(v2.numeric).to eq(123)
    end

    context 'when set value has expired' do
      let(:key  ) { SecureRandom.uuid }
      let(:value) { '123'             }

      before :each do
        @cache_store.set(key, value, 1)
        sleep(1.2)  # TODO: find a way to remove this by stubbing the Redis expire mechanism
      end

      it 'returns nil' do
        expect(@cache_store.get(key)).to be_nil
      end
    end

    context 'when namespaced' do
      let(:key  ) { 'name' }
      let(:value) { 'Tom'  }

      subject { described_class.new('myname') }

      it 'sets the value' do
        @cache_store.set(key, value)

        expect(@cache_store.get(key)).to eq(value)
      end

      context 'when key already exists' do
        let(:new_value) { 'Peter' }
        before { @cache_store.set(key, value) }

        it 'updates the item' do
          @cache_store.set(key, new_value)

          expect(@cache_store.get(key)).to eq(new_value)
        end
      end
    end
  end

  describe '#get' do
    let(:value) { 'value' }
    let(:key) { 'getkey' }

    it 'runs the hyrdation block when the value is not in the cache' do
      v = @cache_store.get(key) do
        value
      end

      expect(@cache_store.get(key)).to eq v
    end

    context 'when the value in the store is empty string' do
      let(:value) { '' }

      it 'does not attempt to deserialize' do
        @cache_store.set(key, value)
        expect(subject).to_not receive(:deserialize)
        expect(@cache_store.get(key)).to be nil
      end
    end
  end

  describe '#exists?' do
    context 'when a key does not exist' do
      let(:key) { SecureRandom.uuid }

      it 'returns false' do
        expect(@cache_store.exist?(key)).to eq(false)
      end
    end

    context 'when a key exists' do
      let(:key) { SecureRandom.uuid }

      before { @cache_store.set(key, '123') }

      it 'returns true ' do
        expect(@cache_store.exist?(key)).to eq(true)
      end
    end
  end

  describe '#remove' do
    context 'when the value exists' do
      let(:key  ) { SecureRandom.uuid }
      let(:value) { '123'             }

      before { @cache_store.set(key, value) }

      it 'removes that value' do
        expect(@cache_store.exist?(key)).to eq(true)

        @cache_store.remove(key)

        expect(@cache_store.exist?(key)).to eq(false)
      end
    end

    context 'when the value does no exist' do
      let(:key) { SecureRandom.uuid }

      it 'does not raise an exception' do
        expect { @cache_store.remove(key) }.to_not raise_error
      end
    end
  end

  describe '#ping' do
    it 'pings the cache store' do
      expect(@cache_store.ping).to eq 'PONG'
    end
  end
end
