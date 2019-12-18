require 'world'
require 'entity'
require 'component'

describe World do
  describe '.update_views(entity)' do
    it 'will call EntityView#update! on each view'
  end

  describe '.update' do
    context 'with no systems registered' do
      xit 'will do nothing'
    end

    context 'with a system registered' do
      context 'when no entities with the requested component exist' do
        it 'will not call the system'
      end
      context 'when entities with the requested component exist' do
        it 'will call the system'
      end
      context 'when multiple entities exist' do
      end
      context 'when entities with the all components exist' do
      end
    end
  end
end
