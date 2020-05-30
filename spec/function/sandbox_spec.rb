RSpec.describe Morrow::Function::Sandbox do
  before(:all) { reset_world }

  let(:sandbox) { described_class.new(entity: entity) }
  let(:entity) { create_entity(base: 'spec:char') }

  describe '#level' do
    before { get_component(entity, :character).level = 10 }

    it 'will return entity level' do
      expect(sandbox.level).to eq(10)
    end
  end

  describe '#by_level' do
    where(:range, :max_at, :level, :value) do
      [ [10..30, 65,   1, 10],
        [10..30, 65,  65, 30],
        [10..30, 65, 100, 30],
        [ 1..30, 30,   3,  3],
        [ 1..30, 30,  12, 12],
      ]
    end

    with_them do
      before { get_component(entity, :character).level = level }

      it 'will return the correct value' do
        expect(sandbox.by_level(range, max_at: max_at)).to eq(value)
      end
    end
  end

  describe '#base' do
    let(:base) { create_entity(base: 'spec:char') }
    let(:entity) { create_entity(base: base) }
    let(:sandbox) do
      described_class.new(entity: entity, component: :character,
                          field: :health_max)
    end

    shared_examples 'leak check' do
      it 'will not leak an entity' do
        # ensure the entity is created before we grab the entity count
        sandbox
        original = entities.clone

        sandbox.base
        expect(entities).to contain_exactly(*original)
      end
    end

    context 'base entity does not have the component' do
      before do
        remove_component(base, :character)
      end

      it 'will return the default field value'do
        default = get_component('spec:char', :character)
            .class.fields[:health_max][:default]
        expect(sandbox.base).to eq(default)
      end

      include_examples 'leak check'
    end

    context 'base entity has field has value' do
      before do
        get_component(base, :character).health_max = 100
      end

      it 'returns the value of the field in the base entity' do
        expect(sandbox.base).to eq(100)
      end

      include_examples 'leak check'
    end

    context 'base field has func that returns value' do
      before do
        get_component(base, :character).health_max =
            Morrow::Function.new('{ :passed }')
      end

      it 'will call the function' do
        expect(sandbox.base).to eq(:passed)
      end

      include_examples 'leak check'
    end

    context 'base field has func that calls base' do
      let(:grand_base) { create_entity }

      before do
        get_component(base, :metadata).base = [ grand_base ]
        get_component!(grand_base, :character).health_max =
            Morrow::Function.new('{ :passed }')
        get_component!(base, :character).health_max =
            Morrow::Function.new('{ base }')
      end

      it 'will call the function' do
        expect(sandbox.base).to eq(:passed)
      end

      include_examples 'leak check'
    end



    # missing the context where we chain a few templates.  So think:
    # entity -> morrow:char/template/warrior -> morrow:char/template/base
    # At the moment there is a bug in this because we create a new
    # entity from the base, BUT that new entity's base is exactly what we
    # just created.  So we end up creating the same entity over and over
    # again, thinking we're traversing.
  end
end
