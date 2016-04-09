require 'slnky/command/request'
require 'slnky/command/response'

require 'docopt'

module Slnky
  module Command
    class Base
      def initialize
        @config = Slnky.config
        @commands = self.class.commands
        @log = Slnky.log
      end

      def load_config(config)
        Slnky::Data.new(config)
      end

      def handle(req, res)
        begin
          @log.response = res
          processor = @commands.select { |c| c.name == req.command }.first
          if processor
            options = processor.process(req.args)
            self.send("handle_#{processor.name}", req, res, options)
          else
            @log.error "unkown command: #{req.command}"
          end
        rescue Docopt::Exit => e
          @log.info e.message
        rescue => e
          @log.error "error in #{req.command}: #{e.message} at #{e.backtrace.first}"
        ensure
          @log.response = false
        end
      end

      def handle_help(req, res, opts={})
        begin
          @log.response = res
          @commands.each do |command|
            @log.info "#{command.name}: #{command.usage}\n  #{command.help}"
          end
        ensure
          @log.response = false
        end
      end

      class << self
        attr_reader :commands

        def command(name, help, desc)
          @commands ||= [Slnky::Command::Processor.new('help', 'print help', 'Usage: help [options]')]
          @commands << Slnky::Command::Processor.new(name, help, desc)
        end
      end
    end

    class Processor
      attr_reader :name
      attr_reader :help
      attr_reader :doc

      def initialize(name, help, doc)
        @name = name.to_s
        @help = help
        @doc = doc
      end

      def usage
        doc.lines.first.chomp
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
    end
  end
end
