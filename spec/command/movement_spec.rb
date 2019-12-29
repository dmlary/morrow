require 'world'
require 'system'
require 'command'

describe Command::Movement do
  include World::Helpers

  before(:all) { load_test_world }
  let(:room) { create_entity(base: 'spec:room/movement') }
  let(:leo) { 'spec:mob/leonidas' }
  before(:each) { move_entity(entity: leo, dest: room) }

  describe '.traverse_passage' do
    let(:dest) { get_component(passage, :destination).entity }

    shared_examples 'will move' do
      it 'will traverse the passage' do
        expect(Command::Movement).to receive(:move_entity) do |p|
          expect(p[:entity]).to eq(leo)
          expect(p[:dest]).to eq(dest)
        end
        Command::Movement.traverse_passage(leo, dir)
      end
    end

    shared_examples 'error closed' do
      it 'will report that the passage is closed' do
        expect(Command::Movement.traverse_passage(leo, dir))
            .to include('seems to be closed.')
      end
      it 'will not traverse the passage' do
        expect(Command::Movement).to_not receive(:move_entity)
        Command::Movement.traverse_passage(leo, dir)
      end
    end

    shared_examples 'error no exit' do
      it 'will report that the passage does not exist' do
        expect(Command::Movement.traverse_passage(leo, dir))
            .to include('Alas, you cannot go that way')
      end
      it 'will not traverse the passage' do
        expect(Command::Movement).to_not receive(:move_entity)
        Command::Movement.traverse_passage(leo, dir)
      end
    end

    def add_passage(passage)
      get_component!(room, :exits).send("#{dir}=", passage)
    end

    World::CARDINAL_DIRECTIONS.each do |dir|
      context(dir) do

        { nil => 'error no exit',
          'spec:exit/open' => 'will move',
          'spec:exit/door/open' => 'will move',
          'spec:exit/door/closed' => 'error closed',
          'spec:exit/door/open/hidden' => 'will move',
          'spec:exit/door/closed/hidden' => 'error no exit'
        }.each do |entity,examples|
          context(entity || 'no exit') do
            let(:passage) { entity }
            let(:dir) { dir }
            before(:each) { add_passage(passage) }
            include_examples examples
          end
        end
      end
    end
  end
end
