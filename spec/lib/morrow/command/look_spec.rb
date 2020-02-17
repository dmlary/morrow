describe Morrow::Command::Look do
  let(:room) { 'spec:room/1' }
  let(:leo) { 'spec:mob/leonidas' }
  let(:chest_closed) { 'spec:obj/chest_closed' }
  let(:output) { strip_color_codes(player_output(leo)) }

  before(:each) do
    reset_world
    move_entity(entity: leo, dest: room)
    player_output(leo).clear
  end

  describe '"look"' do
    before(:each) { run_cmd(leo, 'look') }

    it 'will show the room title' do
      expect(output).to include(get_component(room, :viewable).short)
    end

    it 'will show the room description' do
      expect(output).to include(get_component(room, :viewable).desc)
    end

    it 'will show the closed door to the east' do
      expect(output).to match(/^Exits:.*\[ east \] /)
    end

    it 'will show the open passage up' do
      expect(output).to match(/^Exits:.* up ?$/)
    end

    it 'will not show the closed hidden door to the west' do
      expect(output).to_not match(/^Exits:.* west ?$/)
    end

    it 'will show the open hidden door to the north' do
      expect(output).to_not match(/^Exits:.* north ?$/)
    end

    it 'will not show Leonidas' do
      expect(output).to_not match(/leonidas/i)
    end

    it 'will show items in the room' do
      expect(output).to include('a wooden chest sits open on the floor')
      expect(output).to include('a wooden chest rests on the floor')
    end

    it 'will show other characters in the room' do
      expect(output).to include('Player the Generic of Springdale')
    end
  end

  describe '"look leonidas"' do
    before(:each) { run_cmd(leo, 'look leonidas') }

    it 'will show the character description' do
      expect(output).to include(entity_desc(leo))
    end

    it 'will show the character short description' do
      expect(output).to include(entity_short(leo))
    end

    it 'will show the character keywords' do
      expect(output).to include(entity_keywords(leo))
    end
  end

  describe '"look chest-closed"' do
    let(:chest) { 'spec:obj/chest_closed' }

    before(:each) { run_cmd(leo, 'look chest-closed') }

    it 'will show the object description' do
      expect(output).to include(entity_desc(chest))
    end

    it 'will show the object short description' do
      expect(output).to include(entity_short(chest))
    end

    it 'will show the object keywords' do
      expect(output).to include(entity_keywords(chest))
    end
  end

  describe '"look in leonidas"' do
    before(:each) { run_cmd(leo, 'look in leonidas') }

    it 'will output an error that you cannot look into that.' do
      expect(output).to include("You cannot look into that.")
    end
  end

  describe '"look in chest-closed"' do
    let(:chest) { 'spec:obj/chest_closed' }

    before(:each) { run_cmd(leo, 'look in chest-closed') }

    it 'will output an error that the chest is closed' do
      expect(output).to include('It is closed.')
    end
  end

  describe '"look in chest-open-nonempty"' do
    before(:each) { run_cmd(leo, 'look in chest-open-nonempty') }

    it 'will output object short descrption' do
      expect(output).to include('an open wooden chest')
    end

    it 'will output chest contents' do
      expect(output).to include('a red rubber ball')
    end
  end

  describe '"look in chest-open-empty"' do
    before(:each) { run_cmd(leo, 'look in chest-open-empty') }

    it 'will output object short descrption' do
      expect(output).to include('an open wooden chest')
    end

    it 'will output "It is empty."' do
      expect(output).to include('It is empty.')
    end
  end

  describe '"look <direction>"' do
    [ { desc: 'no exit',
        cmd: 'look d',
        output: 'You look downward, but see nothing special.' },
      { desc: 'non-closable exit',
        cmd: 'look u',
        output: 'You can travel upward.' },
      { desc: 'closed exit',
        cmd: 'look e',
        output: 'The door to the east is closed.' },
      { desc: 'open exit',
        before: 'open door',
        cmd: 'look e',
        output: 'The door to the east is open.' },
      { desc: 'closed & concealed exit',
        cmd: 'look w',
        output: 'You look to the west, but see nothing special.' },
      { desc: 'open & concealed exit',
        before: 'open hidden-cupboard',
        cmd: 'look w',
        output: 'The hidden-cupboard to the west is open.' }
    ].each do |p|
      context p[:desc] do
        before { run_cmd(leo, p[:before]) } if p[:before]
        it "will output '#{p[:output]}'" do
          run_cmd(leo, p[:cmd])
          expect(output).to include(p[:output])
        end
      end
    end
  end
end
