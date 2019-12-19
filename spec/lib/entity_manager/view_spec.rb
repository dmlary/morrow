describe EntityManager::View do
  let(:req_a) { Class.new(Component) }
  let(:req_b) { Class.new(Component) }
  let(:optional) { Class.new(Component) }
  let(:excluded) { Class.new(Component) }
  let(:non_uniq) { Class.new(Component) { not_unique } }
  let(:entity) { World.add_entity(Entity.new) }
  let(:view) do
    EntityManager::View
        .new(all: [ req_a, req_b ], any: [ optional ], excl: [ excluded ])
  end

  describe '#update!(entity)' do
    shared_examples 'entity not present' do
      before(:each) { view.update!(entity) }
      it 'will not add the Entity' do
        expect(view.each.map(&:first)).to_not include(entity.id)
      end
    end

    shared_examples 'entity present' do
      before(:each) { view.update!(entity) }
      it 'will add the Entity' do
        expect(view.each.map(&:first)).to include(entity.id)
      end
    end

    shared_examples 'excluded components' do |present|
      context 'with an excluded Component' do
        before(:each) { entity << excluded.new }
        include_examples 'entity not present'
      end

      context 'without any excluded Components' do
        if present
          include_examples 'entity present'
        else
          include_examples 'entity not present'
        end
      end
    end

    shared_examples 'optional components' do |present|
      context 'without any optional Components' do
        include_examples 'excluded components', false
      end
      context 'with an optional Components' do
        before(:each) { entity << optional.new }
        include_examples 'excluded components', present && true
      end
    end

    shared_examples 'required components' do
      context 'with no required Components' do
        include_examples 'optional components', false
      end
      context 'with some required Components' do
        before(:each) { entity << req_a.new }
        include_examples 'optional components', false
      end
      context 'with all required Components' do
        before(:each) { entity << req_a.new; entity << req_b.new }
        include_examples 'optional components', true
      end
    end

    context 'Entity is not present in view' do
      include_examples 'required components'
    end
    context 'Entity is already present in view' do
      before(:each) do
        entity << req_a.new
        entity << req_b.new
        entity << optional.new
        view.update!(entity)
        entity.rem_component(req_a)
        entity.rem_component(req_b)
        entity.rem_component(optional)
      end
      include_examples 'required components'
    end

    context 'when one required Component is unique, and one is non-unique' do
      let(:view) { EntityManager::View.new(all: [ req_a, non_uniq]) }

      context 'and two non-unique instances exist on the Entity' do
        before(:each) { 2.times { entity << non_uniq.new } }
        include_examples 'entity not present'
      end

      context 'and one unique, and multiple non-unique instances exist' do
        let(:non_uniqs) { 2.times.map { non_uniq.new } }
        before(:each) do
          entity << req_a.new
          entity << non_uniqs
          view.update!(entity)
        end
        it 'will include all non-unique instances in the record' do
          expect(view.each.first[-1]).to contain_exactly(*non_uniqs)
        end
      end
    end
    context 'when an optional Component is non-unique' do
      let(:view) { EntityManager::View.new(any: [ optional, non_uniq ]) }

      context 'and no non-unique instances are provided' do
        before(:each) do
          entity << optional.new
          view.update!(entity)
        end
        it 'will add an empty array for that component in the record' do
          id, opt, non_uniq = view.each.first
          expect(non_uniq).to eq([])
        end
      end
      context 'and multiple non-unique instances are provided' do
        let(:non_uniqs) { 2.times.map { non_uniq.new } }
        before(:each) do
          entity << req_a.new
          entity << non_uniqs
          view.update!(entity)
        end
        it 'will include each of the non-unique instances in the record' do
          id, opt, non_uniq = view.each.first
          expect(non_uniq).to contain_exactly(*non_uniqs)
        end
      end

      context 'and multiple Entity instances have the Component' do
        let(:non_uniq_a) { non_uniq.new }
        let(:non_uniq_b) { non_uniq.new }
        let(:entity_a) { Entity.new(non_uniq_a) }
        let(:entity_b) { Entity.new(non_uniq_b) }
        before(:each) { view.update!(entity_a); view.update!(entity_b) }

        it 'will include only the Components in that Entity in the record' do
          id, opt, non_uniq = view.each.find { |id,*_| id == entity_b.id }
          expect(non_uniq).to contain_exactly(non_uniq_b)
        end
      end
    end
  end

  describe '#each' do
    context 'with excluded Components' do
      let(:view) { EntityManager::View.new(excl: [ VirtualComponent ]) }
      let(:entity) { Entity.new }
      before(:each) { view.update!(entity) }

      it 'will not yield a value for excluded components' do
        expect(view.each.to_a.first).to eq([entity.id])
      end
    end
  end
end
