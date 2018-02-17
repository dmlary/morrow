require 'world'
require 'system'

describe System::CommandQueue do
  before(:all) do
    World.reset!
    Component.reset!
    Component.import(YAML.load_file('./data/components.yml'))
    Entity.reset!
    Entity.import(YAML.load_file('./data/entities.yml'))
  end

  describe 'look' do
    before(:all) do
      World.reset!
      @room = Entity.new(:room)
      @room.get(:name).value = 'Generic Room Name'
      @room.get(:description).value = 'A generic room description'
      @player = Entity.new(:player)
      @player.get(:location).value = @room.id
      World.add_entity(@room)
      World.add_entity(@player)
    end
    context 'at the current room' do
      let(:output) { System::CommandQueue.handle_command(@player, 'look') }

      it 'will include the room name' do
        expect(output).to include(@room.get_value(:name))
      end
      it 'will include the room description' do
        expect(output).to include(@room.get_value(:description))
      end
      context 'autoexit enabled' do
        before(:all) do
          @exit = Component.new(:exit, direction: 'north')
          @room.add(@exit)
        end
        after(:all) { @room.remove(@exit) }
        it 'will display the exits' do
          expect(output.strip_color_codes).to include("Exits: north")
        end
      end
      context 'autoexit disabled' do
        it 'will not display the exits'
      end
    end
  end
end
