require 'world'
require 'entity'
require 'component'

describe World do
  before(:all) { Helpers::Logging.logger.level = Logger::WARN }

  let(:entity) { Entity.new }
  describe 'new_entity(*args)' do
    it 'will pass *args to Entity.new' do
      expect(Entity).to receive(:new).with(:type, :args).and_return(entity)
      World.new_entity(:type, :args)
    end

    it 'will call World.add_entity with the result of Entity.new' do
      expect(Entity).to receive(:new).and_return(entity)
      expect(World).to receive(:add_entity).with(entity)
      World.new_entity
    end

    it 'will return the entity id' do
      expect(Entity).to receive(:new).and_return(entity)
      expect(World.new_entity).to eq(entity.id)
    end
  end

  describe 'add_entity(entity)' do
    it 'will return the entity id' do
      World.add_entity(entity)
      expect(World.by_id(entity.id)).to eq(entity)
    end
    it 'will add the entity to @entities_by_id' do
      World.add_entity(entity)
      expect(World.by_id(entity.id)).to eq(entity)
    end
  end

  describe '.update' do
    context 'with no systems registered' do
      xit 'will do nothing'
    end

    context 'with a system registered' do
      before(:all) do
        Component.reset!
        Component.define(:animate)
        Component.define(:connection)

        Entity.reset!
        Entity.define(:item)
        Entity.define(:char, :animate)
        Entity.define(:player, :animate, :connection)
      end

      let(:system_args) do
        World.update
        @args
      end

      let(:entity) { system_args.first }
      let(:components) { system_args[1..-1] }

      context 'when no entities with the requested component exist' do
        before(:all) do
          @callback = proc { |*a| }
          World.reset!
          World.register_system(:animate, &@callback)
          5.times { World.new_entity(:item) }
        end
        it 'will not call the system' do
          expect(@callback).to_not receive(:call)
          World.update
        end
      end
      context 'when entities with the requested component exist' do
        before(:all) do
          @callback = proc { |*a| }
          World.reset!
          World.register_system(:animate, &@callback)
          5.times { World.new_entity(:item) }
          @char = Entity.new(:char)
          World.add_entity(@char)
          @animate = @char.get(:animate)
        end
          
        it 'will call the system with the entity and requested component' do
          expect(@callback).to receive(:call).with(@char, @animate)
          World.update
        end
      end
      context 'when multiple entities exist' do
        before(:all) do
          @callback = proc { |*a| }
          World.reset!
          World.register_system(:animate, &@callback)
          5.times { World.new_entity(:item) }
          3.times { World.new_entity(:char) }
        end
 
        it 'will call the system for each entity' do
          expect(@callback).to receive(:call).exactly(3).times
          World.update
        end
      end

      context 'when entities with the all components exist' do
        before(:all) do
          @callback = proc { |*a| }
          World.reset!
          World.register_system(:animate, :connection, &@callback)
          5.times { World.new_entity(:item); World.new_entity(:char) }
          @player = Entity.new(:player)
          World.add_entity(@player)
          @animate = @player.get(:animate)
          @conn = @player.get(:connection)
        end
          
        it 'will call the system with entity, and all component' do
          expect(@callback).to receive(:call).with(@player, @animate, @conn)
          World.update
        end
      end
    end
  end
end
