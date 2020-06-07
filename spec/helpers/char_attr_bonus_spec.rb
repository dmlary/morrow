describe 'Morrow::Helpers.char_attr_bonus' do
  let(:entity) { create_entity(base: 'spec:char/actor') }
  let(:char) { get_component!(entity, :character) }

  before(:all) { reset_world }

  context 'entity is not a character' do
    it 'will raise InvalidEntity' do
      ball = create_entity(base: 'spec:obj/ball')
      expect { char_attr_bonus(ball, :con) }
          .to raise_error(Morrow::InvalidEntity)
    end
  end

  where(:attr, :value, :bonus) do
    [ [ :con, 13, 1.0 ],
      [ :con, 25, 1.12 ],
      [ :con, 3, 0.9 ],
    ]
  end

  with_them do
    before(:each) do
      allow(self).to receive(:char_attr).and_return(value)
    end

    it 'will return bonus' do
      expect(char_attr_bonus(entity, attr)).to eq(bonus)
    end
  end
end
