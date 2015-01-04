module Spritz

  class Rect

    attr_accessor :x, :y, :width, :height, :value

    def initialize(value, x, y, width, height, rotated = false)
      @value, @x, @y, @width, @height, @rotated = value, x, y, width, height, rotated
    end

    def rotated?
      @rotated
    end

    def intersects?(other)
      return @x >= other.x + other.width || @x + @width <= other.x ||
        @y >= other.y + other.height || @y + @height <= other.y
    end

    def contained_in?(other)
      return @x >= other.x && @y >= other.y &&
        @x + @width <= other.x + other.width &&
        @y + @height <= other.y + other.height
    end

    def x2
      @x + @width
    end

    def y2
      @y + @height
    end

  end

end