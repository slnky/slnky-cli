require 'slnky/command/request'
require 'slnky/command/response'

require 'docopt'

module Slnky
  module Command
    class Base
      def initialize
        @commands = self.class.commands
      end

      def name
        @name ||= self.class.name.split('::')[1].downcase
      end

      def config
        @config ||= Slnky.config
      end

      def log
        @log ||= Slnky.log
      end

      def handle(event, data)
        begin
          req = Slnky::Command::Request.new(data)
          res = Slnky::Command::Response.new(data.response, name)
          log.response = res
          res.start!

          if event == 'slnky.help.command'
            handle_help(req, res)
          else
            handle_command(req, res)
          end

        rescue => e
          log.error "failed to run command: #{name}: #{data.command}: #{e.message} at #{e.backtrace.first}"
        ensure
          res.done!
          log.response = false
        end
      end

      def handle_help(req, res, opts={})
        @commands.each do |command|
          log.info "#{command.name}: #{command.usage}\n  #{command.banner}"
        end
      end

      def handle_command(req, res)
        begin
          processor = @commands.select { |c| c.name == req.command }.first
          if processor
            options = processor.process(req.args)
            self.send("handle_#{processor.name}", req, res, options)
          else
            log.error "unknown command: #{req.command}"
          end
        rescue Docopt::Exit => e
          log.info e.message
        rescue => e
          log.error "error in #{req.command}: #{e.message} at #{e.backtrace.first}"
        end
      end

      class << self
        attr_reader :commands

        def command(name, banner, desc)
          @commands ||= [Slnky::Command::Processor.new('help', 'print help', 'help [options]')]
          @commands << Slnky::Command::Processor.new(name, banner, desc)
        end
      end
    end

    class Processor
      attr_reader :name
      attr_reader :banner
      attr_reader :doc

      def initialize(name, banner, doc)
        @name = name.to_s
        @banner = banner
        @doc = doc =~ /^Usage/ ? doc : "Usage: #{doc}"
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
