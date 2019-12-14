require 'entity_manager'

describe EntityManager do
  let(:em) do
    World.entity_manager = EntityManager.new
  end
  describe '#entity_by_id' do
    context 'when an Entity with that id exists' do
      let(:entity) { Entity.new }
      context 'and has been added' do
        it 'will return the Entity' do
          em.add(entity)
          expect(em.entity_by_id(entity.id)).to be(entity)
        end
      end
      context 'and has not been added' do
        it 'will return nil' do
          expect(em.entity_by_id(entity.id)).to be_nil
        end
      end
    end
    
    context 'when an Entity with that id does not exist' do
      it 'will return nil' do
        expect(em.entity_by_id(-4)).to eq(nil)
      end
    end
  end

  describe '#entity_by_virtual' do
    context 'when an Entity with the virtual id has been added' do
      it 'will return the Entity' do
        e = Entity.new(VirtualComponent.new(id: 'test:entity'))
        em.add(e)
        expect(em.entity_by_virtual('test:entity')).to be(e)
      end 
    end
    context 'when no Entity with the virtual id has been added' do
      it 'will raise EntityManager::UnknownVirtual' do
        e = Entity.new(VirtualComponent.new(id: 'test:entity'))
        expect { em.entity_by_virtual('test:entity') }
            .to raise_error(EntityManager::UnknownVirtual)
      end
    end
  end

  describe '#new_entity()' do
    let(:entity) { Entity.new }

    context 'when called with no arguments' do
      it 'will return an Entity with no Components' do
        expect(em.new_entity.components).to be_empty
      end
    end

    shared_examples 'will return a merged Entity' do
      it 'will return an Entity instance' do
        expect(em.new_entity(arg)).to be_a_kind_of(Entity)
      end
      it 'will not add the Entity to the EntityManager' do
        new = em.new_entity(arg)
        expect(em.entity_by_id(new.id)).to be_nil
      end
      it 'will call Entity#merge! on the base Entity' do
        expect_any_instance_of(Entity).to receive(:merge!).with(entity)
        em.new_entity(arg)
      end
    end

    context 'when called with an Entity argument' do
      let(:arg) { entity }
      include_examples 'will return a merged Entity'
    end
    context 'when called with a Reference argument' do
      before(:each) { em.add(entity) }
      let(:arg) { entity.to_ref }
      include_examples 'will return a merged Entity'
    end
    context 'when called with a String argument' do
      before(:each) do
        entity << VirtualComponent.new(id: 'test:entity')
        em.add(entity)
      end
      let(:arg) { 'test:entity' }
      include_examples 'will return a merged Entity'
    end
    context 'when called with an Array' do
      # Ran into problems implementing this with a expect_any_instance_of mock.
      it 'will call Entity#merge! Array.size times'
    end

    context 'component: [ Component ]' do
      let(:comp) { Class.new(Component) }

      context 'the Component is unique' do
        context 'and exists in base' do
          let(:comp_arg) { comp.new }
          let(:other_comp) { comp.new }
          let(:other) { Entity.new(other_comp) }
          it 'will call #merge! on the base Component' do
            expect_any_instance_of(comp).to receive(:merge!).with(comp_arg)
            em.new_entity(other, components: [comp_arg])
          end
        end
        context 'and does not exist in base' do
          it 'will add the Component to base' do
            component = comp.new
            entity = em.new_entity(components: [component])
            expect(entity.components).to include(component)
          end      
        end
      end
      context 'the Component is not unique' do
        it 'will add the Component to base' do
          comp = Class.new(Component) { not_unique }
          base_comp = comp.new
          add_comp = comp.new
          base = Entity.new(base_comp)
          entity = em.new_entity(base, components: [add_comp])
          expect(entity.get_components(comp).size).to eq(2)
        end
      end
    end

    context 'add: false' do
      it 'will not call EntityManager#add' do
        expect(em).to_not receive(:add)
        em.new_entity(add: false)
      end

      context 'link: [ Reference ]' do
        it 'will raise an ArgumentError' do
          ref = em.new_entity(add: true).to_ref
          expect { em.new_entity(add: false, link: [ref]) }
              .to raise_error(ArgumentError)
        end
      end
    end

    context 'add: true' do
      it 'will call EntityManager#add' do
        expect(em).to receive(:add)
        em.new_entity(add: true)
      end

      context 'link: [ Reference ]' do
        let(:ref) { em.new_entity(add: true).to_ref }

        it 'will call EntityManager#schedule(:link, ref: ref, entity: ?)' do
          expect(em).to receive(:schedule) do |name,args|
            expect(name).to be(:link)
            expect(args).to include(ref: ref)
          end
          em.new_entity(add: true, links: [ ref ])
        end
      end
    end
  end

  describe '#schedule(task, args)' do
    it 'will call @tasks.push' do
      expect(em.instance_variable_get(:@tasks)).to receive(:push)
      em.schedule(:link, ref: nil, entity: nil)
    end
  end

  describe '#resolve!' do
    before(:all) { Helpers::Logging.logger.level = Logger::ERROR }
    context 'a :new_entity task' do
      context 'with only arguments' do
        it 'will call #new_entity(*args)' do
          em.schedule(:new_entity, [1, 2, 3])
          expect(em).to receive(:new_entity) do |*others|
            expect(others).to eq([1,2,3])
          end
          em.resolve!
        end
      end

      context 'with only parameters' do
        it 'will call #new_entity with parameters' do
          em.schedule(:new_entity, add: true)
          expect(em).to receive(:new_entity) do |*args, add: false|
            expect(add).to be(true)
          end
          em.resolve!
        end
      end

      context 'with arguments & parameters' do
        it 'will call #new_entity with args & parameters' do
          em.schedule(:new_entity, [ 'test:room', add: true ])
          expect(em).to receive(:new_entity) do |*args, add: false|
            expect(args).to eq(['test:room'])
            expect(add).to be(true)
          end
          em.resolve!
        end
      end

      context 'with an unknown base' do
        it 'will raise a RuntimeError' do
          em.schedule(:new_entity, 'missing')
          expect { em.resolve! }.to raise_error(RuntimeError)
        end
      end

      context 'with an unknown link' do
        it 'will raise a RuntimeError' do
          em.schedule(:new_entity, add: true,
              links: [Reference.new('test:missing.other.thing')])
          expect { em.resolve! }.to raise_error(RuntimeError)
        end
      end
    end

    context 'a :link task' do
      context 'with a Reference to a valid Entity' do
        let(:dest) do
          e = Entity.new
          e << VirtualComponent.new(id: 'test:entity')
          e << ContainerComponent.new
          e
        end
        before(:each) { em << dest }

        context 'to an Array value' do
          it 'will push an Entity reference onto the Array' do
            ref = Reference.new('test:entity.container.contents')
            entity = em.new_entity(add: true)
            em.schedule(:link, ref: ref, entity: entity)
            em.resolve!
            expect(dest.get(:container, :contents).map(&:entity))
                .to eq([entity])
          end
        end
        context 'to a non-Array value' do
          it 'will replace the value' do
            ref = Reference.new('test:entity.container.max_volume')
            entity = em.new_entity(add: true)
            em.schedule(:link, ref: ref, entity: entity)
            em.resolve!
            expect(dest.get(:container, :max_volume).entity)
                .to be(entity)
          end
        end
      end

      context 'with a Reference to an undefined Entity' do
        it 'will raise EntityManager::UnknownVirtual' do
          ref = Reference.new('test:missing.a.b')
          entity = em.new_entity(add: true)
          em.schedule(:link, ref: ref, entity: entity)
          expect { em.resolve! }.to raise_error(RuntimeError)
        end
      end
    end
  end
end
