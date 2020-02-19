describe Morrow::Command::ActClosable do
  before(:each) { reset_world }

  let(:room) { 'spec:room/1' }
  let(:leo) { 'spec:mob/leonidas' }
  let(:chest_closed) { 'spec:obj/chest_closed' }
  let(:output) { strip_color_codes(player_output(leo)) }

  before(:each) do
    move_entity(entity: leo, dest: room)
    player_output(leo).clear
  end

  [ { desc: 'open a closed door',
      room: 'spec:room/door/closed',
      cmd: 'open door',
      closed: false,
      output: 'You open the door.' },
    { desc: 'open an open door',
      room: 'spec:room/door/open',
      cmd: 'open door',
      closed: false,
      output: 'It is already open.' },
    { desc: 'open closed object in the room',
      room: 'spec:room/room_item/closed',
      cmd: 'open chest',
      closed: false,
      output: 'You open a wooden chest.' },
    { desc: 'open an open object in the room',
      room: 'spec:room/room_item/open',
      cmd: 'open chest',
      closed: false,
      output: 'It is already open.' },
    { desc: 'open a closed inventory item',
      actor: 'spec:player/inventory_item/closed',
      cmd: 'open bag',
      closed: false,
      output: 'You open a small bag.' },
    { desc: 'open an open inventory item',
      actor: 'spec:player/inventory_item/open',
      cmd: 'open bag',
      closed: false,
      output: 'It is already open.' },

    { desc: 'close a closed door',
      room: 'spec:room/door/closed',
      cmd: 'close door',
      closed: true,
      output: 'It is already closed.' },
    { desc: 'close an open door',
      room: 'spec:room/door/open',
      cmd: 'close door',
      closed: true,
      output: 'You close the door.' },
    { desc: 'close closed object in the room',
      room: 'spec:room/room_item/closed',
      cmd: 'close chest',
      closed: true,
      output: 'It is already closed.' },
    { desc: 'close an open object in the room',
      room: 'spec:room/room_item/open',
      cmd: 'close chest',
      closed: true,
      output: 'You close a wooden chest.' },
    { desc: 'close a closed inventory item',
      actor: 'spec:player/inventory_item/closed',
      cmd: 'close bag',
      closed: true,
      output: 'It is already closed.' },
    { desc: 'close an open inventory item',
      actor: 'spec:player/inventory_item/open',
      cmd: 'close bag',
      closed: true,
      output: 'You close a small bag.' },
    ].each do |p|
      describe "#{p[:desc]}" do
        let(:room) { p[:room] } if p[:room]
        let(:leo) { p[:actor] } if p[:actor]
        let(:target) { "#{p[:room] || p[:actor]}/target" }

        before(:each) { run_cmd(leo, p[:cmd]) }

        it 'the target will be %s' % [ p[:closed] ? 'closed' : 'open' ] do
          expect(entity_closed?(target)).to be(p[:closed])
        end

        it "will output '#{p[:output]}'" do
          expect(output).to include(p[:output])
        end
      end
    end
end
