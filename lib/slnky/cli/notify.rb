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
      parameter 'NAME', 'the name of the event to send'
      parameter '[ATTRIBUTES] ...', 'key=value pairs to add to the event, merged with optional file', attribute_name: :kvs

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
        kvs.each do |kv|
          (k, v) = kv.split('=')
          attributes[k] = v
        end
        msg = Slnky::Message.new({name: name, attributes: attributes})
        cfg = Slnky.config
        srv = server || cfg['slnky']['url']

        puts 'sending message:'
        puts JSON.pretty_generate(msg.to_h)
        Slnky.notify(msg)
      end
    end
  end
end
Slnky::CLI::Main.subcommand 'notify', 'send notification to the slnky server', Slnky::CLI::Notify
