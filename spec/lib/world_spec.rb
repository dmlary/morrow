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
          @animate = @char.get_component(:animate)
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
          @animate = @player.get_component(:animate)
          @conn = @player.get_component(:connection)
        end
          
        it 'will call the system with entity, and all component' do
          expect(@callback).to receive(:call).with(@player, @animate, @conn)
          World.update
        end
      end
    end
  end

  describe '.by_id(id, &block)' do
    context 'id is nil' do
      it 'will return nil' do
        expect(World.by_id(nil)).to eq(nil)
      end
    end
    context 'id is Entity instance' do
      context 'when Entity exists in World' do
        it 'will return Entity instance' do
          entity = Entity.new
          World.add_entity(entity)
          expect(World.by_id(entity)).to eq(entity)
        end
      end
      context 'when Entity does not exist in World' do
        it 'will return nil' do
          entity = Entity.new
          expect(World.by_id(entity)).to be_nil
        end
      end
    end
    context 'id is Integer' do
      context 'entity with that id exists' do
        it 'will return Entity instance' do
          entity = Entity.new
          World.add_entity(entity)
          expect(World.by_id(entity.id)).to eq(entity)
        end
      end
      context 'entity with that id does not exist' do
        it 'will return nil' do
          expect(World.by_id(12345)).to be_nil
        end
      end
    end
    context 'id is Array' do
      context 'containing nil' do
        it 'will not return a value for nil' do
          expect(World.by_id([nil])).to be_empty
        end
        it 'will delete nil from the array' do
          a = [nil]
          World.by_id(a)
          expect(a).to be_empty
        end
      end
      context 'containing an Entity instance' do
        context 'that exists in World' do
          it 'will include the entity instance in the results' do
            entity = Entity.new
            World.add_entity(entity)
            expect(World.by_id([entity])).to contain_exactly(entity)
          end
          it 'will not delete the entity from the array' do
            entity = Entity.new
            array = [ entity ]
            World.add_entity(entity)
            World.by_id(array)
            expect(array).to contain_exactly(entity)
          end
        end
        context 'that does not exist in World' do
          let(:entity) { Entity.new }
          let(:array) { [ entity ] }
          it 'will not include the entity instance in the results' do
            expect(World.by_id(array)).to_not include(entity)
          end
          it 'will delete the entity from the array' do
            World.by_id(array)
            expect(array).to_not include(entity)
          end
        end
      end
      context 'containing an Integer' do
        let(:entity) { Entity.new }
        let(:array) { [ entity.id ] }
        context 'entity with that id exists' do
          it 'will include entity in results' do
            World.add_entity(entity)
            expect(World.by_id(array)).to contain_exactly(entity)
          end
          it 'will not delete the entity from the array' do
            World.add_entity(entity)
            World.by_id(array)
            expect(array).to include(entity.id)
          end
        end
        context 'entity with that id does not exist' do
          it 'will not include anything in the results' do
            expect(World.by_id(array)).to_not include(entity)
          end
          it 'will delete the id from the array' do
            World.by_id(array)
            expect(array).to_not include(entity)
          end
        end
      end
    end
    context 'id is unsupported type' do
      it 'will raise ArgumentError'
    end

    context 'block is provided' do
      let(:block) { proc { } }
      let(:entity) { Entity.new }
      context 'when id is nil' do
        it 'will raise an error' do
          expect(block).to_not receive(:call)
          expect { World.by_id(nil, &block) }.to raise_error(ArgumentError)
        end
      end
      context 'when arg is entity instance' do
        context 'entity exists in the world' do
          it 'will raise an error' do
            World.add_entity(entity)
            expect(block).to_not receive(:call)
            expect { World.by_id(entity, &block) }
                .to raise_error(ArgumentError)
          end
        end
        context 'entity does not exist in the world' do
          it 'will raise an error' do
            expect(block).to_not receive(:call)
            expect { World.by_id(entity, &block) }
                .to raise_error(ArgumentError)
          end
        end
      end
      context 'when id is Integer' do
        context 'entity with id exists' do
          it 'will call the block with id & entity' do
            World.add_entity(entity)
            expect(block).to_not receive(:call)
            expect { World.by_id(entity.id, &block) }
                .to raise_error(ArgumentError)
          end
        end
        context 'entity with id does not exist' do
          it 'will not call the block' do
            expect(block).to_not receive(:call)
            expect { World.by_id(entity.id, &block) }
                .to raise_error(ArgumentError)
          end
        end
      end
      context 'id is Array' do
        context 'containing nil' do
          let(:array) { [nil] }
          it 'will not call block' do
            expect(block).to_not receive(:call)
            World.by_id(array, &block)
          end
          it 'will delete nil from arg' do
            World.by_id(array, &block)
            expect(array).to_not include(nil)
          end
        end
        context 'containing entity instance' do
          let(:array) { [entity] }
          it 'will call block with id & entity' do
            World.add_entity(entity)
            expect(block).to receive(:call).with(entity.id, entity)
            World.by_id(array, &block)
          end
          it 'will not delete entity from arg' do
            World.add_entity(entity)
            World.by_id(array, &block)
            expect(array).to include(entity)
          end
        end
        context 'containing an Integer' do
          let(:array) { [ entity.id ] }
          context 'entity exists' do
            it 'will call the block with id & entity' do
              World.add_entity(entity)
              expect(block).to receive(:call).with(entity.id, entity)
              World.by_id(array, &block)
            end
            it 'will not delete entity id from arg' do
              World.add_entity(entity)
              World.by_id(array, &block)
              expect(array).to include(entity.id)
            end
          end
          context 'entity does not exist' do
            it 'will call the block with id & nil' do
              expect(block).to receive(:call).with(entity.id, nil)
              World.by_id(array, &block)
            end
            it 'will remove the id from arg' do
              World.by_id(array, &block)
              expect(array).to_not include(entity.id)
            end
          end
        end
      end
    end
  end
end
