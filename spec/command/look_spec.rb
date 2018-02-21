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
            description: |
              Shoulders hunched, and back bent, this man stands as
              though the world has beaten him, and he is bracing for the next
              blow.  His eyes, downcast and lined with concern, dart about the
              room, never lighting on anything for more than a moment.
      - type: npc
        components:
        - viewable:
            short: a generic mob
            long: a generic mob eyes you warily
            description: |
              It stands here, non-descript eyes doing things like blinking.
              This mob hopes for nothing more than to die in service of giving
              you experience.
            keywords: [ generic, mob ]
      END
      @room, @player, @mob = load_yaml_entities(buf)

      World.add_entity(@room)
      World.add_entity(@player)
      World.add_entity(@mob)

      move_to_location(@player, @room)
      move_to_location(@mob, @room)
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

    shared_examples 'common elements' do
      it 'will include the short name' do
        expect(output).to include(target.get(:viewable, :short))
      end
      it 'will include the description' do
        expect(output).to include(target.get(:viewable, :description))
      end
      it 'will include the keywords' do
        expect(output).to include(target.get(:viewable, :keywords).join('-'))
      end
      it 'will include the status' do
        skip 'no health component' unless target.get(:health)
      end
    end

    shared_examples 'equipment' do |entity|
      it 'will include the equipment'
    end

    context 'at something that does not exist' do
      let(:output) { Command.run(@player, 'look purple-people-eater') }
      it 'will output an error message' do
        expect(output).to eq("You do not see that here.")
      end
    end
    context 'at ourselves' do
      let(:target) { @player }
      let(:output) { Command.run(@player, 'look self') }
      include_examples('common elements')
      include_examples('equipment')
    end
    context 'at a mob' do
      let(:target) { @mob }
      let(:output) { Command.run(@player, 'look mob') }
      include_examples('common elements')
      include_examples('equipment')
    end
    context 'at an exit' do
    end
    context 'at a room feature' do
    end
    context 'at an item in inventory' do
    end
    context 'at an equipped item' do
    end
    context 'at an item in the room' do
    end
    context 'at a container' do
    end
  end
end
