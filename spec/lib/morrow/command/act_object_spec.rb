describe Morrow::Command::ActObject do
  let(:room) { 'spec:room/act_object' }
  let(:not_here) { 'spec:room/1' }
  let(:actor) { 'spec:mob/leonidas' }
  let(:observer) { 'spec:char/observer' }
  let(:ball) { create_entity(base: 'spec:obj/junk/ball') }
  let(:fountain) { create_entity(base: 'spec:obj/fountain') }
  let(:chest_open) { create_entity(base: 'spec:obj/chest_open_empty') }
  let(:chest_closed) { create_entity(base: 'spec:obj/chest_closed') }

  before(:each) do
    reset_world
    move_entity(entity: actor, dest: room)
    player_output(actor).clear
    move_entity(entity: observer, dest: room)
    player_output(observer).clear
  end

  describe 'get' do
    shared_examples 'get' do |cmd:, move:, output:|
      before(:each) do
        move_entity(entity: obj, dest: obj_location)
        run_cmd(actor, cmd)
      end

      if move
        it 'will move the item' do
          expect(entity_location(obj)).to eq(actor)
        end
      else
        it 'will not move the item' do
          expect(entity_location(obj)).to eq(obj_location)
        end
      end

      it 'will output %s to actor' % [ output.inspect ] do
        expect(player_output(actor)).to include(output)
      end
    end

    # defaults for the following contexts
    let(:obj) { ball }
    let(:obj_location) { room }

    context 'object is not present' do
      let(:obj) { ball }
      let(:obj_location) { not_here }
      include_examples 'get',
          cmd: 'get ball',
          move: false,
          output: 'You do not see a ball here.'
    end

    context 'object is non-corporeal' do
      let(:obj) { remove_component(ball, :corporeal); ball }
      include_examples 'get',
          cmd: 'get ball',
          move: false,
          output: 'Your hand passes right through a red rubber ball!'
    end

    context 'object is corporeal' do
      let(:obj) { ball }
      include_examples 'get',
          cmd: 'get ball',
          move: true,
          output: 'You pick up a red rubber ball.'
    end

    context 'object is too heavy' do
      before(:each) { get_component!(actor, :container).max_weight = 100 }
      let(:obj) { fountain }

      include_examples 'get',
          cmd: 'get fountain',
          move: false,
          output: 'A marble fountain is too heavy for you to carry.'
    end

    context 'actor inventory is full' do
      before(:each) { get_component!(actor, :container).max_volume = 0 }

      include_examples 'get',
          cmd: 'get ball',
          move: false,
          output: 'Your hands are full.'
    end

    context 'from a container' do
      shared_examples 'get from container' do |cmd:, move:, output:|
        before(:each) do
          move_entity(dest: container_location, entity: container)
        end

        include_examples 'get', cmd: cmd, move: move, output: output
      end

      # defaults for the following contexts
      let(:container_location) { room }
      let(:container) { chest_open }
      let(:obj_location) { container }

      context 'container is not present' do
        let(:container_location) { not_here }

        include_examples 'get from container',
            cmd: 'get ball chest',
            move: false,
            output: 'You do not see a chest here.'
      end

      context 'container is closed' do
        let(:container) { chest_closed }

        include_examples 'get from container',
            cmd: 'get ball chest',
            move: false,
            output: 'A wooden chest is closed.'
      end

      context 'object not in container' do
        let(:obj_location) { not_here }

        include_examples 'get from container',
            cmd: 'get ball chest',
            move: false,
            output: 'You do not see a ball in an open wooden chest'
      end

      context 'object is non-corporeal' do
        let(:obj) { remove_component(ball, :corporeal); ball }

        include_examples 'get from container',
            cmd: 'get ball chest',
            move: false,
            output: 'Your hand passes right through a red rubber ball!'
      end

      context 'object is corporeal' do
        include_examples 'get from container',
            cmd: 'get ball chest',
            move: true,
            output: 'You get a red rubber ball from an open wooden chest.'
      end

      context 'actor inventory is full' do
        before(:each) do
          get_component!(actor, :container).max_volume = 0
        end

        include_examples 'get from container',
            cmd: 'get ball chest',
            move: false,
            output: 'Your hands are full.'
      end

      context 'container in room, actor inventory over weight' do
        before(:each) do
          get_component!(actor, :container).max_weight = 0
        end

        include_examples 'get from container',
            cmd: 'get ball chest',
            move: false,
            output: 'A red rubber ball is too heavy for you to carry.'
      end

      context 'container in inventory, actor inventory over weight' do
        let(:container_location) { actor }

        before(:each) do
          get_component!(actor, :container).max_weight = 0
        end

        include_examples 'get from container',
            cmd: 'get ball chest',
            move: true,
            output: 'You get a red rubber ball from an open wooden chest.'
      end
    end

    context 'container in room, and in inventory' do
      let(:room_chest) { create_entity(base: chest_open) }
      let(:inv_chest) { create_entity(base: chest_open) }
      before(:each) do
        move_entity(dest: room, entity: room_chest)
        move_entity(dest: actor, entity: inv_chest)
        move_entity(dest: room_chest, entity: ball)
        run_cmd(actor, 'get ball chest')
      end

      it 'will get the item from the room container' do
        expect(entity_location(ball)).to eq(actor)
      end
    end

    context 'container in room, and in inventory, using "my" keyword' do
      let(:room_chest) { create_entity(base: chest_open) }
      let(:inv_chest) { create_entity(base: chest_open) }
      before(:each) do
        move_entity(dest: room, entity: room_chest)
        move_entity(dest: actor, entity: inv_chest)
        move_entity(dest: inv_chest, entity: ball)
        run_cmd(actor, 'get ball my chest')
      end

      it 'will get the item from the room container' do
        expect(entity_location(ball)).to eq(actor)
      end
    end
  end

  describe 'drop' do
    shared_examples 'drop' do |cmd:, drop:, output:|
      before(:each) do
        move_entity(entity: obj, dest: obj_location)
        run_cmd(actor, cmd)
      end

      if move
        it 'will move the item' do
          expect(entity_location(obj)).to eq(actor)
        end
      else
        it 'will not move the item' do
          expect(entity_location(obj)).to eq(obj_location)
        end
      end

      it 'will output %s to actor' % [ output.inspect ] do
        expect(player_output(actor)).to include(output)
      end
    end

    context 'object not in inventory' do
      before(:each) { run_cmd(actor, 'drop ball') }

      it 'will output "You do not have a ball."' do
        expect(player_output(actor)).to include('You do not have a ball.')
      end
    end

    context 'room is full' do
      before(:each) do
        move_entity(dest: actor, entity: ball)
        get_component!(room, :container).max_volume = 0
        run_cmd(actor, 'drop ball')
      end

      it 'will output "There is no space to drop that here."' do
        expect(player_output(actor))
            .to include('There is no space to drop that here.')
      end

      it 'will not move the object' do
        expect(entity_location(ball)).to eq(actor)
      end
    end

    context 'object in inventory' do
      before(:each) do
        move_entity(dest: actor, entity: ball)
        run_cmd(actor, 'drop ball')
      end

      it 'will output "You drop a red rubber ball."' do
        expect(player_output(actor))
            .to include('You drop a red rubber ball.')
      end

      it 'will move the object' do
        expect(entity_location(ball)).to eq(room)
      end
    end
  end

  describe 'put' do
    let(:obj) { ball }
    let(:container) { chest_open }

    before(:each) { move_entity(dest: actor, entity: ball) }

    shared_examples('put in container') do |cmd:|
      context 'container is closed' do
        before(:each) do
          get_component(container, :closable).closed = true
          run_cmd(actor, cmd)
        end

        it 'will output "<container> is closed."' do
          expect(player_output(actor)).to include(' is closed.')
        end

        it 'will not move the object' do
          expect(entity_location(obj)).to eq(actor)
        end
      end

      context 'container is at max volume' do
        before(:each) do
          get_component(container, :container).max_volume = 0
          run_cmd(actor, cmd)
        end
        it 'will output "will not fit"' do
          expect(player_output(actor)).to include(' will not fit ')
        end
        it 'will not move the object' do
          expect(entity_location(obj)).to eq(actor)
        end
      end

      context 'container is at max weight' do
        before(:each) do
          get_component(container, :container).max_weight = 0
          run_cmd(actor, cmd)
        end
        it 'will output "is too heavy"' do
          expect(player_output(actor)).to include(' is too heavy ')
        end
        it 'will not move the object' do
          expect(entity_location(obj)).to eq(actor)
        end
      end

      context 'container is open and has space' do
        before(:each) { run_cmd(actor, cmd) }

        it 'will output "You put <obj> in <container>."' do
          expect(player_output(actor))
              .to match(/^You put .*? in .*?.$/)
        end

        it 'will move the object into the container' do
          expect(entity_location(obj)).to eq(container)
        end
      end
    end

    context 'container not present' do
      before(:each) do
        run_cmd(actor, 'put ball chest')
      end

      it 'will output "You do not see a chest here."' do
        expect(player_output(actor))
            .to include('You do not see a chest here.')
      end

      it 'will not move the object' do
        expect(entity_location(obj)).to eq(actor)
      end
    end

    context 'object not in inventory' do
      before(:each) do
        move_entity(dest: room, entity: container)
        run_cmd(actor, 'put missing chest')
      end

      it 'will output "You do not have a missing."' do
        expect(player_output(actor))
            .to include('You do not have a missing')
      end

      it 'will not move the object' do
        expect(entity_location(obj)).to eq(actor)
      end
    end

    context 'container in room' do
      before(:each) { move_entity(dest: room, entity: container) }

      include_examples('put in container', cmd: 'put ball chest')
    end

    context 'container in inventory' do
      before(:each) { move_entity(dest: actor, entity: container) }

      include_examples('put in container', cmd: 'put ball chest')
    end

    context 'container in room, and in inventory' do
      let(:room_chest) { create_entity(base: chest_open) }
      let(:inv_chest) { create_entity(base: chest_open) }

      before(:each) do
        move_entity(dest: room, entity: room_chest)
        move_entity(dest: actor, entity: inv_chest)
      end

      context 'without "my" keyword' do
        let(:container) { room_chest }

        include_examples('put in container', cmd: 'put ball chest')
      end

      context 'with "my" keyword' do
        let(:container) { inv_chest }

        include_examples('put in container', cmd: 'put ball my chest')
      end
    end
  end
end
