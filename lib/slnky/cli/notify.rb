module Slnky
  module CLI
    class Notify < Base
      # option %w{-s --server}, '[SERVER]', 'set server url', environment_variable: 'SLNKY_SERVER'
      option %w{-f --file}, '[FILE]', 'load attributes from yaml file' do |f|
        unless File.exist?(f)
          puts "ERROR: file #{f} does not exist"
          exit(1)
        end
        f
      end
      option %w{-n --dry-run}, :flag, "just output the event, don't send"
      parameter 'NAME', 'the name of the event to send'
      parameter '[ATTRIBUTES] ...', <<-DESC.strip_heredoc, attribute_name: :kvs
        key=value pairs to add to the event, merged with optional file
        supports dotted notation keys, and will merge them into nested hash
        chat.* keys are specially handled, they are not encoded as part of the
        attributes, they will be moved to their own keyspace
      DESC
      def execute
        attributes = {}
        if file
          begin
            yaml = YAML.load_file(file)
            attributes.merge!(yaml)
          rescue => e
            puts "ERROR: reading file #{file}"
            exit(1)
          end
        end
        attributes.merge!(dothash(kvs)) if kvs
        chat = attributes.delete(:chat)
        msg = Slnky::Message.new({name: name, attributes: attributes, chat: chat})
        cfg = Slnky.config
        srv = server || cfg['slnky']['url']

        puts 'sending message:'
        puts JSON.pretty_generate(msg.to_h)
        Slnky.notify(msg, srv) unless dry_run?
      end

      # convert list of dot notation key.name=value into nested hash
      def dothash(list)
        input_hash = list.inject({}) {|h, e| (k,v)=e.split('='); h[k]=v; h}
        input_hash.map do |main_key, main_value|
          main_key.to_s.split(".").reverse.inject(main_value) do |value, key|
            {key.to_sym => value(value)}
          end
        end.inject(&:deep_merge)
      end

      # convert value from string to internal types
      def value(value)
        return value unless value.is_a?(String)
        case value
          when 'true'
            true
          when 'false'
            false
          when /^\d+\.\d+\.\d+/ # ip addr
            value
          when /^\d+$/ # number
            value.to_i
          when /^[\d\.]+$/ # float
            value.to_f
          else
            value
        end
      end
    end
  end
end
Slnky::CLI::Main.subcommand('notify', 'send notification to the slnky server', Slnky::CLI::Notify)
