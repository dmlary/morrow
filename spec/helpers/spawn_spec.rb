RSpec.describe 'Morrow::Helpers#spawn' do
  before(:all) { reset_world }

  context 'area provided' do
    it 'will set Metadata.area to the area provided' do
      entity = spawn(base: [], area: :passed)
      expect(get_component(entity, :metadata).area).to eq(:passed)
    end
  end

  context 'base includes a template component' do
    let(:base) { create_entity(components: %i{ template }) }

    before do
      get_component!(base, :character).health_max =
          Morrow::Function.new('{ 1234 }').dup
    end

    it 'will evaluate any function field values' do
      entity = spawn(base: base)
      expect(get_component(entity, :character).health_max).to eq(1234)
    end

    it 'will pass the correct arguments to a function field value' do
      expect(get_component(base, :character).health_max)
          .to receive(:call) do |**p|
        expect(p[:component]).to be_a(Class)
        expect(p[:field]).to eq(:health_max)
      end
      spawn(base: base)
    end
  end

  context 'base does not include a template component' do
    let(:base) do
      b = create_entity(components: %i{})
    end

    before do
      get_component!(base, :character).health_max =
          Morrow::Function.new('{ }').dup
    end

    it 'will not evaluate any function field values' do
      expect(get_component(base, :character).health_max)
          .to_not receive(:call)
      spawn(base: base)
    end
  end

  context 'error in field function' do
    let(:template) { create_entity(components: %i{ template }) }

    before do
      # We're going to cause an exception here by giving our template entity a
      # reference to an invalid base entity, then add a function to the
      # template entity to pull the value from the base.  This should cause an
      # UnknownEntity exception when we spawn.
      get_component!(template, :metadata).base = [ 'does not exist' ]
      get_component!(template, :character).health_max =
          Morrow::Function.new('{ base }')
    end

    it 'will raise an error and destroy the incomplete entity' do
      aggregate_failures do
        expect(self).to receive(:destroy_entity)
        expect { spawn(base: template) }.to raise_error(Morrow::UnknownEntity)
      end
    end
  end
end
