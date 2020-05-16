describe 'Morrow::Helpers.spawn_corpse' do
  let(:room) { 'spec:room/empty' }
  let(:entity) { create_entity(base: 'spec:char/victim') }
  let(:ball) { create_entity(base: 'spec:obj/ball') }
  let(:leo) { 'spec:mob/leonidas' }
  let(:corpse) { entity_contents(room).last }

  before(:each) do
    reset_world
    move_entity(entity: ball, dest: entity)
    move_entity(entity: entity, dest: room)
  end

  context 'inanimate entity' do
    before(:each) do
      remove_component(entity, :character)
      spawn_corpse(entity)
    end

    it 'will not create a corpse' do
      expect(corpse).to eq(entity)
    end
  end

  context 'animate entity' do
    before(:each) { spawn_corpse(entity) }

    it 'will destroy the entity' do
      expect(entity_destroyed?(entity)).to be(true)
    end

    it 'create a corpse' do
      expect(corpse).to_not be(nil)
    end

    describe 'will create a corpse that' do
      it 'will include the entity keywords' do
        expect(entity_keywords(corpse))
            .to include(entity_keywords('spec:char/victim'))
      end

      it 'will include "corpse" in keywords' do
        expect(entity_keywords(corpse)).to include('corpse')
      end

      it 'will include "remains" in keyword' do
        expect(entity_keywords(corpse)).to include('remains')
      end

      it 'will contain the entity\'s items' do
        expect(entity_location(ball)).to eq(corpse)
        expect(entity_contents(corpse)).to contain_exactly(ball)
      end

      it 'will have viewable contents' do
        move_entity(entity: leo, dest: room)
        expect(cmd_output(leo, 'look in corpse'))
            .to include('a red rubber ball')
      end

      it 'will include the entity short in the long description' do
        expect(entity_long(corpse))
            .to include(entity_short('spec:char/victim'))
      end

      it 'will be scheduled to decay' do
        expect(get_component(corpse, :decay)).to_not eq(nil)
      end
    end
  end
end
