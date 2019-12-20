require 'entity_manager'

describe EntityManager do
  let(:em) do
    World.entity_manager = EntityManager.new
  end
  let(:comp) { Class.new(Component) }

  describe '#create_entity()' do
    shared_examples 'will create an entity' do
      it 'will return a String' do
        expect(id).to be_a(String)
      end
      it 'will add the entity to the entities hash' do
        expect(em.entities[id]).to be_a(Hash)
      end
      it 'will not return an existing id' do
        expect(em.entities.keys).to_not include(id)
      end
    end

    context 'with no arguments' do
      let(:id) { em.create_entity }
      context 'when called the first time' do
        include_examples 'will create an entity'
      end

      context 'when called multiple times' do
        before(:each) { 5.times { em.create_entity } }
        include_examples 'will create an entity'
      end
    end

    context 'with an id provided' do
      context 'that does not exist' do
        let(:id) { em.create_entity(id: 'test:by_id') }
        include_examples 'will create an entity'
      end

      context 'that already exists' do
        it 'will raise an EntityManager::DuplicateId exception' do
          em.create_entity(id: 'test:duplicate_id')
          expect { em.create_entity(id: 'test:duplicate_id') }
              .to raise_error(EntityManager::DuplicateId)
        end
      end
    end

    context 'with a single base' do
      before(:each) { em.create_entity(id: 'test:base') }
      let(:id) { em.create_entity(base: 'test:base') }

      include_examples 'will create an entity'

      it 'will include "test:base" in the entity id' do
        expect(id).to include('test:base')
      end

      it 'will call EntityManager#merge_entity(id, "test:base")' do
        expect(em).to receive(:merge_entity) do |dest, base|
          expect(base).to eq('test:base')
        end
        id
      end
    end

    context 'with multiple bases' do
      before(:each) do
        em.create_entity(id: 'test:base_a')
        em.create_entity(id: 'test:base_b')
      end
      let(:id) { em.create_entity(base: [ 'test:base_a', 'test:base_b' ]) }

      include_examples 'will create an entity'

      it 'will include "test:base_a" in the entity id' do
        expect(id).to include('test:base_a')
      end

      it 'will not include "test:base_b" in the entity id' do
        expect(id).to_not include('test:base_b')
      end

      it 'will call EntityManager#merge_entity() for each base in order' do
        expect(em).to receive(:merge_entity).ordered do |dest, base|
          expect(base).to eq('test:base_a')
        end
        expect(em).to receive(:merge_entity).ordered do |dest, base|
          expect(base).to eq('test:base_b')
        end
        id
      end
    end

    context 'with a single component' do
      let(:id) { em.create_entity(components: comp) }
      include_examples 'will create an entity'

      it 'will call EntityManager#add_component() with the component' do
        expect(em).to receive(:add_component) do |_,*components|
          expect(components).to eq([ comp ])
        end
        id
      end
    end

    context 'with multiple components' do
      let(:components) { 3.times.map { comp.new } }
      let(:id) { em.create_entity(components: components) }
      include_examples 'will create an entity'

      it 'will call EntityManager#add_component() with the components' do
        expect(em).to receive(:add_component) do |_,*component|
          expect(component).to eq(components)
        end
        id
      end
    end

    context 'with base and components' do
      it 'will apply base before merging components' do
        expect(em).to receive(:merge_entity).ordered
        expect(em).to receive(:add_component).ordered
        em.create_entity(base: 'test:base', components: :wolf)
      end
    end
  end

  describe '#add_component(entity, component)' do
    context 'entity does not exist' do
      it 'will raise EntityManager::UnknownId' do
        other = em.create_entity
        expect { em.merge_entity('missing', other) }
            .to raise_error(EntityManager::UnknownId)
      end
    end

    context 'with a unique component instance' do
      let(:id) { em.create_entity }
      let(:comp) { Class.new(Component) }
      let(:instance) { comp.new }

      it 'will add that instance to the entity' do
        em.add_component(id, instance)
        expect(em.entities[id][comp]).to be(instance)
      end
    end

    context 'with a unique component class' do
      let(:id) { em.create_entity }
      let(:comp) { Class.new(Component) }

      it 'will create a new instance of the component' do
        expect(comp).to receive(:new)
        em.add_component(id, comp)
      end

      it 'will add a component instance to the entity' do
        em.add_component(id, comp)
        expect(em.entities[id][comp]).to be_a(comp)
      end
    end

    context 'with a non-unique component instance' do
      let(:id) { em.create_entity }
      let(:comp) { Class.new(Component) { not_unique } }
      let(:instance) { comp.new }

      it 'will add that instance to the entity' do
        em.add_component(id, instance)
        expect(em.entities[id][comp]).to eq([instance])
      end
    end

    context 'with a non-unique component class' do
      let(:id) { em.create_entity }
      let(:comp) { Class.new(Component) { not_unique } }

      it 'will create a new instance of the component' do
        expect(comp).to receive(:new)
        em.add_component(id, comp)
      end

      it 'will add a component instance to the entity' do
        em.add_component(id, comp)
        expect(em.entities[id][comp]).to include(be_a(comp))
      end
    end
  end

  describe '#get_component(id, comp)' do
    context 'entity does not exist' do
      it 'will raise EntityManager::UnknownId' do
        expect { em.get_component('missing', comp) }
            .to raise_error(EntityManager::UnknownId)
      end
    end

    context 'with a unique component' do
      context 'that has been added to the entity' do
        it 'will return the component instance for that entity' do
          instance = comp.new
          id = em.create_entity(components: instance)
          expect(em.get_component(id, comp)).to be(instance)
        end
      end
      context 'that is absent from the entity' do
        it 'will return nil' do
          id = em.create_entity
          expect(em.get_component(id, comp)).to be(nil)
        end
      end
    end

    context 'with a non-unique component' do
      it 'will raise an error'
    end
  end

  describe '#merge_entity(dest, other)' do
    context 'dest does not exist' do
      it 'will raise EntityManager::UnknownId' do
        other = em.create_entity
        expect { em.merge_entity('missing', other) }
            .to raise_error(EntityManager::UnknownId)
      end
    end
    context 'other does not exist' do
      it 'will raise EntityManager::UnknownId' do
        base = em.create_entity
        expect { em.merge_entity(base, 'missing') }
            .to raise_error(EntityManager::UnknownId)
      end
    end

    context 'when other has a component missing in dest' do
      let(:comp) { Class.new(Component) { field :value } }
      let(:dest) { em.create_entity }
      let(:other) { em.create_entity(components: comp.new(value: :pass)) }

      it 'will copy other component into dest' do
        em.merge_entity(dest, other)
        expect(em.get_component(dest, comp).value).to eq(:pass)
      end
    end

    context 'when both have a unique component' do
      it 'will call Component#merge!(dest, other)'
    end

    context 'when both have a non-unique component' do
      it 'will copy other component into dest'
    end
  end

end

#   describe '#new_entity()' do
#     let(:entity) { Entity.new }
# 
#     context 'when called with no arguments' do
#       it 'will return an Entity with no Components' do
#         expect(em.new_entity.components).to be_empty
#       end
#     end
# 
#     shared_examples 'will return a merged Entity' do
#       it 'will return an Entity instance' do
#         expect(em.new_entity(arg)).to be_a_kind_of(Entity)
#       end
#       it 'will not add the Entity to the EntityManager' do
#         new = em.new_entity(arg)
#         expect(em.entity_by_id(new.id)).to be_nil
#       end
#       it 'will call Entity#merge! on the base Entity' do
#         expect_any_instance_of(Entity).to receive(:merge!).with(entity)
#         em.new_entity(arg)
#       end
#     end
# 
#     context 'when called with an Entity argument' do
#       let(:arg) { entity }
#       include_examples 'will return a merged Entity'
#     end
#     context 'when called with a Reference argument' do
#       before(:each) { em.add(entity) }
#       let(:arg) { entity.to_ref }
#       include_examples 'will return a merged Entity'
#     end
#     context 'when called with a String argument' do
#       before(:each) do
#         entity << VirtualComponent.new(id: 'test:entity')
#         em.add(entity)
#       end
#       let(:arg) { 'test:entity' }
#       include_examples 'will return a merged Entity'
#     end
#     context 'when called with an Array' do
#       # Ran into problems implementing this with a expect_any_instance_of mock.
#       it 'will call Entity#merge! Array.size times'
#     end
# 
#     context 'component: [ Component ]' do
#       let(:comp) { Class.new(Component) }
# 
#       context 'the Component is unique' do
#         context 'and exists in base' do
#           let(:comp_arg) { comp.new }
#           let(:other_comp) { comp.new }
#           let(:other) { Entity.new(other_comp) }
#           it 'will call #merge! on the base Component' do
#             expect_any_instance_of(comp).to receive(:merge!).with(comp_arg)
#             em.new_entity(other, components: [comp_arg])
#           end
#         end
#         context 'and does not exist in base' do
#           it 'will add the Component to base' do
#             component = comp.new
#             entity = em.new_entity(components: [component])
#             expect(entity.components).to include(component)
#           end      
#         end
#       end
#       context 'the Component is not unique' do
#         it 'will add the Component to base' do
#           comp = Class.new(Component) { not_unique }
#           base_comp = comp.new
#           add_comp = comp.new
#           base = Entity.new(base_comp)
#           entity = em.new_entity(base, components: [add_comp])
#           expect(entity.get_components(comp).size).to eq(2)
#         end
#       end
#     end
# 
#     context 'add: false' do
#       it 'will not call EntityManager#add' do
#         expect(em).to_not receive(:add)
#         em.new_entity(add: false)
#       end
# 
#       context 'link: [ Reference ]' do
#         it 'will raise an ArgumentError' do
#           ref = em.new_entity(add: true).to_ref
#           expect { em.new_entity(add: false, link: [ref]) }
#               .to raise_error(ArgumentError)
#         end
#       end
#     end
# 
#     context 'add: true' do
#       it 'will call EntityManager#add' do
#         expect(em).to receive(:add)
#         em.new_entity(add: true)
#       end
# 
#       context 'link: [ Reference ]' do
#         let(:ref) { em.new_entity(add: true).to_ref }
# 
#         it 'will call EntityManager#schedule(:link, ref: ref, entity: ?)' do
#           expect(em).to receive(:schedule) do |name,args|
#             expect(name).to be(:link)
#             expect(args).to include(ref: ref)
#           end
#           em.new_entity(add: true, links: [ ref ])
#         end
#       end
#     end
#   end
# 
#   describe '#schedule(task, args)' do
#     it 'will call @tasks.push' do
#       expect(em.instance_variable_get(:@tasks)).to receive(:push)
#       em.schedule(:link, ref: nil, entity: nil)
#     end
#   end
# 
#   describe '#resolve!' do
#     before(:all) { Helpers::Logging.logger.level = Logger::ERROR }
#     context 'a :new_entity task' do
#       context 'with only arguments' do
#         it 'will call #new_entity(*args)' do
#           em.schedule(:new_entity, [1, 2, 3])
#           expect(em).to receive(:new_entity) do |*others|
#             expect(others).to eq([1,2,3])
#           end
#           em.resolve!
#         end
#       end
# 
#       context 'with only parameters' do
#         it 'will call #new_entity with parameters' do
#           em.schedule(:new_entity, add: true)
#           expect(em).to receive(:new_entity) do |*args, add: false|
#             expect(add).to be(true)
#           end
#           em.resolve!
#         end
#       end
# 
#       context 'with arguments & parameters' do
#         it 'will call #new_entity with args & parameters' do
#           em.schedule(:new_entity, [ 'test:room', add: true ])
#           expect(em).to receive(:new_entity) do |*args, add: false|
#             expect(args).to eq(['test:room'])
#             expect(add).to be(true)
#           end
#           em.resolve!
#         end
#       end
# 
#       context 'with an unknown base' do
#         it 'will raise a RuntimeError' do
#           em.schedule(:new_entity, 'missing')
#           expect { em.resolve! }.to raise_error(RuntimeError)
#         end
#       end
# 
#       context 'with an unknown link' do
#         it 'will raise a RuntimeError' do
#           em.schedule(:new_entity, add: true,
#               links: [Reference.new('test:missing.other.thing')])
#           expect { em.resolve! }.to raise_error(RuntimeError)
#         end
#       end
#     end
# 
#     context 'a :link task' do
#       context 'with a Reference to a valid Entity' do
#         let(:dest) do
#           e = Entity.new
#           e << VirtualComponent.new(id: 'test:entity')
#           e << ContainerComponent.new
#           e
#         end
#         before(:each) { em << dest }
# 
#         context 'to an Array value' do
#           it 'will push an Entity reference onto the Array' do
#             ref = Reference.new('test:entity.container.contents')
#             entity = em.new_entity(add: true)
#             em.schedule(:link, ref: ref, entity: entity)
#             em.resolve!
#             expect(dest.get(:container, :contents).map(&:entity))
#                 .to eq([entity])
#           end
#         end
#         context 'to a non-Array value' do
#           it 'will replace the value' do
#             ref = Reference.new('test:entity.container.max_volume')
#             entity = em.new_entity(add: true)
#             em.schedule(:link, ref: ref, entity: entity)
#             em.resolve!
#             expect(dest.get(:container, :max_volume).entity)
#                 .to be(entity)
#           end
#         end
#       end
# 
#       context 'with a Reference to an undefined Entity' do
#         it 'will raise EntityManager::UnknownVirtual' do
#           ref = Reference.new('test:missing.a.b')
#           entity = em.new_entity(add: true)
#           em.schedule(:link, ref: ref, entity: entity)
#           expect { em.resolve! }.to raise_error(RuntimeError)
#         end
#       end
#     end
#   end
# 
#   describe '#get_view' do
#     context 'for a new view' do
#       it 'will create a new View instance' do
#         args = {
#             all: [ VirtualComponent ],
#             any: [ ExitsComponent ],
#             excl: [ ContainerComponent ] }
# 
#         expect(EntityManager::View).to receive(:new) do |p|
#           expect(p).to eq(args)
#         end
#         em.get_view(args)
#       end
# 
#       context 'without ViewExemptComponent in a parameter' do
#         it 'will add ViewExemptComponent to the exclude list' do
#           expect(EntityManager::View).to receive(:new) do |p|
#             expect(p[:excl]).to include(ViewExemptComponent)
#           end
#           em.get_view()
#         end
#       end
# 
#       %i{ all any }.each do |type|
#         context "with ViewExemptComponent in #{type}" do
#           it 'will not add ViewExemptComponent to the exclude list' do
#             expect(EntityManager::View).to receive(:new) do |p|
#               expect(p[:excl]).to_not include(ViewExemptComponent)
#             end
#             em.get_view(type => [ ViewExemptComponent ])
#           end
#         end
#       end
#     end
#     context 'for an existing view' do
#       it 'will return the existing view' do
#         a = em.get_view(all: [ ContainerComponent ])
#         b = em.get_view(all: [ ContainerComponent ])
#         expect(a).to be(b)
#       end
#     end
#   end
#end
