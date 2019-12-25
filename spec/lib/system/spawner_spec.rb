describe System::Spawner do
  include World::Helpers

  before(:each) { load_test_world }
  let(:bag) { 'test-world:obj/spawn-bag' }
  let(:spawn_point) { get_component(bag, :spawn_point) }
  let(:ball) { 'test-world:obj/junk/ball' }
  let(:spawn) { get_component('test-world:spawn/ball', :spawn) }

  describe '.update(dest, point)' do
    context 'with an empty SpawnPointComponent' do
      it 'will not spawn any entities' do
        spawn_point.list.clear
        before = World.entities.keys
        System::Spawner.update(bag, spawn_point)
        expect(World.entities.keys).to eq(before)
      end
    end
    context 'with an invalid entity id in the spawn point' do
      it 'will log an error'
      it 'will remove the entity from the spawn point'
    end
    context 'with a valid entity in the spawn point' do
      context 'with less than minimum active' do
        before(:each) do
          spawn.min = 2
          spawn.active = 0
          spawn.max = 10
          spawn.frequency = 90
        end

        it 'will spawn an entity at each call until minimum active' do
          before = World.entities.keys
          10.times { System::Spawner.update(bag, spawn_point) }
          after = World.entities.keys
          expect((after - before).size).to eq(2)
        end

        it 'will set spawn.active to 2' do
          10.times { System::Spawner.update(bag, spawn_point) }
          expect(spawn.active).to eq(2)
        end
      end

      context 'with more than minimum, less than max active' do
        before(:each) do
          spawn.min = 2
          spawn.active = 2
          spawn.max = 10
          spawn.frequency = 1

          # math here: frequency is 1 second, we update every 1/4 second, so we
          # should avoid any weirdness if we call update 6 seconds, expecting
          # two entities to have spawned.
        end

        it 'will spawn one entity each frequency' do
          before = World.entities.keys
          6.times { System::Spawner.update(bag, spawn_point); sleep 0.25 }
          after = World.entities.keys
          expect((after - before).size).to eq(2)
        end

        it 'will set spawn.active to 4' do
          6.times { System::Spawner.update(bag, spawn_point); sleep 0.25 }
          expect(spawn.active).to eq(4)
        end
      end

      context 'with less than max active, and stale next_spawn' do
        before(:each) do
          spawn.active = 0
          spawn.min = 2
          spawn.max = 10
          spawn.frequency = 10
        end

        context 'next_spawn less than max * frequency in the past' do
          it 'will spawn enough entities for next_spawn to not be stale' do
            # spawn time was 55 seconds ago; the extra 5 seconds are to avoid
            # falling right on an extra spawn interval.
            spawn.next_spawn = Time.now - (5 * spawn.frequency) + 5
            10.times { System::Spawner.update(bag, spawn_point) }
            expect(spawn.active).to eq(5)
          end
        end
        context 'next_spawn greater than max * frequency in the past' do
          it 'will spawn at most max entities' do
            spawn.next_spawn = Time.now - (100 * spawn.frequency)
            20.times { System::Spawner.update(bag, spawn_point) }
            expect(spawn.active).to eq(10)
          end
        end
      end

      context 'when it spawns the last entity' do
        before(:each) do
          spawn.min = 2
          spawn.active = 9
          spawn.max = 10
          spawn.next_spawn = Time.now
          System::Spawner.update(bag, spawn_point)
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
        end

        it 'will not spawn an entity' do
          before = World.entities.keys
          System::Spawner.update(bag, spawn_point)
          expect(World.entities.keys).to eq(before)
        end
      end
    end
  end
end
