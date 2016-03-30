module Slnky
  module CLI
    class Command < Base
      # option %w{-s --server}, '[SERVER]', 'set server url', environment_variable: 'SLNKY_SERVER'
      option %w{-n --dry-run}, :flag, "just output the event, don't send"
      option %w{-t --timeout}, '[TIMEOUT]', "just output the event, don't send", default: 10 do |t|
        Integer(t)
      end
      parameter 'SERVICE', 'the name of the service'
      parameter 'COMMAND', 'the name of the command'
      parameter '[ARGUMENTS] ...', <<-DESC.strip_heredoc, attribute_name: :args
        arguments to the command
        commands support options and command line arguments similarly to
        standard option parsing.
      DESC

      def execute
        data = {
            name: "slnky.#{service}.command",
            command: command,
            args: args,
            response: "command-#{$$}",
        }
        msg = Slnky::Message.new(data)
        puts JSON.pretty_generate(msg.to_h) if dry_run?
        amqp(msg) unless dry_run?
      end

      def amqp(msg)
        response = msg.response
        srv = server || Slnky.config['slnky']['url']
        config = Slnky::Data.new(Slnky.get_server_config(srv, :command))

        AMQP.start("amqp://#{config.rabbit.host}:#{config.rabbit.port}") do |connection|
          @channel = AMQP::Channel.new(connection)
          @channel.on_error do |ch, channel_close|
            raise "Channel-level exception: #{channel_close.reply_text}"
          end

          stopper = Proc.new do
            # out :info, 'stopping'
            connection.close { EventMachine.stop }
          end
          Signal.trap("INT", stopper)
          Signal.trap("TERM", stopper)

          exchange = @channel.direct('slnky.response')
          queue = @channel.queue("command.#{response}.response", auto_delete: true).bind(exchange, routing_key: response)
          queue.subscribe do |raw|
            message = Slnky::Message.parse(raw)
            if message.level.to_sym == :complete
              stopper.call
            else
              out message.level, message.message
            end
          end

          EventMachine.add_periodic_timer(timeout) do
            out :error, "timed out after #{timeout} seconds"
            stopper.call
          end

          out :info, 'sending command'
          Slnky.notify(msg, srv)
        end
      end

      def out(level, message)
        puts "%s [%-6s] %s" % [Time.now, level, message]
      end
    end
  end
end
Slnky::CLI::Main.subcommand('command', 'send command to the slnky server', Slnky::CLI::Command)
