require 'reference'

describe Reference do
  # Do we want two different methods for resolving?
  #
  # eref = Reference.new('base:room')
  # eref.entity   # => Entity
  # eref.field?   # => false
  # eref.value    # => raise RuntimeError
  # eref.value=   # => raise RuntimeError
  #
  # fref = Reference.new('base:room.contents.list')
  # fref.entity     # => Entity
  # fref.field?     # => true
  # fref.value      # => []
  # fref.value=(x)  # => x
  let(:exits) { ExitsComponent.new }
  let(:entity) do
    virtual = VirtualComponent.new(id: 'test:entity')
    World.new_entity(components: [virtual, exits])
  end
  let(:entity_ref) { Reference.new('test:entity') }
  let(:field_ref)  { Reference.new('test:entity.exits.list') }
  let(:invalid_ref) { Reference.new('test:nonexistent_entity.exits.list') }
  let(:abs_ref) { Reference.new(entity) }

  before(:each) do
    World.reset!
    World.add_entity(entity)
  end

  describe '#entity' do
    context 'on Entity Reference' do
      it 'will return the Entity' do
        expect(entity_ref.entity).to be(entity)
      end

      it 'will cache the Entity id' do
        entity_ref.entity
        expect(entity_ref.entity_id).to eq(entity.id)
      end
    end
    context 'on Component Field Reference' do
      it 'will return the Entity' do
        expect(field_ref.entity).to be(entity)
      end
      it 'will cache the Entity id' do
        entity_ref.entity
        expect(entity_ref.entity_id).to eq(entity.id)
      end
    end
    context 'on a Reference to a non-existent Entity' do
      it 'will raise EntityManager::UnknownVirtual' do
        expect { invalid_ref.entity }
            .to raise_error(EntityManager::UnknownVirtual)
      end
    end
  end

  describe '#has_field?' do
    context 'on Entity Reference' do
      it 'will return false' do
        expect(entity_ref.has_field?).to be(false)
      end
    end
    context 'on Component Field Reference' do
      it 'will return true' do
        expect(field_ref.has_field?).to be(true)
      end
    end
  end

  describe '#value' do
    context 'on Entity Reference' do
      it 'will raise a Reference::NoField error' do
        expect { entity_ref.value }.to raise_error(Reference::NoField)
      end
    end
    context 'on Invalid Reference' do
      it 'will raise a EntityManager::UnknownVirtual error' do
        expect { invalid_ref.value }
            .to raise_error(EntityManager::UnknownVirtual)
      end
    end
    context 'on Component Field Reference' do
      it 'will return the value of the Component Field' do
        expect(field_ref.value).to be(exits.list)
      end
      it 'will not cache the Component or Component Field Value' do
        field_ref.value
        entity.rem_component(exits)
        new_exits = ExitsComponent.new
        entity.add_component(new_exits)
        expect(field_ref.value).to be(new_exits.list)
      end
    end
  end

  describe '#initialize(Entity)' do
    it 'will set the entity_id' do
      r = Reference.new(entity)
      expect(r.entity_id).to eq(entity.id)
    end
    it 'will not set match' do
      r = Reference.new(entity)
      expect(r.match).to be_nil
    end
  end

  describe '#absolute?' do
    context 'on Entity reference' do
      it 'will return false' do
        expect(entity_ref.absolute?).to eq(false)
      end
    end
    context 'on Component Field Reference' do
      it 'will return false' do
        expect(field_ref.absolute?).to eq(false)
      end
    end
    context 'on Absolute Reference' do
      it 'will return true' do
        expect(abs_ref.absolute?).to eq(true)
      end
    end
  end

  context 'loaded from yaml' do
    context 'a relative reference' do
      let(:relative_ref) do
        YAML.load_file(File.join(File.dirname(__FILE__),
            'reference_relative.yml'))
      end
      it 'will set the area to "reference_spec" if not specified' do
        expect(World).to receive(:by_virtual)
            .with('reference_relative:entity').and_return(entity)
        relative_ref.entity
      end
    end
    context 'an absolute reference' do
      let(:abs_ref) do
        YAML.load_file(File.join(File.dirname(__FILE__),
            'reference_absolute.yml'))
      end
      it 'will not change the area' do
        expect(World).to receive(:by_virtual)
            .with('test:entity').and_return(entity)
        abs_ref.entity
      end
    end
  end
end
__END__
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
