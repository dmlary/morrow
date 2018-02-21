require 'world'
require 'system'
require 'command'

describe World::Helpers do
  describe 'match_keyword(buf, *pool)' do
    include World::Helpers

    before(:all) do
      Component.reset!
      Component.import(YAML.load_file('./data/components.yml'))
      Entity.reset!
      Entity.import(YAML.load_file('./data/entities.yml'))

      World.reset!
      buf = <<~END
      ---
      - type: npc
        components:
        - viewable:
            short: a generic mob
            long: a generic mob eyes you warily
            keywords: [ generic, mob ]
      - type: npc
        components:
        - viewable:
            short: a generic mob
            long: a generic mob eyes you warily
            keywords: [ generic, mob ]
      - type: npc
        components:
        - viewable:
            short: a specific mob
            long: a specific mob, should not be found
            keywords: [ specific, mob ]
      - type: npc
        components:
        - viewable:
            short: a generic fido
            long: a beastly fido is here being generic
            keywords: [ beastly, generic, fido ]
      END
      @entities = load_yaml_entities(buf).each { |e| World.add_entity(e) }
    end

    context 'multiple matches requested' do
      let(:results) do
        match_keyword(prefix + keyword, @entities, multiple: true)
      end
      let(:keyword) { 'mob-generic' }

      shared_examples 'no matches found' do
        let(:keyword) { 'does_not_match' }
        it 'will return an empty array' do
          expect(results).to eq([])
        end
      end
      context 'with the all prefix' do
        let(:prefix) { "all." }
        it_behaves_like 'no matches found'
        it 'will return all entities with generic & mob in their keywords' do
          mobs = @entities.select do |entity|
            words = entity.get(:viewable, :keywords)
            words.include?('generic') and words.include?('mob')
          end
          expect(results).to contain_exactly(*mobs)
        end
      end
      context 'with an index prefix' do
        let(:prefix) { "2." }
        it_behaves_like 'no matches found'
        it 'will return all entities with generic & mob in their keywords' do
          mob = @entities.select do |entity|
            words = entity.get(:viewable, :keywords)
            words.include?('generic') and words.include?('mob')
          end[1]
          expect(results).to contain_exactly(mob)
        end
      end
      context 'with no prefix' do
        let(:prefix) { "" }
        it_behaves_like 'no matches found'
        it 'will return all entities with generic & mob in their keywords' do
          mobs = @entities.select do |entity|
            words = entity.get(:viewable, :keywords)
            words.include?('generic') and words.include?('mob')
          end
          expect(results).to contain_exactly(*mobs)
        end
      end
    end

    context 'single match requested' do
      let(:results) do
        match_keyword(prefix + keyword, @entities, multiple: false)
      end
      let(:keyword) { 'mob-generic' }

      shared_examples 'no matches found' do
        let(:keyword) { 'does_not_match' }
        it 'will return nil' do
          expect(results).to be_nil
        end
      end
      context 'with the all prefix' do
        let(:prefix) { 'all.' }
        it 'will raise Command::SyntaxError' do
          expect { results }.to raise_error(Command::SyntaxError)
        end
      end
      context 'with an index prefix' do
        let(:prefix) { '2.' }
        it_behaves_like 'no matches found'
        it 'will return the second generic mob' do
          mob = @entities.select do |entity|
            words = entity.get(:viewable, :keywords)
            words.include?('generic') and words.include?('mob')
          end[1]
          expect(results).to be(mob)
        end
      end
      context 'with no prefix' do
        let(:prefix) { '' }
        it_behaves_like 'no matches found'
        it 'will return the first generic mob' do
          mob = @entities.find do |entity|
            words = entity.get(:viewable, :keywords)
            words.include?('generic') and words.include?('mob')
          end
          expect(results).to be(mob)
        end

      end
    end
  end
end
