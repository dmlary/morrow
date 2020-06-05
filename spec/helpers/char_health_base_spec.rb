describe 'Morrow::Helpers.char_health_base' do
  let(:char) { create_entity(base: 'spec:char/actor') }
  let(:char_comp) { get_component!(char, :character) }

  before(:all) { reset_world }

  context 'entity is not a character' do
    it 'will raise InvalidEntity' do
      ball = create_entity(base: 'spec:obj/ball')
      expect { char_health_base(ball) }
          .to raise_error(Morrow::InvalidEntity)
    end
  end

  [ { desc: 'single class; passes level to func',
      classes: {
        warrior: { level: 23, func: '{ level }' }
      },
      expect: 23 },
    { desc: 'dual class; average health funcs',
      classes: {
        warrior: { level: 1, func: '{ 25 }' },
        thief:   { level: 5, func: '{ 10 }' },
      },
      expect: 17 },
    { desc: 'func references base',
      classes: {
        warrior: { level: 12, func: '{ base }' },
      },
      base: 1234,
      expect: 1234 },
  ].each do |t|
    context t[:desc] do

      # create a base entity for our test class definitions
      let(:base) do
        e = create_entity(base: 'morrow:class/base')
        get_component(e, :metadata).base.clear
        get_component!(e, :class_definition).health_func = t[:base] || 100
        e
      end

      # create our class definition entities
      let(:classes) do
        t[:classes].inject({}) do |o, (name, cfg)|
          e = create_entity(base: base)
          get_component!(e, :class_definition).health_func =
              Morrow::Function.new(cfg[:func])
          o[name] = e
          o
        end
      end

      before(:each) do
        # set the character level for each class provided
        char_comp.class_level = {}
        t[:classes].each do |name, cfg|
          char_comp.class_level[name] = cfg[:level]
        end

        # switch out the real classes for our stubbed classes
        allow(Morrow.config).to receive(:classes).and_return(classes)
      end

      it 'will return %d' % t[:expect] do
        expect(char_health_base(char)).to eq(t[:expect])
      end
    end
  end
end
