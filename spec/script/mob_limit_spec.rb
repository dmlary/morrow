describe 'teleporter script' do
  include World::Helpers

  before(:each) { load_test_world }
  let(:room) do
    create_entity(base: [ 'base:room', 'base:act/mob_limit' ])
  end
  let(:contents) { get_component!(room, :container).contents }
  let(:will_enter_hook) do
    get_components(room, :hook).find { |h| h.event == :will_enter }
  end
  let(:start) { create_entity(base: 'base:room') }
  let(:leo) { 'spec:mob/leonidas' }

  before(:each) do
    move_entity(entity: leo, dest: start)
    will_enter_hook.script_config['limit'] = 2
    player_output(leo).clear
  end

  context 'room is full' do
    before(:each) do
      contents << create_entity(base: 'base:char')
      contents << create_entity(base: 'base:char')
      move_entity(entity: leo, dest: room, look: true)
    end

    it 'will not move' do
      expect(entity_location(leo)).to_not eq(room)
    end
    it 'will tell the entity the room is full' do
      expect(player_output(leo)).to include('too crowded for you')
    end
    it 'will not display the full room to the player' do
      expect(player_output(leo)).to_not include(entity_desc(room))
    end
  end

  context 'room is not full' do
    before(:each) do
      contents.clear
      move_entity(entity: leo, dest: room, look: true)
    end

    it 'will move' do
      expect(entity_location(leo)).to eq(room)
    end

    it 'will tell the entity the room is full' do
      expect(player_output(leo)).to include(entity_desc(room))
    end
  end
end
