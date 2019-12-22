require 'world'
require 'component'

describe World do
  let(:comp) { Class.new(Component) }

  %i{ create_entity destroy_entity entities add_component remove_component
      get_component get_components }.each do |method|
    describe ".#{method}()" do
      it "will call World.em.#{method}()" do
        expect(World.em).to receive(method).with(:passed)
        World.send(method, :passed)
      end
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
