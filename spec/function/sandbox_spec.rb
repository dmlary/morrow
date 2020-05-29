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
        entity
        count = entities.size

        sandbox.base
        expect(entities.size).to eq(count)
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

    context 'base field has func' do
      before do
        # set up the function; use dup to create an unfrozen instance we can
        # mock.
        get_component(base, :character).health_max =
            Morrow::Function.new('{}').dup
      end

      it 'will call the function' do
        expect(get_component(base, :character).health_max).to receive(:call)
        sandbox.base
      end

      include_examples 'leak check'
    end
  end
end
