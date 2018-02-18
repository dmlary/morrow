require 'entity'
require 'component'

describe Entity do
  before(:each) { Entity.reset! }

  describe '.define(type, *args)' do
    context 'entity type already defined' do
      it 'will raise EntityAlreadyDefined' do
        Entity.define(:test)
        expect { Entity.define(:test) }
            .to raise_error(Entity::AlreadyDefined)
      end
    end
    context 'entity type not defined' do
      it 'will register entity type' do
        expect(Entity.get(:test)).to be_nil
        Entity.define(:test)
        expect(Entity.get(:test)).to_not be_nil
      end
    end
    context 'entity with multiple components as arguments' do
      it 'will add arguments to components' do
        components = %w{ first second third }
        e = Entity.define(:test, *components)
        expect(e.components.map(&:first).flatten)
            .to contain_exactly(*components.map(&:to_sym))
      end
    end
    context 'entity with components as parameters' do
      it 'will add parameters to components' do
        components = %w{ first second third }
        e = Entity.define(:test, components: components)
        expect(e.components.map(&:first).flatten)
            .to contain_exactly(*components.map(&:to_sym))
      end
    end
    context 'entity with components as args and params' do
      it 'will add parameters to components' do
        e = Entity.define(:test, :arg1, :arg2,
                          components: [ :param1, :param2 ])
        expect(e.components.map(&:first).flatten)
            .to contain_exactly(:arg1, :arg2, :param1, :param2)
      end
    end
    context 'entity with include parameter' do
      it 'will add include parameters to includes' do
        includes = %w{ first second third }
        e = Entity.define(:test, include: includes)
        expect(e.includes).to contain_exactly(*includes.map(&:to_sym))
      end
    end
    context 'components with defaults' do
      it 'will set default values' do
        expect { Entity.define(:test, components: [ comp: :default ]) }
            .to_not raise_error
      end
    end

    context 'components with defaults' do
      context 'expressed as an array' do
        let(:entity) do
          Component.reset!
          Component.define(:health, max: :fail, current: :fail)
          Component.define(:name, value: 'unnamed')
          Entity.define(:char,
              components: [
                'name',
                { health: [ :pass, :also_pass ] }
              ])
          Entity.new(:char)
        end
        it 'will set entity.health.max to :pass' do
          expect(entity.get(:health).max).to eq(:pass)
        end
        it 'will set entity.health.current to :pass' do
          expect(entity.get(:health).current).to eq(:also_pass)
        end

      end
    end

    context 'as key/value pairs' do
    end
  end

  describe '.import(data)' do
    context 'with a single entity' do
      it 'will call :define for the entity' do
        expect(Entity).to receive(:define)
            .with('room', {})
            .exactly(1).times
        Entity.import({type: 'room'})
      end
    end

    context 'with multiple entities' do
      it 'will call :define for each entity' do
        expect(Entity).to receive(:define).exactly(3).times
        Entity.import([{type: 'room'}, {type: 'spider'}, {type: 'eek'}])
      end
    end
  end

  describe '.new(type, *components)' do
    context 'entity type is not defined' do
      it 'will raise EntityNotDefined' do
        expect { Entity.new(:test) }
            .to raise_error(Entity::NotDefined)
      end
    end

    context 'entity type is defined' do
      let(:pc) do
        Component.reset!
        Component.define(:health, :max, :current)
        Component.define(:desc, String)
        Component.define(:name, String)
        Component.define(:conn)
        Entity.define(:char, :health, :desc)
        Entity.define(:pc, :name, include: :char)
        Entity.new(:pc, Component.new(:conn))
      end

      it 'will return an Entity instance of the appropriate type' do
        expect(pc.type).to eq(:pc)
      end
      it 'will include components passed in as arguments' do
        expect(pc.components).to include(have_attributes(component: :conn))
      end
      it 'will include components defined in Entity type' do
        expect(pc.components).to include(have_attributes(component: :name))
      end
      it 'will include components from included Entity types' do
        expect(pc.components).to include(have_attributes(component: :desc))
        expect(pc.components).to include(have_attributes(component: :health))
      end
    end

    context 'nested included entity types' do
      let(:pc) do
        Component.reset!
        Component.define(:nested)
        Entity.define(:level3, :nested)
        Entity.define(:level2, include: :level3)
        Entity.define(:level1, include: :level2)
        Entity.define(:level0, include: :level1)
        Entity.new(:level0)
      end

      it 'will include all nested components' do
        expect(pc.components).to include(have_attributes(component: :nested))
      end
    end

    context 'duplicate components in included entities' do
      let(:ab) do
        Component.reset!
        Component.define(:test)
        Entity.define(:a, :test)
        Entity.define(:b, :test)
        Entity.define(:ab, include: [:a, :b])
        Entity.new(:ab)
      end

      it 'will only have one instance of the duplicate component type' do
        expect(ab.components.size).to eq(1)
        expect(ab.components).to include(have_attributes(component: :test))
      end
    end

    context 'duplicate includes' do
      let(:aa) do
        Component.reset!
        Component.define(:test)
        Entity.define(:a, :test)
        Entity.define(:aa, include: [:a, :a])
        Entity.new(:aa)
      end

      it 'will only have one instance of the duplicate component type' do
        expect(aa.components.size).to eq(1)
        expect(aa.components).to include(have_attributes(component: :test))
      end
    end

    context 'argument components overriding default entity components' do
      let(:entity) do
        Component.reset!
        Component.define(:title, :value)
        Component.define(:desc, :value)
        Entity.define(:e, :title, :desc)
        components = [ Component.new(:title, 'wolf'),
                       Component.new(:desc, 'lala') ]
        Entity.new(:e, *components)
      end

      it 'will have title set to "wolf"' do
        expect(entity.get(:title).value).to eq('wolf')
      end
      it 'will have only one instance of component' do
        expect(entity.get(:title, true).size).to eq(1)
      end
    end

    context 'with a tag parameter' do
      let(:entity) do
        Entity.define(:test)
        Entity.new(:test, tag: :test_tag)
      end

      it 'will have a tag set to test_tag' do
        expect(entity.tag).to eq(:test_tag)
      end
    end

    context 'when included entity type is not defined' do
      it 'will raise IncludedEntityNotDefined'
    end

    context 'when component is not defined' do
      it 'will raise ComponentNotDefined'
    end

    context 'when Symbol is provided as argument' do
      it 'will ??? error, or something?'
    end
  end

  describe '.load(types)' do
    context 'any entity type already defined' do
      it 'will raise Entity::AlreadyDefined'
    end
    context 'no entity type is already defined' do
      it 'will define every entity type provided'
    end
  end

  describe '#entity_id' do
    it 'will return the entity id'
  end

  describe '#entity_type' do
    it 'will return the entity type'
  end

  describe '#add(*components)' do
    it 'will add supplied components to the entity'
  end

  describe '#get(component, multiple=false)' do
    let(:entity) do
      Component.reset!
      Component.define(:a)
      Component.define(:b)
      Entity.define(:entity, 'a', 'b')
      Entity.new(:entity)
    end

    it 'will return the component if included in the entity' do
      expect(entity.get(:a)).to_not be_nil
      expect(entity.get(:a).component).to eq(:a)
    end
    it 'will return nil if not present in the entity' do
      expect(entity.get(:x)).to be_nil
    end
  end

  describe '#get(component, true)' do
    let(:entity) do
      Component.reset!
      Component.define(:a)
      Component.define(:b)
      Entity.define(:entity)
      Entity.new(:entity)
          .add(Component.new(:a))
          .add(Component.new(:a))
          .add(Component.new(:b))
    end

    it 'will return all the components of the right type' do
      components = entity.get(:a, true)
      expect(components.size).to eq(2)
      expect(components).to all(have_attributes(component: :a))
    end

    it 'will return an empty array if no matches' do
      expect(entity.get(:x, true)).to be_empty
    end
  end

  describe '#get([components], true)' do
    let (:components) do
      Component.reset!
      Component.define(:a)
      Component.define(:b)
      Component.define(:c)
      Entity.define(:entity)
      Entity.new(:entity)
          .add(Component.new(:a))
          .add(Component.new(:a))
          .add(Component.new(:b))
          .add(Component.new(:c))
          .get([:a, :b], true)
    end

    it 'will return all the components of both types' do
      expect(components).to include(have_attributes(component: :a))
      expect(components).to include(have_attributes(component: :b))
      expect(components).to_not include(have_attributes(component: :c))
    end
  end

  describe '#set(type, field=:value, value)' do
    let(:entity) do
      Entity.reset!
      Component.reset!
      Component.define(:test_comp, value: :unchanged, name: :unchanged)
      Entity.new.add(Component.new(:test_comp))
    end

    context 'when no component of type exists in entity' do
      it 'will raise an error' do
        expect { entity.set(:fake_component, 3) }
            .to raise_error(Entity::ComponentNotFound)
      end
    end

    context 'when one component of type exists in entity' do
      context 'when field is supplied' do
        it 'will set the correct field' do
          entity.set(:test_comp, :name, :pass)
          expect(entity.get_name(:test_comp)).to eq(:pass)
        end
      end
      context 'when field is not supplied' do
        it 'will set the correct field' do
          entity.set(:test_comp, :pass)
          expect(entity.get_value(:test_comp)).to eq(:pass)
        end
      end
      context 'when wrong field is supplied' do
        it 'will raise an error' do
          expect { entity.set(:test_comp, :bad_field, :fail) }
              .to raise_error(Entity::FieldNotFound)
        end
      end
    end

    context 'when multiple components of type exist in entity' do
    end
    let (:components) do
      Component.reset!
      Component.define(:a)
      Component.define(:b)
      Component.define(:c)
      Entity.define(:entity)
      Entity.new(:entity)
          .add(Component.new(:a))
          .add(Component.new(:a))
          .add(Component.new(:b))
          .add(Component.new(:c))
          .get([:a, :b], true)
    end

    it 'will return all the components of both types' do
      expect(components).to include(have_attributes(component: :a))
      expect(components).to include(have_attributes(component: :b))
      expect(components).to_not include(have_attributes(component: :c))
    end
  end
end
