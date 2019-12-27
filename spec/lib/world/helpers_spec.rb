require 'world'
require 'system'
require 'command'

describe World::Helpers do
  include World::Helpers
  before(:all) { load_test_world }

  describe '.send_to_char(char: nil, buf: nil)' do
    context 'char has no ConnectionComponent' do
      it 'will not error' do
        char = create_entity
        expect { send_to_char(char: char, buf: 'blah') }
            .to_not raise_error
      end
    end
    context 'char is not connected' do
      it 'will not error' do
        char = create_entity(components: :connection)
        expect { send_to_char(char: char, buf: 'blah') }
            .to_not raise_error
      end
    end
    context 'char is connected' do
      it 'will append the data to the output buffer' do
        conn_comp = ConnectionComponent.new
        conn_comp.conn = instance_double('TelnetServer::Connection')
        char = create_entity(components: conn_comp)
        send_to_char(char: char, buf: 'passed')
        expect(conn_comp.buf).to eq('passed')
      end
    end
  end

  describe '.match_keyword(buf, *pool, multiple: false)' do
    context 'multiple: false' do
    end
    context 'mutliple: true' do
    end
  end

  describe '.spawn(base: nil, area: nil)' do
    it 'will set Metadata.area to the area provided' do
      entity = spawn(area: :passed)
      expect(get_component(entity, :metadata).area).to eq(:passed)
    end
  end

  describe '.visibile_contents(actor: nil, cont: nil)' do
    context 'when the container does not have the ContainerComponent' do
      it 'will raise an exception'
    end
    context 'when the container is empty' do
      it 'will return an empty Array'
    end
    context 'when an item in the container is visible to the actor' do
      it 'will be in included in the results'
    end
    context 'when an item in the container is not visible to the actor' do
      it 'will not be included in the results'
    end
  end

  describe '.save_entities(dest, *entities' do
    let(:player) { create_entity(base: [ 'base:player', 'base:race/elf' ]) }
    let(:inventory) do
      10.times.map do
        item = create_entity(base: 'base:obj/junk/ball')
        move_entity(dest: player, entity: item)
        item
      end
    end
    let(:entities) { [ player ] + inventory }
    let(:path) { tmppath << '.yml' }
    after(:each) { File.unlink(path) if File.exist?(path) }

    def entity_snapshot(entity)
      entity_components(entity).flatten.map do |comp|
        next unless comp and comp.save?
        comp.to_h
      end.compact
    end

    context 'dest does not exist' do
      it 'will creade dest' do
        save_entities(path, entities)
        expect(File.exist?(path)).to be(true)
      end

      it 'will write all entities to dest' do
        snapshot = entities.inject({}) { |o,e| o[e] = entity_snapshot(e); o }

        save_entities(path, entities)
        World.entity_manager.destroy_entity(*entities)
        load_entities(path)

        entities.each do |entity|
          expect(entity_snapshot(entity)).to eq(snapshot[entity])
        end
      end
    end
    context 'dest exists' do
      context 'an error occurs' do
        it 'will not modify original dest file'
      end
    end
  end
end
