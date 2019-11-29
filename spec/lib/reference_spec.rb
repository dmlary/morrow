require 'reference'

describe Reference do
  context 'loaded from yaml' do
    let(:ref) { YAML.load "!ref meep" }
    it 'will have the correct vid' do
      expect(ref.vid).to eq("meep")
    end
  end

  context 'emitted to yaml' do
    let(:ref) { Reference.new('test') }
    let(:yaml) { ref.to_yaml }
    it 'will have the same vid when parsed' do
      loaded = YAML.load(yaml)
      expect(loaded.vid).to eq(ref.vid)
    end
  end

  describe '#resolve' do
    context 'Entity id has not been resolved' do
      it 'will call World.by_vid("test/test/test")' do
        World = double
        expect(World).to receive(:by_id).with('test/test/test') { -1 }
        Reference.new('test/test/test').resolve(nil)
      end
    end
  end
end
