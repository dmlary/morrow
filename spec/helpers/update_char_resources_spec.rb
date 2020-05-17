describe 'Morrow::Helpers.update_char_resources' do
  let(:entity) { create_entity(base: 'spec:char/actor') }
  let(:char) { get_component!(entity, :character) }

  before(:all) { reset_world }

  context 'entity is not a character' do
    it 'will raise InvalidEntity' do
      ball = create_entity(base: 'spec:obj/ball')
      expect { update_char_resources(ball) }
          .to raise_error(Morrow::InvalidEntity)
    end
  end

  context 'new health_max is higher than current health' do
    before(:each) do
      expect(self).to receive(:char_health_base).and_return(100)
      char.health = 200
      update_char_resources(entity)
    end

    it 'will reduce current health to health_max' do
      expect(char.health).to eq(100)
    end
  end

  # this is complex to test at this level:
  #   max_hp = avg(hp_per_level for each class) * level * con bonus
  #     + (bonus hp * hp multiplier)
  #
  #   max_hp = char_health_base * con bonus
  # Consider breaking out some of these pieces into individual helpers to
  # simplify testing.
  [
  ].each do |t|
    context t[:desc] do
    end
  end
end
