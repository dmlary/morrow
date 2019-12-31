describe 'teleporter script' do
  include World::Helpers

  before(:each) { load_test_world }
  let(:troom) do
    create_entity(base: [ 'base:room', 'base:act/teleporter' ])
  end
  let(:on_enter_hook) do
    get_components(troom, :hook).find { |h| h.event == :on_enter }
  end
  let(:teleporter) { get_component!(troom, :teleporter) }
  let(:dest) { create_entity(base: 'base:room') }
  let(:leo) { 'spec:mob/leonidas' }
  let(:teleport) { get_component(leo, :teleport) }
  before(:each) { teleporter.dest = dest; teleporter.delay = 60 }

  context 'entity enters teleporter' do
    it 'will add the teleport component to entity' do
      move_entity(entity: leo, dest: troom)
      expect(get_component(leo, :teleport)).to_not be_nil
    end

    it 'will set the teleport destination' do
      move_entity(entity: leo, dest: troom)
      expect(teleport.dest).to eq(teleporter.dest)
    end

    it 'will set the look field' do
      move_entity(entity: leo, dest: troom)
      expect(teleport.look).to eq(teleporter.look)
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

    context 'config[:skip_if_flying] is set' do
      before(:each) do
        on_enter_hook.script_config = { skip_if_flying: true }
      end

      it 'will not teleport an entity that is flying' do
        allow(Script::Sandbox).to receive(:entity_flying?).and_return(true)
        move_entity(entity: leo, dest: troom)
        expect(teleport).to be(nil)
      end
      it 'will teleport an entity that is not flying' do
        move_entity(entity: leo, dest: troom)
        expect(teleport).to_not be(nil)
      end
    end

    context 'config[:message] is set' do
      before(:each) do
        on_enter_hook.script_config = { message: :passed }
      end

      it 'will set teleport message' do
        move_entity(entity: leo, dest: troom)
        expect(teleport.message).to be(:passed)
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
