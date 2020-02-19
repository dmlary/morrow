describe Morrow::Command::Move do
  let(:room) { 'spec:room/movement' }
  let(:void) { 'morrow:room/void' }
  let(:leo) { 'spec:mob/leonidas' }
  let(:output) { strip_color_codes(player_output(leo)) }

  before(:each) do
    reset_world
    move_entity(entity: leo, dest: room)
    player_output(leo).clear
  end

  [ { context: 'move through an exit with no destination',
      room: 'spec:room/no_exits',
      cmd: 'east',
      move: false,
      output: 'Alas, you cannot go that way ...' },
    { context: 'move through an exit that has no door',
      room: 'spec:room/with_exit',
      cmd: 'east',
      move: true,
      output: :look },
    { context: 'move through a closed door',
      room: 'spec:room/door/closed',
      cmd: 'east',
      move: false,
      output: 'The door is closed.' },
    { context: 'move through an open door',
      room: 'spec:room/door/open',
      cmd: 'east',
      move: true,
      output: :look },
    { context: 'move through a closed, concealed door',
      room: 'spec:room/door/concealed/closed',
      cmd: 'east',
      move: false,
      output: 'Alas, you cannot go that way ...' },
    { context: 'move through an open, concealed door',
      room: 'spec:room/door/concealed/open',
      cmd: 'east',
      move: true,
      output: :look } ].each do |p|

    context p[:context] do
      let(:room) { p[:room] }
      let(:dest) { get_component(room, :exits)&.send(p[:cmd]) }

      before(:each) { run_cmd(leo, p[:cmd]) }

      if p[:move]
        it 'will move the actor to the next room' do
          expect(entity_location(leo)).to eq(dest)
        end
      else
        it 'will not move the actor' do
          expect(entity_location(leo)).to eq(room)
        end
      end

      if p[:output] == :look
        it 'will run "look" in the new room' do
          expect(output).to include(entity_desc(dest))
        end
      else
        it "will output '#{p[:output]}'" do
          expect(output).to include(p[:output])
        end
      end
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
