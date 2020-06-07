describe 'Morrow::Helpers.damage_entity' do
  let(:room) { 'spec:room/1' }
  let(:actor) { 'spec:char/actor' }
  let(:victim) { 'spec:char/victim' }

  before(:each) do
    reset_world
    move_entity(entity: actor, dest: room)
    move_entity(entity: victim, dest: room)
  end

  def set_health(entity, health)
    get_component!(entity, :character).health = health
  end

  context 'entity does not have health resource' do
    before(:each) { set_health(victim, nil) }
    it 'will raise an Morrow::InvalidEntity error' do
      expect { damage_entity(actor: actor, entity: victim, amount: 10) }
          .to raise_error(Morrow::InvalidEntity)
    end
  end

  context 'entity has health resource' do
    def call_damage_entity
      damage_entity(actor: actor, entity: victim, amount: amount)
    end

    shared_examples 'common stuff' do
      it 'will call act()' do
        expect(self).to receive(:act)
        call_damage_entity
      end

      it 'will reduce entity health resource' do
        before = entity_health(victim)
        call_damage_entity
        expect(entity_health(victim)).to eq(before - amount)
      end
    end

    context 'damaged health > 0' do
      before(:each) { set_health(victim, 100) }
      let(:amount) { 10 }

      include_examples 'common stuff'

      it 'will not change entity position' do
        call_damage_entity
        expect(entity_position(victim)).to eq(:standing)
      end
    end

    context 'damaged health equals zero' do
      before(:each) { set_health(victim, 10) }
      let(:amount) { 10 }

      include_examples 'common stuff'

      it 'will set entity position to lying' do
        call_damage_entity
        expect(entity_position(victim)).to eq(:lying)
      end

      it 'will set entity unconscious' do
        call_damage_entity
        expect(entity_unconscious?(victim)).to be(true)
      end
    end

    context 'damaged health < -10 (mortally wounded)' do
      before(:each) do
        set_health(victim, 0)
      end
      let(:amount) { 11 }

      it 'will call update_char_regen()' do
        expect(self).to receive(:update_char_regen).with(victim)
        call_damage_entity
      end
    end

    context 'damaged health < -20' do
      before(:each) do
        set_health(victim, 0)
      end
      let(:amount) { 40 }

      it 'will create a corpse for entity' do
        expect(self).to receive(:spawn_corpse)
        call_damage_entity
      end
      it 'will destroy entity' do
        call_damage_entity
        expect(entity_destroyed?(victim)).to be(true)
      end
    end

    context 'entity is sitting' do
      before(:each) do
        get_component!(victim, :character).position = :sitting
        set_health(victim, 100)
      end

      let(:amount) { 10 }

      it 'will recuce health by 1.5 times the amount' do
        call_damage_entity
        expect(entity_health(victim)).to eq(85)
      end
    end

    context 'entity is lying down' do
      before(:each) do
        get_component!(victim, :character).position = :lying
        set_health(victim, 100)
      end

      let(:amount) { 10 }

      it 'will recuce health by 2 times the amount' do
        call_damage_entity
        expect(entity_health(victim)).to eq(80)
      end
    end
  end
end
