describe Morrow::System::Spawner do
  before(:each) { reset_world }

  let(:bag) { 'spec:obj/spawn-bag' }
  let(:spawn_point) { get_component(bag, :spawn_point) }
  let(:ball) { 'spec:obj/ball' }
  let(:spawn_id) { 'spec:spawn/ball' }
  let(:spawn) { get_component(spawn_id, :spawn) }

  # Fake like we're Morrow.update.  Update the start time, then call the system
  # directly on the bag.
  def run_update
    Morrow.instance_eval { @update_start_time = Time.now }
    Morrow::System::Spawner.update(bag, spawn_point)
  end

  describe '.update(dest, point)' do
    context 'with an empty SpawnPointComponent' do
      it 'will not spawn any entities' do
        spawn_point.list.clear
        before = entities
        run_update
        expect(entities).to eq(before)
      end
    end
    context 'with an invalid entity id in the spawn point' do
      before(:each) do
        spawn_point.list << 'bad_id'
        run_update
      end

      it 'will remove the entity from the spawn point' do
        expect(spawn_point.list).to_not include('bad_id')
      end
    end
    context 'with a valid entity in the spawn point' do
      shared_examples 'spawned entity' do
        it 'will set MetadataComponent.spawned_by in spawned entities' do
          before = entities
          run_update
          spawned = entities - before
          spawned.each do |id|
            expect(get_component(id, :metadata).spawned_by).to eq(spawn_id)
          end
        end
      end

      context 'with less than minimum active' do
        before(:each) do
          spawn.min = 2
          spawn.active = 0
          spawn.max = 10
          spawn.frequency = 90
          spawn.next_spawn = now
        end

        it 'will spawn an entity at each call until minimum active' do
          before = entities
          10.times { run_update }
          after = entities
          expect((after - before).size).to eq(2)
        end

        it 'will set spawn.active to 2' do
          10.times { run_update }
          expect(spawn.active).to eq(2)
        end

        include_examples 'spawned entity'
      end

      context 'with more than minimum, less than max active' do
        before(:each) do
          spawn.min = 2
          spawn.active = 2
          spawn.max = 10
          spawn.frequency = 1
          spawn.next_spawn = now

          # math here: frequency is 1 second, we update every 1/4 second, so we
          # should avoid any weirdness if we call update 6 seconds, expecting
          # two entities to have spawned.
        end

        it 'will spawn one entity each frequency' do
          before = entities
          6.times { run_update; sleep 0.25 }
          after = entities
          expect((after - before).size).to eq(2)
        end

        it 'will set spawn.active to 4' do
          6.times { run_update; sleep 0.25 }
          expect(spawn.active).to eq(4)
        end
      end

      context 'with less than max active, and stale next_spawn' do
        before(:each) do
          spawn.active = 0
          spawn.min = 2
          spawn.max = 10
          spawn.frequency = 10
          spawn.next_spawn = now
        end

        context 'next_spawn less than max * frequency in the past' do
          it 'will spawn enough entities for next_spawn to not be stale' do
            # spawn time was 55 seconds ago; the extra 5 seconds are to avoid
            # falling right on an extra spawn interval.
            spawn.next_spawn = Time.now - (5 * spawn.frequency) + 5
            10.times { run_update }
            expect(spawn.active).to eq(5)
          end
        end
        context 'next_spawn greater than max * frequency in the past' do
          it 'will spawn at most max entities' do
            spawn.next_spawn = Time.now - (100 * spawn.frequency)
            20.times { run_update }
            expect(spawn.active).to eq(10)
          end
        end
      end

      context 'when it spawns the last entity' do
        before(:each) do
          spawn.min = 2
          spawn.active = 9
          spawn.max = 10
          spawn.next_spawn = now

          run_update
        end

        it 'will set active to max' do
          expect(spawn.active).to eq(spawn.max)
        end

        it 'will clear next_spawn' do
          expect(spawn.next_spawn).to eq(nil)
        end
      end

      context 'when at maximum active' do
        before(:each) do
          spawn.active = 10
          spawn.min = 2
          spawn.max = 10
          spawn.frequency = 10
          spawn.next_spawn = now
        end

        it 'will not spawn an entity' do
          before = entities
          run_update
          expect(entities).to eq(before)
        end
      end
    end
  end
end
