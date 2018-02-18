require 'world'
require 'system'

describe System::CommandQueue do
  include Entity::Helpers
  include System::Base

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
          .set(:name, 'The Testing Room')
          .set(:description,
              'A horrific room where all manner of terifying experiments ' <<
              'are conducted against hapless, helpless, and hopeless victims.')

      @player = Entity.new(:player)
          .set(:name, 'Leonidas')
          .set(:title, 'the Cursed')
          .set(:keywords, %w{ leonidas })

      @mob = Entity.new(:npc)
          .set(:short, 'generic mob')
          .set(:long, 'a generic mob eyes you warily')
          .set(:keywords, %w{ generic mob })

      move_to_location(@player, @room)
      move_to_location(@mob, @room)

      World.add_entity(@room)
      World.add_entity(@player)
      World.add_entity(@mob)
    end
    context 'at the current room' do
      let(:output) { System::CommandQueue.handle_command(@player, 'look') }

      it 'will include the room name' do
        expect(output).to include(@room.get_value(:name))
      end
      it 'will include the room description' do
        expect(output).to include(@room.get_value(:description))
      end
      it 'will display NPCs in the room' do
        expect(output).to include(@mob.get_value(:long))
      end
      it 'will not display the player in the room' do
        expect(output).to_not include(@player.get_value(:name))
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
