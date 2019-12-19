require 'world'
require 'system'
require 'command'

describe World::Helpers do
  include World::Helpers
  before(:all) { load_test_world }

  describe 'match_keyword(buf, *pool, multiple: false)' do
    context 'multiple: false' do
    end
    context 'mutliple: true' do
    end
  end

  describe 'spawn(dest, base)' do
  end

  describe 'visibile_contents(actor: nil, cont: nil)' do
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

  describe 'entity_desc(entity)' do
    context 'when Entity has VirtualComponent' do
      it 'will return VirtualComponent.id' do
        entity = Entity.new
        entity << VirtualComponent.new(id: 'passed')
        expect(entity_desc(entity)).to eq('passed')
      end
    end
    context 'when Entity does not have VirtualComponent' do
      it 'will return LoadedComponent.base and KeywordComponent.words' do
        entity = Entity.new
        entity << LoadedComponent.new(base: [ Reference.new('test:base') ],
                                      area: 'test')
        entity << KeywordsComponent.new(words: ['words', 'passed'])
        expect(entity_desc(entity)).to eq('[test:base] words-passed')
      end
    end
  end
end
