describe Morrow::Command::Inventory do
  let(:room) { 'spec:room/act_object' }
  let(:not_here) { 'spec:room/1' }
  let(:actor) { 'spec:char/actor' }
  let(:ball) { create_entity(id: 'ball', base: 'spec:obj/ball/red') }
  let(:other_ball) { create_entity(id: 'other-ball', base: 'spec:obj/ball/blue') }
  let(:flower) { create_entity(id: 'flower', base: 'spec:obj/flower') }
  let(:fountain) { create_entity(base: 'spec:obj/fountain') }
  let(:chest_open) { create_entity(base: 'spec:obj/chest_open_empty') }
  let(:chest_closed) { create_entity(base: 'spec:obj/chest_closed') }

  before(:each) do
    reset_world
    move_entity(entity: actor, dest: room)
    player_output(actor).clear
  end

  describe 'inventory' do
    context 'is empty' do
      it "it will output 'You are not carrying anything.'" do
        expect(cmd_output(actor, "inventory"))
            .to include("You are not carrying anything")
      end
    end

    context 'is not empty' do
      before(:each) do
        move_entity(entity: ball, dest: actor)
        move_entity(entity: flower, dest: actor)
        move_entity(entity: other_ball, dest: actor)
      end

      it 'will output the inventory' do
        expect(cmd_output(actor, "inventory")).to include(<<~END)
          You are carrying 3 items:
          a blue rubber ball
          a yellow wildflower
          a red rubber ball
        END
      end
    end
  end
end
