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

    context 'a component composed of no values' do
      let(:comp) { Component.define(:test) }
      it 'will not have any fields' do
        expect(comp.fields).to be_empty
      end
    end

    context 'a component composed of values' do
      context 'without defaults' do
        let(:comp) do
          Component.define('test', 'field_1', 'field_2')
        end
        it 'will have two fields named :field_1, and :field_2'
        it 'will have nil as the default values for both fields'
      end

      context 'with defaults' do
        let(:comp) do
          Component.define('test', field_1: :pass_1, field_2: :pass_2)
        end
        it 'will have two fields named :field_1, and :field_2'
        it 'will have :pass_1 as the default for :field_1'
        it 'will have :pass_2 as the default for :field_2'
      end

      context 'reserved word is used as a key' do
        it 'will error if component is used' do
          expect { Component.define('test', :component) }
              .to raise_error(Component::ReservedKey)
        end
      end
    end
  end

  describe 'new' do
    context 'component with no data' do
      it 'will return an instance of the component' do
        Component.define(:test)
        test = Component.new(:test)
        expect(test.component).to eq(:test)
      end
    end

    context 'component composed of key/value store' do
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
        expect(Component.new(:test).class.fields).to be_empty
      end
    end

    context 'with multiple keys' do
      before(:each) do
        Component.import({name: :test, fields: {a: nil, b: nil}})
      end
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
      before(:each) do
        Component.import({name: :test, fields: {a: nil, b: 3}})
      end
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
        - name: contents
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
        fields:
          value: default description
      - name: contents
        fields: {}
      END
      data = YAML.load(buf)
      Component.import(data)
      expect(Component.export).to eq(data)
    end
  end
end
