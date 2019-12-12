require 'entity'
require 'component'

describe Entity do
  let(:comp_a) { Class.new(Component) { field :a, default: :a }.new }
  let(:comp_b) { Class.new(Component) { field :b, default: :b }.new }
  let(:klass_multi) { Class.new(Component) { not_unique } }
  let(:components) { [ comp_a, comp_b ] }

  describe '.new(*components, tags: [])' do
    context 'with no components' do
      it 'will have no components' do
        expect(Entity.new.components).to be_empty
      end
    end

    context 'with components' do
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
      it 'will add the components' do
        entity = Entity.new
        entity.add_component(components)
        expect(entity.components).to contain_exactly(*components)
      end
    end
    context 'with a non-duplicate unique component' do
      let(:entity) { Entity.new(comp_a) }

      it 'will add the component' do
        entity.add_component(comp_b)
        expect(entity.components).to contain_exactly(comp_a, comp_b)
      end
    end
    context 'with a duplicate unique component' do
      let(:entity) { Entity.new(comp_a) }

      it 'will raise an DuplicateUniqueComponent error' do
        expect { entity.add_component(comp_a) }
            .to raise_error(Entity::DuplicateUniqueComponent)
      end
    end
  end

  describe '#get_component(type)' do
    let(:entity) do
      e = Entity.new(comp_a, klass_multi.new)
    end

    it 'will return the component if included in the entity' do
      expect(entity.get_component(comp_a.class)).to eq(comp_a)
    end
    it 'will return nil if not present in the entity' do
      expect(entity.get_component(comp_b.class)).to be_nil
    end
    it 'will raise an error if the Component type is unique' do
      expect { entity.get_component(klass_multi) }
          .to raise_error(ArgumentError)
    end
  end

  describe '#get_components(type)' do
    let(:entity) do
      Entity.new(comp_a, klass_multi.new, klass_multi.new)
    end

    it 'will return all the components of the right type' do
      components = entity.get_components(klass_multi)
      expect(components.size).to eq(2)
      expect(components).to all(be_a_kind_of(klass_multi))
    end

    it 'will return an empty array if no matches' do
      expect(entity.get_components(comp_b.class)).to be_empty
    end
  end

  describe '#set(type, pairs)' do
    let(:entity) do
      Entity.new(comp_a)
    end

    context 'when no component of type exists in entity' do
      it 'will raise an error' do
        expect { entity.set(Class.new(Component), 3) }
            .to raise_error(Entity::ComponentNotFound)
      end
    end

    context 'when one component of type exists in entity' do
      context 'when field is supplied' do
        it 'will set the correct field' do
          entity.set(comp_a.class, a: :pass)
          expect(entity.get(comp_a.class, :a)).to eq(:pass)
        end
      end
      context 'when wrong field is supplied' do
        it 'will raise an error' do
          expect { entity.set(comp_a.class, bad_field: :fail) }
              .to raise_error(ArgumentError)
        end
      end
    end
  end
  
  describe '#get(type, *fields)' do
    let(:component) do
      Class.new(Component) do
        field :a, default: :a_val
        field :b, default: :b_val
        field :c, default: :c_val
      end
    end
    let(:entity) { Entity.new(component.new) }

    context 'wth no fields' do
      it 'will raise an ArgumentError' do
        expect { entity.get(component) }.to raise_error(ArgumentError)
      end
    end

    context 'with a single field' do
      context 'that is a member of the Component' do
        it 'will return the value for that key' do
          expect(entity.get(component, :a)).to eq(:a_val)
        end
      end
      context 'that is not a member of the Component' do
        it 'will raise an ArgumentError' do
          expect { entity.get(component, :x) }.to raise_error(ArgumentError)
        end
      end
    end

    context 'with multiple fields' do
      context 'all fields are members of the Component' do
        it 'will return an Array of results' do
          expect(entity.get(component, :a, :c)).to eq([:a_val, :c_val])
        end
      end
      context 'any field is not a member of the Component' do
        it 'will raise an ArgumentError' do
          expect { entity.get(component, :x) }.to raise_error(ArgumentError)
        end
      end
    end
  end

  describe '#merge!(*others)' do
    context 'with a single other' do
      let(:base) { Entity.new }
      let(:other) { Entity.new }
      
      shared_examples 'will merge components' do
        it 'will have all component types present in other' do
          expect(base.components.map(&:class))
              .to include(*other.components.map(&:class))
        end

        it 'will clone any copied components from other' do
          base.components.each do |comp|
            expect(other.components).to_not include(comp)
          end
        end
      end

      it 'will return self' do
        expect(base.merge!(other)).to be(base)
      end

      context 'when the base has no components' do
        before(:each) do
          other.add_component(comp_a)
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
          base_comp = comp_a.clone
          base_comp.a = :fail
          other_comp = comp_a.clone
          other_comp.a = :pass
          base.add_component(base_comp)
          other.add_component(other_comp)
          base.merge!(other)
        end

        include_examples 'will merge components'
        it 'will overwrite component values' do
          expect(base.get(comp_a.class, :a)).to eq(:pass)
        end
      end

      context 'when the base has duplicate non-unique components' do
        before(:each) do
          component = klass_multi
          base.add_component(component.new)
          other.add_component(component.new)
          base.merge!(other)
        end
        include_examples 'will merge components'
        it 'will add the additional components' do
          expect(base.get_components(klass_multi).size).to eq(2)
        end
      end

      context 'when other set component field back to default' do
        before(:each) do
          base_comp = comp_a.clone
          base_comp.a = :fail
          base.add_component(base_comp)

          other_comp = comp_a.clone
          other_comp.a = :a
          other.add_component(other_comp)

          base.merge!(other)
        end
        include_examples 'will merge components'
        it 'will set component field to default' do
          expect(base.get(comp_a.class, :a)).to eq(:a)
        end
      end

      context 'when :all is not set' do
        context 'when only other has a non-merged Component' do
          let(:no_merge_comp) do
            Class.new(Component) { not_merged }.new
          end
          before(:each) do
            other.add_component(no_merge_comp)
            base.merge!(other)
          end
          it 'will not include the other component' do
            expect(base.get_component(no_merge_comp.class)).to be(nil)
          end
        end

        context 'when both have a common non-merged Component' do
          let(:comp_klass) { Class.new(Component) { not_merged; field :a } }
          let(:base_comp) { comp_klass.new(a: :pass) }
          let(:other_comp) { comp_klass.new(a: :fail) }

          before(:each) do
            base.add_component(base_comp)
            other.add_component(other_comp)
            base.merge!(other)
          end
          it 'will not include the other component' do
            expect(base.get(comp_klass, :a)).to eq(:pass)
          end
        end
      end

      context 'when :all is set' do
        context 'when only other has a non-merged Component' do
          let(:no_merge_comp) do
            Class.new(Component) { not_merged }.new
          end
          before(:each) do
            other.add_component(no_merge_comp)
            base.merge!(other, all: true)
          end
          it 'will not include the other component' do
            expect(base.get_component(no_merge_comp.class)).to_not be(nil)
          end
        end

        context 'when both have a common non-merged Component' do
          let(:comp_klass) { Class.new(Component) { not_merged; field :a } }
          let(:base_comp) { comp_klass.new(a: :fail) }
          let(:other_comp) { comp_klass.new(a: :pass) }

          before(:each) do
            base.add_component(base_comp)
            other.add_component(other_comp)
            base.merge!(other, all: true)
          end
          it 'will not include the other component' do
            expect(base.get(comp_klass, :a)).to eq(:pass)
          end
        end
      end
    end
  end
end
