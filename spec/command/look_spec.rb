require 'world'
require 'system'
require 'command'

describe Command do
  describe 'look' do
    include World::Helpers

    before(:all) do
      Component.reset!
      Component.import(YAML.load_file('./data/components.yml'))
      Entity.reset!
      Entity.import(YAML.load_file('./data/entities.yml'))

      World.reset!
      buf = <<~END
      ---
      - type: room
        components:
        - viewable:
            short: The Testing Room
            description: |-
              A horrific room where all manner of terifying experiments
              are conducted against hapless, helpless, and hopeless victims
      - type: player
        components:
        - viewable:
            short: Leonidas
            long: Leonidas the Cursed
            keywords: [ leonidas ]
      - type: npc
        components:
        - viewable:
            short: a generic mob
            long: a generic mob eyes you warily
            keywords: [ generic mob ]
      END
      @room, @player, @mob = load_yaml_entities(buf)

      move_to_location(@player, @room)
      move_to_location(@mob, @room)

      World.add_entity(@room)
      World.add_entity(@player)
      World.add_entity(@mob)
    end

    context 'at the current room' do
      let(:output) { Command.run(@player, 'look') }

      it 'will include the room name' do
        expect(output).to include(@room.get(:viewable, :short))
      end
      it 'will include the room description' do
        expect(output).to include(@room.get(:viewable, :description))
      end
      it 'will display NPCs in the room' do
        expect(output).to include(@mob.get(:viewable, :long))
      end
      it 'will not display the player in the room' do
        expect(output).to_not include(@player.get(:viewable, :short))
        expect(output).to_not include(@player.get(:viewable, :long))
      end
      context 'autoexit enabled' do
        before(:all) do
          @exit = Component.new(:exit, direction: 'north')
          @room.add(@exit)
        end
        after(:all) { @room.remove(@exit) }
        it 'will display the exits' do
          pending 'Exit entity implementation'
          expect(output.strip_color_codes).to include("Exits: north")
        end
      end
      context 'autoexit disabled' do
        it 'will not display the exits'
      end
    end
  end
end
