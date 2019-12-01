module EntityManager::Loader
  class Base
    class << self
      def inherited(other)
        EntityManager.register_loader(other)
      end

      def load(manager, path)
        loader = new(manager)
        loader.load(path)
      end

      def supports?(path)
        raise RuntimeError, 'implement this method in your loader'
      end
    end

    def initialize(manager)
      @manager = manager
    end

    def load(path)
      raise RuntimeError, 'implement this method in your loader'
    end
  end
end

require_relative 'loader/yaml'
