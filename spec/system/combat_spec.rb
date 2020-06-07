describe Morrow::System::Combat do
  let(:room) { 'spec:room/1' }
  let(:actor) { spawn(base: 'spec:char/actor') }
  let(:victim) { spawn(base: 'spec:char/victim') }
  let(:observer) { 'spec:char/observer' }
  let(:attacker) { 'spec:char/attacker' }
  let(:absent) { 'spec:char/absent' }
  let(:actor_combat) { get_component!(actor, :combat) }
  let(:victim_combat) { get_component!(victim, :combat) }
  let(:attacker_combat) { get_component!(attacker, :combat) }

  before(:each) do
    reset_world
    [ actor, victim, observer, attacker ].each do |e|
      move_entity(entity: e, dest: room)
      player_output(e).clear
    end
  end

  describe '.update' do
    def run_update
      described_class.update(actor, actor_combat)
    end

    it 'will run once every three seconds' do
      actor_combat.target = victim
      expect(described_class).to receive(:update).once

      (3/Morrow.config.update_interval).to_i.times { Morrow.update }
    end

    it 'will update entities in the order they entered combat' do
      actor_combat.target = victim
      victim_combat.target = actor

      expect(described_class).to receive(:update)
          .with(actor, actor_combat)
          .ordered
      expect(described_class).to receive(:update)
          .with(victim, victim_combat)
          .ordered
      Morrow.update
    end

    [ { target: :absent,
        attacker: false,
        target_next_attacker: true,
        do_round: false,
        remove: true },
      { target: :absent,
        attacker: true,
        target_next_attacker: true,
        do_round: true,
        remove: false },
      { target: :victim,
        attacker: false,
        target_next_attacker: false,
        do_round: true,
        remove: false },
      { target: :victim,
        attacker: true,
        target_next_attacker: false,
        do_round: true,
        remove: false },
    ].each do |p|
      context 'target is %s, %s additional attackers' %
          [ p[:target], p[:attacker] ? 'with' : 'without' ] do

        before(:each) do
          actor_combat.target = send(p[:target])
          actor_combat.attackers << attacker if p[:attacker]
        end

        if p[:target_next_attacker]
          it 'will try to target the next attacker in the room' do
            expect(described_class).to receive(:find_next_attacker)
                .with(actor_combat, room)
            run_update
          end
        else
          it 'will not try to target the next attacker in the room' do
            expect(described_class).to_not receive(:find_next_attacker)
            run_update
          end
        end

        if p[:do_round]
          it 'will perform a round of combat' do
            expect(described_class).to receive(:do_combat_round)
            run_update
          end
        else
          it 'will not perform a round of combat' do
            expect(described_class).to_not receive(:do_combat_round)
            run_update
          end
        end

        if p[:remove]
          it 'will remove the combat component from actor' do
            run_update
            expect(get_component(actor, :combat)).to eq(nil)
          end

          it 'will call update_char_regen() on actor' do
            expect(described_class).to receive(:update_char_regen)
                .with(actor)
            run_update
          end
        else
          it 'will not remove the combat component from actor' do
            run_update
            expect(get_component(actor, :combat)).to_not be(nil)
          end
        end
      end
    end
  end

  describe '.do_combat_round' do
  end

  describe '.find_next_attacker' do
    def run_method
      described_class.send(:find_next_attacker, actor_combat, room)
    end

    context 'invalid attacker' do
      before(:each) do
        attacker = spawn(base: 'spec:char/attacker')
        attacker_combat.target = actor
        destroy_entity(attacker)
      end

      it 'will not return invalid attacker' do
        expect(run_method).to_not eq('invalid')
      end
      it 'will remove attacker from attackers list' do
        run_method
        expect(actor_combat.attackers).to_not include('invalid')
      end
    end

    context 'absent attacker' do
      before(:each) do
        actor_combat.attackers << absent
      end

      it 'will not return absent attacker' do
        expect(run_method).to_not eq(absent)
      end
      it 'will remove attacker from attackers list' do
        run_method
        expect(actor_combat.attackers).to_not include(absent)
      end
    end

    context 'present attacker' do
      before(:each) do
        actor_combat.attackers << attacker
      end

      it 'will return present attacker' do
        expect(run_method).to eq(attacker)
      end

      it 'will not remove attacker from attackers list' do
        run_method
        expect(actor_combat.attackers).to include(attacker)
      end
    end

    context 'multiple attackers present' do
      before(:each) do
        @attackers = 5.times.map do |i|
          e = spawn(id: "spec:char/attacker-#{i}", base: 'spec:char/attacker')
          get_component!(e, :combat).target = actor
          actor_combat.attackers << e
          e
        end
      end

      it 'will return attacker who first attacked' do
        expect(run_method).to eq(@attackers.first)
      end
    end
  end
end
