require 'colorize'

module Slnky
  module CLI
    class Command < Base
      # option %w{-s --server}, '[SERVER]', 'set server url', environment_variable: 'SLNKY_SERVER'
      option %w{-n --dry-run}, :flag, "just output the event, don't send"
      option %w{-t --timeout}, '[TIMEOUT]', "time to wait for response in seconds", default: 10 do |t|
        Integer(t)
      end
      option %w{--[no-]color}, :flag, "disable color output", default: false do |c|
        String.disable_colorization = !c
      end
      parameter '[SERVICE]', 'the name of the service', default: 'help' do |h|
        h == '-h' && 'help' || h
      end
      parameter '[COMMAND]', 'the name of the command', default: 'help' do |h|
        h == '-h' && 'help' || h
      end
      parameter '[ARGUMENTS] ...', <<-DESC.strip_heredoc, attribute_name: :args
        arguments to the command
        commands support options and command line arguments similarly to
        standard option parsing.
      DESC

      def execute
        @name = service
        Slnky::Config.configure(@name, environment: environment)
        data = {
            name: "slnky.#{service}.command",
            command: service == 'help' ? nil : command,
            args: args,
            response: "command-#{$$}",
        }
        msg = Slnky::Message.new(data)
        puts JSON.pretty_generate(msg.to_h) if dry_run?
        amqp(msg) unless dry_run?
      end

      def name
        @name
      end

      def amqp(msg)
        response = msg.response
        tx = Slnky::Transport.instance

        tx.start!(self) do |_|
          queue = tx.queue(response, 'response', durable: false, auto_delete: true, routing_key: response)
          queue.subscribe do |raw|
            message = Slnky::Message.parse(raw)
            level = message.level.to_sym
            if level == :complete
              tx.stop!
            elsif level == :start
              # start tracking responders?
            else
              out level, message.message, message.service
            end
          end

          EventMachine.add_periodic_timer(timeout) do
            out :error, "timed out after #{timeout} seconds"
            tx.stop!('Timed out')
          end

          EventMachine.add_timer(1) do
            puts "sending request:".colorize(:light_white)
            Slnky.notify(msg)
          end
        end

        # sleep 10
        # Slnky.notify(msg)
      end

      def out(level, message, service=nil)
        service ||= Slnky::System.pid('local')
        lines = message.split("\n")
        lines.each do |line|
          str = service.colorize(:light_black)
          color = case level
                    when :warn
                      :yellow
                    when :error
                      :red
                    else
                      :white
          end
          str << (" [ %5s ] %s" % [level.to_s.upcase, line]).colorize(color)
          # puts "#{service} [#{level}] #{line}"
          puts str
        end
      end
    end
  end
end
Slnky::CLI::Main.subcommand('command', 'send command to the slnky server', Slnky::CLI::Command)
