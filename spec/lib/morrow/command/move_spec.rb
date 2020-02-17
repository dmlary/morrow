describe Morrow::Command::Look do
  let(:room) { 'spec:room/movement' }
  let(:void) { 'morrow:room/void' }
  let(:leo) { 'spec:mob/leonidas' }
  let(:output) { strip_color_codes(player_output(leo)) }

  before(:each) do
    reset_world
    move_entity(entity: leo, dest: room)
    player_output(leo).clear
  end

  context 'no exit' do
    before(:each) do
      get_component!(room, :exits).down = nil
      run_cmd(leo, 'down')
    end

    it 'will not move the actor' do
      expect(entity_location(leo)).to eq(room)
    end
    it 'will output an error to the actor' do
      expect(output).to include('Alas, you cannot go that way ...')
    end
  end

  context 'invalid exit entity' do
    before(:each) do
      get_component!(room, :exits).down = 'invalid entity'
      expect { run_cmd(leo, 'down') }
          .to raise_error(Morrow::UnknownEntity)
    end

    it 'will not move the actor' do
      expect(entity_location(leo)).to eq(room)
    end
  end

  context 'unclosable passage' do
    before(:each) do
      get_component!(room, :exits).down = 'spec:exit/open'
      run_cmd(leo, 'down')
    end

    it 'will move the actor' do
      expect(entity_location(leo)).to eq(void)
    end
    it 'will run look in the next room' do
      expect(output).to include(entity_desc(void))
    end
  end

  context 'closed door' do
    before(:each) do
      get_component!(room, :exits).down = 'spec:exit/door/closed'
      run_cmd(leo, 'down')
    end

    it 'will not move the actor' do
      expect(entity_location(leo)).to eq(room)
    end
    it 'will output an error with the door name to the actor' do
      expect(output).to include(entity_keywords('spec:exit/door/closed'))
    end
  end

  context 'open door' do
    before(:each) do
      get_component!(room, :exits).down = 'spec:exit/door/open'
      run_cmd(leo, 'down')
    end

    it 'will move the actor' do
      expect(entity_location(leo)).to eq(void)
    end
    it 'will run look in the next room' do
      expect(output).to include(entity_desc(void))
    end
  end

  context 'closed concealed door' do
    before(:each) do
      get_component!(room, :exits).down = 'spec:exit/door/closed/hidden'
      run_cmd(leo, 'down')
    end

    it 'will not move the actor' do
      expect(entity_location(leo)).to eq(room)
    end

    it 'will output an error with the door name to the actor' do
      expect(output)
          .to_not include(entity_keywords('spec:exit/door/closed/hidden'))
    end
  end

  context 'open concealed door' do
    before(:each) do
      get_component!(room, :exits).down = 'spec:exit/door/open/hidden'
      run_cmd(leo, 'down')
    end

    it 'will move the actor' do
      expect(entity_location(leo)).to eq(void)
    end
    it 'will run look in the next room' do
      expect(output).to include(entity_desc(void))
    end
  end

  context 'destination room is full' do
    it 'will output an error to the actor' do
      expect(Morrow::Command::Move)
          .to receive(:move_entity).and_return(:full)
      get_component!(room, :exits).down = 'spec:exit/open'
      run_cmd(leo, 'down')
      expect(output).to include('It\'s too crowded')
    end
  end
end
