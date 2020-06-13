describe Morrow::System::Combat do
  let(:room) { 'spec:room/1' }
  let(:other_room) { 'spec:room/2' }
  let(:actor) { spawn(base: 'spec:char/actor') }
  let(:victim) { spawn(base: 'spec:char/victim') }
  let(:actor_combat) { get_component!(actor, :combat) }
  let(:victim_combat) { get_component!(victim, :combat) }

  before(:each) do
    reset_world
    [ actor, victim ].each do |e|
      move_entity(entity: e, dest: room)
      player_output(e).clear
    end
  end

  describe '.update' do
    def run_update
      described_class.update(actor, actor_combat)
    end

    it 'will run once every three seconds' do
      actor_combat.attackers << victim
      expect(described_class).to receive(:update).once

      (3/Morrow.config.update_interval).to_i.times { Morrow.update }
    end

    it 'will update entities in the order they entered combat' do
      enter_combat(actor: actor, target: victim)

      expect(described_class).to receive(:update)
          .with(actor, actor_combat)
          .ordered
      expect(described_class).to receive(:update)
          .with(victim, victim_combat)
          .ordered
      Morrow.update
    end

    where do
      { 'single attacker absent' => {
          attacks: 1,
          attackers: [
            { dead: false,  present: false, hit: false, remove: true },
          ],
          exit_combat: true
        },
        'single attacker dead' => {
          attacks: 1,
          attackers: [
            { dead: true,   present: true,  hit: false, remove: true },
          ],
          exit_combat: true
        },
        'first attacker absent' => {
          attacks: 1,
          attackers: [
            { dead: false,  present: false, hit: false, remove: true },
            { dead: false,  present: true,  hit: true,  remove: false },
          ],
          exit_combat: false,
        },
        'two attackers, two attacks, first attacker dies' => {
          attacks: 2,
          attackers: [
            { dead: false,  present: true,  hit: :kill, remove: true },
            { dead: false,  present: true,  hit: true,  remove: false },
          ],
          exit_combat: false,
        },
        'two attackers, two attacks, first attacker flees' => {
          attacks: 2,
          attackers: [
            { dead: false,  present: true,  hit: :flee, remove: true },
            { dead: false,  present: true,  hit: true,  remove: false },
          ],
          exit_combat: false,
        },
        'two attackers, two attacks, first attacker survives' => {
          attacks: 2,
          attackers: [
            { dead: false,  present: true,  hit: 2,     remove: false },
            { dead: false,  present: true,  hit: false, remove: false },
          ],
          exit_combat: false,
        },
        'one attacker, two attacks, first attacker dies' => {
          attacks: 2,
          attackers: [
            { dead: false,  present: true,  hit: :kill, remove: true },
          ],
          exit_combat: true,
        },
      }
    end

    with_them do
      before do
        # create the attackers
        actor_combat.attackers = attackers.map do |cfg|
          victim = spawn_at(base: 'spec:char/victim',
              dest: cfg[:present] ? room : other_room)

          get_component(victim, :character).health = -21 if cfg[:dead]

          cfg[:entity] = victim
        end

        # set up the number of attacks the actor will perform
        allow(described_class).to receive(:char_attacks).with(actor)
            .and_return(attacks)

        # set up killing blows & wimpy
        allow(described_class).to receive(:hit_entity) do |p|
          cfg = attackers.find { |a| a[:entity] == p[:entity] } or next

          case cfg[:hit]
          when :kill
            damage_entity(actor: p[:actor], entity: p[:entity], amount: 1000)
          when :flee
            move_entity(entity: p[:entity], dest: other_room)
          end
        end
      end

      it 'will call hit_entity() on the expected attackers' do
        attackers.each do |cfg|
          case cfg[:hit]
          when false
            expect(described_class).to_not receive(:hit_entity)
                .with(actor: actor, entity: cfg[:entity]),
                  "should not have hit attacker: #{cfg}"
          when true, Integer
            expect(described_class).to receive(:hit_entity)
                .with(actor: actor, entity: cfg[:entity])
                .exactly(cfg[:hit] == true ? 1 : cfg[:hit]).times,
                  "should have hit attacker: #{cfg}"
          when :kill
            expect(described_class).to receive(:hit_entity) do |p|
              expect(p[:actor]).to eq(actor)
              expect(p[:entity]).to eq(cfg[:entity])
              damage_entity(actor: p[:actor], entity: p[:entity], amount: 1000)
            end
          when :flee
            expect(described_class).to receive(:hit_entity) do |p|
              expect(p[:actor]).to eq(actor)
              expect(p[:entity]).to eq(cfg[:entity])
              move_entity(entity: p[:entity], dest: other_room)
            end
          else
            raise "Unsupported hit value: #{cfg.inspect}"
          end
        end

        run_update
      end

      it 'will remove stale attackers' do
        run_update
        expected = attackers
            .map { |cfg| cfg[:entity] unless cfg[:remove] }.compact
        expect(actor_combat.attackers).to eq(expected)
      end

      it 'will call exit_combat() as needed' do
        if exit_combat
          expect(described_class).to receive(:exit_combat).with(actor)
        else
          expect(described_class).to_not receive(:exit_combat).with(actor)
        end
        run_update
      end
    end

    where(:health, :output, :exit_combat) do
      [ [ 10,   'You are stunned',            false ],
        [ -6,   'You are incapacitated',      false ],
        [ -11,  'You are mortally wounded',   false ],
        [ -21,  nil,                          true ],
      ]
    end

    with_them do
      before do
        actor_combat.attackers << spawn_at(base: 'spec:char/victim',
                                          dest: room)
        get_component!(actor, :character).health = health
        get_component!(actor, :character).unconscious = true
        get_component!(actor, :character).position = :lying

        player_output(actor).clear

        run_update
      end

      it 'will output the appropriate message' do
        if output
          expect(stripped_output(actor)).to include(output)
        else
          expect(stripped_output(actor)).to be_empty
        end
      end
    end
  end
end
