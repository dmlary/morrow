describe Morrow::System::Decay do
  let(:room) { 'spec:room/1' }
  let(:decay) { get_component!(corpse, :decay) }
  let(:corpse) { create_entity }

  before(:each) do
    reset_world
    move_entity(entity: corpse, dest: room)
  end

  def run_update
    described_class.update(corpse, decay)
  end

  context ':at is in the future' do
    before(:each) { decay.at = now + 1 }
    it 'will not destroy entity' do
      run_update
      expect(entity_destroyed?(corpse)).to eq(false)
    end
    it 'will not remove component' do
      run_update
      expect(get_component(corpse, :decay)).to be(decay)
    end
    it 'will not call act()' do
      expect(described_class).to_not receive(:act)
      run_update
    end
  end

  context ':at is not in the future' do
    before(:each) { decay.at = now }

    shared_examples 'decay the entity' do
      it 'will move entity contents into location contents' do
        ball = spawn_at(dest: corpse, base: 'spec:obj/ball')
        run_update
        expect(entity_location(ball)).to eq(room)
      end

      it 'will destroy the entity' do
        run_update
        expect(entity_destroyed?(corpse)).to eq(true)
      end
    end

    context ':act is nil' do
      before(:each) { decay.act = nil }

      include_examples 'decay the entity'

      it 'will not call act()' do
        expect(described_class).to_not receive(:act)
      end
    end

    context ':act is set' do
      before(:each) { decay.act = "%{actor} falls to pieces" }

      include_examples 'decay the entity'

      it 'will call act() with entity as actor' do
        expect(described_class).to receive(:act) do |fmt,p={}|
          expect(p[:actor]).to be(corpse)
        end

        run_update
      end
    end

    context 'entity has no location' do
      before(:each) { get_component!(corpse, :location).entity = nil }

      it 'will destroy the entity' do
        run_update
        expect(entity_destroyed?(corpse)).to eq(true)
      end

      it 'will destroy entity contents' do
        ball = spawn_at(dest: corpse, base: 'spec:obj/ball')
        run_update
        expect(entity_destroyed?(ball)).to be(true)
      end
    end
  end
end
