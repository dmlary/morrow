describe Morrow::Command::Flee do
  let(:actor) { 'spec:char/actor' }
  let(:victim) { 'spec:char/victim' }
  let(:attacker) { 'spec:char/attacker' }

  table = [
    { desc: 'actor not in combat',
      room: 'spec:room/no_exits', 
      in_combat: false,
      move: false,
      output: described_class::MSG_NOT_IN_COMBAT },
    { desc: 'actor in combat in a room with a single closed exit',
      room: 'spec:room/door/closed',
      in_combat: true,
      move: false,
      output: described_class::MSG_NO_ESCAPE },
    { desc: 'actor in combat in a room with single open exit fails check',
      room: 'spec:room/door/open',
      in_combat: true,
      fail: true,
      move: false,
      output: described_class::MSG_FAILED },
    { desc: 'actor in combat in a room with single open exit passes check',
      room: 'spec:room/door/open',
      in_combat: true,
      fail: false,
      move: true,
      output: described_class::MSG_SUCCESS },
    { desc: 'actor flees successfully, but destination is full',
      room: 'spec:room/door/open',
      in_combat: true,
      fail: false,
      dest_full: true,
      move: false,
      output: described_class::MSG_EXIT_FULL },
  ].each do |p|
    context p[:desc] do
      room = p[:room]

      # Helper methods:
      # * convert symbol into send(sym) for lets
      before(:each) do
        reset_world
        move_entity(entity: actor, dest: room)
        move_entity(entity: victim, dest: room)

        enter_combat(actor: actor, target: victim) if p[:in_combat]

        allow(described_class).to receive(:rand) do |x|
          p[:fail] ? 0 : (x-1)
        end

        allow(described_class).to receive(:move_entity)
            .and_raise(Morrow::EntityWillNotFit) if p[:dest_full]

        run_cmd(actor, 'flee')
      end

      msg = strip_color_codes(p[:output])
      it 'will output "%s"' % msg do
        expect(player_output(actor)).to include(msg)
      end

      if p[:move]
        it 'will move the actor' do
          expect(entity_location(actor)).to_not eq(room)
        end

        it 'will show the destination room' do
          expect(player_output(actor)).to include('Exits: ')
        end

        it 'will remove the combat component from the actor' do
          expect(get_component(actor, :combat)).to be_nil
        end
      else
        it 'will not move the actor' do
          expect(entity_location(actor)).to eq(room)
        end
      end
    end
  end
end
