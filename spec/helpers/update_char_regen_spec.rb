RSpec.describe 'Helpers.update_char_regen' do
  let(:entity) { spawn(base: 'spec:char/actor') }
  let(:char) { get_component!(entity, :character) }

  before(:all) { reset_world }

  context 'entity is not a character' do
    let(:ball) { create_entity(base: 'spec:obj/ball') }

    it 'will not raise an error' do
      expect { update_char_regen(ball) }.to_not raise_error
    end

    it 'will not add the character component' do
      update_char_regen(ball)
      expect(get_component(ball, :character)).to eq(nil)
    end
  end

  context 'entity is not a non-player character' do
    let(:npc) { spawn(base: 'spec:char') }

    it 'will not raise an error' do
      expect { update_char_regen(npc) }.to_not raise_error
    end
  end

  where(is_npc: [ true, false ])

  with_them do
    where(:health, :pos, :in_combat, :base, :mod, :attr_bonus, :result) do
      [ [  10, :standing, false, 0.2,    0, 1.0, 0.2 ],
        [  10, :standing, true,  0.2,    0, 1.0, 0.0 ],
        [  10, :sitting,  false, 0.2,    0, 1.0, (0.2 * 1.5) ],
        [  10, :sitting,  true,  0.2,    0, 1.0, 0.0 ],
        [  10, :lying,    false, 0.2,    0, 1.0, (0.2 * 2.0) ],
        [  10, :lying,    true,  0.2,    0, 1.0, 0.0 ],

        [  10, :standing, false, 0.2, -0.3, 1.0, (0.2 - 0.3) ],
        [  10, :sitting,  false, 0.2, -0.3, 1.0, ((0.2 - 0.3) * 1.5) ],
        [  10, :lying,    false, 0.2, -0.3, 1.0, ((0.2 - 0.3) * 2.0) ],

        [  10, :standing, false, 0.2,    0, 1.2, (0.2 * 1.2) ],
        [  10, :sitting,  false, 0.2,    0, 1.2, (0.2 * 1.2 * 1.5) ],
        [  10, :lying,    false, 0.2,    0, 1.2, (0.2 * 1.2 * 2.0) ],

        [ -10, :standing, false, 0.2,    0, 1.0, (0.2 * 1.0) ],
        [ -10, :standing, true,  0.2,    0, 1.0, 0.0 ],
        [ -10, :sitting,  false, 0.2,    0, 1.0, (0.2 * 1.5) ],
        [ -10, :sitting,  true,  0.2,    0, 1.0, 0.0 ],
        [ -10, :lying,    false, 0.2,    0, 1.0, (0.2 * 2.0) ],
        [ -10, :lying,    true,  0.2,    0, 1.0, 0.0 ],

        # This is the mortally wounded case, health < -10.  We expect the
        # character to slowly die (< -20 health) over the next 20 seconds.
        # To make this math easy, we're going to hard-code the character's
        # health_max to 10 in the before()
        [ -11, :standing, false, 0.2,    0, 1.0, -0.05 ],
        [ -11, :standing, true,  0.2,    0, 1.0, -0.05 ],
        [ -11, :sitting,  false, 0.2,    0, 1.0, -0.05 ],
        [ -11, :sitting,  true,  0.2,    0, 1.0, -0.05 ],
        [ -11, :lying,    false, 0.2,    0, 1.0, -0.05 ],
        [ -11, :lying,    true,  0.2,    0, 1.0, -0.05 ],
      ]
    end

    with_them do
      before do
        # set up the character to have the correct state
        char.health = health
        char.health_max = 10   # in support of mortally wounded regen
        char.position = pos
        get_component!(entity, :combat).target = 'meep' if in_combat

        char.health_regen_base = base

        if !is_npc and !in_combat and !entity_mortally_wounded?(entity)
          char.class_level = {}
          expect(self).to receive(:player_class_def_value)
              .with(entity, :health_regen)
              .and_return(base)
        end

        char.health_regen_modifier = mod

        allow(self).to receive(:char_attr_bonus)
            .with(entity, :con)
            .and_return(attr_bonus)

        # perform the update
        update_char_regen(entity)
      end

      it 'will set health_regen to the result value' do
        expect(char.health_regen).to eq(result)
      end
    end
  end
end
