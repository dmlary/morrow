require_relative '../../bitmap.rb'

class World::Importer::WolvesbaneRock
  include World::Helpers

  SECT = %i{ inside city field forest hills mountains water_swim water_noswim
             air underwater desert teleport }

  TELE = Bitmap.new(
    (1 << 0) => :look,
    (1 << 1) => :count,
    (1 << 2) => :random,
    (1 << 3) => :spin)

  RoomFlags = Bitmap.new(
    (1 << 0) => :dark,
    (1 << 1) => :death,
    (1 << 2) => :no_mob,
    (1 << 3) => :peaceful,
    (1 << 4) => :no_steal,
    (1 << 5) => :no_travel_out,
    (1 << 6) => :no_magic,
    (1 << 7) => :no_travel_in,
    (1 << 8) => :silence,
    (1 << 9) => :no_push,
    (1 << 10) => :immort_rm,
    (1 << 11) => :god_rm,
    (1 << 12) => :no_recall,
    (1 << 13) => :damroom,
    (1 << 14) => :mobroom,
    (1 << 15) => :no_scry,
    (1 << 16) => :no_purge,
    (1 << 17) => :vamp_rm,
    (1 << 18) => :drak_rm)

  EX = Bitmap.new(
    (1 << 0) => :isdoor,
    (1 << 1) => :closed,
    (1 << 2) => :locked,
    (1 << 3) => :secret,
    (1 << 4) => :hidden,
    (1 << 5) => :pickproof)

  DIRS = %w{ north east south west up down }

  def initialize(*files)
    @data = files.map { |f| YAML.load_file(f) }
    import
  end

  def reset
    World.entities.keys
        .select { |e| e =~ /^wbr:/ }
        .each { |e| World.destroy_entity(e) }
  end

  def import_passage(data, dir: nil, from: nil)
    dest = data['to_room']
    id = "#{from}/passage/#{dir}-to-#{dest}"
    create_entity(id: id, base: 'base:exit')

    get_component!(id, :destination).entity = "wbr:room/#{data['to_room']}"
    if data['general_description']
      view = get_component!(id, :viewable)
      view.desc = data['general_description']
    end

    flags = EX.decode(data['exit_info'])
    key = "wbr:item/#{data['key']}" if data['key'] != -1
    if flags.include?(:isdoor)
      closable = get_component!(id, :closable)
      closable.closed = flags.include?(:closed)
      closable.lockable = key != nil
      closable.locked = flags.include?(:locked)
      closable.key = key
      closable.pickable = !flags.include?(:pickproof)
    end

    keywords = get_component!(id, :keywords)
    if data['keyword']
      keywords.words = data['keyword'].chomp.split
    else
      keywords.words = [ dir ]
    end

    # conceal the door if it's either hidden or secret, or if the direction was
    # not included in the keywords
    if flags.include?(:secret) or flags.include?(:hidden) or
        (data['keyword'] and !data['keyword'].include?(dir))
      add_component(id, :concealed)
    end

    id
  end

  def import_extra_desc(extra, room: nil)
    keywords = extra['keyword'].split
    id = "#{room}/desc/#{keywords.join('-')}"
    begin
      create_entity(id: id)
    rescue EntityManager::DuplicateId
      warn "#{room} has duplicate extra description for #{keywords}; skipping"
      return nil
    end
    get_component!(id, :viewable).format = 'extra_desc'
    get_component!(id, :viewable).desc = extra['description']
    get_component!(id, :keywords).words = keywords
    id
  end

  def import_room(data)
    room = "wbr:room/#{data['number']}"
    create_entity(base: 'base:room', id: room)

    if data['description'].nil?
      warn "#{room} has no description; making one up"
      data['description'] = 'XXX missing description; report to admin'
    end

    view = get_component!(room, :viewable)
    view.short = data['name']
    view.desc  = data['description'].chomp.chomp

    env = get_component!(room, :environment)
    env.flags = RoomFlags.decode(data['room_flags'])
    env.terrain = SECT[data['sector_type']]

    exits = get_component!(room, :exits)
    data['dir_option'].each_with_index do |passage,i|
      next if passage == '0x00000000'
      dir = DIRS[i]
      exits.send("#{dir}=", import_passage(passage, from: room, dir: dir))
    end

    data['ex_description'].each do |extra|
      id = import_extra_desc(extra, room: room)
      move_entity(entity: id, dest: room) if id
    end
  end

  def import
    @data.each do |f|
      f.each do |element|
        if element.has_key?('dir_option')
          import_room(element)
        else
          error("unsupported element:\n#{element.pretty_inspect}")
        end
      end
    end
  end
end
