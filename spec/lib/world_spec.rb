require 'world'
require 'component'

describe World do
  include World::Helpers

  let(:comp) { Class.new(Component) }

  %i{ entities add_component remove_component
      get_component get_components }.each do |method|
    describe ".#{method}()" do
      it "will call World.em.#{method}()" do
        expect(World.em).to receive(method).with(:passed)
        World.send(method, :passed)
      end
    end
  end

  describe '.create_entity' do
    before(:each) { World.reset! }
    let(:base) { World.create_entity }

    it 'will set MetadataComponent.base to an array of bases' do
      id = World.create_entity(base: base)
      expect(World.get_component(id, :metadata).base).to eq([base])
    end
  end
  describe '.destroy_entity' do
    before(:each) { World.reset! }
    let(:entity) { create_entity }

    it 'will remove the entity from the location' do
      room = create_entity
      move_entity(entity: entity, dest: room)
      World.destroy_entity(entity)
      expect(entity_contents(room)).to_not include(entity)
    end
    it 'will update the spawn source' do
      spawn = create_entity
      get_component!(spawn, :spawn).active = 1
      get_component!(entity, :metadata).spawned_by = spawn
      World.destroy_entity(entity)
      expect(get_component(spawn, :spawn).active).to eq(0)
    end
    it 'will destroy the entity' do
      World.destroy_entity(entity)
      expect(entity_exists?(entity)).to be(false)
    end
  end

  describe '.get_component!(entity, type)' do
    let(:entity) { World.create_entity }

    context 'entity does not have component' do
      it 'will call World.em.get_component' do
        expect(World.em).to receive(:get_component).with(entity, comp)
            .and_return(comp.new)
        World.get_component!(entity, comp)
      end
      it 'will call World.em.add_component' do
        expect(World.em).to receive(:add_component).with(entity, comp)
        World.get_component!(entity, comp)
      end
      it 'will return a Component instance' do
        expect(World.get_component!(entity, comp)).to be_a(comp)
      end
    end

    context 'entity has component' do
      let(:instance) { comp.new }
      before(:each) { World.add_component(entity, instance) }

      it 'will call World.em.get_component' do
        expect(World.em).to receive(:get_component).with(entity, comp)
            .and_return(comp.new)
        World.get_component!(entity, comp)
      end
      it 'will not call World.em.add_component' do
        expect(World.em).to_not receive(:add_component)
        World.get_component!(entity, comp)
      end
      it 'will return a Component instance' do
        expect(World.get_component!(entity, comp)).to be(instance)
      end
    end
  end

  describe '.update_views(entity)' do
    it 'will call EntityView#update! on each view'
  end

  describe '.update' do
    context 'with no systems registered' do
      xit 'will do nothing'
    end

    context 'with a system registered' do
      context 'when no entities with the requested component exist' do
        it 'will not call the system'
      end
      context 'when entities with the requested component exist' do
        it 'will call the system'
      end
      context 'when multiple entities exist' do
      end
      context 'when entities with the all components exist' do
      end
    end
  end
end
