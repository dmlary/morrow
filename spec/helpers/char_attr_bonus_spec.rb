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

  [ { desc: 'constitution of 13',
      attr: :con,
      value: 13,
      bonus: 1.0 },
    { desc: 'constitution of 25',
      attr: :con,
      value: 25,
      bonus: 1.12 },
    { desc: 'constitution of 3',
      attr: :con,
      value: 3,
      bonus: 0.9 },
  ].each do |t|
    describe t[:desc] do
      before(:each) do
        allow(self).to receive(:char_attr).and_return(t[:value])
      end

      it 'will return %s' % t[:bonus] do
        expect(char_attr_bonus(entity, t[:attr])).to eq(t[:bonus])
      end
    end
  end
end

