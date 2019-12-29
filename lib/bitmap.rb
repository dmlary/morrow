# Bitmap
#
# Parser for C bitmaps
#
# Usage:
#   Flags = Bitmap.new(1 => :dark, 2 => :no_mob, 4 => :no_push)
#
#   Flags.decode(3)   # => [ :dark, :no_mob ]
#
class Bitmap
  def initialize(map={})
    @map = map
  end

  def decode(value)
    value = value.to_i(0) if value.is_a?(String)
    @map.inject([]) { |o,(k,v)| o << v if (value & k) == k; o }
  end
end

