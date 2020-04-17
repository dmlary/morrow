describe Morrow::Command::ActObject do
  let(:room) { 'spec:room/act_object' }
  let(:not_here) { 'spec:room/1' }
  let(:actor) { 'spec:mob/leonidas' }
  let(:ball) { create_entity(id: 'ball', base: 'spec:obj/ball') }
  let(:other_ball) { create_entity(id: 'other-ball', base: 'spec:obj/ball') }
  let(:flower) { create_entity(id: 'flower', base: 'spec:obj/flower') }
  let(:fountain) { create_entity(base: 'spec:obj/fountain') }
  let(:chest_open) { create_entity(base: 'spec:obj/chest_open_empty') }
  let(:chest_closed) { create_entity(base: 'spec:obj/chest_closed') }

  before(:each) do
    reset_world
    move_entity(entity: actor, dest: room)
    player_output(actor).clear
  end

  describe 'get' do
    shared_examples 'obj errors' do |ignore_weight:false|
      context 'object not found' do
        before(:each) do
          # clear all the entities out of the object's location, with the
          # possible exlusion of the actor.  We need to do it this way to
          # support the 'all.<obj>' tests where multiple objects in the
          # container or room will match the keywords.
          entity_contents(entity_location(obj)).clone.each do |obj|
            next if obj == actor
            move_entity(entity: obj, dest: not_here)
          end

          run_cmd(actor, cmd)
        end

        it 'will output containing "You do not see a <obj>"' do
          expect(player_output(actor)).to match(/You do not see an? /)
        end

        it 'will not move the object' do
          expect(entity_location(obj)).to eq(not_here)
        end
      end

      context 'object is non-corporeal' do
        before(:each) do
          remove_component(obj, :corporeal)
          run_cmd(actor, cmd)
        end

        it 'will output "Your hand passes right through <obj>"' do
          expect(player_output(actor))
              .to include('Your hand passes right through ')
        end

        it 'will not move the object' do
          expect(entity_location(obj)).to_not eq(actor)
        end
      end

      context 'object is too heavy' do
        before(:each) do
          get_component!(actor, :container).max_weight = 0
          run_cmd(actor, cmd)
        end

        if ignore_weight
          it 'will output "You get "' do
            expect(player_output(actor)).to include('You get ')
          end

          it 'will move the object' do
            expect(entity_location(obj)).to eq(actor)
          end
        else
          it 'will output "is too heavy for you to carry"' do
            expect(player_output(actor))
                .to include(' is too heavy for you to carry.')
          end

          it 'will not move the object' do
            expect(entity_location(obj)).to_not eq(actor)
          end
        end
      end

      context 'object is too big' do
        before(:each) do
          get_component!(actor, :container).max_volume = 0
          run_cmd(actor, cmd)
        end

        it 'will output "Your hands are full."' do
          expect(player_output(actor))
              .to include('Your hands are full.')
        end

        it 'will not move the object' do
          expect(entity_location(obj)).to_not eq(actor)
        end
      end
    end

    shared_examples 'container errors' do
      context 'container not found' do
        before(:each) do
          move_entity(entity: container, dest: not_here)
          run_cmd(actor, cmd)
        end

        it 'will output "You do not see a <container>"' do
          expect(player_output(actor)).to include('You do not see a ')
        end

        it 'will not move the object' do
          expect(entity_location(obj)).to eq(container)
        end
      end

      context 'container closed' do
        before(:each) do
          get_component!(container, :closable).closed = true
          run_cmd(actor, cmd)
        end

        it 'will output "<container> is closed."' do
          expect(player_output(actor)).to include(' is closed.')
        end

        it 'will not move the object' do
          expect(entity_location(obj)).to eq(container)
        end
      end
    end

    shared_examples 'container success' do
      context 'success' do
        before(:each) { run_cmd(actor, cmd) }

        it 'will move the object' do
          expect(entity_location(ball)).to eq(actor)
        end

        it 'will output "You get <obj> from <cont>."' do
          expect(player_output(actor))
              .to match(/^You get .*? from .*?\.$/)
        end
      end
    end

    shared_examples 'container success all' do
      context 'success' do
        before(:each) { run_cmd(actor, cmd) }

        it 'will move each of the matching objects' do
          objs.each do |o|
            expect(entity_location(o)).to eq(actor)
          end
        end

        it 'will output "You get <obj> from <cont>." for each object moved' do
          buf = objs.map do |o|
              'You get %s from %s.' %
                  [ entity_short(o), entity_short(container) ]
          end.join("\n")
          expect(player_output(actor)).to include(buf)
        end
      end
    end

    context "'get <obj>'" do
      let(:obj) { ball }
      let(:cmd) { 'get ball' }

      before(:each) do
        move_entity(entity: other_ball, dest: room)
        move_entity(entity: obj, dest: room)
        move_entity(entity: flower, dest: room)
      end

      include_examples 'obj errors'

      context 'success' do
        before(:each) { run_cmd(actor, cmd) }

        it 'will move the object' do
          expect(entity_location(obj)).to eq(actor)
        end

        it 'will not move the duplicate object in the room' do
          expect(entity_location(other_ball)).to eq(room)
        end

        it 'will not move the other object in the room' do
          expect(entity_location(flower)).to eq(room)
        end

        it 'will output "You get <obj>."' do
          expect(player_output(actor))
              .to include('You pick up a red rubber ball.')
        end
      end
    end

    context "'get all.<obj>'" do
      let(:balls) do
        5.times.map { create_entity(base: 'spec:obj/ball') }
      end
      let(:obj) { balls.first }
      let(:cmd) { 'get all.ball' }

      before(:each) do
        balls.each { |b| move_entity(entity: b, dest: room) }
        move_entity(entity: flower, dest: room)
      end

      include_examples 'obj errors'

      context 'success' do
        before(:each) { run_cmd(actor, cmd) }

        it 'will move each of the matching objects' do
          balls.each do |ball|
            expect(entity_location(ball)).to eq(actor)
          end
        end

        it 'will output "You get <obj>." for each object moved' do
          buf = "You pick up a red rubber ball.\n" * balls.size
          expect(player_output(actor)).to include(buf)
        end

        it 'will not move non-matching objects' do
          expect(entity_location(flower)).to eq(room)
        end
      end
    end

    context "'get all'" do
      let(:cmd) { 'get all' }
      let(:ball) { create_entity(base: 'spec:obj/ball') }
      let(:flower) { create_entity(base: 'spec:obj/flower') }
      let(:objs) { [ ball, flower ] }
      let(:observer) { 'spec:char/observer' }

      before(:each) do
        # We want the objects in the room to be in the same order as the array,
        # so move them in in reverse order; the room is a stack.
        objs.reverse.each { |o| move_entity(entity: o, dest: room) }
        move_entity(entity: observer, dest: room)
      end

      context 'the first object is too heavy' do
        before(:each) do
          get_component!(actor, :container).max_weight = 100
          get_component!(ball, :corporeal).weight = 1000000
          get_component!(flower, :corporeal).weight = 1
          run_cmd(actor, cmd)
        end

        it 'will not move the first object' do
          expect(entity_location(ball)).to eq(room)
        end

        it 'will not move the second object' do
          expect(entity_location(flower)).to eq(room)
        end

        it 'will output a single line stating that the ball is too heavy' do
          expect(player_output(actor))
              .to match(/is too heavy for you to carry.\s+\Z/m)
        end
      end

      context 'the first object is too big' do
        before(:each) do
          get_component!(actor, :container).max_volume = 100
          get_component!(ball, :corporeal).volume = 1000000
          get_component!(flower, :corporeal).volume = 1
          run_cmd(actor, cmd)
        end

        it 'will not move the first object' do
          expect(entity_location(ball)).to eq(room)
        end

        it 'will not move the second object' do
          expect(entity_location(flower)).to eq(room)
        end

        it 'will output a single line, "Your hands are full."' do
          expect(player_output(actor))
              .to match(/^Your hands are full.\s+\Z/m)
        end
      end

      context 'the first object is non-corporeal' do
        before(:each) do
          remove_component(ball, :corporeal)
          run_cmd(actor, cmd)
        end

        it 'will not move the first object' do
          expect(entity_location(ball)).to eq(room)
        end

        it 'will output "Your hand passes right through a red rubber ball."' do
          expect(player_output(actor))
              .to include("Your hand passes right through a red rubber ball.")
        end

        it 'will move the second object' do
          expect(entity_location(flower)).to eq(actor)
        end

        it 'will output "You pick up a yellow wildflower."' do
          expect(player_output(actor))
              .to include("You pick up a yellow wildflower.")
        end
      end

      context 'success' do
        before(:each) { run_cmd(actor, cmd) }

        it 'will move the first object' do
          expect(entity_location(ball)).to eq(actor)
        end

        it 'will output "You pick up a red rubber ball."' do
          expect(player_output(actor))
              .to include("You pick up a red rubber ball.")
        end

        it 'will move the second object' do
          expect(entity_location(flower)).to eq(actor)
        end

        it 'will output "You pick up a yellow wildflower."' do
          expect(player_output(actor))
              .to include("You pick up a yellow wildflower.")
        end

        it 'will not move the observer' do
          expect(entity_location(observer)).to eq(room)
        end

        it 'will not move the actor' do
          expect(entity_location(actor)).to eq(room)
        end
      end
    end

    context "'get <obj> <container>'" do
      let(:obj) { ball }
      let(:container) { chest_open }
      let(:cmd) { 'get ball chest' }

      before(:each) do
        move_entity(entity: other_ball, dest: container)
        move_entity(entity: obj, dest: container)
        move_entity(entity: flower, dest: container)
      end

      context 'container in room' do
        before(:each) { move_entity(entity: container, dest: room) }

        include_examples 'container errors'
        include_examples 'obj errors'
        include_examples 'container success'
      end

      context 'container in inventory' do
        before(:each) { move_entity(entity: container, dest: actor) }

        include_examples 'container errors'
        include_examples 'obj errors', ignore_weight: true
        include_examples 'container success'
      end
    end

    context "'get <obj> my <container>'" do
      let(:obj) { ball }
      let(:room_chest) { create_entity(base: 'spec:obj/chest_open_empty') }
      let(:my_chest) { create_entity(base: 'spec:obj/chest_open_empty') }
      let(:container) { my_chest }
      let(:cmd) { 'get ball my chest' }

      before(:each) do
        # The key here is that the ball exists only in my_chest, not in
        # room_chest.  So if 'my' breaks, then most of these tests will fail
        # with the "not found" error message.
        move_entity(entity: room_chest, dest: room)
        move_entity(entity: obj, dest: my_chest)
        move_entity(entity: my_chest, dest: actor)
      end

      include_examples 'container errors'
      include_examples 'obj errors', ignore_weight: true
      include_examples 'container success'
    end

    context "'get all.<obj> <container>'" do
      let(:objs) do
        5.times.map { create_entity(base: 'spec:obj/ball') }
      end
      let(:obj) { objs.first }
      let(:container) { chest_open }
      let(:cmd) { 'get all.ball chest' }

      before(:each) do
        objs.each { |b| move_entity(entity: b, dest: container) }
        move_entity(entity: flower, dest: container)
      end

      context 'container in room' do
        before(:each) { move_entity(entity: container, dest: room) }

        include_examples 'container errors'
        include_examples 'obj errors'
        include_examples 'container success all'
      end

      context 'container in inventory' do
        before(:each) { move_entity(entity: container, dest: actor) }

        include_examples 'container errors'
        include_examples 'obj errors', ignore_weight: true
        include_examples 'container success all'
      end
    end

    context "'get all.<obj> my <container>'" do
      let(:objs) do
        5.times.map { create_entity(base: 'spec:obj/ball') }
      end
      let(:obj) { objs.first }
      let(:room_chest) { create_entity(base: 'spec:obj/chest_open_empty') }
      let(:my_chest) { create_entity(base: 'spec:obj/chest_open_empty') }
      let(:container) { my_chest }
      let(:cmd) { 'get all.ball my chest' }

      before(:each) do
        objs.each { |b| move_entity(entity: b, dest: my_chest) }
        move_entity(entity: flower, dest: my_chest)
        move_entity(entity: room_chest, dest: room)
        move_entity(entity: my_chest, dest: actor)
      end

      include_examples 'container errors'
      include_examples 'obj errors', ignore_weight: true
      include_examples 'container success all'
    end

    context "'get all <container>'" do
      let(:cmd) { 'get all' }
      let(:ball) { create_entity(base: 'spec:obj/ball') }
      let(:flower) { create_entity(base: 'spec:obj/flower') }
      let(:objs) { [ ball, flower ] }
      let(:container) { create_entity(base: 'spec:obj/chest_open_empty') }

      before(:each) do
        # the objects in the container should be in the same order as the
        # array, so we move them in reverse order.  This is necessary for some
        # of the tests.
        objs.reverse.each { |o| move_entity(entity: o, dest: container) }
      end

    end
  end

  describe 'get' do
    shared_examples('move second') do
      it 'will move the second object'
      it 'will output "You get <obj>"'
    end

    shared_examples('get objects from source') do
      before(:each) do
        move_entity(entity: ball, dest: source)
        move_entity(entity: flower, dest: source)
      end

      context 'no objects matched in source' do
        before(:each) do
          move_entity(entity: ball, dest: not_here)
          move_entity(entity: flower, dest: not_here)
        end
        it 'will output \"You do not see .* here\"'
      end

      context 'first object is too heavy' do
        before(:each) do
          get_component!(actor, :container).max_weight = 100
          get_component!(ball, :corporeal).weight = 200
        end

        it 'will not move the first object'
        it 'will output "<obj> is too heavy"'
        include_examples('move flower')
      end

      context 'first object is too big' do
        before(:each) do
          get_component!(actor, :container).max_volume = 100
          get_component!(ball, :corporeal).volume = 200
        end

        it 'will not move the first object'
        it 'will output "<obj> is too big"'
        include_examples('move flower')
      end
    end

    # XXX re-imagined test layout, but DAAAAMN, this is a lot of work I really
    # don't want to do.
    #
    # shared_examples('objects from source') do |cmd:, src:|
    # - obj not found/no objects
    #   - output single error
    # - obj too heavy
    #   - output error, try others
    # - obj too big/hands full
    #   - output error, try others
    # - obj non-corporeal
    #   - output error, try others
    # - success
    #   - move the thing
    #
    # shared_examples('container not found') do |cmd|
    # - error
    #
    # shared_examples('objects from container') do |cmd|
    # - container closed
    #   - error
    # - container open
    #   - include_examples('objects from source', cmd, container)
    #
    # room:
    # - include_examples('objects from source', 'get all', room)
    # my:
    # - container not found
    #   - include_examples('container not found', 'get all my chest')
    # - container in room
    #   - include_examples('container not found', 'get all my chest')
    # - container in inventory
    #   - include_examples('objects from container', 'get all my chest')
    # not my:
    # - container not found
    #   - include_examples('container not found', 'get all chest')
    # - container in room
    #   - include_examples('objects from container', 'get all chest')
    # - container in inventory
    #   - include_examples('objects from container', 'get all chest')
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

    context 'drop all' do
      before(:each) do
        move_entity(entity: ball, dest: actor)
        move_entity(entity: flower, dest: actor)
        run_cmd(actor, 'drop all')
      end

      it 'will move the ball to the room' do
        expect(entity_location(ball)).to eq(room)
      end

      it 'will move the flower to the room' do
        expect(entity_location(flower)).to eq(room)
      end
    end

    context 'drop all.<obj>' do
      before(:each) do
        move_entity(entity: ball, dest: actor)
        move_entity(entity: flower, dest: actor)
        run_cmd(actor, 'drop all.ball')
      end

      it 'will move the ball to the room' do
        expect(entity_location(ball)).to eq(room)
      end

      it 'will not move the flower' do
        expect(entity_location(flower)).to eq(actor)
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

    context 'put all <container>' do
      context 'container in room' do
        before(:each) do
          entity_contents(actor).clear
          move_entity(entity: ball, dest: actor)
          move_entity(entity: flower, dest: actor)
          move_entity(entity: chest_open, dest: room)
          run_cmd(actor, 'put all chest')
        end

        it 'will move ball into chest' do
          expect(entity_location(ball)).to eq(chest_open)
        end

        it 'will move flower into chest' do
          expect(entity_location(flower)).to eq(chest_open)
        end

        it 'will leave no items in the actor\'s inventory' do
          expect(entity_contents(actor)).to be_empty
        end
      end

      context 'container in inventory' do
        before(:each) do
          entity_contents(actor).clear
          move_entity(entity: ball, dest: actor)
          move_entity(entity: flower, dest: actor)
          move_entity(entity: chest_open, dest: actor)
          run_cmd(actor, 'put all chest')
        end

        it 'will not move container' do
          expect(entity_location(chest_open)).to eq(actor)
        end

        it 'will move all other objects into container' do
          expect(entity_contents(actor)).to contain_exactly(chest_open)
        end
      end
    end

    context 'put all.ball <container>' do
      before(:each) do
        entity_contents(actor).clear
        move_entity(entity: ball, dest: actor)
        move_entity(entity: flower, dest: actor)
        move_entity(entity: chest_open, dest: room)
        run_cmd(actor, 'put all.ball chest')
      end

      it 'will move the ball' do
        expect(entity_location(ball)).to eq(chest_open)
      end

      it 'will not move the flower' do
        expect(entity_location(flower)).to eq(actor)
      end
    end
  end
end
