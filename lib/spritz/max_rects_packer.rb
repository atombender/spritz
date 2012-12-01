module Spritz

  # Adapted from C++ version originally by Jukka Jylänki.
  class MaxRectsPacker

    def initialize(width, height)
      @width = width
      @height = height
      @free_rects = [Rect.new(nil, 0, 0, @width, @height)]
      @used_rects = []
    end

    def insert(value, width, height)
      best_score1 = 2 ** 32
      best_score2 = 2 ** 32
      best_rect = nil

      [:bottom_left, :best_short_side_fit, :best_long_side_fit, :best_area_fit,
        :contact_point_rule].each do |method|
        new_rect, score1, score2 = self.send("find_position_for_#{method}",
          width, height, 2 ** 32, 2 ** 32)
        if new_rect
          score1 = -score1 if method == :contact_point_rule
          if new_rect and score1 < best_score1 or (score1 == best_score1 and score2 < best_score2)
            best_score1 = score1
            best_score2 = score2
            best_rect = new_rect
          end
        end
      end

      if best_rect
        @free_rects.dup.each do |free|
          if split_free_node(free, best_rect)
            @free_rects.delete(free)
          end
        end

        @free_rects.dup.each_with_index do |free, i|
          (@free_rects[(i + 1)..-1] || []).each do |free2|
            @free_rects.delete(free) if free.contained_in?(free2)
            @free_rects.delete(free2) if free2.contained_in?(free)
          end
        end

        best_rect.value = value
        @used_rects.push(best_rect)
        true
      else
        false
      end
    end

    def coverage_ratio
      return @used_rects.inject(0) { |sum, rect| sum + rect.width * rect.height } /
        (@width * @height).to_f
    end

    def rects
      @used_rects
    end

    attr_reader :width
    attr_reader :height

    private

      def find_position_for_bottom_left(width, height, best_y, best_x)
        best_rect = nil
        best_y = 2 ** 32
        @free_rects.each do |free|
          if free.width >= width and free.height >= height
            top_side_y = free.y + height
            if top_side_y < best_y or (top_side_y == best_y and free.x < best_x)
              best_rect = Rect.new(nil, free.x, free.y, width, height)
              best_y = top_side_y
              best_x = free.x
            end
          end
          if free.width >= height and free.height >= width
            top_side_y = free.y + width
            if top_side_y < best_y or (top_side_y == best_y and free.x < best_x)
              best_rect = Rect.new(nil, free.x, free.y, height, width, true)
              best_y = top_side_y
              best_x = free.x
            end
          end
        end
        return best_rect, best_y, best_x
      end

      def find_position_for_best_short_side_fit(width, height,
        best_short_side_fit, best_long_side_fit)
        best_rect = nil
        best_short_side_fit = 2 ** 32
        @free_rects.each do |free|
          if free.width >= width and free.height >= height
            leftover_horiz = (free.width - width).abs
            leftover_vert = (free.height - height).abs
            short_side_fit = [leftover_horiz, leftover_vert].min
            long_side_fit = [leftover_horiz, leftover_vert].max
            if short_side_fit < best_short_side_fit or
              (short_side_fit == best_short_side_fit and long_side_fit < best_long_side_fit)
              best_rect = Rect.new(nil, free.x, free.y, width, height)
              best_short_side_fit = short_side_fit
              best_long_side_fit = long_side_fit
            end
          end
          if free.width >= height and free.height >= width
            flipped_leftover_horiz = (free.width - height).abs
            flipped_leftover_vert = (free.height - width).abs
            flipped_short_side_fit = [flipped_leftover_horiz, flipped_leftover_vert].min
            flipped_long_side_fit = [flipped_leftover_horiz, flipped_leftover_vert].max
            if flipped_short_side_fit < best_short_side_fit or
              (flipped_short_side_fit == best_short_side_fit and flipped_long_side_fit < best_long_side_fit)
              best_rect = Rect.new(nil, free.x, free.y, height, width, true)
              best_short_side_fit = flipped_short_side_fit
              best_long_side_fit = flipped_long_side_fit
            end
          end
        end
        return best_rect, best_short_side_fit, best_long_side_fit
      end

      def find_position_for_best_long_side_fit(width, height,
        best_short_side_fit, best_long_side_fit)
        best_rect = nil
        best_long_side_fit = 2 ** 32
        @free_rects.each do |free|
          if free.width >= width and free.height >= height
            leftover_horiz = (free.width - width).abs
            leftover_vert = (free.height - height).abs
            short_side_fit = [leftover_horiz, leftover_vert].min
            long_side_fit = [leftover_horiz, leftover_vert].max
            if long_side_fit < best_long_side_fit or
              (long_side_fit == best_long_side_fit and short_side_fit < best_short_side_fit)
              best_rect = Rect.new(nil, free.x, free.y, width, height)
              best_short_side_fit = short_side_fit
              best_long_side_fit = long_side_fit
            end
          end
          if free.width >= height and free.height >= width
            leftover_horiz = (free.width - height).abs
            leftover_vert = (free.height - width).abs
            short_side_fit = [leftover_horiz, leftover_vert].min
            long_side_fit = [leftover_horiz, leftover_vert].max
            if long_side_fit < best_long_side_fit or
              (long_side_fit == best_long_side_fit and short_side_fit < best_short_side_fit)
              best_rect = Rect.new(nil, free.x, free.y, height, width, true)
              best_short_side_fit = short_side_fit
              best_long_side_fit = long_side_fit
            end
          end
        end
        return best_rect, best_short_side_fit, best_long_side_fit
      end

      def find_position_for_best_area_fit(width, height,
        best_area_fit, best_short_side_fit)
        best_rect = nil
        best_area_fit = 2 ** 32
        @free_rects.each do |free|
          area_fit = free.width * free.height - width * height
          if free.width >= width and free.height >= height
            leftover_horiz = (free.width - width).abs
            leftover_vert = (free.height - height).abs
            short_side_fit = [leftover_horiz, leftover_vert].min
            if area_fit < best_area_fit or
              (area_fit == best_area_fit and short_side_fit < best_short_side_fit)
              best_rect = Rect.new(nil, free.x, free.y, width, height)
              best_short_side_fit = short_side_fit
              best_area_fit = area_fit
            end
          end
          if free.width >= height and free.height >= width
            leftover_horiz = (free.width - height).abs
            leftover_vert = (free.height - width).abs
            short_side_fit = [leftover_horiz, leftover_vert].min
            if area_fit < best_area_fit or
              (area_fit == best_area_fit and short_side_fit < best_short_side_fit)
              best_rect = Rect.new(nil, free.x, free.y, height, width, true)
              best_short_side_fit = short_side_fit
              best_area_fit = area_fit
            end
          end
        end
        return best_rect, best_area_fit, best_short_side_fit
      end

      def common_interval_length(a, b)
        if a.end < b.begin or b.end < a.begin
          0
        else
          [a.end, b.end].min - [a.begin, b.begin].max
        end
      end

      def contact_point_score_node(x, y, width, height)
        score = 0
        score += height if x == 0 or x + width == @width
        score += width if y == 0 or y + height == @height
        @used_rects.each do |rect|
          if rect.x == x + width or rect.x + rect.width == x
            score += common_interval_length(
              rect.y..(rect.y + rect.height),
              y..(y + height))
          end
          if rect.y == y + height or rect.y + rect.height == y
            score += common_interval_length(
              rect.x..(rect.x + rect.width),
              x..(x + width))
          end
        end
        score
      end

      def find_position_for_contact_point_rule(width, height, best_contact_score, _)
        best_rect = nil
        best_contact_score = -1
        @free_rects.each do |free|
          if free.width >= width and free.height >= height
            score = contact_point_score_node(free.x, free.y, width, height)
            if score > best_contact_score
              best_rect = Rect.new(nil, free.x, free.y, width, height)
              best_contact_score = score
            end
          end
          if free.width >= height and free.height >= width
            score = contact_point_score_node(free.x, free.y, width, height)
            if score > best_contact_score
              best_rect = Rect.new(nil, free.x, free.y, height, width, true)
              best_contact_score = score
            end
          end
        end
        return best_rect, best_contact_score, 0
      end

      def split_free_node(free, used)
        if used.intersects?(free)
          false
        else
          if used.x < free.x + free.width and used.x + used.width > free.x
            if used.y > free.y and used.y < free.y + free.height
              @free_rects.push(Rect.new(nil, free.x, free.y, free.width, used.y - free.y))
            end
            if used.y + used.height < free.y + free.height
              @free_rects.push(Rect.new(nil, free.x, used.y + used.height,
                free.width, free.y + free.height - (used.y + used.height)))
            end
          end
          if used.y < free.y + free.height and used.y + used.height > free.y
            if used.x > free.x and used.x < free.x + free.width
              @free_rects.push(Rect.new(nil, free.x, free.y, used.x - free.x, free.height))
            end
            if used.x + used.width < free.x + free.width
              @free_rects.push(Rect.new(nil, used.x + used.width, free.y,
                free.x + free.width - (used.x + used.width), free.height))
            end
          end
          true
        end
      end

  end
end