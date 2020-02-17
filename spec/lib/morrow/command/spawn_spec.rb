describe Morrow::Command::Spawn do
  let(:room) { 'spec:room/1' }
  let(:leo) { 'spec:mob/leonidas' }
  let(:output) { strip_color_codes(player_output(leo)) }

  before(:each) do
    reset_world
    move_entity(entity: leo, dest: room)
    player_output(leo).clear
  end

  context 'no argument' do
    it 'will output an error' do
      run_cmd(leo, 'spawn')
      expect(output).to include('What would you like to spawn?')
    end
  end

  context 'invalid entity id' do
    it 'will output an error' do
      run_cmd(leo, 'spawn garbage')
      expect(output).to include('That is not a valid id')
    end
  end

  context 'valid entity id' do
    it 'will output creation message' do
      run_cmd(leo, 'spawn morrow:obj/junk/ball')
      expect(output).to include('a red rubber ball')
    end

    it 'will spawn the entity in the current room' do
      run_cmd(leo, 'spawn morrow:obj/junk/ball')
      run_cmd(leo, 'look')
      expect(output).to include('a red rubber ball is on the floor')
    end
  end
end
