RSpec.describe 'Helpers.update_char_inventory_limits' do
  let(:entity)  { spawn(base: 'spec:char/actor') }
  let(:char)    { get_component!(entity, :character) }
  let(:inv)     { get_component!(entity, :container) }

  before(:all) { reset_world }

  context 'entity is not a character' do
    let(:ball) { create_entity(base: 'spec:obj/ball') }

    it 'will not raise an error' do
      expect { update_char_inventory_limits(ball) }.to_not raise_error
    end

    it 'will not add the container component' do
      update_char_inventory_limits(ball)
      expect(get_component(ball, :container)).to eq(nil)
    end
  end

  it 'will set max_weight to the str value from the config table' do
    table = 31.times.map { |i| "failed_#{i}" }
    table[12] = :passed

    expect(Morrow.config).to receive(:char_inventory_max_weight)
        .and_return(table)

    allow(self).to receive(:char_attr).and_return(1)
    expect(self).to receive(:char_attr)
        .with(entity, :str)
        .and_return(12)

    inv.max_weight = :unchanged

    update_char_inventory_limits(entity)
    expect(inv.max_weight).to eq(:passed)
  end

  it 'will set max_value to the dex value from the config table' do
    table = 31.times.map { |i| "failed_#{i}" }
    table[30] = :passed

    expect(Morrow.config).to receive(:char_inventory_max_volume)
        .and_return(table)

    allow(self).to receive(:char_attr).and_return(1)
    expect(self).to receive(:char_attr)
        .with(entity, :dex)
        .and_return(30)

    inv.max_volume = :unchanged

    update_char_inventory_limits(entity)
    expect(inv.max_volume).to eq(:passed)
  end
end
