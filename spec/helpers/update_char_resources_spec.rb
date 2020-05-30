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

  context 'health' do
    where(:base, :mod, :max) do
      [ [ 10, 10, 20 ],
        [ 10,  0, 10 ],
        [  0, 10, 10 ],
      ]
    end

    with_them do
      before do
        allow(self).to receive(:char_health_base).and_return(base)
        char.health_modifier = mod
        update_char_resources(entity)
      end

      it 'will set the new max' do
        expect(char.health_max).to eq(max)
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
  end
end
