require 'singleton'

module Spritz

  class Logger

    include Singleton

    attr_accessor :device

    def self.log_write(*args, &block)
      instance.log_write(*args, &block)
    end

    def self.log_action(*args)
      instance.log_action(*args)
    end

    def self.log(*args)
      instance.log(*args)
    end

    def log_write(path, &block)
      if File.exist?(path)
        log_action "Overwrite", path
      else
        log_action "Create", path
      end
      yield path
    end

    def log_action(what, *rest)
      case what
        when 'Render'
          color = '33'
        when 'Overwrite'
          color = '31'
        when 'Create'
          color = '32'
        else
          color = '36'
      end
      log("\e[#{color};1m%12s\e[0m %s\n" % [what, rest.join(' ')])
    end

    def log(line)
      if @device
        @device.write(line)
      end
    end

  end

end