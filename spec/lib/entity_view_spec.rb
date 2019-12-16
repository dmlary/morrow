describe EntityView do
  let(:req_a) { Class.new(Component) }
  let(:req_b) { Class.new(Component) }
  let(:optional) { Class.new(Component) }
  let(:excluded) { Class.new(Component) }
  let(:entity) { World.add_entity(Entity.new) }
  let(:view) do
    EntityView.new(all: [ req_a, req_b ], any: [ optional ], excl: [ excluded ])
  end

  describe '#add(entity)' do
    # well this is hard to test
  end

  describe '#update(entity)' do
    context 'Entity is not present' do
      context 'Entity matches the view criteria' do
        before(:each) do
          expect(view).to receive(:match?).with(entity).and_return(true)
        end
        
        it 'will call #add(entity)' do
          expect(view).to receive(:add).with(entity)
          view.update(entity)
        end
      end

      context 'Entity does not match the view criteria' do
        before(:each) do
          expect(view).to receive(:match?).with(entity).and_return(false)
        end

        it 'will not call #add(entity)' do
          expect(view).to_not receive(:add)
          view.update(entity)
        end
      end
    end

    context 'Entity is already present' do
      before(:each) { view.add(entity) }

      context 'Entity matches the view criteria' do
        before(:each) do
          expect(view).to receive(:match?).with(entity).and_return(true)
        end
        
        it 'will call #add(entity)' do
          expect(view).to receive(:add).with(entity)
          view.update(entity)
        end
      end

      context 'Entity does not match the view criteria' do
        before(:each) do
          expect(view).to receive(:match?).with(entity).and_return(false)
        end

        it 'will remove the Entity' do
          view.update(entity)
          expect(view.each.map(&:first)).to_not include(entity)
        end
      end
    end
  end

  describe '#match?(entity)' do
    shared_examples 'excluded Components' do |match|
      context 'with an excluded Component' do
        before(:each) { entity << excluded.new }

        it 'will return false' do
          expect(view.match?(entity)).to be(false)
        end
      end
      context 'without any excluded Components' do
        it 'will return true' do
          expect(view.match?(entity)).to be(match && true)
        end
      end
    end

    shared_examples 'optional Components' do |match|
      context 'with any optional Component' do
        before(:each) { entity << optional.new }
        include_examples 'excluded Components', match && true
      end
      context 'without any optional Components' do
        include_examples 'excluded Components', false
      end
    end

    context 'with all required Components' do
      before(:each) do
        entity << req_a.new
        entity << req_b.new
      end
      include_examples 'optional Components', true
    end
    context 'without all required Components' do
      before(:each) do
        entity << req_a.new
      end
      include_examples 'optional Components', false
    end
  end
end
