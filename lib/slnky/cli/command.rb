module Slnky
  module CLI
    class Command < Base
      # option %w{-s --server}, '[SERVER]', 'set server url', environment_variable: 'SLNKY_SERVER'
      option %w{-n --dry-run}, :flag, "just output the event, don't send"
      option %w{-t --timeout}, '[TIMEOUT]', "time to wait for response in seconds", default: 10 do |t|
        Integer(t)
      end
      parameter 'SERVICE', 'the name of the service'
      parameter '[COMMAND]', 'the name of the command', default: 'help'
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
          # queue = tx.queue(response, 'response', durable: true, routing_key: response)
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

          Slnky.notify(msg)
        end
      end

      def out(level, message, service=:local)
        # unless @remote[service]
        #   say "<%= color('response from service: #{data.service}', BOLD) %>"
        #   @first = true
        # end
        # color = level.to_s == 'info' ? 'GREEN' : 'RED'
        # say "<%= color(\"#{service}\", GRAY) %> <%= color(\"#{message}\", #{color}) %>"
        lines = message.split("\n")
        lines.each do |line|
          puts "#{service} [#{level}] #{line}"
        end
      end
    end
  end
end
Slnky::CLI::Main.subcommand('command', 'send command to the slnky server', Slnky::CLI::Command)
