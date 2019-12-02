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
    context 'a component with no fields' do
      let(:comp) { Component.define(:test) }
      it 'will not have any fields' do
        expect(comp.fields).to be_empty
      end
    end
    context 'a component with fields' do
      let(:comp) do
        Component.define('test',
            fields: {field_1: :pass, field_2: :also_pass})
      end

      it 'will have fields for field_1 and field_2' do
        expect(comp.fields).to contain_exactly(*%i{field_1 field_2})
      end
      it 'will have :pass as the default for :field_1' do
        expect(comp.defaults[:field_1]).to eq(:pass)
      end
      it 'will have :also_pass as the default for :field_2' do
        expect(comp.defaults[:field_2]).to eq(:also_pass)
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

    context 'component with fields' do
      context 'default values provided' do
        it 'will use the default values' do
          Component.define(:health, fields: {max: 100, current: 10})
          h = Component.new(:health)
          expect(h.get(:max)).to eq(100)
          expect(h.get(:current)).to eq(10)
        end
        it 'will assign unique instances of default values' do
          Component.define(:inventory, fields: { value: [] })
          a = Component.new(:inventory)
          b = Component.new(:inventory)
          expect(a.get.__id__).to_not eq(b.get.__id__)
        end
      end
      it 'will accept values as parameters' do
        Component.define(:health, fields: { max: 100, current: 10 })
        h = Component.new(:health, current: 0)
        expect(h.get(:max)).to eq(100)
        expect(h.get(:current)).to eq(0)
      end
      it 'will accept values as arguments' do
        Component.define(:health, fields: { max: 100, current: 10 })
        h = Component.new(:health, 50)
        expect(h.get(:max)).to eq(50)
        expect(h.get(:current)).to eq(10)
      end

      context 'with a frozen String value for the field' do
        it 'will not clone the String' do
          Component.define(:test, fields: { value: nil })
          str = "frozen".freeze
          c = Component.new(:test, str)
          expect(c.get.__id__).to eq(str.__id__)
        end
      end
      context 'with an unfrozen String value for the field' do
        it 'will clone the String' do
          Component.define(:test, fields: { value: nil })
          str = "frozen"
          c = Component.new(:test, str)
          expect(c.get.__id__).to_not eq(str.__id__)
        end
      end
    end
  end

  describe '#get(field=:value)' do
    let (:comp) { Component.define(:test, fields: { value: :pass }).new }

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
    let (:comp) do
      Component.define(:test, fields: { value: :fail, other: :fail }).new
    end
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

  describe '#clone' do
    it 'will clone field values'
  end

  describe '#modified_fields' do
    let(:component) do
      Component.reset!
      Component.define(:test, fields: { value: :default }).new
    end

    context 'when nothing has been modified' do
      it 'will return an empty Hash' do
        expect(component.modified_fields).to eq({})
      end
    end

    context 'when a field is modified' do
      it 'along with its value will be included in the results' do
        component.set(:pass)
        expect(component.modified_fields).to eq({value: :pass})
      end
    end

    context 'when a field is set to the default value' do
      it 'along with its value will be included in the results' do
        component.set(:default)
        expect(component.modified_fields).to eq({value: :default})
      end
    end
  end
end
