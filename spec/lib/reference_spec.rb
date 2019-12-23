require 'reference'

describe Reference do
  let(:exits) { ExitsComponent.new }
  let(:entity) { World.create_entity(id: 'test:entity', components: exits) }
  let(:entity_ref) { Reference.new('test:entity') }
  let(:field_ref)  { Reference.new('test:entity.exits.list') }
  let(:invalid_ref) { Reference.new('test:nonexistent_entity.exits.list') }
  let(:abs_ref) { Reference.new(entity) }

  before(:each) { World.reset!; entity }

  describe '#entity' do
    context 'on Entity Reference' do
      it 'will return the Entity' do
        expect(entity_ref.entity).to eq(entity)
      end
    end
    context 'on Component Field Reference' do
      it 'will return the Entity' do
        expect(field_ref.entity).to eq(entity)
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
            .to raise_error(EntityManager::UnknownId)
      end
    end
    context 'on Component Field Reference' do
      it 'will return the value of the Component Field' do
        expect(field_ref.value).to be(exits.list)
      end
      it 'will not cache the Component or Component Field Value' do
        field_ref.value
        World.remove_component(entity, exits)
        new_exits = ExitsComponent.new
        World.add_component(entity, new_exits)
        expect(field_ref.value).to be(new_exits.list)
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
            .to raise_error(EntityManager::UnknownId)
      end
    end
    context 'on Component Field Reference' do
      it 'will call the setter on the Component' do
        expect(exits).to receive(:list=).with(:pass)
        field_ref.value = :pass
      end
    end
  end
end
