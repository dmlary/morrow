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
      shared_examples 'has both fields' do
        it 'will have fields for field_1 and field_2' do
          expect(comp.fields).to contain_exactly(*%i{field_1 field_2})
        end
      end

      context 'without defaults' do
        let(:comp) do
          Component.define('test', 'field_1', 'field_2')
        end
        include_examples 'has both fields'
      end

      context 'with defaults' do
        let(:comp) do
          Component.define('test', field_1: :pass, field_2: :also_pass)
        end
        include_examples 'has both fields'

        it 'will have :pass as the default for :field_1' do
          expect(comp.defaults[:field_1]).to eq(:pass)
        end
        it 'will have :also_pass as the default for :field_2' do
          expect(comp.defaults[:field_2]).to eq(:also_pass)
        end
      end
    end
  end

  describe 'new' do
    context 'component with no data' do
      it 'will return an instance of the component' do
        Component.define(:test)
        test = Component.new(:test)
        expect(test.type).to eq(:test)
      end
    end

    context 'component composed of key/value store' do
      it 'will set value to nil if no default provided' do
        Component.define(:health, :max, :current)
        h = Component.new(:health)
        expect(h.get(:max)).to be_nil
        expect(h.get(:current)).to be_nil
      end
      it 'will set default values if provided' do
        Component.define(:health, max: 100, current: 10)
        h = Component.new(:health)
        expect(h.get(:max)).to eq(100)
        expect(h.get(:current)).to eq(10)
      end
      it 'will accept values as parameters' do
        Component.define(:health, max: 100, current: 10)
        h = Component.new(:health, current: 0)
        expect(h.get(:max)).to eq(100)
        expect(h.get(:current)).to eq(0)
      end
      it 'will accept values as arguments' do
        Component.define(:health, max: 100, current: 10)
        h = Component.new(:health, 50)
        expect(h.get(:max)).to eq(50)
        expect(h.get(:current)).to eq(10)
      end
    end
  end

  describe '#get(field=:value)' do
    let (:comp) { Component.define(:test, value: :pass).new }

    context 'when the field exists' do
      it 'will return the value' do
        expect(comp.get(:value)).to eq(:pass)
      end
    end
    context 'when the field does not exist' do
      it 'will raise an InvalidField error' do
        expect { comp.get(:bad_field) }.to raise_error(Component::InvalidField)
      end
    end
  end

  describe '#set(field=:value, value)' do
    let (:comp) { Component.define(:test, value: :fail, other: :fail).new }
    context 'when no field is supplied' do
      it 'will set the value' do
        comp.set(:pass)
        expect(comp.get(:value)).to eq(:pass)
      end
    end
    context 'when field is supplied' do
      it 'will set the requested field' do
        comp.set(:other, :pass)
        expect(comp.get(:other)).to eq(:pass)
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
        expect(Component.new(:test).get(:a)).to eq(nil)
      end
      it 'will have nil for :b' do
        expect(Component.new(:test).get(:b)).to eq(nil)
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
        expect(Component.new(:test).get(:a)).to eq(nil)
      end
      it 'will have 3 for :b' do
        expect(Component.new(:test).get(:b)).to eq(3)
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
