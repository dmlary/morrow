require 'world'
require 'system'
require 'command'

describe Command::Look do
  include World::Helpers

  before(:all) { load_test_world; spawn_entities }
  let(:room) { World.by_virtual('test-world:room/testing') }
  let(:leo) { World.by_virtual('test-world:mob/leonidas') }
  let(:chest_closed) { World.by_virtual('test-world:obj/chest_closed') }
  before(:each) { move_entity(leo, room) }

  describe 'command parsing' do
    context '"look"' do
      it 'will call show_room(leo, room)' do
        expect(Command::Look).to receive(:show_room).with(leo, room)
        Command.run(leo, 'look')
      end
    end

    context '"look self"' do
      it 'will call show_char(leo, leo)' do
        expect(Command::Look).to receive(:show_char).with(leo, leo)
        Command.run(leo, 'look self')
      end
    end

    context '"look me"' do
      it 'will call show_char(leo, leo)' do
        expect(Command::Look).to receive(:show_char).with(leo, leo)
        Command.run(leo, 'look me')
      end
    end

    context '"look leonidas"' do
      let(:cmd) { "look leonidas" }

      it 'will call match_keyword("leonidas", visible entities)' do
        expected_objs = room.get(:exits, :list)
        expected_objs += visible_contents(actor: leo, cont: room)
        expected_objs += visible_contents(actor: leo, cont: leo)

        expect(Command::Look).to receive(:match_keyword) do |key,*objs|
          expect(key).to eq('leonidas')
          expect(objs.flatten).to eq(expected_objs)
          nil
        end
        Command.run(leo, cmd)
      end

      it 'will call show_contents(leo, leo)' do
        expect(Command::Look).to receive(:match_keyword) { leo }
        expect(Command::Look).to receive(:show_char)
            .with(leo, leo)
        Command.run(leo, cmd)
      end
    end

    context '"look nothing"' do
      it 'will not call show_obj'
      it 'will not call show_room'
      it 'will not call show_char'
    end

    context '"look closed-chest"' do
      it 'will call match_keyword("closed-chest", exits + visible entities)' do
        expected_objs = room.get(:exits, :list)
        expected_objs += visible_contents(actor: leo, cont: room)
        expected_objs += visible_contents(actor: leo, cont: leo)

        expect(Command::Look).to receive(:match_keyword) do |key,*objs|
          expect(key).to eq('closed-chest')
          expect(objs.flatten).to eq(expected_objs)
          nil
        end
        Command.run(leo, 'look closed-chest')
      end

      it 'will call show_obj(leo, closed_chest)' do
        expect(Command::Look).to receive(:match_keyword) { chest_closed }
        expect(Command::Look).to receive(:show_obj)
            .with(leo, chest_closed)
        Command.run(leo, 'look closed-chest')
      end
    end

    context '"look in closed-chest"' do
      it 'will call match_keyword("closed-chest", visible entities)' do
        expected_objs = visible_contents(actor: leo, cont: room)
        expected_objs += visible_contents(actor: leo, cont: leo)

        expect(Command::Look).to receive(:match_keyword) do |key,*objs|
          expect(key).to eq('closed-chest')
          expect(objs.flatten).to eq(expected_objs)
          chest_closed
        end
        Command.run(leo, 'look in closed-chest')
      end

      it 'will call show_contents(leo, closed_chest)' do
        expect(Command::Look).to receive(:match_keyword) { chest_closed }
        expect(Command::Look).to receive(:show_contents)
            .with(leo, chest_closed)
        Command.run(leo, 'look in closed-chest')
      end
    end

    context '"look in leonidas"' do
      it 'will not call show_contents(leo, leo)'
    end
  end
end
