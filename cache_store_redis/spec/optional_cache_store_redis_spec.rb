describe OptionalRedisCacheStore do
  before do
    @cache_store = OptionalRedisCacheStore.new(namespace: 'test')
    @cache_store.configure(url: 'redis://redis:6379')
  end

  describe '#set' do
    let(:key) { 'setkey' }
    let(:value) { double }
    it 'should pass the key/value to the redis_store' do
      expect(@cache_store.redis_store).to receive(:set).with(key, value, 0).once
      @cache_store.set(key, value)
    end
    context 'when an error occurs' do
      before do
        allow(@cache_store.redis_store).to receive(:set).and_raise(StandardError)
      end
      it 'does not raise error' do
        expect{ @cache_store.set(key, value) }.not_to raise_error
      end
    end
  end

  describe '#get' do
    let(:key) { 'getkey' }
    it 'requests the key from the redis_store' do
      expect(@cache_store.redis_store).to receive(:get).with(key, 0).once
      @cache_store.get(key)
    end
    context 'when an error occurs' do
      before do
        allow(@cache_store.redis_store).to receive(:get).and_raise(StandardError)
      end
      it 'returns nil' do
        expect(@cache_store.get(key)).to be nil
      end
    end
  end

  describe '#exist?' do
    let(:key) { 'exists_key' }
    it 'should pass the key to the redis_store' do
      expect(@cache_store.redis_store).to receive(:exist?).with(key).once
      @cache_store.exist?(key)
    end
    context 'when an error occurs' do
      before do
        allow(@cache_store.redis_store).to receive(:exist?).and_raise(StandardError)
      end
      it 'returns false' do
        expect(@cache_store.exist?(key)).to be false
      end
    end
  end

  describe '#remove' do
    let(:key) { 'remove_key' }
    it 'should pass the key to the redis_store' do
      expect(@cache_store.redis_store).to receive(:remove).with(key).once
      @cache_store.remove(key)
    end
    context 'when an error occurs' do
      before do
        allow(@cache_store.redis_store).to receive(:remove).and_raise(StandardError)
      end
      it 'does not raise error' do
        expect{ @cache_store.remove(key) }.not_to raise_error
      end
    end
  end

  describe '#ping' do
    it 'should call ping on the redis_store' do
      expect(@cache_store.redis_store).to receive(:ping).once
      @cache_store.ping
    end
    context 'when an error occurs' do
      before do
        allow(@cache_store.redis_store).to receive(:ping).and_raise(StandardError)
      end
      it 'returns false' do
        expect(@cache_store.ping).to be false
      end
    end
  end
end
