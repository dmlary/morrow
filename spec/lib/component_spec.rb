require 'component'
require 'yaml'

describe Component do
  describe '.field(name, default: nil, freeze: false)' do
    let(:component) do
      Class.new(Component) do
        field :value, default: 4
      end.new
    end
    it 'will define a reader method' do
      expect(component).to respond_to(:value)
    end
    it 'will define a writer method' do
      expect(component).to respond_to(:value=)
    end
    it 'will set the default value for the field' do
      expect(component.value).to eq(4)
    end
  end

  describe '#merge?' do
    context 'on a Component that may be merged by Entity#merge' do
      let(:component) { Class.new(Component).new }
      it 'will return true' do
        expect(component.merge?).to eq(true)
      end
    end
    context 'on a Component that may not be merged by Entity#merge' do
      let(:component) do
        Class.new(Component) { not_merged }.new
      end
      it 'will return true' do
        expect(component.merge?).to eq(false)
      end
    end
  end

  describe '.unique?' do
    context 'on a unique Component' do
      let(:component) { Class.new(Component) }
      it 'will return true' do
        expect(component.unique?).to eq(true)
      end
    end
    context 'on a non-unique Component' do
      let(:component) { Class.new(Component) { not_unique } }
      it 'will return false' do
        expect(component.unique?).to eq(false)
      end
    end
  end

  describe '#unique?' do
    context 'on a unique Component' do
      let(:component) { Class.new(Component).new }
      it 'will return true' do
        expect(component.unique?).to eq(true)
      end
    end
    context 'on a non-unique Component' do
      let(:component) { Class.new(Component) { not_unique }.new }
      it 'will return false' do
        expect(component.unique?).to eq(false)
      end
    end
  end

  describe 'field setters' do
    context 'when the field is declared with freeze: false' do
      let(:component) do
        Class.new(Component) do
          field :value, freeze: false
        end.new
      end
      let(:str) { 'wolf' }
      context 'when called with a non-frozen value' do
        it 'will clone the value' do
          component.value = str
          expect(component.value.__id__).to_not eq(str.__id__)
        end
        it 'will not freeze the value' do
          component.value = str
          expect(component.value).to_not be_frozen
        end
      end

      context 'when called with a frozen value' do
        it 'will not clone the value' do
          str = 'wolf'.freeze
          component.value = str
          expect(component.value.__id__).to eq(str.__id__)
        end
      end
    end
    context 'when the field is declared with freeze: true' do
      let(:component) do
        Class.new(Component) do
          field :value, freeze: true
        end.new
      end
      let(:str) { 'bear' }

      context 'when called with a non-frozen value' do
        it 'will clone the value' do
          component.value = str
          expect(component.value.__id__).to_not eq(str.__id__)
        end
        it 'will freeze the value' do
          component.value = str
          expect(component.value).to be_frozen
        end
      end
      context 'when called with a frozen value' do
        it 'will not clone the value' do
          str.freeze
          component.value = str
          expect(component.value.__id__).to eq(str.__id__)
        end
      end
    end

    context 'when the field is declared with clone: false' do
      let(:component) do
        Class.new(Component) do
          field :value, clone: false
        end.new
      end
      it 'will not clone the value' do
        value = "test"
        component.value = value
        expect(component.value).to be(value)
      end
      it 'will not freeze the value' do
        value = "test"
        component.value = value
        expect(component.value).to_not be_frozen
      end
    end

    context 'when the field is declared with valid: Array' do
      let(:comp) do
        Class.new(Component) do
          field :value, valid: [ :pass ]
        end
      end

      context 'with a value from the valid array is set' do
        it 'will set the value' do
          c = comp.new
          c.value = :pass
          expect(c.value).to eq(:pass)
        end
      end

      context 'with a value not in the valid array' do
        it 'will raise an error' do
          c = comp.new
          expect { c.value = :fail }.to raise_error(Component::InvalidValue)
        end
      end
    end

    context 'when the field is declared with valid: Proc' do
      let(:comp) do
        Class.new(Component) do
          field :value, valid: proc { |v| v.nil? or v == :pass }
        end
      end

      context 'with a value from the valid array is set' do
        it 'will set the value' do
          c = comp.new
          c.value = :pass
          expect(c.value).to eq(:pass)
        end
      end

      context 'with a value not in the valid array' do
        it 'will raise an error' do
          c = comp.new
          expect { c.value = :fail }.to raise_error(Component::InvalidValue)
        end
      end
    end
  end

  describe 'field getters' do
    it 'will return the value' do
      c = Class.new(Component) { field :value, default: :pass }.new
      expect(c.value).to eq(:pass)
    end
  end

  describe '#initialize' do
    let(:klass) do
      Class.new(Component) do
        field :a, default: :a
        field :b, default: :b
        field :c, default: :c
      end
    end

    context 'when the argument is an Array' do
      context 'that has too few elements' do
        it 'will raise an ArgumentError' do
          expect { klass.new([1,2]) }.to raise_error(ArgumentError)
        end
      end
      context 'that has too many elements' do
        it 'will raise an ArgumentError' do
          expect { klass.new([1,2,3,4]) }.to raise_error(ArgumentError)
        end
      end
      context 'that has the right number of elements' do
        it 'will call the field setters' do
          expect_any_instance_of(klass).to receive(:a=).with(1)
          expect_any_instance_of(klass).to receive(:b=).with(2)
          expect_any_instance_of(klass).to receive(:c=).with(3)
          klass.new([1,2,3])
        end
      end
    end

    context 'when the argument is a Hash' do
      context 'with an unknown field as a key' do
        it 'will raise an ArgumentError' do
          expect { klass.new(wolf: 3) }.to raise_error(ArgumentError)
        end
      end
      context 'with known fields as keys' do
        it 'will call the first field setter with the supplied value' do
          expect_any_instance_of(klass).to receive(:a=).with(1)
          klass.new(a: 1)
        end
        it 'will call the remaining field setters with default values' do
          expect_any_instance_of(klass).to receive(:b=)
              .with(:b, set_modified: false)
          expect_any_instance_of(klass).to receive(:c=)
              .with(:c, set_modified: false)
          klass.new(a: 1)
        end
      end
    end

    context 'when no argument is provided' do
      it 'will call the field setters with the default values' do
        expect_any_instance_of(klass).to receive(:a=)
            .with(:a, set_modified: false)
        expect_any_instance_of(klass).to receive(:b=)
            .with(:b, set_modified: false)
        expect_any_instance_of(klass).to receive(:c=)
            .with(:c, set_modified: false)
        klass.new
      end
    end
  end

  describe '#to_h' do
    it 'will return a hash of all field values' do
      comp = Class.new(Component) do
        field :a, default: :a
        field :b, default: :b
      end.new
      expect(comp.to_h).to include(a: :a, b: :b)
    end
  end

  describe '#-(other)' do
    let(:klass) do
      Class.new(Component) do
        field :a, default: :a
        field :b, default: :b
      end
    end
    let(:klass_b) do
      Class.new(Component) do
        field :x, default: :x
        field :y, default: :y
      end
    end
    let(:base)  { klass.new }
    let(:other) { klass.new }
    let(:other_b) { klass_b.new }

    context 'when other is a Component' do
      context 'of a different type' do
        it 'will raise an ArgumentError' do
          expect { base - other_b }.to raise_error(ArgumentError)
        end
      end
      context 'of the same type' do
        it 'will call other.to_h()' do
          expect(other).to receive(:to_h).and_return({})
          base - other
        end
      end
    end

    context 'when other is a Hash' do
      let(:diff) do
        base.a = :base
        other.a = :other
        base - other
      end

      context 'when a value differs' do
        it 'will include the field & value from base in output' do
          expect(diff).to include(a: :base)
        end
      end
      context 'when a value is the same' do
        it 'will not include the common field' do
          expect(diff).to_not include(b: :b)
        end
      end
    end
  end

  describe '#clone' do
    let(:component) { Class.new(Component) { field :value }.new }
    it 'will clone unfrozen field values' do
      str = 'wolf'
      component.value = str
      expect(component.clone.value.__id__).to_not eq(str.__id__)
    end
    it 'will not clone frozen field values' do
      str = 'wolf'.freeze
      component.value = str
      expect(component.clone.value.__id__).to eq(str.__id__)
    end
  end

  describe '#get_modified_fields' do
    let(:comp) do
      Class.new(Component) do
        field :a, default: :fail
      end.new
    end
    context 'on a Component with no modifications' do
      it 'will return an empty Hash' do
        expect(comp.get_modified_fields).to eq({})
      end
    end
    context 'on a Component that a setter has been called' do
      it 'will return a Hash with the field and value'
    end
  end

  describe '#merge!(other)' do
    let(:comp) do
      Class.new(Component) do
        field :a, default: :default
        field :b, default: :unchanged
        field :c, default: :unchanged
      end
    end
    let(:base) { comp.new(a: :failed) }
    let(:other) { comp.new }

    shared_examples 'when merged' do |pairs|
      pairs.each do |key,value|
        it "will set #{key} to #{value.inspect}" do
          expect(base.send(key)).to eq(value)
        end
      end
    end

    context 'when other is a Hash' do
      before(:each) do
        base.merge!(a: :passed, b: :passed)
      end
      include_examples 'when merged', a: :passed, b: :passed, c: :unchanged
    end

    context 'when other is an instance of the same class' do
      before(:each) do
        other.a = :default
        other.c = :passed
        base.merge!(other)
      end
      include_examples 'when merged', a: :default, b: :unchanged, c: :passed
    end
    context 'when other is an instance of a different Component' do
      it 'will raise an error' do
        other = Class.new(Component).new
        expect { base.merge!(other) }.to raise_error(ArgumentError)
      end
    end
  end

  describe '#clear_modified!' do
    let(:comp) do
      Class.new(Component) do
        field :a
        field :b
      end
    end
    it 'will clear all modified flags' do
      c = comp.new
      c.a = :failed
      c.clear_modified!
      expect(c.get_modified_fields).to eq({})
    end
  end
end
