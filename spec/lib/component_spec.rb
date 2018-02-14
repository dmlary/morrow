require 'component'
require 'yaml'

describe Component do
  before(:each) { Component.reset! }

  describe 'define' do
    it 'will define a new component type' do
      expect { Component.new('test') }
          .to raise_error(Component::NotDefined)
      Component.define('test')
      expect { Component.new('test') }.to_not raise_error
    end
    it 'will raise an exception if the type already exists' do
      Component.define('test')
      expect { Component.define('test') }
          .to raise_error(Component::AlreadyDefined)
    end
  end

  describe 'new' do
    context 'no data' do
      it 'will return an instance of the component' do
        Component.define(:test)
        test = Component.new(:test)
        expect(test.component).to eq(:test)
      end
    end
    context 'instance value' do
      it 'will set component to a new instance of the class by default' do
        Component.define(:title, String)
        title = Component.new(:title)
        expect(title).to be_a(String)
        expect(title.component).to eq(:title)
      end
      xit 'will support a default value for the class' do
        Component.define(:test, String, 'pass')
        comp = Component.new(:test)
        expect(test).to eq('pass')
      end
    end
    context 'key/value store' do
      it 'will set value to nil if no default provided' do
        Component.define(:health, :max, :current)
        h = Component.new(:health)
        expect(h.max).to be_nil
        expect(h.current).to be_nil
      end
      it 'will set default values if provided' do
        Component.define(:health, max: 100, current: 10)
        h = Component.new(:health)
        expect(h.max).to eq(100)
        expect(h.current).to eq(10)
      end
      it 'will accept values as parameters' do
        Component.define(:health, max: 100, current: 10)
        h = Component.new(:health, current: 0)
        expect(h.max).to eq(100)
        expect(h.current).to eq(0)
      end
      it 'will accept values as arguments' do
        Component.define(:health, max: 100, current: 10)
        h = Component.new(:health, 50)
        expect(h.max).to eq(50)
        expect(h.current).to eq(10)
      end
    end
  end

  describe 'import' do
    context 'with no value' do
      before(:each) { Component.import({name: :test}) }
      it 'will define the component' do
        expect { Component.new(:test) }.to_not raise_error
      end
      it 'will not have any value' do
        expect(Component.new(:test)).to be_a_kind_of(Component::Empty)
      end
    end

    context 'with a value of String' do
      before(:each) { Component.import({name: :test, value: String}) }
      it 'will define the component' do
        expect { Component.new(:test) }.to_not raise_error
      end
      it 'will be a type of String' do
        expect(Component.new(:test)).to be_a_kind_of(String)
      end
    end

    context 'with multiple keys' do
      before(:each) { Component.import({name: :test, value: [:a, :b]}) }
      it 'will define the component' do
        expect { Component.new(:test) }.to_not raise_error
      end
      it 'will have nil for :a' do
        expect(Component.new(:test).a).to eq(nil)
      end
      it 'will have nil for :b' do
        expect(Component.new(:test).b).to eq(nil)
      end
    end

    context 'with multiple keys and defaults' do
      before(:each) { Component.import({name: :test, value: [:a, b: 3]}) }
      it 'will define the component' do
        expect { Component.new(:test) }.to_not raise_error
      end
      it 'will have nil for :a' do
        expect(Component.new(:test).a).to eq(nil)
      end
      it 'will have 3 for :b' do
        expect(Component.new(:test).b).to eq(3)
      end
    end

    context 'with multiple definitions' do
      it 'will define both components' do
        buf =<<~END
        ---
        - name: description
          value: !ruby/class 'String'
        - name: contents
          value: !ruby/class 'Array'
        END
        Component.import(YAML.load(buf))
        expect { Component.new(:description) }.to_not raise_error
        expect { Component.new(:contents) }.to_not raise_error
      end
    end
  end
  describe 'export' do
    it 'will export a structure that matches imported components' do
      buf =<<~END
      ---
      - name: description
        value: !ruby/class 'String'
      - name: contents
        value: !ruby/class 'Array'
      END
      data = YAML.load(buf)
      Component.import(data)
      expect(Component.export).to eq(data)
    end
  end
end
