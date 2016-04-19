require 'slnky/command/request'
require 'slnky/command/response'

require 'docopt'

module Slnky
  module Command
    class Base
      def initialize
        @commands = self.class.commands
      end

      def handle(event, data, response=nil)
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
          puts "ERROR: #{e.message}"
          log.error "failed to run command: #{name}: #{data.command}: #{e.message} at #{e.backtrace.first}"
        ensure
          log.response = false
          res.done!
        end
      end

      def handle_help(req, res, opts={})
        @commands.each do |command|
          log.info "#{name} #{command.name}: #{command.banner}"
        end
      end

      def handle_command(req, res)
        puts "REQ ARGS: #{req.inspect}"
        begin
          processor = @commands.select { |c| c.name == req.command }.first
          puts "REQ: #{req.inspect}"
          if processor
            options = processor.process(req.args)
            self.send("handle_#{processor.name}", req, res, options)
          else
            log.error "unknown command: #{req.command}"
          end
        rescue Docopt::Exit => e
          log.info e.message
        end
      end

      def name
        @name ||= self.class.name.split('::')[1].downcase
      end

      def config
        Slnky.config
      end

      def log
        Slnky.log
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
        opts = Docopt::docopt(@doc, argv: args||[])
        data = Slnky::Data.new
        opts.each do |key, value|
          k = key.gsub(/^--/, '').downcase
          data.send("#{k}=", value)
        end
        data
      end
    end
  end
end
