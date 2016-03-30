require 'slnky/command/request'
require 'slnky/command/response'

require 'docopt'

module Slnky
  module Command
    class Base
      def initialize(config={})
        @config = load_config(config)
        @commands = self.class.commands
      end

      def load_config(config)
        Slnky::Data.new(config)
      end

      def options(args, desc=nil, &block)
        command = (caller[0] =~ /`([^']*)'/ and $1)
        banner = "usage: #{command} [options] ..."
        banner += "\n  #{desc}" if desc
        Slop.parse(args) do |slop|
          slop.banner = banner
          yield slop
        end
      end

      def handle(req, res)
        processor = @commands.select{|c| c.name == req.command}.first
        if processor
          options = processor.process(req.args)
          self.send("handle_#{processor.name}", req, res, options)
        else
          res.error "unkown command: #{req.command}"
        end
      rescue Docopt::Exit => e
        res.output e.message
      end

      def handle_help

      end

      class << self
        attr_reader :commands
        def command(name, help, desc)
          @commands ||= []
          @commands << Slnky::Command::Processor.new(name, help, desc)
        end
      end
    end

    class Processor
      attr_reader :name
      attr_reader :help
      attr_reader :banner
      attr_reader :usage

      def initialize(name, help, doc)
        @name = name.to_s
        @help = help
        @doc = doc
      end

      def process(args)
        opts = Docopt::docopt(@doc, argv: args)
        data = Slnky::Data.new
        opts.each do |key, value|
          k = key.gsub(/^--/, '')
          data.send("#{k}=", value)
        end
        data
      end

      # def process(args)
      #   opts = Slop.parse(args) do |slop|
      #     slop.banner = @help
      #     @usage.each do |line|
      #       next unless line =~ /^\-/
      #       (short, long, desc) = line.split(/\s+/, 3)
      #       (type, desc) = desc.split(':', 2)
      #       if desc
      #         type = type.to_sym
      #       else
      #         desc = type
      #         type = :on
      #       end
      #       puts "line: #{[type, short, long, desc]}"
      #       slop.send(type, short, long, desc)
      #     end
      #   end
      #   options = Slnky::Data.new(opts.to_hash)
      #   options.args = args
      #   puts options.inspect
      #   options
      # end
    end
  end
end
