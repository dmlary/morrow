class Helpers::Database < Module
  def initialize(p={})
    @type = p[:type] || Array
    @key = (p[:key] || :id).to_sym
    @find = p[:find] || [:id, :short]
  end

  def included(base)
    base.instance_variable_set(:@database, @type.new)
    base.instance_variable_set(:@database_key, @key)
    base.instance_variable_set(:@database_find_fields, @find)
    base.extend(ClassMethods)
  end

  module ClassMethods
    class Error < StandardError;end
    class KeyExists < Error
      def initialize(orig, added)
        @orig = orig
        @added = added
        super "key exists: %s\n  orig: %s\n  new: %s" %
            [orig.send(@database_key).inspect, orig.inspect, added.inspect ]
      end
    end

    def all
      @database.is_a?(Hash) ? @database.values : @database
    end

    def add(entry)
      found = @database[entry.send(@database_key)] and
          raise KeyExists.new(found, entry)
      @database[entry.send(@database_key)] = entry
    end

    # get(1)  # => Puff
    def get(key)
      @database[key]
    end

    # find(1)  # => Puff
    # find('Puff') # => Puff
    def find(arg)
      @database_find_fields.each do |field|
        found = if @database.is_a?(Hash)
          @database.find { |k,e| e and e.send(field) == arg }
        else
          @database.find { |e| e and e.send(field) == arg }
        end and return found
      end
    end
  end
end
