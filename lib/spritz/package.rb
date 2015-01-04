module Spritz

  class Package

    class Slice

      attr_reader :file_name, :x, :y, :width, :height, :padding

      def initialize(file_name, x, y, width, height, padding)
        @file_name, @x, @y, @width, @height, @padding =
          file_name, x, y, width, height, padding
      end

      def image
        image = Magick::Image.from_blob(File.read(@file_name)).first
        image.crop!(@x, @y, @width, @height)
        image
      end

    end

    attr_reader :name
    attr_reader :texture_width, :texture_height
    attr_reader :format
    attr_reader :padding
    attr_reader :sheets

    def initialize(options = {})
      @name = options[:name]
      @texture_width = options[:width] || 2048
      @texture_height = options[:height] || 2048
      @format = options[:format] || :png
      @padding = options[:padding]
      @sheets = []
      @rendered_images = {}
    end

    def add_file(file_name)
      Logger.log_action "Add", file_name

      image = Magick::Image.ping(file_name).first
      t_width = @texture_width - @padding * 2
      t_height = @texture_height - @padding * 2
      (0..(image.columns / t_width.to_f).floor).to_a.each do |tile_x|
        (0..(image.rows / t_height.to_f).floor).to_a.each do |tile_y|
          if image.columns - tile_x * t_width + @padding > 0 and
            image.rows - tile_y * t_height + @padding > 0
            add_slice(
              Slice.new(file_name,
                tile_x * t_width,
                tile_y * t_height,
                [image.columns - tile_x * t_width + @padding, t_width].min,
                [image.rows - tile_y * t_height + @padding, t_height].min,
                @padding))
          end
        end
      end
    end

    def add_slice(slice)
      inserted = false
      @sheets.each do |sheet|
        if sheet.insert(slice, slice.width, slice.height)
          inserted = true
          break
        end
      end
      unless inserted
        sheet = new_sheet!
        unless sheet.insert(slice, slice.width, slice.height)
          raise "Unexpectedly unable to add image to any sheet: #{slice.file_name}"
        end
      end
    end

    def render
      @sheets.each_with_index do |sheet, index|
        Logger.log_action "Render", "Sheet ##{index}"
        @rendered_images[index] ||= render_sheet(sheet)
      end
      @rendered_images
    end

    def write
      render

      @rendered_images.each_pair do |index, image|
        base_name = "#{@name}.#{index}"
        case @format
          when :png
            Logger.log_write(file_name_for_format(base_name, @format)) do |path|
              File.open(path, 'w:binary') do |file|
                file.write as_png(image)
              end
            end
          when :pvrtc, :'pvrtc-gz'
            Logger.log_write(file_name_for_format(base_name, @format)) do |path|
              Tempfile.open('spritz') do |tempfile|
                tempfile.write as_png(image)
                tempfile.close

                texturetool_flags = '--alpha-is-opacity --bits-per-pixel-4'

                system("texturetool -f raw -e PVRTC #{texturetool_flags} " <<
                  "-o #{file_name_for_format base_name, :pvrtc} #{tempfile.path}")
                unless $?.exited? and $?.exitstatus == 0
                  raise "Failed to run texturetool. Is it installed?"
                end

                if @format == :'pvrtc-gz'
                  system("gzip -c #{file_name_for_format base_name, :pvrtc} >#{path}")
                  unless $?.exited? and $?.exitstatus == 0
                    raise "Failed to run gzip. Is it installed?"
                  end
                end
              end
            end
        end
        image.destroy!
      end

      rects_by_slice = {}
      @sheets.each_with_index do |sheet, index|
        sheet.rects.each do |rect|
          (rects_by_slice[rect.value.file_name] ||= []).push([index, rect])
        end
      end

      frames = {}
      rects_by_slice.each do |file_name, rects|
        key = file_name.gsub(/\.\w+$/, '')
        frames[key] = rects.map { |(sheet_index, rect)|
          {
            :i => sheet_index,
            :w => rect.width,
            :h => rect.height,
            :r => rect.rotated?,
            :v => vertex_coords_for(rect),
            :t => texture_coords_for(rect)
          }
        }
      end
      structure = {
        :version => 1,
        :textures => Hash[*(0...@sheets.length).to_a.map { |i|
          [i, {
            :format => @format,
            :file => "#{File.basename(@name)}.#{i}.#{@format}"
          }]
        }.flatten],
        :texture_width => @texture_width,
        :texture_height => @texture_height,
        :padding => @padding,
        :frames => frames
      }

      Logger.log_write("#{@name}.json.gz") do |path|
        Zlib::GzipWriter.open(path) do |file|
          file.write JSON.pretty_generate(structure)
        end
      end
    end

    def file_name_for_format(base, format)
      case format
        when :png, :pvrtc
          return "#{base}.#{format}"
        when :'pvrtc-gz'
          return "#{base}.pvr.gz"
      end
    end

    private

      def as_png(image)
        image.to_blob {
          self.format = 'png'
          self.compression = Magick::ZipCompression
          self.depth = 16
          self.quality = 100
        }
      end

      def vertex_coords_for(rect)
        x1 = 0
        y1 = 0
        x2 = rect.width
        y2 = rect.height
        return [
          [x1, y1],
          [x2, x1],
          [y1, y2],
          [x2, y2]
        ]
      end

      def texture_coords_for(rect)
        if @padding > 0
          tx1 = ((2 * rect.x) + 1) / (2 * @texture_width.to_f)
          ty1 = ((2 * rect.y) + 1) / (2 * @texture_height.to_f)
          if rect.rotated?
            tx2 = (((2 * rect.x) + 1) + (rect.height * 2) - 2) / (2 * @texture_width.to_f)
            ty2 = (((2 * rect.y) + 1) + (rect.width * 2) - 2) / (2 * @texture_height.to_f)
          else
            tx2 = (((2 * rect.x) + 1) + (rect.width * 2) - 2) / (2 * @texture_width.to_f)
            ty2 = (((2 * rect.y) + 1) + (rect.height * 2) - 2) / (2 * @texture_height.to_f)
          end
        else
          tx1 = rect.x / @texture_width.to_f
          ty1 = rect.y / @texture_height.to_f
          if rect.rotated?
            tx2 = (rect.x + rect.height) / @texture_height.to_f
            ty2 = (rect.y + rect.width) / @texture_width.to_f
          else
            tx2 = (rect.x + rect.width) / @texture_width.to_f
            ty2 = (rect.y + rect.height) / @texture_height.to_f
          end
        end
        return [
          [tx1, ty1],
          [tx2, ty1],
          [tx2, ty2],
          [tx1, ty2]
        ]
      end

      def render_sheet(sheet)
        image = Magick::Image.new(@texture_width, @texture_height) do |i|
          i.background_color = 'transparent'
        end
        sheet.rects.each do |rect|
          slice = rect.value
          frame = slice.image
          frame.rotate!(-90) if rect.rotated?
          image.composite!(frame, Magick::NorthWestGravity,
            @padding + rect.x, @padding + rect.y, Magick::ReplaceCompositeOp)
        end
        image
      end

      def new_sheet!
        sheet = MaxRectsPacker.new(@texture_width - @padding, @texture_height - @padding)
        @sheets.push(sheet)
        sheet
      end

  end

end