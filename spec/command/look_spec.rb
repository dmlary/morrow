require 'world'
require 'system'
require 'command'

describe Command::Look do
  include World::Helpers

  before(:all) { load_test_world; spawn_entities }
  let(:room) { 'test-world:room/testing' }
  let(:leo) { 'test-world:mob/leonidas' }
  let(:chest_closed) { 'test-world:obj/chest_closed' }
  before(:each) { move_entity(entity: leo, dest: room) }

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

    context '"look keyword"' do
      it 'will call match_keyword("keyword", visible exits, ' +
          'visible room and actor contents)' do
        visible = visible_exits(actor: leo, room: room) +
            visible_contents(actor: leo, cont: room) +
            visible_contents(actor: leo, cont: leo)
        expect(Command::Look).to receive(:match_keyword) do |key,*entities|
          expect(key).to eq('keyword')
          expect(entities.flatten).to eq(visible.flatten)
          nil # nothing found
        end
        Command.run(leo, 'look keyword')
      end
    end

    context '"look in container"' do
      it 'will call match_keyword("in container", ' +
          'visible room & actor contents)' do
        visible = visible_contents(actor: leo, cont: room) +
            visible_contents(actor: leo, cont: leo)
        expect(Command::Look).to receive(:match_keyword) do |key,*entities|
          expect(key).to eq('container')
          expect(entities.flatten).to eq(visible.flatten)
          nil # nothing found
        end
        Command.run(leo, 'look in container')
      end
    end

    context '"look leonidas"' do
      let(:cmd) { "look leonidas" }

      it 'will call match_keyword("leonidas", ...)' do
        expect(Command::Look).to receive(:match_keyword) do |key,*objs|
          expect(key).to eq('leonidas')
          nil # nothing found
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
      it 'will call show_obj(leo, closed_chest)' do
        expect(Command::Look).to receive(:match_keyword) { chest_closed }
        expect(Command::Look).to receive(:show_obj)
            .with(leo, chest_closed)
        Command.run(leo, 'look closed-chest')
      end
    end

    context '"look in closed-chest"' do
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
