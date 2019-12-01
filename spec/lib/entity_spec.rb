require 'entity'
require 'component'

describe Entity do
  before(:each) { Component.reset! }
  describe '.new(*components, tags: [])' do
    context 'with no components' do
      it 'will have no components' do
        expect(Entity.new.components).to be_empty
      end
    end

    context 'with components' do
      let(:components) do
        Component.define(:a)
        Component.define(:b)
        [ Component.new(:a), Component.new(:b) ]
      end

      let(:entity) do
        Entity.new(components)
      end

      it 'will include supplied components' do
        expect(entity.components).to contain_exactly(*components)
      end
    end

    context 'with a single tag supplied' do
      it 'will set the tag'
    end

    context 'with multiple tags supplied' do
      it 'will include each tag'
    end
  end

  describe '#id' do
    let(:entity) { Entity.new }
    it 'will return the entity id' do
      expect(entity.id).to eq(entity.__id__)
    end
  end

  describe '#add_component(*components)' do
    context 'with multiple components' do
      let(:components) do
        Component.define(:a)
        Component.define(:b)
        [ Component.new(:a), Component.new(:b) ]
      end

      it 'will add the components' do
        entity = Entity.new
        entity.add_component(components)
        expect(entity.components).to contain_exactly(*components)
      end
    end
    context 'with a non-duplicate unique component' do
      let(:comp_a) { Component.define(:a).new }
      let(:comp_b) { Component.define(:b).new }
      let(:entity) { Entity.new(comp_a) }

      it 'will add the component' do
        entity.add_component(comp_b)
        expect(entity.components).to contain_exactly(comp_a, comp_b)
      end
    end
    context 'with a duplicate unique component' do
      let(:comp_a) { Component.define(:a).new }
      let(:entity) { Entity.new(comp_a) }

      it 'will raise an DuplicateUniqueComponent error' do
        expect { entity.add_component(comp_a) }
            .to raise_error(Entity::DuplicateUniqueComponent)
      end
    end
  end

  describe '#get_component(type)' do
    let(:entity) do
      Component.reset!
      a = Component.define(:a).new
      b = Component.define(:b).new
      e = Entity.new(a, b)
    end

    it 'will return the component if included in the entity' do
      expect(entity.get_component(:a)).to_not be_nil
      expect(entity.get_component(:a).type).to eq(:a)
    end
    it 'will return nil if not present in the entity' do
      expect(entity.get_component(:x)).to be_nil
    end
  end

  describe '#get_components(type)' do
    let(:entity) do
      Component.reset!
      Component.define(:a, unique: false)
      Component.define(:b)
      Entity.new(Component.new(:a), Component.new(:a), Component.new(:b))
    end

    it 'will return all the components of the right type' do
      components = entity.get_components(:a)
      expect(components.size).to eq(2)
      expect(components).to all(have_attributes(type: :a))
    end

    it 'will return an empty array if no matches' do
      expect(entity.get_components(:x)).to be_empty
    end
  end

  describe '#set(type, field=:value, value)' do
    let(:entity) do
      Component.reset!
      Component.define(:test_comp,
          fields: {value: :unchanged, name: :unchanged})
      Entity.new(Component.new(:test_comp))
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
          expect(entity.get(:test_comp, :name)).to eq(:pass)
        end
      end
      context 'when field is not supplied' do
        it 'will set the correct field' do
          entity.set(:test_comp, :pass)
          expect(entity.get(:test_comp)).to eq(:pass)
        end
      end
      context 'when wrong field is supplied' do
        it 'will raise an error' do
          expect { entity.set(:test_comp, :bad_field, :fail) }
              .to raise_error(Component::InvalidField)
        end
      end
    end
  end

  describe '#merge!(*others)' do
    context 'with a single other' do
      let(:base) { Entity.new }
      let(:other) { Entity.new }
      let(:uniq_comp) { Component.define(:unique, fields: { value: nil }) }
      let(:comp_a) { Component.define(:a).new }
      let(:comp_b) { Component.define(:b).new }
      
      shared_examples 'will merge components' do
        it 'will have all component types present in other' do
          expect(base.components.map(&:type))
              .to include(*other.components.map(&:type))
        end

        it 'will clone any copied components from other' do
          base.components.each do |comp|
            expect(other.components).to_not include(comp)
          end
        end
      end

      context 'when the base has no components' do
        before(:each) do
          other.add_component(uniq_comp.new)
          base.merge!(other)
        end

        include_examples 'will merge components'
      end

      context 'when the base has existing components' do
        before(:each) do
          base.add_component(comp_a)
          other.add_component(comp_b)
          base.merge!(other)
        end
        it 'will keep its existing components' do
          expect(base.components).to include(comp_a)
        end
        include_examples 'will merge components'
      end

      context 'when the base has duplicate unique components' do
        before(:each) do
          base.add_component(uniq_comp.new(:fail))
          other.add_component(uniq_comp.new(:pass))
          base.merge!(other)
        end

        include_examples 'will merge components'
        it 'will overwrite component values' do
          expect(base.get(:unique)).to eq(:pass)
        end
      end

      context 'when the base has duplicate non-unique components' do
        before(:each) do
          component = Component.define(:dup, unique: false)
          base.add_component(component.new)
          other.add_component(component.new)
          base.merge!(other)
        end
        include_examples 'will merge components'
        it 'will add the additional components' do
          expect(base.get_components(:dup).size).to eq(2)
        end
      end

      context 'when other set component field back to default' do
        before(:each) do
          component = Component.define(:layer, fields: {value: :pass})
          base.add_component(component.new(:fail))
          other.add_component(component.new(:pass))
          base.merge!(other)
        end
        include_examples 'will merge components'
        it 'will set component field to default' do
          expect(base.get(:layer)).to eq(:pass)
        end
      end
    end
  end
end
