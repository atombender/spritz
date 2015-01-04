module Spritz

  class CLI

    def run!(args = ARGV)
      args.options do |opts|
        opts.banner = %{
  Usage:
    #{File.basename($0)} pack [OPTIONS] PACKAGE FILE ...
    #{File.basename($0)} pack -h | --help

  }
        opts.on("-h", "--help", "Show this help message.") do
          puts opts
          exit
        end
        opts.on("-v", "--version", "Show version.") do
          puts Spritz::VERSION
          exit
        end
        opts.order! { |x| opts.terminate(x) }
        if args.empty?
          abort "Nothing to do. Run with -h for help."
        end
      end

      command = args.shift
      case command
        when 'pack'
          pack_command(args)
        else
          abort "Unknown command '#{command}'. Run with -h for help."
      end
    end

    def pack_command(args)
      texture_width = nil
      texture_height = nil
      padding = 0
      format = nil
      quiet = false
      steps = []

      args.options do |opts|
        opts.banner = "Usage: #{File.basename($0)} pack [OPTIONS] PACKAGE FILE ...\n\n"
        opts.on("-h", "--help", "Show this help message.") do
          puts opts
          exit
        end
        opts.on("-q", "--[no-]quiet", "Don't output anything.") do |v|
          quiet = !!v
        end
        opts.on("-s", "--size WIDTHxHEIGHT", String,
          "Maximum texture size (defaults to 2048x2048)") do |v|
          if v =~ /(\d+)x(\d+)/i
            texture_width, texture_height = $1.to_i, $2.to_i
          else
            abort "Expected WIDTHxHEIGHT, got #{v.inspect}"
          end
        end
        opts.on("--padding PIXELS", Integer,
          "Padding between packed images (defaults to 0)") do |v|
          padding = v
        end
        opts.on("-f FORMAT", "--format FORMAT", String,
          "Bitmap format for textures. Defaults to 'png', may be set to 'pvrtc'",
          "(requires textiletool from iOS SDK) or 'pvrtc-gz' (same as pvrtc,",
          "but gzip-compressed).") do |v|
          unless %w(png pvrtc pvrtc-gz).include?(v.downcase)
            abort "Unexpected format #{v.inspect}"
          end
          format = v.to_sym
        end

        Plugins::MoaiPlugin.add_options(opts, steps)

        opts.order! { |x| opts.terminate(x) }
        if args.empty?
          abort "Nothing to do. Run with -h for help."
        end
      end

      package_name = args.shift
      abort "Package name not specified." unless package_name

      Logger.instance.device = $stdout unless quiet

      package = Spritz::Package.new(
        :name => package_name,
        :width => texture_width,
        :height => texture_height,
        :padding => padding,
        :format => format)
      args.each do |file_glob|
        Dir.glob(file_glob).each do |file_name|
          package.add_file(file_name)
        end
      end
      package.write

      steps.each do |step|
        step.call(package)
      end
    end

  end

end