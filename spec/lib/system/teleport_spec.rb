describe System::Teleport do
  include World::Helpers

  before(:each) { load_test_world }
  let(:leo) { 'spec:mob/leonidas' }
  let(:teleport) { get_component!(leo, :teleport) }
  let(:dest) { create_entity(base: 'base:room') }
  let(:src) { create_entity(base: 'base:room') }
  before(:each) { move_entity(entity: leo, dest: src) }

  def run_update
    System::Teleport.update(leo, teleport)
  end

  shared_examples 'error' do
    before(:each) { run_update }
    it 'will remove the teleport component' do
      expect(get_component(leo, :teleport)).to eq(nil)
    end
    it 'will not move the entity' do
      expect(entity_location(leo)).to eq(src)
    end
  end

  context 'with no time set' do
    before(:each) { teleport.dest = dest }
    include_examples 'error'
  end

  context 'with no dest set' do
    before(:each) { teleport.time = Time.now }
    include_examples 'error'
  end

  context 'when time is in the future' do
    before(:each) do
      teleport.dest = dest
      teleport.time = Time.now + 1
      run_update
    end

    it 'will not move the entity' do
      expect(entity_location(leo)).to eq(src)
    end
  end

  context 'when time is in the past' do
    before(:each) do
      teleport.dest = dest
      teleport.time = Time.now - 1
      run_update
    end

    it 'will move the entity' do
      expect(entity_location(leo)).to eq(dest)
    end
  end
end

