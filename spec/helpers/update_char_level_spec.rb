describe 'Morrow::Helpers.update_char_level' do
  let(:char) { create_entity(base: 'spec:char/actor') }
  let(:char_comp) { get_component!(char, :character) }

  before(:all) { reset_world }

  context 'entity is not a character' do
    it 'will raise InvalidEntity' do
      ball = create_entity(base: 'spec:obj/ball')
      expect { update_char_level(ball) }
          .to raise_error(Morrow::InvalidEntity)
    end
  end

  [ { desc: 'character has nil class_level',
      class_level: nil,
      before: 10,
      after: 10 },
    { desc: 'character has empty class_level',
      class_level: {},
      before: 10,
      after: 10 },
    { desc: 'character is level 1, class level 5 warrior',
      class_level: { warrior: 5 },
      before: 1,
      after: 5 },
    { desc: 'character is level 5, class level 5 warrior, 10 thief',
      class_level: { warrior: 5, thief: 10 },
      before: 1,
      after: 10 },
    { desc: 'character is level 20, class level 5 warrior, 10 thief',
      class_level: { warrior: 5, thief: 10 },
      before: 20,
      after: 10 },
  ].each do |t|
    context t[:desc] do
      before(:each) do
        char_comp.level = t[:before]
        char_comp.class_level = t[:class_level]
        update_char_level(char)
      end

      if t[:before] == t[:after]
        it 'level will remain %d' % t[:after] do
          expect(char_level(char)).to eq(t[:after])
        end
      else
        it 'will change level to %d' % t[:after] do
          expect(char_level(char)).to eq(t[:after])
        end
      end
    end
  end
end
