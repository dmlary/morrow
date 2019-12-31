describe 'teleporter script' do
  include World::Helpers

  before(:each) { load_test_world }
  let(:troom) do
    create_entity(base: [ 'base:room', 'base:act/teleporter' ])
  end
  let(:teleporter) { get_component!(troom, :teleporter) }
  let(:dest) { create_entity(base: 'base:room') }
  let(:leo) { 'spec:mob/leonidas' }
  before(:each) { teleporter.dest = dest; teleporter.delay = 60 }

  context 'entity enters teleporter' do
    let(:teleport) { get_component(leo, :teleport) }
    it 'will add the teleport component to entity' do
      move_entity(entity: leo, dest: troom)
      expect(get_component(leo, :teleport)).to_not be_nil
    end

    it 'will set the teleport destination' do
      move_entity(entity: leo, dest: troom)
      expect(teleport.dest).to eq(teleporter.dest)
    end

    context 'when delay is not a range' do
      it 'will set the teleport delay' do
        move_entity(entity: leo, dest: troom)
        expect(teleport.time.to_f)
            .to be_within(1).of(Time.now.to_f + teleporter.delay)
      end
    end

    context 'when delay is a Range' do
      before(:each) { teleporter.delay = 10..20 }
      it 'will set the teleport delay to a value in the range' do
        move_entity(entity: leo, dest: troom)
        expect(teleport.time - Time.now)
            .to be_between(9,20)
      end
    end
  end

  context 'entity exits teleporter' do
    before(:each) do
      move_entity(entity: leo, dest: troom)
      expect(get_component(leo, :teleport)).to_not be_nil
      move_entity(entity: leo, dest: dest)
    end

    it 'will remove the teleport component to entity' do
      expect(get_component(leo, :teleport)).to eq(nil)
    end
  end
end
